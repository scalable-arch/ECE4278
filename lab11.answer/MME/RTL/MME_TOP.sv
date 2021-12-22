// Copyright (c) 2021 Sungkyunkwan University
//
// Authors:
// - Jungrae Kim <dale40@skku.edu>

module MME_TOP
#(
    parameter DW                = 32,   // data width (element size)
    parameter SA_WIDTH          = 4,    // systolic array width in PE count
    parameter BUF_AW            = 6,    // buffer address width
    // Systolic array width in PE count
    parameter BUF_DW            = DW*SA_WIDTH    // 128

 )
(
    input   wire                clk,
    input   wire                rst_n,  // _n means active low

    // AMBA APB interface
    APB.slave                   apb_if,

    // AMBA AXI interface
    AXI_AW_CH.master            axi_aw_if,
    AXI_W_CH.master             axi_w_if,
    AXI_B_CH.slave              axi_b_if,
    AXI_AR_CH.master            axi_ar_if,
    AXI_R_CH.slave              axi_r_if
);

    // interface between CFG <-> other blocks
    wire    [31:0]              mat_a_addr,     mat_b_addr,     mat_c_addr;
    wire    [7:0]               mat_width;
    wire                        engine_start,   engine_done;

    // DMA engine <-> SRAM buffers
    wire                        buf_a_wren;
    wire    [BUF_AW-1:0]        buf_a_waddr,    buf_a_raddr;
    wire    [BUF_DW/8-1:0]      buf_a_wbyteenable, buf_b_wbyteenable;
    wire    [BUF_DW-1:0]        buf_a_wdata,    buf_a_rdata;
    wire                        buf_b_wren;
    wire    [BUF_AW-1:0]        buf_b_waddr,    buf_b_raddr;
    wire    [BUF_DW-1:0]        buf_b_wdata,    buf_b_rdata;

    // DMA engine <-> MM engine
    wire                        mm_start;
    wire                        mm_done;
    wire    signed [2*DW:0]     accum[SA_WIDTH][SA_WIDTH];

    MME_CFG                     u_cfg
    (
        .PCLK                   (clk),
        .RESET                  (rst_n),
        .PSEL                   (apb_if.psel),
        .PENABLE                (apb_if.penable),
        .PADDR                  (apb_if.paddr[9:0]),
        .PWRITE                 (apb_if.pwrite),
        .PWDATA                 (apb_if.pwdata),
        .PRDATA                 (apb_if.prdata),
        .PREADY                 (apb_if.pready),

        .MAT_CFG_mat_width      (mat_width),
        .MAT_A_ADDR_start_addr  (mat_a_addr),
        .MAT_B_ADDR_start_addr  (mat_b_addr),
        .MAT_C_ADDR_start_addr  (mat_c_addr),
        .MME_CMD_start          (engine_start),
        .MME_STATUS_done        (engine_done)
    );
    assign  apb_if.pslverr      = 1'b0;

    DMA_ENGINE
    #(
        .DW                     (DW),
        .SA_WIDTH               (SA_WIDTH),
        .BUF_AW                 (BUF_AW),
        .BUF_DW                 (BUF_DW)
     )
    u_dma
    (
        .clk                    (clk),
        .rst_n                  (rst_n),

        // configuration interface
        .mat_a_addr_i           (mat_a_addr),
        .mat_b_addr_i           (mat_b_addr),
        .mat_c_addr_i           (mat_c_addr),
        .mat_width_i            (mat_width),
        .start_i                (engine_start),
        .done_o                 (engine_done),
        
        // AXI interface
        .axi_aw_if              (axi_aw_if),
        .axi_w_if               (axi_w_if),
        .axi_b_if               (axi_b_if),
        .axi_ar_if              (axi_ar_if),
        .axi_r_if               (axi_r_if),

        // buffer interface
        .buf_a_wren_o           (buf_a_wren),
        .buf_a_waddr_o          (buf_a_waddr),
        .buf_a_wbyteenable_o    (buf_a_wbyteenable),
        .buf_a_wdata_o          (buf_a_wdata),
        .buf_b_wren_o           (buf_b_wren),
        .buf_b_waddr_o          (buf_b_waddr),
        .buf_b_wbyteenable_o    (buf_b_wbyteenable),
        .buf_b_wdata_o          (buf_b_wdata),

        // other module start interface
        .mm_start_o             (mm_start),
        .mm_done_i              (mm_done),
        .accum_i                (accum)
    );

    DUAL_PORT_SRAM
    #(
        .AW                     (BUF_AW),
        .DW                     (BUF_DW)
     )
    u_buf_a
    (
        .clk                    (clk),
        .wren_i                 (buf_a_wren),
        .waddr_i                (buf_a_waddr),
        .wbyteenable_i          (buf_a_wbyteenable),
        .wdata_i                (buf_a_wdata),
        .raddr_i                (buf_a_raddr),
        .rdata_o                (buf_a_rdata)
    );

    DUAL_PORT_SRAM
    #(
        .AW                     (BUF_AW),
        .DW                     (BUF_DW)
     )
    u_buf_b
    (
        .clk                    (clk),
        .wren_i                 (buf_b_wren),
        .waddr_i                (buf_b_waddr),
        .wbyteenable_i          (buf_b_wbyteenable),
        .wdata_i                (buf_b_wdata),
        .raddr_i                (buf_b_raddr),
        .rdata_o                (buf_b_rdata)
    );

    MM_ENGINE
    #(
        .DW                     (DW),
        .SA_WIDTH               (SA_WIDTH),
        .BUF_AW                 (BUF_AW),
        .BUF_DW                 (BUF_DW)
    )
    u_mm
    (
        .clk                    (clk),
        .rst_n                  (rst_n),

        .mat_width_i            (mat_width),
        .start_i                (mm_start),
        .done_o                 (mm_done),

        .buf_a_raddr_o          (buf_a_raddr),
        .buf_a_rdata_i          (buf_a_rdata),
        .buf_b_raddr_o          (buf_b_raddr),
        .buf_b_rdata_i          (buf_b_rdata),

        .accum_o                (accum)
    );

endmodule
