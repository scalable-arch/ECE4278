`include "../TB/def.svh"

class transactor;
  // input port
  rand bit [`DATA_WIDTH-1:0]wdata;
  rand bit rd_en;
  rand bit wr_en;

  // output port
  bit [`DATA_WIDTH-1:0]rdata;
  bit full;
  bit empty;

  constraint rd_wr_en{ rd_en != wr_en; }

  virtual function bit compare(transactor trans);
    compare =1'b1;
    if(trans==null)
      compare =0;
    else begin
      if(trans.wr_en!=this.wr_en)
        compare = 0;
      if(trans.rd_en!=this.rd_en)
        compare = 0;
      if(trans.wdata!=this.wdata)
        compare = 0;
      if(trans.rdata!=this.rdata)
        compare = 0;
      if(trans.full!=this.full)
        compare = 0;
      if(trans.empty!=this.empty)
        compare = 0;
    end
  endfunction

  function void print(string tag = "");
    $display("T=%0t [%s] \t wr_en=%b, full=%b, wdata=0x%08h, rd_en=%b, empty=%b, rdata=0x%08h",
      $time, tag, wr_en, full, wdata, rd_en, empty, rdata);
  endfunction

endclass

