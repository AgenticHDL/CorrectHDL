// ----------------------------------------------------------------------
//  HLS HDL:        Verilog Netlister
//  HLS Version:    2022.2/1008433 Production Release
//  HLS Date:       Fri Aug 19 18:40:59 PDT 2022
// 
//  
//  
// ----------------------------------------------------------------------

// 
// ------------------------------------------------------------------
//  Design Unit:    bfs_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_3_64_64_6_0_1_0_0_0_1_1_64_64_1_1_gen
// ------------------------------------------------------------------


module bfs_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_3_64_64_6_0_1_0_0_0_1_1_64_64_1_1_gen
    (
  data_out, re, addr_rd, addr_rd_d, re_d, data_out_d
);
  input [63:0] data_out;
  output re;
  output [5:0] addr_rd;
  input [5:0] addr_rd_d;
  input re_d;
  output [63:0] data_out_d;



  // Interconnect Declarations for Component Instantiations 
  assign data_out_d = data_out;
  assign re = (re_d);
  assign addr_rd = (addr_rd_d);
endmodule

// ------------------------------------------------------------------
//  Design Unit:    bfs_core_core_fsm
//  FSM Module
// ------------------------------------------------------------------


module bfs_core_core_fsm (
  clk, rst, fsm_output, loop_nodes_C_0_tr0, loop_neighbors_C_1_tr0, loop_nodes_C_1_tr0,
      loop_horizons_C_1_tr0
);
  input clk;
  input rst;
  output [9:0] fsm_output;
  reg [9:0] fsm_output;
  input loop_nodes_C_0_tr0;
  input loop_neighbors_C_1_tr0;
  input loop_nodes_C_1_tr0;
  input loop_horizons_C_1_tr0;


  // FSM State Type Declaration for bfs_core_core_fsm_1
  parameter
    core_rlp_C_0 = 4'd0,
    main_C_0 = 4'd1,
    main_C_1 = 4'd2,
    loop_nodes_C_0 = 4'd3,
    loop_neighbors_C_0 = 4'd4,
    loop_neighbors_C_1 = 4'd5,
    loop_nodes_C_1 = 4'd6,
    loop_horizons_C_0 = 4'd7,
    loop_horizons_C_1 = 4'd8,
    main_C_2 = 4'd9;

  reg [3:0] state_var;
  reg [3:0] state_var_NS;


  // Interconnect Declarations for Component Instantiations 
  always @(*)
  begin : bfs_core_core_fsm_1
    case (state_var)
      main_C_0 : begin
        fsm_output = 10'b0000000010;
        state_var_NS = main_C_1;
      end
      main_C_1 : begin
        fsm_output = 10'b0000000100;
        state_var_NS = loop_nodes_C_0;
      end
      loop_nodes_C_0 : begin
        fsm_output = 10'b0000001000;
        if ( loop_nodes_C_0_tr0 ) begin
          state_var_NS = loop_nodes_C_1;
        end
        else begin
          state_var_NS = loop_neighbors_C_0;
        end
      end
      loop_neighbors_C_0 : begin
        fsm_output = 10'b0000010000;
        state_var_NS = loop_neighbors_C_1;
      end
      loop_neighbors_C_1 : begin
        fsm_output = 10'b0000100000;
        if ( loop_neighbors_C_1_tr0 ) begin
          state_var_NS = loop_nodes_C_1;
        end
        else begin
          state_var_NS = loop_neighbors_C_0;
        end
      end
      loop_nodes_C_1 : begin
        fsm_output = 10'b0001000000;
        if ( loop_nodes_C_1_tr0 ) begin
          state_var_NS = loop_horizons_C_0;
        end
        else begin
          state_var_NS = loop_nodes_C_0;
        end
      end
      loop_horizons_C_0 : begin
        fsm_output = 10'b0010000000;
        state_var_NS = loop_horizons_C_1;
      end
      loop_horizons_C_1 : begin
        fsm_output = 10'b0100000000;
        if ( loop_horizons_C_1_tr0 ) begin
          state_var_NS = main_C_2;
        end
        else begin
          state_var_NS = loop_nodes_C_0;
        end
      end
      main_C_2 : begin
        fsm_output = 10'b1000000000;
        state_var_NS = main_C_0;
      end
      // core_rlp_C_0
      default : begin
        fsm_output = 10'b0000000001;
        state_var_NS = main_C_0;
      end
    endcase
  end

  always @(posedge clk) begin
    if ( rst ) begin
      state_var <= core_rlp_C_0;
    end
    else begin
      state_var <= state_var_NS;
    end
  end

endmodule

// ------------------------------------------------------------------
//  Design Unit:    bfs_core
// ------------------------------------------------------------------


