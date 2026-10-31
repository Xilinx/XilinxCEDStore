class data_cfg extends base_cfg;

  `uvm_object_utils(data_cfg)

  bit           a2f;
  port_t        port;
  bit           cxl_mem_sup;     //"sup" = supported
  bit           cxl_cch_sup;     //"sup" = supported
  bit           cxl_mem_emd_sup; //"sup" = supported
  bit [1:0]     blocking;
  bit           pbr_flit_mode_en;
  bit           flit_mode_enc_en; 
  bit           ide_epoch_support;
  generic_ctl_t crd_ret_ctl;

  // DATA specific
  bit [2:0] data_hdr_sep;
  bit       data_cmd_parity_en;
  bit       data_be_parity_en;
  bit       txfer_32b_en;
  bit       mem_dathdr_split;

  // Not part of CPI spec, but we need some way to test this
  int       emd_bits; 

  // Only relevant to "active Slave" configurations
  bit       skip_credit_returns;
  bit [7:0] init_credit_ded[1:0][15:0]; //dedicated credits; per [protocol] (0:CXL.cache, 1:CXL.mem) and [VC-ID]  
  bit [7:0] init_credit_shr;            //shared credits

  // Only relevant to "master" configurations
  bit       skip_credit_check; 

  function new(string name = "data_cfg");
    super.new(name);
  endfunction

endclass
