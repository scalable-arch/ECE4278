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
    localparam N_MASTER_LG2     = $clog2(N_MASTER);

    reg     [N_MASTER_LG2-1:0]  rotate_ptr;
    reg                         shift_valid[N_MASTER];
    reg     [DATA_SIZE-1:0]     shift_data[N_MASTER];
    reg                         shift_ready[N_MASTER];

    always_ff @(posedge clk)
        if (~rst_n) begin
            rotate_ptr          <= 'd0;
        end
        else begin
            if (src_valid_i[0] & src_ready_o[0]) begin
                rotate_ptr          <= 2'd1;
            end
            else if (src_valid_i[1] & src_ready_o[1]) begin
                rotate_ptr          <= 2'd2;
            end
            else if (src_valid_i[2] & src_ready_o[2]) begin
                rotate_ptr          <= 2'd3;
            end
            else if (src_valid_i[3] & src_ready_o[3]) begin
                rotate_ptr          <= 2'd0;
            end
        end

    always_comb begin
        case (rotate_ptr)
            'd0: begin
                shift_valid         = {src_valid_i[3], src_valid_i[2], src_valid_i[1], src_valid_i[0]};
                shift_data          = {src_data_i[3], src_data_i[2], src_data_i[1], src_data_i[0]};
                src_ready_o         = {shift_ready[3], shift_ready[2], shift_ready[1], shift_ready[0]};
            end
            'd1: begin
                shift_valid         = {src_valid_i[0], src_valid_i[3], src_valid_i[2], src_valid_i[1]};
                shift_data          = {src_data_i[0], src_data_i[3], src_data_i[2], src_data_i[1]};
                src_ready_o         = {shift_ready[0], shift_ready[3], shift_ready[2], shift_ready[1]};
            end
            'd2: begin
                shift_valid         = {src_valid_i[1], src_valid_i[0], src_valid_i[3], src_valid_i[2]};
                shift_data          = {src_data_i[1], src_data_i[0], src_data_i[3], src_data_i[2]};
                src_ready_o         = {shift_ready[1], shift_ready[0], shift_ready[3], shift_ready[2]};
            end
            'd3: begin
                shift_valid         = {src_valid_i[2], src_valid_i[1], src_valid_i[0], src_valid_i[3]};
                shift_data          = {src_data_i[2], src_data_i[1], src_data_i[0], src_data_i[3]};
                src_ready_o         = {shift_ready[2], shift_ready[1], shift_ready[0], shift_ready[3]};
            end
        endcase
    end

    // fixed priority arbiter
    always_comb begin
        // default
        dst_valid_o             = 1'b0;
        dst_data_o              = shift_data[3];    // don't care
        for (int i=0; i<N_MASTER; i++) begin
            shift_ready[i]          = 1'b0;
        end

        for (int i=0; i<N_MASTER; i++) begin
            if (shift_valid[i]) begin
                dst_valid_o             = 1'b1;
                dst_data_o              = shift_data[i];
                shift_ready[i]          = dst_ready_i;
                break;
            end
        end
    end

endmodule
