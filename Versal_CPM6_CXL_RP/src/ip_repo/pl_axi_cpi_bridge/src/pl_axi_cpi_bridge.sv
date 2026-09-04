// MODULE : pl_axi_cpi_bridge
//
// DESCRIPTION:
// This module is intended to be used in a CXL Root Port design when there is
// a PL master that doesn't use the NOC to reach an attached CXL memory
// expander (Type 3 device). This module specifically functions to reorder 
// transaction responses from the remote device to meet the AXI spec that 
// writes and reads to the same AXI ID are returned in order. It reformats
// the input AXI transaction requests and outputs them as CPI transaction 
// requests, performing the conversion in reverse to responses from the remote
// device. A PL master may take advantage of the AXI USER bits to use them for
// for addl. control over request transactions and gather status data from 
// response transactions.
//
// DETAILS:
//  - The CXL 16-bit tag will be unique for every transaction. To enable easy visual
//    debug on an analyzer or ILA, fields are nibble aligned. Each tag will be built 
//    as follows:
//    {1b:RD/WRb, 1b:RSVD, 2b:BRDG_ID, 4b:AXI_ID, 8b:issue_ptr}
//  - WUSER has fields that are fixed and present as below
//    {METADATA (2,1-32), POISON (1)}
//  - BUSER has fields that are fixed and present as below
//    {DEVLOAD (2)}
//  - ARUSER has fields that are fixed and present as below
//    {METADATA (2), METADATA_FLAG (1), CMD (2)}
//    - METADATA_FLAG only present if metadata is enabled. For 2-bit metadata, it is
//      used to update metadata in device during a read to METADATA. For extended 
//      metadata, it is used to request that device returns extended metadata 
//      with data.
//    - CMD is used to specify memopcode field as follows. If ARUSER_*_SUPP are not 
//      set, then that encoding is not used and each transaction defaults to MemRd.
//      - 2'b00 : MemRd | 2'b01 : MemSpecRd | 2'b10 : MemInv | 2'b11 : MemInvNT
//  - RUSER has fields that are fixed and present as below
//    {METADATA (2,1-32), METAFIELD (2), DEVLOAD (2)}
//
// RESTRICTIONS:
//  - AXI data bus must always be 512 bits
//  - AXI narrow transfers not supported
//  - AXI unaligned transfers not supported
//  - AXI max beats per burst is 1
//  - AXI burst types FIXED and WRAP not supported, only INCR
//  - AXI_IDS_SUPP must be less than or equal to 16; it is assumed AXI_ID ranges 
//    from {0:AXI_IDS_SUPP-1}
//
// ACRONYMS:
//  - RSTRCT = restriction
//  - NU     = not used
//  - SUPP   = supported
//  - BS     = bit-start; LSb of field in a concatenated bus
//  - TTA    = TTCL away
//  - RP     = remove port
//
// TODO:
//  - 1 : Add more debug statistic capabilities
//    - a : add logic internally for the DEBUG
//      - transaction count (per id)
//      - transaction count (total)
//      - current outstanding (per id)
//      - current outstanding (total)
//      - max outstanding (per id)
//      - max outstanding (total)
//      - devload (from device)
//  - 2 : Add error tracking and logging for CXL_RAS.UncorrectablErrorStatus.ExtendedMetataError

module pl_axi_cpi_bridge 
  import cxl_tl_enum_pkg::*;
  import cpi_pkg::cpi_flitmode_t;
