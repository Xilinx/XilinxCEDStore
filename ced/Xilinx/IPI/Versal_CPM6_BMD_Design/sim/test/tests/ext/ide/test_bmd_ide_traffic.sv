////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
////////////////////////////////////////////////////////////////////////

//==============================================================================
// test_bmd_ide_traffic.sv - BMD write traffic over a secured Link IDE stream
//==============================================================================
// Establishes Link IDE (test_ide_basic's main_phase, through test_bmd_ide_basic,
// which also applies the +CTRLRx_SPEED / +CTRLRx_FM plusargs) and then runs the
// same BMD write-traffic shape as test_bmd_write_min_size_min_count (1 write,
// 1 DW) over the secured link. Default test of the BMD CED when IDE is on.
//
// test_ide_basic and the test_bmd_* chain are siblings (both descend from
// test_enum, along different branches: test_ide_basic via base_ep_test,
// test_bmd_* via test_bmd_ep), so this class extends test_bmd_ide_basic (a
// test_ide_basic) and reproduces test_bmd_base/test_bmd's setup calls by
// composition instead of inheriting them.
//==============================================================================

class test_bmd_ide_traffic extends test_bmd_ide_basic;
    `uvm_component_utils(test_bmd_ide_traffic)

    //--------------------------------------------------------------------------
    // BMD environment/config objects (mirrors test_bmd_base's own fields)
    //--------------------------------------------------------------------------
    bmd_env_c         bmd_env;
    bmd_csr_config_c  csr_cfg;
    bmd_cap_config_c  cap_cfg;
    bmd_test_config_c tst_cfg;

    //--------------------------------------------------------------------------
    // BMD sequences (mirrors test_bmd's own fields)
    //--------------------------------------------------------------------------
    bmd_startup_vseq_c startup_seq;
    bmd_traffic_vseq_c traffic_seq;

    function new(string name = "test_bmd_ide_traffic", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Build phase (mirrors test_bmd_base.build_phase)
    //--------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        bmd_env = bmd_env_c::type_id::create("bmd_env", this);
        uvm_config_db#(tb_env)::set(this, "bmd_env", "framework_env", env);
        uvm_config_db#(tb_env)::set(null, "bmd_base_sequence", "env", env);

        csr_cfg = bmd_csr_config_c::type_id::create("csr_cfg");
        cap_cfg = bmd_cap_config_c::type_id::create("cap_cfg");
        tst_cfg = bmd_test_config_c::type_id::create("tst_cfg");

        uvm_config_db#(bmd_csr_config_c)::set(this,  "bmd_env", "csr_cfg", csr_cfg);
        uvm_config_db#(bmd_cap_config_c)::set(this,  "bmd_env", "cap_cfg", cap_cfg);
        uvm_config_db#(bmd_test_config_c)::set(this, "bmd_env", "tst_cfg", tst_cfg);

        uvm_config_db#(bmd_csr_config_c)::set(null,  "bmd_base_sequence", "csr_cfg", csr_cfg);
        uvm_config_db#(bmd_cap_config_c)::set(null,  "bmd_base_sequence", "cap_cfg", cap_cfg);
        uvm_config_db#(bmd_test_config_c)::set(null, "bmd_base_sequence", "tst_cfg", tst_cfg);

        startup_seq = bmd_startup_vseq_c::type_id::create("startup_seq");
        traffic_seq = bmd_traffic_vseq_c::type_id::create("traffic_seq");

        // The root port's requests go on the IDE stream once it is secure
        // (bmd_ide_tlps.sv)
        amd_mem_tlp::type_id::set_type_override(bmd_ide_mem_tlp::get_type());
        amd_cfg_tlp::type_id::set_type_override(bmd_ide_cfg_tlp::get_type());
    endfunction

    //--------------------------------------------------------------------------
    // Configure phase (mirrors test_bmd_base.configure_phase). Populates the
    // pdev_ep/pdev_rp fields inherited from test_ide_basic -- test_ide_basic
    // only sets them in main_phase, too late for BAR-exclusion setup here.
    //--------------------------------------------------------------------------
    virtual task configure_phase(uvm_phase phase);
        super.configure_phase(phase);

        pdev_ep = env.shim.container.get_pdev_EP();
        pdev_rp = env.shim.container.get_pdev_RP();

        if (pdev_ep == null) begin
            `uvm_fatal(get_name(), "Failed to get endpoint device handle")
        end

        foreach (pdev_ep.membar[i]) begin
            if (pdev_ep.membar[i].sz > 0) begin
                csr_cfg.add_excluded_region(pdev_ep.membar[i].base, pdev_ep.membar[i].sz);
            end
        end

        if (!csr_cfg.randomize()) begin
            `uvm_fatal(get_name(), "Failed to randomize CSR configuration")
        end

        add_address_exclusion_regions();

        if (!cap_cfg.randomize()) begin
            `uvm_fatal(get_name(), "Failed to randomize capability configuration")
        end

        tst_cfg.add_error_vars(bmd_mem_pkg::MAX_CSR, csr_cfg.rd_pattern);

        if (!tst_cfg.randomize()) begin
            `uvm_fatal(get_name(), "Failed to randomize test configuration")
        end
    endtask

    //--------------------------------------------------------------------------
    // Post-configure phase -- write-min-size-min-count traffic shape (mirrors
    // test_bmd_write_min_size_min_count.post_configure_phase) plus
    // test_bmd_base.disable_extra (inlined; not inherited from that class).
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        cap_cfg.cfg_int_disable         = 1'b1;
        cap_cfg.cfg_atomic_req_en       = 1'b0;
        cap_cfg.cfg_pf_pasid_en         = 1'b0;
        cap_cfg.cfg_msix_en             = 1'b0;
        cap_cfg.cfg_msi_en              = 1'b0;
        cap_cfg.cfg_pf_pasid_exe_en     = 1'b0;
        cap_cfg.cfg_pf_pasid_priv_en    = 1'b0;
        cap_cfg.cfg_tph_en              = 1'b0;
        cap_cfg.cfg_tph_ext_en          = 1'b0;

        tst_cfg.send_ur_to_dut          = 1'b0;
        tst_cfg.read_out_of_range       = 1'b0;
        tst_cfg.inject_bad_data         = 1'b0;

        csr_cfg.rd_int_disable          = 1'b1;
        csr_cfg.wr_int_disable          = 1'b1;

        csr_cfg.wr_start    = 1'b1;
        csr_cfg.rd_start    = 1'b0;
        csr_cfg.wr_size     = 9'h001;
        csr_cfg.wr_count    = 16'h0001;
        csr_cfg.wr_upper_be = 4'b0000;

        // TC0 is the Link IDE stream's TC, so the write is sent encrypted
        csr_cfg.wr_tc_en    = 1'b0;
        csr_cfg.wr_tc       = 3'b000;
    endtask

    //--------------------------------------------------------------------------
    // Address exclusions (mirrors test_bmd_base.add_address_exclusion_regions)
    //--------------------------------------------------------------------------
    function void add_address_exclusion_regions();
        cap_cfg.add_excluded_region({32'd0, csr_cfg.rd_addr},
                                    {32'd0, csr_cfg.rd_addr} +
                                    (csr_cfg.rd_count * (csr_cfg.rd_size << 2)));
        cap_cfg.add_excluded_region({csr_cfg.rd_uaddr, csr_cfg.rd_addr},
                                    {csr_cfg.rd_uaddr, csr_cfg.rd_addr} +
                                    (csr_cfg.rd_count * (csr_cfg.rd_size << 2)));
        cap_cfg.add_excluded_region({32'd0, csr_cfg.wr_addr},
                                    {32'd0, csr_cfg.wr_addr} +
                                    (csr_cfg.wr_count * (csr_cfg.wr_size << 2)));
        cap_cfg.add_excluded_region({csr_cfg.wr_uaddr, csr_cfg.wr_addr},
                                    {csr_cfg.wr_uaddr, csr_cfg.wr_addr} +
                                    (csr_cfg.wr_count * (csr_cfg.wr_size << 2)));
    endfunction

    //--------------------------------------------------------------------------
    // Main phase: establish Link IDE first (test_ide_basic.main_phase), then
    // run BMD write traffic over the now-secured link (mirrors test_bmd.main_phase).
    //--------------------------------------------------------------------------
    virtual task main_phase(uvm_phase phase);
        bmd_ide_cfg_cb ide_cfg_cb = new();

        super.main_phase(phase);  // test_ide_basic: establishes Link IDE, waits secure

        env.shim.vip.append_callback(ide_cfg_cb);
        bmd_ide_stream::id = link_ide_cfg.stream_id;

        phase.raise_objection(this, "test_bmd_ide_traffic executing");
        `uvm_info(get_type_name(), "Starting BMD write traffic over secured Link IDE", UVM_LOW)

        startup_seq.start(env.shim.vsqr);
        bmd_env.pass_config();
        traffic_seq.start(env.shim.vsqr);

        `uvm_info(get_type_name(), "Completed BMD write traffic over secured Link IDE", UVM_LOW)
        phase.drop_objection(this, "test_bmd_ide_traffic complete");
    endtask

endclass : test_bmd_ide_traffic
