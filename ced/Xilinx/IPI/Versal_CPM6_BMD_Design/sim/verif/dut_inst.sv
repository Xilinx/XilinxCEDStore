generate
    if (tb_top.LINK0_WIDTH != 0 && tb_top.LINK1_WIDTH != 0) begin : ctrl_inst
        dual_ctrl_bmd_ep dut_inst (
            .CTRL0_GT_0_grx_n           ( vip2dut_n[0] ),
            .CTRL0_GT_0_grx_p           ( vip2dut_p[0] ),
            .CTRL0_GT_0_gtx_n           ( dut2vip_n[0] ),
            .CTRL0_GT_0_gtx_p           ( dut2vip_p[0] ),
            .CTRL1_GT_0_grx_n           ( vip2dut_n[1] ),
            .CTRL1_GT_0_grx_p           ( vip2dut_p[1] ),
            .CTRL1_GT_0_gtx_n           ( dut2vip_n[1] ),
            .CTRL1_GT_0_gtx_p           ( dut2vip_p[1] ),

            .ctrl0_gt_refclk_0_clk_n    ( refclk_0_n ),
            .ctrl0_gt_refclk_0_clk_p    ( refclk_0_p ),

            .ctrl1_gt_refclk_0_clk_n    ( refclk_1_n ),
            .ctrl1_gt_refclk_0_clk_p    ( refclk_1_p )
        );
    end else if (tb_top.LINK1_WIDTH != 0) begin : ctrl_inst
        ctrl1_bmd_ep dut_inst (
            .CTRL1_GT_0_grx_n           ( vip2dut_n[1] ),
            .CTRL1_GT_0_grx_p           ( vip2dut_p[1] ),
            .CTRL1_GT_0_gtx_n           ( dut2vip_n[1] ),
            .CTRL1_GT_0_gtx_p           ( dut2vip_p[1] ),

            .ctrl1_gt_refclk_0_clk_n    ( refclk_1_n ),
            .ctrl1_gt_refclk_0_clk_p    ( refclk_1_p )
        );
    end else if (tb_top.LINK0_WIDTH != 0) begin : ctrl_inst
        ctrl0_bmd_ep dut_inst (
            .CTRL0_GT_0_grx_n           ( vip2dut_n[0] ),
            .CTRL0_GT_0_grx_p           ( vip2dut_p[0] ),
            .CTRL0_GT_0_gtx_n           ( dut2vip_n[0] ),
            .CTRL0_GT_0_gtx_p           ( dut2vip_p[0] ),

            .ctrl0_gt_refclk_0_clk_n    ( refclk_0_n ),
            .ctrl0_gt_refclk_0_clk_p    ( refclk_0_p )
        );
    end
endgenerate


// initial begin
//     $dumpfile("waves.vcd");
//     $dumpvars(0, tb_top.ctrl_inst.dut_inst);
// end

/////////////////////////////////////////////////////////
// Create Interfaces

    // TX streaming Interface
plstr_tx_if tx_if (
    .clk(tb_top.ctrl_inst.dut_inst.pl0_ref_clk_0)
);

    // RX streaming Interface
plstr_rx_if rx_if (
    .clk(tb_top.ctrl_inst.dut_inst.pl0_ref_clk_0)
);

    // RX credit Interface
plstr_credit_if rx_cr_if (
    .clk(tb_top.ctrl_inst.dut_inst.pl0_ref_clk_0)
);

    // TX credit Interface
plstr_credit_if tx_cr_if (
    .clk(tb_top.ctrl_inst.dut_inst.pl0_ref_clk_0)
);

    // Write CSR Interface
bmd_write_csr_if write_csr_if (
    .clk(tb_top.ctrl_inst.dut_inst.pl0_ref_clk_0)
);

    // Read CSR Interface
bmd_read_csr_if read_csr_if (
    .clk(tb_top.ctrl_inst.dut_inst.pl0_ref_clk_0)
);

/////////////////////////////////////////////////////////
// Connect Interfaces

    // Connect rx/tx streaming interfaces
assign tx_if.tx_intf      = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.tx;
assign rx_if.rx_intf      = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.rx;

    // Connect rx credit interface signals
assign rx_cr_if.cr        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.rx_crd.cr;
assign rx_cr_if.cr_valid  = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.rx_crd.cr_valid;
assign rx_cr_if.cr_active = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.rx_crd.cr_active;

    // Connect tx credit interface signals
