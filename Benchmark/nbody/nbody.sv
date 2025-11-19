

// nAtoms=32, maxNeighbors=4

`timescale 1ns/1ps

module md_kernel #
(
  parameter N_ATOMS = 32,
  parameter MAX_NEI = 4
)
(
  input  wire               clk,
  input  wire               rst,     
  input  wire               start,   


  input  wire               nl_we,
  input  wire [6:0]         nl_waddr,   // 0..127
  input  wire [5:0]         nl_wdata,   // 0..31


  output reg                out_we,
  output reg  [5:0]         out_addr,   // 0..31
  output reg  signed [15:0] out_fx,
  output reg  signed [15:0] out_fy,
  output reg  signed [15:0] out_fz,

  output reg                done        
);

  // ---------------------------
  // NL RAM：128 × 6bit
  // ---------------------------
  reg [5:0] nl_mem [0:(N_ATOMS*MAX_NEI-1)];
  always @(posedge clk) begin
    if (nl_we) nl_mem[nl_waddr] <= nl_wdata;
  end

  // ---------------------------
  // ---------------------------
  localparam signed [15:0] INV_1   = 16'sd256; // 1.0
  localparam signed [15:0] INV_4   = 16'sd64;  // 0.25
  localparam signed [15:0] INV_16  = 16'sd16;  // 0.0625
  localparam signed [15:0] INV_64  = 16'sd4;   // 0.015625

  localparam signed [15:0] LJ1 = 16'sd384;     // 1.5
  localparam signed [15:0] LJ2 = 16'sd512;     // 2.0

  // ---------------------------
  // ---------------------------
  function [15:0] mul_q8;
    input signed [15:0] a;
    input signed [15:0] b;
    reg   signed [31:0] p;
    reg   signed [31:0] shr;
    reg   signed [31:0] absp;
  begin
    p = a * b;
    if (p >= 0)
      shr = p >>> 8;           
    else begin
      absp = -p;
      shr  = -(absp >>> 8);    
    end
    mul_q8 = shr[15:0];        
  end
  endfunction

  // ---------------------------
  // FSM
  // ---------------------------
  localparam S_IDLE   = 4'd0;
  localparam S_INITI  = 4'd1;
  localparam S_INITJ  = 4'd2;
  localparam S_PREP   = 4'd3;
  localparam S_MUL1   = 4'd4;
  localparam S_MUL2   = 4'd5;
  localparam S_MUL3   = 4'd6;
  localparam S_MUL4   = 4'd7;
  localparam S_MUL5   = 4'd8;
  localparam S_MUL6   = 4'd9;
  localparam S_NEXTJ  = 4'd10;
  localparam S_OUT    = 4'd11;
  localparam S_DONE   = 4'd12;

  reg [3:0]  st, st_n;

  reg [5:0]  i_cnt;           // 0..31
  reg [2:0]  j_cnt;           // 0..3

  reg signed [15:0] fx_acc, fy_acc, fz_acc;

  // 中间寄存器（跨拍）
  reg  [6:0]          nl_addr_cur;
  reg  [5:0]          jidx_u;
  reg  signed [7:0]   dx_r;          // -31..31
  reg  signed [15:0]  delx_q8_r;
  reg  signed [15:0]  r2inv_q8_r;
  reg  signed [15:0]  t1_q8_r;
  reg  signed [15:0]  r6inv_q8_r;
  reg  signed [15:0]  lj1r6_q8_r;
  reg  signed [15:0]  t4_q8_r;
  reg  signed [15:0]  potential_q8_r;
  reg  signed [15:0]  force_q8_r;

  // 组合 next-state
  always @* begin
    st_n = st;
    case (st)
      S_IDLE  : st_n = start ? S_INITI : S_IDLE;
      S_INITI : st_n = S_INITJ;
      S_INITJ : st_n = S_PREP;
      S_PREP  : st_n = S_MUL1;
      S_MUL1  : st_n = S_MUL2;
      S_MUL2  : st_n = S_MUL3;
      S_MUL3  : st_n = S_MUL4;
      S_MUL4  : st_n = S_MUL5;
      S_MUL5  : st_n = S_MUL6;
      S_MUL6  : st_n = S_NEXTJ;
      S_NEXTJ : st_n = (j_cnt == (MAX_NEI-1)) ? S_OUT : S_PREP;
      S_OUT   : st_n = (i_cnt == (N_ATOMS-1)) ? S_DONE : S_INITJ;
      S_DONE  : st_n = S_IDLE;
      default : st_n = S_IDLE;
    endcase
  end


  always @(posedge clk) begin
    if (rst) begin
      st <= S_IDLE;
      i_cnt <= 6'd0;
      j_cnt <= 3'd0;

      fx_acc <= 16'sd0;
      fy_acc <= 16'sd0;
      fz_acc <= 16'sd0;

      out_we <= 1'b0;
      out_addr <= 6'd0;
      out_fx <= 16'sd0;
      out_fy <= 16'sd0;
      out_fz <= 16'sd0;
      done   <= 1'b0;

      nl_addr_cur <= 7'd0;
      jidx_u      <= 6'd0;
      dx_r        <= 8'sd0;
      delx_q8_r   <= 16'sd0;

      r2inv_q8_r  <= 16'sd0;
      t1_q8_r     <= 16'sd0;
      r6inv_q8_r  <= 16'sd0;
      lj1r6_q8_r  <= 16'sd0;
      
      t4_q8_r     <= 16'sd0;
      potential_q8_r <= 16'sd0;
      force_q8_r  <= 16'sd0;
    end else begin
      st     <= st_n;
      out_we <= 1'b0;
      done   <= 1'b0;

      case (st)
        S_IDLE: begin

        end

        S_INITI: begin
          i_cnt <= 6'd0;
        end

        S_INITJ: begin
          j_cnt  <= 3'd0;
          fx_acc <= 16'sd0;
          fy_acc <= 16'sd0;
          fz_acc <= 16'sd0;
        end


        S_PREP: begin
          integer i_s, j_s;
          integer dx_tmp;
          integer adx_tmp;
          reg signed [15:0] r2inv_tmp;
          reg signed [15:0] delx_tmp_q8;

          i_s = i_cnt;
          j_s = nl_mem[(i_cnt * MAX_NEI) + j_cnt]; // 组合读
          jidx_u <= j_s[5:0];

          // dx = i - jidx
          dx_tmp = i_s - j_s;


          if (dx_tmp > 16)       dx_tmp = dx_tmp - 32;
          else if (dx_tmp < -16) dx_tmp = dx_tmp + 32;

          delx_tmp_q8 = $signed(dx_tmp) <<< 8;
          adx_tmp     = (dx_tmp < 0) ? -dx_tmp : dx_tmp;

          // r2inv LUT
          if      (adx_tmp == 1) r2inv_tmp = INV_1;
          else if (adx_tmp == 2) r2inv_tmp = INV_4;
          else if (adx_tmp == 4) r2inv_tmp = INV_16;
          else if (adx_tmp == 8) r2inv_tmp = INV_64;
          else                   r2inv_tmp = 16'sd0;

          dx_r       <= dx_tmp[7:0];
          delx_q8_r  <= delx_tmp_q8;
          r2inv_q8_r <= r2inv_tmp;
        end

        S_MUL1: begin
          t1_q8_r <= mul_q8(r2inv_q8_r, r2inv_q8_r);
        end

        S_MUL2: begin
          r6inv_q8_r <= mul_q8(t1_q8_r, r2inv_q8_r);
        end

        S_MUL3: begin
          lj1r6_q8_r <= mul_q8(LJ1, r6inv_q8_r);
        end

        S_MUL4: begin
          t4_q8_r        <= lj1r6_q8_r - LJ2;
          potential_q8_r <= mul_q8(r6inv_q8_r, lj1r6_q8_r - LJ2);
        end

        S_MUL5: begin
          force_q8_r <= mul_q8(r2inv_q8_r, potential_q8_r);
        end

        S_MUL6: begin

          fx_acc <= fx_acc + mul_q8(delx_q8_r, force_q8_r);
        end

        S_NEXTJ: begin
          if (j_cnt != (MAX_NEI-1))
            j_cnt <= j_cnt + 3'd1;
        end

        S_OUT: begin
          out_we   <= 1'b1;
          out_addr <= i_cnt[5:0];
          out_fx   <= fx_acc;
          out_fy   <= 16'sd0;
          out_fz   <= 16'sd0;

          if (i_cnt != (N_ATOMS-1)) begin
            i_cnt  <= i_cnt + 6'd1;
            j_cnt  <= 3'd0;
            fx_acc <= 16'sd0;
            fy_acc <= 16'sd0;
            fz_acc <= 16'sd0;
          end
        end

        S_DONE: begin
          done <= 1'b1;
        end

        default: ;
      endcase
    end
  end

endmodule
