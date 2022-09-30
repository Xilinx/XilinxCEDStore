// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
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
// ////////////////////////////////////////////////////////////////////////
`ifndef CPM5N_IF_SV
`define CPM5N_IF_SV 1

interface cpm5n_cxs1024_if();
  logic          cxs_active_ack_chk_rx;
  logic          cxs_active_ack_chk_tx;
  logic          cxs_active_ack_rx;
  logic          cxs_active_ack_tx;
  logic          cxs_active_req_chk_rx;
  logic          cxs_active_req_chk_tx;
  logic          cxs_active_req_rx;
  logic          cxs_active_req_tx;
  logic [5:0]    cxs_cntl_chk_rx;
  logic [5:0]    cxs_cntl_chk_tx;
  logic [43:0]   cxs_cntl_rx;
  logic [43:0]   cxs_cntl_tx;
  logic          cxs_crdgnt_chk_rx;
  logic          cxs_crdgnt_chk_tx;
  logic          cxs_crdgnt_rx;
  logic          cxs_crdgnt_tx;
  logic          cxs_crdrtn_chk_rx;
  logic          cxs_crdrtn_chk_tx;
  logic          cxs_crdrtn_rx;
  logic          cxs_crdrtn_tx;
  logic [127:0]  cxs_data_chk_rx;
  logic [127:0]  cxs_data_chk_tx;
  logic [1023:0] cxs_data_rx;
  logic [1023:0] cxs_data_tx;
  logic          cxs_deact_hint_rx;
  logic          cxs_deact_hint_tx;
  logic          cxs_valid_chk_rx;
  logic          cxs_valid_chk_tx;
  logic          cxs_valid_rx;
  logic          cxs_valid_tx;

  modport slave (
    output cxs_active_ack_chk_rx,
    input  cxs_active_ack_chk_tx,
    output cxs_active_ack_rx,
    input  cxs_active_ack_tx,
    input  cxs_active_req_chk_rx,
    output cxs_active_req_chk_tx,
    input  cxs_active_req_rx,
    output cxs_active_req_tx,
    input  cxs_cntl_chk_rx,
    output cxs_cntl_chk_tx,
    input  cxs_cntl_rx,
    output cxs_cntl_tx,
    output cxs_crdgnt_chk_rx,
    input  cxs_crdgnt_chk_tx,
    output cxs_crdgnt_rx,
    input  cxs_crdgnt_tx,
    input  cxs_crdrtn_chk_rx,
    output cxs_crdrtn_chk_tx,
    input  cxs_crdrtn_rx,
    output cxs_crdrtn_tx,
    input  cxs_data_chk_rx,
    output cxs_data_chk_tx,
    input  cxs_data_rx,
    output cxs_data_tx,
    output cxs_deact_hint_rx,
    input  cxs_deact_hint_tx,
    input  cxs_valid_chk_rx,
    output cxs_valid_chk_tx,
    input  cxs_valid_rx,
    output cxs_valid_tx
  );

  modport master (
    input  cxs_active_ack_chk_rx,
    output cxs_active_ack_chk_tx,
    input  cxs_active_ack_rx,
    output cxs_active_ack_tx,
    output cxs_active_req_chk_rx,
    input  cxs_active_req_chk_tx,
    output cxs_active_req_rx,
    input  cxs_active_req_tx,
    output cxs_cntl_chk_rx,
    input  cxs_cntl_chk_tx,
    output cxs_cntl_rx,
    input  cxs_cntl_tx,
    input  cxs_crdgnt_chk_rx,
    output cxs_crdgnt_chk_tx,
    input  cxs_crdgnt_rx,
    output cxs_crdgnt_tx,
    output cxs_crdrtn_chk_rx,
    input  cxs_crdrtn_chk_tx,
    output cxs_crdrtn_rx,
    input  cxs_crdrtn_tx,
    output cxs_data_chk_rx,
    input  cxs_data_chk_tx,
    output cxs_data_rx,
    input  cxs_data_tx,
    input  cxs_deact_hint_rx,
    output cxs_deact_hint_tx,
    output cxs_valid_chk_rx,
    input  cxs_valid_chk_tx,
    output cxs_valid_rx,
    input  cxs_valid_tx
  );

  modport snoop (

    input  cxs_active_req_rx,
    input  cxs_active_req_chk_rx,
    input  cxs_active_ack_rx,
    input  cxs_active_ack_chk_rx,
    input  cxs_deact_hint_rx,
    input  cxs_active_req_tx,
    input  cxs_active_req_chk_tx,
    input  cxs_active_ack_tx,
    input  cxs_active_ack_chk_tx,
    input  cxs_deact_hint_tx,
    input  cxs_data_rx,
    input  cxs_cntl_rx,
    input  cxs_valid_rx,
    input  cxs_crdgnt_rx,
    input  cxs_crdrtn_rx,
    input  cxs_data_chk_rx,
    input  cxs_cntl_chk_rx,
    input  cxs_valid_chk_rx,
    input  cxs_crdgnt_chk_rx,
    input  cxs_crdrtn_chk_rx,
    input  cxs_data_tx,
    input  cxs_cntl_tx,
    input  cxs_valid_tx,
    input  cxs_crdgnt_tx,
    input  cxs_crdrtn_tx,
    input  cxs_data_chk_tx,
    input  cxs_cntl_chk_tx,
    input  cxs_valid_chk_tx,
    input  cxs_crdgnt_chk_tx,
    input  cxs_crdrtn_chk_tx
  );
endinterface : cpm5n_cxs1024_if

interface cpm5n_pl_cxscxl23_iomux_if;

  logic [1023:0] cxl_rx_data;
  logic [31:0]  cxl_rx_crc;
  logic [143:0] cxl_rx_parity;
  logic [2:0]   cxl_rx_valid;
  logic [2:0]   cxl_rx_viral;
  logic [2:0]   cxl_rx_all_data_flit;

  logic [1023:0] cxl_tx_data;
  logic [31:0]  cxl_tx_crc;
  logic [143:0] cxl_tx_parity;
  logic [2:0]   cxl_tx_valid;
  logic [5:0]   cxl_tx_ready;
  logic [2:0]   cxl_tx_viral;
  logic [2:0]   cxl_tx_all_data_flit;
  logic [3:0]   cxl_crd_resp_mem;
  logic         cxl_crd_resp_mem_vld;
  logic [3:0]   cxl_crd_data_mem;
  logic         cxl_crd_data_mem_vld;
  logic [3:0]   cxl_crd_req_mem;
  logic         cxl_crd_req_mem_vld;
  logic [3:0]   cxl_crd_resp_cache;
  logic         cxl_crd_resp_cache_vld;
  logic [3:0]   cxl_crd_data_cache;
  logic         cxl_crd_data_cache_vld;
  logic [3:0]   cxl_crd_req_cache;
  logic         cxl_crd_req_cache_vld;
  logic         cxl_pm_l1_enable;
  logic         cxl_pm_mem_recovery;
  logic         cxl_pm_mem_link_down;
  logic         cxl_reset;
  modport m (
    output cxl_rx_data,
    output cxl_rx_crc,
    output cxl_rx_parity,
    output cxl_rx_valid,
    output cxl_rx_viral,
    output cxl_rx_all_data_flit,
    input  cxl_tx_data,
    input  cxl_tx_crc,
    input  cxl_tx_parity,
    input  cxl_tx_valid,
    output cxl_tx_ready,

    input  cxl_tx_viral,
    input  cxl_tx_all_data_flit,
    input  cxl_crd_resp_mem,
    input  cxl_crd_resp_mem_vld,
    input  cxl_crd_data_mem,
    input  cxl_crd_data_mem_vld,
    input  cxl_crd_req_mem,
    input  cxl_crd_req_mem_vld,
    input  cxl_crd_resp_cache,
    input  cxl_crd_resp_cache_vld,
    input  cxl_crd_data_cache,
    input  cxl_crd_data_cache_vld,
    input  cxl_crd_req_cache,
    input  cxl_crd_req_cache_vld,
    input  cxl_pm_l1_enable,
    input  cxl_pm_mem_recovery,
    input  cxl_pm_mem_link_down,
    output cxl_reset
  );

  modport s (
    input  cxl_rx_data,
    input  cxl_rx_crc,
    input  cxl_rx_parity,
    input  cxl_rx_valid,
    input  cxl_rx_viral,
    input  cxl_rx_all_data_flit,

    output cxl_tx_data,
    output cxl_tx_crc,
    output cxl_tx_parity,
    output cxl_tx_valid,
    input  cxl_tx_ready,
    output cxl_tx_viral,
    output cxl_tx_all_data_flit,

    output cxl_crd_resp_mem,
    output cxl_crd_resp_mem_vld,
    output cxl_crd_data_mem,
    output cxl_crd_data_mem_vld,
    output cxl_crd_req_mem,
    output cxl_crd_req_mem_vld,
    output cxl_crd_resp_cache,
    output cxl_crd_resp_cache_vld,
    output cxl_crd_data_cache,
    output cxl_crd_data_cache_vld,
    output cxl_crd_req_cache,
    output cxl_crd_req_cache_vld,
    output cxl_pm_l1_enable,
    output cxl_pm_mem_recovery,
    output cxl_pm_mem_link_down,
    input  cxl_reset
  );

endinterface: cpm5n_pl_cxscxl23_iomux_if

interface cpm5n_pl_cxscxl_iomux_if;
  logic [1535:0] cxl_rx_data;
  logic [50:0]  cxl_rx_crc;
  logic [215:0] cxl_rx_parity;
  logic [2:0]   cxl_rx_valid;
  logic [2:0]   cxl_rx_viral;
  logic [2:0]   cxl_rx_all_data_flit;
  logic [1535:0] cxl_tx_data;
  logic [50:0]  cxl_tx_crc;
  logic [215:0] cxl_tx_parity;
  logic [2:0]   cxl_tx_valid;
  logic [5:0]   cxl_tx_ready;
  logic [2:0]   cxl_tx_viral;
  logic [2:0]   cxl_tx_all_data_flit;
  logic [3:0]   cxl_crd_resp_mem;
  logic         cxl_crd_resp_mem_vld;
  logic [3:0]   cxl_crd_data_mem;
  logic         cxl_crd_data_mem_vld;
  logic [3:0]   cxl_crd_req_mem;
  logic         cxl_crd_req_mem_vld;
  logic [3:0]   cxl_crd_resp_cache;
  logic         cxl_crd_resp_cache_vld;
  logic [3:0]   cxl_crd_data_cache;
  logic         cxl_crd_data_cache_vld;
  logic [3:0]   cxl_crd_req_cache;
  logic         cxl_crd_req_cache_vld;
  logic         cxl_pm_l1_enable;
  logic         cxl_pm_mem_recovery;
  logic         cxl_pm_mem_link_down;
  logic         cxl_reset;

  modport m (
    output cxl_rx_data,
    output cxl_rx_crc,
    output cxl_rx_parity,
    output cxl_rx_valid,
    output cxl_rx_viral,
    output cxl_rx_all_data_flit,
    input  cxl_tx_data,
    input  cxl_tx_crc,
    input  cxl_tx_parity,
    input  cxl_tx_valid,
    output cxl_tx_ready,
    input  cxl_tx_viral,
    input  cxl_tx_all_data_flit,
    input  cxl_crd_resp_mem,
    input  cxl_crd_resp_mem_vld,
    input  cxl_crd_data_mem,
    input  cxl_crd_data_mem_vld,
    input  cxl_crd_req_mem,
    input  cxl_crd_req_mem_vld,
    input  cxl_crd_resp_cache,
    input  cxl_crd_resp_cache_vld,
    input  cxl_crd_data_cache,
    input  cxl_crd_data_cache_vld,
    input  cxl_crd_req_cache,
    input  cxl_crd_req_cache_vld,
    input  cxl_pm_l1_enable,
    input  cxl_pm_mem_recovery,
    input  cxl_pm_mem_link_down,
    output cxl_reset
  );

  modport s (
    input  cxl_rx_data,
    input  cxl_rx_crc,
    input  cxl_rx_parity,
    input  cxl_rx_valid,
    input  cxl_rx_viral,
    input  cxl_rx_all_data_flit,
    output cxl_tx_data,
    output cxl_tx_crc,
    output cxl_tx_parity,
    output cxl_tx_valid,
    input  cxl_tx_ready,
    output cxl_tx_viral,
    output cxl_tx_all_data_flit,
    output cxl_crd_resp_mem,
    output cxl_crd_resp_mem_vld,
    output cxl_crd_data_mem,
    output cxl_crd_data_mem_vld,
    output cxl_crd_req_mem,
    output cxl_crd_req_mem_vld,
    output cxl_crd_resp_cache,
    output cxl_crd_resp_cache_vld,
    output cxl_crd_data_cache,
    output cxl_crd_data_cache_vld,
    output cxl_crd_req_cache,
    output cxl_crd_req_cache_vld,
    output cxl_pm_l1_enable,
    output cxl_pm_mem_recovery,
    output cxl_pm_mem_link_down,
    input  cxl_reset
  );

endinterface: cpm5n_pl_cxscxl_iomux_if

interface cpm5n_pl_dpu_cdx_pinmux_if();

  logic [998:0] in;
  logic [841:0] out;

  modport slave (
    input  out,
    output in
  );

  modport master (
    output out,
    input  in
  );

endinterface : cpm5n_pl_dpu_cdx_pinmux_if

interface cpm5n_pl_mpiobot_if();
  logic [5592:0] in;
  logic [4058:0] out;

  modport slave (
    input  out,
    output in
  );

  modport master (
    output out,
    input  in
  );
endinterface : cpm5n_pl_mpiobot_if

interface cpm5n_pl_mpiotop_if();
  logic [5764:0] in;
  logic [4334:0] out;

  modport slave (
    input  out,
    output in
  );

  modport master (
    output out,
    input  in
  );
endinterface : cpm5n_pl_mpiotop_if

