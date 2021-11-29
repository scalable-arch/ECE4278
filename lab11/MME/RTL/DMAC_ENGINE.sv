// Copyright (c) 2021 Sungkyunkwan University
//
// Authors:
// - Jungrae Kim <dale40@skku.edu>

module DMAC_ENGINE
#(
    parameter DW                = 32,   // data size
    parameter SA_WIDTH          = 4,    // systolic array width in PE count
    parameter BUF_AW            = 6,    // buffer address width
    parameter BUF_DW            = 128   // buffer data width
 )
(
    input   wire                clk,
    input   wire                rst_n,  // _n means active low

    // configuration registers
    input   wire    [31:0]      mat_a_addr_i,
    input   wire    [31:0]      mat_b_addr_i,
    input   wire    [31:0]      mat_c_addr_i,
    input   wire    [7:0]       mat_width_i,
    input   wire                start_i,
    output  wire                done_o,

    // AMBA AXI interface
    AXI_AW_CH.master            axi_aw_if,
    AXI_W_CH.master             axi_w_if,
    AXI_B_CH.slave              axi_b_if,
    AXI_AR_CH.master            axi_ar_if,
    AXI_R_CH.slave              axi_r_if,

    // buffer interface
    output  reg                 buf_a_wren_o,
    output  wire   [BUF_AW-1:0] buf_a_waddr_o,
    output  reg    [BUF_DW/8-1:0] buf_a_wbyteenable_o,
    output  wire   [BUF_DW-1:0] buf_a_wdata_o,
    output  reg                 buf_b_wren_o,
    output  wire   [BUF_AW-1:0] buf_b_waddr_o,
    output  reg    [BUF_DW/8-1:0] buf_b_wbyteenable_o,
    output  wire   [BUF_DW-1:0] buf_b_wdata_o,

    // other module start
    output  reg                 dp_start_o,
    output  reg                 sa_start_o,

    input   wire                sa_done_i,
    input   signed [2*DW:0]     accum_i[SA_WIDTH][SA_WIDTH]
);

    //----------------------------------------------------------
    // AR channel control
    //----------------------------------------------------------
    enum    logic [1:0]     { S_AR_IDLE, S_AR_REQA, S_AR_REQB }
                                ar_state,   ar_state_n;

    always_comb begin
        ar_state_n                  = ar_state;

        axi_ar_if.arvalid           = 1'b0;
        axi_ar_if.araddr            = mat_a_addr_i;
        axi_ar_if.arid              = 'd0;
        axi_ar_if.arlen             = 4'hF;     // 16 burst
        axi_ar_if.arsize            = 3'b010;   // 4 bytes per transfer
        axi_ar_if.arburst           = 2'b01;    // incremental

        case (ar_state)
            S_AR_IDLE: begin
                if (start_i) begin
                    ar_state_n                  = S_AR_REQA;
                end
            end
            S_AR_REQA: begin
                axi_ar_if.arvalid           = 1'b1;
                axi_ar_if.araddr            = mat_a_addr_i;
                if (axi_ar_if.arready) begin
                    ar_state_n                  = S_AR_REQB;
                end
            end
            S_AR_REQB: begin
                axi_ar_if.arvalid           = 1'b1;
                axi_ar_if.araddr            = mat_b_addr_i;
                if (axi_ar_if.arready) begin
                    ar_state_n                  = S_AR_IDLE;
                end
            end
        endcase
    end

    always_ff @(posedge clk)
        if (!rst_n) begin
            ar_state                    <= S_AR_IDLE;
        end
        else begin
            ar_state                    <= ar_state_n;
        end

    //----------------------------------------------------------
    // R channel control
    //----------------------------------------------------------
    enum    logic [1:0]     { S_R_REQA, S_R_REQB, S_R_DP, S_R_SA }
                                r_state,    r_state_n;
    reg     [BUF_AW+1:0]        rcnt,       rcnt_n;                                

    always_comb begin
        r_state_n                   = r_state;
        rcnt_n                      = rcnt;

        axi_r_if.rready             = 1'b0;
        buf_a_wren_o                = 1'b0;
        buf_b_wren_o                = 1'b0;
        dp_start_o                  = 1'b0;
        sa_start_o                  = 1'b0;

        case (r_state)
            S_R_REQA: begin
                axi_r_if.rready             = 1'b1;
                if (axi_r_if.rvalid) begin
                    buf_a_wren_o                = 1'b1;
                    if (axi_r_if.rlast) begin
                        r_state_n                   = S_R_REQB;
                        rcnt_n                      = 'd0;
                    end
                    else begin
                        rcnt_n                      = rcnt + 'd1;
                    end
                end
            end
            S_R_REQB: begin
                axi_r_if.rready             = 1'b1;
                if (axi_r_if.rvalid) begin
                    buf_b_wren_o                = 1'b1;
                    if (axi_r_if.rlast) begin
                        r_state_n                   = S_R_DP;
                        rcnt_n                      = 'd0;
                    end
                    else begin
                        rcnt_n                      = rcnt + 'd1;
                    end
                end
            end
            S_R_DP: begin
                dp_start_o                  = 1'b1;
                r_state_n                   = S_R_SA;
            end
            S_R_SA: begin
                sa_start_o                  = 1'b1;
                r_state_n                   = S_R_REQA;
            end
        endcase
    end

    always_ff @(posedge clk)
        if (!rst_n) begin
            r_state                     <= S_R_REQA;
            rcnt                        <= 'd0;
        end
        else begin
            r_state                     <= r_state_n;
            rcnt                        <= rcnt_n;
        end

    assign  buf_a_waddr_o           = rcnt>>2;
    assign  buf_a_wbyteenable_o     = (rcnt[1:0]=='d0) ? {{{DW/8}{1'b1}}, {{DW/8}{1'b0}}, {{DW/8}{1'b0}}, {{DW/8}{1'b0}}} :
                                      (rcnt[1:0]=='d1) ? {{{DW/8}{1'b0}}, {{DW/8}{1'b1}}, {{DW/8}{1'b0}}, {{DW/8}{1'b0}}} :
                                      (rcnt[1:0]=='d2) ? {{{DW/8}{1'b0}}, {{DW/8}{1'b0}}, {{DW/8}{1'b1}}, {{DW/8}{1'b0}}} :
                                                         {{{DW/8}{1'b0}}, {{DW/8}{1'b0}}, {{DW/8}{1'b0}}, {{DW/8}{1'b1}}};
    assign  buf_b_waddr_o           = buf_a_waddr_o;
    assign  buf_b_wbyteenable_o     = buf_a_wbyteenable_o;

    //----------------------------------------------------------
    // AW/W/B channel control
    //----------------------------------------------------------
    enum    logic [2:0]     { S_W_IDLE, S_W_SA_WAIT, S_W_REQ, S_W_DATA, S_W_RSP }
                                w_state,    w_state_n;
    reg     [3:0]               wcnt,       wcnt_n;                                

    always_comb begin
        w_state_n                   = w_state;
        wcnt_n                      = wcnt;

        axi_aw_if.awvalid           = 1'b0;
        axi_w_if.wvalid             = 1'b0;
        axi_b_if.bready             = 1'b0;

        case (w_state)
            S_W_IDLE: begin
                if (sa_start_o) begin
                    w_state_n                   = S_W_SA_WAIT;
                end
            end
            S_W_SA_WAIT: begin
                if (sa_done_i) begin
                    w_state_n                   = S_W_SA_WAIT;
                end
            end
            S_W_REQ: begin
                axi_aw_if.awvalid           = 1'b0;
                if (axi_aw_if.awready) begin
                    w_state_n                   = S_W_DATA;
                    wcnt_n                      = 'd0;
                end
            end
            S_W_DATA: begin
                axi_w_if.wvalid             = 1'b0;
                axi_w_if.wlast              = (wcnt=='hF);
                axi_w_if.wdata              = accum_i[wcnt/4][wcnt%4][31:0];
                if (axi_w_if.wready) begin
                    wcnt_n                      = wcnt + 'd1;
                    if (axi_w_if.wlast) begin
                        w_state_n                   = S_W_RSP;
                    end
                end
            end
            S_W_RSP: begin
                axi_b_if.bready             = 1'b1;
                if (axi_b_if.bvalid) begin
                    w_state_n                   = S_W_IDLE;
                end
            end
        endcase
    end

    always_ff @(posedge clk)
        if (!rst_n) begin
            w_state                     <= S_W_IDLE;
            wcnt                        <= 'd0;
        end
        else begin
            w_state                     <= w_state_n;
            wcnt                        <= wcnt_n;
        end

/*
    // Output assigments
    assign  done_o                  = done;

    assign  awaddr_o                = dst_addr;
    assign  awlen_o                 = (cnt >= 'd64) ? 4'hF: cnt[5:2]-4'h1;
    assign  awsize_o                = 3'b010;   // 4 bytes per transfer
    assign  awburst_o               = 2'b01;    // incremental
    assign  awvalid_o               = awvalid;

    assign  wdata_o                 = fifo_rdata;
    assign  wstrb_o                 = 4'b1111;  // all bytes within 4 byte are valid
    assign  wlast_o                 = wlast;
    assign  wvalid_o                = wvalid;

    assign  bready_o                = 1'b1;

    assign  araddr_o                = src_addr;
    assign  arlen_o                 = (cnt >= 'd64) ? 4'hF: cnt[5:2]-4'h1;
    assign  arsize_o                = 3'b010;   // 4 bytes per transfer
    assign  arburst_o               = 2'b01;    // incremental
    assign  arvalid_o               = arvalid;

    assign  rready_o                = rready & !fifo_full;
*/

endmodule
