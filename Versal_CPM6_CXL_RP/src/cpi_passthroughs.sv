module cpi_f2a_req_passthrough
(
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ is_valid" *)
  input        s_is_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ early_valid" *)
  input        s_early_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ protocol_id" *)
  input  [3:0] s_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ vc_id" *)
  input  [3:0] s_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ shared_credit" *)
  input        s_shared_credit,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ header" *)
  input [86:0] s_header,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ cmd_parity" *)
  input        s_cmd_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ spid" *)
  input [11:0] s_spid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ dpid" *)
  input [11:0] s_dpid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ txblock_crd_flow" *)
  input        s_txblock_crd_flow,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ block" *)
  output logic        s_block,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ rxcrd_valid" *)
  output logic        s_rxcrd_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ rxcrd_protocol_id" *)
  output logic [3:0]  s_rxcrd_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ rxcrd_vc_id" *)
  output logic [3:0]  s_rxcrd_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 S_F2A_REQ rxcrd_shared" *)
  output logic        s_rxcrd_shared,

  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ is_valid" *)
  output logic        m_is_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ early_valid" *)
  output logic        m_early_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ protocol_id" *)
  output logic [3:0]  m_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ vc_id" *)
  output logic [3:0]  m_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ shared_credit" *)
  output logic        m_shared_credit,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ header" *)
  output logic [86:0] m_header,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ cmd_parity" *)
  output logic        m_cmd_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ spid" *)
  output logic [11:0] m_spid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ dpid" *)
  output logic [11:0] m_dpid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ txblock_crd_flow" *)
  output logic        m_txblock_crd_flow,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ block" *)
  input        m_block,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ rxcrd_valid" *)
  input        m_rxcrd_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ rxcrd_protocol_id" *)
  input  [3:0] m_rxcrd_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ rxcrd_vc_id" *)
  input  [3:0] m_rxcrd_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_req:1.0 M_F2A_REQ rxcrd_shared" *)
  input        m_rxcrd_shared,

  output logic        is_valid,
  output logic [15:0] HDRtag,
  output logic [3:0]  HDRmemopcode
);

  assign m_is_valid         = s_is_valid;
  assign m_early_valid      = s_early_valid;
  assign m_protocol_id      = s_protocol_id;
  assign m_vc_id            = s_vc_id;
  assign m_shared_credit    = s_shared_credit;
  assign m_header           = s_header;
  assign m_cmd_parity       = s_cmd_parity;
  assign m_spid             = s_spid;
  assign m_dpid             = s_dpid;
  assign m_txblock_crd_flow = s_txblock_crd_flow;

  assign s_block             = m_block;
  assign s_rxcrd_valid       = m_rxcrd_valid;
  assign s_rxcrd_protocol_id = m_rxcrd_protocol_id;
  assign s_rxcrd_vc_id       = m_rxcrd_vc_id;
  assign s_rxcrd_shared      = m_rxcrd_shared;

  assign is_valid     = s_is_valid;
  // s_header is CPM6/ps_wizard's real 87-bit cpi_req header (includes
  // pl_axi_cpi_bridge's CXL_IDE_EPOCH_SUPPORT portid/epochid/epochvalid
  // padding bits, unused here). Sliced directly by bit position rather
  // than importing cpi_pkg -- Vivado errors on synthesizing a package
  // import from a plain RTL module, since cpi_pkg is only compiled
  // inside pl_axi_cpi_bridge's own IP scope, not visible here. Per
  // cpi_pkg.sv's req_hdr_u.dsp.f2am struct (packed MSB-first, so these
  // fields sit at the same low bit positions regardless of how much IDE
  // padding precedes them): [19:4] = tag (16b), [3:0] = memopcode (4b).
  assign HDRtag       = s_header[19:4];
  assign HDRmemopcode = s_header[3:0];

endmodule

