`ifndef CPM6_IF_SV
`define CPM6_IF_SV 1
`include "pcie6_defines.svh"

`define XPREG(clk, reset_n, q,d,rstval) \
  always @(posedge clk) begin \
    if (reset_n == 1'b0)  \
      q <= #(TCQ) rstval; \
    else                  \
      q <= #(TCQ)  d;     \
  end

interface pcie6_pstbr_pl_tx_if ();
  import cpm6_v1_0_40791_pkg::*;

// Data and Control
  logic tx_valid;
  logic [`PCIE6_PSTBR_PL_TX_DATA_WIDTH-1:0]        tx_data;
  logic [`PCIE6_PSTBR_PL_TX_DATA_PARITY_WIDTH-1:0] tx_parity;
  logic [`PCIE6_PSTBR_PL_TX_START_WIDTH-1:0]       tx_start;
  logic [`PCIE6_PSTBR_PL_TX_STARTPTR_WIDTH-1:0]    tx_start0ptr;
  logic [`PCIE6_PSTBR_PL_TX_STARTPTR_WIDTH-1:0]    tx_start1ptr;
  logic [`PCIE6_PSTBR_PL_TX_STARTPTR_WIDTH-1:0]    tx_start2ptr;
  logic [`PCIE6_PSTBR_PL_TX_STARTTYPE_WIDTH-1:0]   tx_start0type;
  logic [`PCIE6_PSTBR_PL_TX_STARTTYPE_WIDTH-1:0]   tx_start1type;
  logic [`PCIE6_PSTBR_PL_TX_STARTTYPE_WIDTH-1:0]   tx_start2type;
  logic [`PCIE6_PSTBR_PL_TX_STARTNPINFO_WIDTH-1:0] tx_start0npinfo;
  logic [`PCIE6_PSTBR_PL_TX_STARTNPINFO_WIDTH-1:0] tx_start1npinfo;
  logic [`PCIE6_PSTBR_PL_TX_STARTNPINFO_WIDTH-1:0] tx_start2npinfo;
  logic [`PCIE6_PSTBR_PL_TX_END_WIDTH-1:0]         tx_end;
  logic [`PCIE6_PSTBR_PL_TX_ENDPTR_WIDTH-1:0]      tx_end0ptr;
  logic [`PCIE6_PSTBR_PL_TX_ENDPTR_WIDTH-1:0]      tx_end1ptr;
  logic [`PCIE6_PSTBR_PL_TX_ENDPTR_WIDTH-1:0]      tx_end2ptr;
  logic [`PCIE6_PSTBR_PL_TX_END_ERROR_WIDTH-1:0]   tx_end_err;

  // Flow Control (Credits)
  logic tx_credit_valid;
  logic tx_credit_active;
  logic [`PCIE6_PSTBR_PL_TX_CREDIT_BUS_WIDTH-1:0] tx_credit;

  // Synopsys PCIe Controller Info Signals
  logic [`PCIE6_CX_NVC*`PCIE6_CX_HCRD_WD-1:0] xadm_ph_cdts;   // header for P dedicated credits
  logic [`PCIE6_CX_NVC*`PCIE6_CX_DCRD_WD-1:0] xadm_pd_cdts;   // data for P dedicated credits
  logic [`PCIE6_CX_NVC*`PCIE6_CX_HCRD_WD-1:0] xadm_nph_cdts;  // header for NPR dedicated credits
  logic [`PCIE6_CX_NVC*`PCIE6_CX_DCRD_WD-1:0] xadm_npd_cdts;  // data for NPR dedicated credits
  logic [`PCIE6_CX_NVC*`PCIE6_CX_HCRD_WD-1:0] xadm_cplh_cdts; // header for cPL dedicated credits
  logic [`PCIE6_CX_NVC*`PCIE6_CX_DCRD_WD-1:0] xadm_cpld_cdts; // data for cPL dedicated credits

  modport m (
    output tx_valid,
    output tx_data,
    output tx_parity,
    output tx_start,
    output tx_start0ptr,
    output tx_start1ptr,
    output tx_start2ptr,
    output tx_start0type,
    output tx_start1type,
    output tx_start2type,
    output tx_start0npinfo,
    output tx_start1npinfo,
    output tx_start2npinfo,
    output tx_end,
    output tx_end0ptr,
    output tx_end1ptr,
    output tx_end2ptr,
    output tx_end_err,

    input  tx_credit_valid,
    input  tx_credit,
    output tx_credit_active,

    input xadm_ph_cdts,
    input xadm_pd_cdts,
    input xadm_nph_cdts,
    input xadm_npd_cdts,
    input xadm_cplh_cdts,
    input xadm_cpld_cdts
  );

  modport s (
    input  tx_valid,
    input  tx_data,
    input  tx_parity,
    input  tx_start,
    input  tx_start0ptr,
    input  tx_start1ptr,
    input  tx_start2ptr,
    input  tx_start0type,
    input  tx_start1type,
    input  tx_start2type,
    input  tx_start0npinfo,
    input  tx_start1npinfo,
    input  tx_start2npinfo,
    input  tx_end,
    input  tx_end0ptr,
    input  tx_end1ptr,
    input  tx_end2ptr,
    input  tx_end_err,

    output tx_credit_valid,
    output tx_credit,
    input  tx_credit_active,

    output xadm_ph_cdts,
    output xadm_pd_cdts,
    output xadm_nph_cdts,
    output xadm_npd_cdts,
    output xadm_cplh_cdts,
    output xadm_cpld_cdts
  );
endinterface : pcie6_pstbr_pl_tx_if

interface pcie6_pstbr_pl_rx_if ();
import cpm6_v1_0_40791_pkg::*;

// Data and Control
  logic rx_valid;
  logic [`PCIE6_PSTBR_PL_RX_DATA_WIDTH-1:0]        rx_data;
  logic [`PCIE6_PSTBR_PL_RX_DATA_PARITY_WIDTH-1:0] rx_parity;
  logic [`PCIE6_PSTBR_PL_RX_START_WIDTH-1:0]       rx_start;
  logic [`PCIE6_PSTBR_PL_RX_STARTPTR_WIDTH-1:0]    rx_start0ptr;
  logic [`PCIE6_PSTBR_PL_RX_STARTPTR_WIDTH-1:0]    rx_start1ptr;
  logic [`PCIE6_PSTBR_PL_RX_STARTPTR_WIDTH-1:0]    rx_start2ptr;
  logic [`PCIE6_PSTBR_PL_RX_STARTTYPE_WIDTH-1:0]   rx_start0type;
  logic [`PCIE6_PSTBR_PL_RX_STARTTYPE_WIDTH-1:0]   rx_start1type;
  logic [`PCIE6_PSTBR_PL_RX_STARTTYPE_WIDTH-1:0]   rx_start2type;
  logic [`PCIE6_PSTBR_PL_RX_STARTNPINFO_WIDTH-1:0] rx_start0npinfo;
  logic [`PCIE6_PSTBR_PL_RX_STARTNPINFO_WIDTH-1:0] rx_start1npinfo;
  logic [`PCIE6_PSTBR_PL_RX_STARTNPINFO_WIDTH-1:0] rx_start2npinfo;
  logic [`PCIE6_PSTBR_PL_RX_END_WIDTH-1:0]         rx_end;
  logic [`PCIE6_PSTBR_PL_RX_ENDPTR_WIDTH-1:0]      rx_end0ptr;
  logic [`PCIE6_PSTBR_PL_RX_ENDPTR_WIDTH-1:0]      rx_end1ptr;
  logic [`PCIE6_PSTBR_PL_RX_ENDPTR_WIDTH-1:0]      rx_end2ptr;
  logic [`PCIE6_PSTBR_PL_RX_END_ERROR_WIDTH-1:0]   rx_end_err;

  // Flow Control (Credits)
  logic rx_credit_valid;
  logic rx_credit_active;
  logic [`PCIE6_PSTBR_PL_RX_CREDIT_BUS_WIDTH-1:0] rx_credit;

  modport m (
    output rx_valid,
    output rx_data,
    output rx_parity,
    output rx_start,
    output rx_start0ptr,
    output rx_start1ptr,
    output rx_start2ptr,
    output rx_start0type,
    output rx_start1type,
    output rx_start2type,
    output rx_start0npinfo,
    output rx_start1npinfo,
    output rx_start2npinfo,
    output rx_end,
    output rx_end0ptr,
    output rx_end1ptr,
    output rx_end2ptr,
    output rx_end_err,

    input  rx_credit_valid,
    input  rx_credit,
    output rx_credit_active
  );

  modport s (
    input  rx_valid,
    input  rx_data,
    input  rx_parity,
    input  rx_start,
    input  rx_start0ptr,
    input  rx_start1ptr,
    input  rx_start2ptr,
    input  rx_start0type,
    input  rx_start1type,
    input  rx_start2type,
    input  rx_start0npinfo,
    input  rx_start1npinfo,
    input  rx_start2npinfo,
    input  rx_end,
    input  rx_end0ptr,
    input  rx_end1ptr,
    input  rx_end2ptr,
    input  rx_end_err,

    output rx_credit_valid,
    output rx_credit,
    input  rx_credit_active
  );
endinterface : pcie6_pstbr_pl_rx_if

interface pcie6_app_layer_intr_if ();
  logic [127:0] edma_int;

  modport m(
    output edma_int
  );

  modport s(
    input edma_int
  );
endinterface : pcie6_app_layer_intr_if

interface pcie6_cxl_rawflit_misc_if ();

  logic [7:0] cxl_error;
  logic [1:0] cxl_flit_mode;
  logic       cxl_reset;
  logic       cfg_cxl_dev_cache_en;
  logic [7:0] cfg_cxl_dev_mem_en;
  logic [7:0] cfg_cxl_dev_cxl_rst_mem_clr_enable;
  logic [7:0] cfg_cxl_mld_hot_rst_active;
  logic [7:0] app_cxl_mld_hot_rst_done ;
  logic [7:0] cxl_spares_in ;
  logic       cfg_cxl_bi_enable;
  logic [7:0] cfg_cxl_dev_initiate_cxl_rst;
  logic       cfg_cxl_dev_disable_caching;
  logic       cfg_cxl_dev_initiate_cache_wr_invld;
  logic       mdh_disable;
  logic       cfg_cxl_io_en;
  logic       cfg_cxl_link_up;
  logic       cxl3_1_emd_enable;
  logic [3:0] vlsm_mc_state;

  modport s (
    input  cxl_error,
    input  cxl_flit_mode,
    input  cxl_reset,
    input  cfg_cxl_dev_cache_en,
    input  cfg_cxl_dev_mem_en,
    input  cfg_cxl_dev_cxl_rst_mem_clr_enable,
    input  cfg_cxl_bi_enable,
    input  cfg_cxl_dev_initiate_cxl_rst,
    input  cfg_cxl_dev_disable_caching,
    input  cfg_cxl_dev_initiate_cache_wr_invld,
    input  mdh_disable,
    input  cfg_cxl_io_en,
    input  cfg_cxl_link_up,
    input  cxl3_1_emd_enable,
    input  vlsm_mc_state,
    output cxl_spares_in,
    input  cfg_cxl_mld_hot_rst_active,
    output app_cxl_mld_hot_rst_done

  );


  modport m ( // PL would be the master
    output cxl_error,
    output cxl_flit_mode,
    output cxl_reset,
    output cfg_cxl_dev_cache_en,
    output cfg_cxl_dev_mem_en,
    output cfg_cxl_dev_cxl_rst_mem_clr_enable,
    output cfg_cxl_bi_enable,
    output cfg_cxl_dev_initiate_cxl_rst,
    output cfg_cxl_dev_disable_caching,
    output cfg_cxl_dev_initiate_cache_wr_invld,
    output mdh_disable,
    output cfg_cxl_io_en,
    output cfg_cxl_link_up,
    output cxl3_1_emd_enable,
    output vlsm_mc_state,
    input  cxl_spares_in,
    output cfg_cxl_mld_hot_rst_active,
    input  app_cxl_mld_hot_rst_done
  );
endinterface : pcie6_cxl_rawflit_misc_if

interface pcie6_cxl_rawflit_rx_if ();
  logic [1535:0] data;
  logic [2:0]    valid;
  logic [2:0]    viral;
  logic [2:0]    adf;
  logic [47:0]   dec_assists;
  logic          credit_valid;
  logic [3:0]    credit_req;
  logic [3:0]    credit_rsp;
  logic [3:0]    credit_data;
  logic [23:0]   parity;
  logic [32:0]   cxl_pm_out;
  logic [4:0]    tx_ready;
  logic [1:0]    flit_mode;

  modport m (
    output data,
    output valid,
    output viral,
    output adf,
    output dec_assists,
    output credit_valid,
    output credit_req,
    output credit_rsp,
    output credit_data,
    output parity,
    output cxl_pm_out,
    output tx_ready,
    output flit_mode
  );


  modport s (
    input  data,
    input  valid,
    input  viral,
    input  adf,
    input  dec_assists,
    input  credit_valid,
    input  credit_req,
    input  credit_rsp,
    input  credit_data,
    input  parity,
    input  cxl_pm_out,
    input  tx_ready,
    input  flit_mode
  );
endinterface : pcie6_cxl_rawflit_rx_if

interface pcie6_cxl_rawflit_tx_if ();
  logic[1535:0] data;
  logic [23:0] parity;
  logic [2:0]  valid;
  logic [2:0]  viral;
  logic [2:0]  adf;
  logic [2:0]  last;
  logic        credit_valid;
  logic [3:0]  credit_req;
  logic [3:0]  credit_rsp;
  logic [3:0]  credit_data;
//logic [4:0]  tx_ready;
  logic        pl_ready;
  logic [33:0] pm_in;

  modport s (
    input  data,
    input  parity,
    input  valid,
    input  viral,
    input  adf,
    input  last,
    input  credit_valid,
    input  credit_req,
    input  credit_rsp,
    input  credit_data,
  //output tx_ready,
    input  pm_in,
    input  pl_ready
  );

  modport m (
    output data,
    output parity,
    output valid,
    output viral,
    output adf,
    output last,
    output credit_valid,
    output credit_req,
    output credit_rsp,
    output credit_data,
  //input  tx_ready,
    output pm_in,
    output pl_ready
  );
endinterface : pcie6_cxl_rawflit_tx_if

interface pcie6_elbi_pl_if ();
  logic        ext_lbc_override_en;
  logic [7:0]  ext_lbc_ack;
  logic [63:0] ext_lbc_din;
  logic [31:0] lbc_ext_addr;
  logic [63:0] lbc_ext_dout;
  logic [7:0]  lbc_ext_valid;
  logic [7:0]  lbc_ext_cs;
  logic [7:0]  lbc_ext_wr;
  logic [7:0]  lbc_ext_rd;
  logic        lbc_ext_dbi_access;
  logic        lbc_ext_cxl_mbar0_access;
  logic        lbc_ext_rom_access;
  logic        lbc_ext_io_access;
  logic [2:0]  lbc_ext_bar_num;
  logic [7:0]  lbc_ext_vfunc_num;
  logic        lbc_ext_vfunc_active;

  modport m (
    input  ext_lbc_override_en,
    input  ext_lbc_ack,
    input  ext_lbc_din,
    output lbc_ext_addr,
    output lbc_ext_dout,
    output lbc_ext_valid,
    output lbc_ext_cs,
    output lbc_ext_wr,
    output lbc_ext_rd,
    output lbc_ext_dbi_access,
    output lbc_ext_cxl_mbar0_access,
    output lbc_ext_rom_access,
    output lbc_ext_io_access,
    output lbc_ext_bar_num,
    output lbc_ext_vfunc_num,
    output lbc_ext_vfunc_active
  );

  modport s (
    output ext_lbc_override_en,
    output ext_lbc_ack,
    output ext_lbc_din,
    input  lbc_ext_addr,
    input  lbc_ext_dout,
    input  lbc_ext_valid,
    input  lbc_ext_cs,
    input  lbc_ext_wr,
    input  lbc_ext_rd,
    input  lbc_ext_dbi_access,
    input  lbc_ext_cxl_mbar0_access,
    input  lbc_ext_rom_access,
    input  lbc_ext_io_access,
    input  lbc_ext_bar_num,
    input  lbc_ext_vfunc_num,
    input  lbc_ext_vfunc_active
  );
endinterface : pcie6_elbi_pl_if

interface pcie6_flr_pl_if ();
  logic [7:0]  app_cxl_rst_active;
  logic [7:0]  app_cxl_rst_done;
  logic [7:0]  app_cxl_rst_error;
  logic [7:0]  app_flr_pf_done;
  logic[255:0] app_flr_vf_done;

  modport m (
    input app_cxl_rst_active,
    input app_cxl_rst_done,
    input app_cxl_rst_error,
    input app_flr_pf_done,
    input app_flr_vf_done
  );

  modport s (
    output app_cxl_rst_active,
    output app_cxl_rst_done,
    output app_cxl_rst_error,
    output app_flr_pf_done,
    output app_flr_vf_done
  );
endinterface : pcie6_flr_pl_if

interface pcie6_cfg_sts_pl_if ();
  logic [15:0] pf_cfg_info;
  logic        pf_cfg_status_vld;
  logic        pf_cfg_status_sos;
  logic [2:0]  pf_cfg_status_num;

  logic [15:0] vf_cfg_info;
  logic        vf_cfg_status_vld;
  logic        vf_cfg_status_sos;
  logic [7:0]  vf_cfg_status_num;

  modport m (
    output pf_cfg_info,
    output pf_cfg_status_vld,
    output pf_cfg_status_sos,
    output pf_cfg_status_num,
    output vf_cfg_info,
    output vf_cfg_status_vld,
    output vf_cfg_status_sos,
    output vf_cfg_status_num
  );

  modport s (
    input pf_cfg_info,
    input pf_cfg_status_vld,
    input pf_cfg_status_sos,
    input pf_cfg_status_num,
    input vf_cfg_info,
    input vf_cfg_status_vld,
    input vf_cfg_status_sos,
    input vf_cfg_status_num
  );
endinterface : pcie6_cfg_sts_pl_if

interface pcie6_misc_sts_pl_if ();
  logic [5:0] cfg_neg_link_width;
  logic       rdlh_link_up;
  logic       smlh_link_up;
  logic [5:0] smlh_ltssm_state;

  modport m (
    output cfg_neg_link_width,
    output rdlh_link_up,
    output smlh_link_up,
    output smlh_ltssm_state
  );

  modport s(
    input cfg_neg_link_width,
    input rdlh_link_up,
    input smlh_link_up,
    input smlh_ltssm_state
  );
endinterface : pcie6_misc_sts_pl_if

interface pcie6_msix_pl_if ();
  logic [2:0]  pl_msi_func_num;
  logic [7:0]  pl_msi_vfunc_num;
  logic        pl_msi_vfunc_active;
  logic [2:0]  pl_msi_tc;
  logic [4:0]  pl_msi_vector;
  logic [31:0] pl_msi_addr_lo;
  logic [31:0] pl_msi_addr_hi;
  logic [31:0] pl_msi_data;
  logic        pl_issue_msi_req;
  logic        pl_issue_msix_req;
  logic        select_pl;
  logic        pl_done;

  modport m (
    input  pl_msi_func_num,
    input  pl_msi_vfunc_num,
    input  pl_msi_vfunc_active,
    input  pl_msi_tc,
    input  pl_msi_vector,
    input  pl_msi_addr_lo,
    input  pl_msi_addr_hi,
    input  pl_msi_data,
    input  pl_issue_msi_req,
    input  pl_issue_msix_req,
    input  select_pl,
    output pl_done
  );

  modport s (
    output pl_msi_func_num,
    output pl_msi_vfunc_num,
    output pl_msi_vfunc_active,
    output pl_msi_tc,
    output pl_msi_vector,
    output pl_msi_addr_lo,
    output pl_msi_addr_hi,
    output pl_msi_data,
    output pl_issue_msi_req,
    output pl_issue_msix_req,
    output select_pl,
    input  pl_done
  );
endinterface : pcie6_msix_pl_if

interface cpm6_axi512_fab_slv_if ();
  logic [47:0]  araddr ;
  logic [1:0]   arburst;
  logic [3:0]   arcache;
  logic [19:0]  arid   ;
  logic [7:0]   arlen  ;
  logic         arlock ;
  logic [2:0]   arprot ;
  logic [3:0]   arqos  ;
  logic         arready;
  logic [2:0]   arsize ;
  logic [148:0] aruser ;
  logic         arvalid;

  logic [511:0] rdata  ;
  logic [19:0]  rid    ;
  logic         rlast  ;
  logic         rready ;
  logic [1:0]   rresp  ;
  logic [185:0] ruser  ;
  logic         rvalid ;

  logic [47:0]  awaddr ;
  logic [1:0]   awburst;
  logic [3:0]   awcache;
  logic [19:0]  awid   ;
  logic [7:0]   awlen  ;
  logic         awlock ;
  logic [2:0]   awprot ;
  logic [3:0]   awqos  ;
  logic         awready;
  logic [2:0]   awsize ;
  logic [227:0] awuser ;
  logic         awvalid;

  logic [19:0]  bid    ;
  logic         bready ;
  logic [1:0]   bresp  ;
  logic [121:0] buser  ;
  logic         bvalid ;

  logic [511:0] wdata  ;
  logic [64:0]  wuser  ;
  logic         wlast  ;
  logic         wready ;
  logic [63:0]  wstrb  ;
  logic         wvalid ;

  modport m (
    //Read Addr
    output araddr ,
    output arburst,
    output arcache,
    output arid   ,
    output arlen  ,
    output arlock ,
    output arprot ,
    output arqos  ,
    input  arready,
    output arsize ,
    output aruser ,
    output arvalid,

    //Read Data
    input  rdata  ,
    input  rid    ,
    input  rlast  ,
    output rready ,
    input  rresp  ,
    input  ruser  ,
    input  rvalid ,

    //Write Addr
    output awaddr ,
    output awburst,
    output awcache,
    output awid   ,
    output awlen  ,
    output awlock ,
    output awprot ,
    output awqos  ,
    input  awready,
    output awsize ,
    output awuser ,
    output awvalid,

    //Write Resp
    input  bid    ,
    output bready ,
    input  bresp  ,
    input  buser  ,
    input  bvalid ,

    //Write Data
    output wdata  ,
    output wlast  ,
    input  wready ,
    output wstrb  ,
    output wvalid ,
    output wuser
  );

  modport s (
    //Read Addr
    input  araddr ,
    input  arburst,
    input  arcache,
    input  arid   ,
    input  arlen  ,
    input  arlock ,
    input  arprot ,
    input  arqos  ,
    output arready,
    input  arsize ,
    input  aruser ,
    input  arvalid,

    //Read Data
    output rdata  ,
    output rid    ,
    output rlast  ,
    input  rready ,
    output rresp  ,
    output ruser  ,
    output rvalid ,

    //Write Addr
    input  awaddr ,
    input  awburst,
    input  awcache,
    input  awid   ,
    input  awlen  ,
    input  awlock ,
    input  awprot ,
    input  awqos  ,
    output awready,
    input  awsize ,
    input  awuser ,
    input  awvalid,

    //Write Resp
    output bid    ,
    input  bready ,
    output bresp  ,
    output buser  ,
    output bvalid ,

    //Write Data
    input  wdata  ,
    input  wlast  ,
    output wready ,
    input  wstrb  ,
    input  wvalid ,
    input  wuser
  );

  modport axi_trace (
    //Read Addr
    input  araddr ,
    input  arburst,
    input  arcache,
    input  arid   ,
    input  arlen  ,
    input  arlock ,
    input  arprot ,
    input  arqos  ,
    input  arready,
    input  arsize ,
    input  aruser ,
    input  arvalid,

    //Read Data
    input  rdata  ,
    input  rid    ,
    input  rlast  ,
    input  rready ,
    input  rresp  ,
    input  ruser  ,
    input  rvalid ,

    //Write Addr
    input  awaddr ,
    input  awburst,
    input  awcache,
    input  awid   ,
    input  awlen  ,
    input  awlock ,
    input  awprot ,
    input  awqos  ,
    input  awready,
    input  awsize ,
    input  awuser ,
    input  awvalid,

    //Write Resp
    input  bid    ,
    input  bready ,
    input  bresp  ,
    input  buser  ,
    input  bvalid ,

    //Write Data
    input  wdata  ,
    input  wlast  ,
    input  wready ,
    input  wstrb  ,
    input  wvalid ,
    input  wuser
  );
endinterface : cpm6_axi512_fab_slv_if

interface cpm6_axi512_fab_mst_if ();
  logic [50:0]  araddr ;
  logic [1:0]   arburst;
  logic [3:0]   arcache;
  logic [9:0]   arid   ;
  logic [7:0]   arlen  ;
  logic         arlock ;
  logic [2:0]   arprot ;
  logic [3:0]   arqos  ;
  logic         arready;
  logic [2:0]   arsize ;
  logic [55:0]  aruser ;
  logic         arvalid;

  logic [511:0] rdata  ;
  logic [9:0]   rid    ;
  logic         rlast  ;
  logic         rready ;
  logic [1:0]   rresp  ;
  logic [67:0]  ruser  ;
  logic         rvalid ;

  logic [50:0]  awaddr ;
  logic [1:0]   awburst;
  logic [3:0]   awcache;
  logic [9:0]   awid   ;
  logic [7:0]   awlen  ;
  logic         awlock ;
  logic [2:0]   awprot ;
  logic [3:0]   awqos  ;
  logic         awready;
  logic [2:0]   awsize ;
  logic [146:0] awuser ;
  logic         awvalid;

  logic [9:0]   bid    ;
  logic         bready ;
  logic [1:0]   bresp  ;
  logic [2:0]   buser  ;
  logic         bvalid ;

  logic [511:0] wdata  ;
  logic [63:0]  wuser  ;
  logic         wlast  ;
  logic         wready ;
  logic [63:0]  wstrb  ;
  logic         wvalid ;

  modport m (
    //Read Addr
    output araddr ,
    output arburst,
    output arcache,
    output arid   ,
    output arlen  ,
    output arlock ,
    output arprot ,
    output arqos  ,
    input  arready,
    output arsize ,
    output aruser ,
    output arvalid,

    //Read Data
    input  rdata  ,
    input  rid    ,
    input  rlast  ,
    output rready ,
    input  rresp  ,
    input  ruser  ,
    input  rvalid ,

    //Write Addr
    output awaddr ,
    output awburst,
    output awcache,
    output awid   ,
    output awlen  ,
    output awlock ,
    output awprot ,
    output awqos  ,
    input  awready,
    output awsize ,
    output awuser ,
    output awvalid,

    //Write Resp
    input  bid    ,
    output bready ,
    input  bresp  ,
    input  buser  ,
    input  bvalid ,

    //Write Data
    output wdata  ,
    output wuser  ,
    output wlast  ,
    input  wready ,
    output wstrb  ,
    output wvalid
  );

  modport s (
    //Read Addr
    input  araddr ,
    input  arburst,
    input  arcache,
    input  arid   ,
    input  arlen  ,
    input  arlock ,
    input  arprot ,
    input  arqos  ,
    output arready,
    input  arsize ,
    input  aruser ,
    input  arvalid,

    //Read Data
    output rdata  ,
    output rid    ,
    output rlast  ,
    input  rready ,
    output rresp  ,
    output ruser  ,
    output rvalid ,

    //Write Addr
    input  awaddr ,
    input  awburst,
    input  awcache,
    input  awid   ,
    input  awlen  ,
    input  awlock ,
    input  awprot ,
    input  awqos  ,
    output awready,
    input  awsize ,
    input  awuser ,
    input  awvalid,

    //Write Resp
    output bid    ,
    input  bready ,
    output bresp  ,
    output buser  ,
    output bvalid ,

    //Write Data
    input  wdata  ,
    input  wuser  ,
    input  wlast  ,
    output wready ,
    input  wstrb  ,
    input  wvalid
  );

  modport axi_trace (
    //Read Addr
    input  araddr ,
    input  arburst,
    input  arcache,
    input  arid   ,
    input  arlen  ,
    input  arlock ,
    input  arprot ,
    input  arqos  ,
    input  arready,
    input  arsize ,
    input  aruser ,
    input  arvalid,

    //Read Data
    input  rdata  ,
    input  rid    ,
    input  rlast  ,
    input  rready ,
    input  rresp  ,
    input  ruser  ,
    input  rvalid ,

    //Write Addr
    input  awaddr ,
    input  awburst,
    input  awcache,
    input  awid   ,
    input  awlen  ,
    input  awlock ,
    input  awprot ,
    input  awqos  ,
    input  awready,
    input  awsize ,
    input  awuser ,
    input  awvalid,

    //Write Resp
    input  bid    ,
    input  bready ,
    input  bresp  ,
    input  buser  ,
    input  bvalid ,

    //Write Data
    input  wdata  ,
    input  wlast  ,
    input  wready ,
    input  wstrb  ,
    input  wvalid
  );
endinterface : cpm6_axi512_fab_mst_if

interface gtmpw_fabric_channel_if;
  wire         bsr_serial_fs;
  wire         bufgtce_sf;
  wire   [3:0] bufgtcemask_sf;
  wire  [11:0] bufgtdiv_sf;
  wire         bufgtrst_sf;
  wire   [3:0] bufgtrstmask_sf;
  wire         cssdstopclk_fs;
  wire         dmonclk_fs;
  wire         dmonfiforeset_fs;
  wire  [31:0] dmonout_sf;
  wire         gtrxreset_fs;
  wire         gttxreset_fs;
  wire         hsdppcsreset_fs;
  wire         phy_ready_sf;
  wire         txcomfinish_sf;
  wire         rxoutclk_valid_sf;
  wire         rxbyteisaligned_sf;
  wire         rxbyterealign_sf;
  wire         rxcommadet_sf;
  wire         rxsliderdy_sf;
  wire         rxslipdone_sf;
  wire         phystatus_sf;
  wire         rx_resetdone_sf;
  wire   [2:0] rxbufstatus_sf;
  wire         rxssclk_sf;
  wire         rxchanbondseq_sf;
  wire   [4:0] rxchbondi_fs;
  wire   [4:0] rxchbondo_sf;
  wire [319:0] rxdata_sf;
  wire         rxelecidle_sf;
  wire         rxgearboxslip_fs;
  wire         rxlatclk_fs;
  wire         rxpolarity_fs;
  wire         rxslide_fs;
  wire         cdrhold_fs;
  wire   [2:0] rxstatus_sf;
  wire         rxtermination_fs;
  wire         rxusrclk_fs;
  wire         rxvalid_sf;
  wire         tstclk0_fs;
  wire         tstclk1_fs;
  wire   [1:0] tx_powerdown_fs;
  wire         tx_resetdone_sf;
  wire   [1:0] txbufstatus_sf;
  wire [319:0] txdata_fs;
  wire         txdetectrxloopback_fs;
  wire         txelecidle_fs;
  wire   [5:0] txempmain_fs;
  wire   [5:0] txemppos_fs;
  wire   [5:0] txemppre_fs;
  wire         txlatclk_fs;
  wire   [7:0] txrate_fs;
  wire         txusrclk_fs;
  wire  [19:0] upi2_ctrl_phy_cmdcode_fs;
  wire         upi2_ctrl_phy_cmdreq_fs;
  wire         upi2_phy_ctrl_cmderror_sf;
  wire         upi2_phy_ctrl_cmdready_sf;
  wire  [31:0] upi2_phy_ctrl_cmdresp_sf;
  wire         upi2_phy_ctrl_msgreq_sf;
  wire         mngpwr_tokenout_sf;
  wire         mngpwr_tokenin_fs;
  wire  [7:0]  pcie_ltssm_state_fs;

  modport master (
    output bsr_serial_fs,
    input  bufgtce_sf,
    input  bufgtcemask_sf,
    input  bufgtdiv_sf,
    input  bufgtrst_sf,
    input  bufgtrstmask_sf,
    output cssdstopclk_fs,
    output dmonclk_fs,
    output dmonfiforeset_fs,
    input  dmonout_sf,
    output gtrxreset_fs,
    output gttxreset_fs,
    output hsdppcsreset_fs,
    input  phy_ready_sf,
    input  txcomfinish_sf,
    input  rxoutclk_valid_sf,
    input  rxbyteisaligned_sf,
    input  rxbyterealign_sf,
    input  rxcommadet_sf,
    input  rxsliderdy_sf,
    input  rxslipdone_sf,
    input  phystatus_sf,
    input  rx_resetdone_sf,
    input  rxbufstatus_sf,
    input  rxssclk_sf,
    input  rxchanbondseq_sf,
    output rxchbondi_fs,
    input  rxchbondo_sf,
    input  rxdata_sf,
    input  rxelecidle_sf,
    output rxgearboxslip_fs,
    output rxlatclk_fs,
    output rxpolarity_fs,
    output rxslide_fs,
    output cdrhold_fs,
    input  rxstatus_sf,
    output rxtermination_fs,
    output rxusrclk_fs,
    input  rxvalid_sf,
    output tstclk0_fs,
    output tstclk1_fs,
    output tx_powerdown_fs,
    input  tx_resetdone_sf,
    input  txbufstatus_sf,
    output txdata_fs,
    output txdetectrxloopback_fs,
    output txelecidle_fs,
    output txempmain_fs,
    output txemppos_fs,
    output txemppre_fs,
    output txlatclk_fs,
    output txrate_fs,
    output txusrclk_fs,
    output upi2_ctrl_phy_cmdcode_fs,
    output upi2_ctrl_phy_cmdreq_fs,
    input  upi2_phy_ctrl_cmderror_sf,
    input  upi2_phy_ctrl_cmdready_sf,
    input  upi2_phy_ctrl_cmdresp_sf,
    input  upi2_phy_ctrl_msgreq_sf,
    output mngpwr_tokenin_fs,
    output pcie_ltssm_state_fs,
    input  mngpwr_tokenout_sf
  );

  modport master_int (
    output bsr_serial_fs,
    input  bufgtce_sf,
    input  bufgtcemask_sf,
    input  bufgtdiv_sf,
    input  bufgtrst_sf,
    input  bufgtrstmask_sf,
    output cssdstopclk_fs,
    output dmonclk_fs,
    output dmonfiforeset_fs,
    input  dmonout_sf,
    output gtrxreset_fs,
    output gttxreset_fs,
    output hsdppcsreset_fs,
    input  phy_ready_sf,
    input  txcomfinish_sf,
    input  rxoutclk_valid_sf,
    input  rxbyteisaligned_sf,
    input  rxbyterealign_sf,
    input  rxcommadet_sf,
    input  rxsliderdy_sf,
    input  rxslipdone_sf,
    input  phystatus_sf,
    input  rx_resetdone_sf,
    input  rxbufstatus_sf,
    input  rxssclk_sf,
    input  rxchanbondseq_sf,
    output rxchbondi_fs,
    input  rxchbondo_sf,
    input  rxdata_sf,
    input  rxelecidle_sf,
    output rxgearboxslip_fs,
    output rxlatclk_fs,
    output rxpolarity_fs,
    output rxslide_fs,
    output cdrhold_fs,
    input  rxstatus_sf,
    output rxtermination_fs,
    output rxusrclk_fs,
    input  rxvalid_sf,
    output tstclk0_fs,
    output tstclk1_fs,
    output tx_powerdown_fs,
    input  tx_resetdone_sf,
    input  txbufstatus_sf,
    output txdata_fs,
    output txdetectrxloopback_fs,
    output txelecidle_fs,
    output txempmain_fs,
    output txemppos_fs,
    output txemppre_fs,
    output txlatclk_fs,
    output txrate_fs,
    output txusrclk_fs,
    output upi2_ctrl_phy_cmdcode_fs,
    output upi2_ctrl_phy_cmdreq_fs,
    input  upi2_phy_ctrl_cmderror_sf,
    input  upi2_phy_ctrl_cmdready_sf,
    input  upi2_phy_ctrl_cmdresp_sf,
    input  upi2_phy_ctrl_msgreq_sf,
    output mngpwr_tokenin_fs,
    output pcie_ltssm_state_fs,
    input  mngpwr_tokenout_sf
  );

  modport slave (
    input  bsr_serial_fs,
    output bufgtce_sf,
    output bufgtcemask_sf,
    output bufgtdiv_sf,
    output bufgtrst_sf,
    output bufgtrstmask_sf,
    input  cssdstopclk_fs,
    input  dmonclk_fs,
    input  dmonfiforeset_fs,
    output dmonout_sf,
    input  gtrxreset_fs,
    input  gttxreset_fs,
    input  hsdppcsreset_fs,
    output phy_ready_sf,
    output txcomfinish_sf,
    output rxoutclk_valid_sf,
    output rxbyteisaligned_sf,
    output rxbyterealign_sf,
    output rxcommadet_sf,
    output rxsliderdy_sf,
    output rxslipdone_sf,
    output phystatus_sf,
    output rx_resetdone_sf,
    output rxbufstatus_sf,
    output rxssclk_sf,
    output rxchanbondseq_sf,
    input  rxchbondi_fs,
    output rxchbondo_sf,
    output rxdata_sf,
    output rxelecidle_sf,
    input  rxgearboxslip_fs,
    input  rxlatclk_fs,
    input  rxpolarity_fs,
    input  rxslide_fs,
    input  cdrhold_fs,
    output rxstatus_sf,
    input  rxtermination_fs,
    input  rxusrclk_fs,
    output rxvalid_sf,
    input  tstclk0_fs,
    input  tstclk1_fs,
    input  tx_powerdown_fs,
    output tx_resetdone_sf,
    output txbufstatus_sf,
    input  txdata_fs,
    input  txdetectrxloopback_fs,
    input  txelecidle_fs,
    input  txempmain_fs,
    input  txemppos_fs,
    input  txemppre_fs,
    input  txlatclk_fs,
    input  txrate_fs,
    input  txusrclk_fs,
    input  upi2_ctrl_phy_cmdcode_fs,
    input  upi2_ctrl_phy_cmdreq_fs,
    output upi2_phy_ctrl_cmderror_sf,
    output upi2_phy_ctrl_cmdready_sf,
    output upi2_phy_ctrl_cmdresp_sf,
    output upi2_phy_ctrl_msgreq_sf,
    input  mngpwr_tokenin_fs,
    input  pcie_ltssm_state_fs,
    output mngpwr_tokenout_sf
  );

  modport slave_int (
    input  bsr_serial_fs,
    output bufgtce_sf,
    output bufgtcemask_sf,
    output bufgtdiv_sf,
    output bufgtrst_sf,
    output bufgtrstmask_sf,
    input  cssdstopclk_fs,
    input  dmonclk_fs,
    input  dmonfiforeset_fs,
    output dmonout_sf,
    input  gtrxreset_fs,
    input  gttxreset_fs,
    input  hsdppcsreset_fs,
    output phy_ready_sf,
    output txcomfinish_sf,
    output rxoutclk_valid_sf,
    output rxbyteisaligned_sf,
    output rxbyterealign_sf,
    output rxcommadet_sf,
    output rxsliderdy_sf,
    output rxslipdone_sf,
    output phystatus_sf,
    output rx_resetdone_sf,
    output rxbufstatus_sf,
    output rxssclk_sf,
    output rxchanbondseq_sf,
    input  rxchbondi_fs,
    output rxchbondo_sf,
    output rxdata_sf,
    output rxelecidle_sf,
    input  rxgearboxslip_fs,
    input  rxlatclk_fs,
    input  rxpolarity_fs,
    input  rxslide_fs,
    input  cdrhold_fs,
    output rxstatus_sf,
    input  rxtermination_fs,
    input  rxusrclk_fs,
    output rxvalid_sf,
    input  tstclk0_fs,
    input  tstclk1_fs,
    input  tx_powerdown_fs,
    output tx_resetdone_sf,
    output txbufstatus_sf,
    input  txdata_fs,
    input  txdetectrxloopback_fs,
    input  txelecidle_fs,
    input  txempmain_fs,
    input  txemppos_fs,
    input  txemppre_fs,
    input  txlatclk_fs,
    input  txrate_fs,
    input  txusrclk_fs,
    input  upi2_ctrl_phy_cmdcode_fs,
    input  upi2_ctrl_phy_cmdreq_fs,
    output upi2_phy_ctrl_cmderror_sf,
    output upi2_phy_ctrl_cmdready_sf,
    output upi2_phy_ctrl_cmdresp_sf,
    output upi2_phy_ctrl_msgreq_sf,
    input  mngpwr_tokenin_fs,
    input  pcie_ltssm_state_fs,
    output mngpwr_tokenout_sf
  );
endinterface

interface gtmpw_fabric_ctrl_if;
  wire        cssdstopclk_fs;
  wire        gtpowergood_sf;
  wire        pcie_link_reach_target_fs;
  wire        mca_eventval_sf;
  wire [15:0] mca_event_sf;
  wire        rx_margin_req_ack_sf;
  wire [3:0]  rx_margin_req_cmd_fs;
  wire [1:0]  rx_margin_req_lane_num_fs;
  wire [7:0]  rx_margin_req_payload_fs;
  wire        rx_margin_req_req_fs;
  wire        rx_margin_res_ack_fs;
  wire [3:0]  rx_margin_res_cmd_sf;
  wire [1:0]  rx_margin_res_lane_num_sf;
  wire [7:0]  rx_margin_res_payload_sf;
  wire        rx_margin_res_req_sf;
  wire        rxmarginclk_fs;
  wire [31:0] ub_gpi_fs;
  wire [31:0] ub_gpo_sf;

modport master (
  output cssdstopclk_fs,
  input  gtpowergood_sf,
  output pcie_link_reach_target_fs,
  input  mca_eventval_sf,
  input  mca_event_sf,
  input  rx_margin_req_ack_sf,
  output rx_margin_req_cmd_fs,
  output rx_margin_req_lane_num_fs,
  output rx_margin_req_payload_fs,
  output rx_margin_req_req_fs,
  output rx_margin_res_ack_fs,
  input  rx_margin_res_cmd_sf,
  input  rx_margin_res_lane_num_sf,
  input  rx_margin_res_payload_sf,
  input  rx_margin_res_req_sf,
  output rxmarginclk_fs,
  output ub_gpi_fs,
  input  ub_gpo_sf);

//modport master_int (
//  output cssdstopclk_fs,
//  input  gtpowergood_sf,
//  output pcie_link_reach_target_fs,
//  input  mca_eventval_sf,
//  input  mca_event_sf,
//  input  rx_margin_req_ack_sf,
//  output rx_margin_req_cmd_fs,
//  output rx_margin_req_lane_num_fs,
//  output rx_margin_req_payload_fs,
//  output rx_margin_req_req_fs,
//  output rx_margin_res_ack_fs,
//  input  rx_margin_res_cmd_sf,
//  input  rx_margin_res_lane_num_sf,
//  input  rx_margin_res_payload_sf,
//  input  rx_margin_res_req_sf,
//  output rxmarginclk_fs,
//  output ub_gpi_fs,
//  input  ub_gpo_sf);

modport slave (
  input  cssdstopclk_fs,
  output gtpowergood_sf,
  input  pcie_link_reach_target_fs,
  output mca_eventval_sf,
  output mca_event_sf,
  output rx_margin_req_ack_sf,
  input  rx_margin_req_cmd_fs,
  input  rx_margin_req_lane_num_fs,
  input  rx_margin_req_payload_fs,
  input  rx_margin_req_req_fs,
  input  rx_margin_res_ack_fs,
  output rx_margin_res_cmd_sf,
  output rx_margin_res_lane_num_sf,
  output rx_margin_res_payload_sf,
  output rx_margin_res_req_sf,
  input  rxmarginclk_fs,
  input  ub_gpi_fs,
  output ub_gpo_sf);

//modport slave_int (
//  input  cssdstopclk_fs,
//  output gtpowergood_sf,
//  input  pcie_link_reach_target_fs,
//  output mca_eventval_sf,
//  output mca_event_sf,
//  output rx_margin_req_ack_sf,
//  input  rx_margin_req_cmd_fs,
//  input  rx_margin_req_lane_num_fs,
//  input  rx_margin_req_payload_fs,
//  input  rx_margin_req_req_fs,
//  input  rx_margin_res_ack_fs,
//  output rx_margin_res_cmd_sf,
//  output rx_margin_res_lane_num_sf,
//  output rx_margin_res_payload_sf,
//  output rx_margin_res_req_sf,
//  input  rxmarginclk_fs,
//  input  ub_gpi_fs,
//  output ub_gpo_sf);
endinterface

interface gtmpw_fabric_hs_clk_if;
wire          corerefclk0_fs;
wire          corerefclk1_fs;
wire          lcpllfreqlock_sf;
wire  [25:0]  lcpllsdmdata_fs;
wire          lcpllsdmtoggle_fs;
wire          mgtlcpllrefclkfa_sf;
wire          mgtrpllrefclkfa_sf;
wire          rpllfreqlock_sf;

  modport master (
    output corerefclk0_fs,
    output corerefclk1_fs,
    input  lcpllfreqlock_sf,
    output lcpllsdmdata_fs,
    output lcpllsdmtoggle_fs,
    input  mgtlcpllrefclkfa_sf,
    input  mgtrpllrefclkfa_sf,
    input  rpllfreqlock_sf);

  modport master_int (  output corerefclk0_fs,
    output corerefclk1_fs,
    input  lcpllfreqlock_sf,
    output lcpllsdmdata_fs,
    output lcpllsdmtoggle_fs,
    input  mgtlcpllrefclkfa_sf,
    input  mgtrpllrefclkfa_sf,
    input  rpllfreqlock_sf);

  modport slave (  input  corerefclk0_fs,
    input  corerefclk1_fs,
    output lcpllfreqlock_sf,
    input  lcpllsdmdata_fs,
    input  lcpllsdmtoggle_fs,
    output mgtlcpllrefclkfa_sf,
    output mgtrpllrefclkfa_sf,
    output rpllfreqlock_sf);

  modport slave_int (  input  corerefclk0_fs,
    input  corerefclk1_fs,
    output lcpllfreqlock_sf,
    input  lcpllsdmdata_fs,
    input  lcpllsdmtoggle_fs,
    output mgtlcpllrefclkfa_sf,
    output mgtrpllrefclkfa_sf,
    output rpllfreqlock_sf);

endinterface

interface gtmpw_fabric_refclk_if;
wire hrow_test_ck_fs;

modport master (    output hrow_test_ck_fs);

modport slave (   input hrow_test_ck_fs);

endinterface

interface chippipe_gt_direct_cfg_if;
  logic [3:0]  mc_tx_lane_cg_en;
  logic [3:0]  mc_rx_lane_cg_en;
  logic        mc_quad_instantiated;

  modport slave (
    input  mc_tx_lane_cg_en,
    input  mc_rx_lane_cg_en,
    input  mc_quad_instantiated
  );

  modport master (
    output  mc_tx_lane_cg_en,
    output  mc_rx_lane_cg_en,
    output  mc_quad_instantiated
  );
 endinterface

interface cpm6_chippipe_scan_if();

  logic [3:0] scan_chnl_in_fs_0_m;
  logic [3:0] scan_chnl_in_fs_1_m;
  logic [3:0] scan_chnl_in_fs_2_m;
  logic [3:0] scan_chnl_in_fs_3_m;
  logic [3:0] scan_chnl_in_fs_top_0_m;
  logic [3:0] scan_chnl_in_fs_top_1_m;
  logic [3:0] scan_chnl_in_fs_top_2_m;
  logic [3:0] scan_chnl_in_fs_top_3_m;
  logic       scan_clk_n_fs_0_m;
  logic       scan_clk_n_fs_1_m;
  logic       scan_clk_n_fs_2_m;
  logic       scan_clk_n_fs_3_m;
  logic       scan_clk_n_fs_top_0_m;
  logic       scan_clk_n_fs_top_1_m;
  logic       scan_clk_n_fs_top_2_m;
  logic       scan_clk_n_fs_top_3_m;
  logic [3:0] scan_chnl_mask_in_fs_0_m;
  logic [3:0] scan_chnl_mask_in_fs_1_m;
  logic [3:0] scan_chnl_mask_in_fs_2_m;
  logic [3:0] scan_chnl_mask_in_fs_3_m;
  logic [3:0] scan_chnl_mask_in_fs_top_0_m;
  logic [3:0] scan_chnl_mask_in_fs_top_1_m;
  logic [3:0] scan_chnl_mask_in_fs_top_2_m;
  logic [3:0] scan_chnl_mask_in_fs_top_3_m;
  logic       scan_cntrl_chnl_in_fs_0_m;
  logic       scan_cntrl_chnl_in_fs_1_m;
  logic       scan_cntrl_chnl_in_fs_2_m;
  logic       scan_cntrl_chnl_in_fs_3_m;
  logic       scan_cntrl_chnl_in_fs_top_0_m;
  logic       scan_cntrl_chnl_in_fs_top_1_m;
  logic       scan_cntrl_chnl_in_fs_top_2_m;
  logic       scan_cntrl_chnl_in_fs_top_3_m;
  logic       scan_edt_updt_n_fs_0_m;
  logic       scan_edt_updt_n_fs_1_m;
  logic       scan_edt_updt_n_fs_2_m;
  logic       scan_edt_updt_n_fs_3_m;
  logic       scan_edt_updt_n_fs_top_0_m;
  logic       scan_edt_updt_n_fs_top_1_m;
  logic       scan_edt_updt_n_fs_top_2_m;
  logic       scan_edt_updt_n_fs_top_3_m;
  logic       scan_en_n_fs_0_m;
  logic       scan_en_n_fs_1_m;
  logic       scan_en_n_fs_2_m;
  logic       scan_en_n_fs_3_m;
  logic       scan_en_n_fs_top_0_m;
  logic       scan_en_n_fs_top_1_m;
  logic       scan_en_n_fs_top_2_m;
  logic       scan_en_n_fs_top_3_m;
  logic       scan_mode_rst_n_fs_0_m;
  logic       scan_mode_rst_n_fs_1_m;
  logic       scan_mode_rst_n_fs_2_m;
  logic       scan_mode_rst_n_fs_3_m;
  logic       scan_mode_rst_n_fs_top_0_m;
  logic       scan_mode_rst_n_fs_top_1_m;
  logic       scan_mode_rst_n_fs_top_2_m;
  logic       scan_mode_rst_n_fs_top_3_m;
  logic       scan_odcc_chnl_mask_in_fs_0_m;
  logic       scan_odcc_chnl_mask_in_fs_1_m;
  logic       scan_odcc_chnl_mask_in_fs_2_m;
  logic       scan_odcc_chnl_mask_in_fs_3_m;
  logic       scan_odcc_chnl_mask_in_fs_top_0_m;
  logic       scan_odcc_chnl_mask_in_fs_top_1_m;
  logic       scan_odcc_chnl_mask_in_fs_top_2_m;
  logic       scan_odcc_chnl_mask_in_fs_top_3_m;
  logic [3:0] scan_chnl_in_gtctrl_fs_m;
  logic       scan_clk_n_gtctrl_fs_m;
  logic [3:0] scan_chnl_mask_in_gtctrl_fs_m;
  logic       scan_cntrl_chnl_in_gtctrl_fs_m;
  logic       scan_edt_updt_n_gtctrl_fs_m;
  logic       scan_en_n_gtctrl_fs_m;
  logic       scan_mode_rst_n_gtctrl_fs_m;
  logic [3:0] scan_chnl_in_gtctrl_fs_top_m;
  logic       scan_clk_n_gtctrl_fs_top_m;
  logic [3:0] scan_chnl_mask_in_gtctrl_fs_top_m;
  logic       scan_cntrl_chnl_in_gtctrl_fs_top_m;
  logic       scan_edt_updt_n_gtctrl_fs_top_m;
  logic       scan_en_n_gtctrl_fs_top_m;
  logic       scan_mode_rst_n_gtctrl_fs_top_m;
  logic       scan_odcc_chnl_mask_in_gtctrl_fs_m;
  logic       scan_odcc_chnl_mask_in_gtctrl_fs_top_m;
  logic [3:0] scan_chnl_out_sf_0_m;
  logic [3:0] scan_chnl_out_sf_1_m;
  logic [3:0] scan_chnl_out_sf_2_m;
  logic [3:0] scan_chnl_out_sf_3_m;
  logic [3:0] scan_chnl_out_sf_top_0_m;
  logic [3:0] scan_chnl_out_sf_top_1_m;
  logic [3:0] scan_chnl_out_sf_top_2_m;
  logic [3:0] scan_chnl_out_sf_top_3_m;
  logic       scan_cntrl_chnl_out_sf_0_m;
  logic       scan_cntrl_chnl_out_sf_1_m;
  logic       scan_cntrl_chnl_out_sf_2_m;
  logic       scan_cntrl_chnl_out_sf_3_m;
  logic       scan_cntrl_chnl_out_sf_top_0_m;
  logic       scan_cntrl_chnl_out_sf_top_1_m;
  logic       scan_cntrl_chnl_out_sf_top_2_m;
  logic       scan_cntrl_chnl_out_sf_top_3_m;
  logic       scan_cntrl_chnl_out_gtctrl_sf_m;
  logic       scan_cntrl_chnl_out_gtctrl_sf_top_m;
  logic [3:0] scan_chnl_out_gtctrl_sf_m;
  logic [3:0] scan_chnl_out_gtctrl_sf_top_m;

  modport master (
    output scan_chnl_in_fs_0_m,
    output scan_chnl_in_fs_1_m,
    output scan_chnl_in_fs_2_m,
    output scan_chnl_in_fs_3_m,
    output scan_chnl_in_fs_top_0_m,
    output scan_chnl_in_fs_top_1_m,
    output scan_chnl_in_fs_top_2_m,
    output scan_chnl_in_fs_top_3_m,
    output scan_clk_n_fs_0_m,
    output scan_clk_n_fs_1_m,
    output scan_clk_n_fs_2_m,
    output scan_clk_n_fs_3_m,
    output scan_clk_n_fs_top_0_m,
    output scan_clk_n_fs_top_1_m,
    output scan_clk_n_fs_top_2_m,
    output scan_clk_n_fs_top_3_m,
    output scan_chnl_mask_in_fs_0_m,
    output scan_chnl_mask_in_fs_1_m,
    output scan_chnl_mask_in_fs_2_m,
    output scan_chnl_mask_in_fs_3_m,
    output scan_chnl_mask_in_fs_top_0_m,
    output scan_chnl_mask_in_fs_top_1_m,
    output scan_chnl_mask_in_fs_top_2_m,
    output scan_chnl_mask_in_fs_top_3_m,
    output scan_cntrl_chnl_in_fs_0_m,
    output scan_cntrl_chnl_in_fs_1_m,
    output scan_cntrl_chnl_in_fs_2_m,
    output scan_cntrl_chnl_in_fs_3_m,
    output scan_cntrl_chnl_in_fs_top_0_m,
    output scan_cntrl_chnl_in_fs_top_1_m,
    output scan_cntrl_chnl_in_fs_top_2_m,
    output scan_cntrl_chnl_in_fs_top_3_m,
    output scan_edt_updt_n_fs_0_m,
    output scan_edt_updt_n_fs_1_m,
    output scan_edt_updt_n_fs_2_m,
    output scan_edt_updt_n_fs_3_m,
    output scan_edt_updt_n_fs_top_0_m,
    output scan_edt_updt_n_fs_top_1_m,
    output scan_edt_updt_n_fs_top_2_m,
    output scan_edt_updt_n_fs_top_3_m,
    output scan_en_n_fs_0_m,
    output scan_en_n_fs_1_m,
    output scan_en_n_fs_2_m,
    output scan_en_n_fs_3_m,
    output scan_en_n_fs_top_0_m,
    output scan_en_n_fs_top_1_m,
    output scan_en_n_fs_top_2_m,
    output scan_en_n_fs_top_3_m,
    output scan_mode_rst_n_fs_0_m,
    output scan_mode_rst_n_fs_1_m,
    output scan_mode_rst_n_fs_2_m,
    output scan_mode_rst_n_fs_3_m,
    output scan_mode_rst_n_fs_top_0_m,
    output scan_mode_rst_n_fs_top_1_m,
    output scan_mode_rst_n_fs_top_2_m,
    output scan_mode_rst_n_fs_top_3_m,
    output scan_odcc_chnl_mask_in_fs_0_m,
    output scan_odcc_chnl_mask_in_fs_1_m,
    output scan_odcc_chnl_mask_in_fs_2_m,
    output scan_odcc_chnl_mask_in_fs_3_m,
    output scan_odcc_chnl_mask_in_fs_top_0_m,
    output scan_odcc_chnl_mask_in_fs_top_1_m,
    output scan_odcc_chnl_mask_in_fs_top_2_m,
    output scan_odcc_chnl_mask_in_fs_top_3_m,
    output scan_chnl_in_gtctrl_fs_m,
    output scan_clk_n_gtctrl_fs_m,
    output scan_chnl_mask_in_gtctrl_fs_m,
    output scan_cntrl_chnl_in_gtctrl_fs_m,
    output scan_edt_updt_n_gtctrl_fs_m,
    output scan_en_n_gtctrl_fs_m,
    output scan_mode_rst_n_gtctrl_fs_m,
    output scan_chnl_in_gtctrl_fs_top_m,
    output scan_clk_n_gtctrl_fs_top_m,
    output scan_chnl_mask_in_gtctrl_fs_top_m,
    output scan_cntrl_chnl_in_gtctrl_fs_top_m,
    output scan_edt_updt_n_gtctrl_fs_top_m,
    output scan_en_n_gtctrl_fs_top_m,
    output scan_mode_rst_n_gtctrl_fs_top_m,
    output scan_odcc_chnl_mask_in_gtctrl_fs_m,
    output scan_odcc_chnl_mask_in_gtctrl_fs_top_m,
    input  scan_chnl_out_sf_0_m,
    input  scan_chnl_out_sf_1_m,
    input  scan_chnl_out_sf_2_m,
    input  scan_chnl_out_sf_3_m,
    input  scan_chnl_out_sf_top_0_m,
    input  scan_chnl_out_sf_top_1_m,
    input  scan_chnl_out_sf_top_2_m,
    input  scan_chnl_out_sf_top_3_m,
    input  scan_cntrl_chnl_out_sf_0_m,
    input  scan_cntrl_chnl_out_sf_1_m,
    input  scan_cntrl_chnl_out_sf_2_m,
    input  scan_cntrl_chnl_out_sf_3_m,
    input  scan_cntrl_chnl_out_sf_top_0_m,
    input  scan_cntrl_chnl_out_sf_top_1_m,
    input  scan_cntrl_chnl_out_sf_top_2_m,
    input  scan_cntrl_chnl_out_sf_top_3_m,
    input  scan_cntrl_chnl_out_gtctrl_sf_m,
    input  scan_cntrl_chnl_out_gtctrl_sf_top_m,
    input  scan_chnl_out_gtctrl_sf_m,
    input  scan_chnl_out_gtctrl_sf_top_m
  );

  modport slave (
    input  scan_chnl_in_fs_0_m,
    input  scan_chnl_in_fs_1_m,
    input  scan_chnl_in_fs_2_m,
    input  scan_chnl_in_fs_3_m,
    input  scan_chnl_in_fs_top_0_m,
    input  scan_chnl_in_fs_top_1_m,
    input  scan_chnl_in_fs_top_2_m,
    input  scan_chnl_in_fs_top_3_m,
    input  scan_clk_n_fs_0_m,
    input  scan_clk_n_fs_1_m,
    input  scan_clk_n_fs_2_m,
    input  scan_clk_n_fs_3_m,
    input  scan_clk_n_fs_top_0_m,
    input  scan_clk_n_fs_top_1_m,
    input  scan_clk_n_fs_top_2_m,
    input  scan_clk_n_fs_top_3_m,
    input  scan_chnl_mask_in_fs_0_m,
    input  scan_chnl_mask_in_fs_1_m,
    input  scan_chnl_mask_in_fs_2_m,
    input  scan_chnl_mask_in_fs_3_m,
    input  scan_chnl_mask_in_fs_top_0_m,
    input  scan_chnl_mask_in_fs_top_1_m,
    input  scan_chnl_mask_in_fs_top_2_m,
    input  scan_chnl_mask_in_fs_top_3_m,
    input  scan_cntrl_chnl_in_fs_0_m,
    input  scan_cntrl_chnl_in_fs_1_m,
    input  scan_cntrl_chnl_in_fs_2_m,
    input  scan_cntrl_chnl_in_fs_3_m,
    input  scan_cntrl_chnl_in_fs_top_0_m,
    input  scan_cntrl_chnl_in_fs_top_1_m,
    input  scan_cntrl_chnl_in_fs_top_2_m,
    input  scan_cntrl_chnl_in_fs_top_3_m,
    input  scan_edt_updt_n_fs_0_m,
    input  scan_edt_updt_n_fs_1_m,
    input  scan_edt_updt_n_fs_2_m,
    input  scan_edt_updt_n_fs_3_m,
    input  scan_edt_updt_n_fs_top_0_m,
    input  scan_edt_updt_n_fs_top_1_m,
    input  scan_edt_updt_n_fs_top_2_m,
    input  scan_edt_updt_n_fs_top_3_m,
    input  scan_en_n_fs_0_m,
    input  scan_en_n_fs_1_m,
    input  scan_en_n_fs_2_m,
    input  scan_en_n_fs_3_m,
    input  scan_en_n_fs_top_0_m,
    input  scan_en_n_fs_top_1_m,
    input  scan_en_n_fs_top_2_m,
    input  scan_en_n_fs_top_3_m,
    input  scan_mode_rst_n_fs_0_m,
    input  scan_mode_rst_n_fs_1_m,
    input  scan_mode_rst_n_fs_2_m,
    input  scan_mode_rst_n_fs_3_m,
    input  scan_mode_rst_n_fs_top_0_m,
    input  scan_mode_rst_n_fs_top_1_m,
    input  scan_mode_rst_n_fs_top_2_m,
    input  scan_mode_rst_n_fs_top_3_m,
    input  scan_odcc_chnl_mask_in_fs_0_m,
    input  scan_odcc_chnl_mask_in_fs_1_m,
    input  scan_odcc_chnl_mask_in_fs_2_m,
    input  scan_odcc_chnl_mask_in_fs_3_m,
    input  scan_odcc_chnl_mask_in_fs_top_0_m,
    input  scan_odcc_chnl_mask_in_fs_top_1_m,
    input  scan_odcc_chnl_mask_in_fs_top_2_m,
    input  scan_odcc_chnl_mask_in_fs_top_3_m,
    input  scan_chnl_in_gtctrl_fs_m,
    input  scan_clk_n_gtctrl_fs_m,
    input  scan_chnl_mask_in_gtctrl_fs_m,
    input  scan_cntrl_chnl_in_gtctrl_fs_m,
    input  scan_edt_updt_n_gtctrl_fs_m,
    input  scan_en_n_gtctrl_fs_m,
    input  scan_mode_rst_n_gtctrl_fs_m,
    input  scan_chnl_in_gtctrl_fs_top_m,
    input  scan_clk_n_gtctrl_fs_top_m,
    input  scan_chnl_mask_in_gtctrl_fs_top_m,
    input  scan_cntrl_chnl_in_gtctrl_fs_top_m,
    input  scan_edt_updt_n_gtctrl_fs_top_m,
    input  scan_en_n_gtctrl_fs_top_m,
    input  scan_mode_rst_n_gtctrl_fs_top_m,
    input  scan_odcc_chnl_mask_in_gtctrl_fs_m,
    input  scan_odcc_chnl_mask_in_gtctrl_fs_top_m,
    output scan_chnl_out_sf_0_m,
    output scan_chnl_out_sf_1_m,
    output scan_chnl_out_sf_2_m,
    output scan_chnl_out_sf_3_m,
    output scan_chnl_out_sf_top_0_m,
    output scan_chnl_out_sf_top_1_m,
    output scan_chnl_out_sf_top_2_m,
    output scan_chnl_out_sf_top_3_m,
    output scan_cntrl_chnl_out_sf_0_m,
    output scan_cntrl_chnl_out_sf_1_m,
    output scan_cntrl_chnl_out_sf_2_m,
    output scan_cntrl_chnl_out_sf_3_m,
    output scan_cntrl_chnl_out_sf_top_0_m,
    output scan_cntrl_chnl_out_sf_top_1_m,
    output scan_cntrl_chnl_out_sf_top_2_m,
    output scan_cntrl_chnl_out_sf_top_3_m,
    output scan_cntrl_chnl_out_gtctrl_sf_m,
    output scan_cntrl_chnl_out_gtctrl_sf_top_m,
    output scan_chnl_out_gtctrl_sf_m,
    output scan_chnl_out_gtctrl_sf_top_m
  );
endinterface : cpm6_chippipe_scan_if

interface cpm6_pl_dbi_axil_if #(DATA_WIDTH = 32, ADDR_WIDTH = 32, AUSER = 11, RESP_USER = 4)();
  logic wready;
  logic wvalid;
  logic rready;
  logic rvalid;
  logic bready;
  logic bvalid;
  logic awready;
  logic awvalid;
  logic arready;
  logic arvalid;

  logic [1:0] rresp;
  logic [1:0] bresp;
  logic [2:0] awprot;
  logic [2:0] arprot;

  logic [AUSER-1:0] awuser;
  logic [AUSER-1:0] aruser;
  logic [RESP_USER-1:0] buser;

  logic [ADDR_WIDTH-1:0] awaddr;
  logic [ADDR_WIDTH-1:0] araddr;

  logic [DATA_WIDTH-1:0] wdata;
  logic [DATA_WIDTH-1:0] rdata;
  logic [DATA_WIDTH/8-1:0] wuser;
  logic [DATA_WIDTH/8-1:0] wstrb;
  logic [DATA_WIDTH/8-1:0] ruser;

  modport s (
     input  awaddr
    ,output awready
    ,input  awvalid
    ,input  awuser
    ,input  awprot
    ,input  araddr
    ,output arready
    ,input  arvalid
    ,input  aruser
    ,input  arprot
    ,input  wdata
    ,input  wuser
    ,input  wstrb
    ,output wready
    ,input  wvalid
    ,output rdata
    ,output rresp
    ,output ruser
    ,input  rready
    ,output rvalid
    ,output bresp
    ,output buser
    ,input  bready
    ,output bvalid
  );

  modport m (
     output awaddr
    ,input  awready
    ,output awvalid
    ,output awuser
    ,output awprot
    ,output araddr
    ,input  arready
    ,output arvalid
    ,output aruser
    ,output arprot
    ,output wdata
    ,output wuser
    ,output wstrb
    ,input  wready
    ,output wvalid
    ,input  rdata
    ,input  rresp
    ,input  ruser
    ,output rready
    ,input  rvalid
    ,input  bresp
    ,input  buser
    ,output bready
    ,input  bvalid
  );


  modport axi_trace (
     input  awaddr
    ,input  awready
    ,input  awvalid
    ,input  awuser
    ,input  awprot
    ,input  araddr
    ,input  arready
    ,input  arvalid
    ,input  aruser
    ,input  arprot
    ,input  wdata
    ,input  wuser
    ,input  wstrb
    ,input  wready
    ,input  wvalid
    ,input  rdata
    ,input  rresp
    ,input  ruser
    ,input  rready
    ,input  rvalid
    ,input  bresp
    ,input  buser
    ,input  bready
    ,input  bvalid
  );

endinterface : cpm6_pl_dbi_axil_if

interface cpm6_pl_dfx_scw15_if();

  logic [14:0] f2c_scan_chnl_in_ext;
  logic [14:0] f2c_scan_chnl_mask_in_ext;
  logic [14:0] c2f_scan_chnl_out_ext;
  logic        f2c_scan_odcc_chnl_in_ext;
  logic        c2f_scan_odcc_chnl_out_ext;
  logic       f2c_scan_odcc_chnl_mask_in_ext;
  //Removed spare bits since they are not needed in CPM6. Can be added later

  modport slave (
    input  f2c_scan_chnl_in_ext,
    input  f2c_scan_chnl_mask_in_ext,
    input  f2c_scan_odcc_chnl_in_ext,
    input  f2c_scan_odcc_chnl_mask_in_ext,
    output c2f_scan_odcc_chnl_out_ext,
    output c2f_scan_chnl_out_ext
  );


  modport master (
    output f2c_scan_chnl_in_ext,
    output f2c_scan_chnl_mask_in_ext,
    output f2c_scan_odcc_chnl_in_ext,
    output f2c_scan_odcc_chnl_mask_in_ext,
    input  c2f_scan_odcc_chnl_out_ext,
    input  c2f_scan_chnl_out_ext
  );

endinterface : cpm6_pl_dfx_scw15_if

interface cpm6_pl_dfx_scw7_if();
  logic [6:0] f2c_scan_chnl_in_ext;
  logic [6:0] f2c_scan_chnl_mask_in_ext;
  logic [6:0] c2f_scan_chnl_out_ext;
  logic       f2c_scan_odcc_chnl_in_ext;
  logic       c2f_scan_odcc_chnl_out_ext;
  logic       f2c_scan_odcc_chnl_mask_in_ext;

  modport slave (
    input  f2c_scan_chnl_in_ext,
    input  f2c_scan_chnl_mask_in_ext,
    input  f2c_scan_odcc_chnl_in_ext,
    input  f2c_scan_odcc_chnl_mask_in_ext,
    output c2f_scan_odcc_chnl_out_ext,
    output c2f_scan_chnl_out_ext
  );

  modport master (
    output f2c_scan_chnl_in_ext,
    output f2c_scan_chnl_mask_in_ext,
    output f2c_scan_odcc_chnl_in_ext,
    output f2c_scan_odcc_chnl_mask_in_ext,
    input  c2f_scan_odcc_chnl_out_ext,
    input  c2f_scan_chnl_out_ext
  );

endinterface : cpm6_pl_dfx_scw7_if

interface cpm6_pl_dfx_ctrl_if();
  logic f2c_scan_clk_n_ext;
  logic f2c_scan_en_n_ext;
  logic f2c_scan_mode_rst_n_ext;
  logic f2c_scan_edt_updt_n_ext;

  modport slave (
    input  f2c_scan_en_n_ext,
    input  f2c_scan_clk_n_ext,
    input  f2c_scan_mode_rst_n_ext,
    input  f2c_scan_edt_updt_n_ext
  );

  modport master (
    output f2c_scan_en_n_ext,
    output f2c_scan_clk_n_ext,
    output f2c_scan_mode_rst_n_ext,
    output f2c_scan_edt_updt_n_ext
  );

endinterface : cpm6_pl_dfx_ctrl_if

interface cpm6_gpio_if ();

  logic [31:0] cpm_pl_gpio;
  logic [31:0] pl_cpm_gpio;

  modport cpm (
    input  pl_cpm_gpio,
    output cpm_pl_gpio
  );

  modport pl (
    output pl_cpm_gpio,
    input  cpm_pl_gpio
  );

endinterface : cpm6_gpio_if

interface ams_sat_fabric_if ();
  // ADC test + Alarms
  logic        fabric_clk;
  logic [15:0] test_adc_in;
  logic [15:0] test_adc_out;
  logic [7:0]  alarm;
  // PVT bus
  logic [15:0] p_value;
  logic [15:0] v_value;
  logic [15:0] t_value;
  logic        data_ready;

  modport sat (
    input   fabric_clk,
    input   test_adc_in,
    output  test_adc_out,
    output  alarm,
    output  p_value,
    output  v_value,
    output  t_value,
    output  data_ready
  );

  modport fabric (
    output fabric_clk,
    output test_adc_in,
    input  test_adc_out,
    input  alarm,
    input  p_value,
    input  v_value,
    input  t_value,
    input  data_ready
  );

  modport sat_user (
    output alarm,
    output p_value,
    output v_value,
    output t_value,
    output data_ready
  );

  modport sat_test (
    input  fabric_clk,
    input  test_adc_in,
    output test_adc_out
  );

  modport fab_user (
    input  alarm,
    input  p_value,
    input  v_value,
    input  t_value,
    input  data_ready
  );

  modport fab_test (
    output fabric_clk,
    output test_adc_in,
    input  test_adc_out
  );

endinterface

interface chippipe_cpm6_pipe_debug_if;
  logic [6:0]  chippipe_dbg_bus_in;
  logic [28:0] chippipe_dbg_bus_out;

  logic [19:0] upi2_ctrl_phy_cmdcode_fs;
  logic        upi2_ctrl_phy_cmdreq_fs;
  logic        upi2_phy_ctrl_cmderror_sf;
  logic        upi2_phy_ctrl_cmdready_sf;
  logic [3:0]  upi2_ctrl_phy_slavesel_fs;
  logic [31:0] upi2_phy_ctrl_cmdresp_sf;
  logic        upi2_phy_ctrl_msgreq_sf;

  modport slave (
    output chippipe_dbg_bus_out,
    input  upi2_ctrl_phy_cmdcode_fs,
    input  upi2_ctrl_phy_cmdreq_fs,
    input  upi2_ctrl_phy_slavesel_fs,
    output upi2_phy_ctrl_cmderror_sf,
    output upi2_phy_ctrl_cmdready_sf,
    output upi2_phy_ctrl_cmdresp_sf,
    output upi2_phy_ctrl_msgreq_sf,
    input  chippipe_dbg_bus_in
  );

  modport master (
    input  chippipe_dbg_bus_out,
    output upi2_ctrl_phy_cmdcode_fs,
    output upi2_ctrl_phy_cmdreq_fs,
    output upi2_ctrl_phy_slavesel_fs,
    input  upi2_phy_ctrl_cmderror_sf,
    input  upi2_phy_ctrl_cmdready_sf,
    input  upi2_phy_ctrl_cmdresp_sf,
    input  upi2_phy_ctrl_msgreq_sf,
    output chippipe_dbg_bus_in
  );
endinterface

interface cpm6_pl_dfx_scw_sysmon_if();
  logic f2c_scan_chnl_in_ext;
  logic c2f_scan_chnl_out_ext;
  logic f2c_scan_odcc_chnl_in_ext;
  logic c2f_scan_odcc_chnl_out_ext;
  //Removed spare bits since they are not needed in CPM6. Can be added later

  modport slave (
    input  f2c_scan_chnl_in_ext,
    output c2f_scan_chnl_out_ext,
    input  f2c_scan_odcc_chnl_in_ext,
    output c2f_scan_odcc_chnl_out_ext
  );

  modport master (
    output f2c_scan_chnl_in_ext,
    input  c2f_scan_chnl_out_ext,
    output f2c_scan_odcc_chnl_in_ext,
    input  c2f_scan_odcc_chnl_out_ext
  );

endinterface : cpm6_pl_dfx_scw_sysmon_if

interface pcie6_pipe_if ();

  logic        phy_mac_maxpclkack_n; // Not part of standard PIPE interface
  logic [63:0] phy_mac_messagebus;
  logic [7:0]  phy_mac_pclkchangeok;
  logic [639:0]phy_mac_rxdata;
  logic [7:0]  phy_mac_rxelecidle;
  logic [7:0]  phy_mac_rxstandbystatus;
  logic [23:0] phy_mac_rxstatus;
  logic [7:0]  phy_mac_rxvalid;
  logic [7:0]  phy_mac_phystatus;
  logic        mac_phy_maxpclkreq_n; // Not part of standard PIPE interface
  logic [7:0]  mac_phy_pclkchangeack;
  logic [31:0] phy_cfg_status; // Not part of standard PIPE interface
  logic [7:0]  mac_phy_dirchange; // Not part of standard PIPE interface
  logic [63:0] mac_phy_messagebus;  // name changed from phy_if_cpcie_mbus
  logic [2:0]  mac_phy_pclk_rate;
  logic [3:0]  mac_phy_powerdown;
  logic [2:0]  mac_phy_rate;
  logic [7:0]  mac_phy_rxstandby;
  logic [1:0]  mac_phy_rxwidth;
  logic [639:0]mac_phy_txdata;
  logic [7:0]  mac_phy_txdatavalid;
  logic [7:0]  mac_phy_txdetectrx_loopback;
  logic [31:0] mac_phy_txelecidle;
  logic [1:0]  mac_phy_width;
  logic        mac_phy_asyncpowerchangeack;
  logic        mac_phy_rxelecidle_disable;
  logic        mac_phy_serdes_arch;
  logic        mac_phy_txcommonmode_disable;
  logic [7:0]  serdes_pipe_rxready; // Not part of standard PIPE interface
  logic [7:0]  serdes_pipe_turnoff_lanes; // Not part of standard PIPE interface

  logic        mac_phy_sris_enable; //newly added
  logic        mac_phy_commonclock_enable; //newly added
  logic [31:0] mac_phy_cfg_phy_control; //newly added
  logic [2:0]  mac_phy_current_data_rate; //newly added
  logic [5:0]  mac_phy_ltssm_state;
  logic [15:0] spare;
  logic [15:0] phy_mac_spare;
  logic        phy_rst_n;

// fixme need to add sris en and common clk en , pm_current_data_rate, phy_if_cfg_phy_control
  modport m (
    input   phy_mac_maxpclkack_n,
    input   phy_mac_messagebus,
    input   phy_mac_pclkchangeok,
    input   phy_mac_rxdata,
    input   phy_mac_rxelecidle,
    input   phy_mac_rxstandbystatus,
    input   phy_mac_rxstatus,
    input   phy_mac_rxvalid,
    input   phy_mac_phystatus,
    output  mac_phy_maxpclkreq_n,
    output  mac_phy_pclkchangeack,
    input   phy_cfg_status,
    output  mac_phy_dirchange, //
    output  mac_phy_messagebus, //
    output  mac_phy_pclk_rate, //
    output  mac_phy_powerdown, //
    output  mac_phy_rate, //
    output  mac_phy_rxstandby, //
    output  mac_phy_rxwidth, //
    output  mac_phy_txdata, //
    output  mac_phy_txdatavalid, //
    output  mac_phy_txdetectrx_loopback, //
    output  mac_phy_txelecidle, //
    output  mac_phy_width, //
    output  mac_phy_asyncpowerchangeack, //
    output  mac_phy_rxelecidle_disable, //
    output  mac_phy_serdes_arch, //
    output  mac_phy_txcommonmode_disable, //
    output  serdes_pipe_rxready,
    output  serdes_pipe_turnoff_lanes,
    output  mac_phy_sris_enable,
    output  mac_phy_commonclock_enable,
    output  mac_phy_cfg_phy_control,
    output  mac_phy_current_data_rate,
    output  mac_phy_ltssm_state,
    output  spare,
    input   phy_mac_spare,
    output  phy_rst_n
  );

  modport s (
    output phy_mac_maxpclkack_n,
    output phy_mac_messagebus,
    output phy_mac_pclkchangeok,
    output phy_mac_rxdata,
    output phy_mac_rxelecidle,
    output phy_mac_rxstandbystatus,
    output phy_mac_rxstatus,
    output phy_mac_rxvalid,
    output phy_mac_phystatus,
    output phy_cfg_status,
    input  mac_phy_pclkchangeack,
    input  mac_phy_maxpclkreq_n,
    input  mac_phy_dirchange, //
    input  mac_phy_messagebus, //
    input  mac_phy_pclk_rate, //
    input  mac_phy_powerdown, //
    input  mac_phy_rate, //
    input  mac_phy_rxstandby, //
    input  mac_phy_rxwidth, //
    input  mac_phy_txdata, //
    input  mac_phy_txdatavalid, //
    input  mac_phy_txdetectrx_loopback, //
    input  mac_phy_txelecidle, //
    input  mac_phy_width, //
    input  mac_phy_asyncpowerchangeack, //
    input  mac_phy_rxelecidle_disable, //
    input  mac_phy_serdes_arch, //
    input  mac_phy_txcommonmode_disable, //
    input  serdes_pipe_rxready,
    input  serdes_pipe_turnoff_lanes,
    input  mac_phy_sris_enable,
    input  mac_phy_commonclock_enable,
    input  mac_phy_cfg_phy_control,
    input  mac_phy_current_data_rate,
    input  mac_phy_ltssm_state,
    input  spare,
    output phy_mac_spare,
    input  phy_rst_n
  );
endinterface : pcie6_pipe_if

interface msix_intf;
  logic [63:0] msix_addr;
  logic [31:0] msix_data;
  logic [2:0]  ven_msi_tc;
  logic        ven_msi_req;
  logic        ven_msi_grant;
  logic [2:0]  ven_msi_func_num;
  logic [7:0]  ven_msi_vfunc_num;
  logic        ven_msi_vfunc_active;

  modport master (
    output msix_addr,
    output msix_data,
    output ven_msi_tc,
    output ven_msi_req,
    input  ven_msi_grant,
    output ven_msi_func_num,
    output ven_msi_vfunc_num,
    output ven_msi_vfunc_active
  );

  modport slave (
    input  msix_addr,
    input  msix_data,
    input  ven_msi_tc,
    input  ven_msi_req,
    output ven_msi_grant,
    input  ven_msi_func_num,
    input  ven_msi_vfunc_num,
    input  ven_msi_vfunc_active
  );
endinterface

interface msix_user_intf;
  logic        user_req;
  logic        user_grant; // Potential backpressure to user logic to not send interrupt/hold current interrupt
  logic        user_error; // 00 = no error, 01 = mask error (= pending set), 10 = parity error (might not want to support)
  logic [2:0]  user_func_num;
  logic [1:0]  user_operation; // 00 = send interrupt, 01 = check pending status, 10 = clear pending status
  logic [7:0]  user_vfunc_num;
  logic [10:0] user_vector_num;
  logic        user_vfunc_active;

  modport master(
    output user_req,
    input  user_error,
    input  user_grant,
    output user_func_num,
    output user_operation,
    output user_vfunc_num,
    output user_vector_num,
    output user_vfunc_active
  );

  modport slave(
    input  user_req,
    output user_grant,
    output user_error,
    input  user_func_num,
    input  user_operation,
    input  user_vfunc_num,
    input  user_vector_num,
    input  user_vfunc_active
  );
endinterface

interface msix_bram_intf #(parameter RAM_ADDR_WIDTH = 1024, RAM_DATA_WIDTH = 32, BYTE_WRITE_WIDTH = 32);
  logic rd_en;
  logic wr_port_en;
  logic [RAM_ADDR_WIDTH - 1:0] rd_addr;
  logic [RAM_DATA_WIDTH - 1:0] rd_data;
  logic [RAM_ADDR_WIDTH - 1:0] wr_addr;
  logic [RAM_DATA_WIDTH - 1:0] wr_data;
  logic [RAM_DATA_WIDTH/BYTE_WRITE_WIDTH - 1:0] wr_en;

  modport slave(
    input  rd_en,
    input  wr_en,
    input  rd_addr,
    output rd_data,
    input  wr_addr,
    input  wr_data,
    input  wr_port_en
  );

  modport master(
    output rd_en,
    output wr_en,
    output rd_addr,
    input  rd_data,
    output wr_addr,
    output wr_data,
    output wr_port_en
  );
endinterface

interface msix_send_interrupt_intf;
  logic        send_req;
  logic        send_ack;
  logic [63:0] send_addr;
  logic [31:0] send_data;
  logic [2:0]  send_func_num;
  logic [7:0]  send_vfunc_num;
  logic        send_vfunc_active;

  modport slave(
    input  send_func_num,
    input  send_vfunc_num,
    input  send_vfunc_active,
    input  send_req,
    input  send_addr,
    input  send_data,
    output send_ack
  );

  modport master(
    output send_func_num,
    output send_vfunc_num,
    output send_vfunc_active,
    output send_req,
    output send_addr,
    output send_data,
    input  send_ack
  );
endinterface

interface msix_lookup_req_intf;
  logic [2:0]  lookup_func_num;
  logic [7:0]  lookup_vfunc_num;
  logic        lookup_vfunc_active;
  logic [10:0] lookup_vector_num;
  logic        lookup_req;
  logic        lookup_ack;
  logic [63:0] lookup_addr;
  logic [31:0] lookup_data;
  logic [1:0]  lookup_operation; // 00 = lookup, 01 = check pending status, 10 = clear pending status
  logic        lookup_error; // LOOKUP: 00 = no error, 01 = mask error (pending set), maybe 10 = parity error
                             // LOOKUP_QUERY: 0 = no pending, 1 = pending bit set
                             // LOOKUP_CLEAR: 0 = pending bit cleared, 1 = pending still set - should never happen!

  modport master(
    output lookup_func_num,
    output lookup_vfunc_num,
    output lookup_vfunc_active,
    output lookup_vector_num,
    output lookup_req,
    output lookup_operation,
    input lookup_addr,
    input lookup_data,
    input lookup_ack,
    input lookup_error
  );

  modport slave(
    input lookup_func_num,
    input lookup_vfunc_num,
    input lookup_vfunc_active,
    input lookup_vector_num,
    input lookup_req,
    input lookup_operation,
    output lookup_addr,
    output lookup_data,
    output lookup_ack,
    output lookup_error
  );
endinterface

interface msix_ctrl_logic_sideband_intf #(NUM_PFS = 8, NUM_VFS = 256);
  logic msix_pf_info_ready;
  logic msix_vf_info_ready;
  logic msix_pf_cfg_flit_mode; // PF0 only, but will use all PF info ready as valid signal
  logic [NUM_PFS-1:0] msix_pf_msix_enable;
  logic [NUM_PFS-1:0] msix_pf_msix_func_mask;
  logic [NUM_PFS-1:0] msix_pf_flr_pf_active;
  logic [NUM_VFS > 0 ? (NUM_VFS - 1) : 0 :0] msix_vf_msix_enable;
  logic [NUM_VFS > 0 ? (NUM_VFS - 1) : 0 :0] msix_vf_msix_func_mask;
  logic [NUM_VFS > 0 ? (NUM_VFS - 1) : 0 :0] msix_vf_flr_vf_active;

  modport master(
    output msix_pf_msix_enable,
    output msix_pf_msix_func_mask,
    output msix_pf_flr_pf_active,
    output msix_vf_msix_enable,
    output msix_vf_msix_func_mask,
    output msix_vf_flr_vf_active,
    output msix_pf_cfg_flit_mode,
    output msix_pf_info_ready,
    output msix_vf_info_ready
  );

  modport slave(
    input msix_pf_msix_enable,
    input msix_pf_msix_func_mask,
    input msix_pf_flr_pf_active,
    input msix_vf_msix_enable,
    input msix_vf_msix_func_mask,
    input msix_vf_flr_vf_active,
    input msix_pf_cfg_flit_mode,
    input msix_pf_info_ready,
    input msix_vf_info_ready
  );
endinterface

interface axil_intf_defs_cpm6 #(parameter AXIL_ADDR_WIDTH=64, parameter AXIL_DATA_WIDTH=64, parameter AXIL_AXUSER_WIDTH=8);

  logic rvalid;
  logic rready;
  logic bready;
  logic bvalid;
  logic wready;
  logic wvalid;
  logic arready;
  logic arvalid;
  logic awready;
  logic awvalid;

  logic [1:0] rresp;
  logic [1:0] bresp;
  logic [2:0] arprot;
  logic [2:0] awprot;

  logic [AXIL_ADDR_WIDTH-1:0]   araddr;
  logic [AXIL_ADDR_WIDTH-1:0]   awaddr;
  logic [AXIL_DATA_WIDTH-1:0]   rdata;
  logic [AXIL_DATA_WIDTH-1:0]   wdata;
  logic [(AXIL_DATA_WIDTH/8)-1:0] wstrb;
  logic [AXIL_AXUSER_WIDTH-1:0]   aruser;
  logic [AXIL_AXUSER_WIDTH-1:0]   ruser;
  logic [AXIL_AXUSER_WIDTH-1:0]   awuser;
  logic [AXIL_AXUSER_WIDTH-1:0]   buser;
  logic [AXIL_AXUSER_WIDTH-1:0]   wuser;

  // Master interface
  modport master(
     output  araddr
    ,output  arprot
    ,input   arready
    ,output  aruser
    ,output  arvalid
    ,input   rdata
    ,output  rready
    ,input   rresp
    ,input   ruser
    ,input   rvalid
    ,output  awaddr
    ,output  awprot
    ,input   awready
    ,output  awuser
    ,output  awvalid
    ,output  bready
    ,input   bresp
    ,input   buser
    ,input   bvalid
    ,output  wdata
    ,output  wuser
    ,input   wready
    ,output  wstrb
    ,output  wvalid
  );

  // Slave interface
  modport slave(
     input  araddr
    ,input  arprot
    ,output arready
    ,input  aruser
    ,input  arvalid
    ,output rdata
    ,input  rready
    ,output rresp
    ,output ruser
    ,output rvalid
    ,input  awaddr
    ,input  awprot
    ,output awready
    ,input  awuser
    ,input  awvalid
    ,input  bready
    ,output bresp
    ,output buser
    ,output bvalid
    ,input  wdata
    ,input  wuser
    ,output wready
    ,input  wstrb
    ,input  wvalid
  );

endinterface:axil_intf_defs_cpm6

interface cpi_req
  import cpm6_v1_0_40791_pkg::req_hdr_u;
();

  // VALID
  logic        is_valid;
  logic        block;
  logic        early_valid;
  // FLOW_C
  logic [ 3:0] protocol_id;
  logic [ 3:0] vc_id;
  logic        shared_credit;
  // HDR
  req_hdr_u    header;
  logic        cmd_parity;
  logic [11:0] spid;
  logic [11:0] dpid;
  // CREDIT
  logic        rxcrd_valid;
  logic [ 3:0] rxcrd_protocol_id;
  logic [ 3:0] rxcrd_vc_id;
  logic        rxcrd_shared;
  logic        txblock_crd_flow;

  modport master (
    output is_valid,
           early_valid,
           protocol_id, 
           vc_id,
           shared_credit,
           header,
           cmd_parity,
           spid,
           dpid,
           txblock_crd_flow,
    input  block,
           rxcrd_valid,
           rxcrd_protocol_id,
           rxcrd_vc_id,
           rxcrd_shared
  );

  modport slave (
    input  is_valid,
           early_valid,
           protocol_id, 
           vc_id,
           shared_credit,
           header,
           cmd_parity,
           spid,
           dpid,
           txblock_crd_flow,
    output block,
           rxcrd_valid,
           rxcrd_protocol_id,
           rxcrd_vc_id,
           rxcrd_shared
  );

  modport monitor (
    input  is_valid,
           early_valid,
           protocol_id,
           vc_id,
           shared_credit,
           header,
           cmd_parity,
           spid,
           dpid,
           txblock_crd_flow,
           block,
           rxcrd_valid,
           rxcrd_protocol_id,
           rxcrd_vc_id,
           rxcrd_shared
  );

endinterface:cpi_req

interface cpi_data
  import cpm6_v1_0_40791_pkg::data_hdr_u;
#(
  parameter BODY_WIDTH=512
);

  // VALID
  logic        is_valid;
  logic        block;
  logic        early_valid;
  // FLOW_C
  logic [ 3:0] protocol_id;
  logic [ 3:0] vc_id;
  logic        shared_credit;
  // HDR
  data_hdr_u   header;
  logic        sz;
  logic        cmd_parity;
  logic [11:0] spid;
  logic [11:0] dpid;
  // PAYLOAD
  logic [     BODY_WIDTH-1:0] body;
  logic [ (BODY_WIDTH/8)-1:0] byte_enable;
  logic                       byte_enable_parity;
  logic                       poison;
  logic [(BODY_WIDTH/64)-1:0] parity; 
  // EOP
  logic        eop;
  // CREDIT
  logic        rxcrd_valid;
  logic [ 3:0] rxcrd_protocol_id;
  logic [ 3:0] rxcrd_vc_id;
  logic        rxcrd_shared;
  logic        txblock_crd_flow;

  modport master (
    output is_valid,
           early_valid,
           protocol_id, 
           vc_id,
           shared_credit,
           header,
           sz,
           cmd_parity,
           spid,
           dpid,
           body,
           byte_enable,
           byte_enable_parity,
           poison,
           parity,
           eop,
           txblock_crd_flow,
    input  block,
           rxcrd_valid,
           rxcrd_protocol_id,
           rxcrd_vc_id,
           rxcrd_shared
  );

  modport slave (
    input  is_valid,
           early_valid,
           protocol_id, 
           vc_id,
           shared_credit,
           header,
           sz,
           cmd_parity,
           spid,
           dpid,
           body,
           byte_enable,
           byte_enable_parity,
           poison,
           parity,
           eop,
           txblock_crd_flow,
    output block,
           rxcrd_valid,
           rxcrd_protocol_id,
           rxcrd_vc_id,
           rxcrd_shared
  );

  modport monitor (
    input  is_valid,
           early_valid,
           protocol_id,
           vc_id,
           shared_credit,
           header,
           sz,
           cmd_parity,
           spid,
           dpid,
           body,
           byte_enable,
           byte_enable_parity,
           poison,
           parity,
           eop,
           txblock_crd_flow,
           block,
           rxcrd_valid,
           rxcrd_protocol_id,
           rxcrd_vc_id,
           rxcrd_shared
  );

