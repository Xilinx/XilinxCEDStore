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
    if (cfg.is_master() && cfg.valid_only_mode) begin
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
    if (cfg.is_slave())
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
    if (cfg.is_slave()) begin
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
    int unsigned digits[0:2];
    int unsigned tmp_max[$];
    int unsigned max[0:2];
    int unsigned total_flits;
    int unsigned tmp_total;
    super.report_phase(phase);
    if (cfg.disable_final_txn_reporting || cfg.is_slave()) return;
    // Find the biggest number
    tmp_max = total_req_driven.max(); max[0] = tmp_max[0];
    tmp_max = total_dat_driven.max(); max[1] = tmp_max[0];
    tmp_max = total_rsp_driven.max(); max[2] = tmp_max[0];
    // Find how many digits to fit biggest number in each column
    foreach (max[ii]) begin
      if      (max[ii] >= 1_000_000)  digits[ii] = 7;
      else if (max[ii] >= 100_000)    digits[ii] = 6;
      else if (max[ii] >= 10_000)     digits[ii] = 5;
      else if (max[ii] >= 1_000)      digits[ii] = 4;
      else if (max[ii] >= 100)        digits[ii] = 3;
      else if (max[ii] >= 10)         digits[ii] = 2;
      else                            digits[ii] = 1;
    end
    total_flits = cfg.flitmode==F68 ? total_slotsets : total_slotsets/4;
    amsg = {"Summary Statistics\n"};
    lmsg = $sformatf("CXL.mem     :");
    foreach (max[ii]) begin
      case (ii)
        0 : tmp_total = total_req_driven[1];
        1 : tmp_total = total_dat_driven[1];
        2 : tmp_total = total_rsp_driven[1];
      endcase
      case (digits[ii])
        7  : lmsg = {lmsg, $sformatf(" %7d", tmp_total)};
        6  : lmsg = {lmsg, $sformatf(" %6d", tmp_total)};
        5  : lmsg = {lmsg, $sformatf(" %5d", tmp_total)};
        4  : lmsg = {lmsg, $sformatf(" %4d", tmp_total)};
        3  : lmsg = {lmsg, $sformatf(" %3d", tmp_total)};
        2  : lmsg = {lmsg, $sformatf(" %2d", tmp_total)};
        1  : lmsg = {lmsg, $sformatf(" %1d", tmp_total)};
        0  : lmsg = {lmsg, $sformatf(" %1d", tmp_total)};
      endcase
      if (cfg.dir == H2C) begin 
        case (ii)
          0 : lmsg = {lmsg, " REQ (M2S_Req) |"};
          1 : lmsg = {lmsg, " DAT (M2S_RwD) |"};
          2 : lmsg = {lmsg, " RSP (M2S_BIRsp)"};
        endcase
      end
      else begin
        case (ii)
          0 : lmsg = {lmsg, " REQ (S2M_BISnp) |"};
          1 : lmsg = {lmsg, " DAT (S2M_DRS) |"};
          2 : lmsg = {lmsg, " RSP (S2M_NDR)"};
        endcase
      end
    end
    // If no .mem txns, just align and print "None" for that whole row
    if (!total_req_driven[1] && !total_dat_driven[1] && !total_rsp_driven[1]) begin
      lmsg = "CXL.mem     : None";
    end
    amsg = {amsg, {70{"-"}}, "\n", $sformatf("Total Flits : %0d\n",total_flits), lmsg, "\n"};
    lmsg = $sformatf("CXL.cache   :");
    foreach (max[ii]) begin
      case (ii)
        0 : tmp_total = total_req_driven[0];
        1 : tmp_total = total_dat_driven[0];
        2 : tmp_total = total_rsp_driven[0];
      endcase
      case (digits[ii])
        7  : lmsg = {lmsg, $sformatf(" %7d", tmp_total)};
        6  : lmsg = {lmsg, $sformatf(" %6d", tmp_total)};
        5  : lmsg = {lmsg, $sformatf(" %5d", tmp_total)};
        4  : lmsg = {lmsg, $sformatf(" %4d", tmp_total)};
        3  : lmsg = {lmsg, $sformatf(" %3d", tmp_total)};
        2  : lmsg = {lmsg, $sformatf(" %2d", tmp_total)};
        1  : lmsg = {lmsg, $sformatf(" %1d", tmp_total)};
        0  : lmsg = {lmsg, $sformatf(" %1d", tmp_total)};
      endcase
      if (cfg.dir == H2C) begin
        case (ii)
          0 : lmsg = {lmsg, " REQ (H2D_Req) |"};
          1 : lmsg = {lmsg, " DAT (H2D_Dat) |"};
          2 : lmsg = {lmsg, " RSP (H2D_Rsp)"};
        endcase
      end
      else begin
        case (ii)
          0 : lmsg = {lmsg, " REQ (D2H_Req)   |"};
          1 : lmsg = {lmsg, " DAT (D2H_Dat) |"};
          2 : lmsg = {lmsg, " RSP (D2H_Rsp)"};
        endcase
      end
    end
    // If no .cache txns, just align and print "None" for that whole row
    if (!total_req_driven[0] && !total_dat_driven[0] && !total_rsp_driven[0]) begin
      lmsg = "CXL.cache   : None";
    end
    amsg = {amsg, lmsg, "\n", {70{"-"}}};
    // Send it
    `uvm_info("DRVR", amsg, UVM_LOW) 
  endfunction

endclass
