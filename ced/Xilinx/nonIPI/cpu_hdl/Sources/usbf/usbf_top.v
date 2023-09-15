/////////////////////////////////////////////////////////////////////
////                                                             ////
////  USB function core                                          ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/usb/       ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2003 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: usbf_top.v,v 1.1 2008/05/07 22:43:23 daughtry Exp $
//
//  $Date: 2008/05/07 22:43:23 $
//  $Revision: 1.1 $
//  $Author: daughtry $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: usbf_top.v,v $
//               Revision 1.1  2008/05/07 22:43:23  daughtry
//               Initial Demo RTL check-in
//
//               Revision 1.7  2003/11/11 07:15:16  rudi
//               Fixed Resume signaling and initial attachment
//
//               Revision 1.6  2003/10/17 02:36:57  rudi
//               - Disabling bit stuffing and NRZI encoding during speed negotiation
//               - Now the core can send zero size packets
//               - Fixed register addresses for some of the higher endpoints
//                 (conversion between decimal/hex was wrong)
//               - The core now does properly evaluate the function address to
//                 determine if the packet was intended for it.
//               - Various other minor bugs and typos
//
//               Revision 1.5  2001/11/04 12:22:45  rudi
//
//               - Fixed previous fix (brocke something else ...)
//               - Majore Synthesis cleanup
//
//               Revision 1.4  2001/11/03 03:26:23  rudi
//
//               - Fixed several interrupt and error condition reporting bugs
//
//               Revision 1.3  2001/09/24 01:15:28  rudi
//
//               Changed reset to be active high async.
//
//               Revision 1.2  2001/08/10 08:48:33  rudi
//
//               - Changed IO names to be more clear.
//               - Uniquifyed define names to be core specific.
//
//               Revision 1.1  2001/08/03 05:30:09  rudi
//
//
//               1) Reorganized directory structure
//
//               Revision 1.2  2001/03/31 13:00:52  rudi
//
//               - Added Core configuration
//               - Added handling of OUT packets less than MAX_PL_SZ in DMA mode
//               - Modified WISHBONE interface and sync logic
//               - Moved SSRAM outside the core (added interface)
//               - Many small bug fixes ...
//
//               Revision 1.0  2001/03/07 09:17:12  rudi
//
//
//               Changed all revisions to revision 1.0. This is because OpenCores CVS
//               interface could not handle the original '0.1' revision ....
//
//               Revision 0.2  2001/03/07 09:08:13  rudi
//
//               Added USB control signaling (Line Status) block. Fixed some minor
//               typos, added resume bit and signal.
//
//               Revision 0.1.0.1  2001/02/28 08:11:40  rudi
//               Initial Release
//
//

`include "usbf_defines.v"

module usbf_top(// WISHBONE Interface
		wb_clk, clk_i, rst_i, wb_addr_i, wb_data_i, wb_data_o,
		wb_ack_o, wb_we_i, wb_stb_i, wb_cyc_i, inta_o,
		dma_ack_i, susp_o, resume_req_i,

		// UTMI Interface
		phy_clk_pad_i, phy_rst_pad_o,
		DataOut_pad_o, TxValid_pad_o, TxReady_pad_i,

		RxValid_pad_i, RxActive_pad_i, RxError_pad_i,
		DataIn_pad_i, XcvSelect_pad_o, TermSel_pad_o,
		SuspendM_pad_o, LineState_pad_i,

		OpMode_pad_o, usb_vbus_pad_i,
		VControl_Load_pad_o, VControl_pad_o, VStatus_pad_i
		);

				 
parameter	SSRAM_HADR = `USBF_SSRAM_HADR;
input wb_clk;
input		clk_i;
input		rst_i;
input	[31:0]	wb_addr_i;
input	[31:0]	wb_data_i;
output	[31:0]	wb_data_o;
output		wb_ack_o;
input		wb_we_i;
input		wb_stb_i;
input		wb_cyc_i;
output		inta_o;
input	[15:0]	dma_ack_i;
output		susp_o;
input		resume_req_i;

