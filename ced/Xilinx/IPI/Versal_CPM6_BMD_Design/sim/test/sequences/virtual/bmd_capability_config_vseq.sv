//==============================================================================
// bmd_capability_config_vseq.sv - BMD Capability Configuration Virtual Sequence
//==============================================================================
// Orchestrates all capability configuration sequences based on config settings
//==============================================================================

class bmd_capability_config_vseq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_capability_config_vseq_c)

    //--------------------------------------------------------------------------
    // Sequences
    //--------------------------------------------------------------------------
    bmd_intx_config_seq_c       intx_seq;
    bmd_10b_tag_config_seq_c    tag_10b_seq;
    bmd_ext_tag_config_seq_c    ext_tag_seq;
    bmd_pasid_config_seq_c      pasid_seq;
    bmd_tph_config_seq_c        tph_seq;
    bmd_msi_config_seq_c        msi_seq;
    bmd_msix_config_seq_c       msix_seq;
    bmd_vsec_config_seq_c       vsec_seq;
    bmd_tlp_type_config_seq_c   ttype_seq;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_capability_config_vseq");
        super.new(name);

        intx_seq    = bmd_intx_config_seq_c::type_id::create("intx_seq");
        tag_10b_seq = bmd_10b_tag_config_seq_c::type_id::create("tag_10b_seq");
        ext_tag_seq = bmd_ext_tag_config_seq_c::type_id::create("ext_tag_seq");
        pasid_seq   = bmd_pasid_config_seq_c::type_id::create("pasid_seq");
        tph_seq     = bmd_tph_config_seq_c::type_id::create("tph_seq");
        msi_seq     = bmd_msi_config_seq_c::type_id::create("msi_seq");
        msix_seq    = bmd_msix_config_seq_c::type_id::create("msix_seq");
        vsec_seq    = bmd_vsec_config_seq_c::type_id::create("vsec_seq");
        ttype_seq   = bmd_tlp_type_config_seq_c::type_id::create("ttype_seq");
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        `uvm_info(get_name(), "Starting capability configuration", UVM_MEDIUM)

        // Configure INTx
        intx_seq.start(m_sequencer);

        // Configure 10-bit tag (also sets MPS)
        tag_10b_seq.start(m_sequencer);

        // Configure extended tag
        ext_tag_seq.start(m_sequencer);

        // Configure PASID
        pasid_seq.start(m_sequencer);

        // Configure TPH
        tph_seq.start(m_sequencer);

        // Configure MSI
        msi_seq.start(m_sequencer);

        // Configure MSI-X
        msix_seq.start(m_sequencer);

        // Configure TLP Type
        ttype_seq.start(m_sequencer);

        // Access VSEC (if enabled)
        if (tst_cfg.access_vsec) begin
            vsec_seq.start(m_sequencer);
        end

        `uvm_info(get_name(), "Capability configuration complete", UVM_MEDIUM)

    endtask

endclass
