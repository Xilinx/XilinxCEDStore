  // Clock signal declarations
  bit ctrl1_gt_refclk_0_clk_n;
  bit ctrl1_gt_refclk_0_clk_p;
  bit pcie1_clk_0;
  bit pcie1_rstn_0;

  bit ctrl0_gt_refclk_0_clk_n;
  bit ctrl0_gt_refclk_0_clk_p;
  bit pcie0_clk_0;
  bit pcie0_rstn_0;

   task automatic clkgen_basic(input shortreal delay, input shortreal clk_T, ref bit clk);
        #delay;
        clk = 1'b0;
        forever clk = #(clk_T/2) !clk;
    endtask

  initial begin
    fork
      clkgen_basic (0,   10.0,   ctrl1_gt_refclk_0_clk_n);
      clkgen_basic (0,   10.0,   ctrl1_gt_refclk_0_clk_p);
      clkgen_basic (0,   2.631,   pcie1_clk_0);  //380MHz
      clkgen_basic (0,   10.0,   ctrl0_gt_refclk_0_clk_n);
      clkgen_basic (0,   10.0,   ctrl0_gt_refclk_0_clk_p);
      clkgen_basic (0,   2.631,   pcie0_clk_0);  //380MHz
    join_none
  end

  generate if(tb_top.LINK0_WIDTH != 0 && tb_top.LINK1_WIDTH !=0) begin : ctrl_inst
      rp_axi_mmbr_top_wrapper_ctrl1_ctrl0_sim_wrapper dut_inst (
        .CTRL1_GT_0_grx_n       (/* CTRL1_GT_0_grx_n */),
        .CTRL1_GT_0_grx_p       (/* CTRL1_GT_0_grx_p */),
        .CTRL1_GT_0_gtx_n       (/* CTRL1_GT_0_gtx_n */),
        .CTRL1_GT_0_gtx_p       (/* CTRL1_GT_0_gtx_p */),
        .ctrl1_gt_refclk_0_clk_n(ctrl1_gt_refclk_0_clk_n),
        .ctrl1_gt_refclk_0_clk_p(ctrl1_gt_refclk_0_clk_p),
        .CTRL0_GT_0_grx_n       (/* CTRL0_GT_0_grx_n */),
        .CTRL0_GT_0_grx_p       (/* CTRL0_GT_0_grx_p */),
        .CTRL0_GT_0_gtx_n       (/* CTRL0_GT_0_gtx_n */),
        .CTRL0_GT_0_gtx_p       (/* CTRL0_GT_0_gtx_p */),
        .ctrl0_gt_refclk_0_clk_n(ctrl0_gt_refclk_0_clk_n),
        .ctrl0_gt_refclk_0_clk_p(ctrl0_gt_refclk_0_clk_p)
      );
    end
    else if (tb_top.LINK1_WIDTH != 0) begin
      rp_axi_mmbr_top_wrapper_ctrl1_sim_wrapper dut_inst (
        .CTRL1_GT_0_grx_n       (/* CTRL1_GT_0_grx_n */),
        .CTRL1_GT_0_grx_p       (/* CTRL1_GT_0_grx_p */),
        .CTRL1_GT_0_gtx_n       (/* CTRL1_GT_0_gtx_n */),
        .CTRL1_GT_0_gtx_p       (/* CTRL1_GT_0_gtx_p */),
        .ctrl1_gt_refclk_0_clk_n(ctrl1_gt_refclk_0_clk_n),
        .ctrl1_gt_refclk_0_clk_p(ctrl1_gt_refclk_0_clk_p)
      );
    end
    else if (tb_top.LINK0_WIDTH != 0) begin
      rp_axi_mmbr_top_wrapper_ctrl0_sim_wrapper dut_inst (
        .CTRL0_GT_0_grx_n       (/* CTRL0_GT_0_grx_n */),
        .CTRL0_GT_0_grx_p       (/* CTRL0_GT_0_grx_p */),
        .CTRL0_GT_0_gtx_n       (/* CTRL0_GT_0_gtx_n */),
        .CTRL0_GT_0_gtx_p       (/* CTRL0_GT_0_gtx_p */),
        .ctrl0_gt_refclk_0_clk_n(ctrl0_gt_refclk_0_clk_n),
        .ctrl0_gt_refclk_0_clk_p(ctrl0_gt_refclk_0_clk_p)
      );
    end
    else begin
      `uvm_fatal("DUT_INSTANTIATION", "No link width specified for either controller, cannot instantiate DUT")
    end
  endgenerate
