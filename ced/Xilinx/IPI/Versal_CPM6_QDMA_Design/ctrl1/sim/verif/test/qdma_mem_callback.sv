import cpm6_qdma_params_pkg::*;

typedef class qdma_base_test;
class qdma_mem_callback /*#(
  parameter int unsigned H2C_DSC_ADDR = 32'h0000_0000,
  parameter int unsigned C2H_DSC_ADDR = 32'h0010_0000,
  parameter int unsigned H2C_DAT_SRC_ADDR = 32'h0000_2000,
  parameter int unsigned C2H_DAT_DST_ADDR = 32'h0000_3000,
  parameter int unsigned DSC_MEM_SIZE = 32'h100000,
  parameter int unsigned H2C_DAT_SIZE = 32'h1000,
  parameter int unsigned C2H_DAT_SIZE = 32'h1000
)*/ extends apci_callbacks;  

  apci_device bfm_handle;
  qdma_base_test test;
  
  longint unsigned addr_decimal;
  host_req_bus dma_trfr_bus;
  
  function new(apci_device bfm_handle, qdma_base_test test);
      this.bfm_handle = bfm_handle;
      this.test = test;
      this.dma_trfr_bus = test.dma_trfr_bus;
  endfunction  

  virtual function void read_mem_cb(
          input bit             is_host_mem,
          input bit[63:0]       addr       ,
          input bit[31:0]       ndw        ,
          input bit[3:0]        first_be   ,
          input bit[3:0]        last_be    ,
          ref   bit[31:0]       va[]       ,
          input avery_data_base src         );
          
      host_req_tr tr;
      addr_decimal = addr;

      `uvm_info("qdma_RC_MEM", $psprintf("read mem cb: is_host_mem: %0d, ADDR_hex: %0h, addr_decimal: %0d, NDW: %0h, FBE: %0h, LBE: %0h",
      is_host_mem, addr, addr_decimal,ndw, first_be, last_be), UVM_HIGH);
      // The uvm_info above is UVM_HIGH and the sim default
      // is VERBOSITY=MEDIUM, so every host-memory TLP callback was dark. Mirror the
      // per-TLP HEADER to cpm6_qdma_dbg.log, which is verbosity-independent.
      // Deliberately header-only: the per-DWORD logs further down sit inside a loop
      // over ndw and would emit roughly 32 lines per 128B TLP - on the order of a
      // million lines for a PIDX=53 5-queue run - so they stay gated (see below).
      if (this.test != null && this.test.shared_log_fd != 0)
        $fdisplay(this.test.shared_log_fd,
                  "%9t ns  TLP   TLP_RD_CB   is_host_mem=%0d  addr=0x%0h  ndw=%0h  fbe=0x%0h  lbe=0x%0h",
                  $time, is_host_mem, addr, ndw, first_be, last_be);
      
      if((addr >= H2C_DSC_ADDR && addr < (H2C_DSC_ADDR + HOST_DSC_MEM_SIZE)) || (addr >= C2H_DSC_ADDR && addr < (C2H_DSC_ADDR + HOST_DSC_MEM_SIZE)) || (addr >= H2C_DAT_SRC_ADDR && addr < (H2C_DAT_SRC_ADDR + H2C_DAT_SIZE)) || (addr >= C2H_DAT_DST_ADDR && addr < (C2H_DAT_DST_ADDR + C2H_DAT_SIZE))) begin
        if(ndw == 1) begin
          va[0][7:0]    = (first_be[0] == 1'b1) ? this.test.host_mem[addr_decimal]      : 'h0;
          va[0][15:8]   = (first_be[1] == 1'b1) ? this.test.host_mem[addr_decimal + 1]  : 'h0;
          va[0][23:16]  = (first_be[2] == 1'b1) ? this.test.host_mem[addr_decimal + 2]  : 'h0;
          va[0][31:24]  = (first_be[3] == 1'b1) ? this.test.host_mem[addr_decimal + 3]  : 'h0;
          `uvm_info("qdma_RC_MEM", $psprintf("va[0]: %0h",va[0]), UVM_HIGH);
        end
        else begin
          for(int i=0;i<ndw;i++) begin
            bit [3:0] be;
            // PCIe spec: first_be applies to first DW, last_be to last DW,
            // middle DWs have all bytes valid (no byte enable masking)
            if      (i == 0)        be = first_be;
            else if (i == ndw-1)    be = last_be;
            else                    be = 4'hF;
            va[i][7:0]    = (be[0] == 1'b1) ? this.test.host_mem[addr_decimal + i*4]        : 'h0;
            va[i][15:8]   = (be[1] == 1'b1) ? this.test.host_mem[addr_decimal + i*4 + 1]    : 'h0;
            va[i][23:16]  = (be[2] == 1'b1) ? this.test.host_mem[addr_decimal + i*4 + 2]    : 'h0;
            va[i][31:24]  = (be[3] == 1'b1) ? this.test.host_mem[addr_decimal + i*4 + 3]    : 'h0;
            if(i < 8) begin
              `uvm_info("qdma_RC_MEM", $psprintf("be: %0h, va[%0h]: %0h,", be, i, va[i]), UVM_HIGH)
              `uvm_info("qdma_RC_MEM", $psprintf("host_mem[%0d]: %0h,",(addr_decimal + i*4), this.test.host_mem[addr_decimal + i*4]), UVM_HIGH)
              `uvm_info("qdma_RC_MEM", $psprintf("host_mem[%0d]: %0h,",(addr_decimal + i*4 + 1), this.test.host_mem[addr_decimal + i*4 + 1]), UVM_HIGH)
              `uvm_info("qdma_RC_MEM", $psprintf("host_mem[%0d]: %0h,",(addr_decimal + i*4 + 2), this.test.host_mem[addr_decimal + i*4 + 2]), UVM_HIGH)
              `uvm_info("qdma_RC_MEM", $psprintf("host_mem[%0d]: %0h" ,(addr_decimal + i*4 + 3), this.test.host_mem[addr_decimal + i*4 + 3]), UVM_HIGH)
            end              
          end
        end
      end 
      tr = host_req_tr::type_id::create("tr");
      if (tr == null) 
        `uvm_fatal("qdma_mem_callback", "host_req_tr::create returned null")
      tr.dma_pkt_type = host_req_tr::MRD;
      tr.addr = addr;//Hexadecimal value
      tr.length_dw = ndw;	 

      // Put payload first, then trigger to avoid races
      dma_trfr_bus.req_mbx.try_put(tr);
      dma_trfr_bus.req_ev.trigger();	
  endfunction

  virtual function void write_mem_cb(
          input bit             is_host_mem,
          input bit[63:0]       addr       ,
          input bit[3:0]        first_be   ,
          input bit[3:0]        last_be    ,
          ref   bit[31:0]       va[]       ,
          input avery_data_base src
  );
  
   host_req_tr tr;
   `uvm_info("qdma_RC_MEM",$psprintf("write mem cb: is_host_mem: %0d, ADDR %0h, FBE %0h, LBE  %0h",
          is_host_mem, addr, first_be, last_be),UVM_HIGH);
   // see read_mem_cb. Per-TLP header only; the per-DWORD
   // write log below stays at UVM_HIGH for the same volume reason.
   if (this.test != null && this.test.shared_log_fd != 0)
     $fdisplay(this.test.shared_log_fd,
               "%9t ns  TLP   TLP_WR_CB   is_host_mem=%0d  addr=0x%0h  fbe=0x%0h  lbe=0x%0h",
               $time, is_host_mem, addr, first_be, last_be);
          
   tr = host_req_tr::type_id::create("tr");
   if (tr == null) 
     `uvm_fatal("qdma_mem_callback", "host_req_tr::create returned null")
   tr.dma_pkt_type = host_req_tr::MWR;
   tr.addr = addr;//Hexadecimal value
   tr.length_dw = va.size(); // DW count; bytes = length_dw * 4

  tr.data = new[va.size()];
  foreach(va[i]) begin
    bit [3:0] be;
    if      (i == 0)           be = first_be;
    else if (i == va.size()-1) be = last_be;
    else                       be = 4'hF;
    if (be[0]) this.test.host_mem[addr + i*4 + 0] = va[i][7:0];
    if (be[1]) this.test.host_mem[addr + i*4 + 1] = va[i][15:8];
    if (be[2]) this.test.host_mem[addr + i*4 + 2] = va[i][23:16];
    if (be[3]) this.test.host_mem[addr + i*4 + 3] = va[i][31:24];
    tr.data[i] = va[i];
    if(i < 8)
      `uvm_info("qdma_RC_MEM", $psprintf("write mem cb: DATA %0h, ADDR %0h, FBE %0h, LBE  %0h, be %0h", va[i], addr, first_be, last_be, be), UVM_HIGH);
  end
  
  // Put payload first, then trigger to avoid races
  dma_trfr_bus.req_mbx.try_put(tr);
  dma_trfr_bus.req_ev.trigger();
  endfunction
endclass