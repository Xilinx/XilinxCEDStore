// Must compile this package first because it's imported
// into this package
`ifdef CPM6_VIVADO
 `include "ps_vip_api_pkg.svh"
`endif

package axi_mst_seq_pkg;

  `include "uvm_macros.svh" 
  import uvm_pkg::*;

`ifdef CPM6_RTL
  import svt_uvm_pkg::*;
  import svt_axi_uvm_pkg::*;
`else
  import ps_vip_api_pkg::*;
`endif
  import cxl_mbox_pkg::*;
  import shim_device_pkg::*;
  import shim_enum_pkg::*;
  import shim_caps_pkg::*;
  import shim_ecaps_pkg::*;

  // For readability
  typedef enum bit [2:0] {
    MISC,     UNCORR,    CORR,    //0,1,2
    MERGED_0, MERGED_1,  MERGED_2 //3,4,5
  } irq_index_e;

  typedef struct {
    string     name;
    bit [31:0] addr;   //to IR_STATUS
    bit        enable;
    time       latest;
    // registers
    logic [31:0] sts;
    logic [31:0] mask; //1=hide it
  } irq_s;

  typedef class cseq_cxl_mbox; //forward typedef
   
  `include "base_log.sv"

  // Object for sequences
  `include "cxl_mbox/cxl_comp_cmd_obj.sv"
  `include "cxl_mbox/cmd_obj_0100h.sv"
  `include "cxl_mbox/base_010_23h.sv"
  `include "cxl_mbox/cmd_obj_0101h.sv"
  `include "cxl_mbox/cmd_obj_0102h.sv"
  `include "cxl_mbox/cmd_obj_0103h.sv"
  `include "cxl_mbox/base_030xh.sv"
  `include "cxl_mbox/cmd_obj_0300h.sv"
  `include "cxl_mbox/cmd_obj_0301h.sv"
  `include "cxl_mbox/cmd_obj_0400h.sv"
  `include "cxl_mbox/cmd_obj_0401h.sv"
  `include "cxl_mbox/cmd_obj_4000h.sv"

  // Equivalent to AXI VIP (sort of)
`ifdef CPM6_VIVADO
  `include "../vivado_only/ps_vip_vsequencer.sv"
`endif

  // Specific AXI VIP base sequences
  `include "seq_base_ps_axi32.sv"
  `include "seq_base_ps_axi128.sv"
  `include "seq_base_ps_axi128_bar.sv"
  // High level sequences
  `include "seq_ps_pcie_enum.sv"
  // Base sequence
  `include  "seq_base_isr_src.sv"
  `include "cseq_base_isr_src.sv"
  // First level sequence (summary)
  `include "seq_ps_isr_src.sv"
  `include "seq_pl_isr_src.sv"
  // Sub-sequences (block level)
  `include "cseq_cpm6_pcie_core_isr_src.sv"
  `include "cseq_cpm6_pcie_core_mbox.sv"
  `include "cxl_mbox/cseq_cxl_mbox.sv"

endpackage
