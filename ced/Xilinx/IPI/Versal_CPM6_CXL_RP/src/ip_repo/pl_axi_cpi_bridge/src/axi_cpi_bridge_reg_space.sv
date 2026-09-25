module axi_cpi_bridge_reg_space #(
  parameter WROB_PTR_W,
  parameter RROB_PTR_W,
  parameter AXI_IDS_SUPP
)(
  // source domain
  input                        axil_clk,
  input                        axil_rstn,
  // destination domain
  input                        dest_clk,
  // monitor any errors
  input                        f2a_req_block_err,
  input                        f2a_dat_block_err,
  input                        a2f_rsp_block_err,
  input                        a2f_dat_block_err,
  input                        a2f_rsp_id_err,
  input                        a2f_dat_id_err,
  // monitor the AXI interface
  input                        awvalid,
  input                        awready,
  input                         wvalid,
  input                         wready,
  input                         bvalid,
  input                         bready,
  input                        arvalid,
  input                        arready,
  input                         rvalid,
  input                         rready,
  // monitor the CPI interface
  input                         f2a_req_valid,
  input                         f2a_req_block,
  input                         f2a_dat_valid,
  input                         f2a_dat_block,
  input                         a2f_dat_valid,
  input                         a2f_dat_block,
  input                         a2f_rsp_valid,
  input                         a2f_rsp_block,
  // monitor the buffer logic
  //  - write re-order buffer (WROB)
  input                        wrob_mpty [AXI_IDS_SUPP],
  input                        wrob_ampty[AXI_IDS_SUPP],
  input                        wrob_full [AXI_IDS_SUPP],
  input                        wr_issue_wrap[AXI_IDS_SUPP],
  input [WROB_PTR_W-1:0]       wr_issue_wptr[AXI_IDS_SUPP],
  input                        wr_compl_wrap[AXI_IDS_SUPP],
  input [WROB_PTR_W-1:0]       wr_compl_rptr[AXI_IDS_SUPP],
  //  - read re-order buffer (RROB)
  input                        rrob_mpty [AXI_IDS_SUPP],
  input                        rrob_ampty[AXI_IDS_SUPP],
  input                        rrob_full [AXI_IDS_SUPP],
  input                        rd_issue_wrap[AXI_IDS_SUPP],
  input [RROB_PTR_W-1:0]       rd_issue_wptr[AXI_IDS_SUPP],
  input                        rd_compl_wrap[AXI_IDS_SUPP],
  input [RROB_PTR_W-1:0]       rd_compl_rptr[AXI_IDS_SUPP],
  // monitor the counters
  debug_axi_cpi_bridge.monitor i_dbg_gpio_if,
  // control reset and freerun
  input                        final_cnt_reset,
  input                        dbg_cnt_reset,
  output logic                 axil_cnt_reset,
  input                        final_cnt_enable,
  input                        dbg_cnt_enable,
  output logic                 axil_cnt_enable,
  input                        final_cnt_freerun,
  input                        dbg_cnt_freerun,
  output logic                 axil_cnt_freerun,
  // AXI4-Lite AR channel (read address)
  input                        s_axil_arvalid,
  output logic                 s_axil_arready,
  input                [11:0]  s_axil_araddr,  // 4KB=12 bits
  input                [ 2:0]  s_axil_arprot,
  // AXI4-Lite R channel (read data)
  output logic                 s_axil_rvalid,
  input                        s_axil_rready,
  output logic         [ 1:0]  s_axil_rresp,
  output logic         [31:0]  s_axil_rdata,
  // AXI4-Lite AW channel (write address)
  input                        s_axil_awvalid,
  output logic                 s_axil_awready,
  input                [11:0]  s_axil_awaddr, // 4 KB=12 bits
  input                [ 2:0]  s_axil_awprot,
  // AXI4-Lite W channel (write data)
  input                        s_axil_wvalid,
  output logic                 s_axil_wready,
  input                [31:0]  s_axil_wdata,
  input                [ 3:0]  s_axil_wstrb,
  // AXI4-Lite B channel (write response)
  output logic                 s_axil_bvalid,
  input                        s_axil_bready,
  output logic         [ 1:0]  s_axil_bresp
);

  // AXI4-Lite response codes
  localparam OKAY   = 2'b00, 
             SLVERR = 2'b10;

  // State machine for single outstanding read
  enum logic [1:0] {READ_IDLE, READ_A2D, READ_D2A, READ_PEND} read_state;

  // State machine for single outstanding write
  enum logic [2:0] {WRITE_IDLE, WRITE_DATA, WRITE_A2D, WRITE_D2A, WRITE_PEND} write_state;

  logic [11:0] captured_araddr_a;
  logic [11:0] captured_araddr_d;
  logic        do_capture_rd_d;
  logic [ 1:0] capture_rresp;
  logic [31:0] capture_rdata;

  logic [11:0] captured_awaddr_a;
  logic [11:0] captured_awaddr_d;
  logic [31:0] captured_wdata_a;
  logic [31:0] captured_wdata_d;
  logic [ 3:0] captured_wstrb_a;
  logic [ 3:0] captured_wstrb_d;
  logic        do_capture_wr_d;
  logic [ 1:0] capture_bresp;

  logic        ar_done;
  logic        r_done;
  logic        aw_done;
  logic        w_done;
  logic        b_done;

  assign ar_done = s_axil_arvalid && s_axil_arready;
  assign r_done  = s_axil_rvalid  && s_axil_rready;
  assign aw_done = s_axil_awvalid && s_axil_awready;
  assign w_done  = s_axil_wvalid  && s_axil_wready;
  assign b_done  = s_axil_bvalid  && s_axil_bready;

  // Pack the unpacked wrob_mpty/wrob_ampty/wrob_full and
  // rrob_mpty/rrob_ampty/rrob_full arrays into vectors for AXI-L reads
  logic [AXI_IDS_SUPP-1:0] wrob_mpty_vec;
  logic [AXI_IDS_SUPP-1:0] wrob_ampty_vec;
  logic [AXI_IDS_SUPP-1:0] wrob_full_vec;
  logic [AXI_IDS_SUPP-1:0] rrob_mpty_vec;
  logic [AXI_IDS_SUPP-1:0] rrob_ampty_vec;
  logic [AXI_IDS_SUPP-1:0] rrob_full_vec;
  always_comb
    for (int i = 0; i < AXI_IDS_SUPP; i++) begin
      wrob_mpty_vec[i]  = wrob_mpty[i];
      wrob_ampty_vec[i] = wrob_ampty[i];
      wrob_full_vec[i]  = wrob_full[i];
      rrob_mpty_vec[i]  = rrob_mpty[i];
      rrob_ampty_vec[i] = rrob_ampty[i];
      rrob_full_vec[i]  = rrob_full[i];
    end

  // AXI-L Clock and Destination Clock may be different domains
  // a = "axi-l clock" | d = "dest clock"
  // Need to sync the fact that a txn has occured from A to C
  // and then need to sync the done case from C to A for both
  // AXI reads and AXI writes
  logic a2d_rreq_a, a2d_rreq_d;
  logic a2d_rack_a, a2d_rack_d;

  logic a2d_rreq_d_pulse;

  (* ASYNC_REG = "TRUE" *) logic a2d_rreq_sync_0, a2d_rreq_sync_1, a2d_rreq_sync_2;
  (* ASYNC_REG = "TRUE" *) logic a2d_rack_sync_0, a2d_rack_sync_1;

  // Write path CDC signals
  logic a2d_wreq_a, a2d_wreq_d;
  logic a2d_wack_a, a2d_wack_d;

  logic a2d_wreq_d_pulse;

  (* ASYNC_REG = "TRUE" *) logic a2d_wreq_sync_0, a2d_wreq_sync_1, a2d_wreq_sync_2;
  (* ASYNC_REG = "TRUE" *) logic a2d_wack_sync_0, a2d_wack_sync_1;

  // Sync-ing the request from A into D
  always_ff @(posedge dest_clk) begin
    a2d_rreq_sync_0 <= a2d_rreq_a;
    a2d_rreq_sync_1 <= a2d_rreq_sync_0;
    a2d_rreq_sync_2 <= a2d_rreq_sync_1;
  end

  assign a2d_rreq_d       = a2d_rreq_sync_1;
  assign a2d_rreq_d_pulse = a2d_rreq_sync_1^a2d_rreq_sync_2;

  // Sync-ing the ack from D into A
  always_ff @(posedge axil_clk) begin
    a2d_rack_sync_0 <= a2d_rack_d;
    a2d_rack_sync_1 <= a2d_rack_sync_0;
  end

  assign a2d_rack_a = a2d_rack_sync_1;

  // Sync-ing the write request from A into D
  always_ff @(posedge dest_clk) begin
    a2d_wreq_sync_0 <= a2d_wreq_a;
    a2d_wreq_sync_1 <= a2d_wreq_sync_0;
    a2d_wreq_sync_2 <= a2d_wreq_sync_1;
  end

  assign a2d_wreq_d       = a2d_wreq_sync_1;
  assign a2d_wreq_d_pulse = a2d_wreq_sync_1^a2d_wreq_sync_2;

  // Sync-ing the write ack from D into A
  always_ff @(posedge axil_clk) begin
    a2d_wack_sync_0 <= a2d_wack_d;
    a2d_wack_sync_1 <= a2d_wack_sync_0;
  end

  assign a2d_wack_a = a2d_wack_sync_1;

  // CXL domain write handler - processes write transactions
  always_ff @(posedge dest_clk) begin
    // Data will be stable, sample from A into D on a posedge pulse
    if (a2d_wreq_d_pulse && a2d_wreq_d) begin
      captured_awaddr_d <= captured_awaddr_a;
      captured_wdata_d  <= captured_wdata_a;
      captured_wstrb_d  <= captured_wstrb_a;
      do_capture_wr_d   <= 1'b1;
    end
    // Next cycle, save into D register
    else if (do_capture_wr_d) begin
      do_capture_wr_d <= 1'b0;
      capture_bresp <= OKAY;
      case (captured_awaddr_d)
        // -------------------------------------------------------- //
        /* Debug Counters */
        // -------------------------------------------------------- //
        12'h0D0 : begin
                    axil_cnt_freerun <= captured_wdata_d[9];
                    axil_cnt_enable  <= captured_wdata_d[5];
                    axil_cnt_reset   <= captured_wdata_d[1];
                  end
      endcase
    end
    // Need to assert back to A that it can sample
    if (do_capture_wr_d)
      a2d_wack_d <= 1'b1;
    // Deassert ack when source has deasserted req
    else if (a2d_wreq_d_pulse)
      a2d_wack_d <= 1'b0;
  end

  // destination domain read handler - processes read transactions
  always_ff @(posedge dest_clk) begin
    // Data will be stable, sample from A into D on a posedge pulse
    if (a2d_rreq_d_pulse && a2d_rreq_d) begin
      captured_araddr_d <= captured_araddr_a;
      do_capture_rd_d <= 1'b1;
    end
    // Next cycle, save into D register
    else if (do_capture_rd_d) begin
      do_capture_rd_d <= 1'b0;
      case (captured_araddr_d)
        // -------------------------------------------------------- //
        /* Debug Counters */
        // -------------------------------------------------------- //
        12'h080 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,                           //31:16
                    i_dbg_gpio_if.axi_wr_start_cnt}; //15: 0
        12'h084 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,                           //31:16
                    i_dbg_gpio_if.axi_wr_compl_cnt}; //15: 0
        12'h088 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,                           //31:16
                    i_dbg_gpio_if.axi_rd_start_cnt}; //15: 0
        12'h08C : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,                           //31:16
                    i_dbg_gpio_if.axi_rd_compl_cnt}; //15: 0
        12'h090 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,                      //31:16
                    i_dbg_gpio_if.f2a_req_cnt}; //15: 0
        12'h094 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,                      //31:16
                    i_dbg_gpio_if.f2a_dat_cnt}; //15: 0
        12'h098 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,                          //31:16
                    i_dbg_gpio_if.f2a_dat_emd_cnt}; //15: 0
        12'h09C : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,                      //31:16
                    i_dbg_gpio_if.a2f_rsp_cnt}; //15: 0
        12'h0A0 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,                      //31:16
                    i_dbg_gpio_if.a2f_dat_cnt}; //15: 0
        12'h0A4 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,                          //31:16
                    i_dbg_gpio_if.a2f_dat_emd_cnt}; //15: 0
        // Same count, just in BCD
        12'h0A8 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    13'h0,                           //31:19
                    i_dbg_gpio_if.axi_wr_start_bcd}; //18: 0
        12'h0AC : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    13'h0,                           //31:19
                    i_dbg_gpio_if.axi_wr_compl_bcd}; //18: 0
        12'h0B0 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    13'h0,                           //31:19
                    i_dbg_gpio_if.axi_rd_start_bcd}; //18: 0
        12'h0B4 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    13'h0,                           //31:19
                    i_dbg_gpio_if.axi_rd_compl_bcd}; //18: 0
        12'h0B8 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    13'h0,                      //31:19
                    i_dbg_gpio_if.f2a_req_bcd}; //18: 0
        12'h0BC : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    13'h0,                      //31:19
                    i_dbg_gpio_if.f2a_dat_bcd}; //18: 0
        12'h0C0 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    13'h0,                          //31:19
                    i_dbg_gpio_if.f2a_dat_emd_bcd}; //18: 0
        12'h0C4 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    13'h0,                      //31:19
                    i_dbg_gpio_if.a2f_rsp_bcd}; //18: 0
        12'h0C8 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    13'h0,                      //31:19
                    i_dbg_gpio_if.a2f_dat_bcd}; //18: 0
        12'h0CC : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    13'h0,                          //31:19
                    i_dbg_gpio_if.a2f_dat_emd_bcd}; //18: 0
        12'h0D0 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    20'h0,             //31:12
                    1'h0,              //11
                    final_cnt_freerun, //10
                    axil_cnt_freerun,  //9
                    dbg_cnt_freerun,   //8
                    1'h0,              //7
                    final_cnt_enable,  //6
                    axil_cnt_enable,   //5
                    dbg_cnt_enable,    //4
                    1'h0,              //3
                    final_cnt_reset,   //2
                    axil_cnt_reset,    //1
                    dbg_cnt_reset};    //0
        // -------------------------------------------------------- //
        /* WROB Status */
        // -------------------------------------------------------- //
        12'h100 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    {(32-AXI_IDS_SUPP){1'b0}}, //31:AXI_IDS_SUPP
                    wrob_mpty_vec};            //AXI_IDS_SUPP-1:0
        12'h104 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    {(32-AXI_IDS_SUPP){1'b0}}, //31:AXI_IDS_SUPP
                    wrob_ampty_vec};           //AXI_IDS_SUPP-1:0
        12'h108 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    {(32-AXI_IDS_SUPP){1'b0}}, //31:AXI_IDS_SUPP
                    wrob_full_vec};            //AXI_IDS_SUPP-1:0
        // -------------------------------------------------------- //
        /* RROB Status */
        // -------------------------------------------------------- //
        12'h200 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    {(32-AXI_IDS_SUPP){1'b0}}, //31:AXI_IDS_SUPP
                    rrob_mpty_vec};            //AXI_IDS_SUPP-1:0
        12'h204 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    {(32-AXI_IDS_SUPP){1'b0}}, //31:AXI_IDS_SUPP
                    rrob_ampty_vec};           //AXI_IDS_SUPP-1:0
        12'h208 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    {(32-AXI_IDS_SUPP){1'b0}}, //31:AXI_IDS_SUPP
                    rrob_full_vec};            //AXI_IDS_SUPP-1:0
        // -------------------------------------------------------- //
        /* Errors */
        // -------------------------------------------------------- //
        12'h300 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    24'h0,             //31:8
                    f2a_req_block_err, //7
                    f2a_dat_block_err, //6
                    a2f_dat_block_err, //5
                    a2f_rsp_block_err, //4
                    2'h0,              //3:2
                    a2f_rsp_id_err,    //1
                    a2f_dat_id_err};   //0
        // -------------------------------------------------------- //
        /* Status */
        // -------------------------------------------------------- //
        12'h400 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    20'h0,      //31:12    
                    2'h0,       //11:10
                    bready,     //9
                    bvalid,     //8
                    2'h0,       //7:6
                    wready,     //5
                    wvalid,     //4
                    2'h0,       //3:2
                    awready,    //1
                    awvalid};   //0
        12'h404 : {capture_rresp, capture_rdata} <= {
                    OKAY,
                    16'h0,          //31:16
                    2'h0,           //15:14
                    a2f_rsp_block,  //13
                    a2f_rsp_valid,  //12
                    2'h0,           //11:10
                    a2f_dat_block,  //9
                    a2f_dat_valid,  //8
                    2'h0,           //7:6
                    f2a_dat_block,  //5 
                    f2a_dat_valid,  //4
                    2'h0,           //3:2
                    f2a_req_block,  //1 
                    f2a_req_valid}; //0
        // -------------------------------------------------------- //
        /* Default Read Response */
        // -------------------------------------------------------- //
        default : {capture_rresp, capture_rdata} <= {
                    SLVERR,
                    32'hDEAD_DEAD};
      endcase
      // -------------------------------------------------------- //
      /* WROB/RROB Pointers : Issue and Complete */
      // -------------------------------------------------------- //
      // One set of registers per supported AXI ID: WROB issue pointer
      // starting at 12'h110, WROB complete pointer starting at 12'h150,
      // RROB issue pointer starting at 12'h210, RROB complete pointer
      // starting at 12'h250, all incrementing by 4 bytes; overrides the
      // case above on a match
      for (int id = 0; id < AXI_IDS_SUPP; id++) begin
        case (captured_araddr_d)
          12'h110 + id*4 : {capture_rresp, capture_rdata} <= {
                              OKAY,
                              15'h0,                     //31:17
                              wr_issue_wrap[id],         //16
                              {(16-WROB_PTR_W){1'b0}},   //15:WROB_PTR_W
                              wr_issue_wptr[id]};        //WROB_PTR_W-1:0
          12'h150 + id*4 : {capture_rresp, capture_rdata} <= {
                              OKAY,
                              15'h0,                     //31:17
                              wr_compl_wrap[id],         //16
                              {(16-WROB_PTR_W){1'b0}},   //15:WROB_PTR_W
                              wr_compl_rptr[id]};        //WROB_PTR_W-1:0
          12'h210 + id*4 : {capture_rresp, capture_rdata} <= {
                              OKAY,
                              15'h0,                     //31:17
                              rd_issue_wrap[id],         //16
                              {(16-RROB_PTR_W){1'b0}},   //15:RROB_PTR_W
                              rd_issue_wptr[id]};        //RROB_PTR_W-1:0
          12'h250 + id*4 : {capture_rresp, capture_rdata} <= {
                              OKAY,
                              15'h0,                     //31:17
                              rd_compl_wrap[id],         //16
                              {(16-RROB_PTR_W){1'b0}},   //15:RROB_PTR_W
                              rd_compl_rptr[id]};        //RROB_PTR_W-1:0
        endcase
      end
    end
    // Need to assert back to A that it can sample
    if (do_capture_rd_d)
      a2d_rack_d <= 1'b1;
    // Deassert ack when source has deasserted req
    else if (a2d_rreq_d_pulse)
      a2d_rack_d <= 1'b0;
  end

  // Read state machine - supports single outstanding read and crosses
  // clock domains from A2D for the req and D2A for the data
  always_ff @(posedge axil_clk) begin
    if (!axil_rstn) begin
      read_state      <= READ_IDLE;
      s_axil_rvalid   <= 1'b0;
      s_axil_arready  <= 1'b0;
      a2d_rreq_a      <= 1'b0;
    end 
    else begin
      case (read_state)
        READ_IDLE: 
          begin
            s_axil_arready <= 1'b1;
            if (ar_done) begin
              s_axil_arready    <= 1'b0;
              captured_araddr_a <= s_axil_araddr;
              read_state        <= READ_A2D;
              // Enhancement : hardcoded details e.g. parameters in regs, just
              //               respond natively and don't need to cross
              //               domains
              /*read_state        <= s_axil_araddr=='0 ? READ_PEND : READ_A2D;*/
            end
          end
        READ_A2D: 
          begin
            a2d_rreq_a <= 1'b1;
            if (a2d_rack_a) begin
              read_state <= READ_D2A;
            end
          end
        READ_D2A: 
          begin
            a2d_rreq_a <= 1'b0;
            if (!a2d_rack_a) 
              read_state <= READ_PEND;
          end
        READ_PEND:
          begin
            s_axil_rvalid <= 1'b1;
            {s_axil_rresp, s_axil_rdata} <= {capture_rresp, capture_rdata};
            // Enhancement : hardcoded details e.g. parameters in regs, just
            //               respond natively and don't need to cross
            //               domains
            /*case (captured_araddr_a)
              12'h000:          {s_axil_rresp, s_axil_rdata} <= {OKAY, <compile time value>};
              // Coming from C domain
              default:          {s_axil_rresp, s_axil_rdata} <= {capture_rresp, capture_rdata};
            endcase*/
            if (r_done) begin
              s_axil_rvalid <= 1'b0;
              read_state    <= READ_IDLE;
            end
          end
      endcase
    end
  end

  // Write state machine - supports single outstanding write and crosses
  // clock domains from A2D for the req and D2A for the response
  always_ff @(posedge axil_clk) begin
    if (!axil_rstn) begin
      write_state     <= WRITE_IDLE;
      s_axil_bvalid   <= 1'b0;
      s_axil_awready  <= 1'b0;
      s_axil_wready   <= 1'b0;
      a2d_wreq_a      <= 1'b0;
    end
    else begin
      case (write_state)
        WRITE_IDLE:
          begin
            s_axil_awready <= 1'b1;
            // Capture AW when it arrives
            if (aw_done) begin
              s_axil_awready    <= 1'b0;
              captured_awaddr_a <= s_axil_awaddr;
              write_state       <= WRITE_DATA;
            end
          end
        WRITE_DATA:
          begin
            s_axil_wready  <= 1'b1;
            // Capture W when it arrives
            if (w_done) begin
              s_axil_wready    <= 1'b0;
              captured_wdata_a <= s_axil_wdata;
              captured_wstrb_a <= s_axil_wstrb;
              write_state      <= WRITE_PEND;
              // Enhancement : hardcoded details e.g. parameters in regs, just
              //               respond natively and don't need to cross
              //               domains
              /*write_state      <= captured_awaddr_a inside {12'h0, 12'h4, 12'h8, 12'hC} ? 
                                    WRITE_PEND :
                                    WRITE_A2D;*/
                                                                                         
            end
          end
        WRITE_A2D:
          begin
            a2d_wreq_a <= 1'b1;
            if (a2d_wack_a) begin
              write_state <= WRITE_D2A;
            end
          end
        WRITE_D2A:
          begin
            a2d_wreq_a <= 1'b0;
            if (!a2d_wack_a)
              write_state <= WRITE_PEND;
          end
        WRITE_PEND:
          begin
            s_axil_bvalid <= 1'b1;
            s_axil_bresp  <= capture_bresp;
            // Enhancement : hardcoded details e.g. parameters in regs, just
            //               respond natively
            /*case (captured_awaddr_a)
              // hardcoded details
              12'h000, 12'h004, 12'h008, 12'h00C: s_axil_bresp <= OKAY;
              // Coming from destination domain
              default:                            s_axil_bresp <= capture_bresp;
            endcase*/
            if (b_done) begin
              s_axil_bvalid <= 1'b0;
              write_state   <= WRITE_IDLE;
            end
          end
      endcase
    end
  end

  `ifndef SYNTHESIS
  //synthesis off
  initial begin
    if (AXI_IDS_SUPP>16)
      $fatal(1, $sformatf("AXI_IDS_SUPP=%0d is above the max supported (16) in axi_cpi_bridge_reg_space", AXI_IDS_SUPP));
    if (WROB_PTR_W>16)
      $fatal(1, $sformatf("WROB_PTR_W=%0d is a above the max supported (16) in axi_cpi_bridge_reg_space", WROB_PTR_W));
    if (RROB_PTR_W>16)
      $fatal(1, $sformatf("RROB_PTR_W=%0d is a above the max supported (16) in axi_cpi_bridge_reg_space", RROB_PTR_W));
  end
  //synthesis on 
  `endif

endmodule
