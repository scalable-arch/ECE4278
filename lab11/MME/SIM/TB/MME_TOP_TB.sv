`define     IP_VER      32'h000
`define     CH_SFR_SIZE 32'h100
`define     SRC_OFFSET  32'h0
`define     DST_OFFSET  32'h4
`define     LEN_OFFSET  32'h8
`define     CMD_OFFSET  32'hc
`define     STAT_OFFSET 32'h10

`define 	TIMEOUT_DELAY 	99999999

`define     SRC_REGION_START    32'h0000_0000
`define     SRC_REGION_SIZE     32'h0000_2000
`define     DST_REGION_STRIDE   32'h0000_2000

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
        $dumpvars(0, u_DUT);
        $dumpfile("dump.vcd");
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

    //----------------------------------------------------------
    // Testbench starts
    //----------------------------------------------------------
    task test_init();
        int data;
        apb_if.init();

        @(posedge rst_n);                   // wait for a release of the reset
        repeat (10) @(posedge clk);         // wait another 10 cycles

        apb_if.read(`IP_VER, data);
        $display("---------------------------------------------------");
        $display("IP version: %x", data);
        $display("---------------------------------------------------");

        $display("---------------------------------------------------");
        $display("Load data to memory");
        $display("---------------------------------------------------");
        for (int i=0; i<`SRC_REGION_SIZE; i=i+4) begin
            // write random data
            u_mem.write_word(`SRC_REGION_START+i, $random);
        end
    endtask

    // this task must be declared automatic so that each invocation uses
    // different memories
    task automatic test_dma(input int ch, input int src, input int dst, input int len);
        int data;
        $display("Ch[%d] DMA configure %x -> %x (%x)", ch, src, dst, len);
        apb_if.write((ch+1)*`CH_SFR_SIZE+`SRC_OFFSET, src);
        apb_if.read((ch+1)*`CH_SFR_SIZE+`SRC_OFFSET, data);
        if (data!==src) begin
            $display("DMA_SRC[%d](fail): %x", ch, data);
            @(posedge clk);
            $finish;
        end
        apb_if.write((ch+1)*`CH_SFR_SIZE+`DST_OFFSET, dst);
        apb_if.read((ch+1)*`CH_SFR_SIZE+`DST_OFFSET, data);
        if (data!==dst) begin
            $display("DMA_DST[%d](fail): %x", ch, data);
            @(posedge clk);
            $finish;
        end
        apb_if.write((ch+1)*`CH_SFR_SIZE+`LEN_OFFSET, len);
        apb_if.read((ch+1)*`CH_SFR_SIZE+`LEN_OFFSET, data);
        if (data!==len) begin
            $display("DMA_LEN[%d](fail): %x", ch, data);
            @(posedge clk);
            $finish;
        end

        $display("Ch[%d] DMA start", ch);
        apb_if.write((ch+1)*`CH_SFR_SIZE+`CMD_OFFSET, 32'h1);

        data = 0;
        while (data!=1) begin
            apb_if.read((ch+1)*`CH_SFR_SIZE+`STAT_OFFSET, data);
            repeat (100) @(posedge clk);
            $display("Ch[%d] Waiting for a DMA completion", ch);
        end
        @(posedge clk);

        $display("Ch[%d] DMA completed", ch);
        for (int i=0; i<len; i=i+4) begin
            logic [31:0]        src_word;
            logic [31:0]        dst_word;
            src_word            = u_mem.read_word(src+i);
            dst_word            = u_mem.read_word(dst+i);
            if (src_word!==dst_word) begin
                $display("Ch[%d] Mismatch! (src:%x @%x, dst:%x @%x", ch, src_word, src+i, dst_word, dst+i);
                @(posedge clk);
                $finish;
            end
        end
        $display("Ch[%d] DMA passed", ch);
    endtask

    // this task must be declared automatic so that each invocation uses
    // different memories
    task automatic test_channel(input int ch, input int test_cnt);
        int         src_offset, dst_offset, len;
        src_offset = 0;
        dst_offset = 0;

        for (int i=0; i<test_cnt; i++) begin
            len = 'h0100;
            test_dma(ch, `SRC_REGION_START+src_offset, (ch+1)*`DST_REGION_STRIDE+dst_offset, len);
            src_offset = src_offset + len;
            dst_offset = dst_offset + len;
        end
    endtask


    // main
    initial begin
        test_init();

        // run 4 channel tests simultaneously
        fork
            test_channel(0, 32);
            test_channel(1, 32);
            test_channel(2, 32);
            test_channel(3, 32);
        join

        $finish;
    end


endmodule
