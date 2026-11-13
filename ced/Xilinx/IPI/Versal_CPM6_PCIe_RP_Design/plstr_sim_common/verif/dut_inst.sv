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

`define DUT_TOP tb_top.ctrl_inst.dut_inst
`ifdef DDR_EN
  // IDE has a NoC: Vivado's logical NoC (xlnoc_top) is bound inside the DUT instance, see
  // tb/vivado_only/cpm6_vivado_binds.sv
  `define XLNOC_DUT_INST tb_top.ctrl_inst.dut_inst
`endif

`ifdef DDR_EN
  // ---- DDR system clock (IDE: the platform adds LPDDR5 via the NoC) ------------
  // 3127 ps period (319.8 MHz), matching axi_noc2's DDRMC5_INPUTCLK0_PERIOD=3127.
  // The LPDDR5 DRAM model lives inside the BD (ddrmc5_responder_0), so the
  // CH0_LPDDR5_0_* pins are left unconnected.
  bit  ddr_sysclk_p;
  wire ddr_sysclk_n = ~ddr_sysclk_p;
  initial forever ddr_sysclk_p = #1.5635ns ~ddr_sysclk_p;
`endif

  // Clock signal declarations
  bit ctrl1_gt_refclk_0_clk_n;
  bit ctrl1_gt_refclk_0_clk_p;
  bit ctrl0_gt_refclk_0_clk_n;
  bit ctrl0_gt_refclk_0_clk_p;
  bit dbi1_clk_0;
  bit dbi1_rstn_0;
  bit pcie1_clk_0;
  bit pcie1_rstn_0;

  bit pl0_resetn_0;
  bit pl0_ref_clk_0;

   task automatic clkgen_basic(input shortreal delay, input shortreal clk_T, ref bit clk);
        #delay;
        clk = 1'b0;
        forever clk = #(clk_T/2) !clk;
    endtask

  initial begin
    fork
      clkgen_basic (0,   10.0,   ctrl1_gt_refclk_0_clk_n);
      clkgen_basic (0,   10.0,   ctrl1_gt_refclk_0_clk_p);
      clkgen_basic (0,   10.0,   ctrl0_gt_refclk_0_clk_n);
      clkgen_basic (0,   10.0,   ctrl0_gt_refclk_0_clk_p);
    join_none
  end

  //////DUT Instantiation//////
generate
  if (tb_top.LINK0_WIDTH != 0) begin : ctrl_inst
    rp_plstr_top_wrapper_ctrl0 dut_inst (
      .CTRL0_GT_0_grx_n       (/* CTRL0_GT_0_grx_n */),
      .CTRL0_GT_0_grx_p       (/* CTRL0_GT_0_grx_p */),
      .CTRL0_GT_0_gtx_n       (/* CTRL0_GT_0_gtx_n */),
      .CTRL0_GT_0_gtx_p       (/* CTRL0_GT_0_gtx_p */),
      .ctrl0_gt_refclk_0_clk_n(ctrl0_gt_refclk_0_clk_n),
      .ctrl0_gt_refclk_0_clk_p(ctrl0_gt_refclk_0_clk_p)
`ifdef DDR_EN
      ,
      .sys_clk0_0_clk_p       (ddr_sysclk_p),
      .sys_clk0_0_clk_n       (ddr_sysclk_n)
`endif
/*,
      // .dbi0_clk_0             (dbi0_clk_0),
      .dbi0_rstn_0            (dbi0_rstn_0),
      // .pcie0_clk_0            (pcie0_clk_0),
      .pcie0_rstn_0           (pcie0_rstn_0),
      .pl0_resetn_0           (pl0_resetn_0),
      .pl0_ref_clk          (pl0_ref_clk_0)*/
    );
  end
  else begin : ctrl_inst
    // CTRL1: instantiate rp_plstr_top_wrapper_ctrl1
    rp_plstr_top_wrapper_ctrl1 dut_inst (
      .CTRL1_GT_0_grx_n       (/* CTRL1_GT_0_grx_n */),
      .CTRL1_GT_0_grx_p       (/* CTRL1_GT_0_grx_p */),
      .CTRL1_GT_0_gtx_n       (/* CTRL1_GT_0_gtx_n */),
      .CTRL1_GT_0_gtx_p       (/* CTRL1_GT_0_gtx_p */),
      .ctrl1_gt_refclk_0_clk_n(ctrl1_gt_refclk_0_clk_n),
      .ctrl1_gt_refclk_0_clk_p(ctrl1_gt_refclk_0_clk_p)
`ifdef DDR_EN
      ,
      .sys_clk0_0_clk_p       (ddr_sysclk_p),
      .sys_clk0_0_clk_n       (ddr_sysclk_n)
`endif
/*,
      // .dbi1_clk_0             (dbi1_clk_0),
      .dbi1_rstn_0            (dbi1_rstn_0),
      // .pcie1_clk_0            (pcie1_clk_0),
      .pcie1_rstn_0           (pcie1_rstn_0),
      .pl0_resetn_0           (pl0_resetn_0),
      .pl0_ref_clk          (pl0_ref_clk_0)*/
    );
  end
