/*
*/
class test_M_bridge_plaxi_ctrlr1_4pf_axildecode extends test_hdma_tasks;

  `uvm_component_utils(test_M_bridge_plaxi_ctrlr1_4pf_axildecode);

  amd_mem_tlp     tlp;

  pcie_device     pdev_rp;
  pcie_device     pdev_ep;
  virtual ps_vip_api_if ps_vip_api;
 
   
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  bit [1:0] dut_ctrlr_en;

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
   
   logic[31:0] rd_data;
   
   logic [31:0]  txfr_size;
   logic [5:0]   chn_num;
   logic [31:0]  rd_pattern;
   logic [63:0]  host_addr;  // address offset in the Host
   logic [63:0]  h2c_dst_address;  // address offset in FPGA
   logic [63:0]  c2h_src_address;  // address offset in FPGA
   logic [63:0]  c2h_dst_address;  // address offset in the Host
   logic [31:0]  bar1_data, bar2_data, bar3_data, bar4_data, bar5_data, bar6_data;
   logic [31:0]  bar1_addr, bar2_addr, bar3_addr, bar4_addr, bar5_addr, bar6_addr;
   int 		 pf; // PF0
   
   
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

    TSK_GET_NUM_PFS_FROM_CFG(num_pfs_cfg);
    `uvm_info(get_type_name, $sformatf("PF count discovered from cfg space = %0d", num_pfs_cfg), UVM_NONE)

    /* How to do individual transactions: use one-liner APIs */
     // On AXI port 0 AXI Lite master control going to PL is assiged
     // so need to alocate 64K space for that.
     // total 128 KB aperture size for all axi ports.

    tlp = amd_mem_tlp::type_id::create("tlp");
    // pf = num_pfs_cfg-1; // PF with max number
    for (pf=0; pf<num_pfs_cfg; pf++) begin
      `uvm_info(get_type_name, $sformatf("PF = %0d", pf), UVM_NONE)
    // pf = 1;
     
     // BAR0 goes to ELBI and CSR registger  
     //BAR 1 // BARM in upper 64K, lower 64K is AXI-Lite control
             // go to AXI_PL0
     // BAR2 // go to AXI_PL1
     // BAR3 // go to AXI_PL2
     // BAR4  // go to AXI_PL3
     // BAR5  // go to NOC to PL to BRAM
 
      bar1_data = $urandom;
      bar2_data = $urandom;
      bar3_data = $urandom;
      bar4_data = $urandom;
      bar5_data = $urandom;
      
      bar1_addr = $urandom_range(0, 32'h0ffff);
      bar1_addr = {16'h0001, bar1_addr[15:0]}; // align to 64K boundary for AXI-Lite decode region
      `uvm_info("***", $sformatf("bar = %d, reg addr : 0x%h, data = 0x%h",1, bar1_addr,bar1_data), UVM_NONE)
      bar1_addr[1:0] = 0;
      
      bar2_addr = $urandom_range(0, 32'h1ffff);
      `uvm_info("***", $sformatf("bar = %d, reg addr : 0x%h, data = 0x%h",1, bar2_addr,bar2_data), UVM_NONE)
      bar2_addr[1:0] = 0;
      bar3_addr = $urandom_range(0, 32'h1ffff);
      `uvm_info("***", $sformatf("bar = %d, reg addr : 0x%h, data = 0x%h",1, bar3_addr,bar3_data), UVM_NONE)
      bar3_addr[1:0] = 0;
      bar4_addr = $urandom_range(0, 32'h1ffff);
      `uvm_info("***", $sformatf("bar = %d, reg addr : 0x%h, data = 0x%h",1, bar4_addr,bar4_data), UVM_NONE)
      bar5_addr = $urandom_range(0, 32'h1ffff);
      `uvm_info("***", $sformatf("bar = %d, reg addr : 0x%h, data = 0x%h",1, bar5_addr,bar5_data), UVM_NONE)

      
      // BAR Write
      bar_write   (pf, 1, 32'h0_0000, 4, 32'h100);
      bar_write   (pf, 1, 32'h0_0004, 4, 32'h200);
      bar_write   (pf, 1, 32'h0_0008, 4, 32'h300);
      bar_write   (pf, 1, 32'h0_000c, 4, 32'h400);
      bar_write   (pf, 1, 32'h0_0010, 4, 32'h500);
      bar_write   (pf, 1, 32'h0_0014, 4, 32'h600);
      
    //	bar_write   (pf, 0, 'h0, bar5_data);

      // BAR Read
      bar_read_chk(pf, 1, 32'h0_0000, 4, 32'h100);
      bar_read_chk(pf, 1, 32'h0_0004, 4, 32'h200);
      bar_read_chk(pf, 1, 32'h0_0008, 4, 32'h300);
      bar_read_chk(pf, 1, 32'h0_000c, 4, 32'h400);
      bar_read_chk(pf, 1, 32'h0_0010, 4, 32'h500);
      bar_read_chk(pf, 1, 32'h0_0014, 4, 32'h600);
    //	bar_read_chk(pf, 0, 'h0, bar5_data);
    end

    phase.drop_objection(this);
  endtask 

endclass
