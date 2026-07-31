`uvm_analysis_imp_decl(_perf_tx)
`uvm_analysis_imp_decl(_perf_rx)
class bmd_performance_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_performance_scoreboard_c)

    int main_phase_started;

    apci_tlp    rx_packets[$];
    real        rx_timestamps[$];

    apci_tlp    tx_packets[$];
    real        tx_timestamps[$];

    real        latency[$];
    real        average_latency;

    virtual bmd_read_csr_if  rd_csr_vif;
    virtual bmd_write_csr_if wr_csr_vif;

    uvm_analysis_imp_perf_tx #(apci_packet, bmd_performance_scoreboard_c) txp;
    uvm_analysis_imp_perf_rx #(apci_packet, bmd_performance_scoreboard_c) rxp;

    // Constructor
    function new(string name = "bmd_performance_scoreboard", uvm_component parent = null);
        super.new(name, parent);

        txp = new("txp", this);
        rxp = new("rxp", this);
    endfunction

    function void clear();
        rx_packets.delete();
        rx_timestamps.delete();

        tx_packets.delete();
        tx_timestamps.delete();

        latency.delete();
        average_latency = '0;
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual bmd_write_csr_if)::get(this, "", "wr_csr_vif", wr_csr_vif))
            `uvm_fatal(get_type_name(), "Virtual interface [wr_csr_vif] not set for this monitor")
        if (!uvm_config_db#(virtual bmd_read_csr_if)::get(this, "", "rd_csr_vif", rd_csr_vif))
            `uvm_fatal(get_type_name(), "Virtual interface [rd_csr_vif] not set for this monitor")
        phase.drop_objection(this);
    endfunction

    task main_phase(uvm_phase phase);
        main_phase_started = 1;
    endtask

    // Write method - called when transaction received
    virtual function void write_perf_tx(apci_packet trans);
        // Add checking logic here
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                tx_packets.push_back(tlp);
                tx_timestamps.push_back($realtime);
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from tx packet to tx tlp")
            end
        end
    endfunction

    // Write method - called when transaction received
    virtual function void write_perf_rx(apci_packet trans);
        // Add checking logic here
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                rx_packets.push_back(tlp);
                rx_timestamps.push_back($realtime);
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from rx packet to rx tlp")
            end
        end
    endfunction

    virtual function void call_report();
        // Write DMA: device MWr to host (VIP RX = rx_packets)
        longint unsigned wr_dma_bytes;
        int              wr_dma_count;
        real             wr_dma_first, wr_dma_last;
        bit              wr_dma_started;
        real             mwr_times[$];
        real             wr_gap_min, wr_gap_max, wr_gap_sum, wr_gap_val;
        int              wr_gap_count;

        // Read DMA: device MRd out (VIP RX) + CplD back in (VIP TX)
        longint unsigned rd_dma_bytes;
        int              rd_dma_mrd_count;
        real             rd_dma_first, rd_dma_last;
        bit              rd_dma_started;

        // Read latency (FIFO queue per tag for tag recycling)
        real mrd_time_q[int][$];
        real lat_min, lat_max, lat_sum, lat_val;
        int  lat_count;

        // Derived
        real wr_dur, rd_dur, overall_dur;
        real wr_bw, rd_bw, overall_bw;
        real overall_first, overall_last;
        real lat_avg, wr_gap_avg;
        longint unsigned overall_bytes;

        // Initialize
        wr_dma_bytes = 0; wr_dma_count = 0;
        wr_dma_first = 0; wr_dma_last = 0; wr_dma_started = 0;
        rd_dma_bytes = 0; rd_dma_mrd_count = 0;
        rd_dma_first = 0; rd_dma_last = 0; rd_dma_started = 0;
        lat_min = 0; lat_max = 0; lat_sum = 0; lat_count = 0;
        wr_gap_min = 0; wr_gap_max = 0; wr_gap_sum = 0; wr_gap_count = 0;

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Pass 1: Scan device TX packets (VIP RX = rx_packets)
        //   - DMA Write: MWr (device writing to host memory)
        //   - DMA Read request: MRd (device requesting read from host memory)
        //   - Ignore: CplD (device responding to host MRd — not DMA traffic)
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        foreach (rx_packets[i]) begin
            case (rx_packets[i].kind)
                APCI_TLP_mwr: begin
                    wr_dma_bytes += rx_packets[i].u.fm_mem64.length * 4;
                    wr_dma_count++;
                    if (!wr_dma_started) begin
                        wr_dma_first = rx_timestamps[i];
                        wr_dma_started = 1;
                    end
                    wr_dma_last = rx_timestamps[i];
                    mwr_times.push_back(rx_timestamps[i]);
                end
                APCI_TLP_mrd: begin
                    rd_dma_mrd_count++;
                    mrd_time_q[rx_packets[i].u.fm_mem64.tag].push_back(rx_timestamps[i]);
                    if (!rd_dma_started) begin
                        rd_dma_first = rx_timestamps[i];
                        rd_dma_started = 1;
                    end
                end
                default: ; // Ignore CplD and other types
            endcase
        end

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Pass 2: Scan device RX packets (VIP TX = tx_packets)
        //   - DMA Read data: CplD (host returning read data to device)
        //   - Ignore: MWr (host MMIO writes to device — not DMA traffic)
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        foreach (tx_packets[i]) begin
            case (tx_packets[i].kind)
                APCI_TLP_cpld: begin
                    rd_dma_bytes += tx_packets[i].u.fm_cpl.length * 4;
                    rd_dma_last = tx_timestamps[i];
                    // Read latency: match CplD to MRd by tag (pop on final completion)
                    begin
                        int cpl_tag = tx_packets[i].u.fm_cpl.tag;
                        if (mrd_time_q.exists(cpl_tag) && mrd_time_q[cpl_tag].size() > 0) begin
                            if (tx_packets[i].u.fm_cpl.byte_cnt <=
                                    (tx_packets[i].u.fm_cpl.length << 2)) begin
                                lat_val = (tx_timestamps[i] -
                                    mrd_time_q[cpl_tag][0]) / 1000.0; // ps to ns
                                if (lat_count == 0 || lat_val < lat_min) lat_min = lat_val;
                                if (lat_count == 0 || lat_val > lat_max) lat_max = lat_val;
                                lat_sum += lat_val;
                                lat_count++;
                                void'(mrd_time_q[cpl_tag].pop_front());
                            end
                        end
                    end
                end
                default: ; // Ignore MWr and other types
            endcase
        end

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Write DMA inter-packet gaps
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        foreach (mwr_times[i]) begin
            if (i > 0) begin
                wr_gap_val = (mwr_times[i] - mwr_times[i-1]) / 1000.0; // ps to ns
                if (wr_gap_count == 0 || wr_gap_val < wr_gap_min) wr_gap_min = wr_gap_val;
                if (wr_gap_count == 0 || wr_gap_val > wr_gap_max) wr_gap_max = wr_gap_val;
                wr_gap_sum += wr_gap_val;
                wr_gap_count++;
            end
        end

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Compute derived values and print report
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        wr_dur  = (wr_dma_started && mwr_times.size() > 1) ?
            (wr_dma_last - wr_dma_first) / 1000.0 : 0;
        rd_dur  = (rd_dma_started) ?
            (rd_dma_last - rd_dma_first) / 1000.0 : 0;

        // Overall: earliest DMA start to latest DMA end
        overall_first = 0;
        overall_last  = 0;
        if (wr_dma_started && rd_dma_started) begin
            overall_first = (wr_dma_first < rd_dma_first) ? wr_dma_first : rd_dma_first;
            overall_last  = (wr_dma_last > rd_dma_last) ? wr_dma_last : rd_dma_last;
        end else if (wr_dma_started) begin
            overall_first = wr_dma_first;
            overall_last  = wr_dma_last;
        end else if (rd_dma_started) begin
            overall_first = rd_dma_first;
            overall_last  = rd_dma_last;
        end
        overall_dur   = (overall_last - overall_first) / 1000.0;
        overall_bytes = wr_dma_bytes + rd_dma_bytes;

        wr_bw      = (wr_dur > 0) ? real'(wr_dma_bytes) / wr_dur : 0;
        rd_bw      = (rd_dur > 0) ? real'(rd_dma_bytes) / rd_dur : 0;
        overall_bw = (overall_dur > 0) ? real'(overall_bytes) / overall_dur : 0;
        lat_avg    = (lat_count > 0) ? lat_sum / lat_count : 0;
        wr_gap_avg = (wr_gap_count > 0) ? wr_gap_sum / wr_gap_count : 0;

        `uvm_info(get_type_name(), $sformatf({"\n",
            "==================================================================\n",
            "                     BMD DMA PERFORMANCE REPORT\n",
            "==================================================================\n",
            "\n",
            "--- WRITE DMA (Device -> Host MWr) ---\n",
            "  Bandwidth:               %0.4f GB/s\n",
            "  Data transferred:        %0d bytes  (%0d TLPs)\n",
            "  Duration:                %0.2f ns\n",
            "  Min inter-write gap:     %0.2f ns\n",
            "  Max inter-write gap:     %0.2f ns\n",
            "  Avg inter-write gap:     %0.2f ns\n",
            "\n",
            "--- READ DMA (Device MRd -> Host CplD) ---\n",
            "  Bandwidth:               %0.4f GB/s\n",
            "  Data transferred:        %0d bytes  (%0d MRd, %0d CplD matched)\n",
            "  Duration:                %0.2f ns  (first MRd -> last CplD)\n",
            "  Latency min:             %0.2f ns\n",
            "  Latency max:             %0.2f ns\n",
            "  Latency avg:             %0.2f ns\n",
            "\n",
            "--- OVERALL DMA ---\n",
            "  Bandwidth:               %0.4f GB/s\n",
            "  Data transferred:        %0d bytes  (wr %0d + rd %0d)\n",
            "  Duration:                %0.2f ns\n",
            "=================================================================="},
            wr_bw,
            wr_dma_bytes, wr_dma_count,
            wr_dur,
            wr_gap_min, wr_gap_max, wr_gap_avg,
            rd_bw,
            rd_dma_bytes, rd_dma_mrd_count, lat_count,
            rd_dur,
            lat_min, lat_max, lat_avg,
            overall_bw,
            overall_bytes, wr_dma_bytes, rd_dma_bytes,
            overall_dur), UVM_LOW)
    endfunction
endclass
