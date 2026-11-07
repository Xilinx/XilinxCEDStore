class base_in_order_sb#(type TXN = base_txn) extends uvm_scoreboard;

  `uvm_component_param_utils(base_in_order_sb#(TXN))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"base_in_order_sb#(",
                                   TXN::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  int unsigned compares;
  int unsigned miscompares;
  int unsigned exp_delete;

  // Create "expected" and "actual" ports for comparison
  `uvm_analysis_imp_decl(_exp)
  `uvm_analysis_imp_decl(_act)

  uvm_analysis_imp_exp #(TXN, base_in_order_sb) impl_exp; 
  uvm_analysis_imp_act #(TXN, base_in_order_sb) impl_act; 

  protected TXN Q[$];

  uvm_comparer comparer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    impl_exp = new("impl_exp", this);
    impl_act = new("impl_act", this);
    comparer = new;
    init_comparer();
  endfunction

  // We will get just print the txn in its entirety, not field-by-field
  virtual function void init_comparer;
    comparer.show_max = 0;
  endfunction

  // This method tries to compare the act txn to the first exp txn. If there is a subsequent 
  // match, then all the previous unmatching txns are removed.
  virtual function void make_comparison(TXN act_t);
    bit match;
    int match_idx[$];
    int unsigned first_result;
    bit first = 1'b1;
    if (!Q.size) begin
      `uvm_error(get_type_name(), "Scoreboard array was empty when an actual txn was received");
      miscompares++;
      return;
    end
    foreach (Q[ii]) begin
      // Do a little pre-check; presumably saves a little computation time
      if ({Q[ii].txn_type, Q[ii].uid} != {act_t.txn_type, act_t.uid})
        continue;
      else begin
        match_idx.push_back(ii);
        if (Q[ii].compare(act_t, comparer)) begin
         `uvm_info(get_type_name(), "sb made a successful comparison", UVM_HIGH)
          match = 1;
          compares++;
          break;
        end
        else if (first) begin
          first_result = comparer.result;
          first = 1'b0;
        end
      end
    end
    if (match) begin
      if (match_idx.size>1) begin
        exp_delete += match_idx.size-1;
        `uvm_error(get_type_name(), $sformatf("Match found, but not in order. %0d txns expected before match.",
                                    match_idx.size-1))
        
      end
      for (int ii=(match_idx.size-1); ii>=0; ii--)
        Q.delete(ii);
    end
    else begin
      miscompares++;
      if (match_idx.size)
        `uvm_error(get_type_name(), {"Miscomparison occured; no match found for actual txn:\n",
                                     act_t.sprint,
                                     $sformatf("expected txn (%0d mismatch%0s):\n",first_result,first_result==1?"":"es"),
                                     Q[match_idx[0]].sprint})
      else
        `uvm_error(get_type_name(), {"Miscomparison occured; no match found for actual txn:\n",act_t.sprint})
    end
  endfunction

  virtual function void write_exp(TXN t);
    t.stamp; //stamp the txn with the timestamp
    `uvm_info(get_type_name(), {"sb received exp txn:\n",t.sprint}, UVM_HIGH)
    Q.push_back(t);
  endfunction

  virtual function void write_act(TXN t);
    string k;
    t.stamp; //stamp the txn with the timestamp
    `uvm_info(get_type_name(), {"sb received act txn:\n",t.sprint}, UVM_HIGH)
    make_comparison(t);
  endfunction

  virtual function void extract_phase(uvm_phase phase);
    string msg;
    msg = $sformatf("%0d compares",compares);
    msg = {msg, $sformatf(", %0d miscompares",miscompares)};
    if (exp_delete)
      msg = {msg, $sformatf(", %0d expected txns deleted",exp_delete)};
    if (Q.size)
      msg = {msg, $sformatf(", %0d unmatched entries", Q.size)};
    if (miscompares || exp_delete || Q.size)
      `uvm_error(get_type_name(), {"SCOREBOARD RESULTS: ",msg})
    else
      `uvm_info(get_type_name(), {"SCOREBOARD RESULTS: ",msg}, UVM_LOW)
    // Let's print some of what was left in the Q
    for (int ii=0; ii<(Q.size>3?3:Q.size); ii++)
      `uvm_info(get_type_name(), $sformatf("Remaining Q entry %0d of %0d:\n%s",ii+1,Q.size,Q[ii].sprint), UVM_MEDIUM)
  endfunction

endclass
