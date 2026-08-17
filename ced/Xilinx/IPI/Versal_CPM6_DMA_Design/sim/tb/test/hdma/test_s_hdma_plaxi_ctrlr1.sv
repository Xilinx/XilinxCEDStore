class test_s_hdma_plaxi_ctrlr1 extends test_hdma_tasks;
//class test_s_hdma_aximm extends test_basic;

  `uvm_component_utils(test_s_hdma_plaxi_ctrlr1);

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
   logic  msi_int;
   logic  msix_int;
    bit [1:0] dut_ctrlr_en;
   
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    // Default each DUT controller to enabled, which affects CDO programming
      dut_ctrlr_en[0] = 1'b0; 
      dut_ctrlr_en[1] = 1'b1;

    `uvm_info("---- Which Controler enabled.  ---- ", $sformatf("Controler %b is enabled", dut_ctrlr_en[1:0]), UVM_NONE)
     
    for (int ii=0; ii<2; ii++) begin
      // VIP as RP
      vip_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
      // DUT as EP
      dut_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
    end
  endfunction

   virtual function void connect_phase(uvm_phase phase);
      phase.raise_objection(this);
      super.connect_phase(phase);
      
      phase.drop_objection(this);
   endfunction // connect_phase
  
  logic [31:0] data;

  virtual task main_phase(uvm_phase phase);
    vseq_loop  seq_loop;
    super.main_phase(phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name, $sformatf("number of pdevs = %0d",env.shim.container.pdev.size), UVM_NONE)

    /* How to do individual transactions: use one-liner APIs */
     // On AXI port 0 AXI Lite master control going to PL is assiged
     // so need to alocate 64K space for that.
     // total 128 KB aperture size for all axi ports.

    tlp = amd_mem_tlp::type_id::create("tlp");

  // Interrupt setup
  // There are two types of Interupt supported MSI and MSIX.  For MSIX interrupt external PL logic is need to enable MSIX verctor/function etc.. 
  // For MSIX interrupt design needs have MSIX enabled and Table offset should be set.
  // For MSI interrupt framework will setup MSI regiater and it is only for PF0 function.
  // if both msi_int and msix_int is set to 0, poll mode will be used.
  // 
     msi_int = 1;
     msix_int = 0;
             // This is interrupt test, so set to 1.  Set to 0 for polling mode.
              // There are two types of Interupt supported MSI and MSIX.
              // For MSIX interrupt external PL logic is need to enable MSIX verctor/function etc.. 
  
  // AXI port 0
     txfr_size = $urandom_range(1, 32'h10000);  // max AX buffer size 32K 0x8000
     chn_num   = $urandom_range(0, 63);
     host_addr = {$urandom, 6'h0};          // Host address
     //txfr_size = 128;
     //chn_num  = 1;
    `uvm_info("---- Simple DMA to AXI0 ---- ", $sformatf("Channel number %d, Size : 0x%d",chn_num, txfr_size), UVM_NONE)
      // H2C on Channel 2 port 0
      s_hdma_h2c_transfer_start(chn_num, host_addr, 64'h050000010000, txfr_size, msi_int, msix_int);

      // C2H on Channel 4 port 0 
      s_hdma_c2h_transfer_start(chn_num, 64'h050000010000, host_addr, txfr_size, msi_int, msix_int);

     // AXI port 1
      txfr_size = $urandom_range(1, 32'h10000);
      chn_num   = $urandom_range(0, 63);
      host_addr = {$urandom, 6'h0}; 
      txfr_size = 128;
      //chn_num  = 1;
               // Host address
      `uvm_info("---- Simple DMA to AXI1 ---- ", $sformatf("Channel number %d, Size : 0x%d",chn_num, txfr_size), UVM_NONE)

      // H2C on Channel 3 port 1
      s_hdma_h2c_transfer_start(chn_num, host_addr, 64'h050000020000, txfr_size, msi_int, msix_int);

      // C2H on Channel 5 port 1 
      s_hdma_c2h_transfer_start(chn_num, 64'h050000020000, host_addr, txfr_size, msi_int, msix_int);

     // AXI port 2
      txfr_size = $urandom_range(1, 32'h10000);
      chn_num   = $urandom_range(0, 63);
      host_addr = {$urandom, 6'h0};          // Host address
      `uvm_info("---- Simple DMA to AXI2 ---- ", $sformatf("Channel number %d, Size : 0x%d",chn_num, txfr_size), UVM_NONE)

      // H2C on Channel 6 port 2
      s_hdma_h2c_transfer_start(chn_num, host_addr, 64'h050000040000, txfr_size, msi_int, msix_int);

      // C2H on Channel 7 port 2 
      s_hdma_c2h_transfer_start(chn_num, 64'h050000040000, host_addr, txfr_size, msi_int, msix_int);

     // AXI port 3
      txfr_size = $urandom_range(1, 32'h10000);
      chn_num   = $urandom_range(0, 63);
      host_addr = {$urandom, 6'h0};          // Host address
      `uvm_info("---- Simple DMA to AXI3 ---- ", $sformatf("Channel number %d, Size : 0x%d",chn_num, txfr_size), UVM_NONE)

      // H2C on Channel 6 port 2
      s_hdma_h2c_transfer_start(chn_num, host_addr, 64'h050000060000, txfr_size, msi_int, msix_int);

      // C2H on Channel 7 port 2 
      s_hdma_c2h_transfer_start(chn_num, 64'h050000060000, host_addr, txfr_size, msi_int, msix_int);
     

//    seq_loop = vseq_loop::type_id::create("seq_loop");
//    seq_loop.tlp      = tlp;
//    seq_loop.loop_cnt = 8;
//    seq_loop.start(env.shim.vsqr);
  
    phase.drop_objection(this);
  endtask 

endclass
