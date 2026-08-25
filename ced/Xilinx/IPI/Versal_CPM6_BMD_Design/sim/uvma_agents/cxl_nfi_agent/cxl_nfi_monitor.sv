class cxl_nfi_monitor#(type CFG, type VIF, type TXN, type SHR) extends base_monitor#(CFG,VIF,TXN,SHR);

  `uvm_component_param_utils(cxl_nfi_monitor#(CFG,VIF,TXN,SHR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"cxl_nfi_monitor#(",
                                   CFG::type_name,",",
                                   "VIF,",
                                   TXN::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  uvm_analysis_port#(flit68_txn)    ap68;
  uvm_analysis_port#(flit256_txn)   ap256;
  uvm_analysis_port#(slotset_txn)   apSS;
  uvm_analysis_port#(flit_base_txn) ap_fb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap68  = new("ap68",  this);
    ap256 = new("ap256", this);
    apSS  = new("apSS", this);
    ap_fb = new("ap_fb", this);
  endfunction

  // Let interface track and report interface-specific errors 
  virtual function void start_of_simulation_phase(uvm_phase phase);
    vif.right_align        = cfg.right_align;
    vif.nfi_width          = cfg.nfi_width;
    vif.h2c                = (cfg.dir==H2C);
    vif.no_drive_dec_assts = (!cfg.drive_dec_assts);
    vif.valid_only_mode      = cfg.valid_only_mode;
  endfunction

  virtual task run_phase(uvm_phase phase);

    bit [1:0]   ptr;
    flit68_txn  t68  = flit68_txn::type_id::create("t68");
    flit256_txn t256 = flit256_txn::type_id::create("t256");

    forever begin
      @(vif.mcb iff (vif.mcb.valid && (vif.valid_only_mode || vif.mcb.ready)));
      for (int ii=0; ii<$bits(vif.valid); ii++) begin
        if (vif.mcb.valid[ii] !== 1'b1) 
          continue;
        /* 68B flit mode */
        else if (cfg.flitmode == F68) begin
          // Enable assertions (first flit won't get checked, that's acceptable)
          vif.f68_mode = 1'b1;
          // Copy over rollover fields
          t68 = t68.new_flit();

          // Some basic setup
          t68.uid   = cfg.uid;
          t68.info  = $sformatf("NFI_%0d",ii);
          t68.info2 = (cfg.dir == H2C) ? "HOST_2_CARD" : "CARD_2_HOST";
          t68.dir   = cfg.dir;
          t68.disable_tight_pack_check = cfg.disable_tight_pack_check; 

          // Copy interface fields into txn
          t68.flit     = vif.mcb.data[ii];
          t68.parity   = vif.mcb.parity[ii];
          t68.viral    = vif.mcb.viral[ii];
          t68.valid    = vif.mcb.valid[ii];
          t68.ready    = vif.mcb.ready[ii];
          t68.adf      = vif.mcb.adf[ii];
          t68.last     = vif.mcb.last[ii];
          // Note : we don't copy over decode assists

          // Unpack the flit from raw bits into objects with a bunch of helpful metadata
          t68.unpack_flit();

          // Check if we've given link partner enough credits for txns it sent us
          if (cfg.is_slave) check_rcvd_have_credits(t68);

          // Broadcast out APs
          ap68.write(t68);
          ap_fb.write(t68);
          base_ap.write(t68);
        end
        /* 256B flit mode */
        else if (cfg.flitmode == F256) begin
    
          if (ptr==0) begin
            // Copy over rollover fields
            t256 = t256.new_flit; 
            // Some basic setup
            t256.uid   = cfg.uid;
            t256.info  = $sformatf("BGN: NFI_%0d",ii);
            t256.info3 = (cfg.dir == H2C) ? "HOST_2_CARD" : "CARD_2_HOST";
            t256.disable_tight_pack_check = cfg.disable_tight_pack_check; 
            t256.flitmode = cfg.flitmode; 
            t256.dir      = cfg.dir;
          end
          else
            t256.slotset[ptr].continue_flit(t256.slotset[ptr-1]);

          // Copy interface fields into txn (adf and last not used)
          t256.slotset[ptr].data   = vif.mcb.data[ii];
          t256.slotset[ptr].parity = vif.mcb.parity[ii];
          t256.slotset[ptr].viral  = vif.mcb.viral[ii];
          t256.slotset[ptr].valid  = vif.mcb.valid[ii];
          t256.slotset[ptr].ready  = vif.mcb.ready[ii];
          // Note : we don't copy over decode assists

          // Give handle between slotsets for LOpt mode
          if (cfg.flitmode == F256_LOPT) begin
            if (ptr==2) begin
              t256.slotset[ptr].lower_slot = t256.slot[7];
              for (int ii=0; ii<2; ii++) begin
                t256.slotset[ptr].pReq_consumed[ii] += t256.slot[7].req_consumed[ii]; 
                t256.slotset[ptr].pDat_consumed[ii] += t256.slot[7].dat_consumed[ii]; 
                t256.slotset[ptr].pRsp_consumed[ii] += t256.slot[7].rsp_consumed[ii]; 
              end
            end
            else if (ptr==3)
              t256.slotset[ptr].lower_slot = t256.slot[8];
          end

          // Tell txn to unpack the slotset
          t256.unpack_slotset(ptr);

          // Check if we've given link partner enough credits for txns it sent us
          if (cfg.is_slave && ptr==3) check_rcvd_have_credits(t256);

          // Have the assembler parse the slotset
          apSS.write(t256.slotset[ptr]);
    
          if (ptr++==3) begin
            t256.info2 = $sformatf("END: NFI_%0d",ii);
            // Broadcast out APs
            ap256.write(t256);
            ap_fb.write(t256);
            base_ap.write(t256);
          end
    
        end
        else begin
          `uvm_fatal(get_type_name, "Started receiving flits before cfg.flitmode was set")
        end
      end
   
    end
  endtask

  // Master agent decrements credits and performs checks in the driver, 
  // so we perform an extra error check if we're a slave agent to see if 
  // we receive a flit when we haven't given enough credits for the txns
  // that it contains
  virtual function void check_rcvd_have_credits(flit_base_txn t);
    string str;
    
    foreach (t.req_consumed[ii]) begin
      if (t.req_consumed[ii] > shr.avl_req_credit[ii]) begin
        str = "Monitor has witnessed a flit sent that consumes more CXL.";
        str = {str,$sformatf("%0s REQ credits than are available.",!ii?"cache":"mem")};
        str = {str,$sformatf(" Available: %0d. Flit %0d Consumes: %0d",shr.avl_req_credit[ii],ii,t.req_consumed[ii])};
        `uvm_error(get_type_name, str);
        shr.avl_req_credit[ii] = 0;
      end
      else
        shr.avl_req_credit[ii] -= t.req_consumed[ii];
      if (t.dat_consumed[ii] > shr.avl_dat_credit[ii]) begin
        str = "Monitor has witnessed a flit sent that consumes more CXL.";
        str = {str,$sformatf("%0s DAT credits than are available.",!ii?"cache":"mem")};
        str = {str,$sformatf(" Available: %0d. Flit %0d Consumes: %0d",shr.avl_dat_credit[ii],ii,t.dat_consumed[ii])};
        `uvm_error(get_type_name, str);
        shr.avl_dat_credit[ii] = 0;
      end
      else
        shr.avl_dat_credit[ii] -= t.dat_consumed[ii];
      if (t.rsp_consumed[ii] > shr.avl_rsp_credit[ii]) begin
        str = "Monitor has witnessed a flit sent that consumes more CXL.";
        str = {str,$sformatf("%0s RSP credits than are available.",!ii?"cache":"mem")};
        str = {str,$sformatf(" Available: %0d. Flit %0d Consumes: %0d",shr.avl_rsp_credit[ii],ii,t.rsp_consumed[ii])};
        `uvm_error(get_type_name, str);
        shr.avl_rsp_credit[ii] = 0;
      end
      else
        shr.avl_rsp_credit[ii] -= t.rsp_consumed[ii];
    end

  endfunction

endclass
