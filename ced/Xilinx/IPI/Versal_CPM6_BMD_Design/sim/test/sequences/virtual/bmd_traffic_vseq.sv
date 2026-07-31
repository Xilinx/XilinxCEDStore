//==============================================================================
// bmd_traffic_vseq.sv - BMD Traffic Monitoring Virtual Sequence
//==============================================================================
// Waits for BMD traffic generation to complete with timeout handling
//==============================================================================

class bmd_traffic_vseq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_traffic_vseq_c)

    //--------------------------------------------------------------------------
    // Configuration
    //--------------------------------------------------------------------------
    int timeout_ns = 50_000_000;  // 50ms default timeout

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_traffic_vseq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        bit write_done, read_done;
        int wait_time;

        `uvm_info(get_name(), "Waiting for traffic completion", UVM_MEDIUM)

        // Wait for traffic to complete or timeout
        fork
            begin
                // Wait for write completion if write traffic enabled
                if (csr_cfg.wr_start) begin
                    wait(wr_csr_vif.monitor_cb.write_done);
                    write_done = 1'b1;
                    `uvm_info(get_name(), "Write traffic completed", UVM_MEDIUM)
                end else begin
                    write_done = 1'b1;
                end

                // Wait for read completion if read traffic enabled
                if (csr_cfg.rd_start) begin
                    wait(rd_csr_vif.monitor_cb.read_done);
                    read_done = 1'b1;
                    `uvm_info(get_name(), "Read traffic completed", UVM_MEDIUM)
                end else begin
                    read_done = 1'b1;
                end

                // Wait for both to complete
                wait(write_done && read_done);
                `uvm_info(get_name(), "All traffic completed successfully", UVM_LOW)
            end

            begin
                // Timeout watchdog
                #(timeout_ns * 1ns);
                if (!(write_done && read_done)) begin
                    `uvm_error(get_name(), $sformatf("Traffic timeout after %0d ns", timeout_ns))
                end
            end
        join_any
        disable fork;

        // Additional settling time
        #5us;

        `uvm_info(get_name(), "Traffic monitoring complete", UVM_MEDIUM)

    endtask

endclass
