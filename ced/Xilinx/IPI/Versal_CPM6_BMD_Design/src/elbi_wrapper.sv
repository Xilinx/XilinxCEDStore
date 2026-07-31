///////////////////////////////////////////////////////
//
//  Filename: elbi_wrapper.sv
//  Description: File to use directly when using elbi2axil bridge
//               1. Instantiates wrapper
//               2. Connects ports via wires to elbi2axi_top
///////////////////////////////////////////////////////


//***************************************************************************************************************
//******************************  ELBI WRAPPER INSTANTIATION ****************************************************
//***************************************************************************************************************

// elbi_wrapper # (
   // .AXIL_ADDR_WIDTH(64),
   // .AXIL_DATA_WIDTH(64),
   // .AXIL_AXUSER_WIDTH(8)
// ) u_elbi_wrapper_bot(
   // /* Clock Interface */
    // .pl_aximm_clk   (pl_aximm_clk_1)  // PL AXI-MM Clock.
   // ,.pl_aximm_rst_n (pl_aximm_rst_n_1)  // PL AXI-MM Reset.

   // /* ELBI slave interface connections */
   // ,.pcie1_elbi_ext_lbc_override_en       (elbi_afifo2pl_if_bot.ext_lbc_override_en)
   // ,.pcie1_elbi_ext_lbc_ack               (elbi_afifo2pl_if_bot.ext_lbc_ack)
   // ,.pcie1_elbi_ext_lbc_din               (elbi_afifo2pl_if_bot.ext_lbc_din)
   // ,.pcie1_elbi_lbc_ext_addr              (elbi_afifo2pl_if_bot.lbc_ext_addr)
   // ,.pcie1_elbi_lbc_ext_dout              (elbi_afifo2pl_if_bot.lbc_ext_dout)
   // ,.pcie1_elbi_lbc_ext_valid             (elbi_afifo2pl_if_bot.lbc_ext_valid)
   // ,.pcie1_elbi_lbc_ext_cs                (elbi_afifo2pl_if_bot.lbc_ext_cs)
   // ,.pcie1_elbi_lbc_ext_wr                (elbi_afifo2pl_if_bot.lbc_ext_wr)
   // ,.pcie1_elbi_lbc_ext_rd                (elbi_afifo2pl_if_bot.lbc_ext_rd)
   // ,.pcie1_elbi_lbc_ext_dbi_access        (elbi_afifo2pl_if_bot.lbc_ext_dbi_access)
   // ,.pcie1_elbi_lbc_ext_cxl_mbar0_access  (elbi_afifo2pl_if_bot.lbc_ext_cxl_mbar0_access)
   // ,.pcie1_elbi_lbc_ext_rom_access        (elbi_afifo2pl_if_bot.lbc_ext_rom_access)
   // ,.pcie1_elbi_lbc_ext_io_access         (elbi_afifo2pl_if_bot.lbc_ext_io_access)
   // ,.pcie1_elbi_lbc_ext_bar_num           (elbi_afifo2pl_if_bot.lbc_ext_bar_num)
   // ,.pcie1_elbi_lbc_ext_vfunc_num         (elbi_afifo2pl_if_bot.lbc_ext_vfunc_num)
   // ,.pcie1_elbi_lbc_ext_vfunc_active      (elbi_afifo2pl_if_bot.lbc_ext_vfunc_active)

   // /* AXI-L CONNECTIONS to control ELBI-AXI registers */
   // ,.axil_slv_regs_araddr  (/*axil_araddr*/)
   // ,.axil_slv_regs_arprot  (/*axil_arprot*/)
   // ,.axil_slv_regs_arready  (/*axil_arready*/)
   // ,.axil_slv_regs_aruser  (/*axil_aruser*/)
   // ,.axil_slv_regs_arvalid  (/*axil_arvalid*/)
   // ,.axil_slv_regs_rdata  (/*axil_rdata*/)
   // ,.axil_slv_regs_rready  (/*axil_rready*/)
   // ,.axil_slv_regs_rresp  (/*axil_rresp*/)
   // ,.axil_slv_regs_ruser  (/*axil_ruser*/)
   // ,.axil_slv_regs_rvalid  (/*axil_rvalid*/)
   // ,.axil_slv_regs_awaddr  (/*axil_awaddr*/)
   // ,.axil_slv_regs_awprot  (/*axil_awprot*/)
   // ,.axil_slv_regs_awready  (/*axil_awready*/)
   // ,.axil_slv_regs_awuser  (/*axil_awuser*/)
   // ,.axil_slv_regs_awvalid  (/*axil_awvalid*/)
   // ,.axil_slv_regs_bready  (/*axil_bready*/)
   // ,.axil_slv_regs_bresp  (/*axil_bresp*/)
   // ,.axil_slv_regs_buser  (/*axil_buser*/)
   // ,.axil_slv_regs_bvalid  (/*axil_bvalid*/)
   // ,.axil_slv_regs_wdata  (/*axil_wdata*/)
   // ,.axil_slv_regs_wuser  (/*axil_wuser*/)
   // ,.axil_slv_regs_wready  (/*axil_wready*/)
   // ,.axil_slv_regs_wstrb  (/*axil_wstrb*/)
   // ,.axil_slv_regs_wvalid  (/*axil_wvalid*/)

   // /* AXI-L CONNECTIONS to User Applications */
   // ,.pl_elbi_axil_mstr_araddr  (user_app_axil_if.araddr)
   // ,.pl_elbi_axil_mstr_arprot  (user_app_axil_if.arprot)
   // ,.pl_elbi_axil_mstr_arready  (user_app_axil_if.arready)
   // ,.pl_elbi_axil_mstr_aruser  (user_app_axil_if.aruser)
   // ,.pl_elbi_axil_mstr_arvalid  (user_app_axil_if.arvalid)
   // ,.pl_elbi_axil_mstr_rdata  (user_app_axil_if.rdata)
   // ,.pl_elbi_axil_mstr_rready  (user_app_axil_if.rready)
   // ,.pl_elbi_axil_mstr_rresp  (user_app_axil_if.rresp)
   // ,.pl_elbi_axil_mstr_ruser  (user_app_axil_if.ruser)
   // ,.pl_elbi_axil_mstr_rvalid  (user_app_axil_if.rvalid)
   // ,.pl_elbi_axil_mstr_awaddr  (user_app_axil_if.awaddr)
   // ,.pl_elbi_axil_mstr_awprot  (user_app_axil_if.awprot)
   // ,.pl_elbi_axil_mstr_awready  (user_app_axil_if.awready)
   // ,.pl_elbi_axil_mstr_awuser  (user_app_axil_if.awuser)
   // ,.pl_elbi_axil_mstr_awvalid  (user_app_axil_if.awvalid)
   // ,.pl_elbi_axil_mstr_bready  (user_app_axil_if.bready)
   // ,.pl_elbi_axil_mstr_bresp  (user_app_axil_if.bresp)
   // ,.pl_elbi_axil_mstr_buser  (user_app_axil_if.buser)
   // ,.pl_elbi_axil_mstr_bvalid  (user_app_axil_if.bvalid)
   // ,.pl_elbi_axil_mstr_wdata  (user_app_axil_if.wdata)
   // ,.pl_elbi_axil_mstr_wuser  (user_app_axil_if.wuser)
   // ,.pl_elbi_axil_mstr_wready  (user_app_axil_if.wready)
   // ,.pl_elbi_axil_mstr_wstrb  (user_app_axil_if.wstrb)
   // ,.pl_elbi_axil_mstr_wvalid  (user_app_axil_if.wvalid)
