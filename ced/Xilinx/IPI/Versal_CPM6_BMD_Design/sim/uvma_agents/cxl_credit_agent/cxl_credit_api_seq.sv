class cxl_credit_api_seq extends uvm_sequence#(cxl_credit_bus_txn);

  `uvm_object_utils(cxl_credit_api_seq)

  function new(string name = "cxl_credit_api_seq");
    super.new(name);
  endfunction

  // If both cache and mem credits need to be returned, randomly choose which to send 
  rand bit proto_req;
  rand bit proto_dat;
  rand bit proto_rsp;

  int unsigned cch_req = 0, mem_req = 0;
  int unsigned cch_dat = 0, mem_dat = 0;
  int unsigned cch_rsp = 0, mem_rsp = 0;

  virtual task body;
    cxl_credit_bus_txn t = cxl_credit_bus_txn::type_id::create("t");
    t.vld = 1'b1;
    while ((cch_req+cch_dat+cch_rsp+mem_req+mem_dat+mem_rsp) != '0) begin 
      start_item(t);
      void'(this.randomize);
      if (!proto_req) begin
        t.req = {1'b0, t.convert2enc(cch_req)};
        cch_req -= t.convert2dec(t.req[2:0]);
      end
      else begin
        t.req = {1'b1, t.convert2enc(mem_req)};
        mem_req -= t.convert2dec(t.req[2:0]);
      end
      if (!proto_dat) begin
        t.dat = {1'b0, t.convert2enc(cch_dat)};
        cch_dat -= t.convert2dec(t.dat[2:0]);
      end
      else begin
        t.dat = {1'b1, t.convert2enc(mem_dat)};
        mem_dat -= t.convert2dec(t.dat[2:0]);
      end
      if (!proto_rsp) begin
        t.rsp = {1'b0, t.convert2enc(cch_rsp)};
        cch_rsp -= t.convert2dec(t.rsp[2:0]);
      end
      else begin
        t.rsp = {1'b1, t.convert2enc(mem_rsp)};
        mem_rsp -= t.convert2dec(t.rsp[2:0]);
      end
      // Send it
      finish_item(t);  
    end
  endtask

  constraint constr_proto {
    if (!cch_req && mem_req)      { proto_req == 1'b1; } 
    else if (cch_req && !mem_req) { proto_req == 1'b0; }
    if (!cch_dat && mem_dat)      { proto_dat == 1'b1; } 
    else if (cch_dat && !mem_dat) { proto_dat == 1'b0; }
    if (!cch_rsp && mem_rsp)      { proto_rsp == 1'b1; } 
    else if (cch_rsp && !mem_rsp) { proto_rsp == 1'b0; }
  } 

endclass
