// PS to CPM6 32bit AXI-Lite Config Interface
class seq_base_ps_axi32 extends 
`ifdef CPM6_RTL
svt_axi_master_base_sequence;
`else
uvm_sequence;
`endif

  `uvm_object_utils(seq_base_ps_axi32)

`ifndef CPM6_RTL
  `uvm_declare_p_sequencer(ps_vip_vsequencer);

  ps_route_mst_e ps_vip_mst;
  ps_route_slv_e ps_vip_slv;
`endif

  function new(string name = "seq_base_ps_axi32");
    super.new(name);
`ifndef CPM6_RTL
    ps_vip_mst = PS_CPM_CFG;
    ps_vip_slv = R5_API;
`endif
  endfunction

`ifdef CPM6_RTL
  virtual task pre_body();
    svt_configuration got_cfg;
    super.pre_body();
    p_sequencer.get_cfg(got_cfg);
    if (!$cast(cfg, got_cfg))
      `uvm_fatal(get_type_name, "Couldn't cast to the cfg object")
  endtask
`endif

  // If any byte of data contains all X, then wstrb for that byte is 0
  virtual task axi_wr(bit [47:0] addr, logic [31:0] data);
`ifdef CPM6_RTL
    string     msg;
    int        num_x;
    bit [31:0] _data = data; //to get rid of any X bits
    svt_axi_master_transaction wr = svt_axi_master_transaction::type_id::create("wr"); 
    `uvm_create(wr)
    wr.port_cfg        = cfg;
    wr.xact_type       = svt_axi_transaction::WRITE;
    wr.burst_type      = svt_axi_transaction::INCR;
    wr.burst_size      = svt_axi_transaction::BURST_SIZE_32BIT;
    wr.atomic_type     = svt_axi_transaction::NORMAL;
    wr.addr            = addr;
    wr.burst_length    = 1;
    wr.data            = new[1];
    wr.wstrb           = new[1];
    wr.data_user       = new[1];
    wr.wvalid_delay    = new[1];
    wr.data[0]         = _data;
    for (int ii=0; ii<4; ii++) begin
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
    wr.wvalid_delay[0] = $urandom_range(4,10);
    wr.bready_delay    = $urandom_range(4,10);
    `uvm_send(wr)
    get_response(rsp);
    if (rsp.bresp != svt_axi_transaction::OKAY)
      `uvm_error(get_type_name, $sformatf("AXI Write 0x%h=0x%h -> BRESP=%0s", addr, _data, rsp.bresp.name))
`else
    bit  [31:0] _data = data; //to get rid of any X bits
    logic [1:0] bresp;
    string      bresp_enum;
    if (addr inside {['hFC00_0000:'hFCFF_FFFF]})
      p_sequencer.ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG, 1'b1);
    else begin
      p_sequencer.ps_vip_api.set_routing_config(R5_API, PS_CPM_PCIE_AXI, 1'b1);
    end
    p_sequencer.ps_vip_api.write_data_32(R5_API, addr, _data, bresp);
    case (bresp)
      2'b00   : bresp_enum = "OKAY";
      2'b01   : bresp_enum = "EXOKAY";
      2'b10   : bresp_enum = "SLVERR";
      2'b11   : bresp_enum = "DECERR";
      default : bresp_enum = "INVALID"; 
    endcase
    if (!(bresp inside {2'b00, 2'b01}))
      `uvm_error(get_type_name, $sformatf("AXI Write 0x%h=0x%h -> BRESP=%0s", addr, _data, bresp_enum))
    if (addr inside {['hFC00_0000:'hFCFF_FFFF]})
      p_sequencer.ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG, 1'b0);
    else
      p_sequencer.ps_vip_api.set_routing_config(R5_API, PS_CPM_PCIE_AXI, 1'b0);
`endif
  endtask

  virtual task axi_rd(bit [47:0] addr, output logic [31:0] data);
`ifdef CPM6_RTL
    svt_axi_master_transaction rd = svt_axi_master_transaction::type_id::create("rd"); 
    // Do Read
    `uvm_create(rd)
    rd.port_cfg        = cfg;
    rd.xact_type       = svt_axi_transaction::READ;
    rd.burst_type      = svt_axi_transaction::INCR;
    rd.burst_size      = svt_axi_transaction::BURST_SIZE_32BIT;
    rd.atomic_type     = svt_axi_transaction::NORMAL;
    rd.addr            = addr;
    rd.burst_length    = 1;
    rd.data            = new[1];
    rd.rresp           = new[1];
    rd.data_user       = new[1];
    rd.rready_delay    = new[1];
    rd.rready_delay[0] = $urandom_range(4,10);
    `uvm_send(rd)
    get_response(rsp);
    data = rsp.data[0];
    if (rsp.rresp[0] != svt_axi_transaction::OKAY)
      `uvm_error(get_type_name, $sformatf("AXI Read 0x%h -> RRESP=%0s", addr, rsp.rresp[0].name))
`else
    logic [1:0] rresp;
    string      rresp_enum;
    if (addr inside {['hFC00_0000:'hFCFF_FFFF]})
      p_sequencer.ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG, 1'b1);
    else begin
      p_sequencer.ps_vip_api.set_routing_config(R5_API, PS_CPM_PCIE_AXI, 1'b1);
    end
    p_sequencer.ps_vip_api.read_data_32(R5_API, addr, data, rresp);
    case (rresp)
      2'b00   : rresp_enum = "OKAY";
      2'b01   : rresp_enum = "EXOKAY";
      2'b10   : rresp_enum = "SLVERR";
      2'b11   : rresp_enum = "DECERR";
      default : rresp_enum = "INVALID"; 
    endcase
    if (!(rresp inside {2'b00, 2'b01}))
      `uvm_error(get_type_name, $sformatf("AXI Read 0x%h -> RRESP=%0s", addr, rresp_enum))
    if (addr inside {['hFC00_0000:'hFCFF_FFFF]})
      p_sequencer.ps_vip_api.set_routing_config(R5_API, PS_CPM_CFG, 1'b0);
    else
      p_sequencer.ps_vip_api.set_routing_config(R5_API, PS_CPM_PCIE_AXI, 1'b0);
`endif
  endtask

  // Each bit can be individudally controlled for the write
  // data[n] = 1'bx -> leave unchanged 
  // data[n] = 1'b0 -> clear
  // data[n] = 1'b1 -> set
  virtual task axi_rd_mod_wr(bit [47:0] addr, logic [31:0] data);
    bit [31:0] rdata;
    bit [31:0] wdata;
    // Do read
    axi_rd(addr, rdata);
    // Create wdata bit-by-bit
    foreach (rdata[ii])
      case (1'b1)
        data[ii]===1'bx : wdata[ii] = rdata[ii];
        data[ii]===1'b0 : wdata[ii] = 1'b0;
        data[ii]===1'b1 : wdata[ii] = 1'b1;
      endcase
    // Do write
    axi_wr(addr, wdata);
  endtask

endclass

