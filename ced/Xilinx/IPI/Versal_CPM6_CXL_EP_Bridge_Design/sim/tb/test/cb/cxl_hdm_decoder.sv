// Callback for the HDM Decoder capability
class cxl_hdm_decoder_cb extends elbi_callback;

  `uvm_object_utils(cxl_hdm_decoder_cb)

  function new(string name = "cxl_hdm_decoder_cb");
    super.new(name);
  endfunction

  elbi_agent agnt[0:1];

  bit decoder[0:1][$:8]; //presence indicates a decoder, set to 1 when committed

  virtual function void enter_cb(elbi_txn t);
    bit id          = (t.uid=="ELBI[1]"); //controller
    bit [15:0] base = 'h1200;
    bit [15:0] offset;
    int        decn; //"decoder n"
    // When "commit" is set, set "committed"
    if (t.lbc_ext_cxl_mbar0_access   &&       //MBAR0
        t.lbc_ext_wr[1] && t.lbc_ext_dout[9]) //[9] = "Commit"
    begin 
      offset  = t.lbc_ext_addr[15:0]-base;
      decn    = (offset/'h20)-1;
      if ((decn>=0) && (decn<decoder[id].size) && !(offset%'h20)) begin
        `uvm_info(get_type_name, $sformatf("Setting 'committed' field for Decoder %0d of Controller %0d",decn,id), UVM_LOW)
        decoder[id][decn] = 1;
        // Add some delay to ensure ELBI writes don't write over this value
        fork
          begin
            wait(agnt[id].shr.mbar[0][t.lbc_ext_addr][9]);
            #1;
            agnt[id].shr.mbar[0][t.lbc_ext_addr][10] = 1'b1;
          end
        join_none
      end
    end
  endfunction

  // Adds a single decoder to track 
  virtual function void add_decoder(bit controller);
    decoder[controller].push_back(1'b0);
  endfunction
 
endclass