input		phy_clk_pad_i;
output	reg	phy_rst_pad_o;

output	[7:0]	DataOut_pad_o;
output	reg	TxValid_pad_o;
input		TxReady_pad_i;

input	[7:0]	DataIn_pad_i;
input		RxValid_pad_i;
input		RxActive_pad_i;
input		RxError_pad_i;

output		XcvSelect_pad_o;
output		TermSel_pad_o;
output		SuspendM_pad_o;
input	[1:0]	LineState_pad_i;
output	[1:0]	OpMode_pad_o;
input		usb_vbus_pad_i;
output		VControl_Load_pad_o;
output	[3:0]	VControl_pad_o;
input	[7:0]	VStatus_pad_i;
 



///////////////////////////////////////////////////////////////////
//
// Local Wires and Registers
//
wire [31:0] wb_data_i_buf, wb_data_o_buf;
wire [15:0] dma_ack_i_buf, dma_req_o_buf ;
wire [`USBF_UFC_HADR:0]	wb_addr_i_buf;
		
wire [7:0] DataOut_pad_o_buf;
reg [15:0] dma_ack_i_reg;
// Buffer Memory Interface
wire	[SSRAM_HADR:0]	sram_adr_o;
wire	[31:0]	sram_data_i;
wire	[31:0]	sram_data_o;
wire		sram_re_o;
wire		sram_we_o;

// UTMI Interface
wire	[7:0]	rx_data;
wire		rx_valid, rx_active, rx_err;
wire	[7:0]	tx_data;
wire		tx_valid;
wire		tx_ready;
wire		tx_first;
wire		tx_valid_last; 
wire        TxValid_pad_o_wire;

// Misc UTMI USB status
wire		mode_hs;	// High Speed Mode
wire		usb_reset;	// USB Reset
wire		usb_suspend;	// USB Sleep
wire		usb_attached;	// Attached to USB
wire		resume_req;	// Resume Request

// Memory Arbiter Interface
wire	[SSRAM_HADR:0]	madr;		// word address
wire	[31:0]	mdout;
wire	[31:0]	mdin;
wire		mwe;
wire		mreq;
wire		mack;
wire		rst;

// Wishbone Memory interface
wire	[`USBF_UFC_HADR:0]	ma_adr;
wire	[31:0]	ma2wb_d;
wire	[31:0]	wb2ma_d;
wire		ma_we;
wire		ma_req;
wire		ma_ack;

// WISHBONE Register File interface
wire		rf_re;
wire		rf_we;
wire	[31:0]	wb2rf_d;
wire	[31:0]	rf2wb_d;

// Internal Register File Interface
wire	[6:0]	funct_adr;	// This functions address (set by controller)
wire	[31:0]	idin;		// Data Input
wire	[3:0]	ep_sel;		// Endpoint Number Input
wire		match;		// Endpoint Matched
wire		dma_in_buf_sz1;
wire		dma_out_buf_avail;
wire		buf0_rl;	// Reload Buf 0 with original values
wire		buf0_set;	// Write to buf 0
wire		buf1_set;	// Write to buf 1
wire		uc_bsel_set;	// Write to the uc_bsel field
wire		uc_dpd_set;	// Write to the uc_dpd field
wire		int_buf1_set;	// Set buf1 full/empty interrupt
wire		int_buf0_set;	// Set buf0 full/empty interrupt
wire		int_upid_set;	// Set unsupported PID interrupt
wire		int_crc16_set;	// Set CRC16 error interrupt
wire		int_to_set;	// Set time out interrupt
wire		int_seqerr_set;	// Set PID sequence error interrupt
wire		out_to_small;	// OUT packet was to small for DMA operation
wire	[31:0]	csr;		// Internal CSR Output
wire	[31:0]	buf0;		// Internal Buf 0 Output
wire	[31:0]	buf1;		// Internal Buf 1 Output
wire	[31:0]	frm_nat;	// Frame Number and Time Register
wire		nse_err;	// No Such Endpoint Error
wire		pid_cs_err;	// PID CS error
wire		crc5_err;	// CRC5 Error
wire		rf_resume_req;	// Resume Request From main CSR

