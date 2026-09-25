// All CXL.cache transactions are included in this file
// _c = "class"
class h2dreq_c extends base_txn;

  `uvm_object_utils(h2dreq_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone 
  // this allows me to do a sort of "partial" copy fo the req
  bit copy_over_x_only = 1'b1; 

         h2dreq68_t req68 = 'x;        h2dreq256_t req256 = 'x;
  rand r_h2dreq68_t rand_req68; rand r_h2dreq256_t rand_req256;

  function new(string name = "h2dreq_c");
    super.new(name);
    txn_type = "H2D_REQ";
  endfunction

  function void pre_randomize();
    case (flitmode)
      F68  : rand_req256.rand_mode(0); 
      F256 : rand_req68 .rand_mode(0); 
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 : 
      begin
        if (req68.rsvd   === 'x) req68.rsvd   = rand_req68.rsvd;
        if (req68.uqid   === 'x) req68.uqid   = rand_req68.uqid;
        if (req68.addr   === 'x) req68.addr   = rand_req68.addr;
        if (req68.opcode === 'x) req68.opcode = rand_req68.opcode;
        if (req68.val    === 'x) req68.val    = rand_req68.val;
      end
      F256 : 
      begin
        if (req256.rsvd    === 'x) req256.rsvd    = rand_req256.rsvd;
        if (req256.cacheid === 'x) req256.cacheid = rand_req256.cacheid;
        if (req256.uqid    === 'x) req256.uqid    = rand_req256.uqid;
        if (req256.addr    === 'x) req256.addr    = rand_req256.addr;
        if (req256.opcode  === 'x) req256.opcode  = rand_req256.opcode;
        if (req256.val     === 'x) req256.val     = rand_req256.val;
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    string str;
    super.do_print(printer);
    case (flitmode)
      F68 :
      begin
        str = $sformatf("'h%0h (%0s)", req68.opcode, req68.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",   req68.rsvd, $bits(req68.rsvd));
        printer.print_int   ("uqid",   req68.uqid, $bits(req68.uqid));
        printer.print_int   ("addr",   req68.addr, $bits(req68.addr));
        printer.print_string("opcode", str);
        printer.print_int   ("val",    req68.val,  $bits(req68.val));
      end
      F256 :
      begin
        str = $sformatf("'h%0h (%0s)",  req256.opcode,  req256.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",    req256.rsvd,    $bits(req256.rsvd));
        printer.print_int   ("cacheid", req256.cacheid, $bits(req256.cacheid));
        printer.print_int   ("uqid",    req256.uqid,    $bits(req256.uqid));
        printer.print_int   ("addr",    req256.addr,    $bits(req256.addr));
        printer.print_string("opcode",  str);
        printer.print_int   ("val",     req256.val,     $bits(req256.val));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    h2dreq_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_req68  = _rhs.rand_req68;
      rand_req256 = _rhs.rand_req256;
      if (!copy_over_x_only) begin
        case (flitmode)
          F68  : req68  = _rhs.req68;
          F256 : req256 = _rhs.req256;
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
      else begin
        case (flitmode)
          F68 :
          begin
            if (req68.rsvd   === 'x) req68.rsvd   = _rhs.req68.rsvd;
            if (req68.uqid   === 'x) req68.uqid   = _rhs.req68.uqid;
            if (req68.addr   === 'x) req68.addr   = _rhs.req68.addr;
            if (req68.opcode === 'x) req68.opcode = _rhs.req68.opcode;
            if (req68.val    === 'x) req68.val    = _rhs.req68.val;
          end
          F256 :
          begin
            if (req256.rsvd    === 'x) req256.rsvd    = _rhs.req256.rsvd;
            if (req256.cacheid === 'x) req256.cacheid = _rhs.req256.cacheid;
            if (req256.uqid    === 'x) req256.uqid    = _rhs.req256.uqid;
            if (req256.addr    === 'x) req256.addr    = _rhs.req256.addr;
            if (req256.opcode  === 'x) req256.opcode  = _rhs.req256.opcode;
            if (req256.val     === 'x) req256.val     = _rhs.req256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    do_compare = 0;
  endfunction

endclass

class h2drsp_c extends base_txn;

  `uvm_object_utils(h2drsp_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy
  bit copy_over_x_only = 1'b1; 

         h2drsp68_t rsp68 = 'x;        h2drsp256_t rsp256 = 'x;
  rand r_h2drsp68_t rand_rsp68; rand r_h2drsp256_t rand_rsp256;

  function new(string name = "h2drsp_c");
    super.new(name);
    txn_type = "H2D_RSP";
  endfunction

  function void pre_randomize();
    case (flitmode)
      F68  : rand_rsp256.rand_mode(0); 
      F256 : rand_rsp68 .rand_mode(0); 
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 : 
      begin
        if (rsp68.rsvd    === 'x) rsp68.rsvd    = rand_rsp68.rsvd;
        if (rsp68.cqid    === 'x) rsp68.cqid    = rand_rsp68.cqid;
        if (rsp68.rsp_pre === 'x) rsp68.rsp_pre = rand_rsp68.rsp_pre;
        if (rsp68.rspdata === 'x) rsp68.rspdata = rand_rsp68.rspdata;
        if (rsp68.opcode  === 'x) rsp68.opcode  = rand_rsp68.opcode;
        if (rsp68.val     === 'x) rsp68.val     = rand_rsp68.val;
      end
      F256 : 
      begin
        if (rsp256.rsvd    === 'x) rsp256.rsvd    = rand_rsp256.rsvd;
        if (rsp256.cacheid === 'x) rsp256.cacheid = rand_rsp256.cacheid;
        if (rsp256.cqid    === 'x) rsp256.cqid    = rand_rsp256.cqid;
        if (rsp256.rsp_pre === 'x) rsp256.rsp_pre = rand_rsp256.rsp_pre;
        if (rsp256.rspdata === 'x) rsp256.rspdata = rand_rsp256.rspdata;
        if (rsp256.opcode  === 'x) rsp256.opcode  = rand_rsp256.opcode;
        if (rsp256.val     === 'x) rsp256.val     = rand_rsp256.val;
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    string str[2];
    super.do_print(printer);
    case (flitmode)
      F68 :
      begin
        str[0] = $sformatf("'h%0h (%0s)",  rsp68.rsp_pre, rsp68.rsp_pre.name);
        str[1] = $sformatf("'h%0h (%0s)",  rsp68.opcode,  rsp68.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",    rsp68.rsvd,    $bits(rsp68.rsvd));
        printer.print_int   ("cqid",    rsp68.cqid,    $bits(rsp68.cqid));
        printer.print_string("rsp_pre", str[0]);
        printer.print_int   ("rspdata", rsp68.rspdata, $bits(rsp68.rspdata));
        printer.print_string("opcode",  str[1]);
        printer.print_int   ("val",     rsp68.val,     $bits(rsp68.val));
      end
      F256 :
      begin
        str[0] = $sformatf("'h%0h (%0s)",  rsp256.rsp_pre, rsp256.rsp_pre.name);
        str[1] = $sformatf("'h%0h (%0s)",  rsp256.opcode,  rsp256.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",    rsp256.rsvd,    $bits(rsp256.rsvd));
        printer.print_int   ("cacheid", rsp256.cacheid, $bits(rsp256.cacheid));
        printer.print_int   ("cqid",    rsp256.cqid,    $bits(rsp256.cqid));
        printer.print_string("rsp_pre", str[0]);
        printer.print_int   ("rspdata", rsp256.rspdata, $bits(rsp256.rspdata));
        printer.print_string("opcode",  str[1]);
        printer.print_int   ("val",     rsp256.val,     $bits(rsp256.val));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    h2drsp_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_rsp68  = _rhs.rand_rsp68;
      rand_rsp256 = _rhs.rand_rsp256;
      if (!copy_over_x_only) begin
        case (flitmode)
          F68  : rsp68  = _rhs.rsp68;
          F256 : rsp256 = _rhs.rsp256;
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
      else begin
        case (flitmode)
          F68 :
          begin
            if (rsp68.rsvd    === 'x) rsp68.rsvd    = _rhs.rsp68.rsvd;
            if (rsp68.cqid    === 'x) rsp68.cqid    = _rhs.rsp68.cqid;
            if (rsp68.rsp_pre === 'x) rsp68.rsp_pre = _rhs.rsp68.rsp_pre;
            if (rsp68.rspdata === 'x) rsp68.rspdata = _rhs.rsp68.rspdata;
            if (rsp68.opcode  === 'x) rsp68.opcode  = _rhs.rsp68.opcode;
            if (rsp68.val     === 'x) rsp68.val     = _rhs.rsp68.val;
          end
          F256 :
          begin
            if (rsp256.rsvd    === 'x) rsp256.rsvd    = _rhs.rsp256.rsvd;
            if (rsp256.cacheid === 'x) rsp256.cacheid = _rhs.rsp256.cacheid;
            if (rsp256.cqid    === 'x) rsp256.cqid    = _rhs.rsp256.cqid;
            if (rsp256.rsp_pre === 'x) rsp256.rsp_pre = _rhs.rsp256.rsp_pre;
            if (rsp256.rspdata === 'x) rsp256.rspdata = _rhs.rsp256.rspdata;
            if (rsp256.opcode  === 'x) rsp256.opcode  = _rhs.rsp256.opcode;
            if (rsp256.val     === 'x) rsp256.val     = _rhs.rsp256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    do_compare = 0;
  endfunction

endclass

class h2ddat_c extends base_txn;

  `uvm_object_utils(h2ddat_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy
  bit copy_over_x_only = 1'b1; 

         h2ddat68_hdr_t hdr68 = 'x;        h2ddat256_hdr_t hdr256 = 'x;
  rand r_h2ddat68_hdr_t rand_hdr68; rand r_h2ddat256_hdr_t rand_hdr256;

  rand logic [511:0]    dat;
  rand logic            txfer_64B = 'x;

  function new(string name = "h2ddat_c");
    super.new(name);
    txn_type = "H2D_DAT";
  endfunction

  function void pre_randomize();
    dat.rand_mode(dat==='x);
    case (flitmode)
      F68  : rand_hdr256.rand_mode(0); 
      F256 : rand_hdr68 .rand_mode(0); 
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
    if (flitmode != F68) begin
      txfer_64B.rand_mode(0);
      txfer_64B = 1;
    end
    else if (txfer_64B !== 'x)
      txfer_64B.rand_mode(0);
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 :
      begin
        if (hdr68.rsvd === 'x)    hdr68.rsvd = rand_hdr68.rsvd;
        if (hdr68.go_e === 'x)    hdr68.go_e = rand_hdr68.go_e;
        if (hdr68.poi  === 'x)    hdr68.poi  = rand_hdr68.poi;
        if (txfer_64B)            hdr68.ch   = 1'b0;
        else if (hdr68.ch === 'x) hdr68.ch   = rand_hdr68.ch;
        if (hdr68.cqid === 'x)    hdr68.cqid = rand_hdr68.cqid;
        if (hdr68.val  === 'x)    hdr68.val  = rand_hdr68.val;
      end
      F256 : 
      begin
        if (hdr256.rsvd    === 'x) hdr256.rsvd    = rand_hdr256.rsvd;
        if (hdr256.cacheid === 'x) hdr256.cacheid = rand_hdr256.cacheid;
        if (hdr256.go_e    === 'x) hdr256.go_e    = rand_hdr256.go_e;
        if (hdr256.poi     === 'x) hdr256.poi     = rand_hdr256.poi;
        if (hdr256.cqid    === 'x) hdr256.cqid    = rand_hdr256.cqid;
        if (hdr256.val     === 'x) hdr256.val     = rand_hdr256.val;
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    string str;
    super.do_print(printer);
    case (flitmode)
      F68 :
      begin
        str = $sformatf("'b%0d (ignored)", hdr68.ch);
        // ---- //
        printer.print_int      ("rsvd", hdr68.rsvd, $bits(hdr68.rsvd));
        printer.print_int      ("go_e", hdr68.go_e, $bits(hdr68.go_e));
        printer.print_int      ("poi",  hdr68.poi,  $bits(hdr68.poi));
        if (txfer_64B) 
          printer.print_string ("ch",   str);
        else           
          printer.print_int    ("ch",   hdr68.ch,   $bits(hdr68.ch));
        printer.print_int      ("cqid", hdr68.cqid, $bits(hdr68.cqid));
        printer.print_int      ("val",  hdr68.val,  $bits(hdr68.val));
        if (!txfer_64B && hdr68.ch) begin
          printer.print_int   ("data[2]", dat[128*2+:128], 128);
          printer.print_int   ("data[3]", dat[128*3+:128], 128);
        end
        else if (!txfer_64B && !hdr68.ch) begin
          printer.print_int   ("data[0]", dat[128*0+:128], 128);
          printer.print_int   ("data[1]", dat[128*1+:128], 128);
        end
        else begin
          printer.print_int   ("data[0]", dat[128*0+:128], 128);
          printer.print_int   ("data[1]", dat[128*1+:128], 128);
          printer.print_int   ("data[2]", dat[128*2+:128], 128);
          printer.print_int   ("data[3]", dat[128*3+:128], 128);
        end
      end
      F256 :
      begin
        printer.print_int ("rsvd",    hdr256.rsvd,     $bits(hdr256.rsvd));
        printer.print_int ("cacheid", hdr256.cacheid,  $bits(hdr256.cacheid));
        printer.print_int ("go_e",    hdr256.go_e,     $bits(hdr256.go_e));
        printer.print_int ("poi",     hdr256.poi,      $bits(hdr256.poi));
        printer.print_int ("cqid",    hdr256.cqid,     $bits(hdr256.cqid));
        printer.print_int ("val",     hdr256.val,      $bits(hdr256.val));
        printer.print_int ("data[0]", dat[128*0+:128], 128);
        printer.print_int ("data[1]", dat[128*1+:128], 128);
        printer.print_int ("data[2]", dat[128*2+:128], 128);
        printer.print_int ("data[3]", dat[128*3+:128], 128);
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase 
  endfunction

  virtual function void do_copy(uvm_object rhs);
    h2ddat_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_hdr68  = _rhs.rand_hdr68;
      rand_hdr256 = _rhs.rand_hdr256;
      dat         = _rhs.dat;
      txfer_64B   = _rhs.txfer_64B;
      if (!copy_over_x_only) begin
        case (flitmode)
          F68  : hdr68  = _rhs.hdr68;
          F256 : hdr256 = _rhs.hdr256;
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
      else begin
        case (flitmode)
          F68 :
          begin
            if (hdr68.rsvd === 'x) hdr68.rsvd = _rhs.hdr68.rsvd;
            if (hdr68.go_e === 'x) hdr68.go_e = _rhs.hdr68.go_e;
            if (hdr68.poi  === 'x) hdr68.poi  = _rhs.hdr68.poi;
            if (hdr68.ch   === 'x) hdr68.ch   = _rhs.hdr68.ch;
            if (hdr68.cqid === 'x) hdr68.cqid = _rhs.hdr68.cqid;
            if (hdr68.val  === 'x) hdr68.val  = _rhs.hdr68.val;
          end
          F256 :
          begin
            if (hdr256.rsvd    === 'x) hdr256.rsvd    = _rhs.hdr256.rsvd;
            if (hdr256.cacheid === 'x) hdr256.cacheid = _rhs.hdr256.cacheid;
            if (hdr256.go_e    === 'x) hdr256.go_e    = _rhs.hdr256.go_e;
            if (hdr256.poi     === 'x) hdr256.poi     = _rhs.hdr256.poi;
            if (hdr256.cqid    === 'x) hdr256.cqid    = _rhs.hdr256.cqid;
            if (hdr256.val     === 'x) hdr256.val     = _rhs.hdr256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    do_compare = 0;
  endfunction

endclass

class d2hreq_c extends base_txn;

  `uvm_object_utils(d2hreq_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy
  bit copy_over_x_only = 1'b1; 

         d2hreq68_t req68 = 'x;        d2hreq256_t req256 = 'x;
  rand r_d2hreq68_t rand_req68; rand r_d2hreq256_t rand_req256;

  function new(string name = "d2hreq_c");
    super.new(name);
    txn_type = "D2H_REQ";
  endfunction
 
  function void pre_randomize();
    case (flitmode)
      F68  : rand_req256.rand_mode(0); 
      F256 : rand_req68 .rand_mode(0); 
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 :
      begin
        if (req68.rsvd1  === 'x) req68.rsvd1  = rand_req68.rsvd1;
        if (req68.addr   === 'x) req68.addr   = rand_req68.addr;
        if (req68.rsvd0  === 'x) req68.rsvd0  = rand_req68.rsvd0;
        if (req68.nt     === 'x) req68.nt     = rand_req68.nt;
        if (req68.cqid   === 'x) req68.cqid   = rand_req68.cqid;
        if (req68.opcode === 'x) req68.opcode = rand_req68.opcode;
        if (req68.val    === 'x) req68.val    = rand_req68.val;
      end
      F256 :
      begin
        if (req256.rsvd1   === 'x) req256.rsvd1   = rand_req256.rsvd1;
        if (req256.addr    === 'x) req256.addr    = rand_req256.addr;
        if (req256.rsvd0   === 'x) req256.rsvd0   = rand_req256.rsvd0;
        if (req256.cacheid === 'x) req256.cacheid = rand_req256.cacheid;
        if (req256.nt      === 'x) req256.nt      = rand_req256.nt;
        if (req256.cqid    === 'x) req256.cqid    = rand_req256.cqid;
        if (req256.opcode  === 'x) req256.opcode  = rand_req256.opcode;
        if (req256.val     === 'x) req256.val     = rand_req256.val;
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    string str;
    super.do_print(printer);
    case (flitmode)
      F68 :
      begin
        str = $sformatf("'h%0h (%0s)", req68.opcode, req68.opcode.name);
        // ---- //
        printer.print_int   ("rsvd1",  req68.rsvd1, $bits(req68.rsvd1));
        printer.print_int   ("addr",   req68.addr,  $bits(req68.addr));
        printer.print_int   ("rsvd0",  req68.rsvd0, $bits(req68.rsvd0));
        printer.print_int   ("nt",     req68.nt,    $bits(req68.nt));
        printer.print_int   ("cqid",   req68.cqid,  $bits(req68.cqid));
        printer.print_string("opcode", str);
        printer.print_int   ("val",    req68.val,   $bits(req68.val));
      end
      F256 :
      begin
        str = $sformatf("'h%0h (%0s)", req256.opcode, req256.opcode.name);
        // ---- //
        printer.print_int   ("rsvd1",  req256.rsvd1,   $bits(req256.rsvd1));
        printer.print_int   ("addr",   req256.addr,    $bits(req256.addr));
        printer.print_int   ("rsvd0",  req256.rsvd0,   $bits(req256.rsvd0));
        printer.print_int   ("cacheid",req256.cacheid, $bits(req256.cacheid));
        printer.print_int   ("nt",     req256.nt,      $bits(req256.nt));
        printer.print_int   ("cqid",   req256.cqid,    $bits(req256.cqid));
        printer.print_string("opcode", str);
        printer.print_int   ("val",    req256.val,     $bits(req256.val));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    d2hreq_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_req68  = _rhs.rand_req68;
      rand_req256 = _rhs.rand_req256;
      if (!copy_over_x_only) begin
        case(flitmode)
          F68  : req68  = _rhs.req68;
          F256 : req256 = _rhs.req256;
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
      else begin
        case(flitmode)
          F68 :
          begin
            if (req68.rsvd1  === 'x) req68.rsvd1  = _rhs.req68.rsvd1;
            if (req68.addr   === 'x) req68.addr   = _rhs.req68.addr;
            if (req68.rsvd0  === 'x) req68.rsvd0  = _rhs.req68.rsvd0;
            if (req68.nt     === 'x) req68.nt     = _rhs.req68.nt;
            if (req68.cqid   === 'x) req68.cqid   = _rhs.req68.cqid;
            if (req68.opcode === 'x) req68.opcode = _rhs.req68.opcode;
            if (req68.val    === 'x) req68.val    = _rhs.req68.val;
          end
          F256 :
          begin
            if (req256.rsvd1   === 'x) req256.rsvd1   = _rhs.req256.rsvd1;
            if (req256.addr    === 'x) req256.addr    = _rhs.req256.addr;
            if (req256.rsvd0   === 'x) req256.rsvd0   = _rhs.req256.rsvd0;
            if (req256.cacheid === 'x) req256.cacheid = _rhs.req256.cacheid;
            if (req256.nt      === 'x) req256.nt      = _rhs.req256.nt;
            if (req256.cqid    === 'x) req256.cqid    = _rhs.req256.cqid;
            if (req256.opcode  === 'x) req256.opcode  = _rhs.req256.opcode;
            if (req256.val     === 'x) req256.val     = _rhs.req256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    do_compare = 0;
  endfunction

endclass

class d2hrsp_c extends base_txn;

  `uvm_object_utils(d2hrsp_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy
  bit copy_over_x_only = 1'b1; 

         d2hrsp68_t rsp68 = 'x;        d2hrsp256_t rsp256 = 'x;
  rand r_d2hrsp68_t rand_rsp68; rand r_d2hrsp256_t rand_rsp256;

  function new(string name = "d2hrsp_c");
    super.new(name);
    txn_type = "D2H_RSP";
  endfunction

  function void pre_randomize();
    case (flitmode)
      F68  : rand_rsp256.rand_mode(0); 
      F256 : rand_rsp68 .rand_mode(0); 
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 : 
      begin
        if (rsp68.rsvd   === 'x) rsp68.rsvd   = rand_rsp68.rsvd;
        if (rsp68.uqid   === 'x) rsp68.uqid   = rand_rsp68.uqid;
        if (rsp68.opcode === 'x) rsp68.opcode = rand_rsp68.opcode;
        if (rsp68.val    === 'x) rsp68.val    = rand_rsp68.val;
      end 
      F256 : 
      begin
        if (rsp256.rsvd   === 'x) rsp256.rsvd   = rand_rsp256.rsvd;
        if (rsp256.uqid   === 'x) rsp256.uqid   = rand_rsp256.uqid;
        if (rsp256.opcode === 'x) rsp256.opcode = rand_rsp256.opcode;
        if (rsp256.val    === 'x) rsp256.val    = rand_rsp256.val;
      end 
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    string str;
    super.do_print(printer);
    
    case (flitmode)
      F68 :
      begin
        str = $sformatf("'h%0h (%0s)", rsp68.opcode, rsp68.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",   rsp68.rsvd,  $bits(rsp68.rsvd));
        printer.print_int   ("cqid",   rsp68.uqid,  $bits(rsp68.uqid));
        printer.print_string("opcode", str);
        printer.print_int   ("val",    rsp68.val,   $bits(rsp68.val));
      end
      F256 :
      begin
        str = $sformatf("'h%0h (%0s)", rsp256.opcode, rsp256.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",   rsp256.rsvd,  $bits(rsp256.rsvd));
        printer.print_int   ("cqid",   rsp256.uqid,  $bits(rsp256.uqid));
        printer.print_string("opcode", str);
        printer.print_int   ("val",    rsp256.val,   $bits(rsp256.val));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    d2hrsp_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_rsp68  = _rhs.rand_rsp68;
      rand_rsp256 = _rhs.rand_rsp256;
      if (!copy_over_x_only) begin
        case (flitmode)
          F68  : rsp68  = _rhs.rsp68;
          F256 : rsp256 = _rhs.rsp256;
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
      else begin
        case (flitmode)
          F68 :
          begin
            if (rsp68.rsvd   === 'x) rsp68.rsvd   = _rhs.rsp68.rsvd;
            if (rsp68.uqid   === 'x) rsp68.uqid   = _rhs.rsp68.uqid;
            if (rsp68.opcode === 'x) rsp68.opcode = _rhs.rsp68.opcode;
            if (rsp68.val    === 'x) rsp68.val    = _rhs.rsp68.val;
          end
          F256 :
          begin
            if (rsp256.rsvd   === 'x) rsp256.rsvd   = _rhs.rsp256.rsvd;
            if (rsp256.uqid   === 'x) rsp256.uqid   = _rhs.rsp256.uqid;
            if (rsp256.opcode === 'x) rsp256.opcode = _rhs.rsp256.opcode;
            if (rsp256.val    === 'x) rsp256.val    = _rhs.rsp256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    do_compare = 0;
  endfunction

endclass

class d2hdat_c extends base_txn;

  `uvm_object_utils(d2hdat_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy
  bit copy_over_x_only = 1'b1; 

         d2hdat68_hdr_t hdr68 = 'x;        d2hdat256_hdr_t hdr256 = 'x;
  rand r_d2hdat68_hdr_t rand_hdr68; rand r_d2hdat256_hdr_t rand_hdr256;

  rand logic [511:0]    dat;
  rand logic [ 63:0]    be = 'x;
  rand logic            txfer_64B = 'x;
  // Control
  rand protected bit    do_be;

  // Notes: To control BE presence may be done as shown below. 
  // 68B Flits
  //  1. Set the be field depending on desired behavior
  //   a. be=='x -> byte enables presence is randomized
  //   b. be=='0 -> special case; user wants randomized byte enables!='1
  //   c. be=='1 -> user wants set byte enables=='1
  // 256B Flits
  //  1. Set the hdr256.bep field depending on desired behavior
  //   a. hdr256.bep=='x -> byte enables presence is randomized unless 2. is active
  //   b. hdr256.bep=='0 -> user wants set byte enables=='1
  //   c. hdr256.bep=='1 -> user wants randomized byte enables!='1 
  //  2. Set the be field depending on desired behavior
  //   a. be=='1 -> user wants set byte enables=='1
  //   b. be==<some value> -> user wants specific byte enables=='1

  // Mostly don't do BE (only 30% of time)
  constraint c_be {
    do_be dist {0 := 70, 1 := 30};
    if (do_be) {be != '1;} 
    else       {be == '1;}
  }

  // Mostly don't do 32B transfers (only 5% of time)
  constraint c_sz { txfer_64B dist {0 := 5, 1 := 95}; }

  function new(string name = "d2hdat_c");
    super.new(name);
    txn_type = "D2H_DAT";
  endfunction

  function void pre_randomize();
    dat.rand_mode(dat==='x);
    case (flitmode)
      F68  : rand_hdr256.rand_mode(0); 
      F256 : rand_hdr68.rand_mode(0); 
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
    // Control BEs
    if (flitmode == F68) begin
      case (1'b1)
        be==='x : begin  //a.
                    do_be.rand_mode(1);
                    be.rand_mode(1);
                  end
        be==='1 : begin //b.
                    do_be.rand_mode(0);
                    do_be = 0;
                    be.rand_mode(0);
                  end
        be==='0 : begin //c.
                    do_be.rand_mode(0);
                    do_be = 1;
                    be.rand_mode(1);
                  end
        default : begin //d.
                    do_be.rand_mode(0);
                    do_be = 1;
                    be.rand_mode(0);
                  end
      endcase
    end
    else begin
      case (1'b1)
        hdr256.bep==='x : if (be==='1) begin
                            do_be.rand_mode(0);
                            do_be = 0;
                            be.rand_mode(0);
                          end
                          else if (be!=='x) begin
                            do_be.rand_mode(0);
                            do_be = 1;
                            be.rand_mode(0);
                          end
                          else begin
                            do_be.rand_mode(1);
                            be.rand_mode(1);
                          end
        hdr256.bep==='1 : begin
                            do_be.rand_mode(0);
                            do_be = 1;
                            be.rand_mode(1);
                          end
        hdr256.bep==='0 : begin
                            do_be.rand_mode(0);
                            do_be = 0;
                            be.rand_mode(0);
                            be = '1;
                          end
        default :         begin
                            do_be.rand_mode(1);
                            be.rand_mode(1);
                          end
      endcase
    end
    // Control 32B split chunks (68B flits only)
    if (flitmode != F68) begin
      txfer_64B.rand_mode(0);
      txfer_64B = 1;
    end
    else if (txfer_64B !== 'x)
      txfer_64B.rand_mode(0);
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 :
      begin
        if (hdr68.rsvd === 'x)    hdr68.rsvd = rand_hdr68.rsvd;
        if (hdr68.poi  === 'x)    hdr68.poi  = rand_hdr68.poi;
        if (hdr68.bg   === 'x)    hdr68.bg   = rand_hdr68.bg;
        if (txfer_64B)            hdr68.ch   = 1'b0;
        else if (hdr68.ch === 'x) hdr68.ch   = rand_hdr68.ch;
        if (hdr68.uqid === 'x)    hdr68.uqid = rand_hdr68.uqid;
        if (hdr68.val  === 'x)    hdr68.val  = rand_hdr68.val;
      end
      F256 :
      begin
        if (hdr256.rsvd === 'x)   hdr256.rsvd = rand_hdr256.rsvd;
        if (hdr256.bep  === 'x)   hdr256.bep  = do_be; 
        if (hdr256.poi  === 'x)   hdr256.poi  = rand_hdr256.poi;
        if (hdr256.bg   === 'x)   hdr256.bg   = rand_hdr256.bg;
        if (hdr256.uqid === 'x)   hdr256.uqid = rand_hdr256.uqid;
        if (hdr256.val  === 'x)   hdr256.val  = rand_hdr256.val;
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    logic [511:0] masked_data;
    string str;
    for (int ii=0; ii<64; ii++)
      masked_data[ii*8+:8] = dat[ii*8+:8] & {8{be[ii]}};
    super.do_print(printer);
    case (flitmode)
      F68 :
      begin
        str = $sformatf("'h%h (ignored)",hdr68.ch);
        // ---- //
        printer.print_int   ("rsvd", hdr68.rsvd, $bits(hdr68.rsvd));
        printer.print_int   ("poi",  hdr68.poi,  $bits(hdr68.poi));
        printer.print_int   ("bg",   hdr68.bg,   $bits(hdr68.bg));
        if (txfer_64B) printer.print_string ("ch", str);
        else           printer.print_int    ("ch", hdr68.ch, $bits(hdr68.ch));
        printer.print_int   ("uqid", hdr68.uqid, $bits(hdr68.uqid));
        printer.print_int   ("val",  hdr68.val,  $bits(hdr68.val));
        if (!txfer_64B && hdr68.ch) begin
          printer.print_int ("data[2]", dat[128*2+:128], 128);
          printer.print_int ("data[3]", dat[128*3+:128], 128);
          if (be[63:32] !== '1) begin
            printer.print_int ("be[63:32]", be[63:32], 32);
            printer.print_int ("data[2] (resultant)", masked_data[128*2+:128], 128);
            printer.print_int ("data[3] (resultant)", masked_data[128*3+:128], 128);
          end
        end
        else if (!txfer_64B && !hdr68.ch) begin
          printer.print_int ("data[0]", dat[128*0+:128], 128);
          printer.print_int ("data[1]", dat[128*1+:128], 128);
          if (be[31:0] !== '1) begin
            printer.print_int ("be[31:0]", be[31:0], 32);
            printer.print_int ("data[0] (resultant)", masked_data[128*0+:128], 128);
            printer.print_int ("data[1] (resultant)", masked_data[128*1+:128], 128);
          end
        end
        else begin
          printer.print_int ("data[0]", dat[128*0+:128], 128);
          printer.print_int ("data[1]", dat[128*1+:128], 128);
          printer.print_int ("data[2]", dat[128*2+:128], 128);
          printer.print_int ("data[3]", dat[128*3+:128], 128);
          if (be !== '1) begin
            printer.print_int ("be", be, 64);
            printer.print_int ("data[0] (resultant)", masked_data[128*0+:128], 128);
            printer.print_int ("data[1] (resultant)", masked_data[128*1+:128], 128);
            printer.print_int ("data[2] (resultant)", masked_data[128*2+:128], 128);
            printer.print_int ("data[3] (resultant)", masked_data[128*3+:128], 128);
          end
        end
      end
      F256 :
      begin
        printer.print_int ("rsvd",    hdr256.rsvd,      $bits(hdr256.rsvd));
        printer.print_int ("bep",     hdr256.bep,       $bits(hdr256.bep));
        printer.print_int ("poi",     hdr256.poi,       $bits(hdr256.poi));
        printer.print_int ("bg",      hdr256.bg,        $bits(hdr256.bg));
        printer.print_int ("uqid",    hdr256.uqid,      $bits(hdr256.uqid));
        printer.print_int ("val",     hdr256.val,       $bits(hdr256.val));
        printer.print_int ("data[0]", dat[128*0+:128], 128);
        printer.print_int ("data[1]", dat[128*1+:128], 128);
        printer.print_int ("data[2]", dat[128*2+:128], 128);
        printer.print_int ("data[3]", dat[128*3+:128], 128);
        if (be !== '1) begin
          printer.print_int ("be", be, 64);
          printer.print_int ("data[0] (resultant)", masked_data[128*0+:128], 128);
          printer.print_int ("data[1] (resultant)", masked_data[128*1+:128], 128);
          printer.print_int ("data[2] (resultant)", masked_data[128*2+:128], 128);
          printer.print_int ("data[3] (resultant)", masked_data[128*3+:128], 128);
        end
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    d2hdat_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_hdr68  = _rhs.rand_hdr68;
      rand_hdr256 = _rhs.rand_hdr256;
      dat         = _rhs.dat;
      be          = _rhs.be;
      txfer_64B   = _rhs.txfer_64B;
      do_be       = _rhs.do_be;
      if (!copy_over_x_only) begin
        case (flitmode)  
          F68  : hdr68  = _rhs.hdr68;
          F256 : hdr256 = _rhs.hdr256;
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
      else begin
        case (flitmode)
          F68 :
          begin
            if (hdr68.rsvd === 'x) hdr68.rsvd = _rhs.hdr68.rsvd;
            if (hdr68.poi  === 'x) hdr68.poi  = _rhs.hdr68.poi;
            if (hdr68.bg   === 'x) hdr68.bg   = _rhs.hdr68.bg;
            if (hdr68.ch   === 'x) hdr68.ch   = _rhs.hdr68.ch;
            if (hdr68.uqid === 'x) hdr68.uqid = _rhs.hdr68.uqid;
            if (hdr68.val  === 'x) hdr68.val  = _rhs.hdr68.val;
          end
          F256 :
          begin
            if (hdr256.rsvd === 'x) hdr256.rsvd = _rhs.hdr256.rsvd;
            if (hdr256.bep  === 'x) hdr256.bep  = _rhs.hdr256.bep;
            if (hdr256.poi  === 'x) hdr256.poi  = _rhs.hdr256.poi;
            if (hdr256.bg   === 'x) hdr256.bg   = _rhs.hdr256.bg;
            if (hdr256.uqid === 'x) hdr256.uqid = _rhs.hdr256.uqid;
            if (hdr256.val  === 'x) hdr256.val  = _rhs.hdr256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    `uvm_warning(get_type_name, "do_compare not written yet")
    do_compare = 0;
  endfunction

endclass
