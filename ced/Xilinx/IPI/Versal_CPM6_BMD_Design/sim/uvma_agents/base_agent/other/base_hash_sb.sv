class base_hash_sb#(type TXN = base_txn) extends uvm_scoreboard;

  `uvm_component_param_utils(base_hash_sb#(TXN))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"base_hash_sb#(",
                                   TXN::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  int unsigned compares;
  int unsigned miscompares;

  // Create "expected" and "actual" ports for comparison
  `uvm_analysis_imp_decl(_exp)
  `uvm_analysis_imp_decl(_act)

  uvm_analysis_imp_exp #(TXN, base_hash_sb) impl_exp; 
  uvm_analysis_imp_act #(TXN, base_hash_sb) impl_act; 

  // Could receive multiple expected txns, so we need to implement
  // a count that we increment and decrement
  protected TXN AA[int];
  protected int AA_cnt[int];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    impl_exp = new("impl_exp", this);
    impl_act = new("impl_act", this);
  endfunction

  virtual function void make_comparison(TXN act_t);
    if (!AA.size) begin
      `uvm_error(get_type_name(), "Scoreboard array was empty when an actual txn was received");
      miscompares++;
      return;
    end
    if (AA_cnt.exists(act_t.hash)) begin
      if (!AA[act_t.hash].compare(act_t))
        `uvm_fatal(get_type_name(), "Hash collision on removal!") 
      else begin
        compares++;
       `uvm_info(get_type_name(), "sb made a successful comparison", UVM_HIGH)
        if (AA_cnt[act_t.hash] == 1) begin
          AA.delete(act_t.hash);
          AA_cnt.delete(act_t.hash);
        end
        else
          AA_cnt[act_t.hash]--;
      end
    end
    else begin
      `uvm_error(get_type_name(), {"Miscomparison occured; no match found for actual txn:\n",act_t.sprint}) 
      miscompares++;
    end
  endfunction

  virtual function void write_exp(TXN t);
    t.stamp; //stamp the txn with the timestamp
    `uvm_info(get_type_name(), {"sb received exp txn:\n",t.sprint}, UVM_HIGH)
    if (AA_cnt.exists(t.hash)) begin
      if (!AA[t.hash].compare(t))
        `uvm_fatal(get_type_name(), "Hash collision on insert!")
      else
        AA_cnt[t.hash]++;
    end
    else begin
      AA[t.hash]     = t;
      AA_cnt[t.hash] = 1;
    end
  endfunction

  virtual function void write_act(TXN t);
    t.stamp; //stamp the txn with the timestamp
    `uvm_info(get_type_name(), {"sb received act txn:\n",t.sprint}, UVM_HIGH)
    make_comparison(t);
  endfunction

  virtual function void extract_phase(uvm_phase phase);
    string msg;
    int unmatched;
    msg = $sformatf("%0d compares",compares);
    msg = {msg, $sformatf(", %0d miscompares",miscompares)};
    if (!AA_cnt.size) begin
      foreach(AA_cnt[key])
        unmatched += AA_cnt[key];
      msg = {msg, $sformatf(", %0d unmatched entries",unmatched)};
    end
    if (miscompares || !AA_cnt.size)
      `uvm_error(get_type_name(), {"SCOREBOARD RESULTS: ",msg})
    else
      `uvm_info(get_type_name(), {"SCOREBOARD RESULTS: ",msg}, UVM_LOW)
  endfunction

endclass
