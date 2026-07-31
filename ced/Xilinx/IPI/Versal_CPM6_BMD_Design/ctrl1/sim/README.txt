================================================================================
  Versal CPM6 BMD Gen6 PIPE Simulation -- CTRL1 EP
  Controller: CTRL1 only (Endpoint)
  Mode      : PIPE Simulation
================================================================================

Steps to run CPM6 BMD (CTRL1) simulation

1.  The following tool versions are needed for running the CPM6 BMD simulation:
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

    d. Set "VIVADO_CLIBS" to the directory containing your precompiled VCS
       simulation libraries for the selected Vivado/VCS version, e.g.
         setenv VIVADO_CLIBS <path_to_compiled_simlibs>

    Or, equivalently, load the module files that set these automatically:
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

    This single step builds the block design, imports the RTL, AND generates
    the VCS simulation scripts (compile.sh/elaborate.sh/simulate.sh) under
    <project_name>.sim/sim_1/behav/vcs/, and copies the sim/ directory
    (this directory) alongside the Vivado project -- no separate
    "launch_simulation" step is needed.

    The sim/ directory contains:
      Makefile
      tb/             -- Framework testbench files
      test/           -- BMD UVM test package
      verif/          -- DUT instantiation
      uvma_agents/    -- UVM agent sources (compiled by make c)
      lib/            -- C shared libraries (date.so, socket_dpi.so)
      avery_vcs.f     -- Avery VIP file list
      cpm6_sip.f      -- CPM6 Secure IP file list
      uvma_agents.f   -- uvma_agents file list

6.  Run simulation:

         cd <project_name>/sim

         make cos                                         -- compile + optimize + simulate
         make cos DUMP=1                                  -- with waveform dump
         make s TEST=test_bmd_read_min_size_min_count     -- re-simulate only
         make distclean                                   -- wipe all compiled libs and start
                                                               completely fresh (use if a build
                                                               gets stuck/inconsistent)
         make h                                           -- show help with all options


--------------------------------------------------------------------------------
AVAILABLE TESTS
--------------------------------------------------------------------------------
Write (DMA):
  test_bmd_write_min_size_min_count   (default)
  test_bmd_write_min_size_max_count
  test_bmd_write_max_size_min_count
  test_bmd_write_max_size_max_count

Read (DMA):
  test_bmd_read_min_size_min_count
  test_bmd_read_min_size_max_count
  test_bmd_read_max_size_min_count
  test_bmd_read_max_size_max_count

Interrupts : test_bmd_intx, test_bmd_msi, test_bmd_msix
Capabilities: test_bmd_tph, test_bmd_pasid, test_bmd_vsec, test_bmd_10b_tag ...
Error tests: test_bmd_inject_bad_data, test_bmd_send_ur ...

See Makefile header for complete test list.