#(
  // General Parameters 
  parameter bit [1:0] BRDG_ID,
  // Debug Related
  parameter bit [1:0] DEBUG_IF_EN  = 0, //[0]=GPIO enable; [1]=AXI-L enable
  parameter bit       DEBUG_EN_BCD = 1,
  // AXI Interface Parameters
  parameter AXI_ADDR_WIDTH = 48,
  parameter AXI_IDS_SUPP   = 8, //max=16
  // Feature Enablement -> controls AXI User Bits
  parameter bit   USER_POISN_SUPP     = 0, //[0, 1]
  parameter       USER_METAD_SUPP     = 0, //[0, 1-32=Nbit EMD, -1=2bit Metadata]
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
  // CAN'T TOUCH 
  // --- // 
  // Internal Hint : -1=no metadata, 0=2bit metadata, 1=ext. metatdata
  localparam METAD_SEL = !USER_METAD_SUPP ? -1 : 
                         (USER_METAD_SUPP == -1 ? 0 : 1), 
  // --- // 
  localparam AXI_ID_WIDTH = AXI_IDS_SUPP==1 ? 1 : $clog2(AXI_IDS_SUPP),
  localparam AXI_MAX_BEATS  = 1,   
  localparam AXI_DATA_WIDTH = 512, 
  localparam SHDW = AXI_DATA_WIDTH, //SHDW="short hand data width"
  localparam AXI_STRB_WIDTH = AXI_DATA_WIDTH/8,
  localparam bit [1:3] MEMOC_SUPP = {ARUSER_MEMSPECRD_SUPP, ARUSER_MEMINV_SUPP, ARUSER_MEMINVNT_SUPP},
  localparam ARCMD_W = !MEMOC_SUPP ? 0 : 2,
  localparam METAD_W = !USER_METAD_SUPP ? 0 : (USER_METAD_SUPP == -1 ? 2 : USER_METAD_SUPP),
  localparam MDFLG_W = !USER_METAD_SUPP ? 0 : 1,
  localparam DEVLD_W = !USER_DEVLD_SUPP ? 0 : 2, 
  localparam POISN_W = !USER_POISN_SUPP ? 0 : 1,
  localparam ARUSER_MIN_WIDTH = ARCMD_W+MDFLG_W+METAD_W,
  localparam ARUSER_MAX_WIDTH = 2+1+32,
  localparam RUSER_MIN_WIDTH  = DEVLD_W+METAD_W,
  localparam RUSER_MAX_WIDTH  = 2+32,
  localparam WUSER_MIN_WIDTH  = POISN_W+METAD_W,
  localparam WUSER_MAX_WIDTH  = 1+32,
  localparam BUSER_MIN_WIDTH  = DEVLD_W,
  localparam BUSER_MAX_WIDTH  = 2,
  // Future provision
  localparam bit ADDR5_SUPP   = 1'b0
)(
  /*** AMBA AXI H.c Revision Interface - Slave Port ***/
  input                          s_axi_aclk,
  input                          s_axi_aresetn,
  //-- Write Address Channel
  input [AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
  input [  AXI_ID_WIDTH-1:0]     s_axi_awid,
  input [               2:0]     s_axi_awprot,  //NU/RP
  input [               1:0]     s_axi_awburst, //RSTRCT/NU: only INCR support
  input [               2:0]     s_axi_awsize,  //RSTRCT/NU: only 64B supported (no narrow transfers)
  input [               3:0]     s_axi_awcache, //NU/RP
  input [               7:0]     s_axi_awlen,   //NU: only INCR1 support and aligned transfers
  input                          s_axi_awlock,  //NU/RP
  input                          s_axi_awvalid,
  output                         s_axi_awready,
  //-- Write Data Channel
  input [WUSER_MAX_WIDTH-1:0]    s_axi_wuser,  //TTA if WUSER_MIN_WIDTH=0
  input [ AXI_DATA_WIDTH-1:0]    s_axi_wdata,
  input [ AXI_STRB_WIDTH-1:0]    s_axi_wstrb,
  input                          s_axi_wlast,  //NU/RP
  input                          s_axi_wvalid,
  output                         s_axi_wready,
  //-- Write Response Channel
  output [BUSER_MAX_WIDTH-1:0]   s_axi_buser,  //TTA if BUSER_MIN_WIDTH=4
  output                         s_axi_bvalid,
  input                          s_axi_bready,
  output [ AXI_ID_WIDTH-1:0]     s_axi_bid,
  output [              1:0]     s_axi_bresp,
  //-- Read Address Channel
  input [ARUSER_MAX_WIDTH-1:0]   s_axi_aruser,  //TTA if ARUSER_MIN_WIDTH=0
  input [  AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
  input [    AXI_ID_WIDTH-1:0]   s_axi_arid,
  input [                 2:0]   s_axi_arprot,  //NU/RP
  input [                 1:0]   s_axi_arburst, //RSTRCT/NU: only INCR support
  input [                 2:0]   s_axi_arsize,  //RSTRCT/NU: only 64B supported (no narrow transfers)
  input [                 3:0]   s_axi_arcache, //NU/RP
  input [                 7:0]   s_axi_arlen,   //NU: only INCR1 support and aligned transfers
  input                          s_axi_arlock,  //NU/RP
  input                          s_axi_arvalid,
  output                         s_axi_arready, 
  //-- Read Data Channel
  output [RUSER_MAX_WIDTH-1:0]   s_axi_ruser,  //TTA if RUSER_MIN_WIDTH=0
  output [   AXI_ID_WIDTH-1:0]   s_axi_rid,
  output [ AXI_DATA_WIDTH-1:0]   s_axi_rdata,
  output logic [          1:0]   s_axi_rresp,
  output                         s_axi_rvalid,
  output                         s_axi_rlast,  
  input                          s_axi_rready,
  /*** Intel CPI v1.0 Interface - REQ Channel (Fabric2Agent: DSP CXL.mem) ***/
  cpi_req.master                 f2a_req,
  /*** Intel CPI v1.0 Interface - DAT Channel (Fabric2Agent: DSP CXL.mem) ***/
  cpi_data.master                f2a_dat,
  output logic [31:0]            f2a_dat_emd, //TTA if USER_METAD_SUPP<=0
  /*** Intel CPI v1.0 Interface - RSP Channel (Agent2Fabric: DSP CXL.mem) ***/
  cpi_rsp.slave                  a2f_rsp,    
  /*** Intel CPI v1.0 Interface - DAT Channel (Agent2Fabric: DSP CXL.mem) ***/
  cpi_data.slave                 a2f_dat,    
  input [31:0]                   a2f_dat_emd, //TTA if USER_METAD_SUPP<=0
  //*** Debug Signals ***/
  //-- GPIO
  debug_axi_cpi_bridge.master    dbg_gpio_if,
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

  /*** Generating Widths from Parameters ***/
  // ROB width will be fixed as the sum of the max of each field, but the presence of 
  // fields will be optimized away at synth due to certain fields having no load.

  // RAMs : 1:{devload (0,2), completed (1)} | Txn+Completed RAM
  //        0:{issued (1)}                   | Issued RAM
  localparam WROB_TXN_WIDTH = 2;
  // Start bit location in control bus
  localparam WROB_ISSU = 0;
  localparam WROB_COMP = 1;
  // Start bit location in txn bus
  localparam WROB_DEVL = 0;

  // 6-field RAM in addition to completed and issued (with MemSpecRd) RAMs
  // RAMs : 3  :Completed Lookup RAM 
  //        2  :Issued Start RAM 
  //        1  :Txn+Completed RAM ...(cont)...
  //        1hi:{metadata (0,2) or emd (0,1-32), metafield (2), poison (0,1),...
  //             devload (0,2), rspnxm (1), data (512)}
  //        1lo:{completed (1)}
  //        0  :{memspecrd mark (1), issued (1)} | Issued RAM
  localparam RROB_TXN_WIDTH = (32+2+1+2+1+AXI_DATA_WIDTH);
  // Start bit location in control bus
  localparam RROB_ISSU = 0;
  localparam RROB_COMP = 1;
  // Start bit location in txn bus
  localparam RROB_DATA = 0;
  localparam RROB_RNXM = 512;
  localparam RROB_DEVL = 513;
  localparam RROB_POIS = 515;
  localparam RROB_MTAF = 516; 
  localparam RROB_MTAD = 518;

  /*** Internal Constants ***/
  //-- AXI *RESP
  localparam OKAY   = 2'b00,
             EXOKAY = 2'b01,
             SLVERR = 2'b10,
             DECERR = 2'b11;

  // Splicing of USER bits from input bus
  localparam ARUSER_CMND_BS = 0;
  localparam ARUSER_MFLG_BS = 2;
  localparam ARUSER_META_BS = 3;
  localparam WUSER_POIS_BS  = 0;
  localparam WUSER_META_BS  = 1;
  // Cannot zero-slice an index
  localparam METAD_W_MIN = !METAD_W ? 1 : METAD_W;

  logic                          f2a_req_block_err;
  logic                          f2a_dat_block_err;
  logic                          a2f_rsp_block_err;
  logic                          a2f_dat_block_err;
  logic                          a2f_dat_id_err;
  logic                          a2f_rsp_id_err;

  debug_axi_cpi_bridge           i_dbg_gpio_if(); //"i_"=internal
  logic                          final_cnt_reset;
  logic                          final_cnt_enable;
  logic                          final_cnt_freerun;
  logic                          axil_cnt_reset;
  logic                          axil_cnt_enable;
  logic                          axil_cnt_freerun;

  logic                          f2a_req_block_q;
  logic                          f2a_dat_block_q;
  logic                          a2f_rsp_block_q;
  logic                          a2f_dat_block_q;

  logic [22:0]                   addr_even;
  logic [22:0]                   addr_odd;

  logic                          awdone, wdone, bdone;
  logic                          ardone, rdone;
  logic                          w_ph_now;     //marks non-overlapping AW/W phase
  logic [    AXI_ADDR_WIDTH-1:0] awaddr_latch; //for non-overlapping AW/W phase
  logic [      AXI_ID_WIDTH-1:0] awid_latch;   //for non-overlapping AW/W phase

  // | =============== | 
  // | compl  | issue  |
  // | column | column |
  // | =============== | ROB's logic to pop is determined by a match between both
  // |    N-1 |    N-1 | columns and !empty. All of the signals below are in 
  // |    ... |    ... | support of reading and writing these columns. Both columns
  // |      1 |      1 | are initialized to 0. There are secondary columns used for
  // |      0 |      0 | lookups, which are required only due to MemSpecRds, which
  // | =============== | never get device responses.

  logic                          wr_push;
  logic                          wr_pop;
  logic [      AXI_IDS_SUPP-1:0] wr_pop_req;
  logic [      AXI_IDS_SUPP-1:0] wr_pop_req_rbs; //rbs = "right barrel shift"
  logic [      AXI_ID_WIDTH-1:0] wr_pop_req_rbs_sel;
  logic                          wr_pop_vld;
  logic [      AXI_ID_WIDTH-1:0] wr_pop_sel;
  logic [$clog2(WROB_DEPTH)-1:0] wr_issue_wptr[AXI_IDS_SUPP]; //needs extra bit for wrap; next line
  logic                          wr_issue_wrap[AXI_IDS_SUPP];
  logic [$clog2(WROB_DEPTH)-1:0] wr_compl_rptr[AXI_IDS_SUPP]; //needs extra bit for wrap; next line
  logic                          wr_compl_wrap[AXI_IDS_SUPP];
  logic [$clog2(WROB_DEPTH)-1:0] wr_compl_wptr;
  logic                          wrob_full [AXI_IDS_SUPP];
  logic                          wrob_mpty [AXI_IDS_SUPP];
  logic                          wrob_ampty[AXI_IDS_SUPP]; //ampty = "almost empty"
  // bit 1: compl and txn ram | bit 0: issue ram 
  logic                          wrob_wen [AXI_IDS_SUPP][1:0];
  logic                          wrob_wdat[AXI_IDS_SUPP][1:0];
  logic [$clog2(WROB_DEPTH)-1:0] wrob_wadr[AXI_IDS_SUPP][1:0];
  logic                          wrob_rdat[AXI_IDS_SUPP][1:0];
  logic [$clog2(WROB_DEPTH)-1:0] wrob_radr[AXI_IDS_SUPP][1:0];
  logic [    WROB_TXN_WIDTH-1:0] wrob_wdat_txn;
  logic [    WROB_TXN_WIDTH-1:0] wrob_rdat_txn[AXI_IDS_SUPP];

  logic                          rd_push;
  logic                          rd_pop;
  logic [      AXI_IDS_SUPP-1:0] rd_pop_req;
  logic [      AXI_IDS_SUPP-1:0] rd_pop_req_rbs; //rbs = "right barrel shift"
  logic [      AXI_ID_WIDTH-1:0] rd_pop_req_rbs_sel;
  logic                          rd_pop_vld;
  logic [      AXI_ID_WIDTH-1:0] rd_pop_sel;
  logic [$clog2(RROB_DEPTH)-1:0] rd_issue_wptr[AXI_IDS_SUPP]; //needs extra bit for wrap; next line
  logic                          rd_issue_wrap[AXI_IDS_SUPP];
  logic [$clog2(RROB_DEPTH)-1:0] rd_compl_rptr[AXI_IDS_SUPP]; //needs extra bit for wrap; next line
  logic                          rd_compl_wrap[AXI_IDS_SUPP];
  logic [$clog2(RROB_DEPTH)-1:0] rd_compl_wptr[AXI_IDS_SUPP];
  logic                          rrob_full [AXI_IDS_SUPP];
  logic                          rrob_mpty [AXI_IDS_SUPP];
  logic                          rrob_ampty[AXI_IDS_SUPP];
  // bit 1: compl and txn ram | bit 0: issue ram 
  logic                          rrob_wen [AXI_IDS_SUPP][1:0];
  logic                          rrob_wdat[AXI_IDS_SUPP][1:0];
  logic [$clog2(RROB_DEPTH)-1:0] rrob_wadr[AXI_IDS_SUPP][1:0];
  logic                          rrob_rdat[AXI_IDS_SUPP][1:0];
  logic [$clog2(RROB_DEPTH)-1:0] rrob_radr[AXI_IDS_SUPP][1:0];
  logic [    RROB_TXN_WIDTH-1:0] rrob_wdat_txn[AXI_IDS_SUPP]; 
  logic [    RROB_TXN_WIDTH-1:0] rrob_rdat_txn[AXI_IDS_SUPP];
  logic                          rrob_rdat_msr[AXI_IDS_SUPP]; //flag: msr="memspecrd"
  logic                          rrob_rdat_issue_strt[AXI_IDS_SUPP];
  logic                          rrob_rdat_compl_lkup[AXI_IDS_SUPP];

  // Start bit in txn bus (MWRT = "multi-write txn")
  localparam MWRT_DEVL = 0;
  localparam MWRT_MTAF = 2;
  localparam MWRT_MTAD = 4;
  // A "multi-write" occurs when an M2SReq=MemInv[NT] and an M2SReq=<other>
  // get responses in the same cycle for the same RROB, which would require
  // writing two ports of the RROB when there is only one. The solution is
  // to block the CPI A2F DAT port, store the response to the MemInv[NT] to
  // a flop while writing the other response to the RROB, then writing the 
  // MemInv[NT] response in the subsequent cycle.
  logic                          special;
  logic                          multi_w;
  logic                          multi_c; //_c = "continued"
  logic [$clog2(RROB_DEPTH)-1:0] multi_w_ptr;
  logic [      AXI_ID_WIDTH-1:0] multi_w_id;
  logic [                   5:0] multi_w_txn; //MF+MV+DV=2+2+2=6b
  logic                          multi_w_vld;

  assign awdone = s_axi_awvalid && s_axi_awready;
  assign  wdone = s_axi_wvalid  && s_axi_wready;
  assign  bdone = s_axi_bvalid  && s_axi_bready;
  assign ardone = s_axi_arvalid && s_axi_arready;
  assign  rdone = s_axi_rvalid  && s_axi_rready;

  /*** Handle A*ID generation from port to internal ***/
  logic [AXI_ID_WIDTH-1:0] i_axi_awid;
//logic [AXI_ID_WIDTH-1:0] i_axi_wid; //not intending to buffer up multiple AW*s before W*

  // Handle assignment from internal to external user bits
  logic [ 1:0] i_axi_buser_devl;
  logic [ 1:0] i_axi_ruser_devl;
  logic [ 1:0] i_axi_ruser_metafield;
  logic [31:0] i_axi_ruser_metavalue;

  assign i_axi_awid = w_ph_now ? awid_latch : s_axi_awid;

  /*** Write Datapath (Write Data [push] and Write Responses [pop]) ***/
  always_ff @(posedge s_axi_aclk) begin
    if (awdone) begin
      awid_latch   <= s_axi_awid;
      awaddr_latch <= s_axi_awaddr;
    end
  end

  always_comb begin
    for (int ii=0; ii<AXI_IDS_SUPP; ii++) begin
      wrob_mpty [ii] = ({wr_issue_wrap[ii], wr_issue_wptr[ii]} == {wr_compl_wrap[ii], wr_compl_rptr[ii]});
      wrob_ampty[ii] = ({wr_issue_wrap[ii], wr_issue_wptr[ii]} == ({wr_compl_wrap[ii], wr_compl_rptr[ii]}+1'b1));
      wrob_full [ii] = (wr_issue_wptr[ii]==wr_compl_rptr[ii]) && (wr_issue_wrap[ii]^wr_compl_wrap[ii]);
    end
  end

  // Backpressure new transactions in 2 cases:
  //   1. ROB is full for that ID (ID-specific backpressure)
  //   2. CPI is backpressuring with !rdy (global backpressure)
  assign s_axi_awready = !w_ph_now;
  assign s_axi_wready  = !(wrob_full[i_axi_awid] || f2a_dat_block_q);

  // Barrel shift right to create a priority search for arbiter 
  // search = {to_search, current_pos}
  always_comb begin
    wr_pop_req_rbs = {wr_pop_req, wr_pop_req} >> wr_pop_sel;
    // Pointer to next req (barrel shifted, so nxt_ptr = cur_ptr+sel
    // Stay at current position if no other reqs
    wr_pop_req_rbs_sel = '0;
    for (int ii=1; ii<AXI_IDS_SUPP; ii++) begin
      if (wr_pop_req_rbs[ii]) begin
        wr_pop_req_rbs_sel = ii;
        break;
      end
    end
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin 
      wr_pop_sel <= '0;
      w_ph_now   <= 'b0;
      for (int ii=0; ii<AXI_IDS_SUPP; ii++) begin
        {wr_issue_wrap[ii], wr_issue_wptr[ii]} <= '0;
        {wr_compl_wrap[ii], wr_compl_rptr[ii]} <= '0;
      end
    end
    else begin
      // Round-robin arbitrate the WR responses
      if (bdone || !wr_pop_req[wr_pop_sel]) begin
        wr_pop_sel <= (wr_pop_sel+wr_pop_req_rbs_sel)%AXI_IDS_SUPP;
      end
      // Identify non-overlapping AW/W phase
      if (awdone && !wdone)
        w_ph_now <= 'b1;
      else if (wdone)
        w_ph_now <= 'b0;
      // Push
      if (wr_push)
        {wr_issue_wrap[i_axi_awid], wr_issue_wptr[i_axi_awid]} <= {wr_issue_wrap[i_axi_awid], wr_issue_wptr[i_axi_awid]} + 1'b1;
      // Pop
      if (wr_pop)
        {wr_compl_wrap[s_axi_bid], wr_compl_rptr[s_axi_bid]} <= {wr_compl_wrap[s_axi_bid], wr_compl_rptr[s_axi_bid]} + 1'b1;
    end
  end

  assign wr_push    = (awdone || w_ph_now) && wdone;
  assign wr_pop     = bdone;
  assign wr_pop_vld = wr_pop_req[wr_pop_sel];

  assign s_axi_bid    = wr_pop_sel;
  assign s_axi_bvalid = wr_pop_vld;
  assign s_axi_bresp  = OKAY;

  // Must handle MemInv[NT] request coming in as AXI RD, but response is on CPI RSP channel
  // instead of CPI DATA channel, so we must detect when to pop RROB from CPI RSP. The 
  // MemInv[NT] opcode is unique because it's the only HDM-H Request that elicits an S2MNDR
  // device response.
  always_comb begin
    special     = '0;
    multi_w     = '0;
    multi_c     = '0;
    if (!METAD_SEL && MEMOC_SUPP[2:3]) begin
      special = a2f_rsp.header.dsp.a2fm.tag[15];
      multi_w = &{a2f_dat.is_valid, a2f_rsp.is_valid, special} && 
                 a2f_dat.header.dsp.a2fm.tag[8+:AXI_ID_WIDTH]==a2f_rsp.header.dsp.a2fm.tag[8+:AXI_ID_WIDTH];
      multi_c = &{multi_w_vld, a2f_rsp.is_valid, special} && 
                 multi_w_id==a2f_rsp.header.dsp.a2fm.tag[8+:AXI_ID_WIDTH];
    end
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      multi_w_vld <= 1'b0;
    else if (!METAD_SEL && MEMOC_SUPP[2:3]) begin
      multi_w_vld <= multi_c || multi_w; 
      multi_w_id  <= a2f_rsp.header.dsp.a2fm.tag[8+:AXI_ID_WIDTH];
      multi_w_txn <= {a2f_rsp.header.dsp.a2fm.metafield, 
                      a2f_rsp.header.dsp.a2fm.metavalue,
                      a2f_rsp.header.dsp.a2fm.devload};
      multi_w_ptr <= a2f_rsp.header.dsp.a2fm.tag[0+:$clog2(RROB_DEPTH)];
    end
  end

  // Get BUSER (potentially) from the WROB
  assign i_axi_buser_devl = !DEVLD_W ? '0 : wrob_rdat_txn[wr_pop_sel][WROB_DEVL+:2];
  assign s_axi_buser = i_axi_buser_devl;

  assign wr_compl_wptr               = a2f_rsp.header.dsp.a2fm.tag[0+:$clog2(WROB_DEPTH)];
  assign wrob_wdat_txn[WROB_DEVL+:2] = a2f_rsp.header.dsp.a2fm.devload;
  //-- RAMs (LUTRAMs)
  for (genvar gw=0; gw<AXI_IDS_SUPP; gw++) begin : wr_ram
    /* Issued */
    assign wrob_wen [gw][WROB_ISSU] = wr_push && i_axi_awid==gw;
    assign wrob_wdat[gw][WROB_ISSU] = !wr_issue_wrap[gw];
    assign wrob_wadr[gw][WROB_ISSU] = wr_issue_wptr[gw];
    assign wrob_radr[gw][WROB_ISSU] = wr_compl_rptr[gw];
    /* Completed */
    //!! Special: MemInv[NT] issuance supported and response on RSP channel must go to RROB; note last condition
    assign wrob_wen [gw][WROB_COMP] = &{a2f_rsp.is_valid, a2f_rsp.header.dsp.a2fm.tag[8+:AXI_ID_WIDTH]==gw, !special};
    assign wrob_wdat[gw][WROB_COMP] = (wr_compl_wptr < wr_compl_rptr[gw]) ?  wr_compl_wrap[gw] :
                                                                            !wr_compl_wrap[gw];
    assign wrob_wadr[gw][WROB_COMP] = wr_compl_wptr;
    assign wrob_radr[gw][WROB_COMP] = wr_compl_rptr[gw];
    // RAM 0 : "issued" mark
    lut_ram #(.WIDTH       (1), 
              .DEPTH       (WROB_DEPTH), 
              .WEN_CTRL    ("bit"),
              .INIT_MEM_SIM("zeroes")) wrob_issue (
      .clk  (s_axi_aclk),
      .wen  (wrob_wen [gw][WROB_ISSU]),
      .waddr(wrob_wadr[gw][WROB_ISSU]),
      .wdata(wrob_wdat[gw][WROB_ISSU]),
      .raddr(wrob_radr[gw][WROB_ISSU]),
      .rdata(wrob_rdat[gw][WROB_ISSU])
    );
    // RAM 1 : "completed" mark and txn
    lut_ram #(.WIDTH       (WROB_TXN_WIDTH+1), 
              .DEPTH       (WROB_DEPTH), 
              .WEN_CTRL    ("word"),
              .INIT_MEM_SIM("zeroes")) wrob_compl (
      .clk  (s_axi_aclk),
      .wen  (wrob_wen [gw][WROB_COMP]),
      .waddr(wrob_wadr[gw][WROB_COMP]),
      .wdata({wrob_wdat_txn, wrob_wdat[gw][WROB_COMP]}),
      .raddr(wrob_radr[gw][WROB_COMP]),
      .rdata({wrob_rdat_txn[gw], wrob_rdat[gw][WROB_COMP]})
    );
    // Pop logic
    assign wr_pop_req[gw] = ~^{wrob_rdat[gw][WROB_ISSU], wrob_rdat[gw][WROB_COMP]} && !wrob_mpty[gw];
  end

  //-- Conversion to F2A CPI DATA Channel
  always_comb begin
    f2a_dat.is_valid = (s_axi_awvalid || w_ph_now) && wdone;
    // Default assignment for any unused bits
    f2a_dat.header = '0;
    // Pull out even/odd addresses 
    {addr_odd, addr_even} = '0;
    for (int ii=0; ii<(AXI_ADDR_WIDTH-6)/2; ii++) begin
      addr_even[ii] = !w_ph_now ? s_axi_awaddr[6+2*ii] : awaddr_latch[6+2*ii];
      addr_odd[ii]  = !w_ph_now ? s_axi_awaddr[7+2*ii] : awaddr_latch[7+2*ii];
    end
    /* Header: LSb to MSb going down */
    f2a_dat.header.dsp.f2am.memopcode         = !(&s_axi_wstrb) ? MemWrPtl : MemWrMem;
    // 2-bit metadata                         
    if (METAD_SEL == 0) begin                 
      f2a_dat.header.dsp.f2am.metafield       = Meta0State;
      f2a_dat.header.dsp.f2am.metavalue       = mem_metavalue_t'(s_axi_wuser[WUSER_META_BS+:METAD_W_MIN]);
      f2a_dat_emd                             = '0;
    end                                       
    // N-bit extended metadata (N=1-32)       
    else if (METAD_SEL == 1) begin            
      f2a_dat.header.dsp.f2am.metafield       = ExtMetaState;
      f2a_dat.header.dsp.f2am.metavalue       = mem_metavalue_t'('0);
      f2a_dat_emd                             = s_axi_wuser[WUSER_META_BS+:METAD_W_MIN];
    end
    // No metadata support
    else begin
      f2a_dat.header.dsp.f2am.metafield       = Meta0State;
      f2a_dat.header.dsp.f2am.metavalue       = mem_metavalue_t'('0);
      f2a_dat_emd                             = '0;
    end                                       
    f2a_dat.header.dsp.f2am.snptype           = SnpNoOp;
    f2a_dat.header.dsp.f2am.tc                = '0;
    f2a_dat.header.dsp.f2am.rsvd14to13        = '0;
    f2a_dat.header.dsp.f2am.addressparity     = !EN_ADR_PARITY ? '0 : ^{addr_even, addr_odd};
    f2a_dat.header.dsp.f2am.address51to6_even = addr_even;
    f2a_dat.header.dsp.f2am.tag[ 7: 0]        = wr_issue_wptr[i_axi_awid]; //WROB ptr
    f2a_dat.header.dsp.f2am.tag[11: 8]        = i_axi_awid; //AXI ID (which WROB)
    f2a_dat.header.dsp.f2am.tag[13:12]        = BRDG_ID; //Bridge ID (which module of this type)
    f2a_dat.header.dsp.f2am.tag[15]           = 1'b0; //WRn
    f2a_dat.header.dsp.f2am.address51to6_odd  = addr_odd;
    f2a_dat.header.dsp.f2am.ldid              = '0;
    f2a_dat.header.dsp.f2am.flitmode          = cpi_flitmode_t'('0); //NU: this is a data re-formatter, 
                                                                     //    not flit aware
    /* Parity */
    f2a_dat.cmd_parity = EN_CMD_PARITY ? ^(f2a_dat.header) : 1'b0;
    /* Payload */
    f2a_dat.body               = s_axi_wdata;
    f2a_dat.byte_enable        = s_axi_wstrb; 
    f2a_dat.byte_enable_parity = EN_BEN_PARITY ? ^s_axi_wstrb : 1'b0;
    f2a_dat.poison             = USER_POISN_SUPP ? s_axi_wuser[WUSER_POIS_BS] : 1'b0;
    f2a_dat.sz                 = 1'b1;
    f2a_dat.eop                = 1'b1;
    for (int pp=0; pp<AXI_DATA_WIDTH/64; pp++)
    f2a_dat.parity[pp]         = EN_DAT_PARITY ? ^(s_axi_wdata[64*pp+:64]) : 1'b0;
  end

  /*** Read Datapath (Read Requests [push] and Read Responses [pop]) ***/
  always_comb begin
    for (int ii=0; ii<AXI_IDS_SUPP; ii++) begin
      rrob_mpty [ii] = ({rd_issue_wrap[ii], rd_issue_wptr[ii]} == {rd_compl_wrap[ii], rd_compl_rptr[ii]});
      rrob_ampty[ii] = ({rd_issue_wrap[ii], rd_issue_wptr[ii]} == ({rd_compl_wrap[ii], rd_compl_rptr[ii]}+1'b1));
      rrob_full [ii] = (rd_issue_wptr[ii]==rd_compl_rptr[ii]) && (rd_issue_wrap[ii]^rd_compl_wrap[ii]);
    end
  end

  // Backpressure new transactions in 2 cases:
  //   1. ROB is full for that ID (ID-specific backpressure)
  //   2. CPI is backpressuring with !rdy (global backpressure)
  assign s_axi_arready = !(rrob_full[s_axi_arid] || f2a_req_block_q);

  // Barrel shift right to create a priority search for arbiter 
  // search = {to_search, current_pos}
  always_comb begin
    rd_pop_req_rbs = {rd_pop_req, rd_pop_req} >> rd_pop_sel;
    // Pointer to next req (barrel shifted, so nxt_ptr = cur_ptr+sel
    // Stay at current position if no other reqs
    rd_pop_req_rbs_sel = '0;
    for (int ii=1; ii<AXI_IDS_SUPP; ii++) begin
      if (rd_pop_req_rbs[ii]) begin
        rd_pop_req_rbs_sel = ii;
        break;
      end
    end
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin 
      rd_pop_sel <= '0;
      for (int ii=0; ii<AXI_IDS_SUPP; ii++) begin
        {rd_issue_wrap[ii], rd_issue_wptr[ii]} <= '0;
        {rd_compl_wrap[ii], rd_compl_rptr[ii]} <= '0;
      end
    end
    else begin
      // Round-robin arbitrate the RD responses
      if (rdone || !rd_pop_req[rd_pop_sel]) begin
        rd_pop_sel <= (rd_pop_sel+rd_pop_req_rbs_sel)%AXI_IDS_SUPP;
      end
      // Push
      if (rd_push)
        {rd_issue_wrap[s_axi_arid], rd_issue_wptr[s_axi_arid]} <= {rd_issue_wrap[s_axi_arid], rd_issue_wptr[s_axi_arid]} + 1'b1;
      // Pop
      if (rd_pop)
        {rd_compl_wrap[s_axi_rid], rd_compl_rptr[s_axi_rid]} <= {rd_compl_wrap[s_axi_rid], rd_compl_rptr[s_axi_rid]} + 1'b1;
    end
  end

  assign rd_push    = ardone;
  assign rd_pop     = rdone;
  assign rd_pop_vld = rd_pop_req[rd_pop_sel];

  assign s_axi_rid    = rd_pop_sel;
  assign s_axi_rvalid = rd_pop_vld;
  assign s_axi_rlast  = 1'b1;
  assign s_axi_rdata  = rrob_rdat_txn[rd_pop_sel][RROB_DATA+:SHDW];
  always_comb begin
    if (rrob_rdat_msr[rd_pop_sel])
      s_axi_rresp = OKAY;
    else if (rrob_rdat_txn[rd_pop_sel][RROB_RNXM])
      s_axi_rresp = DECERR;
    else if (USER_POISN_SUPP && rrob_rdat_txn[rd_pop_sel][RROB_POIS])
      s_axi_rresp = SLVERR;
    else
      s_axi_rresp = OKAY;
  end

  // Get RUSER (potentially) from the RROB
  assign i_axi_ruser_devl      = !DEVLD_W ? '0 : rrob_rdat_txn[rd_pop_sel][RROB_DEVL+:2];
  assign i_axi_ruser_metafield =                 rrob_rdat_txn[rd_pop_sel][RROB_MTAF+:2];
  assign i_axi_ruser_metavalue = !METAD_W ? '0 : rrob_rdat_txn[rd_pop_sel][RROB_MTAD+:METAD_W_MIN];
  assign s_axi_ruser = {i_axi_ruser_metavalue, i_axi_ruser_metafield, i_axi_ruser_devl};
  
  //-- RAMs (LUTRAMs)
  for (genvar gr=0; gr<AXI_IDS_SUPP; gr++) begin : rd_ram
    /* There are 3 cases to complete an issuance from the RROB
     * 1. Normal  : a read gets a response with data from device
     * 2. Special : a MemInv[NT] "read" gets a response without data from device
     * 3. SpecRd  : a speculative read gets no response from device */
    always@(*)  begin
      // Normal
      if ((a2f_dat.is_valid && a2f_dat.header.dsp.a2fm.tag[8+:AXI_ID_WIDTH]==gr) ||
          !(!METAD_SEL && MEMOC_SUPP[2:3]))
      begin
        rd_compl_wptr[gr] = a2f_dat.header.dsp.a2fm.tag[0+:$clog2(RROB_DEPTH)];
        rrob_wdat_txn[gr][RROB_DATA+:SHDW] = a2f_dat.body; //data
        rrob_wdat_txn[gr][RROB_RNXM+:   1] = (a2f_dat.header.dsp.a2fm.opcode == MemDataNXM); //rspnxm
        rrob_wdat_txn[gr][RROB_DEVL+:   2] = a2f_dat.header.dsp.a2fm.devload; //devload
        rrob_wdat_txn[gr][RROB_POIS+:   1] = a2f_dat.poison; //poison
        rrob_wdat_txn[gr][RROB_MTAF+:   2] = a2f_dat.header.dsp.a2fm.metafield; //metafield
        // 2-bit metadata
        if (METAD_SEL == 0)      
          rrob_wdat_txn[gr][RROB_MTAD+: 2] = a2f_dat.header.dsp.a2fm.metavalue;
        // N-bit extended metadata (N=1-32)
        else if (METAD_SEL == 1)
          rrob_wdat_txn[gr][RROB_MTAD+:32] = a2f_dat_emd;
        // No metadata support
        else
          rrob_wdat_txn[gr][RROB_MTAD+: 2] = 2'h0;
      end
      else begin
        // Common tie-offs
        rrob_wdat_txn[gr][RROB_DATA+:SHDW] = a2f_dat.body; //!!data is garbage; master should discard
        rrob_wdat_txn[gr][RROB_RNXM+:1]    = 1'b0; //rspnxm
        rrob_wdat_txn[gr][RROB_POIS+:1]    = 1'b0; //poison
        // Multi-Write Saved 
        if (multi_w_vld && multi_w_id==gr) begin
          rd_compl_wptr[gr] = multi_w_ptr;
          rrob_wdat_txn[gr][RROB_DEVL+:2]  = multi_w_txn[MWRT_DEVL+:2]; //devload
          rrob_wdat_txn[gr][RROB_MTAF+:2]  = multi_w_txn[MWRT_MTAF+:2]; //metafield
          rrob_wdat_txn[gr][RROB_MTAD+:2]  = multi_w_txn[MWRT_MTAD+:2]; //2b metavalue
        end
        // Special
        else begin
          rd_compl_wptr[gr] = a2f_rsp.header.dsp.a2fm.tag[0+:$clog2(RROB_DEPTH)];
          rrob_wdat_txn[gr][RROB_DEVL+:2]  = a2f_rsp.header.dsp.a2fm.devload; //devload
          rrob_wdat_txn[gr][RROB_MTAF+:2]  = a2f_rsp.header.dsp.a2fm.metafield; //metafield
          rrob_wdat_txn[gr][RROB_MTAD+:2]  = a2f_rsp.header.dsp.a2fm.metavalue; //2b metavalue
        end
      end
    end
    /* Issued */
    assign rrob_wen [gr][RROB_ISSU] = &{rd_push, s_axi_arid==gr}; 
    assign rrob_wdat[gr][RROB_ISSU] = ^{f2a_req.header.dsp.f2am.memopcode!=MemSpecRd, //toggle
                                        rrob_rdat_issue_strt[gr]};
    assign rrob_wadr[gr][RROB_ISSU] = rd_issue_wptr[gr];
    assign rrob_radr[gr][RROB_ISSU] = rd_compl_rptr[gr];
    /* Completed */
    assign rrob_wen[ gr][RROB_COMP] = 
      &{a2f_dat.is_valid, a2f_dat.header.dsp.a2fm.tag[8+:AXI_ID_WIDTH]==gr} || //Normal
      &{a2f_rsp.is_valid, a2f_rsp.header.dsp.a2fm.tag[8+:AXI_ID_WIDTH]==gr, special} || //Special
      &{multi_w_vld,      multi_w_id==gr}; //Multi-Write Saved
    assign rrob_wdat[gr][RROB_COMP] = rrob_rdat_compl_lkup[gr];
    assign rrob_wadr[gr][RROB_COMP] = rd_compl_wptr[gr];
    assign rrob_radr[gr][RROB_COMP] = rd_compl_rptr[gr];

    // RAM 0 : "issued" and "MemSpecRd" marks
    lut_ram #(.WIDTH       (2), 
              .DEPTH       (RROB_DEPTH), 
              .WEN_CTRL    ("word"),
              .INIT_MEM_SIM("zeroes")) rrob_issue (
      .clk  (s_axi_aclk),
      .wen  (rrob_wen [gr][RROB_ISSU]),
      .waddr(rrob_wadr[gr][RROB_ISSU]),
      .wdata({f2a_req.header.dsp.f2am.memopcode==MemSpecRd, rrob_wdat[gr][RROB_ISSU]}),
      .raddr(rrob_radr[gr][RROB_ISSU]),
      .rdata({rrob_rdat_msr[gr], rrob_rdat[gr][RROB_ISSU]})
    );
    // RAM 1 : "completed" mark and txn
    lut_ram #(.WIDTH       (RROB_TXN_WIDTH+1), 
              .DEPTH       (RROB_DEPTH), 
              .WEN_CTRL    ("word"),
              .INIT_MEM_SIM("zeroes")) rrob_compl (
      .clk  (s_axi_aclk),
      .wen  (rrob_wen [gr][RROB_COMP]),
      .waddr(rrob_wadr[gr][RROB_COMP]),
      .wdata({rrob_wdat_txn[gr], rrob_wdat[gr][RROB_COMP]}),
      .raddr(rrob_radr[gr][RROB_COMP]),
      .rdata({rrob_rdat_txn[gr], rrob_rdat[gr][RROB_COMP]})
    );
    // RAM 2 : the value of the "issued" column before a valid txn hits it
    lut_ram #(.WIDTH       (1), 
              .DEPTH       (RROB_DEPTH), 
              .WEN_CTRL    ("bit"),
              .INIT_MEM_SIM("zeroes")) rrob_issue_start (
      .clk  (s_axi_aclk),
      .wen  (rrob_wen [gr][RROB_ISSU]),
      .waddr(rrob_wadr[gr][RROB_ISSU]),
      .wdata(rrob_wdat[gr][RROB_ISSU]),
      .raddr(rrob_wadr[gr][RROB_ISSU]),
      .rdata(rrob_rdat_issue_strt[gr])
    );
    // RAM 3 : the value of the "completed" column that's getting written
    lut_ram #(.WIDTH       (1), 
              .DEPTH       (RROB_DEPTH), 
              .WEN_CTRL    ("bit"),
              .INIT_MEM_SIM("zeroes")) rrob_compl_lookup (
      .clk  (s_axi_aclk),
      .wen  (rrob_wen [gr][RROB_ISSU]),
      .waddr(rrob_wadr[gr][RROB_ISSU]),
      .wdata(rrob_wdat[gr][RROB_ISSU]),
      .raddr(rrob_wadr[gr][RROB_COMP]),
      .rdata(rrob_rdat_compl_lkup[gr])
    );
    // Pop logic
    assign rd_pop_req[gr] = ~^{rrob_rdat[gr][RROB_ISSU], rrob_rdat[gr][RROB_COMP]} && !rrob_mpty[gr];

  end

  //-- Conversion to F2A CPI REQ Channel
  always_comb begin
    f2a_req.is_valid = rd_push;
    /* Header: LSb to MSb going down */
    f2a_req.header = '0; //Default assignment for any unused bits
    if (MEMOC_SUPP == 3'b000)
      f2a_req.header.dsp.f2am.memopcode = MemRd;
    else begin
      case (s_axi_aruser[ARUSER_CMND_BS+:2])
        2'b01   : f2a_req.header.dsp.f2am.memopcode = MEMOC_SUPP[1] ? MemSpecRd : MemRd;
        2'b10   : f2a_req.header.dsp.f2am.memopcode = MEMOC_SUPP[2] ? MemInv    : MemRd;
        2'b11   : f2a_req.header.dsp.f2am.memopcode = MEMOC_SUPP[3] ? MemInvNT  : MemRd;
        default : f2a_req.header.dsp.f2am.memopcode = MemRd;
      endcase
    end
    f2a_req.header.dsp.f2am.tag[ 7: 0]    = rd_issue_wptr[s_axi_arid]; //RROB ptr
    f2a_req.header.dsp.f2am.tag[11: 8]    = s_axi_arid; //AXI ID (which RROB)
    f2a_req.header.dsp.f2am.tag[13:12]    = BRDG_ID; //Bridge ID (which module of this type)
    f2a_req.header.dsp.f2am.tag[15]       = 1'b1; //RD
    f2a_req.header.dsp.f2am.tc            = '0;
    f2a_req.header.dsp.f2am.snptype       = SnpNoOp;
    f2a_req.header.dsp.f2am.address5      = !ADDR5_SUPP ? 1'b0 : s_axi_araddr[5];
    // MemSpecRd opcode doesn't use these fields
    if (f2a_req.header.dsp.f2am.memopcode == MemSpecRd) begin
      f2a_req.header.dsp.f2am.metafield   = NoOp;
      f2a_req.header.dsp.f2am.metavalue   = mem_metavalue_t'('0);
    end
    // 2-bit metadata
    else if (METAD_SEL == 0) begin
      f2a_req.header.dsp.f2am.metafield   = s_axi_aruser[ARUSER_MFLG_BS] ? Meta0State : NoOp;
      f2a_req.header.dsp.f2am.metavalue   = mem_metavalue_t'(s_axi_aruser[ARUSER_META_BS+:METAD_W_MIN]);
    end
    // N-bit extended metadata (N=1-32)
    else if (METAD_SEL == 1) begin
      f2a_req.header.dsp.f2am.metafield   = s_axi_aruser[ARUSER_MFLG_BS] ? ExtMetaState : NoOp;
      f2a_req.header.dsp.f2am.metavalue   = mem_metavalue_t'('0);
    end
    // No metadata support
    else begin
      f2a_req.header.dsp.f2am.metafield   = NoOp;
      f2a_req.header.dsp.f2am.metavalue   = mem_metavalue_t'('0);
    end
    f2a_req.header.dsp.f2am.addressparity = !EN_ADR_PARITY ? '0 : ^(s_axi_araddr[AXI_ADDR_WIDTH-1:(5+!ADDR5_SUPP)]);
    f2a_req.header.dsp.f2am.address51to6  = s_axi_araddr[AXI_ADDR_WIDTH-1:6];
    f2a_req.header.dsp.f2am.ldid          = '0;
    f2a_req.header.dsp.f2am.flitmode      = cpi_flitmode_t'('0); //NU: this is a data re-formatter, not flit aware
    /* Parity */
    f2a_req.cmd_parity = EN_CMD_PARITY ? ^(f2a_req.header) : 1'b0;
  end

  /* CPI Blocking */
  always @(posedge s_axi_aclk) begin
    // Blocking rcvd on master CPI interface; won't push next cycle 
    f2a_req_block_q <= f2a_req.block;
    f2a_dat_block_q <= f2a_dat.block;
    // Blocking on slave CPI interface; can't push next cycle (error detect)
    a2f_dat_block_q <= a2f_dat.block;
    a2f_rsp_block_q <= a2f_rsp.block;
  end

  assign a2f_dat.block = multi_w || multi_c;
  assign a2f_rsp.block = 1'b0;

  // Error checking
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      f2a_req_block_err <= 1'b0;
      f2a_dat_block_err <= 1'b0;
      a2f_rsp_block_err <= 1'b0;
      a2f_dat_block_err <= 1'b0;
      a2f_dat_id_err    <= 1'b0;
      a2f_rsp_id_err    <= 1'b0;
    end
    else begin
      // Latch error when blocking response violated on CPI interface (AgentBlocking=FabricBlocking=1)
      if (f2a_req.is_valid && f2a_req_block_q)
        f2a_req_block_err <= 1'b1;
      if (f2a_dat.is_valid && f2a_dat_block_q)
        f2a_dat_block_err <= 1'b1;
      if (a2f_rsp.is_valid && a2f_rsp_block_q)
        a2f_rsp_block_err <= 1'b1;
      if (a2f_dat.is_valid && a2f_dat_block_q)
        a2f_dat_block_err <= 1'b1;
      // Latch error when txn with mismatching bridge ID is received
      if (a2f_dat.is_valid && a2f_dat.header.dsp.a2fm.tag[13:12]!=BRDG_ID)
        a2f_dat_id_err <= 1'b1;
      if (a2f_rsp.is_valid && a2f_rsp.header.dsp.a2fm.tag[13:12]!=BRDG_ID)
        a2f_rsp_id_err <= 1'b1;
    end
  end

  // Connections to internal bus
  // - top level outputs
  assign dbg_gpio_if.axi_wr_start_cnt = DEBUG_IF_EN[0] ? i_dbg_gpio_if.axi_wr_start_cnt : 0;
  assign dbg_gpio_if.axi_wr_compl_cnt = DEBUG_IF_EN[0] ? i_dbg_gpio_if.axi_wr_compl_cnt : 0;
  assign dbg_gpio_if.axi_rd_start_cnt = DEBUG_IF_EN[0] ? i_dbg_gpio_if.axi_rd_start_cnt : 0;
  assign dbg_gpio_if.axi_rd_compl_cnt = DEBUG_IF_EN[0] ? i_dbg_gpio_if.axi_rd_compl_cnt : 0;
  assign dbg_gpio_if.f2a_req_cnt      = DEBUG_IF_EN[0] ? i_dbg_gpio_if.f2a_req_cnt      : 0;    
  assign dbg_gpio_if.f2a_dat_cnt      = DEBUG_IF_EN[0] ? i_dbg_gpio_if.f2a_dat_cnt      : 0;    
  assign dbg_gpio_if.a2f_rsp_cnt      = DEBUG_IF_EN[0] ? i_dbg_gpio_if.a2f_rsp_cnt      : 0;    
  assign dbg_gpio_if.a2f_dat_cnt      = DEBUG_IF_EN[0] ? i_dbg_gpio_if.a2f_dat_cnt      : 0;    
  assign dbg_gpio_if.f2a_dat_emd_cnt  = DEBUG_IF_EN[0] ? i_dbg_gpio_if.f2a_dat_emd_cnt  : 0;
  assign dbg_gpio_if.a2f_dat_emd_cnt  = DEBUG_IF_EN[0] ? i_dbg_gpio_if.a2f_dat_emd_cnt  : 0;
  assign dbg_gpio_if.axi_wr_start_bcd = DEBUG_IF_EN[0] ? i_dbg_gpio_if.axi_wr_start_bcd : 0;
  assign dbg_gpio_if.axi_wr_compl_bcd = DEBUG_IF_EN[0] ? i_dbg_gpio_if.axi_wr_compl_bcd : 0;
  assign dbg_gpio_if.axi_rd_start_bcd = DEBUG_IF_EN[0] ? i_dbg_gpio_if.axi_rd_start_bcd : 0;
  assign dbg_gpio_if.axi_rd_compl_bcd = DEBUG_IF_EN[0] ? i_dbg_gpio_if.axi_rd_compl_bcd : 0;
  assign dbg_gpio_if.f2a_req_bcd      = DEBUG_IF_EN[0] ? i_dbg_gpio_if.f2a_req_bcd      : 0;    
  assign dbg_gpio_if.f2a_dat_bcd      = DEBUG_IF_EN[0] ? i_dbg_gpio_if.f2a_dat_bcd      : 0;    
  assign dbg_gpio_if.a2f_rsp_bcd      = DEBUG_IF_EN[0] ? i_dbg_gpio_if.a2f_rsp_bcd      : 0;    
  assign dbg_gpio_if.a2f_dat_bcd      = DEBUG_IF_EN[0] ? i_dbg_gpio_if.a2f_dat_bcd      : 0;    
  assign dbg_gpio_if.f2a_dat_emd_bcd  = DEBUG_IF_EN[0] ? i_dbg_gpio_if.f2a_dat_emd_bcd  : 0;
  assign dbg_gpio_if.a2f_dat_emd_bcd  = DEBUG_IF_EN[0] ? i_dbg_gpio_if.a2f_dat_emd_bcd  : 0;

  // these may come from GPIO and/or AXI-L
  assign final_cnt_reset      = &{DEBUG_IF_EN[0], dbg_gpio_if.cnt_reset} ||
                                &{DEBUG_IF_EN[1], axil_cnt_reset};
  assign final_cnt_enable     = &{DEBUG_IF_EN[0], dbg_gpio_if.cnt_enable} ||
                                &{DEBUG_IF_EN[1], axil_cnt_enable};
  assign final_cnt_freerun    = &{DEBUG_IF_EN[0], dbg_gpio_if.cnt_freerun} ||
                                &{DEBUG_IF_EN[1], axil_cnt_freerun};
  generate
  if (DEBUG_IF_EN) begin : DEBUG_CNT

    // Init for sim
    initial begin
      i_dbg_gpio_if.axi_wr_start_cnt <= '0;
      i_dbg_gpio_if.axi_wr_compl_cnt <= '0;
      i_dbg_gpio_if.axi_rd_start_cnt <= '0;
      i_dbg_gpio_if.axi_rd_compl_cnt <= '0;
      i_dbg_gpio_if.f2a_req_cnt      <= '0;
      i_dbg_gpio_if.f2a_dat_cnt      <= '0;
      i_dbg_gpio_if.f2a_dat_emd_cnt  <= '0;
      i_dbg_gpio_if.a2f_rsp_cnt      <= '0;
      i_dbg_gpio_if.a2f_dat_cnt      <= '0;
      i_dbg_gpio_if.a2f_dat_emd_cnt  <= '0;
    end

    always @(posedge s_axi_aclk) begin
      if (final_cnt_reset) begin
        // AXI side
        i_dbg_gpio_if.axi_wr_start_cnt <= 0;
        i_dbg_gpio_if.axi_wr_compl_cnt <= 0;
        i_dbg_gpio_if.axi_rd_start_cnt <= 0;
        i_dbg_gpio_if.axi_rd_compl_cnt <= 0;
        // CPI side 
        i_dbg_gpio_if.f2a_req_cnt     <= 0;
        i_dbg_gpio_if.f2a_dat_cnt     <= 0;
        i_dbg_gpio_if.a2f_rsp_cnt     <= 0;
        i_dbg_gpio_if.a2f_dat_cnt     <= 0;
        i_dbg_gpio_if.f2a_dat_emd_cnt <= 0;
        i_dbg_gpio_if.a2f_dat_emd_cnt <= 0;
      end
      else if (final_cnt_enable) begin
        // AXI side
        if (awdone && (final_cnt_freerun || !(&i_dbg_gpio_if.axi_wr_start_cnt)))
          i_dbg_gpio_if.axi_wr_start_cnt <= i_dbg_gpio_if.axi_wr_start_cnt + 1'b1;
        if ( bdone && (final_cnt_freerun || !(&i_dbg_gpio_if.axi_wr_compl_cnt))) 
          i_dbg_gpio_if.axi_wr_compl_cnt <= i_dbg_gpio_if.axi_wr_compl_cnt + 1'b1;
        if (ardone && (final_cnt_freerun || !(&i_dbg_gpio_if.axi_rd_start_cnt))) 
          i_dbg_gpio_if.axi_rd_start_cnt <= i_dbg_gpio_if.axi_rd_start_cnt + 1'b1;
        if ( rdone && (final_cnt_freerun || !(&i_dbg_gpio_if.axi_rd_compl_cnt))) 
          i_dbg_gpio_if.axi_rd_compl_cnt <= i_dbg_gpio_if.axi_rd_compl_cnt + 1'b1;
        // CPI side 
        if (f2a_req.is_valid && (final_cnt_freerun || !(&i_dbg_gpio_if.f2a_req_cnt))) 
          i_dbg_gpio_if.f2a_req_cnt <= i_dbg_gpio_if.f2a_req_cnt + 1'b1;
        if (f2a_dat.is_valid && (final_cnt_freerun || !(&i_dbg_gpio_if.f2a_dat_cnt))) 
          i_dbg_gpio_if.f2a_dat_cnt <= i_dbg_gpio_if.f2a_dat_cnt + 1'b1;
        if (a2f_rsp.is_valid && (final_cnt_freerun || !(&i_dbg_gpio_if.a2f_rsp_cnt))) 
          i_dbg_gpio_if.a2f_rsp_cnt <= i_dbg_gpio_if.a2f_rsp_cnt + 1'b1;
        if (a2f_dat.is_valid && (final_cnt_freerun || !(&i_dbg_gpio_if.a2f_dat_cnt))) 
          i_dbg_gpio_if.a2f_dat_cnt <= i_dbg_gpio_if.a2f_dat_cnt + 1'b1;
        if (METAD_SEL==1) begin
          if (f2a_dat.is_valid && f2a_dat.header.dsp.f2am.metafield==ExtMetaState && 
             (final_cnt_freerun || !(&i_dbg_gpio_if.f2a_dat_emd_cnt)))
          begin
            i_dbg_gpio_if.f2a_dat_emd_cnt <= i_dbg_gpio_if.f2a_dat_emd_cnt + 1'b1;
          end
          if (a2f_dat.is_valid && a2f_dat.header.dsp.a2fm.metafield==ExtMetaState && 
             (final_cnt_freerun || !(&i_dbg_gpio_if.a2f_dat_emd_cnt)))
          begin
            i_dbg_gpio_if.a2f_dat_emd_cnt <= i_dbg_gpio_if.a2f_dat_emd_cnt + 1'b1;
          end
        end
      end
    end

  end : DEBUG_CNT
  endgenerate

  generate
  if (DEBUG_IF_EN && DEBUG_EN_BCD) begin : DEBUG_BCD

    logic         bcd_load;
    logic [15:0]  bin;
    logic         in_prog;
    logic [18:0]  bcd;
    logic         bcd_done;

    logic [i_dbg_gpio_if.NUM_DEBUG-1:0] bcd_attn;
    logic [    i_dbg_gpio_if.CNT_W-1:0] attn_ptr;

    initial begin
      bcd_attn <= '0;
      attn_ptr <= '0;
    end

    // Single module that will convert a binary number to BCD 
    bin2bcd_seq #(16) i_bin2bcd_seq(
      .clk     (s_axi_aclk),
      .load    (bcd_load),
      .bin     (bin),
      .in_prog (in_prog),
      .done    (bcd_done),
      .bcd     (bcd)
    );
    
    always_comb begin
      bcd_load = !in_prog && !bcd_done && bcd_attn[attn_ptr];
      case (attn_ptr)
        0 : bin = i_dbg_gpio_if.axi_wr_start_cnt; 
        1 : bin = i_dbg_gpio_if.axi_wr_compl_cnt;
        2 : bin = i_dbg_gpio_if.axi_rd_start_cnt;
        3 : bin = i_dbg_gpio_if.axi_rd_compl_cnt;
        4 : bin = i_dbg_gpio_if.f2a_req_cnt;
        5 : bin = i_dbg_gpio_if.f2a_dat_cnt;
        6 : bin = i_dbg_gpio_if.a2f_rsp_cnt;
        7 : bin = i_dbg_gpio_if.a2f_dat_cnt;
        // Only possible if METAD_SEL==1
        8 : bin = i_dbg_gpio_if.f2a_dat_emd_cnt;
        9 : bin = i_dbg_gpio_if.a2f_dat_emd_cnt;
        default : bin = i_dbg_gpio_if.axi_wr_start_cnt; 
      endcase
    end
    
    always @(posedge s_axi_aclk) begin
      // Use a ring like structure and iterate through it
      if (bcd_done || (!in_prog && !bcd_attn[attn_ptr])) 
        attn_ptr <= attn_ptr==i_dbg_gpio_if.NUM_DEBUG-1 ? 0 : attn_ptr + 1'b1;
      // Set and clear each attn in the ring and latch value
      // -- 0 --
      if (final_cnt_reset)
        i_dbg_gpio_if.axi_wr_start_bcd <= 0;
      else if (bcd_done && attn_ptr==0) 
        i_dbg_gpio_if.axi_wr_start_bcd <= bcd;
      if (awdone) 
        bcd_attn[0] <= 1'b1;
      else if (bcd_load && attn_ptr==0)
        bcd_attn[0] <= 1'b0;
      // -- 1 -- 
      if (final_cnt_reset)
        i_dbg_gpio_if.axi_wr_compl_bcd <= 0;
      else if (bcd_done && attn_ptr==1) 
        i_dbg_gpio_if.axi_wr_compl_bcd <= bcd;
      if (bdone) 
        bcd_attn[1] <= 1'b1;
      else if (bcd_load && attn_ptr==1)
        bcd_attn[1] <= 1'b0;
      // -- 2 -- 
      if (final_cnt_reset)
        i_dbg_gpio_if.axi_rd_start_bcd <= 0;
      else if (bcd_done && attn_ptr==2) 
        i_dbg_gpio_if.axi_rd_start_bcd <= bcd;
      if (ardone) 
        bcd_attn[2] <= 1'b1;
      else if (bcd_load && attn_ptr==2)
        bcd_attn[2] <= 1'b0;
      // -- 3 -- 
      if (final_cnt_reset)
        i_dbg_gpio_if.axi_rd_compl_bcd <= 0;
      else if (bcd_done && attn_ptr==3) 
        i_dbg_gpio_if.axi_rd_compl_bcd <= bcd;
      if (rdone) 
        bcd_attn[3] <= 1'b1;
      else if (bcd_load && attn_ptr==3)
        bcd_attn[3] <= 1'b0;
      // -- 4 -- 
      if (final_cnt_reset)
        i_dbg_gpio_if.f2a_req_bcd <= 0;
      else if (bcd_done && attn_ptr==4) 
        i_dbg_gpio_if.f2a_req_bcd <= bcd;
      if (f2a_req.is_valid)
        bcd_attn[4] <= 1'b1;
      else if (bcd_load && attn_ptr==4)
        bcd_attn[4] <= 1'b0;
      // -- 5 -- 
      if (final_cnt_reset)
        i_dbg_gpio_if.f2a_dat_bcd <= 0;
      else if (bcd_done && attn_ptr==5) 
        i_dbg_gpio_if.f2a_dat_bcd <= bcd;
      if (f2a_dat.is_valid)
        bcd_attn[5] <= 1'b1;
      else if (bcd_load && attn_ptr==5)
        bcd_attn[5] <= 1'b0;
      // -- 6 -- 
      if (final_cnt_reset)
        i_dbg_gpio_if.a2f_rsp_bcd <= 0;
      else if (bcd_done && attn_ptr==6) 
        i_dbg_gpio_if.a2f_rsp_bcd <= bcd;
      if (a2f_rsp.is_valid)
        bcd_attn[6] <= 1'b1;
      else if (bcd_load && attn_ptr==6)
        bcd_attn[6] <= 1'b0;
      // -- 7 -- 
      if (final_cnt_reset)
        i_dbg_gpio_if.a2f_dat_bcd <= 0;
      else if (bcd_done && attn_ptr==7) 
        i_dbg_gpio_if.a2f_dat_bcd <= bcd;
      if (a2f_dat.is_valid)
        bcd_attn[7] <= 1'b1;
      else if (bcd_load && attn_ptr==7)
        bcd_attn[7] <= 1'b0;
      // ------- //
      if (METAD_SEL==1) begin
        // -- 8 -- 
        if (final_cnt_reset)
          i_dbg_gpio_if.f2a_dat_emd_bcd <= 0;
        else if (bcd_done && attn_ptr==8) 
          i_dbg_gpio_if.f2a_dat_emd_bcd <= bcd;
        if (f2a_dat.is_valid && f2a_dat.header.dsp.f2am.metafield==ExtMetaState)
          bcd_attn[8] <= 1'b1;
        else if (bcd_load && attn_ptr==8) begin
          bcd_attn[8] <= 1'b0;
        end
        // -- 9 -- 
        if (final_cnt_reset)
          i_dbg_gpio_if.a2f_dat_emd_bcd <= 0;
        else if (bcd_done && attn_ptr==9) 
          i_dbg_gpio_if.a2f_dat_emd_bcd <= bcd;
        if (a2f_dat.is_valid && a2f_dat.header.dsp.a2fm.metafield==ExtMetaState)
          bcd_attn[9] <= 1'b1;
        else if (bcd_load && attn_ptr==9)
          bcd_attn[9] <= 1'b0;
      end
    end
  end : DEBUG_BCD
  else begin : NO_DEBUG_BCD
    assign i_dbg_gpio_if.axi_wr_start_bcd = 0;
    assign i_dbg_gpio_if.axi_wr_compl_bcd = 0;
    assign i_dbg_gpio_if.axi_rd_start_bcd = 0;
    assign i_dbg_gpio_if.axi_rd_compl_bcd = 0;
    assign i_dbg_gpio_if.f2a_req_bcd      = 0;
    assign i_dbg_gpio_if.f2a_dat_bcd      = 0;
    assign i_dbg_gpio_if.a2f_rsp_bcd      = 0;
    assign i_dbg_gpio_if.a2f_dat_bcd      = 0;
    assign i_dbg_gpio_if.f2a_dat_emd_bcd  = 0;
    assign i_dbg_gpio_if.a2f_dat_emd_bcd  = 0;
  end : NO_DEBUG_BCD
  endgenerate

  generate
  if (DEBUG_IF_EN[1]) begin : DEBUG_AXIL

     axi_cpi_bridge_reg_space #(
       .AXI_IDS_SUPP (AXI_IDS_SUPP),
       .WROB_PTR_W   ($clog2(WROB_DEPTH)),
       .RROB_PTR_W   ($clog2(RROB_DEPTH))
     ) reg_space (
       // source domain
       .axil_clk          (s_axil_aclk),
       .axil_rstn         (s_axil_aresetn),
       // destination domain
       .dest_clk          (s_axi_aclk),
       // monitor any errors
       .f2a_req_block_err (f2a_req_block_err),
       .f2a_dat_block_err (f2a_dat_block_err),
       .a2f_rsp_block_err (a2f_rsp_block_err),
       .a2f_dat_block_err (a2f_dat_block_err),
       .a2f_rsp_id_err    (a2f_rsp_id_err),
       .a2f_dat_id_err    (a2f_dat_id_err),
       // monitor the AXI interface
       .awvalid           (s_axi_awvalid),
       .awready           (s_axi_awready),
       .wvalid            (s_axi_wvalid),
       .wready            (s_axi_wready),
       .bvalid            (s_axi_bvalid),
       .bready            (s_axi_bready),
       .arvalid           (s_axi_arvalid),
       .arready           (s_axi_arready),
       .rvalid            (s_axi_rvalid),
       .rready            (s_axi_rready),
       // monitor the CPI interface
       .f2a_req_valid     (f2a_req.is_valid),
       .f2a_req_block     (f2a_req_block_q),
       .f2a_dat_valid     (f2a_dat.is_valid),
       .f2a_dat_block     (f2a_dat_block_q),
       .a2f_dat_valid     (a2f_dat.is_valid),
       .a2f_dat_block     (a2f_dat_block_q),
       .a2f_rsp_valid     (a2f_rsp.is_valid),
       .a2f_rsp_block     (a2f_rsp_block_q),
       // monitor the buffer logic
       //  - write re-order buffer (WROB)
       .wrob_mpty         (wrob_mpty),
       .wrob_ampty        (wrob_ampty),
       .wrob_full         (wrob_full),
       .wr_issue_wrap     (wr_issue_wrap),
       .wr_issue_wptr     (wr_issue_wptr),
       .wr_compl_wrap     (wr_compl_wrap),
       .wr_compl_rptr     (wr_compl_rptr),
       //  - read re-order buffer (RROB)
       .rrob_mpty         (rrob_mpty),
       .rrob_ampty        (rrob_ampty),
       .rrob_full         (rrob_full),
       .rd_issue_wrap     (rd_issue_wrap),
       .rd_issue_wptr     (rd_issue_wptr),
       .rd_compl_wrap     (rd_compl_wrap),
       .rd_compl_rptr     (rd_compl_rptr),
       // monitor the counters
       .i_dbg_gpio_if     (i_dbg_gpio_if),
       // control reset, enable, and freerun
       .final_cnt_reset   (final_cnt_reset),
       .dbg_cnt_reset     (dbg_gpio_if.cnt_reset),
       .axil_cnt_reset    (axil_cnt_reset),
       .final_cnt_enable  (final_cnt_enable),
       .dbg_cnt_enable    (dbg_gpio_if.cnt_enable),
       .axil_cnt_enable   (axil_cnt_enable),
       .final_cnt_freerun (final_cnt_freerun),
       .dbg_cnt_freerun   (dbg_gpio_if.cnt_freerun),
       .axil_cnt_freerun  (axil_cnt_freerun),
       // AXI4-Lite AR channel (read address)
       .s_axil_arvalid    (s_axil_arvalid),
       .s_axil_arready    (s_axil_arready),
       .s_axil_araddr     (s_axil_araddr[11:0]),
       .s_axil_arprot     (s_axil_arprot),
       // AXI4-Lite R channel (read data)
       .s_axil_rvalid     (s_axil_rvalid),
       .s_axil_rready     (s_axil_rready),
       .s_axil_rresp      (s_axil_rresp),
       .s_axil_rdata      (s_axil_rdata),
       // AXI4-Lite AW channel (write address)
       .s_axil_awvalid    (s_axil_awvalid),
       .s_axil_awready    (s_axil_awready),
       .s_axil_awaddr     (s_axil_awaddr[11:0]),
       .s_axil_awprot     (s_axil_awprot),
       // AXI4-Lite W channel (write data)
       .s_axil_wvalid     (s_axil_wvalid),
       .s_axil_wready     (s_axil_wready),
       .s_axil_wdata      (s_axil_wdata),
       .s_axil_wstrb      (s_axil_wstrb),
       // AXI4-Lite B channel (write response)
       .s_axil_bvalid     (s_axil_bvalid),
       .s_axil_bready     (s_axil_bready),
       .s_axil_bresp      (s_axil_bresp)
     );
  end : DEBUG_AXIL
  endgenerate

  /* Initialization for sim */
  initial begin
    f2a_req_block_q <= '0;
    f2a_dat_block_q <= '0;
    a2f_rsp_block_q <= '0;
    a2f_dat_block_q <= '0;
  end

  `ifndef SYNTHESIS
  //synthesis off
  initial begin
    if (|(WROB_DEPTH&(WROB_DEPTH-1)))
      $fatal(0, $sformatf("WROB_DEPTH=%0d is invalid; must be a power of 2",WROB_DEPTH));
    if (|(RROB_DEPTH&(RROB_DEPTH-1)))
      $fatal(0, $sformatf("RROB_DEPTH=%0d is invalid; must be a power of 2",RROB_DEPTH));
    if (WROB_DEPTH>256)
      $fatal(0, $sformatf("WROB_DEPTH=%0d is invalid; maximum is 256",WROB_DEPTH));
    if (RROB_DEPTH>256)
      $fatal(0, $sformatf("RROB_DEPTH=%0d is invalid; maximum is 256",RROB_DEPTH));
    if (AXI_IDS_SUPP>16)
      $fatal(0, $sformatf("AXI_IDS_SUPP=%0d is invalid; maximum is 16",AXI_IDS_SUPP));
    if (USER_METAD_SUPP!=-1 && MEMOC_SUPP[2:3])
      $fatal(0, {"To enable MemInv and/or MemInvNT opcodes, 2 bit metadata ",
                 "must be enabled by setting USER_METAD_SUPP=-1"});
  end
  //synthesis on
  `endif

endmodule
