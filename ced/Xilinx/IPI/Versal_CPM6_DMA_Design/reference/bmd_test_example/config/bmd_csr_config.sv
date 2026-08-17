class bmd_csr_config_c extends uvm_object;
    `uvm_object_utils(bmd_csr_config_c)

    typedef struct {
        bit [63:0] base;
        bit [63:0] size;
    } bar_region_t;

    bar_region_t excluded_regions[$];
    protected bit bars_populated = 0;

    ////////////////////////////////////////////
    //  Not currently randomized - Set by test
    ////////////////////////////////////////////
    bit        rd_inc_addr  = '0;
    bit        wr_inc_addr  = '0;
    bit [9:0]  wr_tid       = '0;

    bit [4:0]  rd_tlp_type  = '0;
    bit        rd_fmt_1     = 1'b0;
    bit [4:0]  wr_tlp_type  = '0;
    bit        wr_fmt_1     = 1'b1;

    //////////////////////////////////////////
    //  Read TLP CSRs
    //////////////////////////////////////////
    rand bit [31:0] rd_addr;
    rand bit [31:0] rd_uaddr;
    rand bit [10:0] rd_size;
    rand bit [15:0] rd_count;
    rand bit        r64_en;
    rand bit [3:0]  rd_lower_be;
    rand bit [3:0]  rd_upper_be;
    rand bit [2:0]  rd_tc;
    rand bit        rd_tc_en;
    rand bit [31:0] rd_pattern;
    rand bit        rd_start;

    bit             rd_t_bit        = '0;
    bit             rd_no_write     = '0;
    bit [1:0]       rd_ats          = '0;
    bit             rd_poisoned     = '0;
    bit             rd_td           = '0;

    //////////////////////////////////////////
    //  Write TLP CSRs
    //////////////////////////////////////////
    rand bit [31:0] wr_addr;
    rand bit [31:0] wr_uaddr;
    rand bit [10:0] wr_size;
    rand bit [15:0] wr_count;
    rand bit        w64_en;
    rand bit [3:0]  wr_lower_be;
    rand bit [3:0]  wr_upper_be;
    rand bit [2:0]  wr_tc;
    rand bit        wr_tc_en;
    rand bit [31:0] wr_pattern;
    rand bit        wr_start;

    bit             wr_t_bit        = '0;
    bit             wr_no_write     = '0;
    bit [1:0]       wr_ats          = '0;
    bit             wr_poisoned     = '0;
    bit             wr_td           = '0;

    //////////////////////////////////////////
    //  Interrupt CSRs
    //////////////////////////////////////////
    rand bit        rd_int_disable;
    rand bit        wr_int_disable;
    rand bit [1:0]  wr_int_sel;
    rand bit [1:0]  rd_int_sel;
    rand bit [10:0] msix_wr_vec;
    rand bit [10:0] msix_rd_vec;
    rand bit [1:0]  intx_wr_vec;
    rand bit [1:0]  intx_rd_vec;

    //////////////////////////////////////////
    //  Prefix CSRs
    //////////////////////////////////////////
    rand bit [19:0] pasid;
    rand bit [15:0] st;
    rand bit [1:0]  ph;

    bit [3:0]       ama = '0;

    //---------------------------------------------------------------------
    // UVM Automation
    //---------------------------------------------------------------------
    function new(string name = "bmd_csr_config");
        super.new(name);
    endfunction

    //---------------------------------------------------------------------
    // Safety Check: Fail if randomized too early
    //---------------------------------------------------------------------
    function void pre_randomize();
        if (!bars_populated) begin
            `uvm_fatal("BMD_CSR_CONFIG", {
                "\n",
                "====================================================================\n",
                " CONFIGURATION ERROR: Randomize called before BAR setup!\n",
                "====================================================================\n",
                " The BMD CSR config cannot be randomized until the environment has\n",
                " populated the BAR exclusion regions.\n",
                "===================================================================="
            })
        end

        `uvm_info("BMD_CSR_CONFIG", $sformatf(
            "Randomizing with %0d excluded BAR regions",
            excluded_regions.size()), UVM_MEDIUM)
    endfunction

    //---------------------------------------------------------------------
    // Called by environment
    //---------------------------------------------------------------------
    function void add_excluded_region(bit [63:0] base, bit [63:0] size);
        bar_region_t region;
        region.base = base;
        region.size = size;
        excluded_regions.push_back(region);

        if (!bars_populated) begin
            `uvm_info("BMD_CSR_CONFIG", "First BAR region added - config ready for randomization", UVM_MEDIUM)
            bars_populated = 1;
        end
    endfunction

    function void clear_excluded_regions();
        excluded_regions.delete();
        bars_populated = 1'b0;
    endfunction

    //---------------------------------------------------------------------
    // General Constraints
    //---------------------------------------------------------------------
    constraint traffic_start_c {
        (wr_start || rd_start) == 1'b1;
    }

    //---------------------------------------------------------------------
    // Write TLP Constraints
    //---------------------------------------------------------------------
    constraint write_addr_bar_conflicts_c {
        foreach(excluded_regions[i]) {
            ({wr_uaddr, wr_addr} < excluded_regions[i].base &&
                wr_addr + (wr_count * (wr_size<<2)) < excluded_regions[i].base)
            ||
            ({wr_uaddr, wr_addr} > excluded_regions[i].base + excluded_regions[i].size - 1 &&
                wr_addr + (wr_count * (wr_size<<2)) > excluded_regions[i].base + excluded_regions[i].size - 1);
        }
    }

    constraint write_upper_address_c {
        if (!w64_en) {
            wr_uaddr == '0;
        } else {
            wr_uaddr != '0;
        }
    }

    constraint write_4k_aligned_c {
        wr_addr[1:0] == 2'b00;
        wr_addr[11:0] % (wr_size << 2) == 0;
    }

    constraint write_size_c {
        wr_size inside {1, 2, 4, 8, 16, 32, 64, 128, 256};
    }

    constraint write_count_c {
        wr_count != 0;
    }

    constraint write_byte_enables_c {
        wr_lower_be inside {4'b0000, 4'b1000, 4'b1100, 4'b1110, 4'b1111};
        wr_upper_be inside {4'b0000, 4'b0001, 4'b0011, 4'b0111, 4'b1111};

        if (wr_size == 1) {
            wr_upper_be == 4'b0000;
        }

        if (wr_size > 1) {
            wr_upper_be != 4'b0000;
            wr_lower_be != 4'b0000;
        }
    }

    constraint write_tc_c {
        if (!wr_tc_en) {
            wr_tc == 3'b000;
        }
    }

    //---------------------------------------------------------------------
    // Read TLP Constraints
    //---------------------------------------------------------------------
    constraint read_addr_bar_conflicts_c {
        foreach(excluded_regions[i]) {
            ({rd_uaddr, rd_addr} < excluded_regions[i].base &&
                rd_addr + (rd_count * (rd_size<<2)) < excluded_regions[i].base)
            ||
            ({rd_uaddr, rd_addr} > excluded_regions[i].base + excluded_regions[i].size - 1 &&
                rd_addr + (rd_count * (rd_size<<2)) > excluded_regions[i].base + excluded_regions[i].size - 1);
        }
    }

    constraint read_upper_address_c {
        if (!r64_en) {
            rd_uaddr == '0;
        } else {
            rd_uaddr != '0;
        }
    }

    constraint read_size_c {
        rd_size inside {1, 2, 4, 8, 16, 32, 64, 128, 256};
    }

    constraint read_count_c {
        rd_count != 0;
    }

    constraint read_4k_aligned_c {
        rd_addr[1:0] == 2'b00;
        rd_addr[11:0] % (rd_size << 2) == 0;
    }

    constraint read_byte_enables_c {
        rd_lower_be inside {4'b0000, 4'b1000, 4'b1100, 4'b1110, 4'b1111};
        rd_upper_be inside {4'b0000, 4'b0001, 4'b0011, 4'b0111, 4'b1111};

        if (rd_size == 1) {
            rd_upper_be == 4'b0000;
        }

        if (rd_size > 1) {
            rd_upper_be != 4'b0000;
            rd_lower_be != 4'b0000;
        }
    }

    constraint read_tc_c {
        if (!rd_tc_en) {
            rd_tc == 3'b000;
        }
    }

    //---------------------------------------------------------------------
    // Interrupt Constraints
    //---------------------------------------------------------------------
    constraint traffic_interrupts_c {
        wr_int_sel != 2'b11;
        rd_int_sel != 2'b11;

        // Requirement for checking
        msix_wr_vec != msix_rd_vec;
        intx_wr_vec != intx_rd_vec;
    }

endclass
