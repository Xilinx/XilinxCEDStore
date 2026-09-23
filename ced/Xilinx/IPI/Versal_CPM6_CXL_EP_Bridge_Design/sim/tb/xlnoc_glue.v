// ===========================================================================
// xlnoc_glue.v - NoC Packet Switch (NPS) simulation-model glue.
//
// WHY THIS FILE EXISTS: Vivado auto-generates a SEPARATE block design ("xlnoc", distinct from
// this project's own "design_1" BD) holding the shared NoC Packet Switch
// (NPS) crossbar simulation models needed to route AXI-NoC traffic between
// this design's 4 axi_noc2_cN (DDRMC5) instances and their AXI masters.
// axi_noc2_cN's internal NoC Packet Port (NPP) signals
// (mc0_ddrc_noc2dmc_*/mc0_ddrc_dmc2noc_*, s00_axi_nmu_if_noc_npp_*,
// m00_axi_nsu_if_noc_npp_*) have NO top-level port exposure on
// design_1_wrapper - they can only be connected to the shared "xlnoc" NPS
// model via simulation-only cross-hierarchical `assign` statements
// targeting deep instance paths inside axi_noc2_cN.inst.
//
// Vivado's OWN default simulation top for this project,
// design_1_wrapper_sim_wrapper.v ("Purpose: NoC Simulation Wrapper
// netlist"), does exactly this: it instantiates BOTH design_1_wrapper AND xlnoc, then
// wires them together with ~44 pairs of cross-hierarchical assigns. This
// file's wire declarations, xlnoc instantiation, and assign statements
// below are copied verbatim from that Vivado-generated file (only the
// `design_1_wrapper_i.design_1_i.` hierarchical prefix was substituted -
// nothing else was changed or re-derived).
//
// THE GAP THIS FIXES: this design's own testbenches (board.sv for
// light_tb, dut_inst.sv for the standalone/Avery path) deliberately do NOT
// use design_1_wrapper_sim_wrapper as their elaboration top - they need
// their OWN top (board/tb_top) for the UVM config_db / CSR / VIP logic,
// which required disabling Vivado's SIM_WRAPPER_TOP fileset property.
// Doing so throws away design_1_wrapper_sim_wrapper's xlnoc
// wiring entirely: without it, every axi_noc2_cN instance's internal NoC
// ports are left completely floating (undriven) - SILENTLY, with no
// compile or elaborate error or warning. This does not affect a pure
// CSR-level test (light_tb's csr_sanity_test.vh never touches the NoC -
// it stays on the LPD_AXI_PL/PS-VIP path), but it WOULD silently produce
// meaningless (X-propagated or simply non-functional) results for any test
// that drives CXL.mem/DDR traffic through the NoC - e.g. a real
// traffic-driving sequence like rand_traffic_cxl_mem_hdm1.sv.
//
// USAGE: this module has NO ports - it must be elaborated as an
// ADDITIONAL VCS `-top` target alongside board/tb_top (VCS supports
// multiple `-top` arguments in one invocation), exactly as
// design_1_wrapper_sim_wrapper.v's own xlnoc_top.v companion file
// describes itself: "Parallel-top simulation module for the logical NoC
// (auto-compiled and bound with the design)". It is not instantiated by
// anything else - do not add it to any module's port list.
//
// `` `DUT_HIER_ROOT`` must resolve to wherever `design_1_wrapper` is
// actually instantiated in the enclosing testbench:
//   light_tb (board.sv):         board.EP            (define LIGHT_TB_ROOT)
//   standalone (dut_inst.sv):    tb_top.dut_inst      (default)
// Add this file to compile.sh/vlogan invocation and add both `xil_defaultlib.
// xlnoc_glue` as a second -top and +define+LIGHT_TB_ROOT (light_tb only) to
// the elaborate/vcs invocation.
//
// This module also needs `xlnoc`'s own simulation-model source compiled
// (Vivado-generated, at <workdir>/design_1.gen/sim_1/bd/xlnoc/sim/xlnoc.v
// in a project built from this CED's build_project*.tcl scripts) - that
// file is NOT part of this repo (it's Vivado-IP-generated per-project
// output, like compile.sh/elaborate.sh themselves) and must be located and
// added to the compile file list alongside this file.
//
// NOT YET LIVE-VERIFIED past hierarchical-name resolution at compile/
// elaborate time: this fixes the WIRING gap, but has not been proven to
// produce correct NoC *traffic* behavior end-to-end, since live simulation
// of either path is currently blocked by separate issues (missing CPM6
// secure-IP sim model / missing precompiled VCS simlib / NoC-BFM
// duplicate-typedef bug). Verify this file's hierarchical references
// resolve cleanly (no "undefined hierarchical name" errors) the next time
// either path gets past those blockers.
// ===========================================================================

