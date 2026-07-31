// Verifies consistency between the PL and BFM boundaries for traffic generated from the device
`uvm_analysis_imp_decl(_tx_str)
`uvm_analysis_imp_decl(_rx_pkt)
class bmd_tx_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_tx_scoreboard_c)

    // Analysis port to receive transactions
    uvm_analysis_imp_tx_str #(tx_str_transaction, bmd_tx_scoreboard_c) tx_str_ai;
    uvm_analysis_imp_rx_pkt #(apci_packet, bmd_tx_scoreboard_c) rxp;

    tx_str_transaction  tx_str[$];
    apci_packet         rx_packets[$];

    bit main_phase_started;

    // Constructor
    function new(string name = "bmd_tx_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        tx_str_ai = new("tx_str_ai", this);
        rxp = new("rxp", this);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.build_phase(phase);
        main_phase_started = 0;
        phase.drop_objection(this);
    endfunction

    // Write method - called when transaction received
    virtual function void write_tx_str(tx_str_transaction trans);
        // Add checking logic here
        if(main_phase_started) begin
            tx_str.push_back(trans);
        end
    endfunction

    // Write method - called when transaction received
    virtual function void write_rx_pkt(apci_packet trans);
        // Add checking logic here
        if (main_phase_started) begin
            rx_packets.push_back(trans);
        end
    endfunction

    task main_phase(uvm_phase phase);
        main_phase_started = 1;
    endtask

    virtual function void write_logs();
        int f = $fopen("./bfm_rx_dump.txt");
        $fwrite(f, $sformatf("Number of entries in RX queue: %0d\n\n", rx_packets.size()));
        foreach (rx_packets[i]) begin
            apci_tlp tlp;
            if($cast(tlp, rx_packets[i])) begin
                $fwrite(f, "TLP[%0d]:\n%s\n", i, tlp.sprint(1));
                $fwrite(f, "\n");
            end else begin
                `uvm_error(get_type_name(), "RX Packet cast failed")
            end
        end
        $fclose(f);

        f = $fopen("./str_tx_dump.txt");
        $fwrite(f, "Number of entries in TX queue: %0d\n\n", tx_str.size());
        foreach (tx_str[i]) begin
            unique case(tx_str[i].ttype)
                2'b00: begin // posted
                    tx_data_p hdr = tx_str[i].header;
                    $fwrite(f,
                        {$sformatf("=== POSTED [%0d] ===\n", i),
                         $sformatf("Fmt: 0x%x, Type: 0x%x\n", hdr.fmt, hdr.ttype),
                         $sformatf("Address:     0x%x\n", hdr.addr),
                         $sformatf("Byte Enable: 0x%x\n", hdr.byte_en),
                         $sformatf("Byte Length: %0d\n", hdr.byte_len)
                        }
                    );
                    if (hdr.byte_len != 0) begin
                        $fwrite(f, "PAYLOAD:\n");
                        foreach (tx_str[i].data[k]) begin
                            $fwrite(f, "%x\n", tx_str[i].data[k]);
                        end
                    end
                end

                2'b01: begin // non-posted
                    tx_data_np hdr = tx_str[i].header;
                    $fwrite(f,
                        {$sformatf("=== NON-POSTED [%0d] ===\n", i),
                         $sformatf("Fmt: 0x%x, Type: 0x%x\n", hdr.fmt, hdr.ttype),
                         $sformatf("Address:     0x%x\n", hdr.addr),
                         $sformatf("Tag:         0x%x\n", hdr.tid),
                         $sformatf("Byte Enable: 0x%x\n", hdr.byte_en),
                         $sformatf("Byte Length: %0d\n", hdr.byte_len)
                        }
                    );
                end

                2'b10: begin // completion
                    tx_data_cpl hdr = tx_str[i].header;
                    $fwrite(f,
                        {$sformatf("=== COMPLETION [%0d] ===\n", i),
                         $sformatf("Fmt: 0x%x, Type: 0x%x\n", hdr.fmt, hdr.ttype),
                         $sformatf("Address:     0x%x\n", hdr.addr),
                         $sformatf("Byte Enable: 0x%x\n", hdr.byte_en),
                         $sformatf("Byte Length: %0d\n", hdr.byte_len)
                        }
                    );
                    if (hdr.byte_len != 0) begin
                        $fwrite(f, "PAYLOAD:\n");
                        foreach (tx_str[i].data[k]) begin
                            $fwrite(f, "%x\n", tx_str[i].data[k]);
                        end
                    end
                end

                2'b11: begin // non-posted w data
                    tx_data_npd hdr = tx_str[i].header;
                    $fwrite(f,
                        {$sformatf("=== NON-POSTED W/ DATA [%0d] ===\n", i),
                         $sformatf("Fmt: 0x%x, Type: 0x%x\n", hdr.fmt, hdr.ttype),
                         $sformatf("Address:     0x%x\n", hdr.addr),
                         $sformatf("Byte Enable: 0x%x\n", hdr.byte_en),
                         $sformatf("Byte Length: %0d\n", hdr.byte_len)
                        }
                    );
                    if (hdr.byte_len != 0) begin
                        $fwrite(f, "PAYLOAD:\n");
                        foreach (tx_str[i].data[k]) begin
                            $fwrite(f, "%x\n", tx_str[i].data[k]);
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
