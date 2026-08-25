class aximon_monitor#(type CFG, type VIF, type TXN) extends base_monitor#(CFG,VIF,TXN,base_share);

  `uvm_component_param_utils(aximon_monitor#(CFG,VIF,TXN))

  uvm_analysis_port#(TXN) granular_ap;

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"aximon_monitor#(",
                                   CFG::type_name,",",
                                   "VIF,",
                                   TXN::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
    granular_ap = new("granular_ap", this);
  endfunction

  function set_txn_widths(TXN txn);
    txn.addr_width   = cfg.addr_width;
    txn.data_width   = cfg.data_width;
    txn.id_width     = cfg.id_width;
    txn.awuser_width = cfg.awuser_width;
    txn.aruser_width = cfg.aruser_width;
    txn.ruser_width  = cfg.ruser_width;
    txn.wuser_width  = cfg.wuser_width;
    txn.buser_width  = cfg.buser_width;
  endfunction

  virtual task run_phase(uvm_phase phase);
    TXN wr_txn[int][$];
    TXN rd_txn[int];

    TXN int_wr_q[$];
    TXN int_aw_q[$];

    TXN int_wr_txn = TXN::type_id::create("int_wr_txn");
    TXN int_aw_txn = TXN::type_id::create("int_aw_txn");;

    set_txn_widths(int_wr_txn);
    set_txn_widths(int_aw_txn);

    forever begin
      @(vif.cb);
      if (vif.cb.awvalid && vif.cb.awready) begin
        TXN aw_txn_granular = TXN::type_id::create("aw_txn_granular");
        aw_txn_granular.txn_type     = TXN::AXI_AWADDR;
        set_txn_widths(aw_txn_granular);

        aw_txn_granular.awaddr       = vif.cb.awaddr;
        aw_txn_granular.awuser       = vif.cb.awuser;
        aw_txn_granular.awburst      = vif.cb.awburst;
        aw_txn_granular.awcache      = vif.cb.awcache;
        aw_txn_granular.awid         = vif.cb.awid;
        aw_txn_granular.awlen        = vif.cb.awlen;
        aw_txn_granular.awlock       = vif.cb.awlock;
        aw_txn_granular.awprot       = vif.cb.awprot;
        aw_txn_granular.awqos        = vif.cb.awqos;
        aw_txn_granular.awsize       = vif.cb.awsize;
        granular_ap.write(aw_txn_granular);

        int_aw_txn.copy(aw_txn_granular);
        int_aw_txn.txn_type = TXN::AXI_WRITE;
        int_aw_q.push_back(int_aw_txn);
      end

      if (vif.cb.arvalid && vif.cb.arready) begin
        TXN ar_txn_granular = TXN::type_id::create("ar_txn_granular");
        ar_txn_granular.txn_type     = TXN::AXI_ARADDR;
        set_txn_widths(ar_txn_granular);
        ar_txn_granular.araddr       = vif.cb.araddr;
        ar_txn_granular.aruser       = vif.cb.aruser;
        ar_txn_granular.arburst      = vif.cb.arburst;
        ar_txn_granular.arcache      = vif.cb.arcache;
        ar_txn_granular.arid         = vif.cb.arid;
        ar_txn_granular.arlen        = vif.cb.arlen;
        ar_txn_granular.arlock       = vif.cb.arlock;
        ar_txn_granular.arprot       = vif.cb.arprot;
        ar_txn_granular.arqos        = vif.cb.arqos;
        ar_txn_granular.arsize       = vif.cb.arsize;
        granular_ap.write(ar_txn_granular);

        rd_txn[vif.cb.arid] = TXN::type_id::create($sformatf("rd_txn_%0d", vif.cb.arid));;
        rd_txn[vif.cb.arid].copy(ar_txn_granular);
        rd_txn[vif.cb.arid].txn_type = TXN::AXI_READ;
      end

      if (vif.cb.rvalid && vif.cb.rready) begin
        TXN r_txn_granular = TXN::type_id::create("r_txn_granular");
        r_txn_granular.txn_type     = TXN::AXI_RDATA;
        set_txn_widths(r_txn_granular);
        r_txn_granular.rid          = vif.cb.rid;
        r_txn_granular.rresp        = vif.cb.rresp;
        r_txn_granular.rlast        = vif.cb.rlast;
        r_txn_granular.rdata.push_back(vif.cb.rdata);
        r_txn_granular.ruser.push_back(vif.cb.ruser);
        granular_ap.write(r_txn_granular);

        if (rd_txn[vif.cb.rid] != null) begin
          rd_txn[vif.cb.rid].rdata.push_back(vif.cb.rdata);
          rd_txn[vif.cb.rid].ruser.push_back(vif.cb.ruser);

          if (vif.cb.rlast) begin
            rd_txn[vif.cb.rid].rid   = vif.cb.rid;
            rd_txn[vif.cb.rid].rresp = vif.cb.rresp;
            rd_txn[vif.cb.rid].rlast = 1;
            ap.write(rd_txn[vif.cb.rid]);
            rd_txn[vif.cb.rid] = null;
          end
        end else begin
          TXN err_txn = TXN::type_id::create("err_txn");
          set_txn_widths(err_txn);
          err_txn.txn_type = TXN::AXI_RDATA;
          err_txn.rid = vif.cb.rid;
          err_txn.rresp = vif.cb.rresp;
          err_txn.err_type = TXN::AXI_ERR_RID_NO_ARID;
          ap.write(err_txn);
        end
      end

      if (vif.cb.wvalid && vif.cb.wready) begin
        TXN w_txn_granular = TXN::type_id::create("w_txn_granular");
        w_txn_granular.txn_type = TXN::AXI_WDATA;
        set_txn_widths(w_txn_granular);
        w_txn_granular.wlast = vif.cb.wlast;
        w_txn_granular.wstrb.push_back(vif.cb.wstrb);
        w_txn_granular.wuser.push_back(vif.cb.wuser);
        w_txn_granular.wdata.push_back(vif.cb.wdata);
        granular_ap.write(w_txn_granular);

        int_wr_txn.wdata.push_back(vif.cb.wdata);
        int_wr_txn.wuser.push_back(vif.cb.wuser);
        int_wr_txn.wstrb.push_back(vif.cb.wstrb);

        if (vif.cb.wlast) begin
          int_wr_txn.wlast = 1;
          int_wr_q.push_back(int_wr_txn);
          int_wr_txn = TXN::type_id::create("int_wr_txn");
          set_txn_widths(int_wr_txn);
        end
      end

      while (int_wr_q.size() > 0 && int_aw_q.size() > 0) begin
        TXN int_aw_pop_txn = int_aw_q.pop_front();
        TXN int_wr_pop_txn = int_wr_q.pop_front();
        TXN int_wr_txn_con = TXN::type_id::create($sformatf("wr_txn_%0d", int_aw_pop_txn.awid));

        int_wr_txn_con.copy(int_aw_pop_txn);
        int_wr_txn_con.txn_type = TXN::AXI_WRITE;
        foreach (int_wr_pop_txn.wdata[i]) int_wr_txn_con.wdata.push_back(int_wr_pop_txn.wdata[i]);
        foreach (int_wr_pop_txn.wuser[i]) int_wr_txn_con.wuser.push_back(int_wr_pop_txn.wuser[i]);
        foreach (int_wr_pop_txn.wstrb[i]) int_wr_txn_con.wstrb.push_back(int_wr_pop_txn.wstrb[i]);
        int_wr_txn_con.wlast = int_wr_pop_txn.wlast;
        wr_txn[int_aw_pop_txn.awid].push_back(int_wr_txn_con);
      end

      if (vif.cb.bvalid && vif.cb.bready) begin
        TXN b_txn_granular = TXN::type_id::create("b_txn_granular");
        b_txn_granular.txn_type     = TXN::AXI_BRESP;
        set_txn_widths(b_txn_granular);
        b_txn_granular.bresp        = vif.cb.bresp;
        b_txn_granular.bid          = vif.cb.bid;
        granular_ap.write(b_txn_granular);

        if (wr_txn[vif.cb.bid].size() > 0) begin
          TXN int_wr_txn;
          int_wr_txn = wr_txn[vif.cb.bid].pop_front();
          
          int_wr_txn.bresp = vif.cb.bresp;
          int_wr_txn.bid   = vif.cb.bid;
          int_wr_txn.bvalid = 1;
          ap.write(int_wr_txn);
        end else begin
          TXN err_txn = TXN::type_id::create("err_txn");
          set_txn_widths(err_txn);
          err_txn.txn_type = TXN::AXI_BRESP;
          err_txn.bid = vif.cb.bid;
          err_txn.bresp = vif.cb.bresp;
          err_txn.err_type = TXN::AXI_ERR_BID_NO_AWID;
          ap.write(err_txn);
        end
      end
    end
  endtask

endclass
