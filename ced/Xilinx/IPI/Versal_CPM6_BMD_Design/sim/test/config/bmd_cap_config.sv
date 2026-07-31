class bmd_cap_config_c extends uvm_object;
    `uvm_object_utils(bmd_cap_config_c)

    typedef struct {
        bit [63:0]      min_addr;
        bit [63:0]      max_addr;
    } reserved_address_range_t;

    reserved_address_range_t    rsvd_addr[$];
    protected bit reserved_range_populated = 0;

    rand bit        cfg_10b_tag_req_en;
    rand bit        cfg_ext_tag_en;
    rand bit        cfg_atomic_req_en;

    rand bit        cfg_int_disable;
    rand bit        cfg_msi_en;
    rand bit        cfg_msix_en;

    rand bit        cfg_msi_ext_data_en;
    rand bit        cfg_msi_mask_vector;

    rand bit [63:0] cfg_msi_addr;
    rand bit [31:0] cfg_msi_data;
    rand bit [63:0] cfg_msix_addr;
    rand bit [31:0] cfg_msix_data_wr;
    rand bit [31:0] cfg_msix_data_rd;

    rand bit [2:0]  cfg_multi_msg_en;

    rand bit        cfg_tph_en;
    rand bit        cfg_tph_ext_en;

    rand bit        cfg_pf_pasid_en;
    bit             cfg_pf_pasid_exe_en    = '0;
    bit             cfg_pf_pasid_priv_en   = '0;

    //---------------------------------------------------------------------
    // UVM Automation
    //---------------------------------------------------------------------
    function new(string name = "bmd_cap_config");
        super.new(name);
    endfunction

    //---------------------------------------------------------------------
    // Safety Check: Fail if randomized too early
    //---------------------------------------------------------------------
    function void pre_randomize();
        if (!reserved_range_populated) begin
            `uvm_fatal("BMD_CAP_CONFIG", {
                "\n",
                "====================================================================\n",
                " CONFIGURATION ERROR: Randomize called before reserved address setup!\n",
                "====================================================================\n",
                " The BMD Capability config cannot be randomized until the environment\n",
                " has populated the Address exclusion regions.\n",
                "===================================================================="
            })
        end

        `uvm_info("BMD_CAP_CONFIG", $sformatf(
            "Randomizing with %0d excluded Address regions",
            rsvd_addr.size()), UVM_MEDIUM)
    endfunction

    //---------------------------------------------------------------------
    // Called by environment
    //---------------------------------------------------------------------
    function void add_excluded_region(bit [63:0] min_addr, bit [63:0] max_addr);
        reserved_address_range_t region;
        region.min_addr = min_addr;
        region.max_addr = max_addr;
        rsvd_addr.push_back(region);

        if (!reserved_range_populated) begin
            `uvm_info("BMD_CAP_CONFIG", "First Address region added - config ready for randomization", UVM_MEDIUM)
            reserved_range_populated = 1;
        end
    endfunction

    //---------------------------------------------------------------------
    // Constraints
    //---------------------------------------------------------------------
    constraint msi_addr_rsvd_bits_c {
        cfg_msi_addr[1:0] == 2'b00;
        cfg_msix_addr[1:0] == 2'b00;
    }

    constraint msix_avoid_rsvd_regions_c {
        foreach (rsvd_addr[i]) {
            cfg_msix_addr < rsvd_addr[i].min_addr || cfg_msix_addr > rsvd_addr[i].max_addr;
            cfg_msix_addr[31:0] < rsvd_addr[i].min_addr || cfg_msix_addr[31:0] > rsvd_addr[i].max_addr;
        }
    }

    constraint msi_avoid_rsvd_regions_c {
        foreach (rsvd_addr[i]) {
            cfg_msi_addr < rsvd_addr[i].min_addr || cfg_msi_addr > rsvd_addr[i].max_addr;
            cfg_msi_addr[31:0] < rsvd_addr[i].min_addr || cfg_msi_addr[31:0] > rsvd_addr[i].max_addr;
        }
    }

    constraint msi_msix_c {
        cfg_msi_addr        != cfg_msix_addr;
        cfg_msi_addr[31:0]  != cfg_msix_addr[31:0];
        !(cfg_msi_en && cfg_msix_en);
    }

endclass
