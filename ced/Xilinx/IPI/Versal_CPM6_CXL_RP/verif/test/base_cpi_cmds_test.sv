/* DESCRIPTION
 * Common machinery for the "full" and "mid" tests. "Full" means the size of
 * the per-(datapath,interface) performance URAM, i.e. 4096 entries, so that
 * a test fills the URAM for each direction it exercises without overflowing
 * it. "Mid" tests use a smaller count (128).
 *
 * Commands go through each CPI's AXI interface (axi4_sim_if), bypassing the
 * custom AXI TG. They are spread round-robin across all AXI IDs so that no
 * single ID's reorder buffer in the pl_axi_cpi_bridge is the limiter. All
 * commands are queued up front with no waits; the bridge back-pressures as
 * it needs to.
 *
 * Line n of CPI c lives at HDM_BASE + (c*URAM_DEPTH + n)*64, so no two
 * datapaths touch the same line when they run in parallel. Read data is not
 * checked, since these tests are for bandwidth and latency.
 *
 * Not a test itself: the cpi*_full_test and cpi*_mid_test classes call
 * run_cmds().
|*/
class base_cpi_cmds_test extends base_ced_test;

  localparam int unsigned URAM_DEPTH = 4096;  // URAM entries
  localparam int unsigned NUM_IDS    = 4;     // 2-bit AXI ID

  // Upper bound on a command's round trip. Even fully serialized, the
  // commands of one direction on one CPI finish within num_cmds*RT_MAX; the
  // timeout adds 10% for start-up and the first command's latency.
  localparam time RT_MAX = 75ns;
             time SEQ_TIMEOUT;

  // Commands per direction per CPI; every derived test must set it by calling
  // set_num_cmds() in its constructor
  int unsigned num_cmds;

  bit   [47:0] HDM_BASE;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Sets the command count and the timeouts that scale with it
  function void set_num_cmds(int unsigned n);
    string msg;
    if (n == 0 || n > URAM_DEPTH) begin
      msg = $sformatf("num_cmds=%0d must be in [1:%0d]", n, URAM_DEPTH);
      `uvm_fatal(get_type_name(), msg)
    end
    num_cmds    = n;
    SEQ_TIMEOUT = num_cmds * RT_MAX * 11 / 10;
    // Bring-up and enumeration take ~160us before the commands start, so the
    // global timeout must cover that plus the commands' own timeout.
    // "timeout" lives in the framework's 1ps time unit, while this package
    // uses the compile timescale, so convert instead of copying the raw value
    timeout = time'(real'(160us + SEQ_TIMEOUT) / real'(1ns) * 1000.0);
  endfunction

  function bit [47:0] line_addr(int cpi, int n);
    return HDM_BASE + 48'((cpi*URAM_DEPTH + n) * 64);
  endfunction

  function void queue_wr(virtual axi4_sim_if vif, int cpi);
    axi_wr_cmd_t wr;
    for (int n=0; n<num_cmds; n++) begin
      wr.addr       = line_addr(cpi, n);
      wr.id         = 2'(n % NUM_IDS);
      wr.data       = {16{4'(cpi), 12'(n), 16'(0)}};
      wr.strb       = '1;
      wr.pre_delay  = 0;
      wr.aw_w_delay = 0;
      if (vif.push_wr(wr) != n)
        `uvm_fatal(get_type_name(), "Write rejected by the AXI4 interface")
    end
  endfunction

  function void queue_rd(virtual axi4_sim_if vif, int cpi);
    axi_rd_cmd_t rd;
    for (int n=0; n<num_cmds; n++) begin
      rd.addr      = line_addr(cpi, n);
      rd.id        = 2'(n % NUM_IDS);
      rd.pre_delay = 0;
      if (vif.push_rd(rd) != n)
        `uvm_fatal(get_type_name(), "Read rejected by the AXI4 interface")
    end
  endfunction

  // Every write must get an OKAY response
  function void check_wr(virtual axi4_sim_if vif, int cpi);
    axi_wr_sum_t sum;
    int          num_bad;
    for (int n=0; n<num_cmds; n++) begin
      sum = vif.wr_sum_q[n % NUM_IDS][vif.wr_sum_loc[n][0].idx];
      if (!sum.done || sum.bresp !== 2'b00) begin
        num_bad++;
        if (num_bad <= 10)
          `uvm_error(get_type_name(), $sformatf(
            "CPI%0d write #%0d @0x%h: done=%0b BRESP=%0d",
            cpi, n, sum.addr, sum.done, sum.bresp))
      end
    end
    if (num_bad == 0)
      `uvm_info(get_type_name(), $sformatf(
        "CPI%0d: %0d writes completed with OKAY", cpi, num_cmds), UVM_LOW)
  endfunction

  // Every read must get an OKAY response
  function void check_rd(virtual axi4_sim_if vif, int cpi);
    axi_rd_sum_t sum;
    int          num_bad;
    for (int n=0; n<num_cmds; n++) begin
      sum = vif.rd_sum_q[n % NUM_IDS][vif.rd_sum_loc[n][0].idx];
      if (!sum.done || sum.rresp !== 2'b00) begin
        num_bad++;
        if (num_bad <= 10)
          `uvm_error(get_type_name(), $sformatf(
            "CPI%0d read #%0d @0x%h: done=%0b RRESP=%0d",
            cpi, n, sum.addr, sum.done, sum.rresp))
      end
    end
    if (num_bad == 0)
      `uvm_info(get_type_name(), $sformatf(
        "CPI%0d: %0d reads completed with OKAY", cpi, num_cmds), UVM_LOW)
  endfunction

  // Runs num_cmds writes and/or reads on CPI0 or, with
  // all_cpi, on every CPI datapath present, all in parallel.
  task run_cmds(bit do_wr, bit do_rd, bit all_cpi);
    int cpi_q[$];

    if (num_cmds == 0)
      `uvm_fatal(get_type_name(), "num_cmds not set; call set_num_cmds()")

    // HDM is placed by enumeration, so take its real base from the EP
    if (ep_pdev == null)
      `uvm_fatal(get_type_name(), "No EP pdev; was enumeration completed?")
    if (ep_pdev.cxl_hdm.size() == 0)
      `uvm_fatal(get_type_name(), "EP pdev has no CXL HDM range recorded")
    HDM_BASE = ep_pdev.cxl_hdm[0].base[47:0];

    for (int ii=0; ii<4; ii++)
      if (axi4_vif[ii] != null && (all_cpi || ii == 0))
        cpi_q.push_back(ii);
    if (cpi_q.size() == 0)
      `uvm_fatal(get_type_name(), "No AXI4 interface for CPI0; is NUM_CPI 0?")

    // Queue everything, then start every datapath back to back
    foreach (cpi_q[ii]) begin
      if (do_wr) queue_wr(axi4_vif[cpi_q[ii]], cpi_q[ii]);
      if (do_rd) queue_rd(axi4_vif[cpi_q[ii]], cpi_q[ii]);
    end
    foreach (cpi_q[ii])
      if (!axi4_vif[cpi_q[ii]].start())
        `uvm_fatal(get_type_name(), $sformatf(
          "Could not start the AXI4 interface queues of CPI%0d", cpi_q[ii]))

    fork
      begin
        foreach (cpi_q[ii]) begin
          automatic virtual axi4_sim_if vif = axi4_vif[cpi_q[ii]];
          fork
            vif.wait_idle();
          join_none
        end
        wait fork;
      end
      begin
        #(SEQ_TIMEOUT);
        `uvm_fatal(get_type_name(), "Timed out waiting for the commands")
      end
    join_any
    disable fork;

    foreach (cpi_q[ii]) begin
      if (do_wr) check_wr(axi4_vif[cpi_q[ii]], cpi_q[ii]);
      if (do_rd) check_rd(axi4_vif[cpi_q[ii]], cpi_q[ii]);
    end
  endtask

endclass
