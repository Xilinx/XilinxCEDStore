class gpdrv_api_seq extends uvm_sequence#(gpdrv_txn);

  `uvm_object_utils(gpdrv_api_seq)

  logic [63:0] sig;

  function new(string name = "gpdrv_api_seq");
    super.new(name);
  endfunction

  virtual task body;
    gpdrv_txn t = gpdrv_txn::type_id::create("t");
    start_item(t);
    t.sig = sig; 
    finish_item(t);
  endtask

endclass
