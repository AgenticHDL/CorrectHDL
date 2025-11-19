`timescale 1ns/1ps
module aes_concat (
  input          clk,
  input          rst_n,
  input          start,           // one-cycle pulse
  input  [255:0] key_in,          // 256-bit key (k[0] is MSB byte)
  input  [127:0] block_in,        // 128-bit plaintext (buf[0] is MSB byte)
  output reg [127:0] block_out,   // 128-bit ciphertext
  output reg     done             // one-cycle pulse when valid
);
  function [7:0] xtime;
    input [7:0] x; begin xtime = x[7] ? ((x<<1)^8'h1b) : (x<<1); end
  endfunction
  function [7:0] Ffunc;
    input [7:0] x; begin Ffunc = x[7] ? ((x<<1)^8'h1b) : (x<<1); end
  endfunction
  reg [7:0] state_b [0:15];   // current 128-bit state
  reg [7:0] key_b   [0:31];   // rolling 256-bit round-key context
  reg [7:0] rcon;
  reg [3:0] round_i;          // 1..13
  reg       is_final;
  reg [4:0] idx;              // 0..31 generic
  reg [1:0] col;              // 0..3 (MixColumns column)
  reg [1:0] mphase;           // 0..3 (byte within the column)
  reg [1:0] sh_stage;         // 0..3 serialized ShiftRows stages
  reg [2:0] sh_step;          // step inside a stage
  reg [7:0] tmp;
  reg [7:0] a,b,c,d;          // MixColumns column bytes
  reg [7:0] t_rot0,t_rot1,t_rot2,t_rot3; // S(k29..k28)
  reg [7:0] t_mid0,t_mid1,t_mid2,t_mid3; // S(k12..k15)
  function [7:0] sbox_fn;
    input [7:0] x;
    reg [7:0] y;
    reg x0,x1,x2,x3,x4,x5,x6,x7;
    reg y0,y1,y2,y3,y4,y5,y6,y7;
    reg a0,a1,a2,a3,b0,b1,b2,b3;
    reg c0,c1,c2,c3,d0,d1,d2,d3;
    reg e0,e1,e2,e3,f0,f1,f2,f3;
    reg g0,g1,g2,g3,h0,h1,h2,h3;
    reg p0,p1,p2,p3,q0,q1,q2,q3;
    reg z0,z1,z2,z3,z4,z5,z6,z7;
    begin
      x7=x[7]; x6=x[6]; x5=x[5]; x4=x[4]; x3=x[3]; x2=x[2]; x1=x[1]; x0=x[0];
      y0 = x0 ^ x3 ^ x5 ^ x6;
      y1 = x0 ^ x1 ^ x2 ^ x3 ^ x5;
      y2 = x0 ^ x1 ^ x3 ^ x4 ^ x7;
      y3 = x0 ^ x1 ^ x2 ^ x5 ^ x7;
      y4 = x1 ^ x2 ^ x3 ^ x7;
      y5 = x2 ^ x5 ^ x6 ^ x7;
      y6 = x0 ^ x2 ^ x6 ^ x7;
      y7 = x1 ^ x4 ^ x6 ^ x7;
      a3 = y7 ^ y5 ^ y4 ^ y2;
      a2 = y6 ^ y4 ^ y1 ^ y0;
      a1 = y7 ^ y6 ^ y3 ^ y2 ^ y1;
      a0 = y6 ^ y5 ^ y2 ^ y1 ^ y0;
      b3 = y7 ^ y5 ^ y3 ^ y1;
      b2 = y6 ^ y4 ^ y2 ^ y0;
      b1 = y5 ^ y4 ^ y3 ^ y2 ^ y1;
      b0 = y7 ^ y6 ^ y5 ^ y4 ^ y0;
      c3 = a3 ^ a1; c2 = a2 ^ a0; c1 = a3; c0 = a2;   // a^2
      d3 = b3 ^ b1; d2 = b2 ^ b0; d1 = b3; d0 = b2;   // b^2
      e3 = c3 ^ c0; e2 = c2; e1 = c1; e0 = c0;        // λ*c
      f3 = d3 ^ d0; f2 = d2; f1 = d1; f0 = d0;        // λ*d
      begin
        reg m0,m1,m2,m3,m4,m5,m6;
        m0=(a0&b0); m1=(a1&b1); m2=(a2&b2); m3=(a3&b3);
        m4=(a0&b1)^(a1&b0);
        m5=(a0&b2)^(a2&b0)^(a1&b1);
        m6=(a0&b3)^(a3&b0)^(a1&b2)^(a2&b1);
        g0=m0^m5; g1=m4^m6^m0; g2=m1^m5^m3; g3=m2^m6;
      end
      h0=e0^g0^f0; h1=e1^g1^f1; h2=e2^g2^f2; h3=e3^g3^f3;
      begin
        reg u0,u1,u2,u3,v0,v1,v2,v3,w0,w1,w2,w3,s0,s1,s2,s3;
        u3=h3^h1; u2=h2^h0; u1=h3; u0=h2; // u=h^2
        begin
          reg n0,n1,n2,n3,n4,n5,n6;
          n0=(u0&h0); n1=(u1&h1); n2=(u2&h2); n3=(u3&h3);
          n4=(u0&h1)^(u1&h0);
          n5=(u0&h2)^(u2&h0)^(u1&h1);
          n6=(u0&h3)^(u3&h0)^(u1&h2)^(u2&h1);
          v0=n0^n5; v1=n4^n6^n0; v2=n1^n5^n3; v3=n2^n6;
        end
        w3=v3^v1; w2=v2^v0; w1=v3; w0=v2; // w=v^2
        begin
          reg r0,r1,r2,r3,r4,r5,r6;
          r0=(w0&h0); r1=(w1&h1); r2=(w2&h2); r3=(w3&h3);
          r4=(w0&h1)^(w1&h0);
          r5=(w0&h2)^(w2&h0)^(w1&h1);
          r6=(w0&h3)^(w3&h0)^(w1&h2)^(w2&h1);
          s0=r0^r5; s1=r4^r6^r0; s2=r1^r5^r3; s3=r2^r6;
          q0=s0; q1=s1; q2=s2; q3=s3;
        end
      end
      begin : MUL_INV_BACK
        reg r0,r1,r2,r3,s0_,s1_,s2_,s3_;
        begin
          reg m0,m1,m2,m3,m4,m5,m6;
          m0=(a0&q0); m1=(a1&q1); m2=(a2&q2); m3=(a3&q3);
          m4=(a0&q1)^(a1&q0);
          m5=(a0&q2)^(a2&q0)^(a1&q1);
          m6=(a0&q3)^(a3&q0)^(a1&q2)^(a2&q1);
          r0=m0^m5; r1=m4^m6^m0; r2=m1^m5^m3; r3=m2^m6;
        end
        begin
          reg n0,n1,n2,n3,n4,n5,n6;
          n0=(b0&q0); n1=(b1&q1); n2=(b2&q2); n3=(b3&q3);
          n4=(b0&q1)^(b1&q0);
          n5=(b0&q2)^(b2&q0)^(b1&q1);
          n6=(b0&q3)^(b3&q0)^(b1&q2)^(b2&q1);
          s0_=n0^n5; s1_=n4^n6^n0; s2_=n1^n5^n3; s3_=n2^n6;
        end
        p3 = r3 ^ s0_; p2 = r2 ^ s3_; p1 = r1 ^ s2_; p0 = r0 ^ s1_;
        q3 = r0 ^ s2_; q2 = r3 ^ s1_; q1 = r2 ^ s0_; q0 = r1 ^ s3_;
      end
      z7 = p3 ^ p1 ^ q3 ^ q2 ^ q0;
      z6 = p3 ^ p2 ^ q2 ^ q1 ^ q0;
      z5 = p3 ^ p2 ^ p0 ^ q3 ^ q2 ^ q1;
      z4 = p2 ^ p1 ^ q3 ^ q1 ^ q0;
      z3 = p3 ^ p1 ^ p0 ^ q3 ^ q2 ^ q0;
      z2 = p3 ^ p2 ^ p0 ^ q2 ^ q1;
      z1 = p2 ^ p1 ^ p0 ^ q3 ^ q1 ^ q0;
      z0 = p3 ^ p1 ^ q3 ^ q2 ^ q1;
      y = {z7, z6^1'b1, z5^1'b1, z4, z3, z2, z1^1'b1, z0^1'b1}; // +0x63
      sbox_fn = y;
    end
  endfunction
  localparam [5:0]
    S_IDLE        = 6'd0,
    S_INIT_ADD0   = 6'd1,   // initial AddRoundKey with key_b[0..15], 1B/cyc
    S_SUB         = 6'd2,   // 16 cycles, 1B/cyc
    S_SHIFT       = 6'd3,   // serialized ShiftRows
    S_MIX_LOAD    = 6'd4,   // load one column a,b,c,d
    S_MIX_BYTE    = 6'd5,   // write back a column bytes in 4 cycles
    S_ADD16       = 6'd6,   // addRoundKey with key_b[16..31], 1B/cyc (odd rounds)
    S_EXP1_SBOX   = 6'd7,   // S(k29..k28), 4 cycles
    S_EXP1_AP0    = 6'd8,   // k[0] ^= t_rot0 ^ rcon
    S_EXP1_AP1    = 6'd9,
    S_EXP1_AP2    = 6'd10,
    S_EXP1_AP3    = 6'd11,  // rcon <= F(rcon)
    S_EXP1_PROP   = 6'd12,  // i=4..15: k[i] ^= k[i-4], 1B/cyc
    S_EXP2_SBOX   = 6'd13,  // S(k12..15), 4 cycles
    S_EXP2_AP0    = 6'd14,
    S_EXP2_AP1    = 6'd15,
    S_EXP2_AP2    = 6'd16,
    S_EXP2_AP3    = 6'd17,
    S_EXP2_PROP   = 6'd18,  // i=20..31: k[i] ^= k[i-4], 1B/cyc
    S_ADD0        = 6'd19,  // addRoundKey with key_b[0..15], 1B/cyc
    S_DONE        = 6'd20;

  reg [5:0] state;

  integer k;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      done      <= 1'b0;
      block_out <= 128'd0;
      rcon      <= 8'h01;
      round_i   <= 4'd0;
      is_final  <= 1'b0;
      idx       <= 5'd0;
      col       <= 2'd0;
      mphase    <= 2'd0;
      sh_stage  <= 2'd0;
      sh_step   <= 3'd0;
      state     <= S_IDLE;
      // clear memories
      for(k=0;k<16;k=k+1) state_b[k] <= 8'd0;
      for(k=0;k<32;k=k+1) key_b[k]   <= 8'd0;
    end else begin
      done <= 1'b0;

      case(state)
        S_IDLE: begin
          if (start) begin
            // load state (big-endian bytes)
            state_b[0]  <= block_in[127:120]; state_b[1]  <= block_in[119:112];
            state_b[2]  <= block_in[111:104]; state_b[3]  <= block_in[103:96];
            state_b[4]  <= block_in[95:88];   state_b[5]  <= block_in[87:80];
            state_b[6]  <= block_in[79:72];   state_b[7]  <= block_in[71:64];
            state_b[8]  <= block_in[63:56];   state_b[9]  <= block_in[55:48];
            state_b[10] <= block_in[47:40];   state_b[11] <= block_in[39:32];
            state_b[12] <= block_in[31:24];   state_b[13] <= block_in[23:16];
            state_b[14] <= block_in[15:8];    state_b[15] <= block_in[7:0];
            // load key bytes
            key_b[0]  <= key_in[255:248]; key_b[1]  <= key_in[247:240];
            key_b[2]  <= key_in[239:232]; key_b[3]  <= key_in[231:224];
            key_b[4]  <= key_in[223:216]; key_b[5]  <= key_in[215:208];
            key_b[6]  <= key_in[207:200]; key_b[7]  <= key_in[199:192];
            key_b[8]  <= key_in[191:184]; key_b[9]  <= key_in[183:176];
            key_b[10] <= key_in[175:168]; key_b[11] <= key_in[167:160];
            key_b[12] <= key_in[159:152]; key_b[13] <= key_in[151:144];
            key_b[14] <= key_in[143:136]; key_b[15] <= key_in[135:128];
            key_b[16] <= key_in[127:120]; key_b[17] <= key_in[119:112];
            key_b[18] <= key_in[111:104]; key_b[19] <= key_in[103:96];
            key_b[20] <= key_in[95:88];   key_b[21] <= key_in[87:80];
            key_b[22] <= key_in[79:72];   key_b[23] <= key_in[71:64];
            key_b[24] <= key_in[63:56];   key_b[25] <= key_in[55:48];
            key_b[26] <= key_in[47:40];   key_b[27] <= key_in[39:32];
            key_b[28] <= key_in[31:24];   key_b[29] <= key_in[23:16];
            key_b[30] <= key_in[15:8];    key_b[31] <= key_in[7:0];

            rcon    <= 8'h01;
            round_i <= 4'd1;
            idx     <= 5'd0;
            state   <= S_INIT_ADD0;
          end
        end

        // initial AddRoundKey with key_b[0..15], byte-serial
        S_INIT_ADD0: begin
          if (idx < 5'd16) begin
            state_b[idx] <= state_b[idx] ^ key_b[idx];
            idx <= idx + 5'd1;
          end else begin
            idx   <= 5'd0;
            state <= S_SUB;
          end
        end

        // SubBytes: 16 cycles, 1 byte per cycle
        S_SUB: begin
          if (idx < 5'd16) begin
            state_b[idx] <= sbox_fn(state_b[idx]);
            idx <= idx + 5'd1;
          end else begin
            idx      <= 5'd0;
            sh_stage <= 2'd0;
            sh_step  <= 3'd0;
            state    <= S_SHIFT;
          end
        end

        // ShiftRows: serialized in four small steps
        S_SHIFT: begin
          case (sh_stage)
            2'd0: begin // ring [1,5,9,13] left rotate by 1
              case (sh_step)
                3'd0: begin tmp = state_b[1];  state_b[1]  <= state_b[5];  sh_step <= 3'd1; end
                3'd1: begin                     state_b[5]  <= state_b[9];  sh_step <= 3'd2; end
                3'd2: begin                     state_b[9]  <= state_b[13]; sh_step <= 3'd3; end
                3'd3: begin                     state_b[13] <= tmp;         sh_step <= 3'd0; sh_stage <= 2'd1; end
              endcase
            end
            2'd1: begin // swap 10 <-> 2
              tmp = state_b[10]; state_b[10] <= state_b[2]; state_b[2] <= tmp;
              sh_stage <= 2'd2;
            end
            2'd2: begin // ring [3,15,11,7] left rotate by 3 (== right by 1)
              case (sh_step)
                3'd0: begin tmp = state_b[3];  state_b[3]  <= state_b[15]; sh_step <= 3'd1; end
                3'd1: begin                     state_b[15] <= state_b[11]; sh_step <= 3'd2; end
                3'd2: begin                     state_b[11] <= state_b[7];  sh_step <= 3'd3; end
                3'd3: begin                     state_b[7]  <= tmp;         sh_step <= 3'd0; sh_stage <= 2'd3; end
              endcase
            end
            2'd3: begin // swap 14 <-> 6
              tmp = state_b[14]; state_b[14] <= state_b[6]; state_b[6] <= tmp;
              if (round_i == 4'd13) begin
                is_final <= 1'b1;
                idx      <= 5'd0;
                state    <= S_EXP1_SBOX; // final also expands then add lower half
              end else begin
                col   <= 2'd0;
                state <= S_MIX_LOAD;
              end
            end
          endcase
        end
        S_MIX_LOAD: begin
          // read old column into temps (blocking OK)
          a = state_b[(col<<2)+0];
          b = state_b[(col<<2)+1];
          c = state_b[(col<<2)+2];
          d = state_b[(col<<2)+3];
          mphase <= 2'd0;
          state  <= S_MIX_BYTE;
        end
        S_MIX_BYTE: begin
          case (mphase)
            2'd0: begin
              state_b[(col<<2)+0] <= (xtime(a) ^ xtime(b) ^ b ^ c ^ d); // 2a+3b+c+d
              mphase <= 2'd1;
            end
            2'd1: begin
              state_b[(col<<2)+1] <= (a ^ xtime(b) ^ xtime(c) ^ c ^ d); // a+2b+3c+d
              mphase <= 2'd2;
            end
            2'd2: begin
              state_b[(col<<2)+2] <= (a ^ b ^ xtime(c) ^ xtime(d) ^ d); // a+b+2c+3d
              mphase <= 2'd3;
            end
            2'd3: begin
              state_b[(col<<2)+3] <= (xtime(a) ^ a ^ b ^ c ^ xtime(d)); // 3a+b+c+2d
              if (col != 2'd3) begin
                col   <= col + 2'd1;
                state <= S_MIX_LOAD;
              end else begin
                idx <= 5'd0;
                if (round_i[0]==1'b1) state <= S_ADD16;     // odd round: add upper half
                else                   state <= S_EXP1_SBOX; // even: expand then add lower half
              end
            end
          endcase
        end

        // addRoundKey with key_b[16..31] (odd rounds), 1B/cycle
        S_ADD16: begin
          if (idx < 5'd16) begin
            state_b[idx] <= state_b[idx] ^ key_b[16+idx];
            idx <= idx + 5'd1;
          end else begin
            round_i <= round_i + 4'd1;
            state   <= S_SUB;
            idx     <= 5'd0;
          end
        end
        S_EXP1_SBOX: begin
          case (idx[1:0])
            2'd0: t_rot0 = sbox_fn(key_b[29]);
            2'd1: t_rot1 = sbox_fn(key_b[30]);
            2'd2: t_rot2 = sbox_fn(key_b[31]);
            2'd3: t_rot3 = sbox_fn(key_b[28]);
          endcase
          if (idx[1:0]==2'd3) begin idx <= 5'd0; state <= S_EXP1_AP0; end
          else idx <= idx + 5'd1;
        end
        S_EXP1_AP0: begin key_b[0]  <= key_b[0]  ^ t_rot0 ^ rcon; rcon <= Ffunc(rcon); state <= S_EXP1_AP1; end
        S_EXP1_AP1: begin key_b[1]  <= key_b[1]  ^ t_rot1;        state <= S_EXP1_AP2; end
        S_EXP1_AP2: begin key_b[2]  <= key_b[2]  ^ t_rot2;        state <= S_EXP1_AP3; end
        S_EXP1_AP3: begin key_b[3]  <= key_b[3]  ^ t_rot3;        idx   <= 5'd4; state <= S_EXP1_PROP; end
        S_EXP1_PROP: begin
          key_b[idx] <= key_b[idx] ^ key_b[idx-5'd4];
          if (idx == 5'd15) begin idx <= 5'd0; state <= S_EXP2_SBOX; end
          else idx <= idx + 5'd1;
        end
        S_EXP2_SBOX: begin
          case (idx[1:0])
            2'd0: t_mid0 = sbox_fn(key_b[12]);
            2'd1: t_mid1 = sbox_fn(key_b[13]);
            2'd2: t_mid2 = sbox_fn(key_b[14]);
            2'd3: t_mid3 = sbox_fn(key_b[15]);
          endcase
          if (idx[1:0]==2'd3) begin idx <= 5'd0; state <= S_EXP2_AP0; end
          else idx <= idx + 5'd1;
        end
        S_EXP2_AP0: begin key_b[16] <= key_b[16] ^ t_mid0; state <= S_EXP2_AP1; end
        S_EXP2_AP1: begin key_b[17] <= key_b[17] ^ t_mid1; state <= S_EXP2_AP2; end
        S_EXP2_AP2: begin key_b[18] <= key_b[18] ^ t_mid2; state <= S_EXP2_AP3; end
        S_EXP2_AP3: begin key_b[19] <= key_b[19] ^ t_mid3; idx   <= 5'd20; state <= S_EXP2_PROP; end
        S_EXP2_PROP: begin
          key_b[idx] <= key_b[idx] ^ key_b[idx-5'd4];
          if (idx == 5'd31) begin
            idx   <= 5'd0;
            state <= S_ADD0;     // even & final both go add lower half next
          end else idx <= idx + 5'd1;
        end
        S_ADD0: begin
          if (idx < 5'd16) begin
            state_b[idx] <= state_b[idx] ^ key_b[idx];
            idx <= idx + 5'd1;
          end else begin
            if (is_final) begin
              block_out <= { state_b[0],state_b[1],state_b[2],state_b[3],
                             state_b[4],state_b[5],state_b[6],state_b[7],
                             state_b[8],state_b[9],state_b[10],state_b[11],
                             state_b[12],state_b[13],state_b[14],state_b[15] };
              done      <= 1'b1;
              is_final  <= 1'b0;
              state     <= S_DONE;
            end else begin
              round_i <= round_i + 4'd1;
              state   <= S_SUB;
              idx     <= 5'd0;
            end
          end
        end
        S_DONE: begin
          state <= S_IDLE;
        end
        default: state <= S_IDLE;
      endcase
    end
  end

endmodule
