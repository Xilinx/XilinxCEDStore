//==============================================================================
// bmd_out_of_range_read_seq.sv - BMD Out-of-Range CSR Read Sequence
//==============================================================================
// Reads an invalid CSR address to generate Unsupported Request
//==============================================================================

class bmd_out_of_range_read_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_out_of_range_read_seq_c)

    //--------------------------------------------------------------------------
    // Configuration
    //--------------------------------------------------------------------------
    rand bit [6:0] out_of_range_addr;

    constraint out_of_range_c {
        // Max CSR address from bmd mem pkg
        out_of_range_addr > MAX_CSR;
    }

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_out_of_range_read_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit [31:0] rd_data;

        // Perform out-of-range CSR read
        issue_csr_read(out_of_range_addr, rd_data);

        `uvm_info(get_name(), $sformatf("Performed out-of-range CSR read: addr=0x%h", out_of_range_addr), UVM_MEDIUM)

    endtask

endclass
