/* DESCRIPTION
 * Issues 4096 writes and 4096 reads on every CPI datapath present, in
 * parallel, through each one's AXI interface (axi4_sim_if), bypassing the
 * custom AXI TGs. Each datapath uses its own slice of the HDM. Here "full"
 * means the size of the per-(datapath,interface) performance URAM (4096
 * entries). Commands are spread across all AXI IDs and all are queued up
 * front; the pl_axi_cpi_bridge back-pressures as needed. Reads and writes run
 * independently. Only the responses are checked, since the test is for
 * bandwidth and latency.
|*/
class cpiALL_mix_full_test extends base_cpi_cmds_test;

  `uvm_component_utils(cpiALL_mix_full_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    set_num_cmds(URAM_DEPTH);
  endfunction

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    phase.raise_objection(this);
    run_cmds(.do_wr(1), .do_rd(1), .all_cpi(1));
    phase.drop_objection(this);
  endtask

endclass