// );

module elbi_wrapper
  import elbi_params_pkg::*;
# (
    parameter AXIL_ADDR_WIDTH    = elbi_params_pkg::AXIL_ADDR_WIDTH
   ,parameter AXIL_DATA_WIDTH    = elbi_params_pkg::AXIL_DATA_WIDTH
   ,parameter AXIL_AXUSER_WIDTH  = elbi_params_pkg::AXIL_AXUSER_WIDTH
) (
   /* Clock Interface */
    input logic             pl_aximm_clk // PL AXI-MM Clock for ELBI.
   ,input logic             pl_aximm_rst_n // PL AXI-MM Reset for ELBI.

   /* ELBI slave interface connections */
   ,output logic          pcie1_elbi_ext_lbc_override_en
   ,output logic  [7:0]   pcie1_elbi_ext_lbc_ack
   ,output logic  [63:0]  pcie1_elbi_ext_lbc_din
   ,input logic   [31:0]  pcie1_elbi_lbc_ext_addr
   ,input logic   [63:0]  pcie1_elbi_lbc_ext_dout
   ,input logic   [7:0]   pcie1_elbi_lbc_ext_valid
   ,input logic   [7:0]   pcie1_elbi_lbc_ext_cs
   ,input logic   [7:0]   pcie1_elbi_lbc_ext_wr
   ,input logic   [7:0]   pcie1_elbi_lbc_ext_rd
   ,input logic           pcie1_elbi_lbc_ext_dbi_access
   ,input logic           pcie1_elbi_lbc_ext_cxl_mbar0_access
   ,input logic           pcie1_elbi_lbc_ext_rom_access
   ,input logic           pcie1_elbi_lbc_ext_io_access
   ,input logic   [2:0]   pcie1_elbi_lbc_ext_bar_num
   ,input logic   [7:0]   pcie1_elbi_lbc_ext_vfunc_num
   ,input logic           pcie1_elbi_lbc_ext_vfunc_active

   /* AXI-L CONNECTIONS to control ELBI-AXI registers */
   ,input  logic   [AXIL_ADDR_WIDTH-1:0]   axil_slv_regs_araddr
   ,input  logic                   [2:0]   axil_slv_regs_arprot
   ,output logic                           axil_slv_regs_arready
   ,input  logic [AXIL_AXUSER_WIDTH-1:0]   axil_slv_regs_aruser
   ,input  logic                           axil_slv_regs_arvalid
   ,output logic   [AXIL_DATA_WIDTH-1:0]   axil_slv_regs_rdata
   ,input  logic                           axil_slv_regs_rready
   ,output logic                   [1:0]   axil_slv_regs_rresp
   ,output logic [AXIL_AXUSER_WIDTH-1:0]   axil_slv_regs_ruser
   ,output logic                           axil_slv_regs_rvalid
   ,input  logic   [AXIL_ADDR_WIDTH-1:0]   axil_slv_regs_awaddr
   ,input  logic                   [2:0]   axil_slv_regs_awprot
   ,output logic                           axil_slv_regs_awready
   ,input  logic [AXIL_AXUSER_WIDTH-1:0]   axil_slv_regs_awuser
   ,input  logic                           axil_slv_regs_awvalid
   ,input  logic                           axil_slv_regs_bready
   ,output logic                   [1:0]   axil_slv_regs_bresp
   ,output logic [AXIL_AXUSER_WIDTH-1:0]   axil_slv_regs_buser
   ,output logic                           axil_slv_regs_bvalid
   ,input  logic   [AXIL_DATA_WIDTH-1:0]   axil_slv_regs_wdata
   ,input  logic [AXIL_AXUSER_WIDTH-1:0]   axil_slv_regs_wuser
   ,output logic                           axil_slv_regs_wready
   ,input  logic [(AXIL_DATA_WIDTH/8)-1:0] axil_slv_regs_wstrb
   ,input  logic                           axil_slv_regs_wvalid

   /* AXI-L CONNECTIONS to User Applications */
   ,output logic   [AXIL_ADDR_WIDTH-1:0]   pl_elbi_axil_mstr_araddr
   ,output logic                   [2:0]   pl_elbi_axil_mstr_arprot
   ,input  logic                           pl_elbi_axil_mstr_arready
   ,output logic [AXIL_AXUSER_WIDTH-1:0]   pl_elbi_axil_mstr_aruser
   ,output logic                           pl_elbi_axil_mstr_arvalid
   ,input  logic   [AXIL_DATA_WIDTH-1:0]   pl_elbi_axil_mstr_rdata
   ,output logic                           pl_elbi_axil_mstr_rready
   ,input  logic                   [1:0]   pl_elbi_axil_mstr_rresp
   ,input  logic [AXIL_AXUSER_WIDTH-1:0]   pl_elbi_axil_mstr_ruser
   ,input  logic                           pl_elbi_axil_mstr_rvalid
   ,output logic   [AXIL_ADDR_WIDTH-1:0]   pl_elbi_axil_mstr_awaddr
   ,output logic                   [2:0]   pl_elbi_axil_mstr_awprot
   ,input  logic                           pl_elbi_axil_mstr_awready
   ,output logic [AXIL_AXUSER_WIDTH-1:0]   pl_elbi_axil_mstr_awuser
   ,output logic                           pl_elbi_axil_mstr_awvalid
   ,output logic                           pl_elbi_axil_mstr_bready
   ,input  logic                   [1:0]   pl_elbi_axil_mstr_bresp
   ,input  logic [AXIL_AXUSER_WIDTH-1:0]   pl_elbi_axil_mstr_buser
   ,input  logic                           pl_elbi_axil_mstr_bvalid
   ,output logic   [AXIL_DATA_WIDTH-1:0]   pl_elbi_axil_mstr_wdata
   ,output logic [AXIL_AXUSER_WIDTH-1:0]   pl_elbi_axil_mstr_wuser
   ,input  logic                           pl_elbi_axil_mstr_wready
   ,output logic [(AXIL_DATA_WIDTH/8)-1:0] pl_elbi_axil_mstr_wstrb
   ,output logic                           pl_elbi_axil_mstr_wvalid
);

