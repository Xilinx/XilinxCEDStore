================================================================================
  Versal CPM6 QDMA Gen6 PIPE Simulation -- CTRL1 EP
  Controller: CTRL1 only (Endpoint)
  Mode      : PIPE Simulation
================================================================================

Steps to run CPM6 QDMA (CTRL1) simulation

1.  The following tool versions are needed for running the CPM6 QDMA simulation. Add these tools to
    your PATH environment variable so that they can be accessed from CED Simulation scripts and add
    the necessary licenses or point to the license servers needed to access them as explained in
    their respective manuals.
    a. Vivado            - 2026.1.1
    b. VCS / Verdi       - X-2025.06-SP2 (Verdi 2025.06-SP2-2 optional, waveforms)
    c. UVM Library       - 1.1
    d. Avery PLI         - 2025.3_1 (see NOTE under step 3a -- version need not match Avery PCIe)
    e. Avery apci-xactor - 2025.3_1

2.  Download and unzip the CPM6 Secure IP package (provided separately) from
    https://account.amd.com/en/member/cpm6-simulation.html

3.  Set the environment variables listed below (tcsh or bash shell):

    a. Set "AVERY_PLI" to the Avery PLI binary location, e.g.
         tcsh: setenv AVERY_PLI <path to avery pli install>
         bash: export AVERY_PLI=<path to avery pli install>

       NOTE: AVERY_PLI version is independent of AVERY_PCIE. avery_pli-2025.3_1's
       tb_vcs64.tab symlink is broken -- use avery_pli-2025.1 instead.

    b. Set "AVERY_PCIE" to the Avery PCIe source libraries, e.g.
         tcsh: setenv AVERY_PCIE <path to avery apci xactor install>
         bash: export AVERY_PCIE=<path to avery apci xactor install>

    c. Set "CPM6_SECUREIP" to the directory where the CPM6 Secure IP
       package was extracted, e.g.
         tcsh: setenv CPM6_SECUREIP <path to extracted cpm6 secureip>
         bash: export CPM6_SECUREIP=<path to extracted cpm6 secureip>

    d. Set "VIVADO_CLIBS" to the directory containing your precompiled VCS
       simulation libraries for the selected Vivado/VCS version, e.g.
         tcsh: setenv VIVADO_CLIBS <path to compiled simlibs>
         bash: export VIVADO_CLIBS=<path to compiled simlibs>

       IMPORTANT: this sets synopsys_sim.setup's OTHERS= line. If unset/wrong,
       OTHERS=?/synopsys_sim.setup and compile.sh fails with Error-[SETUP_INCLUDE_ERR].

    Verify:
         echo $VCS_HOME       # should show X-2025.06-SP2 path
         echo $AVERY_PLI      # see NOTE above -- version need not match AVERY_PCIE
         echo $AVERY_PCIE     # should show apcievip-2025.3_1 path
         echo $CPM6_SECUREIP  # should show your extracted path
         echo $VIVADO_CLIBS   # should show your compiled simlib path

4.  Create the Vivado project from this CED.

    This single step builds the block design, imports the RTL, AND generates
    the VCS simulation scripts (compile.sh/elaborate.sh/simulate.sh) under
    <project_name>.sim/sim_1/behav/vcs/, and copies the sim/ directory
    (this directory) alongside the Vivado project -- no separate
    "launch_simulation" step is needed.

    NOTE: use part xc2vp3602-vsvc3340-2MHP-e-S (not 2MP-e-L or 2LHP-e-S).

    NOTE: Controller_0 and Dual_Controller are not yet supported for QDMA --
    only Controller_1 is offered (see ../../init.tcl).

    The sim/ directory contains:
      Makefile
      tb/             -- Framework testbench files
      test/           -- QDMA UVM test package
      verif/          -- DUT instantiation + test_qdma_h2c_c2h_mm_Mfnc_MQ.sv
      uvma_agents/    -- UVM agent sources (compiled by make c)
      lib/            -- C shared libraries (date.so, socket_dpi.so)
      avery_vcs.f     -- Avery VIP file list
      cpm6_sip.f      -- CPM6 Secure IP file list
      uvma_agents.f   -- uvma_agents file list

