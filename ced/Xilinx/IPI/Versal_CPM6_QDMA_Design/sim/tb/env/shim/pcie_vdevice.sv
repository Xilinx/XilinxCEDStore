typedef class pcie_device;
// This object is supposed to capture all relevant details about each unique 
// virtual PCIe device. Some of the members may not be currently used and are 
// placed here for future enhancements.
class pcie_vdevice extends pcie_device_base;

  `uvm_object_utils(pcie_vdevice)

  function new(string name = "pcie_vdevice");
    super.new(name);
  endfunction

  // Handle to the PF that is associated with this object
  pcie_device    pf;
  // PCIe refers to "VF N,M" as the Nth PF and Mth VF number; >= 1
  int unsigned   vf_num; 

  // ------------------------
  // METHODS
  // ------------------------

  // Query if this is a VF (virtual function)
  virtual function bit is_vf();
    return 1;
  endfunction

  // Lookup by BAR number; returns 0 if not found, else return 1
  // - A 64 bit BAR is indexed by the lower DW
  // - For VFs, uses PF's sriov.vf_membar with base adjusted by VF number
  virtual function bit get_membar(bit [2:0] num, ref mem_bar_s bar);
    if (pf.sriov.vf_membar.exists(num)) begin
      bar = pf.sriov.vf_membar[num];
      bar.base = bar.base + 64'(vf_num-1) * bar.sz;
      return 1;
    end
    return 0;
  endfunction

endclass
