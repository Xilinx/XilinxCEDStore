// qdma_periph_tm_dsc_if.sv — Portless SV interface for tm_dsc_sts observation
//
// tm_dsc_sts is a real cpm6_qdma_v1_0_0_top_wrapper port (traffic-manager descriptor
// status), but it is internal to cpm6_qdma_0 — not exposed at design_1 wire scope
// (confirmed: bind.qdma_periph.sv's own header note, and design_1.v only carries the
// tied-constant tm_dsc_sts_rdy). Reaching it requires binding directly to the
// cpm6_qdma_v1_0_0_top_wrapper module type, hence a SEPARATE interface + bind file
// from qdma_periph_if.sv (which is design_1-scoped) rather than adding fields to it.
//
// Field set mirrors this CED's qdma_boundary_probe TM_DSC_STS capture
// for log-format consistency.

interface qdma_periph_tm_dsc_if ();

   logic         clk;
   logic         rst_n;

   logic         tm_dsc_sts_vld;
   logic         tm_dsc_sts_byp;
   logic         tm_dsc_sts_qen;
   logic         tm_dsc_sts_dir;
   logic         tm_dsc_sts_mm;
   logic         tm_dsc_sts_error;
   logic [12:0]  tm_dsc_sts_qid;
   logic [15:0]  tm_dsc_sts_avl;
   logic [2:0]   tm_dsc_sts_port_id;
   logic         tm_dsc_sts_qinv;
   logic         tm_dsc_sts_irq_arm;
   logic         tm_dsc_sts_vio_dsc_crdt;
   logic         tm_dsc_sts_vio_en;
   logic [11:0]  tm_dsc_sts_func;
   logic [15:0]  tm_dsc_sts_pidx;
   logic         tm_dsc_sts_vio_hw_db;
   logic         tm_dsc_sts_vio_sw_db;
   logic         tm_dsc_sts_vio_avl_flg;
   logic         tm_dsc_sts_rdy;

endinterface
