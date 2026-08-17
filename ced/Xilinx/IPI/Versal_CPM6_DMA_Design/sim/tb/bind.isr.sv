// This module is translating between the Vivado generated CPM6 instance 
// to the UVM interface used in the uvma-pcie-sim-framework for the PL and
// PS ISRs. This is specifically designed to be bound at the CPM6 uni-sim 
// instance level e.g.
//   bind CPM6 bind_isr bind_isr();
module bind_isr
  import uvm_pkg::*;
();

  `include "uvm_macros.svh"

  // ***********************************************
  // PS Interrupts
  // ***********************************************

  gpmon_if gpmon_ps_isr(); 
  assign gpmon_ps_isr.clk    = inst.cpm_osc_clk_div2; //async(???); whatever, just sim
  assign gpmon_ps_isr.sig[2] = inst.cpmps_corr_irq;
  assign gpmon_ps_isr.sig[1] = inst.cpmps_uncorr_irq;
  assign gpmon_ps_isr.sig[0] = inst.cpmps_misc_irq;

  initial
    uvm_config_db#(virtual gpmon_if)::set(null, "*", "vif_cpm_ps_isr", gpmon_ps_isr);

  // ***********************************************
  // PL Interrupts
  // ***********************************************

  gpmon_if gpmon_pl_isr(); 
  assign gpmon_pl_isr.clk    = inst.cpm_osc_clk_div2; //async(???); whatever, just sim 
  assign gpmon_pl_isr.sig[2] = inst.cpm_pl_irq2; //not sure this is CORR
  assign gpmon_pl_isr.sig[1] = inst.cpm_pl_irq1; //not sure this is UNCORR
  assign gpmon_pl_isr.sig[0] = inst.cpm_pl_irq0; //not sure if this is MISC

  initial
    uvm_config_db#(virtual gpmon_if)::set(null, "*", "vif_cpm_pl_isr", gpmon_pl_isr);

endmodule
