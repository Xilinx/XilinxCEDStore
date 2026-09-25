class dut_config extends generic_config;

  `uvm_object_utils(dut_config)

  function new(string name = "dut_config");
    super.new(name);
  endfunction

  // Housekeeping things
  string cdo_dir = "../cdo"; //default path to base CDOs 
  string base_cdo;           //must be a text CDO
  string full_cdo;           //must NOT be a text CDO; cdo loader uses directly
  string output_cdo = "test_generated.cdo";
  string absolute_cdo;
  bit    rand_me = 1'b1;

  // Variables that MUST be set for RTL
  enum {NO_USE_CASE, PCIE_STR, PCIE_DMA, CXL_STR, CXL_DMA} use_case[2];
  
  // Variables that can be randomized
  // --

  // ---------------------------- //
  // Constraints
  // ---------------------------- //
  // Must control enablement based on ctrlr_en    
  constraint c_funcs {
    foreach (pcie_cfg[ii]) {
      ctrlr_en[ii] -> pcie_cfg[ii].num_pfs inside {[1:8]};
    }
  }

  // Do stuff before randomization
  function void pre_randomize;
    super.pre_randomize;
    foreach (ctrlr_en[ii]) begin

      // Detect error conditions 
      if (ctrlr_en[ii] && (use_case[ii]==NO_USE_CASE))
`ifdef CPM6_RTL
        `uvm_fatal(get_type_name, $sformatf("ctrlr_en[%0d]=1, but use_case[%0d] not specified",ii,ii))
`else
        `uvm_warning(get_type_name, $sformatf("ctrlr_en[%0d]=1, but use_case[%0d] not specified (not required)",ii,ii))
`endif
    end
  endfunction

  // Do stuff after randomization
  function void post_randomize;
    super.post_randomize;
  endfunction

  function void resolve_cdo_source();
    string msg;
    int    fd;
    // If running a Vivado sim, summarize some data and return
    if ($test$plusargs("CPM6_VIVADO")) begin
      rand_me = 1'b0;
      if (!uvm_config_db#(string)::get(null, "", "cpm6_cdo_file", output_cdo))
        `uvm_fatal("CFGDB_NOGET", "Could not get 'cpm6_cdo_file' from cfg db")
      // This name is hardcoded; Vivado generates a text CDO that must be converted
      absolute_cdo = {"../", output_cdo};
      `uvm_info("CDO_INFO", $sformatf("Using CPM6 CDO specified from Vivado: %0s", output_cdo), UVM_NONE)
      return;
    end
    /* Allow command line arguments to override the settings, if desired*/
    if ($value$plusargs("CDO_DIR=%s", cdo_dir)) begin
      // Found relative to sim directory; from test is ../
      if (!$system({"test -d ../",cdo_dir})) begin
        `uvm_info("PLUSARG", $sformatf("CDO_DIR=%0s passed to test, using it", cdo_dir), UVM_NONE)
        cdo_dir = {"../", cdo_dir};
      end
      // Given as absolute path
      else if (!$system({"test -d ",cdo_dir})) begin
        `uvm_info("PLUSARG", $sformatf("CDO_DIR=%0s passed to test, using it", cdo_dir), UVM_NONE)
      end
      else begin
        `uvm_fatal("PLUSARG", $sformatf("CDO_DIR=%0s passed to test doesn't exist", cdo_dir))
      end
    end
    // A full CDO from plusarg is the highest priority...
    if ($value$plusargs("FULL_CDO=%s", full_cdo)) begin
      rand_me = 1'b0;
      output_cdo = basename(full_cdo);
      // Found in sim launch directory; relative to test is ../
      if (!$system({"test -e ../",full_cdo})) begin
        `uvm_info("PLUSARG", $sformatf("FULL_CDO=%0s passed to test, using it directly", full_cdo), UVM_NONE)
        absolute_cdo = {"../", full_cdo};
        return;
      end
      // Given as a full path
      else if (!$system({"test -e ",full_cdo})) begin
        `uvm_info("PLUSARG", $sformatf("FULL_CDO=%0s passed to test, using it directly", full_cdo), UVM_NONE)
        absolute_cdo = full_cdo;
        return;
      end
      // Found in 'cdo_dir' directory
      else if (!$system({"test -e ",cdo_dir,"/",full_cdo})) begin
        `uvm_info("PLUSARG", $sformatf("FULL_CDO=%0s passed to test, using it directly from %0s", full_cdo, cdo_dir), UVM_NONE)
        absolute_cdo = {cdo_dir, "/", full_cdo};
        return;
      end
      // Else fatal
      else begin
        `uvm_fatal("PLUSARG", $sformatf("FULL_CDO=%0s passed to test doesn't exist in current or %0s dir", full_cdo, cdo_dir))
      end
    end
    // ...then the full CDO provided by the test...
    else if (full_cdo != "") begin 
      rand_me = 1'b0;
      output_cdo = full_cdo;
      // Found in sim launch directory; relative to test is ../
      if (!$system({"test -e ../",full_cdo})) begin
        `uvm_info("TEST_SPEC", $sformatf("The full CDO is specified by the test directly: %0s", full_cdo), UVM_NONE)
        absolute_cdo = {"../", full_cdo};
        return;
      end
      // Given as a full path
      else if (!$system({"test -e ",full_cdo})) begin
        `uvm_info("TEST_SPEC", $sformatf("FULL_CDO=%0s passed to test, using it directly", full_cdo), UVM_NONE)
        absolute_cdo = full_cdo;
        return;
      end
      // Found in 'cdo_dir' directory
      else if (!$system({"test -e ",cdo_dir,"/",full_cdo})) begin
        `uvm_info("TEST_SPEC", $sformatf("The full CDO is specified by the test directly: %0s", {cdo_dir,"/",full_cdo}), UVM_NONE)
        absolute_cdo = {cdo_dir, "/", full_cdo};
        return;
      end
      // Else fatal
      else begin
        `uvm_fatal("TEST_SPEC", $sformatf("The full CDO - %0s - specified by the test doesn't exist in current or %0s dir", full_cdo, cdo_dir))
      end
    end
    // ...else use a base CDO from plusarg...
    else if ($value$plusargs("BASE_CDO=%s", base_cdo)) begin
      // Found in sim launch directory; relative to test is ../
      if (!$system({"test -e ../",base_cdo})) begin
        `uvm_info("PLUSARG", $sformatf("BASE_CDO=%0s passed to test, using it", base_cdo), UVM_NONE)
        absolute_cdo = {"../", base_cdo};
      end
      // Given as a full path
      else if (!$system({"test -e ",base_cdo})) begin
        `uvm_info("PLUSARG", $sformatf("BASE_CDO=%0s passed to test, using it directly", base_cdo), UVM_NONE)
        absolute_cdo = base_cdo;
        return;
      end
      // Found in 'cdo_dir' directory
      else if (!$system({"test -e ",cdo_dir,"/",base_cdo})) begin
        `uvm_info("PLUSARG", $sformatf("BASE_CDO=%0s passed to test, using it at %0s", base_cdo, cdo_dir), UVM_NONE)
        absolute_cdo = {cdo_dir, "/", base_cdo};
      end
      else begin
        `uvm_fatal("PLUSARG", $sformatf("BASE_CDO=%0s passed to test doesn't exist in local or %0s dir", base_cdo, cdo_dir))
      end
    end
    // ...else use a base CDO provided by the test
    else if (base_cdo != "") begin 
      // Found in sim launch directory; relative to test is ../
      if (!$system({"test -e ../",base_cdo})) begin
        `uvm_info("TEST_SPEC", $sformatf("The base CDO is specified by the test directly: %0s", base_cdo), UVM_NONE)
        absolute_cdo = {"../", base_cdo};
        return;
      end
      // Given as a full path
      else if (!$system({"test -e ",base_cdo})) begin
        `uvm_info("TEST_SPEC", $sformatf("BASE_CDO=%0s passed to test, using it directly", base_cdo), UVM_NONE)
        absolute_cdo = base_cdo;
        return;
      end
      // Found in 'cdo_dir' directory
      else if (!$system({"test -e ",cdo_dir,"/",base_cdo})) begin
        `uvm_info("TEST_SPEC", $sformatf("The base CDO is specified by the test directly: %0s", {cdo_dir,"/",base_cdo}), UVM_NONE)
        absolute_cdo = {cdo_dir, "/", base_cdo};
        return;
      end
      // Else fatal
      else begin
        `uvm_fatal("TEST_SPEC", $sformatf("The base CDO - %0s - specified by the test doesn't exist in current or %0s dir", base_cdo, cdo_dir))
      end
    end
    // No CDO specified
    else begin
      return;
    end
  endfunction

  // If a user is running a Vivado sim, passes in a full CDO (FULL_CDO=%s) 
  // from the command line a test, use it directly. Otherwise, take the 
  // settings, append to a base do given by the test or command line, and 
  // program the attribute registers so all settings get applied to the DUT.
  function void create_test_cdo;
    string rbase; //reg block base
    int    fd;
    string msg;
    string sh; //sh = "shorthand"
    string orig_cdo;
    string cu_args = "-device xc2vp3202 -output-raw-be -output-file";
    if ($test$plusargs("CPM6_VIVADO")) begin
      orig_cdo = {"../", output_cdo.substr(0,output_cdo.len-5), "_text.cdo"};
      // Copy the Vivado generated CDO to the simulation so it remains untouched
      msg = $sformatf("cp %0s %0s", orig_cdo, orig_cdo.substr(3, orig_cdo.len-1));
      orig_cdo = orig_cdo.substr(3, orig_cdo.len-1);
      if ($system(msg)) begin
        `uvm_fatal("ERRCALL", {"Return value non-zero: ", msg}) 
      end
      // Perform a quick check to make sure cfg.ctrlr_en[n] matches CDO
      // PCIE0_CFG = 0xFC0....
      if (ctrlr_en[0]) begin
        if ($system({"grep -iq 'write 0xfc0' ",orig_cdo," 2&>1 > /dev/null"})) begin
          `uvm_fatal(get_type_name, "ctrlr_en[0]=1 but CDO doesn't contain any PCIE0_CFG setup")
        end
      end
      // PCIE1_CFG = 0xFC4....
      if (ctrlr_en[1]) begin
        if ($system({"grep -iq 'write 0xfc4' ",orig_cdo," 2&>1 > /dev/null"})) begin
          `uvm_fatal(get_type_name, "ctrlr_en[1]=1 but CDO doesn't contain any PCIE1_CFG setup")
        end
      end
      // Remove any CHIPPIPE programming if running a PIPE sim
      if ($test$plusargs("PCIE_LINK_PIPE")) begin
        msg = "Running a PIPE sim: removing any CHIPPIPE programming from CDO to save sim time";
        `uvm_info("FIXME::CDO_MOD", msg, UVM_NONE)
        msg = $sformatf("sed -i 's/^write 0xfcc/#write 0xfcc/' %0s", orig_cdo);
        if ($system(msg)) begin
          `uvm_fatal("ERRCALL", {"Return value non-zero: ", msg}) 
        end
        msg = $sformatf("sed -i 's/^mask_write 0xfcc/#mask_write 0xfcc/' %0s", orig_cdo);
        if ($system(msg)) begin
          `uvm_fatal("ERRCALL", {"Return value non-zero: ", msg}) 
        end
      end
      // Use CDO util call to convert to ASCII hex CDO instead of text CDO
      msg = $sformatf("$CDOUTIL_PATH/cdoutil %0s %0s %0s 2&>1 > /dev/null",
                       cu_args,
                       output_cdo,
                       orig_cdo);
      // if CDOUTIL_PATH env var is unset, just assume it's found in PATH 
      if ($system("printenv | grep -q 'CDOUTIL_PATH='")) begin
        // Use CDO util to convert to ASCII hex CDO instead of text CDO
        msg = msg.substr(14, msg.len-1);
      end
      if ($system(msg)) begin
        `uvm_fatal("ERRCALL", {"Return value non-zero: ", msg}) 
      end
      return;
    end
    // Copy the CDO directly and use it; MUST be ASCII hex
    if (full_cdo != "") begin
      `uvm_info(get_type_name, $sformatf("Copying full CDO for test to use: %0s", absolute_cdo), UVM_NONE)
      msg = $sformatf("cp -f %0s %0s", absolute_cdo, output_cdo);
      if ($system(msg)) begin
        `uvm_fatal("ERRCALL", {"Return value non-zero: ", msg}) 
      end
    end
    // Append to base CDO (must be text)
    else begin
      // Print to logfile
      print_settings;
      // Fatal if CDO wasn't specified
      if (absolute_cdo=="")
        `uvm_fatal("NO_CDO", "Something went wrong; there's no CDO specified")
      // Write new CDO
      `uvm_info(get_type_name, $sformatf("Base CDO: %0s, creating new CDO: %0s", absolute_cdo, output_cdo), UVM_NONE)
      // Copy the CDO 
      msg = $sformatf("cp -f %0s %0s.anno", absolute_cdo, output_cdo);
      if ($system(msg)) begin
        `uvm_fatal("ERRCALL", {"Return value non-zero: ", msg}) 
      end
      // Open the copied cdo and append to it
      fd = $fopen({output_cdo,".anno"}, "a");
      // Let the user know where we started adding
      $fdisplay(fd, "%0s", {70{"#"}});
      $fdisplay(fd, {"# Original CDO: ", absolute_cdo});
      $fdisplay(fd, "# Additional CDO programming added from test settings and dut_config::randomize call");
      $fdisplay(fd, "%0s", {70{"#"}});
      /* Start programming CDO values */
      if (ctrlr_en[0]) begin
        $fdisplay(fd, "### Controller 0 settings");
        // Print child settings 
        pcie_cfg[0].create_cdo(fd, 0);
        if (port_ctl[0]!=PCIE) 
          cxl_cfg[0].create_cdo(fd, 0);
      end
      if (ctrlr_en[1]) begin
        $fdisplay(fd, "### Controller 1 settings");
        // Print child settings 
        pcie_cfg[1].create_cdo(fd, 1);
        if (port_ctl[1]!=PCIE)
          cxl_cfg[1].create_cdo(fd, 1);
      end
      // Done programming
      $fclose(fd);
      // Use CDO util call to convert to ASCII hex CDO instead of text CDO
      msg = $sformatf("$CDOUTIL_PATH/cdoutil %0s %0s %0s 2&>1 > /dev/null",
                       cu_args,
                       output_cdo,
                       {output_cdo, ".anno"}); 
      // if CDOUTIL_PATH env var is unset, just assume it's found in PATH 
      if ($system("printenv | grep 'CDOUTIL_PATH='")) begin
        // Use CDO util to convert to ASCII hex CDO instead of text CDO
        msg = msg.substr(14, msg.len-1);
      end
      if ($system(msg)) begin
        `uvm_fatal("ERRCALL", {"Return value non-zero: ", msg}) 
      end
    end
    // Pass the name of CDO file so CDO loader can use it
    if ($test$plusargs("CPM6_RTL")) begin
      uvm_config_db#(string)::set(null, "*", "cdo_file", output_cdo);
    end
  endfunction

  // This function will copy the GT configuration files to the test directory.
  // Vivado creates these files so we just copy them. We do not run an RTL
  // simulation with the GTs involved, so this method does nothing for RTL
  // source.
  function void resolve_gt_config();
    string msg;
    if (!$test$plusargs("CPM6_RTL")) begin
      msg = $sformatf("cp -f ../bd_*gt_quad_*.mem ./");
      if ($system(msg)) begin
        `uvm_fatal("ERRCALL", {"Return value non-zero: ", msg}) 
      end
    end
  endfunction

  virtual function void pre_top_cb(int fd, int ctrlr = -1);
    $fdisplay(fd, "  - use_case : %0s", use_case[ctrlr].name);
  endfunction

  // Same functionality as Linux 'basename'; cuts from last "/" char to end
  virtual function string basename(string inp);
    int last = inp.len-1;
    for (int ii=last; ii>=0; ii--)
      if (inp[ii]=="/")
        return (inp.substr(ii+1,last));
    return inp;
  endfunction

endclass