module bfs_core (
  clk, rst, nodes_edge_begin_rsc_dat, nodes_edge_begin_triosy_lz, nodes_edge_end_rsc_dat,
      nodes_edge_end_triosy_lz, edges_dst_triosy_lz, starting_node_rsc_dat, starting_node_triosy_lz,
      level_rsc_zout, level_rsc_lzout, level_rsc_zin, level_triosy_lz, level_counts_rsc_dat,
      level_counts_triosy_lz, edges_dst_rsci_addr_rd_d, edges_dst_rsci_re_d, edges_dst_rsci_data_out_d
);
  input clk;
  input rst;
  input [1023:0] nodes_edge_begin_rsc_dat;
  output nodes_edge_begin_triosy_lz;
  input [1023:0] nodes_edge_end_rsc_dat;
  output nodes_edge_end_triosy_lz;
  output edges_dst_triosy_lz;
  input [63:0] starting_node_rsc_dat;
  output starting_node_triosy_lz;
  output [127:0] level_rsc_zout;
  output level_rsc_lzout;
  input [127:0] level_rsc_zin;
  output level_triosy_lz;
  output [639:0] level_counts_rsc_dat;
  output level_counts_triosy_lz;
  output [5:0] edges_dst_rsci_addr_rd_d;
  output edges_dst_rsci_re_d;
  input [63:0] edges_dst_rsci_data_out_d;


  // Interconnect Declarations
  wire [1023:0] nodes_edge_begin_rsci_idat;
  wire [1023:0] nodes_edge_end_rsci_idat;
  wire [63:0] starting_node_rsci_idat;
  wire [127:0] level_rsci_din;
  reg [63:0] level_counts_rsci_idat_639_576;
  reg [63:0] level_counts_rsci_idat_575_512;
  reg [63:0] level_counts_rsci_idat_511_448;
  reg [63:0] level_counts_rsci_idat_447_384;
  reg [63:0] level_counts_rsci_idat_383_320;
  reg [63:0] level_counts_rsci_idat_319_256;
  reg [63:0] level_counts_rsci_idat_255_192;
  reg [63:0] level_counts_rsci_idat_191_128;
  reg [63:0] level_counts_rsci_idat_127_64;
  wire [9:0] fsm_output;
  wire loop_horizons_loop_horizons_if_nor_tmp;
  wire loop_horizons_or_tmp;
  wire [3:0] loop_horizons_acc_1_tmp;
  wire [4:0] nl_loop_horizons_acc_1_tmp;
  wire loop_neighbors_if_or_tmp;
  wire loop_nodes_loop_nodes_if_and_tmp;
  wire or_dcpl_6;
  wire or_dcpl_7;
  wire or_dcpl_8;
  wire or_dcpl_9;
  wire or_dcpl_10;
  wire or_dcpl_11;
  wire or_dcpl_12;
  wire or_dcpl_13;
  wire or_dcpl_14;
  wire or_dcpl_15;
  wire or_dcpl_16;
  wire or_dcpl_17;
  wire or_dcpl_18;
  wire or_dcpl_19;
  wire or_dcpl_20;
  wire or_dcpl_21;
  wire and_dcpl_18;
  wire or_dcpl_22;
  wire or_dcpl_23;
  wire and_dcpl_20;
  wire or_dcpl_25;
  wire and_dcpl_22;
  wire or_dcpl_27;
  wire and_dcpl_24;
  wire or_dcpl_29;
  wire or_dcpl_30;
  wire and_dcpl_30;
  wire or_dcpl_35;
  wire and_dcpl_35;
  wire or_dcpl_40;
  wire or_tmp_111;
  reg exit_loop_neighbors_sva;
  reg loop_horizons_slc_loop_horizons_acc_3_itm;
  wire equal_tmp_18;
  wire equal_tmp_20;
  wire equal_tmp_22;
  wire equal_tmp_24;
  wire equal_tmp_26;
  wire equal_tmp_28;
  wire equal_tmp_30;
  wire equal_tmp_29;
  wire equal_tmp_27;
  wire equal_tmp_25;
  wire equal_tmp_23;
  wire equal_tmp_21;
  wire equal_tmp_19;
  wire equal_tmp_17;
  wire equal_tmp_16;
  reg loop_horizons_loop_horizons_if_nor_itm;
  reg loop_neighbors_loop_neighbors_nand_itm;
  reg reg_level_counts_triosy_obj_ld_cse;
  wire loop_neighbors_if_nor_2_cse;
  wire loop_neighbors_if_nor_9_cse;
  wire loop_neighbors_if_equal_tmp_16;
  wire loop_neighbors_if_equal_tmp_30;
  wire loop_neighbors_if_equal_tmp_29;
  wire loop_neighbors_if_equal_tmp_28;
  wire loop_neighbors_if_equal_tmp_27;
  wire loop_neighbors_if_equal_tmp_26;
  wire loop_neighbors_if_equal_tmp_25;
  wire loop_neighbors_if_equal_tmp_24;
  wire loop_neighbors_if_equal_tmp_23;
  wire loop_neighbors_if_equal_tmp_22;
  wire loop_neighbors_if_equal_tmp_21;
  wire loop_neighbors_if_equal_tmp_20;
  wire loop_neighbors_if_equal_tmp_19;
  wire loop_neighbors_if_equal_tmp_18;
  wire loop_neighbors_if_equal_tmp_17;
  wire exs_33_0;
  reg [63:0] e_sva;
  wire [63:0] e_sva_2;
  wire or_192_tmp;
  wire and_284_tmp;
  wire or_194_tmp;
  wire and_276_tmp;
  wire or_196_tmp;
  wire and_268_tmp;
  wire or_198_tmp;
  wire and_260_tmp;
  wire or_200_tmp;
  wire and_252_tmp;
  wire or_202_tmp;
  wire and_244_tmp;
  wire or_204_tmp;
  wire and_236_tmp;
  wire or_206_tmp;
  wire and_228_tmp;
  wire or_208_tmp;
  wire and_220_tmp;
  wire or_210_tmp;
  wire and_212_tmp;
  wire or_212_tmp;
  wire and_204_tmp;
  wire or_214_tmp;
  wire and_196_tmp;
  wire or_216_tmp;
  wire and_188_tmp;
  wire or_218_tmp;
  wire and_180_tmp;
  wire or_220_tmp;
  wire and_172_tmp;
  wire or_222_tmp;
  wire and_422_cse;
  wire [63:0] z_out;
  wire [64:0] nl_z_out;
  wire [7:0] z_out_1;
  reg [63:0] level_counts_rsc_1_319_256_lpi_2;
  reg [63:0] level_counts_rsc_1_383_320_lpi_2;
  reg [63:0] level_counts_rsc_1_255_192_lpi_2;
  reg [63:0] level_counts_rsc_1_447_384_lpi_2;
  reg [63:0] level_counts_rsc_1_191_128_lpi_2;
  reg [63:0] level_counts_rsc_1_511_448_lpi_2;
  reg [63:0] level_counts_rsc_1_127_64_lpi_2;
  reg [63:0] level_counts_rsc_1_575_512_lpi_2;
  reg [63:0] level_counts_rsc_1_639_576_lpi_2;
  reg [3:0] horizon_3_0_sva;
  reg [63:0] cnt_lpi_4;
  reg [63:0] loop_nodes_if_tmp_end_sva;
  reg [3:0] n_4_0_sva_3_0;
  wire [63:0] loop_nodes_if_tmp_end_sva_1;
  wire [63:0] e_e_mux_cse;
  wire z_out_2_64;

  wire and_109_nl;
  wire and_115_nl;
  wire and_121_nl;
  wire and_127_nl;
  wire and_133_nl;
  wire and_139_nl;
  wire and_145_nl;
  wire and_151_nl;
  wire and_157_nl;
  wire nor_nl;
  wire not_266_nl;
  wire not_267_nl;
  wire[59:0] loop_neighbors_if_loop_neighbors_if_and_16_nl;
  wire[59:0] loop_neighbors_if_mux_1_nl;
  wire loop_neighbors_if_nor_11_nl;
  wire[3:0] loop_neighbors_if_mux1h_2_nl;
  wire[65:0] acc_1_nl;
  wire[66:0] nl_acc_1_nl;
  wire[63:0] loop_neighbors_mux_3_nl;
  wire[3:0] loop_nodes_if_mux_18_nl;

  // Interconnect Declarations for Component Instantiations 
  wire  nl_level_rsci_ldout;
  assign nl_level_rsci_ldout = (fsm_output[1]) | ((z_out_1==8'b01111111) & (fsm_output[4]));
  wire[3:0] and_426_nl;
  wire nor_16_nl;
  wire[3:0] mux1h_16_nl;
  wire nor_32_nl;
  wire and_428_nl;
  wire[3:0] and_429_nl;
  wire nor_17_nl;
  wire[3:0] mux1h_17_nl;
  wire nor_33_nl;
  wire and_431_nl;
  wire[3:0] and_432_nl;
  wire nor_18_nl;
  wire[3:0] mux1h_18_nl;
  wire nor_34_nl;
  wire and_434_nl;
  wire[3:0] and_435_nl;
  wire nor_19_nl;
  wire[3:0] mux1h_19_nl;
  wire nor_35_nl;
  wire and_437_nl;
  wire[3:0] and_438_nl;
  wire nor_20_nl;
  wire[3:0] mux1h_20_nl;
  wire nor_36_nl;
  wire and_440_nl;
  wire[3:0] and_441_nl;
  wire nor_21_nl;
  wire[3:0] mux1h_21_nl;
  wire nor_37_nl;
  wire and_443_nl;
  wire[3:0] and_444_nl;
  wire nor_22_nl;
  wire[3:0] mux1h_22_nl;
  wire nor_38_nl;
  wire and_446_nl;
  wire[3:0] and_447_nl;
  wire nor_23_nl;
  wire[3:0] mux1h_23_nl;
  wire nor_39_nl;
  wire and_449_nl;
  wire[3:0] and_450_nl;
  wire nor_24_nl;
  wire[3:0] mux1h_24_nl;
  wire nor_40_nl;
  wire and_452_nl;
  wire[3:0] and_453_nl;
  wire nor_25_nl;
  wire[3:0] mux1h_25_nl;
  wire nor_41_nl;
  wire and_455_nl;
  wire[3:0] and_456_nl;
  wire nor_26_nl;
  wire[3:0] mux1h_26_nl;
  wire nor_42_nl;
  wire and_458_nl;
  wire[3:0] and_459_nl;
  wire nor_27_nl;
  wire[3:0] mux1h_27_nl;
  wire nor_43_nl;
  wire and_461_nl;
  wire[3:0] and_462_nl;
  wire nor_28_nl;
  wire[3:0] mux1h_28_nl;
  wire nor_44_nl;
  wire and_464_nl;
  wire[3:0] and_465_nl;
  wire nor_29_nl;
  wire[3:0] mux1h_29_nl;
  wire nor_45_nl;
  wire and_467_nl;
  wire[3:0] and_468_nl;
  wire nor_30_nl;
  wire[3:0] mux1h_30_nl;
  wire nor_46_nl;
  wire and_470_nl;
  wire[3:0] and_471_nl;
  wire nor_31_nl;
  wire[3:0] mux1h_nl;
  wire nor_47_nl;
  wire and_473_nl;
  wire [127:0] nl_level_rsci_dout;
  assign nor_16_nl = ~((equal_tmp_16 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_16
      & (fsm_output[4])));
  assign and_426_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[127:124]), nor_16_nl);
  assign nor_32_nl = ~(and_284_tmp | or_192_tmp);
  assign and_428_nl = and_284_tmp & (~ or_192_tmp);
  assign mux1h_16_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_16)), loop_horizons_acc_1_tmp,
      (level_rsci_din[123:120]), {nor_32_nl , and_428_nl , or_192_tmp});
  assign nor_17_nl = ~((equal_tmp_17 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_30
      & (fsm_output[4])));
  assign and_429_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[119:116]), nor_17_nl);
  assign nor_33_nl = ~(and_276_tmp | or_194_tmp);
  assign and_431_nl = and_276_tmp & (~ or_194_tmp);
  assign mux1h_17_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_17)), loop_horizons_acc_1_tmp,
      (level_rsci_din[115:112]), {nor_33_nl , and_431_nl , or_194_tmp});
  assign nor_18_nl = ~((equal_tmp_19 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_29
      & (fsm_output[4])));
  assign and_432_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[111:108]), nor_18_nl);
  assign nor_34_nl = ~(and_268_tmp | or_196_tmp);
  assign and_434_nl = and_268_tmp & (~ or_196_tmp);
  assign mux1h_18_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_19)), loop_horizons_acc_1_tmp,
      (level_rsci_din[107:104]), {nor_34_nl , and_434_nl , or_196_tmp});
  assign nor_19_nl = ~((equal_tmp_21 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_28
      & (fsm_output[4])));
  assign and_435_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[103:100]), nor_19_nl);
  assign nor_35_nl = ~(and_260_tmp | or_198_tmp);
  assign and_437_nl = and_260_tmp & (~ or_198_tmp);
  assign mux1h_19_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_21)), loop_horizons_acc_1_tmp,
      (level_rsci_din[99:96]), {nor_35_nl , and_437_nl , or_198_tmp});
  assign nor_20_nl = ~((equal_tmp_23 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_27
      & (fsm_output[4])));
  assign and_438_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[95:92]), nor_20_nl);
  assign nor_36_nl = ~(and_252_tmp | or_200_tmp);
  assign and_440_nl = and_252_tmp & (~ or_200_tmp);
  assign mux1h_20_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_23)), loop_horizons_acc_1_tmp,
      (level_rsci_din[91:88]), {nor_36_nl , and_440_nl , or_200_tmp});
  assign nor_21_nl = ~((equal_tmp_25 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_26
      & (fsm_output[4])));
  assign and_441_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[87:84]), nor_21_nl);
  assign nor_37_nl = ~(and_244_tmp | or_202_tmp);
  assign and_443_nl = and_244_tmp & (~ or_202_tmp);
  assign mux1h_21_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_25)), loop_horizons_acc_1_tmp,
      (level_rsci_din[83:80]), {nor_37_nl , and_443_nl , or_202_tmp});
  assign nor_22_nl = ~((equal_tmp_27 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_25
      & (fsm_output[4])));
  assign and_444_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[79:76]), nor_22_nl);
  assign nor_38_nl = ~(and_236_tmp | or_204_tmp);
  assign and_446_nl = and_236_tmp & (~ or_204_tmp);
  assign mux1h_22_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_27)), loop_horizons_acc_1_tmp,
      (level_rsci_din[75:72]), {nor_38_nl , and_446_nl , or_204_tmp});
  assign nor_23_nl = ~((equal_tmp_29 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_24
      & (fsm_output[4])));
  assign and_447_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[71:68]), nor_23_nl);
  assign nor_39_nl = ~(and_228_tmp | or_206_tmp);
  assign and_449_nl = and_228_tmp & (~ or_206_tmp);
  assign mux1h_23_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_29)), loop_horizons_acc_1_tmp,
      (level_rsci_din[67:64]), {nor_39_nl , and_449_nl , or_206_tmp});
  assign nor_24_nl = ~((equal_tmp_30 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_23
      & (fsm_output[4])));
  assign and_450_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[63:60]), nor_24_nl);
  assign nor_40_nl = ~(and_220_tmp | or_208_tmp);
  assign and_452_nl = and_220_tmp & (~ or_208_tmp);
  assign mux1h_24_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_30)), loop_horizons_acc_1_tmp,
      (level_rsci_din[59:56]), {nor_40_nl , and_452_nl , or_208_tmp});
  assign nor_25_nl = ~((equal_tmp_28 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_22
      & (fsm_output[4])));
  assign and_453_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[55:52]), nor_25_nl);
  assign nor_41_nl = ~(and_212_tmp | or_210_tmp);
  assign and_455_nl = and_212_tmp & (~ or_210_tmp);
  assign mux1h_25_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_28)), loop_horizons_acc_1_tmp,
      (level_rsci_din[51:48]), {nor_41_nl , and_455_nl , or_210_tmp});
  assign nor_26_nl = ~((equal_tmp_26 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_21
      & (fsm_output[4])));
  assign and_456_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[47:44]), nor_26_nl);
  assign nor_42_nl = ~(and_204_tmp | or_212_tmp);
  assign and_458_nl = and_204_tmp & (~ or_212_tmp);
  assign mux1h_26_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_26)), loop_horizons_acc_1_tmp,
      (level_rsci_din[43:40]), {nor_42_nl , and_458_nl , or_212_tmp});
  assign nor_27_nl = ~((equal_tmp_24 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_20
      & (fsm_output[4])));
  assign and_459_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[39:36]), nor_27_nl);
  assign nor_43_nl = ~(and_196_tmp | or_214_tmp);
  assign and_461_nl = and_196_tmp & (~ or_214_tmp);
  assign mux1h_27_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_24)), loop_horizons_acc_1_tmp,
      (level_rsci_din[35:32]), {nor_43_nl , and_461_nl , or_214_tmp});
  assign nor_28_nl = ~((equal_tmp_22 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_19
      & (fsm_output[4])));
  assign and_462_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[31:28]), nor_28_nl);
  assign nor_44_nl = ~(and_188_tmp | or_216_tmp);
  assign and_464_nl = and_188_tmp & (~ or_216_tmp);
  assign mux1h_28_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_22)), loop_horizons_acc_1_tmp,
      (level_rsci_din[27:24]), {nor_44_nl , and_464_nl , or_216_tmp});
  assign nor_29_nl = ~((equal_tmp_20 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_18
      & (fsm_output[4])));
  assign and_465_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[23:20]), nor_29_nl);
  assign nor_45_nl = ~(and_180_tmp | or_218_tmp);
  assign and_467_nl = and_180_tmp & (~ or_218_tmp);
  assign mux1h_29_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_20)), loop_horizons_acc_1_tmp,
      (level_rsci_din[19:16]), {nor_45_nl , and_467_nl , or_218_tmp});
  assign nor_30_nl = ~((equal_tmp_18 & (~ (fsm_output[4]))) | (loop_neighbors_if_equal_tmp_17
      & (fsm_output[4])));
  assign and_468_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[15:12]), nor_30_nl);
  assign nor_46_nl = ~(and_172_tmp | or_220_tmp);
  assign and_470_nl = and_172_tmp & (~ or_220_tmp);
  assign mux1h_30_nl = MUX1HOT_v_4_3_2((signext_4_1(~ equal_tmp_18)), loop_horizons_acc_1_tmp,
      (level_rsci_din[11:8]), {nor_46_nl , and_470_nl , or_220_tmp});
  assign nor_31_nl = ~((~(exs_33_0 | (fsm_output[4]))) | and_422_cse);
  assign and_471_nl = MUX_v_4_2_2(4'b0000, (level_rsci_din[7:4]), nor_31_nl);
  assign nor_47_nl = ~(and_422_cse | or_222_tmp);
  assign and_473_nl = and_422_cse & (~ or_222_tmp);
  assign mux1h_nl = MUX1HOT_v_4_3_2(({{3{exs_33_0}}, exs_33_0}), loop_horizons_acc_1_tmp,
      (level_rsci_din[3:0]), {nor_47_nl , and_473_nl , or_222_tmp});
  assign nl_level_rsci_dout = {and_426_nl , mux1h_16_nl , and_429_nl , mux1h_17_nl
      , and_432_nl , mux1h_18_nl , and_435_nl , mux1h_19_nl , and_438_nl , mux1h_20_nl
      , and_441_nl , mux1h_21_nl , and_444_nl , mux1h_22_nl , and_447_nl , mux1h_23_nl
      , and_450_nl , mux1h_24_nl , and_453_nl , mux1h_25_nl , and_456_nl , mux1h_26_nl
      , and_459_nl , mux1h_27_nl , and_462_nl , mux1h_28_nl , and_465_nl , mux1h_29_nl
      , and_468_nl , mux1h_30_nl , and_471_nl , mux1h_nl};
  wire [639:0] nl_level_counts_rsci_idat;
  assign nl_level_counts_rsci_idat = {level_counts_rsci_idat_639_576 , level_counts_rsci_idat_575_512
      , level_counts_rsci_idat_511_448 , level_counts_rsci_idat_447_384 , level_counts_rsci_idat_383_320
      , level_counts_rsci_idat_319_256 , level_counts_rsci_idat_255_192 , level_counts_rsci_idat_191_128
      , level_counts_rsci_idat_127_64 , 64'b0000000000000000000000000000000000000000000000000000000000000001};
  wire  nl_bfs_core_core_fsm_inst_loop_nodes_C_0_tr0;
  assign nl_bfs_core_core_fsm_inst_loop_nodes_C_0_tr0 = ~(loop_nodes_loop_nodes_if_and_tmp
      & z_out_2_64);
  wire  nl_bfs_core_core_fsm_inst_loop_nodes_C_1_tr0;
  assign nl_bfs_core_core_fsm_inst_loop_nodes_C_1_tr0 = z_out[4];
  ccs_in_v1 #(.rscid(32'sd1),
  .width(32'sd1024)) nodes_edge_begin_rsci (
      .dat(nodes_edge_begin_rsc_dat),
      .idat(nodes_edge_begin_rsci_idat)
    );
  ccs_in_v1 #(.rscid(32'sd2),
  .width(32'sd1024)) nodes_edge_end_rsci (
      .dat(nodes_edge_end_rsc_dat),
      .idat(nodes_edge_end_rsci_idat)
    );
  ccs_in_v1 #(.rscid(32'sd4),
  .width(32'sd64)) starting_node_rsci (
      .dat(starting_node_rsc_dat),
      .idat(starting_node_rsci_idat)
    );
  mgc_inout_prereg_en_v1 #(.rscid(32'sd5),
  .width(32'sd128)) level_rsci (
      .din(level_rsci_din),
      .ldout(nl_level_rsci_ldout),
      .dout(nl_level_rsci_dout[127:0]),
      .zin(level_rsc_zin),
      .lzout(level_rsc_lzout),
      .zout(level_rsc_zout)
    );
  ccs_out_v1 #(.rscid(32'sd6),
  .width(32'sd640)) level_counts_rsci (
      .idat(nl_level_counts_rsci_idat[639:0]),
      .dat(level_counts_rsc_dat)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) nodes_edge_begin_triosy_obj (
      .ld(reg_level_counts_triosy_obj_ld_cse),
      .lz(nodes_edge_begin_triosy_lz)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) nodes_edge_end_triosy_obj (
      .ld(reg_level_counts_triosy_obj_ld_cse),
      .lz(nodes_edge_end_triosy_lz)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) edges_dst_triosy_obj (
      .ld(reg_level_counts_triosy_obj_ld_cse),
      .lz(edges_dst_triosy_lz)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) starting_node_triosy_obj (
      .ld(reg_level_counts_triosy_obj_ld_cse),
      .lz(starting_node_triosy_lz)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) level_triosy_obj (
      .ld(reg_level_counts_triosy_obj_ld_cse),
      .lz(level_triosy_lz)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) level_counts_triosy_obj (
      .ld(reg_level_counts_triosy_obj_ld_cse),
      .lz(level_counts_triosy_lz)
    );
  bfs_core_core_fsm bfs_core_core_fsm_inst (
      .clk(clk),
      .rst(rst),
      .fsm_output(fsm_output),
      .loop_nodes_C_0_tr0(nl_bfs_core_core_fsm_inst_loop_nodes_C_0_tr0),
      .loop_neighbors_C_1_tr0(exit_loop_neighbors_sva),
      .loop_nodes_C_1_tr0(nl_bfs_core_core_fsm_inst_loop_nodes_C_1_tr0),
      .loop_horizons_C_1_tr0(or_dcpl_6)
    );
  assign e_e_mux_cse = MUX_v_64_2_2(e_sva_2, z_out, fsm_output[4]);
  assign equal_tmp_16 = (starting_node_rsci_idat[3:0]==4'b1111);
  assign equal_tmp_17 = (starting_node_rsci_idat[3:0]==4'b1110);
  assign equal_tmp_18 = (starting_node_rsci_idat[3:0]==4'b0001);
  assign equal_tmp_19 = (starting_node_rsci_idat[3:0]==4'b1101);
  assign equal_tmp_20 = (starting_node_rsci_idat[3:0]==4'b0010);
  assign equal_tmp_21 = (starting_node_rsci_idat[3:0]==4'b1100);
  assign equal_tmp_22 = (starting_node_rsci_idat[3:0]==4'b0011);
  assign equal_tmp_23 = (starting_node_rsci_idat[3:0]==4'b1011);
  assign equal_tmp_24 = (starting_node_rsci_idat[3:0]==4'b0100);
  assign equal_tmp_25 = (starting_node_rsci_idat[3:0]==4'b1010);
  assign equal_tmp_26 = (starting_node_rsci_idat[3:0]==4'b0101);
  assign equal_tmp_27 = (starting_node_rsci_idat[3:0]==4'b1001);
  assign equal_tmp_28 = (starting_node_rsci_idat[3:0]==4'b0110);
  assign equal_tmp_29 = (starting_node_rsci_idat[3:0]==4'b1000);
  assign equal_tmp_30 = (starting_node_rsci_idat[3:0]==4'b0111);
  assign exs_33_0 = equal_tmp_18 | equal_tmp_20 | equal_tmp_22 | equal_tmp_24 | equal_tmp_26
      | equal_tmp_28 | equal_tmp_30 | equal_tmp_29 | equal_tmp_27 | equal_tmp_25
      | equal_tmp_23 | equal_tmp_21 | equal_tmp_19 | equal_tmp_17 | equal_tmp_16;
  assign nl_loop_horizons_acc_1_tmp = horizon_3_0_sva + 4'b0001;
  assign loop_horizons_acc_1_tmp = nl_loop_horizons_acc_1_tmp[3:0];
  assign loop_nodes_loop_nodes_if_and_tmp = ((z_out_1[3:0]) == (horizon_3_0_sva))
      & (z_out_1[7:4]==4'b0000);
  assign loop_nodes_if_tmp_end_sva_1 = MUX_v_64_16_2((nodes_edge_end_rsci_idat[63:0]),
      (nodes_edge_end_rsci_idat[127:64]), (nodes_edge_end_rsci_idat[191:128]), (nodes_edge_end_rsci_idat[255:192]),
      (nodes_edge_end_rsci_idat[319:256]), (nodes_edge_end_rsci_idat[383:320]), (nodes_edge_end_rsci_idat[447:384]),
      (nodes_edge_end_rsci_idat[511:448]), (nodes_edge_end_rsci_idat[575:512]), (nodes_edge_end_rsci_idat[639:576]),
      (nodes_edge_end_rsci_idat[703:640]), (nodes_edge_end_rsci_idat[767:704]), (nodes_edge_end_rsci_idat[831:768]),
      (nodes_edge_end_rsci_idat[895:832]), (nodes_edge_end_rsci_idat[959:896]), (nodes_edge_end_rsci_idat[1023:960]),
      n_4_0_sva_3_0);
  assign e_sva_2 = MUX_v_64_16_2((nodes_edge_begin_rsci_idat[63:0]), (nodes_edge_begin_rsci_idat[127:64]),
      (nodes_edge_begin_rsci_idat[191:128]), (nodes_edge_begin_rsci_idat[255:192]),
      (nodes_edge_begin_rsci_idat[319:256]), (nodes_edge_begin_rsci_idat[383:320]),
      (nodes_edge_begin_rsci_idat[447:384]), (nodes_edge_begin_rsci_idat[511:448]),
      (nodes_edge_begin_rsci_idat[575:512]), (nodes_edge_begin_rsci_idat[639:576]),
      (nodes_edge_begin_rsci_idat[703:640]), (nodes_edge_begin_rsci_idat[767:704]),
      (nodes_edge_begin_rsci_idat[831:768]), (nodes_edge_begin_rsci_idat[895:832]),
      (nodes_edge_begin_rsci_idat[959:896]), (nodes_edge_begin_rsci_idat[1023:960]),
      n_4_0_sva_3_0);
  assign loop_neighbors_if_equal_tmp_16 = (edges_dst_rsci_data_out_d[3:0]==4'b1111);
  assign loop_neighbors_if_or_tmp = loop_neighbors_if_equal_tmp_17 | loop_neighbors_if_equal_tmp_18
      | loop_neighbors_if_equal_tmp_19 | loop_neighbors_if_equal_tmp_20 | loop_neighbors_if_equal_tmp_21
      | loop_neighbors_if_equal_tmp_22 | loop_neighbors_if_equal_tmp_23 | loop_neighbors_if_equal_tmp_24
      | loop_neighbors_if_equal_tmp_25 | loop_neighbors_if_equal_tmp_26 | loop_neighbors_if_equal_tmp_27
      | loop_neighbors_if_equal_tmp_28 | loop_neighbors_if_equal_tmp_29 | loop_neighbors_if_equal_tmp_30
      | loop_neighbors_if_equal_tmp_16;
  assign loop_neighbors_if_equal_tmp_17 = (edges_dst_rsci_data_out_d[3:0]==4'b0001);
  assign loop_neighbors_if_equal_tmp_18 = (edges_dst_rsci_data_out_d[3:0]==4'b0010);
  assign loop_neighbors_if_nor_2_cse = ~((edges_dst_rsci_data_out_d[3:2]!=2'b00));
  assign loop_neighbors_if_equal_tmp_19 = (edges_dst_rsci_data_out_d[1:0]==2'b11)
      & loop_neighbors_if_nor_2_cse;
  assign loop_neighbors_if_equal_tmp_20 = (edges_dst_rsci_data_out_d[3:0]==4'b0100);
  assign loop_neighbors_if_equal_tmp_21 = (edges_dst_rsci_data_out_d[3:0]==4'b0101);
  assign loop_neighbors_if_equal_tmp_22 = (edges_dst_rsci_data_out_d[3:0]==4'b0110);
  assign loop_neighbors_if_equal_tmp_23 = (edges_dst_rsci_data_out_d[3:0]==4'b0111);
  assign loop_neighbors_if_equal_tmp_24 = (edges_dst_rsci_data_out_d[3:0]==4'b1000);
  assign loop_neighbors_if_equal_tmp_25 = (edges_dst_rsci_data_out_d[3:0]==4'b1001);
  assign loop_neighbors_if_equal_tmp_26 = (edges_dst_rsci_data_out_d[3:0]==4'b1010);
  assign loop_neighbors_if_equal_tmp_27 = (edges_dst_rsci_data_out_d[3:0]==4'b1011);
  assign loop_neighbors_if_nor_9_cse = ~((edges_dst_rsci_data_out_d[1:0]!=2'b00));
  assign loop_neighbors_if_equal_tmp_28 = (edges_dst_rsci_data_out_d[3:2]==2'b11)
      & loop_neighbors_if_nor_9_cse;
  assign loop_neighbors_if_equal_tmp_29 = (edges_dst_rsci_data_out_d[3:0]==4'b1101);
  assign loop_neighbors_if_equal_tmp_30 = (edges_dst_rsci_data_out_d[3:0]==4'b1110);
  assign loop_horizons_loop_horizons_if_nor_tmp = ~((cnt_lpi_4!=64'b0000000000000000000000000000000000000000000000000000000000000000));
  assign loop_horizons_or_tmp = ~((loop_horizons_acc_1_tmp==4'b0001));
  assign or_dcpl_6 = (~ loop_horizons_slc_loop_horizons_acc_3_itm) | loop_horizons_loop_horizons_if_nor_itm;
  assign or_dcpl_7 = (loop_horizons_acc_1_tmp[1:0]!=2'b10);
  assign or_dcpl_8 = (loop_horizons_acc_1_tmp[3:2]!=2'b00);
  assign or_dcpl_9 = or_dcpl_8 | or_dcpl_7;
  assign or_dcpl_10 = ~((loop_horizons_acc_1_tmp[1:0]==2'b11));
  assign or_dcpl_11 = or_dcpl_8 | or_dcpl_10;
  assign or_dcpl_12 = (loop_horizons_acc_1_tmp[1:0]!=2'b00);
  assign or_dcpl_13 = (loop_horizons_acc_1_tmp[3:2]!=2'b01);
  assign or_dcpl_14 = or_dcpl_13 | or_dcpl_12;
  assign or_dcpl_15 = (loop_horizons_acc_1_tmp[1:0]!=2'b01);
  assign or_dcpl_16 = or_dcpl_13 | or_dcpl_15;
  assign or_dcpl_17 = or_dcpl_13 | or_dcpl_7;
  assign or_dcpl_18 = or_dcpl_13 | or_dcpl_10;
  assign or_dcpl_19 = (loop_horizons_acc_1_tmp[3:2]!=2'b10);
  assign or_dcpl_20 = or_dcpl_19 | or_dcpl_12;
  assign or_dcpl_21 = or_dcpl_19 | or_dcpl_15;
  assign and_dcpl_18 = (edges_dst_rsci_data_out_d[1:0]==2'b01);
  assign or_dcpl_22 = (edges_dst_rsci_data_out_d[3:2]!=2'b00);
  assign or_dcpl_23 = (edges_dst_rsci_data_out_d[1:0]!=2'b01);
  assign and_dcpl_20 = (edges_dst_rsci_data_out_d[1:0]==2'b10);
  assign or_dcpl_25 = (edges_dst_rsci_data_out_d[1:0]!=2'b10);
  assign and_dcpl_22 = (edges_dst_rsci_data_out_d[1:0]==2'b11);
  assign or_dcpl_27 = ~((edges_dst_rsci_data_out_d[1:0]==2'b11));
  assign and_dcpl_24 = (edges_dst_rsci_data_out_d[3:2]==2'b01);
  assign or_dcpl_29 = (edges_dst_rsci_data_out_d[3:2]!=2'b01);
  assign or_dcpl_30 = (edges_dst_rsci_data_out_d[1:0]!=2'b00);
  assign and_dcpl_30 = (edges_dst_rsci_data_out_d[3:2]==2'b10);
  assign or_dcpl_35 = (edges_dst_rsci_data_out_d[3:2]!=2'b10);
  assign and_dcpl_35 = (edges_dst_rsci_data_out_d[3:2]==2'b11);
  assign or_dcpl_40 = ~((edges_dst_rsci_data_out_d[3:2]==2'b11));
  assign or_tmp_111 = (fsm_output[8]) | (fsm_output[2]);
  assign edges_dst_rsci_addr_rd_d = MUX_v_6_2_2((e_sva[5:0]), (e_sva_2[5:0]), fsm_output[3]);
  assign edges_dst_rsci_re_d = ~((loop_nodes_loop_nodes_if_and_tmp & z_out_2_64 &
      (fsm_output[3])) | ((~ exit_loop_neighbors_sva) & (fsm_output[5])));
  assign or_192_tmp = ((~ equal_tmp_16) & (fsm_output[1])) | ((or_dcpl_27 | or_dcpl_40)
      & (fsm_output[4]));
  assign and_284_tmp = and_dcpl_22 & and_dcpl_35 & (fsm_output[4]);
  assign or_194_tmp = ((~ equal_tmp_17) & (fsm_output[1])) | ((or_dcpl_25 | or_dcpl_40)
      & (fsm_output[4]));
  assign and_276_tmp = and_dcpl_20 & and_dcpl_35 & (fsm_output[4]);
  assign or_196_tmp = ((~ equal_tmp_19) & (fsm_output[1])) | ((or_dcpl_23 | or_dcpl_40)
      & (fsm_output[4]));
  assign and_268_tmp = and_dcpl_18 & and_dcpl_35 & (fsm_output[4]);
  assign or_198_tmp = ((~ equal_tmp_21) & (fsm_output[1])) | ((or_dcpl_30 | or_dcpl_40)
      & (fsm_output[4]));
  assign and_260_tmp = loop_neighbors_if_nor_9_cse & and_dcpl_35 & (fsm_output[4]);
  assign or_200_tmp = ((~ equal_tmp_23) & (fsm_output[1])) | ((or_dcpl_27 | or_dcpl_35)
      & (fsm_output[4]));
  assign and_252_tmp = and_dcpl_22 & and_dcpl_30 & (fsm_output[4]);
  assign or_202_tmp = ((~ equal_tmp_25) & (fsm_output[1])) | ((or_dcpl_25 | or_dcpl_35)
      & (fsm_output[4]));
  assign and_244_tmp = and_dcpl_20 & and_dcpl_30 & (fsm_output[4]);
  assign or_204_tmp = ((~ equal_tmp_27) & (fsm_output[1])) | ((or_dcpl_23 | or_dcpl_35)
      & (fsm_output[4]));
  assign and_236_tmp = and_dcpl_18 & and_dcpl_30 & (fsm_output[4]);
  assign or_206_tmp = ((~ equal_tmp_29) & (fsm_output[1])) | ((or_dcpl_30 | or_dcpl_35)
      & (fsm_output[4]));
  assign and_228_tmp = loop_neighbors_if_nor_9_cse & and_dcpl_30 & (fsm_output[4]);
  assign or_208_tmp = ((~ equal_tmp_30) & (fsm_output[1])) | ((or_dcpl_27 | or_dcpl_29)
      & (fsm_output[4]));
  assign and_220_tmp = and_dcpl_22 & and_dcpl_24 & (fsm_output[4]);
  assign or_210_tmp = ((~ equal_tmp_28) & (fsm_output[1])) | ((or_dcpl_25 | or_dcpl_29)
      & (fsm_output[4]));
  assign and_212_tmp = and_dcpl_20 & and_dcpl_24 & (fsm_output[4]);
  assign or_212_tmp = ((~ equal_tmp_26) & (fsm_output[1])) | ((or_dcpl_23 | or_dcpl_29)
      & (fsm_output[4]));
  assign and_204_tmp = and_dcpl_18 & and_dcpl_24 & (fsm_output[4]);
  assign or_214_tmp = ((~ equal_tmp_24) & (fsm_output[1])) | ((or_dcpl_30 | or_dcpl_29)
      & (fsm_output[4]));
  assign and_196_tmp = loop_neighbors_if_nor_9_cse & and_dcpl_24 & (fsm_output[4]);
  assign or_216_tmp = ((~ equal_tmp_22) & (fsm_output[1])) | ((or_dcpl_27 | or_dcpl_22)
      & (fsm_output[4]));
  assign and_188_tmp = and_dcpl_22 & loop_neighbors_if_nor_2_cse & (fsm_output[4]);
  assign or_218_tmp = ((~ equal_tmp_20) & (fsm_output[1])) | ((or_dcpl_25 | or_dcpl_22)
      & (fsm_output[4]));
  assign and_180_tmp = and_dcpl_20 & loop_neighbors_if_nor_2_cse & (fsm_output[4]);
  assign or_220_tmp = ((~ equal_tmp_18) & (fsm_output[1])) | ((or_dcpl_23 | or_dcpl_22)
      & (fsm_output[4]));
  assign and_172_tmp = and_dcpl_18 & loop_neighbors_if_nor_2_cse & (fsm_output[4]);
  assign and_422_cse = (~ loop_neighbors_if_or_tmp) & (fsm_output[4]);
  assign or_222_tmp = (exs_33_0 & (fsm_output[1])) | (loop_neighbors_if_or_tmp &
      (fsm_output[4]));
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsci_idat_127_64 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( fsm_output[7] ) begin
      level_counts_rsci_idat_127_64 <= MUX_v_64_2_2(level_counts_rsc_1_127_64_lpi_2,
          cnt_lpi_4, and_109_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsci_idat_191_128 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( fsm_output[7] ) begin
      level_counts_rsci_idat_191_128 <= MUX_v_64_2_2(cnt_lpi_4, level_counts_rsc_1_191_128_lpi_2,
          and_115_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsci_idat_255_192 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( fsm_output[7] ) begin
      level_counts_rsci_idat_255_192 <= MUX_v_64_2_2(cnt_lpi_4, level_counts_rsc_1_255_192_lpi_2,
          and_121_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsci_idat_319_256 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( fsm_output[7] ) begin
      level_counts_rsci_idat_319_256 <= MUX_v_64_2_2(cnt_lpi_4, level_counts_rsc_1_319_256_lpi_2,
          and_127_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsci_idat_383_320 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( fsm_output[7] ) begin
      level_counts_rsci_idat_383_320 <= MUX_v_64_2_2(cnt_lpi_4, level_counts_rsc_1_383_320_lpi_2,
          and_133_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsci_idat_447_384 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( fsm_output[7] ) begin
      level_counts_rsci_idat_447_384 <= MUX_v_64_2_2(cnt_lpi_4, level_counts_rsc_1_447_384_lpi_2,
          and_139_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsci_idat_511_448 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( fsm_output[7] ) begin
      level_counts_rsci_idat_511_448 <= MUX_v_64_2_2(cnt_lpi_4, level_counts_rsc_1_511_448_lpi_2,
          and_145_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsci_idat_575_512 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( fsm_output[7] ) begin
      level_counts_rsci_idat_575_512 <= MUX_v_64_2_2(cnt_lpi_4, level_counts_rsc_1_575_512_lpi_2,
          and_151_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsci_idat_639_576 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( fsm_output[7] ) begin
      level_counts_rsci_idat_639_576 <= MUX_v_64_2_2(cnt_lpi_4, level_counts_rsc_1_639_576_lpi_2,
          and_157_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      reg_level_counts_triosy_obj_ld_cse <= 1'b0;
      exit_loop_neighbors_sva <= 1'b0;
      loop_neighbors_loop_neighbors_nand_itm <= 1'b0;
      loop_horizons_loop_horizons_if_nor_itm <= 1'b0;
    end
    else begin
      reg_level_counts_triosy_obj_ld_cse <= or_dcpl_6 & (fsm_output[8]);
      exit_loop_neighbors_sva <= ~ z_out_2_64;
      loop_neighbors_loop_neighbors_nand_itm <= ~((z_out_1==8'b01111111));
      loop_horizons_loop_horizons_if_nor_itm <= loop_horizons_loop_horizons_if_nor_tmp;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsc_1_127_64_lpi_2 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~(loop_horizons_or_tmp | (~ (fsm_output[7]))) ) begin
      level_counts_rsc_1_127_64_lpi_2 <= cnt_lpi_4;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsc_1_191_128_lpi_2 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~(or_dcpl_9 | (~ (fsm_output[7]))) ) begin
      level_counts_rsc_1_191_128_lpi_2 <= cnt_lpi_4;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsc_1_255_192_lpi_2 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~(or_dcpl_11 | (~ (fsm_output[7]))) ) begin
      level_counts_rsc_1_255_192_lpi_2 <= cnt_lpi_4;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsc_1_319_256_lpi_2 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~(or_dcpl_14 | (~ (fsm_output[7]))) ) begin
      level_counts_rsc_1_319_256_lpi_2 <= cnt_lpi_4;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsc_1_383_320_lpi_2 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~(or_dcpl_16 | (~ (fsm_output[7]))) ) begin
      level_counts_rsc_1_383_320_lpi_2 <= cnt_lpi_4;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsc_1_447_384_lpi_2 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~(or_dcpl_17 | (~ (fsm_output[7]))) ) begin
      level_counts_rsc_1_447_384_lpi_2 <= cnt_lpi_4;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsc_1_511_448_lpi_2 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~(or_dcpl_18 | (~ (fsm_output[7]))) ) begin
      level_counts_rsc_1_511_448_lpi_2 <= cnt_lpi_4;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsc_1_575_512_lpi_2 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~(or_dcpl_20 | (~ (fsm_output[7]))) ) begin
      level_counts_rsc_1_575_512_lpi_2 <= cnt_lpi_4;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      level_counts_rsc_1_639_576_lpi_2 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~(or_dcpl_21 | (~ (fsm_output[7]))) ) begin
      level_counts_rsc_1_639_576_lpi_2 <= cnt_lpi_4;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      horizon_3_0_sva <= 4'b0000;
    end
    else if ( (~((fsm_output[6:4]!=3'b000))) & (~((fsm_output[8]) | (fsm_output[3])))
        ) begin
      horizon_3_0_sva <= MUX_v_4_2_2(4'b0000, loop_horizons_acc_1_tmp, nor_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      n_4_0_sva_3_0 <= 4'b0000;
    end
    else if ( (fsm_output[6]) | or_tmp_111 ) begin
      n_4_0_sva_3_0 <= MUX_v_4_2_2(4'b0000, (z_out[3:0]), not_266_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      cnt_lpi_4 <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ((~ loop_neighbors_loop_neighbors_nand_itm) & (fsm_output[5])) | or_tmp_111
        ) begin
      cnt_lpi_4 <= MUX_v_64_2_2(64'b0000000000000000000000000000000000000000000000000000000000000000,
          z_out, not_267_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      loop_nodes_if_tmp_end_sva <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~((fsm_output[5:4]!=2'b00)) ) begin
      loop_nodes_if_tmp_end_sva <= loop_nodes_if_tmp_end_sva_1;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      e_sva <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    end
    else if ( ~ (fsm_output[5]) ) begin
      e_sva <= e_e_mux_cse;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      loop_horizons_slc_loop_horizons_acc_3_itm <= 1'b0;
    end
    else if ( ~ loop_horizons_loop_horizons_if_nor_tmp ) begin
      loop_horizons_slc_loop_horizons_acc_3_itm <= z_out[3];
    end
  end
  assign and_109_nl = (~ loop_horizons_or_tmp) & (fsm_output[7]);
  assign and_115_nl = or_dcpl_9 & (fsm_output[7]);
  assign and_121_nl = or_dcpl_11 & (fsm_output[7]);
  assign and_127_nl = or_dcpl_14 & (fsm_output[7]);
  assign and_133_nl = or_dcpl_16 & (fsm_output[7]);
  assign and_139_nl = or_dcpl_17 & (fsm_output[7]);
  assign and_145_nl = or_dcpl_18 & (fsm_output[7]);
  assign and_151_nl = or_dcpl_20 & (fsm_output[7]);
  assign and_157_nl = or_dcpl_21 & (fsm_output[7]);
  assign nor_nl = ~((fsm_output[9]) | (fsm_output[0]) | (fsm_output[1]) | (fsm_output[2]));
  assign not_266_nl = ~ or_tmp_111;
  assign not_267_nl = ~ or_tmp_111;
  assign loop_neighbors_if_mux_1_nl = MUX_v_60_2_2((cnt_lpi_4[63:4]), (e_sva[63:4]),
      fsm_output[4]);
  assign loop_neighbors_if_nor_11_nl = ~((fsm_output[7:6]!=2'b00));
  assign loop_neighbors_if_loop_neighbors_if_and_16_nl = MUX_v_60_2_2(60'b000000000000000000000000000000000000000000000000000000000000,
      loop_neighbors_if_mux_1_nl, loop_neighbors_if_nor_11_nl);
  assign loop_neighbors_if_mux1h_2_nl = MUX1HOT_v_4_4_2((cnt_lpi_4[3:0]), loop_horizons_acc_1_tmp,
      (e_sva[3:0]), n_4_0_sva_3_0, {(fsm_output[5]) , (fsm_output[7]) , (fsm_output[4])
      , (fsm_output[6])});
  assign nl_z_out = ({loop_neighbors_if_loop_neighbors_if_and_16_nl , loop_neighbors_if_mux1h_2_nl})
      + conv_u2u_3_64(signext_3_2({(fsm_output[7]) , 1'b1}));
  assign z_out = nl_z_out[63:0];
  assign loop_neighbors_mux_3_nl = MUX_v_64_2_2((~ loop_nodes_if_tmp_end_sva_1),
      (~ loop_nodes_if_tmp_end_sva), fsm_output[4]);
  assign nl_acc_1_nl = ({1'b1 , e_e_mux_cse , 1'b1}) + conv_u2u_65_66({loop_neighbors_mux_3_nl
      , 1'b1});
  assign acc_1_nl = nl_acc_1_nl[65:0];
  assign z_out_2_64 = readslicef_66_1_65(acc_1_nl);
  assign loop_nodes_if_mux_18_nl = MUX_v_4_2_2(n_4_0_sva_3_0, (edges_dst_rsci_data_out_d[3:0]),
      fsm_output[4]);
  assign z_out_1 = MUX_v_8_16_2((level_rsci_din[7:0]), (level_rsci_din[15:8]), (level_rsci_din[23:16]),
      (level_rsci_din[31:24]), (level_rsci_din[39:32]), (level_rsci_din[47:40]),
      (level_rsci_din[55:48]), (level_rsci_din[63:56]), (level_rsci_din[71:64]),
      (level_rsci_din[79:72]), (level_rsci_din[87:80]), (level_rsci_din[95:88]),
      (level_rsci_din[103:96]), (level_rsci_din[111:104]), (level_rsci_din[119:112]),
      (level_rsci_din[127:120]), loop_nodes_if_mux_18_nl);

  function automatic [3:0] MUX1HOT_v_4_3_2;
    input [3:0] input_2;
    input [3:0] input_1;
    input [3:0] input_0;
    input [2:0] sel;
    reg [3:0] result;
  begin
    result = input_0 & {4{sel[0]}};
    result = result | (input_1 & {4{sel[1]}});
    result = result | (input_2 & {4{sel[2]}});
    MUX1HOT_v_4_3_2 = result;
  end
  endfunction


  function automatic [3:0] MUX1HOT_v_4_4_2;
    input [3:0] input_3;
    input [3:0] input_2;
    input [3:0] input_1;
    input [3:0] input_0;
    input [3:0] sel;
    reg [3:0] result;
  begin
    result = input_0 & {4{sel[0]}};
    result = result | (input_1 & {4{sel[1]}});
    result = result | (input_2 & {4{sel[2]}});
    result = result | (input_3 & {4{sel[3]}});
    MUX1HOT_v_4_4_2 = result;
  end
  endfunction


  function automatic [3:0] MUX_v_4_2_2;
    input [3:0] input_0;
    input [3:0] input_1;
    input  sel;
    reg [3:0] result;
  begin
    case (sel)
      1'b0 : begin
        result = input_0;
      end
      default : begin
        result = input_1;
      end
    endcase
    MUX_v_4_2_2 = result;
  end
  endfunction


  function automatic [59:0] MUX_v_60_2_2;
    input [59:0] input_0;
    input [59:0] input_1;
    input  sel;
    reg [59:0] result;
  begin
    case (sel)
      1'b0 : begin
        result = input_0;
      end
      default : begin
        result = input_1;
      end
    endcase
    MUX_v_60_2_2 = result;
  end
  endfunction


  function automatic [63:0] MUX_v_64_16_2;
    input [63:0] input_0;
    input [63:0] input_1;
    input [63:0] input_2;
    input [63:0] input_3;
    input [63:0] input_4;
    input [63:0] input_5;
    input [63:0] input_6;
    input [63:0] input_7;
    input [63:0] input_8;
    input [63:0] input_9;
    input [63:0] input_10;
    input [63:0] input_11;
    input [63:0] input_12;
    input [63:0] input_13;
    input [63:0] input_14;
    input [63:0] input_15;
    input [3:0] sel;
    reg [63:0] result;
  begin
    case (sel)
      4'b0000 : begin
        result = input_0;
      end
      4'b0001 : begin
        result = input_1;
      end
      4'b0010 : begin
        result = input_2;
      end
      4'b0011 : begin
        result = input_3;
      end
      4'b0100 : begin
        result = input_4;
      end
      4'b0101 : begin
        result = input_5;
      end
      4'b0110 : begin
        result = input_6;
      end
      4'b0111 : begin
        result = input_7;
      end
      4'b1000 : begin
        result = input_8;
      end
      4'b1001 : begin
        result = input_9;
      end
      4'b1010 : begin
        result = input_10;
      end
      4'b1011 : begin
        result = input_11;
      end
      4'b1100 : begin
        result = input_12;
      end
      4'b1101 : begin
        result = input_13;
      end
      4'b1110 : begin
        result = input_14;
      end
      default : begin
        result = input_15;
      end
    endcase
    MUX_v_64_16_2 = result;
  end
  endfunction


  function automatic [63:0] MUX_v_64_2_2;
    input [63:0] input_0;
    input [63:0] input_1;
    input  sel;
    reg [63:0] result;
  begin
    case (sel)
      1'b0 : begin
        result = input_0;
      end
      default : begin
        result = input_1;
      end
    endcase
    MUX_v_64_2_2 = result;
  end
  endfunction


  function automatic [5:0] MUX_v_6_2_2;
    input [5:0] input_0;
    input [5:0] input_1;
    input  sel;
    reg [5:0] result;
  begin
    case (sel)
      1'b0 : begin
        result = input_0;
      end
      default : begin
        result = input_1;
      end
    endcase
    MUX_v_6_2_2 = result;
  end
  endfunction


  function automatic [7:0] MUX_v_8_16_2;
    input [7:0] input_0;
    input [7:0] input_1;
    input [7:0] input_2;
    input [7:0] input_3;
    input [7:0] input_4;
    input [7:0] input_5;
    input [7:0] input_6;
    input [7:0] input_7;
    input [7:0] input_8;
    input [7:0] input_9;
    input [7:0] input_10;
    input [7:0] input_11;
    input [7:0] input_12;
    input [7:0] input_13;
    input [7:0] input_14;
    input [7:0] input_15;
    input [3:0] sel;
    reg [7:0] result;
  begin
    case (sel)
      4'b0000 : begin
        result = input_0;
      end
      4'b0001 : begin
        result = input_1;
      end
      4'b0010 : begin
        result = input_2;
      end
      4'b0011 : begin
        result = input_3;
      end
      4'b0100 : begin
        result = input_4;
      end
      4'b0101 : begin
        result = input_5;
      end
      4'b0110 : begin
        result = input_6;
      end
      4'b0111 : begin
        result = input_7;
      end
      4'b1000 : begin
        result = input_8;
      end
      4'b1001 : begin
        result = input_9;
      end
      4'b1010 : begin
        result = input_10;
      end
      4'b1011 : begin
        result = input_11;
      end
      4'b1100 : begin
        result = input_12;
      end
      4'b1101 : begin
        result = input_13;
      end
      4'b1110 : begin
        result = input_14;
      end
      default : begin
        result = input_15;
      end
    endcase
    MUX_v_8_16_2 = result;
  end
  endfunction


  function automatic [0:0] readslicef_66_1_65;
    input [65:0] vector;
    reg [65:0] tmp;
  begin
    tmp = vector >> 65;
    readslicef_66_1_65 = tmp[0:0];
  end
  endfunction


  function automatic [2:0] signext_3_2;
    input [1:0] vector;
  begin
    signext_3_2= {{1{vector[1]}}, vector};
  end
  endfunction


  function automatic [3:0] signext_4_1;
    input  vector;
  begin
    signext_4_1= {{3{vector}}, vector};
  end
  endfunction


  function automatic [63:0] conv_u2u_3_64 ;
    input [2:0]  vector ;
  begin
    conv_u2u_3_64 = {{61{1'b0}}, vector};
  end
  endfunction


  function automatic [65:0] conv_u2u_65_66 ;
    input [64:0]  vector ;
  begin
    conv_u2u_65_66 = {1'b0, vector};
  end
  endfunction

endmodule

// ------------------------------------------------------------------
//  Design Unit:    bfs
// ------------------------------------------------------------------


module bfs (
  clk, rst, nodes_edge_begin_rsc_dat, nodes_edge_begin_triosy_lz, nodes_edge_end_rsc_dat,
      nodes_edge_end_triosy_lz, edges_dst_rsc_addr_rd, edges_dst_rsc_re, edges_dst_rsc_data_out,
      edges_dst_triosy_lz, starting_node_rsc_dat, starting_node_triosy_lz, level_rsc_zout,
      level_rsc_lzout, level_rsc_zin, level_triosy_lz, level_counts_rsc_dat, level_counts_triosy_lz
);
  input clk;
  input rst;
  input [1023:0] nodes_edge_begin_rsc_dat;
  output nodes_edge_begin_triosy_lz;
  input [1023:0] nodes_edge_end_rsc_dat;
  output nodes_edge_end_triosy_lz;
  output [5:0] edges_dst_rsc_addr_rd;
  output edges_dst_rsc_re;
  input [63:0] edges_dst_rsc_data_out;
  output edges_dst_triosy_lz;
  input [63:0] starting_node_rsc_dat;
  output starting_node_triosy_lz;
  output [127:0] level_rsc_zout;
  output level_rsc_lzout;
  input [127:0] level_rsc_zin;
  output level_triosy_lz;
  output [639:0] level_counts_rsc_dat;
  output level_counts_triosy_lz;


  // Interconnect Declarations
  wire [5:0] edges_dst_rsci_addr_rd_d;
  wire edges_dst_rsci_re_d;
  wire [63:0] edges_dst_rsci_data_out_d;


  // Interconnect Declarations for Component Instantiations 
  bfs_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_3_64_64_6_0_1_0_0_0_1_1_64_64_1_1_gen
      edges_dst_rsci (
      .data_out(edges_dst_rsc_data_out),
      .re(edges_dst_rsc_re),
      .addr_rd(edges_dst_rsc_addr_rd),
      .addr_rd_d(edges_dst_rsci_addr_rd_d),
      .re_d(edges_dst_rsci_re_d),
      .data_out_d(edges_dst_rsci_data_out_d)
    );
  bfs_core bfs_core_inst (
      .clk(clk),
      .rst(rst),
      .nodes_edge_begin_rsc_dat(nodes_edge_begin_rsc_dat),
      .nodes_edge_begin_triosy_lz(nodes_edge_begin_triosy_lz),
      .nodes_edge_end_rsc_dat(nodes_edge_end_rsc_dat),
      .nodes_edge_end_triosy_lz(nodes_edge_end_triosy_lz),
      .edges_dst_triosy_lz(edges_dst_triosy_lz),
      .starting_node_rsc_dat(starting_node_rsc_dat),
      .starting_node_triosy_lz(starting_node_triosy_lz),
      .level_rsc_zout(level_rsc_zout),
      .level_rsc_lzout(level_rsc_lzout),
      .level_rsc_zin(level_rsc_zin),
      .level_triosy_lz(level_triosy_lz),
      .level_counts_rsc_dat(level_counts_rsc_dat),
      .level_counts_triosy_lz(level_counts_triosy_lz),
      .edges_dst_rsci_addr_rd_d(edges_dst_rsci_addr_rd_d),
      .edges_dst_rsci_re_d(edges_dst_rsci_re_d),
      .edges_dst_rsci_data_out_d(edges_dst_rsci_data_out_d)
    );
endmodule