reg		susp_o;
reg		susp_o_pipe;
reg	[1:0]	LineState_r;	// Added to make a full synchronizer
reg	[7:0]	VStatus_r;	// Added to make a full synchronizer
																 
//added for design preservation
reg    wb_stb_i_reg;
reg    wb_we_i_reg;		
reg    wb_cyc_i_reg;	   
reg    usb_vbus_pad_i_reg;	  
reg    resume_req_i_reg;
  	 
wire   [31:0]	wb_pass;
wire   [31:0]	wb_data_o_temp;
reg    [31:0]	wb_data_o;   
wire   [15:0]	dma_req_o_temp;
reg    [15:0]	dma_req_o_reg;
wire   intb_o;
wire   SuspendM_pad_o_temp;
reg    SuspendM_pad_o;
	   

reg wb_ack_o;
wire wb_ack_o_pass; 
wire wr_en0, wr_en1, wr_en2, wr_en3;
wire [3:0] vend_ctrl;
wire [1:0]OpModeBuf;
///////////////////////////////////////////////////////////////////
//
//dave added a level of register insulation where needed
 always @(posedge phy_clk_pad_i) begin
        wb_stb_i_reg <= wb_stb_i;
        wb_we_i_reg <= wb_we_i;
        wb_cyc_i_reg <= wb_cyc_i;
        usb_vbus_pad_i_reg <= usb_vbus_pad_i;  
        resume_req_i_reg <= resume_req_i;
end



///////////////////////////////////////////////////////////////////
//
// Misc Logic
//
assign rst = rst_i;
assign resume_req = resume_req_i_reg;

always @(posedge clk_i)
    phy_rst_pad_o <= resume_req_i_reg ^ rst_i;

always @(posedge clk_i)
	susp_o_pipe <= usb_suspend;		 
	
always @(posedge phy_clk_pad_i)
	susp_o <= susp_o_pipe;		 


//dave need to tie off int_a, int_b, susp_o and remove them from the interface	

always @(posedge phy_clk_pad_i)		// First Stage Synchronizer
	LineState_r <= LineState_pad_i;

always @(posedge phy_clk_pad_i)		// First Stage Synchronizer
	VStatus_r <= VStatus_pad_i;
									  
always @(posedge phy_clk_pad_i)
    TxValid_pad_o <= TxValid_pad_o_wire;
    
///////////////////////////////////////////////////////////////////
//
// Module Instantiations
//

reg		resume_req_r;
reg		suspend_clr_wr;
wire		suspend_clr;

always @(posedge clk_i)
	suspend_clr_wr <= suspend_clr;

