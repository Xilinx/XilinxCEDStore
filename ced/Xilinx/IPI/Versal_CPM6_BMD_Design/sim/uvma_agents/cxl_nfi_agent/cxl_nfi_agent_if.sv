// The AMD CXL interface to the PL is a set of N 64B chunks, where N=[1:3]. 
// A CXL link that has trained to 68B flit mode will issue multiple flits on 
// this interface, while a 256B flit mode link will issue flit-chunks. The 
// generic term used for each chunk is also known as a slot-set.
interface cxl_nfi_agent_if #(
  parameter NFI_W = 3
);

  localparam WDAT = 512;
  localparam WPAR =  8;
  localparam WDEC = 16;

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  
  bit  agent_driven;

  wire clk;

  wire [NFI_W-1:0][WDAT-1:0] data;
  wire [NFI_W-1:0][WPAR-1:0] parity;
  wire [NFI_W-1:0]           viral;
  wire [NFI_W-1:0]           valid;
  wire [      4:0]           ready;
  wire [NFI_W-1:0]           adf;
  wire [NFI_W-1:0]           last;
  wire [NFI_W-1:0][     3:0] dec_sop;
  wire [NFI_W-1:0][     3:0] dec_eop;
  wire [NFI_W-1:0][     3:0] dec_be;
  wire [NFI_W-1:0][     3:0] dec_mem;

  // Don't touch
  logic  [NFI_W-1:0][WDAT-1:0] i_data    = 'z;
  logic  [NFI_W-1:0][WPAR-1:0] i_parity  = 'z;
  logic  [NFI_W-1:0]           i_viral   = 'z;
  logic  [NFI_W-1:0]           i_valid   = 'z;
  logic  [      4:0]           i_ready   = 'z;
  logic  [NFI_W-1:0]           i_adf     = 'z;
  logic  [NFI_W-1:0]           i_last    = 'z;
  logic  [NFI_W-1:0][     3:0] i_dec_sop = 'z;
  logic  [NFI_W-1:0][     3:0] i_dec_eop = 'z;
  logic  [NFI_W-1:0][     3:0] i_dec_be  = 'z;
  logic  [NFI_W-1:0][     3:0] i_dec_mem = 'z;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_* nets directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a
  // passive slave and not have to worry about changing the interface,
  // only the configuration object
  assign data     = i_data;
  assign parity   = i_parity;
  assign viral    = i_viral;
  assign valid    = i_valid;
  assign ready    = i_ready;
  assign adf      = i_adf;
  assign last     = i_last;
  assign dec_sop  = i_dec_sop;
  assign dec_eop  = i_dec_eop;
  assign dec_be   = i_dec_be;
  assign dec_mem  = i_dec_mem;

  // Control for interface
  bit valid_only_mode;

  // dcb = "driver clocking block"
  clocking dcb @(posedge clk);
    output i_valid,
           i_data,
           i_parity,
           i_viral,
           i_ready,
           i_adf,
           i_last,
           i_dec_sop,
           i_dec_eop,
           i_dec_be,
           i_dec_mem;
  endclocking

  // mcb = "monitor clocking block" ; not qualified by anything
  clocking mcb @(posedge clk);
    input valid,
          data,
          parity,
          viral,
          ready,
          adf,
          last,
          dec_sop,
          dec_eop,
          dec_be,
          dec_mem;
  endclocking

  /* Assertions */
  logic       en_assert = 1'bx;
  bit         en_xz_check  = 1'b1;
  bit         right_align;
  int         nfi_width;
  bit         f68_mode;
  bit         h2c;
  bit         no_drive_dec_assts;

  // Auto-enable assertions
  initial begin
    wait(valid === '0);
    en_assert = en_assert === 1'bx ? 1'b1 : en_assert;
  end

  property no_valid_no_dec_sop_check(flit);
  //@(mcb iff (mcb.valid[flit]===1'b0))
  //@(posedge clk iff (mcb.valid[flit]===1'b0))
    @(posedge clk iff (valid[flit]===1'b0))
    disable iff (!en_assert || no_drive_dec_assts)
  //$countones(mcb.dec_sop[flit])==0;
    $countones(dec_sop[flit])==0;
  endproperty

  property no_valid_no_dec_eop_check(flit);
  //@(mcb iff (mcb.valid[flit]===1'b0))
  //@(posedge clk iff (mcb.valid[flit]===1'b0))
    @(posedge clk iff (valid[flit]===1'b0))
    disable iff (!en_assert || no_drive_dec_assts)
  //$countones(mcb.dec_eop[flit])==0;
    $countones(dec_eop[flit])==0;
  endproperty

  property no_valid_no_dec_mem_check(flit);
  //@(mcb iff (mcb.valid[flit]===1'b0))
  //@(posedge clk iff (mcb.valid[flit]===1'b0))
    @(posedge clk iff (valid[flit]===1'b0))
    disable iff (!en_assert || no_drive_dec_assts)
  //$countones(mcb.dec_mem[flit][3:0])==0;
    $countones(dec_mem[flit][3:0])==0;
  endproperty

  property no_valid_no_dec_be_check(flit);
  //@(mcb iff (mcb.valid[flit]===1'b0))
  //@(posedge clk iff (mcb.valid[flit]===1'b0))
    @(posedge clk iff (valid[flit]===1'b0))
    disable iff (!en_assert || no_drive_dec_assts)
  //$countones(mcb.dec_be[flit])==0;
    $countones(dec_be[flit])==0;
  endproperty

  property right_align_check;
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready))) 
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready))) 
    @(posedge clk iff (valid && (valid_only_mode || ready))) 
    disable iff (!en_assert || !right_align)
  //(mcb.valid >> $countones(mcb.valid)) == 0;
    (valid >> $countones(valid)) == 0;
  endproperty 

  property dual_sop_f68_check(flit);
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert || !f68_mode || h2c)
  //($countones(mcb.dec_sop[flit])==2) |-> mcb.dec_sop==4'b1010; //S2M, 32B txfers
    ($countones(dec_sop[flit])==2) |-> dec_sop==4'b1010; //S2M, 32B txfers
  endproperty

  property dual_eop_f68_check(flit);
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert || !f68_mode || h2c)
  //($countones(mcb.dec_eop[flit])==2) |-> mcb.dec_eop==4'b1010; //S2M, 32B txfers
    ($countones(dec_eop[flit])==2) |-> dec_eop==4'b1010; //S2M, 32B txfers
  endproperty

  property max_valid_check;
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert)
  //$countones(mcb.valid) <= nfi_width;
    $countones(valid) <= nfi_width;
  endproperty

  property max_sop_check(flit);
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert)
  //$countones(mcb.dec_sop[flit]) <= ((f68_mode && !h2c) ? 2 : 1); //2 => S2M, 32B txfers
    $countones(dec_sop[flit]) <= ((f68_mode && !h2c) ? 2 : 1); //2 => S2M, 32B txfers
  endproperty

  property max_eop_check(flit);
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert || !mcb.valid[flit])
  //$countones(mcb.dec_eop[flit]) <= ((f68_mode && !h2c) ? 2 : 1); //2 => S2M, 32B txfers
    $countones(dec_eop[flit]) <= ((f68_mode && !h2c) ? 2 : 1); //2 => S2M, 32B txfers
  endproperty

  property max_be_check(flit);
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert)
  //$countones(mcb.dec_be[flit]) <= 1;
    $countones(dec_be[flit]) <= 1;
  endproperty

  property max_mem_check(flit);
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert || !mcb.valid[flit])
  //$countones(mcb.dec_mem[flit]) <= 1;
    $countones(dec_mem[flit]) <= 1;
  endproperty

  property eop_be_align(flit, x);
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert)
  //mcb.dec_be[flit][x] |-> mcb.dec_eop[flit][x];
    dec_be[flit][x] |-> dec_eop[flit][x];
  endproperty

  property sop_mem_align(flit, x);
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert)
  //mcb.dec_mem[flit][x] |-> mcb.dec_sop[flit][x];
    dec_mem[flit][x] |-> dec_sop[flit][x];
  endproperty

  property xz_dat_check(flit);
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert || !en_xz_check)
    ($countbits(data[flit], 'x, 'z) == 0);
  endproperty

  property xz_assist_check(flit);
  //@(mcb iff (mcb.valid && (valid_only_mode || mcb.ready)))
  //@(posedge clk iff (mcb.valid && (valid_only_mode || mcb.ready)))
    @(posedge clk iff (valid && (valid_only_mode || ready)))
    disable iff (!en_assert || !en_xz_check || no_drive_dec_assts)
  /*($countbits(mcb.dec_mem[flit], 'x, 'z) == 0) &&
    ($countbits(mcb.dec_sop[flit], 'x, 'z) == 0) &&
    ($countbits(mcb.dec_eop[flit], 'x, 'z) == 0) &&
    ($countbits(mcb.dec_be [flit], 'x, 'z) == 0); */
    ($countbits(dec_mem[flit], 'x, 'z) == 0) &&
    ($countbits(dec_sop[flit], 'x, 'z) == 0) &&
    ($countbits(dec_eop[flit], 'x, 'z) == 0) &&
    ($countbits(dec_be [flit], 'x, 'z) == 0);
  endproperty

  aprop_rightalign : assert property(right_align_check) else
                       `uvm_error("cxl_nfi_agent_if", "aprop_rightalign assertion failure") 
  aprop_maxvalid   : assert property(max_valid_check) else 
                       `uvm_error("cxl_nfi_agent_if", "aprop_maxvalid assertion failure")
  // Per-flit checks
  generate 
    for (genvar ii=0; ii<NFI_W; ii++) begin
      aprop_no_sop : assert property(no_valid_no_dec_sop_check(ii)) else
                       `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_no_sop_%0d assertion failure",ii));
      aprop_no_eop : assert property(no_valid_no_dec_eop_check(ii)) else
                       `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_no_eop_%0d assertion failure",ii));
      aprop_no_mem : assert property(no_valid_no_dec_mem_check(ii)) else
                       `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_no_mem_%0d assertion failure",ii));
      aprop_no_be  : assert property(no_valid_no_dec_be_check(ii)) else
                       `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_no_be_%0d assertion failure",ii));
      aprop_xz_dat    : assert property(xz_dat_check(ii)) else
                          `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_xz_dat_%0d assertion failure",ii));
      aprop_xz_assist : assert property(xz_assist_check(ii)) else 
                          `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_xz_assist_%0d assertion failure",ii));
      aprop_maxsop    : assert property(max_sop_check(ii)) else 
                          `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_maxsop_%0d assertion failure",ii));
      aprop_maxeop    : assert property(max_eop_check(ii)) else 
                          `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_maxeop_%0d assertion failure",ii));
      aprop_dualeop   : assert property(dual_eop_f68_check(ii)) else 
                          `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_dualeop_%0d assertion failure",ii));
      aprop_dualsop   : assert property(dual_sop_f68_check(ii)) else 
                          `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_dualsop_%0d assertion failure",ii));
      aprop_maxbe     : assert property(max_be_check(ii))  else 
                          `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_maxbe_%0d assertion failure",ii));
      aprop_maxmem    : assert property(max_mem_check(ii)) else 
                          `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_maxmem_%0d assertion failure",ii));
      for (genvar kk=0; kk<4; kk++) begin
        aprop_eop_be  : assert property(eop_be_align(ii,kk)) else 
                          `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_eop_be_%0d_%0d assertion failure",ii,kk));
        aprop_sop_mem : assert property(sop_mem_align(ii,kk)) else 
                          `uvm_error("cxl_nfi_agent_if", $sformatf("aprop_sop_mem_%0d_%0d assertion failure",ii,kk));
      end
    end
  endgenerate
 
endinterface : cxl_nfi_agent_if
