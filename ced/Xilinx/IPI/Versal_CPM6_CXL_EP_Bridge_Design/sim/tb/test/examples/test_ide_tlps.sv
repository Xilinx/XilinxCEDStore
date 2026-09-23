class test_ide_tlps extends test_ide_basic;

  `uvm_component_utils(test_ide_tlps);

  amd_cfg_tlp     tlp;

  function new(string name, uvm_component parent);
    super.new(name, parent);

    timeout = 800us;
    cdo_timeout = 400us;

    // Configure Link IDE using link_ide_cfg from test_ide_basic
    link_ide_cfg.enable = 1'b1;
    link_ide_cfg.pcrc_enable = 1'b0;
    link_ide_cfg.partial_header_encryption_mode = 4'b0;
    link_ide_cfg.tc = 3'b0;
    link_ide_cfg.stream_id = 8'h01;
  endfunction

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    phase.raise_objection(this);
        
    // Send an IDE TLP to the EP
    tlp = amd_cfg_tlp::type_id::create("tlp");
    tlp.build_rd('h0, .bdf(pdev_ep.bdf));
    tlp.ide_stream_id = link_ide_cfg.stream_id;
    env.shim.api.send_cfg(tlp);
    
    phase.drop_objection(this);
  endtask 

endclass
