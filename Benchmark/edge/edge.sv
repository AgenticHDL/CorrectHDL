// kernel_deriche_min.v  (Verilog-2001)
// Resource-shared, single-multiplier, sequential datapath.
// Fixed-point: signed Q(4,8) => 12-bit total, 4 integer (incl. sign), 8 fractional.

`timescale 1ns/1ps

module kernel_deriche
#(
  parameter W = 8,
  parameter H = 8,
  parameter BITS  = 12,
  parameter IBITS = 4,
  parameter FBITS = (BITS-IBITS)
)(
  input  wire                   clk,
  input  wire                   rst,
  input  wire                   start,
  input  wire signed [BITS-1:0] alpha,       // kept for interface compatibility (not used; constants pre-quantized for alpha=0.25)

  input  wire                   in_we,
  input  wire        [5:0]      in_addr,
  input  wire signed [BITS-1:0] in_wdata,

  input  wire        [5:0]      out_addr,
  output reg  signed [BITS-1:0] out_rdata,

  output reg                    busy,
  output reg                    done
);

  // Q(4,8) constants for alpha = 0.25 (rounded to nearest)
  // k  = 0.0625    ->  16
  // a2 = -0.03651  ->  -9
  // a3 = 0.06084   ->  16
  // a4 = -0.03791  -> -10
  // b1 = 0.840896  -> 215
  // b2 = -0.606531 -> -155
  // c1 = c2 = 1.0  -> 256
  localparam signed [BITS-1:0] A1 = 12'sd16;
  localparam signed [BITS-1:0] A2 = -12'sd9;
  localparam signed [BITS-1:0] A3 = 12'sd16;
  localparam signed [BITS-1:0] A4 = -12'sd10;
  localparam signed [BITS-1:0] A5 = 12'sd16;
  localparam signed [BITS-1:0] A6 = -12'sd9;
  localparam signed [BITS-1:0] A7 = 12'sd16;
  localparam signed [BITS-1:0] A8 = -12'sd10;
  localparam signed [BITS-1:0] B1 = 12'sd215;
  localparam signed [BITS-1:0] B2 = -12'sd155;
  localparam signed [BITS-1:0] C1 = 12'sd256;  // == 1.0
  localparam signed [BITS-1:0] C2 = 12'sd256;  // == 1.0

  localparam signed [BITS-1:0] FX_ZERO = {BITS{1'b0}};

  // Memories (64 words each)
  reg signed [BITS-1:0] imgIn_mem [0:W*H-1];
  reg signed [BITS-1:0] y1_mem    [0:W*H-1];
  reg signed [BITS-1:0] y2_mem    [0:W*H-1];
  reg signed [BITS-1:0] tmp_mem   [0:W*H-1];
  reg signed [BITS-1:0] out_mem   [0:W*H-1];

  // Host ports
  always @(posedge clk) begin
    if (in_we && !busy) begin
      imgIn_mem[in_addr] <= in_wdata;
    end
  end

  always @(posedge clk) begin
    out_rdata <= out_mem[out_addr];
  end

  // Single shared multiplier (only one '*' in the whole design)
  reg  signed [BITS-1:0] mul_a, mul_b;
  wire signed [(2*BITS)-1:0] mul_p  = mul_a * mul_b;
  wire signed [(2*BITS)-1:0] mul_pr = mul_p + {{(2*BITS-FBITS-1){1'b0}}, 1'b1, {FBITS-1{1'b0}}}; // + 0.5 ulp
  wire signed [BITS-1:0]     mul_q  = mul_pr >>> FBITS;
  reg  signed [BITS-1:0]     mul_q_reg;

  // Accumulator for sum of products
  reg  signed [BITS-1:0] acc;

  // Indices and micro-steps
  reg [2:0] i_row;
  reg [2:0] j_col;
  reg [2:0] phase; // 0..4 for MAC sequencing

  // Recurrences
  reg signed [BITS-1:0] xm1, ym1, ym2;
  reg signed [BITS-1:0] xp1, xp2, yp1, yp2;
  reg signed [BITS-1:0] tm1;
  reg signed [BITS-1:0] tp1, tp2;

  // FSM
  localparam S_IDLE       = 4'd0;
  localparam S_ROW_FWD    = 4'd1;
  localparam S_ROW_BWD    = 4'd2;
  localparam S_COMB1      = 4'd3;
  localparam S_COL_FWD    = 4'd4;
  localparam S_COL_BWD    = 4'd5;
  localparam S_COMB2      = 4'd6;
  localparam S_DONE       = 4'd7;

  reg [3:0] state, nstate;

  // Address concat helper
  wire [5:0] addr_ij = {i_row, j_col};

  // Next-state (simple)
  always @* begin
    nstate = state;
    case (state)
      S_IDLE    : nstate = start ? S_ROW_FWD : S_IDLE;
      S_ROW_FWD : nstate = (i_row==3'd7 && j_col==3'd7 && phase==3'd4) ? S_ROW_BWD : S_ROW_FWD;
      S_ROW_BWD : nstate = (i_row==3'd7 && j_col==3'd0 && phase==3'd4) ? S_COMB1   : S_ROW_BWD;
      S_COMB1   : nstate = (i_row==3'd7 && j_col==3'd7)               ? S_COL_FWD : S_COMB1;
      S_COL_FWD : nstate = (j_col==3'd7 && i_row==3'd7 && phase==3'd4) ? S_COL_BWD : S_COL_FWD;
      S_COL_BWD : nstate = (j_col==3'd7 && i_row==3'd0 && phase==3'd4) ? S_COMB2   : S_COL_BWD;
      S_COMB2   : nstate = (i_row==3'd7 && j_col==3'd7)               ? S_DONE    : S_COMB2;
      S_DONE    : nstate = S_IDLE;
      default   : nstate = S_IDLE;
    endcase
  end

  // Main sequential
  always @(posedge clk) begin
    if (rst) begin
      state    <= S_IDLE;
      busy     <= 1'b0;
      done     <= 1'b0;
      i_row    <= 3'd0;
      j_col    <= 3'd0;
      phase    <= 3'd0;
      xm1 <= FX_ZERO; ym1 <= FX_ZERO; ym2 <= FX_ZERO;
      xp1 <= FX_ZERO; xp2 <= FX_ZERO; yp1 <= FX_ZERO; yp2 <= FX_ZERO;
      tm1 <= FX_ZERO; tp1 <= FX_ZERO; tp2 <= FX_ZERO;
      mul_a <= FX_ZERO; mul_b <= FX_ZERO; mul_q_reg <= FX_ZERO;
      acc  <= FX_ZERO;
    end else begin
      state     <= nstate;
      mul_q_reg <= mul_q;
      done      <= 1'b0;

      case (state)
        S_IDLE: begin
          busy  <= 1'b0;
          if (start) begin
            busy   <= 1'b1;
            i_row  <= 3'd0;
            j_col  <= 3'd0;
            phase  <= 3'd0;
            xm1 <= FX_ZERO; ym1 <= FX_ZERO; ym2 <= FX_ZERO;
            xp1 <= FX_ZERO; xp2 <= FX_ZERO; yp1 <= FX_ZERO; yp2 <= FX_ZERO;
            tm1 <= FX_ZERO; tp1 <= FX_ZERO; tp2 <= FX_ZERO;
            acc <= FX_ZERO;
            mul_a <= FX_ZERO; mul_b <= FX_ZERO;
          end
        end

        // y1[i][j] = a1*img + a2*xm1 + b1*ym1 + b2*ym2
        S_ROW_FWD: begin
          if (phase == 3'd0) begin
            acc   <= FX_ZERO;
            mul_a <= A1;
            mul_b <= imgIn_mem[addr_ij];
            phase <= 3'd1;
          end else if (phase == 3'd1) begin
            acc   <= mul_q_reg;
            mul_a <= A2;
            mul_b <= xm1;
            phase <= 3'd2;
          end else if (phase == 3'd2) begin
            acc   <= acc + mul_q_reg;
            mul_a <= B1;
            mul_b <= ym1;
            phase <= 3'd3;
          end else if (phase == 3'd3) begin
            acc   <= acc + mul_q_reg;
            mul_a <= B2;
            mul_b <= ym2;
            phase <= 3'd4;
          end else begin
            acc                 <= acc + mul_q_reg;
            y1_mem[addr_ij]     <= acc + mul_q_reg;
            xm1                 <= imgIn_mem[addr_ij];
            ym2                 <= ym1;
            ym1                 <= acc + mul_q_reg;
            phase               <= 3'd0;
            if (j_col == 3'd7) begin
              j_col <= 3'd0;
              if (i_row == 3'd7) begin
                i_row <= 3'd7;
              end else begin
                i_row <= i_row + 3'd1;
                xm1   <= FX_ZERO; ym1 <= FX_ZERO; ym2 <= FX_ZERO;
              end
            end else begin
              j_col <= j_col + 3'd1;
            end
          end
        end

        // y2[i][j] = a3*xp1 + a4*xp2 + b1*yp1 + b2*yp2  (j from 7 downto 0)
        S_ROW_BWD: begin
          if (phase == 3'd0) begin
            if (i_row == 3'd0 && j_col == 3'd0) begin
              i_row <= 3'd0;
              j_col <= 3'd7;
              xp1 <= FX_ZERO; xp2 <= FX_ZERO; yp1 <= FX_ZERO; yp2 <= FX_ZERO;
            end
            acc   <= FX_ZERO;
            mul_a <= A3;
            mul_b <= xp1;
            phase <= 3'd1;
          end else if (phase == 3'd1) begin
            acc   <= mul_q_reg;
            mul_a <= A4;
            mul_b <= xp2;
            phase <= 3'd2;
          end else if (phase == 3'd2) begin
            acc   <= acc + mul_q_reg;
            mul_a <= B1;
            mul_b <= yp1;
            phase <= 3'd3;
          end else if (phase == 3'd3) begin
            acc   <= acc + mul_q_reg;
            mul_a <= B2;
            mul_b <= yp2;
            phase <= 3'd4;
          end else begin
            acc                 <= acc + mul_q_reg;
            y2_mem[addr_ij]     <= acc + mul_q_reg;
            xp2                 <= xp1;
            xp1                 <= imgIn_mem[addr_ij];
            yp2                 <= yp1;
            yp1                 <= acc + mul_q_reg;
            phase               <= 3'd0;
            if (j_col == 3'd0) begin
              j_col <= 3'd7;
              if (i_row == 3'd7) begin
                i_row <= 3'd7;
              end else begin
                i_row <= i_row + 3'd1;
                xp1 <= FX_ZERO; xp2 <= FX_ZERO; yp1 <= FX_ZERO; yp2 <= FX_ZERO;
              end
            end else begin
              j_col <= j_col - 3'd1;
            end
          end
        end

        // tmp = c1*(y1+y2) ; c1==1.0 -> tmp = y1 + y2
        S_COMB1: begin
          tmp_mem[addr_ij] <= y1_mem[addr_ij] + y2_mem[addr_ij];
          if (j_col == 3'd7) begin
            j_col <= 3'd0;
            if (i_row == 3'd7) begin
              i_row <= 3'd0;
            end else begin
              i_row <= i_row + 3'd1;
            end
          end else begin
            j_col <= j_col + 3'd1;
          end
        end

        // y1[i][j] = a5*tmp + a6*tm1 + b1*ym1 + b2*ym2  (i from 0..7 for each column j)
        S_COL_FWD: begin
          if (phase == 3'd0) begin
            if (i_row == 3'd0 && j_col == 3'd0) begin
              tm1 <= FX_ZERO; ym1 <= FX_ZERO; ym2 <= FX_ZERO;
            end
            acc   <= FX_ZERO;
            mul_a <= A5;
            mul_b <= tmp_mem[addr_ij];
            phase <= 3'd1;
          end else if (phase == 3'd1) begin
            acc   <= mul_q_reg;
            mul_a <= A6;
            mul_b <= tm1;
            phase <= 3'd2;
          end else if (phase == 3'd2) begin
            acc   <= acc + mul_q_reg;
            mul_a <= B1;
            mul_b <= ym1;
            phase <= 3'd3;
          end else if (phase == 3'd3) begin
            acc   <= acc + mul_q_reg;
            mul_a <= B2;
            mul_b <= ym2;
            phase <= 3'd4;
          end else begin
            acc                 <= acc + mul_q_reg;
            y1_mem[addr_ij]     <= acc + mul_q_reg;
            tm1                 <= tmp_mem[addr_ij];
            ym2                 <= ym1;
            ym1                 <= acc + mul_q_reg;
            phase               <= 3'd0;
            if (i_row == 3'd7) begin
              i_row <= 3'd0;
              if (j_col == 3'd7) begin
                j_col <= 3'd7;
              end else begin
                j_col <= j_col + 3'd1;
                tm1 <= FX_ZERO; ym1 <= FX_ZERO; ym2 <= FX_ZERO;
              end
            end else begin
              i_row <= i_row + 3'd1;
            end
          end
        end

        // y2[i][j] = a7*tp1 + a8*tp2 + b1*yp1 + b2*yp2  (i from 7..0 for each column j)
        S_COL_BWD: begin
          if (phase == 3'd0) begin
            if (i_row == 3'd7 && j_col == 3'd7) begin
              j_col <= 3'd0;
              i_row <= 3'd7;
              tp1 <= FX_ZERO; tp2 <= FX_ZERO; yp1 <= FX_ZERO; yp2 <= FX_ZERO;
            end
            acc   <= FX_ZERO;
            mul_a <= A7;
            mul_b <= tp1;
            phase <= 3'd1;
          end else if (phase == 3'd1) begin
            acc   <= mul_q_reg;
            mul_a <= A8;
            mul_b <= tp2;
            phase <= 3'd2;
          end else if (phase == 3'd2) begin
            acc   <= acc + mul_q_reg;
            mul_a <= B1;
            mul_b <= yp1;
            phase <= 3'd3;
          end else if (phase == 3'd3) begin
            acc   <= acc + mul_q_reg;
            mul_a <= B2;
            mul_b <= yp2;
            phase <= 3'd4;
          end else begin
            acc                 <= acc + mul_q_reg;
            y2_mem[addr_ij]     <= acc + mul_q_reg;
            tp2                 <= tp1;
            tp1                 <= tmp_mem[addr_ij];
            yp2                 <= yp1;
            yp1                 <= acc + mul_q_reg;
            phase               <= 3'd0;
            if (i_row == 3'd0) begin
              i_row <= 3'd7;
              if (j_col == 3'd7) begin
                j_col <= 3'd7;
              end else begin
                j_col <= j_col + 3'd1;
                tp1 <= FX_ZERO; tp2 <= FX_ZERO; yp1 <= FX_ZERO; yp2 <= FX_ZERO;
              end
            end else begin
              i_row <= i_row - 3'd1;
            end
          end
        end

        // out = c2*(y1+y2) ; c2==1.0 -> out = y1 + y2
        S_COMB2: begin
          out_mem[addr_ij] <= y1_mem[addr_ij] + y2_mem[addr_ij];
          if (j_col == 3'd7) begin
            j_col <= 3'd0;
            if (i_row == 3'd7) begin
              i_row <= 3'd0;
            end else begin
              i_row <= i_row + 3'd1;
            end
          end else begin
            j_col <= j_col + 3'd1;
          end
        end

        S_DONE: begin
          busy <= 1'b0;
          done <= 1'b1;
        end

        default: begin
          // no-op
        end
      endcase
    end
  end

endmodule
