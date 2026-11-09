class aximon_monitor#(type CFG, type VIF, type TXN) extends base_monitor#(CFG,VIF,TXN,base_share);

  `uvm_component_param_utils(aximon_monitor#(CFG,VIF,TXN))

  uvm_analysis_port#(TXN) channel_ap;

  // builds transactions [per ID] which must be in-order, thus, a queue
  TXN wr_txn[int][$];
  TXN rd_txn[int][$];

  TXN int_w_q[$];
  TXN int_aw_q[$];
  TXN int_w_txn;

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"aximon_monitor#(",
                                   CFG::type_name,",",
                                   "VIF,",
                                   TXN::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
    channel_ap = new("channel_ap", this);
  endfunction

  // Push the cfg widths into the interface so its assertions use the same
  // values as the agent. Done after build so a test can finalize cfg first.
  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    vif.addr_width   = cfg.addr_width;
    vif.data_width   = cfg.data_width;
    vif.id_width     = cfg.id_width;
    vif.awuser_width = cfg.awuser_width;
    vif.aruser_width = cfg.aruser_width;
    vif.ruser_width  = cfg.ruser_width;
    vif.wuser_width  = cfg.wuser_width;
    vif.buser_width  = cfg.buser_width;
  endfunction

  function void configure_txn(TXN txn, string info, string info2,
                              aximon_txn::aximon_err_t err_type = aximon_txn::AXI_ERR_NONE);
    txn.info         = info;
    txn.info2        = info2;
    txn.err_type     = err_type;
    txn.addr_width   = cfg.addr_width;
    txn.data_width   = cfg.data_width;
    txn.id_width     = cfg.id_width;
    txn.awuser_width = cfg.awuser_width;
    txn.aruser_width = cfg.aruser_width;
    txn.ruser_width  = cfg.ruser_width;
    txn.wuser_width  = cfg.wuser_width;
    txn.buser_width  = cfg.buser_width;
  endfunction

  // Each helper samples every signal of its channel into the txn
  function void sample_aw_chan(TXN txn);
    txn.awaddr  = vif.mcb.awaddr;
    txn.awburst = vif.mcb.awburst;
    txn.awcache = vif.mcb.awcache;
    txn.awid    = vif.mcb.awid;
    txn.awlen   = vif.mcb.awlen;
    txn.awlock  = vif.mcb.awlock;
    txn.awprot  = vif.mcb.awprot;
    txn.awqos   = vif.mcb.awqos;
    txn.awsize  = vif.mcb.awsize;
    txn.awuser  = vif.mcb.awuser;
    txn.awvalid = vif.mcb.awvalid;
    txn.awready = vif.mcb.awready;
  endfunction

  function void sample_ar_chan(TXN txn);
    txn.araddr  = vif.mcb.araddr;
    txn.arburst = vif.mcb.arburst;
    txn.arcache = vif.mcb.arcache;
    txn.arid    = vif.mcb.arid;
    txn.arlen   = vif.mcb.arlen;
    txn.arlock  = vif.mcb.arlock;
    txn.arprot  = vif.mcb.arprot;
    txn.arqos   = vif.mcb.arqos;
    txn.arsize  = vif.mcb.arsize;
    txn.aruser  = vif.mcb.aruser;
    txn.arvalid = vif.mcb.arvalid;
    txn.arready = vif.mcb.arready;
  endfunction

  function void sample_w_chan(TXN txn);
    txn.wdata.push_back(vif.mcb.wdata);
    txn.wstrb.push_back(vif.mcb.wstrb);
    txn.wuser.push_back(vif.mcb.wuser);
    txn.wlast  = vif.mcb.wlast;
    txn.wvalid = vif.mcb.wvalid;
    txn.wready = vif.mcb.wready;
  endfunction

  function void sample_b_chan(TXN txn);
    txn.bresp  = vif.mcb.bresp;
    txn.bid    = vif.mcb.bid;
    txn.buser  = vif.mcb.buser;
    txn.bvalid = vif.mcb.bvalid;
    txn.bready = vif.mcb.bready;
  endfunction

  function void sample_r_chan(TXN txn);
    txn.rdata.push_back(vif.mcb.rdata);
    txn.ruser.push_back(vif.mcb.ruser);
    txn.rid    = vif.mcb.rid;
    txn.rresp  = vif.mcb.rresp;
    txn.rlast  = vif.mcb.rlast;
    txn.rvalid = vif.mcb.rvalid;
    txn.rready = vif.mcb.rready;
  endfunction

  // 1 if an AW with this ID has completed but its W phase hasn't
  function bit aw_in_flight(logic [31:0] id);
    foreach (int_aw_q[i])
      if (int_aw_q[i].awid == id)
        return 1;
    return 0;
  endfunction

  function void report_outstanding(string id, aximon_cfg::aximon_rpt_t rpt,
                                   string msg);
    case (rpt)
      aximon_cfg::AXI_RPT_INFO    : `uvm_info   (id, msg, UVM_NONE)
      aximon_cfg::AXI_RPT_WARNING : `uvm_warning(id, msg)
      aximon_cfg::AXI_RPT_ERROR   : `uvm_error  (id, msg)
      default                     : ;
    endcase
  endfunction

  function void check_outstanding_rd();
    string msg;
    int    num = 0;

    if (cfg.outstanding_rd_rpt == aximon_cfg::AXI_RPT_HIDDEN)
      return;

    foreach (rd_txn[id,i]) begin
      msg = {msg, $sformatf("\n  read id='h%0h addr='h%0h: %0d R beat(s) received",
                            id, rd_txn[id][i].araddr, rd_txn[id][i].rdata.size())};
      num++;
    end
    if (num)
      report_outstanding("OUTSTANDING_RD", cfg.outstanding_rd_rpt,
        $sformatf("%0d read txn(s) outstanding at the end of the sim:%s", num, msg));
  endfunction

  function void check_outstanding_wr();
    string msg;
    int    num = 0;

    if (cfg.outstanding_wr_rpt == aximon_cfg::AXI_RPT_HIDDEN)
      return;

    foreach (int_aw_q[i]) begin
      msg = {msg, $sformatf("\n  write id='h%0h addr='h%0h: AW done, W not complete",
                            int_aw_q[i].awid, int_aw_q[i].awaddr)};
      num++;
    end
    foreach (int_w_q[i]) begin
      msg = {msg, $sformatf("\n  write: %0d W beat(s) complete, no AW received",
                            int_w_q[i].wdata.size())};
      num++;
    end
    if (int_w_txn != null && int_w_txn.wdata.size()) begin
      msg = {msg, $sformatf("\n  write: %0d W beat(s) received without wlast, no AW matched yet",
                            int_w_txn.wdata.size())};
      num++;
    end
    foreach (wr_txn[id,i]) begin
      msg = {msg, $sformatf("\n  write id='h%0h addr='h%0h: AW and W done, no B",
                            id, wr_txn[id][i].awaddr)};
      num++;
    end
    if (num)
      report_outstanding("OUTSTANDING_WR", cfg.outstanding_wr_rpt,
        $sformatf("%0d write txn(s) outstanding at the end of the sim:%s", num, msg));
  endfunction

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    check_outstanding_rd();
    check_outstanding_wr();
  endfunction

  virtual task run_phase(uvm_phase phase);
    // int_<chan>_txn objects are the txns built UP TO AND INCLUDING that
    // channel's phase of the transfer: int_aw_txn holds the AW info,
    // int_w_txn the W beats, and int_b_txn is the final write txn that
    // includes the AW, W and B info. For reads, int_ar_txn starts with the
    // AR info, then int_r_txn also collects the R beats until rlast.

    int_w_txn = TXN::type_id::create("int_w_txn");
    configure_txn(int_w_txn, "FULL", "WRITE");

    forever begin
      @(vif.mcb);
      if (vif.mcb.awvalid && vif.mcb.awready) begin
        TXN aw_chan_txn;
        TXN int_aw_txn;

        aw_chan_txn = TXN::type_id::create("aw_chan_txn");

        configure_txn(aw_chan_txn, "CHANNEL", "AW");
        sample_aw_chan(aw_chan_txn);
        channel_ap.write(aw_chan_txn);

        int_aw_txn = TXN::type_id::create("int_aw_txn");
        int_aw_txn.copy(aw_chan_txn);
        configure_txn(int_aw_txn, "FULL", "WRITE");
        int_aw_q.push_back(int_aw_txn);
      end

      if (vif.mcb.arvalid && vif.mcb.arready) begin
        TXN ar_chan_txn;
        TXN int_ar_txn;

        ar_chan_txn = TXN::type_id::create("ar_chan_txn");
        configure_txn(ar_chan_txn, "CHANNEL", "AR");
        sample_ar_chan(ar_chan_txn);
        channel_ap.write(ar_chan_txn);

        int_ar_txn = TXN::type_id::create($sformatf("rd_txn_%0d", vif.mcb.arid));
        int_ar_txn.copy(ar_chan_txn);
        configure_txn(int_ar_txn, "FULL", "READ");
        rd_txn[vif.mcb.arid].push_back(int_ar_txn);
      end

      if (vif.mcb.rvalid && vif.mcb.rready) begin
        TXN r_chan_txn;

        r_chan_txn = TXN::type_id::create("r_chan_txn");
        configure_txn(r_chan_txn, "CHANNEL", "R");
        sample_r_chan(r_chan_txn);
        channel_ap.write(r_chan_txn);

        // Same-ID reads return in order, so the oldest outstanding read
        // for this ID owns the beat
        if (rd_txn.exists(vif.mcb.rid) && rd_txn[vif.mcb.rid].size()) begin
          TXN int_r_txn = rd_txn[vif.mcb.rid][0];

          int_r_txn.rdata.push_back(vif.mcb.rdata);
          int_r_txn.ruser.push_back(vif.mcb.ruser);

          if (vif.mcb.rlast) begin
            int_r_txn.rid    = vif.mcb.rid;
            int_r_txn.rresp  = vif.mcb.rresp;
            int_r_txn.rlast  = 1;
            int_r_txn.rvalid = vif.mcb.rvalid;
            int_r_txn.rready = vif.mcb.rready;
            ap.write(int_r_txn);
            void'(rd_txn[vif.mcb.rid].pop_front());
          end
        end else begin
          TXN err_txn = TXN::type_id::create("err_txn");
          configure_txn(err_txn, "CHANNEL", "R", TXN::AXI_ERR_RID_NO_ARID);
          sample_r_chan(err_txn);
          ap.write(err_txn);
        end
      end

      if (vif.mcb.wvalid && vif.mcb.wready) begin
        TXN w_chan_txn = TXN::type_id::create("w_chan_txn");
        configure_txn(w_chan_txn, "CHANNEL", "W");
        sample_w_chan(w_chan_txn);
        channel_ap.write(w_chan_txn);

        int_w_txn.wdata.push_back(vif.mcb.wdata);
        int_w_txn.wuser.push_back(vif.mcb.wuser);
        int_w_txn.wstrb.push_back(vif.mcb.wstrb);

        if (vif.mcb.wlast) begin
          int_w_txn.wlast  = 1;
          int_w_txn.wvalid = vif.mcb.wvalid;
          int_w_txn.wready = vif.mcb.wready;
          int_w_q.push_back(int_w_txn);
          int_w_txn = TXN::type_id::create("int_w_txn");
          configure_txn(int_w_txn, "FULL", "WRITE");
        end
      end

      while (int_w_q.size() && int_aw_q.size()) begin
        TXN int_aw_pop_txn = int_aw_q.pop_front();
        TXN int_wr_pop_txn = int_w_q.pop_front();
        TXN int_wr_txn_con = TXN::type_id::create($sformatf("wr_txn_%0d", int_aw_pop_txn.awid));

        int_wr_txn_con.copy(int_aw_pop_txn);
        configure_txn(int_wr_txn_con, "FULL", "WRITE");
        foreach (int_wr_pop_txn.wdata[i]) int_wr_txn_con.wdata.push_back(int_wr_pop_txn.wdata[i]);
        foreach (int_wr_pop_txn.wuser[i]) int_wr_txn_con.wuser.push_back(int_wr_pop_txn.wuser[i]);
        foreach (int_wr_pop_txn.wstrb[i]) int_wr_txn_con.wstrb.push_back(int_wr_pop_txn.wstrb[i]);
        int_wr_txn_con.wlast  = int_wr_pop_txn.wlast;
        int_wr_txn_con.wvalid = int_wr_pop_txn.wvalid;
        int_wr_txn_con.wready = int_wr_pop_txn.wready;
        wr_txn[int_aw_pop_txn.awid].push_back(int_wr_txn_con);
      end

      if (vif.mcb.bvalid && vif.mcb.bready) begin
        TXN b_chan_txn = TXN::type_id::create("b_chan_txn");

        configure_txn(b_chan_txn, "CHANNEL", "B");
        sample_b_chan(b_chan_txn);
        channel_ap.write(b_chan_txn);

        if (wr_txn.exists(vif.mcb.bid) && wr_txn[vif.mcb.bid].size()) begin
          TXN int_b_txn = wr_txn[vif.mcb.bid].pop_front();
          sample_b_chan(int_b_txn);
          ap.write(int_b_txn);
        end else begin
          TXN err_txn = TXN::type_id::create("err_txn");
          aximon_txn::aximon_err_t err_type;

          // The AW phase finished but the W phase hasn't, vs no AW at all
          err_type = aw_in_flight(vif.mcb.bid) ? aximon_txn::AXI_ERR_BID_NO_W :
                                                 aximon_txn::AXI_ERR_BID_NO_AWID;
          configure_txn(err_txn, "CHANNEL", "B", err_type);
          sample_b_chan(err_txn);
          ap.write(err_txn);
        end
      end
    end
  endtask

endclass
