//==============================================================================
// bmd_byte_enable_config_seq.sv - BMD Byte Enable Configuration Sequence
//==============================================================================
// Programs DMAEXT register with byte enable settings for read and write TLPs
//==============================================================================

class bmd_byte_enable_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_byte_enable_config_seq_c)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_byte_enable_config_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] dmaext_data;

        // Build DMAEXT register value
        dmaext_data = {
            16'd0,                  // Reserved                       [31:16]
            csr_cfg.wr_upper_be,    // Write Upper Byte Enable        [15:12]
            csr_cfg.wr_lower_be,    // Write Lower Byte Enable        [11:8]
            csr_cfg.rd_upper_be,    // Read Upper Byte Enable         [7:4]
            csr_cfg.rd_lower_be     // Read Lower Byte Enable         [3:0]
        };

        // Program byte enable CSR
        issue_csr_write(DMAEXT, dmaext_data);

        `uvm_info(get_name(), {"Programmed Byte Enables:\n",
                                "\t", $sformatf("Write Upper Byte Enable      = 0x%x,",
                                    csr_cfg.wr_upper_be), "\n",
                                "\t", $sformatf("Write Lower Byte Enable      = 0x%x,",
                                    csr_cfg.wr_lower_be), "\n",
                                "\t", $sformatf("Read Upper Byte Enable       = 0x%x,",
                                    csr_cfg.rd_upper_be), "\n",
                                "\t", $sformatf("Read Lower Byte Enable       = 0x%x",
                                    csr_cfg.rd_lower_be), "\n"
                            }, UVM_MEDIUM)

    endtask

endclass
