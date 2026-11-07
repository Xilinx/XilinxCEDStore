class test_cfg_tlps extends test_enum;

  `uvm_component_utils(test_cfg_tlps);

  amd_cfg_tlp        tlp;
  seq_cap_traverse   seq_cap;
  seq_cfg_spc_header seq_cfgspc_hdr;
  seq_ep_get_bars    seq_get_bars;

  pcie_device        pdev_rp;
  pcie_device        pdev_ep;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task main_phase(uvm_phase phase);
    bit [31:0]    rcfg;
    bit           err;
    cap_pci_pm    pm;
    ecap_pl_64gts pl64;
    super.main_phase(phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name, $sformatf("number of pdevs = %0d",env.shim.container.pdev.size), UVM_NONE)
    pdev_rp = env.shim.container.get_pdev_RP; 
    pdev_ep = env.shim.container.get_pdev_EP; 

    /* How to do individual transactions: use one-liner APIs */

    // A1. Create a txn (can re-use it)
    tlp = amd_cfg_tlp::type_id::create("tlp");

    // A2. Build the txn
    // A3. Send it (via a generic txn datapath)

    // - Target Local
    // Cfg Read (Vendor ID, Device ID)
    tlp.build_rd('h0, .bdf(pdev_rp.bdf));
    env.shim.api.send_cfg(tlp);

    // - Target Remote; (across link)
    // Cfg Read (Vendor ID, Device ID)
    tlp.build_rd('h0, .bdf(pdev_ep.bdf));
    env.shim.api.send_cfg(tlp);

    // Command Register: RdModWrRdback
    tlp.build_rd('h4); 
    env.shim.api.send_cfg(tlp);
    tlp.build_wr('h4, tlp.payload[0][0]&8'hFE, 'h1); //Disable "I/O Space Enable"
    env.shim.api.send_cfg(tlp);
    tlp.build_rd('h4, {{29{1'bx}}, 3'h6}, 'h1); 
    env.shim.api.send_cfg(tlp);

    // B1. Call as a true one-liner with a single DW
    // - Target Local
    env.shim.api.read_cap_dw (pdev_rp.bdf,                       .offset(2), .data(rcfg),     .err(err));
    env.shim.api.read_cap_dw (pdev_rp.bdf, .cap   (CAP_PCI_EXP), .offset(0), .data(rcfg),     .err(err));
    env.shim.api.write_cap_dw(pdev_rp.bdf, .ecap  (ECAP_AER),    .offset(2), .data('hFF<<14), .err(err));
    env.shim.api.read_cap_dw (pdev_rp.bdf, .ecap  (ECAP_AER),    .offset(2), .data(rcfg),     .err(err));
    // - Target Remote; (across link)
    env.shim.api.read_cap_dw (pdev_ep.bdf,                       .offset(2), .data(rcfg),     .err(err));
    env.shim.api.read_cap_dw (pdev_ep.bdf, .cap   (CAP_PCI_EXP), .offset(0), .data(rcfg),     .err(err));
    env.shim.api.write_cap_dw(pdev_ep.bdf, .ecap  (ECAP_AER),    .offset(2), .data('hFF<<14), .err(err));
    env.shim.api.read_cap_dw (pdev_ep.bdf, .ecap  (ECAP_AER),    .offset(2), .data(rcfg),     .err(err));

    // B2. Call as a true one-liner with an object being passed to access one
    // or more DWs
    // - Target Local
    pm = cap_pci_pm::type_id::create("pm");
    env.shim.api.read_cap(pdev_rp.bdf, pm, 0, 2, err);
    pl64 = ecap_pl_64gts::type_id::create("pl64");
    env.shim.api.read_cap(pdev_rp.bdf, pl64, 0, 4, err); 
    // - Target Remote; (across link)
    pm = cap_pci_pm::type_id::create("pm");
    env.shim.api.read_cap(pdev_ep.bdf, pm, 0, 2, err);
    pl64 = ecap_pl_64gts::type_id::create("pl64");
    env.shim.api.read_cap(pdev_ep.bdf, pl64, 0, 4, err); 

    /* How to send multiple transactions: use sequence to run on vseqr */
    seq_cap = seq_cap_traverse::type_id::create("seq_cap");
    seq_cap.dst_bdf = pdev_ep.bdf;
    seq_cap.start(env.shim.vsqr);

    seq_cfgspc_hdr = seq_cfg_spc_header::type_id::create("seq_cfgspc_hdr");
    seq_cfgspc_hdr.dst_bdf = pdev_ep.bdf;
    seq_cfgspc_hdr.start(env.shim.vsqr);

    seq_get_bars = seq_ep_get_bars::type_id::create("seq_get_bars");
    seq_get_bars.dst_bdf = pdev_ep.bdf;
    seq_get_bars.start(env.shim.vsqr);
  
    phase.drop_objection(this);
  endtask 

endclass
