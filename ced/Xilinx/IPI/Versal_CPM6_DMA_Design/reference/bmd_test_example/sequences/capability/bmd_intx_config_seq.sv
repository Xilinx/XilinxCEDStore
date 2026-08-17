//==============================================================================
// bmd_intx_config_seq.sv - BMD INTx Configuration Sequence
//==============================================================================
// Programs INTx disable bit in Type 0 configuration header (Command Register)
//==============================================================================

class bmd_intx_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_intx_config_seq_c)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_intx_config_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        apci_cap_type0 type0_cap;
        int err;

        // Create and configure Type 0 capability structure
        type0_cap = new();
        type0_cap.configure();

        ///////////////////////////////////////////////////////////////////
        // [Read] Interrupt Disable
        env.shim.vip.read_capability(pdev_ep.bdf, type0_cap,
            type0_cap.interrupt_disable.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error reading Type 0 capability")

        // [Set] Interrupt Disable
        type0_cap.interrupt_disable.set_v(cap_cfg.cfg_int_disable);

        // [Write] Interrupt Disable
        env.shim.vip.write_capability(pdev_ep.bdf, type0_cap,
            type0_cap.interrupt_disable.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error writing Type 0 capability")

        // [Verify] Interrupt Disable
        env.shim.vip.read_capability(pdev_ep.bdf, type0_cap,
            type0_cap.interrupt_disable.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error reading Type 0 capability")
        if (type0_cap.interrupt_disable.v != cap_cfg.cfg_int_disable)
            `uvm_error(get_name(), " [CFG] Failed to write Type 0 interrupt disable")

        ///////////////////////////////////////////////////////////////////
        // Summary
        `uvm_info(get_name(), {"Programmed INTx:\n",
                                "\t", $sformatf("Interrupt disable            = 0x%x",
                                    cap_cfg.cfg_int_disable), "\n"}, UVM_MEDIUM)
    endtask

endclass
