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
`ifndef __ks_global_interfaces_def_e_sv__
`define __ks_global_interfaces_def_e_sv__

//=============================================================================
//         !!!                      CAUTION                 !!!
//
//         !!!                 GENERATED CODE               !!!
//
//         !!!  DO NOT MANUALLY EDIT THE CODE IN THIS FILE  !!!
//
//=============================================================================

//auto-struct-begin
// ------------------------------------------------------
//                   Structs
// ------------------------------------------------------

  typedef struct packed {
    logic [1:0]   fifo;
    logic [3:0]   credit;
  } ks_plugin_credit_msg_t;

  typedef struct packed {
    logic [223:0]   data;
  } ks_generic_meta_t;

  typedef struct packed {
    logic [21:0]   data;
  } ks_generic_sfmd_t;

  typedef struct packed {
    logic [1:0]     err;
    logic [5:0]     mty;
    logic           eop;
    logic           sop;
    logic [511:0]   data;
  } ks_smpl_sb_t;

  typedef struct packed {
    logic [1:0]      err;
    logic [6:0]      mty;
    logic            eop;
    logic            sop;
    logic [1023:0]   data;
  } ks_smpl_sb1024_t;

  typedef struct packed {
    logic [63:0]    data_integrity;
    logic [1:0]     err;
    logic [5:0]     eop_mty;
    logic           eop;
    logic           sop;
    logic [511:0]   data;
  } rh_icsb_sb_t;

  typedef struct packed {
    logic [3:0]    mtype;
    logic          meop;
    logic          msop;
    logic [15:0]   mdata;
  } ks_sched_msg_t;

  typedef struct packed {
    logic [1:0]     iscb_err;
    logic [1:0]     pkt_dmac_type;
    logic [14:0]    pkt_len;
    logic [223:0]   ph_rcvd;
  } ks_stat_msg_t;

  typedef struct packed {
    logic [11:0]   txq;
  } ks_ts_info_msg_t;

  typedef struct packed {
    logic [3:0]    fifo;
    logic [15:0]   bytes;
  } ks_plugin_ingress_notify_t;

  typedef struct packed {
    logic          ack;
    logic          err;
    logic          vld;
    logic [31:0]   rdat;
  } csr_to_mc_t;

  typedef struct packed {
    logic          req;
    logic          wr;
    logic [31:0]   addr;
    logic [31:0]   wdat;
  } csr_from_mc_t;

  typedef struct packed {
    logic [7:0]   pause_mask;
    logic [2:0]   port_id;
  } ks_mac_fc_msg_if_t;

  typedef struct packed {
    logic         opcode;
    logic [2:0]   pri_id;
    logic [2:0]   port_id;
  } ks_net_fc_msg_if_t;

  typedef struct packed {
    logic         pause;
    logic [7:0]   fifo_id;
  } ks_fc_fifo_stall_if_t;

  typedef struct packed {
    logic [96:0]   rsrvd;
    logic          vntx_drop;
    logic [13:0]   orig_len;
    logic [15:0]   mport;
    logic          user_flag;
    logic [31:0]   user_mark;
    logic          timestamp_req;
    logic [31:0]   partial_timestamp;
  } rh_mas_context_r1_hdr_t;

  typedef struct packed {
    logic [23:0]   rsrvd;
    logic          first_replay;
    logic          action_drop;
    logic [11:0]   action_lport_rel_qid;
    logic          action_rss_en;
    logic [7:0]    action_rss_ctx_id;
    logic [31:0]   action_mark_val;
    logic          action_set_flag;
    logic          action_strip_fcs;
    logic          vntx_drop;
    logic [13:0]   orig_len;
    logic [15:0]   egress_mport;
    logic [15:0]   ingress_mport;
    logic          user_flag;
    logic [31:0]   user_mark;
    logic          timestamp_req;
    logic [31:0]   partial_timestamp;
  } rh_nic_rx_socket_context_r1_hdr_t;

  typedef struct packed {
    logic [96:0]   rsrvd;
    logic          vntx_drop;
    logic [13:0]   orig_len;
    logic [15:0]   mport;
    logic          user_flag;
    logic [31:0]   user_mark;
    logic          timestamp_req;
    logic [31:0]   partial_timestamp;
  } rh_mas_context_hdr_t;

  typedef struct packed {
    logic [206:0]   pseudo_data;
    logic [3:0]     sdaccelrouting;
    logic [11:0]    flowid;
    logic           netpacket;
  } rh_pseudo_hdr_t;

  typedef struct packed {
    logic [4:0]    contexttype;
    logic [3:0]    buffer_rh;
    logic [3:0]    portid;
    logic [3:0]    sdaccelrouting;
    logic [11:0]   flowid;
    logic          netpacket;
  } rh_pseudo_hdr_common_t;

  typedef struct packed {
    logic [193:0]   net_context;
    logic [4:0]     contexttype;
    logic [7:0]     halfrouting;
  } rh_pseudo_net_hdr_t;

  typedef struct packed {
    logic [174:0]   contxt;
    logic [7:0]     capsuletype;
    logic [7:0]     targetselect;
    logic [7:0]     socketbehaviour;
    logic [15:0]    fullrouting;
  } rh_pseudo_capsule_hdr_t;

  typedef struct packed {
    logic [193:0]   context_meta;
  } rh_context_hdr_t;

  typedef struct packed {
    logic [103:0]   rsrvd;
    logic           timestamp_req;
    logic [49:0]    h2c_override_hdr;
    logic [38:0]    h2c_offload_hdr;
  } rh_h2c_dma_context_hdr_t;

  typedef struct packed {
    logic [17:0]   rsrvd;
    logic          user_flag;
    logic [31:0]   user_mark;
    logic [31:0]   partial_tstamp;
    logic [37:0]   c2h_packet_char_saf;
    logic [72:0]   c2h_packet_characterization;
  } rh_c2h_dma_context_hdr_t;

  typedef struct packed {
    logic [161:0]   rsrvd;
    logic [31:0]    timestamp;
  } rh_rx_netport_context_hdr_t;

  typedef struct packed {
    logic [180:0]   rsrvd;
    logic           timestamp_request;
    logic [11:0]    timestamp_qid;
  } rh_tx_netport_context_hdr_t;

  typedef struct packed {
    logic [15:0]   vlan_insert_tci;
    logic          vlan_insert_en;
    logic [4:0]    cso_partial_csum_w;
    logic [8:0]    cso_partial_start_w;
    logic [1:0]    cso_partial_en;
    logic          cso_inner_l4;
    logic [2:0]    cso_inner_l3;
    logic          cso_outer_l4;
    logic          cso_outer_l3;
  } rh_h2c_offload_hdr_t;

  typedef struct packed {
    logic [15:0]   mport;
    logic          src_mport_en;
    logic [31:0]   mark;
    logic          mark_en;
  } rh_h2c_override_hdr_t;

  typedef struct packed {
    logic [15:0]   vlan_strip_tci;
    logic [15:0]   ingress_vport;
    logic          rss_hash_valid;
    logic [31:0]   rss_hash;
    logic [1:0]    nt_or_inner_l4_class;
    logic [2:0]    tunnel_class;
    logic [1:0]    l2_n_vlan;
    logic          l2_class;
  } rh_c2h_packet_char_hdr_t;

  typedef struct packed {
    logic          netpacket;
    logic [7:0]    halfrouting;
    logic          sfmd_err;
    logic [15:0]   csum_frame;
    logic [1:0]    tun_outer_l3_class;
    logic [1:0]    nt_or_inner_l3_class;
    logic          tun_outer_l4_csum;
    logic          nt_or_inner_l4_csum;
    logic [1:0]    l2_status;
    logic [13:0]   length;
  } rh_c2h_packet_char_sf_hdr_t;

  typedef struct packed {
    logic [15:0]   csum_frame;
    logic [1:0]    tun_outer_l3_class;
    logic [1:0]    nt_or_inner_l3_class;
    logic          tun_outer_l4_csum;
    logic          nt_or_inner_l4_csum;
    logic [1:0]    l2_status;
    logic [13:0]   length;
  } rh_c2h_packet_char_sf_hier_t;

  typedef struct packed {
    logic [3:0]   buffer_rh;
    logic [3:0]   portid;
  } rh_halfrouting_hdr_t;

  typedef struct packed {
    logic [13:0]   tso_inner_tcp_off;
    logic [7:0]    tso_outer_ip_off;
    logic          tso_outer_udp_len;
    logic          tso_inner_ip6_len;
    logic          tso_outer_ip6_len;
    logic          tso_inner_ip4_csum;
    logic [1:0]    tso_inner_ip4_id;
    logic [1:0]    tso_outer_ip4_id;
    logic [15:0]   vlan_off_tci;
    logic          vlan_off_en;
    logic [5:0]    cso_partial_csum;
    logic [9:0]    cso_partial_start;
    logic          cso_partial_en;
    logic          cso_i_l4;
    logic          cso_i_l3;
    logic          cso_o_l4;
    logic          cso_o_l3;
  } rh_igrs_meta_tso_off_t;

  typedef struct packed {
    logic [223:0]   data;
  } rh_generic_meta_t;

  typedef struct packed {
    logic [47:0]   data;
  } rh_generic_sfmd_t;

  typedef struct packed {
    logic [63:0]    dpar;
    logic [1:0]     err;
    logic [5:0]     mty;
    logic           eop;
    logic           sop;
    logic [511:0]   data;
  } rh_smpl_sb_t;

  typedef struct packed {
    logic [1:0]     iscb_err;
    logic [1:0]     pkt_dmac_type;
    logic [14:0]    pkt_len;
    logic [223:0]   ph_rcvd;
  } rh_stat_msg_t;

  typedef struct packed {
    logic [3:0]    mtype;
    logic          meop;
    logic          msop;
    logic [15:0]   mdata;
  } rh_sched_msg_t;

  typedef struct packed {
    logic [11:0]   txq;
  } rh_ts_info_msg_t;

  typedef struct packed {
    logic          evc_barrier;
    logic          err;
    logic [15:0]   desc_id;
    logic [11:0]   txq;
    logic [31:0]   tstamp;
  } rh_ts_ctxt_info_msg_t;

  typedef struct packed {
    logic          evc_barrier;
    logic          err;
    logic [15:0]   desc_id;
    logic [11:0]   txq;
    logic [31:0]   tstamp;
  } ks_ts_ctxt_info_msg_t;

  typedef struct packed {
    logic         tun_outer_l4_csum;
    logic [1:0]   tun_outer_l3_class;
    logic         nt_or_inner_l4_csum;
    logic [1:0]   nt_or_inner_l4_class;
    logic [1:0]   nt_or_inner_l3_class;
    logic [2:0]   tunnel_class;
    logic [1:0]   l2_n_vlan;
    logic         l2_class;
    logic [1:0]   l2_status;
  } rh_egres_hclass_t;


