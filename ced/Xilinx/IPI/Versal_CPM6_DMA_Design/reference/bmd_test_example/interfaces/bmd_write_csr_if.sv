interface bmd_write_csr_if (
    input logic clk
);
    // The monitor will sample this struct on clock edges
    logic [4:0]     write_type;
    logic           write_fmt;

    logic [10:0]    write_size;
    logic [31:0]    write_address;
    logic [31:0]    write_up_address;
    logic [15:0]    write_count;
    logic [31:0]    write_pattern;
    logic [3:0]     write_l_be;
    logic [3:0]     write_u_be;
    logic           write_done;
    logic           write_start;
    logic           write_64b_en;
    //INTx
    logic           wr_int_disable;
    logic [1:0]     wr_int_sel;
    logic [1:0]     intx_wr_vec;

    logic [10:0]    msix_wr_vec;

    // TPH
    logic [11:0]    write_tph;          // EXT TPH Prefix
    logic           write_tph_ext_vld;  // EXT TPH Valid
    logic           write_tph_vld;      // TPH Valid
    logic [7:0]     write_st;           // Steering Tag [7:0]
    logic [1:0]     write_ph;           // Processing Hints

    // PASID
    logic           write_pasid_en;
    logic [23:0]    write_pasid;

    logic [31:0]    write_perf;

    // Clocking block specifically for the monitor
    // This ensures proper signal sampling and prevents race conditions
    clocking monitor_cb @(posedge clk);
        input write_type;
        input write_fmt;

        input write_size;
        input write_address;
        input write_up_address;
        input write_count;
        input write_pattern;
        input write_l_be;
        input write_u_be;
        input write_done;
        input write_start;
        input write_64b_en;

        input wr_int_disable;
        input wr_int_sel;
        input intx_wr_vec;

        input msix_wr_vec;

        input write_tph;
        input write_tph_ext_vld;
        input write_tph_vld;
        input write_st;
        input write_ph;

        input write_pasid_en;
        input write_pasid;

        input write_perf;
    endclocking

    // Modport for the monitor - restricts access to just what's needed
    modport monitor_mp (
        clocking monitor_cb
    );
endinterface
