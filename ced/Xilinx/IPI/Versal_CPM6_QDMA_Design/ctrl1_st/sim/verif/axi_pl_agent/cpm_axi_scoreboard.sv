// ==============================================================================
// CPM AXI Scoreboard
// ==============================================================================
// This UVM scoreboard collects performance metrics from all 4 AXI port monitors
// and generates comprehensive reports including:
//   - Aggregate bandwidth across all ports
//   - Per-port performance summaries
//   - CSV export for data analysis
//   - JSON export for plotting tools
// ==============================================================================

`ifndef CPM_AXI_SCOREBOARD_SV
`define CPM_AXI_SCOREBOARD_SV

// Declare specialized analysis imp port types — one per monitored AXI port.
// `uvm_analysis_imp_decl(_suffix) generates:
//   class uvm_analysis_imp_suffix #(T, IMP) and routes write() to write_suffix()
`uvm_analysis_imp_decl(_port0)
`uvm_analysis_imp_decl(_port1)
`uvm_analysis_imp_decl(_port2)
`uvm_analysis_imp_decl(_port3)

class cpm_axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(cpm_axi_scoreboard)

    // Analysis imports - one for each AXI port
    uvm_analysis_imp_port0 #(cpm_axi_perf_monitor::perf_metrics_t, cpm_axi_scoreboard) port0_imp;
    uvm_analysis_imp_port1 #(cpm_axi_perf_monitor::perf_metrics_t, cpm_axi_scoreboard) port1_imp;
    uvm_analysis_imp_port2 #(cpm_axi_perf_monitor::perf_metrics_t, cpm_axi_scoreboard) port2_imp;
    uvm_analysis_imp_port3 #(cpm_axi_perf_monitor::perf_metrics_t, cpm_axi_scoreboard) port3_imp;

    // Metrics storage for each port
    cpm_axi_perf_monitor::perf_metrics_t port_metrics[4];

    // File handles for reports
    int csv_fh;
    int json_fh;

    string report_dir = "./reports";

    // ========================================================================
    // Constructor
    // ========================================================================
    function new(string name = "cpm_axi_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ========================================================================
    // Build Phase
    // ========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        port0_imp = new("port0_imp", this);
        port1_imp = new("port1_imp", this);
        port2_imp = new("port2_imp", this);
        port3_imp = new("port3_imp", this);

        // Create reports directory
        void'($system($sformatf("mkdir -p %s", report_dir)));
    endfunction

    // ========================================================================
    // Analysis Import Write Functions (one for each port)
    // ========================================================================
    function void write_port0(cpm_axi_perf_monitor::perf_metrics_t metrics);
        port_metrics[0] = metrics;
        `uvm_info(get_type_name(),
            $sformatf("AXI-PL metrics update: source=cpm_axi_pl0_monitor write_bytes=%0d read_bytes=%0d write_txns=%0d read_txns=%0d",
                      metrics.write_bytes, metrics.read_bytes,
                      metrics.write_transactions, metrics.read_transactions),
            UVM_DEBUG)
    endfunction

    function void write_port1(cpm_axi_perf_monitor::perf_metrics_t metrics);
        port_metrics[1] = metrics;
        `uvm_info(get_type_name(),
            $sformatf("AXI-PL metrics update: source=cpm_axi_pl1_monitor write_bytes=%0d read_bytes=%0d write_txns=%0d read_txns=%0d",
                      metrics.write_bytes, metrics.read_bytes,
                      metrics.write_transactions, metrics.read_transactions),
            UVM_DEBUG)
    endfunction

    function void write_port2(cpm_axi_perf_monitor::perf_metrics_t metrics);
        port_metrics[2] = metrics;
        `uvm_info(get_type_name(),
            $sformatf("AXI-PL metrics update: source=cpm_axi_pl2_monitor write_bytes=%0d read_bytes=%0d write_txns=%0d read_txns=%0d",
                      metrics.write_bytes, metrics.read_bytes,
                      metrics.write_transactions, metrics.read_transactions),
            UVM_DEBUG)
    endfunction

    function void write_port3(cpm_axi_perf_monitor::perf_metrics_t metrics);
        port_metrics[3] = metrics;
        `uvm_info(get_type_name(),
            $sformatf("AXI-PL metrics update: source=cpm_axi_pl3_monitor write_bytes=%0d read_bytes=%0d write_txns=%0d read_txns=%0d",
                      metrics.write_bytes, metrics.read_bytes,
                      metrics.write_transactions, metrics.read_transactions),
            UVM_DEBUG)
    endfunction

    // ========================================================================
    // Report Phase - Generate comprehensive reports
    // ========================================================================
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        print_summary_report();
        generate_csv_report();
        generate_json_report();
    endfunction

    // ========================================================================
    // Print Summary Report
    // ========================================================================
    function void print_summary_report();
        string report;
        real total_write_bw;
        real total_read_bw;
        longint total_write_bytes;
        longint total_read_bytes;
        int total_write_txns;
        int total_read_txns;
        int total_violations;
        int summary_fh;
        total_write_bw    = 0.0;
        total_read_bw     = 0.0;
        total_write_bytes = 0;
        total_read_bytes  = 0;
        total_write_txns  = 0;
        total_read_txns   = 0;
        total_violations  = 0;

        report = "\n\n";
        report = {report, "================================================================================\n"};
        report = {report, "                     CPM AXI PERFORMANCE SUMMARY REPORT\n"};
        report = {report, "================================================================================\n\n"};
        report = {report, "Source note: this scoreboard is based on AXI-PL interface monitor observations.\n"};
        report = {report, "It is independent of DMA_SCOREBOARD host-side PCIe MRD/MWR byte-count checks.\n\n"};

        // Per-port summary
        for (int i = 0; i < 4; i++) begin
            report = {report, $sformatf("Port cpm_axi_pl%0d:\n", i)};
            report = {report, $sformatf("  Write: %6.2f GB/s | %8d txns | %12d bytes | %10d MB\n",
                port_metrics[i].write_bandwidth_gbps,
                port_metrics[i].write_transactions,
                port_metrics[i].write_bytes,
                port_metrics[i].write_bytes / 1048576)};
            report = {report, $sformatf("  Read:  %6.2f GB/s | %8d txns | %12d bytes | %10d MB\n",
                port_metrics[i].read_bandwidth_gbps,
                port_metrics[i].read_transactions,
                port_metrics[i].read_bytes,
                port_metrics[i].read_bytes / 1048576)};
            report = {report, $sformatf("  Write Latency: Min=%.1f ns, Avg=%.1f ns, Max=%.1f ns\n",
                port_metrics[i].write_latency_min_ns,
                port_metrics[i].write_latency_avg_ns,
                port_metrics[i].write_latency_max_ns)};
            report = {report, $sformatf("  Read Latency:  Min=%.1f ns, Avg=%.1f ns, Max=%.1f ns\n",
                port_metrics[i].read_latency_min_ns,
                port_metrics[i].read_latency_avg_ns,
                port_metrics[i].read_latency_max_ns)};
            report = {report, $sformatf("  Peak Outstanding: WR=%0d, RD=%0d\n",
                port_metrics[i].peak_outstanding_wr,
                port_metrics[i].peak_outstanding_rd)};
            report = {report, $sformatf("  Protocol Violations: %0d\n\n",
                port_metrics[i].protocol_violations)};

            // Accumulate totals
            total_write_bw += port_metrics[i].write_bandwidth_gbps;
            total_read_bw += port_metrics[i].read_bandwidth_gbps;
            total_write_bytes += port_metrics[i].write_bytes;
            total_read_bytes += port_metrics[i].read_bytes;
            total_write_txns += port_metrics[i].write_transactions;
            total_read_txns += port_metrics[i].read_transactions;
            total_violations += port_metrics[i].protocol_violations;
        end

        report = {report, "--------------------------------------------------------------------------------\n"};
        report = {report, "AGGREGATE PERFORMANCE:\n"};
        report = {report, $sformatf("  Total Write Bandwidth:    %.2f GB/s\n", total_write_bw)};
        report = {report, $sformatf("  Total Read Bandwidth:     %.2f GB/s\n", total_read_bw)};
        report = {report, $sformatf("  Total Bandwidth:          %.2f GB/s\n",
            total_write_bw + total_read_bw)};
        report = {report, $sformatf("  Total Write Transactions: %0d\n", total_write_txns)};
        report = {report, $sformatf("  Total Read Transactions:  %0d\n", total_read_txns)};
        report = {report, $sformatf("  Total Data Written:       %0d MB\n",
            total_write_bytes / 1048576)};
        report = {report, $sformatf("  Total Data Read:          %0d MB\n",
            total_read_bytes / 1048576)};
        report = {report, $sformatf("  Total Protocol Violations: %0d\n", total_violations)};

        if (total_violations == 0)
            report = {report, "\n  ✓ ALL PROTOCOL CHECKS PASSED\n"};
        else
            report = {report, "\n  ✗ PROTOCOL VIOLATIONS DETECTED\n"};

        report = {report, "================================================================================\n\n"};

        `uvm_info(get_type_name(), report, UVM_LOW)

        // Also log to file
        summary_fh = $fopen({report_dir, "/summary.txt"}, "w");
        if (summary_fh) begin
            $fwrite(summary_fh, "%s", report);
            $fclose(summary_fh);
            `uvm_info(get_type_name(), $sformatf("Summary report written to %s/summary.txt",
                report_dir), UVM_LOW)
        end
    endfunction

    // ========================================================================
    // Generate CSV Report
    // ========================================================================
    function void generate_csv_report();
        csv_fh = $fopen({report_dir, "/performance_metrics.csv"}, "w");

        if (!csv_fh) begin
            `uvm_error(get_type_name(), "Failed to open CSV file")
            return;
        end

        // CSV Header
        $fwrite(csv_fh, "Port,Direction,Bandwidth_GBps,Transactions,Bytes,");
        $fwrite(csv_fh, "Latency_Min_ns,Latency_Avg_ns,Latency_Max_ns,");
        $fwrite(csv_fh, "Peak_Outstanding,Protocol_Violations\n");

        // Write data for each port
        for (int i = 0; i < 4; i++) begin
            // Write transactions
            $fwrite(csv_fh, "cpm_axi_pl%0d,Write,%.3f,%0d,%0d,%.2f,%.2f,%.2f,%0d,%0d\n",
                i,
                port_metrics[i].write_bandwidth_gbps,
                port_metrics[i].write_transactions,
                port_metrics[i].write_bytes,
                port_metrics[i].write_latency_min_ns,
                port_metrics[i].write_latency_avg_ns,
                port_metrics[i].write_latency_max_ns,
                port_metrics[i].peak_outstanding_wr,
                port_metrics[i].protocol_violations);

            // Read transactions
            $fwrite(csv_fh, "cpm_axi_pl%0d,Read,%.3f,%0d,%0d,%.2f,%.2f,%.2f,%0d,%0d\n",
                i,
                port_metrics[i].read_bandwidth_gbps,
                port_metrics[i].read_transactions,
                port_metrics[i].read_bytes,
                port_metrics[i].read_latency_min_ns,
                port_metrics[i].read_latency_avg_ns,
                port_metrics[i].read_latency_max_ns,
                port_metrics[i].peak_outstanding_rd,
                port_metrics[i].protocol_violations);
        end

        $fclose(csv_fh);
        `uvm_info(get_type_name(), $sformatf("CSV report written to %s/performance_metrics.csv",
            report_dir), UVM_LOW)
    endfunction

    // ========================================================================
    // Generate JSON Report
    // ========================================================================
    function void generate_json_report();
        json_fh = $fopen({report_dir, "/performance_metrics.json"}, "w");

        if (!json_fh) begin
            `uvm_error(get_type_name(), "Failed to open JSON file")
            return;
        end

        $fwrite(json_fh, "{\n");
        $fwrite(json_fh, "  \"test_name\": \"cpm_axi_performance\",\n");
        $fwrite(json_fh, "  \"timestamp\": \"%0t\",\n", $time);
        $fwrite(json_fh, "  \"ports\": [\n");

        for (int i = 0; i < 4; i++) begin
            $fwrite(json_fh, "    {\n");
            $fwrite(json_fh, "      \"port_name\": \"cpm_axi_pl%0d\",\n", i);
            $fwrite(json_fh, "      \"write\": {\n");
            $fwrite(json_fh, "        \"bandwidth_gbps\": %.3f,\n",
                port_metrics[i].write_bandwidth_gbps);
            $fwrite(json_fh, "        \"transactions\": %0d,\n",
                port_metrics[i].write_transactions);
            $fwrite(json_fh, "        \"bytes\": %0d,\n",
                port_metrics[i].write_bytes);
            $fwrite(json_fh, "        \"latency_ns\": {\n");
            $fwrite(json_fh, "          \"min\": %.2f,\n",
                port_metrics[i].write_latency_min_ns);
            $fwrite(json_fh, "          \"avg\": %.2f,\n",
                port_metrics[i].write_latency_avg_ns);
            $fwrite(json_fh, "          \"max\": %.2f\n",
                port_metrics[i].write_latency_max_ns);
            $fwrite(json_fh, "        },\n");
            $fwrite(json_fh, "        \"peak_outstanding\": %0d\n",
                port_metrics[i].peak_outstanding_wr);
            $fwrite(json_fh, "      },\n");
            $fwrite(json_fh, "      \"read\": {\n");
            $fwrite(json_fh, "        \"bandwidth_gbps\": %.3f,\n",
                port_metrics[i].read_bandwidth_gbps);
            $fwrite(json_fh, "        \"transactions\": %0d,\n",
                port_metrics[i].read_transactions);
            $fwrite(json_fh, "        \"bytes\": %0d,\n",
                port_metrics[i].read_bytes);
            $fwrite(json_fh, "        \"latency_ns\": {\n");
            $fwrite(json_fh, "          \"min\": %.2f,\n",
                port_metrics[i].read_latency_min_ns);
            $fwrite(json_fh, "          \"avg\": %.2f,\n",
                port_metrics[i].read_latency_avg_ns);
            $fwrite(json_fh, "          \"max\": %.2f\n",
                port_metrics[i].read_latency_max_ns);
            $fwrite(json_fh, "        },\n");
            $fwrite(json_fh, "        \"peak_outstanding\": %0d\n",
                port_metrics[i].peak_outstanding_rd);
            $fwrite(json_fh, "      },\n");
            $fwrite(json_fh, "      \"protocol_violations\": %0d,\n",
                port_metrics[i].protocol_violations);
            $fwrite(json_fh, "      \"simulation_time_ns\": %.2f\n",
                port_metrics[i].simulation_time_ns);

            if (i < 3)
                $fwrite(json_fh, "    },\n");
            else
                $fwrite(json_fh, "    }\n");
        end

        $fwrite(json_fh, "  ]\n");
        $fwrite(json_fh, "}\n");

        $fclose(json_fh);
        `uvm_info(get_type_name(), $sformatf("JSON report written to %s/performance_metrics.json",
            report_dir), UVM_LOW)
    endfunction

endclass : cpm_axi_scoreboard

`endif // CPM_AXI_SCOREBOARD_SV
