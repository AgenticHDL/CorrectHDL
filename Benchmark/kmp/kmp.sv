// kmp4.v
// Verilog-2001 sequential KMP (PATTERN_SIZE=4, STRING_SIZE=2241)

`timescale 1ns/1ps

module kmp4
#(
  parameter PATTERN_SIZE = 4,
  parameter STRING_SIZE  = 2241
)(
  input               clk,
  input               rst_n,          // active-low
  input               start,          // 1-cycle pulse

  input      [7:0]    pattern_0,
  input      [7:0]    pattern_1,
  input      [7:0]    pattern_2,
  input      [7:0]    pattern_3,

  input               in_valid,
  output reg          in_ready,
  input      [7:0]    in_data,
  input               in_last,

  output reg          done,           // 1-cycle pulse
  output reg [31:0]   n_matches
);




  localparam QW    = 3;
  localparam NEXTW = 2;


  reg [7:0]        pat     [0:PATTERN_SIZE-1];
  reg [NEXTW-1:0]  kmpNext [0:PATTERN_SIZE-1];

  // FSM
  localparam S_IDLE           = 4'd0;
  localparam S_CPF_INIT       = 4'd1;
  localparam S_CPF_Q_LOOP     = 4'd2;
  localparam S_CPF_WHILE      = 4'd3;
  localparam S_CPF_SET        = 4'd4;
  localparam S_PROC_WAITBYTE  = 4'd5;
  localparam S_PROC_WHILE     = 4'd6;
  localparam S_PROC_STEP      = 4'd7;
  localparam S_DONE           = 4'd8;

  reg [3:0] state, state_n;


  reg [NEXTW-1:0] cpf_k, cpf_k_n;   // 0..3
  reg [QW-1:0]    cpf_q, cpf_q_n;   // 0..4


  reg [QW-1:0]    q, q_n;           // 0..4
  reg [7:0]       byte_reg, byte_reg_n;
  reg             last_reg, last_reg_n;

  reg [31:0] match_cnt, match_cnt_n;


  reg             we_next;
  reg [QW-1:0]    next_idx;
  reg [NEXTW-1:0] next_val;

  integer idx;


  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      state     <= S_IDLE;
      cpf_k     <= {NEXTW{1'b0}};
      cpf_q     <= {QW{1'b0}};
      q         <= {QW{1'b0}};
      byte_reg  <= 8'd0;
      last_reg  <= 1'b0;
      match_cnt <= 32'd0;

      in_ready  <= 1'b0;
      done      <= 1'b0;
      n_matches <= 32'd0;

      for (idx=0; idx<PATTERN_SIZE; idx=idx+1) begin
        pat[idx]     <= 8'd0;
        kmpNext[idx] <= {NEXTW{1'b0}};
      end
    end else begin
      state     <= state_n;
      cpf_k     <= cpf_k_n;
      cpf_q     <= cpf_q_n;
      q         <= q_n;
      byte_reg  <= byte_reg_n;
      last_reg  <= last_reg_n;
      match_cnt <= match_cnt_n;

      in_ready  <= (state_n==S_PROC_WAITBYTE); 


      done      <= (state_n==S_DONE);
      if (state_n==S_DONE) n_matches <= match_cnt;


      if (state==S_IDLE && start) begin
        pat[0] <= pattern_0;
        pat[1] <= pattern_1;
        pat[2] <= pattern_2;
        pat[3] <= pattern_3;
        kmpNext[0] <= {NEXTW{1'b0}}; // pi[0]=0
      end


      if (we_next) begin
        kmpNext[next_idx] <= next_val;
      end
    end
  end


  always @* begin

    state_n      = state;
    cpf_k_n      = cpf_k;
    cpf_q_n      = cpf_q;
    q_n          = q;
    byte_reg_n   = byte_reg;
    last_reg_n   = last_reg;
    match_cnt_n  = match_cnt;



    we_next      = 1'b0;
    next_idx     = {QW{1'b0}};
    next_val     = {NEXTW{1'b0}};

    case (state)
      // ------------------------
      S_IDLE: begin
        if (start) begin

          match_cnt_n = 32'd0;
          q_n         = {QW{1'b0}};
          last_reg_n  = 1'b0;

          // CPF 初始化：q 从 1 开始
          cpf_k_n   = {NEXTW{1'b0}};
          cpf_q_n   = 3'd1;
          state_n   = S_CPF_INIT;
        end
      end

      // ------------------------
      S_CPF_INIT: begin
        state_n = S_CPF_Q_LOOP;
      end

      // q 从 1..PATTERN_SIZE-1
      S_CPF_Q_LOOP: begin
        if (cpf_q < PATTERN_SIZE) begin
        
          if ((cpf_k > 0) && (pat[cpf_k] != pat[cpf_q])) begin
            state_n = S_CPF_WHILE;
          end else begin

            if (pat[cpf_k] == pat[cpf_q]) begin
              cpf_k_n = cpf_k + 1'b1;
            end
            state_n = S_CPF_SET;
          end
        end else begin

          state_n = S_PROC_WAITBYTE;
        end
      end

      S_CPF_WHILE: begin
        // k = pi[k-1]
        cpf_k_n = kmpNext[cpf_k - 1'b1];
        state_n = S_CPF_Q_LOOP;
      end

      S_CPF_SET: begin
        // pi[q] = k
        we_next  = 1'b1;
        next_idx = cpf_q;       // 1..3
        next_val = cpf_k;       // 0..3
        cpf_q_n  = cpf_q + 1'b1;
        state_n  = S_CPF_Q_LOOP;
      end

      // ------------------------
      S_PROC_WAITBYTE: begin

        if (in_valid) begin
          byte_reg_n = in_data;
          last_reg_n = in_last;
          state_n    = S_PROC_WHILE;
        end
      end

      // while (q>0 && pat[q]!=byte) q=pi[q-1]
      S_PROC_WHILE: begin
        if ( (q > 0) && (pat[q] != byte_reg) ) begin
          q_n    = kmpNext[q - 1'b1];
          state_n = S_PROC_WHILE;
        end else begin
          state_n = S_PROC_STEP;
        end
      end

      // if (pat[q]==byte) q++;

      S_PROC_STEP: begin
        if (pat[q] == byte_reg) begin
          if (q == (PATTERN_SIZE-1)) begin

            match_cnt_n = match_cnt + 32'd1;
            q_n         = kmpNext[q]; 
          end else begin
            q_n = q + 1'b1;
          end
        end
        state_n = (last_reg) ? S_DONE : S_PROC_WAITBYTE;
      end

      // ------------------------
      S_DONE: begin
        state_n = S_IDLE;
      end

      default: begin
        state_n = S_IDLE;
      end
    endcase
  end

endmodule
