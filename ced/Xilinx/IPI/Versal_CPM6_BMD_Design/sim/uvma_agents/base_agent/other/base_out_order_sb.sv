class base_out_order_sb#(type TXN = base_txn) extends uvm_scoreboard;

  `uvm_component_param_utils(base_out_order_sb#(TXN))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"base_out_order_sb#(",
                                   TXN::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  int unsigned compares;
  int unsigned miscompares;

  // Create "expected" and "actual" ports for comparison
  `uvm_analysis_imp_decl(_exp)
  `uvm_analysis_imp_decl(_act)

  uvm_analysis_imp_exp #(TXN, base_out_order_sb) impl_exp; 
  uvm_analysis_imp_act #(TXN, base_out_order_sb) impl_act; 

  protected TXN Q[$];

  uvm_comparer comparer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    impl_exp = new("impl_exp", this);
    impl_act = new("impl_act", this);
    comparer = new;
    init_comparer();
  endfunction

  // When performing out of order comparisons, you will get excessive miscompare
  // messages that aren't really valid, so we disable their printing
  virtual function void init_comparer;
    comparer.show_max = 0;
  endfunction

  virtual function void make_comparison(TXN act_t);
    string msg;
    int best_idx = -1;
    int unsigned best_result = '1;
    if (!Q.size) begin
      `uvm_error(get_type_name(), "Scoreboard array was empty when an actual txn was received");
      miscompares++;
      return;
    end
    foreach (Q[ii]) begin
      // Do a little pre-check; presumably saves a little computation time
      if ({Q[ii].txn_type, Q[ii].uid} != {act_t.txn_type, act_t.uid})
        continue;
      if (Q[ii].compare(act_t, comparer)) begin
       `uvm_info(get_type_name(), "sb made a successful comparison", UVM_HIGH)
        compares++;
        Q.delete(ii);
        return;
      end
      else if (comparer.result < best_result) begin
        best_result = comparer.result;
        best_idx = ii;
      end
    end
    msg = {"Miscomparison occurred; no match found for actual txn:\n", act_t.sprint};
    if (best_idx != -1) begin
      msg = {msg, 
             $sformatf("closest match: %0d mismatch%0s\n", 
                 best_result, best_result>1?"es":""), 
             Q[best_idx].sprint};
    end
    `uvm_error(get_type_name(), msg);
    miscompares++;
  endfunction

  virtual function void write_exp(TXN t);
    t.stamp; //stamp the txn with the timestamp
    `uvm_info(get_type_name(), {"sb received exp txn:\n",t.sprint}, UVM_HIGH)
    Q.push_back(t);
  endfunction

  virtual function void write_act(TXN t);
    t.stamp; //stamp the txn with the timestamp
    `uvm_info(get_type_name(), {"sb received act txn:\n",t.sprint}, UVM_HIGH)
    make_comparison(t);
  endfunction

  virtual function void extract_phase(uvm_phase phase);
    string msg;
    msg = $sformatf("%0d compares",compares);
    msg = {msg, $sformatf(", %0d miscompares",miscompares)};
    // We calculate unmatched as Q.size-miscompares, because we presumably HAD a
    // match, but something bad happened. An in order sb can simply pop when a 
    // miscompare occurs, but with an out of order sb, you can't do that.
    if ((Q.size-miscompares))
      msg = {msg, $sformatf(", %0d unmatched entries",Q.size-miscompares)};
    if (miscompares || (Q.size-miscompares))
      `uvm_error(get_type_name(), {"SCOREBOARD RESULTS: ",msg})
    else
      `uvm_info(get_type_name(), {"SCOREBOARD RESULTS: ",msg}, UVM_LOW)
    // Let's print some of what was left in the Q
    for (int ii=0; ii<(Q.size>3?3:Q.size); ii++)
      `uvm_info(get_type_name(), $sformatf("Remaining Q entry %0d of %0d:\n%s",ii+1,Q.size,Q[ii].sprint), UVM_MEDIUM)
  endfunction

endclass