pcie6_elbi_pl_if pl_pcie1_elbi_intf();
axil_intf_defs_cpm6 pl_elbi_axil_intf();
axil_intf_defs_cpm6 pl_axil_regs_intf();

assign pcie1_elbi_ext_lbc_override_en        = pl_pcie1_elbi_intf.ext_lbc_override_en;
assign pcie1_elbi_ext_lbc_ack                = pl_pcie1_elbi_intf.ext_lbc_ack;
assign pcie1_elbi_ext_lbc_din                = pl_pcie1_elbi_intf.ext_lbc_din;
assign pl_pcie1_elbi_intf.lbc_ext_addr             = pcie1_elbi_lbc_ext_addr;
assign pl_pcie1_elbi_intf.lbc_ext_dout             = pcie1_elbi_lbc_ext_dout;
assign pl_pcie1_elbi_intf.lbc_ext_valid            = pcie1_elbi_lbc_ext_valid;
assign pl_pcie1_elbi_intf.lbc_ext_cs               = pcie1_elbi_lbc_ext_cs;
assign pl_pcie1_elbi_intf.lbc_ext_wr               = pcie1_elbi_lbc_ext_wr;
assign pl_pcie1_elbi_intf.lbc_ext_rd               = pcie1_elbi_lbc_ext_rd;
assign pl_pcie1_elbi_intf.lbc_ext_dbi_access       = pcie1_elbi_lbc_ext_dbi_access;
assign pl_pcie1_elbi_intf.lbc_ext_cxl_mbar0_access = pcie1_elbi_lbc_ext_cxl_mbar0_access;
assign pl_pcie1_elbi_intf.lbc_ext_rom_access       = pcie1_elbi_lbc_ext_rom_access;
assign pl_pcie1_elbi_intf.lbc_ext_io_access        = pcie1_elbi_lbc_ext_io_access;
assign pl_pcie1_elbi_intf.lbc_ext_bar_num          = pcie1_elbi_lbc_ext_bar_num;
assign pl_pcie1_elbi_intf.lbc_ext_vfunc_num        = pcie1_elbi_lbc_ext_vfunc_num;
assign pl_pcie1_elbi_intf.lbc_ext_vfunc_active     = pcie1_elbi_lbc_ext_vfunc_active;

