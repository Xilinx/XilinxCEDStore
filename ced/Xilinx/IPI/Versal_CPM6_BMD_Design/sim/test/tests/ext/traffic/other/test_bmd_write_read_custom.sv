//==============================================================================
// test_bmd_write_read_custom.sv - Combined Write+Read Traffic BMD Test (custom size/count)
//==============================================================================
// Description:
//   BMD test that creates writes and reads of a hand-editable size/count,
//   run concurrently (write and read DMA both started together). Edit the
//   wr_size/wr_count/rd_size/rd_count lines below to change the traffic
//   shape for a quick one-off run.
//==============================================================================

class test_bmd_write_read_custom extends test_bmd;
    `uvm_component_utils(test_bmd_write_read_custom)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "test_bmd_write_read_custom", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Post-Configure - Provide any overrides to randomization
    //--------------------------------------------------------------------------
    virtual task post_configure_phase(uvm_phase phase);
        super.post_configure_phase(phase);

        disable_extra();

        csr_cfg.wr_start = 1'b1;
        csr_cfg.rd_start = 1'b1;

        csr_cfg.wr_size  = 9'h010;    // <-- change this to alter TLP size (legal: 1,2,4,8,16,32,64,128,256 DW)
        csr_cfg.wr_count = 16'd1024;  // <-- change this to alter TLP count (legal range: 1 to 65535)
        csr_cfg.rd_size  = 9'h010;    // <-- change this to alter TLP size (legal: 1,2,4,8,16,32,64,128,256 DW)
        csr_cfg.rd_count = 16'd1024;  // <-- change this to alter TLP count (legal range: 1 to 65535)

        csr_cfg.wr_pattern = 32'h54535251;
        csr_cfg.rd_pattern = 32'h54535251;

        csr_cfg.wr_addr[9:0]  = '0;
        csr_cfg.rd_addr[10:0] = '0;

        if (csr_cfg.wr_upper_be == 4'b0000) csr_cfg.wr_upper_be = 4'b1111;
        if (csr_cfg.wr_lower_be == 4'b0000) csr_cfg.wr_lower_be = 4'b1111;
        if (csr_cfg.rd_upper_be == 4'b0000) csr_cfg.rd_upper_be = 4'b1111;
        if (csr_cfg.rd_lower_be == 4'b0000) csr_cfg.rd_lower_be = 4'b1111;

        csr_cfg.wr_tc_en = 1'b0;
        csr_cfg.wr_tc    = 3'b000;
        csr_cfg.rd_tc_en = 1'b0;
        csr_cfg.rd_tc    = 3'b000;
    endtask

endclass : test_bmd_write_read_custom