endinterface:cpi_data

interface cpi_rsp
  import cpm6_v1_0_40791_pkg::rsp_hdr_u;
();

  // VALID
  logic        is_valid;
  logic        block;
  logic        early_valid;
  // FLOW_C
  logic [ 3:0] protocol_id;
  logic [ 3:0] vc_id;
  logic        shared_credit;
  // HDR
  rsp_hdr_u    header;
  logic        cmd_parity;
  logic [11:0] spid;
  logic [11:0] dpid;
  // CREDIT
  logic        rxcrd_valid;
  logic [ 3:0] rxcrd_protocol_id;
  logic [ 3:0] rxcrd_vc_id;
  logic        rxcrd_shared;
  logic        txblock_crd_flow;

  modport master (
    output is_valid,
           early_valid,
           protocol_id, 
           vc_id,
           shared_credit,
           header,
           cmd_parity,
           spid,
           dpid,
           txblock_crd_flow,
    input  block,
           rxcrd_valid,
           rxcrd_protocol_id,
           rxcrd_vc_id,
           rxcrd_shared
  );

  modport slave (
    input  is_valid,
           early_valid,
           protocol_id, 
           vc_id,
           shared_credit,
           header,
           cmd_parity,
           spid,
           dpid,
           txblock_crd_flow,
    output block,
           rxcrd_valid,
           rxcrd_protocol_id,
           rxcrd_vc_id,
           rxcrd_shared
  );

  modport monitor (
    input  is_valid,
           early_valid,
           protocol_id,
           vc_id,
           shared_credit,
           header,
           cmd_parity,
           spid,
           dpid,
           txblock_crd_flow,
           block,
           rxcrd_valid,
           rxcrd_protocol_id,
           rxcrd_vc_id,
           rxcrd_shared
  );

