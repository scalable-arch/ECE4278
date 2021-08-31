module DMAC_TOP_TB ();

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

    // enable waveform dump
    initial begin
        $dumpvars(0, u_DUT);
        $dumpfile("dump.vcd");
    end

    APB                         apb_if  (.clk(clk));

    AXI_AW_CH                   aw_ch   (.clk(clk));
    AXI_W_CH                    w_ch    (.clk(clk));
    AXI_B_CH                    b_ch    (.clk(clk));
    AXI_AR_CH                   ar_ch   (.clk(clk));
    AXI_R_CH                    r_ch    (.clk(clk));

    initial begin
        int data;
        apb_if.init();

        @(posedge rst_n);                   // wait for a release of the reset
        repeat (10) @(posedge clk);         // wait another 10 cycles

        apb_if.read(32'h0, data);
        $display("---------------------------------------------------");
        $display("IP version: %x", data);
        $display("---------------------------------------------------");

        $display("---------------------------------------------------");
        $display("Reset value test");
        $display("---------------------------------------------------");
        apb_if.read(32'h100, data);
        if (data===0)
            $display("DMA_SRC(pass): %x", data);
        else begin
            $display("DMA_SRC(fail): %x", data);
            @(posedge clk);
            $finish;
        end
        apb_if.read(32'h104, data);
        if (data===0)
            $display("DMA_DST(pass): %x", data);
        else begin
            $display("DMA_DST(fail): %x", data);
            @(posedge clk);
            $finish;
        end
        apb_if.read(32'h108, data);
        if (data===0)
            $display("DMA_LEN(pass): %x", data);
        else begin
            $display("DMA_LEN(fail): %x", data);
            @(posedge clk);
            $finish;
        end
        apb_if.read(32'h110, data);
        if (data===1)
            $display("DMA_STATUS(pass): %x", data);
        else begin
            $display("DMA_STATUS(fail): %x", data);
            @(posedge clk);
            $finish;
        end

        apb_if.write(32'h100, 32'h1000);
        apb_if.write(32'h104, 32'h2000);
        apb_if.write(32'h108, 32'h100);
        apb_if.write(32'h10c, 32'h1);

        data = 0;
        while (data==0) begin
            apb_if.read(32'h110, data);
            repeat (100) @(posedge clk);
        end
        @(posedge clk);

        $display("DMA completed");
        $finish;
    end


    AXI_SLAVE   u_mem (
        .clk                    (clk),
        .rst_n                  (rst_n),
        
        .aw_ch                  (aw_ch),
        .w_ch                   (w_ch),
        .b_ch                   (b_ch),
        .ar_ch                  (ar_ch),
        .r_ch                   (r_ch)
    );

    DMAC_TOP  u_DUT (
        .clk                    (clk),
        .rst_n                  (rst_n),

        // APB interface
        .psel_i                 (apb_if.psel),
        .penable_i              (apb_if.penable),
        .paddr_i                (apb_if.paddr[11:0]),
        .pwrite_i               (apb_if.pwrite),
        .pwdata_i               (apb_if.pwdata),
        .pready_o               (apb_if.pready),
        .prdata_o               (apb_if.prdata),
        .pslverr_o              (apb_if.pslverr),

        // AXI AW channel
        .awid_o                 (aw_ch.awid),
        .awaddr_o               (aw_ch.awaddr),
        .awlen_o                (aw_ch.awlen),
        .awsize_o               (aw_ch.awsize),
        .awburst_o              (aw_ch.awburst),
        .awvalid_o              (aw_ch.awvalid),
        .awready_i              (aw_ch.awready),

        // AXI W channel
        .wid_o                  (w_ch.wid),
        .wdata_o                (w_ch.wdata),
        .wstrb_o                (w_ch.wstrb),
        .wlast_o                (w_ch.wlast),
        .wvalid_o               (w_ch.wvalid),
        .wready_i               (w_ch.wready),

        // AXI B channel
        .bid_i                  (b_ch.bid),
        .bresp_i                (b_ch.bresp),
        .bvalid_i               (b_ch.bvalid),
        .bready_o               (b_ch.bready),

        // AXI AR channel
        .arid_o                 (ar_ch.arid),
        .araddr_o               (ar_ch.araddr),
        .arlen_o                (ar_ch.arlen),
        .arsize_o               (ar_ch.arsize),
        .arburst_o              (ar_ch.arburst),
        .arvalid_o              (ar_ch.arvalid),
        .arready_i              (ar_ch.arready),

        // AXI R channel
        .rid_i                  (r_ch.rid),
        .rdata_i                (r_ch.rdata),
        .rresp_i                (r_ch.rresp),
        .rlast_i                (r_ch.rlast),
        .rvalid_i               (r_ch.rvalid),
        .rready_o               (r_ch.rready)
    );

endmodule
