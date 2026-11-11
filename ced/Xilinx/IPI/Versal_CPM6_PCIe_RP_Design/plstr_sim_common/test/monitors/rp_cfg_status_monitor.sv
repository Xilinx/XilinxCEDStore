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

class rp_cfg_status_monitor extends uvm_monitor;
    `uvm_component_utils(rp_cfg_status_monitor)

    // Configuration tracking structure
    typedef struct packed {
        bit is_vf;
        logic [8:0] function_num;
        bit msix_en;
        bit msix_func_mask;
        bit flr_active;
        time last_update;
    } func_cfg_t;

    // Storage indexed by absolute function number
    protected func_cfg_t func_configs[int];
    
    // Sequence tracking
    protected int pf_sequence_num = 0;
    protected int vf_sequence_num = 0;

    // Interface handles
    virtual pf_cfg_if.monitor_mp pf_vif;
    virtual vf_cfg_if.monitor_mp vf_vif;

    int counter_pf = 0;
    int counter_vf = 0;

    bit SOS_pf = 0;
    bit SOS_vf = 0;
    bit clock_skip = 0;

    bit flit_mode;


    function new(string name, uvm_component parent);
        super.new(name, parent);

        // Initialize PF configurations (0)
        for (int i = 0; i < 1; i++) begin
            func_configs[i] = '{
                is_vf: 0,
                function_num: i[8:0],
                msix_en: 0,
                msix_func_mask: 0, 
                flr_active: 0,
                last_update: 0
            };
        end

        `uvm_info(get_type_name(), $sformatf(
            "Initialized configuration storage for 1 PF"), UVM_LOW)
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get virtual interfaces from config DB
        if (!uvm_config_db#(virtual pf_cfg_if.monitor_mp)::get(this, "", "pf_cfg_if", pf_vif))
            `uvm_fatal(get_type_name(), "Failed to get PF config virtual interface")

        if (!uvm_config_db#(virtual vf_cfg_if.monitor_mp)::get(this, "", "vf_cfg_if", vf_vif))
            `uvm_fatal(get_type_name(), "Failed to get VF config virtual interface")

        // Initialize sequence numbers
        pf_sequence_num = 0;
        vf_sequence_num = 0;
            
        `uvm_info(get_type_name(), "Retrieved virtual interfaces successfully", UVM_LOW)
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            monitor_pf_sequence();
        join
    endtask

    // Monitor PF configuration sequence
    virtual task monitor_pf_sequence();
        logic [8:0] func_num = 'h5;
        forever @(pf_vif.monitor_cb) begin
            if (pf_vif.monitor_cb.pf_cfg_status_pvld) begin

                // Check if function number has changed
                if (func_num != pf_vif.monitor_cb.pf_cfg_status_func_num || pf_vif.monitor_cb.pf_cfg_status_sos) begin
                    func_num = {6'b0, pf_vif.monitor_cb.pf_cfg_status_func_num}; // Zero extend 3-bit to 8-bit
                    
                    // New sequence starting
                    if ((pf_vif.monitor_cb.pf_cfg_status_sos | SOS_pf)) begin
                        pf_sequence_num++;

                        SOS_pf = 1;

                        // Update config
                        func_configs[func_num].msix_func_mask = pf_vif.monitor_cb.pf_cfg_status_info.c0.msix_func_mask;

                        // Update config for this PF
                        func_configs[func_num].is_vf = 0;
                        func_configs[func_num].function_num = func_num;
                        func_configs[func_num].msix_en = pf_vif.monitor_cb.pf_cfg_status_info.c0.msix_en;
                        func_configs[func_num].msix_func_mask = pf_vif.monitor_cb.pf_cfg_status_info.c0.msix_func_mask;
                        func_configs[func_num].flr_active = pf_vif.monitor_cb.pf_cfg_status_info.c0.flr_pf_active;
                        func_configs[func_num].last_update = $time;
                        
                        flit_mode = pf_vif.monitor_cb.pf_cfg_status_info.c1.flit_mode;

                    end

                    if(counter_pf%1000 == 0) begin
                        report_pf_configs();
                    end
                    counter_pf++;
                    end
            end
        end
    endtask

    // Monitor VF configuration sequence
    virtual task monitor_vf_sequence();
        logic [8:0] vf_num;
        forever @(vf_vif.monitor_cb) begin
            if (vf_vif.monitor_cb.vf_cfg_status_vld) begin
                // New sequence starting
                if (vf_vif.monitor_cb.vf_cfg_status_sos || SOS_vf) begin
                    vf_sequence_num++;
                SOS_vf = 1;
                // Calculate absolute function number using parameters

                vf_num = {1'b0,vf_vif.monitor_cb.vf_cfg_status_func_num} + 1; //1PF

                // Update config
                func_configs[vf_num].msix_func_mask = 
                    vf_vif.monitor_cb.vf_cfg_status_info.vf_msix_func_mask;
                // Update config for this VF
                func_configs[vf_num].is_vf = 1;
                func_configs[vf_num].function_num = vf_num;
                func_configs[vf_num].msix_en = vf_vif.monitor_cb.vf_cfg_status_info.vf_msix_en;
                func_configs[vf_num].msix_func_mask = vf_vif.monitor_cb.vf_cfg_status_info.vf_msix_func_mask;
                func_configs[vf_num].flr_active = vf_vif.monitor_cb.vf_cfg_status_info.flr_vf_active;
                func_configs[vf_num].last_update = $time;

                if(counter_vf%10000 == 0) begin
                        report_vf_configs();
                    end
                counter_vf++;
                end
            end
        end
    endtask

    // Helper to print function status
    protected function void report_func_status(int func_num);
        string func_str = $sformatf("Function%0d", func_configs[func_num].function_num);

        `uvm_info(get_type_name(), $sformatf(
            "%s Status Update at time %0t:\n  MSIX_EN=%b\n  FUNC_MASK=%b\n  FLR=%b",
            func_str,
            $time,
            func_configs[func_num].msix_en,
            func_configs[func_num].msix_func_mask,
            func_configs[func_num].flr_active), UVM_LOW)
    endfunction


    // Public report function for PF configuration details
    function void report_pf_configs();
        string report_str;
        string separator = "+-----+----------------+-----------+-------------+-----------+--------------+\n";
        bit [7:0] msix_en_bits = 0;    // For 8 PFs
        bit [7:0] func_mask_bits = 0;
        bit [7:0] flr_active_bits = 0;

        report_str = "\n=== Physical Function Configuration Report ===\n";
        report_str = {report_str, separator};
        report_str = {report_str, "| PF  | Function Number | MSI-X En  | Func Mask  | FLR Active| Last Update  |\n"};
        report_str = {report_str, separator};
        
        for (int i = 0; i < 1; i++) begin
            if (func_configs.exists(i)) begin
                // Accumulate status bits
                msix_en_bits[i] = func_configs[i].msix_en;
                func_mask_bits[i] = func_configs[i].msix_func_mask;
                flr_active_bits[i] = func_configs[i].flr_active;

                report_str = {report_str, $sformatf("| %-3d | %-14d | %-9b | %-11b | %-9b | %-12b | %-12t |\n",
                    i,
                    func_configs[i].function_num,
                    func_configs[i].msix_en,
                    func_configs[i].msix_func_mask,
                    func_configs[i].flr_active,
                    flit_mode,
                    func_configs[i].last_update)
                };
            end else begin
                report_str = {report_str, $sformatf("| %-3d | %-14s | %-9s | %-11s | %-9s | %-12s |\n",
                    i, "N/A", "N/A", "N/A", "N/A", "N/A")};
            end
        end
        
        report_str = {report_str, separator};
        // Add accumulated status in hex
        report_str = {report_str, $sformatf("PF Status Summary (hex):\n")};
        report_str = {report_str, $sformatf("MSI-X Enable   = 'h%2h\n", msix_en_bits)};
        report_str = {report_str, $sformatf("Function Mask  = 'h%2h\n", func_mask_bits)};
        report_str = {report_str, $sformatf("FLR Active     = 'h%2h\n", flr_active_bits)};
        
        `uvm_info(get_type_name(), report_str, UVM_LOW)
    endfunction

    // Public report function for VF configuration details
    function void report_vf_configs();
        string report_str;
        string separator = "+-----+----------------+-----------+-------------+-----------+--------------+\n";
        bit [255:0] msix_en_bits = 0;    // For 256 VFs
        bit [255:0] func_mask_bits = 0;
        bit [255:0] flr_active_bits = 0;
        
        report_str = "\n=== Virtual Function Configuration Report ===\n";
        report_str = {report_str, separator};
        report_str = {report_str, "| VF  | Function Number | MSI-X En  | Func Mask  | FLR Active| Last Update  |\n"};
        report_str = {report_str, separator};
        
        
        report_str = {report_str, separator};
        // Add accumulated status in hex (showing in 64-bit chunks)
        report_str = {report_str, $sformatf("VF Status Summary (hex):\n")};
        report_str = {report_str, $sformatf("MSI-X Enable   = 'h%64h\n", msix_en_bits)};
        report_str = {report_str, $sformatf("Function Mask  = 'h%64h\n", func_mask_bits)};
        report_str = {report_str, $sformatf("FLR Active     = 'h%64h\n", flr_active_bits)};
        
        `uvm_info(get_type_name(), report_str, UVM_LOW)
    endfunction

    // Public accessor for config data
    function func_cfg_t get_func_config(int func_num);
        if (!func_configs.exists(func_num)) begin
            `uvm_error(get_type_name(), $sformatf("No config found for function %0d", func_num))
            return '0;
        end
        return func_configs[func_num];
    endfunction
endclass