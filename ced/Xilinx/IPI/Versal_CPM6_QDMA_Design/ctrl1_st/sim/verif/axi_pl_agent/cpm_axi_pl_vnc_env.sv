// cpm_axi_pl_vnc_env.sv — 3-port AXI-PL UVM environment
//
// CPM6 exposes three cpm_axi_pl ports:  PL0, PL1, PL3  (PL2 is absent).
// This env manages exactly the three ports present in the design:
//
//   perf_mon[0]  →  cpm_axi_pl0   config_db key "vif_axi_pl0"  PORT_ID=0
//   perf_mon[1]  →  cpm_axi_pl1   config_db key "vif_axi_pl1"  PORT_ID=1
//   perf_mon[2]  →  cpm_axi_pl3   config_db key "vif_axi_pl3"  PORT_ID=3
//
// The cpm_axi_scoreboard has analysis imports port0_imp..port3_imp; we connect
// perf_mon[0]→port0_imp, perf_mon[1]→port1_imp, perf_mon[2]→port3_imp.
// port2_imp receives no transactions (PL2 does not exist) — the scoreboard
// will report 0 bandwidth for port 2, which is accurate.
//
// Report artifacts written by cpm_axi_scoreboard at report_phase:
//   reports/summary.txt
//   reports/performance_metrics.csv
//   reports/performance_metrics.json
// These land in the VCS simulation output directory.

`ifndef CPM_AXI_PL_VNC_ENV_SV
`define CPM_AXI_PL_VNC_ENV_SV

class cpm_axi_pl_vnc_env extends uvm_env;
  `uvm_component_utils(cpm_axi_pl_vnc_env)

  // Performance monitors: [0]=PL0, [1]=PL1, [2]=PL3
  cpm_axi_perf_monitor perf_mon[3];

  // Coverage collectors
  cpm_axi_coverage cov[3];

  // Protocol/error checkers — see axi_pl_protocol_monitor.sv
  axi_pl_protocol_monitor proto_mon[3];
  int shared_log_fd;

  // Aggregating scoreboard (4-port; port2 receives no transactions)
  cpm_axi_scoreboard scb;

  // Virtual interfaces retrieved from config_db
  virtual axi_if vif[3];

  // Mapping: logical index → AXI-PL port number (used for PORT_ID and
  // scoreboard connection)
  localparam int PORT_IDS[3] = '{0, 1, 3};

  // config_db keys registered by bind_axi_pl
  localparam string VIF_KEYS[3] = '{"vif_axi_pl0", "vif_axi_pl1", "vif_axi_pl3"};

  function new(string name = "cpm_axi_pl_vnc_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(int)::get(this, "", "log_fd", shared_log_fd))
      shared_log_fd = 1;

    // Retrieve virtual interfaces
    for (int i = 0; i < 3; i++) begin
      if (!uvm_config_db#(virtual axi_if)::get(this, "", VIF_KEYS[i], vif[i]))
        `uvm_warning(get_type_name(),
          $sformatf("Virtual interface %s not set  -  bind.axi_pl.sv may not have run", VIF_KEYS[i]))
    end

    // Scoreboard
    scb = cpm_axi_scoreboard::type_id::create("scb", this);

    // Monitors and coverage collectors — created only when their vif is bound.
    // cpm_axi_coverage and cpm_axi_perf_monitor uvm_fatal in build_phase if
    // vif is null, so we skip creation when the underlying bind is gated off
    // (e.g. PL3 when ENABLE_PL3_BIND is undefined).
    for (int i = 0; i < 3; i++) begin
      string mon_name = $sformatf("perf_mon%0d", PORT_IDS[i]);
      string cov_name = $sformatf("cov%0d",      PORT_IDS[i]);

      if (vif[i] == null) begin
        `uvm_info(get_type_name(),
          $sformatf("Skipping %s/%s creation  -  %s not bound",
                    mon_name, cov_name, VIF_KEYS[i]), UVM_LOW)
        continue;
      end

      perf_mon[i] = cpm_axi_perf_monitor::type_id::create(mon_name, this);
      uvm_config_db#(virtual axi_if)::set(this, mon_name, "vif", vif[i]);
      uvm_config_db#(int)::set(this, mon_name, "port_id", PORT_IDS[i]);

      cov[i] = cpm_axi_coverage::type_id::create(cov_name, this);
      uvm_config_db#(virtual axi_if)::set(this, cov_name, "vif", vif[i]);
      uvm_config_db#(int)::set(this, cov_name, "port_id", PORT_IDS[i]);

      begin
        string proto_name = $sformatf("proto_mon%0d", PORT_IDS[i]);
        proto_mon[i] = axi_pl_protocol_monitor::type_id::create(proto_name, this);
        uvm_config_db#(virtual axi_if)::set(this, proto_name, "vif", vif[i]);
        uvm_config_db#(int)::set(this, proto_name, "port_id", PORT_IDS[i]);
        uvm_config_db#(int)::set(this, proto_name, "log_fd", shared_log_fd);
      end
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect to the matching imp port on the 4-port scoreboard.
    // Each connect is guarded — perf_mon[i] is null when its vif wasn't bound
    // (see build_phase). port2_imp is intentionally always unconnected
    // (PL2 doesn't exist in CPM6).
    if (perf_mon[0] != null) perf_mon[0].metrics_ap.connect(scb.port0_imp);  // PL0
    if (perf_mon[1] != null) perf_mon[1].metrics_ap.connect(scb.port1_imp);  // PL1
    if (perf_mon[2] != null) perf_mon[2].metrics_ap.connect(scb.port3_imp);  // PL3 → port3_imp
    for (int i = 0; i < 3; i++)
      if (perf_mon[i] != null && cov[i] != null)
        perf_mon[i].metrics_ap.connect(cov[i].analysis_export);
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),
      "CPM6 AXI-PL performance monitoring complete (PL0, PL1, PL3)", UVM_LOW)
  endfunction

endclass : cpm_axi_pl_vnc_env

`endif // CPM_AXI_PL_VNC_ENV_SV
