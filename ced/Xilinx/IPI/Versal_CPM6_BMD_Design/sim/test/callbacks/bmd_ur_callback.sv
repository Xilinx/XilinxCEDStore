// Used to "corrupt" memory reads from bmd to cause UR
class bmd_ur_callback_c extends apci_callbacks;

    bit main_phase_started;

    bit             send_ur_to_dut;
    bit             ur_sent;
    bit [13:0]      ur_tag;
    bit [15:0]      rd_count;
    bit             is_split;

    function new(apci_device bfm_handle = null);
        ur_sent = 1'b0;
        main_phase_started = 1'b0;
        is_split = 1'b0;
    endfunction

    virtual function void clear();
        send_ur_to_dut  = '0;
        ur_sent         = '0;
        ur_tag          = '0;
        rd_count        = '0;
        is_split        = '0;
    endfunction

    virtual function void tx_pkt_exit_tl(
                apci_device  bfm,
                apci_tlp     tlp
            );
        if (tlp.kind == APCI_TLP_cpld && main_phase_started) begin
            if (send_ur_to_dut && !ur_sent && (rd_count == 1 || tlp.u.fm_cpl.tag != 0)) begin
                this.ur_sent = 1'b1;
                this.ur_tag = tlp.u.fm_cpl.tag;
                tlp.kind = APCI_TLP_cpl;
                tlp.set_cpl_status(3'b001);
                is_split = 1'b1;
            end else if (is_split && tlp.u.fm_cpl.tag == this.ur_tag) begin // same tag and sequential
                tlp.kind = APCI_TLP_cpl;
                tlp.set_cpl_status(3'b001);
                is_split = 1'b0;
            end else begin
                is_split = 1'b0;
            end
            rd_count++;
        end
    endfunction

endclass
