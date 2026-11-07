/* DESCRIPTION
 * Issues 128 writes through CPI0's AXI interface (axi4_sim_if), bypassing the
 * custom AXI TG. Commands are spread across all AXI IDs and all are queued up
 * front; the pl_axi_cpi_bridge back-pressures as needed. Every write must get
 * an OKAY response.
|*/
class cpi0_wr_mid_test extends base_cpi_cmds_test;

  `uvm_component_utils(cpi0_wr_mid_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    set_num_cmds(128);
  endfunction

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    phase.raise_objection(this);
    run_cmds(.do_wr(1), .do_rd(0), .all_cpi(0));
    phase.drop_objection(this);
  endtask

endclass
