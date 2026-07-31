interface elbi_if;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  bit          agent_driven;
  
  wire         clk;

  wire         ext_lbc_override_en; //not used
  wire  [ 7:0] ext_lbc_ack;         //not used per SNPS behavior (any valid = good)
  wire  [63:0] ext_lbc_din;
  wire  [31:0] lbc_ext_addr;
  wire  [63:0] lbc_ext_dout;
  wire  [ 7:0] lbc_ext_valid;
  wire  [ 7:0] lbc_ext_cs;
  wire  [ 7:0] lbc_ext_wr;
  wire  [ 7:0] lbc_ext_rd;
  wire         lbc_ext_dbi_access;
  wire         lbc_ext_cxl_mbar0_access;
  wire         lbc_ext_rom_access;
  wire         lbc_ext_io_access;
  wire  [ 2:0] lbc_ext_bar_num;
  wire  [ 7:0] lbc_ext_vfunc_num;
  wire         lbc_ext_vfunc_active;

  // Don't touch
  logic        i_ext_lbc_override_en      = 'z;
  logic [ 7:0] i_ext_lbc_ack              = 'z;
  logic [63:0] i_ext_lbc_din              = 'z;
  logic [31:0] i_lbc_ext_addr             = 'z;
  logic [63:0] i_lbc_ext_dout             = 'z;
  logic [ 7:0] i_lbc_ext_valid            = 'z;
  logic [ 7:0] i_lbc_ext_cs               = 'z;
  logic [ 7:0] i_lbc_ext_wr               = 'z;
  logic [ 7:0] i_lbc_ext_rd               = 'z;
  logic        i_lbc_ext_dbi_access       = 'z;
  logic        i_lbc_ext_cxl_mbar0_access = 'z;
  logic        i_lbc_ext_rom_access       = 'z;
  logic        i_lbc_ext_io_access        = 'z;
  logic [ 2:0] i_lbc_ext_bar_num          = 'z;
  logic [ 7:0] i_lbc_ext_vfunc_num        = 'z;
  logic        i_lbc_ext_vfunc_active     = 'z;
  // this can be used to control an external mux in case a user
  // wants to combine this agent with separate RTL
  bit          select;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_* nets directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a
  // passive slave and not have to worry about changing the interface,
  // only the configuration object
  assign ext_lbc_override_en      = i_ext_lbc_override_en;
  assign ext_lbc_ack              = i_ext_lbc_ack;
  assign ext_lbc_din              = i_ext_lbc_din;
  assign lbc_ext_addr             = i_lbc_ext_addr;
  assign lbc_ext_dout             = i_lbc_ext_dout;
  assign lbc_ext_valid            = i_lbc_ext_valid;
  assign lbc_ext_cs               = i_lbc_ext_cs;
  assign lbc_ext_wr               = i_lbc_ext_wr;
  assign lbc_ext_rd               = i_lbc_ext_rd;
  assign lbc_ext_dbi_access       = i_lbc_ext_dbi_access;
  assign lbc_ext_cxl_mbar0_access = i_lbc_ext_cxl_mbar0_access;
  assign lbc_ext_rom_access       = i_lbc_ext_rom_access;
  assign lbc_ext_io_access        = i_lbc_ext_io_access;
  assign lbc_ext_bar_num          = i_lbc_ext_bar_num;
  assign lbc_ext_vfunc_num        = i_lbc_ext_vfunc_num;
  assign lbc_ext_vfunc_active     = i_lbc_ext_vfunc_active;

  // Master agent will drive some of the i_* signals 
  // Active slave agent will drive some other i_* signals 
  // Passive slave agent will just monitor all signals
  clocking dcb @(posedge clk);
    output i_ext_lbc_override_en,
           i_ext_lbc_ack,
           i_ext_lbc_din,
           i_lbc_ext_addr,
           i_lbc_ext_dout,
           i_lbc_ext_valid,
           i_lbc_ext_cs,
           i_lbc_ext_wr,
           i_lbc_ext_rd,
           i_lbc_ext_dbi_access,
           i_lbc_ext_cxl_mbar0_access,
           i_lbc_ext_rom_access,
           i_lbc_ext_io_access,
           i_lbc_ext_bar_num,
           i_lbc_ext_vfunc_num,
           i_lbc_ext_vfunc_active,
           select;
  endclocking

  clocking mcb @(posedge clk);
    input  ext_lbc_override_en,
           ext_lbc_ack,
           ext_lbc_din,
           lbc_ext_addr,
           lbc_ext_dout,
           lbc_ext_valid,
           lbc_ext_cs,
           lbc_ext_wr,
           lbc_ext_rd,
           lbc_ext_dbi_access,
           lbc_ext_cxl_mbar0_access,
           lbc_ext_rom_access,
           lbc_ext_io_access,
           lbc_ext_bar_num,
           lbc_ext_vfunc_num,
           lbc_ext_vfunc_active;
  endclocking

  // Use this as trigger for new transaction
  logic        req_trigger;
  logic        redge_valid;
  logic        redge_cs;
  logic [ 7:0] lbc_ext_valid_q;
  logic [ 7:0] lbc_ext_cs_q;
  assign redge_valid = ({|lbc_ext_valid, |lbc_ext_valid_q}==2'b10);
  assign redge_cs    = ({|lbc_ext_cs,    |lbc_ext_cs_q   }==2'b10);
  assign req_trigger = redge_valid || redge_cs;
  always_ff @(posedge clk) begin
    lbc_ext_valid_q <= lbc_ext_valid;
    lbc_ext_cs_q    <= lbc_ext_cs;
  end

  // Use this as trigger for response
  logic        rsp_trigger;
  logic        redge_ack;
  logic        ext_lbc_ack_q;
  assign redge_ack   = ({ext_lbc_ack,ext_lbc_ack_q}==2'b10);
  assign rsp_trigger = redge_ack;
  always_ff @(posedge clk)
    ext_lbc_ack_q <= ext_lbc_ack;

  bit pflag[0:3]; //avoid multiple repetitions

  // Gate the assertion until it's settled
  bit ready_oap; //oap="override assert property"
  initial begin
    wait(ext_lbc_override_en===1'b0);
    ready_oap = 1'b1;
  end

  // property definitions
  property override_assert_p;
    @(posedge clk) 
    disable iff (pflag[0] || !ready_oap)
    (ext_lbc_override_en==1'b0);
  endproperty 

  property vld_acc_p;
    @(posedge clk) 
    disable iff (pflag[1])
    $rose(lbc_ext_cs) |-> $countones({lbc_ext_dbi_access,
                                      lbc_ext_cxl_mbar0_access,
                                      lbc_ext_rom_access,
                                      lbc_ext_io_access}) inside {0,1};
  endproperty

  property vld_rd_ben_p;
    @(posedge clk)
    disable iff (!$countones(lbc_ext_valid) || pflag[2])
    lbc_ext_rd inside {'0, 8'h0F, 8'hF0, '1};
  endproperty

  property vld_rd_wr_p;
    @(posedge clk)
    disable iff (!$countones(lbc_ext_valid) || pflag[3])
    !(lbc_ext_rd && lbc_ext_wr);
  endproperty
  
  // assert the properties
  override_assert_chk : assert property (override_assert_p) else begin
    `uvm_error("elbi_if", "override_assert_chk failed : ext_lbc_override_en not used")
    pflag[0]=1;
  end

  one_acc_chk : assert property (vld_acc_p) else begin
    `uvm_error("elbi_if", "one_acc_chk failed")
    pflag[1]=1;
  end

  vld_rd_ben_chk : assert property (vld_rd_ben_p) else begin
    `uvm_error("elbi_if", "vld_rd_ben_chk failed")
    pflag[2]=1;
  end

  rd_or_wr_chk : assert property (vld_rd_wr_p) else begin
    `uvm_error("elbi_if", "rd_or_wr_chk failed")
    pflag[3]=1;
  end

endinterface
