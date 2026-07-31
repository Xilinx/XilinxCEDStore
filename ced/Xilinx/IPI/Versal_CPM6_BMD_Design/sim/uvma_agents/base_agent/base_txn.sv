// - Base Txn Class
// - Users will extend this class to create their own transactions
class base_txn extends uvm_sequence_item;

  `uvm_object_utils(base_txn)

  string txn_type;       //extended class should set this in constructor
  string uid;            //addl. field to distinguish txns between multiple agents
                         //of the same type e.g. {txn_type, uid} or "if (t.uid==...)"
  string info;           //addl. field so user/agent can add extra info
  string info2;          //addl. field so user/agent can add extra extra info
  string info3;          //addl. field so user/agent can add extra extra info
  time   timestamp;      //SB should stamp the time
  string addl_info[$:4]; //from cfg object

  bit    append_uid;
  int    compare_info;      //-1 is compare all
  int    compare_addl_info; //-1 is compare all

  function new(string name = "base_txn");
    super.new(name);
  endfunction 

  virtual function void stamp;
    timestamp = $time;
  endfunction

  // Helper functions
  protected function int min(int a, int b); 
    return (a < b ? a : b); 
  endfunction 
  protected function int max(int a, int b); 
    return (a > b ? a : b); 
  endfunction 
  protected function int unsigned umin(int unsigned a, int unsigned b); 
    return (a < b ? a : b); 
  endfunction 
  protected function int unsigned umax(int unsigned a, int unsigned b); 
    return (a > b ? a : b); 
  endfunction 

  virtual function void do_copy(uvm_object rhs);
    base_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_copy got a txn that wasn't extended from base_txn")
    txn_type          = t.txn_type;
    uid               = t.uid;
    append_uid        = t.append_uid;
    compare_info      = t.compare_info;
    info              = t.info;
    info2             = t.info2;
    info3             = t.info3;
    addl_info         = t.addl_info;
    compare_addl_info = t.compare_addl_info;
    timestamp         = t.timestamp;
  endfunction

  virtual function void do_print(uvm_printer printer);
    string txnt_str = append_uid ? {txn_type,uid} : txn_type; 
    printer.print_string  ("txn_type", txnt_str);
    if (uid != "" && !append_uid)
      printer.print_string("uid",      uid);
    if (info != "")
      printer.print_string("info",     info);
    if (info2 != "")
      printer.print_string("info2",    info2);
    if (info3 != "")
      printer.print_string("info3",    info3);
    foreach (addl_info[ii]) 
      printer.print_string($sformatf("addl_info[%0d]",ii), addl_info[ii]);
    printer.print_time    ("timestamp", timestamp);
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    base_txn t;
    if (!$cast(t, rhs))
      `uvm_fatal(get_type_name, "do_compare got a txn that wasn't extended from base_txn")
    if (append_uid) 
      do_compare = comparer.compare_string("txn_type", {txn_type,uid}, {t.txn_type,t.uid});
    else begin
      do_compare  = comparer.compare_string("txn_type", txn_type, t.txn_type);
      do_compare &= comparer.compare_string("uid",      uid,      t.uid); 
    end
    if (compare_info > 0 || compare_info==-1) 
      do_compare &= comparer.compare_string("info",  info,  t.info);
    if (compare_info > 1 || compare_info==-1)
      do_compare &= comparer.compare_string("info2", info2, t.info2);
    if (compare_info > 2 || compare_info==-1)
      do_compare &= comparer.compare_string("info3", info3, t.info3);
    foreach (addl_info[ii]) begin
      if (ii!=-1 && ii==compare_addl_info) break;
      do_compare &= comparer.compare_string($sformatf("addl_info[%0d]",ii), addl_info[ii], t.addl_info[ii]);
    end
  endfunction

  // Used with hash_sb
  virtual function int hash(base_txn t);
    `uvm_warning(get_type_name, "Hash function not implemented")
    return 0;
  endfunction 

endclass
