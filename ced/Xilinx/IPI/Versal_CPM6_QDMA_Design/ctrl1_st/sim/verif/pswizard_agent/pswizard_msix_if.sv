// pswizard_msix_if.sv - MSI-X control-FSM observation interface
//
// Not bound in this testbench. Compiled because pswizard_monitor declares a
// virtual pswizard_msix_if member (see pkg.pswizard_agent.sv).
`ifndef __PSWIZARD_MSIX_IF_SV__
`define __PSWIZARD_MSIX_IF_SV__

interface pswizard_msix_if;

   logic         clk;
   logic         rst_n;

   // --- Requester side, sampled combinationally ---
   logic         user_req;
   logic         user_grant;
   logic         user_error;
   logic [2:0]   user_func_num;
   logic [7:0]   user_vfunc_num;
   logic [10:0]  user_vector_num;
   logic         user_vfunc_active;
   logic [1:0]   user_operation;

   // --- The enable lookup itself ---
   logic [15:0]  msix_user_vf_index;
   logic         user_function_is_enabled;
   logic [255:0] msix_vf_msix_enable;
   logic [7:0]   msix_pf_msix_enable;
   logic [2:0]   ctrl_state;

endinterface : pswizard_msix_if

`endif // __PSWIZARD_MSIX_IF_SV__