interface cpm5n_pl_pcie23_axi_if();
  logic [511:0] axis_cq_tdata;
  logic [1:0]   axis_cq_tlast;// double
  logic [1:0]   axis_rc_tlast;
  logic [15:0]  axis_cq_tkeep;
  logic [29:0]  pcie_axis_cq_ready;
  logic [29:0]  pcie_axis_rc_ready;
  logic [1:0]   pcie_axis_cq_vld;//double
  logic [1:0]   pcie_axis_rc_vld;//double
  logic [1:0]   pcie_axis_cq_rts;//double
  logic [1:0]   pcie_axis_rc_rts;//double
  logic [284:0] axis_cq_tuser;
  logic [511:0] axis_cc_tdata;
  logic [1:0]   axis_cc_tlast;//double
  logic [15:0]  axis_cc_tkeep;
  logic [1:0]   axis_cc_tvalid;//double
  logic [7:0]   axis_cc_tready;
  logic [134:0] axis_cc_tuser;
  logic [511:0] axis_rq_tdata;
  logic [1:0]   axis_rq_tlast;//double
  logic [15:0]  axis_rq_tkeep;
  logic [1:0]   axis_rq_tvalid;//double
  logic [7:0]   axis_rq_tready;
  logic [222:0] axis_rq_tuser;
  logic [2:0]   pcie_cq_np_req;
  logic [15:0]  pcie_cq_np_req_count;//double
  logic [79:0]  pcie_rq_tag;
  logic [7:0]   pcie_rq_tag_vld;
  logic [15:0]  pcie_rq_seq_num0;//double
  logic [15:0]  pcie_rq_seq_num1;//double
  logic [15:0]  pcie_rq_seq_num2;//double
  logic [15:0]  pcie_rq_seq_num3;//double
  logic [7:0]   pcie_rq_seq_num_vld;//double
  logic [15:0]  pcie_tfc_nph_av;//double
  logic [15:0]  pcie_tfc_npd_av;//double
  logic [15:0]  pcie_rq_tag_av;//double
  logic [ 3:0]  cfg_ptm_spare_in;
  logic [ 3:0]  cfg_ptm_spare_out;
  logic [ 1:0]  cfg_ide_transit_to_insecure;
  logic [27:0]  cfg_msix_int_tph_data_in;
  logic [27:0]  cfg_msix_int_tph_data_out;
  logic [ 3:0]  cfg_cxl_pm_credit_avail;
  logic [7:0]   cfg_vlsm_io;
  logic [7:0]   cfg_vlsm_cachemem;
  logic [1:0]   cfg_wrreq_flr_vld;
  logic [1:0]   cfg_wrreq_msi_vld;
  logic [1:0]   cfg_wrreq_msix_vld;
  logic [1:0]   cfg_wrreq_bme_vld;
  logic [1:0]   cfg_wrreq_vfe_vld;
  logic [31:0]  cfg_wrreq_func_num;
  logic [ 7:0]  cfg_wrreq_out_value;
  logic [47:0]  cfg_perfunc_out;
  logic [1:0]   cfg_perfunc_vld;
  logic [31:0]  cfg_perfunc_func_num;
  logic [1:0]   cfg_perfunc_req;
  logic [19:0]  cfg_mgmt_addr;
  logic [31:0]  cfg_mgmt_function_number;
  logic [1:0]   cfg_mgmt_write;
  logic [63:0]  cfg_mgmt_write_data;
  logic [7:0]   cfg_mgmt_byte_enable;
  logic [1:0]   cfg_mgmt_read;
  logic [63:0]  cfg_mgmt_read_data;
  logic [1:0]   cfg_mgmt_read_write_done;
  logic [1:0]   cfg_mgmt_debug_access;
  logic [1:0]   cfg_phy_link_down;
  logic [3:0]   cfg_phy_link_status;
  logic [5:0]   cfg_negotiated_width;
  logic [5:0]   cfg_current_speed;
  logic [3:0]   cfg_max_payload;
  logic [5:0]   cfg_max_read_req;
  logic [7:0]   cfg_function_status;
  logic [5:0]   cfg_function_power_state;
  logic [3:0]   cfg_link_power_state;
  logic [1:0]   cfg_err_cor_out;
  logic [1:0]   cfg_err_nonfatal_out;
  logic [1:0]   cfg_err_fatal_out;
  logic [1:0]   cfg_local_error_valid;
  logic [11:0]  cfg_local_error_out;
  logic [11:0]  cfg_ltssm_state;
  logic [3:0]   cfg_rx_pm_state;
  logic [3:0]   cfg_tx_pm_state;
  logic [1:0]   cfg_rcb_status;
  logic [1:0]   cfg_atomic_requester_enable;
  logic [1:0]   cfg_10b_tag_requester_enable;
  logic [1:0]   cfg_pl_status_change;
  logic [1:0]   cfg_ext_tag_enable;
  logic [1:0]   cfg_vc1_enable;
  logic [1:0]   cfg_vc1_negotiation_pending;
  logic [1:0]   cfg_msg_received;
  logic [15:0]  cfg_msg_received_data;
  logic [9:0]   cfg_msg_received_type;
  logic [1:0]   cfg_msg_transmit;
  logic [5:0]   cfg_msg_transmit_type;
  logic [63:0]  cfg_msg_transmit_data;
  logic [1:0]   cfg_msg_transmit_done;
  logic [23:0]  cfg_fc_ph;
  logic [3:0]   cfg_fc_ph_scale;
  logic [31:0]  cfg_fc_pd;
  logic [3:0]   cfg_fc_pd_scale;
  logic [23:0]  cfg_fc_nph;
  logic [3:0]   cfg_fc_nph_scale;
  logic [31:0]  cfg_fc_npd;
  logic [3:0]   cfg_fc_npd_scale;
  logic [23:0]  cfg_fc_cplh;
  logic [3:0]   cfg_fc_cplh_scale;
  logic [31:0]  cfg_fc_cpld;
  logic [3:0]   cfg_fc_cpld_scale;
  logic [5:0]   cfg_fc_sel;
  logic [1:0]   cfg_fc_vc_sel;
  logic [1:0]   cfg_hot_reset_in;
  logic [1:0]   cfg_hot_reset_out;

  logic [15:0]  cfg_bus_number;
  logic [1:0]   cfg_power_state_change_ack;
  logic [1:0]   cfg_power_state_change_interrupt;
  logic [1:0]   cfg_err_cor_in;
  logic [1:0]   cfg_err_uncor_in;
  logic [1:0]   cfg_flr_done;
  logic [31:0]  cfg_flr_done_func_num;
  logic [7:0]   cfg_interrupt_int;
  logic [1:0]   cfg_interrupt_sent;
  logic [63:0]  cfg_interrupt_pending;
  logic [1:0]   cfg_interrupt_msi_enable;
  logic [63:0]  cfg_interrupt_msi_int;
  logic [1:0]   cfg_interrupt_msi_sent;
  logic [1:0]   cfg_interrupt_msi_fail;
  logic [5:0]   cfg_interrupt_msi_mmenable;
  logic [63:0]  cfg_interrupt_msi_pending_status;
  logic [9:0]   cfg_interrupt_msi_pending_status_function_num;
  logic [1:0]   cfg_interrupt_msi_pending_status_data_enable;
  logic [1:0]   cfg_interrupt_msi_mask_update;
  logic [9:0]   cfg_interrupt_msi_select;
  logic [63:0]  cfg_interrupt_msi_data;
  logic [1:0]   cfg_interrupt_msix_enable;
  logic [1:0]   cfg_interrupt_msix_mask;
  logic [127:0] cfg_interrupt_msix_address;
  logic [63:0]  cfg_interrupt_msix_data;
  logic [1:0]   cfg_interrupt_msix_int;
  logic [3:0]   cfg_interrupt_msix_vec_pending;
  logic [1:0]   cfg_interrupt_msix_vec_pending_status;
  logic [31:0]  cfg_interrupt_msix_ld_id;
  logic [1:0]   cfg_interrupt_msix_ld_id_valid;
  logic [1:0]   cfg_interrupt_msix_ide_valid;
  logic [1:0]   cfg_interrupt_msix_tbit;

  logic [5:0]   cfg_interrupt_msi_attr;
  logic [1:0]   cfg_interrupt_msi_tph_present;
  logic [3:0]   cfg_interrupt_msi_tph_type;
  logic [15:0]  cfg_interrupt_msi_tph_st_tag;
  logic [31:0]  cfg_interrupt_msi_function_number;
  logic [1:0]   cfg_ext_read_received;
  logic [1:0]   cfg_ext_write_received;
  logic [19:0]  cfg_ext_register_number;
  logic [31:0]  cfg_ext_function_number;
  logic [63:0]  cfg_ext_write_data;
  logic [7:0]   cfg_ext_write_byte_enable;
  logic [63:0]  cfg_ext_read_data;
  logic [1:0]   cfg_ext_read_data_valid;
  logic [5:0]   cfg_ext_compl_status;
  logic [1:0]   cfg_ext_send_completion;
  logic [1:0]   cfg_ext_adv_swt_access;
  logic [63:0]  cfg_ext_read_debug1;
  logic [63:0]  cfg_ext_write_debug1;
  logic [1:0]   cfg_ccix_edr_data_rate_change_req;
  logic [1:0]   cfg_ccix_edr_data_rate_change_ack;
  logic [1:0]   cfg_edr_enable;
  logic [1:0]   cfg_pasid_enable;
  logic [1:0]   cfg_pasid_exec_permission_enable;
  logic [1:0]   cfg_pasid_privil_mode_enable;
  logic [31:0]  spare_outputs;
  logic [31:0]  spare_inputs;

  modport s(

    input  axis_cq_tdata,
    input  axis_cq_tlast,
    input  axis_rc_tlast,
    input  axis_cq_tkeep,
    output pcie_axis_cq_ready,
    output pcie_axis_rc_ready,
    input  pcie_axis_cq_vld,
    input  pcie_axis_rc_vld,
    output pcie_axis_cq_rts,
    output pcie_axis_rc_rts,
    input  axis_cq_tuser,

    output axis_cc_tdata,
    output axis_cc_tlast,
    output axis_cc_tkeep,
    output axis_cc_tvalid,
    input  axis_cc_tready,
    output axis_cc_tuser,
    output axis_rq_tdata,
    output axis_rq_tlast,
    output axis_rq_tkeep,
    output axis_rq_tvalid,
    input  axis_rq_tready,
    output axis_rq_tuser,
    output pcie_cq_np_req,
    input  pcie_cq_np_req_count,

    input  pcie_rq_tag,
    input  pcie_rq_tag_vld,

    input  pcie_rq_seq_num0,
    input  pcie_rq_seq_num1,
    input  pcie_rq_seq_num2,
    input  pcie_rq_seq_num3,
    input  pcie_rq_seq_num_vld,

    input  pcie_tfc_nph_av,
    input  pcie_tfc_npd_av,
    input  pcie_rq_tag_av,
    output cfg_ptm_spare_in,
    input  cfg_ptm_spare_out,
    input  cfg_ide_transit_to_insecure,
    output cfg_msix_int_tph_data_in,
    input  cfg_msix_int_tph_data_out,
    input  cfg_cxl_pm_credit_avail,
    input  cfg_vlsm_io,
    input  cfg_vlsm_cachemem,
    input  cfg_wrreq_flr_vld,
    input  cfg_wrreq_msi_vld,
    input  cfg_wrreq_msix_vld,
    input  cfg_wrreq_bme_vld,
    input  cfg_wrreq_vfe_vld,
    input  cfg_wrreq_func_num,
    input  cfg_wrreq_out_value,
    input  cfg_perfunc_out,
    input  cfg_perfunc_vld,
    output cfg_perfunc_func_num,
    output cfg_perfunc_req,
    output cfg_mgmt_addr,
    output cfg_mgmt_function_number,
    output cfg_mgmt_write,
    output cfg_mgmt_write_data,
    output cfg_mgmt_byte_enable,
    output cfg_mgmt_read,
    input  cfg_mgmt_read_data,
    input  cfg_mgmt_read_write_done,
    output cfg_mgmt_debug_access,
    input  cfg_phy_link_down,
    input  cfg_phy_link_status,
    input  cfg_negotiated_width,
    input  cfg_current_speed,
    input  cfg_max_payload,
    input  cfg_max_read_req,
    input  cfg_function_status,
    input  cfg_function_power_state,
    input  cfg_link_power_state,
    input  cfg_err_cor_out,
    input  cfg_err_nonfatal_out,
    input  cfg_err_fatal_out,
    input  cfg_local_error_valid,
    input  cfg_local_error_out,
    input  cfg_ltssm_state,
    input  cfg_rx_pm_state,
    input  cfg_tx_pm_state,
    input  cfg_rcb_status,
    input  cfg_atomic_requester_enable,
    input  cfg_10b_tag_requester_enable,
    input  cfg_pl_status_change,
    input  cfg_ext_tag_enable,
    input  cfg_vc1_enable,
    input  cfg_vc1_negotiation_pending,
    input  cfg_msg_received,
    input  cfg_msg_received_data,
    input  cfg_msg_received_type,
    output cfg_msg_transmit,
    output cfg_msg_transmit_type,
    output cfg_msg_transmit_data,
    input  cfg_msg_transmit_done,
    input  cfg_fc_ph,
    input  cfg_fc_ph_scale,
    input  cfg_fc_pd,
    input  cfg_fc_pd_scale,
    input  cfg_fc_nph,
    input  cfg_fc_nph_scale,
    input  cfg_fc_npd,
    input  cfg_fc_npd_scale,
    input  cfg_fc_cplh,
    input  cfg_fc_cplh_scale,
    input  cfg_fc_cpld,
    input  cfg_fc_cpld_scale,
    output cfg_fc_sel,
    output cfg_fc_vc_sel,
    output cfg_hot_reset_in,
    input  cfg_hot_reset_out,
    input  cfg_bus_number,
    output cfg_power_state_change_ack,
    input  cfg_power_state_change_interrupt,
    output cfg_err_cor_in,
    output cfg_err_uncor_in,
    output cfg_flr_done,
    output cfg_flr_done_func_num,
    output cfg_interrupt_int,
    input  cfg_interrupt_sent,
    output cfg_interrupt_pending,
    input  cfg_interrupt_msi_enable,
    output cfg_interrupt_msi_int,
    input  cfg_interrupt_msi_sent,
    input  cfg_interrupt_msi_fail,
    input  cfg_interrupt_msi_mmenable,
    output cfg_interrupt_msi_pending_status,
    output cfg_interrupt_msi_pending_status_function_num,
    output cfg_interrupt_msi_pending_status_data_enable,
    input  cfg_interrupt_msi_mask_update,
    output cfg_interrupt_msi_select,
    input  cfg_interrupt_msi_data,
    input  cfg_interrupt_msix_enable,
    input  cfg_interrupt_msix_mask,
    output cfg_interrupt_msix_address,
    output cfg_interrupt_msix_data,
    output cfg_interrupt_msix_int,
    output cfg_interrupt_msix_vec_pending,
    input  cfg_interrupt_msix_vec_pending_status,
    output cfg_interrupt_msix_ld_id,
    output cfg_interrupt_msix_ld_id_valid,
    output cfg_interrupt_msix_ide_valid,
    output cfg_interrupt_msix_tbit,
    output cfg_interrupt_msi_attr,
    output cfg_interrupt_msi_tph_present,
    output cfg_interrupt_msi_tph_type,
    output cfg_interrupt_msi_tph_st_tag,
    output cfg_interrupt_msi_function_number,
    input  cfg_ext_read_received,
    input  cfg_ext_write_received,
    input  cfg_ext_register_number,
    input  cfg_ext_function_number,
    input  cfg_ext_write_data,
    input  cfg_ext_write_byte_enable,
    output cfg_ext_read_data,
    output cfg_ext_read_data_valid,
    output cfg_ext_send_completion,
    output cfg_ext_compl_status,
    input  cfg_ext_adv_swt_access,
    output cfg_ext_read_debug1,
    input  cfg_ext_write_debug1,
    input  cfg_ccix_edr_data_rate_change_req,
    output cfg_ccix_edr_data_rate_change_ack,
    input  cfg_edr_enable,
    input  cfg_pasid_enable,
    input  cfg_pasid_exec_permission_enable,
    input  cfg_pasid_privil_mode_enable,
    input  spare_outputs,
    output spare_inputs
  );

  modport m (
    output axis_cq_tdata,
    output axis_cq_tlast,
    output axis_rc_tlast,
    output axis_cq_tkeep,
    input  pcie_axis_cq_ready,
    input  pcie_axis_rc_ready,
    output pcie_axis_cq_vld,
    output pcie_axis_rc_vld,
    input  pcie_axis_cq_rts,
    input  pcie_axis_rc_rts,
    output axis_cq_tuser,

    input  axis_cc_tdata,
    input  axis_cc_tlast,
    input  axis_cc_tkeep,
    input  axis_cc_tvalid,
    output axis_cc_tready,
    input  axis_cc_tuser,

    input  axis_rq_tdata,
    input  axis_rq_tlast,
    input  axis_rq_tkeep,
    input  axis_rq_tvalid,
    input  axis_rq_tuser,
    output axis_rq_tready,

    input  pcie_cq_np_req,
    output pcie_cq_np_req_count,

    output pcie_rq_tag,
    output pcie_rq_tag_vld,

    output pcie_rq_seq_num0,
    output pcie_rq_seq_num1,
    output pcie_rq_seq_num2,
    output pcie_rq_seq_num3,
    output pcie_rq_seq_num_vld,

    output pcie_tfc_nph_av,
    output pcie_tfc_npd_av,
    output pcie_rq_tag_av,

    input  cfg_ptm_spare_in,
    output cfg_ptm_spare_out,
    output cfg_ide_transit_to_insecure,
    input  cfg_msix_int_tph_data_in,
    output cfg_msix_int_tph_data_out,
    output cfg_cxl_pm_credit_avail,
    output cfg_vlsm_io,
    output cfg_vlsm_cachemem,
    output cfg_wrreq_flr_vld,
    output cfg_wrreq_msi_vld,
    output cfg_wrreq_msix_vld,
    output cfg_wrreq_bme_vld,
    output cfg_wrreq_vfe_vld,
    output cfg_wrreq_func_num,
    output cfg_wrreq_out_value,
    output cfg_perfunc_out,
    output cfg_perfunc_vld,
    input  cfg_perfunc_func_num,
    input  cfg_perfunc_req,
    input  cfg_mgmt_addr,
    input  cfg_mgmt_function_number,
    input  cfg_mgmt_write,
    input  cfg_mgmt_write_data,
    input  cfg_mgmt_byte_enable,
    input  cfg_mgmt_read,
    output cfg_mgmt_read_data,
    output cfg_mgmt_read_write_done,
    input  cfg_mgmt_debug_access,
    output cfg_phy_link_down,
    output cfg_phy_link_status,
    output cfg_negotiated_width,
    output cfg_current_speed,
    output cfg_max_payload,
    output cfg_max_read_req,
    output cfg_function_status,
    output cfg_function_power_state,
    output cfg_link_power_state,
    output cfg_err_cor_out,
    output cfg_err_nonfatal_out,
    output cfg_err_fatal_out,
    output cfg_local_error_valid,
    output cfg_local_error_out,
    output cfg_ltssm_state,
    output cfg_rx_pm_state,
    output cfg_tx_pm_state,
    output cfg_rcb_status,
    output cfg_atomic_requester_enable,
    output cfg_10b_tag_requester_enable,
    output cfg_pl_status_change,
    output cfg_ext_tag_enable,
    output cfg_vc1_enable,
    output cfg_vc1_negotiation_pending,
    output cfg_msg_received,
    output cfg_msg_received_data,
    output cfg_msg_received_type,
    input  cfg_msg_transmit,
    input  cfg_msg_transmit_type,
    input  cfg_msg_transmit_data,
    output cfg_msg_transmit_done,
    output cfg_fc_ph,
    output cfg_fc_ph_scale,
    output cfg_fc_pd,
    output cfg_fc_pd_scale,
    output cfg_fc_nph,
    output cfg_fc_nph_scale,
    output cfg_fc_npd,
    output cfg_fc_npd_scale,
    output cfg_fc_cplh,
    output cfg_fc_cplh_scale,
    output cfg_fc_cpld,
    output cfg_fc_cpld_scale,
    input  cfg_fc_sel,
    input  cfg_fc_vc_sel,
    input  cfg_hot_reset_in,
    output cfg_hot_reset_out,
    output cfg_bus_number,
    input  cfg_power_state_change_ack,
    output cfg_power_state_change_interrupt,
    input  cfg_err_cor_in,
    input  cfg_err_uncor_in,
    input  cfg_flr_done,
    input  cfg_flr_done_func_num,
    input  cfg_interrupt_int,
    output cfg_interrupt_sent,
    input  cfg_interrupt_pending,
    output cfg_interrupt_msi_enable,
    input  cfg_interrupt_msi_int,
    output cfg_interrupt_msi_sent,
    output cfg_interrupt_msi_fail,
    output cfg_interrupt_msi_mmenable,
    input  cfg_interrupt_msi_pending_status,
    input  cfg_interrupt_msi_pending_status_function_num,
    input  cfg_interrupt_msi_pending_status_data_enable,
    output cfg_interrupt_msi_mask_update,
    input  cfg_interrupt_msi_select,
    output cfg_interrupt_msi_data,
    output cfg_interrupt_msix_enable,
    output cfg_interrupt_msix_mask,
    input  cfg_interrupt_msix_address,
    input  cfg_interrupt_msix_data,
    input  cfg_interrupt_msix_int,
    input  cfg_interrupt_msix_vec_pending,
    output cfg_interrupt_msix_vec_pending_status,
    input  cfg_interrupt_msix_ld_id,
    input  cfg_interrupt_msix_ld_id_valid,
    input  cfg_interrupt_msix_ide_valid,
    input  cfg_interrupt_msix_tbit,
    input  cfg_interrupt_msi_attr,
    input  cfg_interrupt_msi_tph_present,
    input  cfg_interrupt_msi_tph_type,
    input  cfg_interrupt_msi_tph_st_tag,
    input  cfg_interrupt_msi_function_number,
    output cfg_ext_read_received,
    output cfg_ext_write_received,
    output cfg_ext_register_number,
    output cfg_ext_function_number,
    output cfg_ext_write_data,
    output cfg_ext_write_byte_enable,
    input  cfg_ext_read_data,
    input  cfg_ext_read_data_valid,
    input  cfg_ext_send_completion,
    input  cfg_ext_compl_status,
    output cfg_ext_adv_swt_access,
    input  cfg_ext_read_debug1,
    output cfg_ext_write_debug1,
    output cfg_ccix_edr_data_rate_change_req,
    input  cfg_ccix_edr_data_rate_change_ack,
    output cfg_edr_enable,
    output cfg_pasid_enable,
    output cfg_pasid_exec_permission_enable,
    output cfg_pasid_privil_mode_enable,
    output spare_outputs,
    input  spare_inputs
  );
endinterface : cpm5n_pl_pcie23_axi_if

