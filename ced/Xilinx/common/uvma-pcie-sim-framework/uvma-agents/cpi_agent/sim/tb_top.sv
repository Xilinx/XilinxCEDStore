`timescale 1ns/1ps

module tb_top;

  // Default: Number of CPI channels, can be overridden
  `ifndef NREQ 
    `define NREQ 1 
   `endif
  `ifndef NDAT 
    `define NDAT 1 
  `endif
  `ifndef NRSP 
    `define NRSP 1 
  `endif

  localparam REQ = `NREQ;
  localparam DAT = `NDAT;
  localparam RSP = `NRSP;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;
  import cpi_agent_pkg::*;
  import cpi_common_pkg::*;

  bit clock;
  initial begin
    clock = 1'b1;
    forever clock = #5 !clock;
  end

  // Structure
  `include "test_env.sv"
 
  `include "custom_report_server.sv"
  `include "base_test.sv"
  // Tests
  `include "req_test.sv"
  `include "dat_test.sv"
  `include "rsp_test.sv"

  cpi_if #(REQ,DAT,RSP) mst_if(), slv_if();

  assign mst_if.clk = clock; 
  assign slv_if.clk = clock; 

  // Just use the slv interface assertions; don't need two copies of the same ones
  initial begin
    #1;
    mst_if.req [0].en_assert = 1'b0;
    mst_if.data[0].en_assert = 1'b0;
    mst_if.rsp [0].en_assert = 1'b0;
    mst_if.req [1].en_assert = 1'b0;
    mst_if.data[1].en_assert = 1'b0;
    mst_if.rsp [1].en_assert = 1'b0;
    mst_if.req [2].en_assert = 1'b0;
    mst_if.data[2].en_assert = 1'b0;
    mst_if.rsp [2].en_assert = 1'b0;
    mst_if.req [3].en_assert = 1'b0;
    mst_if.data[3].en_assert = 1'b0;
    mst_if.rsp [3].en_assert = 1'b0;
    mst_if.req [4].en_assert = 1'b0;
    mst_if.data[4].en_assert = 1'b0;
    mst_if.rsp [4].en_assert = 1'b0;
    mst_if.req [5].en_assert = 1'b0;
    mst_if.data[5].en_assert = 1'b0;
    mst_if.rsp [5].en_assert = 1'b0;
    mst_if.req [6].en_assert = 1'b0;
    mst_if.data[6].en_assert = 1'b0;
    mst_if.rsp [6].en_assert = 1'b0;
    mst_if.req [7].en_assert = 1'b0;
    mst_if.data[7].en_assert = 1'b0;
    mst_if.rsp [7].en_assert = 1'b0;
  end

  assign slv_if.glbl.txcon_req     = mst_if.glbl.txcon_req;
  assign mst_if.glbl.rxcon_ack     = slv_if.glbl.rxcon_ack;
  assign mst_if.glbl.rxdiscon_nack = slv_if.glbl.rxdiscon_nack;
  assign mst_if.glbl.rx_empty      = slv_if.glbl.rx_empty;
  assign slv_if.glbl.fatal         = mst_if.glbl.fatal;
  assign slv_if.glbl.viral         = mst_if.glbl.viral;
  // only present for A2F
  assign slv_if.glbl.epoch_id      = mst_if.glbl.epoch_id;
  assign slv_if.glbl.epoch_commit  = mst_if.glbl.epoch_commit;
  assign slv_if.glbl.epoch_reject  = mst_if.glbl.epoch_reject;
  for (genvar ii=0; ii<REQ; ii++) begin
    assign slv_if.req[ii].req_is_valid          = mst_if.req[ii].req_is_valid;
    assign mst_if.req[ii].req_block             = slv_if.req[ii].req_block;
    assign slv_if.req[ii].req_early_valid       = mst_if.req[ii].req_early_valid;
    assign slv_if.req[ii].req_protocol_id       = mst_if.req[ii].req_protocol_id;
    assign slv_if.req[ii].req_vc_id             = mst_if.req[ii].req_vc_id;
    assign slv_if.req[ii].req_shared_credit     = mst_if.req[ii].req_shared_credit;
    assign slv_if.req[ii].req_header            = mst_if.req[ii].req_header;
    assign slv_if.req[ii].req_cmd_parity        = mst_if.req[ii].req_cmd_parity;
    assign slv_if.req[ii].req_spid              = mst_if.req[ii].req_spid;      
    assign slv_if.req[ii].req_dpid              = mst_if.req[ii].req_dpid;      
    assign mst_if.req[ii].req_rxcrd_valid       = slv_if.req[ii].req_rxcrd_valid;
    assign mst_if.req[ii].req_rxcrd_protocol_id = slv_if.req[ii].req_rxcrd_protocol_id;
    assign mst_if.req[ii].req_rxcrd_vc_id       = slv_if.req[ii].req_rxcrd_vc_id;
    assign mst_if.req[ii].req_rxcrd_shared      = slv_if.req[ii].req_rxcrd_shared;
    assign slv_if.req[ii].req_txblock_crd_flow  = mst_if.req[ii].req_txblock_crd_flow;
  end
  for (genvar kk=0; kk<DAT; kk++) begin
    assign slv_if.data[kk].data_is_valid          = mst_if.data[kk].data_is_valid;
    assign mst_if.data[kk].data_block             = slv_if.data[kk].data_block;
    assign slv_if.data[kk].data_early_valid       = mst_if.data[kk].data_early_valid;
    assign slv_if.data[kk].data_protocol_id       = mst_if.data[kk].data_protocol_id;
    assign slv_if.data[kk].data_vc_id             = mst_if.data[kk].data_vc_id;
    assign slv_if.data[kk].data_shared_credit     = mst_if.data[kk].data_shared_credit;
    assign slv_if.data[kk].data_header            = mst_if.data[kk].data_header;
    assign slv_if.data[kk].data_sz                = mst_if.data[kk].data_sz;
    assign slv_if.data[kk].data_cmd_parity        = mst_if.data[kk].data_cmd_parity;
    assign slv_if.data[kk].data_spid              = mst_if.data[kk].data_spid;      
    assign slv_if.data[kk].data_dpid              = mst_if.data[kk].data_dpid;      
    assign slv_if.data[kk].data_body              = mst_if.data[kk].data_body;      
    assign slv_if.data[kk].data_byte_enable       = mst_if.data[kk].data_byte_enable;
    assign slv_if.data[kk].data_byte_enable_parity= mst_if.data[kk].data_byte_enable_parity;
    assign slv_if.data[kk].data_poison            = mst_if.data[kk].data_poison;
    assign slv_if.data[kk].data_parity            = mst_if.data[kk].data_parity;
    assign slv_if.data[kk].data_eop               = mst_if.data[kk].data_eop;
    assign mst_if.data[kk].data_rxcrd_valid       = slv_if.data[kk].data_rxcrd_valid;
    assign mst_if.data[kk].data_rxcrd_protocol_id = slv_if.data[kk].data_rxcrd_protocol_id;
    assign mst_if.data[kk].data_rxcrd_vc_id       = slv_if.data[kk].data_rxcrd_vc_id;
    assign mst_if.data[kk].data_rxcrd_shared      = slv_if.data[kk].data_rxcrd_shared;
    assign slv_if.data[kk].data_txblock_crd_flow  = mst_if.data[kk].data_txblock_crd_flow;
  end
  for (genvar mm=0; mm<RSP; mm++) begin
    assign slv_if.rsp[mm].rsp_is_valid          = mst_if.rsp[mm].rsp_is_valid;
    assign mst_if.rsp[mm].rsp_block             = slv_if.rsp[mm].rsp_block;
    assign slv_if.rsp[mm].rsp_early_valid       = mst_if.rsp[mm].rsp_early_valid;
    assign slv_if.rsp[mm].rsp_protocol_id       = mst_if.rsp[mm].rsp_protocol_id;
    assign slv_if.rsp[mm].rsp_vc_id             = mst_if.rsp[mm].rsp_vc_id;
    assign slv_if.rsp[mm].rsp_shared_credit     = mst_if.rsp[mm].rsp_shared_credit;
    assign slv_if.rsp[mm].rsp_header            = mst_if.rsp[mm].rsp_header;
    assign slv_if.rsp[mm].rsp_cmd_parity        = mst_if.rsp[mm].rsp_cmd_parity;
    assign slv_if.rsp[mm].rsp_spid              = mst_if.rsp[mm].rsp_spid;      
    assign slv_if.rsp[mm].rsp_dpid              = mst_if.rsp[mm].rsp_dpid;      
    assign mst_if.rsp[mm].rsp_rxcrd_valid       = slv_if.rsp[mm].rsp_rxcrd_valid;
    assign mst_if.rsp[mm].rsp_rxcrd_protocol_id = slv_if.rsp[mm].rsp_rxcrd_protocol_id;
    assign mst_if.rsp[mm].rsp_rxcrd_vc_id       = slv_if.rsp[mm].rsp_rxcrd_vc_id;
    assign mst_if.rsp[mm].rsp_rxcrd_shared      = slv_if.rsp[mm].rsp_rxcrd_shared;
    assign slv_if.rsp[mm].rsp_txblock_crd_flow  = mst_if.rsp[mm].rsp_txblock_crd_flow;
  end

  initial run_test("");

  initial begin
    uvm_config_db#(virtual cpi_if #(REQ,DAT,RSP))::set(null, "*", "v_mst_if", mst_if);
    uvm_config_db#(virtual cpi_if #(REQ,DAT,RSP))::set(null, "*", "v_slv_if", slv_if);
    uvm_config_db#(int                          )::set(null, "*", "REQ",      REQ);
    uvm_config_db#(int                          )::set(null, "*", "DAT",      DAT);
    uvm_config_db#(int                          )::set(null, "*", "RSP",      RSP);
  end

endmodule
