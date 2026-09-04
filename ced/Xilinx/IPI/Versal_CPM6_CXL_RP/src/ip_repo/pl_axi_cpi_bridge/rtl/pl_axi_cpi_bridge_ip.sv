// MODULE : pl_axi_cpi_bridge_ip
//
// DESCRIPTION:
// Pure-port packaging wrapper around pl_axi_cpi_bridge. The DUT exposes the
// CPI REQ/DATA/RSP channels and the debug GPIO bus as SystemVerilog
// interfaces, which the Vivado IP Packager cannot expose on a packaged IP's
// external boundary. This wrapper instantiates those interfaces internally
// and unrolls every field to a flat vector port so the module below can be
// packaged and dropped into a Vivado block design.
//
// All ports here are a 1:1, direction-preserving unroll of the interface
// fields defined in cpi_ifs.sv and debug_gpio_ifs.axi_cpi_bridge.sv against
// the modports used by pl_axi_cpi_bridge (f2a_req/f2a_dat: master,
// a2f_rsp/a2f_dat: slave, dbg_gpio_if: master).

module pl_axi_cpi_bridge_ip
  import cpi_pkg::req_hdr_u;
  import cpi_pkg::data_hdr_u;
  import cpi_pkg::rsp_hdr_u;
#(
  // General Parameters
  parameter bit [1:0] BRDG_ID,
  // Debug Related
  parameter bit [1:0] DEBUG_IF_EN  = 0, //[0]=GPIO enable; [1]=AXI-L enable
  parameter bit       DEBUG_EN_BCD = 1,
  // AXI Interface Parameters
  parameter AXI_ADDR_WIDTH = 48,
  // Feature Enablement -> controls AXI User Bits
  parameter bit   USER_POISN_SUPP     = 0, //[0, 1]
  // USER_METAD_SUPP is derived below from USER_METAD_MODE/EMD_BITS (a GUI
  // selector split into a mode combo box plus a width field), so it is
  // never exposed as its own parameter.
  parameter  USER_METAD_MODE = 0, //0=None,1=2bit MetaData,2=Extended MetaData
  parameter  EMD_BITS        = 8, //valid 1-32; only used when USER_METAD_MODE==2
  localparam USER_METAD_SUPP = (USER_METAD_MODE==0) ? 0 :
                               (USER_METAD_MODE==1) ? -1 : EMD_BITS,
  parameter bit   USER_DEVLD_SUPP     = 0, //[0, 1]
  parameter bit ARUSER_MEMSPECRD_SUPP = 0, //[0, 1]
  parameter bit ARUSER_MEMINV_SUPP    = 0, //[0, 1]
  parameter bit ARUSER_MEMINVNT_SUPP  = 0, //[0, 1]
  // CPI Interface Parameters
  parameter bit EN_CMD_PARITY = 0,
  parameter bit EN_DAT_PARITY = 0,
  parameter bit EN_BEN_PARITY = 0,
  parameter bit EN_ADR_PARITY = 0,
  // Internal Functionality Parameters
  parameter WROB_DEPTH = 64, //[1,2,4,8...256]
  parameter RROB_DEPTH = 64, //[1,2,4,8...256]
  // --- Port Widths (mirrors pl_axi_cpi_bridge; kept in sync with it) --- //
  // AXI_ID_WIDTH is the user-facing knob (validated 1-4 in the IP GUI).
  // AXI_IDS_SUPP -- the actual outstanding-AXI-ID count the DUT wants --
  // is derived from it below as a localparam, so it is never exposed as
  // its own parameter and never shows up in the customization GUI.
  parameter  AXI_ID_WIDTH    = 3,
  localparam AXI_IDS_SUPP    = 1 << AXI_ID_WIDTH, //max=16 (AXI_ID_WIDTH<=4)
  // Fixed CPI/AXI protocol widths. These are plain integer literals
  // (rather than expressions referencing other localparams or $bits())
  // because the IP Packager's port-width resolver can't evaluate those
  // forms either. None of these depend on the parameters above; update
  // them if AXI_DATA_WIDTH ever changes. REQ/DAT/RSP_HDR_WIDTH assume
  // CXL_IDE_EPOCH_SUPPORT+CXL_ACTIVE_PORTS=2 (set via verilog_define in
  // package_ip.tcl) so the f2a_req/f2a_dat/a2f_rsp/a2f_dat bus interfaces
  // match real CPM6's cpi_req/cpi_data/cpi_rsp header widths exactly,
  // enabling a direct interface connection to a real CPM6 instance.
  localparam AXI_DATA_WIDTH  = 512,
  localparam AXI_STRB_WIDTH  = 64,
  localparam WUSER_MAX_WIDTH = 1+32,
  localparam ARUSER_MAX_WIDTH= 2+1+32,
  localparam RUSER_MAX_WIDTH = 2+32,
  localparam BUSER_MAX_WIDTH = 2,
  localparam REQ_HDR_WIDTH   = 87,
  localparam DAT_HDR_WIDTH   = 88,
  localparam RSP_HDR_WIDTH   = 41,
  localparam DAT_PARITY_W    = 8
)(
  /*** AMBA AXI H.c Revision Interface - Slave Port ***/
  input                          s_axi_aclk,
  input                          s_axi_aresetn,
  //-- Write Address Channel
  input  [AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
  input  [  AXI_ID_WIDTH-1:0]    s_axi_awid,
  input  [               2:0]    s_axi_awprot,
  input  [               1:0]    s_axi_awburst,
  input  [               2:0]    s_axi_awsize,
  input  [               3:0]    s_axi_awcache,
  input  [               7:0]    s_axi_awlen,
  input                          s_axi_awlock,
  input                          s_axi_awvalid,
  output                         s_axi_awready,
  //-- Write Data Channel
  input  [WUSER_MAX_WIDTH-1:0]   s_axi_wuser,
  input  [ AXI_DATA_WIDTH-1:0]   s_axi_wdata,
  input  [ AXI_STRB_WIDTH-1:0]   s_axi_wstrb,
  input                          s_axi_wlast,
  input                          s_axi_wvalid,
  output                         s_axi_wready,
  //-- Write Response Channel
  output [BUSER_MAX_WIDTH-1:0]   s_axi_buser,
  output                         s_axi_bvalid,
  input                          s_axi_bready,
  output [ AXI_ID_WIDTH-1:0]     s_axi_bid,
  output [              1:0]     s_axi_bresp,
  //-- Read Address Channel
  input  [ARUSER_MAX_WIDTH-1:0]  s_axi_aruser,
  input  [  AXI_ADDR_WIDTH-1:0]  s_axi_araddr,
  input  [    AXI_ID_WIDTH-1:0]  s_axi_arid,
  input  [                 2:0]  s_axi_arprot,
  input  [                 1:0]  s_axi_arburst,
  input  [                 2:0]  s_axi_arsize,
  input  [                 3:0]  s_axi_arcache,
  input  [                 7:0]  s_axi_arlen,
  input                          s_axi_arlock,
  input                          s_axi_arvalid,
  output                         s_axi_arready,
  //-- Read Data Channel
  output [RUSER_MAX_WIDTH-1:0]   s_axi_ruser,
  output [   AXI_ID_WIDTH-1:0]   s_axi_rid,
  output [ AXI_DATA_WIDTH-1:0]   s_axi_rdata,
  output [              1:0]     s_axi_rresp,
  output                         s_axi_rvalid,
  output                         s_axi_rlast,
  input                          s_axi_rready,
  /*** Intel CPI v1.0 Interface - REQ Channel (Fabric2Agent: DSP CXL.mem) ***/
  output                         f2a_req_is_valid,
  output                         f2a_req_early_valid,
  output [               3:0]    f2a_req_protocol_id,
  output [               3:0]    f2a_req_vc_id,
  output                         f2a_req_shared_credit,
  output [REQ_HDR_WIDTH-1:0]     f2a_req_header,
  output                         f2a_req_cmd_parity,
  output [              11:0]    f2a_req_spid,
  output [              11:0]    f2a_req_dpid,
  output                         f2a_req_txblock_crd_flow,
  input                          f2a_req_block,
  input                          f2a_req_rxcrd_valid,
  input  [               3:0]    f2a_req_rxcrd_protocol_id,
  input  [               3:0]    f2a_req_rxcrd_vc_id,
  input                          f2a_req_rxcrd_shared,
  /*** Intel CPI v1.0 Interface - DAT Channel (Fabric2Agent: DSP CXL.mem) ***/
  output                         f2a_dat_is_valid,
  output                         f2a_dat_early_valid,
  output [               3:0]    f2a_dat_protocol_id,
  output [               3:0]    f2a_dat_vc_id,
  output                         f2a_dat_shared_credit,
  output [DAT_HDR_WIDTH-1:0]     f2a_dat_header,
  output                         f2a_dat_sz,
  output                         f2a_dat_cmd_parity,
  output [              11:0]    f2a_dat_spid,
  output [              11:0]    f2a_dat_dpid,
  output [ AXI_DATA_WIDTH-1:0]   f2a_dat_body,
  output [ AXI_STRB_WIDTH-1:0]   f2a_dat_byte_enable,
  output                         f2a_dat_byte_enable_parity,
  output                         f2a_dat_poison,
  output [ DAT_PARITY_W-1:0]     f2a_dat_parity,
  output                         f2a_dat_eop,
  output                         f2a_dat_txblock_crd_flow,
  input                          f2a_dat_block,
  input                          f2a_dat_rxcrd_valid,
  input  [               3:0]    f2a_dat_rxcrd_protocol_id,
  input  [               3:0]    f2a_dat_rxcrd_vc_id,
  input                          f2a_dat_rxcrd_shared,
  output [              31:0]    f2a_dat_emd, //TTA if USER_METAD_SUPP<=0
  /*** Intel CPI v1.0 Interface - RSP Channel (Agent2Fabric: DSP CXL.mem) ***/
  input                          a2f_rsp_is_valid,
  input                          a2f_rsp_early_valid,
  input  [               3:0]    a2f_rsp_protocol_id,
  input  [               3:0]    a2f_rsp_vc_id,
  input                          a2f_rsp_shared_credit,
  input  [RSP_HDR_WIDTH-1:0]     a2f_rsp_header,
  input                          a2f_rsp_cmd_parity,
  input  [              11:0]    a2f_rsp_spid,
  input  [              11:0]    a2f_rsp_dpid,
  input                          a2f_rsp_txblock_crd_flow,
  output                         a2f_rsp_block,
  output                         a2f_rsp_rxcrd_valid,
  output [               3:0]    a2f_rsp_rxcrd_protocol_id,
  output [               3:0]    a2f_rsp_rxcrd_vc_id,
  output                         a2f_rsp_rxcrd_shared,
  /*** Intel CPI v1.0 Interface - DAT Channel (Agent2Fabric: DSP CXL.mem) ***/
  input                          a2f_dat_is_valid,
  input                          a2f_dat_early_valid,
  input  [               3:0]    a2f_dat_protocol_id,
  input  [               3:0]    a2f_dat_vc_id,
  input                          a2f_dat_shared_credit,
  input  [DAT_HDR_WIDTH-1:0]     a2f_dat_header,
  input                          a2f_dat_sz,
  input                          a2f_dat_cmd_parity,
  input  [              11:0]    a2f_dat_spid,
  input  [              11:0]    a2f_dat_dpid,
  input  [ AXI_DATA_WIDTH-1:0]   a2f_dat_body,
  input  [ AXI_STRB_WIDTH-1:0]   a2f_dat_byte_enable,
  input                          a2f_dat_byte_enable_parity,
  input                          a2f_dat_poison,
  input  [ DAT_PARITY_W-1:0]     a2f_dat_parity,
  input                          a2f_dat_eop,
  input                          a2f_dat_txblock_crd_flow,
  output                         a2f_dat_block,
  output                         a2f_dat_rxcrd_valid,
  output [               3:0]    a2f_dat_rxcrd_protocol_id,
  output [               3:0]    a2f_dat_rxcrd_vc_id,
  output                         a2f_dat_rxcrd_shared,
  input  [              31:0]    a2f_dat_emd, //TTA if USER_METAD_SUPP<=0
  //*** Debug Signals ***/
  //-- GPIO
  input                          dbg_gpio_cnt_reset,
  input                          dbg_gpio_cnt_enable,
  input                          dbg_gpio_cnt_freerun,
  output [              15:0]    dbg_gpio_axi_wr_start_cnt,
  output [              18:0]    dbg_gpio_axi_wr_start_bcd,
  output [              15:0]    dbg_gpio_axi_wr_compl_cnt,
  output [              18:0]    dbg_gpio_axi_wr_compl_bcd,
  output [              15:0]    dbg_gpio_axi_rd_start_cnt,
  output [              18:0]    dbg_gpio_axi_rd_start_bcd,
  output [              15:0]    dbg_gpio_axi_rd_compl_cnt,
  output [              18:0]    dbg_gpio_axi_rd_compl_bcd,
  output [              15:0]    dbg_gpio_f2a_req_cnt,
  output [              18:0]    dbg_gpio_f2a_req_bcd,
  output [              15:0]    dbg_gpio_f2a_dat_cnt,
  output [              18:0]    dbg_gpio_f2a_dat_bcd,
  output [              15:0]    dbg_gpio_a2f_rsp_cnt,
  output [              18:0]    dbg_gpio_a2f_rsp_bcd,
  output [              15:0]    dbg_gpio_a2f_dat_cnt,
  output [              18:0]    dbg_gpio_a2f_dat_bcd,
  output [              15:0]    dbg_gpio_f2a_dat_emd_cnt,
  output [              18:0]    dbg_gpio_f2a_dat_emd_bcd,
  output [              15:0]    dbg_gpio_a2f_dat_emd_cnt,
  output [              18:0]    dbg_gpio_a2f_dat_emd_bcd,
  //-- AXI-Lite
  input                          s_axil_aclk,
  input                          s_axil_aresetn,
  //  . AW
  input                          s_axil_awvalid,
  output                         s_axil_awready,
  input  [15:0]                  s_axil_awaddr,
  input  [ 2:0]                  s_axil_awprot,
  //  .  W
  input                          s_axil_wvalid,
  output                         s_axil_wready,
  input  [31:0]                  s_axil_wdata,
  input  [ 3:0]                  s_axil_wstrb,
  //  .  B
  output                         s_axil_bvalid,
  input                          s_axil_bready,
  output [ 1:0]                  s_axil_bresp,
  //  . AR
  input                          s_axil_arvalid,
  output                         s_axil_arready,
  input  [15:0]                  s_axil_araddr,
  input  [ 2:0]                  s_axil_arprot,
  //  .  R
  output                         s_axil_rvalid,
  input                          s_axil_rready,
  output [ 1:0]                  s_axil_rresp,
  output [31:0]                  s_axil_rdata
);

  /*** Internal SV Interface Instances (unrolled to the flat ports above) ***/
  cpi_req              f2a_req_if();
  cpi_data              f2a_dat_if();
  cpi_rsp                a2f_rsp_if();
  cpi_data                a2f_dat_if();
  debug_axi_cpi_bridge dbg_gpio_if_i();

  //-- f2a_req (cpi_req.master) : DUT-driven fields read out, block/credit fed in
  assign f2a_req_is_valid          = f2a_req_if.is_valid;
  assign f2a_req_early_valid       = f2a_req_if.early_valid;
  assign f2a_req_protocol_id       = f2a_req_if.protocol_id;
  assign f2a_req_vc_id             = f2a_req_if.vc_id;
  assign f2a_req_shared_credit     = f2a_req_if.shared_credit;
  assign f2a_req_header            = f2a_req_if.header;
  assign f2a_req_cmd_parity        = f2a_req_if.cmd_parity;
  assign f2a_req_spid              = f2a_req_if.spid;
  assign f2a_req_dpid              = f2a_req_if.dpid;
  assign f2a_req_txblock_crd_flow  = f2a_req_if.txblock_crd_flow;
  assign f2a_req_if.block             = f2a_req_block;
  assign f2a_req_if.rxcrd_valid       = f2a_req_rxcrd_valid;
  assign f2a_req_if.rxcrd_protocol_id = f2a_req_rxcrd_protocol_id;
  assign f2a_req_if.rxcrd_vc_id       = f2a_req_rxcrd_vc_id;
  assign f2a_req_if.rxcrd_shared      = f2a_req_rxcrd_shared;

  //-- f2a_dat (cpi_data.master) : DUT-driven fields read out, block/credit fed in
  assign f2a_dat_is_valid           = f2a_dat_if.is_valid;
  assign f2a_dat_early_valid        = f2a_dat_if.early_valid;
  assign f2a_dat_protocol_id        = f2a_dat_if.protocol_id;
  assign f2a_dat_vc_id              = f2a_dat_if.vc_id;
  assign f2a_dat_shared_credit      = f2a_dat_if.shared_credit;
  assign f2a_dat_header             = f2a_dat_if.header;
  assign f2a_dat_sz                 = f2a_dat_if.sz;
  assign f2a_dat_cmd_parity         = f2a_dat_if.cmd_parity;
  assign f2a_dat_spid               = f2a_dat_if.spid;
  assign f2a_dat_dpid               = f2a_dat_if.dpid;
  assign f2a_dat_body               = f2a_dat_if.body;
  assign f2a_dat_byte_enable        = f2a_dat_if.byte_enable;
  assign f2a_dat_byte_enable_parity = f2a_dat_if.byte_enable_parity;
  assign f2a_dat_poison             = f2a_dat_if.poison;
  assign f2a_dat_parity             = f2a_dat_if.parity;
  assign f2a_dat_eop                = f2a_dat_if.eop;
  assign f2a_dat_txblock_crd_flow   = f2a_dat_if.txblock_crd_flow;
  assign f2a_dat_if.block             = f2a_dat_block;
  assign f2a_dat_if.rxcrd_valid       = f2a_dat_rxcrd_valid;
  assign f2a_dat_if.rxcrd_protocol_id = f2a_dat_rxcrd_protocol_id;
  assign f2a_dat_if.rxcrd_vc_id       = f2a_dat_rxcrd_vc_id;
  assign f2a_dat_if.rxcrd_shared      = f2a_dat_rxcrd_shared;

  //-- a2f_rsp (cpi_rsp.slave) : fields fed in, block/credit read out
  assign a2f_rsp_if.is_valid       = a2f_rsp_is_valid;
  assign a2f_rsp_if.early_valid    = a2f_rsp_early_valid;
  assign a2f_rsp_if.protocol_id    = a2f_rsp_protocol_id;
  assign a2f_rsp_if.vc_id          = a2f_rsp_vc_id;
  assign a2f_rsp_if.shared_credit  = a2f_rsp_shared_credit;
  assign a2f_rsp_if.header         = rsp_hdr_u'(a2f_rsp_header);
  assign a2f_rsp_if.cmd_parity     = a2f_rsp_cmd_parity;
  assign a2f_rsp_if.spid           = a2f_rsp_spid;
  assign a2f_rsp_if.dpid           = a2f_rsp_dpid;
  assign a2f_rsp_if.txblock_crd_flow = a2f_rsp_txblock_crd_flow;
  assign a2f_rsp_block               = a2f_rsp_if.block;
  assign a2f_rsp_rxcrd_valid         = a2f_rsp_if.rxcrd_valid;
  assign a2f_rsp_rxcrd_protocol_id   = a2f_rsp_if.rxcrd_protocol_id;
  assign a2f_rsp_rxcrd_vc_id         = a2f_rsp_if.rxcrd_vc_id;
  assign a2f_rsp_rxcrd_shared        = a2f_rsp_if.rxcrd_shared;

  //-- a2f_dat (cpi_data.slave) : fields fed in, block/credit read out
  assign a2f_dat_if.is_valid           = a2f_dat_is_valid;
  assign a2f_dat_if.early_valid        = a2f_dat_early_valid;
  assign a2f_dat_if.protocol_id        = a2f_dat_protocol_id;
  assign a2f_dat_if.vc_id              = a2f_dat_vc_id;
  assign a2f_dat_if.shared_credit      = a2f_dat_shared_credit;
  assign a2f_dat_if.header             = data_hdr_u'(a2f_dat_header);
  assign a2f_dat_if.sz                 = a2f_dat_sz;
  assign a2f_dat_if.cmd_parity         = a2f_dat_cmd_parity;
  assign a2f_dat_if.spid               = a2f_dat_spid;
  assign a2f_dat_if.dpid               = a2f_dat_dpid;
  assign a2f_dat_if.body               = a2f_dat_body;
  assign a2f_dat_if.byte_enable        = a2f_dat_byte_enable;
  assign a2f_dat_if.byte_enable_parity = a2f_dat_byte_enable_parity;
  assign a2f_dat_if.poison             = a2f_dat_poison;
  assign a2f_dat_if.parity             = a2f_dat_parity;
  assign a2f_dat_if.eop                = a2f_dat_eop;
  assign a2f_dat_if.txblock_crd_flow   = a2f_dat_txblock_crd_flow;
  assign a2f_dat_block                 = a2f_dat_if.block;
  assign a2f_dat_rxcrd_valid           = a2f_dat_if.rxcrd_valid;
  assign a2f_dat_rxcrd_protocol_id     = a2f_dat_if.rxcrd_protocol_id;
  assign a2f_dat_rxcrd_vc_id           = a2f_dat_if.rxcrd_vc_id;
  assign a2f_dat_rxcrd_shared          = a2f_dat_if.rxcrd_shared;

  //-- dbg_gpio_if (debug_axi_cpi_bridge.master) : ctrl fed in, counters read out
  assign dbg_gpio_if_i.cnt_reset   = dbg_gpio_cnt_reset;
  assign dbg_gpio_if_i.cnt_enable  = dbg_gpio_cnt_enable;
  assign dbg_gpio_if_i.cnt_freerun = dbg_gpio_cnt_freerun;
  assign dbg_gpio_axi_wr_start_cnt = dbg_gpio_if_i.axi_wr_start_cnt;
  assign dbg_gpio_axi_wr_start_bcd = dbg_gpio_if_i.axi_wr_start_bcd;
  assign dbg_gpio_axi_wr_compl_cnt = dbg_gpio_if_i.axi_wr_compl_cnt;
  assign dbg_gpio_axi_wr_compl_bcd = dbg_gpio_if_i.axi_wr_compl_bcd;
  assign dbg_gpio_axi_rd_start_cnt = dbg_gpio_if_i.axi_rd_start_cnt;
  assign dbg_gpio_axi_rd_start_bcd = dbg_gpio_if_i.axi_rd_start_bcd;
  assign dbg_gpio_axi_rd_compl_cnt = dbg_gpio_if_i.axi_rd_compl_cnt;
  assign dbg_gpio_axi_rd_compl_bcd = dbg_gpio_if_i.axi_rd_compl_bcd;
  assign dbg_gpio_f2a_req_cnt      = dbg_gpio_if_i.f2a_req_cnt;
  assign dbg_gpio_f2a_req_bcd      = dbg_gpio_if_i.f2a_req_bcd;
  assign dbg_gpio_f2a_dat_cnt      = dbg_gpio_if_i.f2a_dat_cnt;
  assign dbg_gpio_f2a_dat_bcd      = dbg_gpio_if_i.f2a_dat_bcd;
  assign dbg_gpio_a2f_rsp_cnt      = dbg_gpio_if_i.a2f_rsp_cnt;
  assign dbg_gpio_a2f_rsp_bcd      = dbg_gpio_if_i.a2f_rsp_bcd;
  assign dbg_gpio_a2f_dat_cnt      = dbg_gpio_if_i.a2f_dat_cnt;
  assign dbg_gpio_a2f_dat_bcd      = dbg_gpio_if_i.a2f_dat_bcd;
  assign dbg_gpio_f2a_dat_emd_cnt  = dbg_gpio_if_i.f2a_dat_emd_cnt;
  assign dbg_gpio_f2a_dat_emd_bcd  = dbg_gpio_if_i.f2a_dat_emd_bcd;
  assign dbg_gpio_a2f_dat_emd_cnt  = dbg_gpio_if_i.a2f_dat_emd_cnt;
  assign dbg_gpio_a2f_dat_emd_bcd  = dbg_gpio_if_i.a2f_dat_emd_bcd;

  pl_axi_cpi_bridge #(
    .BRDG_ID                 (BRDG_ID),
    .DEBUG_IF_EN             (DEBUG_IF_EN),
    .DEBUG_EN_BCD            (DEBUG_EN_BCD),
    .AXI_ADDR_WIDTH          (AXI_ADDR_WIDTH),
    .AXI_IDS_SUPP            (AXI_IDS_SUPP),
    .USER_POISN_SUPP         (USER_POISN_SUPP),
    .USER_METAD_SUPP         (USER_METAD_SUPP),
    .USER_DEVLD_SUPP         (USER_DEVLD_SUPP),
    .ARUSER_MEMSPECRD_SUPP   (ARUSER_MEMSPECRD_SUPP),
    .ARUSER_MEMINV_SUPP      (ARUSER_MEMINV_SUPP),
    .ARUSER_MEMINVNT_SUPP    (ARUSER_MEMINVNT_SUPP),
    .EN_CMD_PARITY           (EN_CMD_PARITY),
    .EN_DAT_PARITY           (EN_DAT_PARITY),
    .EN_BEN_PARITY           (EN_BEN_PARITY),
    .EN_ADR_PARITY           (EN_ADR_PARITY),
    .WROB_DEPTH              (WROB_DEPTH),
    .RROB_DEPTH              (RROB_DEPTH)
  ) i_pl_axi_cpi_bridge (
    /*** Clock/Reset ***/
    .s_axi_aclk    (s_axi_aclk),
    .s_axi_aresetn (s_axi_aresetn),
    //-- Write Address Channel
    .s_axi_awaddr  (s_axi_awaddr),
    .s_axi_awid    (s_axi_awid),
    .s_axi_awprot  (s_axi_awprot),
    .s_axi_awburst (s_axi_awburst),
    .s_axi_awsize  (s_axi_awsize),
    .s_axi_awcache (s_axi_awcache),
    .s_axi_awlen   (s_axi_awlen),
    .s_axi_awlock  (s_axi_awlock),
    .s_axi_awvalid (s_axi_awvalid),
    .s_axi_awready (s_axi_awready),
    //-- Write Data Channel
    .s_axi_wuser   (s_axi_wuser),
    .s_axi_wdata   (s_axi_wdata),
    .s_axi_wstrb   (s_axi_wstrb),
    .s_axi_wlast   (s_axi_wlast),
    .s_axi_wvalid  (s_axi_wvalid),
    .s_axi_wready  (s_axi_wready),
    //-- Write Response Channel
    .s_axi_buser   (s_axi_buser),
    .s_axi_bvalid  (s_axi_bvalid),
    .s_axi_bready  (s_axi_bready),
    .s_axi_bid     (s_axi_bid),
    .s_axi_bresp   (s_axi_bresp),
    //-- Read Address Channel
    .s_axi_aruser  (s_axi_aruser),
    .s_axi_araddr  (s_axi_araddr),
    .s_axi_arid    (s_axi_arid),
    .s_axi_arprot  (s_axi_arprot),
    .s_axi_arburst (s_axi_arburst),
    .s_axi_arsize  (s_axi_arsize),
    .s_axi_arcache (s_axi_arcache),
    .s_axi_arlen   (s_axi_arlen),
    .s_axi_arlock  (s_axi_arlock),
    .s_axi_arvalid (s_axi_arvalid),
    .s_axi_arready (s_axi_arready),
    //-- Read Data Channel
    .s_axi_ruser   (s_axi_ruser),
    .s_axi_rid     (s_axi_rid),
    .s_axi_rdata   (s_axi_rdata),
    .s_axi_rresp   (s_axi_rresp),
    .s_axi_rvalid  (s_axi_rvalid),
    .s_axi_rlast   (s_axi_rlast),
    .s_axi_rready  (s_axi_rready),
    /*** CPI Channels (unrolled internally, see assigns above) ***/
    .f2a_req     (f2a_req_if),
    .f2a_dat     (f2a_dat_if),
    .f2a_dat_emd (f2a_dat_emd),
    .a2f_rsp     (a2f_rsp_if),
    .a2f_dat     (a2f_dat_if),
    .a2f_dat_emd (a2f_dat_emd),
    /*** Debug ***/
    .dbg_gpio_if (dbg_gpio_if_i),
    //-- AXI-Lite
    .s_axil_aclk    (s_axil_aclk),
    .s_axil_aresetn (s_axil_aresetn),
    .s_axil_awvalid (s_axil_awvalid),
    .s_axil_awready (s_axil_awready),
    .s_axil_awaddr  (s_axil_awaddr),
    .s_axil_awprot  (s_axil_awprot),
    .s_axil_wvalid  (s_axil_wvalid),
    .s_axil_wready  (s_axil_wready),
    .s_axil_wdata   (s_axil_wdata),
    .s_axil_wstrb   (s_axil_wstrb),
    .s_axil_bvalid  (s_axil_bvalid),
    .s_axil_bready  (s_axil_bready),
    .s_axil_bresp   (s_axil_bresp),
    .s_axil_arvalid (s_axil_arvalid),
    .s_axil_arready (s_axil_arready),
    .s_axil_araddr  (s_axil_araddr),
    .s_axil_arprot  (s_axil_arprot),
    .s_axil_rvalid  (s_axil_rvalid),
    .s_axil_rready  (s_axil_rready),
    .s_axil_rresp   (s_axil_rresp),
    .s_axil_rdata   (s_axil_rdata)
  );

endmodule
