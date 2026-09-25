// bind.qdma_boundary_probe.sv -- diagnostic-only bind covering the FULL
// interface boundary of the cpm6_qdma IP core (module type
// cpm6_qdma_v1_0_0_top_wrapper, the "cpm6_qdma_0" BD cell's actual type).
//
// This probe answers "which HDMA channel / which
// cpm_axi_pl port does a queue's transfer actually use, and does the C2H
// direction ever produce a DBI doorbell/context write at all".
//
// This probe is limited to the IP's port boundary and is a debug-only
// addition, not a permanent monitor.
//
// Self-contained plain $fdisplay-to-file bind (no UVM agent, no
// uvm_config_db) -- a standard pattern for diagnostic-only probes.
// $fdisplay executes at elaboration regardless of
// -kdb/-debug_access, unlike FSDB waveform dumping, so this works today
// without touching Vivado's generated compile.sh.
//
// Following bind.pswizard.sv's established convention in this same
// directory: every port below is declared "input wire" regardless of the
// target module's actual port direction, relying on (.*) name-based
// connection resolution (IEEE 1800-2017 23.3.2) rather than preserving
// exact directionality -- avoids depending on VCS XMRE wire merge across
// library boundaries.
//
// Port list copied verbatim from the generated cpm6_qdma_v1_0_0_top_wrapper
// module. Parameter values below (DMA_ST=0, MSIX_EN=1, P_DSC_CRDT_EN=1) are
// hardcoded LOCAL CONSTANTS, not read from the bound instance -- these match
// this CED's BD IP configuration (msix_en=true, traf_man_intf=true; DMA_ST=0
// since this CED ships only the MM-mode test suite, test_qdma_h2c_c2h_mm_Mfnc_MQ).
// Re-verify these three if the BD's cpm6_qdma_0 IP configuration ever changes.