// ------------------------------------------------------
//                   Enums
// ------------------------------------------------------

typedef enum logic[3:0] {
  RH_META_PORTID_HOST               = 0,
  RH_META_PORTID_MC                 = 1,
  RH_META_PORTID_P0                 = 2,
  RH_META_PORTID_P1                 = 3,
  RH_META_PORTID_P2                 = 7,
  RH_META_PORTID_P3                 = 8,
  RH_META_PORTID_SDA                = 4
  } rh_meta_portid_e;

typedef enum logic[3:0] {
  RH_SCHED_MSG_SRC_CRED             = 0,
  RH_SCHED_MSG_JREQ                 = 1,
  RH_SCHED_MSG_JRESP                = 2,
  RH_SCHED_MSG_DEST_CRED            = 3,
  RH_SCHED_MSG_JERR                 = 4,
  RH_SCHED_MSG_XON_XOFF             = 5,
  RH_SCHED_MSG_BARRIER              = 15
  } rh_sched_msg_e;

typedef enum logic[3:0] {
  KS_SCHED_MSG_SRC_CRED             = 0,
  KS_SCHED_MSG_JREQ                 = 1,
  KS_SCHED_MSG_JRESP                = 2,
  KS_SCHED_MSG_DEST_CRED            = 3,
  KS_SCHED_MSG_JERR                 = 4,
  KS_SCHED_MSG_XON_XOFF             = 5,
  KS_SCHED_MSG_BARRIER              = 15
  } ks_sched_msg_e;

