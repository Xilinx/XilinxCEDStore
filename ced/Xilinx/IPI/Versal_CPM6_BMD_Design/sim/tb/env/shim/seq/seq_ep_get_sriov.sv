// DESCRIPTION
// This sequence is designed to parse an EP's PF to build a VF device  
// object after enumeration for an easily readable format
class seq_ep_get_sriov extends vseq_in_order;

  `uvm_object_utils(seq_ep_get_sriov)

  // Knobs to set before calling 'start'
  logic [15:0] dst_bdf;
  bit          print = 1;

  // if given, build results here
  pcie_device pdev;

  bit         ecap_sriov_not_found; //check before proceeding
  ecap_s      ecap_sriov;           //capability summary 
  sriov_s     sriov;                //capability details: generic member

  function new(string name = "seq_ep_get_sriov");
    super.new(name);
  endfunction

  // Ensure SR-IOV is present
  virtual task pre_body(); 
    amd_cfg_tlp tlp;
    bit [11:0]  ptr;
    int         sz_num;
    string      sz_unit;
    if (dst_bdf==='x && pdev==null)
      `uvm_fatal(get_type_name, "dst_bdf member or pdev must be set before running sequence")
    // Get sriov capability if we have object 
    if (pdev!=null) begin
      ecap_sriov_not_found = !pdev.get_ecap(ECAP_SRIOV, ecap_sriov);
      dst_bdf = pdev.bdf;
    end
    // If no object, then we need to look for sriov capability
    else begin
      ecap_sriov_not_found = 1;
      tlp = amd_cfg_tlp::type_id::create("tlp");
      ptr = 'h100;
      tlp.build_rd(ptr);
      p_sequencer.api.send_cfg(tlp);
      if (tlp.payload[0]!='0) begin
        // Go read all ext. capabilities until sriov found or end of list
        while (!is_sriov(tlp, ptr) && (tlp.payload[0]>>20)) begin
          if (!(ptr inside {'h0, ['h100:'hFFF]}))
            `uvm_fatal(get_type_name, $sformatf("Next ext. capability offset (0x%h) is invalid",ptr))
          else if (|ptr[1:0])
            `uvm_fatal(get_type_name, "Next ext. capability offset 2 LSbs should be 0")
          // Go read it
          tlp.build_rd(ptr & 12'hFFC);
          p_sequencer.api.send_cfg(tlp);
        end
      end
    end
    if (!ecap_sriov_not_found) begin
      tlp = amd_cfg_tlp::type_id::create("tlp");
      /* Read the SR-IOV capability for important info */
      // 0x8 = {SR-IOV Status, SR-IOV Control}
      tlp.build_rd(ecap_sriov.base+'h8, .bdf(dst_bdf));
      p_sequencer.api.send_cfg(tlp);
      sriov.vf_enable = tlp.payload[0][0][0];
      sriov.vf_mse    = tlp.payload[0][0][3];
      if (tlp.payload[0][2][0])
        `uvm_error(get_type_name, "'SR-IOV Status.VF Migration Status' should be 0; refer PCIe Spec")
      // 0xC = {TotalVFs, InitialVFs}
      tlp.build_rd(ecap_sriov.base+'hC, .bdf(dst_bdf));
      p_sequencer.api.send_cfg(tlp);
      sriov.total_vfs = tlp.payload[0][3:2];
      if (tlp.payload[0][3:2] != tlp.payload[0][1:0])
        `uvm_error(get_type_name, "InitialVFs should equal TotalVFs; refer PCIe Spec")
      // 0x10 = {[31:16], NumVFs}
      tlp.build_rd(ecap_sriov.base+'h10, .bdf(dst_bdf));
      p_sequencer.api.send_cfg(tlp);
      sriov.num_vfs = tlp.payload[0][1:0];
      // 0x14 = {VF Stride, FirstVF Offset}
      tlp.build_rd(ecap_sriov.base+'h14, .bdf(dst_bdf));
      p_sequencer.api.send_cfg(tlp);
      sriov.first_vf_offset = tlp.payload[0][1:0];
      sriov.vf_stride       = tlp.payload[0][3:2];
      // 0x20 = System Page Size
      tlp.build_rd(ecap_sriov.base+'h20, .bdf(dst_bdf));
      p_sequencer.api.send_cfg(tlp);
      sriov.sys_page_sz = tlp.payload[0]<<12;
      if ($countones(tlp.payload[0])!=1) begin
        `uvm_error(get_type_name, 
                   $sformatf("Invalid num of 1s (%0d) in the 'System Page Size' register",
                             $countones(tlp.payload[0])))
      end
      else begin
        // Build string
        for (int ii=12; ii<44; ii++) begin
          case (ii) 
            12: sz_unit = "KiB";
            20: sz_unit = "MiB";
            30: sz_unit = "GiB";
            40: sz_unit = "TiB";
          endcase
          if (sriov.sys_page_sz[ii]) begin
            case (1'b1)
              ii<20  : sz_num = 1<<(ii-10); 
              ii<30  : sz_num = 1<<(ii-20); 
              ii<40  : sz_num = 1<<(ii-30); 
              default: sz_num = 1<<(ii-40);
            endcase
            break;
          end
        end
        sriov.sys_page_sz_str = $sformatf("%0d%0s", sz_num, sz_unit);
      end
      // Note: fill the queue (don't acually perform txns)
      // Setup to read each VF BAR successively to restore later
      for (bit [2:0] bar=0; bar<6; bar++) begin
        tlp = amd_cfg_tlp::type_id::create("tlp");
        tlp.build_rd(ecap_sriov.base+'h24+'h4*bar, .bdf(dst_bdf));
        add_txn(tlp);
      end
    end
  endtask

  virtual task body();
    bit         upper;
    bit [63:0]  bar_reg; 
    amd_cfg_tlp tlp;
    // no point in continuing if not found
    if (ecap_sriov_not_found) return;
    // Read all 6 VF BARs first
    super.body();
    // Set txn constant 
    tlp = amd_cfg_tlp::type_id::create("tlp");
    tlp.dst_bdf = dst_bdf;
    // Write then readback each BAR successively
    for (bit [2:0] bar=0; bar<6; bar++) begin
      if (!upper) bar_reg = '0;
      tlp.build_wr(ecap_sriov.base+'h24+'h4*bar, '1);
      p_sequencer.api.send_cfg(tlp);
      tlp.rd = 1;
      p_sequencer.api.send_cfg(tlp);
      if (upper) bar_reg[63:32] = tlp.payload[0];
      else       bar_reg[31: 0] = tlp.payload[0];
      // 64b Memory BAR detected
      if (!upper && bar_reg[2:0]=='b100)
        upper = 1;  
      else if (upper || (!upper && (|bar_reg[31:0]))) begin
        // Memory BAR
        if (upper || (!upper && !bar_reg[0])) begin
          parse_mem_bar(bar_reg, upper, (upper ? bar-1 : bar));
          upper = 0;
        end
        // IO BAR
        else 
          parse_io_bar(bar_reg[31:0], bar);
      end
    end
    // Change each original BAR read to a write
    foreach (q[ii]) begin
      $cast(tlp, q[ii]);
      tlp.rd = 0; 
    end
    // Re-run the programming to restore
    super.body();
  endtask

  virtual task post_body();
    if (ecap_sriov_not_found) begin
      `uvm_info(get_type_name, $sformatf("BDF 0x%h (PF) : SR-IOV extended capability not present", dst_bdf), UVM_LOW)
      return;
    end
    else begin
      pdev.sriov = sriov; //give results to object
      `uvm_info(get_type_name, $sformatf("BDF 0x%h (PF) : SR-IOV extended capability present and parsed", dst_bdf), UVM_LOW)
    end
    if (print) begin
      `uvm_info(get_type_name, $sformatf("  - Total VFs     : %0d",  sriov.total_vfs), UVM_LOW)
      `uvm_info(get_type_name, $sformatf("  - Num VFs       : %0d",  sriov.num_vfs), UVM_LOW)
      `uvm_info(get_type_name, $sformatf("  - VF Enable     : %0d",  sriov.vf_enable), UVM_LOW)
      `uvm_info(get_type_name, $sformatf("  - VF MSE        : %0d",  sriov.vf_mse), UVM_LOW)
      `uvm_info(get_type_name, $sformatf("  - 1st VF Offset : 0x%h", sriov.first_vf_offset), UVM_LOW)
      `uvm_info(get_type_name, $sformatf("  - VF Stride     : 0x%h", sriov.vf_stride), UVM_LOW)
      `uvm_info(get_type_name, $sformatf("  - Sys Page Sz   : %0s",  sriov.sys_page_sz_str), UVM_LOW)
      if (sriov.vf_membar.size) begin
        `uvm_info(get_type_name, $sformatf("BDF 0x%h (PF) : Printing %0d VF memory BARs", dst_bdf, sriov.vf_membar.size), UVM_LOW)
        foreach (sriov.vf_membar[ii])
          `uvm_info(get_type_name, $sformatf("  - VF BAR[%0d] | is_64=%0b, prefetchable=%0b, size=%0s, base=0x%0h", ii, sriov.vf_membar[ii].is_64, sriov.vf_membar[ii].is_pftch, sriov.vf_membar[ii].sz_str, sriov.vf_membar[ii].base), UVM_LOW)
      end
      if (sriov.vf_iobar.size) begin
        `uvm_info(get_type_name, $sformatf("BDF 0x%h (PF) : Printing %0d VF IO BARs", dst_bdf, sriov.vf_iobar.size), UVM_LOW)
        foreach (sriov.vf_iobar[ii])
          `uvm_info(get_type_name, $sformatf("  - VF BAR[%0d] | size=%0s, base=0x%0h", ii, sriov.vf_iobar[ii].sz_str, sriov.vf_iobar[ii].base), UVM_LOW)
      end
      if (!sriov.vf_membar.size && !sriov.vf_iobar.size)
        `uvm_info(get_type_name, $sformatf("BDF 0x%h (PF) has no VF BARs", dst_bdf), UVM_LOW)
    end
  endtask

  // --------------------------------
  // HELPER METHODS 
  // --------------------------------

  // MEM BARs can map any pow2 size 
  virtual function void parse_mem_bar(bit [63:0] bar, bit is_64, int idx);
    amd_cfg_tlp tlp;
    int         sz_num;
    string      sz_unit;
    bit [63:0]  masked_bar = bar & (~64'hF);
    // Get values
    sriov.vf_membar[idx].is_64    = is_64;
    sriov.vf_membar[idx].is_pftch = bar[3];
    // For 32-bit BARs, perform calculation on lower 32 bits only to avoid
    // upper bits becoming all 1s when inverting zeros
    if (is_64)
      sriov.vf_membar[idx].sz = ~masked_bar + 64'd1;
    else
      sriov.vf_membar[idx].sz = {32'd0, (~masked_bar[31:0] + 32'd1)};
    if (is_64) begin 
      $cast(tlp, q[idx]);
      sriov.vf_membar[idx].base[31: 0] = tlp.payload[0] & (~32'hF);
      $cast(tlp, q[idx+1]);
      sriov.vf_membar[idx].base[63:32] = tlp.payload[0];
    end
    else begin
      $cast(tlp, q[idx]);
      sriov.vf_membar[idx].base[31: 0] = tlp.payload[0] & (~32'hF);
    end
    // Build string
    for (int ii=0; ii<(is_64?64:32); ii++) begin
      case (ii) 
        0 : sz_unit = "B";
        10: sz_unit = "KiB";
        20: sz_unit = "MiB";
        30: sz_unit = "GiB";
        40: sz_unit = "TiB";
        50: sz_unit = "PiB";
        60: sz_unit = "EiB";
      endcase
      if (sriov.vf_membar[idx].sz[ii]) begin
        case (1'b1)
          ii<10  : sz_num = 1<<ii; 
          ii<20  : sz_num = 1<<(ii-10); 
          ii<30  : sz_num = 1<<(ii-20); 
          ii<40  : sz_num = 1<<(ii-30); 
          ii<50  : sz_num = 1<<(ii-40); 
          ii<60  : sz_num = 1<<(ii-50); 
          default: sz_num = 1<<(ii-60);
        endcase
        break;
      end
    end
    sriov.vf_membar[idx].sz_str = $sformatf("%0d%0s", sz_num, sz_unit);
  endfunction

  // Spec: IO BARs can map 16-256B only
  virtual function void parse_io_bar(bit [31:0] bar, int idx);
    amd_cfg_tlp tlp;
    int         sz_num;
    string      sz_unit;
    bit [31:0]  masked_bar = bar & (~32'h3);
    // Get values
    sriov.vf_iobar[idx].sz = ~masked_bar+1;
    $cast(tlp, q[idx]);
    sriov.vf_iobar[idx].base = tlp.payload[0] & (~32'h3);
    // Build string
    for (int ii=0; ii<32; ii++) begin
      case (ii) 
        0 : sz_unit = "B";
        10: sz_unit = "KiB";
        20: sz_unit = "MiB";
        30: sz_unit = "GiB";
      endcase
      if (sriov.vf_iobar[idx].sz[ii]) begin
        case (1'b1)
          ii<10  : sz_num = 1<<ii; 
          ii<20  : sz_num = 1<<(ii-10); 
          ii<30  : sz_num = 1<<(ii-20); 
          default: sz_num = 1<<(ii-30);
        endcase
        break;
      end
    end
    sriov.vf_iobar[idx].sz_str = $sformatf("%0d%0s", sz_num, sz_unit);
  endfunction

  virtual function bit is_sriov(amd_cfg_tlp tlp, ref bit [11:0] ptr);
    if (pcie_ecapid_e'(tlp.payload[0][1:0]) == ECAP_SRIOV) begin
      ecap_sriov.id        = ECAP_SRIOV;
      ecap_sriov.base      = ptr;
      ecap_sriov.version   = tlp.payload[0][2][3:0];
      ecap_sriov_not_found = 0;
      return 1;
    end
    else begin 
      ptr = tlp.payload[0]>>20;
      return 0;
    end
  endfunction

endclass