interface cpm5n_pl_pcie_axi_if();

  logic [1023:0] axis_cq_tdata;      // External Output Flops Needed
  logic         axis_cq_tlast;      // External Output Flop Needed
  logic         axis_rc_tlast;      // External Output Flop Needed
  logic [31:0]  axis_cq_tkeep;      // External Output Flops Needed
  logic [59:0]  pcie_axis_cq_ready; // There should be No Input Flops on these inputs,
  logic [59:0]  pcie_axis_rc_ready; // There should be No Input Flops on these inputs,
  logic         pcie_axis_cq_vld;   // External Output Flop is Needed
  logic         pcie_axis_rc_vld;   // External Output Flop is Needed
  logic         pcie_axis_cq_rts;   // There should be No Input Flop on this input,
  logic         pcie_axis_rc_rts;   // there should be No Input Flop on this input,
  logic [572:0] axis_cq_tuser;      // External Output Flops Needed
  logic [1023:0] axis_cc_tdata;  // External Input Flops Needed
  logic         axis_cc_tlast;  // External Input Flop Needed
  logic [31:0]  axis_cc_tkeep;  // External Input Flops Needed
  logic         axis_cc_tvalid; // External Input Flop Needed
  logic [7:0]   axis_cc_tready; // No External Input Flop should be added
  logic [272:0] axis_cc_tuser;  // External Input Flops Needed

  logic [1023:0] axis_rq_tdata;  // Needs External Input Flops
  logic         axis_rq_tlast;  // Needs External Input Flop
  logic [31:0]  axis_rq_tkeep;  // Needs External Input Flops
  logic         axis_rq_tvalid; // Needs External Input Flop
  logic [7:0]   axis_rq_tready; // No External Output Flops should be added
  logic [456:0] axis_rq_tuser;  // Needs External Input Flops

  logic [2:0]   pcie_cq_np_req;
  logic [7:0]   pcie_cq_np_req_count;
  logic [39:0]  pcie_rq_tag;
  logic [3:0]   pcie_rq_tag_vld;
  logic [7:0]   pcie_rq_seq_num0;
  logic [7:0]   pcie_rq_seq_num1;
  logic [7:0]   pcie_rq_seq_num2;
  logic [7:0]   pcie_rq_seq_num3;
  logic [3:0]   pcie_rq_seq_num_vld;
  logic [7:0]   pcie_tfc_nph_av;
  logic [7:0]   pcie_tfc_npd_av;
  logic [7:0]   pcie_rq_tag_av;
  logic [1:0]   cfg_ptm_spare_in;
  logic [1:0]   cfg_ptm_spare_out;
  logic         cfg_ide_transit_to_insecure;
  logic [13:0]  cfg_msix_int_tph_data_in;
  logic [13:0]  cfg_msix_int_tph_data_out;
  logic [1:0]   cfg_cxl_pm_credit_avail;
  logic [3:0]   cfg_vlsm_io;
  logic [3:0]   cfg_vlsm_cachemem;
  logic         cfg_wrreq_flr_vld;
  logic         cfg_wrreq_msi_vld;
  logic         cfg_wrreq_msix_vld;
  logic         cfg_wrreq_bme_vld;
  logic         cfg_wrreq_vfe_vld;
  logic [15:0]  cfg_wrreq_func_num;
  logic [ 3:0]  cfg_wrreq_out_value;
  logic [23:0]  cfg_perfunc_out;
  logic         cfg_perfunc_vld;
  logic [15:0]  cfg_perfunc_func_num;
  logic         cfg_perfunc_req;
  logic [9:0]   cfg_mgmt_addr;
  logic [15:0]  cfg_mgmt_function_number;
  logic         cfg_mgmt_write;
  logic [31:0]  cfg_mgmt_write_data;
  logic [3:0]   cfg_mgmt_byte_enable;
  logic         cfg_mgmt_read;
  logic [31:0]  cfg_mgmt_read_data;
  logic         cfg_mgmt_read_write_done;
  logic         cfg_mgmt_debug_access;
  logic         cfg_phy_link_down;
  logic [1:0]   cfg_phy_link_status;
  logic [2:0]   cfg_negotiated_width;
  logic [2:0]   cfg_current_speed;
  logic [1:0]   cfg_max_payload;
  logic [2:0]   cfg_max_read_req;
  logic [3:0]   cfg_function_status;
  logic [2:0]   cfg_function_power_state;
  logic [1:0]   cfg_link_power_state;
  logic         cfg_err_cor_out;
  logic         cfg_err_nonfatal_out;
  logic         cfg_err_fatal_out;
  logic         cfg_local_error_valid;
  logic [5:0]   cfg_local_error_out;
  logic [5:0]   cfg_ltssm_state;
  logic [1:0]   cfg_rx_pm_state;
  logic [1:0]   cfg_tx_pm_state;
  logic         cfg_rcb_status;
  logic         cfg_atomic_requester_enable;
  logic         cfg_10b_tag_requester_enable;
  logic         cfg_pl_status_change;
  logic         cfg_ext_tag_enable;
  logic         cfg_vc1_enable;
  logic         cfg_vc1_negotiation_pending;
  logic         cfg_msg_received;
  logic [7:0]   cfg_msg_received_data;
  logic [4:0]   cfg_msg_received_type;
  logic         cfg_msg_transmit;
  logic [2:0]   cfg_msg_transmit_type;
  logic [31:0]  cfg_msg_transmit_data;
  logic         cfg_msg_transmit_done;
  logic [11:0]  cfg_fc_ph;
  logic [1:0]   cfg_fc_ph_scale;
  logic [15:0]  cfg_fc_pd;
  logic [1:0]   cfg_fc_pd_scale;
  logic [11:0]  cfg_fc_nph;
  logic [1:0]   cfg_fc_nph_scale;
  logic [15:0]  cfg_fc_npd;
  logic [1:0]   cfg_fc_npd_scale;
  logic [11:0]  cfg_fc_cplh;
  logic [1:0]   cfg_fc_cplh_scale;
  logic [15:0]  cfg_fc_cpld;
  logic [1:0]   cfg_fc_cpld_scale;
  logic [2:0]   cfg_fc_sel;
  logic         cfg_fc_vc_sel;
  logic         cfg_hot_reset_in;
  logic         cfg_hot_reset_out;

  logic [7:0]   cfg_bus_number;
  logic         cfg_power_state_change_ack;
  logic         cfg_power_state_change_interrupt;
  logic         cfg_err_cor_in;
  logic         cfg_err_uncor_in;
  logic         cfg_flr_done;
  logic [15:0]  cfg_flr_done_func_num;
  logic [3:0]   cfg_interrupt_int;
  logic         cfg_interrupt_sent;
  logic [31:0]  cfg_interrupt_pending;
  logic         cfg_interrupt_msi_enable;
  logic [31:0]  cfg_interrupt_msi_int;
  logic         cfg_interrupt_msi_sent;
  logic         cfg_interrupt_msi_fail;
  logic [ 2:0]  cfg_interrupt_msi_mmenable;
  logic [31:0]  cfg_interrupt_msi_pending_status;
  logic [4:0]   cfg_interrupt_msi_pending_status_function_num;
  logic         cfg_interrupt_msi_pending_status_data_enable;
  logic         cfg_interrupt_msi_mask_update;
  logic [4:0]   cfg_interrupt_msi_select;
  logic [31:0]  cfg_interrupt_msi_data;
  logic         cfg_interrupt_msix_enable;
  logic         cfg_interrupt_msix_mask;
  logic [63:0]  cfg_interrupt_msix_address;
  logic [31:0]  cfg_interrupt_msix_data;
  logic         cfg_interrupt_msix_int;
  logic [1:0]   cfg_interrupt_msix_vec_pending;
  logic         cfg_interrupt_msix_vec_pending_status;
  logic [15:0]  cfg_interrupt_msix_ld_id;
  logic         cfg_interrupt_msix_ld_id_valid;
  logic         cfg_interrupt_msix_ide_valid;
  logic         cfg_interrupt_msix_tbit;
  logic [2:0]   cfg_interrupt_msi_attr;
  logic         cfg_interrupt_msi_tph_present;
  logic [1:0]   cfg_interrupt_msi_tph_type;
  logic [7:0]   cfg_interrupt_msi_tph_st_tag;
  logic [15:0]  cfg_interrupt_msi_function_number;
  logic         cfg_ext_read_received;
  logic         cfg_ext_write_received;
  logic [9:0]   cfg_ext_register_number;
  logic [15:0]  cfg_ext_function_number;
  logic [31:0]  cfg_ext_write_data;
  logic [3:0]   cfg_ext_write_byte_enable;
  logic [31:0]  cfg_ext_read_data;
  logic         cfg_ext_read_data_valid;
  logic         cfg_ext_send_completion;
  logic [2:0]   cfg_ext_compl_status;
  logic         cfg_ext_adv_swt_access;
  logic [31:0]  cfg_ext_read_debug1;
  logic [31:0]  cfg_ext_write_debug1;
  logic         cfg_ccix_edr_data_rate_change_req;
  logic         cfg_ccix_edr_data_rate_change_ack;
  logic         cfg_edr_enable;
  logic         cfg_pasid_enable;
  logic         cfg_pasid_exec_permission_enable;
  logic         cfg_pasid_privil_mode_enable;
  logic [15:0]  spare_outputs;
  logic [15:0]  spare_inputs;

  modport s(
    input  axis_cq_tdata,
    input  axis_cq_tlast,
    input  axis_rc_tlast,
    input  axis_cq_tkeep,
    output pcie_axis_cq_ready,
    output pcie_axis_rc_ready,
    input  pcie_axis_cq_vld,
    input  pcie_axis_rc_vld,
    output pcie_axis_cq_rts,
    output pcie_axis_rc_rts,
    input  axis_cq_tuser,

    output axis_cc_tdata,
    output axis_cc_tlast,
    output axis_cc_tkeep,
    output axis_cc_tvalid,
    input  axis_cc_tready,
    output axis_cc_tuser,
    output axis_rq_tdata,
    output axis_rq_tlast,
    output axis_rq_tkeep,
    output axis_rq_tvalid,
    input  axis_rq_tready,
    output axis_rq_tuser,
    output pcie_cq_np_req,
    input  pcie_cq_np_req_count,

    input  pcie_rq_tag,
    input  pcie_rq_tag_vld,

    input  pcie_rq_seq_num0,
    input  pcie_rq_seq_num1,
    input  pcie_rq_seq_num2,
    input  pcie_rq_seq_num3,
    input  pcie_rq_seq_num_vld,

    input  pcie_tfc_nph_av,
    input  pcie_tfc_npd_av,
    input  pcie_rq_tag_av,
    output cfg_ptm_spare_in,
    input  cfg_ptm_spare_out,
    input  cfg_ide_transit_to_insecure,
    output cfg_msix_int_tph_data_in,
    input  cfg_msix_int_tph_data_out,
    input  cfg_cxl_pm_credit_avail,
    input  cfg_vlsm_io,
    input  cfg_vlsm_cachemem,
    input  cfg_wrreq_flr_vld,
    input  cfg_wrreq_msi_vld,
    input  cfg_wrreq_msix_vld,
    input  cfg_wrreq_bme_vld,
    input  cfg_wrreq_vfe_vld,
    input  cfg_wrreq_func_num,
    input  cfg_wrreq_out_value,
    input  cfg_perfunc_out,
    input  cfg_perfunc_vld,
    output cfg_perfunc_func_num,
    output cfg_perfunc_req,
    output cfg_mgmt_addr,
    output cfg_mgmt_function_number,
    output cfg_mgmt_write,
    output cfg_mgmt_write_data,
    output cfg_mgmt_byte_enable,
    output cfg_mgmt_read,
    input  cfg_mgmt_read_data,
    input  cfg_mgmt_read_write_done,
    output cfg_mgmt_debug_access,
    input  cfg_phy_link_down,
    input  cfg_phy_link_status,
    input  cfg_negotiated_width,
    input  cfg_current_speed,
    input  cfg_max_payload,
    input  cfg_max_read_req,
    input  cfg_function_status,
    input  cfg_function_power_state,
    input  cfg_link_power_state,
    input  cfg_err_cor_out,
    input  cfg_err_nonfatal_out,
    input  cfg_err_fatal_out,
    input  cfg_local_error_valid,
    input  cfg_local_error_out,
    input  cfg_ltssm_state,
    input  cfg_rx_pm_state,
    input  cfg_tx_pm_state,
    input  cfg_rcb_status,
    input  cfg_atomic_requester_enable,
    input  cfg_10b_tag_requester_enable,
    input  cfg_pl_status_change,
    input  cfg_ext_tag_enable,
    input  cfg_vc1_enable,
    input  cfg_vc1_negotiation_pending,
    input  cfg_msg_received,
    input  cfg_msg_received_data,
    input  cfg_msg_received_type,
    output cfg_msg_transmit,
    output cfg_msg_transmit_type,
    output cfg_msg_transmit_data,
    input  cfg_msg_transmit_done,
    input  cfg_fc_ph,
    input  cfg_fc_ph_scale,
    input  cfg_fc_pd,
    input  cfg_fc_pd_scale,
    input  cfg_fc_nph,
    input  cfg_fc_nph_scale,
    input  cfg_fc_npd,
    input  cfg_fc_npd_scale,
    input  cfg_fc_cplh,
    input  cfg_fc_cplh_scale,
    input  cfg_fc_cpld,
    input  cfg_fc_cpld_scale,
    output cfg_fc_sel,
    output cfg_fc_vc_sel,
    output cfg_hot_reset_in,
    input  cfg_hot_reset_out,

    input  cfg_bus_number,
    output cfg_power_state_change_ack,
    input  cfg_power_state_change_interrupt,
    output cfg_err_cor_in,
    output cfg_err_uncor_in,
    output cfg_flr_done,
    output cfg_flr_done_func_num,
    output cfg_interrupt_int,
    input  cfg_interrupt_sent,
    output cfg_interrupt_pending,
    input  cfg_interrupt_msi_enable,
    output cfg_interrupt_msi_int,
    input  cfg_interrupt_msi_sent,
    input  cfg_interrupt_msi_fail,
    input  cfg_interrupt_msi_mmenable,
    output cfg_interrupt_msi_pending_status,
    output cfg_interrupt_msi_pending_status_function_num,
    output cfg_interrupt_msi_pending_status_data_enable,
    input  cfg_interrupt_msi_mask_update,
    output cfg_interrupt_msi_select,
    input  cfg_interrupt_msi_data,
    input  cfg_interrupt_msix_enable,
    input  cfg_interrupt_msix_mask,
    output cfg_interrupt_msix_address,
    output cfg_interrupt_msix_data,
    output cfg_interrupt_msix_int,
    output cfg_interrupt_msix_vec_pending,
    input  cfg_interrupt_msix_vec_pending_status,
    output cfg_interrupt_msix_ld_id,
    output cfg_interrupt_msix_ld_id_valid,
    output cfg_interrupt_msix_ide_valid,
    output cfg_interrupt_msix_tbit,
    output cfg_interrupt_msi_attr,
    output cfg_interrupt_msi_tph_present,
    output cfg_interrupt_msi_tph_type,
    output cfg_interrupt_msi_tph_st_tag,
    output cfg_interrupt_msi_function_number,
    input  cfg_ext_read_received,
    input  cfg_ext_write_received,
    input  cfg_ext_register_number,
    input  cfg_ext_function_number,
    input  cfg_ext_write_data,
    input  cfg_ext_write_byte_enable,
    output cfg_ext_read_data,
    output cfg_ext_read_data_valid,
    output cfg_ext_send_completion,
    output cfg_ext_compl_status,
    input  cfg_ext_adv_swt_access,
    output cfg_ext_read_debug1,
    input  cfg_ext_write_debug1,
    input  cfg_ccix_edr_data_rate_change_req,
    output cfg_ccix_edr_data_rate_change_ack,
    input  cfg_edr_enable,
    input  cfg_pasid_enable,
    input  cfg_pasid_exec_permission_enable,
    input  cfg_pasid_privil_mode_enable,
    input  spare_outputs,
    output spare_inputs
  );

  modport m (
    output axis_cq_tdata,
    output axis_cq_tlast,
    output axis_rc_tlast,
    output axis_cq_tkeep,
    input  pcie_axis_cq_ready,
    input  pcie_axis_rc_ready,
    output pcie_axis_cq_vld,
    output pcie_axis_rc_vld,
    input  pcie_axis_cq_rts,
    input  pcie_axis_rc_rts,
    output axis_cq_tuser,
    input  axis_cc_tdata,
    input  axis_cc_tlast,
    input  axis_cc_tkeep,
    input  axis_cc_tvalid,
    output axis_cc_tready,
    input  axis_cc_tuser,
    input  axis_rq_tdata,
    input  axis_rq_tlast,
    input  axis_rq_tkeep,
    input  axis_rq_tvalid,
    input  axis_rq_tuser,
    output axis_rq_tready,

    input  pcie_cq_np_req,
    output pcie_cq_np_req_count,

    output pcie_rq_tag,
    output pcie_rq_tag_vld,

    output pcie_rq_seq_num0,
    output pcie_rq_seq_num1,
    output pcie_rq_seq_num2,
    output pcie_rq_seq_num3,
    output pcie_rq_seq_num_vld,

    output pcie_tfc_nph_av,
    output pcie_tfc_npd_av,
    output pcie_rq_tag_av,

    input  cfg_ptm_spare_in,
    output cfg_ptm_spare_out,
    output cfg_ide_transit_to_insecure,
    input  cfg_msix_int_tph_data_in,
    output cfg_msix_int_tph_data_out,
    output cfg_cxl_pm_credit_avail,
    output cfg_vlsm_io,
    output cfg_vlsm_cachemem,
    output cfg_wrreq_flr_vld,
    output cfg_wrreq_msi_vld,
    output cfg_wrreq_msix_vld,
    output cfg_wrreq_bme_vld,
    output cfg_wrreq_vfe_vld,
    output cfg_wrreq_func_num,
    output cfg_wrreq_out_value,
    output cfg_perfunc_out,
    output cfg_perfunc_vld,
    input  cfg_perfunc_func_num,
    input  cfg_perfunc_req,
    input  cfg_mgmt_addr,
    input  cfg_mgmt_function_number,
    input  cfg_mgmt_write,
    input  cfg_mgmt_write_data,
    input  cfg_mgmt_byte_enable,
    input  cfg_mgmt_read,
    output cfg_mgmt_read_data,
    output cfg_mgmt_read_write_done,
    input  cfg_mgmt_debug_access,
    output cfg_phy_link_down,
    output cfg_phy_link_status,
    output cfg_negotiated_width,
    output cfg_current_speed,
    output cfg_max_payload,
    output cfg_max_read_req,
    output cfg_function_status,
    output cfg_function_power_state,
    output cfg_link_power_state,
    output cfg_err_cor_out,
    output cfg_err_nonfatal_out,
    output cfg_err_fatal_out,
    output cfg_local_error_valid,
    output cfg_local_error_out,
    output cfg_ltssm_state,
    output cfg_rx_pm_state,
    output cfg_tx_pm_state,
    output cfg_rcb_status,
    output cfg_atomic_requester_enable,
    output cfg_10b_tag_requester_enable,
    output cfg_pl_status_change,
    output cfg_ext_tag_enable,
    output cfg_vc1_enable,
    output cfg_vc1_negotiation_pending,
    output cfg_msg_received,
    output cfg_msg_received_data,
    output cfg_msg_received_type,
    input  cfg_msg_transmit,
    input  cfg_msg_transmit_type,
    input  cfg_msg_transmit_data,
    output cfg_msg_transmit_done,
    output cfg_fc_ph,
    output cfg_fc_ph_scale,
    output cfg_fc_pd,
    output cfg_fc_pd_scale,
    output cfg_fc_nph,
    output cfg_fc_nph_scale,
    output cfg_fc_npd,
    output cfg_fc_npd_scale,
    output cfg_fc_cplh,
    output cfg_fc_cplh_scale,
    output cfg_fc_cpld,
    output cfg_fc_cpld_scale,
    input  cfg_fc_sel,
    input  cfg_fc_vc_sel,
    input  cfg_hot_reset_in,
    output cfg_hot_reset_out,
    output cfg_bus_number,
    input  cfg_power_state_change_ack,
    output cfg_power_state_change_interrupt,
    input  cfg_err_cor_in,
    input  cfg_err_uncor_in,
    input  cfg_flr_done,
    input  cfg_flr_done_func_num,
    input  cfg_interrupt_int,
    output cfg_interrupt_sent,
    input  cfg_interrupt_pending,
    output cfg_interrupt_msi_enable,
    input  cfg_interrupt_msi_int,
    output cfg_interrupt_msi_sent,
    output cfg_interrupt_msi_fail,
    output cfg_interrupt_msi_mmenable,
    input  cfg_interrupt_msi_pending_status,
    input  cfg_interrupt_msi_pending_status_function_num,
    input  cfg_interrupt_msi_pending_status_data_enable,
    output cfg_interrupt_msi_mask_update,
    input  cfg_interrupt_msi_select,
    output cfg_interrupt_msi_data,
    output cfg_interrupt_msix_enable,
    output cfg_interrupt_msix_mask,
    input  cfg_interrupt_msix_address,
    input  cfg_interrupt_msix_data,
    input  cfg_interrupt_msix_int,
    input  cfg_interrupt_msix_vec_pending,
    output cfg_interrupt_msix_vec_pending_status,
    input  cfg_interrupt_msix_ld_id,
    input  cfg_interrupt_msix_ld_id_valid,
    input  cfg_interrupt_msix_ide_valid,
    input  cfg_interrupt_msix_tbit,
    input  cfg_interrupt_msi_attr,
    input  cfg_interrupt_msi_tph_present,
    input  cfg_interrupt_msi_tph_type,
    input  cfg_interrupt_msi_tph_st_tag,
    input  cfg_interrupt_msi_function_number,
    output cfg_ext_read_received,
    output cfg_ext_write_received,
    output cfg_ext_register_number,
    output cfg_ext_function_number,
    output cfg_ext_write_data,
    output cfg_ext_write_byte_enable,
    input  cfg_ext_read_data,
    input  cfg_ext_read_data_valid,
    input  cfg_ext_send_completion,
    input  cfg_ext_compl_status,
    output cfg_ext_adv_swt_access,
    input  cfg_ext_read_debug1,
    output cfg_ext_write_debug1,
    output cfg_ccix_edr_data_rate_change_req,
    input  cfg_ccix_edr_data_rate_change_ack,
    output cfg_edr_enable,
    output cfg_pasid_enable,
    output cfg_pasid_exec_permission_enable,
    output cfg_pasid_privil_mode_enable,
    output spare_outputs,
    input  spare_inputs
  );
endinterface : cpm5n_pl_pcie_axi_if

interface cpm5n_pl_pcie_cdxbot_axi_if();
  logic [3593:0] in;
  logic [2352:0] out;

  modport s (
    input  out,
    output in
  );

  modport m (
    output out,
    input  in
  );

