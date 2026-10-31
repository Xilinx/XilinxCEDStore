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

class pl_dbi_monitor extends uvm_monitor;
    `uvm_component_utils(pl_dbi_monitor)

    virtual pl_dbi_if.monitor_mp vif;
    uvm_analysis_port #(rp_cfg_txn) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual pl_dbi_if.monitor_mp)::get(this, "", "pl_dbi_if", vif)) begin
            `uvm_fatal(get_type_name(), "pl_dbi_if.monitor_mp is not set");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "PL DBI Monitor started", UVM_LOW);
        monitor_dbi();
    endtask

    virtual task monitor_dbi();
        forever begin
            @(posedge vif.clk);
            
            if(vif.dbi_arvalid) begin
                rp_cfg_txn txn;
                txn = rp_cfg_txn::type_id::create("txn", this);
                txn.is_write = 0;
                txn.addr     = vif.dbi_araddr;

                // Wait for rvalid
                do begin
                    @(posedge vif.clk);
                end while(!vif.dbi_rvalid);

                txn.data     = vif.dbi_rdata;
                txn.resp    = vif.dbi_rresp;
                `uvm_info(get_type_name(), $sformatf("PL DBI MONITOR: Sent read txn: %s", txn.sprint()), UVM_LOW);
                ap.write(txn);
            end

            if(vif.dbi_awvalid && vif.dbi_wvalid) begin
                rp_cfg_txn txn;
                txn = rp_cfg_txn::type_id::create("txn", this);
                txn.is_write = 1;
                txn.addr     = vif.dbi_awaddr;
                txn.data     = vif.dbi_wdata;

                // Wait for bvalid
                do begin
                    @(posedge vif.clk);
                end while(!vif.dbi_bvalid);

                txn.resp    = vif.dbi_bresp;
                `uvm_info(get_type_name(), $sformatf("PL DBI MONITOR: Sent write txn: %s", txn.sprint()), UVM_LOW);
                ap.write(txn);
            end
        end
    endtask

endclass