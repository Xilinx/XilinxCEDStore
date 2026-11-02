// This object is supposed to capture all relevant details about each unique 
// PCIe device. Some of the members may not be currently used and are placed
// here for future enhancements.
class pcie_device extends pcie_device_base;

  `uvm_object_utils(pcie_device)

  function new(string name = "pcie_device");
    super.new(name);
  endfunction

  /* Common */

  bit [15:0]     vendorid;
  bit [15:0]     deviceid;

  class_code_s   class_code; //ENHANCEMENT
                
  amd_devport_t  ptype;
  bit            is_cxl_port;
  bit            is_cxl_link; //ENHANCEMENT

  // Type0:max6, Type1:max2 | key is BAR number (lower for 64b BAR)
  mem_bar_s      membar[bit [2:0]];
  io_bar_s       iobar [bit [2:0]];
  // Type 0 AND Type 1, but differ in cfg space location
  erom_bar_s     erombar; //ENHANCEMENT
  // is_cxl_port only
  cxl_reg_blk_s  cxl_reg_blk[$:8]; //MMIO; register block
  cxl_dev_cap_s  cxl_dev_cap[$:4]; //MMIO; device capabilities

  /* Type 0 Only */
  bit [15:0]     subsys_id;       //ENHANCEMENT
  bit [15:0]     subsys_vendorid; //ENHANCEMENT
  pcie_vdevice   vf[$];

  // - is_cxl_port only
  mem_range64_s  cxl_hdm[$:2];

  /* Type 1 Only | aper="aperture" */
  bit [ 7:0]     primary_bus;
  bit [ 7:0]     secondary_bus;
  bit [ 7:0]     subord_bus;

  mem_range32_s  io_aper; 
  mem_range32_s  npmem_aper; 
  mem_range64_s  pmem_aper; 
  mem_range64_s  cxl_aper;

  /* Other */
  sriov_s        sriov;      //SR-IOV struct

  // ------------------------
  // METHODS
  // ------------------------

  // - get_* : simplify getting a member in some way

  // Lookup by BAR number; returns 0 if not found, else return 1
  // - A 64 bit BAR is indexed by the lower DW
  virtual function bit get_membar(bit [2:0] num, ref mem_bar_s bar);
    if (membar.exists(num)) begin
      bar = membar[num];
      return 1;
    end
    return 0;
  endfunction

  // Lookup by BAR number; returns 0 if not found, else return 1
  virtual function bit get_iobar(bit [2:0] num, ref io_bar_s bar);
    if (iobar.exists(num)) begin
      bar = iobar[num];
      return 1;
    end
    return 0;
  endfunction

  // Lookup by ID; returns 0 if not found, else return 1
  virtual function bit get_cxl_reg_blk(cxl_reg_blk_id_e id, ref cxl_reg_blk_s s);
    int qi[$:1];
    qi = cxl_reg_blk.find_first_index with (item.id==id);
    if (!qi.size) return 0;
    s = cxl_reg_blk[qi[0]];
    return 1;
  endfunction

  // Lookup by ID; returns 0 if not found, else return 1
  virtual function bit get_cxl_dev_cap(cxl_dev_cap_id_e id, ref cxl_dev_cap_s s);
    int qi[$:1];
    qi = cxl_dev_cap.find_first_index with (item.id==id);
    if (!qi.size) return 0;
    s = cxl_dev_cap[qi[0]];
    return 1;
  endfunction

  // - is_* : query the object about itself

  virtual function bit is_type1();
    return (ptype inside {[PT_RP:PT_PCIX2PCIE]});
  endfunction

  // Should only modify BARs or apertures through methods below so that
  // the sz_str can be correctly set 

  // - add_*_bar

  virtual function void add_mem_bar(bit [2:0] idx, bit is_64, bit pftch, bit [63:0] base, bit [63:0] size);
    if (is_type1 && idx>1)
      `uvm_fatal(get_type_name, "Cannot add a Type 1 BAR with index>1")
    else if (idx>5)
      `uvm_fatal(get_type_name, "Cannot add a BAR with index>5")
    else
      membar[idx] = '{is_64, pftch, size_to_str(size), size, base};
  endfunction

  virtual function void add_io_bar(bit [2:0] idx, bit [31:0] base, bit [31:0] size);
    if (is_type1 && idx>1)
      `uvm_fatal(get_type_name, "Cannot add a Type 1 BAR with index>1")
    else if (idx>5)
      `uvm_fatal(get_type_name, "Cannot add a BAR with index>5")
    else
      iobar[idx] = '{size_to_str(size), size, base};
  endfunction

  virtual function void add_cxl_hdm(bit [63:0] base, bit [63:0] size);
    if (is_type1 && ptype inside {PT_RP, PT_SW_DSP})
      `uvm_fatal(get_type_name, "Cannot add CXL HDM to a downstream port")
    else
      cxl_hdm.push_back('{size_to_str(size), size, base}); 
  endfunction

  // - add_*_aper

  virtual function void add_pmem_aper(bit [63:0] base, bit [63:0] size);
    if (!is_type1) `uvm_fatal(get_type_name, "Cannot add an aperture to Type 0 device")
    pmem_aper = '{size_to_str(size), size, base}; 
  endfunction

  virtual function void add_npmem_aper(bit [31:0] base, bit [31:0] size);
    if (!is_type1) `uvm_fatal(get_type_name, "Cannot add an aperture to Type 0 device")
    npmem_aper = '{size_to_str(size), size, base}; 
  endfunction

  virtual function void add_io_aper(bit [31:0] base, bit [31:0] size);
    if (!is_type1) `uvm_fatal(get_type_name, "Cannot add an aperture to Type 0 device")
    io_aper = '{size_to_str(size), size, base}; 
  endfunction

  virtual function void add_cxl_aper(bit [63:0] base, bit [63:0] size);
    if (!is_type1) `uvm_fatal(get_type_name, "Cannot add an aperture to Type 0 device")
    cxl_aper = '{size_to_str(size), size, base}; 
  endfunction 

  // - print summaries : print some helpful info about the device

  virtual function void print_cxl_dev_caps(string pfx = "");
    string msg;
    if (pfx=="") begin 
      if (1'b0 /*is_ari*/)
        pfx = $sformatf("CXL %h:0.%h (ARI)", bdf.b, bdf.id.arif);
      else
        pfx = $sformatf("CXL %h:%h.%h", bdf.b, bdf.id.df.d, bdf.id.df.f);
    end
    if (!cxl_dev_cap.size) begin
      `uvm_info(get_type_name, {pfx, ": ","No CXL device capabilities found in object"}, UVM_LOW)
      return;
    end
    foreach (cxl_dev_cap[ii]) begin 
      msg = {pfx,
             ": ",
             $sformatf("Device Cap. %0d | %0s (ID=0x%h) at 0x%0h; size=%0dB", 
               ii, cxl_dev_cap[ii].id.name, cxl_dev_cap[ii].id, 
                   cxl_dev_cap[ii].base,    cxl_dev_cap[ii].len)
            };
      `uvm_info(get_type_name, msg, UVM_LOW)
    end
  endfunction

  virtual function void print_cxl_reg_blks(string pfx = "");
    string msg;
    if (pfx=="") begin 
      if (1'b0 /*is_ari*/)
        pfx = $sformatf("CXL %h:0.%h (ARI)", bdf.b, bdf.id.arif);
      else
        pfx = $sformatf("CXL %h:%h.%h", bdf.b, bdf.id.df.d, bdf.id.df.f);
    end
    if (!cxl_reg_blk.size) begin
      `uvm_info(get_type_name, {pfx, ": ","No CXL register blocks found in object"}, UVM_LOW)
      return;
    end
    foreach (cxl_reg_blk[ii]) begin 
      if (cxl_reg_blk[ii].id == NULL_REG_BLOCK) begin
        msg = {pfx,
               ": ",
               $sformatf("Reg. Block %0d | %0s (ID=0x%h)", 
                 ii, cxl_reg_blk[ii].id.name, cxl_reg_blk[ii].id)
              };
      end
      else if (cxl_reg_blk[ii].id.name == "") begin
        msg = {pfx,
               ": ",
               $sformatf("Reg. Block %0d | %0s (ID=0x%h) at BAR%0d and Offset=0x%0h", 
                 ii, "Unknown",           cxl_reg_blk[ii].id, 
                     cxl_reg_blk[ii].bar, cxl_reg_blk[ii].abs_offset)
              };
      end
      else begin
        msg = {pfx,
               ": ",
               $sformatf("Reg. Block %0d | %0s (ID=0x%h) at BAR%0d and Offset=0x%0h", 
                 ii, cxl_reg_blk[ii].id.name, cxl_reg_blk[ii].id, 
                     cxl_reg_blk[ii].bar,     cxl_reg_blk[ii].abs_offset)
              };
      end
      `uvm_info(get_type_name, msg, UVM_LOW)
    end
  endfunction

  // - helpers

  // Convert a size into a string for easier printing
  virtual function string size_to_str(bit [63:0] size);
    string sz_unit;
    int    sz_num;
    for (int ii=0; ii<64; ii++) begin
      case (ii)
        0 : sz_unit = "B";
        10: sz_unit = "KiB";
        20: sz_unit = "MiB";
        30: sz_unit = "GiB";
        40: sz_unit = "TiB";
        50: sz_unit = "PiB";
        60: sz_unit = "EiB";
      endcase
      if (size[ii]) begin
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
    if (!sz_num) return "NONE";
    else         return ($sformatf("%0d%0s", sz_num, sz_unit));
  endfunction

endclass
