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

// rp_flow_log - one line per PCIe transaction, in time order, written to
// rp_flow_log.txt and the UVM log through the `rp_flow macro below.

class rp_flow_log;

    protected static int fh = 0;

    // Opened lazily on first use so that no single component has to own the
    // file's lifetime - the first transaction to be logged creates it.
    static function int handle();
        if (fh == 0) begin
            fh = $fopen("rp_flow_log.txt", "w");
            if (fh != 0) begin
                $fwrite(fh, "========================================================================\n");
                $fwrite(fh, "  CPM6 PCIe Root Port - PL streaming - transaction flow\n");
                $fwrite(fh, "========================================================================\n");
                $fwrite(fh, "  One line per PCIe transaction, in time order.\n");
                $fwrite(fh, "    RP -> EP   a request the Root Port issued downstream\n");
                $fwrite(fh, "    EP -> RP   the Endpoint's response coming back upstream\n");
                $fwrite(fh, "  Match a request to its response by tag.\n");
                $fwrite(fh, "\n");
                $fwrite(fh, "  Companion logs in this directory:\n");
                $fwrite(fh, "    ep_config_log.txt        every config-space access, decoded\n");
                $fwrite(fh, "    bar_config_log.txt       BAR sizing and base assignment\n");
                $fwrite(fh, "    device_vendor_id_log.txt the Device/Vendor ID handshake\n");
                $fwrite(fh, "    memory_txn_log.txt       per-transaction memory detail\n");
                $fwrite(fh, "    credit_log.txt           flow-control credit movement\n");
                $fwrite(fh, "========================================================================\n");
                $fwrite(fh, "\n");
            end
        end
        return fh;
    endfunction

    // A free-form line (banners, configuration, result), no timestamp column.
    static function void note(string s);
        int f = handle();
        if (f != 0) begin
            $fwrite(f, "%s\n", s);
            $fflush(f);
        end
    endfunction

    // A transaction line, prefixed with the simulation time in ns. The
    // enclosing package is timeunit 1ps, so $time is in ps.
    static function void stamped(string s);
        int f = handle();
        if (f != 0) begin
            $fwrite(f, "%8d ns  %s\n", $time / 1000, s);
            $fflush(f);
        end
    endfunction

endclass

// Emit one flow line to both the UVM log and rp_flow_log.txt.
`define rp_flow(MSG)                                  \
    begin                                             \
        string rp_flow_msg_;                          \
        rp_flow_msg_ = MSG;                           \
        `uvm_info("RP_FLOW", rp_flow_msg_, UVM_LOW)   \
        rp_flow_log::stamped(rp_flow_msg_);           \
    end

// A headline line - configuration and result. UVM_NONE so it survives any
// verbosity setting, and unstamped in the flow log so the banners read cleanly.
`define rp_note(ID, MSG)                              \
    begin                                             \
        string rp_note_msg_;                          \
        rp_note_msg_ = MSG;                           \
        `uvm_info(ID, rp_note_msg_, UVM_NONE)         \
        rp_flow_log::note(rp_note_msg_);              \
    end
