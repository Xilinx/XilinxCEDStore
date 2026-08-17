interface bmd_read_csr_if (
    input logic clk
);
    // The monitor will sample this struct on clock edges
    logic [4:0]     read_type;
    logic           read_fmt;

    logic [31:0]    received_cpls;
    logic [15:0]    read_count;
    logic [31:0]    read_pattern;
    logic [10:0]    read_size;
    logic [3:0]     read_l_be;
    logic [3:0]     read_u_be;
    logic [31:0]    read_address;
    logic [31:0]    read_up_address;
    logic           read_start;
    logic           read_done;
    logic           read_dma_err;
    logic           read_64b_en;

    //INTx
    logic           rd_int_disable;
    logic [1:0]     rd_int_sel;
    logic [1:0]     intx_rd_vec;

    logic [10:0]    msix_rd_vec;

    //UR
    logic [15:0]    cpl_ur_found_i;
    logic [9:0]     cpl_ur_tag_i;

    // TPH
    logic [11:0]    read_tph;          // EXT TPH Prefix
    logic           read_tph_ext_vld;  // EXT TPH Valid
    logic           read_tph_vld;      // TPH Valid
    logic [7:0]     read_st;           // Steering Tag [7:0]
    logic [1:0]     read_ph;           // Processing Hints

    // PASID
    logic           read_pasid_en;
    logic [23:0]    read_pasid;

    logic [31:0]    read_perf;

    // Clocking block specifically for the monitor
    // This ensures proper signal sampling and prevents race conditions
    clocking monitor_cb @(posedge clk);
        input read_type;
        input read_fmt;

        input received_cpls;
        input read_count;
        input read_pattern;
        input read_size;
        input read_l_be;
        input read_u_be;
        input read_address;
        input read_up_address;
        input read_start;
        input read_done;
        input read_dma_err;
        input read_64b_en;

        input rd_int_disable;
        input rd_int_sel;
        input intx_rd_vec;

        input msix_rd_vec;

        input cpl_ur_found_i;
        input cpl_ur_tag_i;

        input read_tph;
        input read_tph_ext_vld;
        input read_tph_vld;
        input read_st;
        input read_ph;

        input read_pasid_en;
        input read_pasid;

        input read_perf;
    endclocking

    // Modport for the monitor - restricts access to just what's needed
    modport monitor_mp (
        clocking monitor_cb
    );
endinterface
