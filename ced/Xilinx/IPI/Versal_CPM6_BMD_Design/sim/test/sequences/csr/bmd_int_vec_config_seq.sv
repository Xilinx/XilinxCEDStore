//==============================================================================
// bmd_int_vec_config_seq.sv - BMD Interrupt Vector Configuration Sequence
//==============================================================================
// Programs DMAMSIX register with interrupt vector settings for MSI-X and INTx
//==============================================================================

class bmd_int_vec_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_int_vec_config_seq_c)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_int_vec_config_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] dmamsix_data;

        // Build DMAMSIX register value
        dmamsix_data = {
            6'b0,                   // Reserved                       [31:26]
            csr_cfg.intx_rd_vec,    // INTx Read Vector               [25:24]
            csr_cfg.intx_wr_vec,    // INTx Write Vector              [23:22]
            csr_cfg.msix_rd_vec,    // MSI-X Read Vector              [21:11]
            csr_cfg.msix_wr_vec     // MSI-X Write Vector             [10:0]
        };

        // Program interrupt vector CSR
        issue_csr_write(DMAMSIX, dmamsix_data);

        `uvm_info(get_name(), {"Programmed Interrupt Vectors:\n",
                                "\t", $sformatf("INTx Read Vector             = 0x%x,",
                                    csr_cfg.intx_rd_vec), "\n",
                                "\t", $sformatf("INTx Write Vector            = 0x%x,",
                                    csr_cfg.intx_wr_vec), "\n",
                                "\t", $sformatf("MSI-X Read Vector            = 0x%x,",
                                    csr_cfg.msix_rd_vec), "\n",
                                "\t", $sformatf("MSI-X Write Vector           = 0x%x",
                                    csr_cfg.msix_wr_vec), "\n"
                                }, UVM_MEDIUM)

    endtask

endclass
