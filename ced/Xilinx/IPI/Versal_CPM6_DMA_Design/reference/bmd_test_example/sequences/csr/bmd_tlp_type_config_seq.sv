//==============================================================================
// bmd_tlp_type_config_seq.sv - BMD Byte Enable Configuration Sequence
//==============================================================================
// Programs DMATLPTYPE to set format and type for non-posted and posted
// generation
//==============================================================================

class bmd_tlp_type_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_tlp_type_config_seq_c)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_tlp_type_config_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] dmatype_data;

        // Build DMA TLP Type register value
        dmatype_data = {
            20'd0,
            csr_cfg.wr_fmt_1,
            csr_cfg.wr_tlp_type,
            csr_cfg.rd_fmt_1,
            csr_cfg.wr_tlp_type
        };

        // Program byte enable CSR
        issue_csr_write(DMATLPTYPE, dmatype_data);

        `uvm_info(get_name(), {"Programmed TLP Type:\n",
                                "\t", $sformatf("Write TLP Type               = 0x%x,",
                                    csr_cfg.wr_tlp_type), "\n",
                                "\t", $sformatf("Write Format[1]              = 0x%x,",
                                    csr_cfg.wr_fmt_1), "\n",
                                "\t", $sformatf("Read TLP Type                = 0x%x,",
                                    csr_cfg.rd_tlp_type), "\n",
                                "\t", $sformatf("Read Format[1]               = 0x%x",
                                    csr_cfg.rd_fmt_1), "\n"
                            }, UVM_MEDIUM)

    endtask

endclass
