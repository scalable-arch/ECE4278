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

    // input interfaces
    input   wire                src_valid_i[N_MASTER],
    output  reg                 src_ready_o[N_MASTER],
    input   wire    [DATA_SIZE-1:0]     src_data_i[N_MASTER],

    // output interface
    output  reg                 dst_valid_o,
    input   wire                dst_ready_i,
    output  reg     [DATA_SIZE-1:0] dst_data_o
);

    enum reg {S_IDLE, S_BUSY}   state,    state_n;
    reg                         dst_valid,  dst_valid_n;
    reg     [DATA_SIZE-1:0]     dst_data,   dst_data_n;

    always_ff @(posedge clk)
        if (~rst_n) begin
            state                   <= S_IDLE;
            dst_valid               <= 1'b0;
            dst_data                <= 'd0;
        end
        else begin
            state                   <= state_n;
            dst_valid               <= dst_valid_n;
            dst_data                <= dst_data_n;
        end

    // fixed priority arbiter
    always_comb begin
        // default
        state_n                 = state;
        dst_valid_n             = dst_valid;
        dst_data_n              = dst_data;
        for (int i=0; i<N_MASTER; i++) begin
            src_ready_o[i]          = 1'b0;
        end

        // there's no valid request
        if (state==S_IDLE) begin
            for (int i=0; i<N_MASTER; i++) begin
                if (src_valid_i[i]) begin
                    state_n                 = S_BUSY;
                    dst_valid_n             = 1'b1;
                    dst_data_n              = src_data_i[i];
                    src_ready_o[i]          = 1'b1;
                    break;
                end
            end
        end
        else // state==I_BUSY
        begin
            if (dst_ready_i) begin
                state_n                 = S_IDLE;
                dst_valid_n             = 1'b0;
                for (int i=0; i<N_MASTER; i++) begin
                    if (src_valid_i[i]) begin
                        dst_valid_n             = 1'b1;
                        dst_data_n              = src_data_i[i];
                        src_ready_o[i]          = 1'b1;
                        state_n                 = S_BUSY;
                        break;
                    end
                end
            end
        end
    end

    assign  dst_valid_o             = dst_valid;
    assign  dst_data_o              = dst_data;

endmodule
