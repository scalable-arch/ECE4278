`define DRIV_IF vif_ff.DRIVER.driver_cb
class driver;

  virtual fifo_if vif_ff;

  mailbox gen2driv;

  int no_of_transactions;

  function new (virtual fifo_if vif_ff,mailbox gen2driv);
    this.vif_ff = vif_ff;
    this.gen2driv = gen2driv;
  endfunction

  task reset();
    wait(!vif_ff.rst_n);
    $display("entered into reset phase");
    `DRIV_IF.wr_en <= 0;
    `DRIV_IF.rd_en <= 0;
    `DRIV_IF.wdata <= 0;
    wait(vif_ff.rst_n);
    $display("leaving from reset phase");
  endtask

  task main();
    forever begin
      transactor trans;
      gen2driv.get(trans);

      `DRIV_IF.wr_en  <= trans.wr_en;
      `DRIV_IF.wdata  <= trans.wdata;
      `DRIV_IF.rd_en  <= trans.rd_en;
      @(posedge vif_ff.DRIVER.clk);
      no_of_transactions++;
    end

  endtask

endclass



