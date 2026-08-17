================================================================================
  Versal CPM6 DMA+DDR Gen6 PIPE Simulation -- CTRL1 EP
  Controller: CTRL1 only (Endpoint)
  Mode      : PIPE Simulation
================================================================================

Steps to run CPM6 DMA+DDR (CTRL1) simulation

1.  The following tool versions are needed for running the CPM6 DMA simulation:
    a. Vivado             - see your CPM6 IP release notes for the
                             recommended/qualified build
    b. VCS / Verdi         - X-2025.06
    c. UVM Library         - 1.1
    d. Avery PLI           - 2025.3_1
    e. Avery apci-xactor   - 2025.3_1

2.  Obtain this CED (Versal_CPM6_BMD_Design). It is registered with Vivado's
    IP Example Design catalog -- no separate download/unzip is required once
    your Vivado installation includes the CPM6 IP and this CED's path has
    been registered (see step 5).

3.  Download and unzip the CPM6 Secure IP package (provided separately).

4.  Set the environment variables listed below (tcsh shell):

    a. Set "AVERY_PLI" to the Avery PLI binary location, e.g.
         setenv AVERY_PLI /tools/installs/avery/pli/avery_pli-2025.3_1

    b. Set "AVERY_PCIE" to the Avery PCIe source libraries, e.g.
         setenv AVERY_PCIE /tools/installs/avery/apciexactor/2025.3_1

    c. Set "CPM6_SECUREIP" to the directory where the CPM6 Secure IP
       package was extracted, e.g.
         setenv CPM6_SECUREIP <path_to_extracted_cpm6_secureip>

       Then open sim/cpm6_sip.f and update the file paths to match your
       package structure, e.g.
         $CPM6_SECUREIP/data/secureip/cpm6/cpm6_001.svp
         $CPM6_SECUREIP/data/secureip/cpm6/cpm6_002.svp
         $CPM6_SECUREIP/data/verilog/src/unisims/CPM6.v

       NOTE: The exact sub-directory structure depends on your package --
       check your extracted package and adjust paths accordingly.

         equivalently, load the module files that set these automatically:
         setenv MODULEPATH /tools/packages/infra/release/modulefiles/xsj/tools/avery:${MODULEPATH}
         setenv MODULEPATH /tools/packages/infra/release/modulefiles/xsj/tools/synopsys:${MODULEPATH}
         module switch vcs/X-2025.06
         module load averyvip/2025.3_1
         (this sets AVERY_PLI, AVERY_PCIE, AVERY_SIM, VCS_HOME)

    Verify:
         echo $VCS_HOME       # should show X-2025.06 path
         echo $AVERY_PLI      # should show avery_pli-2025.3_1 path
         echo $AVERY_PCIE     # should show apcievip-2025.3_1 path
         echo $CPM6_SECUREIP  # should show your extracted path
         echo $VIVADO_CLIBS   # should show your compiled simlib path

5.  Create the Vivado project from this CED.

    This single step builds the block design, imports the RTL, 
    and then set the sim settings in vivado project, and then generate scripts enabled
    "launch_simulation" step is needed.

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

6.  Run simulation:

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
Real HDMA-specific UVM tests are compiled in via sim/tb/test/hdma/ (ported
verbatim from uvma-pcie-sim-framework/cpm6/common/test/hdma/, the same
source used by the verified-passing regression at
cpm6/ctrl1ep_g6x8_hdma_1pf). This variant (hdma_ddr, LPDDR5-backed) should
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
sign-off. The "plaxi" flavored tests (for the non-DDR hdma/ variant) are
also compiled in (all HDMA tests share one test_pkg.svh) but are expected
to target hdma/'s BRAM-backed hardware, not this DDR variant.

A handful of other generic framework tests (test_init, test_enum, test_base,
base_ep_test, ...) are also compiled in via sim/tb/test/test_pkg.svh.
