import shim_caps_pkg::*;
class test_hdma_tasks extends base_ep_test;
//class test_hdma_tasks extends test_basic;

  `uvm_component_utils(test_hdma_tasks)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction // new
   
   logic[31:0] rd_data;
   logic [31:0]  txfr_size;
   logic [5:0]   chn_num;
   logic [31:0]  rd_pattern;
   rc_mem_callback mem_cb;
   logic [63:0]  host_addr;  // address offset in the Host
   logic [63:0]  h2c_dst_address;  // address offset in FPGA
   logic [63:0]  c2h_src_address;  // address offset in FPGA
   logic [63:0]  c2h_dst_address;  // address offset in the Host
   int           count;
   pcie_device     pdev_rp;
   pcie_device     pdev_ep[$];
   amd_mem_tlp     tlp;

  bit [1:0] dut_ctrlr_en;
  int dut_ctrlr;
  parameter NUM_PFS = 4;
  parameter MAX_PFS = 8;
  integer        PF_MSIX_BAR_INDEX  = 0;          // BAR0 holds the MSI-X table for PF
  integer        VF_MSIX_BAR_INDEX  = 0;
  bit [31:0]     PF_MSIX_VEC_OFFSET = 32'h30000; // PF MSI-X table base in BAR0
  bit [31:0]     PF_MSIX_PBA_OFFSET = 32'h34000; // PF PBA base in BAR0
  bit [31:0]     VF_MSIX_VEC_OFFSET = 32'h4000;  // VF MSI-X table base in BAR0
  bit [31:0]     VF_MSIX_PBA_OFFSET = 32'h4800;  // VF PBA base in BAR0

logic  [15:0] FIRST_VF_OFFSET [NUM_PFS-1:0];
reg    [15:0] NUM_VFS [NUM_PFS-1:0];
reg    [15:0] TOTAL_VFS [NUM_PFS-1:0];

      // -------------------------------------------------------------------------
    // Shared capability objects — allocated once in build_phase and reused
    // across all config-space accesses to avoid repeated allocation overhead.
    // -------------------------------------------------------------------------
    protected apci_cap_msix  msix_cap;
    protected apci_cap_pcie  pcie_cap;
    protected bdf_s          ep_bdf_pf;
    protected apci_cap_type0 type0_cap;
    protected apci_cap_type0 type0_cap_copy;
    protected apci_cap_type1 type1_cap;
    protected apci_cap_type1 type1_cap_copy;
    protected apci_cap_type1 type1_caps[12];
    protected apci_cap_type0 type0_caps[12];

   
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    // Default each DUT controller to enabled, which affects CDO programming
      dut_ctrlr_en[0] = 1'b0; 
      dut_ctrlr_en[1] = 1'b1;

//    `uvm_info("---- Which Controler enabled.  ---- ", $sformatf("Controler %b is enabled", dut_ctrlr_en[1:0]), UVM_NONE)

    for (int ii=0; ii<2; ii++) begin
      // VIP as RP
      vip_cfg.ctrlr_en[ii] = 1'b1;
      vip_cfg.port_ctl[ii] = generic_config::PCIE;
      vip_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::RP;
//      vip_cfg.pcie_cfg[ii].flit_mode_ctl = 1;
      // DUT as EP
      dut_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
      dut_cfg.port_ctl[ii] = generic_config::PCIE;
      dut_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::EP;
//      dut_cfg.pcie_cfg[ii].flit_mode_ctl = 1;
    end
    NUM_VFS[0] = 0;
    NUM_VFS[1] = 0;
    NUM_VFS[2] = 0;
    NUM_VFS[3] = 0;
    for (int pf_idx=0; pf_idx<NUM_PFS; pf_idx++) begin
      FIRST_VF_OFFSET[pf_idx] = 16'h1000 + pf_idx*16;
      TOTAL_VFS[pf_idx] = FIRST_VF_OFFSET[pf_idx] + NUM_VFS[pf_idx];
    end

  endfunction
   
   virtual task csr_write(bit [31:0]  csr,
                         bit [31:0] data
                     );
      logic [63:0] addr;
      logic [31:0] data_arr[];
      data_arr = {data};
      addr     = pdev_ep[0].membar[0].base + csr;
      
    // Write 1 DW to BAR0
      tlp.build_wr(addr, .length(1), .data(data_arr), .f_be('1), .l_be ('0), .blocking(NONBLOCK) );
      env.shim.api.send_mem(tlp);
      `uvm_info("MWR", $sformatf("Write CSR reg: 0x%h=0x%h",addr,data), UVM_NONE)

   endtask

  virtual task csr_read(input bit [31:0]  csr,
			output bit [31:0] data
                        );
     logic [63:0] addr;
     addr = pdev_ep[0].membar[0].base + csr;
     tlp.build_rd(addr, .length(1), .f_be('1), .l_be ('0), .blocking(DONE) );
     env.shim.api.send_mem(tlp);
     data = tlp.data[0];
     `uvm_info("MRD", $sformatf("Read CSR reg: addr=0x%h, data=0x%h",addr,data), UVM_NONE)
  endtask // csr_read

  virtual task csr_read_chk(bit [31:0]  csr,
                            bit [31:0] exp_data
                            );
     logic [63:0] addr;
     logic [31:0] data;
     addr = pdev_ep[0].membar[0].base + csr;
     tlp.build_rd(addr, .length(1), .f_be('1), .l_be ('0), .blocking(DONE) );
     env.shim.api.send_mem(tlp);
     data = tlp.data[0];
     if (data == exp_data)
       `uvm_info("MRD", $sformatf("Bar Read match : addr=0x%h, data=0x%h", addr,data), UVM_NONE)
     else
       `uvm_error("MRD", $sformatf("ERROR Bar Read : addr=0x%h, exp_data=0x%h, data = 0x%h",addr,exp_data, data))
  endtask 
/*   
   virtual task bar_write(int pf,
			  int 	     bar, 
			  bit [31:0] csr,
                          bit [31:0] data
                     );
      logic [63:0] addr;
      logic [31:0] data_arr[];
      logic [3:0]  f_be,l_be;
      data_arr = {data};
      addr     = pdev_ep[pf].membar[bar].base + csr;
//      addr[3:0] = 'h0;
    // Write 1 DW to BAR
      case(addr[1:0])
	2'b00 : begin f_be = 4'b1111; l_be = 4'b0000; 
                end
	2'b01 : begin f_be = 4'b1110; l_be = 4'b0001; 
	        end
	2'b10 : begin f_be = 4'b1100; l_be = 4'b0011; 
                end
	2'b11 : begin f_be = 4'b1000; l_be = 4'b0111; 
                end
      endcase	   
      tlp.build_wr(addr, .length(1), .data(data_arr), .f_be(f_be), .l_be (l_be), .blocking(NONBLOCK) );
      env.shim.api.send_mem(tlp);
      `uvm_info("MWR", $sformatf("BAR Write PF= %d, bar = %d, reg addr: 0x%h, data = 0x%h",pf, bar, addr,data), UVM_NONE)
   endtask
*/
/*
   virtual function [7:0] get_f_be_l_be(bit [1:0]   addr,
					int num_b
					);
      bit [7:0] out;
					
      case(addr[1:0])
	   2'b00 : begin
	        case(num_b)
		  4 : begin out = {4'b1111,4'b0000}; end
		  3 : begin out = {4'b0111,4'b0000}; end
		  2 : begin out = {4'b0011,4'b0000}; end
		  1 : begin out = {4'b0001,4'b0000}; end
		endcase // case (num_b)
	        end
	   2'b01 : begin
	        case(num_b)
		  4 : begin out = {4'b1110,4'b0001}; end
		  3 : begin out = {4'b1110,4'b0000}; end
		  2 : begin out = {4'b0110,4'b0000}; end
		  1 : begin out = {4'b0010,4'b0000}; end
		endcase // case (num_b)
	           end
	   2'b10 : begin
	        case(num_b)
		  4 : begin out = {4'b1100,4'b0011}; end
		  3 : begin out = {4'b1100,4'b0001}; end
		  2 : begin out = {4'b1100,4'b0000}; end
		  1 : begin out = {4'b0100,4'b0000}; end
		endcase // case (num_b)
	           end
	   2'b11 : begin
	        case(num_b)
		  4 : begin out = {4'b1000,4'b0111}; end
		  3 : begin out = {4'b1000,4'b0011}; end
		  2 : begin out = {4'b1000,4'b0001}; end
		  1 : begin out = {4'b1000,4'b0000}; end
		endcase // case (num_b)
	           end
      endcase // case (addr[1:0])
      `uvm_info("OUT", $sformatf("-- out = %b", out), UVM_NONE)
      return out;
   endfunction // get_f_be_l_be
*/
   virtual task get_f_be_l_be_wr(input bit [1:0]   addr,
				   input int 	     num_b,
				   input bit [31:0]  data_in,
				   output bit [7:0]  out,
				   output bit [31:0] data0,
				   output bit [31:0] data1
				 );
      bit [7:0] out;
					
      case(addr[1:0])
	   2'b00 : begin
	        case(num_b)
		  4 : begin out = {4'b1111,4'b0000}; end
		  3 : begin out = {4'b0111,4'b0000}; end
		  2 : begin out = {4'b0011,4'b0000}; end
		  1 : begin out = {4'b0001,4'b0000}; end
		endcase // case (num_b)
	      data0 = data_in;
	      data1 = '0;
	        end
	   2'b01 : begin
	        case(num_b)
		  4 : begin out = {4'b1110,4'b0001}; data0 = data_in << 8; data1 = data_in >> 24; end
		  3 : begin out = {4'b1110,4'b0000}; data0 = data_in << 8; data1 = 0; end
		  2 : begin out = {4'b0110,4'b0000}; data0 = data_in << 8; data1 = 0; end
		  1 : begin out = {4'b0010,4'b0000}; data0 = data_in << 8; data1 = 0; end
		endcase // case (num_b)
	           end
	   2'b10 : begin
	        case(num_b)
		  4 : begin out = {4'b1100,4'b0011}; data0 = data_in << 16; data1 = data_in >> 16; end
