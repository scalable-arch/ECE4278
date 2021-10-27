class scoreboard;

  circular_queue ref_q;

  mailbox mon2scb;

  int no_of_transactions;
  int err_cnt;

  function new(mailbox mon2scb);
    this.mon2scb = mon2scb;

    ref_q = new();
  endfunction

  task main;
    transactor trans;
    transactor ref_trans;
    forever begin
      mon2scb.get(trans);
      ref_trans = ref_q.ref_trans(trans);
      if (trans.compare(ref_trans)) begin
        $display("T=%t [Correct]", $time);
      end
      else begin
        trans.print("Not Correct: FIFO Module   ");
        ref_trans.print("Not Correct: Circular Queue");
      end

      no_of_transactions++;
    end
  endtask

endclass