endinterface:cpi_rsp

interface cxl_credit_if;

  logic       valid;
  logic [3:0] req;
  logic [3:0] dat;
  logic [3:0] rsp;

  modport master (
    import is_mem, is_cch, enc2dec, dec2enc,
    output valid,
           req, 
           dat, 
           rsp
  );

  modport slave (
    import is_mem, is_cch, enc2dec, dec2enc,
    input  valid,
           req, 
           dat, 
           rsp
  );

  function bit is_cch(bit msb);
    is_cch = !msb;
  endfunction

  function bit is_mem(bit msb);
    is_mem = msb;
  endfunction

  function bit [6:0] enc2dec(bit [2:0] enc);
    enc2dec = !enc[2:0] ? '0 : (1<<(enc[2:0]-1));
  endfunction

  function bit [2:0] dec2enc(bit [6:0] dec);
    case (dec) inside
      7'b1?????? : dec2enc = $clog2(64)+1;
      7'b01????? : dec2enc = $clog2(32)+1;
      7'b001???? : dec2enc = $clog2(16)+1;
      7'b0001??? : dec2enc = $clog2( 8)+1;
      7'b00001?? : dec2enc = $clog2( 4)+1;
      7'b000001? : dec2enc = $clog2( 2)+1;
      7'b0000001 : dec2enc = $clog2( 1)+1;
      7'b0000000 : dec2enc = 0;
    endcase 
  endfunction