module cpi_f2a_data_passthrough #(
  parameter BODY_WIDTH = 512
) (
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA is_valid" *)
  input        s_is_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA early_valid" *)
  input        s_early_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA protocol_id" *)
  input  [3:0] s_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA vc_id" *)
  input  [3:0] s_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA shared_credit" *)
  input        s_shared_credit,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA header" *)
  input [87:0] s_header,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA sz" *)
  input        s_sz,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA cmd_parity" *)
  input        s_cmd_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA spid" *)
  input [11:0] s_spid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA dpid" *)
  input [11:0] s_dpid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA body" *)
  input [    BODY_WIDTH-1:0] s_body,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA byte_enable" *)
  input [(BODY_WIDTH/8)-1:0] s_byte_enable,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA byte_enable_parity" *)
  input        s_byte_enable_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA poison" *)
  input        s_poison,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA parity" *)
  input [(BODY_WIDTH/64)-1:0] s_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA eop" *)
  input        s_eop,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA txblock_crd_flow" *)
  input        s_txblock_crd_flow,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA block" *)
  output logic        s_block,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA rxcrd_valid" *)
  output logic        s_rxcrd_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA rxcrd_protocol_id" *)
  output logic [3:0]  s_rxcrd_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA rxcrd_vc_id" *)
  output logic [3:0]  s_rxcrd_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_F2A_DATA rxcrd_shared" *)
  output logic        s_rxcrd_shared,

  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA is_valid" *)
  output logic        m_is_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA early_valid" *)
  output logic        m_early_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA protocol_id" *)
  output logic [3:0]  m_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA vc_id" *)
  output logic [3:0]  m_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA shared_credit" *)
  output logic        m_shared_credit,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA header" *)
  output logic [87:0] m_header,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA sz" *)
  output logic        m_sz,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA cmd_parity" *)
  output logic        m_cmd_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA spid" *)
  output logic [11:0] m_spid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA dpid" *)
  output logic [11:0] m_dpid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA body" *)
  output logic [    BODY_WIDTH-1:0] m_body,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA byte_enable" *)
  output logic [(BODY_WIDTH/8)-1:0] m_byte_enable,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA byte_enable_parity" *)
  output logic        m_byte_enable_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA poison" *)
  output logic        m_poison,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA parity" *)
  output logic [(BODY_WIDTH/64)-1:0] m_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA eop" *)
  output logic        m_eop,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA txblock_crd_flow" *)
  output logic        m_txblock_crd_flow,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA block" *)
  input        m_block,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA rxcrd_valid" *)
  input        m_rxcrd_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA rxcrd_protocol_id" *)
  input  [3:0] m_rxcrd_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA rxcrd_vc_id" *)
  input  [3:0] m_rxcrd_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_F2A_DATA rxcrd_shared" *)
  input        m_rxcrd_shared,

  output logic        is_valid,
  output logic [15:0] HDRtag,
  output logic [3:0]  HDRmemopcode
);

  assign m_is_valid           = s_is_valid;
  assign m_early_valid        = s_early_valid;
  assign m_protocol_id        = s_protocol_id;
  assign m_vc_id              = s_vc_id;
  assign m_shared_credit      = s_shared_credit;
  assign m_header             = s_header;
  assign m_sz                 = s_sz;
  assign m_cmd_parity         = s_cmd_parity;
  assign m_spid               = s_spid;
  assign m_dpid               = s_dpid;
  assign m_body               = s_body;
  assign m_byte_enable        = s_byte_enable;
  assign m_byte_enable_parity = s_byte_enable_parity;
  assign m_poison             = s_poison;
  assign m_parity             = s_parity;
  assign m_eop                = s_eop;
  assign m_txblock_crd_flow   = s_txblock_crd_flow;

  assign s_block             = m_block;
  assign s_rxcrd_valid       = m_rxcrd_valid;
  assign s_rxcrd_protocol_id = m_rxcrd_protocol_id;
  assign s_rxcrd_vc_id       = m_rxcrd_vc_id;
  assign s_rxcrd_shared      = m_rxcrd_shared;

  assign is_valid     = s_is_valid;
  // s_header is CPM6/ps_wizard's real 88-bit cpi_data header (includes
  // pl_axi_cpi_bridge's CXL_IDE_EPOCH_SUPPORT portid/epochid/epochvalid
  // padding bits, unused here). Sliced directly by bit position rather
  // than importing cpi_pkg -- Vivado errors on synthesizing a package
  // import from a plain RTL module, since cpi_pkg is only compiled
  // inside pl_axi_cpi_bridge's own IP scope, not visible here. Per
  // cpi_pkg.sv's data_hdr_u.dsp.f2am struct (packed MSB-first, so these
  // fields sit at the same low bit positions regardless of how much IDE
  // padding precedes them): [54:39] = tag (16b), [3:0] = memopcode (4b).
  assign HDRtag       = s_header[54:39];
  assign HDRmemopcode = s_header[3:0];

endmodule