endinterface : cpm5n_pl_pcie_cdxbot_axi_if

interface cpm5n_pl_pcie_cdxtop_axi_if();
  logic [3994:0] in;
  logic [2714:0] out;

  modport s (
    input  out,
    output in
  );

  modport m (
    output out,
    input  in
  );

endinterface : cpm5n_pl_pcie_cdxtop_axi_if

interface cpm5n_pl_pciex4_axi_if();

  logic [255:0] axis_cq_tdata;
  logic         axis_cq_tlast;// double
  logic         axis_rc_tlast;
  logic [7:0]   axis_cq_tkeep;
  logic [59:0]  pcie_axis_cq_ready;
  logic [59:0]  pcie_axis_rc_ready;
  logic         pcie_axis_cq_vld;//double
  logic         pcie_axis_rc_vld;//double
  logic         pcie_axis_cq_rts;//double
  logic         pcie_axis_rc_rts;//double
  logic [135:0] axis_cq_tuser;
  logic [255:0] axis_cc_tdata;
  logic         axis_cc_tlast;//double
  logic [7:0]   axis_cc_tkeep;
  logic         axis_cc_tvalid;//double
  logic [1:0]   axis_cc_tready;
  logic [59:0]  axis_cc_tuser;
  logic [255:0] axis_rq_tdata;
  logic         axis_rq_tlast;//double
  logic [7:0]   axis_rq_tkeep;
  logic         axis_rq_tvalid;//double
  logic [1:0]   axis_rq_tready;
  logic [104:0] axis_rq_tuser;
  logic         pcie_cq_np_req;
  logic [7:0]   pcie_cq_np_req_count;//double
  logic [39:0]  pcie_rq_tag;
  logic [3:0]   pcie_rq_tag_vld;
  logic [7:0]   pcie_rq_seq_num0;//double
  logic [7:0]   pcie_rq_seq_num1;//double
  logic [7:0]   pcie_rq_seq_num2;//double
  logic [7:0]   pcie_rq_seq_num3;//double
  logic [3:0]   pcie_rq_seq_num_vld;//double
  logic [7:0]   pcie_tfc_nph_av;//double
  logic [7:0]   pcie_tfc_npd_av;//double
  logic [7:0]   pcie_rq_tag_av;//double
  logic [1:0]   cfg_ptm_spare_in;
  logic [1:0]   cfg_ptm_spare_out;
  logic         cfg_ide_transit_to_insecure;
  logic [13:0]  cfg_msix_int_tph_data_in;
  logic [13:0]  cfg_msix_int_tph_data_out;
  logic [ 1:0]  cfg_cxl_pm_credit_avail;
  logic [3:0]   cfg_vlsm_io;
  logic [3:0]   cfg_vlsm_cachemem;
  logic         cfg_wrreq_flr_vld;
  logic         cfg_wrreq_msi_vld;
  logic         cfg_wrreq_msix_vld;
  logic         cfg_wrreq_bme_vld;
  logic         cfg_wrreq_vfe_vld;
  logic [15:0]  cfg_wrreq_func_num;
  logic [ 3:0]  cfg_wrreq_out_value;
  logic [23:0]  cfg_perfunc_out;
  logic         cfg_perfunc_vld;
  logic [15:0]  cfg_perfunc_func_num;
  logic         cfg_perfunc_req;
  logic [9:0]   cfg_mgmt_addr;
  logic [15:0]  cfg_mgmt_function_number;
  logic         cfg_mgmt_write;
  logic [31:0]  cfg_mgmt_write_data;
  logic [3:0]   cfg_mgmt_byte_enable;
  logic         cfg_mgmt_read;
  logic [31:0]  cfg_mgmt_read_data;
  logic         cfg_mgmt_read_write_done;
  logic         cfg_mgmt_debug_access;
  logic         cfg_phy_link_down;
  logic [1:0]   cfg_phy_link_status;
  logic [2:0]   cfg_negotiated_width;
  logic [2:0]   cfg_current_speed;
  logic [1:0]   cfg_max_payload;
  logic [2:0]   cfg_max_read_req;
  logic [3:0]   cfg_function_status;
  logic [2:0]   cfg_function_power_state;
  logic [1:0]   cfg_link_power_state;
  logic         cfg_err_cor_out;
  logic         cfg_err_nonfatal_out;
  logic         cfg_err_fatal_out;
  logic         cfg_local_error_valid;
  logic [5:0]   cfg_local_error_out;
  logic [5:0]   cfg_ltssm_state;
  logic [1:0]   cfg_rx_pm_state;
  logic [1:0]   cfg_tx_pm_state;
  logic         cfg_rcb_status;
  logic         cfg_atomic_requester_enable;
  logic         cfg_10b_tag_requester_enable;
  logic         cfg_pl_status_change;
  logic         cfg_ext_tag_enable;
  logic         cfg_vc1_enable;
  logic         cfg_vc1_negotiation_pending;
  logic         cfg_msg_received;
  logic [7:0]   cfg_msg_received_data;
  logic [4:0]   cfg_msg_received_type;
  logic         cfg_msg_transmit;
  logic [2:0]   cfg_msg_transmit_type;
  logic [31:0]  cfg_msg_transmit_data;
  logic         cfg_msg_transmit_done;
  logic [11:0]  cfg_fc_ph;
  logic [1:0]   cfg_fc_ph_scale;
  logic [15:0]  cfg_fc_pd;
  logic [1:0]   cfg_fc_pd_scale;
  logic [11:0]  cfg_fc_nph;
  logic [1:0]   cfg_fc_nph_scale;
  logic [15:0]  cfg_fc_npd;
  logic [1:0]   cfg_fc_npd_scale;
  logic [11:0]  cfg_fc_cplh;
  logic [1:0]   cfg_fc_cplh_scale;
  logic [15:0]  cfg_fc_cpld;
  logic [1:0]   cfg_fc_cpld_scale;
  logic [2:0]   cfg_fc_sel;
  logic         cfg_fc_vc_sel;
  logic         cfg_hot_reset_in;
  logic         cfg_hot_reset_out;
  logic [7:0]   cfg_bus_number;
  logic         cfg_power_state_change_ack;
  logic         cfg_power_state_change_interrupt;
  logic         cfg_err_cor_in;
  logic         cfg_err_uncor_in;
  logic         cfg_flr_done;
  logic [15:0]  cfg_flr_done_func_num;
  logic [3:0]   cfg_interrupt_int;
  logic         cfg_interrupt_sent;
  logic [31:0]  cfg_interrupt_pending;
  logic         cfg_interrupt_msi_enable;
  logic [31:0]  cfg_interrupt_msi_int;
  logic         cfg_interrupt_msi_sent;
  logic         cfg_interrupt_msi_fail;
  logic [2:0]   cfg_interrupt_msi_mmenable;
  logic [31:0]  cfg_interrupt_msi_pending_status;
  logic [4:0]   cfg_interrupt_msi_pending_status_function_num;
  logic         cfg_interrupt_msi_pending_status_data_enable;
  logic         cfg_interrupt_msi_mask_update;
  logic [4:0]   cfg_interrupt_msi_select;
  logic [31:0]  cfg_interrupt_msi_data;
  logic         cfg_interrupt_msix_enable;
  logic         cfg_interrupt_msix_mask;
  logic [63:0]  cfg_interrupt_msix_address;
  logic [31:0]  cfg_interrupt_msix_data;
  logic         cfg_interrupt_msix_int;
  logic [1:0]   cfg_interrupt_msix_vec_pending;
  logic         cfg_interrupt_msix_vec_pending_status;
  logic [15:0]  cfg_interrupt_msix_ld_id;
  logic         cfg_interrupt_msix_ld_id_valid;
  logic         cfg_interrupt_msix_ide_valid;
  logic         cfg_interrupt_msix_tbit;
  logic [2:0]   cfg_interrupt_msi_attr;
  logic         cfg_interrupt_msi_tph_present;
  logic [1:0]   cfg_interrupt_msi_tph_type;
  logic [7:0]   cfg_interrupt_msi_tph_st_tag;
  logic [15:0]  cfg_interrupt_msi_function_number;
  logic         cfg_ext_read_received;
  logic         cfg_ext_write_received;
  logic [9:0]   cfg_ext_register_number;
  logic [15:0]  cfg_ext_function_number;
  logic [31:0]  cfg_ext_write_data;
  logic [3:0]   cfg_ext_write_byte_enable;
  logic [31:0]  cfg_ext_read_data;
  logic         cfg_ext_read_data_valid;
  logic [2:0]   cfg_ext_compl_status;
  logic         cfg_ext_send_completion;
  logic         cfg_ext_adv_swt_access;
  logic [31:0]  cfg_ext_read_debug1;
  logic [31:0]  cfg_ext_write_debug1;
  logic         cfg_ccix_edr_data_rate_change_req;
  logic         cfg_ccix_edr_data_rate_change_ack;
  logic         cfg_edr_enable;
  logic         cfg_pasid_enable;
  logic         cfg_pasid_exec_permission_enable;
  logic         cfg_pasid_privil_mode_enable;
  logic [15:0]  spare_outputs;
  logic [15:0]  spare_inputs;

  modport s(
    input  axis_cq_tdata,
    input  axis_cq_tlast,
    input  axis_rc_tlast,
    input  axis_cq_tkeep,
    output pcie_axis_cq_ready,
    output pcie_axis_rc_ready,
    input  pcie_axis_cq_vld,
    input  pcie_axis_rc_vld,
    output pcie_axis_cq_rts,
    output pcie_axis_rc_rts,
    input  axis_cq_tuser,

    output axis_cc_tdata,
    output axis_cc_tlast,
    output axis_cc_tkeep,
    output axis_cc_tvalid,
    input  axis_cc_tready,
    output axis_cc_tuser,
    output axis_rq_tdata,
    output axis_rq_tlast,
    output axis_rq_tkeep,
    output axis_rq_tvalid,
    input  axis_rq_tready,
    output axis_rq_tuser,
    output pcie_cq_np_req,
    input  pcie_cq_np_req_count,

    input  pcie_rq_tag,
    input  pcie_rq_tag_vld,

    input  pcie_rq_seq_num0,
    input  pcie_rq_seq_num1,
    input  pcie_rq_seq_num2,
    input  pcie_rq_seq_num3,
    input  pcie_rq_seq_num_vld,

    input  pcie_tfc_nph_av,
    input  pcie_tfc_npd_av,
    input  pcie_rq_tag_av,
    output cfg_ptm_spare_in,
    input  cfg_ptm_spare_out,
    input  cfg_ide_transit_to_insecure,
    output cfg_msix_int_tph_data_in,
    input  cfg_msix_int_tph_data_out,
    input  cfg_cxl_pm_credit_avail,
    input  cfg_vlsm_io,
    input  cfg_vlsm_cachemem,
    input  cfg_wrreq_flr_vld,
    input  cfg_wrreq_msi_vld,
    input  cfg_wrreq_msix_vld,
    input  cfg_wrreq_bme_vld,
    input  cfg_wrreq_vfe_vld,
    input  cfg_wrreq_func_num,
    input  cfg_wrreq_out_value,
    input  cfg_perfunc_out,
    input  cfg_perfunc_vld,
    output cfg_perfunc_func_num,
    output cfg_perfunc_req,
    output cfg_mgmt_addr,
    output cfg_mgmt_function_number,
    output cfg_mgmt_write,
    output cfg_mgmt_write_data,
    output cfg_mgmt_byte_enable,
    output cfg_mgmt_read,
    input  cfg_mgmt_read_data,
    input  cfg_mgmt_read_write_done,
    output cfg_mgmt_debug_access,
    input  cfg_phy_link_down,
    input  cfg_phy_link_status,
    input  cfg_negotiated_width,
    input  cfg_current_speed,
    input  cfg_max_payload,
    input  cfg_max_read_req,
    input  cfg_function_status,
    input  cfg_function_power_state,
    input  cfg_link_power_state,
    input  cfg_err_cor_out,
    input  cfg_err_nonfatal_out,
    input  cfg_err_fatal_out,
    input  cfg_local_error_valid,
    input  cfg_local_error_out,
    input  cfg_ltssm_state,
    input  cfg_rx_pm_state,
    input  cfg_tx_pm_state,
    input  cfg_rcb_status,
    input  cfg_atomic_requester_enable,
    input  cfg_10b_tag_requester_enable,
    input  cfg_pl_status_change,
    input  cfg_ext_tag_enable,
    input  cfg_vc1_enable,
    input  cfg_vc1_negotiation_pending,
    input  cfg_msg_received,
    input  cfg_msg_received_data,
    input  cfg_msg_received_type,
    output cfg_msg_transmit,
    output cfg_msg_transmit_type,
    output cfg_msg_transmit_data,
    input  cfg_msg_transmit_done,
    input  cfg_fc_ph,
    input  cfg_fc_ph_scale,
    input  cfg_fc_pd,
    input  cfg_fc_pd_scale,
    input  cfg_fc_nph,
    input  cfg_fc_nph_scale,
    input  cfg_fc_npd,
    input  cfg_fc_npd_scale,
    input  cfg_fc_cplh,
    input  cfg_fc_cplh_scale,
    input  cfg_fc_cpld,
    input  cfg_fc_cpld_scale,
    output cfg_fc_sel,
    output cfg_fc_vc_sel,
    output cfg_hot_reset_in,
    input  cfg_hot_reset_out,
    input  cfg_bus_number,
    output cfg_power_state_change_ack,
    input  cfg_power_state_change_interrupt,
    output cfg_err_cor_in,
    output cfg_err_uncor_in,
    output cfg_flr_done,
    output cfg_flr_done_func_num,
    output cfg_interrupt_int,
    input  cfg_interrupt_sent,
    output cfg_interrupt_pending,
    input  cfg_interrupt_msi_enable,
    output cfg_interrupt_msi_int,
    input  cfg_interrupt_msi_sent,
    input  cfg_interrupt_msi_fail,
    input  cfg_interrupt_msi_mmenable,
    output cfg_interrupt_msi_pending_status,
    output cfg_interrupt_msi_pending_status_function_num,
    output cfg_interrupt_msi_pending_status_data_enable,
    input  cfg_interrupt_msi_mask_update,
    output cfg_interrupt_msi_select,
    input  cfg_interrupt_msi_data,
    input  cfg_interrupt_msix_enable,
    input  cfg_interrupt_msix_mask,
    output cfg_interrupt_msix_address,
    output cfg_interrupt_msix_data,
    output cfg_interrupt_msix_int,
    output cfg_interrupt_msix_vec_pending,
    input  cfg_interrupt_msix_vec_pending_status,
    output cfg_interrupt_msix_ld_id,
    output cfg_interrupt_msix_ld_id_valid,
    output cfg_interrupt_msix_ide_valid,
    output cfg_interrupt_msix_tbit,
    output cfg_interrupt_msi_attr,
    output cfg_interrupt_msi_tph_present,
    output cfg_interrupt_msi_tph_type,
    output cfg_interrupt_msi_tph_st_tag,
    output cfg_interrupt_msi_function_number,
    input  cfg_ext_read_received,
    input  cfg_ext_write_received,
    input  cfg_ext_register_number,
    input  cfg_ext_function_number,
    input  cfg_ext_write_data,
    input  cfg_ext_write_byte_enable,
    output cfg_ext_read_data,
    output cfg_ext_read_data_valid,
    output cfg_ext_send_completion,
    output cfg_ext_compl_status,
    input  cfg_ext_adv_swt_access,
    output cfg_ext_read_debug1,
    input  cfg_ext_write_debug1,
    input  cfg_ccix_edr_data_rate_change_req,
    output cfg_ccix_edr_data_rate_change_ack,
    input  cfg_edr_enable,
    input  cfg_pasid_enable,
    input  cfg_pasid_exec_permission_enable,
    input  cfg_pasid_privil_mode_enable,
    input  spare_outputs,
    output spare_inputs
  );

  modport m (
    output axis_cq_tdata,
    output axis_cq_tlast,
    output axis_rc_tlast,
    output axis_cq_tkeep,
    input  pcie_axis_cq_ready,
    input  pcie_axis_rc_ready,
    output pcie_axis_cq_vld,
    output pcie_axis_rc_vld,
    input  pcie_axis_cq_rts,
    input  pcie_axis_rc_rts,
    output axis_cq_tuser,

    input  axis_cc_tdata,
    input  axis_cc_tlast,
    input  axis_cc_tkeep,
    input  axis_cc_tvalid,
    output axis_cc_tready,
    input  axis_cc_tuser,

    input  axis_rq_tdata,
    input  axis_rq_tlast,
    input  axis_rq_tkeep,
    input  axis_rq_tvalid,
    input  axis_rq_tuser,
    output axis_rq_tready,

    input  pcie_cq_np_req,
    output pcie_cq_np_req_count,

    output pcie_rq_tag,
    output pcie_rq_tag_vld,

    output pcie_rq_seq_num0,
    output pcie_rq_seq_num1,
    output pcie_rq_seq_num2,
    output pcie_rq_seq_num3,
    output pcie_rq_seq_num_vld,

    output pcie_tfc_nph_av,
    output pcie_tfc_npd_av,
    output pcie_rq_tag_av,

    input  cfg_ptm_spare_in,
    output cfg_ptm_spare_out,
    output cfg_ide_transit_to_insecure,
    input  cfg_msix_int_tph_data_in,
    output cfg_msix_int_tph_data_out,
    output cfg_cxl_pm_credit_avail,
    output cfg_vlsm_io,
    output cfg_vlsm_cachemem,
    output cfg_wrreq_flr_vld,
    output cfg_wrreq_msi_vld,
    output cfg_wrreq_msix_vld,
    output cfg_wrreq_bme_vld,
    output cfg_wrreq_vfe_vld,
    output cfg_wrreq_func_num,
    output cfg_wrreq_out_value,
    output cfg_perfunc_out,
    output cfg_perfunc_vld,
    input  cfg_perfunc_func_num,
    input  cfg_perfunc_req,
    input  cfg_mgmt_addr,
    input  cfg_mgmt_function_number,
    input  cfg_mgmt_write,
    input  cfg_mgmt_write_data,
    input  cfg_mgmt_byte_enable,
    input  cfg_mgmt_read,
    output cfg_mgmt_read_data,
    output cfg_mgmt_read_write_done,
    input  cfg_mgmt_debug_access,
    output cfg_phy_link_down,
    output cfg_phy_link_status,
    output cfg_negotiated_width,
    output cfg_current_speed,
    output cfg_max_payload,
    output cfg_max_read_req,
    output cfg_function_status,
    output cfg_function_power_state,
    output cfg_link_power_state,
    output cfg_err_cor_out,
    output cfg_err_nonfatal_out,
    output cfg_err_fatal_out,
    output cfg_local_error_valid,
    output cfg_local_error_out,
    output cfg_ltssm_state,
    output cfg_rx_pm_state,
    output cfg_tx_pm_state,
    output cfg_rcb_status,
    output cfg_atomic_requester_enable,
    output cfg_10b_tag_requester_enable,
    output cfg_pl_status_change,
    output cfg_ext_tag_enable,
    output cfg_vc1_enable,
    output cfg_vc1_negotiation_pending,
    output cfg_msg_received,
    output cfg_msg_received_data,
    output cfg_msg_received_type,
    input  cfg_msg_transmit,
    input  cfg_msg_transmit_type,
    input  cfg_msg_transmit_data,
    output cfg_msg_transmit_done,
    output cfg_fc_ph,
    output cfg_fc_ph_scale,
    output cfg_fc_pd,
    output cfg_fc_pd_scale,
    output cfg_fc_nph,
    output cfg_fc_nph_scale,
    output cfg_fc_npd,
    output cfg_fc_npd_scale,
    output cfg_fc_cplh,
    output cfg_fc_cplh_scale,
    output cfg_fc_cpld,
    output cfg_fc_cpld_scale,
    input  cfg_fc_sel,
    input  cfg_fc_vc_sel,
    input  cfg_hot_reset_in,
    output cfg_hot_reset_out,
    output cfg_bus_number,
    input  cfg_power_state_change_ack,
    output cfg_power_state_change_interrupt,
    input  cfg_err_cor_in,
    input  cfg_err_uncor_in,
    input  cfg_flr_done,
    input  cfg_flr_done_func_num,
    input  cfg_interrupt_int,
    output cfg_interrupt_sent,
    input  cfg_interrupt_pending,
    output cfg_interrupt_msi_enable,
    input  cfg_interrupt_msi_int,
    output cfg_interrupt_msi_sent,
    output cfg_interrupt_msi_fail,
    output cfg_interrupt_msi_mmenable,
    input  cfg_interrupt_msi_pending_status,
    input  cfg_interrupt_msi_pending_status_function_num,
    input  cfg_interrupt_msi_pending_status_data_enable,
    output cfg_interrupt_msi_mask_update,
    input  cfg_interrupt_msi_select,
    output cfg_interrupt_msi_data,
    output cfg_interrupt_msix_enable,
    output cfg_interrupt_msix_mask,
    input  cfg_interrupt_msix_address,
    input  cfg_interrupt_msix_data,
    input  cfg_interrupt_msix_int,
    input  cfg_interrupt_msix_vec_pending,
    output cfg_interrupt_msix_vec_pending_status,
    input  cfg_interrupt_msix_ld_id,
    input  cfg_interrupt_msix_ld_id_valid,
    input  cfg_interrupt_msix_ide_valid,
    input  cfg_interrupt_msix_tbit,
    input  cfg_interrupt_msi_attr,
    input  cfg_interrupt_msi_tph_present,
    input  cfg_interrupt_msi_tph_type,
    input  cfg_interrupt_msi_tph_st_tag,
    input  cfg_interrupt_msi_function_number,
    output cfg_ext_read_received,
    output cfg_ext_write_received,
    output cfg_ext_register_number,
    output cfg_ext_function_number,
    output cfg_ext_write_data,
    output cfg_ext_write_byte_enable,
    input  cfg_ext_read_data,
    input  cfg_ext_read_data_valid,
    input  cfg_ext_send_completion,
    input  cfg_ext_compl_status,
    output cfg_ext_adv_swt_access,
    input  cfg_ext_read_debug1,
    output cfg_ext_write_debug1,
    output cfg_ccix_edr_data_rate_change_req,
    input  cfg_ccix_edr_data_rate_change_ack,
    output cfg_edr_enable,
    output cfg_pasid_enable,
    output cfg_pasid_exec_permission_enable,
    output cfg_pasid_privil_mode_enable,
    output spare_outputs,
    input  spare_inputs
  );
