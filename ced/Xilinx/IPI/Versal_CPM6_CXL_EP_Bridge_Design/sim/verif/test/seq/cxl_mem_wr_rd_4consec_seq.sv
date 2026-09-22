// cxl_mem_wr_rd_4consec_seq.sv - Versal CPM6 CXL EP Bridge Design
//
// Writes 4 CXL.mem cachelines (base, +64, +128, +192) with distinct data
// patterns, then reads each back and verifies against the expected value.
// Uses 4 fixed addresses (not randomized like sibling HDM sequences) so
// every mismatch is unambiguous about which address failed.
class cxl_mem_wr_rd_4consec_seq extends uvm_sequence;

  `uvm_object_utils(cxl_mem_wr_rd_4consec_seq)

  localparam int NUM_ADDR   = 4;
  localparam int CL_STRIDE  = 64; // cacheline size in bytes

  // Device handles (cached for convenience)
  pcie_device pdev_ep;
  pcie_device pdev_rp;

  // Framework environment handle (for shim API access)
  tb_env      env;

  function new(string name = "cxl_mem_wr_rd_4consec_seq");
    super.new(name);
  endfunction

  virtual task pre_body();
    super.pre_body();
    if (!uvm_config_db#(tb_env)::get(null, "base_sequence", "env", env))
      `uvm_fatal(get_name(), "Failed to get framework environment handle from config_db")

    pdev_ep = env.shim.container.get_pdev_EP();
    pdev_rp = env.shim.container.get_pdev_RP();
    if (pdev_ep == null)
      `uvm_fatal(get_name(), "Failed to get endpoint device handle")
  endtask

  virtual task body();
    string          msg;
    bit    [63:0]   hdm_base;
    bit    [63:0]   addr[NUM_ADDR];
    bit    [63:0][7:0] wdat[NUM_ADDR];
    amd_cxlmem_tlp  cxltlp;

    pdev_ep.print_cxl_reg_blks;
    pdev_ep.print_cxl_dev_caps;

    hdm_base = pdev_ep.cxl_hdm[0].base;
    `uvm_info(get_type_name(), $sformatf(
      "HDM base = 0x%016h (size = 0x%016h)", hdm_base, pdev_ep.cxl_hdm[0].sz), UVM_NONE)

    // Pattern encodes the address index so mismatches are unambiguous.
    for (int a = 0; a < NUM_ADDR; a++) begin
      addr[a] = hdm_base + (a * CL_STRIDE);
      foreach (wdat[a][ii]) wdat[a][ii] = {a[3:0], ii[3:0]};
    end

    // --- Writes ---
    for (int a = 0; a < NUM_ADDR; a++) begin
      cxltlp = amd_cxlmem_tlp::type_id::create($sformatf("cxltlp_wr%0d", a));
      cxltlp.build_wr(addr[a], '{wdat[a]}, .coh(BYPASS_AGENT), .blocking(DONE));

      msg = $sformatf("Sending CXL.mem WR[%0d] to 0x%h:\n", a, addr[a]);
      foreach (cxltlp.data[0][ii])
        msg = {msg, $sformatf("\t%0sDW_%0d = 0x%h\n", ii<10?" ":"", ii, cxltlp.data[0][ii])};
      `uvm_info(get_type_name(), msg, UVM_NONE)

      env.shim.api.send_cxl_txn(cxltlp);
      `uvm_info(get_type_name(), $sformatf("CXL.mem WR[%0d] done", a), UVM_NONE)
    end

    // --- Reads + verify ---
    for (int a = 0; a < NUM_ADDR; a++) begin
      bit          mismatch = 1'b0;
      bit [31:0]   expected_dw[16];

      cxltlp = amd_cxlmem_tlp::type_id::create($sformatf("cxltlp_rd%0d", a));
      cxltlp.build_rd(addr[a], .coh(BYPASS_AGENT), .blocking(DONE));
      `uvm_info(get_type_name(), $sformatf("Sending CXL.mem RD[%0d] to 0x%h", a, addr[a]), UVM_NONE)
      env.shim.api.send_cxl_txn(cxltlp);

      // cxltlp.data[0] is DWORD-indexed, wdat[a] is byte-indexed - pack
      // each DWORD's 4 bytes (little-endian) into expected_dw[] to compare.
      foreach (cxltlp.data[0][ii]) begin
        expected_dw[ii] = {wdat[a][4*ii+3], wdat[a][4*ii+2], wdat[a][4*ii+1], wdat[a][4*ii]};
        if (cxltlp.data[0][ii] !== expected_dw[ii]) mismatch = 1'b1;
      end

      msg = $sformatf("CXL.mem RD[%0d] from 0x%h:\n", a, addr[a]);
      foreach (cxltlp.data[0][ii])
        msg = {msg, $sformatf("\t%0sDW_%0d = 0x%h (expected 0x%h)\n",
                    ii<10?" ":"", ii, cxltlp.data[0][ii], expected_dw[ii])};
      `uvm_info(get_type_name(), msg, UVM_NONE)

      if (mismatch)
        `uvm_error(get_type_name(), $sformatf("CXL.mem readback MISMATCH at address 0x%h (index %0d)", addr[a], a))
      else
        `uvm_info(get_type_name(), $sformatf("PASS: CXL.mem readback OK at address 0x%h (index %0d)", addr[a], a), UVM_NONE)
    end
  endtask

endclass