endinterface:cxl_credit_if

interface cxl_nfi_if
  import cpm6_v1_0_40791_pkg::*;
();

  localparam MAX_W = 3;

  // Transmit AND Receive directions
  logic [MAX_W-1:0][3:0][127:0] data;   //4 slots of 128 bits each
  logic [MAX_W-1:0][3:0][  1:0] parity; //4 slots of 2 bits each
  logic [MAX_W-1:0]     [  0:0] valid; 
  logic [MAX_W-1:0]     [  0:0] adf;    //68B only
  logic [MAX_W-1:0]     [  0:0] viral;
  // Transmit ONLY direction
  logic                 [  4:0] ready; //single bit replicated for better timing
  logic [MAX_W-1:0]     [  0:0] last;  //68B only
  // Receive ONLY direction; CPM6 drives
  dec_ast_t                     assist[MAX_W-1:0];

  /* These interfaces are unique in the TX and RX direction, but Vivado
     requires a single "master" and "slave" modport per interface. So we
     will just use a subset of the modport and tie off unused values in RTL, 
     depending on direction. */

  modport master(
    // Transmit direction: send to link
    // Noted receive direction difference by comment
    output data,
           parity,
           valid,
           adf,
           viral,
           assist, //receive ONLY
           last,   //receive MISSING
    input  ready   //receive MISSING
  );

  modport slave(
    // Transmit direction: send to link
    // Noted receive direction difference by comment
    input  data,
           parity,
           valid,
           adf,
           viral,
           assist, //receive ONLY
           last,   //receive MISSING
    output ready   //receive MISSING
  );

