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


  // --- 64-bit dsc_base support (+DSC_BASE_HI) --------------------------------
  // host_mem is `byte host_mem[int]` -- a 32-bit index -- so the address is SPLIT:
  // the low word addresses host memory, the upper word is verified here. That is
  // what proves the DUT emitted a genuine 64-bit fetch address instead of
  // dropping the high half.
  int unsigned hi_seen_cnt = 0;
  int unsigned hi_trunc_cnt = 0;
  function void chk_addr_hi(input bit [63:0] a, input string kind);
    bit in_dsc_range;
    if (this.test == null) return;

    // Not in 64-bit mode -> nothing to check. Gate on the PROGRAMMED value, not
    // on the observed address, so an address whose high word was DROPPED is
    // still checked.
    if (this.test.dsc_base_hi == 32'h0) return;

    // Only DESCRIPTOR fetches carry the high word. Data buffers are addressed by
    // the low word by design (host_mem is `byte host_mem[int]`; see the split
    // rationale in qdma_base_test.sv), so requiring the high word on them would
    // false-fire on every data TLP. Classify by the same address ranges the
    // read/write handlers below use.
    in_dsc_range = (a[31:0] >= H2C_DSC_ADDR && a[31:0] < (H2C_DSC_ADDR + HOST_DSC_MEM_SIZE)) ||
                   (a[31:0] >= C2H_DSC_ADDR && a[31:0] < (C2H_DSC_ADDR + HOST_DSC_MEM_SIZE));
    if (!in_dsc_range) return;

    if (a[63:32] == 32'h0) begin
      hi_trunc_cnt++;
      `uvm_error("qdma_RC_MEM", $sformatf(
        "%s DESCRIPTOR TLP upper address word is ZERO but +DSC_BASE_HI=0x%08h was programmed -- the DUT TRUNCATED the 64-bit ring base to 32 bits (addr=0x%016h). The low word still addresses valid host memory, so the transfer may complete and every other check may pass; this is the only check that catches it.",
        kind, this.test.dsc_base_hi, a))
    end else if (a[63:32] !== this.test.dsc_base_hi) begin
      `uvm_error("qdma_RC_MEM", $sformatf(
        "%s TLP upper address word 0x%08h does not match +DSC_BASE_HI 0x%08h -- the DUT emitted a 64-bit address the TB never programmed (addr=0x%016h)",
        kind, a[63:32], this.test.dsc_base_hi, a))
    end else begin
      hi_seen_cnt++;                               // positive evidence the high word survived
      if (this.test.shared_log_fd != 0 && hi_seen_cnt <= 8)
        $fdisplay(this.test.shared_log_fd,
          "%9t ns  TLP   TLP_ADDR_HI  %s  hi=0x%08h  lo=0x%08h  (match #%0d)",
          $time, kind, a[63:32], a[31:0], hi_seen_cnt);
    end
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
      chk_addr_hi(addr, "RD");
      addr = {32'h0, addr[31:0]};   // fold to low word: region decode + host_mem
      addr_decimal = addr;

      `uvm_info("qdma_RC_MEM", $psprintf("read mem cb: is_host_mem: %0d, ADDR_hex: %0h, addr_decimal: %0d, NDW: %0h, FBE: %0h, LBE: %0h",
      is_host_mem, addr, addr_decimal,ndw, first_be, last_be), UVM_HIGH);
      // The uvm_info above is UVM_HIGH; mirror the per-TLP HEADER to
      // cpm6_qdma_dbg.log, which is verbosity-independent. Header-only: the
      // per-DWORD logs further down sit inside a loop over ndw and would emit
      // roughly 32 lines per 128B TLP, so they stay gated (see below).
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
   chk_addr_hi(addr, "WR");
   addr = {32'h0, addr[31:0]};   // fold to low word: region decode + host_mem
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