endinterface : cpm5n_pl_pciex4_axi_if

interface dpu_fabric_channel_if();
  localparam int TDATA_WIDTH = 256;

  logic tvalid;
  logic tready;
  logic [TDATA_WIDTH-1:0] tdata;
  logic tlast;

  modport master (
    output tvalid,
    input  tready,
    output tdata,
    output tlast
  );

  modport slave (
    input  tvalid,
    output tready,
    input  tdata,
    input  tlast
  );

endinterface : dpu_fabric_channel_if

interface dpu_fabric_command_if;
  localparam int TDATA_WIDTH = 256;
  localparam int TID_WIDTH   = 2; // Width based on conversation with David Riddoch

  logic tvalid;
  logic tready;
  logic [TDATA_WIDTH-1:0] tdata;
  logic tlast;
  logic [TID_WIDTH-1:0] tid;

  modport master (
    output tvalid,
    input  tready,
    output tdata,
    output tlast,
    output tid
  );

  modport slave (
    input  tvalid,
    output tready,
    input  tdata,
    input  tlast,
    input  tid
  );
endinterface : dpu_fabric_command_if

interface dpu_fabric_credit_if ();
  logic [7:0] data;

  modport master (
    output data
  );

  modport slave (
    input  data
  );

  // Used for verification monitoring connections and binds
  // e.g. testbench grey-box probes, assertion checkers etc.
  modport passive (
    input  data
  );

endinterface : dpu_fabric_credit_if

interface pcie5n_port_1024b_pcie_axi_if();

  logic [2:0]   pcie_cq_np_req; // gate 'b0
  logic [7:0]   pcie_cq_np_req_count;

  logic [39:0]  pcie_rq_tag;
  logic [3:0]   pcie_rq_tag_vld;
                // 0000 - No Tags allocated in this cycle
                // 0001 - Tag for the first request is on pcie_rq_tag[9:0].
                // 0011 - Tags for the first and second requests are  on pcie_rq_tag[9:0] and pcie_rq_tag[19:10].
                // 0111 - Tags for the first, second and third requests are on pcie_rq_tag[9:0], pcie_rq_tag[19:10] and pcie_rq_tag[29:20].
                // 1111 - Tags for four requests are on pcie_rq_tag[9:0], pcie_rq_tag[19:10], pcie_rq_tag[29:20] and pcie_rq_tag[39:30].

  logic [7:0]   pcie_rq_seq_num0;
  logic [7:0]   pcie_rq_seq_num1;
  logic [7:0]   pcie_rq_seq_num2;
  logic [7:0]   pcie_rq_seq_num3;
  logic [3:0]   pcie_rq_seq_num_vld;
                // 0000 - No sequence number outputs are valid in this cycle,
                // 0001 - Sequence number on pcie_rq_seq_num0 output is valid.,
                // 0011 - Sequence numbers on pcie_rq_seq_num0 and pcie_rq_seq_num1 outputs are valid.,
                // 0111 - Sequence numbers on pcie_rq_seq_num0,  pcie_rq_seq_num1 and pcie_rq_seq_num2 outputs are valid.,
                // 1111 - Sequence numbers on pcie_rq_seq_num0,  pcie_rq_seq_num1, pcie_rq_seq_num2 and pcie_rq_seq_num3outputs are valid.,
                // All other encodings are reserved.

  logic [7:0]   pcie_tfc_nph_av;
                // 0000 - No credit available.
                // 0001 - 1 credit available
                // 0010 - 2 credits available
                // ...
                // 1110 - 14 credits available
                // 1111 -  15 or more credits available.

  logic [7:0]   pcie_tfc_npd_av;
                // 0000 - No credit available.
                // 0001 - 1 credit available
                // 0010 - 2 credits available
                // ...
                // 1110 - 14 credits available
                // 1111 -  15 or more credits available.

  logic [7:0]   pcie_rq_tag_av;
                // 0000 - No credit available.
                // 0001 - 1 credit available
                // 0010 - 2 credits available
                // ...
                // 1110 - 14 credits available
                // 1111 -  15 or more credits available.

  modport s (
    input  pcie_cq_np_req,
    output pcie_cq_np_req_count,

    output pcie_rq_tag,
    output pcie_rq_tag_vld,

    output pcie_rq_seq_num0,
    output pcie_rq_seq_num1,
    output pcie_rq_seq_num2,
    output pcie_rq_seq_num3,
    output pcie_rq_seq_num_vld,

    output pcie_tfc_nph_av,
    output pcie_tfc_npd_av,
    output pcie_rq_tag_av
  );

  modport m (
    output pcie_cq_np_req,
    input  pcie_cq_np_req_count,

    input  pcie_rq_tag,
    input  pcie_rq_tag_vld,

    input  pcie_rq_seq_num0,
    input  pcie_rq_seq_num1,
    input  pcie_rq_seq_num2,
    input  pcie_rq_seq_num3,
    input  pcie_rq_seq_num_vld,

    input  pcie_tfc_nph_av,
    input  pcie_tfc_npd_av,
    input  pcie_rq_tag_av
  );

endinterface : pcie5n_port_1024b_pcie_axi_if

// 512b, 256b, 128b and 64b interfaces are overlayed
interface pcie5n_port_axis_1024b_cc_ext_if();
  wire [1023:0] axis_cc_tdata; // External Input Flops Needed
  wire          axis_cc_tlast; // External Input Flop Needed
  wire [31:0]   axis_cc_tkeep; // External Input Flops Needed
  wire          axis_cc_tvalid; // External Input Flop Needed
  wire [7:0]    axis_cc_tready; // No External Input Flop should be added
  wire [272:0]  axis_cc_tuser;  // External Input Flops Needed  // was 164:0 ??

  modport s (
    input  axis_cc_tdata,
    input  axis_cc_tlast,
    input  axis_cc_tkeep,
    input  axis_cc_tvalid,
    output axis_cc_tready,
    input  axis_cc_tuser
  );

  modport m (
    output axis_cc_tdata,
    output axis_cc_tlast,
    output axis_cc_tkeep,
    output axis_cc_tvalid,
    input  axis_cc_tready,
    output axis_cc_tuser
  );

endinterface : pcie5n_port_axis_1024b_cc_ext_if

// 512b, 256b, 128b and 64b interfaces are overlayed
interface pcie5n_port_axis_1024b_rq_ext_if();
  wire [1023:0] axis_rq_tdata;  // Needs External Input Flops
  wire          axis_rq_tlast;  // Needs External Input Flop
  wire [31:0]   axis_rq_tkeep;   // Needs External Input Flops
  wire          axis_rq_tvalid;  // Needs External Input Flop
  wire [7:0]    axis_rq_tready;  // No External Output Flops should be added
  wire [456:0]  axis_rq_tuser;   // Needs External Input Flops // was 448:0

  modport s (
    input  axis_rq_tdata,
    input  axis_rq_tlast,
    input  axis_rq_tkeep,
    input  axis_rq_tvalid,
    input  axis_rq_tuser,
    output axis_rq_tready
  );

  modport m (
    output axis_rq_tdata,
    output axis_rq_tlast,
    output axis_rq_tkeep,
    output axis_rq_tvalid,
    input  axis_rq_tready,
    output axis_rq_tuser
  );

endinterface : pcie5n_port_axis_1024b_rq_ext_if

// CQ and RC are unified, 512b and 256b interfaces are overlayed
interface pcie5n_port_axis_unified_1024b_cq_ext_if();

  logic [1023:0] axis_cq_tdata;     // External Output Flops Needed
  logic         axis_cq_tlast;      // External Output Flop Needed
  logic         axis_rc_tlast;      // External Output Flop Needed
  logic [31:0]  axis_cq_tkeep;      // External Output Flops Needed
  logic [59:0]  pcie_axis_cq_ready; // There should be No Input Flops on these inputs,
  logic [59:0]  pcie_axis_rc_ready; // There should be No Input Flops on these inputs,
  logic         pcie_axis_cq_vld;   // External Output Flop is Needed
  logic         pcie_axis_rc_vld;   // External Output Flop is Needed
  logic         pcie_axis_cq_rts;   // There should be No Input Flop on this input,
  logic         pcie_axis_rc_rts;   // there should be No Input Flop on this input,
  logic [572:0] axis_cq_tuser;      // External Output Flops Needed // was 532:0

  modport m (
    output axis_cq_tdata,
    output axis_cq_tlast,
    output axis_rc_tlast,
    output axis_cq_tkeep,
    input  pcie_axis_cq_ready,
    input  pcie_axis_rc_ready,
    output pcie_axis_cq_vld,
    output pcie_axis_rc_vld,
    input  pcie_axis_cq_rts,
    input  pcie_axis_rc_rts,
    output axis_cq_tuser
  );

  modport s (
    input  axis_cq_tdata,
    input  axis_cq_tlast,
    input  axis_rc_tlast,
    input  axis_cq_tkeep,
    output pcie_axis_cq_ready,
    output pcie_axis_rc_ready,
    input  pcie_axis_cq_vld,
    input  pcie_axis_rc_vld,
    output pcie_axis_cq_rts,
    output pcie_axis_rc_rts,
    input  axis_cq_tuser
  );

endinterface : pcie5n_port_axis_unified_1024b_cq_ext_if

