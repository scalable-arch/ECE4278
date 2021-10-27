`include "../TB/def.svh"

program test(fifo_if inf);
  environment env;

  initial begin
    $display("######### Environment Setup ##########");
    env = new(inf);  

    env.init();
    env.set_count(`REPEAT);

    $display("#########        Run        ##########");
    env.run();

    $display("#########     Finished      ##########");
    $finish();
  end

endprogram
