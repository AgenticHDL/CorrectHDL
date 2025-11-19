// ----------------------------------------------------------------------
//  HLS HDL:        Verilog Netlister
//  HLS Version:    2022.2/1008433 Production Release
//  HLS Date:       Fri Aug 19 18:40:59 PDT 2022
// 


// ----------------------------------------------------------------------

// 
// ------------------------------------------------------------------
//  Design Unit:    viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rwport_en_7_512_16_9_0_1_0_0_0_1_1_16_512_1_1_gen
// ------------------------------------------------------------------


module viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rwport_en_7_512_16_9_0_1_0_0_0_1_1_16_512_1_1_gen
    (
  en, we, addr_wr, data_in, data_out, re, addr_rd, data_in_d, addr_rd_d, addr_wr_d,
      re_d, we_d, data_out_d, en_d
);
  output en;
  output we;
  output [8:0] addr_wr;
  output [15:0] data_in;
  input [15:0] data_out;
  output re;
  output [8:0] addr_rd;
  input [15:0] data_in_d;
  input [8:0] addr_rd_d;
  input [8:0] addr_wr_d;
  input re_d;
  input we_d;
  output [15:0] data_out_d;
  input en_d;



  // Interconnect Declarations for Component Instantiations 
  assign en = (en_d);
  assign we = (we_d);
  assign addr_wr = (addr_wr_d);
  assign data_in = (data_in_d);
  assign data_out_d = data_out;
  assign re = (re_d);
  assign addr_rd = (addr_rd_d);
endmodule

// ------------------------------------------------------------------
//  Design Unit:    viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rwport_5_32_8_5_0_1_0_0_0_1_1_8_32_1_1_gen
// ------------------------------------------------------------------


module viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rwport_5_32_8_5_0_1_0_0_0_1_1_8_32_1_1_gen
    (
  we, addr_wr, data_in, data_out, re, addr_rd, data_in_d, addr_rd_d, addr_wr_d, re_d,
      we_d, data_out_d
);
  output we;
  output [4:0] addr_wr;
  output [7:0] data_in;
  input [7:0] data_out;
  output re;
  output [4:0] addr_rd;
  input [7:0] data_in_d;
  input [4:0] addr_rd_d;
  input [4:0] addr_wr_d;
  input re_d;
  input we_d;
  output [7:0] data_out_d;



  // Interconnect Declarations for Component Instantiations 
  assign we = (we_d);
  assign addr_wr = (addr_wr_d);
  assign data_in = (data_in_d);
  assign data_out_d = data_out;
  assign re = (re_d);
  assign addr_rd = (addr_rd_d);
endmodule

// ------------------------------------------------------------------
//  Design Unit:    viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_4_256_16_8_0_1_0_0_0_1_1_16_256_1_1_gen
// ------------------------------------------------------------------


module viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_4_256_16_8_0_1_0_0_0_1_1_16_256_1_1_gen
    (
  data_out, re, addr_rd, addr_rd_d, re_d, data_out_d
);
  input [15:0] data_out;
  output re;
  output [7:0] addr_rd;
  input [7:0] addr_rd_d;
  input re_d;
  output [15:0] data_out_d;



  // Interconnect Declarations for Component Instantiations 
  assign data_out_d = data_out;
  assign re = (re_d);
  assign addr_rd = (addr_rd_d);
endmodule

// ------------------------------------------------------------------
//  Design Unit:    viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_3_256_16_8_0_1_0_0_0_1_1_16_256_1_1_gen
// ------------------------------------------------------------------


module viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_3_256_16_8_0_1_0_0_0_1_1_16_256_1_1_gen
    (
  data_out, re, addr_rd, addr_rd_d, re_d, data_out_d
);
  input [15:0] data_out;
  output re;
  output [7:0] addr_rd;
  input [7:0] addr_rd_d;
  input re_d;
  output [15:0] data_out_d;



  // Interconnect Declarations for Component Instantiations 
  assign data_out_d = data_out;
  assign re = (re_d);
  assign addr_rd = (addr_rd_d);
endmodule

// ------------------------------------------------------------------
//  Design Unit:    viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_1_32_8_5_0_1_0_0_0_1_1_8_32_1_1_gen
// ------------------------------------------------------------------


module viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_1_32_8_5_0_1_0_0_0_1_1_8_32_1_1_gen
    (
  data_out, re, addr_rd, addr_rd_d, re_d, data_out_d
);
  input [7:0] data_out;
  output re;
  output [4:0] addr_rd;
  input [4:0] addr_rd_d;
  input re_d;
  output [7:0] data_out_d;



  // Interconnect Declarations for Component Instantiations 
  assign data_out_d = data_out;
  assign re = (re_d);
  assign addr_rd = (addr_rd_d);
endmodule

// ------------------------------------------------------------------
//  Design Unit:    viterbi_core_core_fsm
//  FSM Module
// ------------------------------------------------------------------


