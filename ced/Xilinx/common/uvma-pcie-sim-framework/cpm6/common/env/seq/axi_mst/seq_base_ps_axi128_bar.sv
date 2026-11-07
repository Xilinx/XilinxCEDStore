class seq_base_ps_axi128_bar extends seq_base_ps_axi128;

  `uvm_object_utils(seq_base_ps_axi128_bar)

  localparam bit [17:0] BAR_USER = 18'h200;

  function new(string name = "seq_base_ps_axi128_bar");
    super.new(name);
  endfunction

  virtual task axi_wr(bit [47:0] addr, logic [127:0] data, bit [4:0] nbytes = 16);
`ifdef CPM6_RTL
    string      msg;
    int         num_x;
    bit [127:0] _data = data;
    svt_axi_master_transaction wr = svt_axi_master_transaction::type_id::create("wr");
    if (addr % nbytes)
      `uvm_fatal(get_type_name, $sformatf("AXI4 does not allow unaligned accesses | addr=0x%h, nbytes=%0d", addr, nbytes))
    `uvm_create(wr)
    wr.port_cfg        = cfg;
    wr.xact_type       = svt_axi_transaction::WRITE;
    wr.burst_type      = svt_axi_transaction::INCR;
    case (nbytes)
      16 : wr.burst_size = svt_axi_transaction::BURST_SIZE_128BIT;
       8 : wr.burst_size = svt_axi_transaction::BURST_SIZE_64BIT;
       4 : wr.burst_size = svt_axi_transaction::BURST_SIZE_32BIT;
       2 : wr.burst_size = svt_axi_transaction::BURST_SIZE_16BIT;
       1 : wr.burst_size = svt_axi_transaction::BURST_SIZE_8BIT;
    endcase
    wr.atomic_type     = svt_axi_transaction::NORMAL;
    wr.addr            = addr;
    wr.addr_user       = BAR_USER;  // AWUSER — routes through PCIe BAR aperture
    wr.burst_length    = 1;
    wr.data            = new[1];
    wr.wstrb           = new[1];
    wr.data_user       = new[1];
    wr.wvalid_delay    = new[1];
    wr.data[0]         = _data;
    wr.data_user[0]    = BAR_USER;  // WUSER
    for (int ii = 0; ii < 16; ii++) begin
      num_x = $countbits(data[ii*8+:8], 'x);
      case (num_x)
        8       : wr.wstrb[0][ii] = 1'b0;
        0       : wr.wstrb[0][ii] = 1'b1;
        default : begin
                    msg = $sformatf("data[%0d:%0d] contains %0d Xs", (ii+1)*8-1, ii*8, num_x);
                    `uvm_fatal(get_type_name, msg);
                  end
      endcase
    end
    wr.wvalid_delay[0] = $urandom_range(4, 10);
    wr.bready_delay    = $urandom_range(4, 10);
    `uvm_send(wr)
    get_response(rsp);
    if (rsp.bresp != svt_axi_transaction::OKAY)
      `uvm_error(get_type_name, $sformatf("AXI Write 0x%h=0x%h -> BRESP=%0s", addr, _data, rsp.bresp.name))
`else
    super.axi_wr(addr, data, nbytes);
`endif
  endtask

  virtual task axi_rd(bit [47:0] addr, output logic [127:0] data, input bit [4:0] nbytes = 16);
`ifdef CPM6_RTL
    svt_axi_master_transaction rd = svt_axi_master_transaction::type_id::create("rd");
    if (addr % nbytes)
      `uvm_fatal(get_type_name, $sformatf("AXI4 does not allow unaligned accesses | addr=0x%h, nbytes=%0d", addr, nbytes))
    `uvm_create(rd)
    rd.port_cfg        = cfg;
    rd.xact_type       = svt_axi_transaction::READ;
    rd.burst_type      = svt_axi_transaction::INCR;
    case (nbytes)
      16 : rd.burst_size = svt_axi_transaction::BURST_SIZE_128BIT;
       8 : rd.burst_size = svt_axi_transaction::BURST_SIZE_64BIT;
       4 : rd.burst_size = svt_axi_transaction::BURST_SIZE_32BIT;
       2 : rd.burst_size = svt_axi_transaction::BURST_SIZE_16BIT;
       1 : rd.burst_size = svt_axi_transaction::BURST_SIZE_8BIT;
    endcase
    rd.atomic_type     = svt_axi_transaction::NORMAL;
    rd.addr            = addr;
    rd.addr_user       = BAR_USER;  // ARUSER — routes through PCIe BAR aperture
    rd.burst_length    = 1;
    rd.data            = new[1];
    rd.rresp           = new[1];
    rd.data_user       = new[1];
    rd.rready_delay    = new[1];
    rd.rready_delay[0] = $urandom_range(4, 10);
    `uvm_send(rd)
    get_response(rsp);
    data = rsp.data[0];
    if (rsp.rresp[0] != svt_axi_transaction::OKAY)
      `uvm_error(get_type_name, $sformatf("AXI Read 0x%h -> RRESP=%0s", addr, rsp.rresp[0].name))
`else
    super.axi_rd(addr, data, nbytes);
`endif
  endtask

`ifdef CPM6_RTL
  virtual task axi_wr_128(bit [47:0] addr, logic [127:0] data,
                           bit [17:0] awuser = BAR_USER, bit [17:0] wuser = BAR_USER);
    bit timeout_flag  = 0;
    int num_x;
    bit [127:0] _data = data;
    svt_axi_master_transaction wr = svt_axi_master_transaction::type_id::create("wr");
    `uvm_create(wr)
    wr.port_cfg        = cfg;
    wr.xact_type       = svt_axi_transaction::WRITE;
    wr.burst_type      = svt_axi_transaction::INCR;
    wr.burst_size      = svt_axi_transaction::BURST_SIZE_128BIT;
    wr.atomic_type     = svt_axi_transaction::NORMAL;
    wr.addr            = addr;
    wr.addr_user       = awuser;
    wr.burst_length    = 1;
    wr.data            = new[1];
    wr.wstrb           = new[1];
    wr.data_user       = new[1];
    wr.wvalid_delay    = new[1];
    wr.data[0]         = _data;
    wr.data_user[0]    = wuser;
    for (int ii = 0; ii < 16; ii++) begin
      num_x = $countbits(data[ii*8+:8], 'x);
      wr.wstrb[0][ii]  = (num_x == 0) ? 1'b1 : 1'b0;
    end
    wr.wvalid_delay[0] = 0;
    wr.bready_delay    = 0;
    `uvm_send(wr)
    fork
      begin get_response(rsp); end
      begin
        #50us;
        timeout_flag = 1;
        `uvm_error(get_type_name, $sformatf("axi_wr_128 TIMEOUT 50us: addr=0x%h", addr))
      end
    join_any
    disable fork;
    if (!timeout_flag && rsp.bresp != svt_axi_transaction::OKAY)
      `uvm_error(get_type_name, $sformatf("AXI Write128 0x%h -> BRESP=%0s", addr, rsp.bresp.name))
  endtask

  virtual task axi_rd_128(bit [47:0] addr, output logic [127:0] data,
                           input bit [17:0] aruser = BAR_USER);
    bit timeout_flag = 0;
    svt_axi_master_transaction rd = svt_axi_master_transaction::type_id::create("rd");
    `uvm_create(rd)
    rd.port_cfg        = cfg;
    rd.xact_type       = svt_axi_transaction::READ;
    rd.burst_type      = svt_axi_transaction::INCR;
    rd.burst_size      = svt_axi_transaction::BURST_SIZE_128BIT;
    rd.atomic_type     = svt_axi_transaction::NORMAL;
    rd.addr            = addr;
    rd.addr_user       = aruser;
    rd.burst_length    = 1;
    rd.data            = new[1];
    rd.rresp           = new[1];
    rd.data_user       = new[1];
    rd.rready_delay    = new[1];
    rd.rready_delay[0] = 0;
    `uvm_send(rd)
    fork
      begin get_response(rsp); end
      begin
        #50us;
        timeout_flag = 1;
        `uvm_error(get_type_name, $sformatf("axi_rd_128 TIMEOUT 50us: addr=0x%h", addr))
      end
    join_any
    disable fork;
    if (!timeout_flag) begin
      data = rsp.data[0];
      if (rsp.rresp[0] != svt_axi_transaction::OKAY)
        `uvm_error(get_type_name, $sformatf("AXI Read128 0x%h -> RRESP=%0s", addr, rsp.rresp[0].name))
    end
  endtask
`endif // CPM6_RTL

  // axi_wr_burst: issues one AXI4 INCR burst write with internally-randomized data.
  virtual task axi_wr_burst(bit [47:0] addr, int num_beats);
    logic [127:0] wr_data[$:256];
    if (!std::randomize(wr_data) with { wr_data.size() == num_beats; })
      `uvm_fatal(get_type_name, "axi_wr_burst: randomization of wr_data failed")
`ifdef CPM6_RTL
    begin
      svt_axi_master_transaction wr = svt_axi_master_transaction::type_id::create("wr");
      `uvm_create(wr)
      wr.port_cfg        = cfg;
      wr.xact_type       = svt_axi_transaction::WRITE;
      wr.burst_type      = svt_axi_transaction::INCR;
      wr.burst_size      = svt_axi_transaction::BURST_SIZE_128BIT;
      wr.atomic_type     = svt_axi_transaction::NORMAL;
      wr.addr            = addr;
      wr.addr_user       = BAR_USER;
      wr.burst_length    = num_beats;
      wr.data            = new[num_beats];
      wr.wstrb           = new[num_beats];
      wr.data_user       = new[num_beats];
      wr.wvalid_delay    = new[num_beats];
      for (int ii = 0; ii < num_beats; ii++) begin
        wr.data[ii]         = wr_data[ii];
        wr.wstrb[ii]        = '1;
        wr.data_user[ii]    = BAR_USER;
        wr.wvalid_delay[ii] = 0;
      end
      wr.bready_delay = 0;
      `uvm_send(wr)
      get_response(rsp);
      if (rsp.bresp != svt_axi_transaction::OKAY)
        `uvm_error(get_type_name, $sformatf("AXI Burst Write 0x%h [%0d beats] -> BRESP=%0s",
                                             addr, num_beats, rsp.bresp.name))
    end
`else
    foreach (wr_data[ii])
      axi_wr(addr + ii*16, wr_data[ii]);
`endif
  endtask

  // axi_rd_burst: issues one AXI4 INCR burst read.
  virtual task axi_rd_burst(bit [47:0] addr, int n, output logic [127:0] rd_data[$:256]);
`ifdef CPM6_RTL
    svt_axi_master_transaction rd = svt_axi_master_transaction::type_id::create("rd");
    `uvm_create(rd)
    rd.port_cfg        = cfg;
    rd.xact_type       = svt_axi_transaction::READ;
    rd.burst_type      = svt_axi_transaction::INCR;
    rd.burst_size      = svt_axi_transaction::BURST_SIZE_128BIT;
    rd.atomic_type     = svt_axi_transaction::NORMAL;
    rd.addr            = addr;
    rd.addr_user       = BAR_USER;
    rd.burst_length    = n;
    rd.data            = new[n];
    rd.rresp           = new[n];
    rd.data_user       = new[n];
    rd.rready_delay    = new[n];
    for (int ii = 0; ii < n; ii++)
      rd.rready_delay[ii] = 0;
    `uvm_send(rd)
    get_response(rsp);
    rd_data.delete();
    for (int ii = 0; ii < n; ii++) begin
      rd_data.push_back(rsp.data[ii]);
      if (rsp.rresp[ii] != svt_axi_transaction::OKAY)
        `uvm_error(get_type_name, $sformatf("AXI Burst Read 0x%h beat[%0d] -> RRESP=%0s",
                                             addr + ii*16, ii, rsp.rresp[ii].name))
    end
`else
    begin : non_rtl_rd_burst
      logic [127:0] _beat;
      rd_data.delete();
      for (int ii = 0; ii < n; ii++) begin
        axi_rd(addr + ii*16, _beat);
        rd_data.push_back(_beat);
      end
    end
`endif
  endtask

endclass
