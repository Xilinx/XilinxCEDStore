// qdma_user_scoreboard.sv — Receives H2C packets from qdma_user_monitor.
//
// Logs each received H2C packet (qid, beats, first beat data word) to
// cpm6_qdma_dbg.log; no byte-level comparison against host_mem[].
//
// Log rule: immediate $fdisplay+$fflush — no buffering.

class qdma_user_scoreboard extends uvm_component;
  `uvm_component_utils(qdma_user_scoreboard)

  localparam int NUM_ST_PORTS = 8;

  uvm_analysis_imp#(qdma_user_transaction, qdma_user_scoreboard) analysis_export;
  int log_fd;
  int pkts_received;
  longint unsigned bytes_received;
  int pkts_per_port[NUM_ST_PORTS];
  longint unsigned bytes_per_port[NUM_ST_PORTS];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    pkts_received = 0;
    bytes_received = 0;
    foreach (pkts_per_port[i]) pkts_per_port[i] = 0;
    foreach (bytes_per_port[i]) bytes_per_port[i] = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export = new("analysis_export", this);
    if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd))
      log_fd = 1;
  endfunction

  // Called by qdma_user_monitor for every completed H2C packet.
  function void write(qdma_user_transaction txn);
    pkts_received++;
    bytes_received += txn.byte_count;
    if (txn.port_id < NUM_ST_PORTS) begin
      pkts_per_port[txn.port_id]++;
      bytes_per_port[txn.port_id] += txn.byte_count;
    end
    $fdisplay(log_fd,
      "%0t ns  [qdma_user_scoreboard]  H2C_PKT#%0d  source=AXI4-Stream_user_monitor  qid=%0d  port=%0d  beats=%0d  bytes=%0d  data[0]=0x%0x",
      $realtime/1ns, pkts_received, txn.qid, txn.port_id, txn.num_beats, txn.byte_count,
      (txn.data.size() > 0) ? txn.data[0][63:0] : 64'h0);
    $fflush(log_fd);
  endfunction

  function void report_phase(uvm_phase phase);
    $fdisplay(log_fd,
      "# [qdma_user_scoreboard]  SUMMARY  source=AXI4-Stream_user_monitor  H2C pkts=%0d  bytes=%0d",
      pkts_received, bytes_received);
    for (int port = 0; port < NUM_ST_PORTS; port++) begin
      if (pkts_per_port[port] > 0)
        $fdisplay(log_fd,
          "# [qdma_user_scoreboard]  SUMMARY  port=%0d  pkts=%0d  bytes=%0d",
          port, pkts_per_port[port], bytes_per_port[port]);
    end
    $fflush(log_fd);
    `uvm_info("qdma_user_scoreboard",
      $sformatf("SUMMARY: source=AXI4-Stream user monitor, H2C packets=%0d bytes=%0d",
                pkts_received, bytes_received),
      UVM_MEDIUM)
  endfunction

endclass
