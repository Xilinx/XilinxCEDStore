// This callback class for CXL transactions does two things to control
// and shape responses.
// 1. When the CXL link operates in 68B flit mode, the link layer allows for
//    a single transaction to be split into two chunks. This is supported for
//    H2D Data, D2H Data, and S2M DRS channels. This callback explicitly disables 
//    that feature. 
// 2. The VIP responds with 0 latency by default, so this randomizes some
//    response latency to show out of order responses are handled properly.
class cxl_rsp_handler_cb extends acxl_callbacks;

  virtual function void rx_cxl_msg_enter_tl(input apci_device bfm, input acxl_msg msg);
    // 1.
    msg.user_ctrl.data_32B = 1'b0;
    // 2. 
    msg.user_ctrl.rspData_delay_ns = $urandom_range(1,40);
    msg.user_ctrl.rsp_delay_ns     = $urandom_range(1,40);
  endfunction

endclass
