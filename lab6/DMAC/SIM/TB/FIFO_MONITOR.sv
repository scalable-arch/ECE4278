`define MON_IF vif_ff.MONITOR.monitor_cb
class monitor;

  virtual fifo_if vif_ff;

  mailbox mon2scb;

  function new(virtual fifo_if vif_ff, mailbox mon2scb);
    this.vif_ff = vif_ff;
    this.mon2scb = mon2scb;
  endfunction

  task main();
    forever begin
      transactor trans;
      trans = new();

      @(posedge vif_ff.MONITOR.clk);
      wait(`MON_IF.rd_en || `MON_IF.wr_en);
      trans.wr_en = `MON_IF.wr_en;
      trans.wdata = `MON_IF.wdata;
      trans.full  = `MON_IF.full;
      trans.empty = `MON_IF.empty;
      trans.rd_en = `MON_IF.rd_en;
      trans.rdata = `MON_IF.rdata;
      mon2scb.put(trans);
    end

  endtask

endclass

