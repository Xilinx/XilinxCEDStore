interface debug_axi_cpi_bridge; 

  localparam NUM_DEBUG = 10;
  localparam CNT_W     = $clog2(NUM_DEBUG);
  
  // Control
  logic cnt_reset;
  logic cnt_enable;
  logic cnt_freerun;
  // Count = 10
  // 16 bit counters -> max=65535 (19 BCD bits)
  logic [15:0] axi_wr_start_cnt; logic [18:0] axi_wr_start_bcd;
  logic [15:0] axi_wr_compl_cnt; logic [18:0] axi_wr_compl_bcd;
  logic [15:0] axi_rd_start_cnt; logic [18:0] axi_rd_start_bcd;
  logic [15:0] axi_rd_compl_cnt; logic [18:0] axi_rd_compl_bcd;
  logic [15:0] f2a_req_cnt;      logic [18:0] f2a_req_bcd;
  logic [15:0] f2a_dat_cnt;      logic [18:0] f2a_dat_bcd;
  logic [15:0] a2f_rsp_cnt;      logic [18:0] a2f_rsp_bcd;
  logic [15:0] a2f_dat_cnt;      logic [18:0] a2f_dat_bcd;
  logic [15:0] f2a_dat_emd_cnt;  logic [18:0] f2a_dat_emd_bcd;
  logic [15:0] a2f_dat_emd_cnt;  logic [18:0] a2f_dat_emd_bcd;

  modport master (
    input  cnt_reset, cnt_enable, cnt_freerun,
    output axi_wr_start_cnt, axi_wr_start_bcd,
           axi_wr_compl_cnt, axi_wr_compl_bcd,
           axi_rd_start_cnt, axi_rd_start_bcd,
           axi_rd_compl_cnt, axi_rd_compl_bcd,
           f2a_req_cnt,      f2a_req_bcd,
           f2a_dat_cnt,      f2a_dat_bcd,
           a2f_rsp_cnt,      a2f_rsp_bcd,
           a2f_dat_cnt,      a2f_dat_bcd,
           f2a_dat_emd_cnt,  f2a_dat_emd_bcd,
           a2f_dat_emd_cnt,  a2f_dat_emd_bcd
  );

  modport slave (
    output cnt_reset, cnt_enable, cnt_freerun,
    input axi_wr_start_cnt, axi_wr_start_bcd,
          axi_wr_compl_cnt, axi_wr_compl_bcd,
          axi_rd_start_cnt, axi_rd_start_bcd,
          axi_rd_compl_cnt, axi_rd_compl_bcd,
          f2a_req_cnt,      f2a_req_bcd,
          f2a_dat_cnt,      f2a_dat_bcd,
          a2f_rsp_cnt,      a2f_rsp_bcd,
          a2f_dat_cnt,      a2f_dat_bcd,
          f2a_dat_emd_cnt,  f2a_dat_emd_bcd,
          a2f_dat_emd_cnt,  a2f_dat_emd_bcd
  );

  modport monitor (
    input cnt_reset, cnt_enable, cnt_freerun,
          axi_wr_start_cnt, axi_wr_start_bcd,
          axi_wr_compl_cnt, axi_wr_compl_bcd,
          axi_rd_start_cnt, axi_rd_start_bcd,
          axi_rd_compl_cnt, axi_rd_compl_bcd,
          f2a_req_cnt,      f2a_req_bcd,
          f2a_dat_cnt,      f2a_dat_bcd,
          a2f_rsp_cnt,      a2f_rsp_bcd,
          a2f_dat_cnt,      a2f_dat_bcd,
          f2a_dat_emd_cnt,  f2a_dat_emd_bcd,
          a2f_dat_emd_cnt,  a2f_dat_emd_bcd
  );

endinterface
