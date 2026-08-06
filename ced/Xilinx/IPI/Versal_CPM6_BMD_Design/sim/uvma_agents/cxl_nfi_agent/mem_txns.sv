// All CXL.mem transactions are included in this file
// _c = "class"
class m2sreq_c extends base_txn;

  `uvm_object_utils(m2sreq_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy of the req
  bit copy_over_x_only = 1'b1; 

         m2sreq68_t req68 = 'x;        m2sreq256_t req256 = 'x;
  rand r_m2sreq68_t rand_req68; rand r_m2sreq256_t rand_req256;

  function new(string name = "m2sreq_c");
    super.new(name);
    txn_type = "M2S_REQ";
  endfunction

  // Here we will select the randomized variable or not, which has
  // allowed for fine randomization of a multi-field variable
  function void post_randomize(); 
    case (flitmode)
      F68 :
      begin
        if (req68.rsvd      === 'x) req68.rsvd      = rand_req68.rsvd;
        if (req68.ldid      === 'x) req68.ldid      = rand_req68.ldid;
        if (req68.tc        === 'x) req68.tc        = rand_req68.tc;
        if (req68.addr      === 'x) req68.addr      = rand_req68.addr;
        if (req68.tag       === 'x) req68.tag       = rand_req68.tag;
        if (req68.metavalue === 'x) req68.metavalue = rand_req68.metavalue;
        if (req68.metafield === 'x) req68.metafield = rand_req68.metafield;
        if (req68.snptype   === 'x) req68.snptype   = rand_req68.snptype;
        if (req68.memop     === 'x) req68.memop     = rand_req68.memop;
        if (req68.val       === 'x) req68.val       = rand_req68.val;
      end
      F256 :
      begin
        if (req256.tc        === 'x) req256.tc        = rand_req256.tc;
        if (req256.rsvd      === 'x) req256.rsvd      = rand_req256.rsvd;
        if (req256.ckid      === 'x) req256.ckid      = rand_req256.ckid;
        if (req256.ldid      === 'x) req256.ldid      = rand_req256.ldid;
        if (req256.addr      === 'x) req256.addr      = rand_req256.addr;
        if (req256.tag       === 'x) req256.tag       = rand_req256.tag;
        if (req256.metavalue === 'x) req256.metavalue = rand_req256.metavalue;
        if (req256.metafield === 'x) req256.metafield = rand_req256.metafield;
        if (req256.snptype   === 'x) req256.snptype   = rand_req256.snptype;
        if (req256.memop     === 'x) req256.memop     = rand_req256.memop;
        if (req256.val       === 'x) req256.val       = rand_req256.val;
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    string str[4];
    string name;
    super.do_print(printer);
    case (flitmode)
      F68 :
      begin
        str[0] = $sformatf("'h%0h (%0s)", req68.metavalue, req68.metavalue.name);
        name = req68.metafield.name=="" ? "Rsvd" : req68.metafield.name;
        str[1] = $sformatf("'h%0h (%0s)", req68.metafield, name);
        name = req68.snptype.name=="" ? "Rsvd" : req68.snptype.name;
        str[2] = $sformatf("'h%0h (%0s)", req68.snptype,   name);
        name = req68.memop.name=="" ? "Rsvd" : req68.memop.name;
        str[3] = $sformatf("'h%0h (%0s)", req68.memop,     name);
        // ---- //
        printer.print_int   ("rsvd",      req68.rsvd, $bits(req68.rsvd));
        printer.print_int   ("ldid",      req68.ldid, $bits(req68.ldid));
        printer.print_int   ("tc",        req68.tc,   $bits(req68.tc));
        printer.print_int   ("addr",      req68.addr, $bits(req68.addr));
        printer.print_int   ("tag",       req68.tag,  $bits(req68.tag));
        printer.print_string("metavalue", str[0]);
        printer.print_string("metafield", str[1]);
        printer.print_string("snptype",   str[2]);
        printer.print_string("memop",     str[3]);
        printer.print_int   ("val",       req68.val,  $bits(req68.val));
      end
      F256 :
      begin
        str[0] = $sformatf("'h%0h (%0s)", req256.metavalue, req256.metavalue.name);
        name = req256.metafield.name=="" ? "Rsvd" : req256.metafield.name;
        str[1] = $sformatf("'h%0h (%0s)", req256.metafield, name);
        name = req256.snptype.name=="" ? "Rsvd" : req256.snptype.name;
        str[2] = $sformatf("'h%0h (%0s)", req256.snptype,   name);
        name = req256.memop.name=="" ? "Rsvd" : req256.memop.name;
        str[3] = $sformatf("'h%0h (%0s)", req256.memop,     name);
        // ---- //
        printer.print_int   ("rsvd",      req256.rsvd, $bits(req256.rsvd));
        printer.print_int   ("ckid",      req256.ckid, $bits(req256.ckid));
        printer.print_int   ("ldid",      req256.ldid, $bits(req256.ldid));
        printer.print_int   ("tc",        req256.tc,   $bits(req256.tc));
        printer.print_int   ("addr",      req256.addr, $bits(req256.addr));
        printer.print_int   ("tag",       req256.tag,  $bits(req256.tag));
        printer.print_string("metavalue", str[0]);
        printer.print_string("metafield", str[1]);
        printer.print_string("snptype",   str[2]);
        printer.print_string("memop",     str[3]);
        printer.print_int   ("val",       req256.val,  $bits(req256.val));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    m2sreq_c _rhs;
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
            if (req68.rsvd === 'x)      req68.rsvd      = _rhs.req68.rsvd;
            if (req68.ldid === 'x)      req68.ldid      = _rhs.req68.ldid;
            if (req68.tc === 'x)        req68.tc        = _rhs.req68.tc;
            if (req68.addr === 'x)      req68.addr      = _rhs.req68.addr;
            if (req68.tag === 'x)       req68.tag       = _rhs.req68.tag;
            if (req68.metavalue === 'x) req68.metavalue = _rhs.req68.metavalue;
            if (req68.metafield === 'x) req68.metafield = _rhs.req68.metafield;
            if (req68.snptype === 'x)   req68.snptype   = _rhs.req68.snptype;
            if (req68.memop === 'x)     req68.memop     = _rhs.req68.memop;
            if (req68.val === 'x)       req68.val       = _rhs.req68.val;
          end
          F256 : 
          begin
            if (req256.rsvd === 'x)      req256.rsvd      = _rhs.req256.rsvd;
            if (req256.ckid === 'x)      req256.ckid      = _rhs.req256.ckid;
            if (req256.ldid === 'x)      req256.ldid      = _rhs.req256.ldid;
            if (req256.tc === 'x)        req256.tc        = _rhs.req256.tc;
            if (req256.addr === 'x)      req256.addr      = _rhs.req256.addr;
            if (req256.tag === 'x)       req256.tag       = _rhs.req256.tag;
            if (req256.metavalue === 'x) req256.metavalue = _rhs.req256.metavalue;
            if (req256.metafield === 'x) req256.metafield = _rhs.req256.metafield;
            if (req256.snptype === 'x)   req256.snptype   = _rhs.req256.snptype;
            if (req256.memop === 'x)     req256.memop     = _rhs.req256.memop;
            if (req256.val === 'x)       req256.val       = _rhs.req256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    m2sreq_c _rhs;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_compare failed")
    case (flitmode)
      F68 : 
      begin
        do_compare &= comparer.compare_field_int("rsvd",      req68.rsvd,      _rhs.req68.rsvd,      $bits(req68.rsvd));
        do_compare &= comparer.compare_field_int("ldid",      req68.ldid,      _rhs.req68.ldid,      $bits(req68.ldid));     
        do_compare &= comparer.compare_field_int("tc",        req68.tc,        _rhs.req68.tc,        $bits(req68.tc));   
        do_compare &= comparer.compare_field_int("addr",      req68.addr,      _rhs.req68.addr,      $bits(req68.addr));
        do_compare &= comparer.compare_field_int("tag",       req68.tag,       _rhs.req68.tag,       $bits(req68.tag));
        do_compare &= comparer.compare_field_int("metavalue", req68.metavalue, _rhs.req68.metavalue, $bits(req68.metavalue));
        do_compare &= comparer.compare_field_int("metafield", req68.metafield, _rhs.req68.metafield, $bits(req68.metafield));
        do_compare &= comparer.compare_field_int("snptype",   req68.snptype,   _rhs.req68.snptype,   $bits(req68.snptype));
        do_compare &= comparer.compare_field_int("memop",     req68.memop,     _rhs.req68.memop,     $bits(req68.memop));
        do_compare &= comparer.compare_field_int("val",       req68.val,       _rhs.req68.val,       $bits(req68.val));
      end
      F256 : 
      begin
        do_compare &= comparer.compare_field_int("rsvd",      req256.rsvd,      _rhs.req256.rsvd,      $bits(req256.rsvd));
        do_compare &= comparer.compare_field_int("ckid",      req256.ckid,      _rhs.req256.ckid,      $bits(req256.ckid));     
        do_compare &= comparer.compare_field_int("ldid",      req256.ldid,      _rhs.req256.ldid,      $bits(req256.ldid));     
        do_compare &= comparer.compare_field_int("tc",        req256.tc,        _rhs.req256.tc,        $bits(req256.tc));   
        do_compare &= comparer.compare_field_int("addr",      req256.addr,      _rhs.req256.addr,      $bits(req256.addr));
        do_compare &= comparer.compare_field_int("tag",       req256.tag,       _rhs.req256.tag,       $bits(req256.tag));
        do_compare &= comparer.compare_field_int("metavalue", req256.metavalue, _rhs.req256.metavalue, $bits(req256.metavalue));
        do_compare &= comparer.compare_field_int("metafield", req256.metafield, _rhs.req256.metafield, $bits(req256.metafield));
        do_compare &= comparer.compare_field_int("snptype",   req256.snptype,   _rhs.req256.snptype,   $bits(req256.snptype));
        do_compare &= comparer.compare_field_int("memop",     req256.memop,     _rhs.req256.memop,     $bits(req256.memop));
        do_compare &= comparer.compare_field_int("val",       req256.val,       _rhs.req256.val,       $bits(req256.val));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

endclass

class m2srwd_c extends base_txn;

  `uvm_object_utils(m2srwd_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy of the hdr
  bit copy_over_x_only = 1'b1; 

         m2srwd68_hdr_t hdr68 = 'x;        m2srwd256_hdr_t hdr256 = 'x;
  rand r_m2srwd68_hdr_t rand_hdr68; rand r_m2srwd256_hdr_t rand_hdr256;

  rand logic [511:0]    dat;
  rand logic [ 63:0]    be = 'x;
  rand logic [ 31:0]    emd = 'x;
  // Control
  rand protected bit    do_be;
  rand protected bit    do_emd;

  // Notes: To control BE and/or TRP presence may be done as shown below. 
  // 68B Flits
  //  1. Set the hdr68.memop field depending on desired behavior
  //   a. hdr68.memop=='x -> byte enables presence is randomized unlss 2. is active 
  //   b. hdr68.memop==MemWrPtl -> user wants randomized byte enables!='1 unless be!='x
  //   c. hdr68.memop!=MemWrPtl -> user wants set byte enables=='1
  //  2. Set the be field depending on desired behavior
  //   a. be=='x -> byte enables presence is randomized
  //   b. be=='0 -> special case; user wants randomized byte enables!='1
  //   c. be=='1 -> user wants set byte enables=='1
  // 256B Flits
  //  - Control BE presence
  //  1. Set the hdr256.memop field depending on desired behavior
  //   a. hdr256.memop=='x -> byte enables presence is randomized unlss 2. is active 
  //   b. hdr256.memop==MemWrPtl -> user wants randomized byte enables!='1 unless be!='x
  //   c. hdr256.memop!=MemWrPtl -> user wants set byte enables=='1
  //  2. Set the be field depending on desired behavior
  //   a. be=='x -> byte enables presence is randomized
  //   b. be=='0 -> special case; user wants randomized byte enables!='1
  //   c. be=='1 -> user wants set byte enables=='1
  //  - Control EMD presence
  //  1. Set the hdr256.metafield field depending on desired behavior
  //   a. hdr256.metafield=='x -> EMD presence is randomized unless 2. is active 
  //   b. hdr256.metafield==ExtMetaState -> user wants randomized EMD unless EMD!='x
  //   c. hdr256.metafield!=ExtMetaState -> user doesn't want EMD
  //  2. Set the emd field depending on desired behavior
  //   a. emd=='x -> extended metadata presence is randomized
  //   b. emd!='x -> user wants set extended metadata

  // Disable EMD if desired
  constraint c_noemd { do_emd==0; }

  constraint c_be_trp {
    // Mostly don't do BE or TRP (30% of time)
    do_be  dist {0 := 70, 1 := 30};
    do_emd dist {0 := 70, 1 := 30};
  }

  constraint c_f68 {
    !(rand_hdr68.memop inside {MemRdFill, MemWrTEE, MemWrPtlTEE, MemRdFillTEE, BIConflict});
    rand_hdr68.metafield != ExtMetaState;
    if (do_be) { be != '1; rand_hdr68.memop == MemWrPtl; } 
    else       { be == '1; rand_hdr68.memop != MemWrPtl; }
  }

  constraint c_f256 {
    if      ( do_be && !do_emd) {be != '1; 
                                 rand_hdr256.trp == 1; 
                                 rand_hdr256.memop inside {MemWrPtl, MemWrPtlTEE};
                                 rand_hdr256.metafield != ExtMetaState;}
    else if (!do_be &&  do_emd) {be == '1; 
                                 rand_hdr256.trp == 1; 
                                 rand_hdr256.memop inside {MemWrMem, MemWrTEE};
                                 rand_hdr256.metafield == ExtMetaState;}
    else if ( do_be &&  do_emd) {be != '1; 
                                 rand_hdr256.trp == 1; 
                                 rand_hdr256.memop inside {MemWrPtl, MemWrPtlTEE};
                                 rand_hdr256.metafield == ExtMetaState;}
    else   /*!do_be && !do_emd*/{be == '1; 
                                 rand_hdr256.trp == 0; 
                                 !(rand_hdr256.memop inside {MemWrPtl, MemWrPtlTEE});
                                 rand_hdr256.metafield != ExtMetaState;}
  }

  function new(string name = "m2srwd_c");
    super.new(name);
    txn_type = "M2S_RWD";
    // EMD allowed by default
    c_noemd.constraint_mode(0);
  endfunction

  function void pre_randomize();
    dat.rand_mode(dat==='x);
    case (flitmode)
      F68  : begin rand_hdr256.rand_mode(0); c_f256.constraint_mode(0); end
      F256 : begin rand_hdr68 .rand_mode(0); c_f68 .constraint_mode(0); end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
    // Control BEs 
    if (flitmode == F68) begin
      do_emd.rand_mode(0); 
      do_emd = 0;
      case (1'b1)
        hdr68.memop==='x : 
          if (be==='1) begin 
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
        hdr68.memop===MemWrPtl : 
          begin
            do_be.rand_mode(0);
            do_be = 1;
            be.rand_mode(1);
          end
        hdr68.memop!==MemWrPtl : 
          begin
            do_be.rand_mode(0);
            do_be = 0;
            be.rand_mode(0);
            be = '1;
          end
      endcase
    end
    // Control BE and EMD for 256B flits
    else begin
      case (1'b1)
        hdr256.memop==='x : 
          if (be==='1) begin 
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
        hdr256.memop inside {MemWrPtl, MemWrPtlTEE} : 
          begin
            do_be.rand_mode(0);
            do_be = 1;
            be.rand_mode(1);
          end
        !(hdr256.memop inside {MemWrPtl, MemWrPtlTEE}) : 
          begin
            do_be.rand_mode(0);
            do_be = 0;
            be.rand_mode(0);
            be = '1;
          end
      endcase
      case (1'b1)
        hdr256.metafield==='x : 
          if (emd==='x) begin
            do_emd.rand_mode(1);
            emd.rand_mode(1);
          end
          else begin
            do_emd.rand_mode(0);
            do_emd = 1;
            emd.rand_mode(0);
          end
        hdr256.metafield==ExtMetaState :
          begin
            do_emd.rand_mode(0);
            do_emd = 1;
            emd.rand_mode(emd==='x);
          end   
        hdr256.metafield!=ExtMetaState :
          begin
            do_emd.rand_mode(0);
            do_emd = 0;
          end   
      endcase
    end
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 :
      begin
        if (hdr68.rsvd      === 'x) hdr68.rsvd      = rand_hdr68.rsvd;
        if (hdr68.ldid      === 'x) hdr68.ldid      = rand_hdr68.ldid;
        if (hdr68.tc        === 'x) hdr68.tc        = rand_hdr68.tc;
        if (hdr68.poi       === 'x) hdr68.poi       = rand_hdr68.poi;
        if (hdr68.addr      === 'x) hdr68.addr      = rand_hdr68.addr;
        if (hdr68.tag       === 'x) hdr68.tag       = rand_hdr68.tag;
        if (hdr68.metavalue === 'x) hdr68.metavalue = rand_hdr68.metavalue;
        if (hdr68.metafield === 'x) hdr68.metafield = rand_hdr68.metafield;
        if (hdr68.snptype   === 'x) hdr68.snptype   = rand_hdr68.snptype;
        if (hdr68.memop     === 'x) hdr68.memop     = rand_hdr68.memop;
        if (hdr68.val       === 'x) hdr68.val       = rand_hdr68.val;
      end
      F256 :
      begin
        if (hdr256.rsvd      === 'x) hdr256.rsvd      = rand_hdr256.rsvd;
        if (hdr256.ckid      === 'x) hdr256.ckid      = rand_hdr256.ckid;
        if (hdr256.ldid      === 'x) hdr256.ldid      = rand_hdr256.ldid;
        if (hdr256.tc        === 'x) hdr256.tc        = rand_hdr256.tc;
        if (hdr256.poi       === 'x) hdr256.poi       = rand_hdr256.poi;
        if (hdr256.addr      === 'x) hdr256.addr      = rand_hdr256.addr;
        if (hdr256.tag       === 'x) hdr256.tag       = rand_hdr256.tag;
        if (hdr256.metavalue === 'x) hdr256.metavalue = rand_hdr256.metavalue;
        if (hdr256.metafield === 'x) hdr256.metafield = rand_hdr256.metafield;
        if (hdr256.snptype   === 'x) hdr256.snptype   = rand_hdr256.snptype;
        if (hdr256.memop     === 'x) hdr256.memop     = rand_hdr256.memop;
        if (hdr256.val       === 'x) hdr256.val       = rand_hdr256.val;
        // Transaction field restrictions
        if (hdr256.memop inside {MemRdFill, MemRdFillTEE}) begin
          hdr256.metafield = NoOp;
          hdr256.snptype   = M2SSnpNoOp;
        end
        // trp is dependent on other fields, not randomized
        hdr256.trp = (hdr256.memop inside {MemWrPtl, MemWrPtlTEE}) || 
                     (hdr256.metafield == ExtMetaState);
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    logic [511:0] masked_data;
    string str[4];
    string name;
    for (int ii=0; ii<64; ii++)
      masked_data[ii*8+:8] = dat[ii*8+:8] & {8{be[ii]}};
    super.do_print(printer);
    case (flitmode) 
      F68 :
      begin
        str[0] = $sformatf("'h%0h (%0s)", hdr68.metavalue, hdr68.metavalue.name);
        name = hdr68.metafield.name=="" ? "Rsvd" : hdr68.metafield.name;
        str[1] = $sformatf("'h%0h (%0s)", hdr68.metafield, name);
        name = hdr68.snptype.name=="" ? "Rsvd" : hdr68.snptype.name;
        str[2] = $sformatf("'h%0h (%0s)", hdr68.snptype,   name);
        str[3] = $sformatf("'h%0h (%0s)", hdr68.memop,     hdr68.memop.name);
        // ---- //
        printer.print_int   ("rsvd",      hdr68.rsvd, $bits(hdr68.rsvd));
        printer.print_int   ("ldid",      hdr68.ldid, $bits(hdr68.ldid));
        printer.print_int   ("tc",        hdr68.tc,   $bits(hdr68.tc));
        printer.print_int   ("poi",       hdr68.poi,  $bits(hdr68.poi));
        printer.print_int   ("addr",      hdr68.addr, $bits(hdr68.addr));
        printer.print_int   ("tag",       hdr68.tag,  $bits(hdr68.tag));
        printer.print_string("metavalue", str[0]); 
        printer.print_string("metafield", str[1]); 
        printer.print_string("snptype",   str[2]); 
        printer.print_string("memop",     str[3]); 
        printer.print_int   ("val",       hdr68.val,  $bits(hdr68.val));
        printer.print_int   ("data[0]",   dat[128*0+:128], 128);
        printer.print_int   ("data[1]",   dat[128*1+:128], 128);
        printer.print_int   ("data[2]",   dat[128*2+:128], 128);
        printer.print_int   ("data[3]",   dat[128*3+:128], 128);
        if (be !== '1) begin
          printer.print_int ("be", be, 64);
          printer.print_int ("data[0] (resultant)", masked_data[128*0+:128], 128);
          printer.print_int ("data[1] (resultant)", masked_data[128*1+:128], 128);
          printer.print_int ("data[2] (resultant)", masked_data[128*2+:128], 128);
          printer.print_int ("data[3] (resultant)", masked_data[128*3+:128], 128);
        end
      end
      F256 :
      begin
        str[0] = $sformatf("'h%0h (%0s)", hdr256.metavalue, hdr256.metavalue.name);
        name = hdr256.metafield.name=="" ? "Rsvd" : hdr256.metafield.name;
        str[1] = $sformatf("'h%0h (%0s)", hdr256.metafield, name);
        name = hdr256.snptype.name=="" ? "Rsvd" : hdr256.snptype.name;
        str[2] = $sformatf("'h%0h (%0s)", hdr256.snptype,   name);
        name = hdr256.memop.name=="" ? "Rsvd" : hdr256.memop.name;
        str[3] = $sformatf("'h%0h (%0s)", hdr256.memop,     hdr256.memop.name);
        // ---- //
        printer.print_int   ("rsvd",      hdr256.rsvd, $bits(hdr256.rsvd));
        printer.print_int   ("ckid",      hdr256.ckid, $bits(hdr256.ckid));
        printer.print_int   ("ldid",      hdr256.ldid, $bits(hdr256.ldid));
        printer.print_int   ("trp",       hdr256.trp,  $bits(hdr256.trp));
        printer.print_int   ("tc",        hdr256.tc,   $bits(hdr256.tc));
        printer.print_int   ("poi",       hdr256.poi,  $bits(hdr256.poi));
        printer.print_int   ("addr",      hdr256.addr, $bits(hdr256.addr));
        printer.print_int   ("tag",       hdr256.tag,  $bits(hdr256.tag));
        printer.print_string("metavalue", str[0]); 
        printer.print_string("metafield", str[1]); 
        printer.print_string("snptype",   str[2]); 
        printer.print_string("memop",     str[3]); 
        printer.print_int   ("val",       hdr256.val,  $bits(hdr256.val));
        printer.print_int   ("data[0]",   dat[128*0+:128], 128);
        printer.print_int   ("data[1]",   dat[128*1+:128], 128);
        printer.print_int   ("data[2]",   dat[128*2+:128], 128);
        printer.print_int   ("data[3]",   dat[128*3+:128], 128);
        if (be !== '1) begin
          printer.print_int ("be", be, 64);
          printer.print_int ("data[0] (resultant)", masked_data[128*0+:128], 128);
          printer.print_int ("data[1] (resultant)", masked_data[128*1+:128], 128);
          printer.print_int ("data[2] (resultant)", masked_data[128*2+:128], 128);
          printer.print_int ("data[3] (resultant)", masked_data[128*3+:128], 128);
        end
        if (hdr256.metafield==ExtMetaState) begin
          printer.print_int ("emd", emd, 32);
        end
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    m2srwd_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_hdr68  = _rhs.rand_hdr68;
      rand_hdr256 = _rhs.rand_hdr256;
      dat         = _rhs.dat;
      be          = _rhs.be;
      emd         = _rhs.emd;
      do_be       = _rhs.do_be;
      do_emd      = _rhs.do_emd;
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
            if (hdr68.rsvd      === 'x) hdr68.rsvd      = _rhs.hdr68.rsvd;
            if (hdr68.ldid      === 'x) hdr68.ldid      = _rhs.hdr68.ldid;
            if (hdr68.tc        === 'x) hdr68.tc        = _rhs.hdr68.tc;
            if (hdr68.poi       === 'x) hdr68.poi       = _rhs.hdr68.poi;
            if (hdr68.addr      === 'x) hdr68.addr      = _rhs.hdr68.addr;
            if (hdr68.tag       === 'x) hdr68.tag       = _rhs.hdr68.tag;
            if (hdr68.metavalue === 'x) hdr68.metavalue = _rhs.hdr68.metavalue;
            if (hdr68.metafield === 'x) hdr68.metafield = _rhs.hdr68.metafield;
            if (hdr68.snptype   === 'x) hdr68.snptype   = _rhs.hdr68.snptype;
            if (hdr68.memop     === 'x) hdr68.memop     = _rhs.hdr68.memop;
            if (hdr68.val       === 'x) hdr68.val       = _rhs.hdr68.val;
          end
          F256 :
          begin
            if (hdr256.rsvd      === 'x) hdr256.rsvd      = _rhs.hdr256.rsvd;
            if (hdr256.ckid      === 'x) hdr256.ckid      = _rhs.hdr256.ckid;
            if (hdr256.ldid      === 'x) hdr256.ldid      = _rhs.hdr256.ldid;
            if (hdr256.trp       === 'x) hdr256.trp       = _rhs.hdr256.trp;
            if (hdr256.tc        === 'x) hdr256.tc        = _rhs.hdr256.tc;
            if (hdr256.poi       === 'x) hdr256.poi       = _rhs.hdr256.poi;
            if (hdr256.addr      === 'x) hdr256.addr      = _rhs.hdr256.addr;
            if (hdr256.tag       === 'x) hdr256.tag       = _rhs.hdr256.tag;
            if (hdr256.metavalue === 'x) hdr256.metavalue = _rhs.hdr256.metavalue;
            if (hdr256.metafield === 'x) hdr256.metafield = _rhs.hdr256.metafield;
            if (hdr256.snptype   === 'x) hdr256.snptype   = _rhs.hdr256.snptype;
            if (hdr256.memop     === 'x) hdr256.memop     = _rhs.hdr256.memop;
            if (hdr256.val       === 'x) hdr256.val       = _rhs.hdr256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    m2srwd_c _rhs;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_compare failed")
    case (flitmode)
      F68 :
      begin
        do_compare &= comparer.compare_field_int("rsvd",      hdr68.rsvd,      _rhs.hdr68.rsvd,      $bits(hdr68.rsvd));
        do_compare &= comparer.compare_field_int("ldid",      hdr68.ldid,      _rhs.hdr68.ldid,      $bits(hdr68.ldid));
        do_compare &= comparer.compare_field_int("tc",        hdr68.tc,        _rhs.hdr68.tc,        $bits(hdr68.tc));
        do_compare &= comparer.compare_field_int("poi",       hdr68.poi,       _rhs.hdr68.poi,       $bits(hdr68.poi));
        do_compare &= comparer.compare_field_int("addr",      hdr68.addr,      _rhs.hdr68.addr,      $bits(hdr68.addr));
        do_compare &= comparer.compare_field_int("tag",       hdr68.tag,       _rhs.hdr68.tag,       $bits(hdr68.tag));
        do_compare &= comparer.compare_field_int("metavalue", hdr68.metavalue, _rhs.hdr68.metavalue, $bits(hdr68.metavalue));
        do_compare &= comparer.compare_field_int("metafield", hdr68.metafield, _rhs.hdr68.metafield, $bits(hdr68.metafield));
        do_compare &= comparer.compare_field_int("snptype",   hdr68.snptype,   _rhs.hdr68.snptype,   $bits(hdr68.snptype));
        do_compare &= comparer.compare_field_int("memop",     hdr68.memop,     _rhs.hdr68.memop,     $bits(hdr68.memop));
        do_compare &= comparer.compare_field_int("val",       hdr68.val,       _rhs.hdr68.val,       $bits(hdr68.val));
        do_compare &= comparer.compare_field    ("dat",       dat,             _rhs.dat,             $bits(dat));
        do_compare &= comparer.compare_field    ("be",        be,              _rhs.be,              $bits(be));
      end
      F256 :
      begin
        do_compare &= comparer.compare_field_int("rsvd",      hdr256.rsvd,      _rhs.hdr256.rsvd,      $bits(hdr256.rsvd));
        do_compare &= comparer.compare_field_int("ckid",      hdr256.ckid,      _rhs.hdr256.ckid,      $bits(hdr256.ckid));
        do_compare &= comparer.compare_field_int("ldid",      hdr256.ldid,      _rhs.hdr256.ldid,      $bits(hdr256.ldid));
        do_compare &= comparer.compare_field_int("trp",       hdr256.trp,       _rhs.hdr256.trp,       $bits(hdr256.trp));
        do_compare &= comparer.compare_field_int("tc",        hdr256.tc,        _rhs.hdr256.tc,        $bits(hdr256.tc));
        do_compare &= comparer.compare_field_int("poi",       hdr256.poi,       _rhs.hdr256.poi,       $bits(hdr256.poi));
        do_compare &= comparer.compare_field_int("addr",      hdr256.addr,      _rhs.hdr256.addr,      $bits(hdr256.addr));
        do_compare &= comparer.compare_field_int("tag",       hdr256.tag,       _rhs.hdr256.tag,       $bits(hdr256.tag));
        do_compare &= comparer.compare_field_int("metavalue", hdr256.metavalue, _rhs.hdr256.metavalue, $bits(hdr256.metavalue));
        do_compare &= comparer.compare_field_int("metafield", hdr256.metafield, _rhs.hdr256.metafield, $bits(hdr256.metafield));
        do_compare &= comparer.compare_field_int("snptype",   hdr256.snptype,   _rhs.hdr256.snptype,   $bits(hdr256.snptype));
        do_compare &= comparer.compare_field_int("memop",     hdr256.memop,     _rhs.hdr256.memop,     $bits(hdr256.memop));
        do_compare &= comparer.compare_field_int("val",       hdr256.val,       _rhs.hdr256.val,       $bits(hdr256.val));
        do_compare &= comparer.compare_field    ("dat",       dat,              _rhs.dat,              $bits(dat));
        do_compare &= comparer.compare_field    ("be",        be,               _rhs.be,               $bits(be));
        if (hdr256.metafield == ExtMetaState)
          do_compare &= comparer.compare_field  ("emd",       emd,              _rhs.emd,              $bits(emd));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

endclass

class m2sbirsp_c extends base_txn;

  `uvm_object_utils(m2sbirsp_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy of the birsp
  bit copy_over_x_only = 1'b1; 

         m2sbirsp256_t birsp256 = 'x;
  rand r_m2sbirsp256_t rand_birsp256;

  function new(string name = "m2sbirsp_c");
    super.new(name);
    txn_type = "S2M_BISNP";
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 : `uvm_fatal(get_type_name, "BIRsp channel not supported in 68B flit mode")
      F256 :
      begin
        if (birsp256.rsvd    === 'x) birsp256.rsvd    = rand_birsp256.rsvd;
        if (birsp256.lowaddr === 'x) birsp256.lowaddr = rand_birsp256.lowaddr;
        if (birsp256.bitag   === 'x) birsp256.bitag   = rand_birsp256.bitag;
        if (birsp256.biid    === 'x) birsp256.biid    = rand_birsp256.biid;
        if (birsp256.opcode  === 'x) birsp256.opcode  = rand_birsp256.opcode;
        if (birsp256.val     === 'x) birsp256.val     = rand_birsp256.val;
      end 
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    string str;
    super.do_print(printer);
    case (flitmode)
      F68 : `uvm_fatal(get_type_name, "BIRsp channel not supported in 68B flit mode")
      F256 :
      begin
        str = $sformatf("'h%0h (%0s)", birsp256.opcode, birsp256.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",    birsp256.rsvd,    $bits(birsp256.rsvd));
        printer.print_int   ("lowaddr", birsp256.lowaddr, $bits(birsp256.lowaddr));
        printer.print_int   ("bitag",   birsp256.bitag,   $bits(birsp256.bitag));
        printer.print_int   ("biid",    birsp256.biid,    $bits(birsp256.biid));
        printer.print_string("opcode",  str);
        printer.print_int   ("val",     birsp256.val,     $bits(birsp256.val));
      end 
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    m2sbirsp_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_birsp256 = _rhs.rand_birsp256;
      if (!copy_over_x_only) begin
        case (flitmode)
          F68  : `uvm_fatal(get_type_name, "BIRsp channel not supported in 68B flit mode")
          F256 : birsp256 = _rhs.birsp256;
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
      else begin
        case (flitmode)
          F68  : `uvm_fatal(get_type_name, "BIRsp channel not supported in 68B flit mode")
          F256 : 
          begin
            if (birsp256.rsvd    === 'x) birsp256.rsvd    = _rhs.birsp256.rsvd;
            if (birsp256.lowaddr === 'x) birsp256.lowaddr = _rhs.birsp256.lowaddr;
            if (birsp256.bitag   === 'x) birsp256.bitag   = _rhs.birsp256.bitag;
            if (birsp256.biid    === 'x) birsp256.biid    = _rhs.birsp256.biid;
            if (birsp256.opcode  === 'x) birsp256.opcode  = _rhs.birsp256.opcode;
            if (birsp256.val     === 'x) birsp256.val     = _rhs.birsp256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    m2sbirsp_c _rhs;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_compare failed")
    do_compare &= comparer.compare_field_int("rsvd",    birsp256.rsvd,    _rhs.birsp256.rsvd,    $bits(birsp256.rsvd));     
    do_compare &= comparer.compare_field_int("lowaddr", birsp256.lowaddr, _rhs.birsp256.lowaddr, $bits(birsp256.lowaddr));     
    do_compare &= comparer.compare_field_int("bitag",   birsp256.bitag,   _rhs.birsp256.bitag,   $bits(birsp256.bitag));
    do_compare &= comparer.compare_field_int("biid",    birsp256.biid,    _rhs.birsp256.biid,    $bits(birsp256.biid));
    do_compare &= comparer.compare_field_int("op",      birsp256.opcode,  _rhs.birsp256.opcode,  $bits(birsp256.opcode));
    do_compare &= comparer.compare_field_int("val",     birsp256.val,     _rhs.birsp256.val,     $bits(birsp256.val));
  endfunction

endclass

class s2mndr_c extends base_txn;

  `uvm_object_utils(s2mndr_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy of the ndr
  bit copy_over_x_only = 1'b1; 

         s2mndr68_t ndr68 = 'x;        s2mndr256_t ndr256 = 'x;
  rand r_s2mndr68_t rand_ndr68; rand r_s2mndr256_t rand_ndr256;

  function new(string name = "s2mndr_c");
    super.new(name);
    txn_type = "S2M_NDR";
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 :
      begin
        if (ndr68.devload   === 'x) ndr68.devload   = rand_ndr68.devload;
        if (ndr68.ldid      === 'x) ndr68.ldid      = rand_ndr68.ldid;
        if (ndr68.tag       === 'x) ndr68.tag       = rand_ndr68.tag;
        if (ndr68.metavalue === 'x) ndr68.metavalue = rand_ndr68.metavalue;
        if (ndr68.metafield === 'x) ndr68.metafield = rand_ndr68.metafield;
        if (ndr68.opcode    === 'x) ndr68.opcode    = rand_ndr68.opcode;
        if (ndr68.val       === 'x) ndr68.val       = rand_ndr68.val;
      end
      F256 :
      begin
        if (ndr256.rsvd      === 'x) ndr256.rsvd      = rand_ndr256.rsvd;
        if (ndr256.devload   === 'x) ndr256.devload   = rand_ndr256.devload;
        if (ndr256.ldid      === 'x) ndr256.ldid      = rand_ndr256.ldid;
        if (ndr256.tag       === 'x) ndr256.tag       = rand_ndr256.tag;
        if (ndr256.metavalue === 'x) ndr256.metavalue = rand_ndr256.metavalue;
        if (ndr256.metafield === 'x) ndr256.metafield = rand_ndr256.metafield;
        if (ndr256.opcode    === 'x) ndr256.opcode    = rand_ndr256.opcode;
        if (ndr256.val       === 'x) ndr256.val       = rand_ndr256.val;
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    string str[4];
    string name;
    super.do_print(printer);
    case (flitmode)
      F68 :
      begin
        str[0] = $sformatf("'h%0h (%0s)", ndr68.devload,   ndr68.devload.name);
        str[1] = $sformatf("'h%0h (%0s)", ndr68.metavalue, ndr68.metavalue.name);
        name = ndr68.metafield.name=="" ? "Rsvd" : ndr68.metafield.name;
        str[2] = $sformatf("'h%0h (%0s)", ndr68.metafield, name);
        str[3] = $sformatf("'h%0h (%0s)", ndr68.opcode,    ndr68.opcode.name);
        // ---- //
        printer.print_string("devload",   str[0]);
        printer.print_int   ("ldid",      ndr68.ldid, $bits(ndr68.ldid));
        printer.print_int   ("tag",       ndr68.tag,  $bits(ndr68.tag));
        printer.print_string("metavalue", str[1]);
        printer.print_string("metafield", str[2]);
        printer.print_string("opcode",    str[3]);
        printer.print_int   ("val",       ndr68.val,  $bits(ndr68.val));
      end
      F256 :
      begin
        str[0] = $sformatf("'h%0h (%0s)", ndr256.devload,   ndr256.devload.name);
        str[1] = $sformatf("'h%0h (%0s)", ndr256.metavalue, ndr256.metavalue.name);
        name = ndr256.metafield.name=="" ? "Rsvd" : ndr256.metafield.name;
        str[2] = $sformatf("'h%0h (%0s)", ndr256.metafield, name);
        str[3] = $sformatf("'h%0h (%0s)", ndr256.opcode,    ndr256.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",      ndr256.rsvd, $bits(ndr256.rsvd));
        printer.print_string("devload",   str[0]);
        printer.print_int   ("ldid",      ndr256.ldid, $bits(ndr256.ldid));
        printer.print_int   ("tag",       ndr256.tag,  $bits(ndr256.tag));
        printer.print_string("metavalue", str[1]);
        printer.print_string("metafield", str[2]);
        printer.print_string("opcode",    str[3]);
        printer.print_int   ("val",       ndr256.val,  $bits(ndr256.val));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    s2mndr_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_ndr68  = _rhs.rand_ndr68;
      rand_ndr256 = _rhs.rand_ndr256;
      if (!copy_over_x_only) begin
        case (flitmode)
          F68  : ndr68  = _rhs.ndr68;
          F256 : ndr256 = _rhs.ndr256;
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
      else begin
        case (flitmode)
          F68 :
          begin
            if (ndr68.devload   === 'x) ndr68.devload   = _rhs.ndr68.devload;           
            if (ndr68.ldid      === 'x) ndr68.ldid      = _rhs.ndr68.ldid;
            if (ndr68.tag       === 'x) ndr68.tag       = _rhs.ndr68.tag;
            if (ndr68.metavalue === 'x) ndr68.metavalue = _rhs.ndr68.metavalue;
            if (ndr68.metafield === 'x) ndr68.metafield = _rhs.ndr68.metafield;
            if (ndr68.opcode    === 'x) ndr68.opcode    = _rhs.ndr68.opcode;
            if (ndr68.val       === 'x) ndr68.val       = _rhs.ndr68.val;
          end
          F256 :
          begin
            if (ndr256.rsvd      === 'x) ndr256.rsvd      = _rhs.ndr256.rsvd;           
            if (ndr256.devload   === 'x) ndr256.devload   = _rhs.ndr256.devload;           
            if (ndr256.ldid      === 'x) ndr256.ldid      = _rhs.ndr256.ldid;
            if (ndr256.tag       === 'x) ndr256.tag       = _rhs.ndr256.tag;
            if (ndr256.metavalue === 'x) ndr256.metavalue = _rhs.ndr256.metavalue;
            if (ndr256.metafield === 'x) ndr256.metafield = _rhs.ndr256.metafield;
            if (ndr256.opcode    === 'x) ndr256.opcode    = _rhs.ndr256.opcode;
            if (ndr256.val       === 'x) ndr256.val       = _rhs.ndr256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    s2mndr_c _rhs;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_compare failed")
    case (flitmode) 
      F68 :
      begin
        do_compare &= comparer.compare_field_int("devload",   ndr68.devload,   _rhs.ndr68.devload,   $bits(ndr68.devload));
        do_compare &= comparer.compare_field_int("ldid",      ndr68.ldid,      _rhs.ndr68.ldid,      $bits(ndr68.ldid));     
        do_compare &= comparer.compare_field_int("tag",       ndr68.tag,       _rhs.ndr68.tag,       $bits(ndr68.tag));
        do_compare &= comparer.compare_field_int("metavalue", ndr68.metavalue, _rhs.ndr68.metavalue, $bits(ndr68.metavalue));
        do_compare &= comparer.compare_field_int("metafield", ndr68.metafield, _rhs.ndr68.metafield, $bits(ndr68.metafield));
        do_compare &= comparer.compare_field_int("opcode",    ndr68.opcode,    _rhs.ndr68.opcode,    $bits(ndr68.opcode));
        do_compare &= comparer.compare_field_int("val",       ndr68.val,       _rhs.ndr68.val,       $bits(ndr68.val));
      end
      F256 :
      begin
        do_compare &= comparer.compare_field_int("rsvd",      ndr256.rsvd,      _rhs.ndr256.rsvd,      $bits(ndr256.rsvd));
        do_compare &= comparer.compare_field_int("devload",   ndr256.devload,   _rhs.ndr256.devload,   $bits(ndr256.devload));
        do_compare &= comparer.compare_field_int("ldid",      ndr256.ldid,      _rhs.ndr256.ldid,      $bits(ndr256.ldid));     
        do_compare &= comparer.compare_field_int("tag",       ndr256.tag,       _rhs.ndr256.tag,       $bits(ndr256.tag));
        do_compare &= comparer.compare_field_int("metavalue", ndr256.metavalue, _rhs.ndr256.metavalue, $bits(ndr256.metavalue));
        do_compare &= comparer.compare_field_int("metafield", ndr256.metafield, _rhs.ndr256.metafield, $bits(ndr256.metafield));
        do_compare &= comparer.compare_field_int("opcode",    ndr256.opcode,    _rhs.ndr256.opcode,    $bits(ndr256.opcode));
        do_compare &= comparer.compare_field_int("val",       ndr256.val,       _rhs.ndr256.val,       $bits(ndr256.val));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

endclass

class s2mdrs_c extends base_txn;

  `uvm_object_utils(s2mdrs_c)

  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy of the hdr
  bit copy_over_x_only = 1'b1; 

         s2mdrs68_hdr_t hdr68 = 'x;        s2mdrs256_hdr_t hdr256 = 'x;
  rand r_s2mdrs68_hdr_t rand_hdr68; rand r_s2mdrs256_hdr_t rand_hdr256;

  rand logic [511:0]  dat;
  rand logic [ 31:0]  emd;
  rand logic          txfer_64B = 'x;
       bit            chunkval; //implied sideband; not part of CXL spec

  rand protected bit  do_emd;

  // Mostly don't do 32B transfers (only 10% of time)
  constraint c_sz  { txfer_64B dist {0 := 10, 1 := 90}; }
  // Mostly don't do EMD (only 40% of time)
  constraint c_emd { do_emd    dist {0 := 60, 1 := 40}; }
  // Disable EMD if desired
  constraint c_noemd { do_emd==0; }

  constraint c_f256 {
    if (!do_emd) {rand_hdr256.trp == 0; 
                  rand_hdr256.metafield != ExtMetaState;}
    else         {rand_hdr256.trp == 1; 
                  rand_hdr256.metafield == ExtMetaState;}
  }

  // 256B Flits
  //  - Control EMD presence
  //  1. Set the hdr256.metafield field depending on desired behavior
  //   a. hdr256.metafield=='x -> EMD presence is randomized unless 2. is active 
  //   b. hdr256.metafield==ExtMetaState -> user wants randomized EMD unless EMD!='x
  //   c. hdr256.metafield!=ExtMetaState -> user doesn't want EMD
  //  2. Set the emd field depending on desired behavior
  //   a. emd=='x -> extended metadata presence is randomized
  //   b. emd!='x -> user wants set extended metadata

  function new(string name = "s2mdrs_c");
    super.new(name);
    txn_type = "S2M_DRS";
    // EMD allowed by default
    c_noemd.constraint_mode(0);
  endfunction

  function void pre_randomize();
    case (flitmode)
      F68  : begin rand_hdr256.rand_mode(0); c_f256.constraint_mode(0); end
      F256 : begin rand_hdr68 .rand_mode(0);                            end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
    dat.rand_mode(dat==='x);
    if (flitmode == F68) begin
      txfer_64B.rand_mode(txfer_64B==='x);
      do_emd.rand_mode(0);
      emd = 0;
    end
    else begin
      txfer_64B.rand_mode(0);
      txfer_64B = 1;
      case (1'b1)
        hdr256.metafield==='x : 
          if (emd==='x) begin
            do_emd.rand_mode(1);
            emd.rand_mode(1);
          end
          else begin
            do_emd.rand_mode(0);
            do_emd = 1;
            emd.rand_mode(0);
          end
        hdr256.metafield==ExtMetaState :
          begin
            do_emd.rand_mode(0);
            do_emd = 1;
            emd.rand_mode(emd==='x);
          end   
        hdr256.metafield!=ExtMetaState :
          begin
            do_emd.rand_mode(0);
            do_emd = 0;
          end   
      endcase
    end
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 :
      begin
        if (hdr68.rsvd      === 'x) hdr68.rsvd      = rand_hdr68.rsvd;
        if (hdr68.devload   === 'x) hdr68.devload   = rand_hdr68.devload;
        if (hdr68.ldid      === 'x) hdr68.ldid      = rand_hdr68.ldid;
        if (hdr68.poi       === 'x) hdr68.poi       = rand_hdr68.poi;
        if (hdr68.tag       === 'x) hdr68.tag       = rand_hdr68.tag;
        if (hdr68.metavalue === 'x) hdr68.metavalue = rand_hdr68.metavalue;
        if (hdr68.metafield === 'x) hdr68.metafield = rand_hdr68.metafield;
        if (hdr68.opcode    === 'x) hdr68.opcode    = rand_hdr68.opcode;
        if (hdr68.val       === 'x) hdr68.val       = rand_hdr68.val;
      end
      F256 :
      begin
        if (hdr256.rsvd      === 'x) hdr256.rsvd      = rand_hdr256.rsvd;
        if (hdr256.devload   === 'x) hdr256.devload   = rand_hdr256.devload;
        if (hdr256.ldid      === 'x) hdr256.ldid      = rand_hdr256.ldid;
        if (hdr256.poi       === 'x) hdr256.poi       = rand_hdr256.poi;
        if (hdr256.tag       === 'x) hdr256.tag       = rand_hdr256.tag;
        if (hdr256.metavalue === 'x) hdr256.metavalue = rand_hdr256.metavalue;
        if (hdr256.metafield === 'x) hdr256.metafield = rand_hdr256.metafield;
        if (hdr256.opcode    === 'x) hdr256.opcode    = rand_hdr256.opcode;
        if (hdr256.val       === 'x) hdr256.val       = rand_hdr256.val;
        // trp is dependent on other fields, not randomized
        hdr256.trp = (hdr256.metafield == ExtMetaState);
        // If no EMD, just assign it to 0
        if (!hdr256.trp) emd = '0;
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    string str[4];
    string name;
    super.do_print(printer);
    case (flitmode)
      F68 :
      begin
        str[0] = $sformatf("'h%0h (%0s)", hdr68.devload,   hdr68.devload.name);
        str[1] = $sformatf("'h%0h (%0s)", hdr68.metavalue, hdr68.metavalue.name);
        name = hdr68.metafield.name=="" ? "Rsvd" : hdr68.metafield.name;
        str[2] = $sformatf("'h%0h (%0s)", hdr68.metafield, name);
        str[3] = $sformatf("'h%0h (%0s)", hdr68.opcode,    hdr68.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",      hdr68.rsvd, $bits(hdr68.rsvd));
        printer.print_string("devload",   str[0]);
        printer.print_int   ("ldid",      hdr68.ldid, $bits(hdr68.ldid));
        printer.print_int   ("poi",       hdr68.poi,  $bits(hdr68.poi));
        printer.print_int   ("tag",       hdr68.tag,  $bits(hdr68.tag));
        printer.print_string("metavalue", str[1]);
        printer.print_string("metafield", str[2]);
        printer.print_string("opcode",    str[3]);
        printer.print_int   ("val",       hdr68.val,  $bits(hdr68.val));
        if (!txfer_64B && chunkval) begin
          printer.print_int ("data[2]",   dat[128*2+:128], 128);
          printer.print_int ("data[3]",   dat[128*3+:128], 128);
        end
        else if (!txfer_64B && !chunkval) begin
          printer.print_int ("data[0]",   dat[128*0+:128], 128);
          printer.print_int ("data[1]",   dat[128*1+:128], 128);
        end
        else begin
          printer.print_int ("data[0]",   dat[128*0+:128], 128);
          printer.print_int ("data[1]",   dat[128*1+:128], 128);
          printer.print_int ("data[2]",   dat[128*2+:128], 128);
          printer.print_int ("data[3]",   dat[128*3+:128], 128);
        end
      end
      F256 :
      begin
        str[0] = $sformatf("'h%0h (%0s)", hdr256.devload,   hdr256.devload.name);
        str[1] = $sformatf("'h%0h (%0s)", hdr256.metavalue, hdr256.metavalue.name);
        name = hdr256.metafield.name=="" ? "Rsvd" : hdr256.metafield.name;
        str[2] = $sformatf("'h%0h (%0s)", hdr256.metafield, name);
        str[3] = $sformatf("'h%0h (%0s)", hdr256.opcode,    hdr256.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",      hdr256.rsvd, $bits(hdr256.rsvd));
        printer.print_int   ("trp",       hdr256.trp,  $bits(hdr256.trp));
        printer.print_string("devload",   str[0]);
        printer.print_int   ("ldid",      hdr256.ldid, $bits(hdr256.ldid));
        printer.print_int   ("poi",       hdr256.poi,  $bits(hdr256.poi));
        printer.print_int   ("tag",       hdr256.tag,  $bits(hdr256.tag));
        printer.print_string("metavalue", str[1]);
        printer.print_string("metafield", str[2]);
        printer.print_string("opcode",    str[3]);
        printer.print_int   ("val",       hdr256.val,  $bits(hdr256.val));
        printer.print_int   ("data[0]",   dat[128*0+:128], 128);
        printer.print_int   ("data[1]",   dat[128*1+:128], 128);
        printer.print_int   ("data[2]",   dat[128*2+:128], 128);
        printer.print_int   ("data[3]",   dat[128*3+:128], 128);
        if (hdr256.metafield==ExtMetaState)
          printer.print_int ("emd",       emd,  $bits(emd));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    s2mdrs_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_hdr68  = _rhs.rand_hdr68;
      rand_hdr256 = _rhs.rand_hdr256;
      emd         = _rhs.emd;
      dat         = _rhs.dat;
      txfer_64B   = _rhs.txfer_64B;
      chunkval    = _rhs.chunkval;
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
            if (hdr68.rsvd      === 'x) hdr68.rsvd      = _rhs.hdr68.rsvd;
            if (hdr68.devload   === 'x) hdr68.devload   = _rhs.hdr68.devload;
            if (hdr68.ldid      === 'x) hdr68.ldid      = _rhs.hdr68.ldid;
            if (hdr68.poi       === 'x) hdr68.poi       = _rhs.hdr68.poi;
            if (hdr68.tag       === 'x) hdr68.tag       = _rhs.hdr68.tag;
            if (hdr68.metavalue === 'x) hdr68.metavalue = _rhs.hdr68.metavalue;
            if (hdr68.metafield === 'x) hdr68.metafield = _rhs.hdr68.metafield;
            if (hdr68.opcode    === 'x) hdr68.opcode    = _rhs.hdr68.opcode;
            if (hdr68.val       === 'x) hdr68.val       = _rhs.hdr68.val;
          end
          F256 :
          begin
            if (hdr256.rsvd      === 'x) hdr256.rsvd      = _rhs.hdr256.rsvd;
            if (hdr256.trp       === 'x) hdr256.trp       = _rhs.hdr256.trp;
            if (hdr256.devload   === 'x) hdr256.devload   = _rhs.hdr256.devload;
            if (hdr256.ldid      === 'x) hdr256.ldid      = _rhs.hdr256.ldid;
            if (hdr256.poi       === 'x) hdr256.poi       = _rhs.hdr256.poi;
            if (hdr256.tag       === 'x) hdr256.tag       = _rhs.hdr256.tag;
            if (hdr256.metavalue === 'x) hdr256.metavalue = _rhs.hdr256.metavalue;
            if (hdr256.metafield === 'x) hdr256.metafield = _rhs.hdr256.metafield;
            if (hdr256.opcode    === 'x) hdr256.opcode    = _rhs.hdr256.opcode;
            if (hdr256.val       === 'x) hdr256.val       = _rhs.hdr256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    s2mdrs_c _rhs;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_compare failed")
    case (flitmode)
      F68 :
      begin    
         do_compare &= comparer.compare_field_int("rsvd",      hdr68.rsvd,      _rhs.hdr68.rsvd,      $bits(hdr68.rsvd));
         do_compare &= comparer.compare_field_int("devload",   hdr68.devload,   _rhs.hdr68.devload,   $bits(hdr68.devload));
         do_compare &= comparer.compare_field_int("ldid",      hdr68.ldid,      _rhs.hdr68.ldid,      $bits(hdr68.ldid));
         do_compare &= comparer.compare_field_int("poi",       hdr68.poi,       _rhs.hdr68.poi,       $bits(hdr68.poi));
         do_compare &= comparer.compare_field_int("tag",       hdr68.tag,       _rhs.hdr68.tag,       $bits(hdr68.tag));
         do_compare &= comparer.compare_field_int("metavalue", hdr68.metavalue, _rhs.hdr68.metavalue, $bits(hdr68.metavalue));
         do_compare &= comparer.compare_field_int("metafield", hdr68.metafield, _rhs.hdr68.metafield, $bits(hdr68.metafield));
         do_compare &= comparer.compare_field_int("opcode",    hdr68.opcode,    _rhs.hdr68.opcode,    $bits(hdr68.opcode));
         do_compare &= comparer.compare_field_int("val",       hdr68.val,       _rhs.hdr68.val,       $bits(hdr68.val));
         do_compare &= comparer.compare_field_int("txfer_64B", txfer_64B,       _rhs.txfer_64B,       $bits(txfer_64B));
         do_compare &= comparer.compare_field    ("dat",       dat,             _rhs.dat,             $bits(dat));
       end
      F256 :
      begin    
         do_compare &= comparer.compare_field_int("rsvd",      hdr256.rsvd,      _rhs.hdr256.rsvd,      $bits(hdr256.rsvd));
         do_compare &= comparer.compare_field_int("trp",       hdr256.trp,       _rhs.hdr256.trp,       $bits(hdr256.trp));
         do_compare &= comparer.compare_field_int("devload",   hdr256.devload,   _rhs.hdr256.devload,   $bits(hdr256.devload));
         do_compare &= comparer.compare_field_int("ldid",      hdr256.ldid,      _rhs.hdr256.ldid,      $bits(hdr256.ldid));
         do_compare &= comparer.compare_field_int("poi",       hdr256.poi,       _rhs.hdr256.poi,       $bits(hdr256.poi));
         do_compare &= comparer.compare_field_int("tag",       hdr256.tag,       _rhs.hdr256.tag,       $bits(hdr256.tag));
         do_compare &= comparer.compare_field_int("metavalue", hdr256.metavalue, _rhs.hdr256.metavalue, $bits(hdr256.metavalue));
         do_compare &= comparer.compare_field_int("metafield", hdr256.metafield, _rhs.hdr256.metafield, $bits(hdr256.metafield));
         do_compare &= comparer.compare_field_int("opcode",    hdr256.opcode,    _rhs.hdr256.opcode,    $bits(hdr256.opcode));
         do_compare &= comparer.compare_field_int("val",       hdr256.val,       _rhs.hdr256.val,       $bits(hdr256.val));
         do_compare &= comparer.compare_field    ("dat",       dat,              _rhs.dat,              $bits(dat));
         if (hdr256.metafield == ExtMetaState)
           do_compare &= comparer.compare_field  ("emd",       emd,              _rhs.emd,              $bits(emd));
       end
       FPBR : ;
       default : `uvm_fatal(get_type_name, "Need to specify flitmode")
     endcase
  endfunction

endclass

class s2mbisnp_c extends base_txn;

  `uvm_object_utils(s2mbisnp_c)
    
  flit_mode_t flitmode;

  // if a field === 'x, copy over from the source, else just leave alone
  // this allows me to do a sort of "partial" copy of the bisnp
  bit copy_over_x_only = 1'b1; 

         s2mbisnp256_t bisnp256 = 'x;
  rand r_s2mbisnp256_t rand_bisnp256;

  function new(string name = "s2mbisnp_c");
    super.new(name);
    txn_type = "S2M_BISNP";
  endfunction

  function void post_randomize();
    case (flitmode)
      F68 : `uvm_fatal(get_type_name, "BISnp channel not supported in 68B flit mode")
      F256 :
      begin
        if (bisnp256.rsvd   === 'x) bisnp256.rsvd   = rand_bisnp256.rsvd;
        if (bisnp256.addr   === 'x) bisnp256.addr   = rand_bisnp256.addr;
        if (bisnp256.bitag  === 'x) bisnp256.bitag  = rand_bisnp256.bitag;
        if (bisnp256.biid   === 'x) bisnp256.biid   = rand_bisnp256.biid;
        if (bisnp256.opcode === 'x) bisnp256.opcode = rand_bisnp256.opcode;
        if (bisnp256.val    === 'x) bisnp256.val    = rand_bisnp256.val;
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_print(uvm_printer printer);
    string str;
    super.do_print(printer);
    case (flitmode)
      F68 : `uvm_fatal(get_type_name, "BISnp channel not supported in 68B flit mode")
      F256 :
      begin
        str = $sformatf("'h%0h (%0s)", bisnp256.opcode, bisnp256.opcode.name);
        // ---- //
        printer.print_int   ("rsvd",   bisnp256.rsvd,  $bits(bisnp256.rsvd));
        printer.print_int   ("addr",   bisnp256.addr,  $bits(bisnp256.addr));
        printer.print_int   ("bitag",  bisnp256.bitag, $bits(bisnp256.bitag));
        printer.print_int   ("biid",   bisnp256.biid,  $bits(bisnp256.biid));
        printer.print_string("opcode", str);
        printer.print_int   ("val",    bisnp256.val,   $bits(bisnp256.val));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

  virtual function void do_copy(uvm_object rhs);
    s2mbisnp_c _rhs;
    super.do_copy(rhs);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_copy failed")
    else begin
      rand_bisnp256 = _rhs.rand_bisnp256;
      if (!copy_over_x_only) begin
        case (flitmode)
          F68  : `uvm_fatal(get_type_name, "BISnp channel not supported in 68B flit mode")
          F256 : bisnp256 = _rhs.bisnp256;
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
      else begin
        case (flitmode)
          F68 : `uvm_fatal(get_type_name, "BISnp channel not supported in 68B flit mode")
          F256 :
          begin
            if (bisnp256.rsvd  === 'x) bisnp256.rsvd   = _rhs.bisnp256.rsvd;
            if (bisnp256.addr  === 'x) bisnp256.addr   = _rhs.bisnp256.addr;
            if (bisnp256.bitag === 'x) bisnp256.bitag  = _rhs.bisnp256.bitag;
            if (bisnp256.biid  === 'x) bisnp256.biid   = _rhs.bisnp256.biid;
            if (bisnp256.opcode=== 'x) bisnp256.opcode = _rhs.bisnp256.opcode;
            if (bisnp256.val   === 'x) bisnp256.val    = _rhs.bisnp256.val;
          end
          FPBR : ;
          default : `uvm_fatal(get_type_name, "Need to specify flitmode")
        endcase
      end
    end
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    s2mbisnp_c _rhs;
    do_compare = super.do_compare(rhs, comparer);
    if (!$cast(_rhs, rhs))
      `uvm_fatal(get_type_name, "Cast in do_compare failed")
    case (flitmode)
      F68  : `uvm_fatal(get_type_name, "BISnp channel not supported in 68B flit mode")
      F256 :
      begin
        do_compare &= comparer.compare_field_int("rsvd",   bisnp256.rsvd,   _rhs.bisnp256.rsvd,   $bits(bisnp256.rsvd));     
        do_compare &= comparer.compare_field_int("addr",   bisnp256.addr,   _rhs.bisnp256.addr,   $bits(bisnp256.addr));     
        do_compare &= comparer.compare_field_int("bitag",  bisnp256.bitag,  _rhs.bisnp256.bitag,  $bits(bisnp256.bitag));
        do_compare &= comparer.compare_field_int("biid",   bisnp256.biid,   _rhs.bisnp256.biid,   $bits(bisnp256.biid));
        do_compare &= comparer.compare_field_int("opcode", bisnp256.opcode, _rhs.bisnp256.opcode, $bits(bisnp256.opcode));
        do_compare &= comparer.compare_field_int("val",    bisnp256.val,    _rhs.bisnp256.val,    $bits(bisnp256.val));
      end
      FPBR : ;
      default : `uvm_fatal(get_type_name, "Need to specify flitmode")
    endcase
  endfunction

endclass


