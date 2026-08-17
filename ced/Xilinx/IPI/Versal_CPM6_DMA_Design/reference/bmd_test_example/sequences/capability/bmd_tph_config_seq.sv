//==============================================================================
// bmd_tph_config_seq.sv - BMD TPH Configuration Sequence
//==============================================================================
// Programs TPH (TLP Processing Hints) extended capability
//==============================================================================

class bmd_tph_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_tph_config_seq_c)

    function new(string name = "bmd_tph_config_seq");
        super.new(name);
    endfunction

    virtual task body();
        apci_cap_tph tph_cap;
        int err;
        logic [1:0] expected_req_en;

        tph_cap = new();
        tph_cap.configure();

        ///////////////////////////////////////////////////////////////////
        // [Read] TPH Capability

            // Device Specific Mode Supported
        env.shim.vip.read_capability(pdev_ep.bdf, tph_cap,
            tph_cap.device_specific_mode_sup.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading TPH capability - device specific mode")

            // Extended TPH Requester Supported
        env.shim.vip.read_capability(pdev_ep.bdf, tph_cap,
            tph_cap.extended_tph_requester_sup.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading TPH capability - extended requester")

            // ST Table Location
        env.shim.vip.read_capability(pdev_ep.bdf, tph_cap,
            tph_cap.st_table_location.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading TPH capability - ST Table location")

            // ST Table Size
        env.shim.vip.read_capability(pdev_ep.bdf, tph_cap,
            tph_cap.st_table_size.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading TPH capability - ST Table Size")

        ///////////////////////////////////////////////////////////////////
        // [Read] TPH Control

            // ST Mode Select
        env.shim.vip.read_capability(pdev_ep.bdf, tph_cap,
            tph_cap.st_mode_select.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading TPH capability - ST Mode")

            // TPH Requester Enable
        env.shim.vip.read_capability(pdev_ep.bdf, tph_cap,
            tph_cap.tph_requester_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading TPH capability - TPH Requester")

        ///////////////////////////////////////////////////////////////////
        // [Set] TPH Control

        if (tph_cap.device_specific_mode_sup.v && cap_cfg.cfg_tph_en == 1'b1) begin
                // ST Mode Select
                `uvm_info(get_type_name(), " [CFG] was able to set ST Mode Select", UVM_LOW)
            tph_cap.st_mode_select.set_v(3'b010);
                // Requester Enable
            if (tph_cap.extended_tph_requester_sup.v && cap_cfg.cfg_tph_ext_en == 1'b1) begin
                `uvm_info(get_type_name(), " [CFG] was able to set requester enable ", UVM_LOW)
                tph_cap.tph_requester_enable.set_v(2'b11);
            end else begin
                `uvm_info(get_type_name(), " [CFG] Issue, was not able requester enable ", UVM_LOW)
                tph_cap.tph_requester_enable.set_v(2'b01);
                cap_cfg.cfg_tph_ext_en = 1'b0;
            end
        end else begin
            // Cant perform test
            `uvm_info(get_type_name(), " [CFG] Issue, could not peform tests and set ST Mode Select and requester enable ", UVM_LOW)
            cap_cfg.cfg_tph_en = 1'b0;
            cap_cfg.cfg_tph_ext_en = 1'b0;
        end

        ///////////////////////////////////////////////////////////////////
        // [Write] TPH Control

            // ST Mode Select
        env.shim.vip.write_capability(pdev_ep.bdf, tph_cap,
            tph_cap.st_mode_select.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error writing TPH capability - ST Mode Select")

            // Requester Enable
        env.shim.vip.write_capability(pdev_ep.bdf, tph_cap,
            tph_cap.tph_requester_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error writing TPH capability - Requester Enable ")

        ///////////////////////////////////////////////////////////////////
        // [Verify] TPH Control

            // ST Mode Select
        env.shim.vip.read_capability(pdev_ep.bdf, tph_cap,
            tph_cap.st_mode_select.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading TPH capability ST Mode Select - read back")
        if (tph_cap.device_specific_mode_sup.v && cap_cfg.cfg_tph_en == 1'b1) begin
            if(tph_cap.st_mode_select.v != 3'b010)
                `uvm_error(get_type_name(), $sformatf(
                    " [CFG] st_mode_select readback mismatch: expected=0x%0x actual=0x%0x",
                    3'b010, tph_cap.st_mode_select.v))
        end

            // Requester Enable
        env.shim.vip.read_capability(pdev_ep.bdf, tph_cap,
            tph_cap.tph_requester_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading TPH capability - Requester Enable - read back")
        if (tph_cap.device_specific_mode_sup.v && cap_cfg.cfg_tph_en == 1'b1) begin
            expected_req_en = (tph_cap.extended_tph_requester_sup.v && cap_cfg.cfg_tph_ext_en == 1'b1) ? 2'b11 : 2'b01;
            if(tph_cap.tph_requester_enable.v != expected_req_en)
                `uvm_error(get_type_name(), $sformatf(
                    " [CFG] tph_requester_enable readback mismatch: expected=0x%0x actual=0x%0x",
                    expected_req_en, tph_cap.tph_requester_enable.v))
        end

        `uvm_info(get_name(), {"Programmed TPH:\n",
                                "\t", $sformatf("ST Mode Select               = 0x%x,",
                                    tph_cap.st_mode_select.v), "\n",
                                "\t", $sformatf("Requester Enable             = 0x%x",
                                    tph_cap.tph_requester_enable.v), "\n"
                                }, UVM_MEDIUM)
    endtask

endclass
