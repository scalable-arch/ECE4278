// Copyright (c) 2021 Sungkyunkwan University
//
// Authors:
// - Jungrae Kim <dale40@skku.edu>

module DMAC_CFG
(
    input   wire                clk,
    input   wire                rst_n,  // _n means active low

    input   wire                wren_i, // write enable
    input   wire                rden_i, // read enable

    input   wire    [31:0]      wdata_i,
    output  reg     [31:0]      rdata_o
);

// Configuration register to read/write
reg [31:0]                        cfg_reg;

// use SRAM-like interface to read/write SFR

//----------------------------------------------------------
// write operation
//----------------------------------------------------------
// clk         : __--__--__--__--__--__--__--
// wren        : ___----____________________
// wdata       :   |dat|
//
// updated reg :       |data
always_ff @(posedge clk) begin  // sync reset
    if (!rst_n) begin
        cfg_reg                 <= 32'd0;
    end
    else if (wren_i) begin
        cfg_reg                 <= wdata_i;
    end
end

//----------------------------------------------------------
// read operation
//----------------------------------------------------------
// clk   : __--__--__--__--__--__--__--
// rden  : ___----____________________
// rdata :       |data
always_ff @(posedge clk) begin  // sync reset
    if (!rst_n) begin
        rdata_o                 <= 32'd0;
    end
    else if (rden_i) begin
        rdata_o                 <= cfg_reg;
    end
end

endmodule
