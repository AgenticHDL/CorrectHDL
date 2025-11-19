// ================================================================
`timescale 1ns/1ps

module gemm_core
(
  input  wire         clk,
  input  wire         rst_n,
  input  wire         wr_en,        // 1
  input  wire  [1:0]  wr_sel,       // 0 = m1, 1 = m2
  input  wire  [7:0]  wr_addr,      // 0..255
  input  wire  signed [20:0] wr_data,// TYPE: signed 21-bit
  input  wire         start,        
  output reg          done,         
  output reg  [31:0]  sum_out
);

  localparam ROWS   = 16;
  localparam COLS   = 16;
  localparam LOGN   = 4;   // log2(16)=4

  reg signed [20:0] m1_mem  [0:255];
  reg signed [20:0] m2_mem  [0:255];
  reg signed [20:0] prod_mem[0:255]; 
  reg [LOGN-1:0] i, j, k;  // 0..15

  // FSM
  localparam S_IDLE = 2'd0;
  localparam S_CALC = 2'd1;
  localparam S_DONE = 2'd2;

  reg [1:0] state, state_next;

  reg signed [31:0] acc;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      // no init
    end else begin

      if (wr_en && (state != S_CALC)) begin
        case (wr_sel)
          2'd0: m1_mem[wr_addr] <= wr_data;
          2'd1: m2_mem[wr_addr] <= wr_data;
          default: /* no-op */;
        endcase
      end

    end
  end


  // i*16 + k, k*16 + j, i*16 + j
  wire [7:0] addr_m1 = {i, 4'b0} + {4'b0, k};
  wire [7:0] addr_m2 = {k, 4'b0} + {4'b0, j};
  wire [7:0] addr_p  = {i, 4'b0} + {4'b0, j};


  wire signed [20:0] m1_rd = m1_mem[addr_m1];
  wire signed [20:0] m2_rd = m2_mem[addr_m2];


  wire signed [13:0] m1_14 = m1_rd[13:0];
  wire signed [13:0] m2_14 = m2_rd[13:0];


  wire signed [27:0] mul28 = m1_14 * m2_14;


  wire signed [31:0] term32 = {{4{mul28[27]}}, mul28};

  wire signed [31:0] acc_add = acc + term32;


  wire signed [20:0] out21 = acc_add[20:0];

  wire signed [31:0] out32 = {{11{out21[20]}}, out21};



  always @(*) begin
    state_next = state;
    case (state)

      S_IDLE: begin
        if (start) state_next = S_CALC;
      end

      S_CALC: begin
        if ((i == 4'd15) && (j == 4'd15) && (k == 4'd15))
          state_next = S_DONE;
      end

      S_DONE: begin      
        if (start) state_next = S_CALC;
      end

      default: state_next = S_IDLE;
      
    endcase
  end


  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      state   <= S_IDLE;
      i       <= 4'd0;
      j       <= 4'd0;
      k       <= 4'd0;
      acc     <= 32'sd0;
      done    <= 1'b0;
      sum_out <= 32'd0;
    end else begin

      state <= state_next;



      case (state)
        S_IDLE: begin
          done <= 1'b0;

          if (start) begin
            i       <= 4'd0;
            j       <= 4'd0;
            k       <= 4'd0;
            acc     <= 32'sd0;
            sum_out <= 32'd0;
          end

        end



        S_CALC: begin
          if (k != 4'd15) begin
            acc <= acc_add;      
            k   <= k + 4'd1;
          end else begin
            acc <= 32'sd0;
            k   <= 4'd0;
            prod_mem[addr_p] <= out21;
            sum_out <= sum_out + out32;


            if (j != 4'd15) begin
              j <= j + 4'd1;
            end else begin
              j <= 4'd0;

              if (i != 4'd15) begin
                i <= i + 4'd1;
              end else begin
                i <= 4'd15; 
              end

            end
          end
        end


        S_DONE: begin
          done <= 1'b1;
          if (start) begin
            done    <= 1'b0;
            i       <= 4'd0;
            j       <= 4'd0;
            k       <= 4'd0;
            acc     <= 32'sd0;
            sum_out <= 32'd0;
          end
        end


        default: /* no-op */;
      endcase
    end
  end

endmodule
