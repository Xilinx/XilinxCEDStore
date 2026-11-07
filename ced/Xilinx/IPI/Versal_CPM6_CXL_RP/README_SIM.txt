================================================================================
 Versal CPM6 CXL Root Port (Versal_CPM6_CXL_RP) - Simulation Quick Guide
================================================================================

WHAT THIS IS
------------
The generated project contains a UVM testbench (uvma-pcie-sim-framework/,
verif/) and a Makefile that compiles, optimizes, and simulates the CPM6 CXL
Root Port against a third-party CXL Type 3 device model (Avery PCIe/CXL VIP)
with VCS or QuestaSim, per the "Simulator" option. No board or JTAG is needed.
See README.txt for the hardware flow.

WHAT A SIMULATION DOES
----------------------
  * Brings the link up (Gen5/Gen6 CXL), then enumerates the Root Port and the
    VIP endpoint and programs one CXL HDM range into it (4 GB).
  * Runs the selected test: a configurable set of AXI commands are pushed
    into each CPI datapath's AXI interface (axi4_sim_if), which replace the
    hardware's custom AXI traffic generators, through pl_axi_cpi_bridge_<N>
    and the CPM6 CXL TL IP, through the CPM6 hard IP, and across the link to
    the VIP's memory.
  * Link-up and enumeration take about 150 us of simulated time, so even the
    smallest test simulates ~155 us.

REQUIREMENTS
------------
  * Vivado simulation libraries compiled for your simulator. Set at
    CED generation time with SIM_LIBS_COMPILED and SIM_LIBS_PATH set
    through TCL or through the GUI.
  * Avery PCIe/CXL VIP (functioning as CXL Type 3 Device)
  * Synopsys VCS or Siemens QuestaSim
  * Contact IP marketing for the supported tool versions and additional
    details.
  * CPM6 SecureIP (QuestaSim only): download it through AMD Lounge access, then
    set SIP_PATH in the generated Makefile (marked ATTN), or on the make
    command line (make ... SIP_PATH=<path>). SIP_PATH is not required for VCS.

QUICK START (from the project directory that contains the Makefile)
-------------------------------------------------------------------
  % make help  ;# all targets and options
  % make lst   ;# list the available tests
  % make cos DUT_CLIBS=MANY DEBUG=0 TEST=cpi0_basic_test

  For QuestaSim, add SIP_PATH=<path> in the generated CED's Makefile; see the
  "ATTN" line in that file.

  cos   = compile (c), optimize (o), simulate (s); run it once per design.
  s     = simulate only; reuse the existing build, e.g. for new seeds.
  DEBUG=0 builds without waveform visibility; the default DEBUG=1 needs
  Verdi-compatible (-kdb) simulation libraries for VCS simulation.
  Typical wall time for a first build and run: 15-25 minutes.
  make cln_clibs / cln_dut / aclean clean compiled libraries, the Vivado DUT
  library, or everything (the next run starts from compile).

TESTS (verif/test/)
-------------------
  % make lst TEST=<testname> ;# this will print a specific test description

  cpi0_basic_test .......... 1 write then 1 read of one HDM line on CPI0;
                             checks BRESP/RRESP and read data.
  cpi{0,ALL}_{wr,rd,mix}_{mid,full}_test
                           Writes, reads, or both, on CPI0 or on every CPI in
                           parallel. "mid" = 128 commands per direction per
                           CPI, "full" = 4096 (the performance URAM depth).
                           Only responses are checked; these are bandwidth and
                           latency stress tests. They are spread across all
                           AXI IDs, and the VIP may return responses out of
                           order.

READING THE RESULTS
-------------------
Output goes to <project>.sim/sim_1/behav/<simulator>/<test>_<date>_<time>/
(the sim log is vcs.sim.log or questa.vsim.log, plus protocol trackers such
as tracker_cxl_tl_vip0.log). A test passes when the log shows its completion
message (e.g. "CPI0 write then read of 0x... matched") and no unexpected
UVM_ERROR/UVM_FATAL.