`ifdef LIGHT_TB_ROOT
  `define DUT_HIER_ROOT board.EP
`else
  `define DUT_HIER_ROOT tb_top.dut_inst
`endif

module xlnoc_glue ();

  wire [0:0]nps4_2_0_mdmc_npp_0_credit_rdy_net;
  wire [4:0]nps4_2_0_mdmc_npp_0_credit_return_net;
  wire [181:0]nps4_2_0_mdmc_npp_0_flit_net;
  wire [1:0]nps4_2_0_mdmc_npp_0_pdest_id_net;
  wire [4:0]nps4_2_0_mdmc_npp_0_valid_net;
  wire [0:0]nps4_2_0_sdmc_npp_0_credit_rdy_net;
  wire [4:0]nps4_2_0_sdmc_npp_0_credit_return_net;
  wire [181:0]nps4_2_0_sdmc_npp_0_flit_net;
  wire [1:0]nps4_2_0_sdmc_npp_0_pdest_id_net;
  wire [4:0]nps4_2_0_sdmc_npp_0_valid_net;
  wire [0:0]nps4_2_1_mdmc_npp_0_credit_rdy_net;
  wire [4:0]nps4_2_1_mdmc_npp_0_credit_return_net;
  wire [181:0]nps4_2_1_mdmc_npp_0_flit_net;
  wire [1:0]nps4_2_1_mdmc_npp_0_pdest_id_net;
  wire [4:0]nps4_2_1_mdmc_npp_0_valid_net;
  wire [0:0]nps4_2_1_sdmc_npp_0_credit_rdy_net;
  wire [4:0]nps4_2_1_sdmc_npp_0_credit_return_net;
  wire [181:0]nps4_2_1_sdmc_npp_0_flit_net;
  wire [1:0]nps4_2_1_sdmc_npp_0_pdest_id_net;
  wire [4:0]nps4_2_1_sdmc_npp_0_valid_net;
  wire [0:0]nps4_2_2_mdmc_npp_0_credit_rdy_net;
  wire [4:0]nps4_2_2_mdmc_npp_0_credit_return_net;
  wire [181:0]nps4_2_2_mdmc_npp_0_flit_net;
  wire [1:0]nps4_2_2_mdmc_npp_0_pdest_id_net;
  wire [4:0]nps4_2_2_mdmc_npp_0_valid_net;
  wire [0:0]nps4_2_2_sdmc_npp_0_credit_rdy_net;
  wire [4:0]nps4_2_2_sdmc_npp_0_credit_return_net;
  wire [181:0]nps4_2_2_sdmc_npp_0_flit_net;
  wire [1:0]nps4_2_2_sdmc_npp_0_pdest_id_net;
  wire [4:0]nps4_2_2_sdmc_npp_0_valid_net;
  wire [0:0]nps4_2_3_mdmc_npp_0_credit_rdy_net;
  wire [4:0]nps4_2_3_mdmc_npp_0_credit_return_net;
  wire [181:0]nps4_2_3_mdmc_npp_0_flit_net;
  wire [1:0]nps4_2_3_mdmc_npp_0_pdest_id_net;
  wire [4:0]nps4_2_3_mdmc_npp_0_valid_net;
  wire [0:0]nps4_2_3_sdmc_npp_0_credit_rdy_net;
  wire [4:0]nps4_2_3_sdmc_npp_0_credit_return_net;
  wire [181:0]nps4_2_3_sdmc_npp_0_flit_net;
  wire [1:0]nps4_2_3_sdmc_npp_0_pdest_id_net;
  wire [4:0]nps4_2_3_sdmc_npp_0_valid_net;
  wire [0:0]nps_0_mnpp_s_credit_rdy_net;
  wire [7:0]nps_0_mnpp_s_credit_return_net;
  wire [181:0]nps_0_mnpp_s_flit_net;
  wire [7:0]nps_0_mnpp_s_valid_net;
  wire [0:0]nps_0_snpp_s_credit_rdy_net;
  wire [7:0]nps_0_snpp_s_credit_return_net;
  wire [181:0]nps_0_snpp_s_flit_net;
  wire [7:0]nps_0_snpp_s_valid_net;
  wire [0:0]nps_1_mnpp_s_credit_rdy_net;
  wire [7:0]nps_1_mnpp_s_credit_return_net;
  wire [181:0]nps_1_mnpp_s_flit_net;
  wire [7:0]nps_1_mnpp_s_valid_net;
  wire [0:0]nps_1_snpp_s_credit_rdy_net;
  wire [7:0]nps_1_snpp_s_credit_return_net;
  wire [181:0]nps_1_snpp_s_flit_net;
  wire [7:0]nps_1_snpp_s_valid_net;
  wire [0:0]nps_2_mnpp_s_credit_rdy_net;
  wire [7:0]nps_2_mnpp_s_credit_return_net;
  wire [181:0]nps_2_mnpp_s_flit_net;
  wire [7:0]nps_2_mnpp_s_valid_net;
  wire [0:0]nps_2_snpp_s_credit_rdy_net;
  wire [7:0]nps_2_snpp_s_credit_return_net;
  wire [181:0]nps_2_snpp_s_flit_net;
  wire [7:0]nps_2_snpp_s_valid_net;
  wire [0:0]nps_3_mnpp_s_credit_rdy_net;
  wire [7:0]nps_3_mnpp_s_credit_return_net;
  wire [181:0]nps_3_mnpp_s_flit_net;
  wire [7:0]nps_3_mnpp_s_valid_net;
  wire [0:0]nps_3_snpp_s_credit_rdy_net;
  wire [7:0]nps_3_snpp_s_credit_return_net;
  wire [181:0]nps_3_snpp_s_flit_net;
  wire [7:0]nps_3_snpp_s_valid_net;
  wire [0:0]nps_4_mnpp_s_credit_rdy_net;
  wire [7:0]nps_4_mnpp_s_credit_return_net;
  wire [181:0]nps_4_mnpp_s_flit_net;
  wire [7:0]nps_4_mnpp_s_valid_net;
  wire [0:0]nps_4_snpp_s_credit_rdy_net;
  wire [7:0]nps_4_snpp_s_credit_return_net;
  wire [181:0]nps_4_snpp_s_flit_net;
  wire [7:0]nps_4_snpp_s_valid_net;
  wire [0:0]nps_5_mnpp_s_credit_rdy_net;
  wire [7:0]nps_5_mnpp_s_credit_return_net;
  wire [181:0]nps_5_mnpp_s_flit_net;
  wire [7:0]nps_5_mnpp_s_valid_net;
  wire [0:0]nps_5_snpp_s_credit_rdy_net;
  wire [7:0]nps_5_snpp_s_credit_return_net;
  wire [181:0]nps_5_snpp_s_flit_net;
  wire [7:0]nps_5_snpp_s_valid_net;

  xlnoc xlnoc_i
       (.nps4_2_0_MDMC_NPP_0_credit_rdy(nps4_2_0_mdmc_npp_0_credit_rdy_net),
        .nps4_2_0_MDMC_NPP_0_credit_return(nps4_2_0_mdmc_npp_0_credit_return_net),
        .nps4_2_0_MDMC_NPP_0_flit(nps4_2_0_mdmc_npp_0_flit_net),
        .nps4_2_0_MDMC_NPP_0_pdest_id(nps4_2_0_mdmc_npp_0_pdest_id_net),
        .nps4_2_0_MDMC_NPP_0_valid(nps4_2_0_mdmc_npp_0_valid_net),
        .nps4_2_0_SDMC_NPP_0_credit_rdy(nps4_2_0_sdmc_npp_0_credit_rdy_net),
        .nps4_2_0_SDMC_NPP_0_credit_return(nps4_2_0_sdmc_npp_0_credit_return_net),
        .nps4_2_0_SDMC_NPP_0_flit(nps4_2_0_sdmc_npp_0_flit_net),
        .nps4_2_0_SDMC_NPP_0_pdest_id(nps4_2_0_sdmc_npp_0_pdest_id_net),
        .nps4_2_0_SDMC_NPP_0_valid(nps4_2_0_sdmc_npp_0_valid_net),
        .nps4_2_1_MDMC_NPP_0_credit_rdy(nps4_2_1_mdmc_npp_0_credit_rdy_net),
        .nps4_2_1_MDMC_NPP_0_credit_return(nps4_2_1_mdmc_npp_0_credit_return_net),
        .nps4_2_1_MDMC_NPP_0_flit(nps4_2_1_mdmc_npp_0_flit_net),
        .nps4_2_1_MDMC_NPP_0_pdest_id(nps4_2_1_mdmc_npp_0_pdest_id_net),
        .nps4_2_1_MDMC_NPP_0_valid(nps4_2_1_mdmc_npp_0_valid_net),
        .nps4_2_1_SDMC_NPP_0_credit_rdy(nps4_2_1_sdmc_npp_0_credit_rdy_net),
        .nps4_2_1_SDMC_NPP_0_credit_return(nps4_2_1_sdmc_npp_0_credit_return_net),
        .nps4_2_1_SDMC_NPP_0_flit(nps4_2_1_sdmc_npp_0_flit_net),
        .nps4_2_1_SDMC_NPP_0_pdest_id(nps4_2_1_sdmc_npp_0_pdest_id_net),
        .nps4_2_1_SDMC_NPP_0_valid(nps4_2_1_sdmc_npp_0_valid_net),
        .nps4_2_2_MDMC_NPP_0_credit_rdy(nps4_2_2_mdmc_npp_0_credit_rdy_net),
        .nps4_2_2_MDMC_NPP_0_credit_return(nps4_2_2_mdmc_npp_0_credit_return_net),
        .nps4_2_2_MDMC_NPP_0_flit(nps4_2_2_mdmc_npp_0_flit_net),
        .nps4_2_2_MDMC_NPP_0_pdest_id(nps4_2_2_mdmc_npp_0_pdest_id_net),
        .nps4_2_2_MDMC_NPP_0_valid(nps4_2_2_mdmc_npp_0_valid_net),
        .nps4_2_2_SDMC_NPP_0_credit_rdy(nps4_2_2_sdmc_npp_0_credit_rdy_net),
        .nps4_2_2_SDMC_NPP_0_credit_return(nps4_2_2_sdmc_npp_0_credit_return_net),
        .nps4_2_2_SDMC_NPP_0_flit(nps4_2_2_sdmc_npp_0_flit_net),
        .nps4_2_2_SDMC_NPP_0_pdest_id(nps4_2_2_sdmc_npp_0_pdest_id_net),
        .nps4_2_2_SDMC_NPP_0_valid(nps4_2_2_sdmc_npp_0_valid_net),
        .nps4_2_3_MDMC_NPP_0_credit_rdy(nps4_2_3_mdmc_npp_0_credit_rdy_net),
        .nps4_2_3_MDMC_NPP_0_credit_return(nps4_2_3_mdmc_npp_0_credit_return_net),
        .nps4_2_3_MDMC_NPP_0_flit(nps4_2_3_mdmc_npp_0_flit_net),
        .nps4_2_3_MDMC_NPP_0_pdest_id(nps4_2_3_mdmc_npp_0_pdest_id_net),
        .nps4_2_3_MDMC_NPP_0_valid(nps4_2_3_mdmc_npp_0_valid_net),
        .nps4_2_3_SDMC_NPP_0_credit_rdy(nps4_2_3_sdmc_npp_0_credit_rdy_net),
        .nps4_2_3_SDMC_NPP_0_credit_return(nps4_2_3_sdmc_npp_0_credit_return_net),
        .nps4_2_3_SDMC_NPP_0_flit(nps4_2_3_sdmc_npp_0_flit_net),
        .nps4_2_3_SDMC_NPP_0_pdest_id(nps4_2_3_sdmc_npp_0_pdest_id_net),
        .nps4_2_3_SDMC_NPP_0_valid(nps4_2_3_sdmc_npp_0_valid_net),
        .nps_0_MNPP_S_credit_rdy(nps_0_mnpp_s_credit_rdy_net),
        .nps_0_MNPP_S_credit_return(nps_0_mnpp_s_credit_return_net),
        .nps_0_MNPP_S_flit(nps_0_mnpp_s_flit_net),
        .nps_0_MNPP_S_valid(nps_0_mnpp_s_valid_net),
        .nps_0_SNPP_S_credit_rdy(nps_0_snpp_s_credit_rdy_net),
        .nps_0_SNPP_S_credit_return(nps_0_snpp_s_credit_return_net),
        .nps_0_SNPP_S_flit(nps_0_snpp_s_flit_net),
        .nps_0_SNPP_S_valid(nps_0_snpp_s_valid_net),
        .nps_1_MNPP_S_credit_rdy(nps_1_mnpp_s_credit_rdy_net),
        .nps_1_MNPP_S_credit_return(nps_1_mnpp_s_credit_return_net),
        .nps_1_MNPP_S_flit(nps_1_mnpp_s_flit_net),
        .nps_1_MNPP_S_valid(nps_1_mnpp_s_valid_net),
        .nps_1_SNPP_S_credit_rdy(nps_1_snpp_s_credit_rdy_net),
        .nps_1_SNPP_S_credit_return(nps_1_snpp_s_credit_return_net),
        .nps_1_SNPP_S_flit(nps_1_snpp_s_flit_net),
        .nps_1_SNPP_S_valid(nps_1_snpp_s_valid_net),
        .nps_2_MNPP_S_credit_rdy(nps_2_mnpp_s_credit_rdy_net),
        .nps_2_MNPP_S_credit_return(nps_2_mnpp_s_credit_return_net),
        .nps_2_MNPP_S_flit(nps_2_mnpp_s_flit_net),
        .nps_2_MNPP_S_valid(nps_2_mnpp_s_valid_net),
        .nps_2_SNPP_S_credit_rdy(nps_2_snpp_s_credit_rdy_net),
        .nps_2_SNPP_S_credit_return(nps_2_snpp_s_credit_return_net),
        .nps_2_SNPP_S_flit(nps_2_snpp_s_flit_net),
        .nps_2_SNPP_S_valid(nps_2_snpp_s_valid_net),
        .nps_3_MNPP_S_credit_rdy(nps_3_mnpp_s_credit_rdy_net),
        .nps_3_MNPP_S_credit_return(nps_3_mnpp_s_credit_return_net),
        .nps_3_MNPP_S_flit(nps_3_mnpp_s_flit_net),
        .nps_3_MNPP_S_valid(nps_3_mnpp_s_valid_net),
        .nps_3_SNPP_S_credit_rdy(nps_3_snpp_s_credit_rdy_net),
        .nps_3_SNPP_S_credit_return(nps_3_snpp_s_credit_return_net),
        .nps_3_SNPP_S_flit(nps_3_snpp_s_flit_net),
        .nps_3_SNPP_S_valid(nps_3_snpp_s_valid_net),
        .nps_4_MNPP_S_credit_rdy(nps_4_mnpp_s_credit_rdy_net),
        .nps_4_MNPP_S_credit_return(nps_4_mnpp_s_credit_return_net),
        .nps_4_MNPP_S_flit(nps_4_mnpp_s_flit_net),
        .nps_4_MNPP_S_valid(nps_4_mnpp_s_valid_net),
        .nps_4_SNPP_S_credit_rdy(nps_4_snpp_s_credit_rdy_net),
        .nps_4_SNPP_S_credit_return(nps_4_snpp_s_credit_return_net),
        .nps_4_SNPP_S_flit(nps_4_snpp_s_flit_net),
        .nps_4_SNPP_S_valid(nps_4_snpp_s_valid_net),
        .nps_5_MNPP_S_credit_rdy(nps_5_mnpp_s_credit_rdy_net),
        .nps_5_MNPP_S_credit_return(nps_5_mnpp_s_credit_return_net),
        .nps_5_MNPP_S_flit(nps_5_mnpp_s_flit_net),
        .nps_5_MNPP_S_valid(nps_5_mnpp_s_valid_net),
        .nps_5_SNPP_S_credit_rdy(nps_5_snpp_s_credit_rdy_net),
        .nps_5_SNPP_S_credit_return(nps_5_snpp_s_credit_return_net),
        .nps_5_SNPP_S_flit(nps_5_snpp_s_flit_net),
        .nps_5_SNPP_S_valid(nps_5_snpp_s_valid_net));

assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.mc0_ddrc_noc2dmc_credit_rdy_0 = nps4_2_0_mdmc_npp_0_credit_rdy_net;
assign nps4_2_0_mdmc_npp_0_credit_return_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.mc0_ddrc_noc2dmc_credit_rtn_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.mc0_ddrc_noc2dmc_data_in_0 = nps4_2_0_mdmc_npp_0_flit_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.mc0_ddrc_noc2dmc_pdest_id_in_0 = nps4_2_0_mdmc_npp_0_pdest_id_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.mc0_ddrc_noc2dmc_valid_in_0 = nps4_2_0_mdmc_npp_0_valid_net;
assign nps4_2_0_sdmc_npp_0_credit_rdy_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.mc0_ddrc_dmc2noc_credit_rdy_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.mc0_ddrc_dmc2noc_credit_rtn_0 = nps4_2_0_sdmc_npp_0_credit_return_net;
assign nps4_2_0_sdmc_npp_0_flit_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.mc0_ddrc_dmc2noc_data_out_0;
assign nps4_2_0_sdmc_npp_0_pdest_id_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.mc0_ddrc_dmc2noc_pdest_id_out_0;
assign nps4_2_0_sdmc_npp_0_valid_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.mc0_ddrc_dmc2noc_valid_out_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.mc0_ddrc_noc2dmc_credit_rdy_0 = nps4_2_1_mdmc_npp_0_credit_rdy_net;
assign nps4_2_1_mdmc_npp_0_credit_return_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.mc0_ddrc_noc2dmc_credit_rtn_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.mc0_ddrc_noc2dmc_data_in_0 = nps4_2_1_mdmc_npp_0_flit_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.mc0_ddrc_noc2dmc_pdest_id_in_0 = nps4_2_1_mdmc_npp_0_pdest_id_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.mc0_ddrc_noc2dmc_valid_in_0 = nps4_2_1_mdmc_npp_0_valid_net;
assign nps4_2_1_sdmc_npp_0_credit_rdy_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.mc0_ddrc_dmc2noc_credit_rdy_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.mc0_ddrc_dmc2noc_credit_rtn_0 = nps4_2_1_sdmc_npp_0_credit_return_net;
assign nps4_2_1_sdmc_npp_0_flit_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.mc0_ddrc_dmc2noc_data_out_0;
assign nps4_2_1_sdmc_npp_0_pdest_id_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.mc0_ddrc_dmc2noc_pdest_id_out_0;
assign nps4_2_1_sdmc_npp_0_valid_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.mc0_ddrc_dmc2noc_valid_out_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.mc0_ddrc_noc2dmc_credit_rdy_0 = nps4_2_2_mdmc_npp_0_credit_rdy_net;
assign nps4_2_2_mdmc_npp_0_credit_return_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.mc0_ddrc_noc2dmc_credit_rtn_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.mc0_ddrc_noc2dmc_data_in_0 = nps4_2_2_mdmc_npp_0_flit_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.mc0_ddrc_noc2dmc_pdest_id_in_0 = nps4_2_2_mdmc_npp_0_pdest_id_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.mc0_ddrc_noc2dmc_valid_in_0 = nps4_2_2_mdmc_npp_0_valid_net;
assign nps4_2_2_sdmc_npp_0_credit_rdy_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.mc0_ddrc_dmc2noc_credit_rdy_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.mc0_ddrc_dmc2noc_credit_rtn_0 = nps4_2_2_sdmc_npp_0_credit_return_net;
assign nps4_2_2_sdmc_npp_0_flit_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.mc0_ddrc_dmc2noc_data_out_0;
assign nps4_2_2_sdmc_npp_0_pdest_id_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.mc0_ddrc_dmc2noc_pdest_id_out_0;
assign nps4_2_2_sdmc_npp_0_valid_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.mc0_ddrc_dmc2noc_valid_out_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.mc0_ddrc_noc2dmc_credit_rdy_0 = nps4_2_3_mdmc_npp_0_credit_rdy_net;
assign nps4_2_3_mdmc_npp_0_credit_return_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.mc0_ddrc_noc2dmc_credit_rtn_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.mc0_ddrc_noc2dmc_data_in_0 = nps4_2_3_mdmc_npp_0_flit_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.mc0_ddrc_noc2dmc_pdest_id_in_0 = nps4_2_3_mdmc_npp_0_pdest_id_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.mc0_ddrc_noc2dmc_valid_in_0 = nps4_2_3_mdmc_npp_0_valid_net;
assign nps4_2_3_sdmc_npp_0_credit_rdy_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.mc0_ddrc_dmc2noc_credit_rdy_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.mc0_ddrc_dmc2noc_credit_rtn_0 = nps4_2_3_sdmc_npp_0_credit_return_net;
assign nps4_2_3_sdmc_npp_0_flit_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.mc0_ddrc_dmc2noc_data_out_0;
assign nps4_2_3_sdmc_npp_0_pdest_id_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.mc0_ddrc_dmc2noc_pdest_id_out_0;
assign nps4_2_3_sdmc_npp_0_valid_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.mc0_ddrc_dmc2noc_valid_out_0;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_0_mnpp_s_credit_rdy_net;
assign nps_0_mnpp_s_credit_return_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_return;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_flit = nps_0_mnpp_s_flit_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_in_noc_valid = nps_0_mnpp_s_valid_net;
assign nps_0_snpp_s_credit_rdy_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_return = nps_0_snpp_s_credit_return_net;
assign nps_0_snpp_s_flit_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_0_snpp_s_valid_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.s00_axi_nmu_if_noc_npp_out_noc_valid;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_credit_rdy = nps_1_mnpp_s_credit_rdy_net;
assign nps_1_mnpp_s_credit_return_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_credit_return;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_flit = nps_1_mnpp_s_flit_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_in_noc_valid = nps_1_mnpp_s_valid_net;
assign nps_1_snpp_s_credit_rdy_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_credit_rdy;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_credit_return = nps_1_snpp_s_credit_return_net;
assign nps_1_snpp_s_flit_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_flit;
assign nps_1_snpp_s_valid_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_0.inst.m00_axi_nsu_if_noc_npp_out_noc_valid;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_2_mnpp_s_credit_rdy_net;
assign nps_2_mnpp_s_credit_return_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_return;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.s00_axi_nmu_if_noc_npp_in_noc_flit = nps_2_mnpp_s_flit_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.s00_axi_nmu_if_noc_npp_in_noc_valid = nps_2_mnpp_s_valid_net;
assign nps_2_snpp_s_credit_rdy_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_return = nps_2_snpp_s_credit_return_net;
assign nps_2_snpp_s_flit_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.s00_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_2_snpp_s_valid_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c1.inst.s00_axi_nmu_if_noc_npp_out_noc_valid;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_3_mnpp_s_credit_rdy_net;
assign nps_3_mnpp_s_credit_return_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_return;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.s00_axi_nmu_if_noc_npp_in_noc_flit = nps_3_mnpp_s_flit_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.s00_axi_nmu_if_noc_npp_in_noc_valid = nps_3_mnpp_s_valid_net;
assign nps_3_snpp_s_credit_rdy_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_return = nps_3_snpp_s_credit_return_net;
assign nps_3_snpp_s_flit_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.s00_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_3_snpp_s_valid_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c5.inst.s00_axi_nmu_if_noc_npp_out_noc_valid;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_4_mnpp_s_credit_rdy_net;
assign nps_4_mnpp_s_credit_return_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_return;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.s00_axi_nmu_if_noc_npp_in_noc_flit = nps_4_mnpp_s_flit_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.s00_axi_nmu_if_noc_npp_in_noc_valid = nps_4_mnpp_s_valid_net;
assign nps_4_snpp_s_credit_rdy_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_return = nps_4_snpp_s_credit_return_net;
assign nps_4_snpp_s_flit_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.s00_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_4_snpp_s_valid_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c0.inst.s00_axi_nmu_if_noc_npp_out_noc_valid;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_rdy = nps_5_mnpp_s_credit_rdy_net;
assign nps_5_mnpp_s_credit_return_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.s00_axi_nmu_if_noc_npp_in_noc_credit_return;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.s00_axi_nmu_if_noc_npp_in_noc_flit = nps_5_mnpp_s_flit_net;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.s00_axi_nmu_if_noc_npp_in_noc_valid = nps_5_mnpp_s_valid_net;
assign nps_5_snpp_s_credit_rdy_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_rdy;
assign `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.s00_axi_nmu_if_noc_npp_out_noc_credit_return = nps_5_snpp_s_credit_return_net;
assign nps_5_snpp_s_flit_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.s00_axi_nmu_if_noc_npp_out_noc_flit;
assign nps_5_snpp_s_valid_net = `DUT_HIER_ROOT.design_1_i.axi_noc2_c4.inst.s00_axi_nmu_if_noc_npp_out_noc_valid;

endmodule