module viterbi_core_core_fsm (
  clk, rst, fsm_output, for_C_2_tr0, for_1_for_for_C_2_tr0, for_1_for_C_5_tr0, for_1_C_0_tr0,
      for_2_C_1_tr0, for_3_for_C_1_tr0, for_3_C_4_tr0
);
  input clk;
  input rst;
  output [28:0] fsm_output;
  reg [28:0] fsm_output;
  input for_C_2_tr0;
  input for_1_for_for_C_2_tr0;
  input for_1_for_C_5_tr0;
  input for_1_C_0_tr0;
  input for_2_C_1_tr0;
  input for_3_for_C_1_tr0;
  input for_3_C_4_tr0;


  // FSM State Type Declaration for viterbi_core_core_fsm_1
  parameter
    core_rlp_C_0 = 5'd0,
    main_C_0 = 5'd1,
    for_C_0 = 5'd2,
    for_C_1 = 5'd3,
    for_C_2 = 5'd4,
    for_1_for_C_0 = 5'd5,
    for_1_for_C_1 = 5'd6,
    for_1_for_C_2 = 5'd7,
    for_1_for_C_3 = 5'd8,
    for_1_for_for_C_0 = 5'd9,
    for_1_for_for_C_1 = 5'd10,
    for_1_for_for_C_2 = 5'd11,
    for_1_for_C_4 = 5'd12,
    for_1_for_C_5 = 5'd13,
    for_1_C_0 = 5'd14,
    main_C_1 = 5'd15,
    main_C_2 = 5'd16,
    for_2_C_0 = 5'd17,
    for_2_C_1 = 5'd18,
    main_C_3 = 5'd19,
    main_C_4 = 5'd20,
    for_3_C_0 = 5'd21,
    for_3_C_1 = 5'd22,
    for_3_C_2 = 5'd23,
    for_3_for_C_0 = 5'd24,
    for_3_for_C_1 = 5'd25,
    for_3_C_3 = 5'd26,
    for_3_C_4 = 5'd27,
    main_C_5 = 5'd28;

  reg [4:0] state_var;
  reg [4:0] state_var_NS;


  // Interconnect Declarations for Component Instantiations 
  always @(*)
  begin : viterbi_core_core_fsm_1
    case (state_var)
      main_C_0 : begin
        fsm_output = 29'b00000000000000000000000000010;
        state_var_NS = for_C_0;
      end
      for_C_0 : begin
        fsm_output = 29'b00000000000000000000000000100;
        state_var_NS = for_C_1;
      end
      for_C_1 : begin
        fsm_output = 29'b00000000000000000000000001000;
        state_var_NS = for_C_2;
      end
      for_C_2 : begin
        fsm_output = 29'b00000000000000000000000010000;
        if ( for_C_2_tr0 ) begin
          state_var_NS = for_1_for_C_0;
        end
        else begin
          state_var_NS = for_C_0;
        end
      end
      for_1_for_C_0 : begin
        fsm_output = 29'b00000000000000000000000100000;
        state_var_NS = for_1_for_C_1;
      end
      for_1_for_C_1 : begin
        fsm_output = 29'b00000000000000000000001000000;
        state_var_NS = for_1_for_C_2;
      end
      for_1_for_C_2 : begin
        fsm_output = 29'b00000000000000000000010000000;
        state_var_NS = for_1_for_C_3;
      end
      for_1_for_C_3 : begin
        fsm_output = 29'b00000000000000000000100000000;
        state_var_NS = for_1_for_for_C_0;
      end
      for_1_for_for_C_0 : begin
        fsm_output = 29'b00000000000000000001000000000;
        state_var_NS = for_1_for_for_C_1;
      end
      for_1_for_for_C_1 : begin
        fsm_output = 29'b00000000000000000010000000000;
        state_var_NS = for_1_for_for_C_2;
      end
      for_1_for_for_C_2 : begin
        fsm_output = 29'b00000000000000000100000000000;
        if ( for_1_for_for_C_2_tr0 ) begin
          state_var_NS = for_1_for_C_4;
        end
        else begin
          state_var_NS = for_1_for_for_C_0;
        end
      end
      for_1_for_C_4 : begin
        fsm_output = 29'b00000000000000001000000000000;
        state_var_NS = for_1_for_C_5;
      end
      for_1_for_C_5 : begin
        fsm_output = 29'b00000000000000010000000000000;
        if ( for_1_for_C_5_tr0 ) begin
          state_var_NS = for_1_C_0;
        end
        else begin
          state_var_NS = for_1_for_C_0;
        end
      end
      for_1_C_0 : begin
        fsm_output = 29'b00000000000000100000000000000;
        if ( for_1_C_0_tr0 ) begin
          state_var_NS = main_C_1;
        end
        else begin
          state_var_NS = for_1_for_C_0;
        end
      end
      main_C_1 : begin
        fsm_output = 29'b00000000000001000000000000000;
        state_var_NS = main_C_2;
      end
      main_C_2 : begin
        fsm_output = 29'b00000000000010000000000000000;
        state_var_NS = for_2_C_0;
      end
      for_2_C_0 : begin
        fsm_output = 29'b00000000000100000000000000000;
        state_var_NS = for_2_C_1;
      end
      for_2_C_1 : begin
        fsm_output = 29'b00000000001000000000000000000;
        if ( for_2_C_1_tr0 ) begin
          state_var_NS = main_C_3;
        end
        else begin
          state_var_NS = for_2_C_0;
        end
      end
      main_C_3 : begin
        fsm_output = 29'b00000000010000000000000000000;
        state_var_NS = main_C_4;
      end
      main_C_4 : begin
        fsm_output = 29'b00000000100000000000000000000;
        state_var_NS = for_3_C_0;
      end
      for_3_C_0 : begin
        fsm_output = 29'b00000001000000000000000000000;
        state_var_NS = for_3_C_1;
      end
      for_3_C_1 : begin
        fsm_output = 29'b00000010000000000000000000000;
        state_var_NS = for_3_C_2;
      end
      for_3_C_2 : begin
        fsm_output = 29'b00000100000000000000000000000;
        state_var_NS = for_3_for_C_0;
      end
      for_3_for_C_0 : begin
        fsm_output = 29'b00001000000000000000000000000;
        state_var_NS = for_3_for_C_1;
      end
      for_3_for_C_1 : begin
        fsm_output = 29'b00010000000000000000000000000;
        if ( for_3_for_C_1_tr0 ) begin
          state_var_NS = for_3_C_3;
        end
        else begin
          state_var_NS = for_3_for_C_0;
        end
      end
      for_3_C_3 : begin
        fsm_output = 29'b00100000000000000000000000000;
        state_var_NS = for_3_C_4;
      end
      for_3_C_4 : begin
        fsm_output = 29'b01000000000000000000000000000;
        if ( for_3_C_4_tr0 ) begin
          state_var_NS = main_C_5;
        end
        else begin
          state_var_NS = for_3_C_0;
        end
      end
      main_C_5 : begin
        fsm_output = 29'b10000000000000000000000000000;
        state_var_NS = main_C_0;
      end
      // core_rlp_C_0
      default : begin
        fsm_output = 29'b00000000000000000000000000001;
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
//  Design Unit:    viterbi_core_wait_dp
// ------------------------------------------------------------------


module viterbi_core_wait_dp (
  llike_rsci_en_d, llike_rsci_cgo, llike_rsci_cgo_ir_unreg
);
  output llike_rsci_en_d;
  input llike_rsci_cgo;
  input llike_rsci_cgo_ir_unreg;



  // Interconnect Declarations for Component Instantiations 
  assign llike_rsci_en_d = ~(llike_rsci_cgo | llike_rsci_cgo_ir_unreg);
endmodule

// ------------------------------------------------------------------
//  Design Unit:    viterbi_core
// ------------------------------------------------------------------


