// Verifies consistency between the PL and BFM boundaries for traffic generated from the BFM

`uvm_analysis_imp_decl(_rx_str)
`uvm_analysis_imp_decl(_tx_pkt)
class bmd_rx_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_rx_scoreboard_c)

    // Analysis port to receive transactions
    uvm_analysis_imp_rx_str #(rx_str_transaction, bmd_rx_scoreboard_c)  rx_str_ai;
    uvm_analysis_imp_tx_pkt #(apci_packet, bmd_rx_scoreboard_c)         txp;

    rx_str_transaction rx_str[$];
    apci_packet        tx_packets[$];

    bit main_phase_started;

    // Constructor
    function new(string name = "bmd_rx_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        rx_str_ai = new("rx_str_ai", this);
        txp = new("txp", this);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.build_phase(phase);
        main_phase_started = 0;
        phase.drop_objection(this);
    endfunction

    // Write method - called when transaction received
    virtual function void write_rx_str(rx_str_transaction trans);
        if(main_phase_started) begin
            rx_str.push_back(trans);
        end
    endfunction

    // Write method - called when transaction received
    virtual function void write_tx_pkt(apci_packet trans);
        // Add checking logic here
        if (main_phase_started) begin
            tx_packets.push_back(trans);
        end
    endfunction

    task main_phase(uvm_phase phase);
        main_phase_started = 1;
    endtask

    virtual function void write_logs();
        int f = $fopen("./bfm_tx_dump.txt");
        $fwrite(f, $sformatf("Number of entries in TX queue: %0d\n\n", tx_packets.size()));
        foreach (tx_packets[i]) begin
            apci_tlp tlp;
            if($cast(tlp, tx_packets[i])) begin
                $fwrite(f, "TLP[%0d]:\n%s\n", i, tlp.sprint(1));
                $fwrite(f, "\n");
            end else begin
                `uvm_error(get_type_name(), "TX Packet cast failed")
            end
        end
        $fclose(f);

        f = $fopen("./str_rx_dump.txt");
        $fwrite(f, "Number of entries in RX queue: %0d\n\n", rx_str.size());
        foreach (rx_str[i]) begin
            unique case(rx_str[i].ttype)
                2'b00: begin // posted
                    rx_data_p hdr = rx_str[i].header;
                    $fwrite(f,
                        {$sformatf("=== POSTED [%0d] ===\n", i),
                         $sformatf("Fmt: 0x%x, Type: 0x%x\n", hdr.fmt, hdr.ttype),
                         $sformatf("Address:     0x%x\n", hdr.addr),
                         $sformatf("First BE:    0x%x\n", hdr.first_be),
                         $sformatf("Last BE:     0x%x\n", hdr.last_be),
                         $sformatf("DW Length:   %0d\n", hdr.dw_len)
                        }
                    );
                    if (hdr.dw_len != 0) begin
                        $fwrite(f, "PAYLOAD:\n");
                        foreach (rx_str[i].data[k]) begin
                            $fwrite(f, "%x\n", rx_str[i].data[k]);
                        end
                    end
                end

                2'b01: begin // non-posted
                    rx_data_np hdr = rx_str[i].header;
                    $fwrite(f,
                        {$sformatf("=== NON-POSTED [%0d] ===\n", i),
                         $sformatf("Fmt: 0x%x, Type: 0x%x\n", hdr.fmt, hdr.ttype),
                         $sformatf("Address:     0x%x\n", hdr.addr),
                         $sformatf("Tag:         0x%x\n", hdr.tag),
                         $sformatf("First BE:    0x%x\n", hdr.first_be),
                         $sformatf("Last BE:     0x%x\n", hdr.last_be),
                         $sformatf("DW Length:   %0d\n", hdr.dw_len)
                        }
                    );
                end

                2'b10: begin // completion
                    rx_data_cpl hdr = rx_str[i].header;
                    $fwrite(f,
                        {$sformatf("=== COMPLETION [%0d] ===\n", i),
                         $sformatf("Fmt: 0x%x, Type: 0x%x\n", hdr.fmt, hdr.ttype),
                         $sformatf("Address:     0x%x\n", hdr.addr),
                         $sformatf("Tag:         0x%x\n", hdr.tag),
                         $sformatf("Byte Count:  %0d\n", hdr.byte_cnt),
                         $sformatf("DW Length:   %0d\n", hdr.dw_len)
                        }
                    );
                    if (hdr.dw_len != 0) begin
                        $fwrite(f, "PAYLOAD:\n");
                        foreach (rx_str[i].data[k]) begin
                            $fwrite(f, "%x\n", rx_str[i].data[k]);
                        end
                    end
                end

                2'b11: begin // non-posted w data
                    rx_data_npd hdr = rx_str[i].header;
                    $fwrite(f,
                        {$sformatf("=== NON-POSTED W/ DATA [%0d] ===\n", i),
                         $sformatf("Fmt: 0x%x, Type: 0x%x\n", hdr.fmt, hdr.ttype),
                         $sformatf("Address:     0x%x\n", hdr.addr),
                         $sformatf("First BE:    0x%x\n", hdr.first_be),
                         $sformatf("Last BE:     0x%x\n", hdr.last_be),
                         $sformatf("DW Length:   %0d\n", hdr.dw_len)
                        }
                    );
                    if (hdr.dw_len != 0) begin
                        $fwrite(f, "PAYLOAD:\n");
                        foreach (rx_str[i].data[k]) begin
                            $fwrite(f, "%x\n", rx_str[i].data[k]);
                        end
                    end
                end
            endcase
            $fwrite(f, "\n");
        end
        $fclose(f);
    endfunction

    // Report phase
    virtual function void report_phase(uvm_phase phase);
        phase.raise_objection(this);
        phase.drop_objection(this);
    endfunction

endclass
