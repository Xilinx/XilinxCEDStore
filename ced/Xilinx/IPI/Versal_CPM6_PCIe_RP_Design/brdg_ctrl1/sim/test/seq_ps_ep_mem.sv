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

class seq_ps_ep_mem extends seq_ps_pcie_enum;

  `uvm_object_utils(seq_ps_ep_mem)

    // Outbound window bases, selected per controller by set_addr_map() below.
    // NOT initialised here - the values depend on which controller this
    // sequence targets.
    bit [31:0] base_addr_32b;
    bit [63:0] base_addr_64b;
    bit [63:0] base_addr_vdm;
    
    // Type0:max6, Type1:max2 | key is BAR number (lower for 64b BAR)
    mem_bar_s      membar[bit [2:0]];
    io_bar_s       iobar [bit [2:0]];

    // parent must set
    bit [47:0] ecam_bus;
    bit [ 7:0]  bus_base;

    function new(string name = "seq_ps_ep_mem");
        super.new(name);
    endfunction

    // Per-controller outbound address map, selected from `ctrlr`. Must track
    // the CPM6_CTRLn_PS_APERTUREn_* keys in design_1_bd.tcl:
    //
    //           ECAM          32b BAR              64b BAR              VDM (64 KB)
    //   Ctrl0  6_0000_0000  e000_0000-e7ff_ffff  80_..-9f_fffe_ffff  9f_ffff_0000
    //   Ctrl1  7_0000_0000  e800_0000-efff_ffff  a0_..-bf_fffe_ffff  bf_ffff_0000
    //
    // ecam_base is NOT set here - the parent test takes it from the
    // enumeration sequence. A dual-controller design must run enumeration per
    // controller so each gets its own ECAM base.
    virtual function void set_addr_map();
        case (ctrlr)
          1'b0: begin
            base_addr_32b = 32'he000_0000;
            base_addr_64b = 64'h80_0000_0000;
            base_addr_vdm = 64'h9f_ffff_0000;
          end
          1'b1: begin
            base_addr_32b = 32'he800_0000;
            base_addr_64b = 64'ha0_0000_0000;
            base_addr_vdm = 64'hbf_ffff_0000;
          end
          default:
            `uvm_fatal(get_type_name,
              "set_ctrlr(<n>) must be called before this sequence runs - no address map to select")
        endcase

        `uvm_info(get_type_name, $sformatf(
          "Ctrl%0d outbound map: 32b BAR 0x%0h  64b BAR 0x%0h  VDM 0x%0h",
          ctrlr, base_addr_32b, base_addr_64b, base_addr_vdm), UVM_LOW)
    endfunction

    // Post-reconfiguration config-space state - what traffic actually runs
    // against. Reads go over PS AXI to the ECAM, so they do not appear in the
    // VIP TLP tracker.
    virtual task print_final_cfg_state;
        bit [31:0] b0_lo, b0_hi, b2, rp_bar0;
        bit [31:0] memwin, pfwin, pf_base_u, pf_lim_u;

        axi_rd((this.ecam_base + (1'b1<<20) + 'h10), b0_lo);
        axi_rd((this.ecam_base + (1'b1<<20) + 'h14), b0_hi);
        axi_rd((this.ecam_base + (1'b1<<20) + 'h18), b2);
        axi_rd((this.ecam_base + 'h10), rp_bar0);
        axi_rd((this.ecam_base + 'h20), memwin);
        axi_rd((this.ecam_base + 'h24), pfwin);
        axi_rd((this.ecam_base + 'h28), pf_base_u);
        axi_rd((this.ecam_base + 'h2c), pf_lim_u);

        `uvm_info(get_type_name, $sformatf({"\n",
          "+----------------------------------------------------------+\n",
          "|        Final Config State (AFTER BAR reconfig)           |\n",
          "+----------------------------------------------------------+\n",
          "  EP (bus 1, dev 0)\n",
          "      BAR0/1 (64b) : 0x%08h_%08h\n",
          "      BAR2   (32b) : 0x%08h\n",
          "  RP (bus 0, dev 0)  -- Type 1 bridge\n",
          "      BAR0         : 0x%08h %s\n",
          "      MEM   (0x20) : 0x%08h -> base=0x%08h limit=0x%08h %s\n",
          "      PFMEM (0x24) : 0x%08h -> base=0x%08h limit=0x%08h %s\n",
          "      PF base upper(0x28) : 0x%08h\n",
          "      PF lim  upper(0x2c) : 0x%08h\n",
          "+----------------------------------------------------------+"},
          b0_hi, b0_lo, b2,
          rp_bar0, (rp_bar0 != 0) ? "(non-zero: BAR matching enabled)" : "(none)",
          memwin, {memwin[15:4],20'h0}, {memwin[31:20],20'hFFFFF},
          (memwin[31:20] < memwin[15:4]) ? "INVERTED (always outside)" : "ACTIVE (claims this range)",
          pfwin,  {pfwin[15:4],20'h0},  {pfwin[31:20],20'hFFFFF},
          (pfwin[31:20] < pfwin[15:4]) ? "INVERTED (always outside)" : "ACTIVE (claims this range)",
          pf_base_u, pf_lim_u), UVM_LOW)
    endtask

    // ---- RP as a real bridge (driven from test_ps_transactions) ------------
    // Type 1 windows and MSE+BME are written over ECAM, so stock upstream
    // enumeration is sufficient and the framework needs no fork. Values derive
    // from base_addr_32b / base_addr_64b, so each controller gets its own:
    //     ctrl0  BAR2 0xE000_0000   BAR0/1 0x80_0000_0000
    //     ctrl1  BAR2 0xE800_0000   BAR0/1 0xA0_0000_0000
    bit        program_rp_bridge;
    bit [31:0] rp_mem_win;
    bit [31:0] rp_pfmem_win     = 32'h0001_0001;  // low nibble = 64b capable (RO)
    bit [31:0] rp_pfmem_base_up;
    bit [31:0] rp_pfmem_lim_up;

    virtual task body;
        bit [31:0] data_rd;
        bit [31:0] rp_cmd;
        bit [31:0] pre_cmd, pre_mem, pre_pf, pre_pfu, pre_pfl;
        bit [31:0] pre_b0lo, pre_b0hi, pre_b2;
        // Expected payloads for the outbound (RP -> EP) MEM write/read-back pairs.
        bit [31:0] exp_64b = 32'h1234_064b;   // via BAR0, 64-bit prefetchable
        bit [31:0] exp_32b = 32'h1234_032b;   // via BAR2, 32-bit non-prefetchable
        int        mem_errs = 0;

        // Pick the outbound window bases for whichever controller this sequence
        // targets. Must happen before any address is used below.
        set_addr_map();

        // Reconfigure the BARs, OVERRIDING what enumeration assigned, so the
        // traffic addresses further down line up. Everything the enum printed
        // in its results table is stale after this point - hence the
        // final-state dump that follows.
        `uvm_info(get_type_name,
          "Reconfiguring BARs (overrides enum-assigned placement)", UVM_LOW)

        `uvm_info(get_type_name,
          "  EP BAR0/1 (64b pf) <- 0x0000_00a0_0000_0000  (enum had 0xe800_0000)", UVM_LOW)
        axi_wr((this.ecam_base + (1'b1<<20) + 'h10), base_addr_64b[31:0]);
        axi_wr((this.ecam_base + (1'b1<<20) + 'h14), base_addr_64b[63:32]);

        `uvm_info(get_type_name,
          "  EP BAR2   (32b np) <- 0xe800_0000            (enum had 0x00000000)", UVM_LOW)
        axi_wr((this.ecam_base + (1'b1<<20) + 'h18), base_addr_32b);

        // RP BAR0 is deliberately NOT programmed.
        //
        // An RP in bridge mode claims inbound by ADDRESS MATCH, not by BAR.
        `uvm_info(get_type_name,
          "  RP BAR0            <- not programmed (Type 1 RP uses address match, not BAR match)", UVM_LOW)

        // Program the RP's Type 1 windows + Command from the test.
        //
        // 0x20 is 1 MB granularity and 32-bit only; base == limit is one
        // granule, covering the small non-prefetchable BAR. 0x24/0x28/0x2C is
        // the only window that can express a 64-bit range, which is why a
        // >4 GB BAR must be prefetchable.
        //
        // Stock seq_ps_pcie_enum hardcodes BME=0 on the RP, so 0x4 is
        // read-modify-written here to set MSE|BME.
        if (program_rp_bridge) begin
          // --- 1. state after stock enumeration ------------------------------
          axi_rd((this.ecam_base + (1'b1<<20) + 'h10), pre_b0lo);
          axi_rd((this.ecam_base + (1'b1<<20) + 'h14), pre_b0hi);
          axi_rd((this.ecam_base + (1'b1<<20) + 'h18), pre_b2);
          axi_rd((this.ecam_base + 'h4),  pre_cmd);
          axi_rd((this.ecam_base + 'h20), pre_mem);
          axi_rd((this.ecam_base + 'h24), pre_pf);
          axi_rd((this.ecam_base + 'h28), pre_pfu);
          axi_rd((this.ecam_base + 'h2c), pre_pfl);

          `rp_cfg("RP_ENUM", "")
          `rp_cfg("RP_ENUM", "=== 1. AFTER STOCK ENUMERATION (before this test programs anything) ===")
          `rp_cfg("RP_ENUM", $sformatf("  ECAM base            : 0x%0h   bus base 0x%0h",
                                       this.ecam_base, this.bus_base))
          `rp_cfg("RP_ENUM", $sformatf("  EP BAR0/1  0x10/0x14 : 0x%08h_%08h", pre_b0hi, pre_b0lo))
          `rp_cfg("RP_ENUM", $sformatf("  EP BAR2    0x18      : 0x%08h", pre_b2))
          `rp_cfg("RP_ENUM", $sformatf("  RP Command 0x04      : 0x%08h   MSE=%0b BME=%0b",
                                       pre_cmd, pre_cmd[1], pre_cmd[2]))
          `rp_cfg("RP_ENUM", $sformatf("  RP MEM     0x20      : 0x%08h   base=0x%08h limit=0x%08h  %s",
                  pre_mem, {pre_mem[15:4],20'h0}, {pre_mem[31:20],20'hFFFFF},
                  (pre_mem[31:20] < pre_mem[15:4]) ? "INVERTED (claims nothing)"
                                                   : "ACTIVE (claims this range)"))
          `rp_cfg("RP_ENUM", $sformatf("  RP PFMEM   0x24      : 0x%08h   upper 0x28=0x%08h 0x2c=0x%08h  %s",
                  pre_pf, pre_pfu, pre_pfl,
                  (pre_pf[31:20] < pre_pf[15:4]) ? "INVERTED (claims nothing)"
                                                 : "ACTIVE (claims this range)"))

          // --- 2. BAR programming performed by this sequence -----------------
          `rp_cfg("RP_BAR", "")
          `rp_cfg("RP_BAR", "=== 2. BAR PROGRAMMING (this sequence) ===")
          `rp_cfg("RP_BAR", $sformatf("  EP BAR0/1 <- 0x%016h   64-bit prefetchable", base_addr_64b))
          `rp_cfg("RP_BAR", $sformatf("  EP BAR2   <- 0x%08h           32-bit non-prefetchable", base_addr_32b))
          `rp_cfg("RP_BAR", $sformatf("  EP VDM    <- 0x%016h", base_addr_vdm))
          `rp_cfg("RP_BAR", "  RP BAR0   :  not programmed - a Type 1 RP claims by address match")

          // --- 3. bridge windows + MSE/BME, derived from those BARs ----------
          rp_mem_win       = {base_addr_32b[31:20], 4'h0,
                              base_addr_32b[31:20], 4'h0};
          rp_pfmem_base_up = base_addr_64b[63:32];
          rp_pfmem_lim_up  = base_addr_64b[63:32];

          axi_wr((this.ecam_base + 'h4), pre_cmd | 32'h0000_0006);
          axi_wr((this.ecam_base + 'h20), rp_mem_win);
          axi_wr((this.ecam_base + 'h24), rp_pfmem_win);
          axi_wr((this.ecam_base + 'h28), rp_pfmem_base_up);
          axi_wr((this.ecam_base + 'h2C), rp_pfmem_lim_up);
          axi_rd((this.ecam_base + 'h4),  rp_cmd);

          `rp_cfg("RP_BRIDGE", "")
          `rp_cfg("RP_BRIDGE", "=== 3. RP BRIDGE CONFIGURATION (written over ECAM by this test) ===")
          `rp_cfg("RP_BRIDGE", $sformatf(
            "  Command  0x04 : 0x%08h -> 0x%08h   MSE %0b->%0b  BME %0b->%0b",
            pre_cmd, rp_cmd, pre_cmd[1], rp_cmd[1], pre_cmd[2], rp_cmd[2]))
          `rp_cfg("RP_BRIDGE", $sformatf(
            "  MEM      0x20 : 0x%08h -> 0x%08h   0x%08h - 0x%08h  (non-prefetchable)",
            pre_mem, rp_mem_win, {rp_mem_win[15:4],20'h0}, {rp_mem_win[31:20],20'hFFFFF}))
          `rp_cfg("RP_BRIDGE", $sformatf(
            "  PFMEM    0x24 : 0x%08h -> 0x%08h   upper 0x28=0x%08h 0x2c=0x%08h  (64-bit)",
            pre_pf, rp_pfmem_win, rp_pfmem_base_up, rp_pfmem_lim_up))
          `rp_cfg("RP_BRIDGE", "")
          `rp_cfg("RP_BRIDGE", "=== 4. TRANSACTIONS ===")
          `rp_cfg("RP_BRIDGE", "  dir  address         target       wrote       read        result")
        end

        #1us;

        print_final_cfg_state();


        //MEM access to EP
        axi_wr(base_addr_64b, exp_64b);
        axi_wr(base_addr_32b, exp_32b);

        // Read back and CHECK. $isunknown() catches the "no valid response"
        // case, where the data bus stays X because nothing drove a completion.
        axi_rd(base_addr_64b, data_rd);
        if ($isunknown(data_rd)) begin
            `uvm_error(get_type_name, $sformatf(
              "MEM readback @ 0x%0h (BAR0, 64b pf) returned X - no valid completion: 0x%08h",
              base_addr_64b, data_rd))
            mem_errs++;
        end
        else if (data_rd !== exp_64b) begin
            `uvm_error(get_type_name, $sformatf(
              "MEM readback MISMATCH @ 0x%0h (BAR0, 64b pf): got 0x%08h  exp 0x%08h",
              base_addr_64b, data_rd, exp_64b))
            mem_errs++;
        end
        else
            `uvm_info(get_type_name, $sformatf(
              "MEM readback @ 0x%0h (BAR0, 64b pf) = 0x%08h *** MATCH ***",
              base_addr_64b, data_rd), UVM_LOW)

        rp_bridge_log::tally(.is_match(data_rd === exp_64b), .is_ur(1'b0));
        `rp_txn($sformatf("  OUT  0x%012h  %-11s  0x%08h  %-10s  %s",
                base_addr_64b, "EP BAR0/1", exp_64b,
                ($isunknown(data_rd)) ? "----------" : $sformatf("0x%08h", data_rd),
                ($isunknown(data_rd)) ? "NO COMPLETION" :
                (data_rd === exp_64b) ? "MATCH" : "MISMATCH"))

        axi_rd(base_addr_32b, data_rd);
        if ($isunknown(data_rd)) begin
            `uvm_error(get_type_name, $sformatf(
              "MEM readback @ 0x%0h (BAR2, 32b np) returned X - no valid completion: 0x%08h",
              base_addr_32b, data_rd))
            mem_errs++;
        end
        else if (data_rd !== exp_32b) begin
            `uvm_error(get_type_name, $sformatf(
              "MEM readback MISMATCH @ 0x%0h (BAR2, 32b np): got 0x%08h  exp 0x%08h",
              base_addr_32b, data_rd, exp_32b))
            mem_errs++;
        end
        else
            `uvm_info(get_type_name, $sformatf(
              "MEM readback @ 0x%0h (BAR2, 32b np) = 0x%08h *** MATCH ***",
              base_addr_32b, data_rd), UVM_LOW)

        rp_bridge_log::tally(.is_match(data_rd === exp_32b), .is_ur(1'b0));
        `rp_txn($sformatf("  OUT  0x%012h  %-11s  0x%08h  %-10s  %s",
                base_addr_32b, "EP BAR2", exp_32b,
                ($isunknown(data_rd)) ? "----------" : $sformatf("0x%08h", data_rd),
                ($isunknown(data_rd)) ? "NO COMPLETION" :
                (data_rd === exp_32b) ? "MATCH" : "MISMATCH"))

        `uvm_info(get_type_name, $sformatf(
          "Outbound MEM check summary: %0d mismatch(es) across 2 read-backs",
          mem_errs), UVM_LOW)

        // Offset 0x100 inside the 64 KB VDM window, NOT the base, so a decode
        // that only matches the base address would still be caught. An address
        // inside the 64-bit BAR window would silently issue a MEM write
        // instead of a VDM.
        `uvm_info(get_type_name, $sformatf(
          "VDM to be sent using address 0x%0h and data abcdabcd", base_addr_vdm + 'h100), UVM_MEDIUM)
        axi_wr(base_addr_vdm + 'h100, 'habcd_abcd);

    endtask

endclass