interface pcie5n_port_cfg_pl_if;
// External Output Flops Needed on all cfg ports
// External Input  Flops Needed on all cfg ports except those marked register-input  only,
  logic [ 1:0]  cfg_ptm_spare_in;
  logic [ 1:0]  cfg_ptm_spare_out;
  logic         cfg_ide_transit_to_insecure;
  logic [13:0]  cfg_msix_int_tph_data_in;
  logic [13:0]  cfg_msix_int_tph_data_out;
  logic [ 1:0]  cfg_cxl_pm_credit_avail;
  logic [ 3:0]  cfg_vlsm_io;
  logic [ 3:0]  cfg_vlsm_cachemem;
  logic         cfg_wrreq_flr_vld;
  logic         cfg_wrreq_msi_vld;
  logic         cfg_wrreq_msix_vld;
  logic         cfg_wrreq_bme_vld;
  logic         cfg_wrreq_vfe_vld;
  logic [15:0]  cfg_wrreq_func_num;
  logic [ 3:0]  cfg_wrreq_out_value;
  logic [23:0]  cfg_perfunc_out;
  logic         cfg_perfunc_vld;
  logic [15:0]  cfg_perfunc_func_num;
  logic         cfg_perfunc_req;
  logic [9:0]   cfg_mgmt_addr;
  logic [15:0]  cfg_mgmt_function_number;
  logic         cfg_mgmt_write;
  logic [31:0]  cfg_mgmt_write_data;
  logic [3:0]   cfg_mgmt_byte_enable;
  logic         cfg_mgmt_read;
  logic [31:0]  cfg_mgmt_read_data;
  logic         cfg_mgmt_read_write_done;
  logic         cfg_mgmt_debug_access;
  logic         cfg_phy_link_down;
  logic [1:0]   cfg_phy_link_status;
  logic [2:0]   cfg_negotiated_width;
  logic [2:0]   cfg_current_speed;
  logic [1:0]   cfg_max_payload;
  logic [2:0]   cfg_max_read_req;
  logic [3:0]   cfg_function_status;
  logic [2:0]   cfg_function_power_state;
  logic [1:0]   cfg_link_power_state;
  logic         cfg_err_cor_out;
  logic         cfg_err_nonfatal_out;
  logic         cfg_err_fatal_out;
  logic         cfg_local_error_valid;
  logic [5:0]   cfg_local_error_out;
  logic [5:0]   cfg_ltssm_state;
  logic [1:0]   cfg_rx_pm_state;
  logic [1:0]   cfg_tx_pm_state;
  logic         cfg_rcb_status;
  logic         cfg_atomic_requester_enable;
  logic         cfg_10b_tag_requester_enable;
  logic         cfg_pl_status_change;
  logic         cfg_ext_tag_enable;
  logic         cfg_vc1_enable;
  logic         cfg_vc1_negotiation_pending;
  logic         cfg_msg_received;
  logic [7:0]   cfg_msg_received_data;
  logic [4:0]   cfg_msg_received_type;
  logic         cfg_msg_transmit;
  logic [2:0]   cfg_msg_transmit_type;
  logic [31:0]  cfg_msg_transmit_data;
  logic         cfg_msg_transmit_done;
  logic [11:0]  cfg_fc_ph;
  logic [1:0]   cfg_fc_ph_scale;
  logic [15:0]  cfg_fc_pd;
  logic [1:0]   cfg_fc_pd_scale;
  logic [11:0]  cfg_fc_nph;
  logic [1:0]   cfg_fc_nph_scale;
  logic [15:0]  cfg_fc_npd;
  logic [1:0]   cfg_fc_npd_scale;
  logic [11:0]  cfg_fc_cplh;
  logic [1:0]   cfg_fc_cplh_scale;
  logic [15:0]  cfg_fc_cpld;
  logic [1:0]   cfg_fc_cpld_scale;
  logic [2:0]   cfg_fc_sel;
  logic         cfg_fc_vc_sel;
  logic         cfg_hot_reset_in;
  logic         cfg_hot_reset_out;
  logic [7:0]   cfg_bus_number;
  logic         cfg_power_state_change_ack;
  logic         cfg_power_state_change_interrupt;
  logic         cfg_err_cor_in;
  logic         cfg_err_uncor_in;
  logic         cfg_flr_done;
  logic [15:0]  cfg_flr_done_func_num;
  logic [3:0]   cfg_interrupt_int;
  logic         cfg_interrupt_sent;
  logic [31:0]  cfg_interrupt_pending;
  logic         cfg_interrupt_msi_enable;
  logic [31:0]  cfg_interrupt_msi_int;
  logic         cfg_interrupt_msi_sent;
  logic         cfg_interrupt_msi_fail;
  logic [ 2:0]  cfg_interrupt_msi_mmenable;
  logic [31:0]  cfg_interrupt_msi_pending_status;
  logic [4:0]   cfg_interrupt_msi_pending_status_function_num;
  logic         cfg_interrupt_msi_pending_status_data_enable;
  logic         cfg_interrupt_msi_mask_update;
  logic [4:0]   cfg_interrupt_msi_select;
  logic [31:0]  cfg_interrupt_msi_data;
  logic         cfg_interrupt_msix_enable;
  logic         cfg_interrupt_msix_mask;
  logic [63:0]  cfg_interrupt_msix_address;
  logic [31:0]  cfg_interrupt_msix_data;
  logic         cfg_interrupt_msix_int;
  logic [1:0]   cfg_interrupt_msix_vec_pending;
  logic         cfg_interrupt_msix_vec_pending_status;
  logic [15:0]  cfg_interrupt_msix_ld_id;
  logic         cfg_interrupt_msix_ld_id_valid;
  logic         cfg_interrupt_msix_ide_valid;
  logic         cfg_interrupt_msix_tbit;
  logic [2:0]   cfg_interrupt_msi_attr;
  logic         cfg_interrupt_msi_tph_present;
  logic [1:0]   cfg_interrupt_msi_tph_type;
  logic [7:0]   cfg_interrupt_msi_tph_st_tag;
  logic [15:0]  cfg_interrupt_msi_function_number;
  logic         cfg_ext_read_received;
  logic         cfg_ext_write_received;
  logic [9:0]   cfg_ext_register_number;
  logic [15:0]  cfg_ext_function_number;
  logic [31:0]  cfg_ext_write_data;
  logic [3:0]   cfg_ext_write_byte_enable;
  logic [31:0]  cfg_ext_read_data;
  logic         cfg_ext_read_data_valid;
  logic         cfg_ext_send_completion;
  logic [2:0]   cfg_ext_compl_status;
  logic         cfg_ext_adv_swt_access;
  logic [31:0]  cfg_ext_read_debug1;
  logic [31:0]  cfg_ext_write_debug1;
  logic         cfg_ccix_edr_data_rate_change_req;
  logic         cfg_ccix_edr_data_rate_change_ack;
  logic         cfg_edr_enable;
  logic         cfg_pasid_enable;
  logic         cfg_pasid_exec_permission_enable;
  logic         cfg_pasid_privil_mode_enable;
  logic [15:0]  spare_outputs;
  logic [15:0]  spare_inputs;

  modport m (
    input  cfg_ptm_spare_in,
    output cfg_ptm_spare_out,
    output cfg_ide_transit_to_insecure,
    input  cfg_msix_int_tph_data_in,
    output cfg_msix_int_tph_data_out,
    output cfg_cxl_pm_credit_avail,
    output cfg_vlsm_io,
    output cfg_vlsm_cachemem,
    output cfg_wrreq_flr_vld,
    output cfg_wrreq_msi_vld,
    output cfg_wrreq_msix_vld,
    output cfg_wrreq_bme_vld,
    output cfg_wrreq_vfe_vld,
    output cfg_wrreq_func_num,
    output cfg_wrreq_out_value,
    output cfg_perfunc_out,
    output cfg_perfunc_vld,
    input  cfg_perfunc_func_num,
    input  cfg_perfunc_req,
    input  cfg_mgmt_addr,
    input  cfg_mgmt_function_number,
    input  cfg_mgmt_write,
    input  cfg_mgmt_write_data,
    input  cfg_mgmt_byte_enable,
    input  cfg_mgmt_read,
    output cfg_mgmt_read_data,
    output cfg_mgmt_read_write_done,
    input  cfg_mgmt_debug_access,
    output cfg_phy_link_down,
    output cfg_phy_link_status,
    output cfg_negotiated_width,
    output cfg_current_speed,
    output cfg_max_payload,
    output cfg_max_read_req,
    output cfg_function_status,
    output cfg_function_power_state,
    output cfg_link_power_state,
    output cfg_err_cor_out,
    output cfg_err_nonfatal_out,
    output cfg_err_fatal_out,
    output cfg_local_error_valid,
    output cfg_local_error_out,
    output cfg_ltssm_state,
    output cfg_rx_pm_state,
    output cfg_tx_pm_state,
    output cfg_rcb_status,
    output cfg_atomic_requester_enable,
    output cfg_10b_tag_requester_enable,
    output cfg_pl_status_change,
    output cfg_ext_tag_enable,
    output cfg_vc1_enable,
    output cfg_vc1_negotiation_pending,
    output cfg_msg_received,
    output cfg_msg_received_data,
    output cfg_msg_received_type,
    input  cfg_msg_transmit,
    input  cfg_msg_transmit_type,
    input  cfg_msg_transmit_data,
    output cfg_msg_transmit_done,
    output cfg_fc_ph,
    output cfg_fc_ph_scale,
    output cfg_fc_pd,
    output cfg_fc_pd_scale,
    output cfg_fc_nph,
    output cfg_fc_nph_scale,
    output cfg_fc_npd,
    output cfg_fc_npd_scale,
    output cfg_fc_cplh,
    output cfg_fc_cplh_scale,
    output cfg_fc_cpld,
    output cfg_fc_cpld_scale,
    input  cfg_fc_sel,
    input  cfg_fc_vc_sel,
    input  cfg_hot_reset_in,
    output cfg_hot_reset_out,
    output cfg_bus_number,
    input  cfg_power_state_change_ack,
    output cfg_power_state_change_interrupt,
    input  cfg_err_cor_in,
    input  cfg_err_uncor_in,
    input  cfg_flr_done,
    input  cfg_flr_done_func_num,
    input  cfg_interrupt_int,
    output cfg_interrupt_sent,
    input  cfg_interrupt_pending,
    output cfg_interrupt_msi_enable,
    input  cfg_interrupt_msi_int,
    output cfg_interrupt_msi_sent,
    output cfg_interrupt_msi_fail,
    output cfg_interrupt_msi_mmenable,
    input  cfg_interrupt_msi_pending_status,
    input  cfg_interrupt_msi_pending_status_function_num,
    input  cfg_interrupt_msi_pending_status_data_enable,
    output cfg_interrupt_msi_mask_update,
    input  cfg_interrupt_msi_select,
    output cfg_interrupt_msi_data,
    output cfg_interrupt_msix_enable,
    output cfg_interrupt_msix_mask,
    input  cfg_interrupt_msix_address,
    input  cfg_interrupt_msix_data,
    input  cfg_interrupt_msix_int,
    input  cfg_interrupt_msix_vec_pending,
    output cfg_interrupt_msix_vec_pending_status,
    input  cfg_interrupt_msix_ld_id,
    input  cfg_interrupt_msix_ld_id_valid,
    input  cfg_interrupt_msix_ide_valid,
    input  cfg_interrupt_msix_tbit,
    input  cfg_interrupt_msi_attr,
    input  cfg_interrupt_msi_tph_present,
    input  cfg_interrupt_msi_tph_type,
    input  cfg_interrupt_msi_tph_st_tag,
    input  cfg_interrupt_msi_function_number,
    output cfg_ext_read_received,
    output cfg_ext_write_received,
    output cfg_ext_register_number,
    output cfg_ext_function_number,
    output cfg_ext_write_data,
    output cfg_ext_write_byte_enable,
    input  cfg_ext_read_data,
    input  cfg_ext_read_data_valid,
    input  cfg_ext_send_completion,
    input  cfg_ext_compl_status,
    output cfg_ext_adv_swt_access,
    input  cfg_ext_read_debug1,
    output cfg_ext_write_debug1,
    output cfg_ccix_edr_data_rate_change_req,
    input  cfg_ccix_edr_data_rate_change_ack,
    output cfg_edr_enable,
    output cfg_pasid_enable,
    output cfg_pasid_exec_permission_enable,
    output cfg_pasid_privil_mode_enable,
    output spare_outputs,
    input  spare_inputs
  );

  modport s (
    output cfg_ptm_spare_in,
    input  cfg_ptm_spare_out,
    input  cfg_ide_transit_to_insecure,
    output cfg_msix_int_tph_data_in,
    input  cfg_msix_int_tph_data_out,
    input  cfg_cxl_pm_credit_avail,
    input  cfg_vlsm_io,
    input  cfg_vlsm_cachemem,
    input  cfg_wrreq_flr_vld,
    input  cfg_wrreq_msi_vld,
    input  cfg_wrreq_msix_vld,
    input  cfg_wrreq_bme_vld,
    input  cfg_wrreq_vfe_vld,
    input  cfg_wrreq_func_num,
    input  cfg_wrreq_out_value,
    input  cfg_perfunc_out,
    input  cfg_perfunc_vld,
    output cfg_perfunc_func_num,
    output cfg_perfunc_req,
    output cfg_mgmt_addr,
    output cfg_mgmt_function_number,
    output cfg_mgmt_write,
    output cfg_mgmt_write_data,
    output cfg_mgmt_byte_enable,
    output cfg_mgmt_read,
    input  cfg_mgmt_read_data,
    input  cfg_mgmt_read_write_done,
    output cfg_mgmt_debug_access,
    input  cfg_phy_link_down,
    input  cfg_phy_link_status,
    input  cfg_negotiated_width,
    input  cfg_current_speed,
    input  cfg_max_payload,
    input  cfg_max_read_req,
    input  cfg_function_status,
    input  cfg_function_power_state,
    input  cfg_link_power_state,
    input  cfg_err_cor_out,
    input  cfg_err_nonfatal_out,
    input  cfg_err_fatal_out,
    input  cfg_local_error_valid,
    input  cfg_local_error_out,
    input  cfg_ltssm_state,
    input  cfg_rx_pm_state,
    input  cfg_tx_pm_state,
    input  cfg_rcb_status,
    input  cfg_atomic_requester_enable,
    input  cfg_10b_tag_requester_enable,
    input  cfg_pl_status_change,
    input  cfg_ext_tag_enable,
    input  cfg_vc1_enable,
    input  cfg_vc1_negotiation_pending,
    input  cfg_msg_received,
    input  cfg_msg_received_data,
    input  cfg_msg_received_type,
    output cfg_msg_transmit,
    output cfg_msg_transmit_type,
    output cfg_msg_transmit_data,
    input  cfg_msg_transmit_done,
    input  cfg_fc_ph,
    input  cfg_fc_ph_scale,
    input  cfg_fc_pd,
    input  cfg_fc_pd_scale,
    input  cfg_fc_nph,
    input  cfg_fc_nph_scale,
    input  cfg_fc_npd,
    input  cfg_fc_npd_scale,
    input  cfg_fc_cplh,
    input  cfg_fc_cplh_scale,
    input  cfg_fc_cpld,
    input  cfg_fc_cpld_scale,
    output cfg_fc_sel,
    output cfg_fc_vc_sel,
    output cfg_hot_reset_in,
    input  cfg_hot_reset_out,
    input  cfg_bus_number,
    output cfg_power_state_change_ack,
    input  cfg_power_state_change_interrupt,
    output cfg_err_cor_in,
    output cfg_err_uncor_in,
    output cfg_flr_done,
    output cfg_flr_done_func_num,
    output cfg_interrupt_int,
    input  cfg_interrupt_sent,
    output cfg_interrupt_pending,
    input  cfg_interrupt_msi_enable,
    output cfg_interrupt_msi_int,
    input  cfg_interrupt_msi_sent,
    input  cfg_interrupt_msi_fail,
    input  cfg_interrupt_msi_mmenable,
    output cfg_interrupt_msi_pending_status,
    output cfg_interrupt_msi_pending_status_function_num,
    output cfg_interrupt_msi_pending_status_data_enable,
    input  cfg_interrupt_msi_mask_update,
    output cfg_interrupt_msi_select,
    input  cfg_interrupt_msi_data,
    input  cfg_interrupt_msix_enable,
    input  cfg_interrupt_msix_mask,
    output cfg_interrupt_msix_address,
    output cfg_interrupt_msix_data,
    output cfg_interrupt_msix_int,
    output cfg_interrupt_msix_vec_pending,
    input  cfg_interrupt_msix_vec_pending_status,
    output cfg_interrupt_msix_ld_id,
    output cfg_interrupt_msix_ld_id_valid,
    output cfg_interrupt_msix_ide_valid,
    output cfg_interrupt_msix_tbit,
    output cfg_interrupt_msi_attr,
    output cfg_interrupt_msi_tph_present,
    output cfg_interrupt_msi_tph_type,
    output cfg_interrupt_msi_tph_st_tag,
    output cfg_interrupt_msi_function_number,
    input  cfg_ext_read_received,
    input  cfg_ext_write_received,
    input  cfg_ext_register_number,
    input  cfg_ext_function_number,
    input  cfg_ext_write_data,
    input  cfg_ext_write_byte_enable,
    output cfg_ext_read_data,
    output cfg_ext_read_data_valid,
    output cfg_ext_send_completion,
    output cfg_ext_compl_status,
    input  cfg_ext_adv_swt_access,
    output cfg_ext_read_debug1,
    input  cfg_ext_write_debug1,
    input  cfg_ccix_edr_data_rate_change_req,
    output cfg_ccix_edr_data_rate_change_ack,
    input  cfg_edr_enable,
    input  cfg_pasid_enable,
    input  cfg_pasid_exec_permission_enable,
    input  cfg_pasid_privil_mode_enable,
    input  spare_outputs,
    output spare_inputs
  );
endinterface: pcie5n_port_cfg_pl_if

interface pcie5n_port_cxl_ext_if;

  logic [1535:0] cxl_rx_data;
  logic [50:0]  cxl_rx_crc;
  logic [215:0] cxl_rx_parity;
  logic [2:0]   cxl_rx_valid;
  logic [2:0]   cxl_rx_viral;
  logic [2:0]   cxl_rx_all_data_flit;

  logic [1535:0] cxl_tx_data;
  logic [50:0]  cxl_tx_crc;
  logic [215:0] cxl_tx_parity;
  logic [2:0]   cxl_tx_valid;
  logic [5:0]   cxl_tx_ready;
  logic [2:0]   cxl_tx_viral;
  logic [2:0]   cxl_tx_all_data_flit;

  logic [3:0]   cxl_crd_resp_mem;
  logic         cxl_crd_resp_mem_vld;
  logic [3:0]   cxl_crd_data_mem;
  logic         cxl_crd_data_mem_vld;
  logic [3:0]   cxl_crd_req_mem;
  logic         cxl_crd_req_mem_vld;
  logic [3:0]   cxl_crd_resp_cache;
  logic         cxl_crd_resp_cache_vld;
  logic [3:0]   cxl_crd_data_cache;
  logic         cxl_crd_data_cache_vld;
  logic [3:0]   cxl_crd_req_cache;
  logic         cxl_crd_req_cache_vld;
  logic         cxl_pm_l1_enable;
  logic         cxl_pm_mem_recovery;
  logic         cxl_pm_mem_link_down;
  logic         cxl_reset;

  modport m (
    output cxl_rx_data,
    output cxl_rx_crc,
    output cxl_rx_parity,
    output cxl_rx_valid,
    output cxl_rx_viral,
    output cxl_rx_all_data_flit,

    input  cxl_tx_data,
    input  cxl_tx_crc,
    input  cxl_tx_parity,
    input  cxl_tx_valid,
    output cxl_tx_ready,
    input  cxl_tx_viral,
    input  cxl_tx_all_data_flit,

    input  cxl_crd_resp_mem,
    input  cxl_crd_resp_mem_vld,
    input  cxl_crd_data_mem,
    input  cxl_crd_data_mem_vld,
    input  cxl_crd_req_mem,
    input  cxl_crd_req_mem_vld,
    input  cxl_crd_resp_cache,
    input  cxl_crd_resp_cache_vld,
    input  cxl_crd_data_cache,
    input  cxl_crd_data_cache_vld,
    input  cxl_crd_req_cache,
    input  cxl_crd_req_cache_vld,
    input  cxl_pm_l1_enable,
    input  cxl_pm_mem_recovery,
    input  cxl_pm_mem_link_down,
    output cxl_reset
  );

  modport s (
    input  cxl_rx_data,
    input  cxl_rx_crc,
    input  cxl_rx_parity,
    input  cxl_rx_valid,
    input  cxl_rx_viral,
    input  cxl_rx_all_data_flit,

    output cxl_tx_data,
    output cxl_tx_crc,
    output cxl_tx_parity,
    output cxl_tx_valid,
    input  cxl_tx_ready,
    output cxl_tx_viral,
    output cxl_tx_all_data_flit,

    output cxl_crd_resp_mem,
    output cxl_crd_resp_mem_vld,
    output cxl_crd_data_mem,
    output cxl_crd_data_mem_vld,
    output cxl_crd_req_mem,
    output cxl_crd_req_mem_vld,
    output cxl_crd_resp_cache,
    output cxl_crd_resp_cache_vld,
    output cxl_crd_data_cache,
    output cxl_crd_data_cache_vld,
    output cxl_crd_req_cache,
    output cxl_crd_req_cache_vld,
    output cxl_pm_l1_enable,
    output cxl_pm_mem_recovery,
    output cxl_pm_mem_link_down,
    input  cxl_reset
  );
endinterface: pcie5n_port_cxl_ext_if

// C2H / ST2M DAT
interface cdx5n_c2h_st2m_dat_if
  import cpm5n_v1_0_1_pkg::*;
#()();

  cdx_c2h_st2m_dat_t intf;
  logic vld;
  logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

// C2H_ST_BYP_IN / ST2M_REQ
interface cdx5n_c2h_st_byp_in_st2m_req_if
  import cpm5n_v1_0_1_pkg::*;
#()();

    cdx_c2h_st_byp_in_st2m_req_t intf;
    logic vld;
    logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

interface cdx5n_c2h_st_pld_cmpt_crdt_if
  import cpm5n_v1_0_1_pkg::*;
#()();

    cdx_c2h_pld_cmpt_crdt_t intf;
    logic vld;
    logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

interface cdx5n_c2h_st_stat_if
  import cpm5n_v1_0_1_pkg::*;
#()();

    cdx_qdm_c2h_stat_ext_t intf;
    logic vld;
    logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

interface cdx5n_cdc_req_if
import cpm5n_v1_0_1_pkg::*;
 ();
  cdc_req_t req;
  logic rdy;
  logic vld;

  modport s (
    input  req,
    input  vld,
    output rdy
  );

  modport m(
    output req,
    output vld,
    input  rdy
  );

endinterface

interface cdx5n_cdc_resp_if
import cpm5n_v1_0_1_pkg::*;
();
  cdc_resp_t resp;
  logic rdy;
  logic vld;

  modport s (
    input  resp,
    input  vld,
    output rdy
  );

  modport m(
    output resp,
    output vld,
    input  rdy
  );

endinterface

// CMPT / MSGST
interface cdx5n_cmpt_msgst_if
  import cpm5n_v1_0_1_pkg::*;
#()();

    cdx_cmpt_msgst_t        intf;
    logic                   vld;
    logic                   rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

interface cdx5n_csi_local_crdt_if
import cpm5n_v1_0_1_pkg::*;
();

  logic [1:0]  local_crdt_snk_id;
  logic [1:0]  local_crdt_src_furc_id;
  csi_flow_t   local_crdt_flow_type;
  logic [6:0]  local_crdt_buf_id;
  logic [15:0] local_crdt;
  logic        local_crdt_vld;
  logic        local_crdt_rdy;

  modport m(
    output local_crdt_snk_id,
    output local_crdt_src_furc_id,
    output local_crdt_flow_type,
    output local_crdt_buf_id,
    output local_crdt,
    output local_crdt_vld,
    input  local_crdt_rdy
  );

  modport s(
    input  local_crdt_snk_id,
    input  local_crdt_src_furc_id,
    input  local_crdt_flow_type,
    input  local_crdt_buf_id,
    input  local_crdt,
    input  local_crdt_vld,
    output local_crdt_rdy
  );

  modport mon (
    input  local_crdt_snk_id,
    input local_crdt_src_furc_id,
    input  local_crdt_flow_type,
    input  local_crdt_buf_id,
    input  local_crdt,
    input  local_crdt_vld,
    input  local_crdt_rdy
  );

endinterface

interface cdx5n_csi_snk_sched_ser_ing_if
import cpm5n_v1_0_1_pkg::*;
();
  ks_sched_msg_t ser_ing_intf_in;
  logic          ser_ing_intf_vld;
  logic          ser_ing_intf_rdy;
//  logic          sched_alert;
 // logic          one_sec_pulse;

  modport m (
    output ser_ing_intf_in,
    output ser_ing_intf_vld,
    input  ser_ing_intf_rdy
//  output sched_alert,
//  input  one_sec_pulse
  );

  modport s (
    input  ser_ing_intf_in,
    input  ser_ing_intf_vld,
    output ser_ing_intf_rdy
//  output sched_alert,
//  input one_sec_pulse

  );

  modport mon (
    input  ser_ing_intf_in,
    input  ser_ing_intf_vld,
    input  ser_ing_intf_rdy
//  output sched_alert,
//  input one_sec_pulse

  );

endinterface

// DSC_CRD_IN / MSGLD_REQ
interface cdx5n_dsc_crd_in_msgld_req_if
  import cpm5n_v1_0_1_pkg::*;
#()();

  cdx_dsc_crd_in_msgld_req_t intf;
  logic vld;
  logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

interface cdx5n_fab_1s_seg_if ();
  logic [319:0] seg;
  logic sop;
  logic eop;
  logic err;
  logic vld;
  logic rdy;

  modport in (
    input  seg,
    input  vld,
    input  sop,
    input  eop,
    input  err,
    output rdy
  );

  modport out(
    output seg,
    output vld,
    output sop,
    output eop,
    output err,
    input  rdy
  );

endinterface

interface cdx5n_fab_2s_seg_if ();
  logic [1:0] [319:0] seg;
  logic [1:0] sop;
  logic [1:0] eop;
  logic [1:0] err;
  logic [1:0] vld;
  logic [1:0] rdy;

  modport in (
    input  seg,
    input  vld,
    input  sop,
    input  eop,
    input  err,
    output rdy
  );

  modport out(
    output seg,
    output vld,
    output sop,
    output eop,
    output err,
    input  rdy
  );

endinterface

interface cdx5n_fabric_flr_axil_if#(DATA_WIDTH = 32, ADDR_WIDTH = 32, USER_W = 13)();

  logic [ADDR_WIDTH-1:0] awaddr;
  logic awready;
  logic awvalid;
  logic [USER_W-1:0] awuser;
  logic [2:0] awprot;

  logic [ADDR_WIDTH-1:0] araddr;
  logic arready;
  logic arvalid;
  logic [USER_W-1:0] aruser;
  logic [2:0] arprot;

  logic [DATA_WIDTH-1:0]   wdata;
  logic [DATA_WIDTH/8-1:0] wdatainfo;
  logic [DATA_WIDTH/8-1:0] wstrb;
  logic wready;
  logic wvalid;

  logic [DATA_WIDTH-1:0]   rdata;
  logic [DATA_WIDTH/8-1:0] rdatainfo;
  logic [1:0] rresp;
  logic rready;
  logic rvalid;

  logic [1:0] bresp;
  logic bready;
  logic bvalid;

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
    ,input  wdatainfo
    ,input  wstrb
    ,output wready
    ,input  wvalid
    ,output rdata
    ,output rdatainfo
    ,output rresp
    ,input  rready
    ,output rvalid
    ,output bresp
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
    ,output wdatainfo
    ,output wstrb
    ,input  wready
    ,output wvalid
    ,input  rdata
    ,input  rdatainfo
    ,input  rresp
    ,output rready
    ,input  rvalid
    ,input  bresp
    ,output bready
    ,input  bvalid
  );

