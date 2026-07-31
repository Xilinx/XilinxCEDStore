//==============================================================================
// bmd_start_traffic_seq.sv - BMD Start Traffic Sequence
//==============================================================================
// Programs DCSR2 register to start read and/or write traffic generation
//==============================================================================

class bmd_start_traffic_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_start_traffic_seq_c)

    // For Override
    bit read_relaxed_ordering = 1'b0;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_start_traffic_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] dcsr2_data;

        // Build DCSR2 register value
        dcsr2_data = {
            8'd0,                       // Reserved                   [31:24]
            csr_cfg.rd_int_disable,     // Read Interrupt Disable     [23]
            1'b0,                       // Reserved                   [22]
            read_relaxed_ordering,      // Read Relaxed Ordering   [21]
            4'd0,                       // Reserved                   [20:17]
            csr_cfg.rd_start,           // Read Start                 [16]
            csr_cfg.rd_int_sel,         // Read Interrupt Select      [15:14]
            3'd0,                       // Reserved                   [13:11]
            csr_cfg.wr_int_sel,         // Write Interrupt Select     [10:9]
            1'd0,                       // Reserved                   [8]
            csr_cfg.wr_int_disable,     // Write Interrupt Disable    [7]
            6'd0,                       // Reserved                   [6:1]
            csr_cfg.wr_start            // Write Start                [0]
        };

        // Program start CSR
        issue_csr_write(DCSR2, dcsr2_data);

        `uvm_info(get_name(), {"Started Traffic:\n",
                                "\t", $sformatf("Write Start                  = 0x%x,",
                                    csr_cfg.wr_start), "\n",
                                "\t", $sformatf("Read Start                   = 0x%x,",
                                    csr_cfg.rd_start), "\n",
                                "\t", $sformatf("Write Interrupt Select       = 0x%x,",
                                    csr_cfg.wr_int_sel), "\n",
                                "\t", $sformatf("Read Interrupt Select        = 0x%x,",
                                    csr_cfg.rd_int_sel), "\n",
                                "\t", $sformatf("Write Interrupt Disable      = 0x%x,",
                                    csr_cfg.wr_int_disable), "\n",
                                "\t", $sformatf("Read Interrupt Disable       = 0x%x",
                                    csr_cfg.rd_int_disable), "\n"
                                }, UVM_MEDIUM)

    endtask

endclass
