class global_share extends base_share;

  `uvm_object_utils(global_share)

  conn_state_t conn_state = DISCONNECTED; 

  // For generating rx_empty when cnt==mark across all channels
  int unsigned total_credits_mark_req;
  int unsigned total_credits_cnt_req;
  int unsigned total_credits_mark_rsp;
  int unsigned total_credits_cnt_rsp;
  int unsigned total_credits_mark_data;
  int unsigned total_credits_cnt_data;

  function new(string name = "global_share");
    super.new(name);
  endfunction

endclass