endgenerate




  // RX CREDIT Interface
  cr_str_if rx_cr_str_if_inst(
    .clk       (`DUT_TOP.pl0_ref_clk)
  );

  assign rx_cr_str_if_inst.cr = `DUT_TOP.rp_top_inst.rx_credit;
  assign rx_cr_str_if_inst.cr_active = `DUT_TOP.rp_top_inst.rx_credit_active;
  assign rx_cr_str_if_inst.cr_valid = `DUT_TOP.rp_top_inst.rx_credit_valid;

  // TX CREDIT Interface
  cr_str_if tx_cr_str_if_inst(
    .clk       (`DUT_TOP.pl0_ref_clk)
  );

  assign tx_cr_str_if_inst.cr = `DUT_TOP.rp_top_inst.tx_credit;
  assign tx_cr_str_if_inst.cr_active = `DUT_TOP.rp_top_inst.tx_credit_active;
  assign tx_cr_str_if_inst.cr_valid = `DUT_TOP.rp_top_inst.tx_credit_valid;

  // RX STR Interface
  rx_str_if rx_inst(
    .clk       (`DUT_TOP.pl0_ref_clk)
  );

  assign rx_inst.rx_intf.rx_valid = `DUT_TOP.rp_top_inst.rx_valid;
  assign rx_inst.rx_intf.rx_data = {
            {{(pcie_str_pkg::RX_SLOT_WIDTH - 512){1'b0}}, `DUT_TOP.rp_top_inst.rx_data[1535:1024]},
            {{(pcie_str_pkg::RX_SLOT_WIDTH - 512){1'b0}}, `DUT_TOP.rp_top_inst.rx_data[1023:512]},
            {{(pcie_str_pkg::RX_SLOT_WIDTH - 512){1'b0}}, `DUT_TOP.rp_top_inst.rx_data[511:0]}
        };
  assign rx_inst.rx_intf.rx_start = `DUT_TOP.rp_top_inst.rx_start;
  assign rx_inst.rx_intf.rx_end = `DUT_TOP.rp_top_inst.rx_end;
  assign rx_inst.rx_intf.rx_startptr[0] = `DUT_TOP.rp_top_inst.rx_start0ptr;
  assign rx_inst.rx_intf.rx_startptr[1] = `DUT_TOP.rp_top_inst.rx_start1ptr;
  assign rx_inst.rx_intf.rx_startptr[2] = `DUT_TOP.rp_top_inst.rx_start2ptr;
  assign rx_inst.rx_intf.rx_endptr[0] = `DUT_TOP.rp_top_inst.rx_end0ptr;
  assign rx_inst.rx_intf.rx_endptr[1] = `DUT_TOP.rp_top_inst.rx_end1ptr;
  assign rx_inst.rx_intf.rx_endptr[2] = `DUT_TOP.rp_top_inst.rx_end2ptr;
  assign rx_inst.rx_intf.rx_startnpinfo[0] = `DUT_TOP.rp_top_inst.rx_start0npinfo;
  assign rx_inst.rx_intf.rx_startnpinfo[1] = `DUT_TOP.rp_top_inst.rx_start1npinfo;
  assign rx_inst.rx_intf.rx_startnpinfo[2] = `DUT_TOP.rp_top_inst.rx_start2npinfo;
  assign rx_inst.rx_intf.rx_starttype[0] = `DUT_TOP.rp_top_inst.rx_start0type;
  assign rx_inst.rx_intf.rx_starttype[1] = `DUT_TOP.rp_top_inst.rx_start1type;
  assign rx_inst.rx_intf.rx_starttype[2] = `DUT_TOP.rp_top_inst.rx_start2type;
  assign rx_inst.rx_intf.rx_parity = `DUT_TOP.rp_top_inst.rx_parity;
  assign rx_inst.rx_intf.rx_end_error = `DUT_TOP.rp_top_inst.rx_end_err;

  // TX STR Interface
  tx_str_if tx_inst(
    .clk       (`DUT_TOP.pl0_ref_clk)
  );

  assign tx_inst.tx_intf.tx_valid = `DUT_TOP.rp_top_inst.tx_valid;
  assign tx_inst.tx_intf.tx_data[0] = `DUT_TOP.rp_top_inst.tx_data[pcie_str_pkg::TX_SLOT_WIDTH-1:0];
  assign tx_inst.tx_intf.tx_data[1] = `DUT_TOP.rp_top_inst.tx_data[(2*pcie_str_pkg::TX_SLOT_WIDTH)-1:pcie_str_pkg::TX_SLOT_WIDTH];
  assign tx_inst.tx_intf.tx_data[2] = `DUT_TOP.rp_top_inst.tx_data[(3*pcie_str_pkg::TX_SLOT_WIDTH)-1:(2*pcie_str_pkg::TX_SLOT_WIDTH)];
  assign tx_inst.tx_intf.tx_start = `DUT_TOP.rp_top_inst.tx_start;
  assign tx_inst.tx_intf.tx_end = `DUT_TOP.rp_top_inst.tx_end;
  assign tx_inst.tx_intf.tx_startptr[0] = `DUT_TOP.rp_top_inst.tx_start0ptr;
  assign tx_inst.tx_intf.tx_startptr[1] = `DUT_TOP.rp_top_inst.tx_start1ptr;
  assign tx_inst.tx_intf.tx_startptr[2] = `DUT_TOP.rp_top_inst.tx_start2ptr;
  assign tx_inst.tx_intf.tx_endptr[0] = `DUT_TOP.rp_top_inst.tx_end0ptr;
  assign tx_inst.tx_intf.tx_endptr[1] = `DUT_TOP.rp_top_inst.tx_end1ptr;
  assign tx_inst.tx_intf.tx_endptr[2] = `DUT_TOP.rp_top_inst.tx_end2ptr;
  assign tx_inst.tx_intf.tx_startnpinfo[0] = `DUT_TOP.rp_top_inst.tx_start0npinfo;
  assign tx_inst.tx_intf.tx_startnpinfo[1] = `DUT_TOP.rp_top_inst.tx_start1npinfo;
  assign tx_inst.tx_intf.tx_startnpinfo[2] = `DUT_TOP.rp_top_inst.tx_start2npinfo;
  assign tx_inst.tx_intf.tx_starttype[0] = `DUT_TOP.rp_top_inst.tx_start0type;
  assign tx_inst.tx_intf.tx_starttype[1] = `DUT_TOP.rp_top_inst.tx_start1type;
  assign tx_inst.tx_intf.tx_starttype[2] = `DUT_TOP.rp_top_inst.tx_start2type;
  assign tx_inst.tx_intf.tx_parity = `DUT_TOP.rp_top_inst.tx_parity;
  assign tx_inst.tx_intf.tx_end_error = `DUT_TOP.rp_top_inst.tx_end_error;

  // PL DBI Interface
  pl_dbi_if pl_dbi_if_inst(
    .clk       (`DUT_TOP.pl0_ref_clk)
  );

  assign pl_dbi_if_inst.dbi_araddr = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_araddr;
  assign pl_dbi_if_inst.dbi_arprot = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_arprot;
  assign pl_dbi_if_inst.dbi_arvalid = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_arvalid;
  assign pl_dbi_if_inst.dbi_arready = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_arready;
  assign pl_dbi_if_inst.dbi_aruser = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_aruser;
  assign pl_dbi_if_inst.dbi_rdata = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_rdata;
  assign pl_dbi_if_inst.dbi_rresp = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_rresp;
  assign pl_dbi_if_inst.dbi_rvalid = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_rvalid;
  assign pl_dbi_if_inst.dbi_rready = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_rready;
  assign pl_dbi_if_inst.dbi_awaddr = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_awaddr;
  assign pl_dbi_if_inst.dbi_awprot = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_awprot;
  assign pl_dbi_if_inst.dbi_awvalid = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_awvalid;
  assign pl_dbi_if_inst.dbi_awready = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_awready;
  assign pl_dbi_if_inst.dbi_awuser = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_awuser;
  assign pl_dbi_if_inst.dbi_wdata = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_wdata;
  assign pl_dbi_if_inst.dbi_wstrb = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_wstrb;
  assign pl_dbi_if_inst.dbi_wvalid = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_wvalid;
  assign pl_dbi_if_inst.dbi_wready = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_wready;
  assign pl_dbi_if_inst.dbi_bresp = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_bresp;
  assign pl_dbi_if_inst.dbi_bvalid = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_bvalid;
  assign pl_dbi_if_inst.dbi_bready = `DUT_TOP.rp_top_inst.pl_dbi_axil_if_bready;

  // PF CFG Status to PL Interface
  pf_cfg_if pf_cfg_status_if_inst(
    .clk       (`DUT_TOP.pl0_ref_clk)
  );

  assign pf_cfg_status_if_inst.pf_cfg_status_pvld                       =  `DUT_TOP.rp_top_inst.pf_cfg_status_pvld;
  assign pf_cfg_status_if_inst.pf_cfg_status_sos                        =  `DUT_TOP.rp_top_inst.pf_cfg_status_sos;
  assign pf_cfg_status_if_inst.pf_cfg_status_func_num                   =  `DUT_TOP.rp_top_inst.pf_cfg_status_func_num;
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.flr_pf_active      =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[15];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.rcb                =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[14];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.ext_tag_en         =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[13];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.max_payload_size   =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[12:10];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.max_rd_req_size    =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[9:7];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.atomic_req_en      =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[6];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.pf_pasid_en        =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[5];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.msix_func_mask     =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[4];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.msix_en            =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[3];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.msi_en             =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[2];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.mem_space_en       =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[1];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c0.bus_master_en      =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[0];

  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.flit_mode          =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[15];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.pm_turnoff         =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[14];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.reserved          =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[13:11];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.tph_req_en       =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[10:9];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.prs_en          =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[8];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.ats_cache_en    =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[7];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.pasid_priv_mode_en =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[6];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.pasid_execute_perm_en =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[5];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.io_space_en     =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[4];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.pm_status       =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[3];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.int_disable     =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[2];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.vf_en          =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[1];
  assign pf_cfg_status_if_inst.pf_cfg_status_info.c1.tenb_tag_req_en =  `DUT_TOP.rp_top_inst.pf_cfg_status_info[0];

  vf_cfg_if vf_cfg_status_if_inst(
    .clk       (`DUT_TOP.pl0_ref_clk)
  );

  assign vf_cfg_status_if_inst.vf_cfg_status_vld                       =  `DUT_TOP.rp_top_inst.vf_cfg_status_pvld;
  assign vf_cfg_status_if_inst.vf_cfg_status_sos                        =  `DUT_TOP.rp_top_inst.vf_cfg_status_sos;
  assign vf_cfg_status_if_inst.vf_cfg_status_func_num                   =  `DUT_TOP.rp_top_inst.vf_cfg_status_func_num;
  assign vf_cfg_status_if_inst.vf_cfg_status_info.flr_vf_active      =  `DUT_TOP.rp_top_inst.vf_cfg_status_info[4];
  assign vf_cfg_status_if_inst.vf_cfg_status_info.vf_msix_func_mask  =  `DUT_TOP.rp_top_inst.vf_cfg_status_info[3];
  assign vf_cfg_status_if_inst.vf_cfg_status_info.vf_msix_en         =  `DUT_TOP.rp_top_inst.vf_cfg_status_info[2];
  assign vf_cfg_status_if_inst.vf_cfg_status_info.vf_msi_en          =  `DUT_TOP.rp_top_inst.vf_cfg_status_info[1];
  assign vf_cfg_status_if_inst.vf_cfg_status_info.vf_bme             =  `DUT_TOP.rp_top_inst.vf_cfg_status_info[0];

  initial begin
    uvm_config_db#(virtual cr_str_if.monitor_mp)::set(null, "*", "rx_cr_vif", rx_cr_str_if_inst);
    uvm_config_db#(virtual cr_str_if.monitor_mp)::set(null, "*", "tx_cr_vif", tx_cr_str_if_inst);
    uvm_config_db#(virtual rx_str_if.monitor_mp)::set(null, "*", "rx_str_if", rx_inst);
    uvm_config_db#(virtual tx_str_if.monitor_mp)::set(null, "*", "tx_str_if", tx_inst);
    uvm_config_db#(virtual pl_dbi_if.monitor_mp)::set(null, "*", "pl_dbi_if", pl_dbi_if_inst);
    uvm_config_db#(virtual pf_cfg_if.monitor_mp)::set(null, "*", "pf_cfg_if", pf_cfg_status_if_inst);
    uvm_config_db#(virtual vf_cfg_if.monitor_mp)::set(null, "*", "vf_cfg_if", vf_cfg_status_if_inst);
  end

  dut_err_cnt_if dut_err_cnt_if_inst(
      .clk       (`DUT_TOP.pl0_ref_clk)
  );

  // Connect the DUT error counter interface to the DUT
  assign dut_err_cnt_if_inst.error_counts = `DUT_TOP.rp_top_inst.error_counts;

  initial begin
    uvm_config_db#(virtual dut_err_cnt_if.monitor_mp)::set(null, "*", "dut_err_cnt_if", dut_err_cnt_if_inst);
  end

  link_if link_if_inst(
    .clk       (`DUT_TOP.pl0_ref_clk)
  );

  assign link_if_inst.link_down = `DUT_TOP.rp_top_inst.link_down;
  assign link_if_inst.reset = ~`DUT_TOP.rp_top_inst.rst_n;

  initial begin
    uvm_config_db#(virtual link_if.monitor_mp)::set(null, "*", "link_if", link_if_inst);
  end
