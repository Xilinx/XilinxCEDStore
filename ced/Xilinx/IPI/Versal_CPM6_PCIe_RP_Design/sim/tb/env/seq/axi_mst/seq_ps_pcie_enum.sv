class seq_ps_pcie_enum extends seq_base_ps_axi32;

  `uvm_object_utils(seq_ps_pcie_enum)

  // parent must set
  bit [47:0]  ecam_base;
  bit [ 7:0]  bus_base;
  protected logic ctrlr; //must be set through method

  // sequence will build these
  pcie_device pdev[$];

  function new(string name = "seq_ps_pcie_enum");
    super.new(name);
  endfunction

  // CXL Consortium Vendor ID (used in all CXL DVSEC structures)
  localparam bit [15:0] CXL_VENDID            = 16'h1e98;
  localparam bit [47:0] CTRLR0_IATU_BASE      = 48'hFC28_0000;  // ctrl0 iATU OB region base
  localparam bit [47:0] CTRLR1_IATU_BASE      = 48'hFC68_0000;  // ctrl1 iATU OB region base
  bit            [47:0] CTRLR_IATU_REGION_BASE;                 
  bit            [63:0] IATU_LWR_BASE_ADDR;                 
  bit            [63:0] IATU_LIMIT_ADDR;                 
  bit            [63:0] IATU_TARGET_ADDR;                 

  // --------------
  // Helper members
  // --------------
       bit        dsp_io32;
       bit        dsp_pfmem64;
  rand bit [31:0] io_aper_base;
  rand bit [31:0] mem_aper_base;
  rand bit [63:0] pfmem_aper_base;

  // CXL HDM allocation knobs (host programs these into the device's HDM decoders)
  rand bit [63:0] cxl_mem_base;    // Starting host PA for CXL HDM allocation
       int        cxl_mem_size_mb = 4096; // Per-decoder allocation size in MiB

  constraint c_aper_base_alignment {
    io_aper_base[11:0]    == '0;
    mem_aper_base[19:0]   == '0;
    pfmem_aper_base[19:0] == '0;
    // 32b IO address support or not
    dsp_io32 -> io_aper_base[31:16] == '0;
    // 64b PF Mem address support or not
    dsp_pfmem64 -> pfmem_aper_base[63:32] == '0;
  };

  // CXL HDM base must be 256MiB aligned (minimum HDM decoder granule) and in 48-bit PA space
  constraint c_cxl_mem_alignment {
    cxl_mem_base[27:0]  == '0;
    cxl_mem_base[63:48] == '0;
  };

  typedef struct packed {
    bit        empty;
    bit        ismem;
    bit        is64;  //membar only
    bit        pftch; //membar only
    bit [63:0] sz;
    bit [63:0] bar;
  } temp_bar_s;

  // --------------
  // Helper methods
  // --------------

  function bit [47:0] build_ecam_acc(bit [47:0] base, bit [11:0] off);
    return base+(off[11:2]<<2);
  endfunction

  virtual function cap_s parse_cap(bit [11:0] base, logic [31:0] hdr);
    cap_s        cap;
    bit [3:0]    capver;
    pcie_capid_e capid = pcie_capid_e'(hdr[7:0]);
    // Capabilities are defined from 'h0-'h15, but not all are relevant or
    // valid anymore. Not all capabilities have versions, but will try to
    // grab the ones that do.
    case (capid)
      CAP_PCI_PM : capver = hdr[18:16];
      CAP_PCI_EXP: capver = hdr[19:16];
    endcase
    // Build structure
    parse_cap = '{capid,
                  base,    //base addr
                  capver}; //version (not all caps have)
  endfunction

  virtual function ecap_s parse_ecap(bit [47:0] base, logic [31:0] hdr);
    bit [ 3:0]    ecapver = hdr[19:16];
    pcie_ecapid_e ecapid  = pcie_ecapid_e'(hdr[15:0]);
    // Build array
    parse_ecap = '{ecapid,
                   base,      //base addr
                   ecapver,   //version
                   /* DVSEC info populated on addl. pass */
                   '0, '0, '0, '0}; 
  endfunction

  virtual function void set_ctrlr(bit c);
    ctrlr = c;
    CTRLR_IATU_REGION_BASE = c ? CTRLR1_IATU_BASE : CTRLR0_IATU_BASE;
    IATU_LWR_BASE_ADDR     = 64'hfc280408 + (c*'h40_0000);
    IATU_LIMIT_ADDR        = 64'hfc280410 + (c*'h40_0000);
    IATU_TARGET_ADDR       = 64'hfc280414 + (c*'h40_0000);

  endfunction


  virtual task pre_body();
    if (ctrlr===1'bx)
      `uvm_fatal(get_type_name, "Must call method 'set_ctrlr(<n>)' before sequence is ran")
  endtask

  // --------------
  // Sequence body
  // --------------

  virtual task body;
    cap_s           cap;
    logic [31:0]    rdat,          wdat;
    pcie_device     dsp,           usp;
    bit   [47:0]    dsp_ecam_base, usp_ecam_base;
    bit             bme, mse, iose;
    int             retry_cnt;
    // --------------- //
    /* Downstream Port */
    // --------------- //
    
    dsp_ecam_base = ecam_base+(bus_base<<20);
    dsp = pcie_device::type_id::create("dsp");
    // CfgSpc 0x0 | {Device ID, Vendor ID}
    retry_cnt = 0;
    do begin
      axi_rd(build_ecam_acc(dsp_ecam_base,'h0), rdat);
      if (rdat inside {'1, '0}) begin
        `uvm_info(get_type_name, $sformatf("Invalid Device ID/Vendor ID=0x%h read from Downstream Port (RP), retrying...", rdat), UVM_MEDIUM)
        retry_cnt++;
      end
      else if (retry_cnt==5)
        `uvm_fatal(get_type_name, $sformatf("Failed to read valid Device ID/Vendor ID from Downstream Port (RP) after %0d retries", retry_cnt));
    end while (rdat inside {'1, '0});
    {dsp.deviceid, dsp.vendorid} = rdat; 
    // CfgSpc 0x8 | {Class Code, Revision ID}
    axi_rd(build_ecam_acc(dsp_ecam_base,'h8), rdat);
    dsp.class_code = rdat[31:8]; 
    // CfgSpc 0x18 | {N/A, Sub Bus#, Sec Bus#, Pri Bus#}
    axi_wr(build_ecam_acc(dsp_ecam_base,'h18), {8'h0, {2{bus_base+1}}, bus_base});
    dsp.primary_bus   = bus_base;
    dsp.secondary_bus = bus_base+1;
    dsp.subord_bus    = bus_base+1;
    // CfgSpc 0x2C | {Subsys ID, Subsys Vendor ID}
    axi_rd(build_ecam_acc(dsp_ecam_base,'h2c), rdat);
    {dsp.subsys_id, dsp.subsys_vendorid} = rdat;
    // Capabilities Linked List
    get_caps(dsp_ecam_base, dsp);
    // Get the Device/Port Type 
    if (!dsp.get_cap(CAP_PCI_EXP, cap))
      `uvm_fatal(get_type_name, "PCIe Express Capability structure not found in Downstream Port")
    axi_rd(build_ecam_acc(dsp_ecam_base,cap.base), rdat);
    dsp.ptype = amd_devport_t'(rdat[23:20]);
    // Ext. Capabilities Linked List
    get_ecaps(dsp_ecam_base, dsp);
    // --------------- //
    /* Upstream Port */
    // - Support multiple PFs
    // - Add VF support
    // --------------- //
    usp_ecam_base = dsp_ecam_base+(1'b1<<20);
    usp = pcie_device::type_id::create("usp");
    // CfgSpc 0x0 | {Device ID, Vendor ID}
    retry_cnt = 0;
    do begin
      axi_rd(build_ecam_acc(usp_ecam_base,'h0), rdat);
      if (rdat inside {'1, '0}) begin
        `uvm_info(get_type_name, $sformatf("Invalid Device ID/Vendor ID=0x%h read from Upstream Port (EP), retrying...", rdat), UVM_MEDIUM)
        retry_cnt++;
      end
      else if (retry_cnt==5)
        `uvm_fatal(get_type_name, $sformatf("Failed to read valid Device ID/Vendor ID from Upstream Port (EP) after %0d retries", retry_cnt));
    end while (rdat inside {'1, '0});
    {usp.deviceid, usp.vendorid} = rdat; 
    // CfgSpc 0x8 | {Class Code, Revision ID}
    axi_rd(build_ecam_acc(usp_ecam_base,'h8), rdat);
    usp.class_code = rdat[31:8]; 
    // CfgSpc 0x2C | {Subsys ID, Subsys Vendor ID}
    axi_rd(build_ecam_acc(usp_ecam_base,'h2c), rdat);
    {usp.subsys_id, usp.subsys_vendorid} = rdat;
    // Capabilities Linked List
    get_caps(usp_ecam_base, usp);
    // Get the Device/Port Type 
    if (!usp.get_cap(CAP_PCI_EXP, cap))
      `uvm_fatal(get_type_name, "PCIe Express Capability structure not found in Upstream Port")
    axi_rd(build_ecam_acc(usp_ecam_base,cap.base), rdat);
    usp.ptype = amd_devport_t'(rdat[23:20]);
    // Ext. Capabilities Linked List
    get_ecaps(usp_ecam_base, usp);

    foreach (usp.ecap[ii]) begin
      if (usp.ecap[ii].id          == ECAP_DVSEC &&
          usp.ecap[ii].dvsec_vendid== CXL_VENDID &&
          usp.ecap[ii].dvsec_id    == 16'h0) begin
          usp.is_cxl_port = 1'b1;
      end
    end
    // CXL: Enable CXL protocol before BAR programming (required before MMIO access)
    if (usp.is_cxl_port)
      cxl_enable(usp_ecam_base, usp);

    // BARs
    handle_usp_bars(dsp_ecam_base, usp_ecam_base, dsp, usp);

    // CXL: Discover MMIO register blocks and program HDM decoders
    if (usp.is_cxl_port) begin
      // MSE must be set on both DSP and USP BEFORE any MMIO reads to the
      // CXL Component Register BAR space.  Without it the VIP EP returns UR
      // for every MemRd TLP and read_mem_cb is never invoked.
      axi_wr(build_ecam_acc(usp_ecam_base,'h4), 32'h6); // MSE+BME
      cxl_get_reg_blks(usp_ecam_base, usp);
      cxl_program_hdm(dsp_ecam_base, dsp, usp);
    end

    // Enable Mem/IO accesses  
    // CfgSpc 0x4 | {Status, Command}
    {bme, mse, iose} = {1'b0, |{dsp.npmem_aper.sz, dsp.pmem_aper.sz, dsp.cxl_aper.sz},
                               |dsp.io_aper.sz};
    axi_wr(build_ecam_acc(dsp_ecam_base,'h4), {24'hx, 5'h0, bme, mse, iose});
    {bme, mse, iose} = {1'b1, |usp.membar.size, |usp.iobar.size};
    axi_wr(build_ecam_acc(usp_ecam_base,'h4), {24'hx, 5'h0, bme, mse, iose});
    // Publish discovered devices for use by calling sequence
    pdev.push_back(dsp);
    pdev.push_back(usp);
  endtask

  virtual task post_body;
    `uvm_info(get_type_name, "Enumeration sequence completed", UVM_LOW)
    print_results;
  endtask

  // --------------
  // Sub-tasks (to break up logic)
  // --------------
 
  /* Parse the capabilities linked list */
  virtual task get_caps(const ref bit [47:0]  ecam_base, 
                                  pcie_device pdev);
    logic [31:0] rdat;
    bit   [ 7:0] ptr;
    bit          done;
    cap_s        cap[$:16];
    // CfgSpc 0x34 | {..., Cap Ptr}
    axi_rd(build_ecam_acc(ecam_base,'h34), rdat);
    if (rdat[7:0]=='0)
      `uvm_fatal(get_type_name, "PCIe Spec: there cannot be no capability structures")
    // Build first linked list read
    ptr = {rdat[7:2], 2'h0};
    // Go read all capabilities
    done = (ptr=='0);
    while (!done) begin
      axi_rd(build_ecam_acc(ecam_base,ptr), rdat);
      cap.push_back(parse_cap(ptr,rdat));
      ptr = rdat[15:8];
      done = (ptr=='0);
    end 
    // Put into pdev object 
    pdev.cap = cap;
  endtask

  /* Parse the extended capabilities linked list */
  virtual task get_ecaps(const ref bit [47:0]  ecam_base, 
                                   pcie_device pdev);
    logic [31:0] rdat;
    bit   [11:0] ptr;
    bit          done;
    ecap_s       ecap[$:64];
    // CfgSpc 0x100 | {"" Ext. Capability Header} or Null
    axi_rd(build_ecam_acc(ecam_base,'h100), rdat);
    if (rdat!='0) begin
      ecap.push_back(parse_ecap('h100, rdat));
      ptr = rdat[31:20];
      done = (rdat=='0);
      // Go read all other ext. capabilities
      while (!done) begin
        axi_rd(build_ecam_acc(ecam_base,ptr), rdat);
        ecap.push_back(parse_ecap(ptr,rdat));
        ptr = rdat[31:20];
        done = (ptr=='0);
      end 
    end 
    // Parse all DVSECs to populate addl. info into struct
    // Note: ecap[ii].base is a 12-bit config space offset; must combine with ecam_base
    foreach (ecap[ii]) begin
      if (ecap[ii].id != ECAP_DVSEC) continue;
      // +0x04: {dvsec_len[31:20], dvsec_rev[19:16], dvsec_vendid[15:0]}
      axi_rd(build_ecam_acc(ecam_base, ecap[ii].base+'h4), rdat);
      {ecap[ii].dvsec_len, ecap[ii].dvsec_rev, ecap[ii].dvsec_vendid} = rdat;
      // +0x08: {device-specific[31:16], dvsec_id[15:0]}
      axi_rd(build_ecam_acc(ecam_base, ecap[ii].base+'h8), rdat);
      ecap[ii].dvsec_id = rdat[15:0];
    end
    // Put into pdev object 
    pdev.ecap = ecap;
  endtask

  /* Decipher and program the Upstream Port BARs */
  // - Write '1 to all USP BARs
  // - Read them back
  // - Calculate total memory (and IO) required by device
  // - Evaluate where they may go in the host side address map (randomized)
  // - Program the USP BARs
  // - Program the DSP apertures (base and limit registers)
  virtual task handle_usp_bars(
    const ref bit [47:0]  dsp_ecam_base,
    const ref bit [47:0]  usp_ecam_base,
    const ref pcie_device dsp,
    const ref pcie_device usp
  );
    logic [31:0]    rdat;
    int             ii;
    bit [5:0][31:0] bar;
    temp_bar_s      tmp_bar[0:5];
    bit [31:0]      tot_mem_sz;
    bit [63:0]      tot_pfmem_sz;
    bit             tot_pfmem_sz64;
    bit [31:0]      tot_io_sz;
    bit             tot_io_sz32;
    bit [31:0]      tmp_io_aper_base;
    bit [31:0]      tmp_mem_aper_base;
    bit [63:0]      tmp_pfmem_aper_base;
    // CDO pre-programming detection
    bit             ps_aper_done;     // PS_APER_CFG_DONE bit[0]: CDO programmed all PS_A* apertures
    bit             iatu_pfmem_found; // set when a CDO-owned iATU OB MEM region is found for pfmem
    bit   [47:0]    iatu_ctrl1_addr, iatu_ctrl2_addr, iatu_src_lo_addr, iatu_lim_lo_addr, iatu_tgt_lo_addr;
    logic [31:0]    iatu_ctrl1, iatu_ctrl2, iatu_src_lo, iatu_lim_lo, iatu_tgt_lo, iatu_tgt_hi;
    bit   [63:0]    iatu_ob_sz;
    // CfgSpc 0x10:0x24 | BARs
    for (ii=0; ii<6; ii++)
      axi_wr(build_ecam_acc(usp_ecam_base,'h10+'h4*ii), '1);
    for (ii=0; ii<6; ii++)
      axi_rd(build_ecam_acc(usp_ecam_base,'h10+'h4*ii), bar[ii]);
    for (ii=0; ii<6; ii++) begin
      if (!bar[ii]) begin
        tmp_bar[ii].empty = 1'b1;
        continue;
      end
      case (bar[ii][0])
        // Memory BAR
        0 : begin
              case (bar[ii][2:1])
        /*32b*/ 2'b00 : tmp_bar[ii].bar = {{32{1'b1}}, bar[ii]};
        /*64b*/ 2'b10 : tmp_bar[ii].bar = {bar[ii+1],  bar[ii]};
              endcase
              tmp_bar[ii].ismem = 1'b1;
              tmp_bar[ii].is64  = (bar[ii][2:1]==2'b10);
              tmp_bar[ii].pftch = bar[ii][3];
              tmp_bar[ii].sz    = ~{tmp_bar[ii].bar[63:4], 4'h0} + 1;
              // Increase aperture total
              if (tmp_bar[ii].pftch)
                tot_pfmem_sz += tmp_bar[ii].sz;
              else
                tot_mem_sz += tmp_bar[ii].sz;
              // Double element incr
              if (tmp_bar[ii].is64)
                ii++;
            end
        // IO BAR
        1 : begin
              tmp_bar[ii].bar = bar[ii];
              tmp_bar[ii].sz  = ~{bar[ii][31:2], 2'h0} + 1;
              // Increase aperture total
              tot_io_sz += tmp_bar[ii].sz;
            end
      endcase
    end
    tot_io_sz32    = |tot_io_sz[31:16];
    tot_pfmem_sz64 = |tot_pfmem_sz[63:32];
    // Must check if DSP supports 32 bit IO and/or 64 bit PF Mem addressing
    if (tot_io_sz) begin
      // CfgSpc 0x1C | {Sec. Sts, IO Limit, IO Base}
      axi_rd(build_ecam_acc(dsp_ecam_base,'h1C), rdat);
      dsp_io32 = (rdat[3:0]=='h1);
    end
    if (tot_pfmem_sz) begin
      // CfgSpc 0x24 | {PF Mem Limit, PF Mem Base}
      axi_rd(build_ecam_acc(dsp_ecam_base,'h24), rdat);
      dsp_pfmem64 = (rdat[3:0]=='h1);
    end
    // If CDO has programmed all PS apertures (PS_APER_CFG_DONE bit[0]=1), scan
    // all iATU OB regions for enabled MEM-type regions sized >= tot_pfmem_sz.
    // The first qualifying region sets pfmem_aper_base; additional matches trigger
    // a warning (ambiguous CDO intent). PS_A*/iATU writes are skipped when ps_aper_done=1.
    if (tot_pfmem_sz) begin
      axi_rd(64'hfc801124, rdat);
      ps_aper_done = rdat[0];   // PS_APER_CFG_DONE
      if (ps_aper_done) begin
        for (int ob = 0; ob < 16; ob++) begin
          iatu_ctrl1_addr  = CTRLR_IATU_REGION_BASE + 'h200*ob;
          iatu_ctrl2_addr  = CTRLR_IATU_REGION_BASE + 'h200*ob + 'h04;
          iatu_src_lo_addr = CTRLR_IATU_REGION_BASE + 'h200*ob + 'h08;
          iatu_lim_lo_addr = CTRLR_IATU_REGION_BASE + 'h200*ob + 'h10;
          iatu_tgt_lo_addr = CTRLR_IATU_REGION_BASE + 'h200*ob + 'h14;
          axi_rd(iatu_ctrl2_addr, iatu_ctrl2);
          if (!iatu_ctrl2[31]) continue;                                      // region not enabled
          axi_rd(iatu_ctrl1_addr, iatu_ctrl1);
          if (iatu_ctrl1[4:0] != 5'h0 && iatu_ctrl1[4:0] != 5'h2) continue; // not MEM type
          axi_rd(iatu_src_lo_addr, iatu_src_lo);
          axi_rd(iatu_lim_lo_addr, iatu_lim_lo);
          iatu_ob_sz = iatu_lim_lo - iatu_src_lo + 1;
          if (iatu_ob_sz < tot_pfmem_sz) continue;                            // too small for pfmem
          if (iatu_pfmem_found) begin
            `uvm_warning(get_type_name, $sformatf(
              "Multiple MEM iATU OB regions qualify for pfmem (OB_%0d also matches, sz=0x%0h); using first match",
              ob, iatu_ob_sz))
            continue;
          end
          iatu_pfmem_found = 1'b1;
          axi_rd(iatu_tgt_lo_addr,        iatu_tgt_lo);
          axi_rd(iatu_tgt_lo_addr + 'h04, iatu_tgt_hi);
          pfmem_aper_base  = {iatu_tgt_hi, iatu_tgt_lo};
          `uvm_info(get_type_name, $sformatf(
            "CDO pre-programmed iATU OB_%0d (MEM, sz=0x%0h): pfmem_aper_base=0x%08h read from TGT_ADDR (skipping PS_A*/iATU override)",
            ob, iatu_ob_sz, pfmem_aper_base), UVM_LOW)
        end
        if (!iatu_pfmem_found)
          `uvm_warning(get_type_name,
            "PS_APER_CFG_DONE=1 but no matching MEM iATU OB region found for pfmem; falling back to randomization")
      end
    end
    // Randomize only what needs to be
    io_aper_base.rand_mode   (|tot_io_sz);
    mem_aper_base.rand_mode  (|tot_mem_sz);
    pfmem_aper_base.rand_mode(|tot_pfmem_sz && !iatu_pfmem_found);
    // Perform randomization
    void'(this.randomize with {
      // Ensure there's no overlap between memory ranges
      (mem_aper_base<pfmem_aper_base && (mem_aper_base+tot_mem_sz)<=pfmem_aper_base)
      ^
      (pfmem_aper_base<mem_aper_base && (pfmem_aper_base+tot_pfmem_sz)<=mem_aper_base);
      // pfmem window must not overlap the ECAM aperture [E000_0000, EFFF_FFFF].
      // BAR3 is placed at pfmem_aper_base+0x10000; excluding the whole window
      // guarantees no prefetchable BAR lands inside the ECAM range.
      (pfmem_aper_base + tot_pfmem_sz <= 64'hE000_0000) ||
      (pfmem_aper_base >= 64'hF000_0000);
    });

    // Reprogram PS_A1 aperture and iATU OB_2 to match randomized pfmem_aper_base.
    // Skipped when CDO has already programmed PS apertures (ps_aper_done=1) AND a
    // valid MEM iATU OB region was found (pfmem_aper_base read from CDO config).
    // When ps_aper_done=1 but no MEM iATU region was found, pfmem_aper_base was
    // randomized so PS_A1/iATU must still be reprogrammed to match, otherwise the
    // PS aperture won't cover the pfmem range and all MMIO reads to the CXL
    // Component Register space (including HDM Decoder Capability) will fail.
    if (tot_pfmem_sz && (!ps_aper_done || !iatu_pfmem_found)) begin
      bit [31:0] pf_limit_l;
      pf_limit_l = pfmem_aper_base[31:0] + tot_pfmem_sz[31:0] - 1;
      // --- PS_A1 aperture ---
      axi_wr(64'hfc801018, pfmem_aper_base[31:0]);  // PS_A1_BASE_L
      axi_wr(64'hfc80101c, 32'h0);                  // PS_A1_BASE_H  (PS VIP ARADDR[51:32])
      axi_wr(64'hfc801020, pf_limit_l);              // PS_A1_LIMIT_L
      axi_wr(64'hfc801024, 32'h0);                   // PS_A1_LIMIT_H
      axi_wr(64'hfc80fc04, 32'h0);                          // PS_A1_SMID (mask=0, match all)
      axi_wr(64'hfc80102c, 32'h1 | (32'h10 << ctrlr));     // PS_A1_CONTROL (dest=DMA[ctrlr], valid=1)
      axi_wr(64'hfc801124, 32'h1);                   // PS_APER_CFG_DONE
      // iATU: no explicit OB region needed. DMA[ctrlr] uses pass-through (identity)
      // translation when no enabled OB region covers the pfmem address, so the PS
      // address becomes the PCIe address directly and the EP VIP decodes correctly.
      `uvm_info(get_type_name, $sformatf(
        "PS_A1 reprogrammed: base=0x%08h limit=0x%08h DMA%0d",
        pfmem_aper_base[31:0], pf_limit_l, ctrlr), UVM_LOW)
    end

    // Program the apertures to DSP
    if (tot_io_sz) begin
      if (tot_io_sz32 && !dsp_io32)
        `uvm_fatal(get_type_name, "Total IO Size exceeds 16b address range but bridge doesn't support 32b addressing")
      // CfgSpc 0x1C | {Sec. Sts, IO Limit, IO Base}
      axi_wr(build_ecam_acc(dsp_ecam_base,'h1C), 
            {16'hx, 
             {tot_io_sz[15:12]-!tot_io_sz32, 4'h0}, 
             {io_aper_base[15:12],           4'h0}});
      if (dsp_io32) begin
        // CfgSpc 0x30 | {IO Limit Upper, IO Base Upper}
        axi_wr(build_ecam_acc(dsp_ecam_base,'h30), 
               {{tot_io_sz[31:16]-tot_io_sz32, 4'h0}, 
                {io_aper_base[31:16],          4'h0}});
      end
    end
    if (tot_mem_sz) begin
      // CfgSpc 0x20 | {Mem Limit, Mem Base}
      axi_wr(build_ecam_acc(dsp_ecam_base,'h20), 
             {{tot_mem_sz[31:20]-1,  4'h0}, 
              {mem_aper_base[31:20], 4'h0}});
    end
    if (tot_pfmem_sz) begin
      if (tot_pfmem_sz64 && !dsp_pfmem64)
        `uvm_fatal(get_type_name, "Total Prefetchable Memory Size exceeds 32b address range but bridge doesn't support 64b addressing")
      // CfgSpc 0x24 | {PF Mem Limit, PF Mem Base}
      axi_wr(build_ecam_acc(dsp_ecam_base,'h24), 
             {{tot_pfmem_sz[31:20]-!tot_pfmem_sz64, 4'h0}, 
              {pfmem_aper_base[31:20],              4'h0}});
      if (dsp_pfmem64) begin
        // CfgSpc 0x28 | {PF Mem Limit Upper, PF Mem Base Upper}
        axi_wr(build_ecam_acc(dsp_ecam_base,'h28), 
               {{tot_pfmem_sz[63:32]-tot_pfmem_sz64},
                pfmem_aper_base[63:32]});
      end
    end

    // Finally program the BAR results to USP
    tmp_io_aper_base    = io_aper_base;
    tmp_mem_aper_base   = mem_aper_base;
    tmp_pfmem_aper_base = pfmem_aper_base;
    for (ii=0; ii<6; ii++) begin
      if (tmp_bar[ii].empty) continue;
      // Memory BAR
      if (tmp_bar[ii].ismem) begin
        // Prefetchable
        if (tmp_bar[ii].pftch) begin
          // Add to pdev objects
          dsp.add_pmem_aper(tmp_pfmem_aper_base, tmp_bar[ii].sz);
          usp.add_mem_bar(ii, tmp_bar[ii].is64, 1'b1, tmp_pfmem_aper_base, tmp_bar[ii].sz);
          // Set base address in USP
          axi_wr(build_ecam_acc(usp_ecam_base,'h10+'h4*ii), tmp_pfmem_aper_base[31: 0]);
          if (tmp_bar[ii].is64) begin
            axi_wr(build_ecam_acc(usp_ecam_base,'h10+'h4*(ii+1)), tmp_pfmem_aper_base[63:32]);
          end
          tmp_pfmem_aper_base += tmp_bar[ii].sz;
          // Double element incr
          if (tmp_bar[ii].is64)
            ii++;
        end
        // Non-Prefetchable
        else begin
          // Add to pdev objects
          dsp.add_npmem_aper(tmp_mem_aper_base, tmp_bar[ii].sz);
          usp.add_mem_bar(ii, 1'b0, tmp_bar[ii].pftch, tmp_mem_aper_base, tmp_bar[ii].sz);
          // Set base address in USP
          axi_wr(build_ecam_acc(usp_ecam_base,'h10+'h4*ii), tmp_mem_aper_base);
          tmp_mem_aper_base += tmp_bar[ii].sz;
        end
      end
      // IO BAR
      else begin
        // Add to pdev objects
        dsp.add_io_aper(tmp_io_aper_base, tmp_bar[ii].sz);
        usp.add_io_bar(ii, tmp_io_aper_base, tmp_bar[ii].sz);
        // Set base address in USP
        axi_wr(build_ecam_acc(usp_ecam_base,'h10+'h4*ii), tmp_io_aper_base);
        tmp_io_aper_base += tmp_bar[ii].sz;
      end
    end
  endtask

  // --------------
  // CXL Sub-tasks
  // --------------

  /* Enable CXL protocol via PCIe DVSEC for CXL Devices (DVSEC ID=0)
   * Sets CXL Enable (bit 20) and Mem Enable (bit 18) in the CXL Control register.
   * Must be called before MMIO register blocks are accessed. */
  virtual task cxl_enable(const ref bit [47:0]  usp_ecam_base,
                                    pcie_device  usp);
    logic [31:0] rdat;
    string       cxl_ver_str;
    bit          cache_cap, mem_cap;
    // Determine CXL version from DVSEC ID=7 (Flex Bus Port).
    // DVSEC ID=7 is present for CXL 2.0 (rev=1, Gen5) and CXL 3.x (rev=2/3, Gen6)
    // and absent for CXL 1.1. Not affected by the dvsec_revision=0 workaround
    // applied to DVSEC ID=0 in shim_layer.sv setup_cfg_space.
    cxl_ver_str = "1.x";
    foreach (usp.ecap[jj]) begin
      if (usp.ecap[jj].id           != ECAP_DVSEC) continue;
      if (usp.ecap[jj].dvsec_vendid != CXL_VENDID) continue;
      if (usp.ecap[jj].dvsec_id     != 16'h7     ) continue;
      case (usp.ecap[jj].dvsec_rev)
        4'h0:    cxl_ver_str = "1.x";
        4'h1:    cxl_ver_str = "2.0";
        4'h2:    cxl_ver_str = "3.0";
        4'h3:    cxl_ver_str = "3.1";
        default: cxl_ver_str = $sformatf("unknown(rev=0x%0h)", usp.ecap[jj].dvsec_rev);
      endcase
      break;
    end
    foreach (usp.ecap[ii]) begin
      if (usp.ecap[ii].id           != ECAP_DVSEC ) continue;
      if (usp.ecap[ii].dvsec_vendid != CXL_VENDID ) continue;
      if (usp.ecap[ii].dvsec_id     != 16'h0      ) continue;
      // DVSEC ID=0: PCIe DVSEC for CXL Devices
      // +0x0C: { CXL Control[31:16] | CXL Capability[15:0] }
      //   Capability bit 0: Cache Capable
      //   Capability bit 2: Mem Capable
      //   Control   bit 16: Cache Enable
      //   Control   bit 18: Mem Enable
      //   Control   bit 20: CXL Enable (always required)
      // CXL Capability register is at base+0x0A (upper 16b of DWORD at base+0x08).
      // DWORD at base+0x08 = {CXL_Capability[15:0], DVSEC_ID[15:0]}
      //   bit 16 = Cache Capable, bit 17 = IO Capable, bit 18 = Mem Capable
      // DWORD at base+0x0C = {CXL_Status[15:0], CXL_Control[15:0]}  ← write target
      axi_rd(build_ecam_acc(usp_ecam_base, usp.ecap[ii].base+'h8), rdat);
      cache_cap = rdat[16]; // CXL Capability bit 0 (Cache Capable)
      mem_cap   = rdat[18]; // CXL Capability bit 2 (Mem Capable)
      `uvm_info(get_type_name, $sformatf(
        "CXL %s device detected: Cache_Cap=%0b Mem_Cap=%0b (Type%s)",
        cxl_ver_str, cache_cap, mem_cap,
        (!cache_cap &&  mem_cap) ? "3" :
        ( cache_cap &&  mem_cap) ? "2" :
        ( cache_cap && !mem_cap) ? "1" : "?"), UVM_LOW)
      // Read CXL Control register (base+0x0C) for RMW; set enable bits; write back
      axi_rd(build_ecam_acc(usp_ecam_base, usp.ecap[ii].base+'hC), rdat);
      rdat[20] = 1'b1;              // CXL Enable (mandatory)
      if (mem_cap)   rdat[18] = 1'b1; // Mem Enable   (Type 2, Type 3)
      if (cache_cap) rdat[16] = 1'b1; // Cache Enable (Type 1, Type 2)
      axi_wr(build_ecam_acc(usp_ecam_base, usp.ecap[ii].base+'hC), rdat);
      `uvm_info(get_type_name, $sformatf(
        "CXL: CXL_En=1 Mem_En=%0b Cache_En=%0b written (DVSEC ID=0)",
        mem_cap, cache_cap), UVM_LOW)
      return;
    end
    `uvm_warning(get_type_name, "CXL: PCIe DVSEC for CXL Devices (ID=0) not found; cannot enable CXL")
  endtask

  /* Discover CXL MMIO register blocks from Register Locator DVSEC (DVSEC ID=8).
   * Resolves the absolute MMIO address of each register block from the USP BAR + offset.
   * Populates usp.cxl_reg_blk[]. */
  virtual task cxl_get_reg_blks(const ref bit [47:0]  usp_ecam_base,
                                           pcie_device  usp);
    logic [31:0] rdat;
    int          nregs;
    foreach (usp.ecap[ii]) begin
      if (usp.ecap[ii].id          != ECAP_DVSEC ) continue;
      if (usp.ecap[ii].dvsec_vendid != CXL_VENDID) continue;
      if (usp.ecap[ii].dvsec_id    != 16'h8      ) continue;
      // DVSEC ID=8: CXL Register Locator DVSEC
      // Header is 12 bytes (3 DWORDs); each register block entry is 8 bytes (2 DWORDs)
      nregs = (int'(usp.ecap[ii].dvsec_len) - 12) / 8;
      for (int rr=0; rr<nregs; rr++) begin
        cxl_reg_blk_s reg_blk;
        mem_bar_s      bar;
        bit [47:0]     dvsec_entry_base;
        // Full 48-bit address of this register block entry in config space
        dvsec_entry_base = usp_ecam_base + {36'h0, usp.ecap[ii].base} + 'hC + 'h8*rr;
        // Read RegOffsetLow
        axi_rd(dvsec_entry_base, rdat);
        reg_blk.id            = cxl_reg_blk_id_e'(rdat[15:8]);
        reg_blk.bar           = rdat[ 2:0];
        reg_blk.offset[31:16] = rdat[31:16];
        // Read RegOffsetHigh
        axi_rd(dvsec_entry_base + 'h4, rdat);
        reg_blk.offset[63:32] = rdat;
        // abs_offset = stored_offset << 16 (64KB granule)
        reg_blk.abs_offset = reg_blk.offset << 16;
        // Resolve MMIO base from USP BAR + abs_offset
        if (reg_blk.id != NULL_REG_BLOCK) begin
          if (!usp.get_membar(reg_blk.bar, bar))
            `uvm_fatal(get_type_name,
              $sformatf("CXL: register block BAR%0d not found in USP", reg_blk.bar))
          reg_blk.base = bar.base + reg_blk.abs_offset;
        end
        usp.cxl_reg_blk.push_back(reg_blk);
      end
      `uvm_info(get_type_name, "CXL: print_cxl_reg_blks", UVM_LOW)
      usp.print_cxl_reg_blks();
      return;
    end
    `uvm_warning(get_type_name, "CXL: Register Locator DVSEC (ID=8) not found")
  endtask

  /* Walk the CXL Component Register Capability Array to locate the
   * HDM Decoder Capability (ID=0x0005).
   * comp_reg_base: MMIO base of the COMPONENT_REG register block.
   * hdm_cap_base:  Returned MMIO base of the HDM Decoder Capability.
   * found:         Set to 1 if HDM Decoder Capability was located. */
  virtual task cxl_find_hdm_cap(
    input  bit [63:0] comp_reg_base,
    output bit [63:0] hdm_cap_base,
    output bit        found
  );
    logic [31:0] rdat;
    bit   [63:0] arr_base;
    bit   [7:0]  cap_count;
    // CXL.cachemem Primary Range begins at comp_reg_base+0x1000 (CXL spec §8.2.4).
    // The Capability Array header is at arr_base+0x0:
    //   [15:0]  = Array ID (must be 0x0001)
    //   [31:24] = Number of capability entries // changed as per spec
    arr_base  = comp_reg_base + 'h1000;
    axi_rd(arr_base[47:0], rdat);
    found = 0;
    `uvm_info(get_type_name, $sformatf("CXL: comp_reg_base = 0x%0h  arr_base = 0x%0h RDATA = 0x%0h", comp_reg_base, arr_base, rdat), UVM_LOW)
    if (rdat[15:0] != 16'h0001) begin
      `uvm_warning(get_type_name, $sformatf("CXL: arr_base header ID=0x%04h (exp 0x0001); VIP model not yet loaded", rdat[15:0]))
      return;
    end
    cap_count = rdat[31:24];
    if (cap_count > 32) begin
      `uvm_warning(get_type_name, $sformatf("CXL: cap_count=%0d out of range; clamping to 32 (raw=0x%08h)", cap_count, rdat))
      cap_count = 12'd32;
    end
    for (int ii=0; ii<cap_count; ii++) begin
      axi_rd((arr_base + 'h4 + 'h4*ii), rdat);
     `uvm_info(get_type_name, $sformatf("CXL:  Address = 0x%0h  RDATA = 0x%0h", (arr_base + 'h4 + 'h4*ii), rdat), UVM_LOW)
      // Entry: [15:0]=cap_id, [19:16]=cap_ver, [31:20]=cap_ptr (byte offset from arr_base)
      if (rdat[15:0] == 16'h0005) begin
        hdm_cap_base = arr_base + 64'(rdat[31:20]); // cap_ptr is a byte offset
        found = 1;
        `uvm_info(get_type_name,
          $sformatf("CXL: HDM Decoder Capability found at 0x%0h", hdm_cap_base), UVM_LOW)
        return;
      end
    end
    `uvm_warning(get_type_name, "CXL: HDM Decoder Capability (ID=0x0005) not found in Component Registers")
  endtask

  /* Program CXL HDM decoders in the Upstream Port (EP).
   * For each active decoder, allocates cxl_mem_size_mb MiB of host PA space
   * starting at cxl_mem_base, writes base/size/commit, and polls for Committed.
   * Records ranges in usp.cxl_hdm[] and the CXL aperture in dsp.cxl_aper.
   * NOTE: The caller must ensure dsp's prefetchable memory window covers
   * [cxl_mem_base, cxl_mem_base+total_cxl_size) so the RP forwards traffic. */
  virtual task cxl_program_hdm(
    const ref bit [47:0]  dsp_ecam_base,
    const ref pcie_device dsp,
    const ref pcie_device usp
  );
    cxl_reg_blk_s comp_blk;
    logic [31:0]  rdat;
    bit   [63:0]  hdm_cap_base;
    bit           found;
    bit   [ 3:0]  dec_cnt_enc;
    int           dec_cnt;
    bit   [63:0]  dec_sz;
    bit   [63:0]  next_base;
    bit   [63:0]  tot_cxl_sz;
    int           timeout;
    // Locate COMPONENT_REG block (populated by cxl_get_reg_blks)
    if (!usp.get_cxl_reg_blk(COMPONENT_REG, comp_blk)) begin
      `uvm_warning(get_type_name, "CXL: No COMPONENT_REG block found; skipping HDM programming")
      return;
    end
    // Find HDM Decoder Capability within CXL Component Register Capability Array
    cxl_find_hdm_cap(comp_blk.base, hdm_cap_base, found);
    if (!found) return;
    // HDM Decoder Capability Header (offset 0x00): bits[3:0] = decoder_cnt encoding
    //   Encoding: 0→1, 1→2, 2→4, 3→6, 4→8 decoders (CXL spec Table 8-18)
    axi_rd(hdm_cap_base[47:0], rdat);
    dec_cnt_enc = rdat[3:0];
    case (dec_cnt_enc)
      4'd0   : dec_cnt = 1;
      4'd1   : dec_cnt = 2;
      4'd2   : dec_cnt = 4;
      4'd3   : dec_cnt = 6;
      4'd4   : dec_cnt = 8;
      default: dec_cnt = 1;
    endcase
    `uvm_info(get_type_name, $sformatf("CXL: %0d HDM decoder(s) found", dec_cnt), UVM_LOW)
    // Enable global HDM decoder via Global Control register (offset 0x04, bit 1)
    axi_rd((hdm_cap_base + 'h4), rdat);
    rdat[1] = 1'b1;
    axi_wr((hdm_cap_base + 'h4), rdat);
    // Per-decoder size: cxl_mem_size_mb MiB (must be 256MiB-aligned minimum)
    dec_sz    = 64'(cxl_mem_size_mb) << 20;
    next_base = cxl_mem_base;
    tot_cxl_sz = '0;
    for (int jj=0; jj<dec_cnt; jj++) begin
      bit [63:0] dec_base_addr;
      bit [47:0] base_lo_addr, base_hi_addr;
      bit [47:0] size_lo_addr, size_hi_addr;
      bit [47:0] ctrl_addr;
      dec_base_addr = next_base;
      base_lo_addr  = (hdm_cap_base + 'h10 + 'h20*jj + 'h00);
      base_hi_addr  = (hdm_cap_base + 'h10 + 'h20*jj + 'h04);
      size_lo_addr  = (hdm_cap_base + 'h10 + 'h20*jj + 'h08);
      size_hi_addr  = (hdm_cap_base + 'h10 + 'h20*jj + 'h0C);
      ctrl_addr     = (hdm_cap_base + 'h10 + 'h20*jj + 'h10);
      // Base Low/High (256MiB granule: bits[27:0] must be 0)
      axi_wr(base_lo_addr, dec_base_addr[31: 0]);
      axi_wr(base_hi_addr, dec_base_addr[63:32]);
      // Size Low/High (256MiB granule: bits[27:0] must be 0)
      axi_wr(size_lo_addr, dec_sz[31: 0]);
      axi_wr(size_hi_addr, dec_sz[63:32]);
      // Control: set Commit (bit 9, W1S)
      axi_rd(ctrl_addr, rdat);
      rdat[9] = 1'b1;
      axi_wr(ctrl_addr, rdat);
      // Poll Committed status (bit 10, RO)
      timeout = 100;
      do begin
        axi_rd(ctrl_addr, rdat);
        timeout--;
      end while (!rdat[10] && timeout > 0);
      if (!rdat[10])
        `uvm_fatal(get_type_name,
          $sformatf("CXL: HDM Decoder %0d did not commit (timeout)", jj))
      `uvm_info(get_type_name,
        $sformatf("CXL: HDM Decoder %0d committed: base=0x%0h size=0x%0h",
                  jj, dec_base_addr, dec_sz), UVM_LOW)
      usp.add_cxl_hdm(dec_base_addr, dec_sz);
      next_base  += dec_sz;
      tot_cxl_sz += dec_sz;
    end
    // Record CXL aperture in DSP object
    dsp.add_cxl_aper(cxl_mem_base, tot_cxl_sz);
    `uvm_info(get_type_name,
      $sformatf("CXL: HDM programming done; %0d decoder(s), base=0x%0h, total_sz=0x%0h",
                dec_cnt, cxl_mem_base, tot_cxl_sz), UVM_LOW)
  endtask

  virtual task print_results;
    string msg;
    msg = "\n+----------------------------------------------------------+\n";
    msg = {msg,   "|              Enumeration Results Summary                 |\n"};
    msg = {msg,   "+----------------------------------------------------------+\n"};
    foreach (pdev[ii]) begin
      string cxl_tag;
      cxl_tag = pdev[ii].is_cxl_port ? " [CXL]" : "";
      msg = {msg, $sformatf("  [%0d] %-10s%s\n", ii,
                             pdev[ii].ptype.name(), cxl_tag)};
      msg = {msg, $sformatf("      VENDOR ID:DEVICE ID = 0x%04h:0x%04h\n",
                             pdev[ii].vendorid, pdev[ii].deviceid)};
      // Type 1 (bridge/RP): bus numbers and apertures
      if (pdev[ii].is_type1()) begin
        msg = {msg, $sformatf("      PriBus=%0d  SecBus=%0d  SubBus=%0d\n",
                               pdev[ii].primary_bus,
                               pdev[ii].secondary_bus,
                               pdev[ii].subord_bus)};
        if (|pdev[ii].npmem_aper.sz)
          msg = {msg, $sformatf("      NP-Mem Aper : 0x%08h  size=%0s\n",
                                 pdev[ii].npmem_aper.base,
                                 pdev[ii].npmem_aper.sz_str)};
        if (|pdev[ii].pmem_aper.sz)
          msg = {msg, $sformatf("      PF-Mem Aper : 0x%08h  size=%0s\n",
                                 pdev[ii].pmem_aper.base,
                                 pdev[ii].pmem_aper.sz_str)};
        if (|pdev[ii].cxl_aper.sz)
          msg = {msg, $sformatf("      CXL Aper    : 0x%08h  size=%0s\n",
                                 pdev[ii].cxl_aper.base,
                                 pdev[ii].cxl_aper.sz_str)};
        if (|pdev[ii].io_aper.sz)
          msg = {msg, $sformatf("      IO Aper     : 0x%08h  size=%0s\n",
                                 pdev[ii].io_aper.base,
                                 pdev[ii].io_aper.sz_str)};
      end
      // Memory BARs
      foreach (pdev[ii].membar[kk]) begin
        msg = {msg, $sformatf("      BAR%0d : 0x%08h  size=%0s  (%s%s)\n",
                               kk,
                               pdev[ii].membar[kk].base,
                               pdev[ii].membar[kk].sz_str,
                               pdev[ii].membar[kk].is_64    ? "64b " : "32b ",
                               pdev[ii].membar[kk].is_pftch ? "pf"   : "np")};
      end
      // IO BARs
      foreach (pdev[ii].iobar[kk]) begin
        msg = {msg, $sformatf("      BAR%0d (IO): 0x%08h  size=%0s\n",
                               kk,
                               pdev[ii].iobar[kk].base,
                               pdev[ii].iobar[kk].sz_str)};
      end
      // CXL HDM ranges (EP only)
      foreach (pdev[ii].cxl_hdm[kk]) begin
        msg = {msg, $sformatf("      CXL HDM[%0d]: 0x%08h  size=%0s\n",
                               kk,
                               pdev[ii].cxl_hdm[kk].base,
                               pdev[ii].cxl_hdm[kk].sz_str)};
      end
      // CXL register blocks
      foreach (pdev[ii].cxl_reg_blk[kk]) begin
        if (pdev[ii].cxl_reg_blk[kk].id != NULL_REG_BLOCK)
          msg = {msg, $sformatf("      CXL Reg Blk[%0d]: 0x%08h  id=0x%02h\n",
                                 kk,
                                 pdev[ii].cxl_reg_blk[kk].base,
                                 pdev[ii].cxl_reg_blk[kk].id)};
      end
    end
    msg = {msg, "+----------------------------------------------------------+"};
    `uvm_info(get_type_name, msg, UVM_NONE)
  endtask
endclass
