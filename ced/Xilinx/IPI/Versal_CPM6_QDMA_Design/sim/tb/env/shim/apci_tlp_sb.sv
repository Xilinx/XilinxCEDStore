typedef struct {
  bit [63:0] addr;
  bit [31:0] payload[];
} mwr_data_t;

class apci_tlp_sb extends uvm_subscriber#(apci_tlp);
  `uvm_component_utils(apci_tlp_sb)

  bit check_enabled = 0;

  // AXI wr/rd transaction queues: populated by write_axi_mon() via axi_mon_cb callback,
  svt_axi_transaction axi_wr_q[$];
  svt_axi_transaction axi_rd_q[$];

  // MWr TLP queue: write_req() pushes decoded MWr here; Thread 2 pops and checks.
  mwr_data_t mwr_q[$];

  // Tag → address map: registered in write_req() (MRd), consumed in write_rsp() (CplD).
  bit [63:0] mrd_tag_to_addr[bit[11:0]];

  // CplD address queue: write_rsp() pushes PCIe-derived address; Thread 3 pops it.
  bit [63:0] cpl_addr_q[$];

  // wr_data_mem[addr] = 32-bit data word at that byte address.
  bit [31:0] exp_wr_data_mem[bit [63:0]];

  int req_count = 0;
  int rsp_count = 0;
  int chk1_pass = 0;
  int chk1_fail = 0;
  int chk2_pass = 0;
  int chk2_fail = 0;

  function new(string name = "apci_tlp_sb", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // axi_mon_cb is a uvm_object registered by the test in connect_phase; nothing to build here.
  endfunction

  function void write_axi_mon(svt_axi_transaction t);
    if (!check_enabled) return;  // ignore all traffic until enumeration is done
    if      (t.xact_type == svt_axi_transaction::WRITE) axi_wr_q.push_back(t);
    else if (t.xact_type == svt_axi_transaction::READ)  axi_rd_q.push_back(t);
  endfunction

virtual task expected_write_data();
      forever begin
        svt_axi_transaction exp_wr_txn;
        bit [63:0] wr_addr;
        wait(axi_wr_q.size() > 0);
        exp_wr_txn = axi_wr_q.pop_front();
        wr_addr = exp_wr_txn.addr;
        for (int dw = 0; dw < exp_wr_txn.burst_length * 4; dw++) begin
          exp_wr_data_mem[wr_addr] = exp_wr_txn.data[dw/4][dw%4 * 32 +: 32];
          wr_addr += 4;
        end
      end
endtask

virtual task write_data_check();
      forever begin
	bit [63:0] act_addr;
        mwr_data_t act_wr_tx;
        wait(mwr_q.size() > 0);
        act_wr_tx = mwr_q.pop_front();
        foreach (act_wr_tx.payload[i]) begin
          act_addr = act_wr_tx.addr + i*4;
          if (exp_wr_data_mem.exists(act_addr)) begin
            if (act_wr_tx.payload[i] !== exp_wr_data_mem[act_addr]) begin
              `uvm_error("axi_apci_tlp_sb", $sformatf("Check1 MWr MISMATCH @ 0x%016h[DW%0d]: got 0x%08h  exp 0x%08h", act_addr, i, act_wr_tx.payload[i], exp_wr_data_mem[act_addr]))
              chk1_fail++;
            end else begin
              `uvm_info("axi_apci_tlp_sb", $sformatf("Check1 PASS MWr @ 0x%016h[DW%0d] = 0x%08h", act_addr, i, act_wr_tx.payload[i]), UVM_LOW)
              chk1_pass++;
            end
          end else begin
	  	`uvm_error("axi_apci_tlp_sb", $sformatf("Check1 addr received from AXI wr txn doesn't match with addr in VIP"))
	  end
        end
      end
endtask

virtual task read_data_check();
      forever begin
        svt_axi_transaction act_rd_t;
        bit [63:0]  cpl_addr;
        bit [63:0]  exp_rd_addr;
        bit [31:0]  act_rd_data;
        int         cpl_size;
        int         no_addr_match;

        wait(axi_rd_q.size() > 0);
        act_rd_t = axi_rd_q.pop_front();
        no_addr_match = 0;
        cpl_size      = cpl_addr_q.size();
        for (int j = 0; j < cpl_size; j++) begin
          if (act_rd_t.addr == cpl_addr_q[j]) begin
            cpl_addr = cpl_addr_q[j];
            cpl_addr_q.delete(j);
            break;
          end else begin
            no_addr_match++;
          end
        end

        if (no_addr_match == cpl_size)
          `uvm_error("axi_apci_tlp_sb", $sformatf(
            "Check2: No CplD address match for AXI rd addr=0x%016h (cpl_addr_q size=%0d)",
            act_rd_t.addr, cpl_size))

        exp_rd_addr = cpl_addr;
        for (int dw = 0; dw < act_rd_t.burst_length * 4; dw++) begin
          act_rd_data = act_rd_t.data[dw/4][dw%4 * 32 +: 32];
          if (exp_wr_data_mem.exists(exp_rd_addr)) begin
            if (act_rd_data !== exp_wr_data_mem[exp_rd_addr]) begin
              `uvm_error("axi_apci_tlp_sb", $sformatf("Check2 AXI/RdData MISMATCH @ 0x%016h[DW%0d]: axi=0x%08h  exp=0x%08h", exp_rd_addr, dw, act_rd_data, exp_wr_data_mem[exp_rd_addr]))
              chk2_fail++;
            end else begin
              `uvm_info("axi_apci_tlp_sb", $sformatf("Check2 PASS AXI/RdData @ 0x%016h[DW%0d] = 0x%08h", exp_rd_addr, dw, act_rd_data), UVM_LOW)
              chk2_pass++;
            end
            exp_wr_data_mem.delete(exp_rd_addr);
          end
          exp_rd_addr += 4;
        end
      end
endtask

  virtual task run_phase(uvm_phase phase);
    fork
      // Thread 1: unpack AXI write transaction beats into wr_data_mem[].
      expected_write_data();
      // Thread 2: Check 1 — MWr TLP payload vs wr_data_mem[].
      write_data_check();
      // Thread 3: Check 2 — AXI rd base address vs PCIe CplD address,
      read_data_check();
    join_none
  endtask

  virtual function void write(apci_tlp t);
    if (t.is_cpl()) write_rsp(t);
    else            write_req(t);
  endfunction

  virtual function void write_req(apci_tlp t);
    string     msg;
    bit [63:0] tlp_addr;
    bit [11:0] tlp_tag;
    req_count++;

    // ---- Flit-mode decode ----
    if (t.is_flit_mode) begin
      if (t.is_mem32()) begin
        msg = {msg, $sformatf("\n Type:Flit Memory 32-bit")};
        msg = {msg, $sformatf("\n Address: 0x%08h",  t.u.fm_mem32.addr)};
        msg = {msg, $sformatf("\n Length: %0d DW",   t.u.fm_mem32.length)};
        msg = {msg, $sformatf("\n Tag: 0x%03h",      t.u.fm_mem32.tag)};
        msg = {msg, $sformatf("\n ReqID: 0x%04h",    t.u.fm_mem32.req_id)};
        tlp_addr = {32'h0, t.u.fm_mem32.addr};
        tlp_tag  = t.u.fm_mem32.tag;
      end
      else if (t.is_mem64()) begin
        msg = {msg, $sformatf("\n Type:Flit Memory 64-bit")};
        msg = {msg, $sformatf("\n Address: 0x%016h", t.u.fm_mem64.addr)};
        msg = {msg, $sformatf("\n Length: %0d DW",   t.u.fm_mem64.length)};
        msg = {msg, $sformatf("\n Tag: 0x%03h",      t.u.fm_mem64.tag)};
        msg = {msg, $sformatf("\n ReqID: 0x%04h",    t.u.fm_mem64.req_id)};
        tlp_addr = t.u.fm_mem64.addr;
        tlp_tag  = t.u.fm_mem64.tag;
      end
      else if (t.is_request()) begin
        msg = {msg, $sformatf("\n Type:Flit Request (generic)")};
        msg = {msg, $sformatf("\n Length: %0d DW",   t.u.fm_req.length)};
      end
    end
    // ---- Standard (non-flit) decode ----
    else begin
      if (t.is_mem32()) begin
        msg = {msg, $sformatf("\n Type: Memory 32-bit")};
        msg = {msg, $sformatf("\n Address: 0x%08h",  t.u.mem32.addr)};
        msg = {msg, $sformatf("\n Length: %0d DW",   t.u.mem32.length)};
        msg = {msg, $sformatf("\n First BE: 0x%h",   t.u.mem32.fbe)};
        msg = {msg, $sformatf("\n Last BE: 0x%h",    t.u.mem32.lbe)};
        msg = {msg, $sformatf("\n Tag: 0x%03h",      t.u.mem32.tag)};
        msg = {msg, $sformatf("\n ReqID: 0x%04h",    t.u.mem32.req_id)};
        tlp_addr = {32'h0, t.u.mem32.addr};
        tlp_tag  = t.u.mem32.tag;
      end
      else if (t.is_mem64()) begin
        msg = {msg, $sformatf("\n Type: Memory 64-bit")};
        msg = {msg, $sformatf("\n Address: 0x%016h", t.u.mem64.addr)};
        msg = {msg, $sformatf("\n Length: %0d DW",   t.u.mem64.length)};
        msg = {msg, $sformatf("\n First BE: 0x%h",   t.u.mem64.fbe)};
        msg = {msg, $sformatf("\n Last BE: 0x%h",    t.u.mem64.lbe)};
        msg = {msg, $sformatf("\n Tag: 0x%03h",      t.u.mem64.tag)};
        msg = {msg, $sformatf("\n ReqID: 0x%04h",    t.u.mem64.req_id)};
        tlp_addr = t.u.mem64.addr;
        tlp_tag  = t.u.mem64.tag;
      end
      else if (t.is_request()) begin
        msg = {msg, $sformatf("\n Type: Request (generic)")};
        msg = {msg, $sformatf("\n Length: %0d DW",   t.u.req.length)};
      end
    end

    // ---- Payload dump ----
    if (t.payload.size() > 0) begin
      msg = {msg, $sformatf("\n--- Formatted Payload (%0d DW = %0d bytes) ---", t.payload.size(), t.payload.size()*4)};
      for (int i = 0; i < t.payload.size(); i++) begin
        if (i % 4 == 0)
          msg = {msg, $sformatf("\n  [%04d]:", i)};
        msg = {msg, $sformatf(" %08h", t.payload[i])};
      end
    end
    `uvm_info("axi_apci_tlp_sb", msg, UVM_MEDIUM)

    // MWr — decode into mwr_q[] for Check 1
    if (t.kind == APCI_TLP_mwr) begin
      mwr_data_t mem_wr_vip;
      mem_wr_vip.addr    = tlp_addr;
      mem_wr_vip.payload = t.payload;  
      mwr_q.push_back(mem_wr_vip);
    end
    // MRd — register tag→addr for Check 2
    else if (t.kind == APCI_TLP_mrd) begin
      mrd_tag_to_addr[tlp_tag] = tlp_addr;
      `uvm_info("axi_apci_tlp_sb", $sformatf("MRd pending: tag=0x%03h addr=0x%016h", tlp_tag, tlp_addr), UVM_LOW)
    end
  endfunction

  virtual function void write_rsp(apci_tlp t);
    string     msg;
    bit [11:0] cpl_tag;
    rsp_count++;

    // ---- Flit-mode decode ----
    if (t.is_flit_mode) begin
      if (t.is_cpl()) begin
        msg = {msg, $sformatf("\n Type:Flit Completion")};
        msg = {msg, $sformatf("\n Tag: 0x%03h",   t.u.fm_cpl.tag)};
        msg = {msg, $sformatf("\n CplID: 0x%04h", t.u.fm_cpl.cpl_id)};
        msg = {msg, $sformatf("\n BDF: %0d",       t.u.fm_cpl.dest_bdf)};
        cpl_tag = t.u.fm_cpl.tag;
      end
    end
    // ---- Standard (non-flit) decode ----
    else begin
      if (t.is_cpl()) begin
        msg = {msg, $sformatf("\n Type: Completion")};
        msg = {msg, $sformatf("\n Tag: 0x%03h",   t.u.cpl.tag)};
        msg = {msg, $sformatf("\n ReqID: 0x%04h", t.u.cpl.req_id)};
        msg = {msg, $sformatf("\n CplID: 0x%04h", t.u.cpl.cpl_id)};
        cpl_tag = t.u.cpl.tag;
      end
    end

    // ---- Payload dump ----
    if (t.payload.size() > 0) begin
      msg = {msg, $sformatf("\n--- Formatted Payload (%0d DW = %0d bytes) ---", t.payload.size(), t.payload.size()*4)};
      for (int i = 0; i < t.payload.size(); i++) begin
        if (i % 4 == 0)
          msg = {msg, $sformatf("\n  [%04d]:", i)};
        msg = {msg, $sformatf(" %08h", t.payload[i])};
      end
    end
    `uvm_info("axi_apci_tlp_sb", msg, UVM_MEDIUM)

    if (mrd_tag_to_addr.exists(cpl_tag)) begin
      cpl_addr_q.push_back(mrd_tag_to_addr[cpl_tag]);
      `uvm_info("axi_apci_tlp_sb", $sformatf("CplD: tag=0x%03h addr=0x%016h forwarded to Check 2", cpl_tag, mrd_tag_to_addr[cpl_tag]), UVM_LOW)
      mrd_tag_to_addr.delete(cpl_tag);
    end
  endfunction

  // ---------------------------------------------------------------------------
  // check_phase — verify no stale state remains after run_phase ends
  // ---------------------------------------------------------------------------
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (exp_wr_data_mem.size() != 0)
      `uvm_warning("axi_apci_tlp_sb", $sformatf("check_phase: %0d exp_wr_data_mem entries never consumed by Check 2 (missing AXI rd burst)", exp_wr_data_mem.size()))
    if (mrd_tag_to_addr.size() != 0)
      `uvm_warning("axi_apci_tlp_sb", $sformatf("check_phase: %0d MRd(s) never received a CplD response (tag leak)", mrd_tag_to_addr.size()))
    if (mwr_q.size() != 0)
      `uvm_warning("axi_apci_tlp_sb", $sformatf("check_phase: %0d MWr TLP(s) in mwr_q never consumed by Thread 2", mwr_q.size()))
    if (cpl_addr_q.size() != 0)
      `uvm_warning("axi_apci_tlp_sb", $sformatf("check_phase: %0d CplD address(es) in cpl_addr_q never consumed by Thread 3", cpl_addr_q.size()))
    if (axi_wr_q.size() != 0)
      `uvm_warning("axi_apci_tlp_sb", $sformatf("check_phase: %0d AXI wr transaction(s) in axi_wr_q never consumed by Thread 1", axi_wr_q.size()))
    if (axi_rd_q.size() != 0)
      `uvm_warning("axi_apci_tlp_sb", $sformatf("check_phase: %0d AXI rd transaction(s) in axi_rd_q never consumed by Thread 3", axi_rd_q.size()))
  endfunction

  // ---------------------------------------------------------------------------
  // report_phase — summary statistics only, no functional checks
  // ---------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("axi_apci_tlp_sb", $sformatf(
      "\n=== Summary ===\n  Requests seen : %0d  |  Responses seen: %0d\n  Check1 (MWr TLP vs exp_wr_data_mem) — PASS: %0d  FAIL: %0d\n  Check2 (AXI rd  vs WrData)      — PASS: %0d  FAIL: %0d", req_count, rsp_count, chk1_pass, chk1_fail, chk2_pass, chk2_fail), UVM_NONE)
  endfunction

endclass
