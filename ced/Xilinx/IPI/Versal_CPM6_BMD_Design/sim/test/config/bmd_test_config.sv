class bmd_test_config_c extends uvm_object;
    `uvm_object_utils(bmd_test_config_c)

    bit [6:0]       max_range_addr;
    protected bit   max_addr_populated = 1'b0;

    bit [31:0]      valid_pattern;
    protected bit   pattern_populated = 1'b0;

    //////////////////////////////////////////
    //  Other Procedures
    //////////////////////////////////////////
    bit             access_vsec = 1'b0;

    //////////////////////////////////////////
    //  Error Injection
    //////////////////////////////////////////
    rand bit        send_ur_to_dut;
    rand bit        read_out_of_range;
    rand bit [6:0]  out_of_range_addr;
    rand bit        inject_bad_data;
    rand bit [31:0] bad_data;
    rand bit [7:0]  bad_byte;

    //---------------------------------------------------------------------
    // UVM Automation
    //---------------------------------------------------------------------
    function new(string name = "bmd_test_config");
        super.new(name);
    endfunction

    //---------------------------------------------------------------------
    // Safety Check: Fail if randomized too early
    //---------------------------------------------------------------------
    function void pre_randomize();
        if (!max_addr_populated || !pattern_populated) begin
            `uvm_fatal("BMD_TEST_CONFIG", {
                "\n",
                "====================================================================\n",
                " CONFIGURATION ERROR: Randomize called before out of range address\n",
                "                      and pattern setup!\n",
                "====================================================================\n",
                " The BMD test config cannot be randomized until the environment has\n",
                " populated the maximum valid address range and a valid data pattern\n",
                " to avoid when performing error injection.\n",
                "===================================================================="
            })
        end

        `uvm_info("BMD_TEST_CONFIG", $sformatf(
            "Randomizing with max range address 0x%x and pattern 0x%x",
            max_range_addr, valid_pattern), UVM_MEDIUM)
    endfunction

    //---------------------------------------------------------------------
    // Called by environment
    //---------------------------------------------------------------------
    function void add_error_vars(bit [6:0] max_range_addr, bit [31:0] valid_pattern);
        this.max_range_addr = max_range_addr;
        this.valid_pattern = valid_pattern;

        if (!max_addr_populated || !pattern_populated) begin
            `uvm_info("BMD_TEST_CONFIG", "Out of range address and valid pattern added - config ready for randomization", UVM_MEDIUM)
            max_addr_populated = 1'b1;
            pattern_populated = 1'b1;
        end
    endfunction

    //---------------------------------------------------------------------
    // Constraints
    //---------------------------------------------------------------------
    constraint out_of_range_addr_c {
        out_of_range_addr > max_range_addr;
    }

    constraint bad_data_c {
        bad_data[7:0]   != valid_pattern[7:0];
        bad_data[15:8]  != valid_pattern[15:8];
        bad_data[23:16] != valid_pattern[23:16];
        bad_data[31:24] != valid_pattern[31:24];
    }

    constraint bad_byte_c {
        bad_byte != valid_pattern[7:0];
        bad_byte != valid_pattern[15:8];
        bad_byte != valid_pattern[23:16];
        bad_byte != valid_pattern[31:24];
    }

endclass
