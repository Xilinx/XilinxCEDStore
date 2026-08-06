class gpdrv_monitor#(type CFG, type VIF, type TXN) extends base_monitor#(CFG,VIF,TXN,base_share);

  `uvm_component_param_utils(gpdrv_monitor#(CFG,VIF,TXN))

  typedef gpdrv_monitor#(CFG,VIF,TXN) this_type;
  typedef gpdrv_mon_cb #(TXN)         cb_type;

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"gpdrv_monitor#(",
                                   CFG::type_name,",",
                                   "VIF,",
                                   TXN::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  // `uvm_register_cb cannot handle parameterized objects, so we must
  // copy what it's done and make our own
  // - `define uvm_register_cb(T,CB) \
  //     static local bit m_register_cb_``CB = uvm_callbacks#(T,CB)::m_register_pair(`"T`",`"CB`");
  // - class uvm_callbacks #(type T=uvm_object, type CB=uvm_callback)
  //   extends uvm_typed_callbacks#(T);
  // - static function bit m_register_pair(string tname="", cbname="");
  // fixme
  `define gpdrv_register_cb(T,CB,Tname,CBname) \
    static local bit m_register_cb_``NAME = uvm_callbacks#(T,CB)::m_register_pair(`"Tname`",`"CBname`");
  // Register the CB
  `gpdrv_register_cb(this_type, cb_type, get_type_name, gpdrv_mon_cb::type_name)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    logic [63:0] prev_sig;
    base_txn     bt;
    TXN          txn = TXN::type_id::create("txn");
    // Copy cfg object stuff to txn once 
    txn.uid         = cfg.uid;
    txn.width       = cfg.width;
    txn.print_radix = cfg.print_radix;
    forever begin
      if (cfg.sync_control == SYNC) begin
        prev_sig = vif.sig;
        @(vif.cb iff (prev_sig !== vif.sig));
      end
      else begin
        @(vif.sig);    
      end
      txn.sig = vif.sig; 
      // Do callback : the callback should enumerate the value to a string for 
      // better readability. By modifying the class object directly, we can
      // get around complicated parameterized types. Callbacks allow anyone
      // to add a callback, which is extremely flexible.
      `uvm_do_callbacks(this_type, cb_type, make_specific(txn))
      ap.write(txn);
      bt = txn;
      base_ap.write(bt);
      // Clear the txn.ml_sig_enum because we're not new-ing the object
      // and we will get repeated prints from the callback
      txn.ml_sig_enum.delete();
    end
  endtask

endclass
