`timescale 1ns/1ps

module tb_viterbi;
  reg clk;
  reg rst_n;

  // DUT ports
  reg        obs_we;
  reg  [4:0] obs_addr;
  reg  [7:0] obs_din;

  reg        start;
  wire       busy;
  wire       done;

  reg  [4:0] path_addr;
  wire [7:0] path_dout;

  // DUT instance
  viterbi_core dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .obs_we    (obs_we),
    .obs_addr  (obs_addr),
    .obs_din   (obs_din),
    .start     (start),
    .busy      (busy),
    .done      (done),
    .path_addr (path_addr),
    .path_dout (path_dout)
  );

  // clock
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // ---------------- Globals / arrays ----------------
  integer i;
  integer fout;
  integer global_pass;
  integer pass1, pass2, pass3, pass4, pass5;

  reg [7:0] obs1   [0:31];
  reg [7:0] obs2   [0:31];
  reg [7:0] obs3   [0:31];
  reg [7:0] obs4   [0:31];
  reg [7:0] obs5   [0:31];

  reg [7:0] golden1[0:31];
  reg [7:0] golden2[0:31];
  reg [7:0] golden3[0:31];
  reg [7:0] golden4[0:31];
  reg [7:0] golden5[0:31];

  reg [7:0] actual [0:31];

  // ---------------- Tasks / functions (no array args) ----------------
  task load_obs_case;
    input integer cid;
    integer k;
    begin
      for (k=0;k<32;k=k+1) begin
        @(posedge clk);
        obs_we   <= 1'b1;
        obs_addr <= k[4:0];
        case (cid)
          1: obs_din <= obs1[k];
          2: obs_din <= obs2[k];
          3: obs_din <= obs3[k];
          4: obs_din <= obs4[k];
          default: obs_din <= obs5[k];
        endcase
      end
      @(posedge clk);
      obs_we <= 1'b0;
    end
  endtask

  task run_once; // uses global 'actual'
    integer k;
    begin
      @(posedge clk); start <= 1'b1;
      @(posedge clk); start <= 1'b0;
      // wait done
      while (done==1'b0) @(posedge clk);
      // read back path
      for (k=0;k<32;k=k+1) begin
        path_addr <= k[4:0];
        @(posedge clk);
        actual[k] = path_dout;
      end
    end
  endtask

  function integer cmp_with_golden_case;
    input integer cid;
    integer k;
    begin
      cmp_with_golden_case = 1;
      for (k=0;k<32;k=k+1) begin
        case (cid)
          1: if (actual[k] !== golden1[k]) cmp_with_golden_case = 0;
          2: if (actual[k] !== golden2[k]) cmp_with_golden_case = 0;
          3: if (actual[k] !== golden3[k]) cmp_with_golden_case = 0;
          4: if (actual[k] !== golden4[k]) cmp_with_golden_case = 0;
          default: if (actual[k] !== golden5[k]) cmp_with_golden_case = 0;
        endcase
      end
    end
  endfunction

  task print_array_obs;
    input integer cid;
    integer k;
    begin
      for (k=0;k<32;k=k+1) begin
        if (k!=0) $write(" ");
        case (cid)
          1: $write("%0d", obs1[k]);
          2: $write("%0d", obs2[k]);
          3: $write("%0d", obs3[k]);
          4: $write("%0d", obs4[k]);
          default: $write("%0d", obs5[k]);
        endcase
      end
    end
  endtask

  task fprint_array_obs;
    input integer cid;
    integer k;
    begin
      for (k=0;k<32;k=k+1) begin
        if (k!=0) $fwrite(fout," ");
        case (cid)
          1: $fwrite(fout,"%0d", obs1[k]);
          2: $fwrite(fout,"%0d", obs2[k]);
          3: $fwrite(fout,"%0d", obs3[k]);
          4: $fwrite(fout,"%0d", obs4[k]);
          default: $fwrite(fout,"%0d", obs5[k]);
        endcase
      end
    end
  endtask

  task print_array_actual;
    integer k;
    begin
      for (k=0;k<32;k=k+1) begin
        if (k!=0) $write(" ");
        $write("%0d", actual[k]);
      end
    end
  endtask

  task fprint_array_actual;
    integer k;
    begin
      for (k=0;k<32;k=k+1) begin
        if (k!=0) $fwrite(fout," ");
        $fwrite(fout,"%0d", actual[k]);
      end
    end
  endtask

  task print_array_golden;
    input integer cid;
    integer k;
    begin
      for (k=0;k<32;k=k+1) begin
        if (k!=0) $write(" ");
        case (cid)
          1: $write("%0d", golden1[k]);
          2: $write("%0d", golden2[k]);
          3: $write("%0d", golden3[k]);
          4: $write("%0d", golden4[k]);
          default: $write("%0d", golden5[k]);
        endcase
      end
    end
  endtask

  task fprint_array_golden;
    input integer cid;
    integer k;
    begin
      for (k=0;k<32;k=k+1) begin
        if (k!=0) $fwrite(fout," ");
        case (cid)
          1: $fwrite(fout,"%0d", golden1[k]);
          2: $fwrite(fout,"%0d", golden2[k]);
          3: $fwrite(fout,"%0d", golden3[k]);
          4: $fwrite(fout,"%0d", golden4[k]);
          default: $fwrite(fout,"%0d", golden5[k]);
        endcase
      end
    end
  endtask

  // ---------------- Build vectors & run ----------------
  initial begin
    // default
    obs_we    = 1'b0;
    obs_addr  = 5'd0;
    obs_din   = 8'd0;
    start     = 1'b0;
    path_addr = 5'd0;

    // reset
    rst_n = 1'b0;
    repeat(4) @(posedge clk);
    rst_n = 1'b1;

    // vectors per your message
    // 1) RAMP_MODN
    for (i=0;i<16;i=i+1) begin
      obs1[i]       = i[7:0];
      obs1[i+16]    = i[7:0];
      golden1[i]    = i[7:0];
      golden1[i+16] = i[7:0];
    end
    // 2) ALT_7_13_WRAPPED
    for (i=0;i<32;i=i+1) begin
      obs2[i]     = (i[0]==1'b0) ? 8'd7 : 8'd13;
      golden2[i]  = 8'd7;
    end
    // 3) BLOCKS_WRAPPED
    for (i=0;i<10;i=i+1) begin obs3[i]=8'd0;  golden3[i]=8'd0; end
    for (i=10;i<20;i=i+1) begin obs3[i]=8'd9; golden3[i]=8'd9; end
    for (i=20;i<30;i=i+1) begin obs3[i]=8'd2; golden3[i]=8'd2; end
    obs3[30]=8'd11; obs3[31]=8'd11; golden3[30]=8'd2; golden3[31]=8'd2;

    // 4) SAW_SMALL_WRAPPED
    for (i=0;i<16;i=i+1) begin
      obs4[i]       = i[7:0];
      obs4[i+16]    = i[7:0];
      golden4[i]    = i[7:0];
      golden4[i+16] = i[7:0];
    end

    // 5) PATTERN_MIX_WRAPPED
    obs5[ 0]=8'd0;  obs5[ 1]=8'd5;  obs5[ 2]=8'd10; obs5[ 3]=8'd15;
    obs5[ 4]=8'd4;  obs5[ 5]=8'd9;  obs5[ 6]=8'd14; obs5[ 7]=8'd3;
    obs5[ 8]=8'd9;  obs5[ 9]=8'd14; obs5[10]=8'd3;  obs5[11]=8'd8;
    obs5[12]=8'd13; obs5[13]=8'd2;  obs5[14]=8'd7;  obs5[15]=8'd12;
    obs5[16]=8'd2;  obs5[17]=8'd7;  obs5[18]=8'd12; obs5[19]=8'd1;
    obs5[20]=8'd6;  obs5[21]=8'd11; obs5[22]=8'd0;  obs5[23]=8'd5;
    obs5[24]=8'd11; obs5[25]=8'd0;  obs5[26]=8'd5;  obs5[27]=8'd10;
    obs5[28]=8'd15; obs5[29]=8'd4;  obs5[30]=8'd9;  obs5[31]=8'd14;

    golden5[ 0]=8'd10; golden5[ 1]=8'd10; golden5[ 2]=8'd10; golden5[ 3]=8'd9;
    golden5[ 4]=8'd9;  golden5[ 5]=8'd9;  golden5[ 6]=8'd9;  golden5[ 7]=8'd9;
    golden5[ 8]=8'd9;  golden5[ 9]=8'd8;  golden5[10]=8'd8;  golden5[11]=8'd8;
    golden5[12]=8'd7;  golden5[13]=8'd7;  golden5[14]=8'd7;  golden5[15]=8'd7;
    golden5[16]=8'd7;  golden5[17]=8'd7;  golden5[18]=8'd6;  golden5[19]=8'd6;
    golden5[20]=8'd6;  golden5[21]=8'd5;  golden5[22]=8'd5;  golden5[23]=8'd5;
    golden5[24]=8'd5;  golden5[25]=8'd5;  golden5[26]=8'd5;  golden5[27]=8'd4;
    golden5[28]=8'd4;  golden5[29]=8'd4;  golden5[30]=8'd4;  golden5[31]=8'd4;

    // open result file
    fout = $fopen("result.txt","w");
    if (fout==0) $display("Error: cannot open result.txt");

    global_pass = 1;

    // ---------------- Case 1 ----------------
    load_obs_case(1);
    run_once();
    pass1 = cmp_with_golden_case(1);
    if (!pass1) global_pass = 0;

    $write("# LOCAL_CHECK1 [RAMP_MODN]: %s, Input: ", pass1?"PASS":"FAIL");
    print_array_obs(1);
    $write(", Actual Output: ");
    print_array_actual();
    $write(", Golden Output: ");
    print_array_golden(1);
    $write("\n");

    $fwrite(fout,"LOCAL_CHECK1 [RAMP_MODN]: %s, Input: ", pass1?"PASS":"FAIL");
    fprint_array_obs(1);
    $fwrite(fout,", Actual Output: ");
    fprint_array_actual();
    $fwrite(fout,", Golden Output: ");
    fprint_array_golden(1);
    $fwrite(fout,"\n");

    // ---------------- Case 2 ----------------
    load_obs_case(2);
    run_once();
    pass2 = cmp_with_golden_case(2);
    if (!pass2) global_pass = 0;

    $write("# LOCAL_CHECK2 [ALT_7_13_WRAPPED]: %s, Input: ", pass2?"PASS":"FAIL");
    print_array_obs(2);
    $write(", Actual Output: ");
    print_array_actual();
    $write(", Golden Output: ");
    print_array_golden(2);
    $write("\n");

    $fwrite(fout,"LOCAL_CHECK2 [ALT_7_13_WRAPPED]: %s, Input: ", pass2?"PASS":"FAIL");
    fprint_array_obs(2);
    $fwrite(fout,", Actual Output: ");
    fprint_array_actual();
    $fwrite(fout,", Golden Output: ");
    fprint_array_golden(2);
    $fwrite(fout,"\n");

    // ---------------- Case 3 ----------------
    load_obs_case(3);
    run_once();
    pass3 = cmp_with_golden_case(3);
    if (!pass3) global_pass = 0;

    $write("# LOCAL_CHECK3 [BLOCKS_WRAPPED]: %s, Input: ", pass3?"PASS":"FAIL");
    print_array_obs(3);
    $write(", Actual Output: ");
    print_array_actual();
    $write(", Golden Output: ");
    print_array_golden(3);
    $write("\n");

    $fwrite(fout,"LOCAL_CHECK3 [BLOCKS_WRAPPED]: %s, Input: ", pass3?"PASS":"FAIL");
    fprint_array_obs(3);
    $fwrite(fout,", Actual Output: ");
    fprint_array_actual();
    $fwrite(fout,", Golden Output: ");
    fprint_array_golden(3);
    $fwrite(fout,"\n");

    // ---------------- Case 4 ----------------
    load_obs_case(4);
    run_once();
    pass4 = cmp_with_golden_case(4);
    if (!pass4) global_pass = 0;

    $write("# LOCAL_CHECK4 [SAW_SMALL_WRAPPED]: %s, Input: ", pass4?"PASS":"FAIL");
    print_array_obs(4);
    $write(", Actual Output: ");
    print_array_actual();
    $write(", Golden Output: ");
    print_array_golden(4);
    $write("\n");

    $fwrite(fout,"LOCAL_CHECK4 [SAW_SMALL_WRAPPED]: %s, Input: ", pass4?"PASS":"FAIL");
    fprint_array_obs(4);
    $fwrite(fout,", Actual Output: ");
    fprint_array_actual();
    $fwrite(fout,", Golden Output: ");
    fprint_array_golden(4);
    $fwrite(fout,"\n");

    // ---------------- Case 5 ----------------
    load_obs_case(5);
    run_once();
    pass5 = cmp_with_golden_case(5);
    if (!pass5) global_pass = 0;

    $write("# LOCAL_CHECK5 [PATTERN_MIX_WRAPPED]: %s, Input: ", pass5?"PASS":"FAIL");
    print_array_obs(5);
    $write(", Actual Output: ");
    print_array_actual();
    $write(", Golden Output: ");
    print_array_golden(5);
    $write("\n");

    $fwrite(fout,"LOCAL_CHECK5 [PATTERN_MIX_WRAPPED]: %s, Input: ", pass5?"PASS":"FAIL");
    fprint_array_obs(5);
    $fwrite(fout,", Actual Output: ");
    fprint_array_actual();
    $fwrite(fout,", Golden Output: ");
    fprint_array_golden(5);
    $fwrite(fout,"\n");

    $fwrite(fout,"GLOBAL_CHECK: %s\n", global_pass?"PASS":"FAIL");
    $fclose(fout);
    $display("\nResults saved to result.txt");

    #20 $finish;
  end

endmodule
