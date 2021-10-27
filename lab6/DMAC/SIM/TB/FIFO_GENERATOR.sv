class generator;

  rand transactor trans;

  mailbox gen2driv;

  int repeat_count;
  int count;

  event ended;

  function new(mailbox gen2driv, event ended);
    this.gen2driv = gen2driv;
    this.ended = ended;
  endfunction

  task main();
    $display("entered into packet generation phase");
    count = 0;
    repeat(repeat_count) begin
      trans=new();
      if(!trans.randomize())   
        $fatal("packet is not randomised");
      else
        $display("%d  :randomization is successfull, rd_en: %h, wr_en: %h, wdata: %h",
          ++count, trans.rd_en, trans.wr_en, trans.wdata);
      gen2driv.put(trans);
    end
    -> ended;
    $display("leaving from packet generation phase");
  endtask:main

endclass

