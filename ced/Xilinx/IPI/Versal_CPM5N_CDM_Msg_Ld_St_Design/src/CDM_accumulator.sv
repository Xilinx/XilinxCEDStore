`timescale 1ps / 1ps

module CDM_accumulator #(
  parameter TCQ         = 1
)(
  // Global
  input logic                       user_clk,
  input logic                       user_reset_n,
  
  // Traffic Generator Side
  cdx5n_cmpt_msgst_if.s             fab0_cmpt_msgst_fab_int_tg,
  cdx5n_mm_byp_out_rsp_if.m         fab0_byp_out_msgld_dat_fab_int_tg,
  cdx5n_dsc_crd_in_msgld_req_if.s   fab0_dsc_crd_msgld_req_fab_int_tg,
  
  // CPM5N Side
  cdx5n_cmpt_msgst_if.m             fab0_cmpt_msgst_fab_int,
  cdx5n_mm_byp_out_rsp_if.s         fab0_byp_out_msgld_dat_fab_int,
  cdx5n_dsc_crd_in_msgld_req_if.m   fab0_dsc_crd_msgld_req_fab_int
);

cdx5n_cmpt_msgst_if             fab0_cmpt_msgst_fab_int_in()       , fab0_cmpt_msgst_fab_int_out();
cdx5n_mm_byp_out_rsp_if         fab0_byp_out_msgld_dat_fab_int_in(), fab0_byp_out_msgld_dat_fab_int_out();
cdx5n_dsc_crd_in_msgld_req_if   fab0_dsc_crd_msgld_req_fab_int_in(), fab0_dsc_crd_msgld_req_fab_int_out();

// Flatten Interface
logic [$bits(fab0_cmpt_msgst_fab_int_in.intf)-1:0]        msgst_intf;
logic [$bits(fab0_byp_out_msgld_dat_fab_int_in.intf)-1:0] msgld_dat_intf;
logic [$bits(fab0_dsc_crd_msgld_req_fab_int_in.intf)-1:0] msgld_req_intf;

logic msgst_fifo_empty, msgst_fifo_full;
logic msgld_fifo_empty, msgld_fifo_full;
logic msgldrsp_fifo_empty, msgldrsp_fifo_full;

assign fab0_cmpt_msgst_fab_int_in.intf        = fab0_cmpt_msgst_fab_int_tg.intf;
assign fab0_byp_out_msgld_dat_fab_int_in.intf = fab0_byp_out_msgld_dat_fab_int.intf;
assign fab0_dsc_crd_msgld_req_fab_int_in.intf = fab0_dsc_crd_msgld_req_fab_int_tg.intf;

assign fab0_cmpt_msgst_fab_int.intf        = fab0_cmpt_msgst_fab_int_out.intf;
assign fab0_byp_out_msgld_dat_fab_int_tg.intf    = fab0_byp_out_msgld_dat_fab_int_out.intf;
assign fab0_dsc_crd_msgld_req_fab_int.intf = fab0_dsc_crd_msgld_req_fab_int_out.intf;

assign msgst_intf     = fab0_cmpt_msgst_fab_int_in.intf;
assign msgld_dat_intf = fab0_byp_out_msgld_dat_fab_int_in.intf;
assign msgld_req_intf = fab0_dsc_crd_msgld_req_fab_int_in.intf;

   xpm_fifo_sync #(
      .CASCADE_HEIGHT(0),        // DECIMAL
      .DOUT_RESET_VALUE("0"),    // String
      .ECC_MODE("no_ecc"),       // String
      .FIFO_MEMORY_TYPE("auto"), // String
      .FIFO_READ_LATENCY(1),     // DECIMAL
      .FIFO_WRITE_DEPTH(128),    // DECIMAL
      .FULL_RESET_VALUE(0),      // DECIMAL
      .PROG_EMPTY_THRESH(10),    // DECIMAL
      .PROG_FULL_THRESH(10),     // DECIMAL
      .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
      .READ_DATA_WIDTH($bits(fab0_cmpt_msgst_fab_int_in.intf)),      // DECIMAL
      .READ_MODE("fwft"),        // String
      .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_ADV_FEATURES("1000"), // String
      .WAKEUP_TIME(0),           // DECIMAL
      .WRITE_DATA_WIDTH($bits(fab0_cmpt_msgst_fab_int_in.intf)),     // DECIMAL
      .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
   xpm_fifo_sync_msgst_inst (
      .almost_empty(),
      .almost_full(),
      .data_valid(fab0_cmpt_msgst_fab_int.vld),
      .dbiterr(),
      .dout(fab0_cmpt_msgst_fab_int_out.intf),
      .empty(msgst_fifo_empty),
      .full(msgst_fifo_full),
      .overflow(),
      .prog_empty(),
      .prog_full(),
      .rd_data_count(),
      .rd_rst_busy(),
      .sbiterr(),
      .underflow(),
      .wr_ack(),
      .wr_data_count(),
      .wr_rst_busy(),
      .din(fab0_cmpt_msgst_fab_int_in.intf),
      .injectdbiterr(1'b0),
      .injectsbiterr(1'b0),
      .rd_en(fab0_cmpt_msgst_fab_int.rdy & fab0_cmpt_msgst_fab_int.vld),
      .rst(~user_reset_n),
      .sleep(1'b0),
      .wr_clk(user_clk),
      .wr_en(fab0_cmpt_msgst_fab_int_tg.vld & fab0_cmpt_msgst_fab_int_tg.rdy)
   );
   
   assign fab0_cmpt_msgst_fab_int_tg.rdy = ~msgst_fifo_full;
   
   xpm_fifo_sync #(
      .CASCADE_HEIGHT(0),        // DECIMAL
      .DOUT_RESET_VALUE("0"),    // String
      .ECC_MODE("no_ecc"),       // String
      .FIFO_MEMORY_TYPE("auto"), // String
      .FIFO_READ_LATENCY(1),     // DECIMAL
      .FIFO_WRITE_DEPTH(128),    // DECIMAL
      .FULL_RESET_VALUE(0),      // DECIMAL
      .PROG_EMPTY_THRESH(10),    // DECIMAL
      .PROG_FULL_THRESH(10),     // DECIMAL
      .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
      .READ_DATA_WIDTH($bits(fab0_dsc_crd_msgld_req_fab_int_in.intf)),      // DECIMAL
      .READ_MODE("fwft"),        // String
      .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_ADV_FEATURES("1000"), // String
      .WAKEUP_TIME(0),           // DECIMAL
      .WRITE_DATA_WIDTH($bits(fab0_dsc_crd_msgld_req_fab_int_in.intf)),     // DECIMAL
      .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
   xpm_fifo_sync_msgld_inst (
      .almost_empty(),
      .almost_full(),
      .data_valid(fab0_dsc_crd_msgld_req_fab_int.vld),
      .dbiterr(),
      .dout(fab0_dsc_crd_msgld_req_fab_int_out.intf),
      .empty(msgld_fifo_empty),
      .full(msgld_fifo_full),
      .overflow(),
      .prog_empty(),
      .prog_full(),
      .rd_data_count(),
      .rd_rst_busy(),
      .sbiterr(),
      .underflow(),
      .wr_ack(),
      .wr_data_count(),
      .wr_rst_busy(),
      .din(fab0_dsc_crd_msgld_req_fab_int_in.intf),
      .injectdbiterr(1'b0),
      .injectsbiterr(1'b0),
      .rd_en(fab0_dsc_crd_msgld_req_fab_int.rdy & fab0_dsc_crd_msgld_req_fab_int.vld),
      .rst(~user_reset_n),
      .sleep(1'b0),
      .wr_clk(user_clk),
      .wr_en(fab0_dsc_crd_msgld_req_fab_int_tg.vld & fab0_dsc_crd_msgld_req_fab_int_tg.rdy)
   );
   
   assign fab0_dsc_crd_msgld_req_fab_int_tg.rdy = ~msgld_fifo_full;

   xpm_fifo_sync #(
      .CASCADE_HEIGHT(0),        // DECIMAL
      .DOUT_RESET_VALUE("0"),    // String
      .ECC_MODE("no_ecc"),       // String
      .FIFO_MEMORY_TYPE("auto"), // String
      .FIFO_READ_LATENCY(1),     // DECIMAL
      .FIFO_WRITE_DEPTH(128),    // DECIMAL
      .FULL_RESET_VALUE(0),      // DECIMAL
      .PROG_EMPTY_THRESH(10),    // DECIMAL
      .PROG_FULL_THRESH(10),     // DECIMAL
      .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
      .READ_DATA_WIDTH($bits(fab0_byp_out_msgld_dat_fab_int_in.intf)),      // DECIMAL
      .READ_MODE("fwft"),        // String
      .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_ADV_FEATURES("1000"), // String
      .WAKEUP_TIME(0),           // DECIMAL
      .WRITE_DATA_WIDTH($bits(fab0_byp_out_msgld_dat_fab_int_in.intf)),     // DECIMAL
      .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
   xpm_fifo_sync_msgldrsp_inst (
      .almost_empty(),
      .almost_full(),
      .data_valid(fab0_byp_out_msgld_dat_fab_int_tg.vld),
      .dbiterr(),
      .dout(fab0_byp_out_msgld_dat_fab_int_out.intf),
      .empty(msgldrsp_fifo_empty),
      .full(msgldrsp_fifo_full),
      .overflow(),
      .prog_empty(),
      .prog_full(),
      .rd_data_count(),
      .rd_rst_busy(),
      .sbiterr(),
      .underflow(),
      .wr_ack(),
      .wr_data_count(),
      .wr_rst_busy(),
      .din(fab0_byp_out_msgld_dat_fab_int_in.intf),
      .injectdbiterr(1'b0),
      .injectsbiterr(1'b0),
      .rd_en(fab0_byp_out_msgld_dat_fab_int_tg.rdy & fab0_byp_out_msgld_dat_fab_int_tg.vld),
      .rst(~user_reset_n),
      .sleep(1'b0),
      .wr_clk(user_clk),
      .wr_en(fab0_byp_out_msgld_dat_fab_int.vld & fab0_byp_out_msgld_dat_fab_int.rdy)
   );
   
   assign fab0_byp_out_msgld_dat_fab_int.rdy = ~msgldrsp_fifo_full;

endmodule
