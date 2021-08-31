`include "../TB/AXI_TYPEDEF.svh"

module AXI_SLAVE
#(
    parameter ADDR_WIDTH        = `AXI_ADDR_WIDTH,
    parameter DATA_WIDTH        = `AXI_DATA_WIDTH,
    parameter ID_WIDTH          = `AXI_ID_WIDTH,
    parameter AWREADY_DELAY     = 1,
    parameter ARREADY_DELAY     = 1,
)
(
    input   wire                clk,
    input   wire                rst_n,  // _n means active low

    AXI_AW_CH                   aw_ch,
    AXI_W_CH                    w_ch,
    AXI_B_CH                    b_ch,
    AXI_AR_CH                   ar_ch,
    AXI_R_CH                    r_ch
);

    assign  aw_ch.awready       = 1'b1;
    assign  w_ch.wready         = 1'b1;
    assign  b_ch.bvalid         = 1'b1;
    assign  ar_ch.arready       = 1'b1;
    assign  r_ch.rvalid         = 1'b1;

    //localparam  DATA_DEPTH      = 1<<ADDR_WIDTH;

    logic   [7:0]               mem[DATA_DEPTH];

endmodule
