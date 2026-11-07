//==============================================================================
// bmd_ide_tlps.sv
//
// Sends the root port's requests on the IDE stream once it is secure, without
// changing the BMD or framework sequences:
//   - bmd_ide_mem_tlp / bmd_ide_cfg_tlp: factory overrides of the TLPs the
//     sequences create (amd_mem_tlp, amd_cfg_tlp); the shim passes their
//     ide_stream_id to the VIP.
//   - bmd_ide_cfg_cb: VIP callback for the configuration requests the VIP
//     builds itself (capability reads/writes), which are not amd_cfg_tlps.
// All of them leave requests unprotected while bmd_ide_stream::id is X.
//==============================================================================

class bmd_ide_stream;
    // Stream to send on; X (no IDE) until the test has the stream secure
    static logic [7:0] id = 'x;
    // Also send configuration requests on the stream (IDE for them is optional
    // on a Link IDE stream)
    static bit cfg_en = 1'b1;
endclass

class bmd_ide_mem_tlp extends amd_mem_tlp;
    `uvm_object_utils(bmd_ide_mem_tlp)

    function new(string name = "bmd_ide_mem_tlp");
        super.new(name);
        ide_stream_id = bmd_ide_stream::id;
    endfunction
endclass

class bmd_ide_cfg_tlp extends amd_cfg_tlp;
    `uvm_object_utils(bmd_ide_cfg_tlp)

    function new(string name = "bmd_ide_cfg_tlp");
        super.new(name);
        if (bmd_ide_stream::cfg_en) ide_stream_id = bmd_ide_stream::id;
    endfunction
endclass

class bmd_ide_cfg_cb extends apci_callbacks;
    function bit use_stream(int ide_stream_id);
        return bmd_ide_stream::cfg_en && bmd_ide_stream::id !== 'x && ide_stream_id == -1;
    endfunction

    virtual function void tx_tr_before_scheduler(apci_device bfm, apci_transaction tr);
        if (tr.kind == APCI_TRANS_cfg && use_stream(tr.user_ctrl.ide_stream_id))
            tr.user_ctrl.ide_stream_id = bmd_ide_stream::id;
    endfunction

    virtual function void tx_tlp_before_scheduler(apci_device bfm, apci_tlp tlp);
        if (tlp.kind inside {APCI_TLP_cfgrd, APCI_TLP_cfgrd0, APCI_TLP_cfgrd1,
                             APCI_TLP_cfgwr, APCI_TLP_cfgwr0, APCI_TLP_cfgwr1} &&
            use_stream(tlp.user_ctrl.ide_stream_id))
            tlp.user_ctrl.ide_stream_id = bmd_ide_stream::id;
    endfunction
endclass
