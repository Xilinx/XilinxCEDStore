================================================================================
  Versal CPM6 DMA+DDR Gen6 PIPE Simulation -- CTRL1 EP
  Controller: CTRL1 only (Endpoint)
  Mode      : PIPE Simulation
================================================================================

Steps to run CPM6 DMA+DDR (CTRL1) simulation

1.  The following tool versions are needed for running the CPM6 DMA simulation. Add these tools to
    your PATH environment variable so that they can be accessed from CED Simulation scripts and add
    the necessary licenses or point to the license servers needed to access them as explained in
    their respective manuals.
    a. Vivado            - see your CPM6 IP release notes for the
                            recommended/qualified build
    b. VCS / Verdi       - X-2025.06
    c. UVM Library       - 1.1
    d. Avery PLI         - 2025.3_1
    e. Avery apci-xactor - 2025.3_1

2.  Download and unzip the CPM6 Secure IP package (provided separately) from
    https://account.amd.com/en/member/cpm6-simulation.html

3.  Set the environment variables listed below (tcsh or bash shell):

    a. Set "AVERY_PLI" to the Avery PLI binary location, e.g.
         tcsh: setenv AVERY_PLI <path to avery pli install>
         bash: export AVERY_PLI=<path to avery pli install>

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

    Equivalently, load the module files that set these automatically:
         setenv MODULEPATH <path to avery modulefiles>:${MODULEPATH}
         setenv MODULEPATH <path to synopsys modulefiles>:${MODULEPATH}
         module switch vcs/X-2025.06
         module load averyvip/2025.3_1
         (this sets AVERY_PLI, AVERY_PCIE, AVERY_SIM, VCS_HOME)

    Verify:
         echo $VCS_HOME       # should show X-2025.06 path
         echo $AVERY_PLI      # should show avery_pli-2025.3_1 path
         echo $AVERY_PCIE     # should show apcievip-2025.3_1 path
         echo $CPM6_SECUREIP  # should show your extracted path
         echo $VIVADO_CLIBS   # should show your compiled simlib path

4.  Create the Vivado project from this CED.

    This single step builds the block design, imports the RTL, and sets
    the clibs path in the sim settings -- no separate "launch_simulation"
    step is needed.

    The sim/ directory contains:
      Makefile
      tb/             -- Framework testbench files
      test/           -- DMA UVM test package
      verif/          -- DUT instantiation
      uvma_agents/    -- UVM agent sources (compiled by make c)
      lib/            -- C shared libraries (date.so, socket_dpi.so)
      avery_vcs.f     -- Avery VIP file list
      cpm6_sip.f      -- CPM6 Secure IP file list
      uvma_agents.f   -- uvma_agents file list

5.  Run simulation:

         cd <project_name>/sim

         make cos                         -- compile + optimize + simulate
         make cos DUMP=1                  -- with waveform dump
         make s TEST=hello_world SEED=123 -- re-simulate with a specific seed
         make smoke                       -- run the smoke test (hello_world) only
         make regr TESTLIST=<file>        -- run every test listed in <file>
         make distclean                   -- wipe all compiled libs and start
                                              completely fresh (use if a build
                                              gets stuck/inconsistent)
         make h                           -- show help with all options


--------------------------------------------------------------------------------
AVAILABLE TESTS
--------------------------------------------------------------------------------
Real DMA-specific UVM tests are compiled in via sim/tb/test/hdma/ (ported
verbatim from uvma-pcie-sim-framework/cpm6/common/test/hdma/, the same
source used by the verified-passing regression at
cpm6/ctrl1ep_g6x8_hdma_1pf). This variant (dma_ddr, LPDDR5-backed) should
use the "ddr" flavored tests:

  hello_world                       (generic framework smoke test, default)
  test_s_hdma_ddr_ctrlr1
  test_s_hdma_ddr_ctrlr1_msix
  test_s_hdma_ddr_ctrlr1_multipf
  test_M_bridge_ddr_ctrlr1
  test_M_bridge_ddr_ctrlr1_4pf
  test_M_bridge_ddr_ctrlr1_bar24_1pf

See sim/testlist_full.txt. NOTE: the ddr/plaxi variant split above is based
on test naming convention, not independently re-verified against this
CED-generated project -- treat as a strong starting point, not confirmed
sign-off. The "plaxi" flavored tests (for the non-DDR dma/ variant) are
also compiled in (all DMA tests share one test_pkg.svh) but are expected
to target dma/'s BRAM-backed hardware, not this DDR variant.

A handful of other generic framework tests (test_init, test_enum, test_base,
base_ep_test, ...) are also compiled in via sim/tb/test/test_pkg.svh.