module cpi_a2f_data_passthrough #(
  parameter BODY_WIDTH = 512
) (
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA is_valid" *)
  input        s_is_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA early_valid" *)
  input        s_early_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA protocol_id" *)
  input  [3:0] s_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA vc_id" *)
  input  [3:0] s_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA shared_credit" *)
  input        s_shared_credit,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA header" *)
  input [87:0] s_header,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA sz" *)
  input        s_sz,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA cmd_parity" *)
  input        s_cmd_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA spid" *)
  input [11:0] s_spid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA dpid" *)
  input [11:0] s_dpid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA body" *)
  input [    BODY_WIDTH-1:0] s_body,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA byte_enable" *)
  input [(BODY_WIDTH/8)-1:0] s_byte_enable,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA byte_enable_parity" *)
  input        s_byte_enable_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA poison" *)
  input        s_poison,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA parity" *)
  input [(BODY_WIDTH/64)-1:0] s_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA eop" *)
  input        s_eop,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA txblock_crd_flow" *)
  input        s_txblock_crd_flow,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA block" *)
  output logic        s_block,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA rxcrd_valid" *)
  output logic        s_rxcrd_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA rxcrd_protocol_id" *)
  output logic [3:0]  s_rxcrd_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA rxcrd_vc_id" *)
  output logic [3:0]  s_rxcrd_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 S_A2F_DATA rxcrd_shared" *)
  output logic        s_rxcrd_shared,

  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA is_valid" *)
  output logic        m_is_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA early_valid" *)
  output logic        m_early_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA protocol_id" *)
  output logic [3:0]  m_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA vc_id" *)
  output logic [3:0]  m_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA shared_credit" *)
  output logic        m_shared_credit,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA header" *)
  output logic [87:0] m_header,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA sz" *)
  output logic        m_sz,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA cmd_parity" *)
  output logic        m_cmd_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA spid" *)
  output logic [11:0] m_spid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA dpid" *)
  output logic [11:0] m_dpid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA body" *)
  output logic [    BODY_WIDTH-1:0] m_body,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA byte_enable" *)
  output logic [(BODY_WIDTH/8)-1:0] m_byte_enable,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA byte_enable_parity" *)
  output logic        m_byte_enable_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA poison" *)
  output logic        m_poison,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA parity" *)
  output logic [(BODY_WIDTH/64)-1:0] m_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA eop" *)
  output logic        m_eop,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA txblock_crd_flow" *)
  output logic        m_txblock_crd_flow,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA block" *)
  input        m_block,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA rxcrd_valid" *)
  input        m_rxcrd_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA rxcrd_protocol_id" *)
  input  [3:0] m_rxcrd_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA rxcrd_vc_id" *)
  input  [3:0] m_rxcrd_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_data:1.0 M_A2F_DATA rxcrd_shared" *)
  input        m_rxcrd_shared,

  output logic        is_valid,
  output logic [15:0] HDRtag,
  output logic [2:0]  HDRopcode,
  output logic [1:0]  HDRdevload
);

  assign m_is_valid           = s_is_valid;
  assign m_early_valid        = s_early_valid;
  assign m_protocol_id        = s_protocol_id;
  assign m_vc_id              = s_vc_id;
  assign m_shared_credit      = s_shared_credit;
  assign m_header             = s_header;
  assign m_sz                 = s_sz;
  assign m_cmd_parity         = s_cmd_parity;
  assign m_spid               = s_spid;
  assign m_dpid               = s_dpid;
  assign m_body               = s_body;
  assign m_byte_enable        = s_byte_enable;
  assign m_byte_enable_parity = s_byte_enable_parity;
  assign m_poison             = s_poison;
  assign m_parity             = s_parity;
  assign m_eop                = s_eop;
  assign m_txblock_crd_flow   = s_txblock_crd_flow;

  assign s_block             = m_block;
  assign s_rxcrd_valid       = m_rxcrd_valid;
  assign s_rxcrd_protocol_id = m_rxcrd_protocol_id;
  assign s_rxcrd_vc_id       = m_rxcrd_vc_id;
  assign s_rxcrd_shared      = m_rxcrd_shared;

  assign is_valid    = s_is_valid;
  // s_header is CPM6/ps_wizard's real 88-bit cpi_data header (includes
  // pl_axi_cpi_bridge's CXL_IDE_EPOCH_SUPPORT portid/epochid/epochvalid
  // padding bits, unused here). Sliced directly by bit position rather
  // than importing cpi_pkg -- Vivado errors on synthesizing a package
  // import from a plain RTL module, since cpi_pkg is only compiled
  // inside pl_axi_cpi_bridge's own IP scope, not visible here. Per
  // cpi_pkg.sv's data_hdr_u.dsp.a2fm struct (packed MSB-first, with a
  // fixed 44b rsvd_ext pad ahead of these fields regardless of IDE
  // support): [31:16] = tag (16b), [2:0] = opcode (3b), [37:36] = devload (2b).
  assign HDRtag      = s_header[31:16];
  assign HDRopcode   = s_header[2:0];
  assign HDRdevload  = s_header[37:36];

