class vseq_random_order extends vseq_in_order;

  `uvm_object_utils(vseq_random_order)

  bit hold;

  function new(string name = "vseq_random_order");
    super.new(name);
  endfunction 
  
  virtual task pre_body;
    if (!hold) q.shuffle;
  endtask
  
  virtual task body;
    sptr = 0;
    super.body();
  endtask

endclass