endinterface:cxl_nfi_if

/* Single file that contains all interfaces */

interface debug_if_cpi();

  localparam NUM_DEBUG = 6*4;
  localparam CNT_W     = $clog2(NUM_DEBUG);

  // Control
  logic cnt_reset;
  logic cnt_enable;
  logic cnt_freerun;
  // 16 bit counters -> max=65535 (19 BCD bits)
  logic [15:0] cpi_req_mem_cnt[4]; logic [18:0] cpi_req_mem_bcd[4];
  logic [15:0] cpi_dat_mem_cnt[4]; logic [18:0] cpi_dat_mem_bcd[4];
  logic [15:0] cpi_rsp_mem_cnt[4]; logic [18:0] cpi_rsp_mem_bcd[4];
  logic [15:0] cpi_req_cch_cnt[4]; logic [18:0] cpi_req_cch_bcd[4];
  logic [15:0] cpi_dat_cch_cnt[4]; logic [18:0] cpi_dat_cch_bcd[4];
  logic [15:0] cpi_rsp_cch_cnt[4]; logic [18:0] cpi_rsp_cch_bcd[4];

  modport master (
    input  cnt_reset, cnt_enable, cnt_freerun,
    output cpi_req_mem_cnt, cpi_req_mem_bcd,
           cpi_dat_mem_cnt, cpi_dat_mem_bcd,
           cpi_rsp_mem_cnt, cpi_rsp_mem_bcd,
           cpi_req_cch_cnt, cpi_req_cch_bcd,
           cpi_dat_cch_cnt, cpi_dat_cch_bcd,
           cpi_rsp_cch_cnt, cpi_rsp_cch_bcd
  );

  modport slave (
    output cnt_reset, cnt_enable, cnt_freerun,
    input  cpi_req_mem_cnt, cpi_req_mem_bcd,
           cpi_dat_mem_cnt, cpi_dat_mem_bcd,
           cpi_rsp_mem_cnt, cpi_rsp_mem_bcd,
           cpi_req_cch_cnt, cpi_req_cch_bcd,
           cpi_dat_cch_cnt, cpi_dat_cch_bcd,
           cpi_rsp_cch_cnt, cpi_rsp_cch_bcd
  );

  modport monitor (
    input  cnt_reset, cnt_enable, cnt_freerun,
           cpi_req_mem_cnt, cpi_req_mem_bcd,
           cpi_dat_mem_cnt, cpi_dat_mem_bcd,
           cpi_rsp_mem_cnt, cpi_rsp_mem_bcd,
           cpi_req_cch_cnt, cpi_req_cch_bcd,
           cpi_dat_cch_cnt, cpi_dat_cch_bcd,
           cpi_rsp_cch_cnt, cpi_rsp_cch_bcd
  );