module viterbi_core (
  clk, rst, obs_triosy_lz, init_rsc_dat, init_triosy_lz, transition_triosy_lz, emission_triosy_lz,
      path_triosy_lz, return_rsc_dat, return_triosy_lz, obs_rsci_addr_rd_d, obs_rsci_re_d,
      obs_rsci_data_out_d, transition_rsci_addr_rd_d, transition_rsci_re_d, transition_rsci_data_out_d,
      emission_rsci_addr_rd_d, emission_rsci_re_d, emission_rsci_data_out_d, path_rsci_data_in_d,
      path_rsci_addr_rd_d, path_rsci_addr_wr_d, path_rsci_re_d, path_rsci_we_d, path_rsci_data_out_d,
      llike_rsci_data_in_d, llike_rsci_addr_rd_d, llike_rsci_addr_wr_d, llike_rsci_re_d,
      llike_rsci_we_d, llike_rsci_data_out_d, llike_rsci_en_d
);
  input clk;
  input rst;
  output obs_triosy_lz;
  input [255:0] init_rsc_dat;
  output init_triosy_lz;
  output transition_triosy_lz;
  output emission_triosy_lz;
  output path_triosy_lz;
  output [31:0] return_rsc_dat;
  output return_triosy_lz;
  output [4:0] obs_rsci_addr_rd_d;
  output obs_rsci_re_d;
  input [7:0] obs_rsci_data_out_d;
  output [7:0] transition_rsci_addr_rd_d;
  output transition_rsci_re_d;
  input [15:0] transition_rsci_data_out_d;
  output [7:0] emission_rsci_addr_rd_d;
  output emission_rsci_re_d;
  input [15:0] emission_rsci_data_out_d;
  output [7:0] path_rsci_data_in_d;
  output [4:0] path_rsci_addr_rd_d;
  output [4:0] path_rsci_addr_wr_d;
  output path_rsci_re_d;
  output path_rsci_we_d;
  input [7:0] path_rsci_data_out_d;
  output [15:0] llike_rsci_data_in_d;
  output [8:0] llike_rsci_addr_rd_d;
  output [8:0] llike_rsci_addr_wr_d;
  output llike_rsci_re_d;
  output llike_rsci_we_d;
  input [15:0] llike_rsci_data_out_d;
  output llike_rsci_en_d;


  // Interconnect Declarations
  wire [255:0] init_rsci_idat;
  wire [28:0] fsm_output;
  wire or_dcpl_25;
  wire or_tmp_30;
  reg [4:0] for_1_for_curr_4_0_sva_1;
  reg [5:0] t_5_0_sva_1;
  reg [4:0] t_1_5_0_sva_4_0;
  reg reg_return_triosy_obj_ld_cse;
  reg reg_llike_rsci_cgo_ir_cse;
  wire and_2_cse;
  wire or_86_ssc;
  wire nor_3_cse;
  wire and_56_rmff;
  reg [3:0] s_1_4_0_sva_3_0;
  reg [4:0] for_3_bp_slc_path_8_7_0_cse_sva_4_0;
  wire llike_rsci_addr_rd_d_mx0c2;
  reg [3:0] for_3_best_3_0_sva;
  reg [2:0] for_3_bp_slc_path_8_7_0_cse_sva_7_5;
  reg [15:0] for_1_for_for_p_acc_itm;
  reg [15:0] for_1_for_min_p_sva;
  wire or_tmp_67;
  wire [3:0] z_out_1;
  wire [4:0] nl_z_out_1;
  wire or_tmp_73;
  wire [15:0] z_out_2;
  wire [16:0] nl_z_out_2;
  reg [15:0] for_1_for_min_p_slc_emission_16_15_0_1_cse_sva;
  reg [15:0] for_1_for_for_p_asn_1_itm;
  wire s_1_4_0_sva_3_0_mx0c0;
  wire s_1_4_0_sva_3_0_mx0c1;
  wire s_1_4_0_sva_3_0_mx0c3;
  wire for_1_for_for_p_acc_itm_mx0c2;
  wire for_1_for_min_p_sva_mx0c3;
  wire for_3_best_3_0_sva_mx0c3;
  wire for_1_for_for_p_or_6_ssc;
  wire for_1_for_for_p_or_2_ssc;
  wire for_1_for_for_p_or_8_cse;
  wire z_out_16;

  wire[3:0] for_3_best_mux1h_1_nl;
  wire s_not_nl;
  wire[15:0] for_mux_3_nl;
  wire for_or_5_nl;
  wire for_or_6_nl;
  wire for_1_for_min_p_or_2_nl;
  wire[3:0] for_1_for_for_prev_mux1h_nl;
  wire for_3_best_not_1_nl;
  wire[3:0] for_1_for_min_p_and_nl;
  wire[3:0] for_1_for_min_p_mux1h_nl;
  wire not_66_nl;
  wire[3:0] for_1_for_min_p_mux1h_3_nl;
  wire for_1_for_min_p_or_1_nl;
  wire not_65_nl;
  wire[4:0] for_or_nl;
  wire[4:0] for_mux1h_nl;
  wire for_or_1_nl;
  wire[3:0] for_and_nl;
  wire[3:0] for_mux_nl;
  wire for_or_4_nl;
  wire for_nor_nl;
  wire[4:0] for_for_and_nl;
  wire[17:0] acc_nl;
  wire[18:0] nl_acc_nl;
  wire[15:0] for_3_for_if_for_3_for_if_mux_2_nl;
  wire[15:0] for_3_for_if_for_3_for_if_mux_3_nl;
  wire[2:0] for_3_for_p_mux_10_nl;
  wire for_3_for_p_mux_11_nl;
  wire[10:0] for_1_for_for_p_and_3_nl;
  wire[10:0] for_1_for_for_p_mux1h_7_nl;
  wire for_1_for_for_p_or_14_nl;
  wire for_1_for_for_p_nor_2_nl;
  wire for_1_for_for_p_and_4_nl;
  wire for_1_for_for_p_mux1h_8_nl;
  wire[3:0] for_1_for_for_p_mux1h_9_nl;
  wire[15:0] for_1_for_for_p_or_15_nl;
  wire[15:0] for_1_for_for_p_mux1h_10_nl;
  wire for_1_for_for_p_or_16_nl;
  wire for_1_for_for_p_or_17_nl;
  wire for_1_for_for_p_or_18_nl;
  wire for_1_for_for_p_or_19_nl;
  wire for_1_for_for_p_or_20_nl;

  // Interconnect Declarations for Component Instantiations 
  wire  nl_viterbi_core_core_fsm_inst_for_C_2_tr0;
  assign nl_viterbi_core_core_fsm_inst_for_C_2_tr0 = z_out_2[4];
  wire  nl_viterbi_core_core_fsm_inst_for_1_for_for_C_2_tr0;
  assign nl_viterbi_core_core_fsm_inst_for_1_for_for_C_2_tr0 = for_1_for_curr_4_0_sva_1[4];
  wire  nl_viterbi_core_core_fsm_inst_for_1_for_C_5_tr0;
  assign nl_viterbi_core_core_fsm_inst_for_1_for_C_5_tr0 = for_1_for_curr_4_0_sva_1[4];
  wire  nl_viterbi_core_core_fsm_inst_for_1_C_0_tr0;
  assign nl_viterbi_core_core_fsm_inst_for_1_C_0_tr0 = z_out_2[5];
  wire  nl_viterbi_core_core_fsm_inst_for_2_C_1_tr0;
  assign nl_viterbi_core_core_fsm_inst_for_2_C_1_tr0 = z_out_2[4];
  wire  nl_viterbi_core_core_fsm_inst_for_3_for_C_1_tr0;
  assign nl_viterbi_core_core_fsm_inst_for_3_for_C_1_tr0 = for_1_for_curr_4_0_sva_1[4];
  wire  nl_viterbi_core_core_fsm_inst_for_3_C_4_tr0;
  assign nl_viterbi_core_core_fsm_inst_for_3_C_4_tr0 = t_5_0_sva_1[5];
  ccs_in_v1 #(.rscid(32'sd2),
  .width(32'sd256)) init_rsci (
      .dat(init_rsc_dat),
      .idat(init_rsci_idat)
    );
  ccs_out_v1 #(.rscid(32'sd6),
  .width(32'sd32)) return_rsci (
      .idat(32'b00000000000000000000000000000000),
      .dat(return_rsc_dat)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) obs_triosy_obj (
      .ld(reg_return_triosy_obj_ld_cse),
      .lz(obs_triosy_lz)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) init_triosy_obj (
      .ld(reg_return_triosy_obj_ld_cse),
      .lz(init_triosy_lz)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) transition_triosy_obj (
      .ld(reg_return_triosy_obj_ld_cse),
      .lz(transition_triosy_lz)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) emission_triosy_obj (
      .ld(reg_return_triosy_obj_ld_cse),
      .lz(emission_triosy_lz)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) path_triosy_obj (
      .ld(reg_return_triosy_obj_ld_cse),
      .lz(path_triosy_lz)
    );
  mgc_io_sync_v2 #(.valid(32'sd0)) return_triosy_obj (
      .ld(reg_return_triosy_obj_ld_cse),
      .lz(return_triosy_lz)
    );
  viterbi_core_wait_dp viterbi_core_wait_dp_inst (
      .llike_rsci_en_d(llike_rsci_en_d),
      .llike_rsci_cgo(reg_llike_rsci_cgo_ir_cse),
      .llike_rsci_cgo_ir_unreg(and_56_rmff)
    );
  viterbi_core_core_fsm viterbi_core_core_fsm_inst (
      .clk(clk),
      .rst(rst),
      .fsm_output(fsm_output),
      .for_C_2_tr0(nl_viterbi_core_core_fsm_inst_for_C_2_tr0),
      .for_1_for_for_C_2_tr0(nl_viterbi_core_core_fsm_inst_for_1_for_for_C_2_tr0),
      .for_1_for_C_5_tr0(nl_viterbi_core_core_fsm_inst_for_1_for_C_5_tr0),
      .for_1_C_0_tr0(nl_viterbi_core_core_fsm_inst_for_1_C_0_tr0),
      .for_2_C_1_tr0(nl_viterbi_core_core_fsm_inst_for_2_C_1_tr0),
      .for_3_for_C_1_tr0(nl_viterbi_core_core_fsm_inst_for_3_for_C_1_tr0),
      .for_3_C_4_tr0(nl_viterbi_core_core_fsm_inst_for_3_C_4_tr0)
    );
  assign nor_3_cse = ~((fsm_output[19]) | (fsm_output[26]));
  assign and_56_rmff = (~((fsm_output[28]) | (fsm_output[0]))) & nor_3_cse & (~((fsm_output[27])
      | (fsm_output[2]) | (fsm_output[20]))) & (~((fsm_output[14]) | (fsm_output[23])))
      & (~ (fsm_output[1])) & (~((fsm_output[8]) | (fsm_output[11]))) & (~ (fsm_output[7]));
  assign and_2_cse = (~ (z_out_2[4])) & (fsm_output[4]);
  assign or_86_ssc = (fsm_output[25:23]!=3'b000);
  assign or_dcpl_25 = (fsm_output[10]) | (fsm_output[8]);
  assign or_tmp_30 = (fsm_output[23]) | (fsm_output[16]);
  assign llike_rsci_addr_rd_d_mx0c2 = (~((fsm_output[21]) | (fsm_output[17]) | (fsm_output[5])))
      & (~((fsm_output[24]) | (fsm_output[9])));
  assign s_1_4_0_sva_3_0_mx0c0 = (fsm_output[25]) | (fsm_output[13]);
  assign s_1_4_0_sva_3_0_mx0c1 = (fsm_output[14]) | (fsm_output[1]) | ((z_out_2[4])
      & (fsm_output[4]));
  assign s_1_4_0_sva_3_0_mx0c3 = (fsm_output[18]) | and_2_cse;
  assign for_1_for_for_p_acc_itm_mx0c2 = (fsm_output[22]) | (fsm_output[16]);
  assign for_1_for_min_p_sva_mx0c3 = z_out_16 & (fsm_output[11]);
  assign for_3_best_3_0_sva_mx0c3 = (z_out_16 & (fsm_output[25])) | (z_out_16 & (fsm_output[18]));
  assign obs_rsci_addr_rd_d = MUX_v_5_2_2(5'b00000, t_1_5_0_sva_4_0, (fsm_output[5]));
  assign obs_rsci_re_d = ~((fsm_output[1]) | (fsm_output[5]) | and_2_cse);
  assign for_1_for_min_p_mux1h_nl = MUX1HOT_v_4_3_2(for_3_best_3_0_sva, (path_rsci_data_out_d[7:4]),
      z_out_1, {(fsm_output[9]) , (fsm_output[22]) , (fsm_output[24])});
  assign not_66_nl = ~ (fsm_output[5]);
  assign for_1_for_min_p_and_nl = MUX_v_4_2_2(4'b0000, for_1_for_min_p_mux1h_nl,
      not_66_nl);
  assign for_1_for_min_p_or_1_nl = (fsm_output[5]) | (fsm_output[9]);
  assign for_1_for_min_p_mux1h_3_nl = MUX1HOT_v_4_3_2(s_1_4_0_sva_3_0, (path_rsci_data_out_d[3:0]),
      (for_3_bp_slc_path_8_7_0_cse_sva_4_0[3:0]), {for_1_for_min_p_or_1_nl , (fsm_output[22])
      , (fsm_output[24])});
  assign transition_rsci_addr_rd_d = {for_1_for_min_p_and_nl , for_1_for_min_p_mux1h_3_nl};
  assign transition_rsci_re_d = ~((fsm_output[22]) | (fsm_output[5]) | (fsm_output[24])
      | (fsm_output[9]));
  assign emission_rsci_addr_rd_d = {z_out_1 , (obs_rsci_data_out_d[3:0])};
  assign emission_rsci_re_d = ~((fsm_output[2]) | (fsm_output[6]));
  assign path_rsci_data_in_d = {4'b0000 , for_3_best_3_0_sva};
  assign not_65_nl = ~ (fsm_output[26]);
  assign path_rsci_addr_wr_d = MUX_v_5_2_2(t_1_5_0_sva_4_0, 5'b11111, not_65_nl);
  assign path_rsci_re_d = ~ (fsm_output[21]);
  assign path_rsci_we_d = nor_3_cse;
  assign llike_rsci_data_in_d = MUX_v_16_2_2(z_out_2, for_1_for_min_p_sva, fsm_output[12]);
  assign for_or_1_nl = (fsm_output[21]) | (fsm_output[24]);
  assign for_mux1h_nl = MUX1HOT_v_5_3_2((z_out_2[4:0]), for_3_bp_slc_path_8_7_0_cse_sva_4_0,
      t_1_5_0_sva_4_0, {(fsm_output[5]) , (fsm_output[9]) , for_or_1_nl});
  assign for_or_nl = for_mux1h_nl | (signext_5_1(fsm_output[17])) | ({{4{llike_rsci_addr_rd_d_mx0c2}},
      llike_rsci_addr_rd_d_mx0c2});
  assign for_or_4_nl = (fsm_output[17]) | (fsm_output[24]);
  assign for_mux_nl = MUX_v_4_2_2(for_3_best_3_0_sva, s_1_4_0_sva_3_0, for_or_4_nl);
  assign for_nor_nl = ~((fsm_output[5]) | (fsm_output[21]));
  assign for_and_nl = for_mux_nl & (signext_4_1(for_nor_nl)) & (signext_4_1(~ llike_rsci_addr_rd_d_mx0c2));
  assign llike_rsci_addr_rd_d = {for_or_nl , for_and_nl};
  assign for_for_and_nl = MUX_v_5_2_2(5'b00000, t_1_5_0_sva_4_0, (fsm_output[12]));
  assign llike_rsci_addr_wr_d = {for_for_and_nl , s_1_4_0_sva_3_0};
  assign llike_rsci_re_d = ~((fsm_output[15]) | (fsm_output[21]) | (fsm_output[17])
      | (fsm_output[5]) | (fsm_output[24]) | (fsm_output[9]));
  assign llike_rsci_we_d = ~((fsm_output[3]) | (fsm_output[12]));
  assign or_tmp_67 = (fsm_output[6]) | (fsm_output[2]);
  assign or_tmp_73 = (fsm_output[12]) | (fsm_output[4]) | (fsm_output[24]) | (fsm_output[18]);
  assign path_rsci_addr_rd_d = z_out_2[4:0];
  assign for_1_for_for_p_or_6_ssc = (fsm_output[23]) | (fsm_output[11]) | (fsm_output[3]);
  assign for_1_for_for_p_or_2_ssc = (fsm_output[8:7]!=2'b00);
  assign for_1_for_for_p_or_8_cse = (fsm_output[26]) | (fsm_output[14]) | (fsm_output[5])
      | (fsm_output[21]);
  always @(posedge clk) begin
    if ( rst ) begin
      reg_return_triosy_obj_ld_cse <= 1'b0;
      reg_llike_rsci_cgo_ir_cse <= 1'b0;
      t_5_0_sva_1 <= 6'b000000;
    end
    else begin
      reg_return_triosy_obj_ld_cse <= (t_5_0_sva_1[5]) & (fsm_output[27]);
      reg_llike_rsci_cgo_ir_cse <= and_56_rmff;
      t_5_0_sva_1 <= z_out_2[5:0];
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      s_1_4_0_sva_3_0 <= 4'b0000;
    end
    else if ( s_1_4_0_sva_3_0_mx0c0 | s_1_4_0_sva_3_0_mx0c1 | or_tmp_30 | s_1_4_0_sva_3_0_mx0c3
        ) begin
      s_1_4_0_sva_3_0 <= MUX_v_4_2_2(4'b0000, for_3_best_mux1h_1_nl, s_not_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      for_1_for_for_p_acc_itm <= 16'b0000000000000000;
    end
    else if ( ((fsm_output[2]) | (fsm_output[10]) | for_1_for_for_p_acc_itm_mx0c2
        | (fsm_output[18]) | (fsm_output[23]) | (fsm_output[25])) & (z_out_16 | (fsm_output[2])
        | (fsm_output[10]) | for_1_for_for_p_acc_itm_mx0c2 | (fsm_output[23])) )
        begin
      for_1_for_for_p_acc_itm <= MUX1HOT_v_16_3_2(for_mux_3_nl, z_out_2, llike_rsci_data_out_d,
          {(fsm_output[2]) , for_or_5_nl , for_or_6_nl});
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      t_1_5_0_sva_4_0 <= 5'b00000;
    end
    else if ( (fsm_output[4]) | (fsm_output[14]) | (fsm_output[20]) | (fsm_output[27])
        ) begin
      t_1_5_0_sva_4_0 <= MUX1HOT_v_5_4_2(5'b00001, (z_out_2[4:0]), 5'b11110, (t_5_0_sva_1[4:0]),
          {(fsm_output[4]) , (fsm_output[14]) , (fsm_output[20]) , (fsm_output[27])});
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      for_3_bp_slc_path_8_7_0_cse_sva_7_5 <= 3'b000;
    end
    else if ( ~ or_86_ssc ) begin
      for_3_bp_slc_path_8_7_0_cse_sva_7_5 <= path_rsci_data_out_d[7:5];
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      for_3_bp_slc_path_8_7_0_cse_sva_4_0 <= 5'b00000;
    end
    else if ( ~(or_dcpl_25 | (fsm_output[11]) | (fsm_output[7]) | (fsm_output[6])
        | (fsm_output[9]) | or_86_ssc) ) begin
      for_3_bp_slc_path_8_7_0_cse_sva_4_0 <= MUX_v_5_2_2((z_out_2[4:0]), (path_rsci_data_out_d[4:0]),
          fsm_output[22]);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      for_1_for_min_p_sva <= 16'b0000000000000000;
    end
    else if ( (fsm_output[8:6]!=3'b000) | for_1_for_min_p_sva_mx0c3 ) begin
      for_1_for_min_p_sva <= MUX_v_16_2_2(transition_rsci_data_out_d, z_out_2, for_1_for_min_p_or_2_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      for_1_for_for_p_asn_1_itm <= 16'b0000000000000000;
    end
    else if ( (fsm_output[10]) | (fsm_output[6]) ) begin
      for_1_for_for_p_asn_1_itm <= llike_rsci_data_out_d;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      for_1_for_min_p_slc_emission_16_15_0_1_cse_sva <= 16'b0000000000000000;
    end
    else if ( ~(or_dcpl_25 | (fsm_output[11]) | (fsm_output[9])) ) begin
      for_1_for_min_p_slc_emission_16_15_0_1_cse_sva <= emission_rsci_data_out_d;
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      for_3_best_3_0_sva <= 4'b0000;
    end
    else if ( (fsm_output[8]) | (fsm_output[11]) | or_tmp_30 | for_3_best_3_0_sva_mx0c3
        ) begin
      for_3_best_3_0_sva <= MUX_v_4_2_2(4'b0000, for_1_for_for_prev_mux1h_nl, for_3_best_not_1_nl);
    end
  end
  always @(posedge clk) begin
    if ( rst ) begin
      for_1_for_curr_4_0_sva_1 <= 5'b00000;
    end
    else if ( (fsm_output[9]) | (fsm_output[12]) | (fsm_output[24]) ) begin
      for_1_for_curr_4_0_sva_1 <= z_out_2[4:0];
    end
  end
  assign for_3_best_mux1h_1_nl = MUX1HOT_v_4_3_2((for_1_for_curr_4_0_sva_1[3:0]),
      4'b0001, (z_out_2[3:0]), {s_1_4_0_sva_3_0_mx0c0 , or_tmp_30 , s_1_4_0_sva_3_0_mx0c3});
  assign s_not_nl = ~ s_1_4_0_sva_3_0_mx0c1;
  assign for_mux_3_nl = MUX_v_16_16_2((init_rsci_idat[15:0]), (init_rsci_idat[31:16]),
      (init_rsci_idat[47:32]), (init_rsci_idat[63:48]), (init_rsci_idat[79:64]),
      (init_rsci_idat[95:80]), (init_rsci_idat[111:96]), (init_rsci_idat[127:112]),
      (init_rsci_idat[143:128]), (init_rsci_idat[159:144]), (init_rsci_idat[175:160]),
      (init_rsci_idat[191:176]), (init_rsci_idat[207:192]), (init_rsci_idat[223:208]),
      (init_rsci_idat[239:224]), (init_rsci_idat[255:240]), s_1_4_0_sva_3_0);
  assign for_or_5_nl = (fsm_output[10]) | (fsm_output[23]) | (fsm_output[25]);
  assign for_or_6_nl = for_1_for_for_p_acc_itm_mx0c2 | (fsm_output[18]);
  assign for_1_for_min_p_or_2_nl = (fsm_output[8:7]!=2'b00) | for_1_for_min_p_sva_mx0c3;
  assign for_1_for_for_prev_mux1h_nl = MUX1HOT_v_4_3_2(4'b0001, (for_1_for_curr_4_0_sva_1[3:0]),
      s_1_4_0_sva_3_0, {(fsm_output[8]) , (fsm_output[11]) , for_3_best_3_0_sva_mx0c3});
  assign for_3_best_not_1_nl = ~ or_tmp_30;
  assign for_3_for_if_for_3_for_if_mux_2_nl = MUX_v_16_2_2(z_out_2, llike_rsci_data_out_d,
      fsm_output[18]);
  assign for_3_for_if_for_3_for_if_mux_3_nl = MUX_v_16_2_2((~ for_1_for_for_p_acc_itm),
      (~ for_1_for_min_p_sva), fsm_output[11]);
  assign nl_acc_nl = conv_s2u_17_18({for_3_for_if_for_3_for_if_mux_2_nl , 1'b1})
      + conv_s2u_17_18({for_3_for_if_for_3_for_if_mux_3_nl , 1'b1});
  assign acc_nl = nl_acc_nl[17:0];
  assign z_out_16 = readslicef_18_1_17(acc_nl);
  assign for_3_for_p_mux_10_nl = MUX_v_3_2_2(for_3_bp_slc_path_8_7_0_cse_sva_7_5,
      (obs_rsci_data_out_d[7:5]), or_tmp_67);
  assign for_3_for_p_mux_11_nl = MUX_s_1_2_2((for_3_bp_slc_path_8_7_0_cse_sva_4_0[4]),
      (obs_rsci_data_out_d[4]), or_tmp_67);
  assign nl_z_out_1 = s_1_4_0_sva_3_0 + ({for_3_for_p_mux_10_nl , for_3_for_p_mux_11_nl});
  assign z_out_1 = nl_z_out_1[3:0];
  assign for_1_for_for_p_or_14_nl = (fsm_output[5]) | (fsm_output[21]);
  assign for_1_for_for_p_mux1h_7_nl = MUX1HOT_v_11_5_2((transition_rsci_data_out_d[15:5]),
      (for_1_for_for_p_acc_itm[15:5]), (for_1_for_min_p_sva[15:5]), (signext_11_1(t_1_5_0_sva_4_0[4])),
      (llike_rsci_data_out_d[15:5]), {(fsm_output[10]) , for_1_for_for_p_or_6_ssc
      , for_1_for_for_p_or_2_ssc , for_1_for_for_p_or_14_nl , (fsm_output[25])});
  assign for_1_for_for_p_nor_2_nl = ~((fsm_output[26]) | or_tmp_73 | (fsm_output[9])
      | (fsm_output[14]));
  assign for_1_for_for_p_and_3_nl = MUX_v_11_2_2(11'b00000000000, for_1_for_for_p_mux1h_7_nl,
      for_1_for_for_p_nor_2_nl);
  assign for_1_for_for_p_mux1h_8_nl = MUX1HOT_s_1_5_2((transition_rsci_data_out_d[4]),
      (for_1_for_for_p_acc_itm[4]), (for_1_for_min_p_sva[4]), (t_1_5_0_sva_4_0[4]),
      (llike_rsci_data_out_d[4]), {(fsm_output[10]) , for_1_for_for_p_or_6_ssc ,
      for_1_for_for_p_or_2_ssc , for_1_for_for_p_or_8_cse , (fsm_output[25])});
  assign for_1_for_for_p_and_4_nl = for_1_for_for_p_mux1h_8_nl & (~(or_tmp_73 | (fsm_output[9])));
  assign for_1_for_for_p_mux1h_9_nl = MUX1HOT_v_4_7_2((transition_rsci_data_out_d[3:0]),
      (for_1_for_for_p_acc_itm[3:0]), (for_1_for_min_p_sva[3:0]), (t_1_5_0_sva_4_0[3:0]),
      s_1_4_0_sva_3_0, for_3_best_3_0_sva, (llike_rsci_data_out_d[3:0]), {(fsm_output[10])
      , for_1_for_for_p_or_6_ssc , for_1_for_for_p_or_2_ssc , for_1_for_for_p_or_8_cse
      , or_tmp_73 , (fsm_output[9]) , (fsm_output[25])});
  assign for_1_for_for_p_or_16_nl = (fsm_output[23]) | (fsm_output[25]);
  assign for_1_for_for_p_or_17_nl = (fsm_output[7]) | (fsm_output[3]);
  assign for_1_for_for_p_or_18_nl = (fsm_output[8]) | (fsm_output[11]);
  assign for_1_for_for_p_or_19_nl = or_tmp_73 | (fsm_output[9]) | (fsm_output[14])
      | (fsm_output[21]);
  assign for_1_for_for_p_mux1h_10_nl = MUX1HOT_v_16_5_2(for_1_for_min_p_slc_emission_16_15_0_1_cse_sva,
      transition_rsci_data_out_d, emission_rsci_data_out_d, for_1_for_for_p_asn_1_itm,
      16'b0000000000000001, {(fsm_output[10]) , for_1_for_for_p_or_16_nl , for_1_for_for_p_or_17_nl
      , for_1_for_for_p_or_18_nl , for_1_for_for_p_or_19_nl});
  assign for_1_for_for_p_or_20_nl = (fsm_output[26]) | (fsm_output[5]);
  assign for_1_for_for_p_or_15_nl = MUX_v_16_2_2(for_1_for_for_p_mux1h_10_nl, 16'b1111111111111111,
      for_1_for_for_p_or_20_nl);
  assign nl_z_out_2 = ({for_1_for_for_p_and_3_nl , for_1_for_for_p_and_4_nl , for_1_for_for_p_mux1h_9_nl})
      + for_1_for_for_p_or_15_nl;
  assign z_out_2 = nl_z_out_2[15:0];

  function automatic  MUX1HOT_s_1_5_2;
    input  input_4;
    input  input_3;
    input  input_2;
    input  input_1;
    input  input_0;
    input [4:0] sel;
    reg  result;
  begin
    result = input_0 & sel[0];
    result = result | (input_1 & sel[1]);
    result = result | (input_2 & sel[2]);
    result = result | (input_3 & sel[3]);
    result = result | (input_4 & sel[4]);
    MUX1HOT_s_1_5_2 = result;
  end
  endfunction


  function automatic [10:0] MUX1HOT_v_11_5_2;
    input [10:0] input_4;
    input [10:0] input_3;
    input [10:0] input_2;
    input [10:0] input_1;
    input [10:0] input_0;
    input [4:0] sel;
    reg [10:0] result;
  begin
    result = input_0 & {11{sel[0]}};
    result = result | (input_1 & {11{sel[1]}});
    result = result | (input_2 & {11{sel[2]}});
    result = result | (input_3 & {11{sel[3]}});
    result = result | (input_4 & {11{sel[4]}});
    MUX1HOT_v_11_5_2 = result;
  end
  endfunction


  function automatic [15:0] MUX1HOT_v_16_3_2;
    input [15:0] input_2;
    input [15:0] input_1;
    input [15:0] input_0;
    input [2:0] sel;
    reg [15:0] result;
  begin
    result = input_0 & {16{sel[0]}};
    result = result | (input_1 & {16{sel[1]}});
    result = result | (input_2 & {16{sel[2]}});
    MUX1HOT_v_16_3_2 = result;
  end
  endfunction


  function automatic [15:0] MUX1HOT_v_16_5_2;
    input [15:0] input_4;
    input [15:0] input_3;
    input [15:0] input_2;
    input [15:0] input_1;
    input [15:0] input_0;
    input [4:0] sel;
    reg [15:0] result;
  begin
    result = input_0 & {16{sel[0]}};
    result = result | (input_1 & {16{sel[1]}});
    result = result | (input_2 & {16{sel[2]}});
    result = result | (input_3 & {16{sel[3]}});
    result = result | (input_4 & {16{sel[4]}});
    MUX1HOT_v_16_5_2 = result;
  end
  endfunction


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


  function automatic [3:0] MUX1HOT_v_4_7_2;
    input [3:0] input_6;
    input [3:0] input_5;
    input [3:0] input_4;
    input [3:0] input_3;
    input [3:0] input_2;
    input [3:0] input_1;
    input [3:0] input_0;
    input [6:0] sel;
    reg [3:0] result;
  begin
    result = input_0 & {4{sel[0]}};
    result = result | (input_1 & {4{sel[1]}});
    result = result | (input_2 & {4{sel[2]}});
    result = result | (input_3 & {4{sel[3]}});
    result = result | (input_4 & {4{sel[4]}});
    result = result | (input_5 & {4{sel[5]}});
    result = result | (input_6 & {4{sel[6]}});
    MUX1HOT_v_4_7_2 = result;
  end
  endfunction


  function automatic [4:0] MUX1HOT_v_5_3_2;
    input [4:0] input_2;
    input [4:0] input_1;
    input [4:0] input_0;
    input [2:0] sel;
    reg [4:0] result;
  begin
    result = input_0 & {5{sel[0]}};
    result = result | (input_1 & {5{sel[1]}});
    result = result | (input_2 & {5{sel[2]}});
    MUX1HOT_v_5_3_2 = result;
  end
  endfunction


  function automatic [4:0] MUX1HOT_v_5_4_2;
    input [4:0] input_3;
    input [4:0] input_2;
    input [4:0] input_1;
    input [4:0] input_0;
    input [3:0] sel;
    reg [4:0] result;
  begin
    result = input_0 & {5{sel[0]}};
    result = result | (input_1 & {5{sel[1]}});
    result = result | (input_2 & {5{sel[2]}});
    result = result | (input_3 & {5{sel[3]}});
    MUX1HOT_v_5_4_2 = result;
  end
  endfunction


  function automatic  MUX_s_1_2_2;
    input  input_0;
    input  input_1;
    input  sel;
    reg  result;
  begin
    case (sel)
      1'b0 : begin
        result = input_0;
      end
      default : begin
        result = input_1;
      end
    endcase
    MUX_s_1_2_2 = result;
  end
  endfunction


  function automatic [10:0] MUX_v_11_2_2;
    input [10:0] input_0;
    input [10:0] input_1;
    input  sel;
    reg [10:0] result;
  begin
    case (sel)
      1'b0 : begin
        result = input_0;
      end
      default : begin
        result = input_1;
      end
    endcase
    MUX_v_11_2_2 = result;
  end
  endfunction


  function automatic [15:0] MUX_v_16_16_2;
    input [15:0] input_0;
    input [15:0] input_1;
    input [15:0] input_2;
    input [15:0] input_3;
    input [15:0] input_4;
    input [15:0] input_5;
    input [15:0] input_6;
    input [15:0] input_7;
    input [15:0] input_8;
    input [15:0] input_9;
    input [15:0] input_10;
    input [15:0] input_11;
    input [15:0] input_12;
    input [15:0] input_13;
    input [15:0] input_14;
    input [15:0] input_15;
    input [3:0] sel;
    reg [15:0] result;
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
    MUX_v_16_16_2 = result;
  end
  endfunction


  function automatic [15:0] MUX_v_16_2_2;
    input [15:0] input_0;
    input [15:0] input_1;
    input  sel;
    reg [15:0] result;
  begin
    case (sel)
      1'b0 : begin
        result = input_0;
      end
      default : begin
        result = input_1;
      end
    endcase
    MUX_v_16_2_2 = result;
  end
  endfunction


  function automatic [2:0] MUX_v_3_2_2;
    input [2:0] input_0;
    input [2:0] input_1;
    input  sel;
    reg [2:0] result;
  begin
    case (sel)
      1'b0 : begin
        result = input_0;
      end
      default : begin
        result = input_1;
      end
    endcase
    MUX_v_3_2_2 = result;
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


  function automatic [4:0] MUX_v_5_2_2;
    input [4:0] input_0;
    input [4:0] input_1;
    input  sel;
    reg [4:0] result;
  begin
    case (sel)
      1'b0 : begin
        result = input_0;
      end
      default : begin
        result = input_1;
      end
    endcase
    MUX_v_5_2_2 = result;
  end
  endfunction


  function automatic [0:0] readslicef_18_1_17;
    input [17:0] vector;
    reg [17:0] tmp;
  begin
    tmp = vector >> 17;
    readslicef_18_1_17 = tmp[0:0];
  end
  endfunction


  function automatic [10:0] signext_11_1;
    input  vector;
  begin
    signext_11_1= {{10{vector}}, vector};
  end
  endfunction


  function automatic [3:0] signext_4_1;
    input  vector;
  begin
    signext_4_1= {{3{vector}}, vector};
  end
  endfunction


  function automatic [4:0] signext_5_1;
    input  vector;
  begin
    signext_5_1= {{4{vector}}, vector};
  end
  endfunction


  function automatic [17:0] conv_s2u_17_18 ;
    input [16:0]  vector ;
  begin
    conv_s2u_17_18 = {vector[16], vector};
  end
  endfunction

endmodule

// ------------------------------------------------------------------
//  Design Unit:    viterbi
// ------------------------------------------------------------------


module viterbi (
  clk, rst, obs_rsc_addr_rd, obs_rsc_re, obs_rsc_data_out, obs_triosy_lz, init_rsc_dat,
      init_triosy_lz, transition_rsc_addr_rd, transition_rsc_re, transition_rsc_data_out,
      transition_triosy_lz, emission_rsc_addr_rd, emission_rsc_re, emission_rsc_data_out,
      emission_triosy_lz, path_rsc_addr_rd, path_rsc_re, path_rsc_data_out, path_rsc_data_in,
      path_rsc_addr_wr, path_rsc_we, path_triosy_lz, return_rsc_dat, return_triosy_lz
);
  input clk;
  input rst;
  output [4:0] obs_rsc_addr_rd;
  output obs_rsc_re;
  input [7:0] obs_rsc_data_out;
  output obs_triosy_lz;
  input [255:0] init_rsc_dat;
  output init_triosy_lz;
  output [7:0] transition_rsc_addr_rd;
  output transition_rsc_re;
  input [15:0] transition_rsc_data_out;
  output transition_triosy_lz;
  output [7:0] emission_rsc_addr_rd;
  output emission_rsc_re;
  input [15:0] emission_rsc_data_out;
  output emission_triosy_lz;
  output [4:0] path_rsc_addr_rd;
  output path_rsc_re;
  input [7:0] path_rsc_data_out;
  output [7:0] path_rsc_data_in;
  output [4:0] path_rsc_addr_wr;
  output path_rsc_we;
  output path_triosy_lz;
  output [31:0] return_rsc_dat;
  output return_triosy_lz;


  // Interconnect Declarations
  wire [4:0] obs_rsci_addr_rd_d;
  wire obs_rsci_re_d;
  wire [7:0] obs_rsci_data_out_d;
  wire [7:0] transition_rsci_addr_rd_d;
  wire transition_rsci_re_d;
  wire [15:0] transition_rsci_data_out_d;
  wire [7:0] emission_rsci_addr_rd_d;
  wire emission_rsci_re_d;
  wire [15:0] emission_rsci_data_out_d;
  wire [7:0] path_rsci_data_in_d;
  wire [4:0] path_rsci_addr_rd_d;
  wire [4:0] path_rsci_addr_wr_d;
  wire path_rsci_re_d;
  wire path_rsci_we_d;
  wire [7:0] path_rsci_data_out_d;
  wire [15:0] llike_rsci_data_in_d;
  wire [8:0] llike_rsci_addr_rd_d;
  wire [8:0] llike_rsci_addr_wr_d;
  wire llike_rsci_re_d;
  wire llike_rsci_we_d;
  wire [15:0] llike_rsci_data_out_d;
  wire llike_rsci_en_d;
  wire llike_rsc_en;
  wire llike_rsc_we;
  wire [8:0] llike_rsc_addr_wr;
  wire [15:0] llike_rsc_data_in;
  wire [15:0] llike_rsc_data_out;
  wire llike_rsc_re;
  wire [8:0] llike_rsc_addr_rd;


  // Interconnect Declarations for Component Instantiations 
  ram_sync_separateRW_be #(.ram_id(32'sd7),
  .words(32'sd512),
  .width(32'sd16),
  .addr_width(32'sd9),
  .a_reset_active(32'sd0),
  .s_reset_active(32'sd1),
  .enable_active(32'sd0),
  .re_active(32'sd0),
  .we_active(32'sd0),
  .num_byte_enables(32'sd1),
  .clock_edge(32'sd1),
  .no_of_RAM_read_port(32'sd1),
  .no_of_RAM_write_port(32'sd1)) llike_rsc_comp (
      .data_in(llike_rsc_data_in),
      .addr_rd(llike_rsc_addr_rd),
      .addr_wr(llike_rsc_addr_wr),
      .re(llike_rsc_re),
      .we(llike_rsc_we),
      .data_out(llike_rsc_data_out),
      .clk(clk),
      .a_rst(1'b1),
      .s_rst(rst),
      .en(llike_rsc_en)
    );
  viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_1_32_8_5_0_1_0_0_0_1_1_8_32_1_1_gen
      obs_rsci (
      .data_out(obs_rsc_data_out),
      .re(obs_rsc_re),
      .addr_rd(obs_rsc_addr_rd),
      .addr_rd_d(obs_rsci_addr_rd_d),
      .re_d(obs_rsci_re_d),
      .data_out_d(obs_rsci_data_out_d)
    );
  viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_3_256_16_8_0_1_0_0_0_1_1_16_256_1_1_gen
      transition_rsci (
      .data_out(transition_rsc_data_out),
      .re(transition_rsc_re),
      .addr_rd(transition_rsc_addr_rd),
      .addr_rd_d(transition_rsci_addr_rd_d),
      .re_d(transition_rsci_re_d),
      .data_out_d(transition_rsci_data_out_d)
    );
  viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rport_4_256_16_8_0_1_0_0_0_1_1_16_256_1_1_gen
      emission_rsci (
      .data_out(emission_rsc_data_out),
      .re(emission_rsc_re),
      .addr_rd(emission_rsc_addr_rd),
      .addr_rd_d(emission_rsci_addr_rd_d),
      .re_d(emission_rsci_re_d),
      .data_out_d(emission_rsci_data_out_d)
    );
  viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rwport_5_32_8_5_0_1_0_0_0_1_1_8_32_1_1_gen
      path_rsci (
      .we(path_rsc_we),
      .addr_wr(path_rsc_addr_wr),
      .data_in(path_rsc_data_in),
      .data_out(path_rsc_data_out),
      .re(path_rsc_re),
      .addr_rd(path_rsc_addr_rd),
      .data_in_d(path_rsci_data_in_d),
      .addr_rd_d(path_rsci_addr_rd_d),
      .addr_wr_d(path_rsci_addr_wr_d),
      .re_d(path_rsci_re_d),
      .we_d(path_rsci_we_d),
      .data_out_d(path_rsci_data_out_d)
    );
  viterbi_ram_nangate_45nm_separate_beh_RAM_separateRW_rwport_en_7_512_16_9_0_1_0_0_0_1_1_16_512_1_1_gen
      llike_rsci (
      .en(llike_rsc_en),
      .we(llike_rsc_we),
      .addr_wr(llike_rsc_addr_wr),
      .data_in(llike_rsc_data_in),
      .data_out(llike_rsc_data_out),
      .re(llike_rsc_re),
      .addr_rd(llike_rsc_addr_rd),
      .data_in_d(llike_rsci_data_in_d),
      .addr_rd_d(llike_rsci_addr_rd_d),
      .addr_wr_d(llike_rsci_addr_wr_d),
      .re_d(llike_rsci_re_d),
      .we_d(llike_rsci_we_d),
      .data_out_d(llike_rsci_data_out_d),
      .en_d(llike_rsci_en_d)
    );
  viterbi_core viterbi_core_inst (
      .clk(clk),
      .rst(rst),
      .obs_triosy_lz(obs_triosy_lz),
      .init_rsc_dat(init_rsc_dat),
      .init_triosy_lz(init_triosy_lz),
      .transition_triosy_lz(transition_triosy_lz),
      .emission_triosy_lz(emission_triosy_lz),
      .path_triosy_lz(path_triosy_lz),
      .return_rsc_dat(return_rsc_dat),
      .return_triosy_lz(return_triosy_lz),
      .obs_rsci_addr_rd_d(obs_rsci_addr_rd_d),
      .obs_rsci_re_d(obs_rsci_re_d),
      .obs_rsci_data_out_d(obs_rsci_data_out_d),
      .transition_rsci_addr_rd_d(transition_rsci_addr_rd_d),
      .transition_rsci_re_d(transition_rsci_re_d),
      .transition_rsci_data_out_d(transition_rsci_data_out_d),
      .emission_rsci_addr_rd_d(emission_rsci_addr_rd_d),
      .emission_rsci_re_d(emission_rsci_re_d),
      .emission_rsci_data_out_d(emission_rsci_data_out_d),
      .path_rsci_data_in_d(path_rsci_data_in_d),
      .path_rsci_addr_rd_d(path_rsci_addr_rd_d),
      .path_rsci_addr_wr_d(path_rsci_addr_wr_d),
      .path_rsci_re_d(path_rsci_re_d),
      .path_rsci_we_d(path_rsci_we_d),
      .path_rsci_data_out_d(path_rsci_data_out_d),
      .llike_rsci_data_in_d(llike_rsci_data_in_d),
      .llike_rsci_addr_rd_d(llike_rsci_addr_rd_d),
      .llike_rsci_addr_wr_d(llike_rsci_addr_wr_d),
      .llike_rsci_re_d(llike_rsci_re_d),
      .llike_rsci_we_d(llike_rsci_we_d),
      .llike_rsci_data_out_d(llike_rsci_data_out_d),
      .llike_rsci_en_d(llike_rsci_en_d)
    );
endmodule



