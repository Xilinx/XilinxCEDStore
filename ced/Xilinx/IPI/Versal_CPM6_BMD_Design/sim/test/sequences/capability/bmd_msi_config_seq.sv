//==============================================================================
// bmd_msi_config_seq.sv - BMD MSI Configuration Sequence
//==============================================================================
// Programs MSI capability including address, data, multi-message, and masking
//==============================================================================

class bmd_msi_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_msi_config_seq_c)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_msi_config_seq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        apci_cap_msi msi_cap;
        bit [31:0] mask;
        int err;

        mask = '0;
        err = '0;

        // Create and configure MSI capability structure
        msi_cap = new();
        msi_cap.configure();

        ///////////////////////////////////////////////////////////////////
        // Read capability registers and reconfigure
            // MSI Enable
        env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
            msi_cap.msi_enable.get_offset_dw, err);
            // Multi Message Capable
        env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
            msi_cap.multi_msg_cap.get_offset_dw, err);
            // Multi Message Enable
        env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
            msi_cap.multi_msg_enable.get_offset_dw, err);
            // 64-bit Capable
        env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
            msi_cap.is_64_bit_cap.get_offset_dw, err);
            // Per Vector Masking Capable
        env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
            msi_cap.per_vec_mask_cap.get_offset_dw, err);
            // Extended Message Data Capable
        env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
            msi_cap.extend_msg_data_cap.get_offset_dw, err);
            // Extended Message Data Enable
        env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
            msi_cap.extend_msg_data_en.get_offset_dw, err);

        msi_cap.reconfig();

        ///////////////////////////////////////////////////////////////////
        // Read remaining features after reconfig
            // Read Message Address
        env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
            msi_cap.msg_addr_low.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
            // Read Message Upper Address
        if (msi_cap.is_64_bit_cap.v) begin
            env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
                msi_cap.msg_addr_high.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
        end
            // Read Message Data
        env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
            msi_cap.msg_data.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
            // Read Extended Message Data
        if (msi_cap.extend_msg_data_cap.v) begin
            env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
                msi_cap.extend_msg_data.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
        end
            // Read Mask
        if (msi_cap.per_vec_mask_cap.v) begin
            env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
                msi_cap.mask_bits.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
        end

        ///////////////////////////////////////////////////////////////////
        // Enable MSI Features
        if (cap_cfg.cfg_msi_en) begin
            // Set Enable MSI
            msi_cap.msi_enable.set_v(1'b1);

            // Set Write Interrupt Select
            if (csr_cfg.wr_int_sel == 2'b01) begin
                csr_cfg.msix_wr_vec = '0;
                csr_cfg.msix_wr_vec[4:0] = $urandom_range(0, (1 << msi_cap.multi_msg_cap.v) - 1);
                while (csr_cfg.msix_rd_vec[4:0] == csr_cfg.msix_wr_vec[4:0]) begin
                    csr_cfg.msix_wr_vec = '0;
                    csr_cfg.msix_wr_vec[4:0] = $urandom_range(0, (1 << msi_cap.multi_msg_cap.v) - 1);
                end
            end

            // Set Read Interrupt Select
            if (csr_cfg.rd_int_sel == 2'b01) begin
                csr_cfg.msix_rd_vec = '0;
                csr_cfg.msix_rd_vec[4:0] = $urandom_range(0, (1 << msi_cap.multi_msg_cap.v) - 1);
                while (csr_cfg.msix_rd_vec[4:0] == csr_cfg.msix_wr_vec[4:0]) begin
                    csr_cfg.msix_rd_vec = '0;
                    csr_cfg.msix_rd_vec[4:0] = $urandom_range(0, (1 << msi_cap.multi_msg_cap.v) - 1);
                end
            end

            // Set Multi-Message Enable
            msi_cap.multi_msg_enable.set_v(msi_cap.multi_msg_cap.v);
            msi_cap.reconfig();

            // Set Extended message data
            if (cap_cfg.cfg_msi_ext_data_en && msi_cap.extend_msg_data_cap.v) begin
                msi_cap.extend_msg_data_en.set_v(1'b1);
            end else begin
                msi_cap.extend_msg_data_en.set_v(1'b0);
                cap_cfg.cfg_msi_ext_data_en = 1'b0;
            end

            // Set address
            msi_cap.msg_addr_low.set_v(cap_cfg.cfg_msi_addr[31:2]);
            if (msi_cap.is_64_bit_cap.v) begin
                msi_cap.msg_addr_high.set_v(cap_cfg.cfg_msi_addr[63:32]);
            end else begin
                cap_cfg.cfg_msi_addr[63:32] = '0;
            end

            // Set MSI Data
            for (int i = 0; i < 32; i++) begin
                if (i < msi_cap.multi_msg_cap.v) begin
                    cap_cfg.cfg_msi_data[i] = 1'b0;
                end
            end
            msi_cap.msg_data.set_v(cap_cfg.cfg_msi_data[15:0]);

            // Set Extended Data
            if (cap_cfg.cfg_msi_ext_data_en) begin
                msi_cap.extend_msg_data.set_v(cap_cfg.cfg_msi_data[31:16]);
            end else begin
                cap_cfg.cfg_msi_data[31:16] = '0;
            end

            // Set Masks
            if (cap_cfg.cfg_msi_mask_vector && msi_cap.per_vec_mask_cap.v) begin
                mask[csr_cfg.msix_wr_vec[4:0]] = 1'b1;
                mask[csr_cfg.msix_rd_vec[4:0]] = 1'b1;
                msi_cap.mask_bits.set_v(mask);
            end else begin
                cap_cfg.cfg_msi_mask_vector = 1'b0;
            end
        end else begin
            msi_cap.msi_enable.set_v(1'b0);
        end

        ///////////////////////////////////////////////////////////////////
        // Write MSI Features
            // MSI Enable
        env.shim.vip.write_capability(pdev_ep.bdf, msi_cap,
            msi_cap.msi_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error writing MSI capability")

            // If MSI is Enabled
        if (cap_cfg.cfg_msi_en) begin
            // Multi Message Enable
            env.shim.vip.write_capability(pdev_ep.bdf, msi_cap,
                msi_cap.multi_msg_enable.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error writing MSI capability")

            // Extended Message Data Enable
            env.shim.vip.write_capability(pdev_ep.bdf, msi_cap,
                msi_cap.extend_msg_data_en.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error writing MSI capability")

            // Write Message Address
            env.shim.vip.write_capability(pdev_ep.bdf, msi_cap,
                msi_cap.msg_addr_low.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error writing MSI capability")

            // Write Message Upper Address
            if (msi_cap.is_64_bit_cap.v) begin
                env.shim.vip.write_capability(pdev_ep.bdf, msi_cap,
                    msi_cap.msg_addr_high.get_offset_dw, err);
                if(err)
                    `uvm_error(get_type_name(), " [CFG] Error writing MSI capability")
            end

            // Write Message Data
            env.shim.vip.write_capability(pdev_ep.bdf, msi_cap,
                msi_cap.msg_data.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error writing MSI capability")

            // Write Extended Message Data
            if (msi_cap.extend_msg_data_cap.v) begin
                env.shim.vip.write_capability(pdev_ep.bdf, msi_cap,
                    msi_cap.extend_msg_data.get_offset_dw, err);
                if(err)
                    `uvm_error(get_type_name(), " [CFG] Error writing MSI capability")
            end

            // Write Mask
            if (msi_cap.per_vec_mask_cap.v) begin
                env.shim.vip.write_capability(pdev_ep.bdf, msi_cap,
                    msi_cap.mask_bits.get_offset_dw, err);
                if(err)
                    `uvm_error(get_type_name(), " [CFG] Error writing MSI capability")
            end
        end


        ///////////////////////////////////////////////////////////////////
        // Verify all Settings

            // Verify MSI Enable
        env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
            msi_cap.msi_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
        if (msi_cap.msi_enable.v != cap_cfg.cfg_msi_en)
            `uvm_error(get_type_name(), " [CFG] Failed to write msi enable field")

        if (cap_cfg.cfg_msi_en) begin
                // Verify Multi Message Enable
            env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
                msi_cap.multi_msg_enable.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
            cap_cfg.cfg_multi_msg_en = msi_cap.multi_msg_enable.v;
            if (msi_cap.multi_msg_enable.v != msi_cap.multi_msg_cap.v)
                `uvm_error(get_type_name(), " [CFG] Failed to write multi msg enable field")

                // Verify Extended Message Data Enable
            env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
                msi_cap.extend_msg_data_en.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
            if (msi_cap.extend_msg_data_en.v != cap_cfg.cfg_msi_ext_data_en)
                `uvm_error(get_type_name(), " [CFG] Failed to write ext msg data enable field")

                // Verify Message Address
            env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
                msi_cap.msg_addr_low.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
            if (msi_cap.msg_addr_low.v != cap_cfg.cfg_msi_addr[31:2])
                `uvm_error(get_type_name(), " [CFG] Failed to write msi addr low field")

                // Verify Message Upper Address
            if (msi_cap.is_64_bit_cap.v) begin
                env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
                    msi_cap.msg_addr_high.get_offset_dw, err);
                if(err)
                    `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
                if (msi_cap.msg_addr_high.v != cap_cfg.cfg_msi_addr[63:32])
                    `uvm_error(get_type_name(), " [CFG] Failed to write msi addr high field")
            end

                // Verify Message Data
            env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
                msi_cap.msg_data.get_offset_dw, err);
            if(err)
                `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
            if (msi_cap.msg_data.v != cap_cfg.cfg_msi_data[15:0])
                `uvm_error(get_type_name(), " [CFG] Failed to write msi data field")

                // Verify Extended Message Data
            if (msi_cap.extend_msg_data_cap.v) begin
                env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
                    msi_cap.extend_msg_data.get_offset_dw, err);
                if(err)
                    `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
            end
            if (msi_cap.extend_msg_data_cap.v && cap_cfg.cfg_msi_ext_data_en) begin
                if (msi_cap.extend_msg_data.v != cap_cfg.cfg_msi_data[31:16])
                    `uvm_error(get_type_name(), " [CFG] Failed to write msi ext data field")
            end

                // Verify Mask register
            if (msi_cap.per_vec_mask_cap.v) begin
                env.shim.vip.read_capability(pdev_ep.bdf, msi_cap,
                    msi_cap.mask_bits.get_offset_dw, err);
                if(err)
                    `uvm_error(get_type_name(), " [CFG] Error reading MSI capability")
            end
            if (msi_cap.per_vec_mask_cap.v) begin
                if (msi_cap.mask_bits.v != mask)
                    `uvm_error(get_type_name(), " [CFG] Failed to write msi mask field")
            end
        end

        `uvm_info(get_name(), {"Programmed MSI:\n",
                                "\t", $sformatf("Enable                       = 0x%x,",
                                                    msi_cap.msi_enable.v), "\n",
                                "\t", $sformatf("Multi-Message Enable         = 0x%x,",
                                                    msi_cap.multi_msg_enable.v), "\n",
                                "\t", $sformatf("Extended Message Data Enable = 0x%x,",
                                                    msi_cap.extend_msg_data_en.v), "\n",
                                "\t", $sformatf("Address                      = 0x%x,",
                                                    {msi_cap.msg_addr_high.v, msi_cap.msg_addr_low.v}), "\n",
                                "\t", $sformatf("Data                         = 0x%x",
                                                    {msi_cap.extend_msg_data.v, msi_cap.msg_data.v}), "\n"
                                }, UVM_MEDIUM)
    endtask

endclass
