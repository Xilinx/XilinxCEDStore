================================================================================
  Versal CPM6 BMD Gen6 PIPE Simulation -- INTERNAL README (AMD/XSJ Servers)
  Controller: CTRL0 + CTRL1 (Dual Endpoint)
  Mode      : PIPE Simulation
================================================================================

This README is for AMD engineers running on XSJ servers (xsjrarajeshXX etc.)
who have access to shared tool installations and internal secure IP paths.

For customer-facing instructions, see README.txt.

Steps to run CPM6 BMD (Dual Controller) simulation (internal)

1.  Tool versions:
    a. Vivado             - IMPORTANT: use the pinned build below, not
                             HEAD_PRIME_daily_latest
    b. VCS / Verdi         - X-2025.06 / 2025.06-SP2-2 (Verdi optional, waveforms)
    c. UVM Library         - 1.1
    d. Avery PLI           - 2025.3_1
    e. Avery apci-xactor   - 2025.3_1

2.  This CED lives at: <path_to_Versal_CPM6_BMD_Design> (this checkout).
    No separate download needed internally.

3.  CPM6 Secure IP is available internally at:
      /everest/pvs_xsj/SECUREIP_cpm6/

    Available releases:
      /everest/pvs_xsj/SECUREIP_cpm6/082625/                    (recommended -- used by reference)
      /everest/pvs_xsj/SECUREIP_cpm6/041626.CR-1266624.fix/
      /everest/pvs_xsj/SECUREIP_cpm6/052526/

4.  Set the environment variables listed below (tcsh shell):

    a. Set env variable for the secure IP release:
         setenv CPM6_SECUREIP /everest/pvs_xsj/SECUREIP_cpm6/082625

       Edit sim/cpm6_sip.f to match the internal structure (files sit
       directly under the release dir, not in subdirectories):
         $CPM6_SECUREIP/cpm6_001.svp
         $CPM6_SECUREIP/cpm6_002.svp
         $CPM6_SECUREIP/CPM6.v

       OR use the internal filelist.f directly in cpm6_sip.f:
         -F /everest/pvs_xsj/SECUREIP_cpm6/082625/filelist.f

       NOTE: internal filelist.f references .sv files (unencrypted source);
       the customer package uses .svp files (encrypted) -- both work with
       vlogan. NOTE: some Vivado builds expect a versioned sub-path instead
       (e.g. "<release>/2026.1/data/secureip/cpm6/...") -- if cpm6_secip
       fails with Error-[SFCOR] Source file cannot be opened, the Vivado
       build has drifted to a newer CPM6 IP core revision than this
       secure-IP mirror; use the pinned Vivado build in step 5, or ask
       whoever maintains /everest/pvs_xsj/SECUREIP_cpm6/ for a matching
       versioned release.

    b. Set VIVADO_CLIBS to the precompiled VCS simlib directory matching the
       pinned Vivado build below:
         setenv VIVADO_CLIBS /proj/xbuilds/2026.1_daily_latest/clibs/vcs/X-2025.06/lin64/lib

       NOTE: use 2026.1 clibs, not 2026.2 (has an empty cpm6_v1_0_8_pkg).

    c. Load tool modules:
         setenv MODULEPATH /tools/packages/infra/release/modulefiles/xsj/tools/avery:${MODULEPATH}
         setenv MODULEPATH /tools/packages/infra/release/modulefiles/xsj/tools/synopsys:${MODULEPATH}
         setenv MODULEPATH /tools/packages/infra/release/modulefiles/xsj/tools/novas:${MODULEPATH}
         module switch vcs/X-2025.06
         module load averyvip/2025.3_1
         module load verdi/2025.06-SP2-2   # optional, for waveform viewing

    Verify:
         echo $VCS_HOME       # should contain X-2025.06
         echo $AVERY_PLI      # should contain avery_pli-2025.3_1
         echo $AVERY_PCIE     # should contain apcievip-2025.3_1
         echo $CPM6_SECUREIP  # should show your chosen release
         echo $VIVADO_CLIBS   # should show the 2026.1 clibs path above

5.  Create the Vivado project. IMPORTANT: use the pinned older Vivado build
    below, not HEAD_PRIME_daily_latest -- newer builds generate different
    CPM6 CDO values causing Avery AVY_ERROR [APIPE_62r_7_1_16n1] during link
    equalization, and/or expect a different secure-IP path layout:

      /proj/primebuilds/9999.0_PRIME_0601_1/installs/lin64/9999.0/Vivado/bin/vivado

    In the Vivado Tcl console:

      set_param ced.repoPaths {<path_to_Versal_CPM6_BMD_Design>}
      create_project <project_name> <output_dir>/<project_name> -part xc2vp3602-vsvc3340-2LHP-e-S
      create_bd_design "cpm6_bmd" -mode batch
      instantiate_example_design -template xilinx.com:design:cpm6_bmd:1.0 \
          -design cpm6_bmd -options { CTRL_CONFIG.VALUE Dual_Controller }

    This now automatically generates the VCS simulation scripts too
    (generate_target, update_compile_order, compxlib.vcs_compiled_library_dir
    from $VIVADO_CLIBS, and launch_simulation -scripts_only are all run from
    inside run.tcl) -- a separate manual "launch_simulation -scripts_only"
    step is no longer required.

    NOTE: use part xc2vp3602-vsvc3340-2LHP-e-S (not 2MP-e-L).

6.  Run simulation:

      cd <output_dir>/<project_name>/sim
      make cos

      Re-simulate only (after first compile+optimize):
      make s TEST=test_bmd_read_min_size_min_count

      If a build gets stuck/inconsistent (partially-compiled clibs or
      Vivado vcs_lib from an earlier failed attempt), wipe everything and
      start fresh:
      make distclean
      make cos

================================================================================
