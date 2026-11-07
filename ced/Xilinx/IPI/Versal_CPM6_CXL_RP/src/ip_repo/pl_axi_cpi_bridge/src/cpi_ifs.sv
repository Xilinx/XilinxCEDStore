interface cpi_req
  import cpi_pkg::req_hdr_u;
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

endinterface

interface cpi_data
  import cpi_pkg::data_hdr_u;
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

endinterface

interface cpi_rsp
  import cpi_pkg::rsp_hdr_u;
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

endinterface
