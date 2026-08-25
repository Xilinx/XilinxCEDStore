// This class will be used to control a configuration of up to a dual link
// system by capturing the capabilities and knobs that a controller should 
// be configured to support.
class generic_config extends uvm_object;

  `uvm_object_utils(generic_config)

  string settings_logfile; 

  // Sub-config objects
  rand pcie_config pcie_cfg[2]; 
  rand cxl_config  cxl_cfg[2]; 

  function new(string name = "generic_config");
    super.new(name);
    for (int ii=0; ii<2; ii++) begin
      cxl_cfg[ii]  = cxl_config ::type_id::create($sformatf("cxl_cfg[%0d]",ii));
      pcie_cfg[ii] = pcie_config::type_id::create($sformatf("pcie_cfg[%0d]",ii));
    end
  endfunction

  // Typedef

  // Variables that MUST be controlled
  bit [1:0]                       ctrlr_en;
  enum {PCIE, PCIE_CXL, CXL_ONLY} port_ctl[2];
  
  // Do stuff before randomization
  function void pre_randomize;
    foreach (ctrlr_en[ii]) begin
      if (ctrlr_en[ii]) begin
        pcie_cfg[ii].rand_mode(1);
        // CXL-enabled port 
        if (port_ctl[ii]!=PCIE) begin
          cxl_cfg[ii].rand_mode(1);
          cxl_cfg[ii].dvsec_cxl_cap.en = (pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type!=pcie_config::RP);
        end
      end
      else begin
        pcie_cfg[ii].rand_mode(0);
        cxl_cfg[ii].rand_mode(0);
      end
    end
  endfunction

  // Do stuff after randomization
  function void post_randomize;
  endfunction

  virtual function void print_settings;
    int fd;
    if (settings_logfile == "") begin
      `uvm_error(get_type_name, "Specify 'settings_logfile' member to get results saved")
      return;
    end
    fd = $fopen(settings_logfile, "w");
    // Print summary
    $fdisplay(fd, "// ----------------------------------------- //");
    $fdisplay(fd, "// Configuration settings from %0s", get_type_name);
    $fdisplay(fd, "// ----------------------------------------- //");
    // Print each port
    for (int ii=0; ii<2; ii++) begin
      $fdisplay(fd, "// Port %0d : %0sABLED", ii, ctrlr_en[ii]? "EN" : "DIS");
      if (!ctrlr_en[ii]) continue;
      pre_top_cb(fd, ii); 
      // Save this object results
      $fdisplay(fd, "  - port_ctl  : %0s", port_ctl[ii].name);
      // Save child results
      pre_pcie_cb(fd, ii); 
      pcie_cfg[ii].print_settings(fd);
      if (port_ctl[ii]!=PCIE) begin
        pre_cxl_cb(fd, ii); 
        cxl_cfg[ii].print_settings(fd);
      end
    end
    // Done
    $fclose(fd);
  endfunction

  // Callback hooks for extended classes
  virtual function void pre_top_cb(int fd,  int ctrlr = -1); endfunction
  virtual function void pre_pcie_cb(int fd, int ctrlr = -1); endfunction
  virtual function void pre_cxl_cb(int fd,  int ctrlr = -1); endfunction

endclass
