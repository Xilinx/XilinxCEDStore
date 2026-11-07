// Base class for PCIe device objects (both PF and VF)
// Contains common members and methods shared by pcie_device and pcie_vdevice
// Note: This is not a SystemVerilog abstract class because UVM factory
// cannot handle abstract classes. Derived classes must override get_membar().
class pcie_device_base extends uvm_object;

  `uvm_object_utils(pcie_device_base)

  function new(string name = "pcie_device_base");
    super.new(name);
  endfunction

  /* Common Members */

  bdf_s          bdf;

  // capability structs
  cap_s          cap[$:16]; 
  // ext. capability structs
  ecap_s         ecap[$:64]; 
  // MSI-X capability struct
  msix_s         msi_x;

  // ------------------------
  // METHODS
  // ------------------------

  // - get_* : simplify getting a member in some way

  // Lookup the base address of a vector in the MSI-X Table Entry
  virtual function bit [63:0] get_msix_table_vec_addr(bit [11:0] vec);
    return (msi_x.table_base+vec*16); 
  endfunction

  // Lookup the base address of a vector in the MSI-X PBA for a QWORD access
  virtual function bit [63:0] get_msix_pba_vec_addr_qw(bit [11:0] vec);
    return (msi_x.pba_base+(vec/64)*8); 
  endfunction

  // Lookup the base address of a vector in the MSI-X PBA for a DWORD access
  virtual function bit [63:0] get_msix_pba_vec_addr_dw(bit [11:0] vec);
    return (msi_x.pba_base+(vec/32)*4); 
  endfunction

  // Lookup by BAR number; returns 0 if not found, else return 1
  // - A 64 bit BAR is indexed by the lower DW
  // - Override in derived classes: PF uses membar directly, VF uses PF's sriov.vf_membar with offset
  // - Default implementation returns 0 (not found)
  virtual function bit get_membar(bit [2:0] num, ref mem_bar_s bar);
    return 0;
  endfunction

  // Lookup by ID; returns 0 if not found, else return 1
  virtual function bit get_cap(pcie_capid_e id, ref cap_s s);
    int qi[$:1];
    qi = cap.find_first_index with (item.id==id);
    if (!qi.size) return 0;
    s = cap[qi[0]];
    return 1;
  endfunction

  // Lookup by ID; returns 0 if not found, else return 1
  virtual function bit get_ecap(pcie_ecapid_e id, ref ecap_s s);
    int qi[$:1];
    qi = ecap.find_first_index with (item.id==id);
    if (!qi.size) return 0;
    s = ecap[qi[0]];
    return 1;
  endfunction

  // Query if this is a VF (virtual function)
  // Override in pcie_vdevice to return 1
  virtual function bit is_vf();
    return 0;
  endfunction

endclass
