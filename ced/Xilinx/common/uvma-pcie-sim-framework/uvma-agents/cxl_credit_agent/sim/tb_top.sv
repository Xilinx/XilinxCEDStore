`timescale 1ns/1ns

module tb_top;

  `include "uvm_macros.svh" 
  import uvm_pkg::*;

  import base_agent_pkg::*;
  import base_sb_pkg::*;
  import cxl_credit_agent_pkg::*;

  `include "full_test.sv"

  bit clk;
  initial forever clk = #5 !clk;

  cxl_credit_agent_if intf();
  assign intf.clk = clk;
  initial uvm_config_db#(virtual cxl_credit_agent_if)::set(null, "", "vif", intf);

  logic vld;
  logic req_prot; logic [2:0] req_crd;
  logic dat_prot; logic [2:0] dat_crd;
  logic rsp_prot; logic [2:0] rsp_crd;

  assign vld                 = intf.vld;
  assign {req_prot, req_crd} = intf.req;
  assign {dat_prot, dat_crd} = intf.dat;
  assign {rsp_prot, rsp_crd} = intf.rsp;

  initial run_test("");

endmodule

