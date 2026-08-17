// Verify that UR is sent by the DUT when an out of range access is performed

`uvm_analysis_imp_decl(_ur_rx)
class bmd_ur_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_ur_scoreboard_c)

    apci_tlp rx_packets[$];

    uvm_analysis_imp_ur_rx #(apci_packet, bmd_ur_scoreboard_c) rxp;

    bit main_phase_started;
    bit read_out_of_range;

    // Constructor
    function new(string name = "bmd_ur_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        rxp = new("rxp", this);
    endfunction

    function void clear();
        rx_packets.delete();
        read_out_of_range = '0;
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.build_phase(phase);
        main_phase_started = 0;
        phase.drop_objection(this);
    endfunction

    task main_phase(uvm_phase phase);
        main_phase_started = 1;
    endtask

    // Write method - called when transaction received
    virtual function void write_ur_rx(apci_packet trans);
        // Add checking logic here
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                rx_packets.push_back(tlp);
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from rx packet to rx tlp")
            end
        end
    endfunction

    // Report phase
    int amt_of_ur;
    virtual function void call_report();
        amt_of_ur = 0;
        // Check UR was returned by DUT if read was out of range
        foreach (rx_packets[i]) begin
            if (rx_packets[i].kind inside {APCI_TLP_cpld, APCI_TLP_cpl}) begin
                if (rx_packets[i].get_cpl_status() == 3'b001) begin
                    amt_of_ur++;
                end
            end
        end
        if (amt_of_ur != 1 && read_out_of_range) `uvm_error(get_type_name(), "UR not sent for out of range read")
    endfunction

endclass

