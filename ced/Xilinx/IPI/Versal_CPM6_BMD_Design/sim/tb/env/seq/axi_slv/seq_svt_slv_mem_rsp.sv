class seq_svt_slv_mem_rsp extends svt_axi_slave_base_sequence;

  `uvm_object_utils(seq_svt_slv_mem_rsp)

  function new(string name = "seq_svt_slv_mem_rsp");
    super.new(name);
  endfunction

  virtual task body();
    svt_axi_slave_transaction rsp;
    svt_configuration gotten_cfg;
    p_sequencer.get_cfg(gotten_cfg);
    if (!$cast(cfg, gotten_cfg))
      `uvm_fatal(get_type_name, "Couldn't cast to the cfg object")
    forever begin
      // Get the response request
      p_sequencer.response_request_port.peek(rsp);
      // Set the response approval
      rsp.bresp = svt_axi_slave_transaction::OKAY;
      foreach (rsp.rresp[ii]) rsp.rresp[ii] = svt_axi_slave_transaction::OKAY;
      // write
      if (rsp.xact_type==svt_axi_slave_transaction::WRITE) begin
        rsp.random_interleave_array = new[1];
        rsp.random_interleave_array[0] = 1;
        put_write_transaction_data_to_mem(rsp);
        `uvm_send(rsp)
      end
      // read
      else begin
        get_read_data_from_mem_to_transaction(rsp);
        rsp.rvalid_delay            = new[1];
        rsp.wready_delay            = new[1];
        rsp.random_interleave_array = new[1];
        rsp.rvalid_delay[0]            = $urandom_range(4,8);
        rsp.wready_delay[0]            = $urandom_range(4,8);
        rsp.random_interleave_array[0] = 1;
        `uvm_send(rsp)
      end
    end
  endtask

endclass
