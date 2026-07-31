// This module is translating between the Vivado generated CPM6 instance 
// to the UVM interfaces used in the uvma-pcie-sim-framework for ELBI. This 
// is specifically designed to be bound at the CPM6 uni-sim instance level 
// e.g.
//   bind CPM6 bind_elbi bind_elbi();
module bind_elbi
  import uvm_pkg::*;
();

  `include "uvm_macros.svh"

  elbi_if elbi_0(), elbi_1();

  initial begin
    uvm_config_db#(virtual elbi_if)::set(null, "*", "vif_elbi[0]", elbi_0);
    uvm_config_db#(virtual elbi_if)::set(null, "*", "vif_elbi[1]", elbi_1);
  end

  // -------------
  // Controller 0 
  // -------------

  initial begin
    wait (elbi_0.agent_driven);
    force inst.pcie0_elbi_din         = elbi_0.ext_lbc_din;
    force inst.pcie0_elbi_ack         = elbi_0.ext_lbc_ack;
    force inst.pcie0_elbi_override_en = elbi_0.ext_lbc_override_en;
  end

  assign elbi_0.clk                      = inst.pcie0_clk;
  assign elbi_0.lbc_ext_addr             = inst.pcie0_elbi_addr;
  assign elbi_0.lbc_ext_dout             = inst.pcie0_elbi_dout;
  assign elbi_0.lbc_ext_valid            = inst.pcie0_elbi_valid;
  assign elbi_0.lbc_ext_cs               = inst.pcie0_elbi_cs;
  assign elbi_0.lbc_ext_wr               = inst.pcie0_elbi_wr;
  assign elbi_0.lbc_ext_rd               = inst.pcie0_elbi_rd;
  assign elbi_0.lbc_ext_dbi_access       = inst.pcie0_elbi_dbi;
  assign elbi_0.lbc_ext_cxl_mbar0_access = inst.pcie0_elbi_cxl_mbar0;
  assign elbi_0.lbc_ext_rom_access       = inst.pcie0_elbi_rom;
  assign elbi_0.lbc_ext_io_access        = inst.pcie0_elbi_io;
  assign elbi_0.lbc_ext_bar_num          = inst.pcie0_elbi_bar_num;
  assign elbi_0.lbc_ext_vfunc_num        = inst.pcie0_elbi_vfunc_num;
  assign elbi_0.lbc_ext_vfunc_active     = inst.pcie0_elbi_vfunc_active;

  // -------------
  // Controller 1 
  // -------------

  initial begin
    wait (elbi_1.agent_driven);
    force inst.pcie1_elbi_din         = elbi_1.ext_lbc_din;
    force inst.pcie1_elbi_ack         = elbi_1.ext_lbc_ack;
    force inst.pcie1_elbi_override_en = elbi_1.ext_lbc_override_en;
  end

  assign elbi_1.clk                      = inst.pcie1_clk;
  assign elbi_1.lbc_ext_addr             = inst.pcie1_elbi_addr;
  assign elbi_1.lbc_ext_dout             = inst.pcie1_elbi_dout;
  assign elbi_1.lbc_ext_valid            = inst.pcie1_elbi_valid;
  assign elbi_1.lbc_ext_cs               = inst.pcie1_elbi_cs;
  assign elbi_1.lbc_ext_wr               = inst.pcie1_elbi_wr;
  assign elbi_1.lbc_ext_rd               = inst.pcie1_elbi_rd;
  assign elbi_1.lbc_ext_dbi_access       = inst.pcie1_elbi_dbi;
  assign elbi_1.lbc_ext_cxl_mbar0_access = inst.pcie1_elbi_cxl_mbar0;
  assign elbi_1.lbc_ext_rom_access       = inst.pcie1_elbi_rom;
  assign elbi_1.lbc_ext_io_access        = inst.pcie1_elbi_io;
  assign elbi_1.lbc_ext_bar_num          = inst.pcie1_elbi_bar_num;
  assign elbi_1.lbc_ext_vfunc_num        = inst.pcie1_elbi_vfunc_num;
  assign elbi_1.lbc_ext_vfunc_active     = inst.pcie1_elbi_vfunc_active;

endmodule
