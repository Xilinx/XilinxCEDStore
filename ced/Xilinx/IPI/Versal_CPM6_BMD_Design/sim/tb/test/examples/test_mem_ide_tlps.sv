class test_mem_ide_tlps extends test_ide_basic;

  `uvm_component_utils(test_mem_ide_tlps);

  amd_mem_tlp     tlp;

  function new(string name, uvm_component parent);
    super.new(name, parent);

    timeout = 800us;
    cdo_timeout = 400us;

    // Configure Selective IDE
    sel_ide_cfg.enable = 1'b1;
    sel_ide_cfg.pcrc_enable = 1'b0;
    sel_ide_cfg.partial_header_encryption_mode = 4'b0;
    sel_ide_cfg.tc = 3'b0;
    sel_ide_cfg.stream_id = 8'h01;
    
    // Selective IDE specific settings
    sel_ide_cfg.default_stream = 1'b1;
    sel_ide_cfg.for_configuration_requests = 1'b0;  // Memory TLPs, not config
    
    // RID association - full range to accept any requester
    sel_ide_cfg.rid_valid = 1'b1;
    sel_ide_cfg.rid_base  = 16'h0000;
    sel_ide_cfg.rid_limit = 16'hffff;
    
    // Address association - full address range
    sel_ide_cfg.addr_valid[0] = 1'b1;
    sel_ide_cfg.addr_base[0] = 64'h0;
    sel_ide_cfg.addr_limit[0] = 64'hFFFF_FFFF_FFFF_FFFF;
  endfunction

  virtual task main_phase(uvm_phase phase);
    pdev_rp = env.shim.container.get_pdev_RP;
    pdev_ep = env.shim.container.get_pdev_EP;

    // Set address association to match BAR0 range
    sel_ide_cfg.addr_base[0] = pdev_ep.membar[0].base;
    sel_ide_cfg.addr_limit[0] = pdev_ep.membar[0].base + pdev_ep.membar[0].sz - 1;

    super.main_phase(phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name, $sformatf("number of pdevs = %0d",env.shim.container.pdev.size), UVM_NONE)

    /* Memory TLPs with Selective IDE */

    // Create a txn (can re-use it)
    tlp = amd_mem_tlp::type_id::create("tlp");

    // Write 1 DW to BAR0 with IDE stream ID
    tlp.build_wr(pdev_ep.membar[0].base, .data('{32'h1F00_2F00}), .blocking(SENT));
    tlp.ide_stream_id = sel_ide_cfg.stream_id;
    env.shim.api.send_mem(tlp);

    // Delay to avoid DUT MAC checker pipeline race: without this, the MRD arrives
    // only ~8ns after the MWR at the DUT receiver, but O_cctx_read_cmd_mac (expected
    // MAC) takes ~16ns to compute after I_cmd_mac is set. The MRD's I_cmd_mac
    // overwrites the MWR's before the comparison fires, causing a false IDE_FAIL.
    #(1us);

    // Read 1 DW from BAR0 and wait for the completion to return
    tlp.build_rd(pdev_ep.membar[0].base, 1, .blocking(DONE));
    tlp.ide_stream_id = sel_ide_cfg.stream_id;
    env.shim.api.send_mem(tlp);

    // Send multiple reads and wait for each completion before ending the test
    repeat (8) begin
      #(1us);
      tlp.build_rd(pdev_ep.membar[0].base+'h100, 1, .blocking(DONE));
      tlp.ide_stream_id = sel_ide_cfg.stream_id;
      env.shim.api.send_mem(tlp);
    end
  
    phase.drop_objection(this);
  endtask 

endclass
