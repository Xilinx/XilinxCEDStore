class test_bmd_ep extends test_enum;

    `uvm_component_utils(test_bmd_ep)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    bit [1:0]                   dut_ctrlr_en;

    bit [1:0]                   ctrlr_override_fm;
    bit [1:0]                   ctrlr_target_fm;

    bit [1:0]                   ctrlr_override_speed;
    bit [1:0][2:0]              ctrlr_target_speed;
    pcie_config::speed_e [1:0]  _target_speed;

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);

        // Default each DUT controller to enabled, which affects CDO programming
        if (!$value$plusargs("CTRLR0_EN=%b",dut_ctrlr_en[0]))
            dut_ctrlr_en[0] = 1'b1;
        if (!$value$plusargs("CTRLR1_EN=%b",dut_ctrlr_en[1]))
            dut_ctrlr_en[1] = 1'b1;

        if (!$value$plusargs("CTRLR0_FM=%b", ctrlr_target_fm[0])) begin
            ctrlr_override_fm[0] = 1'b0;
        end else begin
            ctrlr_override_fm[0] = 1'b1;
        end

        if (!$value$plusargs("CTRLR1_FM=%b", ctrlr_target_fm[1])) begin
            ctrlr_override_fm[1] = 1'b0;
        end else begin
            ctrlr_override_fm[1] = 1'b1;
        end

        if (!$value$plusargs("CTRLR0_SPEED=%d", ctrlr_target_speed[0])) begin
            ctrlr_override_speed[0] = 1'b0;
        end else begin
            ctrlr_override_speed[0] = 1'b1;
            case(ctrlr_target_speed[0])
                1 : _target_speed[0] = pcie_config::GEN1;
                2 : _target_speed[0] = pcie_config::GEN2;
                3 : _target_speed[0] = pcie_config::GEN3;
                4 : _target_speed[0] = pcie_config::GEN4;
                5 : _target_speed[0] = pcie_config::GEN5;
                6 : _target_speed[0] = pcie_config::GEN6;
                default : `uvm_fatal(get_type_name(),
                            $sformatf("Invalid speed passed as plusarg: %d", ctrlr_target_speed[0]))
            endcase
        end

        if (!$value$plusargs("CTRLR1_SPEED=%d", ctrlr_target_speed[1])) begin
            ctrlr_override_speed[1] = 1'b0;
        end else begin
            ctrlr_override_speed[1] = 1'b1;
            case(ctrlr_target_speed[1])
                1 : _target_speed[1] = pcie_config::GEN1;
                2 : _target_speed[1] = pcie_config::GEN2;
                3 : _target_speed[1] = pcie_config::GEN3;
                4 : _target_speed[1] = pcie_config::GEN4;
                5 : _target_speed[1] = pcie_config::GEN5;
                6 : _target_speed[1] = pcie_config::GEN6;
                default : `uvm_fatal(get_type_name(),
                            $sformatf("Invalid speed passed as plusarg: %d", ctrlr_target_speed[1]))
            endcase
        end

        // Basic setup
        for (int ii=0; ii<2; ii++) begin
            // VIP as RP
            vip_cfg.ctrlr_en[ii] = '1;
            vip_cfg.port_ctl[ii] = generic_config::PCIE;
            vip_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::RP;
            if(ctrlr_override_fm[ii])    vip_cfg.pcie_cfg[ii].flit_mode_ctl = ctrlr_target_fm[ii];
            if(ctrlr_override_speed[ii]) vip_cfg.pcie_cfg[ii].pcie_cap.link_ctl2.target_link_speed = _target_speed[ii];
            `uvm_info(get_type_name(), {$sformatf("Configured VIP as RP: "), "\n",
                                        $sformatf("    * Flit Mode Override:  0x%x", ctrlr_override_fm[ii]), "\n",
                                        $sformatf("    * Flit Mode:           0x%x", ctrlr_target_fm[ii]), "\n",
                                        $sformatf("    * Speed Override:      0x%x", ctrlr_override_speed[ii]), "\n",
                                        $sformatf("    * Target Speed:        0x%x", ctrlr_target_speed[ii]),  "\n"},
                                            UVM_MEDIUM)

            // DUT as EP
            dut_cfg.ctrlr_en[ii] = dut_ctrlr_en[ii];
            dut_cfg.port_ctl[ii] = generic_config::PCIE;
            dut_cfg.pcie_cfg[ii].pcie_cap.pcie_cap.dev_port_type = pcie_config::EP;
            if(ctrlr_override_fm[ii])    dut_cfg.pcie_cfg[ii].flit_mode_ctl = ctrlr_target_fm[ii];
            if(ctrlr_override_speed[ii]) dut_cfg.pcie_cfg[ii].pcie_cap.link_ctl2.target_link_speed = _target_speed[ii];
            `uvm_info(get_type_name(), {$sformatf("Configured DUT as EP: "), "\n",
                                        $sformatf("    * Flit Mode Override:  0x%x", ctrlr_override_fm[ii]), "\n",
                                        $sformatf("    * Flit Mode:           0x%x", ctrlr_target_fm[ii]), "\n",
                                        $sformatf("    * Speed Override:      0x%x", ctrlr_override_speed[ii]), "\n",
                                        $sformatf("    * Target Speed:        0x%x", ctrlr_target_speed[ii]),  "\n"},
                                            UVM_MEDIUM)
        end
endfunction

    // Override pre_enum_seq to support SRIOV VF enumeration via plusargs:
    //   +SRIOV_ENUM          - enable VF enumeration (sets bus_enum_skip_vf_enable=0)
    //   +ENUM_TIMEOUT=<us>   - override enum timeout in microseconds (default: 250us)
    virtual task pre_enum_seq();
        int _enum_timeout_us;
        if ($value$plusargs("ENUM_TIMEOUT=%d", _enum_timeout_us))
            bus_enum.enum_timeout = _enum_timeout_us * 1us;
        if ($test$plusargs("SRIOV_ENUM")) begin
            env.shim.vip.cfg_info.SRIOV_sup = 1;
            env.shim.vip.set("bus_enum_skip_vf_enable", 0);
        end
        // BMD does not implement DOE/CMA/SPDM required for IDE
        env.shim.vip.cfg_info.ide_sup = 0;
        env.shim.vip.cfg_info.doe_sup = 0;
    endtask

endclass
