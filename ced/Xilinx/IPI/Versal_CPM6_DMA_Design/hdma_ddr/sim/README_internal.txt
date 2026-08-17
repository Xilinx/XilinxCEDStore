================================================================================
  Versal CPM6 HDMA+DDR Gen6 PIPE Simulation -- INTERNAL README (AMD/XSJ Servers)
  Controller: CTRL1 only (Endpoint), LPDDR5-backed
  Mode      : PIPE Simulation
================================================================================

This README is for AMD engineers running on XSJ servers (xsjrarajeshXX etc.)
who have access to shared tool installations and internal secure IP paths.

For customer-facing instructions, see README.txt.


--------------------------------------------------------------------------------
ENVIRONMENT SETUP  (tcsh shell)
--------------------------------------------------------------------------------

  setenv MODULEPATH /tools/packages/infra/release/modulefiles/xsj/tools/avery:${MODULEPATH}
  setenv MODULEPATH /tools/packages/infra/release/modulefiles/xsj/tools/synopsys:${MODULEPATH}
  setenv MODULEPATH /tools/packages/infra/release/modulefiles/xsj/tools/novas:${MODULEPATH}

  module switch vcs/X-2025.06
  module load averyvip/2025.3_1
  module load verdi/2025.06-SP2-2   # optional, for waveform viewing

  # Verify
  echo $VCS_HOME      # should contain X-2025.06
  echo $AVERY_PLI     # should contain avery_pli-2025.3_1
  echo $AVERY_PCIE    # should contain apcievip-2025.3_1


--------------------------------------------------------------------------------
CPM6 SECURE IP SETUP (internal)
--------------------------------------------------------------------------------

  The CPM6 Secure IP is available internally at:
    /everest/pvs_xsj/SECUREIP_cpm6/

  Available releases (unverified -- documented by an earlier design template,
  not confirmed by real usage on this testcase):
    /everest/pvs_xsj/SECUREIP_cpm6/082625/
    /everest/pvs_xsj/SECUREIP_cpm6/041626.CR-1266624.fix/
    /everest/pvs_xsj/SECUREIP_cpm6/052526/

  Releases actually exercised against cpm6/ctrl1ep_g6x8_hdma_1pf (per real
  vlogan invocations recorded for that testcase):
    /everest/pvs_xsj/SECUREIP_cpm6/internal.latest/                    (flat layout, see Step 2a)
    /everest/pvs_xsj/SECUREIP_cpm6/lounge.latest/cpm6-secureip/2026.1/ (versioned layout, see Step 2b)

  Step 1 -- Set env variable to whichever release you're using, e.g.:
    setenv CPM6_SECUREIP /everest/pvs_xsj/SECUREIP_cpm6/internal.latest

  Step 2a -- If using a FLAT-layout release (e.g. internal.latest/, files
  directly under $CPM6_SECUREIP with no subdirectories):

    Edit sim/cpm6_sip.f to list CPM6.v FIRST, then the .svp files (this
    matches the compile order used in real vlogan invocations against this
    layout -- do not reorder):
      $CPM6_SECUREIP/CPM6.v
      $CPM6_SECUREIP/cpm6_001.svp
      $CPM6_SECUREIP/cpm6_002.svp

  Step 2b -- If using a VERSIONED-layout release (e.g.
  lounge.latest/cpm6-secureip/2026.1/, matching the customer package's
  2026.1/data/... directory structure): no edit needed -- point
  CPM6_SECUREIP at the release root (e.g.
  .../lounge.latest/cpm6-secureip) and the default, unmodified
  sim/cpm6_sip.f already resolves correctly:
      $CPM6_SECUREIP/2026.1/data/secureip/cpm6/cpm6_001.svp
      $CPM6_SECUREIP/2026.1/data/secureip/cpm6/cpm6_002.svp
      $CPM6_SECUREIP/2026.1/data/verilog/src/unisims/CPM6.v

  NOTE: Internal filelist.f (if your release ships one) references .sv
        files (unencrypted source). Customer package uses .svp files
        (encrypted). Both work with vlogan.


