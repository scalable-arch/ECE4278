`define     OFFSET_IP_VER       32'h000
`define     OFFSET_MAT_CFG      32'h100
`define     OFFSET_MAT_A_ADDR   32'h200
`define     OFFSET_MAT_B_ADDR   32'h204
`define     OFFSET_MAT_C_ADDR   32'h208
`define     OFFSET_MME_CMD      32'h20C
`define     OFFSET_MME_STATUS   32'h210

`define 	TIMEOUT_DELAY 	99999999

`define     SRC_REGION_START    32'h0000_0000
`define     SRC_REGION_SIZE     32'h0000_2000
`define     DST_REGION_STRIDE   32'h0000_2000

`define     MAT_WIDTH           4

module MME_TOP_TB ();

    //----------------------------------------------------------
    // clock and reset generation
    //----------------------------------------------------------
    reg                     clk;
    reg                     rst_n;

    // clock generation
    initial begin
        clk                     = 1'b0;

        forever #10 clk         = !clk;
    end

    // reset generation
    initial begin
        rst_n                   = 1'b0;     // active at time 0

        repeat (3) @(posedge clk);          // after 3 cycles,
        rst_n                   = 1'b1;     // release the reset
    end

	// timeout
	initial begin
		#`TIMEOUT_DELAY $display("Timeout!");
		$finish;
	end

    // enable waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, u_DUT);
    end

    //----------------------------------------------------------
    // Connection between DUT and test modules
    //----------------------------------------------------------
    APB                         apb_if  (.clk(clk));

    AXI_AW_CH                   aw_ch   (.clk(clk));
    AXI_W_CH                    w_ch    (.clk(clk));
    AXI_B_CH                    b_ch    (.clk(clk));
    AXI_AR_CH                   ar_ch   (.clk(clk));
    AXI_R_CH                    r_ch    (.clk(clk));

    MME_TOP  u_DUT (
        .clk                    (clk),
        .rst_n                  (rst_n),

        // APB interface
        .apb_if                 (apb_if),

        // AXI interface
        .axi_aw_if              (aw_ch),
        .axi_w_if               (w_ch),
        .axi_b_if               (b_ch),
        .axi_ar_if              (ar_ch),
        .axi_r_if               (r_ch)
    );

    AXI_SLAVE   u_mem (
        .clk                    (clk),
        .rst_n                  (rst_n),

        .aw_ch                  (aw_ch),
        .w_ch                   (w_ch),
        .b_ch                   (b_ch),
        .ar_ch                  (ar_ch),
        .r_ch                   (r_ch)
    );

    logic   signed [31:0]       mat_a[4][`MAT_WIDTH];
    logic   signed [31:0]       mat_b[`MAT_WIDTH][4];

    //----------------------------------------------------------
    // Testbench starts
    //----------------------------------------------------------
    task automatic apb_write_n_verify(int addr, int wdata);
        int rdata;

        apb_if.write(addr, wdata);
        apb_if.read(addr, rdata);
        if (rdata!==wdata) begin
            $display("APB write failure @0x%x : Write data = %x, Read-back data = %x", addr, wdata, rdata);
            @(posedge clk);
            $finish;
        end
    endtask

    task init();
        int data;
        apb_if.init();

        @(posedge rst_n);                   // wait for a release of the reset
        repeat (10) @(posedge clk);         // wait another 10 cycles

        apb_if.read(`OFFSET_IP_VER, data);
        $display("---------------------------------------------------");
        $display("IP version: %x", data);
        $display("---------------------------------------------------");
    endtask

    // this task must be declared automatic so that each invocation uses
    // different memories
    task automatic test_mme(int mat_width, int mat_a_addr, int mat_b_addr, int mat_c_addr);
        int data;
        logic signed [64:0] expected_c[4][4];

        $display("---------------------------------------------------");
        $display("Matrix multiplication: A(@0x%x) x B(@0x%x) = C(@0x%x)", mat_a_addr, mat_b_addr, mat_c_addr);
        $display("Matrix sizes         : (4 x %d) x (%d x 4) = (4 x 4)", mat_width, mat_width);
        $display("---------------------------------------------------");

        $display("---------------------------------------------------");
        $display("Load matrix A and B to memory");
        $display("---------------------------------------------------");

        for (int i=0; i<4; i++) begin
            for (int j=0; j<mat_width; j++) begin
                // row-major layout
                //   A[0][0] - A[0][1] - A[0][2] - A[0][3]
                // - A[1][0] - A[1][1] - A[1][2] - A[1][3]
                // ...
                //u_mem.write_word(mat_a_addr+(i*mat_width+j)*4, mat_a[i][j]);
                u_mem.write_word(mat_a_addr+(i+j*mat_width)*4, mat_a[i][j]);
            end
        end

        for (int j=0; j<4; j++) begin
            for (int i=0; i<mat_width; i++) begin
                // column-major layout
                //   A[0][0] - A[1][0] - A[2][0] - A[3][0] - ...
                // - A[0][1] - A[1][1] - A[2][1] - A[3][1] - ...
                //u_mem.write_word(mat_b_addr+(i+j*mat_width)*4, mat_b[i][j]);
                u_mem.write_word(mat_b_addr+(i*mat_width+j)*4, mat_b[i][j]);
            end
        end

        $display("---------------------------------------------------");
        $display("Configure");
        $display("---------------------------------------------------");
        apb_write_n_verify(`OFFSET_MAT_CFG, mat_width);
        apb_write_n_verify(`OFFSET_MAT_A_ADDR, mat_a_addr);
        apb_write_n_verify(`OFFSET_MAT_B_ADDR, mat_b_addr);
        apb_write_n_verify(`OFFSET_MAT_C_ADDR, mat_c_addr);

        $display("---------------------------------------------------");
        $display("MM start");
        $display("---------------------------------------------------");
        apb_if.write(`OFFSET_MME_CMD, 32'h1);

        data = 0;
        while (data!=1) begin
            apb_if.read(`OFFSET_MME_STATUS, data);
            repeat (100) @(posedge clk);
            $display("Waiting for a MM completion");
        end
        @(posedge clk);
        $display("---------------------------------------------------");
        $display("MM completed");
        $display("---------------------------------------------------");

        $display("---------------------------------------------------");
        $display("Verify result");
        $display("---------------------------------------------------");
        for (int i=0; i<mat_width; i++) begin
            for (int j=0; j<mat_width; j++) begin
                expected_c[i][j]                = 'd0;
                for(int k=0; k<4; k++) begin
                    expected_c[i][j]                += (mat_a[i][k] * mat_b[k][j]);
                end
            end
        end

        for (int i=0; i<4; i++) begin
            for (int j=0; j<4; j++) begin
                data = u_mem.read_word(mat_c_addr+(i*4+j)*4);
                if (data!==expected_c[i][j][31:0]) begin
                    $display("Output mismatch at (%x, %d): expected=%x, real=%x", i, j, expected_c[i][j], data);
                    @(posedge clk);
                    $finish;
                end
                else begin
                    $display("Output match at (%d, %d)", i, j);
                end
            end
        end

        $display("---------------------------------------------------");
        $display("MM passed");
        $display("---------------------------------------------------");
    endtask

    // main
    initial begin
        init();

        // initialize data
        for (int i=0; i<`MAT_WIDTH; i++) begin
            for (int j=0; j<4; j++) begin
                //mat_a[i][j]                 = 32'h1;
                //mat_b[j][i]                 = 32'h1;
                mat_a[i][j]                 = i*'h10+j;
                mat_b[j][i]                 = i*'h100+j;
                //mat_a[i][j]                 = $urandom()%256;
                //mat_b[j][i]                 = $urandom()%256;
            end
        end

        test_mme(`MAT_WIDTH, 32'h0, 32'h1000, 32'h2000);

        $finish;
    end

endmodule
