`timescale 1ns/1ps

// ------------------------------------------------------------
// SGD Logistic Regression core (fixed-point, Hard-Sigmoid)
// - Feature/Data: signed Q6.10 (16-bit), AC_TRN + AC_WRAP 
// - prob = clamp(0,1, 0.5 + x/4) => Q6.10: clamp(0,1024, 512 + (dot>>>2))
// 
// ------------------------------------------------------------
module sgd_lr_int
#(
  parameter integer NUM_FEATURES = 32,
  parameter integer NUM_TRAINING = 40,
  parameter integer NUM_EPOCHS   = 2
)(
  input  wire                 clk,
  input  wire                 rst_n,
  input  wire                 start,


  input  wire  [15:0]         feature_in,    // Q6.10 signed
  input  wire                 feature_valid,
  input  wire   [7:0]         label_in,      // 0/1
  input  wire                 label_valid,

  output reg                  sample_req,    // 请求下一个样本
  output reg                  done,          // 全部训练完成


  input  wire   [5:0]         theta_rd_idx,  // 0..31
  output wire  [15:0]         theta_rd_data  // Q6.10 signed
);



  // ----------------------------
  function [15:0] q6_10_mul;
    input signed [15:0] a;
    input signed [15:0] b;
    reg   signed [31:0] prod;
    reg   signed [31:0] shr;
    begin
      prod = $signed(a) * $signed(b); // Q12.20
      shr  = prod >>> 10;             // 直接算术右移，相当于 floor
      q6_10_mul = shr[15:0];          // 16 位环绕
    end
  endfunction



  reg  signed [15:0] theta   [0:NUM_FEATURES-1];
  reg  signed [15:0] featbuf [0:NUM_FEATURES-1];
  reg  [7:0]  cur_label;

  assign theta_rd_data = theta[theta_rd_idx];

  // FSM
  localparam [2:0]
    ST_IDLE     = 3'd0,
    ST_LOAD     = 3'd1,
    ST_WAIT_LBL = 3'd2,
    ST_DOT      = 3'd3,
    ST_SIGMOID  = 3'd4,
    ST_UPDATE   = 3'd5,
    ST_DONE     = 3'd6;

  reg [2:0] state;


  reg [5:0]  fcnt;      // 0..31
  reg [5:0]  icnt;      // 0..31
  reg [5:0]  train_id;  // 0..39
  reg [1:0]  epoch;     // 0..1

  reg  signed [15:0] dot;   // Q6.10
  reg  signed [15:0] err;   // Q6.10

  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= ST_IDLE;
      sample_req <= 1'b0;
      done       <= 1'b0;
      fcnt       <= 6'd0;
      icnt       <= 6'd0;
      train_id   <= 6'd0;
      epoch      <= 2'd0;
      dot        <= 16'sd0;
      err        <= 16'sd0;
      for (i=0;i<NUM_FEATURES;i=i+1) begin
        theta[i]   <= 16'sd0;
        featbuf[i] <= 16'sd0;
      end
    end else begin
      case (state)
        ST_IDLE: begin
          done       <= 1'b0;
          sample_req <= 1'b0;
          if (start) begin
            for (i=0;i<NUM_FEATURES;i=i+1) theta[i] <= 16'sd0;
            epoch      <= 2'd0;
            train_id   <= 6'd0;
            fcnt       <= 6'd0;
            sample_req <= 1'b1;
            state      <= ST_LOAD;
          end
        end

        ST_LOAD: begin
          if (feature_valid) begin
            featbuf[fcnt] <= feature_in;
            fcnt <= fcnt + 6'd1;
            if (fcnt == (NUM_FEATURES-1)) begin
              fcnt <= 6'd0;
              sample_req <= 1'b0;
              state <= ST_WAIT_LBL;
            end
          end
        end

        ST_WAIT_LBL: begin
          if (label_valid) begin
            icnt <= 6'd0;
            dot  <= 16'sd0;
            state <= ST_DOT;
          end
        end

        ST_DOT: begin
          dot  <= dot + q6_10_mul(theta[icnt], featbuf[icnt]);
          icnt <= icnt + 6'd1;
          if (icnt == (NUM_FEATURES-1)) begin
            state <= ST_SIGMOID;
          end
        end

        ST_SIGMOID: begin
          // Hard-Sigmoid: y = clamp(0,1024, 512 + (dot>>>2))
          reg signed [15:0] dot_div4;
          reg signed [15:0] y;
          reg signed [15:0] labelQ;
          dot_div4 = $signed(dot) >>> 2;
          y = 16'sd512 + dot_div4;
          if ($signed(y) < 16'sd0)     y = 16'sd0;
          if ($signed(y) > 16'sd1024)  y = 16'sd1024;
          labelQ = {8'd0, label_in, 10'd0};
          err <= y - labelQ;
          icnt <= 6'd0;
          state <= ST_UPDATE;
        end

        ST_UPDATE: begin
          // theta[i] -= err * feat[i]
          theta[icnt] <= theta[icnt] - q6_10_mul(featbuf[icnt], err);
          icnt <= icnt + 6'd1;
          if (icnt == (NUM_FEATURES-1)) begin
            if (train_id == (NUM_TRAINING-1)) begin
              train_id <= 6'd0;
              if (epoch == (NUM_EPOCHS-1)) begin
                state <= ST_DONE;
              end else begin
                epoch <= epoch + 2'd1;
                sample_req <= 1'b1;
                state <= ST_LOAD;
              end
            end else begin
              train_id <= train_id + 6'd1;
              sample_req <= 1'b1;
              state <= ST_LOAD;
            end
          end
        end

        ST_DONE: begin
          done <= 1'b1;
          if (!start) state <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

endmodule
