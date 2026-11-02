class rsp_share extends base_share;

  `uvm_object_utils(rsp_share)

  bit [7:0] credit_cnt_ded[1:0][15:0]; //dedicated credits; per [protocol] and [VC-ID]
  bit [7:0] credit_cnt_shr;            //shared credits

  global_share gshr; //handle assigned by parent agent (cpi_agent)

  function new(string name = "rsp_share");
    super.new(name);
  endfunction 

endclass
