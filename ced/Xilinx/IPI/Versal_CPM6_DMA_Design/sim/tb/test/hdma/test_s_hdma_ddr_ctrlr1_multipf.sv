class test_s_hdma_ddr_ctrlr1_multipf extends test_hdma_tasks;
//class test_s_hdma_aximm extends test_basic;

  `uvm_component_utils(test_s_hdma_ddr_ctrlr1_multipf);

  amd_mem_tlp     tlp;

  pcie_device     pdev_rp;
  pcie_device     pdev_ep;
   
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

   logic[31:0] rd_data;
   
   logic [31:0]  txfr_size;
   logic [5:0]   chn_num;
   logic [31:0]  rd_pattern;
//   rc_mem_callback mem_cb;
   logic [63:0]  host_addr;  // address offset in the Host
   logic [63:0]  h2c_dst_address;  // address offset in FPGA
   logic [63:0]  c2h_src_address;  // address offset in FPGA
   logic [63:0]  c2h_dst_address;  // address offset in the Host
   logic [63:0]  fpga_dev_addr;    // address offset in device 
  logic 	 msi_int;
  logic 	 msix_int;
    bit [1:0] dut_ctrlr_en;
    int pf;
   
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

      dut_ctrlr_en[0] = 1'b0; 
      dut_ctrlr_en[1] = 1'b1;

    `uvm_info("---- Which Controler enabled.  ---- ", $sformatf("Controler %b is enabled", dut_ctrlr_en[1:0]), UVM_NONE)

    for (int ii=0; ii<2; ii++) begin
      // VIP as RP
      vip_cfg.ctrlr_en[ii] = 1'b1;
      vip_cfg.port_ctl[ii] = generic_config::PCIE;
      vip_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::RP;
      vip_cfg.pcie_cfg[ii].flit_mode_ctl = 1;
      // DUT as EP
      dut_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
      dut_cfg.port_ctl[ii] = generic_config::PCIE;
      dut_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::EP;
      dut_cfg.pcie_cfg[ii].flit_mode_ctl = 1;
    end
     // PS_VIP routing for DDR access
     //      
    if (!uvm_config_db#(virtual ps_vip_api_if)::get(this, "", "ps_vip_api", ps_vip_api)) 
      `uvm_fatal("CFGDB_NOGET", "Could not get 'ps_vip_api' from cfg db")

     ps_vip_api.set_routing_config(CPM_PS_AXI_0, PS_NOC_PCI_AXI_0, 1'b1);
     ps_vip_api.set_routing_config(CPM_PS_AXI_1, PS_NOC_PCI_AXI_1, 1'b1);
  endfunction

   virtual function void connect_phase(uvm_phase phase);
      phase.raise_objection(this);
      super.connect_phase(phase);
      
      phase.drop_objection(this);
   endfunction // connect_phase
  
  logic [31:0] data;

  virtual task main_phase(uvm_phase phase);
    vseq_loop  seq_loop;
    int        num_pfs_cfg;
    super.main_phase(phase);
    phase.raise_objection(this);

 `uvm_info(get_type_name, $sformatf("number of pdevs = %0d",env.shim.container.pdev.size), UVM_NONE)

    // Program MSIX table for all functions that are enabled.
    TSK_GET_NUM_PFS_FROM_CFG(num_pfs_cfg);
    `uvm_info(get_type_name, $sformatf("PF count discovered from cfg space = %0d", num_pfs_cfg), UVM_NONE)
    for (int pf_num = 0; pf_num < num_pfs_cfg; pf_num++) begin
        TSK_PROGRAM_MSIX_VEC_TABLE(pf_num);
    end

    // Program HDMA context for 4 channels (channel 0-3, one per PF).
    hdma_ctxt_init_prog(4);

    tlp = amd_mem_tlp::type_id::create("tlp");

    // if both msi_int and msix_int is 0, poll mode is used.
    msi_int  = 0;
    msix_int = 1;

    host_addr     = {$urandom, 6'h0};        // Host address
    fpga_dev_addr = 64'h0500_0001_0000;       // PL-AXI 0

    // Test H2C and C2H for PF0 through PF3.
    // PF N is mapped to channel N via func_to_chn table in pl_example.sv.
    // Doorbell offsets are channel-relative:
    //   H2C: 0x200 + (N * 0x400) + 0x04
    //   C2H:          (N * 0x400) + 0x04
    for (int iter=0; iter<40; iter++) begin
    for (int pf=0; pf<4; pf++) begin
      `uvm_info("---- H2C DMA ---- ", $sformatf("PF%0d -> channel %0d", pf, pf), UVM_NONE)
      bar_write(pf, 1, 32'h0_0000, 4, 32'h100);              // Size
      bar_write(pf, 1, 32'h0_0004, 4, host_addr[31:0]);      // Src addr lo
      bar_write(pf, 1, 32'h0_0008, 4, host_addr[63:32]);     // Src addr hi
      bar_write(pf, 1, 32'h0_000c, 4, fpga_dev_addr[31:0]);  // Dst addr lo
      bar_write(pf, 1, 32'h0_0010, 4, fpga_dev_addr[63:32]); // Dst addr hi (triggers DMA)

      // Wait for H2C transfer to complete via MSI-X interrupt.
      s_hdma_chk_txfr_done(H2C, 32'h200 + (pf * 32'h400) + 32'h04, msi_int, msix_int);

      `uvm_info("---- C2H DMA ---- ", $sformatf("PF%0d -> channel %0d", pf, pf), UVM_NONE)
      bar_write(pf, 1, 32'h0_0100, 4, 32'h100);              // Size
      bar_write(pf, 1, 32'h0_0104, 4, fpga_dev_addr[31:0]);  // Src addr lo
      bar_write(pf, 1, 32'h0_0108, 4, fpga_dev_addr[63:32]); // Src addr hi
      bar_write(pf, 1, 32'h0_010c, 4, host_addr[31:0]);      // Dst addr lo
      bar_write(pf, 1, 32'h0_0110, 4, host_addr[63:32]);     // Dst addr hi (triggers DMA, is_c2h=1)

      // Wait for C2H transfer to complete via MSI-X interrupt.
      s_hdma_chk_txfr_done(C2H, (pf * 32'h400) + 32'h04, msi_int, msix_int);
    end
    end

    // Wait for some time before exit
    #10000ns;


    phase.drop_objection(this);
  endtask 

endclass