typedef enum logic[1:0] {
  KS_ICSB_ERR_L2_STATUS_GOOD        = 0,
  KS_ICSB_ERR_L2_STATUS_WIRE_ERR    = 1,
  KS_ICSB_ERR_L2_STATUS_LEN_ERR     = 2,
  KS_ICSB_ERR_L2_STATUS_DP_ERR      = 3
  } ks_icsb_err_e;

typedef enum logic {
  KS_HCLASS_L2_CLASS_OTHER          = 0,
  KS_HCLASS_L2_CLASS_E2_0123VLAN    = 1
  } ks_hclass_l2_class_e;

typedef enum logic[1:0] {
  KS_HCLASS_L3_CLASS_IP4GOOD        = 0,
  KS_HCLASS_L3_CLASS_IP4BAD         = 1,
  KS_HCLASS_L3_CLASS_IP6            = 2,
  KS_HCLASS_L3_CLASS_OTHER          = 3
  } ks_hclass_l3_class_e;

typedef enum logic {
  KS_HCLASS_L4_CSUM_BAD_OR_UNKNOWN  = 0,
  KS_HCLASS_L4_CSUM_GOOD            = 1
  } ks_hclass_l4_csum_e;

typedef enum logic[1:0] {
  RH_ICSB_ERR_L2_STATUS_GOOD        = 0,
  RH_ICSB_ERR_L2_STATUS_WIRE_ERR    = 1,
  RH_ICSB_ERR_L2_STATUS_LEN_ERR     = 2,
  RH_ICSB_ERR_L2_STATUS_DP_ERR      = 3
  } rh_icsb_err_e;