endinterface : cdx5n_fabric_flr_axil_if
 // IF_CDX5N_FABRIC_FLR_AXIL_IF

// H2C_ST_BYP_IN / M2ST_REQ
interface cdx5n_h2c_st_byp_in_m2st_req_if
  import cpm5n_v1_0_1_pkg::*;
#()();

    cdx_h2c_st_byp_in_m2st_req_t intf;
    logic vld;
    logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

// H2C-ST / M2ST DATA
interface cdx5n_h2c_st_m2st_dat_if
  import cpm5n_v1_0_1_pkg::*;
#()();

    cdx_h2c_st_m2st_dat_t intf;
    logic vld;
    logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

// MM_BYP_IN / M2M_REQ
interface cdx5n_mm_byp_in_m2m_req_if
  import cpm5n_v1_0_1_pkg::*;
#()();

    cdx_mm_byp_in_m2m_req_t intf;
    logic vld;
    logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

// BYP_OUT / RESP
interface cdx5n_mm_byp_out_rsp_if
  import cpm5n_v1_0_1_pkg::*;
#()();

    cdx_mm_byp_out_rsp_t intf;
    logic vld;
    logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

interface cdx5n_pkt_sched_ser_if
import cpm5n_v1_0_1_pkg::*;
();
  ks_sched_msg_t ser_intf_msg;
  logic ser_intf_vld;
  logic ser_intf_rdy;

  modport ing (
    input  ser_intf_msg,
    input  ser_intf_vld,
    output ser_intf_rdy
  );

  modport egr (
    output ser_intf_msg,
    output ser_intf_vld,
    input  ser_intf_rdy
  );
endinterface

// QDM.TM_DSC_STS
interface cdx5n_qdm_tm_dsc_sts_if
  import cpm5n_v1_0_1_pkg::*;
#()();

  qdm_tm_dsc_sts_t intf;
  logic vld;
  logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

// QDM.QSTS / CDM.RESP
interface cdx5n_qsts_rsp_if
  import cpm5n_v1_0_1_pkg::*;
#()();

  cdx_qsts_rsp_ext_t intf;
  logic vld;
  logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

// H2CST / M2ST NOTIF
interface cdx5n_rru_dst_crd_if
  import cpm5n_v1_0_1_pkg::*;
#()();

  cdm_rru_dst_crdt_t intf;
  logic vld;
  logic rdy;

  modport m (
    output intf,
    output vld,
    input  rdy
  );

  modport s (
    input  intf,
    input  vld,
    output rdy
  );

endinterface

interface ks_plugin_credit_msg_if #(DW = 6, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [3:0] fifo;
  logic [1:0] credit;
  logic [VW-1:0] msg_vld;
  logic [RW-1:0] msg_rdy;

  modport producer (
    output fifo,
    output credit,
    output msg_vld,
    input  msg_rdy
  );

  modport consumer (
    input  fifo,
    input  credit,
    input  msg_vld,
    output msg_rdy
  );

  modport snooper (
    input  fifo,
    input  credit,
    input  msg_vld,
    input  msg_rdy
  );

endinterface

interface ks_generic_meta_if #(DW = 224, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [223:0]    data;

  logic [VW-1:0]   sb_md_vld;
  logic [RW-1:0]   sb_md_rdy;

  modport producer (
    output data,
    output sb_md_vld,
    input  sb_md_rdy
  );

  modport consumer (
    input  data,
    input  sb_md_vld,
    output sb_md_rdy
  );

  modport snooper (
    input  data,
    input  sb_md_vld,
    input  sb_md_rdy
  );

endinterface

