// DESCRIPTION
// This sequence is designed to traverse the capability structure
// list and/or the extended capabilities structure list. It captures 
// the results into an associative array and can print the results.
// Works for both PF (pcie_device) and VF (pcie_vdevice) using the
// common base class pcie_device_base.
class seq_cap_traverse extends vseq_base;

  `uvm_object_utils(seq_cap_traverse)

  // Knobs to set before calling 'start'
  logic [15:0] dst_bdf;
  bit          get_caps    = 1;
  bit          get_ecaps   = 1;
  bit          print_caps  = 1;
  bit          print_ecaps = 1;

  // Results stored in queues by traversal order
  cap_s   cap[$:16];
  ecap_s ecap[$:64];

  // Device handle - can be either PF or VF via base class
  // Set one of these before running the sequence
  pcie_device_base dev;   // Base class handle (preferred - works for both PF/VF)
  pcie_device      pdev;  // Legacy: PF device handle
  pcie_vdevice     vdev;  // Legacy: VF device handle

  function new(string name = "seq_cap_traverse");
    super.new(name);
  endfunction

  virtual task pre_body();
    // Support both new (dev) and legacy (pdev/vdev) interfaces
    if (dev==null && pdev!=null)
      dev = pdev;
    else if (dev==null && vdev!=null)
      dev = vdev;
      
    if (dst_bdf==='x && dev==null)
      `uvm_fatal(get_type_name, "dst_bdf member or dev/pdev/vdev must be set before running sequence")
    if (dev!=null) 
      dst_bdf = dev.bdf;
  endtask

  virtual task body();
    bit         done;
    amd_cfg_tlp tlp;
    bit [11:0]  nxtptr;
    int         nregs;
    cap_s       tmpcap;
    mem_bar_s   tmpbar;
    bit         tmpret;
    pcie_device pf_dev;  // For CXL handling on PF only
    // Constant setup for object
    tlp = amd_cfg_tlp::type_id::create("tlp");
    tlp.dst_bdf = dst_bdf;
    // Get all capabilities
    if (get_caps) begin
      tlp.build_rd('h34);
      p_sequencer.api.send_cfg(tlp);
      if (tlp.payload[0][0]=='0)
        `uvm_fatal(get_type_name, "PCIe Spec: there cannot be no capability structures")
      nxtptr = tlp.payload[0][0];
      // Build first linked list read
      tlp.build_rd(nxtptr & 8'hFC);
      // Go read all capabilities
      done=(nxtptr=='0);
      while (!done) begin
        p_sequencer.api.send_cfg(tlp);
        parse_cap(tlp);
        nxtptr = tlp.payload[0][1];
        tlp.build_rd(nxtptr);
        done=(nxtptr=='0);
      end
    end
    // Get all ext. capabilities
    if (get_ecaps) begin
      tlp.build_rd('h100);
      p_sequencer.api.send_cfg(tlp);
      if (tlp.payload[0]!='0) begin
        parse_ecap(tlp);
        nxtptr=(tlp.payload[0]>>20);
        tlp.build_rd(nxtptr & 12'hFFC);
        // Go read all other ext. capabilities
        done=(nxtptr=='0);
        while (!done) begin
          p_sequencer.api.send_cfg(tlp);
          parse_ecap(tlp);
          nxtptr=(tlp.payload[0]>>20);
          tlp.build_rd(nxtptr & 12'hFFC);
          done=(nxtptr=='0);
          if (!(nxtptr inside {'h0, ['h100:'hFFF]}))
            `uvm_fatal(get_type_name, $sformatf("Next ext. capability offset (0x%h) is invalid",nxtptr))
          else if (|nxtptr[1:0])
            `uvm_fatal(get_type_name, "Next ext. capability offset 2 LSbs should be 0")
        end
      end
    end
    // Parse all DVSECs to populate addl. info into struct
    foreach (ecap[ii]) begin
      if (ecap[ii].id != ECAP_DVSEC) continue;
      tlp.build_rd(ecap[ii].base+4);  
      p_sequencer.api.send_cfg(tlp);
      {ecap[ii].dvsec_len, ecap[ii].dvsec_rev, ecap[ii].dvsec_vendid} = tlp.payload[0];
      tlp.build_rd(ecap[ii].base+8);
      p_sequencer.api.send_cfg(tlp);
      ecap[ii].dvsec_id = tlp.payload[0];
    end
    // assign to dev handle if present
    if (dev != null) begin
      dev.cap  = cap;
      dev.ecap = ecap;
      // dev has other general info to populate
      if (dev.get_cap(CAP_MSI_X, tmpcap)) begin
        tlp.build_rd(tmpcap.base);  
        p_sequencer.api.send_cfg(tlp);
        dev.msi_x.enable    = tlp.payload[0][3][7];
        dev.msi_x.func_mask = tlp.payload[0][3][6];
        dev.msi_x.nvec      = 1+(tlp.payload[0][3:2]&{11{1'b1}}); 
        tlp.build_rd(tmpcap.base+4);  
        p_sequencer.api.send_cfg(tlp);
        dev.msi_x.table_bar    = tlp.payload[0][2:0];
        dev.msi_x.table_offset = tlp.payload[0]&(~32'h7);
        tmpret = dev.get_membar(dev.msi_x.table_bar, tmpbar);
        if (tmpret)
          dev.msi_x.table_base = tmpbar.base + dev.msi_x.table_offset;
        tlp.build_rd(tmpcap.base+8);  
        p_sequencer.api.send_cfg(tlp);
        dev.msi_x.pba_bar      = tlp.payload[0][2:0];
        dev.msi_x.pba_offset   = tlp.payload[0]&(~32'h7);
        tmpret = dev.get_membar(dev.msi_x.pba_bar, tmpbar);
        if (tmpret)
          dev.msi_x.pba_base = tmpbar.base + dev.msi_x.pba_offset;
      end 
      // CXL handling - only for PF devices (not VFs)
      if (!dev.is_vf() && $cast(pf_dev, dev)) begin
        foreach (ecap[ii]) begin
          // Determine if port is CXL capable
          if (&{ecap[ii].id          == ECAP_DVSEC, 
                ecap[ii].dvsec_vendid== 'h1e98, 
                ecap[ii].dvsec_id    == 7})
          begin
            pf_dev.is_cxl_port = 1'b1;
          end
          // Go grab register blocks from Register Locator DVSEC
          else if (&{ecap[ii].id          == ECAP_DVSEC, 
                     ecap[ii].dvsec_vendid== 'h1e98, 
                     ecap[ii].dvsec_id    == 8})
          begin
            nregs = (ecap[ii].dvsec_len-12)/4; //len is bytes; -12 to skip header
            // No support for RegBlockIdent=DVSEC Regs
            for (int rr=0; rr<nregs/2; rr++) begin
              cxl_reg_blk_s reg_blk;
              // Read RegOffsetLow
              tlp.build_rd(ecap[ii].base+'hC+'h8*rr);  
              p_sequencer.api.send_cfg(tlp);
              reg_blk.id = cxl_reg_blk_id_e'(tlp.payload[0][1]); //15:8
              if (reg_blk.id.name=="")
                `uvm_fatal(get_type_name, $sformatf("Invalid Reg_Block_Id=0x%h",reg_blk.id))
              else if (reg_blk.id != NULL_REG_BLOCK) begin 
                reg_blk.bar           = tlp.payload[0][0][2:0]; // 2: 0
                reg_blk.offset[31:16] = tlp.payload[0][3:2];    //31:16
                if (reg_blk.id==DVSEC_REG)
                  `uvm_warning(get_type_name, "Sequence not set up to build DVSEC Reg Block")
                else begin
                  // Read RegOffsetHigh
                  tlp.build_rd(ecap[ii].base+'hC+'h8*rr+4);  
                  p_sequencer.api.send_cfg(tlp);
                  reg_blk.offset[63:32] = tlp.payload[0];
                  reg_blk.abs_offset = reg_blk.offset<<16;
                  reg_blk.base[31: 0] = pf_dev.membar[reg_blk.bar].base[31:0];
                  if (pf_dev.membar[reg_blk.bar].is_64)
                    reg_blk.base[63:32] = pf_dev.membar[reg_blk.bar].base[63:32];
                  reg_blk.base += reg_blk.abs_offset;
                end
              end
              pf_dev.cxl_reg_blk.push_back(reg_blk); //push summary onto Q
              // Go grab CXL Device Registers
              if (reg_blk.id == CXL_DEVICE_REG) begin
                cxl_dev_cap_s dev_cap;
                bit [15:0]    cap_cnt;
                amd_mem_tlp   mtlp = amd_mem_tlp::type_id::create("mtlp");
                mtlp.build_rd(reg_blk.base, 2, .blocking(DONE));
                p_sequencer.api.send_mem(mtlp);
                cap_cnt = mtlp.data[1][1:0];
                // Create a structure from the array
                for (int jj=0; jj<cap_cnt; jj++) begin
                  mtlp.build_rd(reg_blk.base+'h10*(jj+1), 2, .blocking(DONE));
                  p_sequencer.api.send_mem(mtlp);
                  dev_cap.id      = cxl_dev_cap_id_e'(mtlp.data[0][1:0]);
                  dev_cap.version = mtlp.data[0][2];
                  dev_cap.offset  = mtlp.data[1];
                  mtlp.build_rd(reg_blk.base+'h10*(jj+1)+'h8, 1, .blocking(DONE));
                  p_sequencer.api.send_mem(mtlp);
                  dev_cap.len     = mtlp.data[0];
                  dev_cap.base    = reg_blk.base+dev_cap.offset; 
                  pf_dev.cxl_dev_cap.push_back(dev_cap); //push summary onto Q
                end
              end
            end
          end
        end
      end // CXL handling
    end 
  endtask

  virtual task post_body();
    string msg;
    string cap_name;
    if (print_caps) begin
      `uvm_info(get_type_name, $sformatf("BDF 0x%h: Printing all capabilities", dst_bdf), UVM_LOW)
      foreach (cap[ii]) begin
        if (cap[ii].id.name!="") begin
          cap_name = cap[ii].id.name;
          cap_name = cap_name.substr(4, cap_name.len-1);
          msg = $sformatf("  - %0s at 0x%2h", cap_name, cap[ii].base);
        end
        else begin
          msg = $sformatf("  - UNKNOWN Capability (ID=0x%h) at 0x%2h", ii, cap[ii].base);
        end
        `uvm_info(get_type_name, msg, UVM_LOW)
      end
    end
    if (print_ecaps) begin
      `uvm_info(get_type_name, $sformatf("BDF 0x%h: Printing all ext. capabilities", dst_bdf), UVM_LOW)
      foreach (ecap[ii]) begin
        if (ecap[ii].id.name!="") begin
          cap_name = ecap[ii].id.name;
          cap_name = cap_name.substr(5, cap_name.len-1);
          msg = $sformatf("  - %0s at 0x%2h", cap_name, ecap[ii].base);
        end
        else begin
          msg = $sformatf("  - UNKNOWN Ext. Capability (ID=0x%h) at 0x%2h", ii, ecap[ii].base);
        end
        `uvm_info(get_type_name, msg, UVM_LOW)
      end
    end
  endtask

  // HELPER METHODS 

  virtual function void parse_cap(amd_cfg_tlp tlp);
    bit [3:0]    capver;
    pcie_capid_e capid = pcie_capid_e'(tlp.payload[0][0]);
    // Capabilities are defined from 'h0-'h15, but not all are relevant or 
    // valid anymore. Not all capabilities have versions, but will try to
    // grab the ones that do.
    case (capid)
      CAP_PCI_PM : capver = tlp.payload[2][2:0];
      CAP_PCI_EXP: capver = tlp.payload[2][3:0];
    endcase
    // Build array
    cap.push_back('{capid,
                    tlp.addr,  //base addr
                    capver});  //version (not all caps have)
  endfunction

  virtual function void parse_ecap(amd_cfg_tlp tlp);
    bit [ 3:0]    ecapver = tlp.payload[0][2][3:0];
    pcie_ecapid_e ecapid  = pcie_ecapid_e'(tlp.payload[0][1:0]);
    // Build array
    ecap.push_back('{ecapid,
                     tlp.addr,  //base addr
                     ecapver,   //version
                     '0, '0, '0, '0}); //dvsec info populated on addl. pass
  endfunction

endclass
