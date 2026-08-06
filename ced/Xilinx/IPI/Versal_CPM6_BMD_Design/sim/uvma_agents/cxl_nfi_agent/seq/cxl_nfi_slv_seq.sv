// The driver expects a transaction of type cxl_nfi_txn#(int), which is basically 
// an N-wide slotset txn, which may be multiple flits or a subset of a flit. The 
// ready being driven on the CXL NFI if is multiple bits wide, but it is just a 
// replication to ease timing. The driver will drive ready[0] across the  bus.
class cxl_nfi_slv_seq#(parameter NFI_W=3) extends cxl_nfi_base_seq#(NFI_W);

  `uvm_object_param_utils(cxl_nfi_slv_seq#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cxl_nfi_slv_seq#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name = "cxl_nfi_slv_seq");
    super.new(name);
  endfunction

  // NONE   : no backpressure              (ready = 1; exit)
  // VLOW   : very light backpressure      (ready = 0 for 1 count per 100 clock cycles) 
  // LOW    : light backpressure           (ready = 0 for 10 counts per 100 clock cycles
  // MEDIUM : medium backpressure          (ready = 0 for 25 counts per 100 clock cycles) 
  // HIGH   : high backpressure            (ready = 0 for 50 counts per 100 clock cycles) 
  // VHIGH  : very high backpressure       (ready = 0 for 75 counts per 100 clock cycles) 
  // VVHIGH : very-very high backpressure  (ready = 0 for 90 counts per 100 clock cycles) 
  // RAND   : user controlled dist         (unique trials with backpressure_chance to backpressure)
  backpressure_ctl_t backpressure_ctl = NONE;

  /* VLOW to VHIGH */
  rand bit rand_ready100[100];
  /* RAND */
       bit [6:0] backpressure_chance = 'd10; //user should set this from 0-100
  rand bit       rand_ready;

  constraint c_backpressure {
    rand_ready dist { 0 := backpressure_chance, 1 := (100-backpressure_chance)};
    if (backpressure_ctl == VLOW)        { rand_ready100.sum with (int'(item)) == 99; } 
    else if (backpressure_ctl == LOW)    { rand_ready100.sum with (int'(item)) == 90; }
    else if (backpressure_ctl == MEDIUM) { rand_ready100.sum with (int'(item)) == 75; }
    else if (backpressure_ctl == HIGH)   { rand_ready100.sum with (int'(item)) == 50; }
    else if (backpressure_ctl == VHIGH)  { rand_ready100.sum with (int'(item)) == 25; }
    else if (backpressure_ctl == VVHIGH) { rand_ready100.sum with (int'(item)) == 10; }
  }

  virtual task body();
    cxl_nfi_txn#(NFI_W) t;
    wait (backpressure_ctl != NONE);
    t = cxl_nfi_txn#(NFI_W)::type_id::create("t");
    forever begin
      if (backpressure_ctl == NONE) begin
        t.ready[0] = 1'b1;
        start_item(t);
        finish_item(t);
        p_sequencer.wait_cycles(1);
      end
      else if (backpressure_ctl == RAND) begin
        void'(this.randomize());
        t.ready[0] = rand_ready;
        start_item(t);
        finish_item(t);
      end  
      else begin
        void'(this.randomize());
        foreach(rand_ready100[ii]) begin
          t.ready[0] = rand_ready100[ii];
          start_item(t);
          finish_item(t);
        end
      end
    end
  endtask

endclass
