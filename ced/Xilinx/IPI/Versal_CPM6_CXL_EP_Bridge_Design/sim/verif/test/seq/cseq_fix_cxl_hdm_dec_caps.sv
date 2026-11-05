// cseq_fix_cxl_hdm_dec_caps.sv - Versal CPM6 CXL EP Bridge Design
//
// Programs 7 registers in the CXL Extended Capability Header linked list
// (RAS/Link/HDM-Decoder/BI-Decoder/Ext-Metadata caps, +0x241xxx off the
// active controller's CXL.cachemem MMIO base) that the CDO leaves at
// reset value, including CXL_HDM_DEC_CAP_HDR's Cap_ID (architected 0x0005).
// Uses axi_rd_mod_wr so only the named bits are touched; everything else
// keeps whatever the CDO already wrote.
class cseq_fix_cxl_hdm_dec_caps extends seq_base_ps_axi32;
  `uvm_object_utils(cseq_fix_cxl_hdm_dec_caps)

`ifdef CXL_BRDG_CTRL0
  localparam bit [47:0] MEMBAR0_RAS_CAP_REG     = 48'hfc24_1004;
  localparam bit [47:0] MEMBAR0_LINK_CAP_REG    = 48'hfc24_100c;
  localparam bit [47:0] CXL_HDM_DEC_CAP_HDR     = 48'hfc24_1010;
  localparam bit [47:0] CXL_BI_DEC_CAP_HDR      = 48'hfc24_1014;
  localparam bit [47:0] CXL_EXT_MET_DAT_CAP_HDR = 48'hfc24_1018;
  localparam bit [47:0] CXL_HDM_DEC_CAP_REG     = 48'hfc24_1200;
  localparam bit [47:0] CXL_HDM_DEC_0_CNTRL_REG = 48'hfc24_1220;
`else
  localparam bit [47:0] MEMBAR0_RAS_CAP_REG     = 48'hfc64_1004;
  localparam bit [47:0] MEMBAR0_LINK_CAP_REG    = 48'hfc64_100c;
  localparam bit [47:0] CXL_HDM_DEC_CAP_HDR     = 48'hfc64_1010;
  localparam bit [47:0] CXL_BI_DEC_CAP_HDR      = 48'hfc64_1014;
  localparam bit [47:0] CXL_EXT_MET_DAT_CAP_HDR = 48'hfc64_1018;
  localparam bit [47:0] CXL_HDM_DEC_CAP_REG     = 48'hfc64_1200;
  localparam bit [47:0] CXL_HDM_DEC_0_CNTRL_REG = 48'hfc64_1220;
`endif

  function new(string name = "cseq_fix_cxl_hdm_dec_caps");
    super.new(name);
  endfunction

  virtual task body();
    logic [31:0] mod_data;

    mod_data = 'x;
    mod_data[19:16] = 4'h3;
    axi_rd_mod_wr(MEMBAR0_RAS_CAP_REG, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Set Cap_Ver (bits[19:16]=3) at MEMBAR0_RAS_CAP_REG [0x%h]", MEMBAR0_RAS_CAP_REG), UVM_LOW)

    mod_data = 'x;
    mod_data[19:16] = 4'h4;
    axi_rd_mod_wr(MEMBAR0_LINK_CAP_REG, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Set Cap_Ver (bits[19:16]=4) at MEMBAR0_LINK_CAP_REG [0x%h]", MEMBAR0_LINK_CAP_REG), UVM_LOW)

    mod_data = 'x;
    mod_data[19:16] = 4'h3;
    axi_rd_mod_wr(CXL_HDM_DEC_CAP_HDR, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Set Ca_Ver (bits[19:16]=3) at CXL_HDM_DEC_CAP_HDR [0x%h]", CXL_HDM_DEC_CAP_HDR), UVM_LOW)

    mod_data = 'x;
    mod_data[15:0] = 16'h0;
    axi_rd_mod_wr(CXL_BI_DEC_CAP_HDR, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Cleared bits[15:0] at CXL_BI_DEC_CAP_HDR [0x%h]", CXL_BI_DEC_CAP_HDR), UVM_LOW)

    mod_data = 'x;
    mod_data[15:0] = 16'h0;
    axi_rd_mod_wr(CXL_EXT_MET_DAT_CAP_HDR, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Cleared bits[15:0] at CXL_EXT_MET_DAT_CAP_HDR [0x%h]", CXL_EXT_MET_DAT_CAP_HDR), UVM_LOW)

    mod_data = 'x;
    mod_data[22:21] = 2'h2;
    mod_data[3:0]   = 4'h0;
    axi_rd_mod_wr(CXL_HDM_DEC_CAP_REG, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Set bits[22:21]=2, bits[3:0]=0 at CXL_HDM_DEC_CAP_REG [0x%h]", CXL_HDM_DEC_CAP_REG), UVM_LOW)

    mod_data = 'x;
    mod_data[12] = 1'b1;
    axi_rd_mod_wr(CXL_HDM_DEC_0_CNTRL_REG, mod_data);
    `uvm_info(get_type_name(), $sformatf(
      "Set tgt_range_and_type (bit[12]=1) at CXL_HDM_DEC_0_CNTRL_REG [0x%h]", CXL_HDM_DEC_0_CNTRL_REG), UVM_LOW)
  endtask

endclass
