class cxl_basic_responder#(int NFI_W = 3) extends uvm_component;

  `uvm_component_param_utils(cxl_basic_responder#(NFI_W))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = $sformatf("cxl_basic_responder#(%0d)",NFI_W);
  virtual function string get_type_name(); return type_name; endfunction

  bit en = 1;
  bit en_2b_md = 1;

  // FIFO to handle initiator txns in order
  uvm_tlm_analysis_fifo#(base_txn) fifo;

  // API(s) allow this component to drive responses back 
  // on the CXL link. Parent must assign handle(s).
  flit68_api #(cxl_nfi_sequencer#(NFI_W), NFI_W) api68;
  flit256_api#(cxl_nfi_sequencer#(NFI_W), NFI_W) api256;
 
  rand time rsp_dly;
       time rsp_dly_min = 100ns;
       time rsp_dly_max = 400ns;

  typedef bit [51:6] cxl_fcl_t; //fcl = "full cache line"

  // Create a memory to store data
  bit [15:0][31:0] mem[cxl_fcl_t];
  bit       [ 1:0] md [cxl_fcl_t]; //2 bit metavalue
  bit       [31:0] emd[cxl_fcl_t]; //<=32 bit extended metadata (>=CXL3)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    fifo = new("fifo", this);
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    if (en) begin
      if (api68==null && api256==null)
        `uvm_fatal(get_type_name, "All API handles are null; parent must assign at least one")
      case ({api68==null, api256==null}) 
        2'b10 : `uvm_info(get_type_name, "Responder component for CXL agent has API for F68 flits", UVM_LOW)
        2'b01 : `uvm_info(get_type_name, "Responder component for CXL agent has API for F256 flits", UVM_LOW)
        2'b11 : `uvm_info(get_type_name, "Responder component for CXL agent has APIs for F68/F256 flits", UVM_LOW)
      endcase
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    string     msg;
    base_txn   txn;
    m2sreq_c   m2sreq;
    m2srwd_c   m2srwd;
    s2mndr_c   s2mndr; 
    s2mdrs_c   s2mdrs; 
    forever begin
      // Get the initiator txn
      fifo.get(txn);
      // Randomize a response delay
      if (en) begin
        void'(this.randomize with { rsp_dly inside {[rsp_dly_min:rsp_dly_max]}; });
        msg = $sformatf("Received a %0s txn; rsp delay was randomized to %t", txn.txn_type, rsp_dly);
        `uvm_info(get_type_name, msg, UVM_LOW)
        #rsp_dly;
      end
      else begin
        msg = $sformatf("Received a %0s txn; 'en' member unset so not sending response", txn.txn_type);
        `uvm_info(get_type_name, msg, UVM_LOW)
        #1;
        continue;
      end
      // Handle the initiator txn and build a response; in order
      case (1'b1)
        $cast(m2sreq, txn) :
        if (m2sreq.flitmode==F68) begin
          // Corner Case if MemInv/MemInvNT, an NDR Cmp Response is sent
          if(m2sreq.req68.memop inside {MemInv, MemInvNT}) begin
            // Build Response
            s2mndr = s2mndr_c::type_id::create("s2mndr");
            // -- Txn --
            s2mndr.ndr68.opcode    = Cmp; 
            s2mndr.ndr68.metafield = NoOp; 
            s2mndr.ndr68.metavalue = mem_metavalue_t'(2'b00); //Metafield==NoOp->Metavalue=2'b00
            s2mndr.ndr68.devload   = mem_devload_t'(2'($urandom_range(0,1))); //Light or Optimal
            s2mndr.ndr68.ldid      = '0;
            s2mndr.ndr68.tag       = m2sreq.req68.tag; 
            // Send it
            api68.issue_msg(s2mndr);
          end else begin
            // Build Response
            s2mdrs = s2mdrs_c::type_id::create("s2mdrs");
            // -- Txn --
            case(m2sreq.req68.memop)
              MemRd,MemRdData : s2mdrs.hdr68.opcode = MemData;
              default         : `uvm_fatal(get_type_name, $sformatf("m2sreq.flitmode=%0s memop=%0s not written yet",m2sreq.flitmode.name,m2sreq.req68.memop.name))
            endcase
            s2mdrs.hdr68.metafield = mem_metafield_t'(en_2b_md ? Meta0State                  : NoOp); 
            s2mdrs.hdr68.metavalue = mem_metavalue_t'(en_2b_md ? md[m2sreq.req68.addr[51:6]] : 2'b00);
            s2mdrs.hdr68.devload   = mem_devload_t'(2'($urandom_range(0,2))); //Light, Optimal, Moderate
            s2mdrs.hdr68.ldid      = '0;
            s2mdrs.hdr68.poi       = '0;
            s2mdrs.hdr68.tag       = m2sreq.req68.tag; 
            // -- Data --
            s2mdrs.txfer_64B = 1;
            s2mdrs.dat = mem[m2sreq.req68.addr[51:6]];
            // Send it
            api68.issue_msg(s2mdrs);
          end
        end    
        /* F256 */
        else if (m2sreq.flitmode==F256) begin
          // Corner Case if MemInv/MemInvNT, an NDR Cmp Response is sent
          if(m2sreq.req256.memop inside {MemInv, MemInvNT}) begin
            // Build Response
            s2mndr = s2mndr_c::type_id::create("s2mndr");
            // -- Txn --
            s2mndr.ndr256.opcode    = Cmp; 
            s2mndr.ndr256.metafield = NoOp; 
            s2mndr.ndr256.metavalue = mem_metavalue_t'(2'b00); //Metafield==NoOp->Metavalue=2'b00
            s2mndr.ndr256.devload   = mem_devload_t'(2'($urandom_range(0,1))); //Light or Optimal
            s2mndr.ndr256.ldid      = '0;
            s2mndr.ndr256.tag       = m2sreq.req256.tag; 
            // Send it
            api256.issue_msg(s2mndr);
          end else begin
            // Build Response
            s2mdrs = s2mdrs_c::type_id::create("s2mdrs");
            // -- Txn --
            if (m2sreq.req256.metafield==NoOp) begin
              s2mdrs.hdr256.metafield = NoOp;
              s2mdrs.hdr256.metavalue = mem_metavalue_t'(2'b00);
            end
            else if (m2sreq.req256.metafield==ExtMetaState) begin
              s2mdrs.hdr256.metafield = ExtMetaState;
              s2mdrs.hdr256.metavalue = mem_metavalue_t'(2'b00);
            end
            else if (m2sreq.req256.metafield==Meta0State && en_2b_md) begin
              s2mdrs.hdr256.metafield = Meta0State;
              s2mdrs.hdr256.metavalue = mem_metavalue_t'(md[m2sreq.req256.addr[51:6]]);
            end
            else begin
              s2mdrs.hdr256.metafield = NoOp;
              s2mdrs.hdr256.metavalue = mem_metavalue_t'(2'b00);
            end
            case(m2sreq.req256.memop)
              MemRd,MemRdData       : s2mdrs.hdr256.opcode = MemData;
              MemRdTEE,MemRdDataTEE : s2mdrs.hdr256.opcode = MemDataTEE;
              default               : `uvm_fatal(get_type_name, $sformatf("m2sreq.flitmode=%0s memop=%0s not written yet",m2sreq.flitmode.name,m2sreq.req256.memop.name))
            endcase
            //s2mdrs.hdr256.opcode  = MemData;
            s2mdrs.hdr256.devload = mem_devload_t'(2'($urandom_range(0,2))); //Light, Optimal, Moderate
            s2mdrs.hdr256.ldid    = '0;
            s2mdrs.hdr256.poi     = '0;
            s2mdrs.hdr256.tag     = m2sreq.req256.tag; 
            // -- Data --
            s2mdrs.dat = mem[m2sreq.req256.addr[51:6]];
            // Send it
            api256.issue_msg(s2mdrs);
          end
        end    
        /* F256_LOPT, FPBR, etc. */
        else begin
          `uvm_fatal(get_type_name, $sformatf("m2sreq.flitmode=%0s not written yet",m2sreq.flitmode.name))
        end    
        $cast(m2srwd, txn) :
        /* F68 */
        if (m2srwd.flitmode==F68) begin
          // Update Metadata
          md[m2srwd.hdr68.addr[51:6]] = m2srwd.hdr68.metavalue;
          // Full Cacheline Write
          if (m2srwd.hdr68.memop==MemWrMem) begin
            mem[m2srwd.hdr68.addr[51:6]] = m2srwd.dat;
          end
          // Partial Write
          else if (m2srwd.hdr68.memop==MemWrPtl) begin
            for (int ii=0; ii<64; ii++) begin
              mem[m2srwd.hdr68.addr[51:6]]
                [ii/4][(ii%4)*8+:8] = m2srwd.dat[ii*8+:8]&{8{m2srwd.be[ii]}};
            end
          end
          // Other
          else begin
            `uvm_fatal(get_type_name, $sformatf("m2srwd.hdr68.memop=%0s not written yet",m2srwd.hdr68.memop.name))
          end
          // Build Response
          s2mndr = s2mndr_c::type_id::create("s2mndr");
          // -- Txn --
          s2mndr.ndr68.opcode    = Cmp; 
          s2mndr.ndr68.metafield = NoOp; 
          s2mndr.ndr68.metavalue = mem_metavalue_t'(2'b00); //Metafield==NoOp->Metavalue=2'b00
          s2mndr.ndr68.devload   = mem_devload_t'(2'($urandom_range(0,1))); //Light or Optimal
          s2mndr.ndr68.ldid      = '0;
          s2mndr.ndr68.tag       = m2srwd.hdr68.tag; 
          // Send it
          api68.issue_msg(s2mndr);
        end    
        /* F256 */
        else if (m2srwd.flitmode==F256) begin
          // Update Extended Metadata
          if (m2srwd.hdr256.metafield==ExtMetaState)
            emd[m2srwd.hdr256.addr[51:6]] = m2srwd.emd;
          // Full Cacheline Write
          if (m2srwd.hdr256.memop==MemWrMem) begin
            mem[m2srwd.hdr256.addr[51:6]] = m2srwd.dat;
          end
          // Partial Write
          else if (m2srwd.hdr256.memop==MemWrPtl) begin
            for (int ii=0; ii<64; ii++) begin
              mem[m2srwd.hdr256.addr[51:6]]
                [ii/4][(ii%4)*8+:8] = m2srwd.dat[ii*8+:8]&{8{m2srwd.be[ii]}};
            end
          end
          // Other
          else begin
            `uvm_fatal(get_type_name, $sformatf("m2srwd.hdr256.memop=%0s not written yet",m2srwd.hdr256.memop.name))
          end
          // Build Response
          s2mndr = s2mndr_c::type_id::create("s2mndr");
          // -- Txn --
          s2mndr.ndr256.opcode    = Cmp; 
          s2mndr.ndr256.metafield = NoOp; 
          s2mndr.ndr256.metavalue = mem_metavalue_t'(2'b00); //Metafield==NoOp->Metavalue=2'b00
          s2mndr.ndr256.devload   = mem_devload_t'(2'($urandom_range(0,1))); //Light or Optimal
          s2mndr.ndr256.ldid      = '0;
          s2mndr.ndr256.tag       = m2srwd.hdr256.tag; 
          // Send it
          api256.issue_msg(s2mndr);
        end    
        /* F256_LOPT, FPBR, etc. */
        else begin
          `uvm_fatal(get_type_name, $sformatf("m2srwd.flitmode=%0s not written yet",m2srwd.flitmode.name))
        end    
      endcase
    end
  endtask
 
endclass