endinterface

interface debug_if_crd(); //crd="credit controller"

  localparam NUM_DEBUG = 6;
  localparam CNT_W     = $clog2(NUM_DEBUG);

  logic [2:0] state;
  // Credits we have to send, given by link partner
  // 10 bit counters -> max=1023 (13 BCD bits)
  logic [9:0] rmt_mem_req_avail_cnt; logic [12:0] rmt_mem_req_avail_bcd;
  logic [9:0] rmt_mem_dat_avail_cnt; logic [12:0] rmt_mem_dat_avail_bcd;
  logic [9:0] rmt_mem_rsp_avail_cnt; logic [12:0] rmt_mem_rsp_avail_bcd;
  logic [9:0] rmt_cch_req_avail_cnt; logic [12:0] rmt_cch_req_avail_bcd;
  logic [9:0] rmt_cch_dat_avail_cnt; logic [12:0] rmt_cch_dat_avail_bcd;
  logic [9:0] rmt_cch_rsp_avail_cnt; logic [12:0] rmt_cch_rsp_avail_bcd;

  modport master (
    output state,
           rmt_mem_req_avail_cnt, rmt_mem_req_avail_bcd,
           rmt_mem_dat_avail_cnt, rmt_mem_dat_avail_bcd,
           rmt_mem_rsp_avail_cnt, rmt_mem_rsp_avail_bcd,
           rmt_cch_req_avail_cnt, rmt_cch_req_avail_bcd,
           rmt_cch_dat_avail_cnt, rmt_cch_dat_avail_bcd,
           rmt_cch_rsp_avail_cnt, rmt_cch_rsp_avail_bcd
  );

  modport slave (
    input  state,
           rmt_mem_req_avail_cnt, rmt_mem_req_avail_bcd,
           rmt_mem_dat_avail_cnt, rmt_mem_dat_avail_bcd,
           rmt_mem_rsp_avail_cnt, rmt_mem_rsp_avail_bcd,
           rmt_cch_req_avail_cnt, rmt_cch_req_avail_bcd,
           rmt_cch_dat_avail_cnt, rmt_cch_dat_avail_bcd,
           rmt_cch_rsp_avail_cnt, rmt_cch_rsp_avail_bcd
  );

  modport monitor (
    input  state,
           rmt_mem_req_avail_cnt, rmt_mem_req_avail_bcd,
           rmt_mem_dat_avail_cnt, rmt_mem_dat_avail_bcd,
           rmt_mem_rsp_avail_cnt, rmt_mem_rsp_avail_bcd,
           rmt_cch_req_avail_cnt, rmt_cch_req_avail_bcd,
           rmt_cch_dat_avail_cnt, rmt_cch_dat_avail_bcd,
           rmt_cch_rsp_avail_cnt, rmt_cch_rsp_avail_bcd
  );

