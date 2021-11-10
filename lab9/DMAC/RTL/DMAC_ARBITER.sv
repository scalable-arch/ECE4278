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
    input   wire                src_last_i[N_MASTER],
    input   wire    [DATA_SIZE-1:0]     src_data_i[N_MASTER],
    output  reg                 src_ready_o[N_MASTER],

    output  reg                 dst_valid_o,
    output  reg                 dst_last_o,
    output  reg     [DATA_SIZE-1:0] dst_data_o,
    input   wire                dst_ready_i
);

    // fixed priority arbiter
    always_comb begin
        dst_valid_o             = 1'b0;
        dst_last_o              = 1'b0;
        dst_data_o              = src_data_i[0];
        for (int i=0; i<N_MASTER; i++) begin
            src_ready_o[i]          = 1'b0;
        end
        if (src_valid_i[0]) begin
            dst_valid_o             = 1'b1;
            dst_last_o              = src_last_i[0];
            dst_data_o              = src_data_i[0];
            src_ready_o[0]          = dst_ready_i;
        end
        else if (src_valid_i[1]) begin
            dst_valid_o             = 1'b1;
            dst_last_o              = src_last_i[1];
            dst_data_o              = src_data_i[1];
            src_ready_o[1]          = dst_ready_i;
        end
        else if (src_valid_i[2]) begin
            dst_valid_o             = 1'b1;
            dst_last_o              = src_last_i[2];
            dst_data_o              = src_data_i[2];
            src_ready_o[2]          = dst_ready_i;
        end
        else if (src_valid_i[3]) begin
            dst_valid_o             = 1'b1;
            dst_last_o              = src_last_i[3];
            dst_data_o              = src_data_i[3];
            src_ready_o[3]          = dst_ready_i;
        end
    end

endmodule
