// Creates a queue object for transactions and when ran, will iterate 
// over the transactions in order
class vseq_in_order extends vseq_base;

  `uvm_object_utils(vseq_in_order)

  // Control popping of txns when sequence runs
  bit          pop;
  int unsigned sptr;

  // What will be sent
  amd_base_tlp q[$:1024]; 

  function new(string name = "vseq_in_order");
    super.new(name);
  endfunction

  /* METHODS: DATA MANIPULATION */

  // Add a txn to the front of queue
  virtual function void push_txn_front(amd_base_tlp t);
    q.push_front(t);
  endfunction

  // Add a txn to the back of queue
  virtual function void push_txn_back(amd_base_tlp t);
    q.push_back(t);
  endfunction

  // Identical to push_txn_back; just an alias
  virtual function void add_txn(amd_base_tlp t);
    push_txn_back(t);
  endfunction

  // Add a txn arbitrarily in queue
  virtual function void insert_txn(int idx, amd_base_tlp t);
    string msg;
    if (idx > num_txns()) begin
       msg = "Attempted to insert a txn beyond end of queue; pushing it to back";
      `uvm_warning(get_type_name, msg)
      idx = num_txns();
    end
    q.insert(idx, t);
  endfunction

  /* METHODS: QUERYING */

  // Query total number of txns
  virtual function int num_txns();
    return q.size;
  endfunction

  /* RUN THIS SEQUENCE */

  virtual task body;
    int eidx = q.size;
    for (int ii=sptr; ii<eidx; ii++)
      p_sequencer.api.send_txn(pop ? q.pop_front : q[ii]);
  endtask

endclass
