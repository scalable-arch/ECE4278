module SYSTOLIC_ARRAY
#(
    parameter DW                = 32,   // data width
    parameter SIZE              = 4     // in PE count
 )
(
    input   wire                clk,
    input   wire                rst_n,
    input   wire   [7:0]        mat_width_i,
    input   wire                start_i,
    output  reg                 done_o,
    input   signed [DW-1:0]     a_i[SIZE],
    input   signed [DW-1:0]     b_i[SIZE],
    output  signed [2*DW:0]     accum_o[SIZE][SIZE]
);

    reg     signed [DW-1:0]     a_input[SIZE][SIZE+1];
    reg     signed [DW-1:0]     b_input[SIZE+1][SIZE];
    reg                         clr[SIZE][SIZE];
    reg                         hold[SIZE][SIZE];

    // generate variable
    genvar geni, genj;

    // to ease the timing, latch the inputs before connecting
    // to PEs
    reg     signed [DW-1:0]     a_i_reg[SIZE];
    reg     signed [DW-1:0]     b_i_reg[SIZE];
    always_ff @(posedge clk)
        if (!rst_n) begin
            for (int i=0; i<SIZE; i++) begin
                a_i_reg[i]              <= 'd0;
                b_i_reg[i]              <= 'd0;
            end
        end
        else begin
            for (int i=0; i<SIZE; i++) begin
                a_i_reg[i]              <= a_i[i];
                b_i_reg[i]              <= b_i[i];
            end
        end

    //              b_input[0][0]   b_input[0][1]   b_input[0][2]   b_input[0][3]
    //                      |               |               |               |
    // a_input[0][0]-       PE00            PE01

    // connect the inputs to the 1st stage
    generate
        for (geni=0; geni<SIZE; geni++) begin
            assign  a_input[geni][0]        = a_i_reg[geni];
            assign  b_input[0][geni]        = b_i_reg[geni];
        end
    endgenerate

    // instantiate PE array
    for (geni=0; geni<SIZE; geni++) begin
        for (genj=0; genj<SIZE; genj++) begin : PE_GEN
            PE  #(.DW(DW)) pe (
                .clk                        (clk),
                .rst_n                      (rst_n),
                .clr_i                      (clr[geni][genj]),
                .hold_i                     (hold[geni][genj]),
                .a_i                        (a_input[geni][genj]),
                .b_i                        (b_input[geni][genj]),
                .a_o                        (a_input[geni][genj+1]),
                .b_o                        (b_input[geni+1][genj]),
                .accum_o                    (accum_o[geni][genj])
            );
        end
    end

    //----------------------------------------------------------
    // Control logic
    //----------------------------------------------------------
    enum reg {S_IDLE, S_BUSY}   state,  state_n;
    // counter to generate clr/hold signals
    reg     [8:0]               cnt, cnt_n;
    reg                         complete;

    always_comb begin
        state_n                 = state;
        cnt_n                   = cnt;

        if (state==S_IDLE) begin
            if (start_i) begin
                state_n                 = S_BUSY;
                cnt_n                   = 'd1;
            end
        end
        else begin  // S_BUSY
            if (complete) begin
                state_n                 = S_IDLE;
                cnt_n                   = 'd0;
            end
            else begin
                cnt_n                   = cnt+'d1;
            end
        end
    end

    // clear/hold signal generation
    // same as the below (for SIZE=4)
    //clr[0][0]               = start_i;
    //clr[1][0]               = (cnt=='d1);
    //clr[0][1]               = (cnt=='d1);
    //clr[2][0]               = (cnt=='d2);
    //clr[1][1]               = (cnt=='d2);
    //clr[0][2]               = (cnt=='d2);
    //clr[3][0]               = (cnt=='d3);
    //clr[2][1]               = (cnt=='d3);
    //clr[1][2]               = (cnt=='d3);
    //clr[0][3]               = (cnt=='d3);
    //clr[3][1]               = (cnt=='d4);
    //clr[2][2]               = (cnt=='d4);
    //clr[1][3]               = (cnt=='d4);
    //clr[3][2]               = (cnt=='d5);
    //clr[2][3]               = (cnt=='d5);
    //clr[3][3]               = (cnt=='d6);

    //hold[0][0]              = (cnt>=(mat_width_i+'d1));
    //hold[0][1]              = (cnt>=(mat_width_i+'d2));
    //hold[1][0]              = (cnt>=(mat_width_i+'d2));
    //hold[2][0]              = (cnt>=(mat_width_i+'d3));
    //...
    always_comb begin
        // clear signal generation
        clr[0][0]               = start_i;
        for (int i=0; i<SIZE; i++) begin
            for (int j=0; j<SIZE; j++) begin
                if ((i!=0) | (j!=0)) begin
                    clr[i][j]               = (cnt==(i+j));
                end
            end
        end
        // hold signal generation
        for (int i=0; i<SIZE; i++) begin
            for (int j=0; j<SIZE; j++) begin
                hold[i][j]               = (state==S_IDLE) | (cnt>=(mat_width_i+i+j+1));
            end
        end
        complete                    = (cnt==(mat_width_i+SIZE+SIZE-1));
    end

    always_ff @(posedge clk)
        if (!rst_n) begin
            state                   <= S_IDLE;
            cnt                     <= 'd0;
        end
        else begin
            state                   <= state_n;
            cnt                     <= cnt_n;
        end

    // output assignments
    assign  done_o                  = (state==S_IDLE);

endmodule
