module DMAC_CFG_TB ();

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
        while (data!==1) begin
            apb_if.read(32'h110, data);
            repeat (100) @(posedge clk);
        end
        @(posedge clk);

        $display("DMA completed");
        $finish;
    end


    DMAC_CFG  u_DUT (
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

        .src_addr_o             (/* FLOATING */),
        .dst_addr_o             (/* FLOATING */),
        .byte_len_o             (/* FLOATING */),
        .start_o                (/* FLOATING */),
        .done_i                 (1'b1)
    );

endmodule