endinterface

interface debug_if_txp(); //txp="tx path"

  localparam NUM_DEBUG = 7;
  localparam CNT_W     = $clog2(NUM_DEBUG);

  // Control
  logic cnt_reset;
  logic cnt_enable;
  logic cnt_freerun;
  // 16 bit counters -> max=65535 (19 BCD bits)
  logic [15:0] nfi_vld_cnt;   logic [18:0] nfi_vld_bcd;
  logic [15:0] m2s_rwd_cnt;   logic [18:0] m2s_rwd_bcd;
  logic [15:0] m2s_req_cnt;   logic [18:0] m2s_req_bcd;
  logic [15:0] m2s_birsp_cnt; logic [18:0] m2s_birsp_bcd;
  logic [15:0] h2d_req_cnt;   logic [18:0] h2d_req_bcd;
  logic [15:0] h2d_dat_cnt;   logic [18:0] h2d_dat_bcd;
  logic [15:0] h2d_rsp_cnt;   logic [18:0] h2d_rsp_bcd;

  modport master (
    input  cnt_reset, cnt_enable, cnt_freerun,
    output nfi_vld_cnt,   nfi_vld_bcd,
           m2s_req_cnt,   m2s_req_bcd,
           m2s_rwd_cnt,   m2s_rwd_bcd,
           m2s_birsp_cnt, m2s_birsp_bcd,
           h2d_req_cnt,   h2d_req_bcd,
           h2d_dat_cnt,   h2d_dat_bcd,
           h2d_rsp_cnt,   h2d_rsp_bcd
  );

  modport slave (
    output cnt_reset, cnt_enable, cnt_freerun,
    input  nfi_vld_cnt,   nfi_vld_bcd,
           m2s_req_cnt,   m2s_req_bcd,
           m2s_rwd_cnt,   m2s_rwd_bcd,
           m2s_birsp_cnt, m2s_birsp_bcd,
           h2d_req_cnt,   h2d_req_bcd,
           h2d_dat_cnt,   h2d_dat_bcd,
           h2d_rsp_cnt,   h2d_rsp_bcd
  );

  modport monitor (
    input  cnt_reset, cnt_enable, cnt_freerun,
           nfi_vld_cnt,   nfi_vld_bcd,
           m2s_req_cnt,   m2s_req_bcd,
           m2s_rwd_cnt,   m2s_rwd_bcd,
           m2s_birsp_cnt, m2s_birsp_bcd,
           h2d_req_cnt,   h2d_req_bcd,
           h2d_dat_cnt,   h2d_dat_bcd,
           h2d_rsp_cnt,   h2d_rsp_bcd
  );

endinterface

interface debug_if_rxp(); //rxp="rx path"

  localparam NUM_DEBUG = 7;
  localparam CNT_W     = $clog2(NUM_DEBUG);

  // Control
  logic cnt_reset;
  logic cnt_enable;
  logic cnt_freerun;
  // 16 bit counters -> max=65535 (19 BCD bits)
  logic [15:0] nfi_vld_cnt;   logic [18:0] nfi_vld_bcd;
  logic [15:0] s2m_ndr_cnt;   logic [18:0] s2m_ndr_bcd;
  logic [15:0] s2m_drs_cnt;   logic [18:0] s2m_drs_bcd;
  logic [15:0] s2m_bisnp_cnt; logic [18:0] s2m_bisnp_bcd;
  logic [15:0] d2h_req_cnt;   logic [18:0] d2h_req_bcd;
  logic [15:0] d2h_dat_cnt;   logic [18:0] d2h_dat_bcd;
  logic [15:0] d2h_rsp_cnt;   logic [18:0] d2h_rsp_bcd;

  modport master (
    input  cnt_reset, cnt_enable, cnt_freerun,
    output nfi_vld_cnt,   nfi_vld_bcd,
           s2m_ndr_cnt,   s2m_ndr_bcd,
           s2m_drs_cnt,   s2m_drs_bcd,
           s2m_bisnp_cnt, s2m_bisnp_bcd,
           d2h_req_cnt,   d2h_req_bcd,
           d2h_dat_cnt,   d2h_dat_bcd,
           d2h_rsp_cnt,   d2h_rsp_bcd
  );

  modport slave (
    output cnt_reset, cnt_enable, cnt_freerun,
    input  nfi_vld_cnt,   nfi_vld_bcd,
           s2m_ndr_cnt,   s2m_ndr_bcd,
           s2m_drs_cnt,   s2m_drs_bcd,
           s2m_bisnp_cnt, s2m_bisnp_bcd,
           d2h_req_cnt,   d2h_req_bcd,
           d2h_dat_cnt,   d2h_dat_bcd,
           d2h_rsp_cnt,   d2h_rsp_bcd
  );

  modport monitor (
    input  cnt_reset, cnt_enable, cnt_freerun,
           nfi_vld_cnt,   nfi_vld_bcd,
           s2m_ndr_cnt,   s2m_ndr_bcd,
           s2m_drs_cnt,   s2m_drs_bcd,
           s2m_bisnp_cnt, s2m_bisnp_bcd,
           d2h_req_cnt,   d2h_req_bcd,
           d2h_dat_cnt,   d2h_dat_bcd,
           d2h_rsp_cnt,   d2h_rsp_bcd
  );

endinterface

