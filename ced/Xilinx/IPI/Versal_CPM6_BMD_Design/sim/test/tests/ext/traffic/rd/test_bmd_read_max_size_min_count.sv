//==============================================================================
// test_bmd_read_max_size_min_count.sv - Read Traffic BMD Tests
//==============================================================================
// Description:
//   BMD test that creates 1 read of 1024 DW length
//==============================================================================

class test_bmd_read_max_size_min_count extends test_bmd;
    `uvm_component_utils(test_bmd_read_max_size_min_count)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_read_max_size_min_count", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        csr_cfg.wr_start = 1'b0;
        csr_cfg.rd_start = 1'b1;

        csr_cfg.rd_size = 9'h100;
        csr_cfg.rd_count = 16'h0001;

        // Prevent Boundary Crossing
        csr_cfg.rd_addr[10:0] = '0;

        if (csr_cfg.rd_upper_be == 4'b0000) begin
            csr_cfg.rd_upper_be = 4'b1111;
        end

        if (csr_cfg.rd_lower_be == 4'b0000) begin
            csr_cfg.rd_lower_be = 4'b1111;
        end

    endtask

endclass : test_bmd_read_max_size_min_count
