class elbi_share extends base_share;

  `uvm_object_utils(elbi_share)

  function new(string name = "elbi_share");
    super.new(name);
  endfunction

  string uid;

  typedef enum bit [2:0] {ZEROES, ONES, X, RAND, ERROR, FATAL} uninit_acc_t;

  // every aperture will have this populated
  typedef struct packed {
    logic  [31:0] saddr;
    logic  [31:0] eaddr;
    bit    [ 2:0] pf;
    bit    [ 2:0] bar;
    uninit_acc_t  uninit_acc; //to control reads before unit
    bit    [ 7:0] rsp_delay;
  } match_s;

  typedef bit [ 2:0] pf_t;
  typedef bit [ 2:0] bar_t;
  typedef bit [31:0] addr32_t;
  typedef bit [11:0] addr12_t;
  typedef bit [15:0] addr16_t;

  // keep independent memory spaces ; allowing up to 32 apertures
  logic [31:0] app [pf_t][bar_t][addr32_t];  match_s app_match [$:32];
  logic [31:0] erom[pf_t][addr32_t];         match_s erom_match[$:32];
  logic [31:0] io  [pf_t][bar_t][addr32_t];  match_s io_match  [$:32];
  logic [31:0] dbi [pf_t][addr12_t];         match_s dbi_match [$:32];
  logic [31:0] mbar[pf_t][addr16_t];         match_s mbar_match[$:32];

  // Users will call this to add a range of memory
  // - acc = {APP, MBAR0, IO, DBI, EROM} 
  // - base ; 'base address' e.g. 16'hA000
  // - offset ; 'offset address' e.g. 12'h0FFF
  // - pf ; 'physical function'
  // - bar = {0-5} ; some memories don't have BAR
  // - nbits = {1, 32} ; for masking 
  // - uninit_acc = {"ZEROES", "ONES", "X", "RAND", "ERROR", "FATAL"}
  // - rsp_delay; respond with {0,N} cycles of delay
  // - data ; register values incrementing from base
  virtual function void add_range(acc_t         acc, 
                                  bit    [31:0] base,
                                  bit    [31:0] offset,
                                  bit    [ 2:0] pf,
                                  logic  [ 2:0] bar        = 'x, 
                                  bit    [ 5:0] nbits      = 32,
                                  string        uninit_acc = "RAND",
                                  bit    [ 7:0] rsp_delay  = 0,
                                  logic  [31:0] data[]     = {}
  );
    uninit_acc_t ui_acc;
    logic [31:0] masked_base;
    logic [31:0] masked_end;
    // Do some error checking first
    if (!(acc inside {APP, MBAR0, IO, DBI, EROM})) begin
      `uvm_error(get_type_name, "Invalid arg 'acc'; returning")
      return;
    end
    if (acc inside {APP, IO} && bar==='x) begin
      `uvm_error(get_type_name, {"Must set arg 'bar' when acc is ", acc.name, "; returning"})
      return;
    end
    case (uninit_acc)
      "ZEROES" : ui_acc = ZEROES;
      "ONES"   : ui_acc = ONES;
      "RAND"   : ui_acc = RAND;
      "ERROR"  : ui_acc = ERROR;
      "FATAL"  : ui_acc = FATAL;
      default  : begin
                   `uvm_warning(get_type_name, {"Invalid arg 'uninit_acc' of ", uninit_acc, "; set to RAND"})
                   ui_acc = RAND; 
                 end
    endcase
    // upper bits not used and are x
    masked_base = base;
    masked_end  = base+offset;
    for (int ii=31; ii>=nbits; ii--) begin
      masked_base[ii] = 1'bx;
      masked_end [ii] = 1'bx;
    end
    case (1'b1)
      acc==APP   &&  app_match.size!=32 : ;
      acc==EROM  && erom_match.size!=32 : ;
      acc==MBAR0 && mbar_match.size!=32 : ;
      acc==IO    &&   io_match.size!=32 : ;
      acc==DBI   &&  dbi_match.size!=32 : ;
      default : begin
                  `uvm_warning(get_type_name, {"Aperture queue for ", acc.name, " is full; returning"}) 
                  return;
                end
    endcase
    case (acc)
      APP  :  app_match.push_back('{masked_base, masked_end, pf, bar, ui_acc, rsp_delay});
      EROM : erom_match.push_back('{masked_base, masked_end, pf, bar, ui_acc, rsp_delay});
      MBAR0: mbar_match.push_back('{masked_base, masked_end, pf, bar, ui_acc, rsp_delay});
      IO   :   io_match.push_back('{masked_base, masked_end, pf, bar, ui_acc, rsp_delay});
      DBI  :  dbi_match.push_back('{masked_base, masked_end, pf, bar, ui_acc, rsp_delay});
    endcase
    if (data.size) begin
      base = masked_base; //assign logic to bit; upper bits now 0
      foreach (data[ii]) begin
        case (acc)
          APP  :   app[pf][bar][base+ii*4] = data[ii];
          EROM :  erom[pf][base+ii*4]      = data[ii];
          MBAR0:  mbar[pf][base+ii*4]      = data[ii];
          IO   :    io[pf][bar][base+ii*4] = data[ii];
          DBI  :   dbi[pf][base+ii*4]      = data[ii];
        endcase
      end
    end
  endfunction

  // Users will call this to add a register of memory
  // ARGUMENTS
  // - acc = {APP, MBAR0, IO, DBI, EROM} 
  // - addr
  // - pf ; 'physical function'
  // - bar = {0-5} ; some memories don't have BAR
  // - nbits = {1, 32} ; for masking 
  // - uninit_acc = {"ZEROES", "ONES", "X", "RAND", "ERROR", "FATAL"}
  // - rsp_delay; respond with {0,N} cycles of delay
  // - data ; register value at addr
  virtual function void add_reg(acc_t         acc, 
                                bit    [31:0] addr,
                                bit    [ 2:0] pf,
                                logic  [ 2:0] bar        = 'x, 
                                bit    [ 5:0] nbits      = 32,
                                string        uninit_acc = "RAND",
                                bit    [ 7:0] rsp_delay  = 0,
                                logic [31:0]  data[$:1]  = {}
  );
    uninit_acc_t ui_acc;
    logic [31:0] mask_addr;
    // Do some error checking first
    if (!(acc inside {APP, MBAR0, IO, DBI, EROM})) begin
      `uvm_error(get_type_name, "Invalid arg 'acc'; returning")
      return;
    end
    if (acc inside {APP, IO} && bar==='x) begin
      `uvm_error(get_type_name, {"Must set arg 'bar' when acc is ", acc.name, "; returning"})
      return;
    end
    case (uninit_acc)
      "ZEROES" : ui_acc = ZEROES;
      "ONES"   : ui_acc = ONES;
      "RAND"   : ui_acc = RAND;
      "ERROR"  : ui_acc = ERROR;
      "FATAL"  : ui_acc = FATAL;
      default  : begin
                   `uvm_warning(get_type_name, {"Invalid arg 'uninit_acc' of ", uninit_acc, "; set to RAND"})
                   ui_acc = RAND; 
                 end
    endcase
    // upper bits not used and are x
    mask_addr = addr;
    for (int ii=31; ii>=nbits; ii--)
      mask_addr[ii] = 1'bx;
    case (1'b1)
      acc==APP   &&  app_match.size!=32 : ;
      acc==EROM  && erom_match.size!=32 : ;
      acc==MBAR0 && mbar_match.size!=32 : ;
      acc==IO    &&   io_match.size!=32 : ;
      acc==DBI   &&  dbi_match.size!=32 : ;
      default : begin
                  `uvm_warning(get_type_name, {"Aperture queue for ", acc.name, " is full; returning"}) 
                  return;
                end
    endcase
    case (acc)
      APP  :  app_match.push_back('{mask_addr, mask_addr, pf, bar, ui_acc, rsp_delay});
      EROM : erom_match.push_back('{mask_addr, mask_addr, pf, bar, ui_acc, rsp_delay});
      MBAR0: mbar_match.push_back('{mask_addr, mask_addr, pf, bar, ui_acc, rsp_delay});
      IO   :   io_match.push_back('{mask_addr, mask_addr, pf, bar, ui_acc, rsp_delay});
      DBI  :  dbi_match.push_back('{mask_addr, mask_addr, pf, bar, ui_acc, rsp_delay});
    endcase
    if (data.size) begin
      addr = mask_addr; //assign logic to bit; upper bits now 0
      case (acc)
        APP  :   app[pf][bar][addr] = data[0];
        EROM :  erom[pf][addr]      = data[0];
        MBAR0:  mbar[pf][addr]      = data[0];
        IO   :    io[pf][bar][addr] = data[0];
        DBI  :   dbi[pf][addr]      = data[0];
      endcase
    end
  endfunction

  // Given a request, return if it's a match to any memory here
  // Returns -1 if no match, else returns aperture hit
  virtual function int match(elbi_txn t);
    bit [31:0]      saddr;
    bit [31:0]      eaddr;
    bit [5:0]       nbits;
    acc_t           acc;
    bit      [31:0] addr;
    bit      [31:0] mask_addr;
    bit       [2:0] pf;
    bit       [2:0] bar;
    // unroll txn for better understanding
    addr = t.lbc_ext_addr;
    pf   = $clog2(t.lbc_ext_valid);
    bar  = t.lbc_ext_bar_num;
    acc  = acc_t'({t.lbc_ext_dbi_access, t.lbc_ext_rom_access,
                   t.lbc_ext_io_access,  t.lbc_ext_cxl_mbar0_access});
    // default
    match = -1;
    case (acc)
      APP : foreach (app_match[ii]) begin 
              // Check pf and bar
              if (pf!=app_match[ii].pf || bar!=app_match[ii].bar) 
                continue;
              // Find the number of bits to match
              mask_addr = addr;
              for (nbits=31; nbits>0; nbits--)
                if (app_match[ii].saddr[nbits]!==1'bx)
                  break;
                else 
                  mask_addr[nbits] = 1'b0;
              // Build aperture; masked bits will be 0 ('X logic to bit assignment)
              saddr = app_match[ii].saddr;
              eaddr = app_match[ii].eaddr;
              // Check if aperture hit
              if (mask_addr inside {[saddr:eaddr]}) begin
                return ii;
              end
            end
      EROM: foreach (erom_match[ii]) begin 
              // Check pf
              if (pf!=erom_match[ii].pf)
                continue;
              // Find the number of bits to match
              mask_addr = addr;
              for (nbits=31; nbits>0; nbits--)
                if (erom_match[ii].saddr[nbits]!==1'bx)
                  break;
                else 
                  mask_addr[nbits] = 1'b0;
              // Build aperture; masked bits will be 0 ('X logic to bit assignment)
              saddr = erom_match[ii].saddr;
              eaddr = erom_match[ii].eaddr;
              // Check if aperture hit
              if (mask_addr inside {[saddr:eaddr]}) begin
                return ii;
              end
            end
      IO  : foreach (io_match[ii]) begin 
              // Check pf and bar
              if (pf!=io_match[ii].pf || bar!=io_match[ii].bar) 
                continue;
              // Find the number of bits to match
              mask_addr = addr;
              for (nbits=31; nbits>0; nbits--)
                if (io_match[ii].saddr[nbits]!==1'bx)
                  break;
                else 
                  mask_addr[nbits] = 1'b0;
              // Build aperture; masked bits will be 0 ('X logic to bit assignment)
              saddr = io_match[ii].saddr;
              eaddr = io_match[ii].eaddr;
              // Check if aperture hit
              if (mask_addr inside {[saddr:eaddr]}) begin
                return ii;
              end
            end
      DBI : foreach (dbi_match[ii]) begin 
              // Check pf
              if (pf!=dbi_match[ii].pf)
                continue;
              // Find the number of bits to match
              mask_addr = addr;
              for (nbits=31; nbits>0; nbits--)
                if (dbi_match[ii].saddr[nbits]!==1'bx)
                  break;
                else 
                  mask_addr[nbits] = 1'b0;
              // Build aperture; masked bits will be 0 ('X logic to bit assignment)
              saddr = dbi_match[ii].saddr;
              eaddr = dbi_match[ii].eaddr;
              // Check if aperture hit
              if (mask_addr inside {[saddr:eaddr]}) begin
                return ii;
              end
            end
      MBAR0: foreach (mbar_match[ii]) begin 
              // Check pf
              if (pf!=mbar_match[ii].pf)
                continue;
              // Find the number of bits to match
              mask_addr = addr;
              for (nbits=31; nbits>0; nbits--)
                if (mbar_match[ii].saddr[nbits]!==1'bx)
                  break;
                else 
                  mask_addr[nbits] = 1'b0;
              // Build aperture; masked bits will be 0 ('X logic to bit assignment)
              saddr = mbar_match[ii].saddr;
              eaddr = mbar_match[ii].eaddr;
              // Check if aperture hit
              if (mask_addr inside {[saddr:eaddr]}) begin
                return ii;
              end
            end
    endcase
  endfunction
  
  virtual function elbi_txn get_response(elbi_txn t);
    bit               init;
    bit               wr;
    bit   [1:0][ 3:0] ben;
    int               idx;
    bit        [31:0] addr;
    bit        [31:0] mask_addr;
    bit        [ 2:0] bar;
    bit        [ 2:0] pf;
    logic [1:0][31:0] wdata;
    logic [1:0][31:0] rdata;
    acc_t             acc;
    elbi_txn          r = elbi_txn::type_id::create("r");
    // Helpful variable
    acc = acc_t'({t.lbc_ext_dbi_access, t.lbc_ext_rom_access,
                  t.lbc_ext_io_access,  t.lbc_ext_cxl_mbar0_access});
    // Pull out some txn metadata
    addr  = t.lbc_ext_addr;
    wr    = |t.lbc_ext_wr;
    pf    = $clog2(t.lbc_ext_valid);
    bar   = t.lbc_ext_bar_num;
    ben   = wr ? t.lbc_ext_wr : t.lbc_ext_rd;
    wdata = t.lbc_ext_dout;
    // Build response
    r.ext_lbc_ack = 1;
    r.ext_lbc_override_en = 0;
    /* WRITE */
    if (wr) begin
      r.ext_lbc_din = {$urandom, $urandom};
      // DW0
      if (ben[0]) begin
        // Check if match for lower DW
        idx = match(t);
        if (idx==-1) begin
          `uvm_warning(get_type_name, "No aperture match for received elbi txn; no response provided")
          return null;
        end
        // Get rsp delay from lower DW
        case (acc)
          APP  : begin
                   r.rsp_delay = $urandom_range(app_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (app_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          EROM : begin
                   r.rsp_delay = $urandom_range(erom_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (erom_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          MBAR0: begin
                   r.rsp_delay = $urandom_range(mbar_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (mbar_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          IO   : begin
                   r.rsp_delay = $urandom_range(io_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (io_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          DBI  : begin
                   r.rsp_delay = $urandom_range(dbi_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (dbi_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
        endcase
        foreach (ben[0][ii]) begin
          if (ben[0][ii]) begin
            case (acc)
              APP  :  app[pf][bar][addr][ii*8+:8] = wdata[0][ii*8+:8];
              EROM : erom[pf][addr][ii*8+:8]      = wdata[0][ii*8+:8];
              MBAR0: mbar[pf][addr][ii*8+:8]      = wdata[0][ii*8+:8];
              IO   :   io[pf][bar][addr][ii*8+:8] = wdata[0][ii*8+:8];
              DBI  :  dbi[pf][addr][ii*8+:8]      = wdata[0][ii*8+:8];
            endcase
          end
        end
      end
      // DW1
      if (ben[1]) begin
        // Upper DW accesses have to be QWORD aligned
        if (!addr[2]) begin
          t.lbc_ext_addr += 4;
          addr           += 4;
        end
        // Check if match for upper DW
        idx = match(t);
        if (idx==-1) begin
          `uvm_warning(get_type_name, "No aperture match for received elbi txn; no response provided")
          return null;
        end
        // Get rsp delay from upper DW
        case (acc)
          APP  : begin
                   r.rsp_delay = $urandom_range(app_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (app_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          EROM : begin
                   r.rsp_delay = $urandom_range(erom_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (erom_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          MBAR0: begin
                   r.rsp_delay = $urandom_range(mbar_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (mbar_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          IO   : begin
                   r.rsp_delay = $urandom_range(io_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (io_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          DBI  : begin
                   r.rsp_delay = $urandom_range(dbi_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (dbi_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
        endcase
        foreach (ben[1][ii]) begin
          if (ben[1][ii]) begin
            case (acc)
              APP  :  app[pf][bar][addr][ii*8+:8] = wdata[1][ii*8+:8];
              EROM : erom[pf][addr][ii*8+:8]      = wdata[1][ii*8+:8];
              MBAR0: mbar[pf][addr][ii*8+:8]      = wdata[1][ii*8+:8];
              IO   :   io[pf][bar][addr][ii*8+:8] = wdata[1][ii*8+:8];
              DBI  :  dbi[pf][addr][ii*8+:8]      = wdata[1][ii*8+:8];
            endcase
          end
        end
      end
    end
    /* READ */
    else begin
      // DW0
      rdata[0] = $urandom;
      if (ben[0]) begin
        init = 0;
        // Check if match for lower DW
        idx = match(t);
        if (idx==-1) begin
          `uvm_warning(get_type_name, "No aperture match for received elbi txn; no response provided")
          return null;
        end
        // Get rsp delay from lower DW
        case (acc)
          APP  : begin
                   r.rsp_delay = $urandom_range(app_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (app_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          EROM : begin
                   r.rsp_delay = $urandom_range(erom_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (erom_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          MBAR0: begin
                   r.rsp_delay = $urandom_range(mbar_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (mbar_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          IO   : begin
                   r.rsp_delay = $urandom_range(io_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (io_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          DBI  : begin
                   r.rsp_delay = $urandom_range(dbi_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (dbi_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
        endcase
        case (acc)
          APP  : if (app.exists(pf) && app[pf].exists(bar) && app[pf][bar].exists(addr)) 
                   {init, rdata[0]} = {1'b1, app[pf][bar][addr]};
          EROM : if (erom.exists(pf) && erom[pf].exists(addr)) 
                   {init, rdata[0]} = {1'b1, erom[pf][addr]};
          MBAR0: if (mbar.exists(pf) && mbar[pf].exists(addr)) 
                   {init, rdata[0]} = {1'b1, mbar[pf][addr]};
          IO   : if (io.exists(pf) && io[pf].exists(bar) && io[pf][bar].exists(addr)) 
                   {init, rdata[0]} = {1'b1, io[pf][bar][addr]};
          DBI  : if (dbi.exists(pf) && dbi[pf].exists(addr)) 
                   {init, rdata[0]} = {1'b1, dbi[pf][addr]};
        endcase
        if (!init) begin
          case (acc)
            APP : case (app_match[idx].uninit_acc)
                    ZEROES : rdata[0] = '0;
                    ONES   : rdata[0] = '1;
                    X      : rdata[0] = 'X;
                    RAND   : ;
                    ERROR  : `uvm_warning(get_type_name, $sformatf("Unitialized access to app space; pf=%0d, bar=%0d, addr=0x%h", pf, bar, addr))
                    FATAL  : `uvm_fatal(get_type_name, $sformatf("Unitialized access to app space; pf=%0d, bar=%0d, addr=0x%h", pf, bar, addr))
                  endcase
          endcase
        end
      end
      // DW1
      rdata[1] = $urandom;
      if (ben[1]) begin
        init = 0;
        // Upper DW accesses have to be QWORD aligned
        if (!addr[2]) begin
          t.lbc_ext_addr += 4;
          addr           += 4;
        end
        // Check if match for upper DW
        idx = match(t);
        if (idx==-1) begin
          `uvm_warning(get_type_name, "No aperture match for received elbi txn; no response provided")
          return null;
        end
        // Get rsp delay from upper DW
        case (acc)
          APP  : begin
                   r.rsp_delay = $urandom_range(app_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (app_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          EROM : begin
                   r.rsp_delay = $urandom_range(erom_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (erom_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          MBAR0: begin
                   r.rsp_delay = $urandom_range(mbar_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (mbar_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          IO   : begin
                   r.rsp_delay = $urandom_range(io_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (io_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
          DBI  : begin
                   r.rsp_delay = $urandom_range(dbi_match[idx].rsp_delay);
                   // Mask the addr upper bits
                   for (int ii=31; ii>0; ii--) begin
                     if (dbi_match[idx].saddr[ii]===1'bx)
                       addr[ii] = 1'b0;
                     else
                       break;
                   end
                 end
        endcase
        case (acc)
          APP  : if (app.exists(pf) && app[pf].exists(bar) && app[pf][bar].exists(addr)) 
                   {init, rdata[1]} = {1'b1, app[pf][bar][addr]};
          EROM : if (erom.exists(pf) && erom[pf].exists(addr)) 
                   {init, rdata[1]} = {1'b1, erom[pf][addr]};
          MBAR0: if (mbar.exists(pf) && mbar[pf].exists(addr)) 
                   {init, rdata[1]} = {1'b1, mbar[pf][addr]};
          IO   : if (io.exists(pf) && io[pf].exists(bar) && io[pf][bar].exists(addr)) 
                   {init, rdata[1]} = {1'b1, io[pf][bar][addr]};
          DBI  : if (dbi.exists(pf) && dbi[pf].exists(addr)) 
                   {init, rdata[1]} = {1'b1, dbi[pf][addr]};
        endcase
        if (!init) begin
          case (acc)
            APP : case (app_match[idx].uninit_acc)
                    ZEROES : rdata[1] = '0;
                    ONES   : rdata[1] = '1;
                    X      : rdata[1] = 'X;
                    RAND   : ;
                    ERROR  : `uvm_warning(get_type_name, $sformatf("Unitialized access to app space; pf=%0d, bar=%0d, addr=0x%h", pf, bar, addr))
                    FATAL  : `uvm_fatal(get_type_name, $sformatf("Unitialized access to app space; pf=%0d, bar=%0d, addr=0x%h", pf, bar, addr))
                  endcase
          endcase
        end
      end
      // Return data
      r.ext_lbc_din = rdata;
    end
    // Return complete object
    return r;
  endfunction

  // Print the apertures of any one space
  virtual function void print_apertures(acc_t acc, string ppend = "");
    match_s aper;    
    int     idx, eidx;
    string  id;
    string  msg;
    case (acc)
      APP  : begin id = "APP";   eidx =  app_match.size; end
      EROM : begin id = "EROM";  eidx = erom_match.size; end
      MBAR0: begin id = "MBAR0"; eidx = mbar_match.size; end
      IO   : begin id = "IO";    eidx =   io_match.size; end
      DBI  : begin id = "DBI";   eidx =  dbi_match.size; end
    endcase
    if (!eidx) begin
      `uvm_info(get_type_name, $sformatf("%0s%0s has no apertures", ppend, id), UVM_LOW)
      return;
    end
    `uvm_info(get_type_name, $sformatf("%0sPrinting all %0d apertures for %0s", ppend, eidx, id), UVM_LOW)
    forever begin  
      if (idx == eidx) break;
      case (acc)
        APP  : aper =  app_match[idx]; 
        EROM : aper = erom_match[idx];
        MBAR0: aper = mbar_match[idx];
        IO   : aper =   io_match[idx];
        DBI  : aper =  dbi_match[idx];
      endcase
      `uvm_info($sformatf("%0s[%0d]",id,idx), $sformatf("saddr:0x%h, eaddr:0x%h, pf:%0d, bar:%0d, uninit_acc:%0s, rsp_delay:%0d ", aper.saddr, aper.eaddr, aper.pf, aper.bar, aper.uninit_acc.name, aper.rsp_delay), UVM_NONE)
      idx++;
    end
  endfunction
  
  // Print ALL space apertures
  virtual function void print_all_apertures(string ppend = "");
    print_apertures(APP,   ppend);
    print_apertures(EROM,  ppend);
    print_apertures(MBAR0, ppend);
    print_apertures(IO,    ppend);
    print_apertures(DBI,   ppend);
  endfunction

 // Print the memory values of any one space; return the count
 // - (Opt.) select a PF or PF+BAR
 // - (Opt.) saddr=='x --> print all, else print between saddr:eaddr
 virtual function void print_mem(acc_t        acc, 
                                 int          pf    = -1,
                                 int          bar   = -1,
                                 logic [31:0] saddr = 'x, 
                                 bit   [31:0] eaddr = '1, 
                                 string       ppend = "");
   string msg;
   int    count;
   /* Get total DW count of memory and build print message */
   msg = $sformatf("%0sPrinting all memory for %0s", ppend, acc.name);
   case (acc)
     APP   : begin 
               // Build message
               if (pf!=-1) begin
                 msg = {msg, $sformatf(" given PF=%0d",pf)}; 
                 if (bar!=-1)
                   msg = {msg, $sformatf(" and BAR=%0d",bar)}; 
                 else
                   msg = {msg, " for all BARs"};
               end
               else
                 msg = {msg, " for all PFs and all BARs"}; 
               /* Get count */
               // Single PF...
               if (pf!=-1) begin
                 if (app.exists(pf)) begin
                   //...and Single BAR
                   if (bar!=-1 && app[pf].exists(bar))
                     count = app[pf][bar].size; 
                   //...and all BARs
                   else
                     foreach (app[pf,ii])
                       count += app[pf][ii].size;
                 end
               end
               // All PFs, all BARs
               else
                 foreach (app[ii,jj])
                   count += app[ii][jj].size;
             end
     IO    : begin 
               // Build message
               if (pf!=-1) begin
                 msg = {msg, $sformatf(" given PF=%0d",pf)}; 
                 if (bar!=-1)
                   msg = {msg, $sformatf(" and BAR=%0d",bar)}; 
                 else
                   msg = {msg, " for all BARs"};
               end
               else
                 msg = {msg, " for all PFs and all BARs"}; 
               /* Get count */
               // Single PF...
               if (pf!=-1) begin
                 if (io.exists(pf)) begin
                   //...and Single BAR
                   if (bar!=-1 && io[pf].exists(bar))
                     count = io[pf][bar].size; 
                   //...and all BARs
                   else
                     foreach (io[pf,ii])
                       count += io[pf][ii].size;
                 end
               end
               // All PFs, all BARs
               else
                 foreach (io[ii,jj])
                   count += io[ii][jj].size;
             end
     EROM  : begin 
               // Build message
               if (pf!=-1)
                 msg = {msg, $sformatf(" given PF=%0d",pf)}; 
               else
                 msg = {msg, " for all PFs"};
               /* Get count */
               // Single PF
               if (pf!=-1) begin
                 if (erom.exists(pf))
                   count = erom[pf].size;
               end
               // All PFs
               else
                 foreach (erom[ii])
                   count += erom[ii].size;
             end
     DBI   : begin 
               // Build message
               if (pf!=-1)
                 msg = {msg, $sformatf(" given PF=%0d",pf)}; 
               else
                 msg = {msg, " for all PFs"};
               /* Get count */
               // Single PF
               if (pf!=-1) begin
                 if (dbi.exists(pf))
                   count = dbi[pf].size;
               end
               // All PFs
               else
                 foreach (dbi[ii])
                   count += dbi[ii].size;
             end
     MBAR0 : begin 
               // Build message
               if (pf!=-1)
                 msg = {msg, $sformatf(" given PF=%0d",pf)}; 
               else
                 msg = {msg, " for all PFs"};
               /* Get count */
               // Single PF
               if (pf!=-1) begin
                 if (mbar.exists(pf))
                   count = mbar[pf].size;
               end
               // All PFs
               else
                 foreach (mbar[ii])
                   count += mbar[ii].size;
             end
   endcase
   msg = {msg, $sformatf("; %0d DW exist",count)};
   `uvm_info(get_type_name, msg, UVM_LOW)
   if (!count) 
     return;
   /* Print all memories, depending on saddr+eaddr */
   case (acc)
     APP   : if (pf!=-1) begin
               if (app.exists(pf)) begin
                 if (bar!=-1) begin
                   if (app[pf].exists(bar)) begin
                     foreach (app[pf,bar,kk]) begin
                       if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                         msg = $sformatf("APP[PF%0d][BAR%0d][0x%h]=0x%h",pf,bar,kk,app[pf][bar][kk]);
                         `uvm_info(get_type_name, msg, UVM_LOW)
                       end
                     end
                   end
                 end
                 else begin
                   foreach (app[pf,jj,kk]) begin
                     if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                       msg = $sformatf("APP[PF%0d][BAR%0d][0x%h]=0x%h",pf,jj,kk,app[pf][jj][kk]);
                       `uvm_info(get_type_name, msg, UVM_LOW)
                     end
                   end
                 end
               end
             end
             else begin
               foreach (app[ii,jj,kk]) begin
                 if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                   msg = $sformatf("APP[PF%0d][BAR%0d][0x%h]=0x%h",ii,jj,kk,app[ii][jj][kk]);
                   `uvm_info(get_type_name, msg, UVM_LOW)
                 end
               end
             end
     IO    : if (pf!=-1) begin
               if (io.exists(pf)) begin
                 if (bar!=-1) begin
                   if (io[pf].exists(bar)) begin
                     foreach (io[pf,bar,kk]) begin
                       if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                         msg = $sformatf("IO[PF%0d][BAR%0d][0x%h]=0x%h",pf,bar,kk,io[pf][bar][kk]);
                         `uvm_info(get_type_name, msg, UVM_LOW)
                       end
                     end
                   end
                 end
                 else begin
                   foreach (io[pf,jj,kk]) begin
                     if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                       msg = $sformatf("IO[PF%0d][BAR%0d][0x%h]=0x%h",pf,jj,kk,io[pf][jj][kk]);
                       `uvm_info(get_type_name, msg, UVM_LOW)
                     end
                   end
                 end
               end
             end
             else begin
               foreach (io[ii,jj,kk]) begin
                 if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                   msg = $sformatf("IO[PF%0d][BAR%0d][0x%h]=0x%h",ii,jj,kk,io[ii][jj][kk]);
                   `uvm_info(get_type_name, msg, UVM_LOW)
                 end
               end
             end
     EROM  : if (pf!=-1) begin
               if (erom.exists(pf)) begin
                 foreach (erom[pf,kk]) begin
                   if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                     msg = $sformatf("EROM[PF%0d][0x%h]=0x%h",pf,kk,erom[pf][kk]);
                     `uvm_info(get_type_name, msg, UVM_LOW)
                   end
                 end
               end
             end
             else begin
               foreach (erom[ii,kk]) begin
                 if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                   msg = $sformatf("EROM[PF%0d][0x%h]=0x%h",ii,kk,erom[ii][kk]);
                   `uvm_info(get_type_name, msg, UVM_LOW)
                 end
               end
             end
     DBI   : if (pf!=-1) begin
               if (dbi.exists(pf)) begin
                 foreach (dbi[pf,kk]) begin
                   if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                     msg = $sformatf("DBI[PF%0d][0x%h]=0x%h",pf,kk,dbi[pf][kk]);
                     `uvm_info(get_type_name, msg, UVM_LOW)
                   end
                 end
               end
             end
             else begin
               foreach (dbi[ii,kk]) begin
                 if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                   msg = $sformatf("DBI[PF%0d][0x%h]=0x%h",ii,kk,dbi[ii][kk]);
                   `uvm_info(get_type_name, msg, UVM_LOW)
                 end
               end
             end
     MBAR0 : if (pf!=-1) begin
               if (mbar.exists(pf)) begin
                 foreach (mbar[pf,kk]) begin
                   if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                     msg = $sformatf("MBAR0[PF%0d][0x%h]=0x%h",pf,kk,mbar[pf][kk]);
                     `uvm_info(get_type_name, msg, UVM_LOW)
                   end
                 end
               end
             end
             else begin
               foreach (mbar[ii,kk]) begin
                 if (saddr==='x || kk inside {[saddr:eaddr]}) begin
                   msg = $sformatf("DBI[MBAR0%0d][0x%h]=0x%h",ii,kk,mbar[ii][kk]);
                   `uvm_info(get_type_name, msg, UVM_LOW)
                 end
               end
             end
   endcase
 endfunction

endclass
