//==============================================================================
// bmd_tph_prefix_seq.sv - BMD TPH Prefix Configuration Sequence
//==============================================================================
// Programs DMATPH register with TPH (TLP Processing Hints) prefix settings
//==============================================================================

class bmd_tph_prefix_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_tph_prefix_seq_c)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_tph_prefix_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] dmatph_data;

        // Build DMATPH register value
        dmatph_data = {
            6'b000000,                                      // Reserved               [31:26]
            cap_cfg.cfg_tph_ext_en && cap_cfg.cfg_tph_en,   // Extended TPH Enable    [25]      [Read]
            csr_cfg.st[15:8],                               // Steering Tag[15:8]     [24:17]   [Read]
            csr_cfg.ama,                                    // AMA                    [16:13]   [Read]
            cap_cfg.cfg_tph_ext_en && cap_cfg.cfg_tph_en,   // Extended TPH Enable    [12]      [Write]
            csr_cfg.st[15:8],                               // Steering Tag[15:8]     [11:4]    [Write]
            csr_cfg.ama                                     // AMA                    [3:0]     [Write]
        };

        // Program TPH prefix CSR
        issue_csr_write(DMATPH, dmatph_data);

        `uvm_info(get_name(), {"Programmed TPH Prefix:\n",
                                "\t", $sformatf("Extended TPH Enable          = 0x%x,",
                                    cap_cfg.cfg_tph_ext_en && cap_cfg.cfg_tph_en), "\n",
                                "\t", $sformatf("Upper ST                     = 0x%x",
                                    csr_cfg.st[15:8]), "\n"
                                }, UVM_MEDIUM)

    endtask

endclass