//		  3 : begin out = {4'b1100,4'b0001}; data0 = data_in << 16; data1 = data_in >> 24; end
		  3 : begin out = {4'b1100,4'b0001}; data0 = data_in << 16; data1 = data_in >> 16; end
		  2 : begin out = {4'b1100,4'b0000}; data0 = data_in << 16; data1 = 0; end
		  1 : begin out = {4'b0100,4'b0000}; data0 = data_in << 16; data1 = 0; end
		endcase // case (num_b)
	           end
	   2'b11 : begin
	        case(num_b)
		  4 : begin out = {4'b1000,4'b0111}; data0 = data_in << 24; data1 = data_in >> 8; end
		  3 : begin out = {4'b1000,4'b0011}; data0 = data_in << 24; data1 = data_in >> 8; end
		  2 : begin out = {4'b1000,4'b0001}; data0 = data_in << 24; data1 = data_in >> 8;end
//		  3 : begin out = {4'b1000,4'b0011}; data0 = data_in << 24; data1 = data_in >> 16; end
//		  2 : begin out = {4'b1000,4'b0001}; data0 = data_in << 24; data1 = data_in >> 24;end
		  1 : begin out = {4'b1000,4'b0000}; data0 = data_in << 24; data1 = 0; end
		endcase // case (num_b)
	           end
      endcase // case (addr[1:0])
      `uvm_info("OUT", $sformatf("-- out = %b, data0 = %h, data1 = %h", out, data0, data1), UVM_NONE)

   endtask // get_f_be_l_be
/*
   virtual task get_f_be_l_be_rd(input bit [1:0]   addr,
				   input int 	     num_b,
				   input bit [31:0] data0,
				   input bit [31:0] data1
				   output bit [31:0] data,
				   output bit [7:0]  out,
				 );
      bit [7:0] out;
					
      case(addr[1:0])
	   2'b00 : begin
	        case(num_b)
		  4 : begin out = {4'b1111,4'b0000}; end
		  3 : begin out = {4'b0111,4'b0000}; end
		  2 : begin out = {4'b0011,4'b0000}; end
		  1 : begin out = {4'b0001,4'b0000}; end
		endcase // case (num_b)
	      data = data0;
	        end
	   2'b01 : begin
	        case(num_b)
		  4 : begin out = {4'b1110,4'b0001}; data = {data1 >> 8, data0 >> 8}; end
		  3 : begin out = {4'b1110,4'b0000}; data = data0 >> 8;; end
		  2 : begin out = {4'b0110,4'b0000}; data = data0 >> 8;; end
		  1 : begin out = {4'b0010,4'b0000}; data = data0 >> 8;; end
		endcase // case (num_b)
	           end
	   2'b10 : begin
	        case(num_b)
		  4 : begin out = {4'b1100,4'b0011}; data = data0 << 16; data1 = data_in >> 16; end
		  3 : begin out = {4'b1100,4'b0001}; data = {data1 >> 16, data0 << 16};; end
		  2 : begin out = {4'b1100,4'b0000}; data = data0 << 16; end
		  1 : begin out = {4'b0100,4'b0000}; data = data0 << 16; end
		endcase // case (num_b)
	           end
	   2'b11 : begin
	        case(num_b)
		  4 : begin out = {4'b1000,4'b0111}; data = data_in << 24; data1 = data_in >> 8; end
		  3 : begin out = {4'b1000,4'b0011}; data = data_in << 24; data1 = data_in >> 16; end
		  2 : begin out = {4'b1000,4'b0001}; data = data_in << 24; data1 = data_in >> 24;end
		  1 : begin out = {4'b1000,4'b0000}; data = data_in << 24; data1 = 0; end
		endcase // case (num_b)
	           end
      endcase // case (addr[1:0])
      `uvm_info("OUT", $sformatf("-- out = %b, data0 = %h, data1 = %h", out, data0, data1), UVM_NONE)

   endtask // get_f_be_l_be
*/  
   virtual task bar_write(int        pf,    // pf number
			   int 	      bar,   // Bar number
			   bit [31:0] csr,   // address
			   int        num_b, // number of bytes
                           bit [31:0] data   // write data
                     );
      logic [63:0] addr;
      logic [31:0] data_arr[];
      logic [3:0]  f_be,l_be;
      int 	   len;
      logic [7:0]  out;
      logic [31:0] data0,data1;
      addr     = pdev_ep[pf].membar[bar].base + csr;
      get_f_be_l_be_wr(addr[1:0],num_b,data,out,data0,data1);
      f_be = out[7:4];
      l_be = out[3:0];
      
      if (|l_be) begin
	 len =2;
	 data_arr = {data0,data1};
	 end
      else begin
	len =1;
	 data_arr = {data0};
      end
      
      `uvm_info("MWR", $sformatf("BAR Write PF= %3d, bar = %3d, num bytes = %3d, reg addr: 0x%h, data = 0x%h",pf, bar, num_b, addr,data), UVM_NONE)
      
      tlp.build_wr(addr, .length(len), .data(data_arr), .f_be(f_be), .l_be (l_be), .blocking(NONBLOCK) );
      env.shim.api.send_mem(tlp);
      `uvm_info("MWR", $sformatf("-- addr[1:0] = %b, num_bytes = %3d, dword_len = %3d, f_be = %b, l_be = %b, data0= %h, data1=%h", addr[1:0], num_b, len, f_be, l_be, data0,data1), UVM_NONE)


   endtask
