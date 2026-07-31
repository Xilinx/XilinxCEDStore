// cxl_cm_reg_cb: CXL Component Register Callback
//
// Registered on the Avery VIP when it acts as a CXL Type-3 EP.
// Modelled after the cxl_ep_cb + ep_storage_cb pattern from the Avery
// VIP sandbox test (test_cxlmem.sv / test_base.sv).
//
// Responsibilities:
//   1. Track CfgWr to BAR3/BAR4 to capture the 64-bit Component Register
//      BAR base.  When BAR4 is finalised, call load_cxl_cm_regs() to
//      populate the shadow memory (mem[]) with the CXL capability array.
//   2. read_mem_cb / write_mem_cb:  shadow memory that the Avery VIP calls
//      for MemRd/MemWr TLPs directed at the EP's BAR space.
//   3. Intercept MemWr that sets the Commit bit (bit 9) of any HDM Decoder
//      Control register.  Fork a process that waits for write_mem_cb to
//      land the write in mem[], then back-door sets Committed (bit 10).
//   4. setup_mmio_reg: minimal override (disable unused MMIO caps) matching
//      the reference test pattern.
//
// Shadow memory layout (relative to arr_base = bar_base + 0x1000):
//
//   offset   content
//   ------   -------
//   +0x000   Array Header  (cap_id=1, cap_ver=1, cm_ver=1, 3 entries)
//   +0x004   RAS  cap entry (id=2, ver=3, ptr=0x100)
//   +0x008   Link cap entry (id=4, ver=4, ptr=0x200)
//   +0x00C   HDM  cap entry (id=5, ver=3, ptr=0x250)  ← found by enum
//
//   +0x250   HDM Decoder Capability (at ptr 0x250 from arr_base):
//     +0x00  cap   (decoder_count[3:0]=0 → 1 decoder; coherency[22:21]=2)
//     +0x04  global_ctl
//     +0x08  rsvd0
//     +0x0C  rsvd1
//     Decoder N at +0x10 + N*0x20:
//       +0x00 base_lo  +0x04 base_hi
//       +0x08 size_lo  +0x0C size_hi
//       +0x10 ctl      (bit9=Commit W1S, bit10=Committed RO)
//
// Dependencies: apci_pkg (apci_callbacks, apci_device, apci_mmio_reg,
//               apci_tlp, avery_data_base)

