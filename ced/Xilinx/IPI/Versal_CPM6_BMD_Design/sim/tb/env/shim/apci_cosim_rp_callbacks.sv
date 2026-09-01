class apci_cosim_rp_callbacks extends apci_callbacks;

  apci_device bfm_handle;
  string sckey;

  function new(apci_device bfm_handle, string key="");
    this.bfm_handle = bfm_handle;
    this.sckey = key;
  endfunction

  virtual function void tx_pkt_exit_tl(
      apci_device   bfm,
      apci_tlp      tlp
  );
    tlp_bookkept(tlp);
  endfunction

  virtual function void rx_pkt_enter_tl(
    apci_device   bfm,
    apci_tlp      tlp
  );
    dma_bookkept(tlp, this.sckey);
  endfunction

  virtual function void write_mem_cb(
      input bit             is_host_mem,
      input bit[63:0]       addr       ,
      input bit[3:0]        first_be   ,
      input bit[3:0]        last_be    ,
      ref   bit[31:0]       va[]       ,
      input avery_data_base src
  );
    if (is_host_mem)
      dma_bookcheck(addr, first_be, last_be, sckey, va);
  endfunction

endclass
