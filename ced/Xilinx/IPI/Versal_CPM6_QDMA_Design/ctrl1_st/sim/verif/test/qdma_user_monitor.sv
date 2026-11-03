// qdma_user_monitor.sv — UVM monitor for H2C AXI4-Stream output.
//
// Observes H2C AXI4-Stream beats, drives h2c_tready=1 (always-accept),
// assembles per-packet qdma_user_transaction objects, and broadcasts them
// via analysis port to the scoreboard.
//
// Log rule: immediate $fdisplay+$fflush only.

class qdma_user_monitor extends uvm_monitor;
  `uvm_component_utils(qdma_user_monitor)

  virtual qdma_user_if vif;
  uvm_analysis_port#(qdma_user_transaction) ap;
  int log_fd;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual qdma_user_if)::get(this, "", "vif", vif))
      `uvm_fatal("qdma_user_monitor", "Failed to get virtual qdma_user_if from config_db")
    if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd))
      log_fd = 1;
  endfunction

  task run_phase(uvm_phase phase);
    // Drive h2c_tready = 1 at time 0 (before reset)
    vif.h2c_cb.h2c_tready <= 1'b1;

    forever begin
      // Wait for reset to deassert (aresetn is active-low)
      @(posedge vif.aresetn);

      $fdisplay(log_fd, "\n%s", {"=" * 70});
      $fdisplay(log_fd, "=== QDMA_USER_MONITOR  H2C AXI4-Stream ===");
      $fdisplay(log_fd, "%s", {"=" * 70});
      $fdisplay(log_fd, "# %0t ns  qdma_user_monitor (re)started (reset deasserted)",
                $realtime/1ns);
      $fflush(log_fd);

      fork
        begin : monitor_logic
          qdma_user_transaction txn;
          bit [511:0] pkt_data[$];
          bit [11:0]  pkt_qid;
          bit [2:0]   pkt_port_id;
          int         beat_cnt;
          int         byte_cnt;

          pkt_data.delete();
          beat_cnt = 0;
          byte_cnt = 0;

          forever begin
            @(vif.h2c_cb);

            // h2c_tready is driven 1 continuously — always accept
            vif.h2c_cb.h2c_tready <= 1'b1;

            if (vif.h2c_cb.h2c_tvalid) begin
              // First beat of a new packet: latch QID from tuser
              if (pkt_data.size() == 0) begin
                pkt_qid = vif.h2c_cb.h2c_tuser_qid;
                pkt_port_id = vif.h2c_cb.h2c_tuser_port_id;
              end

              // Check h2c_tuser_err on every valid beat
              if (|vif.h2c_cb.h2c_tuser_err) begin
                $fdisplay(log_fd,
                  "%0t ns  [qdma_user_monitor]  H2C_TUSER_ERR  qid=%0d  err=0x%01h  beat=%0d",
                  $realtime/1ns, vif.h2c_cb.h2c_tuser_qid,
                  vif.h2c_cb.h2c_tuser_err, beat_cnt);
                $fflush(log_fd);
                `uvm_error("qdma_user_monitor",
                  $sformatf("H2C tuser_err=0x%01h on qid=%0d at %0t ns",
                    vif.h2c_cb.h2c_tuser_err, vif.h2c_cb.h2c_tuser_qid,
                    $realtime/1ns))
              end

              pkt_data.push_back(vif.h2c_cb.h2c_tdata);
              beat_cnt++;
              if (vif.h2c_cb.h2c_tlast && vif.h2c_cb.h2c_tuser_mty > 0)
                byte_cnt += 64 - int'(vif.h2c_cb.h2c_tuser_mty);
              else
                byte_cnt += 64;

              if (vif.h2c_cb.h2c_tlast) begin
                // Packet complete — build and broadcast transaction
                txn = qdma_user_transaction::type_id::create("h2c_mon_txn");
                txn.qid       = pkt_qid;
                txn.port_id   = pkt_port_id;
                txn.is_h2c    = 1'b1;
                txn.num_beats = beat_cnt;
                txn.byte_count = byte_cnt;
                txn.mty       = vif.h2c_cb.h2c_tuser_mty;
                txn.data      = new[pkt_data.size()];
                foreach (pkt_data[i]) txn.data[i] = pkt_data[i];

                ap.write(txn);

                $fdisplay(log_fd,
                  "%0t ns  [qdma_user_monitor]  H2C_PKT  qid=%0d  port=%0d  beats=%0d  bytes=%0d  mty=%0d",
                  $realtime/1ns, pkt_qid, pkt_port_id, beat_cnt, byte_cnt,
                  vif.h2c_cb.h2c_tuser_mty);
                $fflush(log_fd);

                pkt_data.delete();
                beat_cnt = 0;
                byte_cnt = 0;
              end
            end
          end
        end : monitor_logic

        begin : reset_watch
          @(negedge vif.aresetn);
          $fdisplay(log_fd,
            "%0t ns  [qdma_user_monitor]  reset asserted  -  reinitializing",
            $realtime/1ns);
          $fflush(log_fd);
        end : reset_watch
      join_any
      disable fork;
    end
  endtask

endclass
