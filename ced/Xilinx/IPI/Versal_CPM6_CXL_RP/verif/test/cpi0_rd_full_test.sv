/* DESCRIPTION
 * Issues 4096 reads through CPI0's AXI interface (axi4_sim_if), bypassing the
 * custom AXI TG. Here "full" means the size of the per-(datapath,interface)
 * performance URAM (4096 entries). Commands are spread across all AXI IDs and
 * all are queued up front; the pl_axi_cpi_bridge back-pressures as needed.
 * Every read must get an OKAY response; the data is not checked.
|*/
class cpi0_rd_full_test extends base_cpi_cmds_test;

  `uvm_component_utils(cpi0_rd_full_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    set_num_cmds(URAM_DEPTH);
  endfunction

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    phase.raise_objection(this);
    run_cmds(.do_wr(0), .do_rd(1), .all_cpi(0));
    phase.drop_objection(this);
  endtask

endclass
