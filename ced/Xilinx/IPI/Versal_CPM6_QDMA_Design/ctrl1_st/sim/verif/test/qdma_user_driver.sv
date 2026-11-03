// qdma_user_driver.sv — UVM driver for C2H AXI4-Stream data.
//
// Active mode only (instantiated by qdma_user_agent when is_active=UVM_ACTIVE).
// Gets qdma_user_transaction objects from the sequencer and drives them on the
// C2H AXI4-Stream interface.

class qdma_user_driver extends uvm_driver#(qdma_user_transaction);
  `uvm_component_utils(qdma_user_driver)

  virtual qdma_user_if vif;
  int log_fd;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual qdma_user_if)::get(this, "", "vif", vif))
      `uvm_fatal("qdma_user_driver", "Failed to get virtual qdma_user_if from config_db")
    if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd))
      log_fd = 1;
  endfunction

  task run_phase(uvm_phase phase);
    qdma_user_transaction txn;

    // Initialize C2H interface to idle
    vif.c2h_cb.c2h_tvalid        <= 1'b0;
    vif.c2h_cb.c2h_tdata         <= '0;
    vif.c2h_cb.c2h_tkeep         <= '0;
    vif.c2h_cb.c2h_tlast         <= 1'b0;
    vif.c2h_cb.c2h_ctrl_qid      <= '0;
    vif.c2h_cb.c2h_mty           <= '0;
    vif.c2h_cb.c2h_ctrl_port_id  <= '0;
    vif.c2h_cb.c2h_ctrl_marker   <= 1'b0;
    vif.c2h_cb.c2h_ctrl_has_cmpt <= 1'b0;
    vif.c2h_cb.c2h_ctrl_len      <= '0;

    @(posedge vif.aresetn);

    forever begin
      seq_item_port.get_next_item(txn);
      drive_c2h_packet(txn);
      seq_item_port.item_done();
    end
  endtask

  // Drive a single C2H packet beat-by-beat.
  // Waits for c2h_tready each beat.
  task drive_c2h_packet(qdma_user_transaction txn);
    // ctrl_len is total bytes in the packet (16-bit field, first-beat sideband)
    automatic int unsigned pkt_bytes = txn.num_beats * 64;

    for (int b = 0; b < int'(txn.num_beats); b++) begin
      // Wait for c2h_tready
      @(vif.c2h_cb);
      while (!vif.c2h_cb.c2h_tready) @(vif.c2h_cb);

      vif.c2h_cb.c2h_tvalid        <= 1'b1;
      vif.c2h_cb.c2h_tdata         <= txn.data[b];
      vif.c2h_cb.c2h_tkeep         <= '1;   // all 64 bytes valid
      vif.c2h_cb.c2h_tlast         <= (b == int'(txn.num_beats) - 1);
      vif.c2h_cb.c2h_ctrl_qid      <= txn.qid;
      vif.c2h_cb.c2h_mty           <= '0;   // no invalid bytes
      vif.c2h_cb.c2h_ctrl_port_id  <= '0;
      vif.c2h_cb.c2h_ctrl_marker   <= 1'b0;
      vif.c2h_cb.c2h_ctrl_has_cmpt <= 1'b0;
      // ctrl_len is valid on the first beat only; zero on subsequent beats
      vif.c2h_cb.c2h_ctrl_len      <= (b == 0) ? 16'(pkt_bytes) : 16'h0;
    end

    // De-assert valid after last beat
    @(vif.c2h_cb);
    vif.c2h_cb.c2h_tvalid <= 1'b0;
    vif.c2h_cb.c2h_tlast  <= 1'b0;

    $fdisplay(log_fd,
      "%0t ns  [qdma_user_driver]  C2H_PKT  qid=%0d  beats=%0d  bytes=%0d",
      $realtime/1ns, txn.qid, txn.num_beats, pkt_bytes);
    $fflush(log_fd);
  endtask

endclass
