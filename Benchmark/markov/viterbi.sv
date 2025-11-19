`timescale 1ns/1ps
module viterbi_core
(
  input  wire        clk,
  input  wire        rst_n,

  input  wire        obs_we,
  input  wire [4:0]  obs_addr,
  input  wire [7:0]  obs_din,

  input  wire        start,
  output reg         busy,
  output reg         done,

  input  wire [4:0]  path_addr,
  output reg  [7:0]  path_dout
);
  localparam N_STATES  = 16;
  localparam N_OBS     = 32;
  localparam PROB_W    = 16; // Q8.8 signed

  localparam signed [PROB_W-1:0] Q_ZERO = 16'sd0;
  localparam signed [PROB_W-1:0] Q_HALF = 16'sd128; // 0.5
  localparam signed [PROB_W-1:0] Q_ONE  = 16'sd256; // 1.0
  localparam signed [PROB_W-1:0] Q_TWO  = 16'sd512; // 2.0

  reg [7:0] obs_mem [0:N_OBS-1];
  reg signed [PROB_W-1:0] V_mem [0:(N_OBS*N_STATES)-1];
  reg [7:0] path_mem [0:N_OBS-1];

  always @(posedge clk) begin
    if (obs_we) obs_mem[obs_addr] <= obs_din;
  end

  always @(*) begin
    path_dout = path_mem[path_addr];
  end

  function [8:0] idx16;
    input [4:0] t;
    input [3:0] s;
    begin
      idx16 = {t,4'b0000} + {5'b0,s};
    end
  endfunction

  function signed [PROB_W-1:0] trans_cost;
    input [3:0] prev_s;
    input [3:0] curr_s;
    reg [3:0] a,b,d;
    begin
      a = prev_s; b = curr_s;
      if (a>=b) d = a-b; else d = b-a;
      if (d==4'd0)      trans_cost = Q_ZERO;
      else if (d==4'd1) trans_cost = Q_HALF;
      else              trans_cost = Q_TWO;
    end
  endfunction

  function signed [PROB_W-1:0] emiss_cost;
    input [3:0] s;
    input [7:0] tok;
    begin
      if (tok[3:0] == s[3:0]) emiss_cost = Q_ZERO;
      else                    emiss_cost = Q_ONE;
    end
  endfunction

  localparam S_IDLE        = 4'd0;
  localparam S_T0_INIT     = 4'd1;
  localparam S_DP_INIT     = 4'd2;
  localparam S_DP_PREV     = 4'd3;
  localparam S_DP_WRITE    = 4'd4;
  localparam S_TAIL_MIN    = 4'd5;
  localparam S_TAIL_COMMIT = 4'd6; // NEW
  localparam S_BK_INIT     = 4'd7;
  localparam S_BK_SCAN     = 4'd8;
  localparam S_BK_COMMIT   = 4'd9; // NEW
  localparam S_DONE        = 4'd10;

  reg [3:0]  st, st_n;
  reg [4:0]  t_idx, t_idx_n;
  reg [3:0]  s_idx, s_idx_n;
  reg [3:0]  prev_idx, prev_idx_n;
  reg [7:0]  obs_t, obs_t_n;

  reg signed [PROB_W-1:0] min_val, min_val_n;
  reg signed [PROB_W-1:0] cand, cand_n;
  reg [3:0]                best_s, best_s_n;
  reg [3:0]                next_state, next_state_n;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st         <= S_IDLE;
      t_idx      <= 5'd0;
      s_idx      <= 4'd0;
      prev_idx   <= 4'd0;
      obs_t      <= 8'd0;
      min_val    <= {PROB_W{1'b0}};
      cand       <= {PROB_W{1'b0}};
      best_s     <= 4'd0;
      next_state <= 4'd0;
      busy       <= 1'b0;
      done       <= 1'b0;
    end else begin
      st         <= st_n;
      t_idx      <= t_idx_n;
      s_idx      <= s_idx_n;
      prev_idx   <= prev_idx_n;
      obs_t      <= obs_t_n;
      min_val    <= min_val_n;
      cand       <= cand_n;
      best_s     <= best_s_n;
      next_state <= next_state_n;
    end
  end

  always @(*) begin
    st_n        = st;
    t_idx_n     = t_idx;
    s_idx_n     = s_idx;
    prev_idx_n  = prev_idx;
    obs_t_n     = obs_t;
    min_val_n   = min_val;
    cand_n      = cand;
    best_s_n    = best_s;
    next_state_n= next_state;

    busy        = (st != S_IDLE) && (st != S_DONE);
    done        = (st == S_DONE);

    case (st)
      S_IDLE: begin
        if (start) begin
          t_idx_n   = 5'd0;
          s_idx_n   = 4'd0;
          obs_t_n   = obs_mem[5'd0];
          st_n      = S_T0_INIT;
        end
      end

      // V[0][s] = emission(s, obs[0])
      S_T0_INIT: begin
        if (s_idx == 4'd15) begin
          t_idx_n    = 5'd1;
          s_idx_n    = 4'd0;
          prev_idx_n = 4'd0;
          obs_t_n    = obs_mem[5'd1];
          st_n       = S_DP_INIT;
        end else begin
          s_idx_n    = s_idx + 4'd1;
        end
      end

      // seed min with prev=0
      S_DP_INIT: begin
        min_val_n  = V_mem[idx16(t_idx-5'd1, 4'd0)] + trans_cost(4'd0, s_idx);
        prev_idx_n = 4'd1;
        st_n       = S_DP_PREV;
      end

      // prev=1..15
      S_DP_PREV: begin
        cand_n = V_mem[idx16(t_idx-5'd1, prev_idx)] + trans_cost(prev_idx, s_idx);
        if (cand_n < min_val) begin
          min_val_n = cand_n;
        end
        if (prev_idx == 4'd15) begin
          st_n = S_DP_WRITE;
        end else begin
          prev_idx_n = prev_idx + 4'd1;
        end
      end

      // write V[t][s] = min + emission
      S_DP_WRITE: begin
        if (s_idx == 4'd15) begin
          if (t_idx == 5'd31) begin
            s_idx_n = 4'd0;
            st_n    = S_TAIL_MIN;
          end else begin
            t_idx_n    = t_idx + 5'd1;
            s_idx_n    = 4'd0;
            prev_idx_n = 4'd0;
            obs_t_n    = obs_mem[t_idx + 5'd1];
            st_n       = S_DP_INIT;
          end
        end else begin
          s_idx_n    = s_idx + 4'd1;
          prev_idx_n = 4'd0;
          st_n       = S_DP_INIT;
        end
      end

      // find min at t=31 over s=0..15
      S_TAIL_MIN: begin
        if (s_idx == 4'd0) begin
          min_val_n = V_mem[idx16(5'd31, 4'd0)];
          best_s_n  = 4'd0;
          s_idx_n   = 4'd1;
        end else begin
          cand_n = V_mem[idx16(5'd31, s_idx)];
          if (cand_n < min_val) begin
            min_val_n = cand_n;
            best_s_n  = s_idx;
          end
          if (s_idx == 4'd15) begin
            // do NOT write here; go commit next cycle
            st_n = S_TAIL_COMMIT;
          end else begin
            s_idx_n = s_idx + 4'd1;
          end
        end
      end

      // commit path[31] with final best_s (registered now)
      S_TAIL_COMMIT: begin
        next_state_n = best_s;
        t_idx_n      = 5'd30;
        s_idx_n      = 4'd0;
        st_n         = S_BK_INIT;
      end

      // backtrack: seed each t with s=0
      S_BK_INIT: begin
        min_val_n = V_mem[idx16(t_idx, 4'd0)] + trans_cost(4'd0, next_state);
        best_s_n  = 4'd0;
        s_idx_n   = 4'd1;
        st_n      = S_BK_SCAN;
      end

      // scan s=1..15
      S_BK_SCAN: begin
        cand_n = V_mem[idx16(t_idx, s_idx)] + trans_cost(s_idx, next_state);
        if (cand_n < min_val) begin
          min_val_n = cand_n;
          best_s_n  = s_idx;
        end
        if (s_idx == 4'd15) begin
          // do NOT write here; go commit next cycle
          st_n = S_BK_COMMIT;
        end else begin
          s_idx_n = s_idx + 4'd1;
        end
      end

      // commit path[t] with final best_s (registered now)
      S_BK_COMMIT: begin
        if (t_idx == 5'd0) begin
          st_n = S_DONE;
        end else begin
          next_state_n = best_s;
          t_idx_n      = t_idx - 5'd1;
          s_idx_n      = 4'd0;
          st_n         = S_BK_INIT;
        end
      end

      S_DONE: begin
        if (!start) st_n = S_IDLE;
      end

      default: begin
        st_n = S_IDLE;
      end
    endcase
  end

  // registered writes (<=)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin : RST_MEMS
      integer i;
      for (i=0;i<N_OBS;i=i+1) begin
        path_mem[i] <= 8'd0;
      end
    end else begin
      if (st == S_T0_INIT) begin
        V_mem[idx16(5'd0, s_idx)] <= emiss_cost(s_idx, obs_t);
      end
      if (st == S_DP_WRITE) begin
        V_mem[idx16(t_idx, s_idx)] <= min_val + emiss_cost(s_idx, obs_t);
      end
      if (st == S_TAIL_COMMIT) begin
        path_mem[5'd31] <= {4'd0, best_s};
      end
      if (st == S_BK_COMMIT) begin
        path_mem[t_idx] <= {4'd0, best_s};
      end
    end
  end

endmodule
