// tb_kmp4.v
`timescale 1ns/1ps

module tb_kmp;

  localparam PATTERN_SIZE = 4;
  localparam STRING_SIZE  = 2241;

  reg         clk;
  reg         rst_n;
  reg         start;
  reg  [7:0]  pattern_0, pattern_1, pattern_2, pattern_3;
  reg         in_valid;
  wire        in_ready;
  reg  [7:0]  in_data;
  reg         in_last;
  wire        done;
  wire [31:0] n_matches;

  kmp4 #(.PATTERN_SIZE(PATTERN_SIZE), .STRING_SIZE(STRING_SIZE)) dut (
    .clk(clk), .rst_n(rst_n), .start(start),
    .pattern_0(pattern_0), .pattern_1(pattern_1),
    .pattern_2(pattern_2), .pattern_3(pattern_3),
    .in_valid(in_valid), .in_ready(in_ready),
    .in_data(in_data), .in_last(in_last),
    .done(done), .n_matches(n_matches)
  );

  // clock
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // reset
  initial begin
    rst_n = 1'b0;
    start = 1'b0;
    in_valid = 1'b0; in_data = 8'd0; in_last = 1'b0;
    pattern_0=8'd0; pattern_1=8'd0; pattern_2=8'd0; pattern_3=8'd0;
    #100; rst_n = 1'b1;
  end

  task automatic stream_byte(input [7:0] b, input is_last);
    begin
      @(posedge clk);
      while (!in_ready) @(posedge clk);
      in_data  <= b;
      in_last  <= is_last ? 1'b1 : 1'b0;
      in_valid <= 1'b1;
      @(posedge clk);
      in_valid <= 1'b0;
      in_last  <= 1'b0;
    end
  endtask

  task automatic run_test(
    input [8*24-1:0] name_str,
    input [7:0] p0, input [7:0] p1, input [7:0] p2, input [7:0] p3,
    input integer golden,
    output integer actual_out
  );
    integer i, rem;
    reg [8*24-1:0] nm;
    begin
      nm = name_str;

      // load pattern + start
      pattern_0 <= p0; pattern_1 <= p1; pattern_2 <= p2; pattern_3 <= p3;
      @(posedge clk); start <= 1'b1;
      @(posedge clk); start <= 1'b0;

      // feed
      if (nm == "T1_ABCD_scattered") begin
        for (i=0; i<STRING_SIZE; i=i+1) begin
          if ((i==100)||(i==400)||(i==800)||(i==1200)||(i==1600)||(i==2000)||(i==2100)) begin
            stream_byte(8'h41, 1'b0); // A
            stream_byte(8'h42, 1'b0); // B
            stream_byte(8'h43, 1'b0); // C
            if ((i+3)==(STRING_SIZE-1)) stream_byte(8'h44, 1'b1);
            else stream_byte(8'h44, 1'b0); // D
            i = i + 3;
          end else begin
            if (i == STRING_SIZE-1) stream_byte(8'h5A, 1'b1); // Z
            else stream_byte(8'h5A, 1'b0);
          end
        end
      end
      else if (nm == "T2_AAAA_runs") begin
        for (i=0; i<STRING_SIZE; i=i+1) begin
          if ((i<20) || (i>=1000 && i<1050)) begin
            if (i == STRING_SIZE-1) stream_byte(8'h41, 1'b1);
            else stream_byte(8'h41, 1'b0); // A
          end else begin
            if (i == STRING_SIZE-1) stream_byte(8'h42, 1'b1);
            else stream_byte(8'h42, 1'b0); // B
          end
        end
      end
      else if (nm == "T3_ABAB_repeat200") begin
        for (i=0; i<STRING_SIZE; i=i+1) begin
          if (i < 200) begin
            if ((i & 1)==0) begin
              if (i == STRING_SIZE-1) stream_byte(8'h41, 1'b1);
              else stream_byte(8'h41, 1'b0); // A
            end else begin
              if (i == STRING_SIZE-1) stream_byte(8'h42, 1'b1);
              else stream_byte(8'h42, 1'b0); // B
            end
          end else begin
            if (i == STRING_SIZE-1) stream_byte(8'h5A, 1'b1);
            else stream_byte(8'h5A, 1'b0); // Z
          end
        end
      end
      else if (nm == "T4_DCBA_nomatch") begin
        for (i=0; i<STRING_SIZE; i=i+1) begin
          if (i == STRING_SIZE-1) stream_byte(8'h41, 1'b1);
          else stream_byte(8'h41, 1'b0); // A
        end
      end
      else begin // T5_ABCD_tightpack
        i = 0;

        while (i + 4 <= STRING_SIZE) begin
          stream_byte(8'h41, 1'b0); // A
          stream_byte(8'h42, 1'b0); // B
          stream_byte(8'h43, 1'b0); // C
          if ((i+4)==STRING_SIZE) stream_byte(8'h44, 1'b1);
          else stream_byte(8'h44, 1'b0); // D
          i = i + 4;
        end

        rem = STRING_SIZE - i; // 0..3
        if (rem > 0) begin
          if (rem >= 1) stream_byte(8'h41, (rem==1) ? 1'b1 : 1'b0); // A
          if (rem >= 2) stream_byte(8'h42, (rem==2) ? 1'b1 : 1'b0); // B
          if (rem >= 3) stream_byte(8'h43, 1'b1);                   // C
        end
      end

      // wait done & capture
      @(posedge clk);
      while (!done) @(posedge clk);
      actual_out = n_matches;

      if (actual_out == golden)
        $display("LOCAL_CHECK%0d: PASS, Input: %0s, Actual Output: %0d, Golden Output: %0d",
          (nm=="T1_ABCD_scattered")?1:
          (nm=="T2_AAAA_runs")?2:
          (nm=="T3_ABAB_repeat200")?3:
          (nm=="T4_DCBA_nomatch")?4:5,
          nm, actual_out, golden);
      else
        $display("LOCAL_CHECK%0d: FAIL, Input: %0s, Actual Output: %0d, Golden Output: %0d",
          (nm=="T1_ABCD_scattered")?1:
          (nm=="T2_AAAA_runs")?2:
          (nm=="T3_ABAB_repeat200")?3:
          (nm=="T4_DCBA_nomatch")?4:5,
          nm, actual_out, golden);
      repeat (5) @(posedge clk);
    end
  endtask

  integer pass_count;
  integer actual1, actual2, actual3, actual4, actual5;
  initial begin
    pass_count = 0;
    @(posedge rst_n);
    repeat (10) @(posedge clk);

    run_test("T1_ABCD_scattered", 8'h41,8'h42,8'h43,8'h44, 7,   actual1); if (actual1==7)   pass_count=pass_count+1;
    run_test("T2_AAAA_runs",      8'h41,8'h41,8'h41,8'h41, 64,  actual2); if (actual2==64)  pass_count=pass_count+1;
    run_test("T3_ABAB_repeat200", 8'h41,8'h42,8'h41,8'h42, 99,  actual3); if (actual3==99)  pass_count=pass_count+1;
    run_test("T4_DCBA_nomatch",   8'h44,8'h43,8'h42,8'h41, 0,   actual4); if (actual4==0)   pass_count=pass_count+1;
    run_test("T5_ABCD_tightpack", 8'h41,8'h42,8'h43,8'h44, 560, actual5); if (actual5==560) pass_count=pass_count+1;

    if (pass_count==5) begin
      $display("GLOBAL_CHECK: PASS");
      $display("LOCAL_CHECK1: PASS, Input: T1_ABCD_scattered, Actual Output: %0d, Golden Output: 7",   actual1);
      $display("LOCAL_CHECK2: PASS, Input: T2_AAAA_runs,      Actual Output: %0d, Golden Output: 64",  actual2);
      $display("LOCAL_CHECK3: PASS, Input: T3_ABAB_repeat200, Actual Output: %0d, Golden Output: 99",  actual3);
      $display("LOCAL_CHECK4: PASS, Input: T4_DCBA_nomatch,   Actual Output: %0d, Golden Output: 0",   actual4);
      $display("LOCAL_CHECK5: PASS, Input: T5_ABCD_tightpack, Actual Output: %0d, Golden Output: 560", actual5);
    end else begin
      $display("GLOBAL_CHECK: FAIL");
    end

    #100; $finish;
  end

endmodule
