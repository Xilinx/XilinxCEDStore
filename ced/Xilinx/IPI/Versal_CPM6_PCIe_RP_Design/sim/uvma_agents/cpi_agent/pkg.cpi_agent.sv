`include "cpi_if.sv"

package cpi_agent_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;

  import cpi_common_pkg::*;
  import global_agent_pkg::*;
  import req_agent_pkg::*;
  import data_agent_pkg::*;
  import rsp_agent_pkg::*;

  `include "cpi_cfg.sv"
  `include "cpi_vsequencer.sv"
  `include "cpi_base_vseq.sv"
  `include "cpi_agent.sv"

endpackage
