class environment;

  generator gen;
  driver driv;
  monitor mon;
  scoreboard scb;

  mailbox gen2driv;
  mailbox mon2scb;

  event gen_ended;

  virtual fifo_if vif_ff;

  function new(virtual fifo_if vif_ff);
    this.vif_ff = vif_ff;
    $display("environment created");
  endfunction

  task init();
    $display("initiating the environment");
    gen2driv = new();
    mon2scb = new();

    gen = new(gen2driv, gen_ended);
    driv = new(vif_ff, gen2driv);
    mon = new(vif_ff, mon2scb);
    scb = new(mon2scb);
  endtask

  task set_count(int repeat_count);
    $display("repeat_count is set to %d", repeat_count);
    this.gen.repeat_count = repeat_count;
  endtask

  task run();
    // pre test
    driv.reset();

    // test
    fork
      gen.main();
      driv.main();
      mon.main();
      scb.main();
    join_any

    // post test 
    wait(gen_ended.triggered);
    wait(gen.repeat_count == driv.no_of_transactions);
    wait(gen.repeat_count == scb.no_of_transactions);
  endtask

endclass


