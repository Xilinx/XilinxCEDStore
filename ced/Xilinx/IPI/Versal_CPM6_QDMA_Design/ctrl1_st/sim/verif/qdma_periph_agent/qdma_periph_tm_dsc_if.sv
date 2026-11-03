// qdma_periph_tm_dsc_if.sv — Portless SV interface for tm_dsc_sts observation
//
// tm_dsc_sts (traffic-manager descriptor status) is not exposed at the BD wire
// scope (the BD carries only the tied-constant tm_dsc_sts_rdy), so it has its
// own interface rather than fields in qdma_periph_if.sv.
//
// Field set mirrors the qdma_boundary_probe TM_DSC_STS capture for log-format
// consistency.

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
   logic [11:0]  tm_dsc_sts_func;
   logic [15:0]  tm_dsc_sts_pidx;
   logic         tm_dsc_sts_rdy;

endinterface
