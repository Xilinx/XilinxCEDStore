//==============================================================================
// bmd_msix_config_seq.sv - BMD MSI-X Configuration Sequence
//==============================================================================
// Programs MSI-X capability and table entries via BAR MMIO
//==============================================================================

class bmd_msix_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_msix_config_seq_c)

    function new(string name = "bmd_msix_config_seq");
        super.new(name);
    endfunction

    virtual task body();
        apci_cap_msix msix_cap;
        bit [63:0] addr;
        bit [31:0] data;
        int err;

        addr = '0;
        err = '0;

        msix_cap = new();
        msix_cap.configure();

        ///////////////////////////////////////////////////////////////////
        // [Read] MSI-X capability

            // Read Table Size
        env.shim.vip.read_capability(pdev_ep.bdf, msix_cap,
            msix_cap.table_size.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading MSI-X capability")

            // Read Function Mask
        env.shim.vip.read_capability(pdev_ep.bdf, msix_cap,
            msix_cap.function_mask.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading MSI-X capability")

            // Read MSI-X Enable
        env.shim.vip.read_capability(pdev_ep.bdf, msix_cap,
            msix_cap.msi_x_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading MSI-X capability")

            // Read Table BIR
        env.shim.vip.read_capability(pdev_ep.bdf, msix_cap,
            msix_cap.table_bir.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading MSI-X capability")

            // Read Table Offset
        env.shim.vip.read_capability(pdev_ep.bdf, msix_cap,
            msix_cap.table_offset.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading MSI-X capability")

        ///////////////////////////////////////////////////////////////////
        // [Set] MSI-X Capability
        if (cap_cfg.cfg_msix_en) begin
            msix_cap.msi_x_enable.set_v(1'b1);
        end else begin
            msix_cap.msi_x_enable.set_v(1'b0);
        end

        env.shim.vip.write_capability(pdev_ep.bdf, msix_cap,
            msix_cap.msi_x_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading MSI-X capability")

        ///////////////////////////////////////////////////////////////////
        // [Verify] MSI-X Capability
        env.shim.vip.read_capability(pdev_ep.bdf, msix_cap,
            msix_cap.msi_x_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading MSI-X capability")
        if (msix_cap.msi_x_enable.v != cap_cfg.cfg_msix_en)
            `uvm_error(get_type_name(), " [CFG] Failed to write MSI-X enable field")

        ///////////////////////////////////////////////////////////////////
        // Program MSI-X Table
        if (cap_cfg.cfg_msix_en) begin
            if (!std::randomize(csr_cfg.msix_wr_vec) with {
                csr_cfg.msix_wr_vec < msix_cap.table_size.v;
            })
                `uvm_error(get_type_name(), " [CFG] Failed to re-randomize msix write vector")

            if (!std::randomize(csr_cfg.msix_rd_vec) with {
                csr_cfg.msix_rd_vec < msix_cap.table_size.v;
                csr_cfg.msix_rd_vec != csr_cfg.msix_wr_vec;
            })
                `uvm_error(get_type_name(), " [CFG] Failed to re-randomize msix read vector")

            data = '0;

            // ****************************************************************************

            // Write MSI-X Address
            addr = pdev_ep.membar[msix_cap.table_bir.v].base +
                   {msix_cap.table_offset.v, 3'b000} + (16 * csr_cfg.msix_wr_vec);
            data = cap_cfg.cfg_msix_addr[31:0];
            issue_addr_write(addr, data);

            // Write MSI-X Upper Address
            data = cap_cfg.cfg_msix_addr[63:32];
            issue_addr_write(addr + 4, data);

            // Write MSI-X Data
            data = cap_cfg.cfg_msix_data_wr;
            issue_addr_write(addr + 8, data);

            // Write MSI-X Vector Control
            data = '0;
            issue_addr_write(addr + 12, data);

            // Read MSI-X Address
            addr = pdev_ep.membar[msix_cap.table_bir.v].base +
                   {msix_cap.table_offset.v, 3'b000} + (16 * csr_cfg.msix_rd_vec);
            data = cap_cfg.cfg_msix_addr[31:0];
            issue_addr_write(addr, data);

            // Read MSI-X Upper Address
            data = cap_cfg.cfg_msix_addr[63:32];
            issue_addr_write(addr + 4, data);

            // Read MSI-X Data
            data = cap_cfg.cfg_msix_data_rd;
            issue_addr_write(addr + 8, data);

            // Read MSI-X Vector Control
            data = '0;
            issue_addr_write(addr + 12, data);

            // ****************************************************************************

            // Check Write MSI-X Setup
            addr = pdev_ep.membar[msix_cap.table_bir.v].base +
                    {msix_cap.table_offset.v, 3'b000} + (16 * csr_cfg.msix_wr_vec);

            // Verify Lower Write MSI-X Address
            issue_addr_read(addr, data);
            if (data != cap_cfg.cfg_msix_addr[31:0])
                `uvm_error(get_type_name(), " [CFG] Failed to write MSI-X address field")

            // Verify Upper Write MSI-X Address
            addr = addr + 4;
            issue_addr_read(addr, data);
            if (data != cap_cfg.cfg_msix_addr[63:32])
                `uvm_error(get_type_name(), " [CFG] Failed to write MSI-X upper address field")

            // Verify Write MSI-X Data
            addr = addr + 4;
            issue_addr_read(addr, data);
            if (data != cap_cfg.cfg_msix_data_wr)
                `uvm_error(get_type_name(), " [CFG] Failed to write MSI-X data field")

            // Verify Write MSI-X Vector Control
            addr = addr + 4;
            issue_addr_read(addr, data);
            if (data != '0)
                `uvm_error(get_type_name(), " [CFG] Failed to write MSI-X vector control field")

            // ****************************************************************************

            // Check Read MSI-X Setup
            addr = pdev_ep.membar[msix_cap.table_bir.v].base +
                {msix_cap.table_offset.v, 3'b000} + (16 * csr_cfg.msix_rd_vec);

            // Verify Lower Read MSI-X Address
            issue_addr_read(addr, data);
            if (data != cap_cfg.cfg_msix_addr[31:0])
                `uvm_error(get_type_name(), " [CFG] Failed to write MSI-X address field")

            // Verify Upper Read MSI-X Address
            addr = addr + 4;
            issue_addr_read(addr, data);
            if (data != cap_cfg.cfg_msix_addr[63:32])
                `uvm_error(get_type_name(), " [CFG] Failed to write MSI-X upper address field")

            // Verify Read MSI-X Data
            addr = addr + 4;
            issue_addr_read(addr, data);
            if (data != cap_cfg.cfg_msix_data_rd)
                `uvm_error(get_type_name(), " [CFG] Failed to write MSI-X data field")

            // Verify Read MSI-X Vector Control
            addr = addr + 4;
            issue_addr_read(addr, data);
            if (data != '0)
                `uvm_error(get_type_name(), " [CFG] Failed to write MSI-X vector control field")
        end

        `uvm_info(get_name(), {"Programmed MSI-X:\n",
                                "\t", $sformatf("Enable                       = 0x%x,",
                                                    msix_cap.msi_x_enable.v), "\n",
                                "\t", $sformatf("Table BIR                    = 0x%x,",
                                                    msix_cap.table_bir.v), "\n",
                                "\t", $sformatf("Table Offset                 = 0x%x,",
                                                    msix_cap.table_offset.v), "\n",
                                "\t", $sformatf("Address                      = 0x%x,",
                                                    cap_cfg.cfg_msix_addr), "\n",
                                "\t", $sformatf("Read Data                    = 0x%x,",
                                                    cap_cfg.cfg_msix_data_rd), "\n",
                                "\t", $sformatf("Write Data                   = 0x%x",
                                                    cap_cfg.cfg_msix_data_wr), "\n"
                                }, UVM_MEDIUM)
    endtask

endclass
