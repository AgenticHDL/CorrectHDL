
`timescale 1ns/1ps

module tb_sha;

  // clock/reset
  reg clk;
  reg rst_n;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;  // 100MHz
  end

  initial begin
    rst_n = 1'b0;
    #100;
    rst_n = 1'b1;
  end

  // DUT I/O
  reg         start;
  reg  [15:0] msg_len;
  wire        busy;
  wire        digest_valid;

  reg         in_valid;
  reg  [7:0]  in_data;
  wire        in_ready;

  wire [31:0] digest0, digest1, digest2, digest3, digest4;

  // 结果相关
  reg         local_pass = 1'b1;   // 每次检查前会重置为 1
  reg [63:0]  total_bits, total_bytes, n_inst;
  reg         global_pass;
  reg         pass_flags [0:4];

  // Instantiate DUT
  sha0_core #(
    .MAX_INPUT_BYTES(64)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .msg_len(msg_len),
    .busy(busy),
    .digest_valid(digest_valid),

    .in_valid(in_valid),
    .in_data(in_data),
    .in_ready(in_ready),

    .digest0(digest0),
    .digest1(digest1),
    .digest2(digest2),
    .digest3(digest3),
    .digest4(digest4)
  );

  // ----------------------------------------
  // Messages (as bytes) and lengths
  // ----------------------------------------
  // tv[0] = ""
  // tv[1] = "abc"
  // tv[2] = "message digest"
  // tv[3] = "abcdefghijklmnopqrstuvwxyz"
  // tv[4] = "abcdbcdecdefdefgefghfghigh"   // 长度 = 26 字节（不是 28！）
  //
  // SHA-0 goldens (big-endian words):
  // 0: f96cea19 8ad1dd56 17ac084a 3d92c610 7708c0ef
  // 1: 0164b8a9 14cd2a5e 74c4f7ff 082c4d97 f1edf880
  // 2: c1b0f222 d150ebb9 aa36a40c afdc8bcb ed830b14
  // 3: b40ce07a 430cfd3c 033039b9 fe9afec9 5dc1bdcd
  // 4: 5b96da10 eafa22e3 7bdd6ffd 8c77920e bcb75c29

  // storage for current message bytes (<=64)
  reg [7:0] msg_mem [0:63];

  // golden digests per test
  reg [31:0] golden [0:4][0:4];

  integer out_fd;
  integer i;

  // helpers
  task init_golden;
  begin
    // test 0
    golden[0][0] = 32'hf96cea19;
    golden[0][1] = 32'h8ad1dd56;
    golden[0][2] = 32'h17ac084a;
    golden[0][3] = 32'h3d92c610;
    golden[0][4] = 32'h7708c0ef;
    // test 1
    golden[1][0] = 32'h0164b8a9;
    golden[1][1] = 32'h14cd2a5e;
    golden[1][2] = 32'h74c4f7ff;
    golden[1][3] = 32'h082c4d97;
    golden[1][4] = 32'hf1edf880;
    // test 2
    golden[2][0] = 32'hc1b0f222;
    golden[2][1] = 32'hd150ebb9;
    golden[2][2] = 32'haa36a40c;
    golden[2][3] = 32'hafdc8bcb;
    golden[2][4] = 32'hed830b14;
    // test 3
    golden[3][0] = 32'hb40ce07a;
    golden[3][1] = 32'h430cfd3c;
    golden[3][2] = 32'h033039b9;
    golden[3][3] = 32'hfe9afec9;
    golden[3][4] = 32'h5dc1bdcd;
    // test 4
    golden[4][0] = 32'h5b96da10;
    golden[4][1] = 32'heafa22e3;
    golden[4][2] = 32'h7bdd6ffd;
    golden[4][3] = 32'h8c77920e;
    golden[4][4] = 32'hbcb75c29;
  end
  endtask

  task clear_msg_mem;
  begin
    for (i=0; i<64; i=i+1) msg_mem[i] = 8'd0;
  end
  endtask

  task load_msg_0; // ""
  begin
    clear_msg_mem();
    msg_len = 16'd0;
  end
  endtask

  task load_msg_1; // "abc"
  begin
    clear_msg_mem();
    msg_mem[0] = "a";
    msg_mem[1] = "b";
    msg_mem[2] = "c";
    msg_len = 16'd3;
  end
  endtask

  task load_msg_2; // "message digest"
  begin
    integer k;
    reg [8*14-1:0] s;
    clear_msg_mem();
    s = "message digest";
    for (k=0;k<14;k=k+1) msg_mem[k] = s[8*(14-k)-1 -: 8];
    msg_len = 16'd14;
  end
  endtask

  task load_msg_3; // "abcdefghijklmnopqrstuvwxyz"
  begin
    integer k;
    reg [8*26-1:0] s;
    clear_msg_mem();
    s = "abcdefghijklmnopqrstuvwxyz";
    for (k=0;k<26;k=k+1) msg_mem[k] = s[8*(26-k)-1 -: 8];
    msg_len = 16'd26;
  end
  endtask

  task load_msg_4; // "abcdbcdecdefdefgefghfghigh"  (长度=26)
  begin
    integer k;
    // 26 bytes  <<< 修正：原来误写成 28
    reg [8*26-1:0] s;
    clear_msg_mem();
    s = "abcdbcdecdefdefgefghfghigh";
    for (k=0;k<26;k=k+1) msg_mem[k] = s[8*(26-k)-1 -: 8];
    msg_len = 16'd26; // <<< 修正：原来是 28
  end
  endtask

  // stream sender: sends msg_mem[0..msg_len-1]
  task send_stream;
    integer p;
  begin
    p = 0;
    // start pulse
    @(posedge clk);
    start   <= 1'b1;
    in_valid<= 1'b0;
    in_data <= 8'd0;
    @(posedge clk);
    start   <= 1'b0;

    // now stream bytes
    while (p < msg_len) begin
      @(posedge clk);
      if (in_ready) begin
        in_valid <= 1'b1;
        in_data  <= msg_mem[p];
        p = p + 1;
      end else begin
        in_valid <= 1'b0;
        in_data  <= 8'd0;
      end
    end
    // finish stream
    @(posedge clk);
    in_valid <= 1'b0;
    in_data  <= 8'd0;
  end
  endtask

  // wait for result, compare, print line, write file
  task wait_and_check;
    input integer tindex;          // <<< 修复：为任务添加形参
  begin
    // 每次检查前重置
    local_pass = 1'b1;             // <<< 修复：避免一次失败影响后续用例

    // wait for digest_valid
    wait (digest_valid === 1'b1);
    @(posedge clk); // sample after pulse

    // compare
    if (digest0 !== golden[tindex][0]) local_pass = 1'b0;
    if (digest1 !== golden[tindex][1]) local_pass = 1'b0;
    if (digest2 !== golden[tindex][2]) local_pass = 1'b0;
    if (digest3 !== golden[tindex][3]) local_pass = 1'b0;
    if (digest4 !== golden[tindex][4]) local_pass = 1'b0;

    // N_INST estimation (like C++)
    // total_bits = len*8 + 1 + 64; total_bytes = ceil(total_bits/8)
    // n_inst = ceil(total_bytes/64)
    total_bits  = (msg_len * 8) + 1 + 64;
    total_bytes = (total_bits + 7) >> 3;
    n_inst      = (total_bytes + 63) >> 6;

    // build hex strings
    $display("LOCAL_CHECK%0d: %s, Input: %0s, Actual Output: %08x %08x %08x %08x %08x, Golden Output: %08x %08x %08x %08x %08x, N_INST: %0d",
              tindex+1,
              local_pass ? "PASS" : "FAIL",
              (tindex==0) ? "" :
              (tindex==1) ? "abc" :
              (tindex==2) ? "message digest" :
              (tindex==3) ? "abcdefghijklmnopqrstuvwxyz" :
                            "abcdbcdecdefdefgefghfghigh",
              digest0, digest1, digest2, digest3, digest4,
              golden[tindex][0], golden[tindex][1], golden[tindex][2],
              golden[tindex][3], golden[tindex][4],
              n_inst);

    if (out_fd != 0) begin
      $fdisplay(out_fd,
        "LOCAL_CHECK%0d: %s, Input: %0s, Actual Output: %08x %08x %08x %08x %08x, Golden Output: %08x %08x %08x %08x %08x, N_INST: %0d",
        tindex+1,
        local_pass ? "PASS" : "FAIL",
        (tindex==0) ? "" :
        (tindex==1) ? "abc" :
        (tindex==2) ? "message digest" :
        (tindex==3) ? "abcdefghijklmnopqrstuvwxyz" :
                      "abcdbcdecdefdefgefghfghigh",
        digest0, digest1, digest2, digest3, digest4,
        golden[tindex][0], golden[tindex][1], golden[tindex][2],
        golden[tindex][3], golden[tindex][4],
        n_inst);
    end

    // record pass/fail flag for global summary
    pass_flags[tindex] = local_pass;
  end
  endtask

  // ----------------------------------------
  // Test sequence
  // ----------------------------------------
  initial begin
    start   = 1'b0;
    msg_len = 16'd0;
    in_valid= 1'b0;
    in_data = 8'd0;

    init_golden();

    // open results file
    out_fd = $fopen("results.txt", "w");
    if (out_fd == 0) $display("Error: Could not open results.txt for writing.");

    // wait reset
    @(posedge rst_n);
    @(posedge clk);

    // ---------- Test 1: "" ----------
    load_msg_0();
    send_stream();
    wait_and_check(0);

    // ---------- Test 2: "abc" ----------
    load_msg_1();
    send_stream();
    wait_and_check(1);

    // ---------- Test 3: "message digest" ----------
    load_msg_2();
    send_stream();
    wait_and_check(2);

    // ---------- Test 4: "abcdefghijklmnopqrstuvwxyz" ----------
    load_msg_3();
    send_stream();
    wait_and_check(3);

    // ---------- Test 5: "abcdbcdecdefdefgefghfghigh" ----------
    load_msg_4();
    send_stream();
    wait_and_check(4);

    // global summary
    global_pass = pass_flags[0] & pass_flags[1] & pass_flags[2] & pass_flags[3] & pass_flags[4];

    $display("\nGLOBAL_CHECK: %s", global_pass ? "PASS" : "FAIL");
    if (out_fd != 0) begin
      $fdisplay(out_fd, "GLOBAL_CHECK: %s", global_pass ? "PASS" : "FAIL");
      $fclose(out_fd);
      $display("\nResults saved to results.txt");
    end

    #50;
    $finish;
  end

endmodule
