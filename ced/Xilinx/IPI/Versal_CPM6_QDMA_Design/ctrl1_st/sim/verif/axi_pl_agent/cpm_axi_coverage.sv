// ==============================================================================
// CPM AXI Coverage Collector
// ==============================================================================
// Functional coverage for AXI transactions including burst types, sizes,
// outstanding transactions, and protocol scenarios
// ==============================================================================

`ifndef CPM_AXI_COVERAGE_SV
`define CPM_AXI_COVERAGE_SV

class cpm_axi_coverage extends uvm_subscriber #(cpm_axi_perf_monitor::perf_metrics_t);
    `uvm_component_utils(cpm_axi_coverage)

    // Virtual interface for sampling
    virtual axi_if vif;

    int port_id;

    // Coverage sampled values
    bit [7:0]  sample_awlen, sample_arlen;
    bit [2:0]  sample_awsize, sample_arsize;
    bit [1:0]  sample_awburst, sample_arburst;
    bit [3:0]  sample_awqos, sample_arqos;
    bit [50:0] sample_awaddr, sample_araddr;
    int        sample_outstanding_wr, sample_outstanding_rd;

    // ========================================================================
    // Coverage Groups
    // ========================================================================

    covergroup cg_write_address;  // sampled explicitly in sample_write_coverage()
        option.per_instance = 1;
        option.name = "cg_write_address";

        cp_burst_len: coverpoint sample_awlen {
            bins single = {0};
            bins short_burst[] = {[1:7]};
            bins medium_burst[] = {[8:15]};
            bins long_burst[] = {[16:63]};
            bins max_burst[] = {[64:255]};
        }

        cp_burst_type: coverpoint sample_awburst {
            bins fixed = {2'b00};
            bins incr  = {2'b01};
            bins wrap  = {2'b10};
            illegal_bins reserved = {2'b11};
        }

        cp_burst_size: coverpoint sample_awsize {
            bins byte_1   = {3'd0};
            bins byte_2   = {3'd1};
            bins byte_4   = {3'd2};
            bins byte_8   = {3'd3};
            bins byte_16  = {3'd4};
            bins byte_32  = {3'd5};
            bins byte_64  = {3'd6};  // Max for 512-bit data
        }

        cp_qos: coverpoint sample_awqos {
            bins low_priority  = {[0:3]};
            bins med_priority  = {[4:11]};
            bins high_priority = {[12:15]};
        }

        cp_addr_align: coverpoint (sample_awaddr & 3'h7) {
            bins aligned_64  = {0};
            bins aligned_32  = {4};
            bins unaligned[] = {[1:7]};
        }

        // Cross coverage
        cross cp_burst_len, cp_burst_type;
        cross cp_burst_len, cp_burst_size;
    endgroup

    covergroup cg_read_address;   // sampled explicitly in sample_read_coverage()
        option.per_instance = 1;
        option.name = "cg_read_address";

        cp_burst_len: coverpoint sample_arlen {
            bins single = {0};
            bins short_burst[] = {[1:7]};
            bins medium_burst[] = {[8:15]};
            bins long_burst[] = {[16:63]};
            bins max_burst[] = {[64:255]};
        }

        cp_burst_type: coverpoint sample_arburst {
            bins fixed = {2'b00};
            bins incr  = {2'b01};
            bins wrap  = {2'b10};
            illegal_bins reserved = {2'b11};
        }

        cp_burst_size: coverpoint sample_arsize {
            bins byte_1   = {3'd0};
            bins byte_2   = {3'd1};
            bins byte_4   = {3'd2};
            bins byte_8   = {3'd3};
            bins byte_16  = {3'd4};
            bins byte_32  = {3'd5};
            bins byte_64  = {3'd6};
        }

        cp_qos: coverpoint sample_arqos {
            bins low_priority  = {[0:3]};
            bins med_priority  = {[4:11]};
            bins high_priority = {[12:15]};
        }

        cp_addr_align: coverpoint (sample_araddr & 3'h7) {
            bins aligned_64  = {0};
            bins aligned_32  = {4};
            bins unaligned[] = {[1:7]};
        }

        cross cp_burst_len, cp_burst_type;
        cross cp_burst_len, cp_burst_size;
    endgroup

    covergroup cg_outstanding_transactions;
        option.per_instance = 1;
        option.name = "cg_outstanding";

        cp_outstanding_wr: coverpoint sample_outstanding_wr {
            bins none = {0};
            bins low[] = {[1:4]};
            bins med[] = {[5:16]};
            bins high[] = {[17:32]};
        }

        cp_outstanding_rd: coverpoint sample_outstanding_rd {
            bins none = {0};
            bins low[] = {[1:4]};
            bins med[] = {[5:16]};
            bins high[] = {[17:32]};
        }

        cross cp_outstanding_wr, cp_outstanding_rd;
    endgroup

    // ========================================================================
    // Constructor
    // ========================================================================
    function new(string name = "cpm_axi_coverage", uvm_component parent = null);
        super.new(name, parent);
        // Embedded covergroups must be constructed in new() per LRM.
        // They use explicit .sample() calls (no clocking event) so vif
        // is not needed at construction time.
        cg_write_address          = new();
        cg_read_address           = new();
        cg_outstanding_transactions = new();
    endfunction

    // ========================================================================
    // Build Phase
    // ========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not set")

        if (!uvm_config_db#(int)::get(this, "", "port_id", port_id))
            port_id = 0;
    endfunction

    // ========================================================================
    // Run Phase - Sample coverage
    // ========================================================================
    task run_phase(uvm_phase phase);
        fork
            sample_write_coverage();
            sample_read_coverage();
            sample_outstanding();
        join_none
    endtask

    task sample_write_coverage();
        forever begin
            @(vif.monitor_cb);
            if (vif.aresetn && vif.monitor_cb.awvalid && vif.monitor_cb.awready) begin
                sample_awlen   = vif.monitor_cb.awlen;
                sample_awsize  = vif.monitor_cb.awsize;
                sample_awburst = vif.monitor_cb.awburst;
                sample_awqos   = vif.monitor_cb.awqos;
                sample_awaddr  = vif.monitor_cb.awaddr;
                cg_write_address.sample();
            end
        end
    endtask

    task sample_read_coverage();
        forever begin
            @(vif.monitor_cb);
            if (vif.aresetn && vif.monitor_cb.arvalid && vif.monitor_cb.arready) begin
                sample_arlen   = vif.monitor_cb.arlen;
                sample_arsize  = vif.monitor_cb.arsize;
                sample_arburst = vif.monitor_cb.arburst;
                sample_arqos   = vif.monitor_cb.arqos;
                sample_araddr  = vif.monitor_cb.araddr;
                cg_read_address.sample();
            end
        end
    endtask

    task sample_outstanding();
        forever begin
            @(vif.monitor_cb);
            // Outstanding counts are not tracked per cycle; 0 is sampled here.
            sample_outstanding_wr = 0;
            sample_outstanding_rd = 0;
            cg_outstanding_transactions.sample();
        end
    endtask

    // ========================================================================
    // Write function - called when metrics are received
    // ========================================================================
    function void write(cpm_axi_perf_monitor::perf_metrics_t t);
        // Sample final outstanding transaction metrics
        sample_outstanding_wr = t.peak_outstanding_wr;
        sample_outstanding_rd = t.peak_outstanding_rd;
        cg_outstanding_transactions.sample();
    endfunction

    // ========================================================================
    // Report Phase
    // ========================================================================
    function void report_phase(uvm_phase phase);
        real wr_addr_cov, rd_addr_cov, outstanding_cov;

        wr_addr_cov = cg_write_address.get_coverage();
        rd_addr_cov = cg_read_address.get_coverage();
        outstanding_cov = cg_outstanding_transactions.get_coverage();

        `uvm_info(get_type_name(),
            $sformatf("\n[Port %0d] Coverage Report:\n  Write Address: %.2f%%\n  Read Address: %.2f%%\n  Outstanding Txns: %.2f%%",
                port_id, wr_addr_cov, rd_addr_cov, outstanding_cov),
            UVM_LOW)
    endfunction

endclass : cpm_axi_coverage

`endif // CPM_AXI_COVERAGE_SV
