`timescale 1ns/1ps

module top;
  bit clk;
  bit rst_n;

  // Interfaces
  standard_stream_if #(512) sbus_in (clk);
  standard_stream_if #(512) sbus_out (clk);

  // DUT
  aes_concat dut (
    .clk(clk),
    .rst_n(rst_n),
    .s0(sbus_in),
    .s_out(sbus_out)
  );

  // Test vectors
  logic [7:0] keys   [0:4][0:31];
  logic [7:0] inputs [0:4][0:15];
  logic [7:0] goldens[0:4][0:15];

  int     report_fh;
  string  local_lines [0:4];
  bit     global_pass;

  // Clock 100MHz
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    int t, j, k;
    logic [7:0] in0 [0:15];
    logic [7:0] in1 [0:15];
    logic [7:0] in2 [0:15];
    logic [7:0] in3 [0:15];
    logic [7:0] in4 [0:15];
    logic [7:0] g0 [0:15];
    logic [7:0] g1 [0:15];
    logic [7:0] g2 [0:15];
    logic [7:0] g3 [0:15];
    logic [7:0] g4 [0:15];

    global_pass = 1'b1;

    // keys init
    for (k = 0; k < 5; k++) begin
      for (j = 0; j < 32; j++) keys[k][j] = 8'h00;
    end
    for (j = 0; j < 32; j++) begin
      keys[0][j] = j[7:0];
      keys[1][j] = j[7:0];
      keys[2][j] = j[7:0];
    end
    for (j = 0; j < 32; j++) begin
      keys[3][j] = 8'hff;
      keys[4][j] = 8'h00;
    end

    // inputs
    in0 = '{8'h00,8'h11,8'h22,8'h33,8'h44,8'h55,8'h66,8'h77,8'h88,8'h99,8'haa,8'hbb,8'hcc,8'hdd,8'hee,8'hff};
    in1 = '{8'h6b,8'hc1,8'hbe,8'he2,8'h2e,8'h40,8'h9f,8'h96,8'he9,8'h3d,8'h7e,8'h11,8'h73,8'h93,8'h17,8'h2a};
    in2 = '{8'hae,8'h2d,8'h8a,8'h57,8'h1e,8'h03,8'hac,8'h9c,8'h9e,8'hb7,8'h6f,8'hac,8'h45,8'haf,8'h8e,8'h51};
    in3 = '{default:8'h00};
    in4 = '{default:8'hff};

    for (j = 0; j < 16; j++) begin
      inputs[0][j] = in0[j];
      inputs[1][j] = in1[j];
      inputs[2][j] = in2[j];
      inputs[3][j] = in3[j];
      inputs[4][j] = in4[j];
    end

    // goldens
    g0 = '{8'h8e,8'ha2,8'hb7,8'hca,8'h51,8'h67,8'h45,8'hbf,8'hea,8'hfc,8'h49,8'h90,8'h4b,8'h49,8'h60,8'h89};
    g1 = '{8'he0,8'ha8,8'hf5,8'h0e,8'hc7,8'h6a,8'h04,8'hd5,8'ha9,8'h6a,8'h17,8'h5a,8'ha8,8'h70,8'hef,8'h63};
    g2 = '{8'h54,8'h2d,8'hde,8'ha4,8'hd5,8'hfa,8'had,8'h62,8'h3e,8'hf8,8'h84,8'hcf,8'h4e,8'h19,8'h8b,8'hdc};
    g3 = '{8'h4b,8'hf8,8'h5f,8'h1b,8'h5d,8'h54,8'had,8'hbc,8'h30,8'h7b,8'h0a,8'h04,8'h83,8'h89,8'had,8'hcb};
    g4 = '{8'hac,8'hda,8'hce,8'h80,8'h78,8'ha3,8'h2b,8'h1a,8'h18,8'h2b,8'hfa,8'h49,8'h87,8'hca,8'h13,8'h47};

    for (j = 0; j < 16; j++) begin
      goldens[0][j] = g0[j];
      goldens[1][j] = g1[j];
      goldens[2][j] = g2[j];
      goldens[3][j] = g3[j];
      goldens[4][j] = g4[j];
    end

    // Reset
    rst_n = 1'b0;
    sbus_in.tvalid = 1'b0;
    sbus_in.tdata  = '0;
    sbus_out.tready = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    repeat (5) @(posedge clk);

    // report
    report_fh = $fopen("report.txt", "w");
    if (report_fh == 0) $display("Error: could not open report.txt");

    // 5 tests
    for (t = 0; t < 5; t++) begin
      logic [7:0] actual [0:15];
      bit   local_pass;
      string input_hex, actual_hex, golden_hex;
      string line;
      int j2;

      // pack key+input
      sbus_in.tdata = '0;
      for (j2 = 0; j2 < 32; j2++) sbus_in.tdata[8*j2 +: 8] = keys[t][j2];
      for (j2 = 0; j2 < 16; j2++) sbus_in.tdata[8*(32 + j2) +: 8] = inputs[t][j2];

      // drive valid until accepted
      sbus_in.tvalid = 1'b1;
      @(posedge clk);
      while (!(sbus_in.tvalid && sbus_in.tready)) @(posedge clk);
      sbus_in.tvalid = 1'b0;

      // wait output
      sbus_out.tready = 1'b1;
      @(posedge clk);
      while (!(sbus_out.tvalid && sbus_out.tready)) @(posedge clk);

      // capture
      for (j2 = 0; j2 < 16; j2++) actual[j2] = sbus_out.tdata[8*j2 +: 8];
      sbus_out.tready = 1'b0;

      // compare
      local_pass = 1'b1;
      for (j2 = 0; j2 < 16; j2++) if (actual[j2] !== goldens[t][j2]) local_pass = 1'b0;
      if (!local_pass) global_pass = 1'b0;

      // strings
      input_hex = ""; actual_hex = ""; golden_hex = "";
      for (j2 = 0; j2 < 16; j2++) begin
        $sformat(input_hex,  "%s%02x%s", input_hex,  inputs[t][j2], (j2<15)?" ":"");
        $sformat(actual_hex, "%s%02x%s", actual_hex, actual[j2],    (j2<15)?" ":"");
        $sformat(golden_hex, "%s%02x%s", golden_hex, goldens[t][j2],(j2<15)?" ":"");
      end

      $sformat(line, "LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %s, Golden Output: %s",
               t+1, (local_pass ? "PASS" : "FAIL"), input_hex, actual_hex, golden_hex);
      local_lines[t] = line;
      $display(line);
      @(posedge clk);
    end

    if (report_fh != 0) begin
      $fdisplay(report_fh, "GLOBAL_CHECK: %s", (global_pass ? "PASS" : "FAIL"));
      for (t = 0; t < 5; t++) $fdisplay(report_fh, "%s", local_lines[t]);
      $fclose(report_fh);
      $display("\nReport saved to report.txt");
    end

    repeat (20) @(posedge clk);
    $finish;
  end
endmodule