assign tx_cr_if.cr        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.tx_crd.cr;
assign tx_cr_if.cr_valid  = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.tx_crd.cr_valid;
assign tx_cr_if.cr_active = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.tx_crd.cr_active;

    // Connect write CSRs
assign write_csr_if.write_type        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_type_o;
assign write_csr_if.write_fmt         = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_fmt_o;
assign write_csr_if.write_size        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_len_o;
assign write_csr_if.write_address     = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_addr_o;
assign write_csr_if.write_up_address  = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_up_addr_o;
assign write_csr_if.write_count       = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_count_o;
assign write_csr_if.write_pattern     = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_data_o;
assign write_csr_if.write_l_be        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_lower_be_o;
assign write_csr_if.write_u_be        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_upper_be_o;
assign write_csr_if.write_done        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_done_i;
assign write_csr_if.write_start       = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_start_o;
assign write_csr_if.write_64b_en      = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_64b_en_o;
assign write_csr_if.wr_int_disable    = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_int_dis_o;
assign write_csr_if.wr_int_sel        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_int_select_o;
assign write_csr_if.intx_wr_vec       = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_intx_vec_o;
assign write_csr_if.msix_wr_vec       = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_msix_vec_o;
assign write_csr_if.write_tph         = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_tph_o;
assign write_csr_if.write_tph_ext_vld = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_tph_vld_o;
assign write_csr_if.write_tph_vld     = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_tph_en_o;
assign write_csr_if.write_ph          = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_phint_o;
assign write_csr_if.write_st          = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_steering_tag_o;
assign write_csr_if.write_pasid_en    = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_pasid_vld_o;
assign write_csr_if.write_pasid       = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mwr_pasid_o;

    // Connect read CSRs
assign read_csr_if.read_type          = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_type_o;
assign read_csr_if.read_fmt           = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_fmt_o;
assign read_csr_if.received_cpls      = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.cpld_found_i;
assign read_csr_if.read_count         = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_count_o;
assign read_csr_if.read_pattern       = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.cpld_data_o;
assign read_csr_if.read_size          = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_len_o;
assign read_csr_if.read_l_be          = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_lower_be_o;
assign read_csr_if.read_u_be          = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_upper_be_o;
assign read_csr_if.read_address       = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_addr_o;
assign read_csr_if.read_up_address    = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_up_addr_o;
assign read_csr_if.read_start         = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_start_o;
assign read_csr_if.read_done          = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_done_i;
assign read_csr_if.read_dma_err       = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.cpld_data_err_i;
assign read_csr_if.read_64b_en        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_64b_en_o;
assign read_csr_if.rd_int_disable     = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_int_dis_o;
assign read_csr_if.rd_int_sel         = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_int_select_o;
assign read_csr_if.intx_rd_vec        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_intx_vec_o;
assign read_csr_if.msix_rd_vec        = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_msix_vec_o;
assign read_csr_if.cpl_ur_found_i     = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.cpl_ur_found_i;
assign read_csr_if.cpl_ur_tag_i       = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.cpl_ur_tag_i;
assign read_csr_if.read_tph           = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_tph_o;
assign read_csr_if.read_tph_ext_vld   = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_tph_vld_o;
assign read_csr_if.read_tph_vld       = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_tph_en_o;
assign read_csr_if.read_ph            = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_phint_o;
assign read_csr_if.read_st            = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_steering_tag_o;
assign read_csr_if.read_pasid_en      = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_pasid_vld_o;
assign read_csr_if.read_pasid         = tb_top.ctrl_inst.dut_inst.pcie_app_versal_bmd_top_i.BMD_AXIST.BMD_AXIST_EP.EP_MEM_ACCESS.EP_MEM.mrd_pasid_o;

/////////////////////////////////////////////////////////
// Add Interfaces to DB
initial begin
    uvm_config_db#(virtual plstr_tx_if)::set     (null, "*", "tx_str_vif", tx_if);
    uvm_config_db#(virtual plstr_rx_if)::set     (null, "*", "rx_str_vif", rx_if);
    uvm_config_db#(virtual plstr_credit_if)::set (null, "*", "rx_cr_vif",  rx_cr_if);
    uvm_config_db#(virtual plstr_credit_if)::set (null, "*", "tx_cr_vif",  tx_cr_if);
    uvm_config_db#(virtual bmd_write_csr_if)::set(null, "*", "wr_csr_vif", write_csr_if);
    uvm_config_db#(virtual bmd_read_csr_if)::set (null, "*", "rd_csr_vif", read_csr_if);
end
