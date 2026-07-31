//==============================================================================
// bmd_ext_tag_config_seq.sv - BMD Extended Tag Configuration Sequence
//==============================================================================
// Programs extended tag field enable in PCIe Device Control register
//==============================================================================

class bmd_ext_tag_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_ext_tag_config_seq_c)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_ext_tag_config_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        apci_cap_pcie pcie_cap;
        int err;

        // Create and configure PCIe capability structure
        pcie_cap = new();
        pcie_cap.configure();

        ///////////////////////////////////////////////////////////////////
        // [Read] Extended Tag Field
        env.shim.vip.read_capability(pdev_ep.bdf, pcie_cap,
            pcie_cap.extended_tag_field_enable.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error reading PCIe capability")

        // [Set] Extended Tag Field
        pcie_cap.extended_tag_field_enable.set_v(cap_cfg.cfg_ext_tag_en);

        // [Write] Extended Tag Field
        env.shim.vip.write_capability(pdev_ep.bdf, pcie_cap,
            pcie_cap.extended_tag_field_enable.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error writing PCIe capability")

        // [Verify] Extended Tag Field
        env.shim.vip.read_capability(pdev_ep.bdf, pcie_cap,
            pcie_cap.extended_tag_field_enable.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error reading PCIe capability")
        if (pcie_cap.extended_tag_field_enable.v != cap_cfg.cfg_ext_tag_en)
            `uvm_error(get_name(), " [CFG] Failed to write PCIe extended tag field")

        ///////////////////////////////////////////////////////////////////
        // Summary
        `uvm_info(get_name(), {"Programmed Extended Tag:\n",
                                "\t", $sformatf("Extended Tag Enable          = 0x%x",
                                    cap_cfg.cfg_ext_tag_en), "\n"}, UVM_MEDIUM)

    endtask

endclass
