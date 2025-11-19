`timescale 1ns/1ps

module tb_gemm;
  integer fresult_local;
  // Clock & reset
  reg clk;
  reg rst_n;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100MHz
  end

  initial begin
    rst_n = 1'b0;
    #50;
    rst_n = 1'b1;
  end

  // DUT ports
  reg         wr_en;
  reg  [1:0]  wr_sel;
  reg  [7:0]  wr_addr;              // 0..255
  reg  signed [20:0] wr_data;
  reg         start;
  wire        done;
  wire [31:0] sum_out;

  // Instantiate DUT
  gemm_core dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .wr_en  (wr_en),
    .wr_sel (wr_sel),
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .start  (start),
    .done   (done),
    .sum_out(sum_out)
  );

  // Constants
  localparam ROWS = 16;
  localparam COLS = 16;


  localparam integer TIMEOUT_CYCLES = 10_000_000;


  task write_m1(input integer addr, input integer val);
    begin
      @(posedge clk);
      wr_en   = 1'b1;
      wr_sel  = 2'd0;
      wr_addr = addr[7:0];
      wr_data = val[20:0];
      @(posedge clk);
      wr_en   = 1'b0;
    end
  endtask

  task write_m2(input integer addr, input integer val);
    begin
      @(posedge clk);
      wr_en   = 1'b1;
      wr_sel  = 2'd1;
      wr_addr = addr[7:0];
      wr_data = val[20:0];
      @(posedge clk);
      wr_en   = 1'b0;
    end
  endtask


  task do_start();
    begin

      @(posedge clk);
      @(posedge clk);
      @(posedge clk);


      start = 1'b1;
      @(posedge clk);
      start = 1'b0;
    end
  endtask

  task wait_done();
    integer wd;
    begin
      wd = 0;


      if (done) begin
        while (done) begin
          @(posedge clk);
          wd = wd + 1;
          if (wd > TIMEOUT_CYCLES) begin
            $display("[%0t] ERROR: Timeout waiting for done to go LOW after start.", $time);
            $finish;
          end
        end
      end


      while (!done) begin
        @(posedge clk);
        wd = wd + 1;
        if (wd > TIMEOUT_CYCLES) begin
          $display("[%0t] ERROR: Timeout waiting for done to go HIGH (completion).", $time);
          $finish;
        end
      end


      @(posedge clk);
    end
  endtask

  // Matrix index helper: r*16 + c
  function integer idx(input integer r, input integer c);
    begin
      idx = (r<<4) + c; // 16x16
    end
  endfunction

  // Patterns -------------------------------------------------------
  task zero_all();
    integer a;
    begin
      for (a=0; a<ROWS*COLS; a=a+1) begin
        write_m1(a, 0);
        write_m2(a, 0);
      end
    end
  endtask

  task case_all_ones();
    integer a;
    begin
      for (a=0; a<ROWS*COLS; a=a+1) begin
        write_m1(a, 1);
        write_m2(a, 1);
      end
    end
  endtask

  task case_identity_m1_ones_m2();
    integer r,c,a;
    begin
      // m1 = I
      for (r=0; r<ROWS; r=r+1)
        for (c=0; c<COLS; c=c+1) begin
          a = idx(r,c);
          write_m1(a, (r==c) ? 1 : 0);
        end
      // m2 = ones
      for (a=0; a<ROWS*COLS; a=a+1)
        write_m2(a, 1);
    end
  endtask

  task case_identity_m1_col_inc_m2();
    integer r,c,a;
    begin
      // m1 = I
      for (r=0; r<ROWS; r=r+1)
        for (c=0; c<COLS; c=c+1) begin
          a = idx(r,c);
          write_m1(a, (r==c) ? 1 : 0);
        end
      // m2: column increasing (j+1)
      for (r=0; r<ROWS; r=r+1)
        for (c=0; c<COLS; c=c+1) begin
          a = idx(r,c);
          write_m2(a, c+1);
        end
    end
  endtask

  task case_row_inc_m1_ones_m2();
    integer r,c,a;
    begin
      // m1: row increasing (i+1)
      for (r=0; r<ROWS; r=r+1)
        for (c=0; c<COLS; c=c+1) begin
          a = idx(r,c);
          write_m1(a, r+1);
        end
      // m2 = ones
      for (a=0; a<ROWS*COLS; a=a+1)
        write_m2(a, 1);
    end
  endtask

  task case_row_inc_m1_col_inc_m2();
    integer r,c,a;
    begin
      // m1: row increasing (i+1)
      for (r=0; r<ROWS; r=r+1)
        for (c=0; c<COLS; c=c+1) begin
          a = idx(r,c);
          write_m1(a, r+1);
        end
      // m2: column increasing (j+1)
      for (r=0; r<ROWS; r=r+1)
        for (c=0; c<COLS; c=c+1) begin
          a = idx(r,c);
          write_m2(a, c+1);
        end
    end
  endtask

  // Test sequence --------------------------------------------------
  integer pass_all;
  reg [31:0] golden [0:4];
  reg [31:0] actual;

  initial begin
    // Init
    wr_en   = 1'b0;
    wr_sel  = 2'd0;
    wr_addr = 8'd0;
    wr_data = 21'sd0;
    start   = 1'b0;

    pass_all = 1;

    // Golden for S=16:
    // 1) ones x ones                : S^3           = 4096
    // 2) I x ones                   : S^2           = 256
    // 3) I x col_inc                : S^2*(S+1)/2   = 2176
    // 4) row_inc x ones             : S^3*(S+1)/2   = 34816
    // 5) row_inc x col_inc          : S^3*(S+1)^2/4 = 295936
    golden[0] = 32'd4096;
    golden[1] = 32'd256;
    golden[2] = 32'd2176;
    golden[3] = 32'd34816;
    golden[4] = 32'd295936;

    fresult_local = $fopen("result.txt", "w");

    // Wait reset
    @(posedge rst_n);
    @(posedge clk);

    // ----- Test 1 -----
    zero_all();
    case_all_ones();
    do_start();
    wait_done();
    actual = sum_out;
    if (actual == golden[0]) begin
      $display("LOCAL_CHECK1: PASS, Input: 1, Actual Output: %0d, Golden Output: %0d", actual, golden[0]);
      if (fresult_local) $fdisplay(fresult_local, "LOCAL_CHECK1: PASS, Input: 1, Actual Output: %0d, Golden Output: %0d", actual, golden[0]);
    end else begin
      pass_all = 0;
      $display("LOCAL_CHECK1: FAIL, Input: 1, Actual Output: %0d, Golden Output: %0d", actual, golden[0]);
      if (fresult_local) $fdisplay(fresult_local, "LOCAL_CHECK1: FAIL, Input: 1, Actual Output: %0d, Golden Output: %0d", actual, golden[0]);
    end

    // ----- Test 2 -----
    zero_all();
    case_identity_m1_ones_m2();
    do_start();
    wait_done();
    actual = sum_out;
    if (actual == golden[1]) begin
      $display("LOCAL_CHECK2: PASS, Input: 2, Actual Output: %0d, Golden Output: %0d", actual, golden[1]);
      if (fresult_local) $fdisplay(fresult_local, "LOCAL_CHECK2: PASS, Input: 2, Actual Output: %0d, Golden Output: %0d", actual, golden[1]);
    end else begin
      pass_all = 0;
      $display("LOCAL_CHECK2: FAIL, Input: 2, Actual Output: %0d, Golden Output: %0d", actual, golden[1]);
      if (fresult_local) $fdisplay(fresult_local, "LOCAL_CHECK2: FAIL, Input: 2, Actual Output: %0d, Golden Output: %0d", actual, golden[1]);
    end

    // ----- Test 3 -----
    zero_all();
    case_identity_m1_col_inc_m2();
    do_start();
    wait_done();
    actual = sum_out;
    if (actual == golden[2]) begin
      $display("LOCAL_CHECK3: PASS, Input: 3, Actual Output: %0d, Golden Output: %0d", actual, golden[2]);
      if (fresult_local) $fdisplay(fresult_local, "LOCAL_CHECK3: PASS, Input: 3, Actual Output: %0d, Golden Output: %0d", actual, golden[2]);
    end else begin
      pass_all = 0;
      $display("LOCAL_CHECK3: FAIL, Input: 3, Actual Output: %0d, Golden Output: %0d", actual, golden[2]);
      if (fresult_local) $fdisplay(fresult_local, "LOCAL_CHECK3: FAIL, Input: 3, Actual Output: %0d, Golden Output: %0d", actual, golden[2]);
    end

    // ----- Test 4 -----
    zero_all();
    case_row_inc_m1_ones_m2();
    do_start();
    wait_done();
    actual = sum_out;
    if (actual == golden[3]) begin
      $display("LOCAL_CHECK4: PASS, Input: 4, Actual Output: %0d, Golden Output: %0d", actual, golden[3]);
      if (fresult_local) $fdisplay(fresult_local, "LOCAL_CHECK4: PASS, Input: 4, Actual Output: %0d, Golden Output: %0d", actual, golden[3]);
    end else begin
      pass_all = 0;
      $display("LOCAL_CHECK4: FAIL, Input: 4, Actual Output: %0d, Golden Output: %0d", actual, golden[3]);
      if (fresult_local) $fdisplay(fresult_local, "LOCAL_CHECK4: FAIL, Input: 4, Actual Output: %0d, Golden Output: %0d", actual, golden[3]);
    end

    // ----- Test 5 -----
    zero_all();
    case_row_inc_m1_col_inc_m2();
    do_start();
    wait_done();
    actual = sum_out;
    if (actual == golden[4]) begin
      $display("LOCAL_CHECK5: PASS, Input: 5, Actual Output: %0d, Golden Output: %0d", actual, golden[4]);
      if (fresult_local) $fdisplay(fresult_local, "LOCAL_CHECK5: PASS, Input: 5, Actual Output: %0d, Golden Output: %0d", actual, golden[4]);
    end else begin
      pass_all = 0;
      $display("LOCAL_CHECK5: FAIL, Input: 5, Actual Output: %0d, Golden Output: %0d", actual, golden[4]);
      if (fresult_local) $fdisplay(fresult_local, "LOCAL_CHECK5: FAIL, Input: 5, Actual Output: %0d, Golden Output: %0d", actual, golden[4]);
    end

    if (pass_all) begin
      $display("\nGLOBAL_CHECK: PASS");
      if (fresult_local) $fdisplay(fresult_local, "GLOBAL_CHECK: PASS");
    end else begin
      $display("\nGLOBAL_CHECK: FAIL");
      if (fresult_local) $fdisplay(fresult_local, "GLOBAL_CHECK: FAIL");
    end

    if (fresult_local) $fclose(fresult_local);
    $finish;
  end

endmodule
