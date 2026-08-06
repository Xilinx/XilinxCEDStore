//==============================================================================
// bmd_read_tlp_format_seq.sv - BMD Read TLP Format Configuration Sequence
//==============================================================================
// Programs BMD read TLP format CSRs:
// - RDMATLPP: Read DMA TLP Pattern
// - RDMATLPA: Read DMA TLP Address
// - RDMATLPS: Read DMA TLP Size/Control
// - RDMATLPUA: Read DMA TLP Upper Address
// - RDMATLPC: Read DMA TLP Count
//==============================================================================

class bmd_read_tlp_format_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_read_tlp_format_seq_c)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_read_tlp_format_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] rdmatlps_data;
        bit [31:0] rdmatlpc_data;

        // Build RDMATLPS register value
        rdmatlps_data = {
            csr_cfg.st[7:0],        // Read DMA Steering Tag          [31:24]
            cap_cfg.cfg_tph_en,     // Read DMA TPH Enable            [23]
            csr_cfg.ph,             // Read DMA Processing Hints      [22:21]
            csr_cfg.rd_td,          // Read DMA TD                    [20]
            csr_cfg.r64_en,         // 64-bit Read TLP Enable         [19]
            csr_cfg.rd_tc,          // Read DMA TLP TC                [18:16]
            csr_cfg.rd_poisoned,    // Read DMA Poisoned TLP          [15]
            csr_cfg.rd_ats,         // Read DMA ATS                   [14:13]
            csr_cfg.rd_no_write,    // Read DMA No-Write              [12]
            csr_cfg.rd_t_bit,       // Read DMA T Bit                 [11]
            csr_cfg.rd_size         // Read DMA TLP Size              [10:0]
        };

        // Build RDMATLPC register value
        rdmatlpc_data = {
            csr_cfg.rd_inc_addr,    // Increment address              [31]
            15'd0,                  // Reserved                       [30:16]
            csr_cfg.rd_count        // Read DMA TLP Count             [15:0]
        };

        // Program read TLP format CSRs
        issue_csr_write(RDMATLPP, csr_cfg.rd_pattern);
        issue_csr_write(RDMATLPA, csr_cfg.rd_addr);
        issue_csr_write(RDMATLPS, rdmatlps_data);
        issue_csr_write(RDMATLPUA, csr_cfg.rd_uaddr);
        issue_csr_write(RDMATLPC, rdmatlpc_data);

        `uvm_info(get_name(), {"Programmed Read TLP:\n",
                                "\t", $sformatf("TLP Count                    = 0x%x,",
                                    csr_cfg.rd_count), "\n",
                                "\t", $sformatf("TLP Size (DW)                = 0x%x,",
                                    csr_cfg.rd_size), "\n",
                                "\t", $sformatf("64-bit Enable                = 0x%x,",
                                    csr_cfg.r64_en), "\n",
                                "\t", $sformatf("Increment Address            = 0x%x,",
                                    csr_cfg.rd_inc_addr), "\n",
                                "\t", $sformatf("TPH Enable                   = 0x%x,",
                                    cap_cfg.cfg_tph_en), "\n",
                                "\t", $sformatf("Processing Hints             = 0x%x,",
                                    csr_cfg.ph), "\n",
                                "\t", $sformatf("Steering Tag                 = 0x%x,",
                                    csr_cfg.st[7:0]), "\n",
                                "\t", $sformatf("TD                           = 0x%x,",
                                    csr_cfg.rd_td), "\n",
                                "\t", $sformatf("TC                           = 0x%x,",
                                    csr_cfg.rd_tc), "\n",
                                "\t", $sformatf("Poisoned                     = 0x%x,",
                                    csr_cfg.rd_poisoned), "\n",
                                "\t", $sformatf("ATS                          = 0x%x,",
                                    csr_cfg.rd_ats), "\n",
                                "\t", $sformatf("No Write                     = 0x%x,",
                                    csr_cfg.rd_no_write), "\n",
                                "\t", $sformatf("T-bit                        = 0x%x",
                                    csr_cfg.rd_t_bit), "\n"
                                }, UVM_MEDIUM)

    endtask

endclass
