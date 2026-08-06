//==============================================================================
// bmd_reset_seq.sv - BMD Reset Sequence
//==============================================================================
// Controls BMD reset via DCSR1 register
// - Assert reset (set bit)
// - Deassert reset (clear bit)
//==============================================================================

class bmd_reset_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_reset_seq_c)

    //--------------------------------------------------------------------------
    // Configuration
    //--------------------------------------------------------------------------
    rand bit assert_reset;      // 1 = assert reset, 0 = deassert reset
    rand int reset_cycles;      // Number of cycles to hold reset (if asserting)

    constraint reset_cycles_c {
        reset_cycles inside {[2:100]};
    }

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_reset_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] dcsr1_data;

        if (assert_reset) begin
            // Assert BMD reset
            issue_csr_write(DCSR1, 32'h0000_0001);
            `uvm_info(get_name(), $sformatf("BMD reset asserted for %0d cycles", reset_cycles), UVM_MEDIUM)

            // Hold reset for specified cycles
            #(reset_cycles * 2.6ns);

        end else begin
            // Deassert BMD reset
            issue_csr_write(DCSR1, 32'h0000_0000);
            `uvm_info(get_name(), "BMD reset deasserted", UVM_MEDIUM)
        end

    endtask

endclass
