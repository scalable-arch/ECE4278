`include "../TB/def.svh"

module DMAC_FIFO_TB;
  bit clk;
  bit rst_n;

  fifo_if inf(clk, rst_n);
  test t1(inf);

  DMAC_FIFO #(
    .DEPTH_LG2  (`DEPTH_LG2),
    .DATA_WIDTH (`DATA_WIDTH)
  ) DUT (
    .clk        (inf.clk),
    .rst_n      (inf.rst_n),

    .full_o     (inf.full),
    .wren_i     (inf.wr_en),
    .wdata_i    (inf.wdata),

    .empty_o    (inf.empty),
    .rden_i     (inf.rd_en),
    .rdata_o    (inf.rdata)
  );

  // clk gen
  initial begin
    clk = 1;
  end
  always #5 clk = ~clk;

  // rst_n
  initial begin
    rst_n = 1;
    repeat(1) @(posedge clk);
    rst_n = 0;
    repeat(3) @(posedge clk);
    rst_n = 1;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule


