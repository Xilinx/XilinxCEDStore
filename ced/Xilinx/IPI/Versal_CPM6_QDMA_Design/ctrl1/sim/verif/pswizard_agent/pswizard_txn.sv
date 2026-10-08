// pswizard_txn.sv — UVM transaction for the pswizard interface monitor
//
// Captures AXI handshake events on CPM_PCIE_AXI_NOC0 and NOC1 plus DMA IRQ
// assertions.  Events observed:
//   PSW_NOC_AW  — AW-channel handshake (awvalid & awready)
//   PSW_NOC_W   — W last beat          (wvalid  & wready  & wlast)
//   PSW_NOC_B   — B-channel handshake  (bvalid  & bready)
//   PSW_NOC_AR  — AR-channel handshake (arvalid & arready)
//   PSW_NOC_R   — R last beat          (rvalid  & rready  & rlast)
//   PSW_DMA_IRQ — any newly-asserted bit in dma_irq[127:0]
//   PSW_RESET   — rst_n de-assertion
class pswizard_txn extends uvm_sequence_item;

  `uvm_object_utils(pswizard_txn)

  typedef enum logic [3:0] {
    PSW_NOC_AW,    // Write address handshake
    PSW_NOC_W,     // Write last-beat handshake
    PSW_NOC_B,     // Write response handshake
    PSW_NOC_AR,    // Read address handshake
    PSW_NOC_R,     // Read last-beat handshake
    PSW_DMA_IRQ,   // DMA completion IRQ assertion
    PSW_RESET,     // rst_n de-assertion
    // cpm_axi_pl0/1/3 events (added for cross-correlation with PSW_DMA_IRQ in
    // the same log stream — observation only, no BRESP/RRESP/BW_CYC/
    // THROUGHPUT checks on these ports; no PL2 (does not exist on this BD);
    // PL3 gated behind `ENABLE_PL3_BIND)
    PSW_PL_AW,
    PSW_PL_W,
    PSW_PL_B,
    PSW_PL_AR,
    PSW_PL_R
  } psw_txn_type_e;

  psw_txn_type_e txn_type;

  // NOC port (0 = CPM_PCIE_AXI_NOC0, 1 = CPM_PCIE_AXI_NOC1)
  // Unused for PSW_RESET.
  logic         port;

  // cpm_axi_pl port (0, 1, or 3 — see PSW_PL_* note above). Unused otherwise.
  logic [2:0]   pl_port;

  // ---- AW / AR fields (PSW_NOC_AW, PSW_NOC_AR) ----
  logic [63:0]  addr;       // awaddr / araddr
  logic [15:0]  id;         // awid   / arid
  logic [7:0]   len;        // awlen  / arlen (burst length)
  logic [2:0]   size;       // awsize / arsize
  logic [1:0]   burst;      // awburst/ arburst
  longint unsigned bytes;   // (len+1)<<size burst estimate; write-side WSTRB-accurate
                            // total (on wlast) is added on top of this in the W log line
  // HDMA channel decoded from addr/SLOT_SIZE_BYTES (dsc_slot_params_pkg) — PSW_NOC_AW/AR
  // (NOC0 only, per user scope) and PSW_PL_AW/AR (PL0/1/3). '1 = not decoded (e.g. NOC1).
  logic [6:0]   chan;
  bit           chan_valid;

  // ---- W fields (PSW_NOC_W) ----
  logic [15:0]  wstrb_np;   // wstrb non-empty beats — upper 16-bit strobe snapshot
  longint unsigned w_bytes; // $countones(full wstrb) on this beat (only meaningful when wlast)

  // ---- B fields (PSW_NOC_B) ----
  logic [15:0]  bid;
  logic [1:0]   bresp;

  // ---- R fields (PSW_NOC_R) ----
  logic [15:0]  rid;
  logic [1:0]   rresp;

  // ---- IRQ fields (PSW_DMA_IRQ) ----
  logic [127:0] irq_new;    // newly-asserted IRQ bits (edge-detect result)

  // Simulation timestamp
  time          timestamp_ns;

  function new(string name = "pswizard_txn");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    pswizard_txn t;
    super.do_copy(rhs);
    if (!$cast(t, rhs))
      `uvm_fatal("pswizard_txn", "do_copy: cast failed")
    txn_type     = t.txn_type;
    port         = t.port;
    pl_port      = t.pl_port;
    addr         = t.addr;
    id           = t.id;
    len          = t.len;
    size         = t.size;
    burst        = t.burst;
    bytes        = t.bytes;
    chan         = t.chan;
    chan_valid   = t.chan_valid;
    wstrb_np     = t.wstrb_np;
    w_bytes      = t.w_bytes;
    bid          = t.bid;
    bresp        = t.bresp;
    rid          = t.rid;
    rresp        = t.rresp;
    irq_new      = t.irq_new;
    timestamp_ns = t.timestamp_ns;
  endfunction

  virtual function string convert2string();
    string s;
    s = $sformatf("[%0t ns] PSW %s", timestamp_ns, txn_type.name());
    case (txn_type)
      PSW_NOC_AW, PSW_NOC_AR:
        s = {s, $sformatf(" noc%0d addr=0x%016h id=0x%04h len=%0d sz=%0d brst=%0d bytes_est=%0d%s",
                port, addr, id, len, size, burst, bytes,
                chan_valid ? $sformatf(" ch=%0d", chan) : "")};
      PSW_NOC_W:
        s = {s, $sformatf(" noc%0d wstrb[31:16]=0x%04h w_bytes=%0d", port, wstrb_np, w_bytes)};
      PSW_NOC_B:
        s = {s, $sformatf(" noc%0d bid=0x%04h resp=%0d", port, bid, bresp)};
      PSW_NOC_R:
        s = {s, $sformatf(" noc%0d rid=0x%04h resp=%0d", port, rid, rresp)};
      PSW_DMA_IRQ:
        s = {s, $sformatf(" irq_new=0x%032h", irq_new)};
      PSW_RESET:
        s = {s, " rst_n deasserted"};
      PSW_PL_AW, PSW_PL_AR:
        s = {s, $sformatf(" pl%0d addr=0x%016h id=0x%04h len=%0d sz=%0d brst=%0d bytes_est=%0d%s",
                pl_port, addr, id, len, size, burst, bytes,
                chan_valid ? $sformatf(" ch=%0d", chan) : "")};
      PSW_PL_W:
        s = {s, $sformatf(" pl%0d wstrb[31:16]=0x%04h w_bytes=%0d", pl_port, wstrb_np, w_bytes)};
      PSW_PL_B:
        s = {s, $sformatf(" pl%0d bid=0x%04h resp=%0d", pl_port, bid, bresp)};
      PSW_PL_R:
        s = {s, $sformatf(" pl%0d rid=0x%04h resp=%0d", pl_port, rid, rresp)};
    endcase
    return s;
  endfunction

endclass
