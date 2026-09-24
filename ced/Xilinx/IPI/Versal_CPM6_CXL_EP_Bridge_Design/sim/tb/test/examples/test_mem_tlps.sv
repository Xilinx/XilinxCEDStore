class test_mem_tlps extends test_enum;

  `uvm_component_utils(test_mem_tlps);

  amd_mem_tlp     tlp;

  pcie_device     pdev_rp;
  pcie_device     pdev_ep;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task main_phase(uvm_phase phase);
    vseq_loop  seq_loop;
    super.main_phase(phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name, $sformatf("number of pdevs = %0d",env.shim.container.pdev.size), UVM_NONE)
    pdev_rp = env.shim.container.get_pdev_RP; 
    pdev_ep = env.shim.container.get_pdev_EP; 

    /* How to do individual transactions: use one-liner APIs */

    // A1. Create a txn (can re-use it)
    tlp = amd_mem_tlp::type_id::create("tlp");

    // A2. Build the txn
    // A3. Send it (via a generic txn datapath)

    // Write 1 DW to BAR0
    tlp.build_wr(pdev_ep.membar[0].base, .data('{32'h1F00_2F00}));
    env.shim.api.send_mem(tlp);

    // Read 1 DW from BAR0
    tlp.build_rd(pdev_ep.membar[0].base, 1);
    env.shim.api.send_mem(tlp);

    /* How to send multiple transactions: use sequence to run on vseqr */

    tlp.build_rd(pdev_ep.membar[0].base+'h100, 1);
    seq_loop = vseq_loop::type_id::create("seq_loop");
    seq_loop.tlp      = tlp;
    seq_loop.loop_cnt = 8;
    seq_loop.start(env.shim.vsqr);
  
    phase.drop_objection(this);
  endtask 

endclass
