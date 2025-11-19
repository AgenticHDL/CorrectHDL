`timescale 1ns/1ps

module tb_mips;

  reg clk;
  reg rstn;
  reg start;

  reg  [31:0] A0, A1, A2, A3, A4, A5, A6, A7;
  wire [31:0] O0, O1, O2, O3, O4, O5, O6, O7;
  wire [31:0] NINST;
  wire        DONE;

  // DUT
  mips_sort dut (
    .clk  (clk),
    .rstn (rstn),
    .start(start),
    .A_in0(A0), .A_in1(A1), .A_in2(A2), .A_in3(A3),
    .A_in4(A4), .A_in5(A5), .A_in6(A6), .A_in7(A7),
    .out0(O0), .out1(O1), .out2(O2), .out3(O3),
    .out4(O4), .out5(O5), .out6(O6), .out7(O7),
    .n_inst_out(NINST),
    .done(DONE)
  );

  // Clock
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100MHz
  end

  // Test vectors (5 cases) and goldens
  reg [31:0] inputs [0:4][0:7];
  reg [31:0] goldens[0:4][0:7];

  integer i;
  integer fd;
  reg     global_pass;
  reg     local_pass;

  initial begin
    // Initialize vectors (match C++ testbench exactly)
    // inputs[0]
    inputs[0][0] = 32'sd22;  inputs[0][1] = 32'sd5;   inputs[0][2] = -32'sd9;  inputs[0][3] = 32'sd3;
    inputs[0][4] = -32'sd17; inputs[0][5] = 32'sd38;  inputs[0][6] = 32'sd0;  inputs[0][7] = 32'sd11;
    goldens[0][0] = -32'sd17; goldens[0][1] = -32'sd9; goldens[0][2] = 32'sd0;  goldens[0][3] = 32'sd3;
    goldens[0][4] = 32'sd5;   goldens[0][5] = 32'sd11; goldens[0][6] = 32'sd22; goldens[0][7] = 32'sd38;

    // inputs[1]
    inputs[1][0] = 32'sd7; inputs[1][1] = 32'sd6; inputs[1][2] = 32'sd5; inputs[1][3] = 32'sd4;
    inputs[1][4] = 32'sd3; inputs[1][5] = 32'sd2; inputs[1][6] = 32'sd1; inputs[1][7] = 32'sd0;
    goldens[1][0] = 32'sd0; goldens[1][1] = 32'sd1; goldens[1][2] = 32'sd2; goldens[1][3] = 32'sd3;
    goldens[1][4] = 32'sd4; goldens[1][5] = 32'sd5; goldens[1][6] = 32'sd6; goldens[1][7] = 32'sd7;

    // inputs[2]
    inputs[2][0] = 32'sd100; inputs[2][1] = -32'sd50; inputs[2][2] = 32'sd25;  inputs[2][3] = -32'sd75;
    inputs[2][4] = 32'sd0;   inputs[2][5] = 32'sd50;  inputs[2][6] = -32'sd100; inputs[2][7] = 32'sd75;
    goldens[2][0] = -32'sd100; goldens[2][1] = -32'sd75; goldens[2][2] = -32'sd50; goldens[2][3] = 32'sd0;
    goldens[2][4] = 32'sd25;  goldens[2][5] = 32'sd50;  goldens[2][6] = 32'sd75;  goldens[2][7] = 32'sd100;

    // inputs[3]
    inputs[3][0] = 32'sd9; inputs[3][1] = 32'sd9; inputs[3][2] = 32'sd9; inputs[3][3] = 32'sd1;
    inputs[3][4] = 32'sd1; inputs[3][5] = 32'sd1; inputs[3][6] = 32'sd5; inputs[3][7] = 32'sd5;
    goldens[3][0] = 32'sd1; goldens[3][1] = 32'sd1; goldens[3][2] = 32'sd1; goldens[3][3] = 32'sd5;
    goldens[3][4] = 32'sd5; goldens[3][5] = 32'sd9; goldens[3][6] = 32'sd9; goldens[3][7] = 32'sd9;

    // inputs[4]
    inputs[4][0] = -32'sd5; inputs[4][1] = -32'sd10; inputs[4][2] = -32'sd3; inputs[4][3] = -32'sd8;
    inputs[4][4] = -32'sd1; inputs[4][5] = -32'sd7;  inputs[4][6] = -32'sd2; inputs[4][7] = -32'sd4;
    goldens[4][0] = -32'sd10; goldens[4][1] = -32'sd8; goldens[4][2] = -32'sd7; goldens[4][3] = -32'sd5;
    goldens[4][4] = -32'sd4;  goldens[4][5] = -32'sd3; goldens[4][6] = -32'sd2; goldens[4][7] = -32'sd1;

    // Reset
    rstn = 1'b0; start = 1'b0;
    A0 = 0;A1 = 0;A2 = 0;A3 = 0;A4 = 0;A5 = 0;A6 = 0;A7 = 0;
    global_pass = 1'b1;

    repeat (5) @(posedge clk);
    rstn = 1'b1;
    @(posedge clk);

    fd = $fopen("results.txt","w");
    if (fd == 0) begin
      $display("Error: Could not open results.txt for writing.");
    end

    // Run 5 cases
    for (i = 0; i < 5; i = i + 1) begin
      // Drive inputs
      A0 = inputs[i][0]; A1 = inputs[i][1]; A2 = inputs[i][2]; A3 = inputs[i][3];
      A4 = inputs[i][4]; A5 = inputs[i][5]; A6 = inputs[i][6]; A7 = inputs[i][7];

      // Start pulse
      @(posedge clk);
      start = 1'b1;
      @(posedge clk);
      start = 1'b0;

      // Wait for done
      @(posedge DONE); // outputs latched at same cycle

      // Check results
      local_pass =
        (O0 === goldens[i][0]) &&
        (O1 === goldens[i][1]) &&
        (O2 === goldens[i][2]) &&
        (O3 === goldens[i][3]) &&
        (O4 === goldens[i][4]) &&
        (O5 === goldens[i][5]) &&
        (O6 === goldens[i][6]) &&
        (O7 === goldens[i][7]);

      if (!local_pass) global_pass = 1'b0;

      // Print to console
      $display("LOCAL_CHECK%0d: %s, Input: %0d %0d %0d %0d %0d %0d %0d %0d, Actual Output: %0d %0d %0d %0d %0d %0d %0d %0d, Golden Output: %0d %0d %0d %0d %0d %0d %0d %0d, N_INST: %0d",
               i+1,
               (local_pass ? "PASS" : "FAIL"),
               $signed(inputs[i][0]), $signed(inputs[i][1]), $signed(inputs[i][2]), $signed(inputs[i][3]),
               $signed(inputs[i][4]), $signed(inputs[i][5]), $signed(inputs[i][6]), $signed(inputs[i][7]),
               $signed(O0), $signed(O1), $signed(O2), $signed(O3), $signed(O4), $signed(O5), $signed(O6), $signed(O7),
               $signed(goldens[i][0]), $signed(goldens[i][1]), $signed(goldens[i][2]), $signed(goldens[i][3]),
               $signed(goldens[i][4]), $signed(goldens[i][5]), $signed(goldens[i][6]), $signed(goldens[i][7]),
               $signed(NINST));

      // Write to file
      if (fd != 0) begin
        $fwrite(fd,
          "LOCAL_CHECK%0d: %s, Input: %0d %0d %0d %0d %0d %0d %0d %0d, Actual Output: %0d %0d %0d %0d %0d %0d %0d %0d, Golden Output: %0d %0d %0d %0d %0d %0d %0d %0d, N_INST: %0d\n",
          i+1,
          (local_pass ? "PASS" : "FAIL"),
          $signed(inputs[i][0]), $signed(inputs[i][1]), $signed(inputs[i][2]), $signed(inputs[i][3]),
          $signed(inputs[i][4]), $signed(inputs[i][5]), $signed(inputs[i][6]), $signed(inputs[i][7]),
          $signed(O0), $signed(O1), $signed(O2), $signed(O3), $signed(O4), $signed(O5), $signed(O6), $signed(O7),
          $signed(goldens[i][0]), $signed(goldens[i][1]), $signed(goldens[i][2]), $signed(goldens[i][3]),
          $signed(goldens[i][4]), $signed(goldens[i][5]), $signed(goldens[i][6]), $signed(goldens[i][7]),
          $signed(NINST));
      end

      // One idle cycle between cases
      @(posedge clk);
    end

    if (fd != 0) begin
      $fwrite(fd, "GLOBAL_CHECK: %s\n", (global_pass ? "PASS" : "FAIL"));
      $fclose(fd);
      $display("Results saved to results.txt");
    end

    $display("\nGLOBAL_CHECK: %s", (global_pass ? "PASS" : "FAIL"));
    #20;
    $finish;
  end

endmodule