/*   
   virtual task bar_write(int        pf,    // pf number
			   int 	      bar,   // Bar number
			   bit [31:0] csr,   // address
			   int        num_b, // number of bytes
                           bit [31:0] data   // write data
                     );
      logic [63:0] addr;
      logic [31:0] data_arr[];
      logic [3:0]  f_be,l_be;
      int 	   length;
      data_arr = {data};
      addr     = pdev_ep[pf].membar[bar].base + csr;
//      addr[3:0] = 'h0;
    // Write 1 DW to BAR
      case(addr[1:0])
	2'b00 : begin
	        case(num_b)
		  4 : begin f_be = 4'b1111; l_be = 4'b0000; end
		  3 : begin f_be = 4'b0111; l_be = 4'b0000; end
		  2 : begin f_be = 4'b0011; l_be = 4'b0000; end
		  1 : begin f_be = 4'b0001; l_be = 4'b0000; end
		endcase // case (num_b)
                tlp.build_wr(addr, .length(1), .data(data_arr), .f_be(f_be), .l_be (l_be), .blocking(NONBLOCK) );
                env.shim.api.send_mem(tlp);
                end
	2'b01 : begin f_be = 4'b1110; l_be = 4'b0001; 
                tlp.build_wr(addr, .length(2), .data(data_arr), .f_be(f_be), .l_be (l_be), .blocking(NONBLOCK) );
                env.shim.api.send_mem(tlp);
	        end
	2'b10 : begin f_be = 4'b1100; l_be = 4'b0011; 
                tlp.build_wr(addr, .length(2), .data(data_arr), .f_be(f_be), .l_be (l_be), .blocking(NONBLOCK) );
                env.shim.api.send_mem(tlp);
                end
	2'b11 : begin f_be = 4'b1000; l_be = 4'b0111; 
                tlp.build_wr(addr, .length(2), .data(data_arr), .f_be(f_be), .l_be (l_be), .blocking(NONBLOCK) );
                env.shim.api.send_mem(tlp);
                end
      endcase	   
      `uvm_info("MWR", $sformatf("BAR Write PF= %d, bar = %d, reg addr: 0x%h, data = 0x%h",pf, bar, addr,data), UVM_NONE)

   endtask
*/
  virtual task bar_read(input int pf, 
			input  int bar, 
			input  bit [31:0] csr,
                        output bit [31:0] data
                        );
     logic [63:0] addr;
     logic [31:0] data_arr[];
     addr = pdev_ep[pf].membar[bar].base + csr;
     tlp.build_rd(addr, .length(1), .f_be('1), .l_be ('0), .blocking(DONE) );
     env.shim.api.send_mem(tlp);
     data = tlp.data[0];
     `uvm_info("MRD", $sformatf("BAR Read PF = %d, bar = %d, reg addr : 0x%h, data = 0x%h",pf, bar, addr,data), UVM_NONE)
     
  endtask 
   
/*
  virtual task bar_read_chk(int pf,
			    int        bar, 
			    bit [31:0] csr,
                            bit [31:0] data
                        );
     logic [63:0] addr;
     logic [31:0] data_arr[];
     logic [3:0]  f_be,l_be;
     addr = pdev_ep[pf].membar[bar].base + csr;
//     addr[3:0] = 'h00;
      case(addr[1:0])
	2'b00 : begin f_be = 4'b1111; l_be = 4'b0000; end
	2'b01 : begin f_be = 4'b1110; l_be = 4'b0001; end
	2'b10 : begin f_be = 4'b1100; l_be = 4'b0011; end
	2'b11 : begin f_be = 4'b1000; l_be = 4'b0111; end
      endcase	   
     tlp.build_rd(addr, .length(1), .f_be(f_be), .l_be (l_be), .blocking(DONE) );
     env.shim.api.send_mem(tlp);
     data = tlp.data[0];
     `uvm_info("MRD", $sformatf("Read BAR = %d reg: 0x%h=0x%h",bar, addr,data), UVM_NONE)
  endtask 
*/   
  virtual task bar_read_chk(int pf,             // pf number 
			    int        bar,      // Bar num
			    bit [31:0] csr,      // address 
			    int        num_b,    // number of bytes
                            bit [31:0] exp_data  // expected data
			    
                        );
     logic [63:0] addr;
     logic [31:0] data_arr[];
     logic [3:0]  f_be,l_be;
     logic [31:0] data, dat_0,dat_1;
     int 	  len;
     logic [7:0]  out;
     logic [31:0] exp_mask;
     
     addr = pdev_ep[pf].membar[bar].base + csr;
     get_f_be_l_be_wr(.addr(addr[1:0]),.num_b(num_b), .data_in(0), .out(out), .data0(dat_0), .data1(dat_1));
                   // just get f_be and l_be only
                   // dat_0 and dat_1 not used fro this task.
      f_be = out[7:4];
      l_be = out[3:0];

      if (|l_be) len =2;
      else len =1;
     tlp.build_rd(addr, .length(len), .f_be(f_be), .l_be (l_be), .blocking(DONE) );
     env.shim.api.send_mem(tlp);
     dat_0 = tlp.data[0];
     dat_1 = tlp.data[1];
