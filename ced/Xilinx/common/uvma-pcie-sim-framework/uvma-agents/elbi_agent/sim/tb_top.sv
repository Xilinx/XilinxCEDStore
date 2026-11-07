// Define this interface I can use tasks to drive
interface elbi_master_if(input clk);

  logic         ext_lbc_override_en;
  logic  [ 7:0] ext_lbc_ack;
  logic  [63:0] ext_lbc_din;
  logic  [31:0] lbc_ext_addr;
  logic  [63:0] lbc_ext_dout;
  logic  [ 7:0] lbc_ext_valid;
  logic  [ 7:0] lbc_ext_cs;
  logic  [ 7:0] lbc_ext_wr;
  logic  [ 7:0] lbc_ext_rd;
  logic         lbc_ext_dbi_access;
  logic         lbc_ext_cxl_mbar0_access;
  logic         lbc_ext_rom_access;
  logic         lbc_ext_io_access;
  logic  [ 2:0] lbc_ext_bar_num;
  logic  [ 7:0] lbc_ext_vfunc_num;
  logic         lbc_ext_vfunc_active;

  initial begin
    lbc_ext_addr             <= '0;
    lbc_ext_dout             <= '0;
    lbc_ext_valid            <= '0;
    lbc_ext_cs               <= '0;
    lbc_ext_wr               <= '0;
    lbc_ext_rd               <= '0;
    lbc_ext_dbi_access       <= '0;
    lbc_ext_cxl_mbar0_access <= '0;
    lbc_ext_rom_access       <= '0;
    lbc_ext_io_access        <= '0;
    lbc_ext_bar_num          <= '0;
    lbc_ext_vfunc_num        <= '0;
    lbc_ext_vfunc_active     <= '0;
  end

  logic  inp_lbc_ext_valid;
  assign inp_lbc_ext_valid = lbc_ext_valid;

  clocking cb @(posedge clk);
    input  ext_lbc_override_en,
           ext_lbc_ack,
           ext_lbc_din,
           inp_lbc_ext_valid; //so we can sample state
    output lbc_ext_valid,
           lbc_ext_addr,
           lbc_ext_dout,
           lbc_ext_cs,
           lbc_ext_wr,
           lbc_ext_rd,
           lbc_ext_dbi_access,
           lbc_ext_cxl_mbar0_access,
           lbc_ext_rom_access,
           lbc_ext_io_access,
           lbc_ext_bar_num,
           lbc_ext_vfunc_num,
           lbc_ext_vfunc_active;
  endclocking

  task drive_req(
    bit [ 2:0] pf,
    bit [ 2:0] bar,
    bit [31:0] addr,
    bit        wr,
    bit [ 7:0] be,
    bit [63:0] wdata = '0,
    bit        io_access    = 1'b0,
    bit        dbi_access   = 1'b0,
    bit        mbar0_access = 1'b0,
    bit        rom_access   = 1'b0,
    bit        cs = 0
  );
    // Build txn
    cb.lbc_ext_addr    <= addr;
    cb.lbc_ext_dout    <= wdata;
    cb.lbc_ext_valid   <= (1'b1<<pf);
    cb.lbc_ext_bar_num <= dbi_access ? 3'b111 : bar;
    cb.lbc_ext_cs      <= cs ? (1'b1<<pf) : '0;
    cb.lbc_ext_wr      <= {8{wr}} & be;
    cb.lbc_ext_rd      <= {8{!wr}} & be;
    // Access
    cb.lbc_ext_dbi_access       <= dbi_access;
    cb.lbc_ext_cxl_mbar0_access <= mbar0_access;
    cb.lbc_ext_rom_access       <= rom_access;
    cb.lbc_ext_io_access        <= io_access;
    // No VFs right now
    cb.lbc_ext_vfunc_active <= 1'b0;
    cb.lbc_ext_vfunc_num    <= '0;
    repeat (1) @(cb);
    // External access must have response
    if (cs) @(cb iff ext_lbc_ack); 
    // Deassert valid and wait one cycle
    cb.lbc_ext_valid <= '0;
    cb.lbc_ext_cs    <= '0;
    cb.lbc_ext_dbi_access       <= '0;
    cb.lbc_ext_cxl_mbar0_access <= '0;
    cb.lbc_ext_rom_access       <= '0;
    cb.lbc_ext_io_access        <= '0;
    if (cs) @(cb);
  endtask

endinterface

`include "uvm_macros.svh"
import  uvm_pkg::*;

import elbi_agent_pkg::*;
import base_agent_pkg::*;
import base_sb_pkg::*;

module tb_top;

  bit clk;
  initial forever clk = #5 !clk;

  // Master (emulate RTL)
  elbi_master_if mst_if(clk); 

  // Slave (agent)
  elbi_if slv_if(); assign slv_if.clk = clk;

  // Slave to Master
  assign mst_if.ext_lbc_override_en = slv_if.ext_lbc_override_en;
  assign mst_if.ext_lbc_ack         = slv_if.ext_lbc_ack;
  assign mst_if.ext_lbc_din         = slv_if.ext_lbc_din;
  // Master to Slave
  assign slv_if.lbc_ext_addr             = mst_if.lbc_ext_addr;
  assign slv_if.lbc_ext_dout             = mst_if.lbc_ext_dout;
  assign slv_if.lbc_ext_valid            = mst_if.lbc_ext_valid;
  assign slv_if.lbc_ext_cs               = mst_if.lbc_ext_cs;
  assign slv_if.lbc_ext_wr               = mst_if.lbc_ext_wr;
  assign slv_if.lbc_ext_rd               = mst_if.lbc_ext_rd;
  assign slv_if.lbc_ext_dbi_access       = mst_if.lbc_ext_dbi_access;
  assign slv_if.lbc_ext_cxl_mbar0_access = mst_if.lbc_ext_cxl_mbar0_access;
  assign slv_if.lbc_ext_rom_access       = mst_if.lbc_ext_rom_access;
  assign slv_if.lbc_ext_io_access        = mst_if.lbc_ext_io_access;
  assign slv_if.lbc_ext_bar_num          = mst_if.lbc_ext_bar_num;
  assign slv_if.lbc_ext_vfunc_num        = mst_if.lbc_ext_vfunc_num;
  assign slv_if.lbc_ext_vfunc_active=     mst_if.lbc_ext_vfunc_active;

  initial run_test("");

  initial begin
    uvm_config_db#(virtual elbi_master_if)::set(null, "*", "mst_vif", mst_if);
    uvm_config_db#(virtual elbi_if)       ::set(null, "*", "slv_vif", slv_if);
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

  virtual elbi_master_if mst_vif;
  virtual elbi_if        slv_vif;

  elbi_cfg               cfg;
  elbi_agent             agnt; 
  print_sb #(elbi_txn)   sb;
  print_sb               sb_base;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual elbi_master_if)::get(this, "", "mst_vif", mst_vif))
      `uvm_fatal(get_type_name, "Couldn't get 'mst_vif' from cfg db")
    if (!uvm_config_db#(virtual elbi_if)::get(this, "", "slv_vif", slv_vif))
      `uvm_fatal(get_type_name, "Couldn't get 'slv_vif' from cfg db")
    // -- //
    cfg = elbi_cfg::type_id::create("cfg");
    {cfg.component, cfg.activity} = {UVM_SLAVE, UVM_ACTIVE};
    // -- //
    agnt = elbi_agent_creator::spawn("agnt", this, slv_vif, cfg);
    // -- //
    sb      = print_sb#(elbi_txn)::type_id::create("sb", this);
    sb_base = print_sb#()        ::type_id::create("sb_base", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agnt.reqext_ap.connect(sb.analysis_export);
    agnt.reqint_ap.connect(sb.analysis_export);
    agnt.rsp_ap.connect(sb.analysis_export);
    agnt.cmb_ap.connect(sb.analysis_export);
  //agnt.req_ap.connect(sb_base.analysis_export); //incompat. assignment
  endfunction

  virtual task run_phase(uvm_phase phase);
    logic [31:0] dat[$];
    phase.raise_objection(this);
    // Initialize 
    repeat (3) @(mst_vif.cb); 
    // Test DBI Read and Write
    mst_vif.drive_req(0, 0, 12'h900, 0, 'hF,           .dbi_access(1)); 
    mst_vif.drive_req(0, 0, 12'h904, 1, 'hF, 32'hCAFE, .dbi_access(1)); 
    repeat (3) @(mst_vif.cb); 
    /* Test a 16 bit aperture read */
    // Set up; regs
    agnt.shr.add_reg(APP, 32'h1234_3000, 0, 0, 16,,, {32'h5}); //initialized
    agnt.shr.add_reg(APP, 32'h1234_3004, 0, 0, 16,,, {32'h6}); //initialized
    // Set up; range
    dat = '{32'hA, 32'hB, 32'hC, 32'hD};
    agnt.shr.add_range(APP, 32'h8888_4000, 12'hFFF, 0, 0, 16,,, dat); 
    `uvm_info("DEBUG", $sformatf("app: %p", agnt.shr.app), UVM_NONE)
    // Read
    mst_vif.drive_req(0, 0, 32'h1234_3000, 0, 'hFF, .cs(1)); //RD both DWORD
    mst_vif.drive_req(0, 0, 32'h789A_3000, 0, 'hFF, .cs(1)); //RD both DWORD
    // Write
    mst_vif.drive_req(0, 0, 32'h1234_3000, 1, 'h0F, 32'h7<<00, .cs(1)); //WR lower DWORD
    mst_vif.drive_req(0, 0, 32'h789A_3000, 1, 'hF0, 32'h8<<32, .cs(1)); //WR upper DWORD
    // Read
    mst_vif.drive_req(0, 0, 32'h1234_3000, 0, 'hFF, .cs(1)); //RD both DWORD
    // Print result
    agnt.shr.print_apertures(APP);
    agnt.shr.print_mem(APP);
    // ------- //
    // Read
    mst_vif.drive_req(0, 0, 32'h0000_4000, 0, 'hFF, .cs(1)); //RD both DWORD
    // Write
    mst_vif.drive_req(0, 0, 32'h0000_4000, 1, 'h09, {8{4'hA}}, .cs(1)); //WR lower DWORD
    // Read
    mst_vif.drive_req(0, 0, 32'h0000_4000, 0, 'h0F, .cs(1)); //RD lower DWORD
    /* Test MBAR */
    agnt.shr.add_range(MBAR0, 16'h1200, 'hFF, 0, 0, 16);
    // Write
    mst_vif.drive_req(0, 0, 16'h1220, 1, 'hFF, 'h3333_2222_1111_0000, .mbar0_access(1), .cs(1));
    // Read
    mst_vif.drive_req(0, 0, 16'h1220, 0, 'hFF,                      , .mbar0_access(1), .cs(1));
    // Print result
    agnt.shr.print_apertures(MBAR0);
    agnt.shr.print_mem(MBAR0);

    repeat (10) @(mst_vif.cb); 
    phase.drop_objection(this);
  endtask

endclass
