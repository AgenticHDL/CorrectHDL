`timescale 1ns/1ps

module tb_spam;

  reg         clk;
  reg         rst_n;
  reg         start;
  reg  [15:0] feature_in;
  reg         feature_valid;
  reg   [7:0] label_in;
  reg         label_valid;
  wire        sample_req;
  wire        done;
  reg   [5:0] theta_rd_idx;
  wire [15:0] theta_rd_data;


  reg signed [31:0] GOLD_DEC1 [0:31];
  reg signed [31:0] GOLD_DEC2 [0:31];
  reg signed [31:0] GOLD_DEC3 [0:31];
  reg signed [31:0] GOLD_DEC4 [0:31];
  reg signed [31:0] GOLD_DEC5 [0:31];
  integer gi;


  sgd_lr_int dut (
    .clk(clk), .rst_n(rst_n), .start(start),
    .feature_in(feature_in), .feature_valid(feature_valid),
    .label_in(label_in), .label_valid(label_valid),
    .sample_req(sample_req), .done(done),
    .theta_rd_idx(theta_rd_idx), .theta_rd_data(theta_rd_data)
  );


  initial clk = 1'b0;
  always #5 clk = ~clk; // 100MHz




  function [15:0] to_q6_10;
    input integer v;
    reg   signed [31:0] t;
    begin
      t = v <<< 10;
      to_q6_10 = t[15:0];
    end
  endfunction



  function [31:0] q6_10_to_int_trunc0;
    input signed [15:0] a;
    reg   signed [31:0] tmp;
    begin
      tmp = $signed(a) >>> 10;  
      q6_10_to_int_trunc0 = tmp[31:0];
    end
  endfunction


  // FNV-1a 64-bit
  function [63:0] fnv1a64_update;
    input [63:0] h;
    input [31:0] v;
    reg   [63:0]  hx;
    reg   [127:0] mul;
    begin
      hx  = h ^ {32'b0, v};
      mul = hx * 64'd1099511628211;
      fnv1a64_update = mul[63:0];
    end
  endfunction


  function integer data_val;
    input integer t, n, j;
    input integer s_in;
    integer v;
    begin
      if (t==0) v = 0;
      else if (t==1) v = (j % 8) - 3;
      else if (t==2) v = ((n + j) & 3) - 1;
      else if (t==3) v = s_in; // LCG 传入
      else v = (n % 5) - (j % 3);
      data_val = v;
    end
  endfunction

  function integer label_val;
    input integer t, n, j, s_in;
    integer v;
    begin
      if (t==0) v = 0;
      else if (t==1) v = (n % 2);
      else if (t==2) v = ((n + j) & 1);
      else if (t==3) v = ((s_in >> 1) & 1);
      else v = ((n % 3) == 0) ? 1 : 0;
      label_val = v;
    end
  endfunction

  // LCG（case 3）
  function [31:0] lcg_next;
    input [31:0] s;
    begin
      lcg_next = 32'd1664525 * s + 32'd1013904223;
    end
  endfunction


  task drive_dataset;
    input integer t;
    integer n, j;
    integer v_int;
    reg [31:0] s;      
    integer lbl;
    begin : DRIVE
      feature_in    <= 16'd0;
      feature_valid <= 1'b0;
      label_in      <= 8'd0;
      label_valid   <= 1'b0;

      n = 0;
      s = 32'd1234567;  
      @(posedge clk);

      while (done == 1'b0) begin

        while ((sample_req == 1'b0) && (done == 1'b0)) @(posedge clk);
        if (done == 1'b1) disable DRIVE;


        for (j=0; j<32; j=j+1) begin
          if (t == 3) begin
            s = lcg_next(s);
            v_int = $signed(((s >> 28) & 32'hF)) - 8;  // [-8,7]
          end else begin
            v_int = data_val(t, n, j, 0);
          end
          feature_in    <= to_q6_10(v_int);
          feature_valid <= 1'b1;
          @(posedge clk);
        end
        feature_valid <= 1'b0;


        if (t == 2)      lbl = (n & 1);                
        else if (t == 3) lbl = (s >> 1) & 1;           
        else              lbl = label_val(t, n, 0, 0);

        label_in    <= lbl[7:0];
        label_valid <= 1'b1;
        @(posedge clk);
        label_valid <= 1'b0;


        if (n == 39) begin
          n = 0;
          if (t == 3) s = 32'd1234567;  
        end else begin
          n = n + 1;
        end
      end
    end
  endtask



  function [63:0] compute_input_digest;
    input integer t;
    integer n, j, v_int;
    reg [63:0] h;
    reg [31:0] s_data; 
    reg [31:0] s_lab;  
    integer lbl;
    begin
      h = 64'd1469598103934665603;


      if (t == 3) s_data = 32'd1234567;
      for (n = 0; n < 40; n = n + 1) begin
        for (j = 0; j < 32; j = j + 1) begin
          if (t == 3) begin
            s_data = lcg_next(s_data);
            v_int  = $signed(((s_data >> 28) & 32'hF)) - 8;
          end else begin
            v_int  = data_val(t, n, j, 0);
          end
          h = fnv1a64_update(h, v_int[31:0]);
        end
      end


      if (t == 3) s_lab = 32'd1234567;
      for (n = 0; n < 40; n = n + 1) begin
        if (t == 0) begin
          lbl = 0;
        end else if (t == 1) begin
          lbl = (n % 2);
        end else if (t == 2) begin
          // C++ label[n] = (n + j) & 1; 
          lbl = (n & 1);
        end else if (t == 3) begin

          for (j = 0; j < 32; j = j + 1) s_lab = lcg_next(s_lab);
          lbl = (s_lab >> 1) & 1;
        end else begin // t==4
          lbl = ((n % 3) == 0) ? 1 : 0;
        end
        h = fnv1a64_update(h, lbl[31:0]);
      end

      compute_input_digest = h;
    end
  endfunction



  task compute_theta_digest;
    output [63:0] h_out;
    integer i;
    reg [63:0] h;
    reg [31:0] vi;
    begin
      h = 64'd1469598103934665603;
      for (i=0; i<32; i=i+1) begin
        theta_rd_idx = i[5:0];
        @(posedge clk);
        vi = q6_10_to_int_trunc0(theta_rd_data);
        h  = fnv1a64_update(h, vi);
      end
      h_out = h;
    end
  endtask




  reg [63:0] GOLD_IN [0:4];
  reg [63:0] GOLD_TH [0:4];
  initial begin
    GOLD_IN[0] = 64'h27787c5d972cbf63;
    GOLD_IN[1] = 64'h9e4e56600879fc33;
    GOLD_IN[2] = 64'h0b351a6e9dc1d833;
    GOLD_IN[3] = 64'h07efe9d05f6db934;
    GOLD_IN[4] = 64'h249eb44a82138811;

    GOLD_TH[0] = 64'h171bb79dc8e18503;
    GOLD_TH[1] = 64'h28ce274ab83dbe83;
    GOLD_TH[2] = 64'hae98b8fde1727083;
    GOLD_TH[3] = 64'hae54b54469d73c1c;
    GOLD_TH[4] = 64'hc825eac2538976d9;
  end


  initial begin
    // 1
    for (gi=0;gi<32;gi=gi+1) GOLD_DEC1[gi]=0;

    // 2
    GOLD_DEC2[ 0]=-2; GOLD_DEC2[ 1]=-1; GOLD_DEC2[ 2]=-1; GOLD_DEC2[ 3]=0;
    GOLD_DEC2[ 4]= 0; GOLD_DEC2[ 5]= 1; GOLD_DEC2[ 6]= 1; GOLD_DEC2[ 7]=2;
    GOLD_DEC2[ 8]=-2; GOLD_DEC2[ 9]=-1; GOLD_DEC2[10]=-1; GOLD_DEC2[11]=0;
    GOLD_DEC2[12]= 0; GOLD_DEC2[13]= 1; GOLD_DEC2[14]= 1; GOLD_DEC2[15]=2;
    GOLD_DEC2[16]=-2; GOLD_DEC2[17]=-1; GOLD_DEC2[18]=-1; GOLD_DEC2[19]=0;
    GOLD_DEC2[20]= 0; GOLD_DEC2[21]= 1; GOLD_DEC2[22]= 1; GOLD_DEC2[23]=2;
    GOLD_DEC2[24]=-2; GOLD_DEC2[25]=-1; GOLD_DEC2[26]=-1; GOLD_DEC2[27]=0;
    GOLD_DEC2[28]= 0; GOLD_DEC2[29]= 1; GOLD_DEC2[30]= 1; GOLD_DEC2[31]=2;

    // 3
    GOLD_DEC3[ 0]=26; GOLD_DEC3[ 1]=-30; GOLD_DEC3[ 2]=26; GOLD_DEC3[ 3]=-24;
    GOLD_DEC3[ 4]=26; GOLD_DEC3[ 5]=-30; GOLD_DEC3[ 6]=26; GOLD_DEC3[ 7]=-24;
    GOLD_DEC3[ 8]=26; GOLD_DEC3[ 9]=-30; GOLD_DEC3[10]=26; GOLD_DEC3[11]=-24;
    GOLD_DEC3[12]=26; GOLD_DEC3[13]=-30; GOLD_DEC3[14]=26; GOLD_DEC3[15]=-24;
    GOLD_DEC3[16]=26; GOLD_DEC3[17]=-30; GOLD_DEC3[18]=26; GOLD_DEC3[19]=-24;
    GOLD_DEC3[20]=26; GOLD_DEC3[21]=-30; GOLD_DEC3[22]=26; GOLD_DEC3[23]=-24;
    GOLD_DEC3[24]=26; GOLD_DEC3[25]=-30; GOLD_DEC3[26]=26; GOLD_DEC3[27]=-24;
    GOLD_DEC3[28]=26; GOLD_DEC3[29]=-30; GOLD_DEC3[30]=26; GOLD_DEC3[31]=-24;

    // 4
    GOLD_DEC4[ 0]=18; GOLD_DEC4[ 1]=31; GOLD_DEC4[ 2]= 7; GOLD_DEC4[ 3]= 9;
    GOLD_DEC4[ 4]=11; GOLD_DEC4[ 5]=-1; GOLD_DEC4[ 6]=-15; GOLD_DEC4[ 7]= 9;
    GOLD_DEC4[ 8]=24; GOLD_DEC4[ 9]= 2; GOLD_DEC4[10]= 2; GOLD_DEC4[11]=-12;
    GOLD_DEC4[12]= 0; GOLD_DEC4[13]=20; GOLD_DEC4[14]=17; GOLD_DEC4[15]=30;
    GOLD_DEC4[16]= 2; GOLD_DEC4[17]=22; GOLD_DEC4[18]=-6; GOLD_DEC4[19]=-24;
    GOLD_DEC4[20]=19; GOLD_DEC4[21]= 2; GOLD_DEC4[22]=31; GOLD_DEC4[23]=26;
    GOLD_DEC4[24]=30; GOLD_DEC4[25]=-17; GOLD_DEC4[26]=-12; GOLD_DEC4[27]=-17;
    GOLD_DEC4[28]=-3; GOLD_DEC4[29]=24; GOLD_DEC4[30]=13; GOLD_DEC4[31]=17;

    // 5
    GOLD_DEC5[ 0]=-30; GOLD_DEC5[ 1]=-10; GOLD_DEC5[ 2]=11; GOLD_DEC5[ 3]=-30;
    GOLD_DEC5[ 4]=-10; GOLD_DEC5[ 5]=11; GOLD_DEC5[ 6]=-30; GOLD_DEC5[ 7]=-10;
    GOLD_DEC5[ 8]=11; GOLD_DEC5[ 9]=-30; GOLD_DEC5[10]=-10; GOLD_DEC5[11]=11;
    GOLD_DEC5[12]=-30; GOLD_DEC5[13]=-10; GOLD_DEC5[14]=11; GOLD_DEC5[15]=-30;
    GOLD_DEC5[16]=-10; GOLD_DEC5[17]=11; GOLD_DEC5[18]=-30; GOLD_DEC5[19]=-10;
    GOLD_DEC5[20]=11; GOLD_DEC5[21]=-30; GOLD_DEC5[22]=-10; GOLD_DEC5[23]=11;
    GOLD_DEC5[24]=-30; GOLD_DEC5[25]=-10; GOLD_DEC5[26]=11; GOLD_DEC5[27]=-30;
    GOLD_DEC5[28]=-10; GOLD_DEC5[29]=11; GOLD_DEC5[30]=-30; GOLD_DEC5[31]=-10;
  end


  task print_theta_decimal;
    input integer tcase; // 1..5
    input integer is_act; // 1: ACT, 0: GLD
    reg signed [31:0] tmp [0:31];
    integer i;
    begin
      if (is_act==1) begin
        for (i=0;i<32;i=i+1) begin
          theta_rd_idx = i[5:0];
          @(posedge clk);
          tmp[i] = q6_10_to_int_trunc0(theta_rd_data);
        end
        $write("# THETA_DECIMAL%0d_ACT: [", tcase);
      end else begin
        for (i=0;i<32;i=i+1) begin
          if (tcase==1) tmp[i]=GOLD_DEC1[i];
          else if (tcase==2) tmp[i]=GOLD_DEC2[i];
          else if (tcase==3) tmp[i]=GOLD_DEC3[i];
          else if (tcase==4) tmp[i]=GOLD_DEC4[i];
          else               tmp[i]=GOLD_DEC5[i];
        end
        $write("# THETA_DECIMAL%0d_GLD: [", tcase);
      end
      for (i=0;i<32;i=i+1) begin
        $write("%0d", tmp[i]);
        if (i!=31) $write(", ");
      end
      $write("]\n");
    end
  endtask


  integer tcase;
  reg [63:0] in_h, th_h;
  integer fdesc;
  reg global_pass, local_pass;

  initial begin
    fdesc = $fopen("result.txt","w");
    global_pass = 1;

    for (tcase=0; tcase<5; tcase=tcase+1) begin

      rst_n = 0; start = 0; feature_in = 16'd0; feature_valid = 0; label_in = 0; label_valid = 0; theta_rd_idx = 0;
      repeat(5) @(posedge clk);
      rst_n = 1;
      repeat(2) @(posedge clk);


      in_h = compute_input_digest(tcase);


      start = 1; @(posedge clk); start = 0;
      drive_dataset(tcase);


      compute_theta_digest(th_h);


      local_pass = ( (in_h == GOLD_IN[tcase]) && (th_h == GOLD_TH[tcase]) );
      if (!local_pass) global_pass = 0;


      $display("# LOCAL_CHECK%0d: %s, Input: %016h, Actual Output: %016h, Golden Output: %016h",
               tcase+1, local_pass ? "PASS" : "FAIL", in_h, th_h, GOLD_TH[tcase]);
      if (fdesc)
        $fdisplay(fdesc, "LOCAL_CHECK%0d: %s, Input: %016h, Actual Output: %016h, Golden Output: %016h",
                  tcase+1, local_pass ? "PASS" : "FAIL", in_h, th_h, GOLD_TH[tcase]);

      print_theta_decimal(tcase+1, 1); // ACT
      print_theta_decimal(tcase+1, 0); // GLD
    end

    $display("# Results saved to result.txt");
    if (fdesc) $fclose(fdesc);
    $finish;
  end

endmodule
