class cxl_nfi_driver#(type REQ, type RSP, type VIF, type CFG, type SHR) extends base_driver#(REQ,RSP,VIF,CFG,SHR);

  `uvm_component_param_utils(cxl_nfi_driver#(REQ,RSP,VIF,CFG,SHR))

  // uvm*param_utils don't define "DRVR"() and type_name
  const static string type_name = {"cxl_nfi_driver#(",
                                   REQ::type_name,",",
                                   RSP::type_name,",",
                                   "VIF,",
                                   CFG::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  event ready_sampled;
  logic [0:0] ready_q;

  int unsigned total_slotsets;
  int unsigned total_req_driven[1:0];
  int unsigned total_dat_driven[1:0];
  int unsigned total_rsp_driven[1:0];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    if (cfg.is_master && cfg.valid_only_mode) begin
      fork
        forever begin
          @(vif.mcb);
          ready_q = (vif.mcb.ready);
          ->ready_sampled;
        end
      join_none
    end
    super.run_phase(phase);
  endtask

  virtual task drive_init();
    vif.agent_driven = 1;
    if (cfg.is_slave)
      vif.i_ready   <= '1;
    else begin
      vif.i_valid   <= '0;
      vif.i_data    <= '0;
      vif.i_parity  <= '0;
      vif.i_adf     <= '0;
      vif.i_last    <= '0;
      vif.i_viral   <= '0;
      vif.i_dec_sop <= '0;
      vif.i_dec_eop <= '0;
      vif.i_dec_be  <= '0;
      vif.i_dec_mem <= '0;
    end
  endtask

  virtual task drive_item(REQ req);
    // Active slave drives ready to control blocking
    if (cfg.is_slave) begin
      // ready is just a signal expanded to a bus, drive the txn lsb on bus
      vif.dcb.i_ready <= {5{req.ready[0]}};
      @(vif.dcb);
    end
    // Master drives transactions
    else begin
      // Master is now responsible for deasserting valid in this mode
      if (cfg.valid_only_mode) begin
        wait(ready_sampled.triggered);
        while (!ready_q) begin
          @(vif.dcb);
          wait(ready_sampled.triggered);
        end
      end
      vif.dcb.i_valid  <= req.valid;
      vif.dcb.i_last   <= req.last; 
      vif.dcb.i_adf    <= req.adf;
      vif.dcb.i_data   <= req.data; 
      vif.dcb.i_parity <= req.parity;
      vif.dcb.i_viral  <= req.viral;
      if (cfg.drive_dec_assts) begin
        vif.dcb.i_dec_sop <= req.dec_sop;
        vif.dcb.i_dec_eop <= req.dec_eop;
        vif.dcb.i_dec_be  <= req.dec_be;
        vif.dcb.i_dec_mem <= req.dec_mem;
      end
      do_credit_tracking(req);
      // Default: VALID/READY INTERFACE (cfg.valid_only_mode==0)
      // Optional: VALID (ONLY) INTERFACE (cfg.valid_only_mode==1)
      @(vif.mcb iff (!req.valid || //user wants an invalid txn for some reason
                     (vif.mcb.valid && (cfg.valid_only_mode || vif.mcb.ready)))); //accepted txn
      vif.dcb.i_valid <= '0;
      // When valid=0, data/adf/decode assists are always 0
      vif.dcb.i_data  <= '0;
      vif.dcb.i_adf   <= '0;
      if (cfg.drive_dec_assts) begin
        vif.dcb.i_dec_sop <= '0;
        vif.dcb.i_dec_eop <= '0;
        vif.dcb.i_dec_be  <= '0;
        vif.dcb.i_dec_mem <= '0;
      end
    end
  endtask

  virtual function void do_credit_tracking(REQ req);
    string str;
    total_slotsets += $countones(req.valid);
    for (int ii=0; ii<vif.NFI_W; ii++) begin //per-slot-set credit tracking
      for (int jj=0; jj<2; jj++) begin //per-protocol (cache and mem)
        // Keep running count of all txns driven
        total_req_driven[jj] += req.req_consumed[ii][jj];
        total_dat_driven[jj] += req.dat_consumed[ii][jj];
        total_rsp_driven[jj] += req.rsp_consumed[ii][jj];
        // Detect error condition of sending when credits aren't available and  
        // also decrement credits as they are consumed
        // -- REQ --
        if (req.req_consumed[ii][jj] > shr.avl_req_credit[jj]) begin
          str = "Driver has been commanded to send flit that consumes more CXL.";
          str = {str,$sformatf("%0s REQ credits than are available.",jj==CCH?"cache":"mem")};
          str = {str,$sformatf(" Available: %0d. NFI_%0d Consumes: %0d",shr.avl_req_credit[jj],ii,req.req_consumed[ii][jj])};
          `uvm_error("DRVR", str);
          shr.avl_req_credit[jj] = 0;
        end
        else
          shr.avl_req_credit[jj] -= req.req_consumed[ii][jj];
        // -- DAT --
        if (req.dat_consumed[ii][jj] > shr.avl_dat_credit[jj]) begin
          str = "Driver has been commanded to send flit that consumes more CXL.";
          str = {str,$sformatf("%0s DAT credits than are available.",jj==CCH?"cache":"mem")};
          str = {str,$sformatf(" Available: %0d. NFI_%0d Consumes: %0d",shr.avl_dat_credit[jj],ii,req.dat_consumed[ii][jj])};
          `uvm_error("DRVR", str);
          shr.avl_dat_credit[jj] = 0;
        end
        else
          shr.avl_dat_credit[jj] -= req.dat_consumed[ii][jj];
        // -- RSP --
        if (req.rsp_consumed[ii][jj] > shr.avl_rsp_credit[jj]) begin
          str = "Driver has been commanded to send flit that consumes more CXL.";
          str = {str,$sformatf("%0s RSP credits than are available.",jj==CCH?"cache":"mem")};
          str = {str,$sformatf(" Available: %0d. NFI_%0d Consumes: %0d",shr.avl_rsp_credit[jj],ii,req.rsp_consumed[ii][jj])};
          `uvm_error("DRVR", str);
          shr.avl_rsp_credit[jj] = 0;
        end
        else
          shr.avl_rsp_credit[jj] -= req.rsp_consumed[ii][jj];
      end
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    string amsg, lmsg, spc; //amsg = "all msg", lmsg = "line msg"
    int digits;
    int unsigned max[$];
    int unsigned new_max[$];
    int unsigned total_flits;
    super.report_phase(phase);
    if (cfg.disable_final_txn_reporting || cfg.is_slave) return;
    // Find the biggest number
    max     = total_req_driven.max;
    new_max = total_dat_driven.max;
    if (new_max[0] > max[0]) max = new_max;
    new_max = total_rsp_driven.max;
    if (new_max[0] > max[0]) max = new_max;
    // Find how many digits to fit biggest number
    if (max[0]/10000)     digits = 5;
    else if (max[0]/1000) digits = 4;
    else if (max[0]/100)  digits = 3;
    else if (max[0]/10)   digits = 2;
    else if (max[0]/1)    digits = 1;
    else    return;
    total_flits = cfg.flitmode==F68 ? total_slotsets : total_slotsets/4;
    amsg = {"Summary Statistics\n"};
    if (cfg.dir == H2C) begin 
      case (digits)
        5 : lmsg = $sformatf("CXL.mem     : %5d REQ (M2S_Req) | %5d DAT (M2S_RwD) | %0sNone",
                            total_req_driven[1], 
                            total_dat_driven[1],
                            {digits-1{" "}});
        4 : lmsg = $sformatf("CXL.mem     : %4d REQ (M2S_Req) | %4d DAT (M2S_RwD) | %0sNone",
                            total_req_driven[1], 
                            total_dat_driven[1],
                            {digits-1{" "}});
        3 : lmsg = $sformatf("CXL.mem     : %3d REQ (M2S_Req) | %3d DAT (M2S_RwD) | %0sNone",
                            total_req_driven[1], 
                            total_dat_driven[1],
                            {digits-1{" "}});
        2 : lmsg = $sformatf("CXL.mem     : %2d REQ (M2S_Req) | %2d DAT (M2S_RwD) | %0sNone",
                            total_req_driven[1], 
                            total_dat_driven[1],
                            {digits-1{" "}});
        1 : lmsg = $sformatf("CXL.mem     : %1d REQ (M2S_Req) | %1d DAT (M2S_RwD) | %0sNone",
                            total_req_driven[1], 
                            total_dat_driven[1],
                            {digits-1{" "}});
        default : lmsg = "print error, see driver";
      endcase
    end
    else begin
      spc = !total_req_driven[0] && !total_dat_driven[0] && !total_rsp_driven[0] ? "" : {digits+9{" "}};
      case (digits)
        5 : lmsg = $sformatf("CXL.mem     : %0sNone | %5d DAT (S2M_DRS) | %5d RSP (S2M_NDR) ",
                             spc,
                             total_dat_driven[1],
                             total_rsp_driven[1]);
        4 : lmsg = $sformatf("CXL.mem     : %0sNone | %4d DAT (S2M_DRS) | %4d RSP (S2M_NDR) ",
                             spc,
                             total_dat_driven[1],
                             total_rsp_driven[1]);
        3 : lmsg = $sformatf("CXL.mem     : %0sNone | %3d DAT (S2M_DRS) | %3d RSP (S2M_NDR) ",
                             spc,
                             total_dat_driven[1],
                             total_rsp_driven[1]);
        2 : lmsg = $sformatf("CXL.mem     : %0sNone | %2d DAT (S2M_DRS) | %2d RSP (S2M_NDR) ",
                             spc,
                             total_dat_driven[1], 
                             total_rsp_driven[1]);
        1 : lmsg = $sformatf("CXL.mem     : %0sNone | %1d DAT (S2M_DRS) | %1d RSP (S2M_NDR) ",
                             spc,
                             total_dat_driven[1], 
                             total_rsp_driven[1]);
        default : lmsg = "print error, see driver";
      endcase
    end
    // If no .mem txns, just align and print "None" for that whole row
    if (!total_req_driven[1] && !total_dat_driven[1] && !total_rsp_driven[1]) begin
      lmsg = "CXL.mem     :";
      repeat (digits-1) lmsg = {lmsg," "};
      lmsg = {lmsg,"None"};
    end
    amsg = {amsg, {70{"-"}}, "\n", $sformatf("Total Flits : %0d\n",total_flits), lmsg, "\n"};
    if (cfg.dir == H2C) begin
      case (digits)
        5 : lmsg = $sformatf("CXL.cache   : %5d REQ (H2D_Req) | %5d DAT (H2D_Dat) | %5d RSP (H2D_Rsp) ",
                            total_req_driven[0],
                            total_dat_driven[0],
                            total_rsp_driven[0]);
        4 : lmsg = $sformatf("CXL.cache   : %4d REQ (H2D_Req) | %4d DAT (H2D_Dat) | %4d RSP (H2D_Rsp) ",
                            total_req_driven[0],
                            total_dat_driven[0],
                            total_rsp_driven[0]);
        3 : lmsg = $sformatf("CXL.cache   : %3d REQ (H2D_Req) | %3d DAT (H2D_Dat) | %3d RSP (H2D_Rsp) ",
                            total_req_driven[0],
                            total_dat_driven[0],
                            total_rsp_driven[0]);
        2 : lmsg = $sformatf("CXL.cache   : %2d REQ (H2D_Req) | %2d DAT (H2D_Dat) | %2d RSP (H2D_Rsp) ",
                            total_req_driven[0],
                            total_dat_driven[0],
                            total_rsp_driven[0]);
        1 : lmsg = $sformatf("CXL.cache   : %1d REQ (H2D_Req) | %1d DAT (H2D_Dat) | %1d RSP (H2D_Rsp) ",
                            total_req_driven[0],
                            total_dat_driven[0],
                            total_rsp_driven[0]);
        default : lmsg = "print error, see driver";
      endcase
    end
    else begin
      case (digits)
        5 : lmsg = $sformatf("CXL.cache   : %5d REQ (D2H_Req) | %5d DAT (D2H_Dat) | %5d RSP (D2H_Rsp) ",
                            total_req_driven[0],
                            total_dat_driven[0],
                            total_rsp_driven[0]);
        4 : lmsg = $sformatf("CXL.cache   : %4d REQ (D2H_Req) | %4d DAT (D2H_Dat) | %4d RSP (D2H_Rsp) ",
                            total_req_driven[0],
                            total_dat_driven[0],
                            total_rsp_driven[0]);
        3 : lmsg = $sformatf("CXL.cache   : %3d REQ (D2H_Req) | %3d DAT (D2H_Dat) | %3d RSP (D2H_Rsp) ",
                            total_req_driven[0],
                            total_dat_driven[0],
                            total_rsp_driven[0]);
        2 : lmsg = $sformatf("CXL.cache   : %2d REQ (D2H_Req) | %2d DAT (D2H_Dat) | %2d RSP (D2H_Rsp) ",
                            total_req_driven[0],
                            total_dat_driven[0],
                            total_rsp_driven[0]);
        1 : lmsg = $sformatf("CXL.cache   : %1d REQ (D2H_Req) | %1d DAT (D2H_Dat) | %1d RSP (D2H_Rsp) ",
                            total_req_driven[0],
                            total_dat_driven[0],
                            total_rsp_driven[0]);
        default : lmsg = "print error, see driver";
      endcase
    end
    // If no .cache txns, just align and print "None" for that whole row
    if (!total_req_driven[0] && !total_dat_driven[0] && !total_rsp_driven[0]) begin
      if (cfg.dir == H2C) begin
        lmsg = "CXL.cache   :";
        repeat (digits-1) lmsg = {lmsg," "};
        lmsg = {lmsg,"None"};
      end
      else
        lmsg = "CXL.cache   : None";
    end
    amsg = {amsg, lmsg, "\n", {70{"-"}}};
    // Send it
    `uvm_info("DRVR", amsg, UVM_LOW) 
  endfunction

endclass
