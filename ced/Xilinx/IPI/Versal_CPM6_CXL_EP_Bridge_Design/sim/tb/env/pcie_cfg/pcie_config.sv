class pcie_config extends uvm_object;
  
  `uvm_object_utils(pcie_config)

  function new(string name = "pcie_config");
    super.new(name);
  endfunction

  /* Typedefs */
  typedef enum bit [3:0] {
    // Type 0 PCI Cfg Space
    EP, LEG_EP, RCIEP=9, RCEC=10,
    // Type 1 PCI Cfg Space
    RP=4, SW_USP, SW_DSP, PCIE_2_PCI, PCI_2_PCIE,
    // Unset
    NO_PORT=15
  } dev_port_e;
  
  typedef enum bit [3:0] {ANY_SPEED, GEN1, GEN2, GEN3, GEN4, GEN5, GEN6} speed_e;

  /* High Level */
  rand logic [ 7:0] num_pfs;
  rand logic [11:0] num_vfs;

  /* Capabilities */
  typedef struct {
    rand struct {
           logic      flit_mode_supp;
           dev_port_e dev_port_type = NO_PORT;
    } pcie_cap;  
    rand struct {
      rand logic [12:0] max_payload_size_supp;
      rand logic        rx_mps_fixed; 
    } device_cap;
    rand struct {
      rand logic        ext_fmt_field_supp;
    } device_cap2;
    rand struct {
      rand logic        retimer1_pres_det_supp;
      rand logic        retimer2_pres_det_supp;
    } link_cap2;
    rand struct {
      rand logic        flit_mode_disable;
    } link_ctl;
    rand struct {
      rand speed_e      target_link_speed;
    } link_ctl2;
  } pcie_cap_t; rand pcie_cap_t pcie_cap;

  typedef struct {
    rand struct {
      rand logic [5:0] multi_msg_cap;
      rand logic       addr64_cap;
      rand logic       per_vec_mask_cap;
      rand logic       ext_msg_data_cap;
    } msg_control; 
  } msi_cap_t; rand msi_cap_t msi_cap;

  /* Extended Capabilities */

  /* Sideband Features (that may roll into capabilities) */
  rand struct {
    rand logic [ 3:0] reqr_tag_supp;
    rand logic [ 3:0] cmpr_tag_supp;
  } tags;
  logic flit_mode_ctl; //master control to force FM or NFM

  /* Constraints */
  constraint c_mps { pcie_cap.device_cap.max_payload_size_supp inside {128, 256, 512, 1024, 2048, 4096}; }
  constraint c_tag_supp {
    tags.reqr_tag_supp inside {5, 8, 10, 14};
    tags.cmpr_tag_supp inside {8, 10, 14};
    tags.reqr_tag_supp <= tags.cmpr_tag_supp; 
  }
  constraint c_retimer_pres_det { !pcie_cap.link_cap2.retimer1_pres_det_supp -> !pcie_cap.link_cap2.retimer2_pres_det_supp; }
  constraint c_msi {
    msi_cap.msg_control.multi_msg_cap inside {1, 2, 4, 8, 16, 32};
  }
  constraint c_speed {
    pcie_cap.link_ctl2.target_link_speed != ANY_SPEED; 
    (!pcie_cap.pcie_cap.flit_mode_supp ||
     pcie_cap.link_ctl.flit_mode_disable) -> pcie_cap.link_ctl2.target_link_speed != GEN6;
  }
  // PCIe spec calls out "MUST@FLIT" which are features that are mandatory
  // for components that support flit mode (flit_mode_supported=1). Parent
  // object will enable or disable this constraint before randomization.
  constraint c_must_at_flit {
    pcie_cap.device_cap.max_payload_size_supp >= 512; 
    pcie_cap.device_cap.rx_mps_fixed == 1;
    pcie_cap.device_cap2.ext_fmt_field_supp == 1;
    pcie_cap.link_cap2.retimer1_pres_det_supp == 1;
    pcie_cap.link_cap2.retimer2_pres_det_supp == 1;
    msi_cap.msg_control.addr64_cap == 1;
    tags.cmpr_tag_supp == 14;
  }
 
  function void pre_randomize();
    // Check that variables that MUST be set have been
    if (pcie_cap.pcie_cap.dev_port_type == NO_PORT)
      `uvm_fatal(get_type_name, "Must set dev_port_type before randomization")
    // We must randomize flit mode variables FIRST so we can control MUST@FLIT
    // constraint enablement
    if (flit_mode_ctl===1'b0) begin
        void'(std::randomize(pcie_cap.pcie_cap.flit_mode_supp,
                             pcie_cap.link_ctl.flit_mode_disable)    
          with {pcie_cap.pcie_cap.flit_mode_supp   ==1'b0 || 
                pcie_cap.link_ctl.flit_mode_disable==1'b1;});
      
    end
    else if (flit_mode_ctl===1'b1) begin
      pcie_cap.pcie_cap.flit_mode_supp    = 1'b1;
      pcie_cap.link_ctl.flit_mode_disable = 1'b0;
    end
    else if (pcie_cap.pcie_cap.flit_mode_supp==='x) begin
      void'(std::randomize(pcie_cap.pcie_cap.flit_mode_supp));
    end
    c_must_at_flit.constraint_mode(pcie_cap.pcie_cap.flit_mode_supp);
    // Disable randomization if variable already set
    num_pfs.rand_mode(num_pfs==='x);
    num_vfs.rand_mode(num_vfs==='x);
    if (!(pcie_cap.device_cap.max_payload_size_supp inside {'x, 128, 256, 512, 1024, 2048, 4096})) begin
     `uvm_error(get_type_name, $sformatf("max_payload_size_supp=%0d is invalid", pcie_cap.device_cap.max_payload_size_supp))
      pcie_cap.device_cap.max_payload_size_supp.rand_mode(1);
    end
    else pcie_cap.device_cap.max_payload_size_supp.rand_mode(pcie_cap.device_cap.max_payload_size_supp==='x);
    // --- 
    pcie_cap.device_cap.rx_mps_fixed.rand_mode(pcie_cap.device_cap.rx_mps_fixed==='x);
    pcie_cap.device_cap2.ext_fmt_field_supp.rand_mode(pcie_cap.device_cap2.ext_fmt_field_supp==='x);
    pcie_cap.link_cap2.retimer1_pres_det_supp.rand_mode(pcie_cap.link_cap2.retimer1_pres_det_supp==='x);
    pcie_cap.link_cap2.retimer2_pres_det_supp.rand_mode(pcie_cap.link_cap2.retimer2_pres_det_supp==='x);
    pcie_cap.link_ctl.flit_mode_disable.rand_mode(pcie_cap.link_ctl.flit_mode_disable==='x);
    pcie_cap.link_ctl2.target_link_speed.rand_mode(pcie_cap.link_ctl2.target_link_speed==ANY_SPEED);
    // --- 
    if (!(tags.reqr_tag_supp inside {'x, 5, 8, 10, 14})) begin
      `uvm_error(get_type_name, $sformatf("reqr_tag_supp=%0d is invalid", tags.reqr_tag_supp))
      tags.reqr_tag_supp.rand_mode(1);
    end
    else tags.reqr_tag_supp.rand_mode(tags.reqr_tag_supp==='x);
    // --- 
    if (!(tags.cmpr_tag_supp inside {'x, 8, 10, 14})) begin
      `uvm_error(get_type_name, $sformatf("cmpr_tag_supp=%0d is invalid", tags.cmpr_tag_supp))
      tags.cmpr_tag_supp.rand_mode(1);
    end
    else tags.cmpr_tag_supp.rand_mode(tags.cmpr_tag_supp==='x);
    // --- 
    if (!(msi_cap.msg_control.multi_msg_cap inside {'x, 1, 2, 4, 8, 16, 32})) begin
      `uvm_error(get_type_name, $sformatf("multi_msg_cap=%0d is invalid", msi_cap.msg_control.multi_msg_cap))
      msi_cap.msg_control.multi_msg_cap.rand_mode(1);
    end
    else tags.cmpr_tag_supp.rand_mode(tags.cmpr_tag_supp==='x);
    // --- 
    if (pcie_cap.pcie_cap.dev_port_type == EP) begin //PCIe Spec
      msi_cap.msg_control.addr64_cap = 1;
      msi_cap.msg_control.addr64_cap.rand_mode(0);
    end
    else if (pcie_cap.pcie_cap.dev_port_type == RP) begin //Avery VIP fatals when rands to 0
      msi_cap.msg_control.addr64_cap = 1;
      msi_cap.msg_control.addr64_cap.rand_mode(0);
    end
    else
      msi_cap.msg_control.addr64_cap.rand_mode(msi_cap.msg_control.addr64_cap==='x);
  endfunction

  function void post_randomize();
  endfunction

  virtual function void print_settings(int fd);
    $fdisplay(fd, "  // Settings from %0s", get_type_name);
    $fdisplay(fd, "  - num_pfs : %0d",                num_pfs);
    $fdisplay(fd, "  - num_vfs : %0d - NOT USED YET", num_vfs);
    // PCIe Capability
    $fdisplay(fd, "  - flit_mode_supp : %0d",         pcie_cap.pcie_cap.flit_mode_supp);
    $fdisplay(fd, "  - dev_port_type : %0s",          pcie_cap.pcie_cap.dev_port_type.name);
    $fdisplay(fd, "  - max_payload_size_supp : %0d",  pcie_cap.device_cap.max_payload_size_supp); 
    $fdisplay(fd, "  - rx_mps_fixed : %0d",           pcie_cap.device_cap.rx_mps_fixed);
    $fdisplay(fd, "  - ext_fmt_field_supp : %0d",     pcie_cap.device_cap2.ext_fmt_field_supp);
    $fdisplay(fd, "  - retimer1_pres_det_supp : %0d", pcie_cap.link_cap2.retimer1_pres_det_supp);
    $fdisplay(fd, "  - retimer2_pres_det_supp : %0d", pcie_cap.link_cap2.retimer2_pres_det_supp);
    $fdisplay(fd, "  - flit_mode_disable : %0d",      pcie_cap.link_ctl.flit_mode_disable);
    $fdisplay(fd, "  - target_link_speed : %0s",      pcie_cap.link_ctl2.target_link_speed.name);
    $fdisplay(fd, "  - reqr_tag_supp : %0d",          tags.reqr_tag_supp);
    $fdisplay(fd, "  - cmpr_tag_supp : %0d",          tags.cmpr_tag_supp);
    // MSI Capability
    $fdisplay(fd, "  - multi_msg_cap : %0d",          msi_cap.msg_control.multi_msg_cap);
    $fdisplay(fd, "  - addr64_cap : %0d",             msi_cap.msg_control.addr64_cap);
    $fdisplay(fd, "  - per_vec_mask_cap : %0d",       msi_cap.msg_control.per_vec_mask_cap);
    $fdisplay(fd, "  - ext_msg_data_cap : %0d",       msi_cap.msg_control.ext_msg_data_cap);
  endfunction

  // We will just overwrite all the fields that we have configured, not taking 
  // into account default values. There is no methodology for RdModWr.
  virtual function void create_cdo(int fd, int ctrlr);
    bit [31:0] d;
    // --- 
    d = `GET_DFAULT_C(PF0_PCIE_CAP_PCIE_CAP_ID_PCIE_NEXT_CAP_PTR_PCIE_CAP_REG)
    d[31]    = pcie_cap.pcie_cap.flit_mode_supp;
    d[23:20] = pcie_cap.pcie_cap.dev_port_type;
    `CDO_SET_ALL_C(PF0_PCIE_CAP_PCIE_CAP_ID_PCIE_NEXT_CAP_PTR_PCIE_CAP_REG, d)
    // --- 
    d = `GET_DFAULT_C(PF0_PCIE_CAP_DEVICE_CAPABILITIES_REG) 
    d[17]  = pcie_cap.device_cap.rx_mps_fixed;
    d[5]   = tags.reqr_tag_supp inside {8, 10, 14}; //Ext. Tag Field Supp
    d[2:0] = $clog2(pcie_cap.device_cap.max_payload_size_supp)-7;
    `CDO_SET_ALL_C(PF0_PCIE_CAP_DEVICE_CAPABILITIES_REG, d)
    // --- 
    d = `GET_DFAULT_C(PF0_PCIE_CAP_DEVICE_CAPABILITIES2_REG) 
    d[20] = pcie_cap.device_cap2.ext_fmt_field_supp;
    d[17] = tags.reqr_tag_supp inside {10, 14};
    d[16] = tags.cmpr_tag_supp inside {10, 14};
    `CDO_SET_ALL_C(PF0_PCIE_CAP_DEVICE_CAPABILITIES2_REG, d)
    // --- 
    d = `GET_DFAULT_C(PF0_PCIE_CAP_LINK_CAPABILITIES2_REG) 
    d[24] = pcie_cap.link_cap2.retimer2_pres_det_supp;
    d[23] = pcie_cap.link_cap2.retimer1_pres_det_supp;
    `CDO_SET_ALL_C(PF0_PCIE_CAP_LINK_CAPABILITIES2_REG, d)
    // --- 
    d = `GET_DFAULT_C(PF0_PCIE_CAP_LINK_CONTROL_LINK_STATUS_REG)
    d[13] = pcie_cap.link_ctl.flit_mode_disable;
    `CDO_SET_ALL_C(PF0_PCIE_CAP_LINK_CONTROL_LINK_STATUS_REG, d)
    // --- 
    d = `GET_DFAULT_C(PF0_DEV3_EXT_CAP_DEVICE_CAPABILITIES_REG)
    d[2] = (tags.reqr_tag_supp==14);
    d[1] = (tags.cmpr_tag_supp==14);
    `CDO_SET_ALL_C(PF0_DEV3_EXT_CAP_DEVICE_CAPABILITIES_REG, d)
    // --- 
    d = `GET_DFAULT_C(PF0_MSI_CAP_PCI_MSI_CAP_ID_NEXT_CTRL_REG)
    d[9+16]    = msi_cap.msg_control.ext_msg_data_cap;
    d[8+16]    = msi_cap.msg_control.per_vec_mask_cap;
    d[7+16]    = msi_cap.msg_control.addr64_cap;
    d[1+16+:3] = $clog2(msi_cap.msg_control.multi_msg_cap);
    `CDO_SET_ALL_C(PF0_MSI_CAP_PCI_MSI_CAP_ID_NEXT_CTRL_REG, d)
    // --- 
    d = `GET_DFAULT_C(PF0_PORT_LOGIC_TIMER_CTRL_MAX_FUNC_NUM_OFF)
    d[0+:8]    = num_pfs-1;
    `CDO_SET_ALL_C(PF0_PORT_LOGIC_TIMER_CTRL_MAX_FUNC_NUM_OFF, d)
    // --- 
    if (num_pfs==1) begin
      `CDO_SET_BYTES_C(PF0_ARI_CAP_CAP_REG, 4'b0010, 32'h0)
    end
    if (num_vfs==0) begin
      d = `GET_DFAULT_C(PF0_PL64G_CAP_PL64G_EXT_CAP_HDR_REG)
      d[31:20] = 'h268;
      `CDO_SET_ALL_C(PF0_PL64G_CAP_PL64G_EXT_CAP_HDR_REG, d)
    end
  endfunction

endclass
