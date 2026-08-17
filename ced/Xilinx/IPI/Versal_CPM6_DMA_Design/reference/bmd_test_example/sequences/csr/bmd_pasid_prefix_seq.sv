//==============================================================================
// bmd_pasid_prefix_seq.sv - BMD PASID Prefix Configuration Sequence
//==============================================================================
// Programs WDMAPASID and RDMAPASID registers with PASID prefix settings
//==============================================================================

class bmd_pasid_prefix_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_pasid_prefix_seq_c)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_pasid_prefix_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] dmapasid_data;

        // Build DMAPASID register value (same for both read and write)
        dmapasid_data = {
            cap_cfg.cfg_pf_pasid_priv_en,       // Privileged Mode Enable     [31]
            cap_cfg.cfg_pf_pasid_exe_en,        // Execute Permission Enable  [30]
            2'b00,                              // Reserved                   [29:28]
            csr_cfg.pasid[19:16],               // PASID[19:16]               [27:24]
            csr_cfg.pasid[15:8],                // PASID[15:8]                [23:16]
            csr_cfg.pasid[7:0],                 // PASID[7:0]                 [15:8]
            cap_cfg.cfg_pf_pasid_en             // PASID Valid                [7:0]
        };

        // Program PASID prefix CSRs (same value for both read and write)
        issue_csr_write(WDMAPASID, dmapasid_data);
        issue_csr_write(RDMAPASID, dmapasid_data);

        `uvm_info(get_name(), {"Programmed PASID Prefix:\n",
                                "\t", $sformatf("PASID Enable                 = 0x%x,",
                                    cap_cfg.cfg_pf_pasid_en), "\n",
                                "\t", $sformatf("PASID Privileged Mode        = 0x%x,",
                                    cap_cfg.cfg_pf_pasid_priv_en), "\n",
                                "\t", $sformatf("PASID Execute Permission     = 0x%x,",
                                    cap_cfg.cfg_pf_pasid_exe_en), "\n",
                                "\t", $sformatf("PASID                        = 0x%x",
                                    csr_cfg.pasid), "\n"
                                }, UVM_MEDIUM)

    endtask

endclass
