`timescale 1ns/1ps
// Verilog-2001, synthesizable, minimal-area rolling-row DP + full ptr for traceback
// ALEN = 10, BLEN = 10

module needwun (
  input  wire        clk,
  input  wire        rstn,
  input  wire        start,

  // SEQA / SEQB: 10 chars (8-bit each), index 0..9
  input  wire [7:0]  SEQA0,  input wire [7:0] SEQA1,  input wire [7:0] SEQA2,  input wire [7:0] SEQA3,
  input  wire [7:0]  SEQA4,  input wire [7:0] SEQA5,  input wire [7:0] SEQA6,  input wire [7:0] SEQA7,
  input  wire [7:0]  SEQA8,  input wire [7:0] SEQA9,

  input  wire [7:0]  SEQB0,  input wire [7:0] SEQB1,  input wire [7:0] SEQB2,  input wire [7:0] SEQB3,
  input  wire [7:0]  SEQB4,  input wire [7:0] SEQB5,  input wire [7:0] SEQB6,  input wire [7:0] SEQB7,
  input  wire [7:0]  SEQB8,  input wire [7:0] SEQB9,

  // aligned outputs: 20 chars each
  output reg  [7:0]  ALIGA0,  output reg [7:0] ALIGA1,  output reg [7:0] ALIGA2,  output reg [7:0] ALIGA3,
  output reg  [7:0]  ALIGA4,  output reg [7:0] ALIGA5,  output reg [7:0] ALIGA6,  output reg [7:0] ALIGA7,
  output reg  [7:0]  ALIGA8,  output reg [7:0] ALIGA9,  output reg [7:0] ALIGA10, output reg [7:0] ALIGA11,
  output reg  [7:0]  ALIGA12, output reg [7:0] ALIGA13, output reg [7:0] ALIGA14, output reg [7:0] ALIGA15,
  output reg  [7:0]  ALIGA16, output reg [7:0] ALIGA17, output reg [7:0] ALIGA18, output reg [7:0] ALIGA19,

  output reg  [7:0]  ALIGB0,  output reg [7:0] ALIGB1,  output reg [7:0] ALIGB2,  output reg [7:0] ALIGB3,
  output reg  [7:0]  ALIGB4,  output reg [7:0] ALIGB5,  output reg [7:0] ALIGB6,  output reg [7:0] ALIGB7,
  output reg  [7:0]  ALIGB8,  output reg [7:0] ALIGB9,  output reg [7:0] ALIGB10, output reg [7:0] ALIGB11,
  output reg  [7:0]  ALIGB12, output reg [7:0] ALIGB13, output reg [7:0] ALIGB14, output reg [7:0] ALIGB15,
  output reg  [7:0]  ALIGB16, output reg [7:0] ALIGB17, output reg [7:0] ALIGB18, output reg [7:0] ALIGB19,

  output reg         done
);

  // --------------------------------------------------------------------------
  // Parameters / constants
  // --------------------------------------------------------------------------
  localparam integer ALEN = 10;
  localparam integer BLEN = 10;
  localparam integer W    = ALEN + 1; // 11
  // scores (signed)
  localparam signed [31:0] MATCH     = 32'sd1;
  localparam signed [31:0] MISMATCH  = -32'sd1;
  localparam signed [31:0] GAP       = -32'sd1;
  // ptr chars
  localparam [7:0] ALIGN_C  = 8'd92; // '\\'
  localparam [7:0] SKIPA_C  = 8'd94; // '^'
  localparam [7:0] SKIPB_C  = 8'd60; // '<'
  localparam [7:0] DASH_C   = 8'd45; // '-'
  localparam [7:0] UNDERSCORE_C = 8'd95; // '_'

  // --------------------------------------------------------------------------
  // Local storage
  // --------------------------------------------------------------------------
  reg [7:0] seqa [0:ALEN-1];
  reg [7:0] seqb [0:BLEN-1];

  // rolling rows for M (signed 32-bit)
  reg signed [31:0] M_prev [0:W-1];
  reg signed [31:0] M_curr [0:W-1];

  // ptr matrix (full), 11*11 = 121 entries
  reg [7:0] ptr_mem [0:W*(BLEN+1)-1]; // [0..120]

  // aligned outputs (buffers)
  reg [7:0] alignedA [0:ALEN+BLEN-1]; // 20
  reg [7:0] alignedB [0:ALEN+BLEN-1]; // 20

  // indices / FSM
  localparam [3:0]
    S_IDLE      = 4'd0,
    S_LDSEQ     = 4'd1,
    S_INIT_ROW0 = 4'd2,
    S_INIT_COL0 = 4'd3,
    S_DP_ROW    = 4'd4,
    S_DP_COPY   = 4'd5,
    S_TRACE     = 4'd6,
    S_FILL_A    = 4'd7,
    S_FILL_B    = 4'd8,
    S_OUTCPY    = 4'd9,
    S_DONE      = 4'd10;

  reg [3:0] state;

  // counters
  reg [5:0] i;               // small counter
  reg [4:0] a_idx;           // 0..10
  reg [4:0] b_idx;           // 0..10
  reg [7:0] base_idx;        // row base = b * W (0..110 fits 7 bits; use 8 for simplicity)

  reg [5:0] a_str_idx;       // 0..20
  reg [5:0] b_str_idx;       // 0..20

  // --------------------------------------------------------------------------
  // Sequential FSM
  // --------------------------------------------------------------------------
  integer k;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      state <= S_IDLE;
      done  <= 1'b0;

      for (k=0; k<ALEN; k=k+1) begin
        seqa[k] <= 8'd0;
        seqb[k] <= 8'd0;
      end
      for (k=0; k<W; k=k+1) begin
        M_prev[k] <= 32'sd0;
        M_curr[k] <= 32'sd0;
      end
      for (k=0; k<W*(BLEN+1); k=k+1) ptr_mem[k] <= 8'd0;
      for (k=0; k<ALEN+BLEN; k=k+1) begin
        alignedA[k] <= 8'd0;
        alignedB[k] <= 8'd0;
      end

      a_idx <= 5'd0; b_idx <= 5'd0; base_idx <= 8'd0;
      a_str_idx <= 6'd0; b_str_idx <= 6'd0;

      {ALIGA0,ALIGA1,ALIGA2,ALIGA3,ALIGA4,ALIGA5,ALIGA6,ALIGA7,ALIGA8,ALIGA9,
       ALIGA10,ALIGA11,ALIGA12,ALIGA13,ALIGA14,ALIGA15,ALIGA16,ALIGA17,ALIGA18,ALIGA19} <= {20{8'd0}};
      {ALIGB0,ALIGB1,ALIGB2,ALIGB3,ALIGB4,ALIGB5,ALIGB6,ALIGB7,ALIGB8,ALIGB9,
       ALIGB10,ALIGB11,ALIGB12,ALIGB13,ALIGB14,ALIGB15,ALIGB16,ALIGB17,ALIGB18,ALIGB19} <= {20{8'd0}};
    end else begin
      case (state)
        // Wait start
        S_IDLE: begin
          done <= 1'b0;
          if (start) begin
            i <= 6'd0;
            state <= S_LDSEQ;
          end
        end

        // Copy input chars into seqa/seqb sequentially (1/cycle)
        S_LDSEQ: begin
          case (i[4:0])
            5'd0:  begin seqa[0] <= SEQA0;  seqb[0]  <= SEQB0;  end
            5'd1:  begin seqa[1] <= SEQA1;  seqb[1]  <= SEQB1;  end
            5'd2:  begin seqa[2] <= SEQA2;  seqb[2]  <= SEQB2;  end
            5'd3:  begin seqa[3] <= SEQA3;  seqb[3]  <= SEQB3;  end
            5'd4:  begin seqa[4] <= SEQA4;  seqb[4]  <= SEQB4;  end
            5'd5:  begin seqa[5] <= SEQA5;  seqb[5]  <= SEQB5;  end
            5'd6:  begin seqa[6] <= SEQA6;  seqb[6]  <= SEQB6;  end
            5'd7:  begin seqa[7] <= SEQA7;  seqb[7]  <= SEQB7;  end
            5'd8:  begin seqa[8] <= SEQA8;  seqb[8]  <= SEQB8;  end
            5'd9:  begin seqa[9] <= SEQA9;  seqb[9]  <= SEQB9;  end
            default: ;
          endcase
          if (i == 6'd9) begin
            a_idx <= 5'd0;
            state <= S_INIT_ROW0;
          end
          i <= i + 6'd1;
        end

        // Initialize first row: M_prev[a] = a * GAP
        S_INIT_ROW0: begin
          M_prev[a_idx] <= $signed({27'd0,a_idx}) * GAP;
          if (a_idx == ALEN[4:0]) begin
            b_idx <= 5'd0;
            state <= S_INIT_COL0;
          end
          a_idx <= a_idx + 5'd1;
        end

        // Initialize first column M[b*W] = b * GAP via M_curr[0]
        S_INIT_COL0: begin
          M_curr[0] <= $signed({27'd0,b_idx}) * GAP;
          if (b_idx == BLEN[4:0]) begin
            b_idx   <= 5'd1;
            a_idx   <= 5'd1;
            base_idx<= (5'd1 * W);
            state   <= S_DP_ROW;
          end else begin
            b_idx <= b_idx + 5'd1;
          end
        end

        // DP inner loop: one cell per cycle
        S_DP_ROW: begin
          // locals (blocking allowed)
          reg signed [31:0] score, up_left, up_v, left_v, m1, m;
          reg [7:0]         tag1, tag;

          if (seqa[a_idx-1] == seqb[b_idx-1]) score = MATCH;
          else                                score = MISMATCH;

          up_left = M_prev[a_idx-1] + score;
          up_v    = M_prev[a_idx]   + GAP;
          left_v  = M_curr[a_idx-1] + GAP;

          // tie-breaking: left > up > diag
          if (up_v > left_v) begin m1 = up_v; tag1 = SKIPA_C; end
          else               begin m1 = left_v; tag1 = SKIPB_C; end
          if (up_left > m1)  begin m  = up_left; tag  = ALIGN_C; end
          else               begin m  = m1;      tag  = tag1;    end

          M_curr[a_idx] <= m;
          ptr_mem[base_idx + a_idx] <= tag;

          if (a_idx == ALEN[4:0]) begin
            i <= 6'd0;
            state <= S_DP_COPY;
          end
          a_idx <= (a_idx == ALEN[4:0]) ? 5'd0 : (a_idx + 5'd1);
        end

        // Copy current row to prev row sequentially, then next row
        S_DP_COPY: begin
          M_prev[i[4:0]] <= M_curr[i[4:0]];
          if (i == ALEN[4:0]) begin
            if (b_idx == BLEN[4:0]) begin
              a_idx     <= ALEN[4:0];
              b_idx     <= BLEN[4:0];
              a_str_idx <= 6'd0;
              b_str_idx <= 6'd0;
              state     <= S_TRACE;
            end else begin
              b_idx    <= b_idx + 5'd1;
              base_idx <= ( (b_idx + 5'd1) * W );
              M_curr[0] <= $signed({27'd0,(b_idx + 5'd1)}) * GAP;
              a_idx   <= 5'd1;
              state   <= S_DP_ROW;
            end
          end
          i <= i + 6'd1;
        end

        // Traceback: while (a>0 || b>0)
        S_TRACE: begin
          if (a_idx==5'd0 && b_idx==5'd0) begin
            state <= S_FILL_A;
          end else begin
            reg [7:0] rbase;
            reg [7:0] tag;
            rbase = b_idx * W[7:0];
            tag   = ptr_mem[rbase + a_idx];
            if (a_idx!=5'd0 && b_idx!=5'd0 && tag==ALIGN_C) begin
              alignedA[a_str_idx] <= seqa[a_idx-1];
              alignedB[b_str_idx] <= seqb[b_idx-1];
              a_idx <= a_idx - 5'd1;
              b_idx <= b_idx - 5'd1;
              a_str_idx <= a_str_idx + 6'd1;
              b_str_idx <= b_str_idx + 6'd1;
            end else if (a_idx!=5'd0 && (tag==SKIPB_C || b_idx==5'd0)) begin
              alignedA[a_str_idx] <= seqa[a_idx-1];
              alignedB[b_str_idx] <= DASH_C;
              a_idx <= a_idx - 5'd1;
              a_str_idx <= a_str_idx + 6'd1;
              b_str_idx <= b_str_idx + 6'd1;
            end else begin
              alignedA[a_str_idx] <= DASH_C;
              alignedB[b_str_idx] <= (b_idx!=5'd0) ? seqb[b_idx-1] : 8'd0;
              if (b_idx!=5'd0) b_idx <= b_idx - 5'd1;
              a_str_idx <= a_str_idx + 6'd1;
              b_str_idx <= b_str_idx + 6'd1;
            end
          end
        end

        // Fill remaining with '_'
        S_FILL_A: begin
          if (a_str_idx < (ALEN+BLEN)) begin
            alignedA[a_str_idx] <= UNDERSCORE_C;
            a_str_idx <= a_str_idx + 6'd1;
          end else begin
            state <= S_FILL_B;
          end
        end

        S_FILL_B: begin
          if (b_str_idx < (ALEN+BLEN)) begin
            alignedB[b_str_idx] <= UNDERSCORE_C;
            b_str_idx <= b_str_idx + 6'd1;
          end else begin
            state <= S_OUTCPY;
            i     <= 6'd0;
          end
        end

        // Copy aligned buffers to outputs (20 cycles)
        S_OUTCPY: begin
          case (i)
            6'd0:  begin ALIGA0  <= alignedA[0];  ALIGB0  <= alignedB[0];  end
            6'd1:  begin ALIGA1  <= alignedA[1];  ALIGB1  <= alignedB[1];  end
            6'd2:  begin ALIGA2  <= alignedA[2];  ALIGB2  <= alignedB[2];  end
            6'd3:  begin ALIGA3  <= alignedA[3];  ALIGB3  <= alignedB[3];  end
            6'd4:  begin ALIGA4  <= alignedA[4];  ALIGB4  <= alignedB[4];  end
            6'd5:  begin ALIGA5  <= alignedA[5];  ALIGB5  <= alignedB[5];  end
            6'd6:  begin ALIGA6  <= alignedA[6];  ALIGB6  <= alignedB[6];  end
            6'd7:  begin ALIGA7  <= alignedA[7];  ALIGB7  <= alignedB[7];  end
            6'd8:  begin ALIGA8  <= alignedA[8];  ALIGB8  <= alignedB[8];  end
            6'd9:  begin ALIGA9  <= alignedA[9];  ALIGB9  <= alignedB[9];  end
            6'd10: begin ALIGA10 <= alignedA[10]; ALIGB10 <= alignedB[10]; end
            6'd11: begin ALIGA11 <= alignedA[11]; ALIGB11 <= alignedB[11]; end
            6'd12: begin ALIGA12 <= alignedA[12]; ALIGB12 <= alignedB[12]; end
            6'd13: begin ALIGA13 <= alignedA[13]; ALIGB13 <= alignedB[13]; end
            6'd14: begin ALIGA14 <= alignedA[14]; ALIGB14 <= alignedB[14]; end
            6'd15: begin ALIGA15 <= alignedA[15]; ALIGB15 <= alignedB[15]; end
            6'd16: begin ALIGA16 <= alignedA[16]; ALIGB16 <= alignedB[16]; end
            6'd17: begin ALIGA17 <= alignedA[17]; ALIGB17 <= alignedB[17]; end
            6'd18: begin ALIGA18 <= alignedA[18]; ALIGB18 <= alignedB[18]; end
            6'd19: begin ALIGA19 <= alignedA[19]; ALIGB19 <= alignedB[19]; end
            default: ;
          endcase
          if (i == 6'd19) begin
            done  <= 1'b1;
            state <= S_DONE;
          end
          i <= i + 6'd1;
        end

        S_DONE: begin
          done  <= 1'b0;
          state <= S_IDLE;
        end

        default: state <= S_IDLE;
      endcase
    end
  end

endmodule