`ifdef USBF_ASYNC_RESET
always @(posedge clk_i or negedge rst)
`else
always @(posedge clk_i)
`endif
//XLNX_MODIFIED this is going to V5 and low resets tie up lut resources
//changing 
//	if(!rst)		resume_req_r <= 1'b0;
//to the prefered high reset
	if(rst)		resume_req_r <= 1'b0;
	else
	if(suspend_clr_wr)	resume_req_r <= 1'b0;
	else
	if(resume_req)		resume_req_r <= 1'b1;

// input fifo
FifoBuffer usb_in (
	.din (wb_data_i),
	.rd_clk (clk_i ),
	.rd_en (resume_req_r),
	.rst( rst),
	.wr_clk (wb_clk),
	.wr_en (wr_en0),
	.dout (wb_data_i_buf)
	);

FifoBuffer usb_dma_wb_in (
	.din ({wb_addr_i}),
	.rd_clk (clk_i ),
	.rd_en (resume_req_r),
	.rst( rst),
	.wr_clk (wb_clk),
	.wr_en (wr_en1),
	.dout ({dma_ack_i_buf,wb_addr_i_buf})
	);
	
// output fifo
FifoBuffer usb_out (
	.din (wb_data_o_buf),
	.rd_clk (wb_clk ),
	.rd_en (wr_en2),
	.rst( rst),
	.wr_clk (clk_i),
	.wr_en (resume_req_r),
	.dout (wb_data_o_temp)
	
	);
// 16, 8, 4, 2	
FifoBuffer dma_out (
	.din ({dma_req_o_buf,DataOut_pad_o_buf, vend_ctrl, OpModeBuf,2'b01}),
	.rd_clk (wb_clk ),
	.rd_en (wr_en3),
	.rst( rst),
	.wr_clk (clk_i),
	.wr_en (resume_req_r),
	.dout ({dma_req_o_temp,DataOut_pad_o, VControl_pad_o, OpMode_pad_o})
	);	 

always @(posedge wb_clk)
   dma_ack_i_reg <= dma_ack_i;
   
   
 assign wr_en0 = dma_ack_i_reg[3] | dma_ack_i_reg[2] | dma_ack_i_reg[1] | dma_ack_i_reg[0];
 assign wr_en1 = dma_ack_i_reg[7] | dma_ack_i_reg[6] | dma_ack_i_reg[5] | dma_ack_i_reg[4];
 assign wr_en2 = dma_ack_i_reg[11] | dma_ack_i_reg[10] | dma_ack_i_reg[9] | dma_ack_i_reg[8];
 assign wr_en3 = dma_ack_i_reg[15] | dma_ack_i_reg[14] | dma_ack_i_reg[13] | dma_ack_i_reg[12];
 
 assign wb_pass = intb_o ? wb_data_o_temp :  dma_req_o_temp ;
 always @(posedge clk_i) begin
		wb_data_o <= wb_pass;
  
		wb_ack_o <= wb_ack_o_pass;
 end

// UTMI Interface
usbf_utmi_if	u0(
		.phy_clk(	phy_clk_pad_i	),
		.rst(		rst		),
		.DataOut(	DataOut_pad_o_buf	),
		.TxValid(	TxValid_pad_o_wire	),
		.TxReady(	TxReady_pad_i	),
		.RxValid(	RxValid_pad_i	),
		.RxActive(	RxActive_pad_i	),
		.RxError(	RxError_pad_i	),
		.DataIn(	DataIn_pad_i	),
		.XcvSelect(	XcvSelect_pad_o	),
		.TermSel(	TermSel_pad_o	),
		.SuspendM(	SuspendM_pad_o_temp	),
		.LineState(	LineState_r		),
		.OpMode(	OpModeBuf	),
		.usb_vbus(	usb_vbus_pad_i_reg	),
		.rx_data(	rx_data		),
		.rx_valid(	rx_valid	),
		.rx_active(	rx_active	),
		.rx_err(	rx_err		),
		.tx_data(	tx_data		),
		.tx_valid(	tx_valid	),
		.tx_valid_last(	tx_valid_last	),
		.tx_ready(	tx_ready	),
		.tx_first(	tx_first	),
		.mode_hs(	mode_hs		),
		.usb_reset(	usb_reset	),
		.usb_suspend(	usb_suspend	),
		.usb_attached(	usb_attached	),
		.resume_req(	resume_req_r	),
		.suspend_clr(	suspend_clr	)
		);

																	 
always @(posedge clk_i) begin
       SuspendM_pad_o <= SuspendM_pad_o_temp;
end

// Protocol Layer
usbf_pl #(SSRAM_HADR)
	u1(	.clk(			phy_clk_pad_i		),
		.rst(			rst			),
		.rx_data(		rx_data			),
		.rx_valid(		rx_valid		),
		.rx_active(		rx_active		),
		.rx_err(		rx_err			),
		.tx_data(		tx_data			),
		.tx_valid(		tx_valid		),
		.tx_valid_last(		tx_valid_last		),
		.tx_ready(		tx_ready		),
		.tx_first(		tx_first		),
		.tx_valid_out(		TxValid_pad_o_wire		),
		.mode_hs(		mode_hs			),
		.usb_reset(		usb_reset		),
		.usb_suspend(		usb_suspend		),
		.usb_attached(		usb_attached		),
		.madr(			madr			),
		.mdout(			mdout			),
		.mdin(			mdin			),
		.mwe(			mwe			),
		.mreq(			mreq			),
		.mack(			mack			),
		.fa(			funct_adr		),
		.dma_in_buf_sz1(	dma_in_buf_sz1		),
		.dma_out_buf_avail(	dma_out_buf_avail	),
		.idin(			idin			),
		.ep_sel(		ep_sel			),
		.match(			match			),
		.buf0_rl(		buf0_rl			),
		.buf0_set(		buf0_set		),
		.buf1_set(		buf1_set		),
		.uc_bsel_set(		uc_bsel_set		),
		.uc_dpd_set(		uc_dpd_set		),
		.int_buf1_set(		int_buf1_set		),
		.int_buf0_set(		int_buf0_set		),
		.int_upid_set(		int_upid_set		),
		.int_crc16_set(		int_crc16_set		),
		.int_to_set(		int_to_set		),
		.int_seqerr_set(	int_seqerr_set		),
		.out_to_small(		out_to_small		),
		.csr(			csr			),
		.buf0(			buf0			),
		.buf1(			buf1			),
		.frm_nat(		frm_nat			),
		.pid_cs_err(		pid_cs_err		),
		.nse_err(		nse_err			),
		.crc5_err(		crc5_err		)
		);

// Memory Arbiter
usbf_mem_arb	#(SSRAM_HADR)
	u2(	.phy_clk(	phy_clk_pad_i	),
		.wclk(		clk_i		),
		.rst(		rst		),

		.sram_adr(	sram_adr_o	),
		.sram_din(	sram_data_i	),
		.sram_dout(	sram_data_o	),
		.sram_re(	sram_re_o	),
		.sram_we(	sram_we_o	),

		.madr(		madr		),
		.mdout(		mdin		),
		.mdin(		mdout		),
		.mwe(		mwe		),
		.mreq(		mreq		),
		.mack(		mack		),

//this will not work tweaking down two
//.wadr(		ma_adr[SSRAM_HADR + 2:2]	),
        .wadr(		ma_adr[SSRAM_HADR:0]	),
		.wdout(		ma2wb_d		),
		.wdin(		wb2ma_d		),
		.wwe(		ma_we		),
		.wreq(		ma_req		),
		.wack(		ma_ack		)
		);

// Register File 
usbf_rf u4(	.clk(			phy_clk_pad_i		),
		.wclk(			clk_i			),
		.rst(			rst			),

		.adr(			ma_adr[8:2]		),
		.re(			rf_re			),
		.we(			rf_we			),
		.din(			wb2rf_d			),
		.dout(			rf2wb_d			),

		.inta(			inta_o			),
		.intb(			intb_o			),
		.dma_req(		dma_req_o_buf		),
		.dma_ack(		dma_ack_i_buf		),
		.idin(			idin			),
		.ep_sel(		ep_sel			),
		.match(			match			),
		.buf0_rl(		buf0_rl			),
		.buf0_set(		buf0_set		),
		.buf1_set(		buf1_set		),
		.uc_bsel_set(		uc_bsel_set		),
		.uc_dpd_set(		uc_dpd_set		),
		.int_buf1_set(		int_buf1_set		),
		.int_buf0_set(		int_buf0_set		),
		.int_upid_set(		int_upid_set		),
		.int_crc16_set(		int_crc16_set		),
		.int_to_set(		int_to_set		),
		.int_seqerr_set(	int_seqerr_set		),
		.out_to_small(		out_to_small		),
		.csr(			csr			),
		.buf0(			buf0			),
		.buf1(			buf1			),
		.funct_adr(		funct_adr		),
		.dma_in_buf_sz1(	dma_in_buf_sz1		),
		.dma_out_buf_avail(	dma_out_buf_avail	),
		.frm_nat(		frm_nat			),
		.utmi_vend_stat(	VStatus_r		),
		.utmi_vend_ctrl(	vend_ctrl		),
		.utmi_vend_wr(		VControl_Load_pad_o	),
		.line_stat(		LineState_r		),
		.usb_attached(		usb_attached		),
		.mode_hs(		mode_hs			),
		.suspend(		usb_suspend		),
		.attached(		usb_attached		),
		.usb_reset(		usb_reset		),
		.pid_cs_err(		pid_cs_err		),
		.nse_err(		nse_err			),
		.crc5_err(		crc5_err		),
		.rx_err(		rx_err			),
		.rf_resume_req(		rf_resume_req		)
		);

    
// WISHBONE Interface
usbf_wb	u5(	.phy_clk(	phy_clk_pad_i	),
		.wb_clk(	clk_i		),
		.rst(		rst		),
		.wb_addr_i(	wb_addr_i_buf	),
		.wb_data_i(	wb_data_i_buf	),
		.wb_data_o(	wb_data_o_buf	),
		.wb_ack_o(	wb_ack_o_pass	),
		.wb_we_i(	wb_we_i_reg		),
		.wb_stb_i(	wb_stb_i_reg	),
		.wb_cyc_i(	wb_cyc_i_reg	),

		.ma_adr(	ma_adr		),
		.ma_dout(	wb2ma_d		),
		.ma_din(	ma2wb_d		),
		.ma_we(		ma_we		),
		.ma_req(	ma_req		),
		.ma_ack(	ma_ack		),

		.rf_re(		rf_re		),
		.rf_we(		rf_we		),
		.rf_dout(	wb2rf_d		),
		.rf_din(	rf2wb_d		)
		);


/*blk_mem_512X32 usbEngineSRAM (
      .clka(clk_i), .wea(sram_we_o), 
      .addra(sram_adr_o), .douta(sram_data_i), .dina(sram_data_o)
   );
*/
rtlRam #(32, SSRAM_HADR+1) usbEngineSRAM (
      .clka(clk_i), .wea(sram_we_o), 
      .addra(sram_adr_o), .douta(sram_data_i), .dina(sram_data_o)
   );

///////////////////////////////////////////////////////////////////
//
// Initialization
// This section does not add any functionality. It is only provided
// to make sure that the core is configured properly and to provide
// configuration information for simulations.
//

// synopsys translate_off
integer 	ep_cnt, ep_cnt2;
reg	[15:0]	ep_check;
initial
   begin
	$display("\n");
	ep_cnt = 1;
	ep_cnt2 = 0;
	ep_check = 0;

`ifdef	USBF_HAVE_EP1	
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP2	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP3	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP4	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP5	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP6	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP7	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP8	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP9	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP10	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP11	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP12	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP13	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP14	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif
ep_cnt2 = ep_cnt2 + 1;
`ifdef	USBF_HAVE_EP15	
	if(!ep_check[ep_cnt2-1])
		$display("ERROR: USBF_TOP: Endpoint %0d not defined but endpoint %0d defined", ep_cnt2, ep_cnt2+1);
	ep_cnt = ep_cnt + 1;
	ep_check[ep_cnt2] = 1;
`endif

	$display("");
	$display("INFO: USB Function core instantiated (%m)");
	$display("      Supported Endpoints: %0d (0 through %0d)",ep_cnt, ep_cnt-1);
	$display("      WISHBONE Address bus size: A%0d:0", `USBF_UFC_HADR );
	$display("      SSRAM Address bus size: A%0d:0", SSRAM_HADR );
	$display("      Buffer Memory Size: %0d bytes", (1<<SSRAM_HADR+1) * 4 );
	$display("");

   end

// synopsys translate_on

endmodule


