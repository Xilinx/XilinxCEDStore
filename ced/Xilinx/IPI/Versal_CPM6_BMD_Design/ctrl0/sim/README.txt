================================================================================
  Versal CPM6 BMD Gen6 PIPE Simulation -- CTRL0 EP
  Controller: CTRL0 only (Endpoint)
  Mode      : PIPE Simulation
================================================================================

Steps to run CPM6 BMD (CTRL0) simulation

1.  The following tool versions are needed for running the CPM6 BMD simulation. Add these tools to
    your PATH environment variable so that they can be accessed from CED Simulation scripts and add
    the necessary licenses or point to the license servers needed to access them as explained in
    their respective manuals.
    a. Vivado            - 2026.1
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

    Verify:
         echo $VCS_HOME       # should show X-2025.06 path
         echo $AVERY_PLI      # should show avery_pli-2025.3_1 path
         echo $AVERY_PCIE     # should show apcievip-2025.3_1 path
         echo $CPM6_SECUREIP  # should show your extracted path
         echo $VIVADO_CLIBS   # should show your compiled simlib path

4.  Create the Vivado project from this CED.

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

5.  Run simulation:

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
