//==============================================================================
// bmd_startup_vseq.sv - BMD Startup Virtual Sequence
//==============================================================================
// Complete BMD initialization: reset → capabilities → CSRs → prefixes → start
//==============================================================================

class bmd_startup_vseq_c extends bmd_base_sequence_c;
    `uvm_object_utils(bmd_startup_vseq_c)

    //--------------------------------------------------------------------------
    // Sequences
    //--------------------------------------------------------------------------
    bmd_reset_seq_c                 reset_seq;
    bmd_capability_config_vseq_c    cap_vseq;
    bmd_write_tlp_format_seq_c      wr_fmt_seq;
    bmd_read_tlp_format_seq_c       rd_fmt_seq;
    bmd_byte_enable_config_seq_c    be_seq;
    bmd_int_vec_config_seq_c        int_vec_seq;
    bmd_pasid_prefix_seq_c          pasid_prefix_seq;
    bmd_tph_prefix_seq_c            tph_prefix_seq;
    bmd_out_of_range_read_seq_c     oor_read_seq;
    bmd_start_traffic_seq_c         start_seq;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "bmd_startup_vseq");
        super.new(name);

        reset_seq           = bmd_reset_seq_c::type_id::create("reset_seq");
        cap_vseq            = bmd_capability_config_vseq_c::type_id::create("cap_vseq");
        wr_fmt_seq          = bmd_write_tlp_format_seq_c::type_id::create("wr_fmt_seq");
        rd_fmt_seq          = bmd_read_tlp_format_seq_c::type_id::create("rd_fmt_seq");
        be_seq              = bmd_byte_enable_config_seq_c::type_id::create("be_seq");
        int_vec_seq         = bmd_int_vec_config_seq_c::type_id::create("int_vec_seq");
        pasid_prefix_seq    = bmd_pasid_prefix_seq_c::type_id::create("pasid_prefix_seq");
        tph_prefix_seq      = bmd_tph_prefix_seq_c::type_id::create("tph_prefix_seq");
        oor_read_seq        = bmd_out_of_range_read_seq_c::type_id::create("oor_read_seq");
        start_seq           = bmd_start_traffic_seq_c::type_id::create("start_seq");
    endfunction

    //--------------------------------------------------------------------------
    // Sequence Body
    //--------------------------------------------------------------------------
    virtual task body();
        `uvm_info(get_name(), "Starting BMD initialization sequence", UVM_LOW)

        // Step 1: Reset BMD (deassert reset)
        reset_seq.assert_reset = 1'b0;  // Deassert reset
        reset_seq.start(m_sequencer);

        // Step 2: Configure all capabilities
        cap_vseq.start(m_sequencer);

        // Step 3: Program write TLP format
        wr_fmt_seq.start(m_sequencer);

        // Step 4: Program read TLP format
        rd_fmt_seq.start(m_sequencer);

        // Step 5: Program byte enables
        be_seq.start(m_sequencer);

        // Step 6: Program interrupt vectors
        int_vec_seq.start(m_sequencer);

        // Step 7: Program PASID prefix
        pasid_prefix_seq.start(m_sequencer);

        // Step 8: Program TPH prefix
        tph_prefix_seq.start(m_sequencer);

        // Setp 9: Perform out of range read
        if (tst_cfg.read_out_of_range) begin
            oor_read_seq.start(m_sequencer);
        end

        // Step 10: Start traffic generation
        start_seq.start(m_sequencer);

        `uvm_info(get_name(), "BMD initialization complete - traffic started", UVM_LOW)

    endtask

endclass
