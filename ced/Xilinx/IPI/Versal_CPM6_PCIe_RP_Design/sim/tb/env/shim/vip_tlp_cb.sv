
class vip_tlp_cb extends apci_callbacks;

  uvm_analysis_port#(apci_tlp) apci_tlp_wr_rd_req;

  function new(string name = "vip_tlp_cb");
    apci_tlp_wr_rd_req = new("apci_tlp_wr_rd_req", null);
  endfunction

  virtual function void rx_pkt_enter_tl(input apci_device bfm, input apci_tlp tlp);
    apci_tlp_wr_rd_req.write(tlp);
  endfunction

  virtual function void tx_pkt_exit_tl(input apci_device bfm, input apci_tlp tlp);
    apci_tlp_wr_rd_req.write(tlp);
  endfunction

endclass
