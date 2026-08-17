//==============================================================================
// bmd_vsec_config_seq.sv - BMD VSEC Configuration Sequence
//==============================================================================
// Programs VSEC (Vendor Specified Extended Capability) with random data
//==============================================================================

class bmd_vsec_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_vsec_config_seq_c)

    logic [31:0]    VSEC_BASE = 'hD00;

    bit [31:0]    rd_data;
    bit [31:0]    wr_data;
    bit           err;

    function new(string name = "bmd_vsec_config_seq");
        super.new(name);
    endfunction

    virtual task body();
        pcie_ecapid_e vsec = ECAP_VENDOR;

        for (int unsigned i = 0; i < 10; i++) begin
            // Read initial value in VSEC control register
            env.shim.api.read_cap_dw(pdev_ep.bdf, .ecap(vsec), .offset(3), .data(rd_data), .err(err));
            if (err) `uvm_error(get_type_name(), $sformatf("Failed VSEC pre-read on iteration %01d", i))

            // Choose any other value to write
            std::randomize(wr_data) with {
                wr_data != rd_data;
            };

            // Write new value
            env.shim.api.write_cap_dw(pdev_ep.bdf, .ecap(vsec), .offset(3), .data(wr_data), .err(err));
            if (err) `uvm_error(get_type_name(), $sformatf("Failed VSEC write on iteration %01d", i))

            // Read again and check for new value
            env.shim.api.read_cap_dw(pdev_ep.bdf, .ecap(vsec), .offset(3), .data(rd_data), .err(err));
            if (err) `uvm_error(get_type_name(), $sformatf("Failed VSEC read on iteration %01d", i))
            if (rd_data != wr_data) `uvm_error(get_type_name(),
                $sformatf("Failed comparison (rd_data /= wr_data): 0x%x /= 0x%x",
                            rd_data, wr_data))

            // Read other vsec registers (no checks, just looking for successful reads)
            env.shim.api.read_cap_dw(pdev_ep.bdf, .ecap(vsec), .offset(0), .data(rd_data), .err(err));
            if (err) `uvm_error(get_type_name(), $sformatf("Failed VSEC EXT CAP read on iteration %01d", i))
            env.shim.api.read_cap_dw(pdev_ep.bdf, .ecap(vsec), .offset(1), .data(rd_data), .err(err));
            if (err) `uvm_error(get_type_name(), $sformatf("Failed VSEC (VSEC) read on iteration %01d", i))
            env.shim.api.read_cap_dw(pdev_ep.bdf, .ecap(vsec), .offset(2), .data(rd_data), .err(err));
            if (err) `uvm_error(get_type_name(), $sformatf("Failed VSEC STATUS read on iteration %01d", i))
        end
    endtask

endclass
