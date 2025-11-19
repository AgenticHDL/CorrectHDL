// tb_md_kernel.v  (Verilog-2001, fixed)
`timescale 1ns/1ps

module tb_knn;


  reg clk, rst, start;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100MHz
  end


  reg        nl_we;
  reg  [6:0] nl_waddr;
  reg  [5:0] nl_wdata;

  wire       out_we;
  wire [5:0] out_addr;
  wire signed [15:0] out_fx, out_fy, out_fz;
  wire       done;


  md_kernel dut (
    .clk(clk), .rst(rst), .start(start),
    .nl_we(nl_we), .nl_waddr(nl_waddr), .nl_wdata(nl_wdata),
    .out_we(out_we), .out_addr(out_addr), .out_fx(out_fx), .out_fy(out_fy), .out_fz(out_fz),
    .done(done)
  );


  reg [5:0] nl_shadow [0:127];


  function [5:0] wrap_idx;
    input integer val;
    integer v;
  begin
    v = val % 32;
    if (v < 0) v = v + 32;
    wrap_idx = v[5:0];
  end
  endfunction

  function integer wrap_min_image;
    input integer d; 
  begin
    if (d >  16) wrap_min_image = d - 32;
    else if (d < -16) wrap_min_image = d + 32; 
    else wrap_min_image = d;
  end
  endfunction

  function [3:0] compute_mask; // bit0->|dx|=1, bit1->2, bit2->4, bit3->8
    integer i, j;
    integer d, ad;
    integer c1, c2, c4, c8;
    reg [3:0] m;
  begin
    m = 4'd0;
    for (i=0; i<32; i=i+1) begin
      c1=0; c2=0; c4=0; c8=0;
      for (j=0; j<4; j=j+1) begin
        d  = wrap_min_image( $signed({1'b0, nl_shadow[i*4+j]}) - i );
        ad = (d<0) ? -d : d;
        if      (ad==1) c1 = c1 + ((d>0)? +1 : -1);
        else if (ad==2) c2 = c2 + ((d>0)? +1 : -1);
        else if (ad==4) c4 = c4 + ((d>0)? +1 : -1);
        else if (ad==8) c8 = c8 + ((d>0)? +1 : -1);
      end
      if (c1!=0) m[0] = 1'b1;
      if (c2!=0) m[1] = 1'b1;
      if (c4!=0) m[2] = 1'b1;
      if (c8!=0) m[3] = 1'b1;
    end
    compute_mask = m;
  end
  endfunction


  task write_NL_with_offsets;
    input integer o0, o1, o2, o3;
    integer i;
    reg [5:0] jidx;
  begin
    for (i=0; i<32; i=i+1) begin
      jidx = wrap_idx(i + o0); write_one(i,0,jidx);
      jidx = wrap_idx(i + o1); write_one(i,1,jidx);
      jidx = wrap_idx(i + o2); write_one(i,2,jidx);
      jidx = wrap_idx(i + o3); write_one(i,3,jidx);
    end
  end
  endtask

  task write_one;
    input integer i;
    input integer w; // 0..3
    input [5:0] jidx;
  begin
    @(posedge clk);
    nl_we    <= 1'b1;
    nl_waddr <= (i*4 + w);
    nl_wdata <= jidx;
    nl_shadow[i*4+w] <= jidx;
    @(posedge clk);
    nl_we    <= 1'b0;
  end
  endtask


  task run_once_and_collect;
    output reg any_nz;
    integer cnt_out;
  begin
    any_nz  = 1'b0;
    cnt_out = 0;

    @(posedge clk); start <= 1'b1;
    @(posedge clk); start <= 1'b0;

    wait_loop: begin
      forever begin
        @(posedge clk);
        if (out_we) begin
          cnt_out = cnt_out + 1;
          if (out_fx != 16'sd0 || out_fy != 16'sd0 || out_fz != 16'sd0)
            any_nz = 1'b1;
        end
        if (done) disable wait_loop;
      end
    end
  end
  endtask


  reg [3:0] golden_mask   [0:5];
  reg       golden_anynz  [0:5];
  reg [3:0] actual_mask;
  reg       actual_anynz;
  reg       global_pass;

  initial begin
    rst   = 1'b1;
    start = 1'b0;
    nl_we = 1'b0;
    nl_waddr = 7'd0;
    nl_wdata = 6'd0;
    #50;
    @(posedge clk);
    rst <= 1'b0;

    // Golden
    golden_mask[0]  = 4'd0;  golden_anynz[0] = 1'b0;
    golden_mask[1]  = 4'd1;  golden_anynz[1] = 1'b1;
    golden_mask[2]  = 4'd2;  golden_anynz[2] = 1'b1;
    golden_mask[3]  = 4'd3;  golden_anynz[3] = 1'b1;
    golden_mask[4]  = 4'd8;  golden_anynz[4] = 1'b0; 
    golden_mask[5]  = 4'd10; golden_anynz[5] = 1'b1;

    global_pass = 1'b1;

    // T1
    write_NL_with_offsets(+1,-1,+2,-2);
    actual_mask  = compute_mask();
    run_once_and_collect(actual_anynz);
    $display("LOCAL_CHECK1: %s, Input: BALANCED_[+1,-1,+2,-2], ActualMask: %0d, GoldenMask: %0d, AnyNonZeroForces: %0d, GoldenAny: %0d",
             ((actual_mask==golden_mask[0]) && (actual_anynz==golden_anynz[0])) ? "PASS":"FAIL",
             actual_mask, golden_mask[0], actual_anynz, golden_anynz[0]);
    if (!((actual_mask==golden_mask[0]) && (actual_anynz==golden_anynz[0]))) global_pass = 1'b0;

    // T2
    write_NL_with_offsets(+1,+1,+2,-2);
    actual_mask  = compute_mask();
    run_once_and_collect(actual_anynz);
    $display("LOCAL_CHECK2: %s, Input: IMBALANCE_ONLY_1_[+1,+1,+2,-2], ActualMask: %0d, GoldenMask: %0d, AnyNonZeroForces: %0d, GoldenAny: %0d",
             ((actual_mask==golden_mask[1]) && (actual_anynz==golden_anynz[1])) ? "PASS":"FAIL",
             actual_mask, golden_mask[1], actual_anynz, golden_anynz[1]);
    if (!((actual_mask==golden_mask[1]) && (actual_anynz==golden_anynz[1]))) global_pass = 1'b0;

    // T3
    write_NL_with_offsets(+1,-1,+2,+2);
    actual_mask  = compute_mask();
    run_once_and_collect(actual_anynz);
    $display("LOCAL_CHECK3: %s, Input: IMBALANCE_ONLY_2_[+1,-1,+2,+2], ActualMask: %0d, GoldenMask: %0d, AnyNonZeroForces: %0d, GoldenAny: %0d",
             ((actual_mask==golden_mask[2]) && (actual_anynz==golden_anynz[2])) ? "PASS":"FAIL",
             actual_mask, golden_mask[2], actual_anynz, golden_anynz[2]);
    if (!((actual_mask==golden_mask[2]) && (actual_anynz==golden_anynz[2]))) global_pass = 1'b0;

    // T4
    write_NL_with_offsets(+1,+1,+2,+2);
    actual_mask  = compute_mask();
    run_once_and_collect(actual_anynz);
    $display("LOCAL_CHECK4: %s, Input: IMBALANCE_1_AND_2_[+1,+1,+2,+2], ActualMask: %0d, GoldenMask: %0d, AnyNonZeroForces: %0d, GoldenAny: %0d",
             ((actual_mask==golden_mask[3]) && (actual_anynz==golden_anynz[3])) ? "PASS":"FAIL",
             actual_mask, golden_mask[3], actual_anynz, golden_anynz[3]);
    if (!((actual_mask==golden_mask[3]) && (actual_anynz==golden_anynz[3]))) global_pass = 1'b0;

    // T5
    write_NL_with_offsets(+8,+8,+8,+8);
    actual_mask  = compute_mask();
    run_once_and_collect(actual_anynz);
    $display("LOCAL_CHECK5: %s, Input: IMBALANCE_ONLY_8_[+8,+8,+8,+8], ActualMask: %0d, GoldenMask: %0d, AnyNonZeroForces: %0d, GoldenAny: %0d",
             ((actual_mask==golden_mask[4]) && (actual_anynz==golden_anynz[4])) ? "PASS":"FAIL",
             actual_mask, golden_mask[4], actual_anynz, golden_anynz[4]);
    if (!((actual_mask==golden_mask[4]) && (actual_anynz==golden_anynz[4]))) global_pass = 1'b0;

    // T6
    write_NL_with_offsets(+2,+2,+8,+8);
    actual_mask  = compute_mask();
    run_once_and_collect(actual_anynz);
    $display("LOCAL_CHECK6: %s, Input: IMBALANCE_2_AND_8_[+2,+2,+8,+8], ActualMask: %0d, GoldenMask: %0d, AnyNonZeroForces: %0d, GoldenAny: %0d",
             ((actual_mask==golden_mask[5]) && (actual_anynz==golden_anynz[5])) ? "PASS":"FAIL",
             actual_mask, golden_mask[5], actual_anynz, golden_anynz[5]);
    if (!((actual_mask==golden_mask[5]) && (actual_anynz==golden_anynz[5]))) global_pass = 1'b0;

    if (global_pass)
      $display("\nGLOBAL_CHECK: PASS");
    else
      $display("\nGLOBAL_CHECK: FAIL");

    $finish;
  end

endmodule
