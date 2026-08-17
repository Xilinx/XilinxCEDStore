//==============================================================================
// bmd_10b_tag_config_seq.sv - BMD 10-bit Tag Configuration Sequence
//==============================================================================
// Programs 10-bit tag requester enable in PCIe Device Control 2 register
// Also programs Max Payload Size (MPS)
//==============================================================================

class bmd_10b_tag_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_10b_tag_config_seq_c)

    bit [2:0] set_mps = 3'b011;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_10b_tag_config_seq");
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
        // [Read] 10-bit tag requester enable
        env.shim.vip.read_capability(pdev_ep.bdf, pcie_cap,
            pcie_cap.ten_bit_tag_requester_enable.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error reading PCIe capability")

        // [Set] 10-bit tag requester enable
        pcie_cap.ten_bit_tag_requester_enable.set_v(cap_cfg.cfg_10b_tag_req_en);

        // [Write] 10-bit tag requester enable
        env.shim.vip.write_capability(pdev_ep.bdf, pcie_cap,
            pcie_cap.ten_bit_tag_requester_enable.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error writing PCIe capability")

        // [Verify] 10-bit tag requester enable
        env.shim.vip.read_capability(pdev_ep.bdf, pcie_cap,
            pcie_cap.ten_bit_tag_requester_enable.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error reading PCIe capability")
        if (pcie_cap.ten_bit_tag_requester_enable.v != cap_cfg.cfg_10b_tag_req_en)
            `uvm_error(get_name(), " [CFG] Failed to write PCIe 10-bit tag field")

        ///////////////////////////////////////////////////////////////////
        // [Read] Max Payload Size
        env.shim.vip.read_capability(pdev_ep.bdf, pcie_cap,
            pcie_cap.max_payload_size.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error reading PCIe capability")

        // [Set] Max Payload Size
        pcie_cap.max_payload_size.set_v(set_mps);

        // [Write] Max Payload Size
        env.shim.vip.write_capability(pdev_ep.bdf, pcie_cap,
            pcie_cap.max_payload_size.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error writing PCIe capability")

        // [Verify] Max Payload Size
        env.shim.vip.read_capability(pdev_ep.bdf, pcie_cap,
            pcie_cap.max_payload_size.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error reading PCIe capability")

        if (pcie_cap.max_payload_size.v != set_mps)
            `uvm_error(get_name(), " [CFG] Failed to write EP MPS field")

        ///////////////////////////////////////////////////////////////////
        // [Program RP MPS to match EP] - prevents MPS violation errors
        env.shim.vip.read_capability(pdev_rp.bdf, pcie_cap,
            pcie_cap.max_payload_size.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error reading RP PCIe capability")

        pcie_cap.max_payload_size.set_v(set_mps);

        env.shim.vip.write_capability(pdev_rp.bdf, pcie_cap,
            pcie_cap.max_payload_size.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error writing RP PCIe capability")

        env.shim.vip.read_capability(pdev_rp.bdf, pcie_cap,
            pcie_cap.max_payload_size.get_offset_dw, err);
        if (err)
            `uvm_error(get_name(), " [CFG] Error reading RP PCIe capability")
        if (pcie_cap.max_payload_size.v != set_mps)
            `uvm_error(get_name(), " [CFG] Failed to write RP MPS field")

        ///////////////////////////////////////////////////////////////////
        // Summary
        `uvm_info(get_name(), {"Programmed 10-bit Tag:\n",
                                "\t", $sformatf("10b Request Enable           = 0x%x,",
                                    cap_cfg.cfg_10b_tag_req_en), "\n",
                                "\t", $sformatf("Max Payload Size             = 0x%x",
                                    set_mps), "\n"}, UVM_MEDIUM)
    endtask

endclass
