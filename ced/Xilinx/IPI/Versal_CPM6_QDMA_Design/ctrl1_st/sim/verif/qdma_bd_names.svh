// qdma_bd_names.svh - names of the block design that instantiates cpm6_qdma
//
// The BD-level monitors bind to the BD module by name, and Vivado names the BD
// and its generated wrappers after the name given at BD creation time. Each
// project or example design therefore supplies its own names; the defaults
// below match a BD created as "design_1".
//
//   CPM6_BD_TOP_MODULE      BD module, the bind target for BD-wire monitors
//   CPM6_BD_TOP_WRAPPER     HDL wrapper generated around the BD
//   CPM6_BD_TOP_SIM_WRAPPER top-level simulation wrapper instantiated by the TB
//   CPM6_BD_PERIPH_RESETN   BD net carrying the proc_sys_reset peripheral_aresetn
//                           output; Vivado renames this net after the BD output
//                           port when the reset is exported from the BD
//
// Override on the compile command line rather than editing this file, e.g. for
// an example design whose BD is "cpm6_qdma" inside top "ctrl1_qdma_ep":
//     +define+CPM6_BD_TOP_MODULE=cpm6_qdma
//     +define+CPM6_BD_TOP_WRAPPER=ctrl1_qdma_ep
//     +define+CPM6_BD_TOP_SIM_WRAPPER=ctrl1_qdma_ep_sim_wrapper
`ifndef QDMA_BD_NAMES_SVH
`define QDMA_BD_NAMES_SVH

`ifndef CPM6_BD_TOP_MODULE
`define CPM6_BD_TOP_MODULE design_1
`endif

`ifndef CPM6_BD_TOP_WRAPPER
`define CPM6_BD_TOP_WRAPPER design_1_wrapper
`endif

`ifndef CPM6_BD_TOP_SIM_WRAPPER
`define CPM6_BD_TOP_SIM_WRAPPER design_1_wrapper_sim_wrapper
`endif

`ifndef CPM6_BD_PERIPH_RESETN
`define CPM6_BD_PERIPH_RESETN proc_sys_reset_0_peripheral_aresetn
`endif

`endif // QDMA_BD_NAMES_SVH
