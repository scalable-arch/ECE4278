`include "../TB/def.svh"

interface fifo_if(input logic clk, rst_n);
  logic rd_en;
  logic wr_en;
  logic [`DATA_WIDTH-1:0]wdata;
  logic [`DATA_WIDTH-1:0]rdata;
  logic full, empty;


  clocking driver_cb @(posedge clk);
//    default input #1 output #1;
    output wdata;
    output rd_en;
    output wr_en;
    input full;
    input empty;
    input rdata;
  endclocking


  clocking monitor_cb @(posedge clk);
//    default input #1 output #1;
    input rd_en;
    input wr_en;
    input wdata;
    input rdata;
    input full, empty;
  endclocking

  modport DRIVER (clocking driver_cb, input clk, rst_n);
  modport MONITOR (clocking monitor_cb, input clk, rst_n);

endinterface