endmodule

module cpi_a2f_rsp_passthrough
(
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP is_valid" *)
  input        s_is_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP early_valid" *)
  input        s_early_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP protocol_id" *)
  input  [3:0] s_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP vc_id" *)
  input  [3:0] s_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP shared_credit" *)
  input        s_shared_credit,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP header" *)
  input [40:0] s_header,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP cmd_parity" *)
  input        s_cmd_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP spid" *)
  input [11:0] s_spid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP dpid" *)
  input [11:0] s_dpid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP txblock_crd_flow" *)
  input        s_txblock_crd_flow,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP block" *)
  output logic        s_block,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP rxcrd_valid" *)
  output logic        s_rxcrd_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP rxcrd_protocol_id" *)
  output logic [3:0]  s_rxcrd_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP rxcrd_vc_id" *)
  output logic [3:0]  s_rxcrd_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 S_A2F_RSP rxcrd_shared" *)
  output logic        s_rxcrd_shared,

  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP is_valid" *)
  output logic        m_is_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP early_valid" *)
  output logic        m_early_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP protocol_id" *)
  output logic [3:0]  m_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP vc_id" *)
  output logic [3:0]  m_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP shared_credit" *)
  output logic        m_shared_credit,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP header" *)
  output logic [40:0] m_header,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP cmd_parity" *)
  output logic        m_cmd_parity,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP spid" *)
  output logic [11:0] m_spid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP dpid" *)
  output logic [11:0] m_dpid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP txblock_crd_flow" *)
  output logic        m_txblock_crd_flow,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP block" *)
  input        m_block,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP rxcrd_valid" *)
  input        m_rxcrd_valid,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP rxcrd_protocol_id" *)
  input  [3:0] m_rxcrd_protocol_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP rxcrd_vc_id" *)
  input  [3:0] m_rxcrd_vc_id,
  (* X_INTERFACE_INFO = "xilinx.com:display_cpm6:cpi_rsp:1.0 M_A2F_RSP rxcrd_shared" *)
  input        m_rxcrd_shared,

  output logic        is_valid,
  output logic [15:0] HDRtag,
  output logic [2:0]  HDRopcode,
  output logic [1:0]  HDRdevload
);

  assign m_is_valid         = s_is_valid;
  assign m_early_valid      = s_early_valid;
  assign m_protocol_id      = s_protocol_id;
  assign m_vc_id            = s_vc_id;
  assign m_shared_credit    = s_shared_credit;
  assign m_header           = s_header;
  assign m_cmd_parity       = s_cmd_parity;
  assign m_spid             = s_spid;
  assign m_dpid             = s_dpid;
  assign m_txblock_crd_flow = s_txblock_crd_flow;

  assign s_block             = m_block;
  assign s_rxcrd_valid       = m_rxcrd_valid;
  assign s_rxcrd_protocol_id = m_rxcrd_protocol_id;
  assign s_rxcrd_vc_id       = m_rxcrd_vc_id;
  assign s_rxcrd_shared      = m_rxcrd_shared;

  assign is_valid    = s_is_valid;
  // s_header is CPM6/ps_wizard's real 41-bit cpi_rsp header (includes
  // pl_axi_cpi_bridge's CXL_IDE_EPOCH_SUPPORT portid/epochid/epochvalid
  // padding bits, unused here). Sliced directly by bit position rather
  // than importing cpi_pkg -- Vivado errors on synthesizing a package
  // import from a plain RTL module, since cpi_pkg is only compiled
  // inside pl_axi_cpi_bridge's own IP scope, not visible here. Per
  // cpi_pkg.sv's rsp_hdr_u.dsp.a2fm struct (packed MSB-first, with a
  // fixed 6b rsvd_ext pad ahead of these fields regardless of IDE
  // support): [22:7] = tag (16b), [2:0] = opcode (3b), [28:27] = devload (2b).
  assign HDRtag      = s_header[22:7];
  assign HDRopcode   = s_header[2:0];
  assign HDRdevload  = s_header[28:27];

endmodule