class cxl_cm_reg_cb extends apci_callbacks;

  const string id = "CXL_CM_REG_CB";

  // -------------------------------------------------------------------------
  // BAR3/BAR4 tracking (64-bit Component Register BAR)
  //   BAR3 → lower 32 bits (config offset 0x1C, reg_no = 7)
  //   BAR4 → upper 32 bits (config offset 0x20, reg_no = 8)
  // -------------------------------------------------------------------------
  bit [63:0] bar_base;        // 64-bit base once host programs BAR3/BAR4
  bit        bar_base_valid;  // set when BAR4 upper half is written non-all-1s

  // -------------------------------------------------------------------------
  // CXL Capability Array header + per-capability pointer DWORDs
  //   Format of each DWORD (same as CXL spec Table 8-17):
  //     [15:0]  = CXL Capability ID
  //     [19:16] = CXL Capability Version
  //     [31:20] = Pointer (byte offset from arr_base)
  // -------------------------------------------------------------------------
  struct {
    bit [31:0] hdr;         // Array header DWORD (id=1)
    bit [31:0] cxl_ras;    // RAS  cap entry    (id=2)
    bit [31:0] cxl_link;   // Link cap entry    (id=4)
    bit [31:0] cxl_hdm_dec;// HDM  cap entry    (id=5)
  } cap_hdr;

  // -------------------------------------------------------------------------
  // HDM Decoder Capability register image
  //   Only the fields written/read by the enumeration firmware are tracked.
  // -------------------------------------------------------------------------
  struct {
    bit [31:0] cap;        // offset +0x00: decoder_count[3:0], coherency[22:21]
    bit [31:0] global_ctl; // offset +0x04
  } hdm_dec;

  // -------------------------------------------------------------------------
  // Shadow memory — the VIP calls read_mem_cb / write_mem_cb for every
  // MemRd / MemWr TLP directed at the EP's BAR space.
  // -------------------------------------------------------------------------
  bit [31:0] mem[bit [63:0]];
  string     default_rsp = "ZEROES";

  // =========================================================================
  // Constructor — initialise capability structures to sensible defaults
  // =========================================================================
  function new();
    init_cxl_cm_regs();
  endfunction

  // =========================================================================
  // init_cxl_cm_regs
  //   Initialise the capability-array and HDM-decoder struct fields.
  //   Matches init_cxl_cm_regs() in test_cxlmem.sv (vip_sandbox reference).
  // =========================================================================
  function void init_cxl_cm_regs();
    // Array header: CXL Cap ID=1, Cap Ver=1, CXL.cache+mem Ver=1, 3 entries
    //   {4'd3 (entries in [27:24]), 4'd1 (cm_ver in [23:20]),
    //    4'd1 (cap_ver in [19:16]), 16'd1 (cap_id in [15:0])}
    //   → 28-bit value zero-extended to 32 bits
    cap_hdr.hdr         = {4'd3, 4'd1, 4'd1, 16'd1};
    // Capability entries: {ptr[31:20], ver[19:16], id[15:0]}
    cap_hdr.cxl_ras     = {12'h100, 4'd3, 16'd2}; // RAS  (id=2) at offset 0x100
    cap_hdr.cxl_link    = {12'h200, 4'd4, 16'd4}; // Link (id=4) at offset 0x200
    cap_hdr.cxl_hdm_dec = {12'h250, 4'd3, 16'd5}; // HDM  (id=5) at offset 0x250
    // HDM Decoder Capability header
    //   decoder_count[3:0] = 0 → 1 decoder
    //   coherency[22:21]   = 2b10 → Bi-directional coherency supported
    hdm_dec.cap        = (2'b10 << 21) | (4'h0 << 0);
    hdm_dec.global_ctl = '0;
    `uvm_info(id, "init_cxl_cm_regs: capability structs initialised", UVM_LOW)
  endfunction

  // =========================================================================
  // load_cxl_cm_regs
  //   Populate the shadow memory (mem[]) with the CXL Component Register
  //   Capability Array once bar_base is known.
  //   Matches load_cxl_cm_regs() in test_cxlmem.sv.
  // =========================================================================
  function void load_cxl_cm_regs();
    bit [63:0] arr_base;
    bit [63:0] hdm_base;
    arr_base = bar_base + 'h1000;
    hdm_base = arr_base + cap_hdr.cxl_hdm_dec[31:20]; // = arr_base + 0x250

    // --- Capability Array (header + 3 entries at +0x0 to +0xC) ---
    mem[arr_base + 'h0] = cap_hdr.hdr;
    mem[arr_base + 'h4] = cap_hdr.cxl_ras;
    mem[arr_base + 'h8] = cap_hdr.cxl_link;
    mem[arr_base + 'hC] = cap_hdr.cxl_hdm_dec;

    // --- HDM Decoder Capability (cap header at hdm_base + 0x00) ---
    mem[hdm_base + 'h00] = hdm_dec.cap;
    mem[hdm_base + 'h04] = hdm_dec.global_ctl;
    mem[hdm_base + 'h08] = '0; // rsvd0
    mem[hdm_base + 'h0C] = '0; // rsvd1
    // Decoder 0 registers at hdm_base + 0x10
    mem[hdm_base + 'h10] = '0; // base_lo  (will be overwritten by DUT)
    mem[hdm_base + 'h14] = '0; // base_hi
    mem[hdm_base + 'h18] = '0; // size_lo
    mem[hdm_base + 'h1C] = '0; // size_hi
    mem[hdm_base + 'h20] = '0; // ctl (Commit=0, Committed=0)

    `uvm_info(id, $sformatf(
      "load_cxl_cm_regs: arr_base=0x%0h  hdm_cap_base=0x%0h",
      arr_base, hdm_base), UVM_LOW)
  endfunction

  // =========================================================================
  // setup_mmio_reg  (apci_callbacks override)
  //   Minimal: disable unused MMIO capabilities.
  //   Matches setup_mmio_reg() in cxl_ep_cb (test_cxlmem.sv reference).
  // =========================================================================
  virtual function void setup_mmio_reg(apci_device bfm, apci_mmio_reg mmreg);
    `uvm_info(id, "setup_mmio_reg: disabling unused MMIO caps (cpmu, chmu)", UVM_LOW)
    mmreg.cxl_cpmu_reg_if = null;
    mmreg.cxl_chmu_reg_if = null;
  endfunction

  // =========================================================================
  // rx_pkt_enter_tl  (apci_callbacks override)
  //   1. Track CfgWr to BAR3/BAR4; call load_cxl_cm_regs() when BAR4 is
  //      finalised (non-all-ones value written to the upper half).
  //   2. Detect MemWr setting Commit (bit 9) on any HDM Decoder Control
  //      register; fork a process that waits for write_mem_cb to land the
  //      data in mem[], then back-door sets Committed (bit 10).
  // =========================================================================
  virtual function void rx_pkt_enter_tl(apci_device bfm, apci_tlp tlp);
    bit [31:0]  wdata;
    bit [ 3:0]  wstrb;
    bit [63:16] waddr_u;
    bit [15: 0] waddr;
    bit [15: 0] hdm_dec_base;
    string      msg;

    // -----------------------------------------------------------------------
    // CfgWr: track BAR3 (reg_no=7 = 0x1C>>2) and BAR4 (reg_no=8 = 0x20>>2)
    // -----------------------------------------------------------------------
    if (tlp.kind == APCI_TLP_cfgwr0) begin
      if (tlp.is_flit_mode) begin
        case (1'b1)
          (tlp.u.fm_cfg.reg_no == ('h1C >> 2)) : bar_base[31: 0] = tlp.payload[0];
          (tlp.u.fm_cfg.reg_no == ('h20 >> 2)) : bar_base[63:32] = tlp.payload[0];
        endcase
        if (tlp.u.fm_cfg.reg_no == ('h20 >> 2) && tlp.payload[0] != '1) begin
          bar_base_valid = 1'b1;
          `uvm_info(id, $sformatf(
            "BAR3/4 finalised: bar_base=0x%0h  arr_base=0x%0h  hdm_cap_base=0x%0h",
            bar_base, bar_base+'h1000,
            bar_base+'h1000+cap_hdr.cxl_hdm_dec[31:20]), UVM_LOW)
          load_cxl_cm_regs();
        end
      end
      else begin
        case (1'b1)
          (tlp.u.cfg.reg_no == ('h1C >> 2)) : bar_base[31: 0] = tlp.payload[0];
          (tlp.u.cfg.reg_no == ('h20 >> 2)) : bar_base[63:32] = tlp.payload[0];
        endcase
        if (tlp.u.cfg.reg_no == ('h20 >> 2) && tlp.payload[0] != '1) begin
          bar_base_valid = 1'b1;
          `uvm_info(id, $sformatf(
            "BAR3/4 finalised: bar_base=0x%0h  arr_base=0x%0h  hdm_cap_base=0x%0h",
            bar_base, bar_base+'h1000,
            bar_base+'h1000+cap_hdr.cxl_hdm_dec[31:20]), UVM_LOW)
          load_cxl_cm_regs();
        end
      end
    end

    // -----------------------------------------------------------------------
    // MemWr: detect Commit bit (bit 9) on an HDM Decoder Control register.
    //   hdm_dec_base = bar_base[15:0] + 0x1000 + ptr (0x250)
    //   Decoder N control is at hdm_dec_base + 0x20 + N*0x20
    //     → offset from hdm_dec_base is a non-zero multiple of 0x20
    //   write_mem_cb will store the write in mem[]; we wait for that
    //   and then back-door set Committed (bit 10) in the shadow.
    // -----------------------------------------------------------------------
    else if (tlp.kind == APCI_TLP_mwr && bar_base_valid) begin
      hdm_dec_base = bar_base[15:0] + 'h1000 + cap_hdr.cxl_hdm_dec[31:20];
      if (tlp.is_flit_mode) begin
        wdata   = tlp.payload[0];
        wstrb   = tlp.u.fm_com.ohc[0] ? tlp.ohc[0].ohc_a1.fbe : '0;
        waddr_u = tlp.u.fm_mem64.addr.dw_addr[63:16];
        waddr   = tlp.u.fm_mem64.addr.dw_addr[15:2] << 2;
      end
      else begin
        wdata   = tlp.payload[0];
        wstrb   = tlp.u.mem64.fbe;
        waddr_u = tlp.u.mem64.addr.dw_addr[63:16];
        waddr   = tlp.u.mem64.addr.dw_addr[15:2] << 2;
      end
      if (waddr_u == bar_base[63:16]) begin
        if (!((waddr - hdm_dec_base) % 'h20) &&
            (waddr - hdm_dec_base) != 0       &&
            wstrb[1] && wdata[9])
        begin
          msg = $sformatf("DUT set Commit on HDM Decoder %0d at addr=0x%0h",
                           (waddr - hdm_dec_base) / 'h20, {waddr_u, waddr});
          `uvm_info(id, msg, UVM_LOW)
          // Fork: wait for write_mem_cb to land the data in mem[], then
          // back-door set Committed (bit 10) — same pattern as test_cxlmem.sv.
          fork
            begin
              automatic bit [63:0] ctl_addr = {waddr_u, waddr};
              wait(mem[ctl_addr][9] == 1'b1);
              `uvm_info(id, $sformatf(
                "Backdoor setting Committed for HDM Decoder at 0x%0h", ctl_addr), UVM_LOW)
              mem[ctl_addr][10] = 1'b1;
            end
          join_none
        end
      end
    end
  endfunction

  // =========================================================================
  // read_mem_cb  (apci_callbacks override)
  //   Serve MemRd completions from the shadow memory.
  //   Uninitialized addresses return default_rsp (ZEROES).
  // =========================================================================
  virtual function void read_mem_cb(
    input bit          is_host_mem,
    input bit [63:0]   addr,
    input bit [31:0]   ndw,
    input bit [ 3:0]   first_be,
    input bit [ 3:0]   last_be,
    ref   bit [31:0]   va[],
    input avery_data_base src
  );
    `uvm_info(id, $sformatf("read_mem_cb addr=0x%0h ndw=%0d fbe=0x%h lbe=0x%h",
                             addr, ndw, first_be, last_be), UVM_LOW)
    for (int ii = 0; ii < int'(ndw); ii++) begin
      if (mem.exists(addr + ii*4)) begin
        va[ii] = mem[addr + ii*4];
        `uvm_info(id, $sformatf("  [0x%0h] HIT -> 0x%08h", addr+ii*4, va[ii]), UVM_LOW)
      end
      else begin
        case (default_rsp)
          "ZEROES" : va[ii] = '0;
          "ONES"   : va[ii] = '1;
          "RANDOM" : va[ii] = $urandom;
          default  : va[ii] = '0;
        endcase
        `uvm_info(id, $sformatf("  [0x%0h] MISS -> %0s (0x%08h)",
                                 addr+ii*4, default_rsp, va[ii]), UVM_LOW)
      end
    end
  endfunction

  // =========================================================================
  // write_mem_cb  (apci_callbacks override)
  //   Store MemWr data into the shadow memory (respects byte-enables).
  //   The rx_pkt_enter_tl Commit detector waits on mem[addr][9] which
  //   becomes valid here.
  // =========================================================================
  virtual function void write_mem_cb(
    input bit          is_host_mem,
    input bit [63:0]   addr,
    input bit [ 3:0]   first_be,
    input bit [ 3:0]   last_be,
    ref   bit [31:0]   va[],
    input avery_data_base src
  );
    `uvm_info(id, $sformatf("write_mem_cb addr=0x%0h fbe=0x%h lbe=0x%h ndw=%0d",
                              addr, first_be, last_be, va.size()), UVM_LOW)
    for (int ii = 0; ii < va.size(); ii++) begin
      if (ii == 0) begin
        if (first_be[0]) mem[addr][ 0+:8] = va[0][ 0+:8];
        if (first_be[1]) mem[addr][ 8+:8] = va[0][ 8+:8];
        if (first_be[2]) mem[addr][16+:8] = va[0][16+:8];
        if (first_be[3]) mem[addr][24+:8] = va[0][24+:8];
      end
      else if (ii == va.size() - 1) begin
        if (last_be[0]) mem[addr+ii*4][ 0+:8] = va[ii][ 0+:8];
        if (last_be[1]) mem[addr+ii*4][ 8+:8] = va[ii][ 8+:8];
        if (last_be[2]) mem[addr+ii*4][16+:8] = va[ii][16+:8];
        if (last_be[3]) mem[addr+ii*4][24+:8] = va[ii][24+:8];
      end
      else begin
        mem[addr + ii*4] = va[ii];
      end
    end
    // If Commit (bit 9) was just written to an HDM Decoder Control register,
    // immediately back-door set Committed (bit 10).  This is more reliable than
    // the fork+wait path in rx_pkt_enter_tl which can miss the write in CXL
    // flit mode when OHC byte-enables are absent (wstrb falls back to '0).
    if (bar_base_valid && mem.exists(addr)) begin
      bit [15:0] hdm_dec_base_l;
      bit [15:0] addr_lo;
      hdm_dec_base_l = bar_base[15:0] + 'h1000 + cap_hdr.cxl_hdm_dec[31:20];
      addr_lo        = addr[15:0];
      if (addr[63:16] == bar_base[63:16]        &&
          !((addr_lo - hdm_dec_base_l) % 'h20)  &&
          (addr_lo - hdm_dec_base_l) != 0        &&
          mem[addr][9])
      begin
        `uvm_info(id, $sformatf(
          "write_mem_cb: Backdoor setting Committed for HDM Decoder at 0x%0h",
          addr), UVM_LOW)
        mem[addr][10] = 1'b1;
      end
    end
  endfunction

endclass
