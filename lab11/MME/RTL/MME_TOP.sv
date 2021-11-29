// Copyright (c) 2021 Sungkyunkwan University
//
// Authors:
// - Jungrae Kim <dale40@skku.edu>

module MME_TOP
#(
    parameter AW                = 6,
    parameter DW                = 32,   // data width
    parameter SA_SIZE           = 4     // systolic array width in PE count
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

    // Systolic array width in PE count
    localparam                  SA_WIDTH    = 4;
    localparam                  BUF_AW      = 6;
    localparam                  BUF_DW      = DW*SA_WIDTH;   // 128

    wire    [31:0]              mat_a_addr,     mat_b_addr,     mat_c_addr;
    wire    [7:0]               mat_width;
    wire                        engine_start,   engine_done;

    wire    signed [DW-1:0]     a[SA_WIDTH];
    wire    signed [DW-1:0]     b[SA_WIDTH];
    wire    signed [2*DW:0]     accum[SA_WIDTH][SA_WIDTH];

    wire                        buf_a_wren;
    wire    [BUF_AW-1:0]        buf_a_waddr,    buf_a_raddr;
    wire    [BUF_DW/8-1:0]      buf_a_wbyteenable, buf_b_wbyteenable;
    wire    [BUF_DW-1:0]        buf_a_wdata,    buf_a_rdata;
    wire                        buf_b_wren;
    wire    [BUF_AW-1:0]        buf_b_waddr,    buf_b_raddr;
    wire    [BUF_DW-1:0]        buf_b_wdata,    buf_b_rdata;

    wire                        dp_start;
    wire                        sa_start;
    wire                        sa_done;

    assign                      mat_a_addr      = 32'h0000_0000;
    assign                      mat_b_addr      = 32'h0000_1000;
    assign                      mat_c_addr      = 32'h0000_2000;
    assign                      mat_width       = 8'h32;

    DMAC_ENGINE
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
        .dp_start_o             (dp_start),
        .sa_start_o             (sa_start),

        .sa_done_i              (sa_done),
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

    DATA_PROVIDER
    #(
        .AW                     (BUF_AW),
        .DW                     (DW),
        .SIZE                   (SA_WIDTH)
    )
    u_provider_a
    (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .mat_width_i            (mat_width),
        .start_i                (dp_start),
        .done_o                 (/* FLOATING */),
        .sram_addr_o            (buf_a_raddr),
        .sram_data_i            (buf_a_rdata),
        .a_o                    (a)
    );

    DATA_PROVIDER
    #(
        .AW                     (BUF_AW),
        .DW                     (DW),
        .SIZE                   (SA_WIDTH)
    )
    u_provider_b
    (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .mat_width_i            (mat_width),
        .start_i                (dp_start),
        .done_o                 (/* FLOATING */),
        .sram_addr_o            (buf_b_raddr),
        .sram_data_i            (buf_b_rdata),
        .a_o                    (b)
    );

    SYSTOLIC_ARRAY
    #(
        .DW                     (DW),
        .SIZE                   (SA_WIDTH)
     ) u_sa
    (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .mat_width_i            (mat_width),
        .start_i                (sa_start),
        .done_o                 (sa_done),
        .a_i                    (a),
        .b_i                    (b),
        .accum_o                (accum)
    );


endmodule
