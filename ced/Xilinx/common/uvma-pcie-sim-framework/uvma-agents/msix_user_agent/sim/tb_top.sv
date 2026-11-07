
`include "uvm_macros.svh"
import uvm_pkg::*;

import base_agent_pkg::*;
import base_sb_pkg::*;
import msix_user_agent_pkg::*;

module tb_top;

  bit clk;
  initial forever clk = #5 !clk;

  initial run_test("");

  // Interface of master agent
  msix_user_if msix_if();
  assign msix_if.clk = clk;

  bit    grant;
  assign msix_if.user_grant = grant;
  assign msix_if.user_error = 1'b0;

  // Fake slave responder 
  initial forever begin 
    @(posedge clk iff msix_if.user_req);
    repeat ($urandom_range(0,4)) @(posedge clk);
    grant = 1;
    @(posedge clk);
    grant = 0;
  end

  initial begin
    uvm_config_db#(virtual msix_user_if)::set(null, "*", "msix_vif", msix_if);
  end

  initial forever begin
    `uvm_info("TIME", $sformatf("Time %0t", $time), UVM_NONE)
    repeat (100) @(posedge clk);
  end  

  initial begin
    #10000;
    `uvm_fatal("TIMEOUT", "Timeout hit")
  end

endmodule

// Test and env
class issue_test extends uvm_test;

  `uvm_component_utils(issue_test)

  virtual msix_user_if      msix_vif;

  msix_user_agent           agnt; 
  print_sb #(msix_user_txn) sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual msix_user_if)::get(this, "", "msix_vif", msix_vif))
      `uvm_fatal(get_type_name, "Couldn't get 'msix_vif' from cfg db")
    // -- //
    agnt = msix_user_agent_creator::spawn("agnt", this, msix_vif);
    // -- //
    sb   = print_sb#(msix_user_txn)::type_id::create("sb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agnt.req_ap.connect(sb.analysis_export);
    agnt.gnt_ap.connect(sb.analysis_export);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    repeat (3) @(msix_vif.mcb); 

    // Issue a req to see if grant comes back
    agnt.api.drive(1, .vec(1024), .op(SEND_IRQ));

    // Now loop
    repeat (4) begin
      agnt.api.drive($urandom, .vec($urandom), .op(SEND_IRQ));
    end

    @(msix_vif.mcb); 

    // Now loop
    repeat (5) begin
      agnt.api.drive($urandom, .vec($urandom), .op(SEND_IRQ));
      @(msix_vif.mcb); 
    end

    repeat (10) @(msix_vif.mcb); 
    phase.drop_objection(this);
  endtask

endclass