interface debug_if_perfmon(); //pfm="performance monitor (tx)"

  // Status
  logic        armed;
  logic        active;
  logic        done;
  logic        safety_exp;      //set if window was force-ended by the safety backstop
  logic [15:0] elapsed_cycles;
  logic [15:0] elapsed_events;
  // CPI F2A REQ per-channel valid/backpressure counters (16 bit, no BCD)
  logic [15:0] f2a_req_valid_cnt[4]; //is_valid
  logic [15:0] f2a_req_block_cnt[4]; //delayed (block_q) block
  // CPI F2A DAT per-channel valid/backpressure counters (16 bit, no BCD)
  logic [15:0] f2a_dat_valid_cnt[4];
  logic [15:0] f2a_dat_block_cnt[4];
  // Credit-value histogram: 6 pools x 6 power-of-2 buckets (16 bit, no BCD)
  //  bucket0==0 | bucket1==1 | bucket2=[2:3] | bucket3=[4:7] | bucket4=[8:15] | bucket5>=16
  logic [15:0] mem_req_bkt_cnt[6];
  logic [15:0] mem_dat_bkt_cnt[6];
  logic [15:0] mem_rsp_bkt_cnt[6];
  logic [15:0] cch_req_bkt_cnt[6];
  logic [15:0] cch_dat_bkt_cnt[6];
  logic [15:0] cch_rsp_bkt_cnt[6];
  // NFI valid-bit-count + backpressure counters (16 bit, no BCD)
  logic [15:0] nfi_vldbits_1_cnt;
  logic [15:0] nfi_vldbits_2_cnt;
  logic [15:0] nfi_vldbits_3_cnt;
  logic [15:0] nfi_backpressure_cnt;

  modport master (
    output armed, active, done, safety_exp, elapsed_cycles, elapsed_events,
           f2a_req_valid_cnt, f2a_req_block_cnt,
           f2a_dat_valid_cnt, f2a_dat_block_cnt,
           mem_req_bkt_cnt, mem_dat_bkt_cnt, mem_rsp_bkt_cnt,
           cch_req_bkt_cnt, cch_dat_bkt_cnt, cch_rsp_bkt_cnt,
           nfi_vldbits_1_cnt, nfi_vldbits_2_cnt, nfi_vldbits_3_cnt, nfi_backpressure_cnt
  );

  modport slave (
    input  armed, active, done, safety_exp, elapsed_cycles, elapsed_events,
           f2a_req_valid_cnt, f2a_req_block_cnt,
           f2a_dat_valid_cnt, f2a_dat_block_cnt,
           mem_req_bkt_cnt, mem_dat_bkt_cnt, mem_rsp_bkt_cnt,
           cch_req_bkt_cnt, cch_dat_bkt_cnt, cch_rsp_bkt_cnt,
           nfi_vldbits_1_cnt, nfi_vldbits_2_cnt, nfi_vldbits_3_cnt, nfi_backpressure_cnt
  );

  modport monitor (
    input  armed, active, done, safety_exp, elapsed_cycles, elapsed_events,
           f2a_req_valid_cnt, f2a_req_block_cnt,
           f2a_dat_valid_cnt, f2a_dat_block_cnt,
           mem_req_bkt_cnt, mem_dat_bkt_cnt, mem_rsp_bkt_cnt,
           cch_req_bkt_cnt, cch_dat_bkt_cnt, cch_rsp_bkt_cnt,
           nfi_vldbits_1_cnt, nfi_vldbits_2_cnt, nfi_vldbits_3_cnt, nfi_backpressure_cnt
  );

endinterface

interface debug_flit_endec(); //top level

  // CRD
  logic [2:0] crd_state;
  logic [9:0] rmt_mem_req_avail_cnt; logic [12:0] rmt_mem_req_avail_bcd;
  logic [9:0] rmt_mem_dat_avail_cnt; logic [12:0] rmt_mem_dat_avail_bcd;
  logic [9:0] rmt_mem_rsp_avail_cnt; logic [12:0] rmt_mem_rsp_avail_bcd;
  logic [9:0] rmt_cch_req_avail_cnt; logic [12:0] rmt_cch_req_avail_bcd;
  logic [9:0] rmt_cch_dat_avail_cnt; logic [12:0] rmt_cch_dat_avail_bcd;
  logic [9:0] rmt_cch_rsp_avail_cnt; logic [12:0] rmt_cch_rsp_avail_bcd;
  // TX
  logic        tx_cnt_reset;     logic        tx_cnt_enable;   logic        tx_cnt_freerun;
  logic [15:0] tx_nfi_vld_cnt;   logic [18:0] tx_nfi_vld_bcd;
  logic [15:0] tx_m2s_req_cnt;   logic [18:0] tx_m2s_req_bcd;
  logic [15:0] tx_m2s_rwd_cnt;   logic [18:0] tx_m2s_rwd_bcd;
  logic [15:0] tx_m2s_birsp_cnt; logic [18:0] tx_m2s_birsp_bcd;
  logic [15:0] tx_h2d_req_cnt;   logic [18:0] tx_h2d_req_bcd;
  logic [15:0] tx_h2d_dat_cnt;   logic [18:0] tx_h2d_dat_bcd;
  logic [15:0] tx_h2d_rsp_cnt;   logic [18:0] tx_h2d_rsp_bcd;
  // RX
  logic        rx_cnt_reset;     logic        rx_cnt_enable;   logic        rx_cnt_freerun;
  logic [15:0] rx_nfi_vld_cnt;   logic [18:0] rx_nfi_vld_bcd;
  logic [15:0] rx_s2m_ndr_cnt;   logic [18:0] rx_s2m_ndr_bcd;
  logic [15:0] rx_s2m_drs_cnt;   logic [18:0] rx_s2m_drs_bcd;
  logic [15:0] rx_s2m_bisnp_cnt; logic [18:0] rx_s2m_bisnp_bcd;
  logic [15:0] rx_d2h_req_cnt;   logic [18:0] rx_d2h_req_bcd;
  logic [15:0] rx_d2h_dat_cnt;   logic [18:0] rx_d2h_dat_bcd;
  logic [15:0] rx_d2h_rsp_cnt;   logic [18:0] rx_d2h_rsp_bcd;
  // CPI F2A
  logic        cpif2a_cnt_reset;      logic        cpif2a_cnt_enable;    logic        cpif2a_cnt_freerun;
  logic [15:0] cpif2a_req_mem_cnt[4]; logic [18:0] cpif2a_req_mem_bcd[4];
  logic [15:0] cpif2a_req_cch_cnt[4]; logic [18:0] cpif2a_req_cch_bcd[4];
  logic [15:0] cpif2a_dat_mem_cnt[4]; logic [18:0] cpif2a_dat_mem_bcd[4];
  logic [15:0] cpif2a_dat_cch_cnt[4]; logic [18:0] cpif2a_dat_cch_bcd[4];
  logic [15:0] cpif2a_rsp_mem_cnt[4]; logic [18:0] cpif2a_rsp_mem_bcd[4];
  logic [15:0] cpif2a_rsp_cch_cnt[4]; logic [18:0] cpif2a_rsp_cch_bcd[4];
  // CPI A2F
  logic cpia2f_cnt_reset;             logic cpia2f_cnt_enable;             logic cpia2f_cnt_freerun;
  logic [15:0] cpia2f_req_mem_cnt[4]; logic [18:0] cpia2f_req_mem_bcd[4];
  logic [15:0] cpia2f_req_cch_cnt[4]; logic [18:0] cpia2f_req_cch_bcd[4];
  logic [15:0] cpia2f_dat_mem_cnt[4]; logic [18:0] cpia2f_dat_mem_bcd[4];
  logic [15:0] cpia2f_dat_cch_cnt[4]; logic [18:0] cpia2f_dat_cch_bcd[4];
  logic [15:0] cpia2f_rsp_mem_cnt[4]; logic [18:0] cpia2f_rsp_mem_bcd[4];
  logic [15:0] cpia2f_rsp_cch_cnt[4]; logic [18:0] cpia2f_rsp_cch_bcd[4];

  modport master (
    // CRD
    output crd_state,
           rmt_mem_req_avail_cnt, rmt_mem_req_avail_bcd,
           rmt_mem_dat_avail_cnt, rmt_mem_dat_avail_bcd,
           rmt_mem_rsp_avail_cnt, rmt_mem_rsp_avail_bcd,
           rmt_cch_req_avail_cnt, rmt_cch_req_avail_bcd,
           rmt_cch_dat_avail_cnt, rmt_cch_dat_avail_bcd,
           rmt_cch_rsp_avail_cnt, rmt_cch_rsp_avail_bcd,
    // TX
    input  tx_cnt_reset,   tx_cnt_enable,   tx_cnt_freerun,
    output tx_nfi_vld_cnt,   tx_nfi_vld_bcd,
           tx_m2s_req_cnt,   tx_m2s_req_bcd,
           tx_m2s_rwd_cnt,   tx_m2s_rwd_bcd,
           tx_m2s_birsp_cnt, tx_m2s_birsp_bcd,
           tx_h2d_req_cnt,   tx_h2d_req_bcd,
           tx_h2d_dat_cnt,   tx_h2d_dat_bcd,
           tx_h2d_rsp_cnt,   tx_h2d_rsp_bcd,
    // RX
    input  rx_cnt_reset,   rx_cnt_enable,   rx_cnt_freerun,
    output rx_nfi_vld_cnt,   rx_nfi_vld_bcd,
           rx_s2m_ndr_cnt,   rx_s2m_ndr_bcd,
           rx_s2m_drs_cnt,   rx_s2m_drs_bcd,
           rx_s2m_bisnp_cnt, rx_s2m_bisnp_bcd,
           rx_d2h_req_cnt,   rx_d2h_req_bcd,
           rx_d2h_dat_cnt,   rx_d2h_dat_bcd,
           rx_d2h_rsp_cnt,   rx_d2h_rsp_bcd,
    // CPI F2A
    input  cpif2a_cnt_reset,   cpif2a_cnt_enable,   cpif2a_cnt_freerun,
    output cpif2a_req_mem_cnt, cpif2a_req_mem_bcd,
           cpif2a_dat_mem_cnt, cpif2a_dat_mem_bcd,
           cpif2a_rsp_mem_cnt, cpif2a_rsp_mem_bcd,
           cpif2a_req_cch_cnt, cpif2a_req_cch_bcd,
           cpif2a_dat_cch_cnt, cpif2a_dat_cch_bcd,
           cpif2a_rsp_cch_cnt, cpif2a_rsp_cch_bcd,
    // CPI A2F
    input  cpia2f_cnt_reset,   cpia2f_cnt_enable,   cpia2f_cnt_freerun,
    output cpia2f_req_mem_cnt, cpia2f_req_mem_bcd,
           cpia2f_dat_mem_cnt, cpia2f_dat_mem_bcd,
           cpia2f_rsp_mem_cnt, cpia2f_rsp_mem_bcd,
           cpia2f_req_cch_cnt, cpia2f_req_cch_bcd,
           cpia2f_dat_cch_cnt, cpia2f_dat_cch_bcd,
           cpia2f_rsp_cch_cnt, cpia2f_rsp_cch_bcd

  );

  modport monitor (
    // CRD
    input crd_state,
          rmt_mem_req_avail_cnt, rmt_mem_req_avail_bcd,
          rmt_mem_dat_avail_cnt, rmt_mem_dat_avail_bcd,
          rmt_mem_rsp_avail_cnt, rmt_mem_rsp_avail_bcd,
          rmt_cch_req_avail_cnt, rmt_cch_req_avail_bcd,
          rmt_cch_dat_avail_cnt, rmt_cch_dat_avail_bcd,
          rmt_cch_rsp_avail_cnt, rmt_cch_rsp_avail_bcd,
    // TX
          tx_cnt_reset,     tx_cnt_enable,     tx_cnt_freerun,
          tx_nfi_vld_cnt,   tx_nfi_vld_bcd,
          tx_m2s_req_cnt,   tx_m2s_req_bcd,
          tx_m2s_rwd_cnt,   tx_m2s_rwd_bcd,
          tx_m2s_birsp_cnt, tx_m2s_birsp_bcd,
          tx_h2d_req_cnt,   tx_h2d_req_bcd,
          tx_h2d_dat_cnt,   tx_h2d_dat_bcd,
          tx_h2d_rsp_cnt,   tx_h2d_rsp_bcd,
    // RX
          rx_cnt_reset,     rx_cnt_enable,     rx_cnt_freerun,
          rx_nfi_vld_cnt,   rx_nfi_vld_bcd,
          rx_s2m_ndr_cnt,   rx_s2m_ndr_bcd,
          rx_s2m_drs_cnt,   rx_s2m_drs_bcd,
          rx_s2m_bisnp_cnt, rx_s2m_bisnp_bcd,
          rx_d2h_req_cnt,   rx_d2h_req_bcd,
          rx_d2h_dat_cnt,   rx_d2h_dat_bcd,
          rx_d2h_rsp_cnt,   rx_d2h_rsp_bcd,
    // CPI F2A
          cpif2a_cnt_reset,   cpif2a_cnt_enable,   cpif2a_cnt_freerun,
          cpif2a_req_mem_cnt, cpif2a_req_mem_bcd,
          cpif2a_req_cch_cnt, cpif2a_req_cch_bcd,
          cpif2a_dat_mem_cnt, cpif2a_dat_mem_bcd,
          cpif2a_dat_cch_cnt, cpif2a_dat_cch_bcd,
          cpif2a_rsp_mem_cnt, cpif2a_rsp_mem_bcd,
          cpif2a_rsp_cch_cnt, cpif2a_rsp_cch_bcd,
    // CPI A2F
          cpia2f_cnt_reset,   cpia2f_cnt_enable,   cpia2f_cnt_freerun,
          cpia2f_req_mem_cnt, cpia2f_req_mem_bcd,
          cpia2f_dat_mem_cnt, cpia2f_dat_mem_bcd,
          cpia2f_rsp_mem_cnt, cpia2f_rsp_mem_bcd,
          cpia2f_req_cch_cnt, cpia2f_req_cch_bcd,
          cpia2f_dat_cch_cnt, cpia2f_dat_cch_bcd,
          cpia2f_rsp_cch_cnt, cpia2f_rsp_cch_bcd
  );

endinterface

interface debug_gpio_if_ep;

  localparam NUM_DEBUG = 10;
  localparam CNT_W     = $clog2(NUM_DEBUG);
  
  // Count = 10
  // 16 bit counters -> max=65535 (19 BCD bits)
  logic [15:0] axi_wr_start_cnt;
  logic [15:0] axi_wr_compl_cnt;
  logic [15:0] axi_rd_start_cnt;
  logic [15:0] axi_rd_compl_cnt;
  logic [15:0] a2f_req_cnt;     
  logic [15:0] a2f_dat_cnt;     
  logic [15:0] f2a_rsp_cnt;     
  logic [15:0] f2a_dat_cnt;     
  logic [15:0] nfi_rx_cnt;
  logic [15:0] nfi_tx_cnt;
  logic [127:0] debug_crd_bus;

  modport master (
    output debug_crd_bus,
           axi_wr_start_cnt,
           axi_wr_compl_cnt,
           axi_rd_start_cnt,
           axi_rd_compl_cnt,
           a2f_req_cnt,     
           a2f_dat_cnt,     
           f2a_rsp_cnt,     
           f2a_dat_cnt,
           nfi_rx_cnt,
           nfi_tx_cnt
  );

  modport slave (
    input debug_crd_bus,
          axi_wr_start_cnt,
          axi_wr_compl_cnt,
          axi_rd_start_cnt,
          axi_rd_compl_cnt,
          a2f_req_cnt,     
          a2f_dat_cnt,     
          f2a_rsp_cnt,     
          f2a_dat_cnt,
          nfi_rx_cnt,
          nfi_tx_cnt
  );

endinterface:debug_gpio_if_ep
`endif

