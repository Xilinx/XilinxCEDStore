//==============================================================================
// bmd_pasid_config_seq.sv - BMD PASID Configuration Sequence
//==============================================================================
// Programs PASID extended capability
//==============================================================================

class bmd_pasid_config_seq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_pasid_config_seq_c)

    function new(string name = "bmd_pasid_config_seq");
        super.new(name);
    endfunction

    virtual task body();
        apci_cap_pasid pasid_cap;
        int err;

        pasid_cap = new();
        pasid_cap.configure();

        ///////////////////////////////////////////////////////////////////
        // [Read] PASID Capability

            // EXE Permission Supported
        env.shim.vip.read_capability(pdev_ep.bdf, pasid_cap,
            pasid_cap.exe_permission_sup.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading PASID capability")

            // Privileged Mode Supported
        env.shim.vip.read_capability(pdev_ep.bdf, pasid_cap,
            pasid_cap.privileged_mode_sup.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading PASID capability")

            // Translated Req With PASID Supported
        env.shim.vip.read_capability(pdev_ep.bdf, pasid_cap,
            pasid_cap.translated_req_with_pasid_sup.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading PASID capability")

            // Max PASID Width
        env.shim.vip.read_capability(pdev_ep.bdf, pasid_cap,
            pasid_cap.max_pasid_width.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading PASID capability")

        // Adjust PASID based on max width supported
        for (int i = 0; i < 20; i++) begin
            if (i >= pasid_cap.max_pasid_width.get_v()) begin
                csr_cfg.pasid[i] = 1'b0;
            end
        end

        ///////////////////////////////////////////////////////////////////
        // [Set] PASID Control

            // PASID Enable
        pasid_cap.pasid_enable.set_v(cap_cfg.cfg_pf_pasid_en);

            // EXE Permission Enable
        if (pasid_cap.exe_permission_sup.v) begin
            pasid_cap.exe_permission_enable.set_v(cap_cfg.cfg_pf_pasid_exe_en);
        end else begin
            cap_cfg.cfg_pf_pasid_exe_en = 1'b0;
        end

            // Privileged Mode Enable
        if (pasid_cap.privileged_mode_sup.v) begin
            pasid_cap.privileged_mode_enable.set_v(cap_cfg.cfg_pf_pasid_priv_en);
        end else begin
            cap_cfg.cfg_pf_pasid_priv_en = 1'b0;
        end

        ///////////////////////////////////////////////////////////////////
        // [Write] PASID Control

            // PASID Enable
        env.shim.vip.write_capability(pdev_ep.bdf, pasid_cap,
            pasid_cap.pasid_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error writing PASID capability")

            // EXE Permission Enable
        env.shim.vip.write_capability(pdev_ep.bdf, pasid_cap,
            pasid_cap.exe_permission_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error writing PASID capability")

            // Privileged Mode Enable
        env.shim.vip.write_capability(pdev_ep.bdf, pasid_cap,
            pasid_cap.privileged_mode_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error writing PASID capability")

        ///////////////////////////////////////////////////////////////////
        // [Verify] PASID Control

            // PASID Enable
        env.shim.vip.read_capability(pdev_ep.bdf, pasid_cap,
            pasid_cap.pasid_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading PASID capability")
        if (pasid_cap.pasid_enable.v != cap_cfg.cfg_pf_pasid_en)
            `uvm_error(get_type_name(), " [CFG] Failed to write PASID enable field")

            // EXE Permission Enable
        env.shim.vip.read_capability(pdev_ep.bdf, pasid_cap,
            pasid_cap.exe_permission_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading PASID capability")
        if (pasid_cap.exe_permission_enable.v != cap_cfg.cfg_pf_pasid_exe_en)
            `uvm_error(get_type_name(), " [CFG] Failed to write pasid exe perm field")

            // Privileged Mode Enable
        env.shim.vip.read_capability(pdev_ep.bdf, pasid_cap,
            pasid_cap.privileged_mode_enable.get_offset_dw, err);
        if(err)
            `uvm_error(get_type_name(), " [CFG] Error reading PASID capability")
        if (pasid_cap.privileged_mode_enable.v != cap_cfg.cfg_pf_pasid_priv_en)
            `uvm_error(get_type_name(), " [CFG] Failed to write pasid priv field")

        `uvm_info(get_name(), {"Programmed PASID:\n",
                                "\t", $sformatf("PASID Enable                 = 0x%x,",
                                    cap_cfg.cfg_pf_pasid_en), "\n",
                                "\t", $sformatf("EXE Permission Enable        = 0x%x,",
                                    cap_cfg.cfg_pf_pasid_exe_en), "\n",
                                "\t", $sformatf("Privileged Mode Enable       = 0x%x",
                                    cap_cfg.cfg_pf_pasid_priv_en), "\n"
                                }, UVM_MEDIUM)
    endtask

endclass
