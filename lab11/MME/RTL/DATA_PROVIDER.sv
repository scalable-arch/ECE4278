module DATA_PROVIDER
#(
    parameter AW                = 6,    // address width
    parameter DW                = 32,   // data width
    parameter SIZE              = 4
 )
(
    input   wire                clk,
    input   wire                rst_n,
    input   wire    [7:0]       mat_width_i,
    input   wire                start_i,
    output  wire                done_o,
    // SRAM read interface
    output  wire    [AW-1:0]    sram_addr_o,
    input   wire    [DW*SIZE-1:0] sram_data_i,
    output  signed  [DW-1:0]    a_o[SIZE]
);

    //-------------------------------------------------------------
    // Waveform
    //--------------------------------------------------------------
    // clk      : __--__--__--__--__--__--__--__--__--__--__--__--__
    // start    : ___----___________________________________________
    // addr     :   0   | 1 | 2 | 3 | 4 | 5 | 6 | 7 
    // data     :     D0    |D1 |D2 |D3 |D4 |D5 |D6 | D7
    // a_o[0]   :     D0    |D1 |D2 |D3 |D4 |D5 |D6 | D7   
    // a_o[1]   :       D0      |D1 |D2 |D3 |D4 |D5 |D6 | D7   
    // a_o[2]   :         D0        |D1 |D2 |D3 |D4 |D5 |D6 | D7   
    // a_o[3]   :           D0          |D1 |D2 |D3 |D4 |D5 |D6 | D7   

    //----------------------------------------------------------
    // Control logic
    //----------------------------------------------------------
    enum reg {S_IDLE, S_BUSY}   state,  state_n;
    // +1 bit for additional cycles
    reg     [AW:0]              addr,   addr_n;
    reg                         complete;

    always_comb begin
        state_n                 = state;
        addr_n                  = addr;

        complete                = (addr==mat_width_i+SIZE-'d1);

        if (state==S_IDLE) begin
            if (start_i) begin
                state_n                 = S_BUSY;
                addr_n                  = 'd1;
            end
        end
        else begin  // S_BUSY
            if (complete) begin
                state_n                 = S_IDLE;
                addr_n                  = 'd0;
            end
            else begin
                addr_n                  = addr+'d1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state                   <= S_IDLE;
            addr                    <= 'd0;
        end
        else begin
            state                   <= state_n;
            addr                    <= addr_n;
        end
    end

    // shift registers to provide aligned data
    reg     [DW*SIZE-1:0] sram_data_reg[SIZE-1];
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i=0; i<(SIZE-1); i++) begin
                sram_data_reg[i]        <= 'd0;
            end
        end
        else begin
            sram_data_reg[0]        <= sram_data_i;
            for (int i=1; i<(SIZE-1); i++) begin
                sram_data_reg[i]        <= sram_data_reg[i-1];
            end
        end
    end

    reg     signed  [DW-1:0]    a[SIZE];

    always_comb begin
        a[0]                = sram_data_i[DW*(SIZE-1)+:DW];
        for (int i=1; i<SIZE; i++) begin
            a[i]                = sram_data_reg[i-1][DW*(SIZE-1-i)+:DW];
        end
    end

    // output assignments
    assign  sram_addr_o             = addr[AW-1:0];
    assign  done_o                  = (state==S_IDLE);
    assign  a_o                     = a;

endmodule
