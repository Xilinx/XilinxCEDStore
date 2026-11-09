/* DESCRIPTION
 * The most basic, targeted test: issues a single write and then a single read
 * to the same HDM line through CPI0's AXI interface (axi4_sim_if), bypassing
 * the custom AXI TG, and checks that the read returns the data that was
 * written.
|*/
class cpi0_basic_test extends base_ced_test;

  `uvm_component_utils(cpi0_basic_test)

        bit [47:0] HDM_BASE;
  const time       SEQ_TIMEOUT = 10us;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    // Bring-up and enumeration take ~160us before the commands start, so the
    // global timeout must cover that plus the commands' own timeout.
    // "timeout" lives in the framework's 1ps time unit, while this package
    // uses the compile timescale, so convert instead of copying the raw value
    timeout = time'(real'(160us + SEQ_TIMEOUT) / real'(1ns) * 1000.0);
  endfunction

  virtual task main_phase(uvm_phase phase);
    virtual axi4_sim_if vif;
    axi_wr_cmd_t        wr;
    axi_rd_cmd_t        rd;
    axi_wr_sum_t        wr_sum;
    axi_rd_sum_t        rd_sum;
    int                 wr_num, rd_num;

    super.main_phase(phase);
    phase.raise_objection(this);

    vif = axi4_vif[0];
    if (vif == null)
      `uvm_fatal(get_type_name(), "No AXI4 interface for CPI0; is NUM_CPI 0?")

    // HDM is placed by enumeration, so take its real base from the EP
    if (ep_pdev == null)
      `uvm_fatal(get_type_name(), "No EP pdev; was enumeration completed?")
    if (ep_pdev.cxl_hdm.size() == 0)
      `uvm_fatal(get_type_name(), "EP pdev has no CXL HDM range recorded")
    HDM_BASE = ep_pdev.cxl_hdm[0].base[47:0];

    // Write one line, then read it back once the write has completed
    wr.addr       = HDM_BASE;
    wr.id         = 2'd0;
    wr.strb       = '1;
    wr.pre_delay  = 0;
    wr.aw_w_delay = 0;
    for (int ii=0; ii<16; ii++)
      wr.data[32*ii +: 32] = 32'hC0DE_0000 + ii;
    wr_num = vif.push_wr(wr);
    if (!vif.push_rd_wait(AXI_WAIT_IND_WR_DONE, wr_num))
      `uvm_fatal(get_type_name(), "Could not queue the wait on the write")
    rd.addr      = HDM_BASE;
    rd.id        = 2'd0;
    rd.pre_delay = 0;
    rd_num = vif.push_rd(rd);
    if (wr_num < 0 || rd_num < 0)
      `uvm_fatal(get_type_name(), "Command was rejected by the AXI4 interface")

    // Start both queues, which also takes the bus from the custom AXI TG
    if (!vif.start())
      `uvm_fatal(get_type_name(), "Could not start the AXI4 interface queues")
    fork
      vif.wait_idle();
      begin
        #(SEQ_TIMEOUT);
        `uvm_fatal(get_type_name(), "Timed out waiting for the write/read")
      end
    join_any
    disable fork;

    // Check
    wr_sum = vif.wr_sum_q[wr.id][vif.wr_sum_loc[wr_num][0].idx];
    rd_sum = vif.rd_sum_q[rd.id][vif.rd_sum_loc[rd_num][0].idx];
    if (wr_sum.bresp !== 2'b00)
      `uvm_error(get_type_name(), $sformatf("Write BRESP=%0d", wr_sum.bresp))
    if (rd_sum.rresp !== 2'b00)
      `uvm_error(get_type_name(), $sformatf("Read RRESP=%0d", rd_sum.rresp))
    if (rd_sum.rdata !== wr.data)
      `uvm_error(get_type_name(), $sformatf(
        "Read data mismatch @0x%h: wrote 0x%h, read 0x%h",
        HDM_BASE, wr.data, rd_sum.rdata))
    else
      `uvm_info(get_type_name(), $sformatf(
        "CPI0 write then read of 0x%h matched", HDM_BASE), UVM_LOW)

    phase.drop_objection(this);
  endtask

endclass
