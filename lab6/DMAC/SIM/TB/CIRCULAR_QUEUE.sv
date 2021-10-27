`include "../TB/def.svh"

`define Q_SIZE 2**`DEPTH_LG2
class circular_queue;

  int queue [0:`Q_SIZE-1];
  int front, rear;

  function new();
    this.queue = '{ `Q_SIZE{0} };
    this.front = -1;
    this.rear = -1;
  endfunction

  function enqueue(int elem);
    if (!is_full()) begin
      rear = (rear + 1) % `Q_SIZE;
      queue[rear] = elem;
    end
  endfunction;

  function dequeue();
    if (!is_empty()) begin
      front = (front + 1) % `Q_SIZE;
    end
  endfunction;

  function int peek();
    peek = queue[(front+1) % `Q_SIZE];
  endfunction

  function int is_empty();
    if (front == rear)
      is_empty = 1;
    else
      is_empty = 0;
  endfunction

  function int is_full();
    if (front == ((rear+1) % `Q_SIZE))
      is_full = 1;
    else
      is_full = 0;
  endfunction

  function transactor ref_trans(transactor curr_trans);
    ref_trans = new();
    ref_trans.wdata = curr_trans.wdata;
    ref_trans.wr_en = curr_trans.wr_en;
    ref_trans.rd_en = curr_trans.rd_en;

    // empty
    ref_trans.empty = is_empty();
    // full
    ref_trans.full = is_full();

    // peek (showahead fifo)
    ref_trans.rdata = peek();

    // queue control
    if (curr_trans.wr_en) begin
      enqueue(curr_trans.wdata);
    end
    else if (curr_trans.rd_en) begin
      dequeue();
    end

  endfunction

endclass
