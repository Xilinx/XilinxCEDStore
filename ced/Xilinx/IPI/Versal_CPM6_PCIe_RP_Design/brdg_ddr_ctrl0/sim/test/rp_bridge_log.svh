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

// ---------------------------------------------------------------------------
// rp_bridge_log - the readable narrative of what the AXI-bridge RP actually did.
//
// vcs.sim.log is ~3 MB, most of it CDO-loader and GT quad-config output from
// inside the CPM6 secure IP, which this testbench cannot silence. This file
// carries the bridge picture separately, so answering "did inbound reach PL
// BRAM?" does not require correlating vcs.sim.log against tracker_tl_vip0.log
// by timestamp.
//
// Sections, in the order they are written:
//   1. ENUMERATION   link, ECAM, bus numbers, EP identity
//   2. BARs          probed size and final base, per BAR
//   3. RP BRIDGE     Command register and the Type 1 MEM/prefetchable windows
//   4. TRANSACTIONS  one line per memory access, with direction and target
//   5. SUMMARY       match/mismatch/UR tally
//
// Written through the macros below, which emit to both the UVM log and this
// file so the two cannot drift.
// ---------------------------------------------------------------------------

class rp_bridge_log;

    protected static int fh = 0;

    // Tallies for the closing summary.
    static int n_match    = 0;
    static int n_mismatch = 0;
    static int n_ur       = 0;

    // Opened lazily on first use, so no component has to own the file's
    // lifetime - whichever section is written first creates it.
    static function int handle();
        if (fh == 0) begin
            fh = $fopen("rp_bridge_log.txt", "w");
            if (fh != 0) begin
                $fwrite(fh, "========================================================================\n");
                $fwrite(fh, "  CPM6 PCIe Root Port - AXI-MM bridge - configuration and traffic\n");
                $fwrite(fh, "========================================================================\n");
                $fwrite(fh, "  Direction is from the Root Port's point of view:\n");
                $fwrite(fh, "    OUT   RP -> EP    the RP reads/writes the Endpoint's BARs\n");
                $fwrite(fh, "    IN    EP -> RP    the Endpoint reads/writes host memory\n");
                $fwrite(fh, "\n");
                $fwrite(fh, "  Inbound targets are decoded from the address:\n");
                $fwrite(fh, "    DDR/NoC   below the top of DDR, routed CPM6 -> PS -> NoC -> MC\n");
                $fwrite(fh, "    PL BRAM   inside the CPM_AXI_PL0 aperture at 0x2_0000_0000\n");
                $fwrite(fh, "    unmapped  claimed by nothing - a read here never returns and\n");
                $fwrite(fh, "              head-of-line blocks every inbound request behind it\n");
                $fwrite(fh, "\n");
                $fwrite(fh, "  Companion logs in this directory:\n");
                $fwrite(fh, "    tracker_tl_vip0.log     every TLP with its header decoded\n");
                $fwrite(fh, "    tracker_cfg_vip0.log    every config-space access\n");
                $fwrite(fh, "    vcs.sim.log             full simulator output\n");
                $fwrite(fh, "========================================================================\n");
                $fwrite(fh, "\n");
            end
        end
        return fh;
    endfunction

    // A free-form line - banners, configuration, results. No timestamp column.
    static function void note(string s);
        int f = handle();
        if (f != 0) begin
            $fwrite(f, "%s\n", s);
            $fflush(f);
        end
    endfunction

    // A transaction line, prefixed with simulation time in ns. The enclosing
    // package is timeunit 1ps, so $time is in ps.
    static function void stamped(string s);
        int f = handle();
        if (f != 0) begin
            $fwrite(f, "%9d ns  %s\n", $time / 1000, s);
            $fflush(f);
        end
    endfunction

    // Which target claims this inbound address. Kept here rather than in the
    // test so every caller decodes it the same way.
    static function string target_of(bit [63:0] addr);
        if (addr >= 64'h2_0000_0000 && addr < 64'h2_0002_0000) return "PL BRAM";
        if (addr <  64'h8000_0000)                             return "DDR/NoC";
        if (addr >= 64'he000_0000 && addr < 64'hf000_0000)     return "EP BAR";
        return "unmapped";
    endfunction

    static function void tally(bit is_match, bit is_ur);
        if      (is_ur)    n_ur++;
        else if (is_match) n_match++;
        else               n_mismatch++;
    endfunction

    static function void summary();
        note("");
        note("========================================================================");
        note($sformatf("  SUMMARY: %0d match, %0d mismatch, %0d UR",
                       n_match, n_mismatch, n_ur));
        note("========================================================================");
    endfunction

endclass

// One transaction line, to both the UVM log and rp_bridge_log.txt.
`define rp_txn(MSG)                                    \
    begin                                              \
        string rp_txn_msg_;                            \
        rp_txn_msg_ = MSG;                             \
        `uvm_info("RP_TXN", rp_txn_msg_, UVM_LOW)      \
        rp_bridge_log::stamped(rp_txn_msg_);           \
    end

// A headline line - configuration and result. UVM_NONE so it survives any
// verbosity setting, and unstamped so the banners read cleanly.
`define rp_cfg(ID, MSG)                                \
    begin                                              \
        string rp_cfg_msg_;                            \
        rp_cfg_msg_ = MSG;                             \
        `uvm_info(ID, rp_cfg_msg_, UVM_NONE)           \
        rp_bridge_log::note(rp_cfg_msg_);              \
    end