interface ks_generic_sfmd_if #(DW = 22, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [21:0]     data;

  logic [VW-1:0]   sb_md_vld;
  logic [RW-1:0]   sb_md_rdy;

  modport producer (
    output data,
    output sb_md_vld,
    input  sb_md_rdy
  );

  modport consumer (
    input  data,
    input  sb_md_vld,
    output sb_md_rdy
  );

  modport snooper (
    input  data,
    input  sb_md_vld,
    input  sb_md_rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: ks_smpl_sb_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface ks_smpl_sb_if #(DW = 522, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [1:0] err;
  logic [5:0] mty;
  logic       eop;
  logic       sop;
  logic [511:0] data;

  logic [VW-1:0]   sb_vld;
  logic [RW-1:0]   sb_rdy;

  modport producer (
    output err,
    output mty,
    output eop,
    output sop,
    output data,
    output sb_vld,
    input  sb_rdy
  );

  modport consumer (
    input  err,
    input  mty,
    input  eop,
    input  sop,
    input  data,
    input  sb_vld,
    output sb_rdy
  );

  modport snooper (
    input  err,
    input  mty,
    input  eop,
    input  sop,
    input  data,
    input  sb_vld,
    input  sb_rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: ks_smpl_sb1024_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface ks_smpl_sb1024_if #(DW = 1035, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [1:0] err;
  logic [6:0] mty;
  logic       eop;
  logic       sop;
  logic [1023:0] data;

  logic [VW-1:0] sb_vld;
  logic [RW-1:0] sb_rdy;

  modport producer (
    output err,
    output mty,
    output eop,
    output sop,
    output data,
    output sb_vld,
    input  sb_rdy
  );

  modport consumer (
    input  err,
    input  mty,
    input  eop,
    input  sop,
    input  data,
    input  sb_vld,
    output sb_rdy
  );

  modport snooper (
    input  err,
    input  mty,
    input  eop,
    input  sop,
    input  data,
    input  sb_vld,
    input  sb_rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_icsb_sb_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_icsb_sb_if #(DW = 586, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [63:0]  data_integrity;
  logic [1:0]   err;
  logic [5:0]   eop_mty;
  logic         eop;
  logic         sop;
  logic [511:0] data;

  logic [VW-1:0] icsb_vld;
  logic [RW-1:0] icsb_rdy;

  modport producer (
    output data_integrity,
    output err,
    output eop_mty,
    output eop,
    output sop,
    output data,
    output icsb_vld,
    input  icsb_rdy
  );

  modport consumer (
    input  data_integrity,
    input  err,
    input  eop_mty,
    input  eop,
    input  sop,
    input  data,
    input  icsb_vld,
    output icsb_rdy
  );

  modport snooper (
    input  data_integrity,
    input  err,
    input  eop_mty,
    input  eop,
    input  sop,
    input  data,
    input  icsb_vld,
    input  icsb_rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: ks_sched_msg_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface ks_sched_msg_if #(DW = 22, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [3:0]      mtype;
  logic            meop;
  logic            msop;
  logic [15:0]     mdata;

  logic [VW-1:0]   msg_vld;
  logic [RW-1:0]   msg_rdy;

  modport producer (
    output mtype,
    output meop,
    output msop,
    output mdata,
    output msg_vld,
    input  msg_rdy
  );

  modport consumer (
    input  mtype,
    input  meop,
    input  msop,
    input  mdata,
    input  msg_vld,
    output msg_rdy
  );

  modport snooper (
    input  mtype,
    input  meop,
    input  msop,
    input  mdata,
    input  msg_vld,
    input  msg_rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: ks_stat_msg_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface ks_stat_msg_if #(DW = 243, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [1:0]   iscb_err;
  logic [1:0]   pkt_dmac_type;
  logic [14:0]  pkt_len;
  logic [223:0] ph_rcvd;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output iscb_err,
    output pkt_dmac_type,
    output pkt_len,
    output ph_rcvd,
    output vld,
    input  rdy
  );

  modport consumer (
    input  iscb_err,
    input  pkt_dmac_type,
    input  pkt_len,
    input  ph_rcvd,
    input  vld,
    output rdy
  );

  modport snooper (
    input  iscb_err,
    input  pkt_dmac_type,
    input  pkt_len,
    input  ph_rcvd,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: ks_ts_info_msg_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface ks_ts_info_msg_if #(DW = 12, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [11:0] txq;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output txq,
    output vld,
    input  rdy
  );

  modport consumer (
    input  txq,
    input  vld,
    output rdy
  );

  modport snooper (
    input  txq,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: ks_plugin_ingress_notify_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface ks_plugin_ingress_notify_if #(DW = 20, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [3:0]  fifo;
  logic [15:0] bytes;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output fifo,
    output bytes,
    output vld,
    input  rdy
  );

  modport consumer (
    input  fifo,
    input  bytes,
    input  vld,
    output rdy
  );

  modport snooper (
    input  fifo,
    input  bytes,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: csr_to_mc_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface csr_to_mc_if #(DW = 35, VW = 1, RW = 1) (input bit clk);

  // Data
  logic ack;
  logic err;
  logic vld;
  logic [31:0] rdat;

  logic [VW-1:0] csr_vld;
  logic [RW-1:0] csr_rdy;

  modport producer (
    output ack,
    output err,
    output vld,
    output rdat,
    output csr_vld,
    input  csr_rdy
  );

  modport consumer (
    input  ack,
    input  err,
    input  vld,
    input  rdat,
    input  csr_vld,
    output csr_rdy
  );

  modport snooper (
    input  ack,
    input  err,
    input  vld,
    input  rdat,
    input  csr_vld,
    input  csr_rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: csr_from_mc_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface csr_from_mc_if #(DW = 66, VW = 1, RW = 1) (input bit clk);

  // Data
  logic req;
  logic wr;
  logic [31:0] addr;
  logic [31:0] wdat;

  logic [VW-1:0] csr_vld;
  logic [RW-1:0] csr_rdy;

  modport producer (
    output req,
    output wr,
    output addr,
    output wdat,
    output csr_vld,
    input  csr_rdy
  );

  modport consumer (
    input  req,
    input  wr,
    input  addr,
    input  wdat,
    input  csr_vld,
    output csr_rdy
  );

  modport snooper (
    input  req,
    input  wr,
    input  addr,
    input  wdat,
    input  csr_vld,
    input  csr_rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: ks_mac_fc_msg_if_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface ks_mac_fc_msg_if_if #(DW = 11, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [7:0] pause_mask;
  logic [2:0] port_id;

  logic [VW-1:0] msg_vld;
  logic [RW-1:0] msg_rdy;

  modport producer (
    output pause_mask,
    output port_id,
    output msg_vld,
    input  msg_rdy
  );

  modport consumer (
    input  pause_mask,
    input  port_id,
    input  msg_vld,
    output msg_rdy
  );

  modport snooper (
    input  pause_mask,
    input  port_id,
    input  msg_vld,
    input  msg_rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: ks_net_fc_msg_if_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface ks_net_fc_msg_if_if #(DW = 7, VW = 1, RW = 1) (input bit clk);

  // Data
  logic opcode;
  logic [2:0] pri_id;
  logic [2:0] port_id;

  logic [VW-1:0] msg_vld;
  logic [RW-1:0] msg_rdy;

  modport producer (
    output opcode,
    output pri_id,
    output port_id,
    output msg_vld,
    input  msg_rdy
  );

  modport consumer (
    input  opcode,
    input  pri_id,
    input  port_id,
    input  msg_vld,
    output msg_rdy
  );

  modport snooper (
    input  opcode,
    input  pri_id,
    input  port_id,
    input  msg_vld,
    input  msg_rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: ks_fc_fifo_stall_if_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface ks_fc_fifo_stall_if_if #(DW = 9, VW = 1, RW = 1) (input bit clk);

  // Data
  logic pause;
  logic [7:0] fifo_id;

  logic [VW-1:0] msg_vld;
  logic [RW-1:0] msg_rdy;

  modport producer (
    output pause,
    output fifo_id,
    output msg_vld,
    input  msg_rdy
  );

  modport consumer (
    input  pause,
    input  fifo_id,
    input  msg_vld,
    output msg_rdy
  );

  modport snooper (
    input  pause,
    input  fifo_id,
    input  msg_vld,
    input  msg_rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_mas_context_r1_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_mas_context_r1_hdr_if #(DW = 194, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [96:0] rsrvd;
  logic        vntx_drop;
  logic [13:0] orig_len;
  logic [15:0] mport;
  logic        user_flag;
  logic [31:0] user_mark;
  logic        timestamp_req;
  logic [31:0] partial_timestamp;

  logic [VW-1:0]   vld;
  logic [RW-1:0]   rdy;

  modport producer (
    output rsrvd,
    output vntx_drop,
    output orig_len,
    output mport,
    output user_flag,
    output user_mark,
    output timestamp_req,
    output partial_timestamp,
    output vld,
    input  rdy
  );

  modport consumer (
    input  rsrvd,
    input  vntx_drop,
    input  orig_len,
    input  mport,
    input  user_flag,
    input  user_mark,
    input  timestamp_req,
    input  partial_timestamp,
    input  vld,
    output rdy
  );

  modport snooper (
    input  rsrvd,
    input  vntx_drop,
    input  orig_len,
    input  mport,
    input  user_flag,
    input  user_mark,
    input  timestamp_req,
    input  partial_timestamp,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_nic_rx_socket_context_r1_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_nic_rx_socket_context_r1_hdr_if #(DW = 194, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [23:0] rsrvd;
  logic        first_replay;
  logic        action_drop;
  logic [11:0] action_lport_rel_qid;
  logic        action_rss_en;
  logic [7:0]  action_rss_ctx_id;
  logic [31:0] action_mark_val;
  logic        action_set_flag;
  logic        action_strip_fcs;
  logic        vntx_drop;
  logic [13:0] orig_len;
  logic [15:0] egress_mport;
  logic [15:0] ingress_mport;
  logic        user_flag;
  logic [31:0] user_mark;
  logic        timestamp_req;
  logic [31:0] partial_timestamp;

  logic [VW-1:0]   vld;
  logic [RW-1:0]   rdy;

  modport producer (
    output rsrvd,
    output first_replay,
    output action_drop,
    output action_lport_rel_qid,
    output action_rss_en,
    output action_rss_ctx_id,
    output action_mark_val,
    output action_set_flag,
    output action_strip_fcs,
    output vntx_drop,
    output orig_len,
    output egress_mport,
    output ingress_mport,
    output user_flag,
    output user_mark,
    output timestamp_req,
    output partial_timestamp,
    output vld,
    input  rdy
  );

  modport consumer (
    input  rsrvd,
    input  first_replay,
    input  action_drop,
    input  action_lport_rel_qid,
    input  action_rss_en,
    input  action_rss_ctx_id,
    input  action_mark_val,
    input  action_set_flag,
    input  action_strip_fcs,
    input  vntx_drop,
    input  orig_len,
    input  egress_mport,
    input  ingress_mport,
    input  user_flag,
    input  user_mark,
    input  timestamp_req,
    input  partial_timestamp,
    input  vld,
    output rdy
  );

  modport snooper (
    input  rsrvd,
    input  first_replay,
    input  action_drop,
    input  action_lport_rel_qid,
    input  action_rss_en,
    input  action_rss_ctx_id,
    input  action_mark_val,
    input  action_set_flag,
    input  action_strip_fcs,
    input  vntx_drop,
    input  orig_len,
    input  egress_mport,
    input  ingress_mport,
    input  user_flag,
    input  user_mark,
    input  timestamp_req,
    input  partial_timestamp,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_mas_context_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_mas_context_hdr_if #(DW = 194, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [96:0] rsrvd;
  logic        vntx_drop;
  logic [13:0] orig_len;
  logic [15:0] mport;
  logic        user_flag;
  logic [31:0] user_mark;
  logic        timestamp_req;
  logic [31:0] partial_timestamp;

  logic [VW-1:0]   vld;
  logic [RW-1:0]   rdy;

  modport producer (
    output rsrvd,
    output vntx_drop,
    output orig_len,
    output mport,
    output user_flag,
    output user_mark,
    output timestamp_req,
    output partial_timestamp,
    output vld,
    input  rdy
  );

  modport consumer (
    input  rsrvd,
    input  vntx_drop,
    input  orig_len,
    input  mport,
    input  user_flag,
    input  user_mark,
    input  timestamp_req,
    input  partial_timestamp,
    input  vld,
    output rdy
  );

  modport snooper (
    input  rsrvd,
    input  vntx_drop,
    input  orig_len,
    input  mport,
    input  user_flag,
    input  user_mark,
    input  timestamp_req,
    input  partial_timestamp,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_pseudo_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_pseudo_hdr_if #(DW = 224, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [206:0] pseudo_data;
  logic [3:0]   sdaccelrouting;
  logic [11:0]  flowid;
  logic         netpacket;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output pseudo_data,
    output sdaccelrouting,
    output flowid,
    output netpacket,
    output vld,
    input  rdy
  );

  modport consumer (
    input  pseudo_data,
    input  sdaccelrouting,
    input  flowid,
    input  netpacket,
    input  vld,
    output rdy
  );

  modport snooper (
    input  pseudo_data,
    input  sdaccelrouting,
    input  flowid,
    input  netpacket,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_pseudo_hdr_common_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_pseudo_hdr_common_if #(DW = 30, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [4:0]  contexttype;
  logic [3:0]  buffer_rh;
  logic [3:0]  portid;
  logic [3:0]  sdaccelrouting;
  logic [11:0] flowid;
  logic        netpacket;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output contexttype,
    output buffer_rh,
    output portid,
    output sdaccelrouting,
    output flowid,
    output netpacket,
    output vld,
    input  rdy
  );

  modport consumer (
    input  contexttype,
    input  buffer_rh,
    input  portid,
    input  sdaccelrouting,
    input  flowid,
    input  netpacket,
    input  vld,
    output rdy
  );

  modport snooper (
    input  contexttype,
    input  buffer_rh,
    input  portid,
    input  sdaccelrouting,
    input  flowid,
    input  netpacket,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_pseudo_net_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_pseudo_net_hdr_if #(DW = 207, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [193:0] net_context;
  logic [4:0]   contexttype;
  logic [7:0]   halfrouting;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output net_context,
    output contexttype,
    output halfrouting,
    output vld,
    input  rdy
  );

  modport consumer (
    input  net_context,
    input  contexttype,
    input  halfrouting,
    input  vld,
    output rdy
  );

  modport snooper (
    input  net_context,
    input  contexttype,
    input  halfrouting,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_pseudo_capsule_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_pseudo_capsule_hdr_if #(DW = 207, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [174:0] contxt;
  logic [7:0]   capsuletype;
  logic [7:0]   targetselect;
  logic [7:0]   socketbehaviour;
  logic [15:0]  fullrouting;

  logic [VW-1:0]   vld;
  logic [RW-1:0]   rdy;

  modport producer (
    output contxt,
    output capsuletype,
    output targetselect,
    output socketbehaviour,
    output fullrouting,
    output vld,
    input  rdy
  );

  modport consumer (
    input  contxt,
    input  capsuletype,
    input  targetselect,
    input  socketbehaviour,
    input  fullrouting,
    input  vld,
    output rdy
  );

  modport snooper (
    input  contxt,
    input  capsuletype,
    input  targetselect,
    input  socketbehaviour,
    input  fullrouting,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_context_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_context_hdr_if #(DW = 194, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [193:0] context_meta;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output context_meta,
    output vld,
    input  rdy
  );

  modport consumer (
    input  context_meta,
    input  vld,
    output rdy
  );

  modport snooper (
    input  context_meta,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_h2c_dma_context_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_h2c_dma_context_hdr_if #(DW = 194, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [103:0] rsrvd;
  logic         timestamp_req;
  logic [49:0]  h2c_override_hdr;
  logic [38:0]  h2c_offload_hdr;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output rsrvd,
    output timestamp_req,
    output h2c_override_hdr,
    output h2c_offload_hdr,
    output vld,
    input  rdy
  );

  modport consumer (
    input  rsrvd,
    input  timestamp_req,
    input  h2c_override_hdr,
    input  h2c_offload_hdr,
    input  vld,
    output rdy
  );

  modport snooper (
    input  rsrvd,
    input  timestamp_req,
    input  h2c_override_hdr,
    input  h2c_offload_hdr,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_c2h_dma_context_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_c2h_dma_context_hdr_if #(DW = 194, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [17:0] rsrvd;
  logic        user_flag;
  logic [31:0] user_mark;
  logic [31:0] partial_tstamp;
  logic [37:0] c2h_packet_char_saf;
  logic [72:0] c2h_packet_characterization;

  logic [VW-1:0]   vld;
  logic [RW-1:0]   rdy;

  modport producer (
    output rsrvd,
    output user_flag,
    output user_mark,
    output partial_tstamp,
    output c2h_packet_char_saf,
    output c2h_packet_characterization,
    output vld,
    input  rdy
  );

  modport consumer (
    input  rsrvd,
    input  user_flag,
    input  user_mark,
    input  partial_tstamp,
    input  c2h_packet_char_saf,
    input  c2h_packet_characterization,
    input  vld,
    output rdy
  );

  modport snooper (
    input  rsrvd,
    input  user_flag,
    input  user_mark,
    input  partial_tstamp,
    input  c2h_packet_char_saf,
    input  c2h_packet_characterization,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_rx_netport_context_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_rx_netport_context_hdr_if #(DW = 194, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [161:0] rsrvd;
  logic [31:0]  timestamp;

  logic [VW-1:0]   vld;
  logic [RW-1:0]   rdy;

  modport producer (
    output rsrvd,
    output timestamp,
    output vld,
    input  rdy
  );

  modport consumer (
    input  rsrvd,
    input  timestamp,
    input  vld,
    output rdy
  );

  modport snooper (
    input  rsrvd,
    input  timestamp,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_tx_netport_context_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_tx_netport_context_hdr_if #(DW = 194, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [180:0]    rsrvd;
  logic            timestamp_request;
  logic [11:0]     timestamp_qid;

  logic [VW-1:0]   vld;
  logic [RW-1:0]   rdy;

  modport producer (
    output rsrvd,
    output timestamp_request,
    output timestamp_qid,
    output vld,
    input  rdy
  );

  modport consumer (
    input  rsrvd,
    input  timestamp_request,
    input  timestamp_qid,
    input  vld,
    output rdy
  );

  modport snooper (
    input  rsrvd,
    input  timestamp_request,
    input  timestamp_qid,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_h2c_offload_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_h2c_offload_hdr_if #(DW = 39, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [15:0] vlan_insert_tci;
  logic        vlan_insert_en;
  logic [4:0]  cso_partial_csum_w;
  logic [8:0]  cso_partial_start_w;
  logic [1:0]  cso_partial_en;
  logic        cso_inner_l4;
  logic [2:0]  cso_inner_l3;
  logic        cso_outer_l4;
  logic        cso_outer_l3;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output vlan_insert_tci,
    output vlan_insert_en,
    output cso_partial_csum_w,
    output cso_partial_start_w,
    output cso_partial_en,
    output cso_inner_l4,
    output cso_inner_l3,
    output cso_outer_l4,
    output cso_outer_l3,
    output vld,
    input  rdy
  );

  modport consumer (
    input  vlan_insert_tci,
    input  vlan_insert_en,
    input  cso_partial_csum_w,
    input  cso_partial_start_w,
    input  cso_partial_en,
    input  cso_inner_l4,
    input  cso_inner_l3,
    input  cso_outer_l4,
    input  cso_outer_l3,
    input  vld,
    output rdy
  );

  modport snooper (
    input  vlan_insert_tci,
    input  vlan_insert_en,
    input  cso_partial_csum_w,
    input  cso_partial_start_w,
    input  cso_partial_en,
    input  cso_inner_l4,
    input  cso_inner_l3,
    input  cso_outer_l4,
    input  cso_outer_l3,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_h2c_override_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_h2c_override_hdr_if #(DW = 50, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [15:0] mport;
  logic        src_mport_en;
  logic [31:0] mark;
  logic        mark_en;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output mport,
    output src_mport_en,
    output mark,
    output mark_en,
    output vld,
    input  rdy
  );

  modport consumer (
    input  mport,
    input  src_mport_en,
    input  mark,
    input  mark_en,
    input  vld,
    output rdy
  );

  modport snooper (
    input  mport,
    input  src_mport_en,
    input  mark,
    input  mark_en,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_c2h_packet_char_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_c2h_packet_char_hdr_if #(DW = 73, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [15:0] vlan_strip_tci;
  logic [15:0] ingress_vport;
  logic        rss_hash_valid;
  logic [31:0] rss_hash;
  logic [1:0]  nt_or_inner_l4_class;
  logic [2:0]  tunnel_class;
  logic [1:0]  l2_n_vlan;
  logic        l2_class;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output vlan_strip_tci,
    output ingress_vport,
    output rss_hash_valid,
    output rss_hash,
    output nt_or_inner_l4_class,
    output tunnel_class,
    output l2_n_vlan,
    output l2_class,
    output vld,
    input  rdy
  );

  modport consumer (
    input  vlan_strip_tci,
    input  ingress_vport,
    input  rss_hash_valid,
    input  rss_hash,
    input  nt_or_inner_l4_class,
    input  tunnel_class,
    input  l2_n_vlan,
    input  l2_class,
    input  vld,
    output rdy
  );

  modport snooper (
    input  vlan_strip_tci,
    input  ingress_vport,
    input  rss_hash_valid,
    input  rss_hash,
    input  nt_or_inner_l4_class,
    input  tunnel_class,
    input  l2_n_vlan,
    input  l2_class,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_c2h_packet_char_sf_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_c2h_packet_char_sf_hdr_if #(DW = 48, VW = 1, RW = 1) (input bit clk);

  // Data
  logic        netpacket;
  logic [7:0]  halfrouting;
  logic        sfmd_err;
  logic [15:0] csum_frame;
  logic [1:0]  tun_outer_l3_class;
  logic [1:0]  nt_or_inner_l3_class;
  logic        tun_outer_l4_csum;
  logic        nt_or_inner_l4_csum;
  logic [1:0]  l2_status;
  logic [13:0] length;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output netpacket,
    output halfrouting,
    output sfmd_err,
    output csum_frame,
    output tun_outer_l3_class,
    output nt_or_inner_l3_class,
    output tun_outer_l4_csum,
    output nt_or_inner_l4_csum,
    output l2_status,
    output length,
    output vld,
    input  rdy
  );

  modport consumer (
    input  netpacket,
    input  halfrouting,
    input  sfmd_err,
    input  csum_frame,
    input  tun_outer_l3_class,
    input  nt_or_inner_l3_class,
    input  tun_outer_l4_csum,
    input  nt_or_inner_l4_csum,
    input  l2_status,
    input  length,
    input  vld,
    output rdy
  );

  modport snooper (
    input  netpacket,
    input  halfrouting,
    input  sfmd_err,
    input  csum_frame,
    input  tun_outer_l3_class,
    input  nt_or_inner_l3_class,
    input  tun_outer_l4_csum,
    input  nt_or_inner_l4_csum,
    input  l2_status,
    input  length,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_c2h_packet_char_sf_hier_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_c2h_packet_char_sf_hier_if #(DW = 38, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [15:0] csum_frame;
  logic [1:0]  tun_outer_l3_class;
  logic [1:0]  nt_or_inner_l3_class;
  logic        tun_outer_l4_csum;
  logic        nt_or_inner_l4_csum;
  logic [1:0]  l2_status;
  logic [13:0] length;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output csum_frame,
    output tun_outer_l3_class,
    output nt_or_inner_l3_class,
    output tun_outer_l4_csum,
    output nt_or_inner_l4_csum,
    output l2_status,
    output length,
    output vld,
    input  rdy
  );

  modport consumer (
    input  csum_frame,
    input  tun_outer_l3_class,
    input  nt_or_inner_l3_class,
    input  tun_outer_l4_csum,
    input  nt_or_inner_l4_csum,
    input  l2_status,
    input  length,
    input  vld,
    output rdy
  );

  modport snooper (
    input  csum_frame,
    input  tun_outer_l3_class,
    input  nt_or_inner_l3_class,
    input  tun_outer_l4_csum,
    input  nt_or_inner_l4_csum,
    input  l2_status,
    input  length,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_halfrouting_hdr_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_halfrouting_hdr_if #(DW = 8, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [3:0] buffer_rh;
  logic [3:0] portid;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output buffer_rh,
    output portid,
    output vld,
    input  rdy
  );

  modport consumer (
    input  buffer_rh,
    input  portid,
    input  vld,
    output rdy
  );

  modport snooper (
    input  buffer_rh,
    input  portid,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_igrs_meta_tso_off_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_igrs_meta_tso_off_if #(DW = 68, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [13:0] tso_inner_tcp_off;
  logic [7:0]  tso_outer_ip_off;
  logic        tso_outer_udp_len;
  logic        tso_inner_ip6_len;
  logic        tso_outer_ip6_len;
  logic        tso_inner_ip4_csum;
  logic [1:0]  tso_inner_ip4_id;
  logic [1:0]  tso_outer_ip4_id;
  logic [15:0] vlan_off_tci;
  logic        vlan_off_en;
  logic [5:0]  cso_partial_csum;
  logic [9:0]  cso_partial_start;
  logic        cso_partial_en;
  logic        cso_i_l4;
  logic        cso_i_l3;
  logic        cso_o_l4;
  logic        cso_o_l3;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output tso_inner_tcp_off,
    output tso_outer_ip_off,
    output tso_outer_udp_len,
    output tso_inner_ip6_len,
    output tso_outer_ip6_len,
    output tso_inner_ip4_csum,
    output tso_inner_ip4_id,
    output tso_outer_ip4_id,
    output vlan_off_tci,
    output vlan_off_en,
    output cso_partial_csum,
    output cso_partial_start,
    output cso_partial_en,
    output cso_i_l4,
    output cso_i_l3,
    output cso_o_l4,
    output cso_o_l3,
    output vld,
    input  rdy
  );

  modport consumer (
    input  tso_inner_tcp_off,
    input  tso_outer_ip_off,
    input  tso_outer_udp_len,
    input  tso_inner_ip6_len,
    input  tso_outer_ip6_len,
    input  tso_inner_ip4_csum,
    input  tso_inner_ip4_id,
    input  tso_outer_ip4_id,
    input  vlan_off_tci,
    input  vlan_off_en,
    input  cso_partial_csum,
    input  cso_partial_start,
    input  cso_partial_en,
    input  cso_i_l4,
    input  cso_i_l3,
    input  cso_o_l4,
    input  cso_o_l3,
    input  vld,
    output rdy
  );

  modport snooper (
    input  tso_inner_tcp_off,
    input  tso_outer_ip_off,
    input  tso_outer_udp_len,
    input  tso_inner_ip6_len,
    input  tso_outer_ip6_len,
    input  tso_inner_ip4_csum,
    input  tso_inner_ip4_id,
    input  tso_outer_ip4_id,
    input  vlan_off_tci,
    input  vlan_off_en,
    input  cso_partial_csum,
    input  cso_partial_start,
    input  cso_partial_en,
    input  cso_i_l4,
    input  cso_i_l3,
    input  cso_o_l4,
    input  cso_o_l3,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_generic_meta_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_generic_meta_if #(DW = 224, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [223:0] data;

  logic [VW-1:0] sb_md_vld;
  logic [RW-1:0] sb_md_rdy;

  modport producer (
    output data,
    output sb_md_vld,
    input  sb_md_rdy
  );

  modport consumer (
    input  data,
    input  sb_md_vld,
    output sb_md_rdy
  );

  modport snooper (
    input  data,
    input  sb_md_vld,
    input  sb_md_rdy
  );

endinterface

interface rh_generic_sfmd_if #(DW = 48, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [47:0]   data;
  logic [VW-1:0] sb_md_vld;
  logic [RW-1:0] sb_md_rdy;

  modport producer (
    output data,
    output sb_md_vld,
    input  sb_md_rdy
  );

  modport consumer (
    input  data,
    input  sb_md_vld,
    output sb_md_rdy
  );

  modport snooper (
    input  data,
    input  sb_md_vld,
    input  sb_md_rdy
  );

endinterface

interface rh_smpl_sb_if #(DW = 586, VW = 1, RW = 1) (input bit clk);
  // Data
  logic [63:0]   dpar;
  logic [1:0]    err;
  logic [5:0]    mty;
  logic          eop;
  logic          sop;
  logic [511:0]  data;

  logic [VW-1:0] sb_vld;
  logic [RW-1:0] sb_rdy;

  modport producer (
    output dpar,
    output err,
    output mty,
    output eop,
    output sop,
    output data,
    output sb_vld,
    input  sb_rdy
  );

  modport consumer (
    input  dpar,
    input  err,
    input  mty,
    input  eop,
    input  sop,
    input  data,
    input  sb_vld,
    output sb_rdy
  );

  modport snooper (
    input  dpar,
    input  err,
    input  mty,
    input  eop,
    input  sop,
    input  data,
    input  sb_vld,
    input  sb_rdy
  );

endinterface

interface rh_stat_msg_if #(DW = 243, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [1:0]   iscb_err;
  logic [1:0]   pkt_dmac_type;
  logic [14:0]  pkt_len;
  logic [223:0] ph_rcvd;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output iscb_err,
    output pkt_dmac_type,
    output pkt_len,
    output ph_rcvd,
    output vld,
    input  rdy
  );

  modport consumer (
    input  iscb_err,
    input  pkt_dmac_type,
    input  pkt_len,
    input  ph_rcvd,
    input  vld,
    output rdy
  );

  modport snooper (
    input  iscb_err,
    input  pkt_dmac_type,
    input  pkt_len,
    input  ph_rcvd,
    input  vld,
    input  rdy
  );

endinterface

interface rh_sched_msg_if #(DW = 22, VW = 1, RW = 1) (input bit clk);
  // Data
  logic [3:0]  mtype;
  logic        meop;
  logic        msop;
  logic [15:0] mdata;

  logic [VW-1:0] msg_vld;
  logic [RW-1:0] msg_rdy;

  modport producer (
    output mtype,
    output meop,
    output msop,
    output mdata,
    output msg_vld,
    input  msg_rdy
  );

  modport consumer (
    input  mtype,
    input  meop,
    input  msop,
    input  mdata,
    input  msg_vld,
    output msg_rdy
  );

  modport snooper (
    input  mtype,
    input  meop,
    input  msop,
    input  mdata,
    input  msg_vld,
    input  msg_rdy
  );

endinterface

interface rh_ts_info_msg_if #(DW = 12, VW = 1, RW = 1) (input bit clk);

  // Data
  logic [11:0] txq;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output txq,
    output vld,
    input  rdy
  );

  modport consumer (
    input  txq,
    input  vld,
    output rdy
  );

  modport snooper (
    input  txq,
    input  vld,
    input  rdy
  );

endinterface

interface rh_ts_ctxt_info_msg_if #(DW = 62, VW = 1, RW = 1) (input bit clk);
  logic        evc_barrier;
  logic        err;
  logic [15:0] desc_id;
  logic [11:0] txq;
  logic [31:0] tstamp;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output evc_barrier,
    output err,
    output desc_id,
    output txq,
    output tstamp,
    output vld,
    input  rdy
  );

  modport consumer (
    input  evc_barrier,
    input  err,
    input  desc_id,
    input  txq,
    input  tstamp,
    input  vld,
    output rdy
  );

  modport snooper (
    input  evc_barrier,
    input  err,
    input  desc_id,
    input  txq,
    input  tstamp,
    input  vld,
    input  rdy
  );

endinterface

interface ks_ts_ctxt_info_msg_if #(DW = 62, VW = 1, RW = 1) (input bit clk);
  logic evc_barrier;
  logic err;
  logic [15:0] desc_id;
  logic [11:0] txq;
  logic [31:0] tstamp;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output evc_barrier,
    output err,
    output desc_id,
    output txq,
    output tstamp,
    output vld,
    input  rdy
  );

  modport consumer (
    input  evc_barrier,
    input  err,
    input  desc_id,
    input  txq,
    input  tstamp,
    input  vld,
    output rdy
  );

  modport snooper (
    input  evc_barrier,
    input  err,
    input  desc_id,
    input  txq,
    input  tstamp,
    input  vld,
    input  rdy
  );

endinterface

// -----------------------------------------------------------------------
//         Interface Defintion: rh_egres_hclass_if
// -----------------------------------------------------------------------

// To parameterise this interface to pass a packed struct - instantiate as:
// push_pop_if #(.DW($bits(struct_name)))   interface_name()
interface rh_egres_hclass_if #(DW = 16, VW = 1, RW = 1) (input bit clk);

  // Data
  logic       tun_outer_l4_csum;
  logic [1:0] tun_outer_l3_class;
  logic       nt_or_inner_l4_csum;
  logic [1:0] nt_or_inner_l4_class;
  logic [1:0] nt_or_inner_l3_class;
  logic [2:0] tunnel_class;
  logic [1:0] l2_n_vlan;
  logic       l2_class;
  logic [1:0] l2_status;

  logic [VW-1:0] vld;
  logic [RW-1:0] rdy;

  modport producer (
    output tun_outer_l4_csum,
    output tun_outer_l3_class,
    output nt_or_inner_l4_csum,
    output nt_or_inner_l4_class,
    output nt_or_inner_l3_class,
    output tunnel_class,
    output l2_n_vlan,
    output l2_class,
    output l2_status,
    output vld,
    input  rdy
  );

  modport consumer (
    input  tun_outer_l4_csum,
    input  tun_outer_l3_class,
    input  nt_or_inner_l4_csum,
    input  nt_or_inner_l4_class,
    input  nt_or_inner_l3_class,
    input  tunnel_class,
    input  l2_n_vlan,
    input  l2_class,
    input  l2_status,
    input  vld,
    output rdy
  );

  modport snooper (
    input  tun_outer_l4_csum,
    input  tun_outer_l3_class,
    input  nt_or_inner_l4_csum,
    input  nt_or_inner_l4_class,
    input  nt_or_inner_l3_class,
    input  tunnel_class,
    input  l2_n_vlan,
    input  l2_class,
    input  l2_status,
    input  vld,
    input  rdy
  );

endinterface

//auto-intf-end

 //__ks_global_interfaces_if_sv__

interface ks_hah_axil_if #(
   DATA_WIDTH = 64,
   ADDR_WIDTH = 48,
   USER_W     = 32
   )
  ();

  logic [ADDR_WIDTH-1:0] awaddr;
  logic awready;
  logic awvalid;
  logic [USER_W-1:0] awuser;
  logic [2:0] awprot;

  logic [ADDR_WIDTH-1:0] araddr;
  logic arready;
  logic arvalid;
  logic [USER_W-1:0] aruser;
  logic [2:0] arprot;

  logic [DATA_WIDTH-1:0] wdata;
  logic [3:0] wdatainfo;
  logic [(DATA_WIDTH/8)-1:0] wstrb;
  logic wready;
  logic wvalid;

  logic [DATA_WIDTH-1:0] rdata;
  logic [3:0] rdatainfo;
  logic [1:0] rresp;
  logic rready;
  logic rvalid;

  logic [1:0] bresp;
  logic bready;
  logic bvalid;

  modport s (
    input  awaddr ,
    output awready,
    input  awvalid,
    input  awuser ,
    input  awprot ,
    input  araddr ,
    output arready,
    input  arvalid,
    input  aruser ,
    input  arprot ,
    input  wdata  ,
    input  wdatainfo,
    input  wstrb ,
    output wready,
    input  wvalid,
    output rdata ,
    output rdatainfo,
    output rresp ,
    input  rready,
    output rvalid,
    output bresp ,
    input  bready,
    output bvalid
  );

  modport m (
    output awaddr ,
    input  awready,
    output awvalid,
    output awuser ,
    output awprot ,
    output araddr ,
    input  arready,
    output arvalid,
    output aruser ,
    output arprot ,
    output wdata  ,
    output wdatainfo,
    output wstrb ,
    input  wready,
    output wvalid,
    input  rdata ,
    input  rdatainfo,
    input  rresp ,
    output rready,
    input  rvalid,
    input  bresp ,
    output bready,
    input  bvalid
  );

endinterface : ks_hah_axil_if
 // IF_KS_HAH_AXIL_IF

`endif