5.  Run simulation:

         cd <project_name>/sim

         make cos                                         -- compile + optimize + simulate
         make cos DUMP=1                                  -- with waveform dump
         make s TEST=<test_name>                          -- re-simulate only
         make smoke                                       -- run the smoke test (test_qdma_h2c_c2h_mm_Mfnc_MQ) only
         make distclean                                   -- wipe all compiled libs and start
                                                               completely fresh (use if a build
                                                               gets stuck/inconsistent)
         make h                                           -- show help with all options

    To force-recompile only the Vivado DUT lib (e.g. after a hand-patched
    generated source), clear contents only -- never remove vcs_lib itself:
      rm -rf <project>.sim/sim_1/behav/vcs/vcs_lib/*
    (vhdlan, used for VHDL libs like proc_sys_reset_v5_0_17, can't recreate
    a missing vcs_lib parent and fails with Error-[DLIB_CANT_CREATE_DIR].)

    Debug hint: if the opt/elaboration step fails with "Error-[SFCOR] Source
    file cannot be opened" on cpm6_001.svp/cpm6_002.svp/CPM6.v even with
    CPM6_SECUREIP set and sim/cpm6_sip.f edited per step 3c above, the
    Vivado build in use expects the nested layout mentioned in step 2's
    NOTE ($CPM6_SECUREIP/data/secureip/cpm6/... and
    $CPM6_SECUREIP/data/verilog/src/unisims/CPM6.v) rather than the flat
    layout your extracted secure-IP package actually has. The real fix is to
    use the pinned Vivado build (step 1a) so cpm6_sip.f is generated
    expecting the flat layout. If switching Vivado builds isn't practical,
    a symlink shim works around it without editing cpm6_sip.f back to the
    flat form:
      mkdir -p sim/.cpm6_secureip_shim/data/secureip/cpm6 \
               sim/.cpm6_secureip_shim/data/verilog/src/unisims
      ln -s $CPM6_SECUREIP/cpm6_001.svp sim/.cpm6_secureip_shim/data/secureip/cpm6/
      ln -s $CPM6_SECUREIP/cpm6_002.svp sim/.cpm6_secureip_shim/data/secureip/cpm6/
      ln -s $CPM6_SECUREIP/CPM6.v sim/.cpm6_secureip_shim/data/verilog/src/unisims/
      setenv CPM6_SECUREIP <this_project>/sim/.cpm6_secureip_shim
    then `make distclean` (a prior compile attempt against the wrong layout
    leaves a broken stub in clibs/cpm6_secip that must be wiped) before
    `make cos`.

    Debug hint: if _check_vivado reports "compile.sh not found" even though it
    exists, a stale sim/simv.daidir from a prior run can make the VIVADO_SIM
    auto-detect match its own embedded path mirror instead of the real Vivado
    sim dir. The find pattern now prunes simv.daidir explicitly.

    Debug hint: if CDO load or PCIe enumeration appear extremely slow or
    stalled, check the +PL0_CLK value printed by bind.ps_vip.sv at sim start
    -- it should read a few hundred MHz. A malformed Hz->MHz conversion in
    PL0_CLK auto-detect previously produced a value ~1000x too high, which
    under a 1fs sim timescale generates an extreme number of clock-edge
    events and can look like a hang rather than a slow run.

    Debug hint (environment, not code): if PCIe enumeration never produces any protocol-layer
    activity (tracker_*.log files in the run directory stay at 0 bytes,
    no avypcie version banner, no LTSSM/BFM progress after "Entering
    configure_phase" -- looks exactly like a hang, with no error printed),
    the Avery license client may never have completed feature checkout, so
    the VIP's protocol engine never initialized. Two environment factors
    were both required to reproduce and resolve this in that instance:
      1. AVERY_PLI must be a version-matched PLI+VIP bundle, e.g.
         .../avery/auciexactor/<ver>/avery_pli-<ver> (installed alongside
         the same-version apcievip), not a standalone
         avery/pli/avery_pli-<ver> install of a different version than
         AVERY_PCIE/AVERY_SIM.
      2. SALT_LICENSE_SERVER must not carry a dead/unreachable entry (e.g.
         a TCP-closed license server address inherited from an interactive
         shell) -- the salt_mgls client busy-loops trying to connect to a
         dead entry and never reaches feature checkout.
    Both must be overridden together when launching (do not rely on the
    inherited interactive shell environment for either):
      setenv AVERY_PLI <path to your version-matched avery_pli-2025.3_1 install>
      setenv SALT_LICENSE_SERVER <port>@<your-license-server-1>,<port>@<your-license-server-2>[,...]

    Debug hint: if configure_phase reaches PCIe enumeration successfully but then hits
    UVM_FATAL in shim_api.sv on a completion status other than Successful
    Completion, the framework may be walking VF Extended Capability space
    while SR-IOV VF Enable is still 0 -- the DUT correctly returns UR for
    those accesses. Guarding the VF capability traverse on the SR-IOV VF
    Enable bit resolves this.

    Debug hint: if H2C/C2H DMA transfers stall partway with no further host-side byte-count progress,
    check that H2C_DAT_DST_ADDR0/1 in pkg.cpm6_qdma_params.sv still match the
    DMA aperture BASEADDR the BD's Address Editor assigns to each CPM_AXI_PLn
    port (ps_wizard_0 -> CPM6_CONFIG -> CPM6_CTRL1_DMA_APERTUREn_BASEADDR/
    LIMITADDR). If you change a DMA aperture's base address in the Address
    Editor, update the matching H2C_DAT_DST_ADDRn constant in the testbench to
    the new offset (bit [48] selects the PL0/PL2 vs PL1/PL3 port group; the
    remaining bits must fall within that port's aperture BASEADDR/LIMITADDR
    range) -- a stale constant here can numerically alias to an unrelated
    address region and silently target the wrong destination.

    Debug hint: on SEED -- VCS's automatic seed (+ntb_random_seed_automatic,
    the default) picks a different pseudo-random stimulus profile every
    launch, which for this testbench can matter well beyond just descriptor
    content: at higher VF counts it affects whether Avery's PCIe VIP clears
    bus enumeration within its fixed wait_event(bus_enum_done, 500000 ns)
    window. Confirmed both ways in back-to-back launches of the identical
    +NUM_PF_TEST=1 +NUM_VF_TEST=8 config: automatic seed 1571030569 hit the
    500us enumeration timeout and UVM_FATAL'd before main_phase; seed
    439119098 passed enumeration cleanly and ran the full test to
    completion. If a launch fails during PCIe/SR-IOV enumeration with no
    other change, try a different explicit SEED before assuming a real
    regression -- the Makefile's SEED default is set to a value already
    confirmed clean at NUM_VF_TEST=8; override with SEED=<n> to reproduce a
    specific prior run (the seed used is always printed in vcs.sim.log,
    either from the automatic-seed NOTE line or the +ntb_random_seed=<n>
    plusarg echoed at the top of the Command: line), or SEED=automatic to
    go back to VCS's own randomization.

    Debug hint: on the svt_axi_system_configuration "set_addr_range ... overlaps"
    UVM_WARNING -- this is expected and benign, not a testbench bug. tb_env.sv
    configures 6 physically distinct AXI slave ports (S_AXIMM_PS0_128,
    S_AXIMM_PS1_128, S_AXIMM_PL0_512 .. S_AXIMM_PL3_512) and deliberately gives
    EACH of them the full 64-bit address range ('0 to '1) via
    axi_cfg.set_addr_range(), because each is a separate physical AXI interface
    (PS-side vs. four independent PL-side buses) rather than a decoded sub-region
    of one shared address map -- there is no duplicate set_addr_range call on the
    same port. The VIP's own overlap checker compares ranges across ALL
    configured slave ports regardless of which physical bus they sit on, so it
    flags these 6 full-range ports as mutually overlapping even though they never
    contend for the same address on the same interface. Narrowing any of these
    ranges to "fix" the warning would be wrong -- it would silently drop valid
    accesses on that port, since each slave is meant to see and decode the
    complete address space presented on its own bus. Leave the ranges as-is.

--------------------------------------------------------------------------------
AVAILABLE TESTS
--------------------------------------------------------------------------------
test_qdma_h2c_c2h_mm_Mfnc_MQ -- multi-queue, H2C+C2H MM DMA test across PF
and/or VF functions. Default and preferred mode is POLL (+IRQ_EN=0); interrupt
mode (+IRQ_EN=1) is not supported when VFs are in use. See the test file header
for the full plusarg list(NUM_PF_TEST/NUM_VF_TEST/NUM_Q_TEST/PIDX/DMA_BYTE_CNT/DIRECTION/
NUM_DMA_PORTS).
================================================================================