--------------------------------------------------------------------------------
VIVADO PROJECT SETUP (internal)
--------------------------------------------------------------------------------

  IMPORTANT: Use older Vivado build (SW Build 6500299, Jun 04 2026).
  Newer builds (>Jun 21 2026) generate different CPM6 CDO values causing
  Avery AVY_ERROR [APIPE_62r_7_1_16n1] during link equalization.

  Old Vivado binary:
    /proj/primebuilds/9999.0_PRIME_0601_1/installs/lin64/9999.0/Vivado/bin/vivado

  In Vivado TCL console:
    set_param ced.repoPaths {<path_to_Versal_CPM6_HDMA_DDR_Design>}
    open_example_project -force -part xc2vp3602-vsvc3340-2LHP-e-S \
      -dir <output_dir> \
      [get_example_designs -of [get_ipdefs xilinx.com:design:cpm6_hdma:1.0]]
    # In the CED options dialog choose CTRL_CONFIG=CONTROLLER1, DDR_EN=true
    set_property compxlib.vcs_compiled_library_dir \
      /proj/xbuilds/2026.1_daily_latest/clibs/vcs/X-2025.06/lin64/lib \
      [current_project]
    launch_simulation -scripts_only

  NOTE: Use part xc2vp3602-vsvc3340-2LHP-e-S (not 2MP-e-L).
  NOTE: Use 2026.1 clibs (not 2026.2 -- has empty cpm6_v1_0_8_pkg).
  NOTE: See README.txt "IMPORTANT NOTE" -- the NoC simulation wrapper for
        this DDR variant is not yet generated/committed. Generate it here
        before attempting `make c`.


--------------------------------------------------------------------------------
RUNNING SIMULATION
--------------------------------------------------------------------------------

  cd <output_dir>/sim
  make cos

  Re-simulate only (after first compile+optimize):
  make s TEST=hello_world


--------------------------------------------------------------------------------
KNOWN ISSUES (internal)
--------------------------------------------------------------------------------

  1. Vivado build >Jun 21 2026 (SW Build >6516846):
     CDO register 0xfc40080c gets value 0x100 instead of 0x400.
     Avery fires AVY_ERROR [APIPE_62r_7_1_16n1] getlocalPresetCoeff.
     Fix: use old Vivado build (9999.0_PRIME_0601_1).

  2. NoC simulation wrapper (design_1_wrapper_sim_wrapper.v equivalent for
     this DDR variant) has not been generated/committed yet -- sim/verif/
     dut_inst.sv currently instantiates a placeholder module name. This
     must be corrected from a real Vivado-generated wrapper before `make c`
     will succeed. See README.txt "IMPORTANT NOTE".

  3. Unclear whether CH0_LPDDR5_0_* top-level pins need a DDR5 simulation
     BFM connected, or whether the ddrmc5_responder IP absorbs DDR traffic
     internally in simulation (tie-off would then be safe). Confirm against
     the ddrmc5_responder IP documentation for the version configured in
     hdma_ddr/design_1_bd.tcl before relying on the current tie-off in
     dut_inst.sv.

  4. No HDMA-specific UVM tests exist yet -- only the generic framework
     hello_world test is verified against hdma_ddr_top (see
     cpm6/ctrl1ep_g6x8_hdma_1pf for a working reference regression run
     of the same sources). sim/test/ still contains the BMD example
     design's verification content and does not apply here.

  5. compile.sh VCS version:
     compile.sh (generated by newer Vivado) hardcodes SIM_VER_VCS=V-2023.12-SP1.
     This may cause KDB incompatibility with X-2025.06 TB compile.
     If issues arise, add the following patch to Makefile (line ~165):
       sed -i "s|export SIM_VER_VCS=V-[^ ]*|export SIM_VER_VCS=$(shell basename $(VCS_HOME))|" \
         $(VIVADO_SIM)/compile.sh

================================================================================
