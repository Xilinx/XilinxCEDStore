// This base sim/verif/dut_inst.sv is a placeholder. Each variant
// (hdma/, hdma_ddr/) has a different DUT top module and port list, so
// each ships its own verif/dut_inst.sv under <variant>/sim/verif/, which
// run.tcl overlays on top of this file when the project is created
// (see run.tcl: `file copy -force ${src_dir}/sim/* $sim_dst`). If you are
// seeing this fatal, the variant-specific overlay did not get copied.
initial `uvm_fatal("DUT_INST", "No variant-specific verif/dut_inst.sv overlay was found -- see hdma/sim/verif/dut_inst.sv or hdma_ddr/sim/verif/dut_inst.sv")