typedef enum logic[4:0] {
  RH_PKT_CONTEXTTYPE_H2C_DMA        = 0,
  RH_PKT_CONTEXTTYPE_H2C_DMA_VIRTIO = 1,
  RH_PKT_CONTEXTTYPE_RX_VPORT       = 2,
  RH_PKT_CONTEXTTYPE_RX_NETPORT     = 3,
  RH_PKT_CONTEXTTYPE_MAS_INGRESS    = 4,
  RH_PKT_CONTEXTTYPE_NIC_RX_SOCKET_INGRESS = 5,
  RH_PKT_CONTEXTTYPE_C2H_DMA        = 16,
  RH_PKT_CONTEXTTYPE_C2H_DMA_VIRTIO = 17,
  RH_PKT_CONTEXTTYPE_TX_VPORT       = 18,
  RH_PKT_CONTEXTTYPE_TX_NETPORT     = 19,
  RH_PKT_CONTEXTTYPE_MAS_EGRESS     = 20,
  RH_PKT_CONTEXTTYPE_NIC_RX_SOCKET_EGRESS = 21
  } rh_pkt_contexttype_e;

typedef enum logic[1:0] {
  RH_HCLASS_L2_STATUS_OK            = 0,
  RH_HCLASS_L2_STATUS_LEN_ERR       = 1,
  RH_HCLASS_L2_STATUS_FCS_ERR       = 2,
  RH_HCLASS_L2_STATUS_RESERVED      = 3
  } rh_hclass_l2_status_e;

typedef enum logic {
  RH_HCLASS_L2_CLASS_OTHER          = 0,
  RH_HCLASS_L2_CLASS_E2_0123VLAN    = 1
  } rh_hclass_l2_class_e;

typedef enum logic[2:0] {
  RH_HCLASS_TUNNEL_CLASS_NONE       = 0,
  RH_HCLASS_TUNNEL_CLASS_VXLAN      = 1,
  RH_HCLASS_TUNNEL_CLASS_NVGRE      = 2,
  RH_HCLASS_TUNNEL_CLASS_GENEVE     = 3,
  RH_HCLASS_TUNNEL_CLASS_RESERVED_4 = 4,
  RH_HCLASS_TUNNEL_CLASS_RESERVED_5 = 5,
  RH_HCLASS_TUNNEL_CLASS_RESERVED_6 = 6,
  RH_HCLASS_TUNNEL_CLASS_RESERVED_7 = 7
  } rh_hclass_tunnel_class_e;

typedef enum logic[1:0] {
  RH_HCLASS_L3_CLASS_IP4GOOD        = 0,
  RH_HCLASS_L3_CLASS_IP4BAD         = 1,
  RH_HCLASS_L3_CLASS_IP6            = 2,
  RH_HCLASS_L3_CLASS_OTHER          = 3
  } rh_hclass_l3_class_e;

typedef enum logic[1:0] {
  RH_HCLASS_L4_CLASS_TCP            = 0,
  RH_HCLASS_L4_CLASS_UDP            = 1,
  RH_HCLASS_L4_CLASS_FRAG           = 2,
  RH_HCLASS_L4_CLASS_OTHER          = 3
  } rh_hclass_l4_class_e;

typedef enum logic {
  RH_HCLASS_L4_CSUM_BAD_OR_UNKNOWN  = 0,
  RH_HCLASS_L4_CSUM_GOOD            = 1
  } rh_hclass_l4_csum_e;

typedef enum logic[7:0] {
  RH_CAPSULETYPE_STREAM_BARRIER     = 127,
  RH_CAPSULETYPE_SLICE_BARRIER      = 255
  } rh_capsuletype_e;

typedef enum logic[1:0] {
  KS_IMPL_L2_DADDR_TYPE_UNICAST     = 0,
  KS_IMPL_L2_DADDR_TYPE_MULTICAST   = 1,
  KS_IMPL_L2_DADDR_TYPE_BROADCAST   = 2
  } ks_impl_l2_daddr_type_e;

//auto-struct-end

`endif //__ks_global_interfaces_def_e_sv__
