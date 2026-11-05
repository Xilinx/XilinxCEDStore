class pdev_container extends uvm_component;

  `uvm_component_utils(pdev_container)

  typedef pcie_device pdev_q_t[$];

  pcie_device pdev[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ---------------------------------------
  //  HELPERS: Modify container structure
  // ---------------------------------------

  virtual function void add_pdev(pcie_device pdev);
    this.pdev.push_back(pdev);
  endfunction

  virtual function void clear_pdevs();
    this.pdev = {};
  endfunction

  // ---------------------------------------
  //  HELPERS: Return device(s) matching ...
  // ---------------------------------------

  // Given a BDF, return that pdev 
  virtual function pcie_device get_pdev_bdf(bdf_s bdf);
    pcie_device q_match[$];
    q_match = pdev.find_first(x) with (x.bdf==bdf);
    if (!q_match.size) return null;
    else               return q_match[0];
  endfunction

  // Given a primary bus, return all pdevs (potentially multiple for bridges)
  virtual function pdev_q_t get_pdev_primary_bus(bit [15:0] primary_bus);
    return (pdev.find(x) with (x.primary_bus==primary_bus));
  endfunction

  // Given a vendor ID, return all pdevs (potentially multiple)
  virtual function pdev_q_t get_pdev_vendorid(bit [15:0] vid);
    return (pdev.find(x) with (x.vendorid==vid));
  endfunction

  // Given a device ID, return all pdevs (potentially multiple)
  virtual function pdev_q_t get_pdev_deviceid(bit [15:0] did);
    return (pdev.find(x) with (x.deviceid==did));
  endfunction

  // Given a port type, return all pdevs (potentially multiple)
  virtual function pdev_q_t get_pdev_ptype(amd_devport_t ptype);
    return (pdev.find(x) with (x.ptype==ptype));
  endfunction

  // In a single link simulation, get the Root Port easily
  virtual function pcie_device get_pdev_RP();
    pcie_device q_match[$];
    q_match = pdev.find_first(x) with (x.ptype==PT_RP);
    if (!q_match.size) return null;
    else               return q_match[0];
  endfunction

  // In a single link simulation, get the Endpoint easily
  virtual function pcie_device get_pdev_EP();
    pcie_device q_match[$];
    q_match = pdev.find_first(x) with (x.ptype==PT_PCIE_EP);
    if (!q_match.size) return null;
    else               return q_match[0];
  endfunction

  // Get all RPs (potentially multiple)
  virtual function pdev_q_t get_pdev_allRPs();
    return (pdev.find(x) with (x.ptype==PT_RP));
  endfunction

  // Get all EPs (potentially multiple)
  virtual function pdev_q_t get_pdev_allEPs();
    return (pdev.find(x) with (x.ptype==PT_PCIE_EP));
  endfunction

endclass
