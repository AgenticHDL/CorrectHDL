`timescale 1ns/1ps

module tb_nw;

  // clock/reset
  reg clk, rstn, start;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100MHz
  end

  // DUT inputs (10 bytes each)
  reg [7:0] A[0:9];
  reg [7:0] B[0:9];

  // wires to connect to DUT ports
  wire [7:0] ALIGA[0:19];
  wire [7:0] ALIGB[0:19];
  wire       DONE;

  // DUT
  needwun dut (
    .clk(clk), .rstn(rstn), .start(start),
    .SEQA0(A[0]),  .SEQA1(A[1]),  .SEQA2(A[2]),  .SEQA3(A[3]),
    .SEQA4(A[4]),  .SEQA5(A[5]),  .SEQA6(A[6]),  .SEQA7(A[7]),
    .SEQA8(A[8]),  .SEQA9(A[9]),
    .SEQB0(B[0]),  .SEQB1(B[1]),  .SEQB2(B[2]),  .SEQB3(B[3]),
    .SEQB4(B[4]),  .SEQB5(B[5]),  .SEQB6(B[6]),  .SEQB7(B[7]),
    .SEQB8(B[8]),  .SEQB9(B[9]),
    .ALIGA0(ALIGA[0]),   .ALIGA1(ALIGA[1]),   .ALIGA2(ALIGA[2]),   .ALIGA3(ALIGA[3]),
    .ALIGA4(ALIGA[4]),   .ALIGA5(ALIGA[5]),   .ALIGA6(ALIGA[6]),   .ALIGA7(ALIGA[7]),
    .ALIGA8(ALIGA[8]),   .ALIGA9(ALIGA[9]),   .ALIGA10(ALIGA[10]), .ALIGA11(ALIGA[11]),
    .ALIGA12(ALIGA[12]), .ALIGA13(ALIGA[13]), .ALIGA14(ALIGA[14]), .ALIGA15(ALIGA[15]),
    .ALIGA16(ALIGA[16]), .ALIGA17(ALIGA[17]), .ALIGA18(ALIGA[18]), .ALIGA19(ALIGA[19]),
    .ALIGB0(ALIGB[0]),   .ALIGB1(ALIGB[1]),   .ALIGB2(ALIGB[2]),   .ALIGB3(ALIGB[3]),
    .ALIGB4(ALIGB[4]),   .ALIGB5(ALIGB[5]),   .ALIGB6(ALIGB[6]),   .ALIGB7(ALIGB[7]),
    .ALIGB8(ALIGB[8]),   .ALIGB9(ALIGB[9]),   .ALIGB10(ALIGB[10]), .ALIGB11(ALIGB[11]),
    .ALIGB12(ALIGB[12]), .ALIGB13(ALIGB[13]), .ALIGB14(ALIGB[14]), .ALIGB15(ALIGB[15]),
    .ALIGB16(ALIGB[16]), .ALIGB17(ALIGB[17]), .ALIGB18(ALIGB[18]), .ALIGB19(ALIGB[19]),
    .done(DONE)
  );

  // helper: clear inputs
  integer ii;
  task clear_inputs;
    begin
      for (ii=0; ii<10; ii=ii+1) begin
        A[ii] = 8'd0;
        B[ii] = 8'd0;
      end
    end
  endtask

  // 5 fixed tests (同你 C++ 版本，超过长度截断到10)
  // 0: "GATTACA" | "GCATGCU"
  // 1: "AAAAACCCCTTTTGGGG" -> A="AAAAACCCCT" | B="AAAACCCGGTT" -> "AAAACCCGGT"
  // 2: "NEEDLEMANWUNSCH" -> "NEEDLEMANW" | "NEWMANWINS"
  // 3: "HELLOWORLD" | "YELLOWBIRD"
  // 4: "AAAAAAAA....(32 A)" -> 10 'A' | "AAAAAAAA...(23A)+TTTTTTTT" -> 前10个 'A'
  task load_test(input integer tid);
    integer j;
    begin
      clear_inputs();
      case (tid)
        0: begin
          A[0]="G";A[1]="A";A[2]="T";A[3]="T";A[4]="A";A[5]="C";A[6]="A";
          B[0]="G";B[1]="C";B[2]="A";B[3]="T";B[4]="G";B[5]="C";B[6]="U";
        end
        1: begin
          // A: "AAAAACCCCT"
          A[0]="A";A[1]="A";A[2]="A";A[3]="A";A[4]="A";
          A[5]="C";A[6]="C";A[7]="C";A[8]="C";
          A[9]="T";
          // B: "AAAACCCGGT"
          B[0]="A";B[1]="A";B[2]="A";B[3]="A";
          B[4]="C";B[5]="C";B[6]="C";B[7]="G";B[8]="G";B[9]="T";
        end
        2: begin
          // A: "NEEDLEMANW"
          A[0]="N";A[1]="E";A[2]="E";A[3]="D";A[4]="L";A[5]="E";A[6]="M";A[7]="A";A[8]="N";A[9]="W";
          // B: "NEWMANWINS"
          B[0]="N";B[1]="E";B[2]="W";B[3]="M";B[4]="A";B[5]="N";B[6]="W";B[7]="I";B[8]="N";B[9]="S";
        end
        3: begin
          // A: "HELLOWORLD" 10 chars
          A[0]="H";A[1]="E";A[2]="L";A[3]="L";A[4]="O";A[5]="W";A[6]="O";A[7]="R";A[8]="L";A[9]="D";
          // B: "YELLOWBIRD" 10 chars
          B[0]="Y";B[1]="E";B[2]="L";B[3]="L";B[4]="O";B[5]="W";B[6]="B";B[7]="I";B[8]="R";B[9]="D";
        end
        4: begin
          // A = 10 'A'
          for (j=0; j<10; j=j+1) A[j] = "A";
          // B = 10 'A' (被截断)
          for (j=0; j<10; j=j+1) B[j] = "A";
        end
      endcase
    end
  endtask

  // djb2 hash for 20-byte array
  function [63:0] djb2_arr20;
    input [7:0] a0;  input [7:0] a1;  input [7:0] a2;  input [7:0] a3;  input [7:0] a4;
    input [7:0] a5;  input [7:0] a6;  input [7:0] a7;  input [7:0] a8;  input [7:0] a9;
    input [7:0] a10; input [7:0] a11; input [7:0] a12; input [7:0] a13; input [7:0] a14;
    input [7:0] a15; input [7:0] a16; input [7:0] a17; input [7:0] a18; input [7:0] a19;
    reg [63:0] h;
    begin
      h = 64'd5381;
      h = ((h<<5)+h) + a0;   h = ((h<<5)+h) + a1;   h = ((h<<5)+h) + a2;   h = ((h<<5)+h) + a3;   h = ((h<<5)+h) + a4;
      h = ((h<<5)+h) + a5;   h = ((h<<5)+h) + a6;   h = ((h<<5)+h) + a7;   h = ((h<<5)+h) + a8;   h = ((h<<5)+h) + a9;
      h = ((h<<5)+h) + a10;  h = ((h<<5)+h) + a11;  h = ((h<<5)+h) + a12;  h = ((h<<5)+h) + a13;  h = ((h<<5)+h) + a14;
      h = ((h<<5)+h) + a15;  h = ((h<<5)+h) + a16;  h = ((h<<5)+h) + a17;  h = ((h<<5)+h) + a18;  h = ((h<<5)+h) + a19;
      djb2_arr20 = h;
    end
  endfunction

  // GOLDEN hashes for ALEN=10, BLEN=10（已按 C 参考算法计算）
  function [63:0] golden_hash_by_id;
    input integer tid;
    begin
      case (tid)
        0: golden_hash_by_id = 64'h5c7f9b08fbe64c99;
        1: golden_hash_by_id = 64'hb0be548b1686ae96;
        2: golden_hash_by_id = 64'h155c83c11c948b09;
        3: golden_hash_by_id = 64'h0e9ffbf35be71d03;
        4: golden_hash_by_id = 64'h0000000000000000; // 两串全 'A'，对齐完全一致 -> XOR 为 0
        default: golden_hash_by_id = 64'h0;
      endcase
    end
  endfunction

  // test flow
  integer t;
  integer fd;
  reg global_pass, local_pass;
  reg [63:0] hA, hB, actual, golden;
  localparam [31:0] N_INST = 32'd100; // ALEN*BLEN

  initial begin
    rstn = 1'b0; start = 1'b0;
    clear_inputs();
    repeat (5) @(posedge clk);
    rstn = 1'b1;
    @(posedge clk);

    fd = $fopen("results.txt","w");
    if (fd==0) $display("Error: Could not open results.txt for writing.");

    global_pass = 1'b1;

    for (t=0; t<5; t=t+1) begin
      load_test(t);
      @(posedge clk); start = 1'b1;
      @(posedge clk); start = 1'b0;

      @(posedge DONE); // wait the one-cycle 'done'

      // compute hashes (20B each)
      hA = djb2_arr20(
        ALIGA[0],ALIGA[1],ALIGA[2],ALIGA[3],ALIGA[4],
        ALIGA[5],ALIGA[6],ALIGA[7],ALIGA[8],ALIGA[9],
        ALIGA[10],ALIGA[11],ALIGA[12],ALIGA[13],ALIGA[14],
        ALIGA[15],ALIGA[16],ALIGA[17],ALIGA[18],ALIGA[19]
      );
      hB = djb2_arr20(
        ALIGB[0],ALIGB[1],ALIGB[2],ALIGB[3],ALIGB[4],
        ALIGB[5],ALIGB[6],ALIGB[7],ALIGB[8],ALIGB[9],
        ALIGB[10],ALIGB[11],ALIGB[12],ALIGB[13],ALIGB[14],
        ALIGB[15],ALIGB[16],ALIGB[17],ALIGB[18],ALIGB[19]
      );
      actual = hA ^ hB;
      golden = golden_hash_by_id(t);

      local_pass = (actual===golden);
      if (!local_pass) global_pass = 1'b0;

      case (t)
        0: begin
          $display("LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %016h, Golden Output: %016h, N_INST: %0d",
                   t+1, (local_pass?"PASS":"FAIL"), "GATTACA|GCATGCU", actual, golden, N_INST);
          if (fd!=0) $fwrite(fd, "LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %016h, Golden Output: %016h, N_INST: %0d\n",
                   t+1, (local_pass?"PASS":"FAIL"), "GATTACA|GCATGCU", actual, golden, N_INST);
        end
        1: begin
          $display("LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %016h, Golden Output: %016h, N_INST: %0d",
                   t+1, (local_pass?"PASS":"FAIL"), "AAAAACCCCTTTTGGGG|AAAACCCGGTT (trunc to 10/10)", actual, golden, N_INST);
          if (fd!=0) $fwrite(fd, "LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %016h, Golden Output: %016h, N_INST: %0d\n",
                   t+1, (local_pass?"PASS":"FAIL"), "AAAAACCCCTTTTGGGG|AAAACCCGGTT (trunc to 10/10)", actual, golden, N_INST);
        end
        2: begin
          $display("LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %016h, Golden Output: %016h, N_INST: %0d",
                   t+1, (local_pass?"PASS":"FAIL"), "NEEDLEMANWUNSCH|NEWMANWINS (trunc A to 10)", actual, golden, N_INST);
          if (fd!=0) $fwrite(fd, "LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %016h, Golden Output: %016h, N_INST: %0d\n",
                   t+1, (local_pass?"PASS":"FAIL"), "NEEDLEMANWUNSCH|NEWMANWINS (trunc A to 10)", actual, golden, N_INST);
        end
        3: begin
          $display("LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %016h, Golden Output: %016h, N_INST: %0d",
                   t+1, (local_pass?"PASS":"FAIL"), "HELLOWORLD|YELLOWBIRD", actual, golden, N_INST);
          if (fd!=0) $fwrite(fd, "LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %016h, Golden Output: %016h, N_INST: %0d\n",
                   t+1, (local_pass?"PASS":"FAIL"), "HELLOWORLD|YELLOWBIRD", actual, golden, N_INST);
        end
        4: begin
          $display("LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %016h, Golden Output: %016h, N_INST: %0d",
                   t+1, (local_pass?"PASS":"FAIL"), "A*32|A*23+T*8 (trunc to 10/10 A's)", actual, golden, N_INST);
          if (fd!=0) $fwrite(fd, "LOCAL_CHECK%0d: %s, Input: %s, Actual Output: %016h, Golden Output: %016h, N_INST: %0d\n",
                   t+1, (local_pass?"PASS":"FAIL"), "A*32|A*23+T*8 (trunc to 10/10 A's)", actual, golden, N_INST);
        end
      endcase

      @(posedge clk);
    end

    $display("GLOBAL_CHECK: %s", (global_pass?"PASS":"FAIL"));
    if (fd!=0) begin
      $fwrite(fd, "GLOBAL_CHECK: %s\n", (global_pass?"PASS":"FAIL"));
      $fclose(fd);
      $display("Results saved to results.txt");
    end
    #20 $finish;
  end

endmodule
