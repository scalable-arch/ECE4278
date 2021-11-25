// Copyright (c) 2021 Sungkyunkwan University
//
// Authors:
// - Jungrae Kim <dale40@skku.edu>

module DMAC_ARBITER
#(
    N_MASTER                    = 4,
    DATA_SIZE                   = 32
)
(
    input   wire                clk,
    input   wire                rst_n,  // _n means active low

    // configuration registers
    input   wire                src_valid_i[N_MASTER],
    output  reg                 src_ready_o[N_MASTER],
    input   wire    [DATA_SIZE-1:0]     src_data_i[N_MASTER],

    output  reg                 dst_valid_o,
    input   wire                dst_ready_i,
    output  reg     [DATA_SIZE-1:0] dst_data_o
);

    reg                         dst_valid,  dst_valid_n;
    reg     [DATA_SIZE-1:0]     dst_data,   dst_data_n;

    always_ff @(posedge clk)
        if (~rst_n) begin
            dst_valid               <= 1'b0;
            dst_data                <= 'd0;
        end
        else begin
            dst_valid               <= dst_valid_n;
            dst_data                <= dst_data_n;
        end

    // fixed priority arbiter
    always_comb begin
        dst_valid_n             = dst_valid;
        dst_data_n              = dst_data;
        for (int i=0; i<N_MASTER; i++) begin
            src_ready_o[i]          = 1'b0;
        end

        if (!dst_valid | dst_ready_i) begin
            if (src_valid_i[0]) begin
                dst_valid_n             = 1'b1;
                dst_data_n              = src_data_i[0];
                src_ready_o[0]          = 1'b1;
            end
            else if (src_valid_i[1]) begin
                dst_valid_n             = 1'b1;
                dst_data_n              = src_data_i[1];
                src_ready_o[1]          = 1'b1;
            end
            else if (src_valid_i[2]) begin
                dst_valid_n             = 1'b1;
                dst_data_n              = src_data_i[2];
                src_ready_o[2]          = 1'b1;
            end
            else if (src_valid_i[3]) begin
                dst_valid_n             = 1'b1;
                dst_data_n              = src_data_i[3];
                src_ready_o[3]          = 1'b1;
            end
            else begin
                dst_valid_n             = 1'b0;
            end
        end
    end

    assign  dst_valid_o             = dst_valid;
    assign  dst_data_o              = dst_data;

endmodule
