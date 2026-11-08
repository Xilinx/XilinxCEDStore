class test_s_dma_ddr_ctrlr1_multipf extends test_dma_tasks_8pf;
//class test_s_dma_aximm extends test_basic;

  `uvm_component_utils(test_s_dma_ddr_ctrlr1_multipf);

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
    int num_iter;
   
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

`ifdef CPM6_VIVADO
  // The 8PF_32VF design's CDO leaves CPM6_PCIE_CORE1.ATTR_REG_0.app_req_retry_en (bit 6) SET, so the controller
  // completes every config request with CRS and bus enumeration never finishes (the 8PF design's CDO clears it).
  // On hardware the firmware releases it; nothing does in simulation, so clear it after the CDO load. No-op on
  // designs whose CDO already clears it. Same hook as test_s_dma_ddr_Ctrl1_8pf_32vf; +KEEP_CFG_RETRY keeps the CDO value.
  virtual task post_cdo_load();
    super.post_cdo_load();
    if (!$test$plusargs("KEEP_CFG_RETRY")) begin
      cdo_mask_write(32'hFC940100, 32'h0000_0040, 32'h0000_0000);
      `uvm_info("CFGRETRY", "ATTR_REG_0.app_req_retry_en (bit 6) cleared after CDO load; +KEEP_CFG_RETRY keeps the CDO value", UVM_NONE)
    end
  endtask
`endif

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
    `uvm_info(get_type_name, $sformatf("MSI-X vector table update COMPLETE for all %0d functions (PF table @ BAR0+0x%0h)",
              num_pfs_cfg, PF_MSIX_VEC_OFFSET), UVM_NONE)

    // Program DMA context for 4 channels (channel 0-3, one per PF).
    dma_ctxt_init_prog(4);

    tlp = amd_mem_tlp::type_id::create("tlp");

    // if both msi_int and msix_int is 0, poll mode is used.
    msi_int  = 0;
    msix_int = 1;

    host_addr     = {$urandom, 6'h0};        // Host address
    // PL-AXI 1 (CPM6 DMA aperture 1, 8KB axi_bram_ctrl_1). Not PL-AXI 0 (0x0500_0001_0000): on the 8PF_32VF design the
    // M00_AXI_0/Reg window on that port is 256KB (BRAM0 moved to 0xC000_0000), so 0x0500_0001_0000 hits the register slave.
    fpga_dev_addr = 64'h0500_0002_0000;       // PL-AXI 1

    // Test H2C and C2H for PF0 through PF3.
    // PF N is mapped to channel N via func_to_chn table in pl_example.sv.
    // PL register map in BAR1 (axil_slave.sv):
    //   C2H bank: 0x10 size, 0x14 src_lo, 0x18 src_hi, 0x1C dst_lo, 0x20 dst_hi (TRIGGER)
    //   H2C bank: 0x30 size, 0x34 src_lo, 0x38 src_hi, 0x3C dst_lo, 0x40 dst_hi (TRIGGER)
    //   0x28 / 0x48: any write requests the C2H / H2C interrupt clear (PL holds the
    //                channel interrupt until the host does this)
    // Doorbell offsets for the status-poll fallback are channel-relative:
    //   H2C: 0x200 + (N * 0x400) + 0x04
    //   C2H:          (N * 0x400) + 0x04
    // Number of iterations over PF0..PF3 (default 40 as in the reference); +NUM_ITER=<n> shortens the run for a quick check
    num_iter = 40;
    void'($value$plusargs("NUM_ITER=%d", num_iter));
    `uvm_info(get_type_name, $sformatf("DMA iterations = %0d", num_iter), UVM_NONE)
    for (int iter=0; iter<num_iter; iter++) begin
    for (int pf=0; pf<4; pf++) begin
      `uvm_info("---- H2C DMA ---- ", $sformatf("iter %0d PF%0d -> channel %0d (trigger = BAR1+0x40)", iter, pf, pf), UVM_NONE)
      bar_write(pf, 1, 32'h30, 4, 32'h100);              // H2C Size
      bar_write(pf, 1, 32'h34, 4, host_addr[31:0]);      // H2C Src addr lo
      bar_write(pf, 1, 32'h38, 4, host_addr[63:32]);     // H2C Src addr hi
      bar_write(pf, 1, 32'h3c, 4, fpga_dev_addr[31:0]);  // H2C Dst addr lo
      bar_write(pf, 1, 32'h40, 4, fpga_dev_addr[63:32]); // H2C Dst addr hi (triggers DMA)

      // Wait for H2C transfer to complete via MSI-X interrupt.
      s_dma_chk_txfr_done(H2C, 32'h200 + (pf * 32'h400) + 32'h04, msi_int, msix_int);
      bar_write(pf, 1, 32'h48, 4, 32'h1);                // H2C interrupt clear request

      `uvm_info("---- C2H DMA ---- ", $sformatf("iter %0d PF%0d -> channel %0d (trigger = BAR1+0x20)", iter, pf, pf), UVM_NONE)
      bar_write(pf, 1, 32'h10, 4, 32'h100);              // C2H Size
      bar_write(pf, 1, 32'h14, 4, fpga_dev_addr[31:0]);  // C2H Src addr lo
      bar_write(pf, 1, 32'h18, 4, fpga_dev_addr[63:32]); // C2H Src addr hi
      bar_write(pf, 1, 32'h1c, 4, host_addr[31:0]);      // C2H Dst addr lo
      bar_write(pf, 1, 32'h20, 4, host_addr[63:32]);     // C2H Dst addr hi (triggers DMA, is_c2h=1)

      // Wait for C2H transfer to complete via MSI-X interrupt.
      s_dma_chk_txfr_done(C2H, (pf * 32'h400) + 32'h04, msi_int, msix_int);
      bar_write(pf, 1, 32'h28, 4, 32'h1);                // C2H interrupt clear request
    end
    end

    // Wait for some time before exit
    #10000ns;


    phase.drop_objection(this);
  endtask 

endclass
