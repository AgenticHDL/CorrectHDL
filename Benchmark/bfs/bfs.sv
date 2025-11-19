`timescale 1ns/1ps

module bfs #(
  parameter SCALE       = 4,
  parameter EDGE_FACTOR = 4,
  parameter N_NODES     = (1<<SCALE),              // 16
  parameter N_EDGES     = (N_NODES*EDGE_FACTOR),   // 64
  parameter N_LEVELS    = 10
)(
  input  wire         clk,
  input  wire         rst_n,

  // load nodes
  input  wire         node_we_begin,
  input  wire         node_we_end,
  input  wire [63:0]  node_waddr,
  input  wire [63:0]  node_edge_begin_wdata,
  input  wire [63:0]  node_edge_end_wdata,

  // load edges
  input  wire         edge_we,
  input  wire [63:0]  edge_waddr,
  input  wire [63:0]  edge_dst_wdata,

  // control
  input  wire         start,
  input  wire [63:0]  starting_node,

  output reg          busy,
  output reg          done,

  // readback level_counts (组合直读；lc_rd_en 可忽略)
  input  wire         lc_rd_en,
  input  wire [63:0]  lc_rd_addr,
  output reg  [63:0]  lc_rd_data
);

  // constants
  localparam [63:0] C_N_NODES  = (64'd1 << SCALE);
  localparam [63:0] C_N_EDGES  = (C_N_NODES * EDGE_FACTOR);
  localparam [63:0] C_N_LEVELS = 64'd10;
  localparam [7:0]  MAX_LEVEL8 = 8'd127;

  // memories
  reg [63:0] nodes_edge_begin [0:N_NODES-1];
  reg [63:0] nodes_edge_end   [0:N_NODES-1];
  reg [63:0] edges_dst        [0:N_EDGES-1];
  reg [7:0]  level_mem        [0:N_NODES-1];
  reg [63:0] level_counts_mem [0:N_LEVELS-1];

  // indices (固定低位掩码)
  wire [3:0] node_idx_wr = node_waddr[3:0];
  wire [5:0] edge_idx_wr = edge_waddr[5:0];
  wire [3:0] lc_idx_rd   = lc_rd_addr[3:0];

  // writes (同步)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // nothing
    end else begin
      if (node_we_begin) nodes_edge_begin[node_idx_wr] <= node_edge_begin_wdata;
      if (node_we_end)   nodes_edge_end  [node_idx_wr] <= node_edge_end_wdata;
      if (edge_we)       edges_dst       [edge_idx_wr] <= edge_dst_wdata;
    end
  end

  // reads (组合直读，避免同步采样造成首项读0)
  always @* begin
    lc_rd_data = level_counts_mem[lc_idx_rd];
  end

  // FSM states
  localparam [3:0]
    S_IDLE        = 4'd0,
    S_INIT_LVL    = 4'd1,
    S_INIT_CNT    = 4'd2,
    S_FORCE_LC0   = 4'd3,  // **新增：强制 level_counts[0]=1**
    S_SET_START   = 4'd4,
    S_H_START     = 4'd5,
    S_NODE_LOAD   = 4'd6,
    S_NODE_DECIDE = 4'd7,
    S_EDGE_LOAD   = 4'd8,
    S_EDGE_DECIDE = 4'd9,
    S_POST_LEVEL  = 4'd10,
    S_DONE        = 4'd11;

  reg [3:0]  st;

  reg [63:0] horizon_r;
  reg [63:0] n_idx_r;
  reg [63:0] e_idx_r;
  reg [63:0] e_end_r;
  reg [63:0] cnt_r;
  reg [7:0]  lvl_at_n_r;
  reg [63:0] dst_reg_r;

  // main seq
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st         <= S_IDLE;
      busy       <= 1'b0;
      done       <= 1'b0;
      horizon_r  <= 64'd0;
      n_idx_r    <= 64'd0;
      e_idx_r    <= 64'd0;
      e_end_r    <= 64'd0;
      cnt_r      <= 64'd0;
      lvl_at_n_r <= 8'd0;
      dst_reg_r  <= 64'd0;
    end else begin
      done <= 1'b0;

      case (st)
        S_IDLE: begin
          busy <= 1'b0;
          if (start) begin
            busy    <= 1'b1;
            n_idx_r <= 64'd0;
            st      <= S_INIT_LVL;
          end
        end

        // level[n] = MAX_LEVEL
        S_INIT_LVL: begin
          level_mem[n_idx_r[3:0]] <= MAX_LEVEL8;
          if (n_idx_r == (C_N_NODES-64'd1)) begin
            n_idx_r <= 64'd0;
            st      <= S_INIT_CNT;
          end else begin
            n_idx_r <= n_idx_r + 64'd1;
          end
        end

        // level_counts[l] = 0
        S_INIT_CNT: begin
          level_counts_mem[n_idx_r[3:0]] <= 64'd0;
          if (n_idx_r == (C_N_LEVELS-64'd1)) begin
            st <= S_FORCE_LC0;         // **清零后立即强制写LC[0]=1**
          end else begin
            n_idx_r <= n_idx_r + 64'd1;
          end
        end

        // **关键：把 level_counts[0] 置 1，先于 BFS 主循环**
        S_FORCE_LC0: begin
          level_counts_mem[4'd0] <= 64'd1;
          st <= S_SET_START;
        end

        // 起点 level[start]=0；horizon=0
        S_SET_START: begin
          level_mem[starting_node[3:0]] <= 8'd0;
          horizon_r <= 64'd0;
          st        <= S_H_START;
        end

        // 新一层
        S_H_START: begin
          cnt_r   <= 64'd0;
          n_idx_r <= 64'd0;
          st      <= S_NODE_LOAD;
        end

        // 取 level[n]
        S_NODE_LOAD: begin
          lvl_at_n_r <= level_mem[n_idx_r[3:0]];
          st         <= S_NODE_DECIDE;
        end

        // 命中该层？
        S_NODE_DECIDE: begin
          if (lvl_at_n_r == horizon_r[7:0]) begin
            e_idx_r <= nodes_edge_begin[n_idx_r[3:0]];
            e_end_r <= nodes_edge_end  [n_idx_r[3:0]];
            st      <= S_EDGE_LOAD;
          end else begin
            if (n_idx_r == (C_N_NODES-64'd1)) begin
              st <= S_POST_LEVEL;
            end else begin
              n_idx_r <= n_idx_r + 64'd1;
              st      <= S_NODE_LOAD;
            end
          end
        end

        // 边遍历装载
        S_EDGE_LOAD: begin
          if (e_idx_r == e_end_r) begin
            if (n_idx_r == (C_N_NODES-64'd1)) begin
              st <= S_POST_LEVEL;
            end else begin
              n_idx_r <= n_idx_r + 64'd1;
              st      <= S_NODE_LOAD;
            end
          end else begin
            dst_reg_r <= edges_dst[e_idx_r[5:0]];
            st        <= S_EDGE_DECIDE;
          end
        end

        // 处理一个邻居
        S_EDGE_DECIDE: begin
          if (level_mem[dst_reg_r[3:0]] == MAX_LEVEL8) begin
            level_mem[dst_reg_r[3:0]] <= (horizon_r[7:0] + 8'd1);
            cnt_r                     <= cnt_r + 64'd1;
          end
          e_idx_r <= e_idx_r + 64'd1;
          st      <= S_EDGE_LOAD;
        end

        // 写本轮“新发现”的个数到 level_counts[h+1]
        S_POST_LEVEL: begin
          level_counts_mem[(horizon_r[3:0] + 4'd1)] <= cnt_r;
          if ((cnt_r == 64'd0) || (horizon_r >= (C_N_LEVELS-64'd2))) begin
            st <= S_DONE;
          end else begin
            horizon_r <= horizon_r + 64'd1;
            st        <= S_H_START;
          end
        end

        S_DONE: begin
          busy <= 1'b0;
          done <= 1'b1;                       // 1-cycle
          level_counts_mem[4'd0] <= 64'd1;    // **再保险**
          if (!start) st <= S_IDLE;
        end

        default: st <= S_IDLE;
      endcase
    end
  end

endmodule
