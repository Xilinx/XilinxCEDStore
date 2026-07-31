//==============================================================================
// bmd_write_tlp_format_seq.sv - BMD Write TLP Format Configuration Sequence
//==============================================================================
// Programs BMD write TLP format CSRs:
// - WDMATLPA: Write DMA TLP Address
// - WDMATLPS: Write DMA TLP Size/Control
// - WDMATLPUA: Write DMA TLP Upper Address
// - WDMATLPC: Write DMA TLP Count
// - WDMATLPP: Write DMA TLP Pattern
//==============================================================================

class bmd_write_tlp_format_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_write_tlp_format_seq_c)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_write_tlp_format_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] wdmatlps_data;
        bit [31:0] wdmatlpc_data;

        // Build WDMATLPS register value
        wdmatlps_data = {
            csr_cfg.st[7:0],        // Write DMA Steering Tag         [31:24]
            cap_cfg.cfg_tph_en,     // Write DMA TPH Enable           [23]
            csr_cfg.ph,             // Write DMA Processing Hints     [22:21]
            csr_cfg.wr_td,          // Write DMA TD                   [20]
            csr_cfg.w64_en,         // 64-bit Write TLP Enable        [19]
            csr_cfg.wr_tc,          // Write DMA TLP TC               [18:16]
            csr_cfg.wr_poisoned,    // Write DMA Poisoned TLP         [15]
            csr_cfg.wr_ats,         // Write DMA ATS                  [14:13]
            csr_cfg.wr_no_write,    // Write DMA No-Write             [12]
            csr_cfg.wr_t_bit,       // Write DMA T Bit                [11]
            csr_cfg.wr_size         // Write DMA TLP Size             [10:0]
        };

        // Build WDMATLPC register value
        wdmatlpc_data = {
            csr_cfg.wr_inc_addr,    // Increment address              [31]
            csr_cfg.wr_tid,         // Transaction ID                 [30:20]
            5'd0,                   // Reserved                       [19:15]
            csr_cfg.wr_count        // Write DMA TLP Count            [15:0]
        };

        // Program write TLP format CSRs
        issue_csr_write(WDMATLPA,  csr_cfg.wr_addr);
        issue_csr_write(WDMATLPS,  wdmatlps_data);
        issue_csr_write(WDMATLPUA, csr_cfg.wr_uaddr);
        issue_csr_write(WDMATLPC,  wdmatlpc_data);
        issue_csr_write(WDMATLPP,  csr_cfg.wr_pattern);

        `uvm_info(get_name(), {"Programmed Write TLP:\n",
                                "\t", $sformatf("TLP Count                    = 0x%x,",
                                    csr_cfg.wr_count), "\n",
                                "\t", $sformatf("TLP Size (DW)                = 0x%x,",
                                    csr_cfg.wr_size), "\n",
                                "\t", $sformatf("64-bit Enable                = 0x%x,",
                                    csr_cfg.w64_en), "\n",
                                "\t", $sformatf("Increment Address            = 0x%x,",
                                    csr_cfg.wr_inc_addr), "\n",
                                "\t", $sformatf("TPH Enable                   = 0x%x,",
                                    cap_cfg.cfg_tph_en), "\n",
                                "\t", $sformatf("Processing Hints             = 0x%x,",
                                    csr_cfg.ph), "\n",
                                "\t", $sformatf("Steering Tag                 = 0x%x,",
                                    csr_cfg.st[7:0]), "\n",
                                "\t", $sformatf("TD                           = 0x%x,",
                                    csr_cfg.wr_td), "\n",
                                "\t", $sformatf("TC                           = 0x%x,",
                                    csr_cfg.wr_tc), "\n",
                                "\t", $sformatf("Poisoned                     = 0x%x,",
                                    csr_cfg.wr_poisoned), "\n",
                                "\t", $sformatf("ATS                          = 0x%x,",
                                    csr_cfg.wr_ats), "\n",
                                "\t", $sformatf("No Write                     = 0x%x,",
                                    csr_cfg.wr_no_write), "\n",
                                "\t", $sformatf("T-bit                        = 0x%x",
                                    csr_cfg.wr_t_bit), "\n"
                                }, UVM_MEDIUM)

    endtask

endclass