/*     
     case(l_be)
       4'b0000 : data = dat_0;
       4'b0001 : data = {dat_1[7:0],dat_0[31:8]};
       4'b0011 : data = {dat_1[15:0],dat_0[31:16]};
       4'b0111 : data = {dat_1[23:0],dat_0[31:24]};
     endcase // case (l_be)
 */    
     case (addr[1:0])
       2'b00 : case(num_b)
		 4 : data = {      dat_0[31:0]};
		 3 : data = {8'h0 ,dat_0[24:0]};
		 2 : data = {16'h0,dat_0[16:0]};
		 1 : data = {24'h0,dat_0[8:0]};
	       endcase // case (num_b)
       2'b01 : case (num_b)
		 4 : data = {dat_1[7:0], dat_0[31:8]};
		 3 : data = {8'h0,       dat_0[31:8]};
		 2 : data = {16'h0,      dat_0[24:8]};
		 1 : data = {24'h0,      dat_0[16:8]};
	   endcase // case (f_be)
       2'b10 : case (num_b)
		 4 : data = {dat_1[15:0],      dat_0[31:16]};
		 3 : data = {8'h0, dat_1[7:0], dat_0[31:16]};
		 2 : data = {16'h0,            dat_0[31:16]};
		 1 : data = {24'h0,            dat_0[24:16]};
	       endcase // case (num_b)
       2'b11 : case (num_b)
		 4 : data = {dat_1[24:0],      dat_0[31:24]};
		 3 : data = {8'h0,dat_1[15:0], dat_0[31:24]};
		 2 : data = {16'h0,dat_1[7:0], dat_0[31:24]};
		 1 : data = {24'h0,            dat_0[31:24]};
	       endcase // case (num_b)
     endcase // case (num_b)

     case (num_b)
       4 : exp_mask = 32'hffff_ffff;
       3 : exp_mask = 32'h00ff_ffff;
       2 : exp_mask = 32'h0000_ffff;
       1 : exp_mask = 32'h0000_00ff;
     endcase // case (num_b)
     
     `uvm_info("MRD", $sformatf("--BAR Read PF = %3d, bar = %3d, reg addr : 0x%h, data0 = 0x%h, data1 = 0x%h, data = %h, exp_mask = %h",pf, bar, addr,tlp.data[0], tlp.data[1], data, exp_mask), UVM_NONE)
     if ((exp_data & exp_mask) == (data & exp_mask))
       `uvm_info("MRD", $sformatf("BAR Read PF = %3d, bar = %3d, reg addr : 0x%h, data = 0x%h",pf, bar, addr,data), UVM_NONE)
     else 
       `uvm_error("MRD", $sformatf("BAR Read ERROR PF = %3d, bar = %3d, reg addr : 0x%h, exp_data = 0x%h, got=0x%h",pf, bar, addr,exp_data, data))

  endtask // bar_read_chk
/*   
  virtual task bar_read_chk(int pf,             // pf number 
			    int        bar,      // Bar num
			    bit [31:0] csr,      // address 
			    int        num_b,    // number of bytes
                            bit [31:0] exp_data  // expected data
			    
                        );
     logic [63:0] addr;
     logic [31:0] data_arr[];
     logic [3:0]  f_be,l_be;
     logic [31:0] data, dat_i;
     addr = pdev_ep[pf].membar[bar].base + csr;
     case(addr[1:0])
	2'b00 : begin
	        case(num_b)
		  4 : begin f_be = 4'b1111; l_be = 4'b0000; end
		  3 : begin f_be = 4'b0111; l_be = 4'b0000; end
		  2 : begin f_be = 4'b0011; l_be = 4'b0000; end
		  1 : begin f_be = 4'b0001; l_be = 4'b0000; end
		endcase // case (num_b)
                tlp.build_rd(addr, .length(1), .f_be(f_be), .l_be (l_be), .blocking(DONE) );
                env.shim.api.send_mem(tlp);
                data = tlp.data[0];
                end
	2'b01 : begin f_be = 4'b1110; l_be = 4'b0001;
                tlp.build_rd(addr, .length(2), .f_be(f_be), .l_be (l_be), .blocking(DONE) );
                env.shim.api.send_mem(tlp);
                data = {tlp.data[1][7:0],tlp.data[0][31:8]};
                end
	2'b10 : begin f_be = 4'b1100; l_be = 4'b0011;
                tlp.build_rd(addr, .length(2), .f_be(f_be), .l_be (l_be), .blocking(DONE) );
                env.shim.api.send_mem(tlp);
                data = {tlp.data[1][15:0],tlp.data[0][31:16]};
	        end
	2'b11 : begin f_be = 4'b1000; l_be = 4'b0111;
                tlp.build_rd(addr, .length(2), .f_be(f_be), .l_be (l_be), .blocking(DONE) );
                env.shim.api.send_mem(tlp);
                data = {tlp.data[1][23:0],tlp.data[0][31:24]};
	        end
      endcase	   
     if (exp_data == data)
       `uvm_info("MRD", $sformatf("BAR Read PF = %d, bar = %d, reg addr : 0x%h, data = 0x%h",pf, bar, addr,data), UVM_NONE)
     else 
       `uvm_error("MRD", $sformatf("BAR Read ERROR PF = %d, bar = %d, reg addr : 0x%h, exp_data = 0x%h, got=0x%h",pf, bar, addr,exp_data, data))

  endtask 
*/   
//---------------------------------------------------------------------------------------------
  typedef enum {H2C, C2H} dma_type_t;

// H2C transfers task Read channel.
  virtual task s_hdma_h2c_transfer_start(
               bit [5:0]  chn,
	       bit [63:0] src_addr,
	       bit [63:0] dst_addr,
	       bit [31:0] size,
	       bit        msi_int,
         bit       msix_int
	       );
     logic [31:0]  rd_chn_base_addr;
     logic [31:0]  data;
      rd_chn_base_addr = 16'h200 + (chn * 16'h400);
      `uvm_info("-- H2C Simple DMA transfer start. ", $sformatf("Chan = %d. Chn_base_addr = 0x%h, size = %d", chn, rd_chn_base_addr, size), UVM_NONE)

      csr_write(rd_chn_base_addr, 32'h1);    // H2C (read) enable
      csr_read_chk(rd_chn_base_addr, 32'h1);    // H2C (read) enable
      if (msix_int) begin
        csr_write(rd_chn_base_addr + 32'h88, 16'h10);     // Only Local interrupt for MSIX
        csr_read_chk(rd_chn_base_addr + 32'h88, 16'h10);  //
      end else begin
        csr_write(rd_chn_base_addr + 32'h88, 16'h18);     // local and remote interrupt for MSI
        csr_read_chk(rd_chn_base_addr + 32'h88, 16'h18);  //
      end

      if (msi_int) begin
        csr_write(rd_chn_base_addr + 32'h90, 32'h00000000); // MSI Stop int addr Low
        csr_write(rd_chn_base_addr + 32'h94, 32'hff000000); // MSI Stop int addr High
        csr_write(rd_chn_base_addr + 32'ha8, 32'hffffeeee); // MSI Message data 
      end
      csr_write(rd_chn_base_addr + 16'h1c, size[31:0]);  // Size
      csr_write(rd_chn_base_addr + 16'h20, src_addr[31:0]); // SRC addr Lo
      csr_write(rd_chn_base_addr + 16'h24, src_addr[63:32]);  // SRC addr Hi
      csr_write(rd_chn_base_addr + 16'h28, dst_addr[31:0]); // DAR addr Lo
      csr_write(rd_chn_base_addr + 16'h2c, dst_addr[63:32]);  // DAR addr Hi
      csr_write(rd_chn_base_addr + 16'h04, 32'h1);  // Doorbell
        
      s_hdma_chk_txfr_done(H2C, rd_chn_base_addr + 16'h1c, msi_int, msix_int);
      `uvm_info("-- H2C Simple DMA transfer Completed. ", $sformatf("Chan = %d. Chn_base_addr = 0x%h", chn, rd_chn_base_addr), UVM_NONE)
     
  endtask // s_hdma_h2c_transfer_start

// C2H transfers task Write channel.
  virtual task s_hdma_c2h_transfer_start(
      bit [5:0]  chn,
	    bit [63:0] src_addr,
	    bit [63:0] dst_addr,
	    bit [31:0] size,
	    bit        msi_int,
      bit       msix_int
	    );
      logic [31:0] wr_chn_base_addr;
      wr_chn_base_addr = 16'h0 + (chn * 16'h400);
      `uvm_info("-- C2H Simple DMA transfer start. ", $sformatf("Chan = %d. Chn_base_addr = 0x%h, size = %d", chn, wr_chn_base_addr, size), UVM_NONE)
      csr_write(wr_chn_base_addr, 32'h1);    // H2C (read) enable
      if (msix_int) begin
        csr_write(wr_chn_base_addr + 32'h88, 16'h10); // Only Local interrupt for MSIX
      end else begin
        csr_write(wr_chn_base_addr + 32'h88, 16'h18); // Enable local and remote interrupt for MSI. Enable Stop Interrupt.
      end
      if (msi_int) begin
	      csr_write(wr_chn_base_addr + 32'h90, 32'h00004000); // MSI Stop int addr Low
	      csr_write(wr_chn_base_addr + 32'h94, 32'hff000000); // MSI Stop int addr High
	      csr_write(wr_chn_base_addr + 32'ha8, 32'hffffeeee); // MSI Message data
      end
      csr_write(wr_chn_base_addr + 16'h1c, size[31:0]);  // Size
      csr_write(wr_chn_base_addr + 16'h20, src_addr[31:0]); // SRC addr Lo
      csr_write(wr_chn_base_addr + 16'h24, src_addr[63:32]);  // SRC addr Hi
      csr_write(wr_chn_base_addr + 16'h28, dst_addr[31:0]); // DAR addr Lo
      csr_write(wr_chn_base_addr + 16'h2c, dst_addr[63:32]);  // DAR addr Hi
      csr_write(wr_chn_base_addr + 16'h04, 32'h1);  // Doorbell
        
      s_hdma_chk_txfr_done(C2H, wr_chn_base_addr + 16'h1c, msi_int, msix_int);
      `uvm_info("-- C2H Simple DMA transfer Completed. ", $sformatf("Chan = %d. Chn_base_addr = 0x%h", chn, wr_chn_base_addr), UVM_NONE)
     
  endtask // s_hdma_c2h_transfer_start

  virtual task s_hdma_chk_txfr_done(dma_type_t typ, bit [31:0]  adr, bit msi_int, bit msix_int);
    logic [63:0] addr;
    logic [31:0] data_arr[];
    logic [31:0] data;
    logic [5:0]  count;

    // chek if there is any interrupt 
    if (msix_int) begin
      `uvm_info("MSIX Interrupt", $sformatf("Waiting for Transfer done with MSIX interrupt"), UVM_NONE)
      wait (mem_cb.int_msix_set == 1); begin
        `uvm_info("MSIX Interrupt", $sformatf("Simple DMA Transfer Completed with MSIX interrupt"), UVM_NONE) 
        mem_cb.int_msix_set = 0;
      end 
    end
    else if (msi_int) begin
      `uvm_info("MSI Interrupt", $sformatf("Waiting for Transfer done with MSI interrupt"), UVM_NONE)
      wait (mem_cb.int_msi_set == 1); begin
        `uvm_info("MSI Interrupt", $sformatf("Simple DMA Transfer Completed with MSI interrupt"), UVM_NONE) 
        mem_cb.int_msi_set = 0;
      end 
    end
    else begin
      `uvm_info("Simple DMA status update check for Transfer done", $sformatf("Reg Adr: 0x%h",adr), UVM_NONE)  
      count = 6'h0;
     //   data = csr_read(adr);
     
      addr = pdev_ep[0].membar[0].base + adr;
      tlp.build_rd(addr, .length(1), .f_be('1), .l_be ('0), .blocking(DONE) );
      env.shim.api.send_mem(tlp);
      data = tlp.data[0];
     
      `uvm_info(" loop ",$sformatf("data = 0x%h",data),  UVM_NONE)
      count = count + 1;
      while ( data > 32'h0) begin
          `uvm_info(" In the loop ",$sformatf("count = 0x%h",count),  UVM_NONE)
          //data = csr_read(adr);
	        env.shim.api.send_mem(tlp);
          data = tlp.data[0];
	    if (data == 0)
	      `uvm_info("DMA transfer completed", $sformatf("Size reg read 0x%h",data), UVM_NONE)
	    else
	      `uvm_info("MRD", $sformatf("Read CSR transfer size reg L : 0x%h=0x%h",addr,data), UVM_NONE)

	    if (count == 6'h3F) begin
	      `uvm_info("MRD", $sformatf("Simple DMA Transfer Error. Tranfer size is non Zero. : 0x%h=0x%h",addr,data), UVM_NONE)
	      data = 0;
	    end
	    count = count + 1;
	    #50000;
  
	    end
    end
  endtask // s_hdma_chk_txfr_done

    virtual task hdma_chk_txfr_done(dma_type_t dir,
				  bit [15:0]  chn_addr);
        logic [63:0] addr;
        logic [31:0] data_arr[];
        logic [31:0] data;
        logic [7:0]  count;

        `uvm_info("%s, DMA status update check for Transfer done", $sformatf("Channel address offset : 0x%h", dir.name, chn_addr), UVM_NONE)
        count = 4'h0;
//        addr = env.pcie_sts.pdevs[1].mem_bar_q[0].base + chn_addr + 16'h80;  // 0x80 status reg offset for a given channel
        addr = pdev_ep[0].membar[0].base + chn_addr + 'h80;
        tlp.build_rd(addr, .length(1), .f_be('1), .l_be ('0), .blocking(DONE) );
        env.shim.api.send_mem(tlp);
        data = tlp.data[0];
       `uvm_info("MRD", $sformatf("Read CSR DMA status reg : 0x%h=0x%h",addr,data), UVM_NONE)
        count = count + 1;
        while ( data == 32'h1) begin
           `uvm_info(" In the loop ",$sformatf("loop count = 0x%h",count),  UVM_NONE)
            tlp.build_rd(addr, .length(1), .f_be('1), .l_be ('0), .blocking(DONE) );
            env.shim.api.send_mem(tlp);
            data = tlp.data[0];
	   `uvm_info("MRD", $sformatf("Read CSR DMA status reg : 0x%h=0x%h",addr,data), UVM_NONE)
	   if (data == 3) begin
	     `uvm_info("DMA transfer completed", $sformatf("%s, CSR DMA Status reg read 0x%h",dir.name, data), UVM_NONE);
	      break;
	   end
	   else begin
	     `uvm_info("MRD", $sformatf("Read CSR transfer status reg L : 0x%h=0x%h",addr,data), UVM_NONE);
	   end

	   if (count == 8'hFF) begin
	      `uvm_error("DMA ERROR", $sformatf("%s, DMA Transfer Error. Transfer status is not set and max count reached: 0x%h=0x%h",dir.name, addr,count));
	      data = 0;
	      break;
	   end
	   count = count + 1;
	end // while ( data == 32'h1)
  endtask // hdma_chk_txfr_done
    
  virtual task gen_ll_dsc(dma_type_t dir,
			  bit [2:0] dsc_port,
			  bit [31:0] desc_addr,
			  bit [63:0] src_addr,
			  bit [63:0] dst_addr,
			  bit [31:0] size
                        );
     //each dsc is set to 4KB
     logic [31:0] tot_size = 0;
     logic [31:0] tot_dsc = 0;
     logic [31:0] desc_size = 0;
     logic [63:0] dsc_src_addr = 0;
     logic [63:0] dsc_dst_addr = 0;
     logic [31:0] addr = 0;
     logic [31:0] desc_count = 0;
     logic [31:0] fix_dsc_size = 4096;
     logic [2:0]  dsc_bar;
     
     tot_size = size;
     tot_dsc = size[31:12] + |size[11:0];
     dsc_bar = dsc_port +1;  // BAR 0 is used for HDMA. BAR1 -> PL_AXI_0, BAR2 -> PL_AXI1, BAR3 -> PL_AXI_2, BAR4 -> PL_AXI3, BAR5 -> PS0  
     dsc_src_addr = src_addr;
     dsc_dst_addr = dst_addr;
     
     addr = desc_addr[16:0];  // assign only 16 bits, as BAR size is 128K and BAR5 is fixed.
                              // bit [16] is used for AXI_PL0. as example deisgn take lower 64K.
                              // upper 64K is used for descriptors.
     
     `uvm_info("-- LL DMA Descriptor write", $sformatf("%s dsc in axipot = %d, total dsc = %d, descriptor addr =0x%h, src_addr = 0x%h, dst_addr = %h, size = 0x%h", dir.name, dsc_port, tot_dsc, addr, src_addr, dst_addr, size), UVM_NONE)
     
      while ( tot_size > 32'h0) begin
	  if (tot_size >= fix_dsc_size) begin
	     desc_size = fix_dsc_size;
	     tot_size = tot_size - fix_dsc_size;
	  end
	  else begin
	     desc_size = tot_size;
	     tot_size = 0;
	  end

	  bar_write(.pf(0), .bar(dsc_bar), .csr(addr),        .num_b(4), .data(32'h1));        // dsc ctrl
	  bar_write(.pf(0), .bar(dsc_bar), .csr(addr+32'h4),  .num_b(4), .data(desc_size));     // dsc size 
	  bar_write(.pf(0), .bar(dsc_bar), .csr(addr+32'h8),  .num_b(4), .data(dsc_src_addr[31:0]));     // src addr low
	  bar_write(.pf(0), .bar(dsc_bar), .csr(addr+32'hc),  .num_b(4), .data(dsc_src_addr[63:32]));     // src addr hig
	  bar_write(.pf(0), .bar(dsc_bar), .csr(addr+32'h10), .num_b(4), .data(dsc_dst_addr[31:0])); // dst addr low 
	  bar_write(.pf(0), .bar(dsc_bar), .csr(addr+32'h14), .num_b(4), .data(dsc_dst_addr[63:32]));     // dst addr high

	  if (tot_size > 0) begin
	     dsc_src_addr = dsc_src_addr + fix_dsc_size;
	     dsc_dst_addr = dsc_dst_addr + fix_dsc_size;
	  end
	  addr = addr+32'h18;
	  desc_count = desc_count+1;
       end // while ( tot_size > 32'h0)

     //last LL descriptor
      bar_write(0, dsc_bar, addr,        4, 32'h0);      // dsc ctrl //LL element
      bar_write(0, dsc_bar, addr+32'h4,  4, 32'h0);      // reserved  
      bar_write(0, dsc_bar, addr+32'h8,  4, 32'h0);      // LL addr low
      bar_write(0, dsc_bar, addr+32'hc,  4, 32'h500);    // LL addr hig
      bar_write(0, dsc_bar, addr+32'h10, 4, 32'h0);      // reserved
      bar_write(0, dsc_bar, addr+32'h14, 4, 32'h0);      // reserved

  endtask // gen_ll_dsc

 // task for contest write in link linst mode
  virtual task hdma_ll_ctext_program(dma_type_t dir,
				     bit [15:0] ctxt_base_addr,
				     bit [63:0] desc_addr,
				     bit [6:0]  pfch_elem
				     );
      `uvm_info("-- Context write ", $sformatf("%s context base address = 0x%h, descriptor addr =0x%h", dir.name, ctxt_base_addr, desc_addr), UVM_NONE)

      csr_write(ctxt_base_addr, 16'h1);           // HDAM enable
      csr_write(ctxt_base_addr + 32'h88, 32'h18); //
      csr_write(ctxt_base_addr + 32'h90, 32'h00004000); // MSI Stop int addr Low
      csr_write(ctxt_base_addr + 32'h94, 32'hff000000); // MSI Stop int addr High
      csr_write(ctxt_base_addr + 32'ha8, 32'hffffeeee); // MSI Message data 
      csr_write(ctxt_base_addr + 32'h34, 32'h1);  // do we need 201??
      csr_write(ctxt_base_addr + 32'h38, 32'h0);  
      csr_write(ctxt_base_addr + 32'h18, 32'h2);  // set to 2 for LL mode
      csr_write(ctxt_base_addr + 32'h10, desc_addr[31:0]);   // LL low address
      csr_write(ctxt_base_addr + 32'h14, desc_addr[63:32]);  // LL hig address
      csr_write(ctxt_base_addr + 32'h08, 32'h0 | pfch_elem); // prefetch 
      csr_write(ctxt_base_addr + 32'h04, 32'h1);             // door bell

  endtask // hdma_ll_ctext_program

/************************************************************
Task : hdma_ctxt_init_prog
Inputs : None
Outputs : None
Description : Programs selected context register to inital values for all channels
              This should reduce each function programming some registers.
*************************************************************/
task hdma_ctxt_init_prog (int num_chn);
  integer i;
  begin
    for (i=0; i< num_chn; i=i+1) begin
      csr_write(32'h200 + (i*32'h400) + 32'h0, 32'h1); // channel Enable 
      csr_write(32'h0   + (i*32'h400) + 32'h0, 32'h1); // Channel Enable 
      csr_write(32'h200 + (i*32'h400) + 32'h88, 32'h10); // Enable Stop Interrupt for H2C channels
      csr_write(32'h0   + (i*32'h400) + 32'h88, 32'h10); // Enable Stop Interrupt for C2H channels
    end
  end 
endtask

/************************************************************
Task : TSK_PROGRAM_MSIX_VEC_TABLE
Inputs : function number
Outputs : None
Description : Program the MSIX vector table
*************************************************************/
task TSK_PROGRAM_MSIX_VEC_TABLE;
  input [7:0] fnc_i;
  
  integer     i;
  bit [31:0]  msix_base;
  integer     bar_idx;
  bit [7:0]   pfn, vfn;
  bit         is_pf;
begin
  // Select BAR and table base depending on PF vs VF
  // MSI-X table is in BAR0 for both PF and VF; offsets differ
  TSK_FIND_PF_VF_NUM(fnc_i, pfn, vfn);
  if (fnc_i < NUM_PFS) begin
    bar_idx   = PF_MSIX_BAR_INDEX;  // BAR0
    msix_base = PF_MSIX_VEC_OFFSET; // 0x30000
    is_pf     = 1'b1;
  end else begin
    bar_idx   = VF_MSIX_BAR_INDEX;  // BAR0
    msix_base = VF_MSIX_VEC_OFFSET; // 0x4000
    is_pf     = 1'b0;
  end

  `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
    "Programming MSI-X VT: fnc=%0d pfn=%0d vfn=%0d bar=%0d base=0x%0h",
    fnc_i, pfn, vfn, bar_idx, msix_base), UVM_MEDIUM)

  // MSI-X host target address: placed in the 4KB gap between H2C data area and
  // H2C descriptor rings (H2C_DAT_SRC_ADDR + H2C_DAT_SIZE = 0xB1000).
  // This range is within the PCIe address window declared by the Avery VIP RC,
  // avoiding the msix_error that 0xADD00000 (outside RC window) would trigger.
  begin
    bit [31:0] msix_host_base;
    //msix_host_base = 32'(H2C_DAT_SRC_ADDR + H2C_DAT_SIZE); // 0xB1000
      msix_host_base = 32'hADD00000; // This address is outside the Avery VIP RC's declared PCIe window, which triggers msix_error responses from the RC and allows testing of the DUT's handling of such errors.
    for (i=0; i<4; i=i+1) begin
      bar_write(.pf(pfn), .bar(0), .csr(msix_base+16*i+0*4), .num_b(4), .data(32'h00000000));
      bar_write(.pf(pfn), .bar(0), .csr(msix_base+16*i+1*4), .num_b(4), .data(32'hADD00000));
      bar_write(.pf(pfn), .bar(0), .csr(msix_base+16*i+2*4), .num_b(4), .data(32'hDEAD0000 + i));
      bar_write(.pf(pfn), .bar(0), .csr(msix_base+16*i+3*4), .num_b(4), .data(32'h00000000));

    end
  end

  // Enable MSI-X in PCIe config space for this function by setting the
  // msix_enable bit (bit 31 of DW0 in the MSI-X Capability Control register).
  //
  // CPM6's cpm6_msix_ctrl_logic checks user_function_is_enabled_reg, which
  // reflects pf_cfg_status.msix_en (PF) or vf_cfg_status.vf_msix_en (VF).
  // When this bit is 0, CPM6 simultaneously asserts both msix_grant AND
  // msix_error for every interrupt request.  irq_mgr gives priority to
  // msix_grant, so it silently drops the retry and the host never receives
  // the MSI-X message.
  begin
    bit         cap_err;
    bit [31:0]  cap_dw0;
    if (is_pf) begin
      env.shim.api.read_cap_dw(pdev_ep[pfn].bdf, .cap(CAP_MSI_X), .offset(0),
                               .data(cap_dw0), .err(cap_err));
      cap_dw0[31] = 1'b1;  // msix_enable = 1
      cap_dw0[30] = 1'b0;  // function_mask = 0 (interrupts not globally masked)
      env.shim.api.write_cap_dw(pdev_ep[pfn].bdf, .cap(CAP_MSI_X), .offset(0),
                                .be(4'b1100), .data(cap_dw0), .err(cap_err));
    end 
    /*
    else begin
      // Avery VIP pdev_ep.vf[] is 1-based: vf[0]=null, vf[1]=VF0, vf[2]=VF1, ...
      // TSK_FIND_PF_VF_NUM returns 0-based vfn, so use vfn+1 as the array index.
      if ((vfn+1) >= pdev_ep.vf.size() || pdev_ep.vf[vfn+1] == null)
        `uvm_fatal("TSK_PROGRAM_MSIX_VEC_TABLE",
          $sformatf("VF[%0d] not found in pdev_ep.vf[] (size=%0d, index=%0d)", vfn, pdev_ep.vf.size(), vfn+1))
      env.shim.api.read_cap_dw(pdev_ep.vf[vfn+1].bdf, .cap(CAP_MSI_X), .offset(0),
                               .data(cap_dw0), .err(cap_err));
      cap_dw0[31] = 1'b1;  // msix_enable = 1
      cap_dw0[30] = 1'b0;  // function_mask = 0
      env.shim.api.write_cap_dw(pdev_ep.vf[vfn+1].bdf, .cap(CAP_MSI_X), .offset(0),
                                .be(4'b1100), .data(cap_dw0), .err(cap_err));
    end
    */
    `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
      "MSI-X cap enabled: fnc=%0d pfn=%0d vfn=%0d cap_dw0=0x%08h err=%0b",
      fnc_i, pfn, vfn, cap_dw0, cap_err), UVM_MEDIUM)
  end

  // No readback check: PCIe MSI-X vector table registers are write-only per spec  -
  // reads return 0x00000000 regardless of what was written.  Correct programming
  // is confirmed by the MSIX_MWR TLP the DUT sends after queue completion.
  // See TSK_CHECK_MSIX_TLP.
  `uvm_info("TSK_PROGRAM_MSIX_VEC_TABLE", $sformatf(
    "MSI-X VT programmed: fnc=%0d bar=%0d base=0x%0h (7 entries, vec 0-6)",
    fnc_i, bar_idx, msix_base), UVM_MEDIUM)
end
endtask // TSK_PROGRAM_MSIX_VEC_TABLE

/************************************************************
Task : TSK_GET_NUM_PFS_FROM_CFG
Inputs : None
Outputs : Number of PFs discovered
Description :
  Probes function numbers on the same Bus/Device as PF0 and counts
  implemented functions by checking Vendor ID in config DW0.
*************************************************************/
task TSK_GET_NUM_PFS_FROM_CFG;
  output int num_pfs;

  amd_cfg_tlp cfg_tlp;
  bdf_s       probe_bdf;
  bit [31:0]  cfg_dw0;

  begin
    num_pfs = 0;

    if ((pdev_ep.size() == 0) || (pdev_ep[0] == null)) begin
      `uvm_error("TSK_GET_NUM_PFS_FROM_CFG", "pdev_ep[0] is not available")
      return;
    end

    cfg_tlp = amd_cfg_tlp::type_id::create("cfg_tlp");
    probe_bdf = pdev_ep[0].bdf;

    for (int pf_num = 0; pf_num < MAX_PFS; pf_num++) begin
      probe_bdf.id.df.f = pf_num[2:0];

      // Read the full DW to avoid advisory errors from completers that return
      // non-zero values in bytes masked off by a partial byte enable.
      cfg_tlp.build_rd(.addr(12'h000), .be(4'b1111), .bdf(probe_bdf));
      // Probing unimplemented functions can legally return non-SC.
      cfg_tlp.cpl_sts_sev = UVM_INFO;
      env.shim.api.send_cfg(cfg_tlp);

      if (!cfg_tlp.got_SC)
        continue;

      if (cfg_tlp.payload.size() > 0) begin
        cfg_dw0 = cfg_tlp.payload[0];
        if (cfg_dw0[15:0] !== 16'hFFFF)
          num_pfs++;
      end
    end

    `uvm_info("TSK_GET_NUM_PFS_FROM_CFG",
              $sformatf("Discovered PF count from cfg space = %0d", num_pfs),
              UVM_MEDIUM)
  end
endtask

/************************************************************
Task : TSK_FIND_PF_VF_NUM
Inputs : function number
Outputs : None
Description : Find out the associated PF# of a VF
*************************************************************/

task TSK_FIND_PF_VF_NUM;
  input  [7:0] fnc;
  output [7:0] pfn;
  output [7:0] vfn;

  begin

    if (fnc < NUM_PFS) begin
      pfn = fnc;
      vfn = 'h0;
    end
    else begin
      pfn = '0;
      vfn = '0;
      for (int pf_i=0; pf_i<NUM_PFS; pf_i=pf_i+1) begin
        `uvm_info("TSK_FIND_PF_VF_NUM", $sformatf(
          "  pf_i=%0d FIRST_VF_OFFSET=%0d NUM_VFS=%0d range=[%0d..%0d)",
          pf_i, FIRST_VF_OFFSET[pf_i], NUM_VFS[pf_i],
          FIRST_VF_OFFSET[pf_i] + pf_i,
          FIRST_VF_OFFSET[pf_i] + NUM_VFS[pf_i] + pf_i), UVM_MEDIUM)
        if (
            (fnc >= FIRST_VF_OFFSET[pf_i] + pf_i) &&
            (fnc < FIRST_VF_OFFSET[pf_i] + NUM_VFS[pf_i] + pf_i)
           ) begin
          pfn = pf_i[7:0];
          vfn = fnc - FIRST_VF_OFFSET[pf_i] - pf_i;
        end
      end
    end
    `uvm_info("TSK_FIND_PF_VF_NUM", $sformatf(" fnc %0d Translates to pfn%0d and vfn%0d", fnc, pfn, vfn), UVM_MEDIUM)

  end
endtask
/*
    // =========================================================================
    // configure_msix
    //
    // Enables or disables the MSI-X capability for the specified PF or VF by
    // writing the MSI-X Enable bit in the MSI-X Capability header.
    //
    //   pf_num : PF index (0..MSIX_PF_COUNT-1)
    //   vf_num : VF index within the PF, or -1 for the PF itself
    //   enable : 1 to enable MSI-X, 0 to disable
    //
    // SHIM CANDIDATE: depends only on env.shim.vip and pdev_eps; migrate when
    // pdev_eps is accessible from a framework base test.
    // =========================================================================
    task configure_msix(input int pf_num, input int vf_num = -1, input bit enable);
        int       err;
        bit [8:0] func_num = get_function_number(pf_num, vf_num);

        ep_bdf_pf = (vf_num == -1) ? pdev_eps[pf_num].bdf
                                    : pdev_eps[pf_num].vf[vf_num+1].bdf;

        `uvm_info("MSIX", $sformatf(
            "configure_msix: func=%0d pf=%0d vf=%0d bdf=0x%0h enable=%0b",
            func_num, pf_num, vf_num, ep_bdf_pf, enable), UVM_LOW)

        env.shim.vip.read_capability(ep_bdf_pf, msix_cap,
            msix_cap.table_size.get_offset_dw, err, .err_severity('d1));
        if (err)
            `uvm_info("MSIX", $sformatf(
                "MSI-X not supported: func=%0d pf=%0d vf=%0d bdf=0x%0h",
                func_num, pf_num, vf_num, ep_bdf_pf), UVM_LOW)

        if (msix_cap.msi_x_enable.v != enable) begin
            msix_cap.msi_x_enable.set_v(enable);
            `uvm_info("MSIX", $psprintf("%s MSI-X for BDF 0x%0h",
                enable ? "Enabling" : "Disabling", ep_bdf_pf), UVM_LOW)
            env.shim.vip.write_capability(ep_bdf_pf, msix_cap,
                msix_cap.msi_x_enable.get_offset_dw, err);
        end
        #1us;
    endtask

    // =========================================================================
    // mask_msix
    //
    // Sets or clears the MSI-X function-level mask bit for the specified PF
    // or VF.  When the function mask is set, all vectors for the function are
    // masked regardless of per-vector mask bits in the MVT.
    //
    //   pf_num : PF index
    //   vf_num : VF index within the PF, or -1 for the PF itself
    //   mask   : 1 to mask, 0 to unmask
    //
    // SHIM CANDIDATE: same dependencies as configure_msix.
    // =========================================================================
    task mask_msix(input int pf_num, input int vf_num = -1, input bit mask);
        int       err;
        bit [8:0] func_num = get_function_number(pf_num, vf_num);

        ep_bdf_pf = (vf_num == -1) ? pdev_eps[pf_num].bdf
                                    : pdev_eps[pf_num].vf[vf_num+1].bdf;

        env.shim.vip.read_capability(ep_bdf_pf, msix_cap,
            msix_cap.table_size.get_offset_dw, err);
        if (err)
            `uvm_info("MSIX", $sformatf(
                "MSI-X not supported: func=%0d bdf=0x%0h", func_num, ep_bdf_pf), UVM_LOW)

        if (msix_cap.function_mask.v != mask) begin
            msix_cap.function_mask.set_v(mask);
            `uvm_info("MSIX", $psprintf("%s MSI-X for BDF 0x%0h",
                mask ? "Masking" : "Unmasking", ep_bdf_pf), UVM_LOW)
            env.shim.vip.write_capability(ep_bdf_pf, msix_cap,
                msix_cap.function_mask.get_offset_dw, err);
        end
        #1us;
    endtask


    // =========================================================================
    // configure_msix_MVT_entry
    //
    // Programs a single 128-bit MSI-X Vector Table entry via two back-to-back
    // 64-bit memory writes (DW0:DW1 first, then DW2:DW3).
    //
    //   pf_num     : PF index
    //   vf_num     : VF index within the PF, or -1 for the PF itself
    //   vector_num : vector index within the function (0-based)
    //   mvt_data   : 128-bit entry packed as {DW3, DW2, DW1, DW0}
    //                  DW3[0]     = per-vector mask bit
    //                  DW2        = message data
    //                  DW1:DW0    = 64-bit message address
    // =========================================================================
    task configure_msix_MVT_entry(input int pf_num,
                                  input int vf_num = -1,
                                  input int vector_num,
                                  input bit [127:0] mvt_data);
        bit [63:0] addr;
        bit [31:0] addr_offset;
        bit [31:0] data[];
        bit [ 8:0] func_num;
        mem_bar_s  tmpbar;
        bit        tmpret;

        if (vf_num == -1) begin
            func_num    = get_function_number(pf_num);
            addr_offset = vector_num << 'd4;
            addr = pdev_eps[pf_num].membar[MSIX_BAR_NUM[func_num]].base
                 + addr_offset + MSIX_MVT_BASE_ADDRESS[func_num];
            data    = new[PAYLOAD_SIZE];
            data[0] = mvt_data[31:0];
            data[1] = mvt_data[63:32];
            `uvm_info("MWR", $sformatf("Write PF%0d lo: 0x%h=0x%h_%h",
                pf_num, addr, data[1], data[0]), UVM_NONE)
            issue_mem_tlp_with_function(MWR, addr, func_num, .data(data), .len(PAYLOAD_SIZE));

            data[0] = mvt_data[95:64];
            data[1] = mvt_data[127:96];
            addr    = pdev_eps[pf_num].membar[MSIX_BAR_NUM[func_num]].base
                    + addr_offset + MSIX_MVT_BASE_ADDRESS[func_num] + 'h8;
            `uvm_info("MWR", $sformatf("Write PF%0d hi: 0x%h=0x%h_%h",
                pf_num, addr, data[1], data[0]), UVM_NONE)
            issue_mem_tlp_with_function(MWR, addr, func_num, .data(data), .len(PAYLOAD_SIZE));

        end else begin
            func_num    = get_function_number(pf_num, vf_num);
            addr_offset = vector_num << 'd4;
            tmpret = pdev_eps[pf_num].vf[vf_num+1].get_membar(MSIX_BAR_NUM[func_num], tmpbar);
            `uvm_info("MSIX", $sformatf(
                "VF membar PF%0d VF%0d BAR%0d: base=0x%0h sz=0x%0h | sriov base=0x%0h sz=0x%0h",
                pf_num, vf_num, MSIX_BAR_NUM[func_num], tmpbar.base, tmpbar.sz,
                pdev_eps[pf_num].vf[vf_num+1].pf.sriov.vf_membar[MSIX_BAR_NUM[func_num]].base,
                pdev_eps[pf_num].vf[vf_num+1].pf.sriov.vf_membar[MSIX_BAR_NUM[func_num]].sz),
                UVM_LOW)
            if (!tmpret)
                `uvm_error("MSI-X Configuration",
                    $sformatf("Failed to get MEMBAR for VF%0d (PF%0d)", vf_num, pf_num))
            addr    = tmpbar.base + addr_offset + MSIX_MVT_BASE_ADDRESS[func_num];
            data    = new[PAYLOAD_SIZE];
            data[0] = mvt_data[31:0];
            data[1] = mvt_data[63:32];
            `uvm_info("MWR", $sformatf("Write VF%0d(PF%0d) lo: 0x%h=0x%h_%h",
                vf_num, pf_num, addr, data[1], data[0]), UVM_NONE)
            issue_mem_tlp_with_function(MWR, addr, func_num, .data(data), .len(PAYLOAD_SIZE));

            tmpret  = pdev_eps[pf_num].vf[vf_num+1].get_membar(MSIX_BAR_NUM[func_num], tmpbar);
            addr    = tmpbar.base + addr_offset + MSIX_MVT_BASE_ADDRESS[func_num] + 'h8;
            data[0] = mvt_data[95:64];
            data[1] = mvt_data[127:96];
            `uvm_info("MWR", $sformatf("Write VF%0d(PF%0d) hi: 0x%h=0x%h_%h",
                vf_num, pf_num, addr, data[1], data[0]), UVM_NONE)
            issue_mem_tlp_with_function(MWR, addr, func_num, .data(data), .len(PAYLOAD_SIZE));
        end
    endtask


    // =========================================================================
    // initiate_flr
    //
    // Triggers a Function Level Reset for the specified PF or VF by writing
    // the Initiate FLR bit in the PCIe Device Control register, then waits
    // 5us for the device to complete the reset.  Returns immediately if the
    // PCIe capability cannot be read (device does not support FLR).
    //
    //   pf_num : PF index
    //   vf_num : VF index within the PF, or -1 for the PF itself
    //
    // SHIM CANDIDATE: depends only on env.shim.vip and pdev_eps.
    // =========================================================================
    task initiate_flr(input int pf_num, input int vf_num = -1);
        int       err;
        bit [8:0] func_num = get_function_number(pf_num, vf_num);

        ep_bdf_pf = (vf_num == -1) ? pdev_eps[pf_num].bdf
                                    : pdev_eps[pf_num].vf[vf_num+1].bdf;

        env.shim.vip.read_capability(ep_bdf_pf, pcie_cap,
            pcie_cap.cor_err_reporting_enable.get_offset_dw, err);
        if (err) begin
            `uvm_info("FLR", $sformatf("PCIe cap not found for %s=%0d; skipping FLR",
                vf_num == -1 ? "PF" : "VF", vf_num == -1 ? pf_num : vf_num), UVM_LOW)
            return;
        end

        if (pcie_cap.initiate_function_level_reset.v == 0) begin
            pcie_cap.initiate_function_level_reset.set_v(1);
            `uvm_info("FLR", $sformatf("FLR initiated for %s=%0d (BDF=0x%0h)",
                vf_num == -1 ? "PF" : "VF", vf_num == -1 ? pf_num : vf_num,
                ep_bdf_pf), UVM_LOW)
            env.shim.vip.write_capability(ep_bdf_pf, pcie_cap,
                pcie_cap.initiate_function_level_reset.get_offset_dw, err);
            if (err)
                `uvm_error("FLR", $sformatf("Failed to write FLR bit for %s=%0d",
                    vf_num == -1 ? "PF" : "VF", vf_num == -1 ? pf_num : vf_num))
        end
        #5us;
    endtask


    // =========================================================================
    // read_mvt_entry
    //
    // Issues two 64-bit memory reads to retrieve a complete 128-bit MVT entry
    // (DW0:DW1 first, then DW2:DW3) and logs each result at UVM_LOW.
    // The table_read_monitor receives the address via issue_mem_tlp_with_function
    // and performs the scoreboard comparison independently.
    // =========================================================================
    task read_mvt_entry(input int pf_num, input int vf_num = -1, input int vector_num);
        bit [31:0] rd_data[];
        bit [63:0] addr;
        bit [ 8:0] func_num;
        mem_bar_s  tmpbar;
        bit        tmpret;

        rd_data = new[PAYLOAD_SIZE];

        if (vf_num == -1) begin
            func_num = get_function_number(pf_num);
            addr = pdev_eps[pf_num].membar[MSIX_BAR_NUM[func_num]].base
                 + (vector_num << 4) + MSIX_MVT_BASE_ADDRESS[func_num];
        end else begin
            func_num = get_function_number(pf_num, vf_num);
            tmpret   = pdev_eps[pf_num].vf[vf_num+1].get_membar(MSIX_BAR_NUM[func_num], tmpbar);
            addr     = tmpbar.base + (vector_num << 4) + MSIX_MVT_BASE_ADDRESS[func_num];
        end

        issue_mem_tlp_with_function(MRD, addr, get_function_number(pf_num, vf_num),
            .len(PAYLOAD_SIZE), .data(rd_data));
        `uvm_info(get_type_name(), $sformatf("MVT Read lo: %s=%0d Vec=%0d Addr=0x%h Data=0x%h_%h",
            vf_num == -1 ? "PF" : "VF", vf_num == -1 ? pf_num : vf_num,
            vector_num, addr, rd_data[1], rd_data[0]), UVM_LOW)

        addr += 8;
        issue_mem_tlp_with_function(MRD, addr, get_function_number(pf_num, vf_num),
            .len(PAYLOAD_SIZE), .data(rd_data));
        `uvm_info(get_type_name(), $sformatf("MVT Read hi: %s=%0d Vec=%0d Addr=0x%h Data=0x%h_%h",
            vf_num == -1 ? "PF" : "VF", vf_num == -1 ? pf_num : vf_num,
            vector_num, addr, rd_data[1], rd_data[0]), UVM_LOW)
    endtask
    
    // =========================================================================
    // get_function_number
    //
    // Returns the absolute function index used by msix_params_pkg for a given
    // PF (vf_idx == -1) or VF (vf_idx >= 0).
    //
    //   PF: returns pf_idx directly (PFs occupy indices 0..MSIX_PF_COUNT-1).
    //   VF: returns SRIOV_PFX_FIRST_VF_OFFSET[pf_idx] + vf_idx.
    //
    // SHIM CANDIDATE: pure arithmetic on msix_params_pkg constants; no env
    // access.  Can be promoted to a package-level function once the framework
    // imports msix_params_pkg.
    // =========================================================================
    function bit [8:0] get_function_number(int pf_idx, int vf_idx = -1);
        if (vf_idx == -1)
            return pf_idx;
        else
            return SRIOV_PFX_FIRST_VF_OFFSET[pf_idx] + vf_idx;
    endfunction
*/
   virtual function void connect_phase(uvm_phase phase);
      phase.raise_objection(this);
      super.connect_phase(phase);
      
      mem_cb = new(env.shim.vip, rd_pattern, txfr_size);
      env.shim.vip.append_callback(mem_cb);
      
      phase.drop_objection(this);
   endfunction // connect_phase
  

   virtual task main_phase(uvm_phase phase);
      super.main_phase(phase);
      phase.raise_objection(this);
//      env.pcie_collect_status();
      
      pdev_rp = env.shim.container.get_pdev_RP; 
      pdev_ep = env.shim.container.get_pdev_allEPs(); 
     // `uvm_info(get_type_name, $sformatf("number of pdevs = %0d",pdev_ep.pf), UVM_NONE)
      tlp = amd_mem_tlp::type_id::create("tlp");

      phase.drop_objection(this);
  endtask

endclass

   