`default_nettype wire
module qdma_boundary_probe (
    //Interface to Register space
    input  wire [42:0]   s_axi_reg_araddr,
    input  wire [1:0]    s_axi_reg_arburst,
    input  wire [31:0]   dbg_mbx_addr,
    input  wire [3:0]    s_axi_reg_arcache,
    input  wire [0:0]    s_axi_reg_arid,
    input  wire [7:0]    s_axi_reg_arlen,
    input  wire          s_axi_reg_arlock,
    input  wire [2:0]    s_axi_reg_arprot,
    input  wire [3:0]    s_axi_reg_arqos,
    input  wire [2:0]    s_axi_reg_arsize,
    input  wire [45:0]   s_axi_reg_aruser,
    input  wire          s_axi_reg_arvalid,
    input  wire          s_axi_reg_arready,

    input  wire [42:0]   s_axi_reg_awaddr,
    input  wire [1:0]    s_axi_reg_awburst,
    input  wire [3:0]    s_axi_reg_awcache,
    input  wire [0:0]    s_axi_reg_awid,
    input  wire [7:0]    s_axi_reg_awlen,
    input  wire          s_axi_reg_awlock,
    input  wire [2:0]    s_axi_reg_awprot,
    input  wire [3:0]    s_axi_reg_awqos,
    input  wire [2:0]    s_axi_reg_awsize,
    input  wire [136:0]  s_axi_reg_awuser,
    input  wire          s_axi_reg_awvalid,
    input  wire          s_axi_reg_awready,

    input  wire [31:0]   s_axi_reg_wdata,
    input  wire          s_axi_reg_wlast,
    input  wire [3:0]    s_axi_reg_wstrb,
    input  wire          s_axi_reg_wvalid,
    input  wire          s_axi_reg_wuser,
    input  wire          s_axi_reg_wready,

    input  wire          s_axi_reg_bready,
    input  wire          s_axi_reg_bvalid,
    input  wire [1:0]    s_axi_reg_bresp,
    input  wire [1:0]    s_axi_reg_bid,
    input  wire [2:0]    s_axi_reg_buser,

    input  wire          s_axi_reg_rready,
    input  wire [31:0]   s_axi_reg_rdata,
    input  wire [0:0]    s_axi_reg_rid,
    input  wire          s_axi_reg_rlast,
    input  wire [1:0]    s_axi_reg_rresp,
    input  wire          s_axi_reg_rvalid,
    input  wire          s_axi_reg_ruser,

    //axi4_intf.S s_axi_mem
    input  wire [63:0]   s_axi_mem_araddr,
    input  wire [1:0]    s_axi_mem_arburst,
    input  wire [3:0]    s_axi_mem_arcache,
    input  wire [1:0]    s_axi_mem_arid,
    input  wire [7:0]    s_axi_mem_arlen,
    input  wire          s_axi_mem_arlock,
    input  wire [2:0]    s_axi_mem_arprot,
    input  wire [3:0]    s_axi_mem_arqos,
    input  wire [2:0]    s_axi_mem_arsize,
    input  wire [17:0]   s_axi_mem_aruser,
    input  wire          s_axi_mem_arvalid,
    input  wire          s_axi_mem_arready,

    input  wire [63:0]   s_axi_mem_awaddr,
    input  wire [1:0]    s_axi_mem_awburst,
    input  wire [3:0]    s_axi_mem_awcache,
    input  wire [1:0]    s_axi_mem_awid,
    input  wire [7:0]    s_axi_mem_awlen,
    input  wire          s_axi_mem_awlock,
    input  wire [2:0]    s_axi_mem_awprot,
    input  wire [3:0]    s_axi_mem_awqos,
    input  wire [2:0]    s_axi_mem_awsize,
    input  wire [17:0]   s_axi_mem_awuser,
    input  wire          s_axi_mem_awvalid,
    input  wire          s_axi_mem_awready,

    input  wire [127:0]  s_axi_mem_wdata,
    input  wire          s_axi_mem_wlast,
    input  wire [15:0]   s_axi_mem_wstrb,
    input  wire          s_axi_mem_wvalid,
    input  wire          s_axi_mem_wuser,
    input  wire          s_axi_mem_wready,

    input  wire          s_axi_mem_bready,
    input  wire          s_axi_mem_bvalid,
    input  wire [1:0]    s_axi_mem_bresp,
    input  wire [1:0]    s_axi_mem_bid,
    input  wire [2:0]    s_axi_mem_buser,

    input  wire          s_axi_mem_rready,
    input  wire [127:0]  s_axi_mem_rdata,
    input  wire [1:0]    s_axi_mem_rid,
    input  wire          s_axi_mem_rlast,
    input  wire [1:0]    s_axi_mem_rresp,
    input  wire          s_axi_mem_rvalid,
    input  wire          s_axi_mem_ruser,

    //Interface to HDMA -- axi4_intf.M m_axil_dbi (the DBI doorbell/context path)
    input  wire [31:0]   m_axil_dbi_araddr,
    input  wire [2:0]    m_axil_dbi_arprot,
    input  wire [15:0]   m_axil_dbi_aruser,
    input  wire          m_axil_dbi_arvalid,
    input  wire          m_axil_dbi_arready,

    input  wire [31:0]   m_axil_dbi_awaddr,
    input  wire [15:0]   m_axil_dbi_awuser,
    input  wire          m_axil_dbi_awvalid,
    input  wire          m_axil_dbi_awready,
    input  wire [2:0]    m_axil_dbi_awprot,

    input  wire [31:0]   m_axil_dbi_wdata,
    input  wire [3:0]    m_axil_dbi_wstrb,
    input  wire          m_axil_dbi_wvalid,
    input  wire [3:0]    m_axil_dbi_wuser,
    input  wire          m_axil_dbi_wready,

    input  wire          m_axil_dbi_bready,
    input  wire          m_axil_dbi_bvalid,
    input  wire [1:0]    m_axil_dbi_bresp,

    input  wire          m_axil_dbi_rready,
    input  wire [31:0]   m_axil_dbi_rdata,
    input  wire [1:0]    m_axil_dbi_rresp,
    input  wire          m_axil_dbi_rvalid,
    input  wire [3:0]    m_axil_dbi_ruser,

    // Traffic-manager descriptor status interface (gated by P_DSC_CRDT_EN)
    input  wire          tm_dsc_sts_vld,
    input  wire          tm_dsc_sts_byp,
    input  wire          tm_dsc_sts_qen,
    input  wire          tm_dsc_sts_dir,
    input  wire          tm_dsc_sts_mm,
    input  wire          tm_dsc_sts_error,
    input  wire [12:0]   tm_dsc_sts_qid,
    input  wire [15:0]   tm_dsc_sts_avl,
    input  wire [2:0]    tm_dsc_sts_port_id,
    input  wire          tm_dsc_sts_qinv,
    input  wire          tm_dsc_sts_irq_arm,
    input  wire          tm_dsc_sts_vio_dsc_crdt,
    input  wire          tm_dsc_sts_vio_en,
    input  wire [11:0]   tm_dsc_sts_func,
    input  wire [15:0]   tm_dsc_sts_pidx,
    input  wire          tm_dsc_sts_vio_hw_db,
    input  wire          tm_dsc_sts_vio_sw_db,
    input  wire          tm_dsc_sts_vio_avl_flg,
    input  wire          tm_dsc_sts_rdy,

    // Descriptor credit input interface (gated by P_DSC_CRDT_EN)
    input  wire          dsc_crdt_in_vld,
    input  wire          dsc_crdt_in_rdy,
    input  wire          dsc_crdt_in_dir,
    input  wire          dsc_crdt_in_fence,
    input  wire [10:0]   dsc_crdt_in_qid,
    input  wire [15:0]   dsc_crdt_in_crdt,

    input  wire [127:0]  hdma_irq,

    // pcie_msix master interface (gated by MSIX_EN)
    input  wire          msix_req,
    input  wire          msix_vfunc_active,
    input  wire          msix_grant,
    input  wire          msix_error,
    input  wire [1:0]    msix_operation,
    input  wire [2:0]    msix_func_num,
    input  wire [7:0]    msix_vfunc_num,
    input  wire [10:0]   msix_vector_num,

    // CPM AXI PL ports -- the actual PL0/PL1/PL2/PL3 BRAM data path.
    // NOTE: in MM mode, these ports are bound from ps_wizard, not stubbed.
    // This probe verifies activity empirically via the end-of-test
    // transaction-count summary below.
    input  wire [51:0]   cpm_axi_pl0_awaddr,
    input  wire [9:0]    cpm_axi_pl0_awid,
    input  wire [7:0]    cpm_axi_pl0_awlen,
    input  wire [2:0]    cpm_axi_pl0_awsize,
    input  wire [1:0]    cpm_axi_pl0_awburst,
    input  wire [2:0]    cpm_axi_pl0_awprot,
    input  wire [3:0]    cpm_axi_pl0_awcache,
    input  wire          cpm_axi_pl0_awlock,
    input  wire          cpm_axi_pl0_awvalid,
    input  wire          cpm_axi_pl0_awready,
    input  wire [511:0]  cpm_axi_pl0_wdata,
    input  wire [63:0]   cpm_axi_pl0_wstrb,
    input  wire          cpm_axi_pl0_wlast,
    input  wire          cpm_axi_pl0_wvalid,
    input  wire          cpm_axi_pl0_wready,
    input  wire [9:0]    cpm_axi_pl0_bid,
    input  wire [1:0]    cpm_axi_pl0_bresp,
    input  wire          cpm_axi_pl0_bvalid,
    input  wire          cpm_axi_pl0_bready,
    input  wire [51:0]   cpm_axi_pl0_araddr,
    input  wire [9:0]    cpm_axi_pl0_arid,
    input  wire [7:0]    cpm_axi_pl0_arlen,
    input  wire [2:0]    cpm_axi_pl0_arsize,
    input  wire [1:0]    cpm_axi_pl0_arburst,
    input  wire [2:0]    cpm_axi_pl0_arprot,
    input  wire [3:0]    cpm_axi_pl0_arcache,
    input  wire          cpm_axi_pl0_arlock,
    input  wire          cpm_axi_pl0_arvalid,
    input  wire          cpm_axi_pl0_arready,
    input  wire [511:0]  cpm_axi_pl0_rdata,
    input  wire [9:0]    cpm_axi_pl0_rid,
    input  wire          cpm_axi_pl0_rlast,
    input  wire [1:0]    cpm_axi_pl0_rresp,
    input  wire          cpm_axi_pl0_rvalid,
    input  wire          cpm_axi_pl0_rready,

    input  wire [51:0]   cpm_axi_pl1_awaddr,
    input  wire [9:0]    cpm_axi_pl1_awid,
    input  wire [7:0]    cpm_axi_pl1_awlen,
    input  wire [2:0]    cpm_axi_pl1_awsize,
    input  wire [1:0]    cpm_axi_pl1_awburst,
    input  wire [2:0]    cpm_axi_pl1_awprot,
    input  wire [3:0]    cpm_axi_pl1_awcache,
    input  wire          cpm_axi_pl1_awlock,
    input  wire          cpm_axi_pl1_awvalid,
    input  wire          cpm_axi_pl1_awready,
    input  wire [511:0]  cpm_axi_pl1_wdata,
    input  wire [63:0]   cpm_axi_pl1_wstrb,
    input  wire          cpm_axi_pl1_wlast,
    input  wire          cpm_axi_pl1_wvalid,
    input  wire          cpm_axi_pl1_wready,
    input  wire [9:0]    cpm_axi_pl1_bid,
    input  wire [1:0]    cpm_axi_pl1_bresp,
    input  wire          cpm_axi_pl1_bvalid,
    input  wire          cpm_axi_pl1_bready,
    input  wire [51:0]   cpm_axi_pl1_araddr,
    input  wire [9:0]    cpm_axi_pl1_arid,
    input  wire [7:0]    cpm_axi_pl1_arlen,
    input  wire [2:0]    cpm_axi_pl1_arsize,
    input  wire [1:0]    cpm_axi_pl1_arburst,
    input  wire [2:0]    cpm_axi_pl1_arprot,
    input  wire [3:0]    cpm_axi_pl1_arcache,
    input  wire          cpm_axi_pl1_arlock,
    input  wire          cpm_axi_pl1_arvalid,
    input  wire          cpm_axi_pl1_arready,
    input  wire [511:0]  cpm_axi_pl1_rdata,
    input  wire [9:0]    cpm_axi_pl1_rid,
    input  wire          cpm_axi_pl1_rlast,
    input  wire [1:0]    cpm_axi_pl1_rresp,
    input  wire          cpm_axi_pl1_rvalid,
    input  wire          cpm_axi_pl1_rready,

    input  wire [51:0]   cpm_axi_pl2_awaddr,
    input  wire [9:0]    cpm_axi_pl2_awid,
    input  wire [7:0]    cpm_axi_pl2_awlen,
    input  wire [2:0]    cpm_axi_pl2_awsize,
    input  wire [1:0]    cpm_axi_pl2_awburst,
    input  wire [2:0]    cpm_axi_pl2_awprot,
    input  wire [3:0]    cpm_axi_pl2_awcache,
    input  wire          cpm_axi_pl2_awlock,
    input  wire          cpm_axi_pl2_awvalid,
    input  wire          cpm_axi_pl2_awready,
    input  wire [511:0]  cpm_axi_pl2_wdata,
    input  wire [63:0]   cpm_axi_pl2_wstrb,
    input  wire          cpm_axi_pl2_wlast,
    input  wire          cpm_axi_pl2_wvalid,
    input  wire          cpm_axi_pl2_wready,
    input  wire [9:0]    cpm_axi_pl2_bid,
    input  wire [1:0]    cpm_axi_pl2_bresp,
    input  wire          cpm_axi_pl2_bvalid,
    input  wire          cpm_axi_pl2_bready,
    input  wire [51:0]   cpm_axi_pl2_araddr,
    input  wire [9:0]    cpm_axi_pl2_arid,
    input  wire [7:0]    cpm_axi_pl2_arlen,
    input  wire [2:0]    cpm_axi_pl2_arsize,
    input  wire [1:0]    cpm_axi_pl2_arburst,
    input  wire [2:0]    cpm_axi_pl2_arprot,
    input  wire [3:0]    cpm_axi_pl2_arcache,
    input  wire          cpm_axi_pl2_arlock,
    input  wire          cpm_axi_pl2_arvalid,
    input  wire          cpm_axi_pl2_arready,
    input  wire [511:0]  cpm_axi_pl2_rdata,
    input  wire [9:0]    cpm_axi_pl2_rid,
    input  wire          cpm_axi_pl2_rlast,
    input  wire [1:0]    cpm_axi_pl2_rresp,
    input  wire          cpm_axi_pl2_rvalid,
    input  wire          cpm_axi_pl2_rready,

    input  wire [51:0]   cpm_axi_pl3_awaddr,
    input  wire [9:0]    cpm_axi_pl3_awid,
    input  wire [7:0]    cpm_axi_pl3_awlen,
    input  wire [2:0]    cpm_axi_pl3_awsize,
    input  wire [1:0]    cpm_axi_pl3_awburst,
    input  wire [2:0]    cpm_axi_pl3_awprot,
    input  wire [3:0]    cpm_axi_pl3_awcache,
    input  wire          cpm_axi_pl3_awlock,
    input  wire          cpm_axi_pl3_awvalid,
    input  wire          cpm_axi_pl3_awready,
    input  wire [511:0]  cpm_axi_pl3_wdata,
    input  wire [63:0]   cpm_axi_pl3_wstrb,
    input  wire          cpm_axi_pl3_wlast,
    input  wire          cpm_axi_pl3_wvalid,
    input  wire          cpm_axi_pl3_wready,
    input  wire [9:0]    cpm_axi_pl3_bid,
    input  wire [1:0]    cpm_axi_pl3_bresp,
    input  wire          cpm_axi_pl3_bvalid,
    input  wire          cpm_axi_pl3_bready,
    input  wire [51:0]   cpm_axi_pl3_araddr,
    input  wire [9:0]    cpm_axi_pl3_arid,
    input  wire [7:0]    cpm_axi_pl3_arlen,
    input  wire [2:0]    cpm_axi_pl3_arsize,
    input  wire [1:0]    cpm_axi_pl3_arburst,
    input  wire [2:0]    cpm_axi_pl3_arprot,
    input  wire [3:0]    cpm_axi_pl3_arcache,
    input  wire          cpm_axi_pl3_arlock,
    input  wire          cpm_axi_pl3_arvalid,
    input  wire          cpm_axi_pl3_arready,
    input  wire [511:0]  cpm_axi_pl3_rdata,
    input  wire [9:0]    cpm_axi_pl3_rid,
    input  wire          cpm_axi_pl3_rlast,
    input  wire [1:0]    cpm_axi_pl3_rresp,
    input  wire          cpm_axi_pl3_rvalid,
    input  wire          cpm_axi_pl3_rready,

    //Global signals
    input  wire          axi_aclk,
    input  wire          axi_aresetn
);

  // Confirmed against this build's BD IP parameters -- see header comment.
  localparam bit DMA_ST_LOCAL         = 1'b0;
  localparam bit MSIX_EN_LOCAL        = 1'b1;
  localparam bit P_DSC_CRDT_EN_LOCAL  = 1'b1;

  int log_fd;

  // Per-port transaction counters (the "is this interface enabled" evidence
  // for cpm_axi_pl0-3 / s_axi_mem, which have no static enable parameter).
  int cnt_pl0_aw, cnt_pl0_w, cnt_pl0_b, cnt_pl0_ar, cnt_pl0_r;
  int cnt_pl1_aw, cnt_pl1_w, cnt_pl1_b, cnt_pl1_ar, cnt_pl1_r;
  int cnt_pl2_aw, cnt_pl2_w, cnt_pl2_b, cnt_pl2_ar, cnt_pl2_r;
  int cnt_pl3_aw, cnt_pl3_w, cnt_pl3_b, cnt_pl3_ar, cnt_pl3_r;
  int cnt_mem_aw, cnt_mem_w, cnt_mem_b, cnt_mem_ar, cnt_mem_r;
  int cnt_dbi_aw, cnt_dbi_w, cnt_dbi_ar;
  int cnt_tm_dsc_sts_vld;

  initial begin
    log_fd = $fopen("qdma_boundary_probe.log", "w");
    $fdisplay(log_fd, "# qdma_boundary_probe -- full cpm6_qdma_0 IP interface boundary log");
    $fdisplay(log_fd, "# DMA_ST=%0d MSIX_EN=%0d P_DSC_CRDT_EN=%0d (hardcoded, confirmed against BD IP params -- see file header)",
              DMA_ST_LOCAL, MSIX_EN_LOCAL, P_DSC_CRDT_EN_LOCAL);
    if (!DMA_ST_LOCAL)
      $fdisplay(log_fd, "# H2C/C2H streaming + completion ports (h2c_st_port*/c2h_st_port*/c2h_cmpt_port*) NOT logged -- DMA_ST=0, provably inactive (generate-gated in the IP)");
    $fdisplay(log_fd, "#");
  end

  // ---- m_axil_dbi: the DBI doorbell/context write path ----
  always @(posedge axi_aclk) begin
    if (axi_aresetn) begin
      if (m_axil_dbi_awvalid && m_axil_dbi_awready) begin
        cnt_dbi_aw++;
        $fdisplay(log_fd, "%0t DBI_AW  addr=0x%08h user=0x%04h", $time, m_axil_dbi_awaddr, m_axil_dbi_awuser);
      end
      if (m_axil_dbi_wvalid && m_axil_dbi_wready) begin
        cnt_dbi_w++;
        $fdisplay(log_fd, "%0t DBI_W   data=0x%08h strb=0x%01h", $time, m_axil_dbi_wdata, m_axil_dbi_wstrb);
      end
      if (m_axil_dbi_arvalid && m_axil_dbi_arready) begin
        cnt_dbi_ar++;
        $fdisplay(log_fd, "%0t DBI_AR  addr=0x%08h user=0x%04h", $time, m_axil_dbi_araddr, m_axil_dbi_aruser);
      end
    end
  end

  // ---- cpm_axi_pl0..3: the actual H2C/C2H BRAM data path ----
  `define PL_LOG(N) \
    always @(posedge axi_aclk) begin \
      if (axi_aresetn) begin \
        if (cpm_axi_pl``N``_awvalid && cpm_axi_pl``N``_awready) begin \
          cnt_pl``N``_aw++; \
          $fdisplay(log_fd, "%0t PL``N``_AW addr=0x%013h id=%0d len=%0d", $time, cpm_axi_pl``N``_awaddr, cpm_axi_pl``N``_awid, cpm_axi_pl``N``_awlen); \
        end \
        if (cpm_axi_pl``N``_wvalid && cpm_axi_pl``N``_wready) begin \
          cnt_pl``N``_w++; \
        end \
        if (cpm_axi_pl``N``_bvalid && cpm_axi_pl``N``_bready) begin \
          cnt_pl``N``_b++; \
          $fdisplay(log_fd, "%0t PL``N``_B  id=%0d resp=%0d", $time, cpm_axi_pl``N``_bid, cpm_axi_pl``N``_bresp); \
        end \
        if (cpm_axi_pl``N``_arvalid && cpm_axi_pl``N``_arready) begin \
          cnt_pl``N``_ar++; \
          $fdisplay(log_fd, "%0t PL``N``_AR addr=0x%013h id=%0d len=%0d", $time, cpm_axi_pl``N``_araddr, cpm_axi_pl``N``_arid, cpm_axi_pl``N``_arlen); \
        end \
        if (cpm_axi_pl``N``_rvalid && cpm_axi_pl``N``_rready) begin \
          cnt_pl``N``_r++; \
        end \
      end \
    end

  `PL_LOG(0)
  `PL_LOG(1)
  `PL_LOG(2)
  `PL_LOG(3)
  `undef PL_LOG

  // ---- s_axi_mem: real, actively-mapped 64KB interface per the BD (S_AXI_MEM memory_map) ----
  always @(posedge axi_aclk) begin
    if (axi_aresetn) begin
      if (s_axi_mem_awvalid && s_axi_mem_awready) begin
        cnt_mem_aw++;
        $fdisplay(log_fd, "%0t MEM_AW addr=0x%016h id=%0d len=%0d", $time, s_axi_mem_awaddr, s_axi_mem_awid, s_axi_mem_awlen);
      end
      if (s_axi_mem_wvalid && s_axi_mem_wready) cnt_mem_w++;
      if (s_axi_mem_bvalid && s_axi_mem_bready) cnt_mem_b++;
      if (s_axi_mem_arvalid && s_axi_mem_arready) begin
        cnt_mem_ar++;
        $fdisplay(log_fd, "%0t MEM_AR addr=0x%016h id=%0d len=%0d", $time, s_axi_mem_araddr, s_axi_mem_arid, s_axi_mem_arlen);
      end
      if (s_axi_mem_rvalid && s_axi_mem_rready) cnt_mem_r++;
    end
  end

  // ---- tm_dsc_sts: traffic-manager per-descriptor status (gated by P_DSC_CRDT_EN) ----
  always @(posedge axi_aclk) begin
    if (axi_aresetn && P_DSC_CRDT_EN_LOCAL) begin
      if (tm_dsc_sts_vld && tm_dsc_sts_rdy) begin
        cnt_tm_dsc_sts_vld++;
        $fdisplay(log_fd,
          "%0t TM_DSC_STS qid=%0d dir=%s func=%0d pidx=%0d avl=%0d port_id=%0d byp=%0d qen=%0d mm=%0d error=%0d qinv=%0d irq_arm=%0d vio_dsc_crdt=%0d vio_en=%0d vio_hw_db=%0d vio_sw_db=%0d vio_avl_flg=%0d",
          $time, tm_dsc_sts_qid, tm_dsc_sts_dir ? "C2H" : "H2C", tm_dsc_sts_func, tm_dsc_sts_pidx,
          tm_dsc_sts_avl, tm_dsc_sts_port_id, tm_dsc_sts_byp, tm_dsc_sts_qen, tm_dsc_sts_mm,
          tm_dsc_sts_error, tm_dsc_sts_qinv, tm_dsc_sts_irq_arm, tm_dsc_sts_vio_dsc_crdt,
          tm_dsc_sts_vio_en, tm_dsc_sts_vio_hw_db, tm_dsc_sts_vio_sw_db, tm_dsc_sts_vio_avl_flg);
      end
    end
  end

  final begin
    $fdisplay(log_fd, "#");
    $fdisplay(log_fd, "# ===== END-OF-TEST TRANSACTION-COUNT SUMMARY =====");
    $fdisplay(log_fd, "# (answers \"was this interface ever exercised\" directly from observed data,");
    $fdisplay(log_fd, "#  not from the rfs header comments, which are confirmed unreliable for cpm_axi_pl0-3)");
    $fdisplay(log_fd, "# s_axi_mem : AW=%0d W=%0d B=%0d AR=%0d R=%0d", cnt_mem_aw, cnt_mem_w, cnt_mem_b, cnt_mem_ar, cnt_mem_r);
    $fdisplay(log_fd, "# m_axil_dbi: AW=%0d W=%0d AR=%0d", cnt_dbi_aw, cnt_dbi_w, cnt_dbi_ar);
    $fdisplay(log_fd, "# cpm_axi_pl0: AW=%0d W=%0d B=%0d AR=%0d R=%0d", cnt_pl0_aw, cnt_pl0_w, cnt_pl0_b, cnt_pl0_ar, cnt_pl0_r);
    $fdisplay(log_fd, "# cpm_axi_pl1: AW=%0d W=%0d B=%0d AR=%0d R=%0d", cnt_pl1_aw, cnt_pl1_w, cnt_pl1_b, cnt_pl1_ar, cnt_pl1_r);
    $fdisplay(log_fd, "# cpm_axi_pl2: AW=%0d W=%0d B=%0d AR=%0d R=%0d", cnt_pl2_aw, cnt_pl2_w, cnt_pl2_b, cnt_pl2_ar, cnt_pl2_r);
    $fdisplay(log_fd, "# cpm_axi_pl3: AW=%0d W=%0d B=%0d AR=%0d R=%0d", cnt_pl3_aw, cnt_pl3_w, cnt_pl3_b, cnt_pl3_ar, cnt_pl3_r);
    $fdisplay(log_fd, "# tm_dsc_sts : vld_fires=%0d", cnt_tm_dsc_sts_vld);
    $fclose(log_fd);
  end

endmodule : qdma_boundary_probe
`default_nettype none

bind cpm6_qdma_v1_0_0_top_wrapper qdma_boundary_probe qdma_boundary_probe_inst (.*);
