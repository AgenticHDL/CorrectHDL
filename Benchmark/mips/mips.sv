`timescale 1ns/1ps

//------------------------------------------------------------------------------
// 
// - One instruction retired per cycle (no parallel loops / no unrolling).
// - Verilog-2001 only. All stateful regs use non-blocking "<=".
// - ROM addressing: IADDR(pc) = (pc[7:0]) >> 2
// - DMEM addressing: DADDR(addr) = (addr[7:0]) >> 2
// - reg[0] is forced to 0 after each instruction (match C++ behavior).
//------------------------------------------------------------------------------

module mips_sort (
  input  wire         clk,
  input  wire         rstn,
  input  wire         start,

  input  wire [31:0]  A_in0,
  input  wire [31:0]  A_in1,
  input  wire [31:0]  A_in2,
  input  wire [31:0]  A_in3,
  input  wire [31:0]  A_in4,
  input  wire [31:0]  A_in5,
  input  wire [31:0]  A_in6,
  input  wire [31:0]  A_in7,

  output reg  [31:0]  out0,
  output reg  [31:0]  out1,
  output reg  [31:0]  out2,
  output reg  [31:0]  out3,
  output reg  [31:0]  out4,
  output reg  [31:0]  out5,
  output reg  [31:0]  out6,
  output reg  [31:0]  out7,

  output reg  [31:0]  n_inst_out,
  output reg          done
);

  // -------------------------------
  // Program ROM (44 words) as a case
  // -------------------------------
  function [31:0] imem_word;
    input [5:0] idx; // pc[7:2]
    begin
      case (idx)
        6'd0:  imem_word = 32'h8fa40000;
        6'd1:  imem_word = 32'h27a50004;
        6'd2:  imem_word = 32'h24a60004;
        6'd3:  imem_word = 32'h00041080;
        6'd4:  imem_word = 32'h00c23021;
        6'd5:  imem_word = 32'h0c100016;
        6'd6:  imem_word = 32'h00000000;
        6'd7:  imem_word = 32'h3402000a;
        6'd8:  imem_word = 32'h0000000c;
        6'd9:  imem_word = 32'h3c011001;
        6'd10: imem_word = 32'h34280000;
        6'd11: imem_word = 32'h00044880;
        6'd12: imem_word = 32'h01094821;
        6'd13: imem_word = 32'h8d2a0000;
        6'd14: imem_word = 32'h00055880;
        6'd15: imem_word = 32'h010b5821;
        6'd16: imem_word = 32'h8d6c0000;
        6'd17: imem_word = 32'h018a682a;
        6'd18: imem_word = 32'h11a00003;
        6'd19: imem_word = 32'had2c0000;
        6'd20: imem_word = 32'had6a0000;
        6'd21: imem_word = 32'h03e00008;
        6'd22: imem_word = 32'h27bdfff4;
        6'd23: imem_word = 32'hafbf0008;
        6'd24: imem_word = 32'hafb10004;
        6'd25: imem_word = 32'hafb00000;
        6'd26: imem_word = 32'h24100000;
        6'd27: imem_word = 32'h2a080008;
        6'd28: imem_word = 32'h1100000b;
        6'd29: imem_word = 32'h26110001;
        6'd30: imem_word = 32'h2a280008;
        6'd31: imem_word = 32'h11000006;
        6'd32: imem_word = 32'h26040000;
        6'd33: imem_word = 32'h26250000;
        6'd34: imem_word = 32'h0c100009;
        6'd35: imem_word = 32'h26310001;
        6'd36: imem_word = 32'h0810001e;
        6'd37: imem_word = 32'h26100001;
        6'd38: imem_word = 32'h0810001b;
        6'd39: imem_word = 32'h8fbf0008;
        6'd40: imem_word = 32'h8fb10004;
        6'd41: imem_word = 32'h8fb00000;
        6'd42: imem_word = 32'h27bd000c;
        6'd43: imem_word = 32'h03e00008;
        default: imem_word = 32'h00000000;
      endcase
    end
  endfunction

  // -------------------------------
  // Constants / opcodes / funct
  // -------------------------------
  localparam [5:0] OP_R    = 6'd0;
  localparam [5:0] OP_J    = 6'd2;
  localparam [5:0] OP_JAL  = 6'd3;
  localparam [5:0] OP_BEQ  = 6'd4;
  localparam [5:0] OP_ADDIU= 6'd9;
  localparam [5:0] OP_SLTI = 6'd10;
  localparam [5:0] OP_ANDI = 6'd12;
  localparam [5:0] OP_ORI  = 6'd13;
  localparam [5:0] OP_LUI  = 6'd15;
  localparam [5:0] OP_LW   = 6'd35;
  localparam [5:0] OP_SW   = 6'd43;

  localparam [5:0] FUNCT_SLL  = 6'd0;
  localparam [5:0] FUNCT_JR   = 6'd8;
  localparam [5:0] FUNCT_ADDU = 6'd33;
  localparam [5:0] FUNCT_SUBU = 6'd35;
  localparam [5:0] FUNCT_SLT  = 6'd42;

  // -------------------------------
  // State & storage
  // -------------------------------
  localparam [3:0]
    S_IDLE       = 4'd0,
    S_CLR_REGS   = 4'd1,
    S_SET_SP     = 4'd2,
    S_CLR_DMEM   = 4'd3,
    S_LOAD_DMEM  = 4'd4,
    S_INIT       = 4'd5,
    S_EXEC       = 4'd6,
    S_DONE       = 4'd7;

  reg [3:0] state;

  reg [31:0] regfile [0:31];
  reg [31:0] dmem    [0:63];

  reg [31:0] pc;
  reg [31:0] n_inst;

  reg [6:0]  idx; // for sequential init: up to 63

  // -------------------------------
  // Sequential FSM
  // -------------------------------
  integer k;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      state      <= S_IDLE;
      done       <= 1'b0;
      pc         <= 32'd0;
      n_inst     <= 32'd0;
      n_inst_out <= 32'd0;
      idx        <= 7'd0;

      // Safe reset (no parallel unroll)
      // Note: these loops are ignored by synthesis for initial reset (simulation aid),
      // real init happens in S_CLR_* states to avoid parallel fanout.
      for (k = 0; k < 32; k = k + 1) regfile[k] <= 32'd0;
      for (k = 0; k < 64; k = k + 1) dmem[k]    <= 32'd0;

      out0 <= 32'd0; out1 <= 32'd0; out2 <= 32'd0; out3 <= 32'd0;
      out4 <= 32'd0; out5 <= 32'd0; out6 <= 32'd0; out7 <= 32'd0;
    end else begin
      case (state)
        // Wait for start pulse
        S_IDLE: begin
          done   <= 1'b0;
          if (start) begin
            idx   <= 7'd0;
            state <= S_CLR_REGS;
          end
        end

        // Clear regfile sequentially
        S_CLR_REGS: begin
          regfile[idx[4:0]] <= 32'd0;
          if (idx == 7'd31) begin
            state <= S_SET_SP;
          end
          idx <= idx + 7'd1;
        end

        // Set stack pointer reg[29] = 0x7fffeffc
        S_SET_SP: begin
          regfile[29] <= 32'h7fffeffc;
          idx         <= 7'd0;
          state       <= S_CLR_DMEM;
        end

        // Clear DMEM sequentially
        S_CLR_DMEM: begin
          dmem[idx] <= 32'd0;
          if (idx == 7'd63) begin
            idx   <= 7'd0;
            state <= S_LOAD_DMEM;
          end else begin
            idx <= idx + 7'd1;
          end
        end

        // Load first 8 words from inputs into DMEM[0..7]
        S_LOAD_DMEM: begin
          case (idx[2:0])
            3'd0: dmem[0] <= A_in0;
            3'd1: dmem[1] <= A_in1;
            3'd2: dmem[2] <= A_in2;
            3'd3: dmem[3] <= A_in3;
            3'd4: dmem[4] <= A_in4;
            3'd5: dmem[5] <= A_in5;
            3'd6: dmem[6] <= A_in6;
            3'd7: dmem[7] <= A_in7;
          endcase
          if (idx == 7'd7) begin
            state <= S_INIT;
          end
          idx <= idx + 7'd1;
        end

        // Initialize PC and counters
        S_INIT: begin
          pc     <= 32'h0040_0000;
          n_inst <= 32'd0;
          state  <= S_EXEC;
        end

        // One instruction per cycle
        S_EXEC: begin
          // --------- Local temporaries (blocking "=" allowed for locals) ---------
          reg [31:0] ins_w;
          reg [5:0]  op_w, funct_w;
          reg [4:0]  rs_w, rt_w, rd_w, shamt_w;
          reg [31:0] next_pc_w;
          reg [31:0] write_data_w;
          reg [4:0]  write_reg_w;
          reg        write_en_w;
          reg        dmem_we_w;
          reg [31:0] dmem_waddr_w;
          reg [31:0] dmem_wdata_w;

          reg [31:0] rs_val, rt_val;
          reg [31:0] imm_sext_w;
          reg [31:0] imm_zext_w;
          reg [31:0] addr_calc_w;
          reg [31:0] tgt_w;

          integer daddr_idx;
          integer iaddr_idx;

          // Fetch
          iaddr_idx  = {2'b00, pc[7:2]}; // keep as integer index (0..63)
          ins_w      = imem_word(pc[7:2]);
          op_w       = ins_w[31:26];
          funct_w    = ins_w[5:0];
          rs_w       = ins_w[25:21];
          rt_w       = ins_w[20:16];
          rd_w       = ins_w[15:11];
          shamt_w    = ins_w[10:6];

          rs_val     = regfile[rs_w];
          rt_val     = regfile[rt_w];

          imm_sext_w = {{16{ins_w[15]}}, ins_w[15:0]}; // sign-extended int16_t
          imm_zext_w = {16'd0, ins_w[15:0]};           // zero-extended uint16_t

          next_pc_w  = pc + 32'd4;
          write_en_w = 1'b0;
          write_reg_w= 5'd0;
          write_data_w=32'd0;
          dmem_we_w  = 1'b0;
          dmem_waddr_w = 32'd0;
          dmem_wdata_w = 32'd0;

          // Decode & Execute
          if (op_w == OP_R) begin
            if (funct_w == FUNCT_ADDU) begin
              write_en_w  = 1'b1;
              write_reg_w = rd_w;
              write_data_w= rs_val + rt_val;
            end else if (funct_w == FUNCT_SUBU) begin
              write_en_w  = 1'b1;
              write_reg_w = rd_w;
              write_data_w= rs_val - rt_val;
            end else if (funct_w == FUNCT_SLL) begin
              write_en_w  = 1'b1;
              write_reg_w = rd_w;
              write_data_w= rt_val << shamt_w;
            end else if (funct_w == FUNCT_SLT) begin
              write_en_w  = 1'b1;
              write_reg_w = rd_w;
              write_data_w= ($signed(rs_val) < $signed(rt_val)) ? 32'd1 : 32'd0;
            end else if (funct_w == FUNCT_JR) begin
              next_pc_w   = rs_val;
            end else begin
              // unsupported funct -> halt
              next_pc_w   = 32'd0;
            end
          end else if (op_w == OP_J) begin
            tgt_w     = {ins_w[25:0], 2'b00};
            next_pc_w = tgt_w;
          end else if (op_w == OP_JAL) begin
            tgt_w       = {ins_w[25:0], 2'b00};
            write_en_w  = 1'b1;
            write_reg_w = 5'd31;
            write_data_w= pc + 32'd4; // link is pc after increment
            next_pc_w   = tgt_w;
          end else begin
            // I-type / memory / others
            if (op_w == OP_ADDIU) begin
              write_en_w  = 1'b1;
              write_reg_w = rt_w;
              write_data_w= $signed(rs_val) + $signed(imm_sext_w);
            end else if (op_w == OP_ANDI) begin
              write_en_w  = 1'b1;
              write_reg_w = rt_w;
              write_data_w= rs_val & imm_zext_w;
            end else if (op_w == OP_ORI) begin
              write_en_w  = 1'b1;
              write_reg_w = rt_w;
              write_data_w= rs_val | imm_zext_w;
            end else if (op_w == OP_LW) begin
              addr_calc_w = $signed(rs_val) + $signed(imm_sext_w);
              daddr_idx   = addr_calc_w[7:2];
              write_en_w  = 1'b1;
              write_reg_w = rt_w;
              write_data_w= dmem[daddr_idx[5:0]];
            end else if (op_w == OP_SW) begin
              addr_calc_w = $signed(rs_val) + $signed(imm_sext_w);
              daddr_idx   = addr_calc_w[7:2];
              dmem_we_w   = 1'b1;
              dmem_waddr_w= {26'd0, daddr_idx[5:0]};
              dmem_wdata_w= rt_val;
            end else if (op_w == OP_LUI) begin
              write_en_w  = 1'b1;
              write_reg_w = rt_w;
              write_data_w= {ins_w[15:0], 16'd0};
            end else if (op_w == OP_BEQ) begin
              if (rs_val == rt_val) begin
                next_pc_w = (pc + 32'd4) - 32'd4 + (imm_sext_w << 2);
              end
            end else if (op_w == OP_SLTI) begin
              write_en_w  = 1'b1;
              write_reg_w = rt_w;
              write_data_w= ($signed(rs_val) < $signed(imm_sext_w)) ? 32'd1 : 32'd0;
            end else begin
              // unsupported opcode -> halt
              next_pc_w = 32'd0;
            end
          end

          // Memory write (SW)
          if (dmem_we_w) begin
            dmem[dmem_waddr_w[5:0]] <= dmem_wdata_w;
          end

          // Register writeback
          if (write_en_w) begin
            regfile[write_reg_w] <= write_data_w;
          end

          // Enforce reg[0] == 0 like C++
          regfile[0] <= 32'd0;

          // Retire instruction count
          n_inst <= n_inst + 32'd1;

          // Update PC & possibly finish
          pc <= next_pc_w;

          if (next_pc_w == 32'd0) begin
            // Copy outputs from DMEM[0..7]
            out0 <= dmem[0];
            out1 <= dmem[1];
            out2 <= dmem[2];
            out3 <= dmem[3];
            out4 <= dmem[4];
            out5 <= dmem[5];
            out6 <= dmem[6];
            out7 <= dmem[7];

            n_inst_out <= n_inst + 32'd1; // includes last instruction (like C++)
            done       <= 1'b1;
            state      <= S_DONE;
          end
        end

        // Pulse done for one cycle, then go idle
        S_DONE: begin
          done   <= 1'b0;
          state  <= S_IDLE;
        end

        default: begin
          state <= S_IDLE;
        end
      endcase
    end
  end

endmodule
