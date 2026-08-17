//
// Hdma LL mode data transfer
//
// Descriptor in AXI_PL0 port
// DMA data transfer on to AXI_PL1, AXI_PL2 and AXI_PL3 ports (not on DDR ports).
// AXI_PL0 lower 64K is use for user logic.
// so descritpr will be stored in upper 64K 0x10000
// H2C descriptors at 0x10000
// C2H descriptors at 0x11000
// DMA tranfer will be randomized between AXI_PL1, AXI_PL2 and ACI_PL3
//

class test_ll_hdma_dsc_axi0_plaxi_ctrlr1 extends test_hdma_tasks;

  `uvm_component_utils(test_ll_hdma_dsc_axi0_plaxi_ctrlr1)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction // new

   
   int 		 itter_count = 20;
   logic [5:0] 	 chn;
   logic [15:0]  rd_chn_base_addr;
   logic [15:0]  wr_chn_base_addr;
   logic [63:0]  axi_port0;
   logic [63:0]  axi_port1;
   logic [63:0]  axi_port2;
   logic [63:0]  axi_port3;
   logic [63:0]  ps_axi_0;
   logic [63:0]  ps_axi_1;
   logic [63:0]  desc_addr_h2c;
   logic [63:0]  desc_addr_c2h;
   logic [31:0]  txfr_size;
   logic [63:0]  h2c_src_address;  // address offset in the Host
   logic [63:0]  h2c_dst_address;  // address offset in FPGA
   logic [63:0]  c2h_src_address;  // address offset in FPGA
   logic [63:0]  c2h_dst_address;  // address offset in the Host
   logic [2:0] 	 port_sel;
   logic [31:0]  rd_pattern;
   logic [31:0]  max_buffer_size = 65536;
   logic [31:0]  max_buffer_size_PS = 16384;
   logic [6:0] 	 tot_dsc;          // total descriptor for prefet calculation
   logic [2:0] 	 dsc_port;
   
   bit [1:0] dut_ctrlr_en;

   // this is to set Gen6 simualtion.
   // if random seed is desired comment out this function.
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    // Default each DUT controller to enabled, which affects CDO programming
      dut_ctrlr_en[0] = 1'b1; 
      dut_ctrlr_en[1] = 1'b1;  // ??
     
    for (int ii=0; ii<2; ii++) begin
      // VIP as RP
      vip_cfg.ctrlr_en[ii] = 1'b1;
      vip_cfg.port_ctl[ii] = generic_config::PCIE;
      vip_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::RP;
      vip_cfg.pcie_cfg[ii].flit_mode_ctl = 1'b1;
       
      // DUT as EP
      dut_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
      dut_cfg.use_case[ii] = dut_config::PCIE_DMA;
      dut_cfg.port_ctl[ii] = generic_config::PCIE;
      dut_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::EP;
      dut_cfg.pcie_cfg[ii].flit_mode_ctl = 1'b1;
    end // for (int ii=0; ii<2; ii++)

     // PS_VIP routing for DDR access
     //      
    if (!uvm_config_db#(virtual ps_vip_api_if)::get(this, "", "ps_vip_api", ps_vip_api)) 
      `uvm_fatal("CFGDB_NOGET", "Could not get 'ps_vip_api' from cfg db")

     ps_vip_api.set_routing_config(CPM_PS_AXI_0, PS_NOC_PCI_AXI_0, 1'b1);
     ps_vip_api.set_routing_config(CPM_PS_AXI_1, PS_NOC_PCI_AXI_1, 1'b1);
  endfunction

   virtual task main_phase(uvm_phase phase);
      phase.raise_objection(this);
      super.main_phase(phase);
      dsc_port = 0;  // AXI_PL0 keep it fixed.

      for (int i = 0; i < itter_count ; i++) begin 
	 chn = $urandom_range(0,63);
	 port_sel = $urandom_range(1,3);  // randomize AXI port 1 to 3 for H2C and C2H DMA transfers.
	 txfr_size = (port_sel == 0) ? $urandom_range(1, max_buffer_size-2048) : 
		     $urandom_range(1, max_buffer_size);
	 //txfr_size = 4096;
	 tot_dsc = txfr_size[17:12] + |txfr_size[11:0];  // setting max size as 64K

	 h2c_src_address = {$urandom, 6'h0};          // Host address
	 c2h_dst_address = {$urandom, 6'h0};          // Host address
	 rd_chn_base_addr = 16'h200 + (chn * 16'h400);
	 wr_chn_base_addr = 16'h0 + (chn * 16'h400);
	 axi_port0 = 64'h50000000000;
	 axi_port1 = 64'h50000020000;
	 axi_port2 = 64'h50000040000;
	 axi_port3 = 64'h50000060000;
	 //      ps_axi_0  = 64'h50000080000;
	 //      ps_axi_1  = 64'h500000a0000;
	 desc_addr_h2c = axi_port0 + 32'h10000;  // H2C descriptor location at PS_axi0 0x10000
	 desc_addr_c2h = axi_port0 + 32'h11000; // C2H descriptor location at PS_axi0  0x11000

	 case (port_sel[2:0]) 
	   0 : begin h2c_dst_address = axi_port0 +32'h2000;  c2h_src_address = axi_port0 +32'h2000; end
	   1 : begin h2c_dst_address = axi_port1;  c2h_src_address = axi_port1; end
	   2 : begin h2c_dst_address = axi_port2;  c2h_src_address = axi_port2; end
	   3 : begin h2c_dst_address = axi_port3;  c2h_src_address = axi_port3; end
	   //	4 : begin h2c_dst_address = ps_axi_0 +32'h2000;   c2h_src_address = ps_axi_0 +32'h2000; end
	   //	5 : begin h2c_dst_address = ps_axi_1;   c2h_src_address = ps_axi_1; end
	   default : begin h2c_dst_address = axi_port0;  c2h_src_address = axi_port0; end
	 endcase // case (port_sel)
         
	 `uvm_info("***** Start HDMA LL transfer parameters", $sformatf("Chan = %d. data port select = %d, HDMA read_base_addr = 0x%h, HDMA write_base_addr = 0x%h, transfer size = %d, h2c_src_addr = 0x%h, h2c_dst_address = 0x%h, c2h_src_addr = 0x%h, c2h_dst_addr 0x%h", chn, port_sel, rd_chn_base_addr, wr_chn_base_addr, txfr_size, h2c_src_address, h2c_dst_address, c2h_src_address, c2h_dst_address), UVM_NONE)
	 
	 // gen LL dscritpor for Read H2C // DSC in bar 0 (AXI_port 0)
	 gen_ll_dsc(H2C, dsc_port, desc_addr_h2c, h2c_src_address, h2c_dst_address, txfr_size);

	 // gen LL dscritpor for Write C2H
	 gen_ll_dsc(C2H, dsc_port, desc_addr_c2h, c2h_src_address, c2h_dst_address, txfr_size);

	 //LL DMA context settings for Read H2C
	 hdma_ll_ctext_program(H2C, rd_chn_base_addr, desc_addr_h2c, tot_dsc);   // H2C desc location at PS_axi0
	 
	 hdma_chk_txfr_done(H2C, rd_chn_base_addr);
	 `uvm_info("-- H2C LL DMA transfer Completed. ", $sformatf("Chan = %d. Chn_base_addr = 0x%h", chn, rd_chn_base_addr), UVM_NONE)

	 hdma_ll_ctext_program(C2H, wr_chn_base_addr, desc_addr_c2h, tot_dsc);  // C2H desc location at PS_axi0 +0x1000
	 
	 hdma_chk_txfr_done(C2H, wr_chn_base_addr);
	 `uvm_info("-- C2H LL DMA transfer Completed. ", $sformatf("Chan = %d. Chn_base_addr = 0x%h", chn, wr_chn_base_addr), UVM_NONE)

      end // for (int i; i = 0 ;i <5 ; i++)
      
    phase.drop_objection(this);
   endtask // main_phase
   
endclass // test_ll_hdma

   
