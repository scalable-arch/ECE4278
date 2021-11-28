module MME_TOP
#(
    parameter DW                = 32,   // data width
    parameter SA_SIZE           = 4     // systolic array width in PE count
 )
(
    input   wire                clk,
    input   wire                rst_n,

    // APB interface
    APB.slave                   apb_if,

    // AXI interface
    AXI_AW_CH.master            axi_aw_if,
    AXI_W_CH,master             axi_w_if,
    AXI_B_CH.slave              axi_b_if,
    AXI_AR_CH.master            axi_ar_if,
    AXI_R_CH.slave              axi_r_if
);

    SYSTOLIC_ARRAY
    #(
        .DW                     (DW),
        .SIZE                   (SA_SIZE)
     ) u_sa
    (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .matrix_width_i         (matrix_width),
        .start_i                (sa_start),
        .done_o                 (sa_done),
        .a_i                    (a),
        .b_i                    (b),
        .accum_o                (accum)
    );

endmodule