assign pl_elbi_axil_mstr_araddr = pl_elbi_axil_intf.araddr;
assign pl_elbi_axil_mstr_arprot = pl_elbi_axil_intf.arprot;
assign pl_elbi_axil_intf.arready = pl_elbi_axil_mstr_arready;
assign pl_elbi_axil_mstr_aruser = pl_elbi_axil_intf.aruser;
assign pl_elbi_axil_mstr_arvalid = pl_elbi_axil_intf.arvalid;
assign pl_elbi_axil_mstr_awaddr = pl_elbi_axil_intf.awaddr;
assign pl_elbi_axil_mstr_awprot = pl_elbi_axil_intf.awprot;
assign pl_elbi_axil_intf.awready = pl_elbi_axil_mstr_awready;
assign pl_elbi_axil_mstr_awuser = pl_elbi_axil_intf.awuser;
assign pl_elbi_axil_mstr_awvalid = pl_elbi_axil_intf.awvalid;
assign pl_elbi_axil_mstr_bready = pl_elbi_axil_intf.bready;
assign pl_elbi_axil_intf.bresp = pl_elbi_axil_mstr_bresp;
assign pl_elbi_axil_intf.buser = pl_elbi_axil_mstr_buser;
assign pl_elbi_axil_intf.bvalid = pl_elbi_axil_mstr_bvalid;
assign pl_elbi_axil_intf.rdata = pl_elbi_axil_mstr_rdata;
assign pl_elbi_axil_mstr_rready = pl_elbi_axil_intf.rready;
assign pl_elbi_axil_intf.rresp = pl_elbi_axil_mstr_rresp;
assign pl_elbi_axil_intf.ruser = pl_elbi_axil_mstr_ruser;
assign pl_elbi_axil_intf.rvalid = pl_elbi_axil_mstr_rvalid;
assign pl_elbi_axil_mstr_wdata = pl_elbi_axil_intf.wdata;
assign pl_elbi_axil_intf.wready = pl_elbi_axil_mstr_wready;
assign pl_elbi_axil_mstr_wstrb = pl_elbi_axil_intf.wstrb;
assign pl_elbi_axil_mstr_wuser = pl_elbi_axil_intf.wuser;
assign pl_elbi_axil_mstr_wvalid = pl_elbi_axil_intf.wvalid;

