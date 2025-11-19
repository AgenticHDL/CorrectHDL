
`timescale 1ns/1ps

module sha0_core #(
  parameter integer MAX_INPUT_BYTES = 64
)(
  input  wire         clk,
  input  wire         rst_n,

  // Control
  input  wire         start,
  input  wire [15:0]  msg_len,
  output reg          busy,
  output reg          digest_valid,

  // Input byte stream
  input  wire         in_valid,
  input  wire [7:0]   in_data,
  output reg          in_ready,

  // Output digest
  output reg  [31:0]  digest0,
  output reg  [31:0]  digest1,
  output reg  [31:0]  digest2,
  output reg  [31:0]  digest3,
  output reg  [31:0]  digest4
);

  // ------------------------------
  // Internal storage for message
  // ------------------------------
  reg [7:0] inbuf [0:MAX_INPUT_BYTES-1];
  reg [15:0] expected_len;
  reg [15:0] wr_ptr;

  // ------------------------------
  // SHA state (H registers)
  // ------------------------------
  reg [31:0] H0, H1, H2, H3, H4;
  reg [31:0] A, B, C, D, E;

  // circular W[0..15]
  reg [31:0] W [0:15];

  // counters / control
  reg [15:0] off_bytes;
  reg [6:0]  round_idx;        // 0..79
  reg [4:0]  w_load_idx;       // 0..16
  reg [6:0]  blk_byte_idx;     // 0..63

  reg        need_second_pad;
  reg        doing_pad_block;
  reg        which_pad_block;

  // 64-bit bit count (for final 8 bytes, big-endian)
  reg [31:0] bitcnt_hi, bitcnt_lo;

  // a local 64B block buffer only used for padding block assembly
  reg [7:0]  blk [0:63];

  // FSM
  localparam [3:0]
    S_IDLE        = 4'd0,
    S_LOAD_INPUT  = 4'd1,
    S_INIT_HASH   = 4'd2,
    S_CHK_FULL    = 4'd3,
    S_W_LOAD_IN   = 4'd4,
    S_ROUNDS      = 4'd5,
    S_ACCUM       = 4'd6,
    S_PREP_PAD    = 4'd7,
    S_PAD_FILL    = 4'd8,
    S_W_LOAD_PAD  = 4'd9,
    S_DONE        = 4'd10;

  reg [3:0] state, state_n;

  // ------------------------------
  // Helpers
  // ------------------------------
  function [31:0] rol32;
    input [31:0] x;
    input [4:0]  n;
    begin

      rol32 = (x << n) | (x >> (32 - n));
    end
  endfunction

  // K/F/Wi combinational
  reg [31:0] K_c, F_c, Wi_c;

  always @* begin
    // default
    K_c  = 32'h00000000;
    F_c  = 32'h00000000;

    if (round_idx < 20) begin
      K_c = 32'h5a827999;
      F_c = (B & C) | ((~B) & D);
    end else if (round_idx < 40) begin
      K_c = 32'h6ed9eba1;
      F_c = (B ^ C ^ D);
    end else if (round_idx < 60) begin
      K_c = 32'h8f1bbcdc;
      F_c = (B & C) | (B & D) | (C & D);
    end else begin
      K_c = 32'hca62c1d6;
      F_c = (B ^ C ^ D);
    end


    if (round_idx < 16) begin
      Wi_c = W[round_idx[3:0]];
    end else begin
      // SHA-0 schedule (no rotate)
      Wi_c = W[(round_idx-3)  & 4'hf]
           ^ W[(round_idx-8)  & 4'hf]
           ^ W[(round_idx-14) & 4'hf]
           ^ W[round_idx[3:0]];
    end
  end

  // ------------------------------
  // Next-state / handshake control
  // ------------------------------
  always @* begin
    state_n  = state;
    in_ready = 1'b0;

    case (state)
      S_IDLE: begin
        if (start) state_n = S_LOAD_INPUT;
      end

      S_LOAD_INPUT: begin
        in_ready = (wr_ptr < expected_len);
        if (wr_ptr == expected_len) state_n = S_INIT_HASH;
      end

      S_INIT_HASH: begin
        state_n = S_CHK_FULL;
      end

      S_CHK_FULL: begin
        if ((off_bytes + 16'd64) <= expected_len) state_n = S_W_LOAD_IN;
        else                                      state_n = S_PREP_PAD;
      end

      S_W_LOAD_IN: begin
        if (w_load_idx == 5'd16) state_n = S_ROUNDS;
      end

      S_ROUNDS: begin
        if (round_idx == 7'd80) state_n = S_ACCUM;
      end

      S_ACCUM: begin
        state_n = S_CHK_FULL;
      end

      S_PREP_PAD: begin
        state_n = S_PAD_FILL;
      end

      S_PAD_FILL: begin
        if (blk_byte_idx == 7'd64) state_n = S_W_LOAD_PAD;
      end

      S_W_LOAD_PAD: begin
        if (w_load_idx == 5'd16) state_n = S_ROUNDS;
      end

      S_DONE: begin
        state_n = S_IDLE;
      end

      default: state_n = S_IDLE;
    endcase
  end

  // ------------------------------
  // Sequential FSM / datapath
  // ------------------------------
  integer ii;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state         <= S_IDLE;
      busy          <= 1'b0;
      digest_valid  <= 1'b0;
      in_ready      <= 1'b0;
      wr_ptr        <= 16'd0;
      expected_len  <= 16'd0;
      off_bytes     <= 16'd0;
      w_load_idx    <= 5'd0;
      round_idx     <= 7'd0;
      blk_byte_idx  <= 7'd0;
      doing_pad_block  <= 1'b0;
      which_pad_block  <= 1'b0;
      need_second_pad  <= 1'b0;

      digest0 <= 32'd0; digest1 <= 32'd0; digest2 <= 32'd0; digest3 <= 32'd0; digest4 <= 32'd0;

      for (ii=0; ii<MAX_INPUT_BYTES; ii=ii+1) inbuf[ii] <= 8'd0;
      for (ii=0; ii<64; ii=ii+1) blk[ii] <= 8'd0;
      for (ii=0; ii<16; ii=ii+1) W[ii] <= 32'd0;

      H0 <= 32'd0; H1 <= 32'd0; H2 <= 32'd0; H3 <= 32'd0; H4 <= 32'd0;
      A  <= 32'd0; B  <= 32'd0; C  <= 32'd0; D  <= 32'd0; E  <= 32'd0;
      bitcnt_lo <= 32'd0; bitcnt_hi <= 32'd0;

    end else begin
      state        <= state_n;
      digest_valid <= 1'b0;

      case (state)
        S_IDLE: begin
          busy            <= 1'b0;
          wr_ptr          <= 16'd0;
          off_bytes       <= 16'd0;
          w_load_idx      <= 5'd0;
          round_idx       <= 7'd0;
          blk_byte_idx    <= 7'd0;
          doing_pad_block <= 1'b0;
          which_pad_block <= 1'b0;
          need_second_pad <= 1'b0;
          if (start) begin
            busy         <= 1'b1;
            expected_len <= (msg_len > MAX_INPUT_BYTES) ? MAX_INPUT_BYTES[15:0] : msg_len;
          end
        end

        S_LOAD_INPUT: begin
          if (in_valid && (wr_ptr < expected_len)) begin
            inbuf[wr_ptr] <= in_data;
            wr_ptr        <= wr_ptr + 16'd1;
          end
        end

        S_INIT_HASH: begin
          H0 <= 32'h67452301;
          H1 <= 32'hefcdab89;
          H2 <= 32'h98badcfe;
          H3 <= 32'h10325476;
          H4 <= 32'hc3d2e1f0;


          begin : compute_bitlen
            reg [63:0] bitlen64_c;
            bitlen64_c = {48'd0, expected_len} << 3;
            bitcnt_lo  <= bitlen64_c[31:0];
            bitcnt_hi  <= bitlen64_c[63:32];
          end

          off_bytes  <= 16'd0;
          w_load_idx <= 5'd0;
          round_idx  <= 7'd0;
        end

        S_CHK_FULL: begin
          // no-op; next-state handles branching
        end

        S_W_LOAD_IN: begin
          if (w_load_idx < 5'd16) begin
            W[w_load_idx] <= { inbuf[off_bytes + (w_load_idx<<2) + 16'd0],
                               inbuf[off_bytes + (w_load_idx<<2) + 16'd1],
                               inbuf[off_bytes + (w_load_idx<<2) + 16'd2],
                               inbuf[off_bytes + (w_load_idx<<2) + 16'd3] };
            w_load_idx    <= w_load_idx + 5'd1;
          end else begin
            A <= H0; B <= H1; C <= H2; D <= H3; E <= H4;
            round_idx  <= 7'd0;
          end
        end

        S_ROUNDS: begin
          if (round_idx < 7'd80) begin
            if (round_idx >= 7'd16) begin
              W[round_idx[3:0]] <= Wi_c;
            end
            begin : update_round
              reg [31:0] temp_c;
              temp_c = rol32(A, 5) + F_c + E + Wi_c + K_c;
              E <= D;
              D <= C;
              C <= rol32(B, 5'd30);
              B <= A;
              A <= temp_c;
            end
            round_idx <= round_idx + 7'd1;
          end
        end


        S_ACCUM: begin
          H0 <= H0 + A;
          H1 <= H1 + B;
          H2 <= H2 + C;
          H3 <= H3 + D;
          H4 <= H4 + E;

          if ((off_bytes + 16'd64) <= expected_len) begin
            off_bytes <= off_bytes + 16'd64;
          end

          w_load_idx <= 5'd0;
          round_idx  <= 7'd0;
        end

        S_PREP_PAD: begin
          doing_pad_block <= 1'b1;
          which_pad_block <= 1'b0;
          begin : decide_pad
            reg [15:0] rem_c;
            rem_c = expected_len - off_bytes;
            need_second_pad <= (rem_c > 16'd55);
          end
          blk_byte_idx <= 7'd0;
          for (ii=0; ii<64; ii=ii+1) blk[ii] <= 8'd0;
        end

        S_PAD_FILL: begin
          if (blk_byte_idx < 7'd64) begin
            reg [7:0] bval;
            bval = 8'h00;

            if (which_pad_block == 1'b0) begin
              reg [15:0] rem_c;
              rem_c = expected_len - off_bytes;

              if (blk_byte_idx < rem_c) begin
                bval = inbuf[off_bytes + blk_byte_idx];
              end else if (blk_byte_idx == rem_c) begin
                bval = 8'h80;
              end else begin
                if (rem_c <= 16'd55) begin
                  if (blk_byte_idx == 7'd56) bval = bitcnt_hi[31:24];
                  else if (blk_byte_idx == 7'd57) bval = bitcnt_hi[23:16];
                  else if (blk_byte_idx == 7'd58) bval = bitcnt_hi[15:8];
                  else if (blk_byte_idx == 7'd59) bval = bitcnt_hi[7:0];
                  else if (blk_byte_idx == 7'd60) bval = bitcnt_lo[31:24];
                  else if (blk_byte_idx == 7'd61) bval = bitcnt_lo[23:16];
                  else if (blk_byte_idx == 7'd62) bval = bitcnt_lo[15:8];
                  else if (blk_byte_idx == 7'd63) bval = bitcnt_lo[7:0];
                  else bval = 8'h00;
                end else begin
                  bval = 8'h00;
                end
              end
            end else begin
              if (blk_byte_idx == 7'd56) bval = bitcnt_hi[31:24];
              else if (blk_byte_idx == 7'd57) bval = bitcnt_hi[23:16];
              else if (blk_byte_idx == 7'd58) bval = bitcnt_hi[15:8];
              else if (blk_byte_idx == 7'd59) bval = bitcnt_hi[7:0];
              else if (blk_byte_idx == 7'd60) bval = bitcnt_lo[31:24];
              else if (blk_byte_idx == 7'd61) bval = bitcnt_lo[23:16];
              else if (blk_byte_idx == 7'd62) bval = bitcnt_lo[15:8];
              else if (blk_byte_idx == 7'd63) bval = bitcnt_lo[7:0];
              else bval = 8'h00;
            end

            blk[blk_byte_idx] <= bval;
            blk_byte_idx      <= blk_byte_idx + 7'd1;
          end else begin
            w_load_idx <= 5'd0;
          end
        end

        S_W_LOAD_PAD: begin
          if (w_load_idx < 5'd16) begin
            W[w_load_idx] <= { blk[(w_load_idx<<2)+0],
                               blk[(w_load_idx<<2)+1],
                               blk[(w_load_idx<<2)+2],
                               blk[(w_load_idx<<2)+3] };
            w_load_idx    <= w_load_idx + 5'd1;
          end else begin
            A <= H0; B <= H1; C <= H2; D <= H3; E <= H4;
            round_idx <= 7'd0;

            if (which_pad_block == 1'b0) begin
              if (need_second_pad) begin
                which_pad_block <= 1'b1;
                blk_byte_idx    <= 7'd0;
                for (ii=0; ii<64; ii=ii+1) blk[ii] <= 8'd0;
              end
            end
          end
        end

        S_DONE: begin
          busy         <= 1'b0;
          digest0      <= H0;
          digest1      <= H1;
          digest2      <= H2;
          digest3      <= H3;
          digest4      <= H4;
          digest_valid <= 1'b1;
        end

        default: ;
      endcase

      // override to DONE when finishing padding
      if (state == S_ACCUM) begin
        if (doing_pad_block) begin
          if ((which_pad_block == 1'b0) && (need_second_pad == 1'b0)) begin
            state <= S_DONE;
          end else if (which_pad_block == 1'b1) begin
            state <= S_DONE;
          end
        end
      end

      if (state == S_PREP_PAD) begin
        doing_pad_block <= 1'b1;
      end
    end
  end

endmodule
