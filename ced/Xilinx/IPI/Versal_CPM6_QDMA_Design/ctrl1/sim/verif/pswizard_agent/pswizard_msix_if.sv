// pswizard_msix_if.sv - MSI-X control-FSM observation interface
//
// Exposes the enable-lookup path inside the CPM6 MSI-X controller
// (`CPM6_MSIX_CTRL) so the VF-index computation is readable from
// cpm6_qdma_dbg.log rather than only from a waveform.
//
// Why this exists: the VF-index skew fixed 2026-08-21 changed
// msix_user_vf_index, and that net appeared in NO log anywhere. It could only
// be read by converting an FSDB captured with FSDB_SECIP=2. That made two
// distinct outcomes indistinguishable from a log -- "the fix is compiled in
// and worked" versus "the patched rfs was never compiled" -- because both
// leave MSI-X errors in place. Publishing the index closes that gap.
//
// Widths are deliberately over-provisioned relative to the RTL nets, which are
// sized from the NUM_VFS/NUM_PFS parameters of the bound instance. Port
// connection zero-extends the narrower actual, so one interface serves every
// configuration; the bind does not need to know the parameter values.
`ifndef __PSWIZARD_MSIX_IF_SV__
`define __PSWIZARD_MSIX_IF_SV__

interface pswizard_msix_if;

   logic         clk;
   logic         rst_n;

   // --- Requester side (msix_user_if_i), sampled combinationally ---
   logic         user_req;
   logic         user_grant;
   logic         user_error;
   logic [2:0]   user_func_num;
   logic [7:0]   user_vfunc_num;
   logic [10:0]  user_vector_num;
   logic         user_vfunc_active;
   logic [1:0]   user_operation;

   // --- The enable lookup itself ---
   // msix_user_vf_index is THE signal the 2026-08-21 fix changed. Everything
   // else here is context for interpreting it.
   logic [15:0]  msix_user_vf_index;
   logic         user_function_is_enabled;
   logic [255:0] msix_vf_msix_enable;
   logic [7:0]   msix_pf_msix_enable;
   logic [2:0]   ctrl_state;

endinterface : pswizard_msix_if

`endif // __PSWIZARD_MSIX_IF_SV__