assign pl_axil_regs_intf.araddr = 'h0;
assign pl_axil_regs_intf.arprot = 'h0;
assign pl_axil_regs_intf.arvalid = 'h0;
assign pl_axil_regs_intf.awaddr = 'h0;
assign pl_axil_regs_intf.awprot = 'h0;
assign pl_axil_regs_intf.awvalid = 'h0;
assign pl_axil_regs_intf.bready = 'h0;
assign pl_axil_regs_intf.rready = 'h0;
assign pl_axil_regs_intf.wdata = 'h0;
assign pl_axil_regs_intf.wstrb = 'h0;
assign pl_axil_regs_intf.wuser = 'h0;
assign pl_axil_regs_intf.wvalid = 'h0;
assign pl_axil_regs_intf.aruser = 'h0;
assign pl_axil_regs_intf.awuser = 'h0;
assign pl_axil_regs_intf.buser = 'h0;

elbi2axi_top # (
   // .TCQ                           (TCQ)
   // ,.TIMEOUT                       (TIMEOUT)
    .AXIL_ADDR_WIDTH                 (AXIL_ADDR_WIDTH)
   ,.AXIL_DATA_WIDTH                 (AXIL_DATA_WIDTH)
   ,.AXIL_AXUSER_WIDTH               (AXIL_AXUSER_WIDTH)
) u_elbi2axi(
    .elbi2axil_clk                   (pl_aximm_clk)
   ,.elbi2axil_rstn                  (pl_aximm_rst_n)

   ,.pl_axil_regs_if                 (pl_axil_regs_intf)
   ,.pl_pcie1_elbi_if                (pl_pcie1_elbi_intf)

   ,.pl_elbi_axil_if                 (pl_elbi_axil_intf)
);

endmodule : elbi_wrapper
