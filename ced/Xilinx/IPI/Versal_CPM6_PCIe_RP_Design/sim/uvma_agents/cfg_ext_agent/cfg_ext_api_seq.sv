class cfg_ext_api_seq extends uvm_sequence#(cfg_ext_txn);

  `uvm_object_utils(cfg_ext_api_seq)

  bit        wr = 1'b0;
  bit        rd = 1'b0;
  bit [11:0] addr;
  bit [31:0] data; 
  bit [ 3:0] be;
  bit [ 7:0] fnc;

  function new(string name = "cfg_ext_api_seq");
    super.new(name);
  endfunction

  virtual task body;
    cfg_ext_txn t = cfg_ext_txn::type_id::create("t");
    start_item(t);
    t.cfg_ext_read_received     = rd;
    t.cfg_ext_write_received    = wr;
    t.cfg_ext_register_number   = addr[11:2];
    t.cfg_ext_function_number   = fnc;
    t.cfg_ext_write_data        = data;
    t.cfg_ext_write_byte_enable = be;
    t.info = wr ? "WRITE" : (rd ? "READ_REQ" : "ERR");
    finish_item(t);
  endtask

endclass
