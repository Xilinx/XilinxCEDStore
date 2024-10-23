
`timescale 1 ns / 1 ps

`include "av_pat_gen_v2_0_1_defs.v"

	module av_pat_gen_v2_0_1_av_axi #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 12
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY,
                input wire  TPG_GEN_EN,

                 output wire [(`DISP_SDP_PYLD_SIZE-1):0] disp_sdp_data_regs,
                 output wire [(`DISP_SDP_CTRL_SIZE-1):0] disp_sdp_ctrl_regs,


                output wire [(`DISP_DTC_REGS_SIZE-1):0] disp_dtc_regs,
                output wire [2:0]                       hdcolorbar_cfg,
                output wire [7:0]                       misc0,
                output wire [7:0]                       misc1,
                output wire [2:0]                       test_pattern,
                output wire                             en_sw_pattern,
                output wire                             dual_pixel_mode,
                output wire                             quad_pixel_mode,
                output wire                             octa_pixel_mode,
   output wire         aud_reset,          // Reset audio generator
   output wire         aud_start,          // Audio starts after set to 1; will
                                          //   not stop until reset
   output wire         aud_config_update,  // Updata audio configuration (sample
                                          //   rate or number of channels)
   output wire [  3:0] aud_sample_rate,    // Audio sample rate. Actual audio
                                          //   clock must be 512 time the sample
                                          //   rate.
   output wire [  3:0] aud_channel_count,  // Number of active audio channels
   output wire [191:0] aud_channel_status, // Channel status to sent. Each bit
                                          //   will be sent twice. The upper
                                          //   bits [191:84] will be sent as 0.
   output wire [  1:0] aud_pattern1,       // Audio pattern on channel 1:
                                          //   00: silence, 10: ping
   output wire [  1:0] aud_pattern2,       // Audio pattern on channel 2
   output wire [  1:0] aud_pattern3,       // Audio pattern on channel 3
   output wire [  1:0] aud_pattern4,       // Audio pattern on channel 4
   output wire [  1:0] aud_pattern5,       // Audio pattern on channel 5
   output wire [  1:0] aud_pattern6,       // Audio pattern on channel 6
   output wire [  1:0] aud_pattern7,       // Audio pattern on channel 7
   output wire [  1:0] aud_pattern8,       // Audio pattern on channel 8
   output wire [  3:0] aud_period1,        // Not used
   output wire [  3:0] aud_period2,        // Not used
   output wire [  3:0] aud_period3,        // Not used
   output wire [  3:0] aud_period4,        // Not used
   output wire [  3:0] aud_period5,        // Not used
   output wire [  3:0] aud_period6,        // Not used
   output wire [  3:0] aud_period7,        // Not used
   output wire [  3:0] aud_period8,        // Not used
   output wire [ 23:0] offset_addr_cntr,    // Number of audio samples in 250ms
   output wire         aud_drop,         
   output wire [31:0]  axi4lite_timer,         
   output wire         audio_chk_start,        
   output wire [3:0]   audio_stream_id,        
   input  wire [191:0] channel_status_ch0,         
   input  wire [191:0] channel_status_ch1,         
   input  wire [31:0]  ch0_sample_cnt,         
   input  wire [31:0]  ch1_sample_cnt,
   input  wire [1:0]   aud_block_state
	);


	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
        localparam [23:0] cOFFSET_CNTR [0:7] = {
                                           24'd08000, //  32k
                                           24'd11025, //  44k1
                                           24'd12000, //  48k
                                           24'd22050, //  88k2
                                           24'd24000, //  96k
                                           24'd44100, // 176k4
                                           24'd48000, // 192k
                                           24'd08000  //  32k (duplicate)
                                           };

	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x0  ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4  ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x8  ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0xC  ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x10 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x14 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x18 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x1C ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x20 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x24 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x28 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x2C ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x34 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x3C ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x40 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x44 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x48 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4C ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x50 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x54 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x58 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x5C ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x60 ;
        	// SDP0
        reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x100  ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x104  ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x108  ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x10C  ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x110 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x114 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x118 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x11C ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x120 ;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x124 ;

	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x300;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x304;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x308;

	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x400;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x404;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x410;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x420;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x430;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x440;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x450;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x460;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x470;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x480;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4A0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4A4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4A8;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4AC;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4B0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4B4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4B8;

	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4C0; //Timer Program
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4C4; //Channel Status0 1-4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4C8; //Channel Status0 5-8
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4CC; //Channel Status0 9-12
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4D0; //Channel Status0 13-16
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4D4; //Channel Status0 17-20
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4D8; //Channel Status0 21-24
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4DC; //Ch0: Sample count per timer programmed interval
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4E0; //Ch1: Sample count per timer programmed interval
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg_0x4E4; //Status                                         

	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	        end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
              slv_reg_0x0    <= 0;   
              slv_reg_0x4    <= 0;
              slv_reg_0x8    <= 0;
              slv_reg_0xC    <= 0;
              slv_reg_0x10   <= 0;
              slv_reg_0x14   <= 0;
              slv_reg_0x18   <= 0;
              slv_reg_0x1C   <= 0;
              slv_reg_0x20   <= 0;
              slv_reg_0x24   <= 0;
              slv_reg_0x28   <= 0;
              slv_reg_0x2C   <= 0;
              slv_reg_0x34   <= 0;
              slv_reg_0x3C   <= 0;
              slv_reg_0x40   <= 0;
              slv_reg_0x44   <= 0;
              slv_reg_0x48   <= 0;
              slv_reg_0x4C   <= 0;
              slv_reg_0x50   <= 0;
              slv_reg_0x54   <= 0;
              slv_reg_0x58   <= 0;
              slv_reg_0x5C   <= 0;
              slv_reg_0x60   <= 0;
              slv_reg_0x100 <= 0;
	          slv_reg_0x104 <= 0;
	          slv_reg_0x108 <= 0;
	          slv_reg_0x10C <= 0;
	          slv_reg_0x110 <= 0;
	          slv_reg_0x114 <= 0;
	          slv_reg_0x118 <= 0;
	          slv_reg_0x11C <= 0;
	          slv_reg_0x120 <= 0;
	          slv_reg_0x124 <= 0;

              slv_reg_0x300  <= 0;
              slv_reg_0x304  <= 0;
              slv_reg_0x308  <= 0;
              slv_reg_0x400  <= 1;
              slv_reg_0x404  <= 0; 
              slv_reg_0x410 <= 0;
              slv_reg_0x420 <= 0;
              slv_reg_0x430 <= 0;
              slv_reg_0x440 <= 0;
              slv_reg_0x450 <= 0;
              slv_reg_0x460 <= 0;
              slv_reg_0x470 <= 0;
              slv_reg_0x480 <= 0;
              slv_reg_0x4A0 <= 0;
              slv_reg_0x4A4 <= 0;
              slv_reg_0x4A8 <= 0;
              slv_reg_0x4AC <= 0;
              slv_reg_0x4B0 <= 0;
              slv_reg_0x4B4 <= 0;
              slv_reg_0x4B8 <= 0;

              slv_reg_0x4C0 <= 0;
              slv_reg_0x4C4 <= 0;
              slv_reg_0x4C8 <= 0;
              slv_reg_0x4CC <= 0;
              slv_reg_0x4D0 <= 0;
              slv_reg_0x4D4 <= 0;
              slv_reg_0x4D8 <= 0;
              slv_reg_0x4DC <= 0;
	    end             
	  else begin        
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[11:0] )
	          12'h0  : slv_reg_0x0   <= S_AXI_WDATA;
	          12'h4  : slv_reg_0x4   <= S_AXI_WDATA;
	          12'h8  : slv_reg_0x8   <= S_AXI_WDATA;
	          12'hC  : slv_reg_0xC   <= S_AXI_WDATA;
	          12'h10 : slv_reg_0x10  <= S_AXI_WDATA;
	          12'h14 : slv_reg_0x14  <= S_AXI_WDATA;
	          12'h18 : slv_reg_0x18  <= S_AXI_WDATA;
	          12'h1C : slv_reg_0x1C  <= S_AXI_WDATA;
	          12'h20 : slv_reg_0x20  <= S_AXI_WDATA;
	          12'h24 : slv_reg_0x24  <= S_AXI_WDATA;
	          12'h28 : slv_reg_0x28  <= S_AXI_WDATA;
	          12'h2C : slv_reg_0x2C  <= S_AXI_WDATA;
	          12'h34 : slv_reg_0x34  <= S_AXI_WDATA;
	          12'h3C : slv_reg_0x3C  <= S_AXI_WDATA;
	          12'h40 : slv_reg_0x40  <= S_AXI_WDATA;
	          12'h44 : slv_reg_0x44  <= S_AXI_WDATA;
	          12'h48 : slv_reg_0x48  <= S_AXI_WDATA;
	          12'h4C : slv_reg_0x4C  <= S_AXI_WDATA;
	          12'h50 : slv_reg_0x50  <= S_AXI_WDATA;
	          12'h54 : slv_reg_0x54  <= S_AXI_WDATA;
	          12'h58 : slv_reg_0x58  <= S_AXI_WDATA;
	          12'h5C : slv_reg_0x5C  <= S_AXI_WDATA;
	          12'h60 : slv_reg_0x60  <= S_AXI_WDATA;
                  12'h100: slv_reg_0x100 <= S_AXI_WDATA;
	          12'h104: slv_reg_0x104 <= S_AXI_WDATA;
	          12'h108: slv_reg_0x108 <= S_AXI_WDATA;
	          12'h10C: slv_reg_0x10C <= S_AXI_WDATA;
	          12'h110: slv_reg_0x110 <= S_AXI_WDATA;
	          12'h114: slv_reg_0x114 <= S_AXI_WDATA;
	          12'h118: slv_reg_0x118 <= S_AXI_WDATA;
	          12'h11C: slv_reg_0x11C <= S_AXI_WDATA;
	          12'h120: slv_reg_0x120 <= S_AXI_WDATA;
	          12'h124: slv_reg_0x124 <= S_AXI_WDATA;

	          12'h300: slv_reg_0x300 <= S_AXI_WDATA;
	          12'h304: slv_reg_0x304 <= S_AXI_WDATA;
	          12'h308: slv_reg_0x308 <= S_AXI_WDATA;

	          12'h400: slv_reg_0x400 <= S_AXI_WDATA;
	          12'h404: slv_reg_0x404 <= S_AXI_WDATA;
	          12'h410: slv_reg_0x410 <= S_AXI_WDATA;
	          12'h420: slv_reg_0x420 <= S_AXI_WDATA;
	          12'h430: slv_reg_0x430 <= S_AXI_WDATA;
	          12'h440: slv_reg_0x440 <= S_AXI_WDATA;
	          12'h450: slv_reg_0x450 <= S_AXI_WDATA;
	          12'h460: slv_reg_0x460 <= S_AXI_WDATA;
	          12'h470: slv_reg_0x470 <= S_AXI_WDATA;
	          12'h480: slv_reg_0x480 <= S_AXI_WDATA;
	          12'h4A0: slv_reg_0x4A0 <= S_AXI_WDATA;
	          12'h4A4: slv_reg_0x4A4 <= S_AXI_WDATA;
	          12'h4A8: slv_reg_0x4A8 <= S_AXI_WDATA;
	          12'h4AC: slv_reg_0x4AC <= S_AXI_WDATA;
	          12'h4B0: slv_reg_0x4B0 <= S_AXI_WDATA;
	          12'h4B4: slv_reg_0x4B4 <= S_AXI_WDATA;

	          12'h4B8: slv_reg_0x4B8 <= S_AXI_WDATA;
	          12'h4C0: slv_reg_0x4C0 <= S_AXI_WDATA;
	        endcase
	      end
	  end
	end    






	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[11:0] )
	        12'h0     : reg_data_out <= slv_reg_0x0  ;
	        12'h4     : reg_data_out <= slv_reg_0x4  ;
	        12'h8     : reg_data_out <= slv_reg_0x8  ;
	        12'hC     : reg_data_out <= slv_reg_0xC  ;
	        12'h10    : reg_data_out <= slv_reg_0x10 ;
	        12'h14    : reg_data_out <= slv_reg_0x14 ;
	        12'h18    : reg_data_out <= slv_reg_0x18 ;
	        12'h1C    : reg_data_out <= slv_reg_0x1C ;
	        12'h20    : reg_data_out <= slv_reg_0x20 ;
	        12'h24    : reg_data_out <= slv_reg_0x24 ;
	        12'h28    : reg_data_out <= slv_reg_0x28 ;
	        12'h2C    : reg_data_out <= slv_reg_0x2C ;
	        12'h34    : reg_data_out <= slv_reg_0x34 ;
	        12'h3C    : reg_data_out <= slv_reg_0x3C ;
	        12'h40    : reg_data_out <= slv_reg_0x40 ;
	        12'h44    : reg_data_out <= slv_reg_0x44 ;
	        12'h48    : reg_data_out <= slv_reg_0x48 ;
	        12'h4C    : reg_data_out <= slv_reg_0x4C ;
	        12'h50    : reg_data_out <= slv_reg_0x50 ;
	        12'h54    : reg_data_out <= slv_reg_0x54 ;
	        12'h58    : reg_data_out <= slv_reg_0x58 ;
	        12'h5C    : reg_data_out <= slv_reg_0x5C ;
	        12'h60    : reg_data_out <= slv_reg_0x60 ;
                
	        12'h100   : reg_data_out <= slv_reg_0x100 ;
	        12'h104   : reg_data_out <= slv_reg_0x104 ;
	        12'h108   : reg_data_out <= slv_reg_0x108 ;
	        12'h10C   : reg_data_out <= slv_reg_0x10C ;
	        12'h110   : reg_data_out <= slv_reg_0x110 ;
	        12'h114   : reg_data_out <= slv_reg_0x114 ;
	        12'h118   : reg_data_out <= slv_reg_0x118 ;
	        12'h11C   : reg_data_out <= slv_reg_0x11C ;
	        12'h120   : reg_data_out <= slv_reg_0x120 ;
	        12'h124   : reg_data_out <= slv_reg_0x124 ;
	        

	        12'h300   : reg_data_out <= slv_reg_0x300;
	        12'h304   : reg_data_out <= slv_reg_0x304;
	        12'h308   : reg_data_out <= slv_reg_0x308;

	        12'h400   : reg_data_out <= slv_reg_0x400;
	        12'h404   : reg_data_out <= slv_reg_0x404;
	        12'h410   : reg_data_out <= slv_reg_0x410;
	        12'h420   : reg_data_out <= slv_reg_0x420;
	        12'h430   : reg_data_out <= slv_reg_0x430;
	        12'h440   : reg_data_out <= slv_reg_0x440;
	        12'h450   : reg_data_out <= slv_reg_0x450;
	        12'h460   : reg_data_out <= slv_reg_0x460;
	        12'h470   : reg_data_out <= slv_reg_0x470;
	        12'h480   : reg_data_out <= slv_reg_0x480;
	        12'h4A0   : reg_data_out <= slv_reg_0x4A0;
	        12'h4A4   : reg_data_out <= slv_reg_0x4A4;
	        12'h4A8   : reg_data_out <= slv_reg_0x4A8;
	        12'h4AC   : reg_data_out <= slv_reg_0x4AC;
	        12'h4B0   : reg_data_out <= slv_reg_0x4B0;
	        12'h4B4   : reg_data_out <= slv_reg_0x4B4;

	        12'h4B8   : reg_data_out <= slv_reg_0x4B8;
	        12'h4C0   : reg_data_out <= slv_reg_0x4C0;
//	        12'h4C4   : reg_data_out <= channel_status_ch0[31:0];
//	        12'h4C8   : reg_data_out <= channel_status_ch0[63:32];
//	        12'h4CC   : reg_data_out <= channel_status_ch0[95:64];
//	        12'h4D0   : reg_data_out <= channel_status_ch0[127:96];
//	        12'h4D4   : reg_data_out <= channel_status_ch0[159:128];
//	        12'h4D8   : reg_data_out <= channel_status_ch0[191:160];
//	        12'h4DC   : reg_data_out <= ch0_sample_cnt;
//	        12'h4E0   : reg_data_out <= ch1_sample_cnt;
//	        12'h4E4   : reg_data_out <= aud_block_state;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    



// CONTROL OUTPUTS
assign disp_dtc_regs[`ENABLE]               = (TPG_GEN_EN && slv_reg_0x0[0]);
assign disp_dtc_regs[`VSYNC_POLARITY]       = slv_reg_0x4[0];
assign disp_dtc_regs[`HSYNC_POLARITY]       = slv_reg_0x8[0];
assign disp_dtc_regs[`DATA_ENABLE_POLARITY] = slv_reg_0xC[0];
assign disp_dtc_regs[`VSYNC_WIDTH]          = slv_reg_0x10[13:0];
assign disp_dtc_regs[`VERT_BACK_PORCH]      = slv_reg_0x14[13:0];
assign disp_dtc_regs[`VERT_FRONT_PORCH]     = slv_reg_0x18[13:0];
assign disp_dtc_regs[`VRES]                 = slv_reg_0x1C[13:0];
assign disp_dtc_regs[`HSYNC_WIDTH]          = slv_reg_0x20[13:0];
assign disp_dtc_regs[`HORIZ_BACK_PORCH]     = slv_reg_0x24[13:0];
assign disp_dtc_regs[`HORIZ_FRONT_PORCH]    = slv_reg_0x28[13:0];
assign disp_dtc_regs[`HRES]                 = slv_reg_0x2C[13:0];
assign disp_dtc_regs[`FRAMELOCK_ENABLE]     = slv_reg_0x34[31];
assign disp_dtc_regs[`FRAMELOCK_DELAY]      = slv_reg_0x34[10:0];
assign disp_dtc_regs[`FRAMELOCK_ALIGN_HSYNC]= slv_reg_0x3C[16];
assign disp_dtc_regs[`FRAMELOCK_LINE_FRAC]  = slv_reg_0x3C[10:0];
assign hdcolorbar_cfg                       = slv_reg_0x40[2:0];
assign disp_dtc_regs[`TC_HSBLNK]            = slv_reg_0x44[13:0];
assign disp_dtc_regs[`TC_HSSYNC]            = slv_reg_0x48[13:0];
assign disp_dtc_regs[`TC_HESYNC]            = slv_reg_0x4C[13:0];
assign disp_dtc_regs[`TC_HEBLNK]            = slv_reg_0x50[13:0];
assign disp_dtc_regs[`TC_VSBLNK]            = slv_reg_0x54[13:0];
assign disp_dtc_regs[`TC_VSSYNC]            = slv_reg_0x58[13:0];
assign disp_dtc_regs[`TC_VESYNC]            = slv_reg_0x5C[13:0];
assign disp_dtc_regs[`TC_VEBLNK]            = slv_reg_0x60[13:0];
assign misc0                                = slv_reg_0x300[7:0];
assign misc1                                = slv_reg_0x304[7:0];
assign test_pattern                         = slv_reg_0x308[2:0];
assign en_sw_pattern                        = slv_reg_0x308[4];
assign dual_pixel_mode                      = slv_reg_0x308[8];
assign quad_pixel_mode                      = slv_reg_0x308[9];
assign octa_pixel_mode                      = slv_reg_0x308[10];


// SDP

assign disp_sdp_data_regs = {slv_reg_0x120,slv_reg_0x11C,slv_reg_0x118,slv_reg_0x114,slv_reg_0x110,slv_reg_0x10C,slv_reg_0x108,slv_reg_0x104,slv_reg_0x100};
assign disp_sdp_ctrl_regs = slv_reg_0x124;



assign aud_reset = slv_reg_0x400[0];        
assign aud_start = slv_reg_0x400[1];        
assign aud_drop =  slv_reg_0x400[2];                 
assign aud_config_update = (((axi_awaddr == 12'h404) && (S_AXI_AWVALID == 1)) ? 1 : 0);
assign aud_sample_rate   = slv_reg_0x404[3:0];        
assign offset_addr_cntr  =  cOFFSET_CNTR[slv_reg_0x404[2:0]];
assign aud_channel_count = slv_reg_0x404[11:8];        
assign aud_channel_status = {slv_reg_0x4A0, slv_reg_0x4A4, slv_reg_0x4A8, slv_reg_0x4AC, slv_reg_0x4B0, slv_reg_0x4B4};
assign aud_pattern1      = slv_reg_0x410[1:0];        
assign aud_pattern2      = slv_reg_0x420[1:0];        
assign aud_pattern3      = slv_reg_0x430[1:0];        
assign aud_pattern4      = slv_reg_0x440[1:0];        
assign aud_pattern5      = slv_reg_0x450[1:0];        
assign aud_pattern6      = slv_reg_0x460[1:0];        
assign aud_pattern7      = slv_reg_0x470[1:0];        
assign aud_pattern8      = slv_reg_0x480[1:0];        
assign aud_period1       = slv_reg_0x410[11:8];        
assign aud_period2       = slv_reg_0x420[11:8];        
assign aud_period3       = slv_reg_0x430[11:8];        
assign aud_period4       = slv_reg_0x440[11:8];        
assign aud_period5       = slv_reg_0x450[11:8];        
assign aud_period6       = slv_reg_0x460[11:8];        
assign aud_period7       = slv_reg_0x470[11:8];        
assign aud_period8       = slv_reg_0x480[11:8];        

   assign axi4lite_timer = slv_reg_0x4C0;
   assign audio_chk_start= slv_reg_0x4B8[0];
   assign audio_stream_id= slv_reg_0x4B8[7:4];
endmodule


//------------------------------------------------------------------------------ 
// Copyright (c) 2010 Xilinx, Inc. 
// All Rights Reserved 
//------------------------------------------------------------------------------ 
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /   Vendor: Xilinx 
// \   \   \/    Author: Vamsi Krishna, IPS Division, Xilinx, Inc.
//  \   \        
//  /   /        
// /___/   /\    Date Created: Oct 11, 2010
// \   \  /  \ 
//  \___\/\___\ 
// 
//------------------------------------------------------------------------------ 
/*
This video generator is used to create different test patterns as listed in 
DP compliance specification.


*/

`timescale 1 ps / 1 ps


module av_pat_gen_v2_0_1_video_pattern_new
#(
  parameter pTCQ = 100,
  parameter C_PPC = 4
)

(
  input wire clk,
  input wire rst,
  input wire [7:0]  misc0, // DP config register
  input wire [7:0]  misc1, // DP confing register
  input wire [13:0] vcount_in,
  input wire [13:0] hcount_in,
  output reg        vid_enable_adj,
  input wire        dual_pixel_mode,  
  input wire        quad_pixel_mode,  
  input wire        octa_pixel_mode,  
  output wire [2:0] bpc_out,
  input wire [2:0]  pattern,
  output reg  [47:0] pixel0,
  output reg  [47:0] pixel1,
  output reg  [47:0] pixel2,
  output reg  [47:0] pixel3,
  output reg  [47:0] pixel4,
  output reg  [47:0] pixel5,
  output reg  [47:0] pixel6,
  output reg  [47:0] pixel7,
  output wire        tvalid,
  output wire        tlast,
  output wire        tuser,
  input wire         tready
  );

// DP MISC0 Fields
parameter VESA_RANGE = 1'b0;
parameter CEA_RANGE  = 1'b1;

parameter YCBCR_ITU_R_BT601 = 1'b0;
parameter YCBCR_ITU_R_BT709 = 1'b1;

parameter BPC_6  = 3'b000;
parameter BPC_8  = 3'b001;
parameter BPC_10 = 3'b010;
parameter BPC_12 = 3'b011;
parameter BPC_16 = 3'b100;

parameter RGB_FORMAT      = 2'b00;
parameter YCBCR_FORMAT    = 2'b01;

// Color Square
parameter COLOR_WHITE  = 3'b000;
parameter COLOR_YELLOW = 3'b001;
parameter COLOR_CYAN   = 3'b010;
parameter COLOR_GREEN  = 3'b011;
parameter COLOR_MAGENTA= 3'b100;
parameter COLOR_RED    = 3'b101;
parameter COLOR_BLUE   = 3'b110;
parameter COLOR_BLACK  = 3'b111;

parameter STATE_RED    = 2'b00;
parameter STATE_GREEN  = 2'b01;
parameter STATE_BLUE   = 2'b10;
parameter STATE_WHITE  = 2'b11;
parameter TOGGLE_BLACK = 1'b0;
parameter TOGGLE_WHITE = 1'b1;

parameter COLOR_RAMP_PATTERN        = 3'b001;
parameter BW_VERTICAL_LINES_PATTERN = 3'b010;
parameter COLOR_SQUARE_PATTERN      = 3'b011;
parameter FLAT_RED_PATTERN          = 3'b100;
parameter FLAT_GREEN_PATTERN        = 3'b101;
parameter FLAT_BLUE_PATTERN         = 3'b110;
parameter FLAT_YELLOW_PATTERN       = 3'b111;

//Color Coefficient ROM
(* rom_extract = "yes" *)
reg [47:0] data_out;
reg [2:0]  color_square;
reg [47:0] pixel0_reg, pixel1_reg;
reg [47:0] pixel2_reg, pixel3_reg;
reg [47:0] pixel0_reg_q, pixel1_reg_q;
reg [47:0] pixel2_reg_q, pixel3_reg_q;

reg [47:0] pixel4_reg, pixel5_reg;
reg [47:0] pixel6_reg, pixel7_reg;
reg [47:0] pixel4_reg_q, pixel5_reg_q;
reg [47:0] pixel6_reg_q, pixel7_reg_q;

reg [2:0] pattern_state;
reg [2:0]  patterns;
reg [15:0] step_size=1;
reg lines64_q, lines32_q;
reg hlines64_q;
reg hlines64_qq;
reg hsync_q;
reg vsync_q;
reg [7:0] vid_enable_adj_taps;
reg vid_started;
reg [1:0]   ramp_index = STATE_RED;
reg         bw_toggle  = TOGGLE_BLACK;
reg [15:0]  ramp_mid_value; 
reg [2:0]   color_square_cnt = 0;
reg         color_square_seq = 0;
reg         lines32_seq = 0;
reg         lines32_seq_q;
wire cr_cb;
reg cr_cb_r;
reg [47:0] pixel0_i, pixel0_i_q;
reg [47:0] pixel1_i, pixel1_i_q;
reg [47:0] pixel2_i, pixel2_i_q;
reg [47:0] pixel3_i, pixel3_i_q;
reg [47:0] pixel4_i, pixel4_i_q;
reg [47:0] pixel5_i, pixel5_i_q;
reg [47:0] pixel6_i, pixel6_i_q;
reg [47:0] pixel7_i, pixel7_i_q;
reg [47:0] pixel0_order, pixel1_order;
reg [47:0] pixel2_order, pixel3_order;
reg [47:0] pixel4_order, pixel6_order;
reg [47:0] pixel5_order, pixel7_order;
reg [3:0] cea_shift = 0;
wire [1:0] ramp_index_next; 
wire [47:0] max_color_value;
wire [1:0] comp_format;
wire       dyn_range;
wire       ycbcr_coloromitry;
wire [2:0] bpc;
wire [9:0] color_def_addr;
wire [1:0] pixel_mode;

wire [13:0] vcount_1;
wire [13:0] hcount_2;
wire lines64_ahead_1p;
wire lines32_ahead_1p;
wire lines64_1p;
wire lines32_1p;   
wire hlines64_1p; 
//wire lines64_ahead_2p;
//wire lines32_ahead_2p;
//wire lines64_2p;
//wire lines32_2p;
wire hlines64_2p; 
wire hlines64_4p; 
wire lines64_ahead;  
wire lines32_ahead;  
wire lines64; 
wire lines32; 
wire hlines64;
wire [15:0] rgb_reset_value;
wire [15:0] pixel_reset_value_r;
wire [15:0] pixel_reset_value_g;
wire [15:0] pixel_reset_value_b;
wire load_last;
wire load_6;
wire load_5;
wire load_4;
wire load_3;
reg tvalid_stage1;
reg tready_stage1;
reg tvalid_stage2;
reg tvalid_stage3;
reg tvalid_stage4;
reg tvalid_stage5;
reg tvalid_stage6;
reg tready_stage2;
reg tlast_stage2;
reg tlast_stage3;
reg tlast_stage4;
reg tlast_stage5;
reg tlast_stage6;
reg tuser_stage2;
reg tuser_stage3;
reg tuser_stage4;
reg tuser_stage5;
reg tuser_stage6;
reg [13:0] vcount;
reg [13:0] hcount;
wire [13:0] hcount_in_plus3;
wire [13:0] vcount_in_plus3;
wire [13:0] hcount_in_min1;
wire [13:0] vcount_in_min1;
wire [13:0] vcount_in_min2;
wire        vid_enable;
wire        hsync;
wire        vsync;
wire        vsync_fe;
reg         vsync_del;
reg         mux_ctrl;
wire hena;
wire hena_inc;
reg [1:0] vsync_drop;

wire mode_422_ppc_gr_1 = (misc0[2:1]==2'b01 && (dual_pixel_mode==1'b1 || quad_pixel_mode==1'b1));

assign max_color_value   = data_out;
assign ycbcr_coloromitry = misc0[4];
assign comp_format       = (misc0[2:1]!=0)?YCBCR_FORMAT:RGB_FORMAT;
assign dyn_range         = (comp_format==YCBCR_FORMAT)?1'b0:misc0[3];
assign bpc     = misc0[7:5];
assign bpc_out = bpc;
assign color_def_addr = {color_square, bpc, ycbcr_coloromitry, dyn_range, comp_format};
// Video enable - adjusted to new pixel data
always@(posedge clk) begin
    vid_enable_adj_taps <= #pTCQ {vid_enable_adj_taps[6:0],vid_enable};     
end 

always@(posedge clk) begin
  if(rst) begin
    vid_enable_adj <= 0;
  end else begin
    case(patterns)  
      COLOR_RAMP_PATTERN:         vid_enable_adj <= vid_enable;   
      BW_VERTICAL_LINES_PATTERN:  vid_enable_adj <= vid_enable; //_adj_taps[3];   
      COLOR_SQUARE_PATTERN:       vid_enable_adj <= vid_enable;//_adj_taps[3];   
      default:                    vid_enable_adj <= vid_enable;   
    endcase    
  end
end  

// Controls to help detecting edges...
always@(posedge clk) begin
  if(rst) begin
    hsync_q <= #pTCQ 0;
    vsync_q <= #pTCQ 0;
  end else if (hena) begin
    hsync_q <= #pTCQ hsync;
    vsync_q <= #pTCQ vsync;
  end  
end 


always@(posedge clk) begin
  if(rst || vsync_fe) begin
    vid_started <= #pTCQ 0;
  end else if(vid_enable) begin
    vid_started <= #pTCQ 1;
  end	  
end

assign   pixel_mode = (octa_pixel_mode)? 2'b11: (quad_pixel_mode)? 2'b10: (dual_pixel_mode)?2'b01:2'b00;

// Control signals to detect depth of 32 & 64 lines
assign vcount_1 = vcount + 1;
assign hcount_2 = hcount - 2;

assign lines64_ahead_1p  = ((vcount_1%64) ? 1'b0: 1'b1 ) & vid_started;
assign lines32_ahead_1p  = ((vcount_1%32) ? 1'b0: 1'b1 ) & vid_started;
assign lines64_1p        = ( (vcount%64)?1'b0:1'b1 )     & vid_enable;
assign lines32_1p        = ( (vcount%32)?1'b0:1'b1 )     & vid_enable;
assign hlines64_1p       = ( (hcount_2%64)?1'b0:1'b1 )   & vid_enable; 

//assign lines64_ahead_2p  = ((vcount_1%32) ? 1'b0: 1'b1 ) & vid_started;
//assign lines32_ahead_2p  = ((vcount_1%16) ? 1'b0: 1'b1 ) & vid_started;
//assign lines64_2p        = ( (vcount%32)?1'b0:1'b1 )     & vid_enable;
//assign lines32_2p        = ( (vcount%16)?1'b0:1'b1 )     & vid_enable;
assign hlines64_2p       = ( (hcount_2%32)?1'b0:1'b1 )   & vid_enable; 
//assign hlines64_4p       = ( (hcount_2%16)?1'b0:1'b1 )   & vid_enable; 
assign hlines64_4p       = ( (hcount%16)?1'b0:1'b1 )   & vid_enable; 
assign hlines64_8p       = ( (hcount%8)?1'b0:1'b1 )   & vid_enable; 

assign lines64_ahead  = lines64_ahead_1p;  
assign lines32_ahead  = lines32_ahead_1p;  
assign lines64        = lines64_1p; 
assign lines32        = lines32_1p; 
assign hlines64       = (octa_pixel_mode)? hlines64_8p:(quad_pixel_mode)? hlines64_4p:(dual_pixel_mode)?hlines64_2p:hlines64_1p; 
                                                          
always@(posedge clk) begin
  if(rst) begin
    lines64_q  <= #pTCQ 0;
    lines32_q  <= #pTCQ 0;
  end else begin
    lines64_q  <= #pTCQ lines64;
    lines32_q  <= #pTCQ lines32;
  end
end

always@(posedge clk) begin
  if(rst) begin
    hlines64_q <= #pTCQ 0;
    hlines64_qq <= #pTCQ 0;
  end else if (hena) begin
    hlines64_q <= #pTCQ hlines64;
    hlines64_qq<= #pTCQ hlines64_q;
  end
end

// Logic to generate MIN value for different BPC & Range

always@(posedge clk) begin
  case(misc0[7:5])
    BPC_8:  cea_shift <= #pTCQ 2;
    BPC_10: cea_shift <= #pTCQ 4;   
    BPC_12: cea_shift <= #pTCQ 6;   
    BPC_16: cea_shift <= #pTCQ 10;   
  endcase
end

// Logic to handle reset/init values for all patterns & ranges
assign rgb_reset_value = 16'h0;
assign pixel_reset_value_r = (misc0[3]==VESA_RANGE)?rgb_reset_value: (16'h0004<<cea_shift);
assign pixel_reset_value_g = (misc0[3]==VESA_RANGE)?rgb_reset_value: (16'h0004<<cea_shift);
assign pixel_reset_value_b = (misc0[3]==VESA_RANGE)?rgb_reset_value: (16'h0004<<cea_shift);

// Test pattern - Color Ramp
// Ramps pattern is R -> G -> B -> W

assign  ramp_index_next = ramp_index + 1; 

// Get ramp mid values - used in coarse & fine ramps...
always@(*) begin
  case(misc0[7:5])
    BPC_10:  ramp_mid_value = (lines32_seq)?16'h0000:16'h0180;      
    BPC_12:  ramp_mid_value = (lines32_seq)?16'h0000:16'h0780;      
    BPC_16:  ramp_mid_value = (lines32_seq)?16'h0000:16'h7F80;      
    default: ramp_mid_value = (lines32_seq)?16'h0000:16'h0000;
  endcase    
end  

// COLOR_SQUARE_PATTERN sequence counter
always@(posedge clk) begin
  if(rst || vsync_fe || (hsync & ~hsync_q)) begin
    color_square_cnt <= #pTCQ 7;
  //end else if((hlines64 & ~hlines64_q) && hena) begin
  end else if((hlines64 & ~hlines64_q) && load_3) begin
    color_square_cnt <= #pTCQ color_square_cnt + 1;
  end	  
end

always@(*) begin
  if(misc0[7:5]!=BPC_6 || misc0[7:5]!=BPC_8) begin
     // Adjuts step size based on ramp pattern defined in spec
     if(lines32_seq) begin
       case(misc0[7:5])
         BPC_10:  step_size =  4;		       
         BPC_12:  step_size =  16;	       
         BPC_16:  step_size =  256;		       
         default: step_size =  1;		 
       endcase		      
     end else begin  
       step_size = 1;		 
     end		      
  end else begin
    step_size = 1;
  end    
end

always@(posedge clk) begin
  if(rst || vsync_fe) 
    lines32_seq <= #pTCQ 0;	    
  else if( (lines32_ahead & (hsync & ~hsync_q))  || (lines64_ahead & (hsync & ~hsync_q)))
    lines32_seq <= #pTCQ ~lines32_seq;	    

  lines32_seq_q <= #pTCQ lines32_seq;
end  
// generating h_count, v_count
//

assign hcount_in_plus3 = hcount_in + 3;
assign hcount_in_min1 = hcount_in - 1;
assign vcount_in_plus3 = vcount_in + 3;
assign vcount_in_min1 = vcount_in - 1;
assign vcount_in_min2 = vcount_in - 2;

  assign hena = (patterns==COLOR_RAMP_PATTERN)?(!tvalid_stage1 || (tready || !tvalid_stage2)) :(!tvalid_stage1 || (tready || !tvalid_stage2 || !tvalid_stage3
                 || !tvalid_stage4 || !tvalid_stage5 || !tvalid_stage6));
  assign hena_inc = (tready || !tvalid_stage2);  // only increment when data is consumned.
  assign hclr = (hcount >= (hcount_in_plus3)) && hena;

always@(posedge clk) begin
  if(rst)
    hcount <= hcount_in_plus3;
  else if (hclr)
    hcount <= 0;
  else if (hena)
    hcount <= hcount + 1;
end

  assign hblnk = (hcount > hcount_in_min1);
  assign hsync = (hcount > hcount_in) && (hcount < hcount_in_plus3);

 assign tlast_stage1 = (hcount == (hcount_in_min1));
 assign active_lines = (hcount < hcount_in) && (vcount < vcount_in);

 assign tuser_stage1 = (hcount == 0) && (vcount == 0);

assign vena = hclr;
assign vclr = ((vcount >= vcount_in_plus3) && vena );

always@(posedge clk) begin
  if(rst)
    vcount <= vcount_in_plus3;
  else if (vclr)
    vcount <= 0;
  else if (hclr)
    vcount <= vcount + 1;
end

  assign vblnk = (vcount > vcount_in_min1);
  assign vsync = (vcount > vcount_in) && (vcount < vcount_in_plus3);

  assign vid_enable = !(hblnk | vblnk);


always@(posedge clk) begin
  if(rst)
    vsync_del <= 0;
  else 
    vsync_del <= vsync;
end
  
 assign vsync_fe = !vsync & (vsync_del);

always@(posedge clk) begin
  if(rst) begin
    vsync_drop <= 0;
    mux_ctrl <= 1'b0;
  end
  else if (vsync_fe) begin
    vsync_drop <= vsync_drop + 1;
    if (&vsync_drop)
       mux_ctrl <= 1'b1;
  end
end

assign tvalid_start1 = ((vcount == vcount_in_plus3) && (hcount == hcount_in_plus3) && hena); 
assign tvalid_start = ((vcount <= vcount_in_min2) && (hcount == hcount_in_plus3) && hena); 
assign tvalid_stop  = ((vcount <= vcount_in_min1) && (hcount == hcount_in_min1) && hena); 

always@(posedge clk) begin
  if(rst)
    tvalid_stage1 <= 1'b0;
  else if (tvalid_start || tvalid_start1) 
    tvalid_stage1 <= 1'b1 && mux_ctrl;
  else if (tvalid_stop)
    tvalid_stage1 <= 1'b0;
end


//  assign tvalid_stage1 = active_lines && mux_ctrl;

always@(posedge clk) begin
  if(rst || vsync_fe) begin
    if(pattern==COLOR_SQUARE_PATTERN)    
      color_square     <= #pTCQ COLOR_WHITE;
    else if(pattern==BW_VERTICAL_LINES_PATTERN)    
      color_square     <= #pTCQ COLOR_BLACK;
    else    
      color_square     <= #pTCQ COLOR_RED;
    ramp_index       <= #pTCQ STATE_RED;//STATE_WHITE; 
    bw_toggle        <= #pTCQ TOGGLE_BLACK;
    color_square_seq <= 1'b0;
    pixel0_reg       <= #pTCQ {pixel_reset_value_r,pixel_reset_value_g,pixel_reset_value_b};      
    pixel1_reg       <= #pTCQ {pixel_reset_value_r,pixel_reset_value_g,pixel_reset_value_b};      
    pixel2_reg       <= #pTCQ {pixel_reset_value_r,pixel_reset_value_g,pixel_reset_value_b};      
    pixel3_reg       <= #pTCQ {pixel_reset_value_r,pixel_reset_value_g,pixel_reset_value_b};      

    pixel4_reg       <= #pTCQ {pixel_reset_value_r,pixel_reset_value_g,pixel_reset_value_b};      
    pixel5_reg       <= #pTCQ {pixel_reset_value_r,pixel_reset_value_g,pixel_reset_value_b};      
    pixel6_reg       <= #pTCQ {pixel_reset_value_r,pixel_reset_value_g,pixel_reset_value_b};      
    pixel7_reg       <= #pTCQ {pixel_reset_value_r,pixel_reset_value_g,pixel_reset_value_b};      

    patterns <= pattern;
  end else if (hena) begin
    if(patterns==COLOR_RAMP_PATTERN) begin

          // For every 64 vertical lines, ramp changes
          //if(lines64 & ~lines64_q) begin
          if(lines64_ahead & (hsync & ~hsync_q)) begin
            ramp_index <= #pTCQ ramp_index + 1;		  

            case(ramp_index_next)	
              STATE_RED: begin	  
                pixel0_reg        <= #pTCQ {ramp_mid_value, pixel_reset_value_g, pixel_reset_value_b};
                pixel1_reg        <= #pTCQ {ramp_mid_value+step_size, pixel_reset_value_g, pixel_reset_value_b};
                pixel2_reg        <= #pTCQ {ramp_mid_value+step_size+step_size, pixel_reset_value_g, pixel_reset_value_b};
                pixel3_reg        <= #pTCQ {ramp_mid_value+step_size+step_size+step_size, pixel_reset_value_g, pixel_reset_value_b};

                pixel4_reg        <= #pTCQ {ramp_mid_value+step_size+step_size+step_size+step_size, pixel_reset_value_g, pixel_reset_value_b};
                pixel5_reg        <= #pTCQ {ramp_mid_value+step_size+step_size+step_size+step_size+step_size, pixel_reset_value_g, pixel_reset_value_b};
                pixel6_reg        <= #pTCQ {ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size, pixel_reset_value_g, pixel_reset_value_b};
                pixel7_reg        <= #pTCQ {ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size+step_size, pixel_reset_value_g, pixel_reset_value_b};
              end	    
              STATE_GREEN: begin	  
                pixel0_reg        <= #pTCQ {pixel_reset_value_r, ramp_mid_value, pixel_reset_value_b};
                pixel1_reg        <= #pTCQ {pixel_reset_value_r, ramp_mid_value+step_size, pixel_reset_value_b};
                pixel2_reg        <= #pTCQ {pixel_reset_value_r, ramp_mid_value+step_size+step_size, pixel_reset_value_b};
                pixel3_reg        <= #pTCQ {pixel_reset_value_r, ramp_mid_value+step_size+step_size+step_size, pixel_reset_value_b};

                pixel4_reg        <= #pTCQ {pixel_reset_value_r, ramp_mid_value+step_size+step_size+step_size+step_size, pixel_reset_value_b};
                pixel5_reg        <= #pTCQ {pixel_reset_value_r, ramp_mid_value+step_size+step_size+step_size+step_size+step_size, pixel_reset_value_b};
                pixel6_reg        <= #pTCQ {pixel_reset_value_r, ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size, pixel_reset_value_b};
                pixel7_reg        <= #pTCQ {pixel_reset_value_r, ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size+step_size, pixel_reset_value_b};
              end	    
              STATE_BLUE: begin	  
                pixel0_reg        <= #pTCQ {pixel_reset_value_r, pixel_reset_value_g, ramp_mid_value};
                pixel1_reg        <= #pTCQ {pixel_reset_value_r, pixel_reset_value_g, ramp_mid_value+step_size};
                pixel2_reg        <= #pTCQ {pixel_reset_value_r, pixel_reset_value_g, ramp_mid_value+step_size+step_size};
                pixel3_reg        <= #pTCQ {pixel_reset_value_r, pixel_reset_value_g, ramp_mid_value+step_size+step_size+step_size};

                pixel4_reg        <= #pTCQ {pixel_reset_value_r, pixel_reset_value_g, ramp_mid_value+step_size+step_size+step_size+step_size};
                pixel5_reg        <= #pTCQ {pixel_reset_value_r, pixel_reset_value_g, ramp_mid_value+step_size+step_size+step_size+step_size+step_size};
                pixel6_reg        <= #pTCQ {pixel_reset_value_r, pixel_reset_value_g, ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size};
                pixel7_reg        <= #pTCQ {pixel_reset_value_r, pixel_reset_value_g, ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size+step_size};
              end	    
              STATE_WHITE: begin	  
                pixel0_reg        <= #pTCQ {ramp_mid_value, ramp_mid_value, ramp_mid_value};
                pixel1_reg[47:32] <= #pTCQ ramp_mid_value+step_size;
                pixel1_reg[31:16] <= #pTCQ ramp_mid_value+step_size;
                pixel1_reg[15:0]  <= #pTCQ ramp_mid_value+step_size;

                pixel2_reg[47:32] <= #pTCQ ramp_mid_value+step_size+step_size;
                pixel2_reg[31:16] <= #pTCQ ramp_mid_value+step_size+step_size;
                pixel2_reg[15:0]  <= #pTCQ ramp_mid_value+step_size+step_size;

                pixel3_reg[47:32] <= #pTCQ ramp_mid_value+step_size+step_size+step_size;
                pixel3_reg[31:16] <= #pTCQ ramp_mid_value+step_size+step_size+step_size;
                pixel3_reg[15:0]  <= #pTCQ ramp_mid_value+step_size+step_size+step_size;

                pixel4_reg[47:32] <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size;
                pixel4_reg[31:16] <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size;
                pixel4_reg[15:0]  <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size;

                pixel5_reg[47:32] <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size+step_size;
                pixel5_reg[31:16] <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size+step_size;
                pixel5_reg[15:0]  <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size+step_size;

                pixel6_reg[47:32] <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size;
                pixel6_reg[31:16] <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size;
                pixel6_reg[15:0]  <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size;

                pixel7_reg[47:32] <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size+step_size;
                pixel7_reg[31:16] <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size+step_size;
                pixel7_reg[15:0]  <= #pTCQ ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size+step_size;
              end	    
            endcase	

	  // Generate ramp based on color config programmed above  
          end else begin

	    // Gets color value from ROM
            case(ramp_index)
              STATE_RED:   color_square <= #pTCQ COLOR_RED;		    
              STATE_GREEN: color_square <= #pTCQ COLOR_GREEN;		    
              STATE_BLUE:  color_square <= #pTCQ COLOR_BLUE;		    
              STATE_WHITE: color_square <= #pTCQ COLOR_WHITE;		    
	    endcase

             //if(lines32 & ~lines32_q)  lines32_seq <= #pTCQ ~lines32_seq;	    

	     // RED Pixel Ramp 
              if(  //pixel0_reg[47:32] == max_color_value[47:32] ||
                      (pixel0_reg[47:32] == 16'h003F && misc0[7:5]==BPC_6) ||
                      (pixel0_reg[47:32] == 16'h00FF && misc0[7:5]==BPC_8) ||   	      
		              (~hsync & hsync_q)                           ||
             		  (lines32_seq & ~lines32_seq_q)               ||

                 ( ((pixel0_reg[47:32] == 16'h027F && lines32_seq==0) || pixel0_reg[47:32] == 16'h03FC 
	                   ) && misc0[7:5]==BPC_10 && pixel_mode==0) ||

                 ( ((pixel1_reg[47:32] == 16'h027F) || pixel1_reg[47:32] == 16'h03FC) && 
                 misc0[7:5]==BPC_10 && (pixel_mode==1)) ||

                 ( ((pixel3_reg[47:32] == 16'h027F) || pixel3_reg[47:32] == 16'h03FC) && 
                 misc0[7:5]==BPC_10 && (pixel_mode==2)) ||

                 ( ((pixel0_reg[47:32] == 16'h087F && lines32_seq==0) || pixel0_reg[47:32] == 16'h0FF0 
         	            ) && misc0[7:5]==BPC_12 && pixel_mode==0) ||

                 ( (pixel1_reg[47:32] == 16'h087F || pixel1_reg[47:32] == 16'h0FF0) &&
                 misc0[7:5]==BPC_12 && (pixel_mode==1)) ||

                 ( (pixel3_reg[47:32] == 16'h087F || pixel3_reg[47:32] == 16'h0FF0) &&
                 misc0[7:5]==BPC_12 && (pixel_mode==2)) ||

            		 ( ((pixel0_reg[47:32] == 16'h807F && lines32_seq==0) || pixel0_reg[47:32] == 16'hFF00 
	               ) && misc0[7:5]==BPC_16 && pixel_mode==0)  ||

            		 ( (pixel1_reg[47:32] == 16'h807F || pixel1_reg[47:32] == 16'hFF00) &&
                 misc0[7:5]==BPC_16  && (pixel_mode==1)) ||

            		 ( (pixel3_reg[47:32] == 16'h807F || pixel3_reg[47:32] == 16'hFF00) &&
                 misc0[7:5]==BPC_16  && (pixel_mode==2)) 

               ) begin

                  pixel0_reg[47:32]        <= #pTCQ (ramp_index==STATE_RED || ramp_index==STATE_WHITE)?ramp_mid_value:0;
                  pixel1_reg[47:32]        <= #pTCQ (ramp_index==STATE_RED || ramp_index==STATE_WHITE)?ramp_mid_value+step_size:0;
                  pixel2_reg[47:32]        <= #pTCQ (ramp_index==STATE_RED || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size:0;
                  pixel3_reg[47:32]        <= #pTCQ (ramp_index==STATE_RED || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size:0;

                  pixel4_reg[47:32]        <= #pTCQ (ramp_index==STATE_RED || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size:0;
                  pixel5_reg[47:32]        <= #pTCQ (ramp_index==STATE_RED || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size+step_size:0;
                  pixel6_reg[47:32]        <= #pTCQ (ramp_index==STATE_RED || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size:0;
                  pixel7_reg[47:32]        <= #pTCQ (ramp_index==STATE_RED || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size+step_size:0;
              end else if(vid_enable && (ramp_index == STATE_WHITE || ramp_index == STATE_RED)) begin
                pixel0_reg[47:32] <= #pTCQ pixel0_reg[47:32] + ((step_size)<<(pixel_mode));
                pixel1_reg[47:32] <= #pTCQ pixel1_reg[47:32] + ((step_size)<<(pixel_mode));
                pixel2_reg[47:32] <= #pTCQ pixel2_reg[47:32] + ((step_size)<<(pixel_mode));
                pixel3_reg[47:32] <= #pTCQ pixel3_reg[47:32] + ((step_size)<<(pixel_mode));		

                pixel4_reg[47:32] <= #pTCQ pixel4_reg[47:32] + ((step_size)<<(pixel_mode));
                pixel5_reg[47:32] <= #pTCQ pixel5_reg[47:32] + ((step_size)<<(pixel_mode));
                pixel6_reg[47:32] <= #pTCQ pixel6_reg[47:32] + ((step_size)<<(pixel_mode));
                pixel7_reg[47:32] <= #pTCQ pixel7_reg[47:32] + ((step_size)<<(pixel_mode));		
       	      end else if(vid_enable && (ramp_index == STATE_GREEN || ramp_index == STATE_BLUE)) begin
                pixel0_reg[47:32] <= #pTCQ pixel_reset_value_r;
                pixel1_reg[47:32] <= #pTCQ pixel_reset_value_r;
                pixel2_reg[47:32] <= #pTCQ pixel_reset_value_r;
                pixel3_reg[47:32] <= #pTCQ pixel_reset_value_r;		

                pixel4_reg[47:32] <= #pTCQ pixel_reset_value_r;
                pixel5_reg[47:32] <= #pTCQ pixel_reset_value_r;
                pixel6_reg[47:32] <= #pTCQ pixel_reset_value_r;
                pixel7_reg[47:32] <= #pTCQ pixel_reset_value_r;		
              end		
        
	     // GREEN Pixel Ramp 
              if(  //pixel0_reg[31:16] == max_color_value[31:16] ||
                      (pixel0_reg[31:16] == 16'h003F && misc0[7:5]==BPC_6) ||
                      (pixel0_reg[31:16] == 16'h00FF && misc0[7:5]==BPC_8) ||   	      
		              (~hsync & hsync_q)                           ||
		              (lines32_seq & ~lines32_seq_q)               ||

                 ( ((pixel0_reg[31:16] == 16'h027F && lines32_seq==0) || pixel0_reg[31:16] == 16'h03FC 
	                   ) && misc0[7:5]==BPC_10 && pixel_mode==0) ||

                 ( ((pixel1_reg[31:16] == 16'h027F) || pixel1_reg[31:16] == 16'h03FC) && 
                 misc0[7:5]==BPC_10 && (pixel_mode==1)) ||

                 ( ((pixel3_reg[31:16] == 16'h027F) || pixel3_reg[31:16] == 16'h03FC) && 
                 misc0[7:5]==BPC_10 && (pixel_mode==2)) ||

                 ( ((pixel0_reg[31:16] == 16'h087F && lines32_seq==0) || pixel0_reg[31:16] == 16'h0FF0 
         	            ) && misc0[7:5]==BPC_12 && pixel_mode==0) ||

                 ( (pixel1_reg[31:16] == 16'h087F || pixel1_reg[31:16] == 16'h0FF0) &&
                 misc0[7:5]==BPC_12 && (pixel_mode==1)) ||

                 ( (pixel3_reg[31:16] == 16'h087F || pixel3_reg[31:16] == 16'h0FF0) &&
                 misc0[7:5]==BPC_12 && (pixel_mode==2)) ||

            		 ( ((pixel0_reg[31:16] == 16'h807F && lines32_seq==0) || pixel0_reg[31:16] == 16'hFF00 
	               ) && misc0[7:5]==BPC_16 && pixel_mode==0)  ||

            		 ( (pixel1_reg[31:16] == 16'h807F || pixel1_reg[31:16] == 16'hFF00) &&
                 misc0[7:5]==BPC_16  && (pixel_mode==1)) ||

            		 ( (pixel3_reg[31:16] == 16'h807F || pixel3_reg[31:16] == 16'hFF00) &&
                 misc0[7:5]==BPC_16  && (pixel_mode==2))  
            
            ) begin
                pixel0_reg[31:16]        <= #pTCQ (ramp_index==STATE_GREEN || ramp_index==STATE_WHITE)?ramp_mid_value:0;
                pixel1_reg[31:16]        <= #pTCQ (ramp_index==STATE_GREEN || ramp_index==STATE_WHITE)?ramp_mid_value+step_size:0;
                pixel2_reg[31:16]        <= #pTCQ (ramp_index==STATE_GREEN || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size:0;
                pixel3_reg[31:16]        <= #pTCQ (ramp_index==STATE_GREEN || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size:0;

                pixel4_reg[31:16]        <= #pTCQ (ramp_index==STATE_GREEN || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size:0;
                pixel5_reg[31:16]        <= #pTCQ (ramp_index==STATE_GREEN || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size+step_size:0;
                pixel6_reg[31:16]        <= #pTCQ (ramp_index==STATE_GREEN || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size:0;
                pixel7_reg[31:16]        <= #pTCQ (ramp_index==STATE_GREEN || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size+step_size:0;
              end else if(vid_enable && (ramp_index == STATE_WHITE || ramp_index == STATE_GREEN)) begin
                pixel0_reg[31:16] <= #pTCQ pixel0_reg[31:16] + (step_size<<(pixel_mode));
                pixel1_reg[31:16] <= #pTCQ pixel1_reg[31:16] + (step_size<<(pixel_mode));
                pixel2_reg[31:16] <= #pTCQ pixel2_reg[31:16] + (step_size<<(pixel_mode));
                pixel3_reg[31:16] <= #pTCQ pixel3_reg[31:16] + (step_size<<(pixel_mode));

                pixel4_reg[31:16] <= #pTCQ pixel4_reg[31:16] + (step_size<<(pixel_mode));
                pixel5_reg[31:16] <= #pTCQ pixel5_reg[31:16] + (step_size<<(pixel_mode));
                pixel6_reg[31:16] <= #pTCQ pixel6_reg[31:16] + (step_size<<(pixel_mode));
                pixel7_reg[31:16] <= #pTCQ pixel7_reg[31:16] + (step_size<<(pixel_mode));
	            end else if(vid_enable && (ramp_index == STATE_RED || ramp_index == STATE_BLUE)) begin 
                pixel0_reg[31:16] <= #pTCQ pixel_reset_value_g;
                pixel1_reg[31:16] <= #pTCQ pixel_reset_value_g;
                pixel2_reg[31:16] <= #pTCQ pixel_reset_value_g;
                pixel3_reg[31:16] <= #pTCQ pixel_reset_value_g;

                pixel4_reg[31:16] <= #pTCQ pixel_reset_value_g;
                pixel5_reg[31:16] <= #pTCQ pixel_reset_value_g;
                pixel6_reg[31:16] <= #pTCQ pixel_reset_value_g;
                pixel7_reg[31:16] <= #pTCQ pixel_reset_value_g;
              end		
              
	     // BLUE Pixel Ramp 
              if(  //pixel0_reg[15:0] == max_color_value[15:0] ||
                      (pixel0_reg[15:0] == 16'h003F && misc0[7:5]==BPC_6) ||
                      (pixel0_reg[15:0] == 16'h00FF && misc0[7:5]==BPC_8) ||   	      
		              (~hsync & hsync_q)                         ||
		              (lines32_seq & ~lines32_seq_q)             ||

                 ( ((pixel0_reg[15:0] == 16'h027F && lines32_seq==0) || pixel0_reg[15:0] == 16'h03FC 
	                   ) && misc0[7:5]==BPC_10 && pixel_mode==0) ||

                 ( ((pixel1_reg[15:0] == 16'h027F) || pixel1_reg[15:0] == 16'h03FC) && 
                 misc0[7:5]==BPC_10 && (pixel_mode==1)) ||

                 ( ((pixel3_reg[15:0] == 16'h027F) || pixel3_reg[15:0] == 16'h03FC) && 
                 misc0[7:5]==BPC_10 && (pixel_mode==2)) ||

                 ( ((pixel0_reg[15:0] == 16'h087F && lines32_seq==0) || pixel0_reg[15:0] == 16'h0FF0 
         	            ) && misc0[7:5]==BPC_12 && pixel_mode==0) ||

                 ( (pixel1_reg[15:0] == 16'h087F || pixel1_reg[15:0] == 16'h0FF0) &&
                 misc0[7:5]==BPC_12 && (pixel_mode==1)) ||

                 ( (pixel3_reg[15:0] == 16'h087F || pixel3_reg[15:0] == 16'h0FF0) &&
                 misc0[7:5]==BPC_12 && (pixel_mode==2)) ||

            		 ( ((pixel0_reg[15:0] == 16'h807F && lines32_seq==0) || pixel0_reg[15:0] == 16'hFF00 
	               ) && misc0[7:5]==BPC_16 && pixel_mode==0)  ||

            		 ( (pixel1_reg[15:0] == 16'h807F || pixel1_reg[15:0] == 16'hFF00) &&
                 misc0[7:5]==BPC_16  && (pixel_mode==1)) ||

            		 ( (pixel3_reg[15:0] == 16'h807F || pixel3_reg[15:0] == 16'hFF00) &&
                 misc0[7:5]==BPC_16  && (pixel_mode==2))  

            ) begin
                pixel0_reg[15:0]        <= #pTCQ (ramp_index==STATE_BLUE || ramp_index==STATE_WHITE)?ramp_mid_value:0;
                pixel1_reg[15:0]        <= #pTCQ (ramp_index==STATE_BLUE || ramp_index==STATE_WHITE)?ramp_mid_value+step_size:0;
                pixel2_reg[15:0]        <= #pTCQ (ramp_index==STATE_BLUE || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size:0;
                pixel3_reg[15:0]        <= #pTCQ (ramp_index==STATE_BLUE || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size:0;

                pixel4_reg[15:0]        <= #pTCQ (ramp_index==STATE_BLUE || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size:0;
                pixel5_reg[15:0]        <= #pTCQ (ramp_index==STATE_BLUE || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size+step_size:0;
                pixel6_reg[15:0]        <= #pTCQ (ramp_index==STATE_BLUE || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size:0;
                pixel7_reg[15:0]        <= #pTCQ (ramp_index==STATE_BLUE || ramp_index==STATE_WHITE)?ramp_mid_value+step_size+step_size+step_size+step_size+step_size+step_size+step_size:0;
              end else if(vid_enable && (ramp_index == STATE_WHITE || ramp_index == STATE_BLUE)) begin
                pixel0_reg[15:0] <= #pTCQ pixel0_reg[15:0] + (step_size<<(pixel_mode));
                pixel1_reg[15:0] <= #pTCQ pixel1_reg[15:0] + (step_size<<(pixel_mode));
                pixel2_reg[15:0] <= #pTCQ pixel2_reg[15:0] + (step_size<<(pixel_mode));
                pixel3_reg[15:0] <= #pTCQ pixel3_reg[15:0] + (step_size<<(pixel_mode));

                pixel4_reg[15:0] <= #pTCQ pixel4_reg[15:0] + (step_size<<(pixel_mode));
                pixel5_reg[15:0] <= #pTCQ pixel5_reg[15:0] + (step_size<<(pixel_mode));
                pixel6_reg[15:0] <= #pTCQ pixel6_reg[15:0] + (step_size<<(pixel_mode));
                pixel7_reg[15:0] <= #pTCQ pixel7_reg[15:0] + (step_size<<(pixel_mode));
              end else if(vid_enable && (ramp_index == STATE_RED || ramp_index == STATE_GREEN))begin
                pixel0_reg[15:0] <= #pTCQ pixel_reset_value_b;
                pixel1_reg[15:0] <= #pTCQ pixel_reset_value_b;
                pixel2_reg[15:0] <= #pTCQ pixel_reset_value_b;
                pixel3_reg[15:0] <= #pTCQ pixel_reset_value_b;

                pixel4_reg[15:0] <= #pTCQ pixel_reset_value_b;
                pixel5_reg[15:0] <= #pTCQ pixel_reset_value_b;
                pixel6_reg[15:0] <= #pTCQ pixel_reset_value_b;
                pixel7_reg[15:0] <= #pTCQ pixel_reset_value_b;
              end	

          end //end lines64

    end else if(patterns == BW_VERTICAL_LINES_PATTERN) begin
      if(hsync & ~hsync_q) begin	    
        bw_toggle    <= #pTCQ TOGGLE_BLACK;  
        color_square <= #pTCQ COLOR_BLACK;
      end else if(vid_enable) begin      
        if(bw_toggle==TOGGLE_BLACK) begin
          color_square <= #pTCQ COLOR_BLACK;
        end else begin
          color_square <= #pTCQ COLOR_WHITE;
        end
        bw_toggle <= #pTCQ ~bw_toggle;  
      end     
        pixel0_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel0_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel0_reg[15:0]  <= #pTCQ max_color_value[15:0];	      
        pixel1_reg[47:32] <= #pTCQ pixel0_reg[47:32];     
        pixel1_reg[31:16] <= #pTCQ pixel0_reg[31:16];     
        pixel1_reg[15:0]  <= #pTCQ pixel0_reg[15:0];      
        pixel2_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel2_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel2_reg[15:0]  <= #pTCQ max_color_value[15:0];	      
        pixel3_reg[47:32] <= #pTCQ pixel2_reg[47:32];     
        pixel3_reg[31:16] <= #pTCQ pixel2_reg[31:16];     
        pixel3_reg[15:0]  <= #pTCQ pixel2_reg[15:0];      

        pixel4_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel4_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel4_reg[15:0]  <= #pTCQ max_color_value[15:0];	      
        pixel5_reg[47:32] <= #pTCQ pixel4_reg[47:32];     
        pixel5_reg[31:16] <= #pTCQ pixel4_reg[31:16];     
        pixel5_reg[15:0]  <= #pTCQ pixel4_reg[15:0];      
        pixel6_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel6_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel6_reg[15:0]  <= #pTCQ max_color_value[15:0];	      
        pixel7_reg[47:32] <= #pTCQ pixel6_reg[47:32];     
        pixel7_reg[31:16] <= #pTCQ pixel6_reg[31:16];     
        pixel7_reg[15:0]  <= #pTCQ pixel6_reg[15:0];      

    end else if(patterns == COLOR_SQUARE_PATTERN) begin
	// Select appropriate color as per sequence defined in spec
        //if(hlines64_q & ~hlines64_qq) begin
        if(hlines64_q & ~hlines64_qq & load_4) begin
        //if(hlines64 & ~hlines64_q) begin
	  case(color_square_cnt) 
            0: color_square <= #pTCQ  (~color_square_seq)?COLOR_WHITE:COLOR_BLUE; 	  
            1: color_square <= #pTCQ  (~color_square_seq)?COLOR_YELLOW:COLOR_RED; 	  
            2: color_square <= #pTCQ  (~color_square_seq)?COLOR_CYAN:COLOR_MAGENTA; 	  
            3: color_square <= #pTCQ  COLOR_GREEN; 	  
            4: color_square <= #pTCQ  (~color_square_seq)?COLOR_MAGENTA:COLOR_CYAN; 	  
            5: color_square <= #pTCQ  (~color_square_seq)?COLOR_RED:COLOR_YELLOW; 	  
            6: color_square <= #pTCQ  (~color_square_seq)?COLOR_BLUE:COLOR_WHITE; 	  
            7: color_square <= #pTCQ  COLOR_BLACK; 	  
          endcase	  
	end//end hlines64_q	  
       
//	if(lines64 & ~lines64_q) 
        if(lines64_ahead & (hsync & ~hsync_q)) 
   	  color_square_seq <= #pTCQ ~color_square_seq;

//      if(vid_enable) begin
      if(load_6) begin
        pixel0_reg[47:32] <= #pTCQ (mode_422_ppc_gr_1)?max_color_value[15:0]:max_color_value[47:32];	      
        pixel0_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel0_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel1_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel1_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel1_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel2_reg[47:32] <= #pTCQ (mode_422_ppc_gr_1)?max_color_value[15:0]:max_color_value[47:32];	      
        pixel2_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel2_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel3_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel3_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel3_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel4_reg[47:32] <= #pTCQ (mode_422_ppc_gr_1)?max_color_value[15:0]:max_color_value[47:32];	      
        pixel4_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel4_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel5_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel5_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel5_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel6_reg[47:32] <= #pTCQ (mode_422_ppc_gr_1)?max_color_value[15:0]:max_color_value[47:32];	      
        pixel6_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel6_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel7_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel7_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel7_reg[15:0]  <= #pTCQ max_color_value[15:0];	      
      end
//      end
    end else if(patterns == FLAT_RED_PATTERN) begin
        color_square     <= #pTCQ COLOR_RED;
        pixel0_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel0_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel0_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel1_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel1_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel1_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel2_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel2_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel2_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel3_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel3_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel3_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel4_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel4_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel4_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel5_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel5_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel5_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel6_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel6_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel6_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel7_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel7_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel7_reg[15:0]  <= #pTCQ max_color_value[15:0];	      
    end else if(patterns == FLAT_GREEN_PATTERN) begin
        color_square     <= #pTCQ COLOR_GREEN;
        pixel0_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel0_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel0_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel1_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel1_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel1_reg[15:0]  <= #pTCQ max_color_value[15:0];	     

        pixel2_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel2_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel2_reg[15:0]  <= #pTCQ max_color_value[15:0];	     

        pixel3_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel3_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel3_reg[15:0]  <= #pTCQ max_color_value[15:0];	     

        pixel4_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel4_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel4_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel5_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel5_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel5_reg[15:0]  <= #pTCQ max_color_value[15:0];	     

        pixel6_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel6_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel6_reg[15:0]  <= #pTCQ max_color_value[15:0];	     

        pixel7_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel7_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel7_reg[15:0]  <= #pTCQ max_color_value[15:0];	     
    end else if(patterns == FLAT_BLUE_PATTERN) begin
        color_square     <= #pTCQ COLOR_BLUE;
        pixel0_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel0_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel0_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel1_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel1_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel1_reg[15:0]  <= #pTCQ max_color_value[15:0];	             	

        pixel2_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel2_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel2_reg[15:0]  <= #pTCQ max_color_value[15:0];	             	

        pixel3_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel3_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel3_reg[15:0]  <= #pTCQ max_color_value[15:0];	             	

        pixel4_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel4_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel4_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel5_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel5_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel5_reg[15:0]  <= #pTCQ max_color_value[15:0];	             	

        pixel6_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel6_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel6_reg[15:0]  <= #pTCQ max_color_value[15:0];	             	

        pixel7_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel7_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel7_reg[15:0]  <= #pTCQ max_color_value[15:0];	             	
    end else if(patterns == FLAT_YELLOW_PATTERN) begin
        color_square     <= #pTCQ COLOR_YELLOW;
        pixel0_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel0_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel0_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel1_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel1_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel1_reg[15:0]  <= #pTCQ max_color_value[15:0];	      	

        pixel2_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel2_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel2_reg[15:0]  <= #pTCQ max_color_value[15:0];	      	

        pixel3_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel3_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel3_reg[15:0]  <= #pTCQ max_color_value[15:0];	      	

        pixel4_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel4_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel4_reg[15:0]  <= #pTCQ max_color_value[15:0];	      

        pixel5_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel5_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel5_reg[15:0]  <= #pTCQ max_color_value[15:0];	      	

        pixel6_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel6_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel6_reg[15:0]  <= #pTCQ max_color_value[15:0];	      	

        pixel7_reg[47:32] <= #pTCQ max_color_value[47:32];	      
        pixel7_reg[31:16] <= #pTCQ max_color_value[31:16];	      
        pixel7_reg[15:0]  <= #pTCQ max_color_value[15:0];	      	
    end // end pattern
  end // end rst
end //end always

// YCBCR422 - Chroma bus is shared


// By default pixels are aligned as per DP PG Spec (Native Interface). At top level RGB -> RBG, CrYCb -> CrCbY.
// For 422, Align as per AXI4S to convert properly Crb-Y -> CrbY-
always@(*) begin
  pixel0_order = (misc0[2:1]==2'b01)? ( (cr_cb)?{pixel0_i[47:32],16'h0000,pixel0_i[31:16]}:{pixel0_i[15:0],16'h0000,pixel0_i[31:16]} )
                              : pixel0_i;  
  pixel1_order = (misc0[2:1]==2'b01)? ( (~cr_cb)?{pixel1_i[15:0],16'h0000,pixel1_i[31:16]}:{pixel1_i[47:32],16'h0000,pixel1_i[31:16]} )
                              : pixel1_i;  
  pixel2_order = (misc0[2:1]==2'b01)? ( (cr_cb)?{pixel2_i[47:32],16'h0000,pixel2_i[31:16]}:{pixel2_i[15:0],16'h0000,pixel2_i[31:16]} )
                              : pixel2_i;  
  pixel3_order = (misc0[2:1]==2'b01)? ( (~cr_cb)?{pixel3_i[15:0],16'h0000,pixel3_i[31:16]}:{pixel3_i[47:32],16'h0000,pixel3_i[31:16]} )
                              : pixel3_i;  


  pixel4_order = (misc0[2:1]==2'b01)? ( (cr_cb)?{pixel4_i[47:32],16'h0000,pixel4_i[31:16]}:{pixel4_i[15:0],16'h0000,pixel4_i[31:16]} )
                              : pixel4_i;  
  pixel5_order = (misc0[2:1]==2'b01)? ( (~cr_cb)?{pixel5_i[15:0],16'h0000,pixel5_i[31:16]}:{pixel5_i[47:32],16'h0000,pixel5_i[31:16]} )
                              : pixel5_i;  
  pixel6_order = (misc0[2:1]==2'b01)? ( (cr_cb)?{pixel6_i[47:32],16'h0000,pixel6_i[31:16]}:{pixel6_i[15:0],16'h0000,pixel6_i[31:16]} )
                              : pixel6_i;  
  pixel7_order = (misc0[2:1]==2'b01)? ( (~cr_cb)?{pixel7_i[15:0],16'h0000,pixel7_i[31:16]}:{pixel7_i[47:32],16'h0000,pixel7_i[31:16]} )
                              : pixel7_i;  
end  



always@(*) begin
  //if(misc0[2:1] == 2'b10) begin //YCBCR422
  //  pixel0 = {pixel0_order[15:0], pixel0_order[31:16], pixel0_order[47:32]};    
  //  pixel1 = {pixel1_order[15:0], pixel1_order[31:16], pixel1_order[47:32]};    
  //end else begin
    pixel0 = pixel0_order;    
    pixel1 = pixel1_order;    
    pixel2 = pixel2_order;    
    pixel3 = pixel3_order;    

    if (C_PPC == 8) begin
        pixel4 = pixel4_order;    
        pixel5 = pixel5_order;    
        pixel6 = pixel6_order;    
        pixel7 = pixel7_order;    
    end
    else begin
        pixel4 = 0;
        pixel5 = 0;
        pixel6 = 0;
        pixel7 = 0;

    end
end  

// Signals to generate YCBCR422 timing
always@(posedge clk) begin
  pixel0_i_q <= #pTCQ pixel0_i;    
  pixel1_i_q <= #pTCQ pixel1_i;    
  pixel2_i_q <= #pTCQ pixel2_i;    
  pixel3_i_q <= #pTCQ pixel3_i;    

  pixel4_i_q <= #pTCQ pixel4_i;    
  pixel5_i_q <= #pTCQ pixel5_i;    
  pixel6_i_q <= #pTCQ pixel6_i;    
  pixel7_i_q <= #pTCQ pixel7_i;    
end  

always@(posedge clk) begin
  if(rst || vsync_fe || hsync) begin
    cr_cb_r <= #pTCQ 0;      
  end else if(vid_enable_adj) begin
    cr_cb_r <= #pTCQ ~cr_cb_r;      
  end    
end  
assign cr_cb = cr_cb_r | mode_422_ppc_gr_1;

assign load_3 = (load_4 || !tvalid_stage3);

always@(posedge clk) begin
  if(rst) begin
    tvalid_stage3 <= 1'b0; 
    tlast_stage3 <= 1'b0;
    tuser_stage3 <= 1'b0;
  end
  //else if (tready || !tvalid_stage4 || !tvalid_stage3) begin
  else if (load_3) begin
       tvalid_stage3 <= tvalid_stage1;
       tlast_stage3 <= tlast_stage1;
       tuser_stage3 <= tuser_stage1;
  end
end

assign load_4 = (load_5 || !tvalid_stage4);

always@(posedge clk) begin
  if(rst) begin
    tvalid_stage4 <= 1'b0; 
    tlast_stage4 <= 1'b0;
    tuser_stage4 <= 1'b0;
  end
  //else if (tready || !tvalid_stage5 || !tvalid_stage4) begin
  else if (load_4) begin
       tvalid_stage4 <= tvalid_stage3;
       tlast_stage4 <= tlast_stage3;
       tuser_stage4 <= tuser_stage3;
  end
end

assign load_5 = (load_6 || !tvalid_stage5);

always@(posedge clk) begin
  if(rst) begin
    tvalid_stage5 <= 1'b0; 
    tlast_stage5 <= 1'b0;
    tuser_stage5 <= 1'b0;
  end
  //else if (tready || !tvalid_stage6 || !tvalid_stage5) begin
  else if (load_5) begin
       tvalid_stage5 <= tvalid_stage4;
       tlast_stage5 <= tlast_stage4;
       tuser_stage5 <= tuser_stage4;
  end
end

assign load_6 = (load_last || !tvalid_stage6);

always@(posedge clk) begin
  if(rst) begin
    tvalid_stage6 <= 1'b0; 
    tlast_stage6 <= 1'b0;
    tuser_stage6 <= 1'b0;
  end
  //else if (tready || !tvalid_stage2 || !tvalid_stage6) begin
  else if (load_6) begin
       tvalid_stage6 <= tvalid_stage5;
       tlast_stage6 <= tlast_stage5;
       tuser_stage6 <= tuser_stage5;
  end
end

assign tvalid_stage61 = (patterns==COLOR_RAMP_PATTERN)?tvalid_stage1:tvalid_stage6;
assign tlast_stage61 = (patterns==COLOR_RAMP_PATTERN)?tlast_stage1:tlast_stage6;
assign tuser_stage61 = (patterns==COLOR_RAMP_PATTERN)?tuser_stage1:tuser_stage6;

assign load_last = (tready || !tvalid_stage2);

always@(posedge clk) begin
  if(rst) begin
    tvalid_stage2 <= 1'b0; 
    tlast_stage2 <= 1'b0;
    tuser_stage2 <= 1'b0;
  end
  //else if (tready || !tvalid_stage2) begin
  else if (load_last) begin
    if (mux_ctrl)
         tvalid_stage2 <= tvalid_stage61;

       tlast_stage2 <= tlast_stage61;
       tuser_stage2 <= tuser_stage61;
  end
end

assign tvalid = tvalid_stage2;
assign tlast = tlast_stage2;
assign tuser = tuser_stage2;

always@(posedge clk) begin
  if(rst) begin
    pixel0_i <= 0;
    pixel1_i <= 0;    
    pixel2_i <= 0;    
    pixel3_i <= 0;   
    pixel4_i <= 0;
    pixel5_i <= 0;    
    pixel6_i <= 0;    
    pixel7_i <= 0;    
  //end else if (tready || !tvalid_stage2) begin  
  end else if (load_last) begin  
    case(misc0[7:5])
      BPC_6: begin 
        pixel0_i[47:32] <= #pTCQ {pixel0_reg[37:32],10'b0};    
        pixel0_i[31:16] <= #pTCQ {pixel0_reg[21:16],10'b0};    
        pixel0_i[15:0]  <= #pTCQ {pixel0_reg[5:0],10'b0};    

        pixel1_i[47:32] <= #pTCQ {pixel1_reg[37:32],10'b0};    
        pixel1_i[31:16] <= #pTCQ {pixel1_reg[21:16],10'b0};    
        pixel1_i[15:0]  <= #pTCQ {pixel1_reg[5:0],10'b0};    

        pixel2_i[47:32] <= #pTCQ {pixel2_reg[37:32],10'b0};    
        pixel2_i[31:16] <= #pTCQ {pixel2_reg[21:16],10'b0};    
        pixel2_i[15:0]  <= #pTCQ {pixel2_reg[5:0],10'b0};    

        pixel3_i[47:32] <= #pTCQ {pixel3_reg[37:32],10'b0};    
        pixel3_i[31:16] <= #pTCQ {pixel3_reg[21:16],10'b0};    
        pixel3_i[15:0]  <= #pTCQ {pixel3_reg[5:0],10'b0};    

        pixel4_i[47:32] <= #pTCQ {pixel4_reg[37:32],10'b0};    
        pixel4_i[31:16] <= #pTCQ {pixel4_reg[21:16],10'b0};    
        pixel4_i[15:0]  <= #pTCQ {pixel4_reg[5:0],10'b0};    

        pixel5_i[47:32] <= #pTCQ {pixel5_reg[37:32],10'b0};    
        pixel5_i[31:16] <= #pTCQ {pixel5_reg[21:16],10'b0};    
        pixel5_i[15:0]  <= #pTCQ {pixel5_reg[5:0],10'b0};    

        pixel6_i[47:32] <= #pTCQ {pixel6_reg[37:32],10'b0};    
        pixel6_i[31:16] <= #pTCQ {pixel6_reg[21:16],10'b0};    
        pixel6_i[15:0]  <= #pTCQ {pixel6_reg[5:0],10'b0};    

        pixel7_i[47:32] <= #pTCQ {pixel7_reg[37:32],10'b0};    
        pixel7_i[31:16] <= #pTCQ {pixel7_reg[21:16],10'b0};    
        pixel7_i[15:0]  <= #pTCQ {pixel7_reg[5:0],10'b0};    
      end      

      BPC_8: begin 
        pixel0_i[47:32] <= #pTCQ {pixel0_reg[39:32],8'b0};    
        pixel0_i[31:16] <= #pTCQ {pixel0_reg[23:16],8'b0};    
        pixel0_i[15:0]  <= #pTCQ {pixel0_reg[7:0],8'b0};    

        pixel1_i[47:32] <= #pTCQ {pixel1_reg[39:32],8'b0};    
        pixel1_i[31:16] <= #pTCQ {pixel1_reg[23:16],8'b0};    
        pixel1_i[15:0]  <= #pTCQ {pixel1_reg[7:0],8'b0};    

        pixel2_i[47:32] <= #pTCQ {pixel2_reg[39:32],8'b0};    
        pixel2_i[31:16] <= #pTCQ {pixel2_reg[23:16],8'b0};    
        pixel2_i[15:0]  <= #pTCQ {pixel2_reg[7:0],8'b0};    

        pixel3_i[47:32] <= #pTCQ {pixel3_reg[39:32],8'b0};    
        pixel3_i[31:16] <= #pTCQ {pixel3_reg[23:16],8'b0};    
        pixel3_i[15:0]  <= #pTCQ {pixel3_reg[7:0],8'b0};    

        pixel4_i[47:32] <= #pTCQ {pixel4_reg[39:32],8'b0};    
        pixel4_i[31:16] <= #pTCQ {pixel4_reg[23:16],8'b0};    
        pixel4_i[15:0]  <= #pTCQ {pixel4_reg[7:0],8'b0};    

        pixel5_i[47:32] <= #pTCQ {pixel5_reg[39:32],8'b0};    
        pixel5_i[31:16] <= #pTCQ {pixel5_reg[23:16],8'b0};    
        pixel5_i[15:0]  <= #pTCQ {pixel5_reg[7:0],8'b0};    

        pixel6_i[47:32] <= #pTCQ {pixel6_reg[39:32],8'b0};    
        pixel6_i[31:16] <= #pTCQ {pixel6_reg[23:16],8'b0};    
        pixel6_i[15:0]  <= #pTCQ {pixel6_reg[7:0],8'b0};    

        pixel7_i[47:32] <= #pTCQ {pixel7_reg[39:32],8'b0};    
        pixel7_i[31:16] <= #pTCQ {pixel7_reg[23:16],8'b0};    
        pixel7_i[15:0]  <= #pTCQ {pixel7_reg[7:0],8'b0};    
      end      

      BPC_10: begin 
        pixel0_i[47:32] <= #pTCQ {pixel0_reg[41:32],6'b0};    
        pixel0_i[31:16] <= #pTCQ {pixel0_reg[25:16],6'b0};    
        pixel0_i[15:0]  <= #pTCQ {pixel0_reg[9:0],6'b0};    

        pixel1_i[47:32] <= #pTCQ {pixel1_reg[41:32],6'b0};    
        pixel1_i[31:16] <= #pTCQ {pixel1_reg[25:16],6'b0};    
        pixel1_i[15:0]  <= #pTCQ {pixel1_reg[9:0],6'b0};    

        pixel2_i[47:32] <= #pTCQ {pixel2_reg[41:32],6'b0};    
        pixel2_i[31:16] <= #pTCQ {pixel2_reg[25:16],6'b0};    
        pixel2_i[15:0]  <= #pTCQ {pixel2_reg[9:0],6'b0};    

        pixel3_i[47:32] <= #pTCQ {pixel3_reg[41:32],6'b0};    
        pixel3_i[31:16] <= #pTCQ {pixel3_reg[25:16],6'b0};    
        pixel3_i[15:0]  <= #pTCQ {pixel3_reg[9:0],6'b0};    

        pixel4_i[47:32] <= #pTCQ {pixel4_reg[41:32],6'b0};    
        pixel4_i[31:16] <= #pTCQ {pixel4_reg[25:16],6'b0};    
        pixel4_i[15:0]  <= #pTCQ {pixel4_reg[9:0],6'b0};    

        pixel5_i[47:32] <= #pTCQ {pixel5_reg[41:32],6'b0};    
        pixel5_i[31:16] <= #pTCQ {pixel5_reg[25:16],6'b0};    
        pixel5_i[15:0]  <= #pTCQ {pixel5_reg[9:0],6'b0};    

        pixel6_i[47:32] <= #pTCQ {pixel6_reg[41:32],6'b0};    
        pixel6_i[31:16] <= #pTCQ {pixel6_reg[25:16],6'b0};    
        pixel6_i[15:0]  <= #pTCQ {pixel6_reg[9:0],6'b0};    

        pixel7_i[47:32] <= #pTCQ {pixel7_reg[41:32],6'b0};    
        pixel7_i[31:16] <= #pTCQ {pixel7_reg[25:16],6'b0};    
        pixel7_i[15:0]  <= #pTCQ {pixel7_reg[9:0],6'b0};    
      end	

      BPC_12: begin 
        pixel0_i[47:32] <= #pTCQ {pixel0_reg[43:32],4'b0};    
        pixel0_i[31:16] <= #pTCQ {pixel0_reg[27:16],4'b0};    
        pixel0_i[15:0]  <= #pTCQ {pixel0_reg[11:0],4'b0};    

        pixel1_i[47:32] <= #pTCQ {pixel1_reg[43:32],4'b0};    
        pixel1_i[31:16] <= #pTCQ {pixel1_reg[27:16],4'b0};    
        pixel1_i[15:0]  <= #pTCQ {pixel1_reg[11:0],4'b0};    

        pixel2_i[47:32] <= #pTCQ {pixel2_reg[43:32],4'b0};    
        pixel2_i[31:16] <= #pTCQ {pixel2_reg[27:16],4'b0};    
        pixel2_i[15:0]  <= #pTCQ {pixel2_reg[11:0],4'b0};    

        pixel3_i[47:32] <= #pTCQ {pixel3_reg[43:32],4'b0};    
        pixel3_i[31:16] <= #pTCQ {pixel3_reg[27:16],4'b0};    
        pixel3_i[15:0]  <= #pTCQ {pixel3_reg[11:0],4'b0};    

        pixel4_i[47:32] <= #pTCQ {pixel4_reg[43:32],4'b0};    
        pixel4_i[31:16] <= #pTCQ {pixel4_reg[27:16],4'b0};    
        pixel4_i[15:0]  <= #pTCQ {pixel4_reg[11:0],4'b0};    

        pixel5_i[47:32] <= #pTCQ {pixel5_reg[43:32],4'b0};    
        pixel5_i[31:16] <= #pTCQ {pixel5_reg[27:16],4'b0};    
        pixel5_i[15:0]  <= #pTCQ {pixel5_reg[11:0],4'b0};    

        pixel6_i[47:32] <= #pTCQ {pixel6_reg[43:32],4'b0};    
        pixel6_i[31:16] <= #pTCQ {pixel6_reg[27:16],4'b0};    
        pixel6_i[15:0]  <= #pTCQ {pixel6_reg[11:0],4'b0};    

        pixel7_i[47:32] <= #pTCQ {pixel7_reg[43:32],4'b0};    
        pixel7_i[31:16] <= #pTCQ {pixel7_reg[27:16],4'b0};    
        pixel7_i[15:0]  <= #pTCQ {pixel7_reg[11:0],4'b0};    
      end	

      BPC_16: begin 
        pixel0_i[47:32] <= #pTCQ pixel0_reg[47:32];    
        pixel0_i[31:16] <= #pTCQ pixel0_reg[31:16];    
        pixel0_i[15:0]  <= #pTCQ pixel0_reg[15:0];    

        pixel1_i[47:32] <= #pTCQ pixel1_reg[47:32];    
        pixel1_i[31:16] <= #pTCQ pixel1_reg[31:16];    
        pixel1_i[15:0]  <= #pTCQ pixel1_reg[15:0];    

        pixel2_i[47:32] <= #pTCQ pixel2_reg[47:32];    
        pixel2_i[31:16] <= #pTCQ pixel2_reg[31:16];    
        pixel2_i[15:0]  <= #pTCQ pixel2_reg[15:0];    

        pixel3_i[47:32] <= #pTCQ pixel3_reg[47:32];    
        pixel3_i[31:16] <= #pTCQ pixel3_reg[31:16];    
        pixel3_i[15:0]  <= #pTCQ pixel3_reg[15:0];    

        pixel4_i[47:32] <= #pTCQ pixel4_reg[47:32];    
        pixel4_i[31:16] <= #pTCQ pixel4_reg[31:16];    
        pixel4_i[15:0]  <= #pTCQ pixel4_reg[15:0];    

        pixel5_i[47:32] <= #pTCQ pixel5_reg[47:32];    
        pixel5_i[31:16] <= #pTCQ pixel5_reg[31:16];    
        pixel5_i[15:0]  <= #pTCQ pixel5_reg[15:0];    

        pixel6_i[47:32] <= #pTCQ pixel6_reg[47:32];    
        pixel6_i[31:16] <= #pTCQ pixel6_reg[31:16];    
        pixel6_i[15:0]  <= #pTCQ pixel6_reg[15:0];    

        pixel7_i[47:32] <= #pTCQ pixel7_reg[47:32];    
        pixel7_i[31:16] <= #pTCQ pixel7_reg[31:16];    
        pixel7_i[15:0]  <= #pTCQ pixel7_reg[15:0];    
      end	
    endcase  
  end  
end


// ROM
// Contains Color Definitions of RGB (VESA/CEA) Range, YCbCr (VESA/CEA) Range
// Used by pattern generation logic to determine various color values

always@(posedge clk) begin
  //if (hena) begin // && (patterns!=COLOR_RAMP_PATTERN)) begin //tready || !tvalid_stage2) begin
  if (load_5) begin // && (patterns!=COLOR_RAMP_PATTERN)) begin //tready || !tvalid_stage2) begin
  case(color_def_addr)
    // ************************************************************ RGB VESA ******************************************************************* //
          // RGB, VESA, White  
    {COLOR_WHITE, BPC_6, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 63;    data_out[31:16] <= 63;    data_out[15:0] <= 63;    end
    {COLOR_WHITE, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 255;   data_out[31:16] <= 255;   data_out[15:0] <= 255;   end
    {COLOR_WHITE, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 1023;  data_out[31:16] <= 1023;  data_out[15:0] <= 1023;  end
    {COLOR_WHITE, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 4095;  data_out[31:16] <= 4095;  data_out[15:0] <= 4095;  end
    {COLOR_WHITE, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 65535; data_out[31:16] <= 65535; data_out[15:0] <= 65535; end
          // RGB, VESA, Yellow
    {COLOR_YELLOW, BPC_6, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:   begin data_out[47:32] <= 63;    data_out[31:16] <= 63;    data_out[15:0] <= 0;     end
    {COLOR_YELLOW, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:   begin data_out[47:32] <= 255;   data_out[31:16] <= 255;   data_out[15:0] <= 0;     end
    {COLOR_YELLOW, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:   begin data_out[47:32] <= 1023;  data_out[31:16] <= 1023;  data_out[15:0] <= 0;     end
    {COLOR_YELLOW, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:   begin data_out[47:32] <= 4095;  data_out[31:16] <= 4095;  data_out[15:0] <= 0;     end
    {COLOR_YELLOW, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:   begin data_out[47:32] <= 65535; data_out[31:16] <= 65535; data_out[15:0] <= 0;     end
          // RGB, VESA, Cyan    
    {COLOR_CYAN, BPC_6, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 0;     data_out[31:16] <= 63;    data_out[15:0] <= 63;    end
    {COLOR_CYAN, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 0;     data_out[31:16] <= 255;   data_out[15:0] <= 255;   end
    {COLOR_CYAN, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 0;     data_out[31:16] <= 1023;  data_out[15:0] <= 1023;  end
    {COLOR_CYAN, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 0;     data_out[31:16] <= 4095;  data_out[15:0] <= 4095;  end
    {COLOR_CYAN, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 0;     data_out[31:16] <= 65535; data_out[15:0] <= 65535; end
          // RGB, VESA, Green  
    {COLOR_GREEN, BPC_6, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 0;     data_out[31:16] <= 63;    data_out[15:0] <= 0;     end
    {COLOR_GREEN, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 0;     data_out[31:16] <= 255;   data_out[15:0] <= 0;     end
    {COLOR_GREEN, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 0;     data_out[31:16] <= 1023;  data_out[15:0] <= 0;     end
    {COLOR_GREEN, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 0;     data_out[31:16] <= 4095;  data_out[15:0] <= 0;     end
    {COLOR_GREEN, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 0;     data_out[31:16] <= 65535; data_out[15:0] <= 0;     end
          // RGB, VESA, Magenta
    {COLOR_MAGENTA, BPC_6, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:  begin data_out[47:32] <= 63;    data_out[31:16] <= 0;     data_out[15:0] <= 63;    end
    {COLOR_MAGENTA, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:  begin data_out[47:32] <= 255;   data_out[31:16] <= 0;     data_out[15:0] <= 255;   end
    {COLOR_MAGENTA, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:  begin data_out[47:32] <= 1023;  data_out[31:16] <= 0;     data_out[15:0] <= 1023;  end
    {COLOR_MAGENTA, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:  begin data_out[47:32] <= 4095;  data_out[31:16] <= 0;     data_out[15:0] <= 4095;  end
    {COLOR_MAGENTA, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:  begin data_out[47:32] <= 65535; data_out[31:16] <= 0;     data_out[15:0] <= 65535; end
          // RGB, VESA, Red    
    {COLOR_RED, BPC_6, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 63;    data_out[31:16] <= 0;     data_out[15:0] <= 0;     end
    {COLOR_RED, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 255;   data_out[31:16] <= 0;     data_out[15:0] <= 0;     end
    {COLOR_RED, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 1023;  data_out[31:16] <= 0;     data_out[15:0] <= 0;     end
    {COLOR_RED, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 4095;  data_out[31:16] <= 0;     data_out[15:0] <= 0;     end
    {COLOR_RED, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 65535; data_out[31:16] <= 0;     data_out[15:0] <= 0;     end
          // RGB, VESA, Blue   
    {COLOR_BLUE, BPC_6, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 0;     data_out[31:16] <= 0;     data_out[15:0] <= 63;    end
    {COLOR_BLUE, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 0;     data_out[31:16] <= 0;     data_out[15:0] <= 255;   end
    {COLOR_BLUE, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 0;     data_out[31:16] <= 0;     data_out[15:0] <= 1023;  end
    {COLOR_BLUE, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 0;     data_out[31:16] <= 0;     data_out[15:0] <= 4095;  end
    {COLOR_BLUE, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 0;     data_out[31:16] <= 0;     data_out[15:0] <= 65535; end
          // RGB, VESA, Black  
    {COLOR_BLACK, BPC_6, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 0;     data_out[31:16] <= 0;     data_out[15:0] <= 0;     end
    {COLOR_BLACK, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 0;     data_out[31:16] <= 0;     data_out[15:0] <= 0;     end
    {COLOR_BLACK, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 0;     data_out[31:16] <= 0;     data_out[15:0] <= 0;     end
    {COLOR_BLACK, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 0;     data_out[31:16] <= 0;     data_out[15:0] <= 0;     end
    {COLOR_BLACK, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 0;     data_out[31:16] <= 0;     data_out[15:0] <= 0;     end
          
    // ************************************************************ RGB CEA ******************************************************************* //
          // RGB, CEA, White  
    {COLOR_WHITE, BPC_8, YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 235;   data_out[31:16] <= 235;   data_out[15:0] <= 235;   end
    {COLOR_WHITE, BPC_10,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 940;   data_out[31:16] <=  940;  data_out[15:0] <=  940;  end
    {COLOR_WHITE, BPC_12,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 3760;  data_out[31:16] <= 3760;  data_out[15:0] <= 3760;  end
    {COLOR_WHITE, BPC_16,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 60160; data_out[31:16] <= 60160; data_out[15:0] <= 60160; end
          // RGB, CEA, Yellow
    {COLOR_YELLOW, BPC_8, YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 235;   data_out[31:16] <= 235;   data_out[15:0] <= 16;    end
    {COLOR_YELLOW, BPC_10,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <=  940;  data_out[31:16] <=  940;  data_out[15:0] <= 64;    end
    {COLOR_YELLOW, BPC_12,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 3760;  data_out[31:16] <= 3760;  data_out[15:0] <= 256;   end
    {COLOR_YELLOW, BPC_16,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:    begin data_out[47:32] <= 60160; data_out[31:16] <= 60160; data_out[15:0] <= 4096;  end
          // RGB, CEA, Cyan                                             
    {COLOR_CYAN, BPC_8, YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 16;    data_out[31:16] <= 235;   data_out[15:0] <= 255;   end
    {COLOR_CYAN, BPC_10,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 64;    data_out[31:16] <= 940;   data_out[15:0] <= 1023;  end
    {COLOR_CYAN, BPC_12,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 256;   data_out[31:16] <= 3760;  data_out[15:0] <= 4095;  end
    {COLOR_CYAN, BPC_16,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 4096;  data_out[31:16] <= 60160; data_out[15:0] <= 65535; end
          // RGB, CEA, Green                                            
    {COLOR_GREEN, BPC_8, YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 16;    data_out[31:16] <= 235;   data_out[15:0] <= 16;    end
    {COLOR_GREEN, BPC_10,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 64;    data_out[31:16] <= 940;   data_out[15:0] <= 64;    end
    {COLOR_GREEN, BPC_12,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 256;   data_out[31:16] <= 3760;  data_out[15:0] <= 256;   end
    {COLOR_GREEN, BPC_16,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 4096;  data_out[31:16] <= 60160; data_out[15:0] <= 4096;  end
          // RGB, CEA, Magenta                                          
    {COLOR_MAGENTA, BPC_8, YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:   begin data_out[47:32] <= 235;   data_out[31:16] <= 16;    data_out[15:0] <= 235;   end
    {COLOR_MAGENTA, BPC_10,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:   begin data_out[47:32] <= 940;   data_out[31:16] <= 64;    data_out[15:0] <= 940;   end
    {COLOR_MAGENTA, BPC_12,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:   begin data_out[47:32] <= 3760;  data_out[31:16] <= 256;   data_out[15:0] <= 3760;  end
    {COLOR_MAGENTA, BPC_16,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:   begin data_out[47:32] <= 60160; data_out[31:16] <= 4096;  data_out[15:0] <= 60160; end
          // RGB, CEA, Red                                              
    {COLOR_RED, BPC_8, YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:       begin data_out[47:32] <= 235;   data_out[31:16] <= 16;    data_out[15:0] <= 16;    end
    {COLOR_RED, BPC_10,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:       begin data_out[47:32] <= 940;   data_out[31:16] <= 64;    data_out[15:0] <= 64;    end
    {COLOR_RED, BPC_12,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:       begin data_out[47:32] <= 3760;  data_out[31:16] <= 256;   data_out[15:0] <= 256;   end
    {COLOR_RED, BPC_16,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:       begin data_out[47:32] <= 60160; data_out[31:16] <= 4096;  data_out[15:0] <= 4096;  end
          // RGB, CEA, Blue                                             
    {COLOR_BLUE, BPC_8, YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 16;    data_out[31:16] <= 16;    data_out[15:0] <= 235;   end
    {COLOR_BLUE, BPC_10,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 64;    data_out[31:16] <= 64;    data_out[15:0] <= 940;   end
    {COLOR_BLUE, BPC_12,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 256;   data_out[31:16] <= 256;   data_out[15:0] <= 3760;  end
    {COLOR_BLUE, BPC_16,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:      begin data_out[47:32] <= 4096;  data_out[31:16] <= 4096;  data_out[15:0] <= 60160; end
          // RGB, CEA, Black                                            
    {COLOR_BLACK, BPC_8, YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 16;    data_out[31:16] <= 16;    data_out[15:0] <= 16;    end
    {COLOR_BLACK, BPC_10,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 64;    data_out[31:16] <= 64;    data_out[15:0] <= 64;    end
    {COLOR_BLACK, BPC_12,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 256;   data_out[31:16] <= 256;   data_out[15:0] <= 256;   end
    {COLOR_BLACK, BPC_16,YCBCR_ITU_R_BT601, CEA_RANGE, RGB_FORMAT}:     begin data_out[47:32] <= 4096;  data_out[31:16] <= 4096;  data_out[15:0] <= 4096;  end

    // ************************************************************ YCbCr 601 ******************************************************************* //
          // YCbCr, White  
    {COLOR_WHITE, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 128;   data_out[31:16] <= 235;   data_out[15:0] <= 128;   end
    {COLOR_WHITE, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 512;   data_out[31:16] <= 940;   data_out[15:0] <= 512;   end
    {COLOR_WHITE, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 2048;  data_out[31:16] <= 3760;  data_out[15:0] <= 2048;  end
    {COLOR_WHITE, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 32768; data_out[31:16] <= 60160; data_out[15:0] <= 32768; end    
          // YCbCr, Yellow
    {COLOR_YELLOW, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}: begin data_out[47:32] <= 146;   data_out[31:16] <= 210;   data_out[15:0] <=  16;   end
    {COLOR_YELLOW, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}: begin data_out[47:32] <= 553;   data_out[31:16] <= 877;   data_out[15:0] <=  64;   end
    {COLOR_YELLOW, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}: begin data_out[47:32] <= 2339;  data_out[31:16] <= 3361;  data_out[15:0] <=  257;  end
    {COLOR_YELLOW, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}: begin data_out[47:32] <= 37421; data_out[31:16] <= 53769; data_out[15:0] <=  4119; end    
          // YCbCr, Cyan
    {COLOR_CYAN, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <=  16;   data_out[31:16] <= 170;   data_out[15:0] <= 166;   end
    {COLOR_CYAN, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <=  64;   data_out[31:16] <= 753;   data_out[15:0] <= 614;   end
    {COLOR_CYAN, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <=  257;  data_out[31:16] <= 2712;  data_out[15:0] <= 2651;  end
    {COLOR_CYAN, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <=  4119; data_out[31:16] <= 43397; data_out[15:0] <= 42411; end    
          // YCbCr, Green
    {COLOR_GREEN, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <=  34;   data_out[31:16] <= 145;   data_out[15:0] <=  54;   end
    {COLOR_GREEN, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <=  106;  data_out[31:16] <= 690;   data_out[15:0] <= 167;   end
    {COLOR_GREEN, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <=  548;  data_out[31:16] <= 2313;  data_out[15:0] <=  860;  end
    {COLOR_GREEN, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <=  8773; data_out[31:16] <= 37006; data_out[15:0] <= 13762; end    
          // YCbCr, Magenta
    {COLOR_MAGENTA, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:begin data_out[47:32] <= 222;   data_out[31:16] <= 106;   data_out[15:0] <= 202;   end
    {COLOR_MAGENTA, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:begin data_out[47:32] <= 918;   data_out[31:16] <= 314;   data_out[15:0] <= 857;   end
    {COLOR_MAGENTA, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:begin data_out[47:32] <= 3548;  data_out[31:16] <= 1703;  data_out[15:0] <= 3236;  end
    {COLOR_MAGENTA, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:begin data_out[47:32] <= 56763; data_out[31:16] <= 27250; data_out[15:0] <= 51774; end    
          // YCbCr, Red
    {COLOR_RED, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:    begin data_out[47:32] <= 240;   data_out[31:16] <=  81;   data_out[15:0] <=  90;   end
    {COLOR_RED, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:    begin data_out[47:32] <= 960;   data_out[31:16] <= 251;   data_out[15:0] <= 410;   end
    {COLOR_RED, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:    begin data_out[47:32] <= 3839;  data_out[31:16] <= 1304;  data_out[15:0] <= 1445;  end
    {COLOR_RED, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:    begin data_out[47:32] <= 61417; data_out[31:16] <= 20859; data_out[15:0] <= 23125; end    
          // YCbCr, Blue
    {COLOR_BLUE, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <= 110;   data_out[31:16] <=  41;   data_out[15:0] <= 240;   end
    {COLOR_BLUE, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <= 471;   data_out[31:16] <=  127;   data_out[15:0] <= 960;   end
    {COLOR_BLUE, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <= 1757;  data_out[31:16] <=  655;  data_out[15:0] <= 3839;  end
    {COLOR_BLUE, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <= 28115; data_out[31:16] <= 10487; data_out[15:0] <= 61417; end    
          // YCbCr, Black
    {COLOR_BLACK, BPC_8, YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 128;   data_out[31:16] <=  16;   data_out[15:0] <= 128;   end
    {COLOR_BLACK, BPC_10,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 512;   data_out[31:16] <=  64;   data_out[15:0] <= 512;   end
    {COLOR_BLACK, BPC_12,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 2048;  data_out[31:16] <=  256;  data_out[15:0] <= 2048;  end
    {COLOR_BLACK, BPC_16,YCBCR_ITU_R_BT601, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 32768; data_out[31:16] <=  4096; data_out[15:0] <= 32768; end    

    // ************************************************************ YCbCr 709 ******************************************************************* //
          // YCbCr, White  
    {COLOR_WHITE, BPC_8, YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 128;   data_out[31:16] <= 235;   data_out[15:0] <= 128;   end
    {COLOR_WHITE, BPC_10,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 512;   data_out[31:16] <= 940;   data_out[15:0] <= 512;   end
    {COLOR_WHITE, BPC_12,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 2048;  data_out[31:16] <= 3760;  data_out[15:0] <= 2048;  end
    {COLOR_WHITE, BPC_16,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 32768; data_out[31:16] <= 60160; data_out[15:0] <= 32768; end    
          // YCbCr, Yellow
    {COLOR_YELLOW, BPC_8, YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}: begin data_out[47:32] <= 138;   data_out[31:16] <= 219;   data_out[15:0] <=  16;   end
    {COLOR_YELLOW, BPC_10,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}: begin data_out[47:32] <= 585;   data_out[31:16] <= 840;   data_out[15:0] <=  64;   end
    {COLOR_YELLOW, BPC_12,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}: begin data_out[47:32] <= 2213;  data_out[31:16] <= 3508;  data_out[15:0] <=  257;  end
    {COLOR_YELLOW, BPC_16,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}: begin data_out[47:32] <= 35403; data_out[31:16] <= 56123; data_out[15:0] <=  4119; end    
          // YCbCr, Cyan
    {COLOR_CYAN, BPC_8, YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <=  16;   data_out[31:16] <= 188;   data_out[15:0] <= 154;   end
    {COLOR_CYAN, BPC_10,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <=  64;   data_out[31:16] <= 678;   data_out[15:0] <= 663;   end
    {COLOR_CYAN, BPC_12,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <=  257;  data_out[31:16] <= 3014;  data_out[15:0] <= 2458;  end
    {COLOR_CYAN, BPC_16,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <=  4119; data_out[31:16] <= 48218; data_out[15:0] <= 39327; end    
          // YCbCr, Green
    {COLOR_GREEN, BPC_8, YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <=  26;   data_out[31:16] <= 173;   data_out[15:0] <=  42;   end
    {COLOR_GREEN, BPC_10,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 137;   data_out[31:16] <= 578;   data_out[15:0] <= 215;   end
    {COLOR_GREEN, BPC_12,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <=  422;  data_out[31:16] <= 2761;  data_out[15:0] <=  667;  end
    {COLOR_GREEN, BPC_16,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <=  6754; data_out[31:16] <= 44182; data_out[15:0] <= 10679; end    
          // YCbCr, Magenta
    {COLOR_MAGENTA, BPC_8, YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:begin data_out[47:32] <= 230;   data_out[31:16] <=  78;   data_out[15:0] <= 214;   end
    {COLOR_MAGENTA, BPC_10,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:begin data_out[47:32] <= 887;   data_out[31:16] <= 426;   data_out[15:0] <= 809;   end
    {COLOR_MAGENTA, BPC_12,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:begin data_out[47:32] <= 3674;  data_out[31:16] <= 1255;  data_out[15:0] <= 3429;  end
    {COLOR_MAGENTA, BPC_16,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:begin data_out[47:32] <= 58782; data_out[31:16] <= 20074; data_out[15:0] <= 54857; end    
          // YCbCr, Red
    {COLOR_RED, BPC_8, YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:    begin data_out[47:32] <= 240;   data_out[31:16] <=  63;   data_out[15:0] <= 102;   end
    {COLOR_RED, BPC_10,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:    begin data_out[47:32] <= 960;   data_out[31:16] <= 326;   data_out[15:0] <= 361;   end
    {COLOR_RED, BPC_12,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:    begin data_out[47:32] <= 3839;  data_out[31:16] <= 1002;  data_out[15:0] <= 1638;  end
    {COLOR_RED, BPC_16,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:    begin data_out[47:32] <= 61417; data_out[31:16] <= 16038; data_out[15:0] <= 26209; end    
          // YCbCr, Blue
    {COLOR_BLUE, BPC_8, YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <= 118;   data_out[31:16] <=  32;   data_out[15:0] <= 240;   end
    {COLOR_BLUE, BPC_10,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <= 439;   data_out[31:16] <= 164;   data_out[15:0] <= 960;   end
    {COLOR_BLUE, BPC_12,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <= 1883;  data_out[31:16] <=  508;  data_out[15:0] <= 3839;  end
    {COLOR_BLUE, BPC_16,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:   begin data_out[47:32] <= 30133; data_out[31:16] <=  8133; data_out[15:0] <= 61417; end    
          // YCbCr, Black
    {COLOR_BLACK, BPC_8, YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 128;   data_out[31:16] <=  16;   data_out[15:0] <= 128;   end
    {COLOR_BLACK, BPC_10,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 512;   data_out[31:16] <=  64;   data_out[15:0] <= 512;   end
    {COLOR_BLACK, BPC_12,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 2048;  data_out[31:16] <=  256;  data_out[15:0] <= 2048;  end
    {COLOR_BLACK, BPC_16,YCBCR_ITU_R_BT709, VESA_RANGE, YCBCR_FORMAT}:  begin data_out[47:32] <= 32768; data_out[31:16] <=  4096; data_out[15:0] <= 32768; end    
    //default
    default:  begin data_out[47:32] <= 0; data_out[31:16] <=  0; data_out[15:0] <= 0; end    


  endcase
end
end


endmodule










/*
 * Copyright (c) 2014 Xilinx, Inc.  All rights reserved.
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 *
 * This file contains the audio generation part of the audio generator.
 *
 * MODIFICATION HISTORY:
 *
 * Ver   Who Date         Changes
 * ----- --- ----------   -----------------------------------------------
 * 1.00  hf  2014/10/21   First release
 *
 *****************************************************************************/

//////////////////////////////////////////////////////////////////////////
//
// Programmable Audio Pattern Generator
// 
//
// Author: Vamsi Krishna
//
//////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps
`define FLOP_DELAY #100
module av_pat_gen_v2_0_1_dport

(
  input wire         aud_clk,
  input wire         aud_reset,
  input wire         aud_start,
  input wire         aud_start_axis,
  input wire [3:0]   aud_sample_rate,
  input wire [3:0]   aud_channel_count,
  input wire [41:0]  aud_spdif_channel_status,
  input wire [1:0]   aud_pattern1,
  input wire [1:0]   aud_pattern2,
  input wire [1:0]   aud_pattern3,
  input wire [1:0]   aud_pattern4,
  input wire [1:0]   aud_pattern5,
  input wire [1:0]   aud_pattern6,
  input wire [1:0]   aud_pattern7,
  input wire [1:0]   aud_pattern8,
  input wire [3:0]   aud_period_ch1,
  input wire [3:0]   aud_period_ch2,
  input wire [3:0]   aud_period_ch3,
  input wire [3:0]   aud_period_ch4,
  input wire [3:0]   aud_period_ch5,
  input wire [3:0]   aud_period_ch6,
  input wire [3:0]   aud_period_ch7,
  input wire [3:0]   aud_period_ch8,
  input wire         aud_config_update,//pulse to update the config
  input wire [23:0]  offset_addr_cntr,// to count 250ms in aud clock


  // AXI Streaming Signals
  input  wire        axis_clk, 
  input  wire        axis_resetn, 
  output reg  [31:0] axis_data_egress,
  output reg  [2:0]  axis_id_egress,
  output reg         axis_tvalid,   
  input  wire        axis_tready,
  output wire [198:0]     debug_port
);

localparam OFFSET_48KHZ_CNTR = 24'h002EE0; //Calculated from 512*48 KHz rate

wire [15:0] aud_sample_preloaded;
reg [7:0] aud_blk_count;

reg [15:0] SineLUT [0:16];
reg [15:0] SineLUT_d2 [0:16];
//-------------------------------------- Sine 2 KHz Samples ----------------------------------

always@(posedge axis_clk) begin
  SineLUT[0] <=  0;
  SineLUT[1] <=  6269; 
  SineLUT[2] <=  11585;
  SineLUT[3] <=  15136;
  SineLUT[4] <=  16383;
  SineLUT[5] <=  15136;
  SineLUT[6] <=  11585;
  SineLUT[7] <=  6270; 
  SineLUT[8] <=  0;     
  SineLUT[9] <= -6270; 
  SineLUT[10]<= -11585; 
  SineLUT[11]<= -15137;
  SineLUT[12]<= -16384;
  SineLUT[13]<= -15138;
  SineLUT[14]<= -11586;
  SineLUT[15]<= -6271; 
  SineLUT[16]<= -2;    

  SineLUT_d2[0] <=  0;
  SineLUT_d2[1] <=  3135; 
  SineLUT_d2[2] <=  5793; 
  SineLUT_d2[3] <=  7568; 
  SineLUT_d2[4] <=  8192; 
  SineLUT_d2[5] <=  7568; 
  SineLUT_d2[6] <=  5793;  
  SineLUT_d2[7] <=  3135; 
  SineLUT_d2[8] <=  0;     
  SineLUT_d2[9] <= -3135; 
  SineLUT_d2[10]<= -5793;  
  SineLUT_d2[11]<= -7568; 
  SineLUT_d2[12]<= -8192; 
  SineLUT_d2[13]<= -7568; 
  SineLUT_d2[14]<= -5793; 
  SineLUT_d2[15]<= -3135; 
  SineLUT_d2[16]<=  0;    
end

//----------------------------------- Sawtooth Peak-Peak Values -------------------------------
reg [39:0] SppLUT [0:15];

//Address = {CH_freq[2:0], Samples_Count[2:0]}

//[0]  =>    3 Samples => Spp = -65532/2, diff=32766 
//[1]  =>    6 Samples => Spp = -65530/2, diff=13106    
//[2]  =>   12 Samples => Spp = -65516/2, diff= 5956    
//[3]  =>   24 Samples => Spp = -65504/2, diff= 2848    
//[4]  =>   48 Samples => Spp = -65518/2, diff= 1394    
//[5]  =>   96 Samples => Spp = -65360/2, diff=  688    
//[6]  =>  192 Samples => Spp = -65322/2, diff=  342    
//[7]  =>  384 Samples => Spp = -65110/2, diff=  170    
//[8]  =>  768 Samples => Spp = -64428/2, diff=   84    
//[9]  => 1536 Samples => Spp = -64512/2, diff=   42    
always@(posedge axis_clk) begin
  SppLUT[0]  <= 'h0;
  SppLUT[1]  <= {24'h800200, 16'h7FFE};
  SppLUT[2]  <= {24'h800300, 16'h3332};
  SppLUT[3]  <= {24'h800A00, 16'h1744};
  SppLUT[4]  <= {24'h801000, 16'h0B20};
  SppLUT[5]  <= {24'h800900, 16'h0572};
  SppLUT[6]  <= {24'h805800, 16'h02B0};
  SppLUT[7]  <= {24'h806B00, 16'h0156};
  SppLUT[8]  <= {24'h80D500, 16'h00AA};
  SppLUT[9]  <= {24'h822A00, 16'h0054};
  SppLUT[10] <= {24'h820000, 16'h002A};
  SppLUT[11] <= 'h0;
  SppLUT[12] <= 'h0;
  SppLUT[13] <= 'h0;
  SppLUT[14] <= 'h0;
  SppLUT[15] <= 'h0;
end

//----------------------------------- Generate 192 sample pulse -------------------------------
//reg [8:0] pulse_cntr;
reg [9:0] pulse_cntr;

// For 192   KHz, Audio Clock = 49.152  MHz, Count = 512
// For 176.4 KHz, Audio Clock = 45.1584 MHz, Count = 512
// For 96    KHz, Audio Clock = 49.152  MHz, Count = 512
// For 88.2  KHz, Audio Clock = 45.1584 MHz, Count = 512
// For 48    KHz, Audio Clock = 49.152  MHz, Count = 512 
// For 44.1  KHz, Audio Clock = 45.1584 MHz, Count = 512 
// For 32    KHz, Audio Clock = 32.768  MHz, Count = 512 
reg       pulse;
reg       pulse_toggle;
reg       aud_config_update_toggle;

reg [2:0] aud_config_update_sync;

//The origin of the signal is from HOST i/f. Hence assumed to be stable for more than 3-5 clocks.
always@(posedge aud_clk) begin
  if(aud_reset) begin
    aud_config_update_sync <= `FLOP_DELAY 'h0;
  end else begin
    aud_config_update_sync <= `FLOP_DELAY {aud_config_update_sync[1:0], aud_config_update};
  end
end

wire aud_config_update_pedge = (aud_config_update_sync[2]==1'b0 && aud_config_update_sync[1]==1'b1);

always@(posedge aud_clk) begin
  if(aud_reset || ~aud_start) begin
    pulse_cntr               <= 'h0;
    pulse_toggle             <= 1'b0;
    aud_config_update_toggle <= 1'b0;
    pulse                    <= 1'b0; 
  end else begin
    pulse_cntr  <= pulse_cntr + 1'b1;

    pulse <= `FLOP_DELAY &pulse_cntr;

    if(pulse) begin        
      pulse_toggle  <= `FLOP_DELAY ~pulse_toggle;
    end
    
    if(aud_config_update_pedge) begin
      aud_config_update_toggle <= `FLOP_DELAY ~aud_config_update_toggle;
    end
  end
end

// Synchronizer
(* ASYNC_REG = "TRUE" *) reg [2:0] pulse_toggle_q_sync;
(* ASYNC_REG = "TRUE" *) reg [2:0] aud_config_update_q_sync;

always@(posedge axis_clk) begin
  if(~axis_resetn) begin
    pulse_toggle_q_sync <= 3'b000;
    aud_config_update_q_sync   <= 3'b000;
  end else begin
    pulse_toggle_q_sync        <= {pulse_toggle_q_sync[1:0],pulse_toggle};
    aud_config_update_q_sync   <= {aud_config_update_q_sync[1:0],aud_config_update_toggle};
  end
end

wire pulse_sync_axis = (pulse_toggle_q_sync[2] != pulse_toggle_q_sync[1]);
wire load_value      = (aud_config_update_q_sync[2] != aud_config_update_q_sync[1]);

//----------------------------------- Generate Sawtooth Pattern -------------------------------
// aud_pattern = 2'b01

reg  [15:0] pattern_frequency_ch1;
reg  [15:0] pattern_frequency_ch2;
reg  [15:0] pattern_frequency_ch3;
reg  [15:0] pattern_frequency_ch4;
reg  [15:0] pattern_frequency_ch5;
reg  [15:0] pattern_frequency_ch6;
reg  [15:0] pattern_frequency_ch7;
reg  [15:0] pattern_frequency_ch8;

wire [15:0] value_16K = 16'h3E80; //16000
wire [15:0] value_14K = 16'h396C; //14700
wire [15:0] value_10K = 16'h29AB; //10667

wire [3:0] aud_period_shift_1_ch1 = aud_period_ch1 - 3; //For 192 KHz & 176.4 KHz
wire [3:0] aud_period_shift_2_ch1 = aud_period_ch1 - 2; //For 96 KHz & 88.2 KHz
wire [3:0] aud_period_shift_3_ch1 = aud_period_ch1 - 1; //For 48 KHz & 44.1 KHz & 32 KHz

wire [3:0] aud_period_shift_1_ch2 = aud_period_ch2 - 3; //For 192 KHz & 176.4 KHz
wire [3:0] aud_period_shift_2_ch2 = aud_period_ch2 - 2; //For 96 KHz & 88.2 KHz
wire [3:0] aud_period_shift_3_ch2 = aud_period_ch2 - 1; //For 48 KHz & 44.1 KHz & 32 KHz

wire [3:0] aud_period_shift_1_ch3 = aud_period_ch3 - 3; //For 192 KHz & 176.4 KHz
wire [3:0] aud_period_shift_2_ch3 = aud_period_ch3 - 2; //For 96 KHz & 88.2 KHz
wire [3:0] aud_period_shift_3_ch3 = aud_period_ch3 - 1; //For 48 KHz & 44.1 KHz & 32 KHz

wire [3:0] aud_period_shift_1_ch4 = aud_period_ch4 - 3; //For 192 KHz & 176.4 KHz
wire [3:0] aud_period_shift_2_ch4 = aud_period_ch4 - 2; //For 96 KHz & 88.2 KHz
wire [3:0] aud_period_shift_3_ch4 = aud_period_ch4 - 1; //For 48 KHz & 44.1 KHz & 32 KHz

wire [3:0] aud_period_shift_1_ch5 = aud_period_ch5 - 3; //For 192 KHz & 176.4 KHz
wire [3:0] aud_period_shift_2_ch5 = aud_period_ch5 - 2; //For 96 KHz & 88.2 KHz
wire [3:0] aud_period_shift_3_ch5 = aud_period_ch5 - 1; //For 48 KHz & 44.1 KHz & 32 KHz

wire [3:0] aud_period_shift_1_ch6 = aud_period_ch6 - 3; //For 192 KHz & 176.4 KHz
wire [3:0] aud_period_shift_2_ch6 = aud_period_ch6 - 2; //For 96 KHz & 88.2 KHz
wire [3:0] aud_period_shift_3_ch6 = aud_period_ch6 - 1; //For 48 KHz & 44.1 KHz & 32 KHz

wire [3:0] aud_period_shift_1_ch7 = aud_period_ch7 - 3; //For 192 KHz & 176.4 KHz
wire [3:0] aud_period_shift_2_ch7 = aud_period_ch7 - 2; //For 96 KHz & 88.2 KHz
wire [3:0] aud_period_shift_3_ch7 = aud_period_ch7 - 1; //For 48 KHz & 44.1 KHz & 32 KHz

wire [3:0] aud_period_shift_1_ch8 = aud_period_ch8 - 3; //For 192 KHz & 176.4 KHz
wire [3:0] aud_period_shift_2_ch8 = aud_period_ch8 - 2; //For 96 KHz & 88.2 KHz
wire [3:0] aud_period_shift_3_ch8 = aud_period_ch8 - 1; //For 48 KHz & 44.1 KHz & 32 KHz

//see Table 3-10 in LLC
always@(*) begin: Pattern_Frequency_Ch1
  case(aud_sample_rate) 
    4'h6:    pattern_frequency_ch1 = value_16K>>aud_period_shift_1_ch1;  //192   KHz
    4'h5:    pattern_frequency_ch1 = value_14K>>aud_period_shift_1_ch1;  //176.4 KHz 
    4'h4:    pattern_frequency_ch1 = value_16K>>aud_period_shift_2_ch1;  //96    KHz 
    4'h3:    pattern_frequency_ch1 = value_14K>>aud_period_shift_2_ch1;  //88.2  KHz 
    4'h2:    pattern_frequency_ch1 = value_16K>>aud_period_shift_3_ch1;  //48    KHz 
    4'h1:    pattern_frequency_ch1 = value_14K>>aud_period_shift_3_ch1;  //44.1  KHz 
    default: pattern_frequency_ch1 = value_10K>>aud_period_shift_3_ch1;  //32    KHz 
  endcase

end

//see Table 3-10 in LLC
always@(*) begin: Pattern_Frequency_Ch2
  case(aud_sample_rate) 
    4'h6:    pattern_frequency_ch2 = value_16K>>aud_period_shift_1_ch2;  //192   KHz 
    4'h5:    pattern_frequency_ch2 = value_14K>>aud_period_shift_1_ch2;  //176.4 KHz 
    4'h4:    pattern_frequency_ch2 = value_16K>>aud_period_shift_2_ch2;  //96    KHz 
    4'h3:    pattern_frequency_ch2 = value_14K>>aud_period_shift_2_ch2;  //88.2  KHz 
    4'h2:    pattern_frequency_ch2 = value_16K>>aud_period_shift_3_ch2;  //48    KHz 
    4'h1:    pattern_frequency_ch2 = value_14K>>aud_period_shift_3_ch2;  //44.1  KHz 
    default: pattern_frequency_ch2 = value_10K>>aud_period_shift_3_ch2;  //32    KHz 
  endcase
end

//see Table 3-10 in LLC
always@(*) begin: Pattern_Frequency_Ch3
  case(aud_sample_rate) 
    4'h6:    pattern_frequency_ch3 = value_16K>>aud_period_shift_1_ch3;  //192   KHz 
    4'h5:    pattern_frequency_ch3 = value_14K>>aud_period_shift_1_ch3;  //176.4 KHz 
    4'h4:    pattern_frequency_ch3 = value_16K>>aud_period_shift_2_ch3;  //96    KHz 
    4'h3:    pattern_frequency_ch3 = value_14K>>aud_period_shift_2_ch3;  //88.2  KHz 
    4'h2:    pattern_frequency_ch3 = value_16K>>aud_period_shift_3_ch3;  //48    KHz 
    4'h1:    pattern_frequency_ch3 = value_14K>>aud_period_shift_3_ch3;  //44.1  KHz 
    default: pattern_frequency_ch3 = value_10K>>aud_period_shift_3_ch3;  //32    KHz 
  endcase
end

//see Table 3-10 in LLC
always@(*) begin: Pattern_Frequency_Ch4
  case(aud_sample_rate) 
    4'h6:    pattern_frequency_ch4 = value_16K>>aud_period_shift_1_ch4;  //192   KHz 
    4'h5:    pattern_frequency_ch4 = value_14K>>aud_period_shift_1_ch4;  //176.4 KHz 
    4'h4:    pattern_frequency_ch4 = value_16K>>aud_period_shift_2_ch4;  //96    KHz 
    4'h3:    pattern_frequency_ch4 = value_14K>>aud_period_shift_2_ch4;  //88.2  KHz 
    4'h2:    pattern_frequency_ch4 = value_16K>>aud_period_shift_3_ch4;  //48    KHz 
    4'h1:    pattern_frequency_ch4 = value_14K>>aud_period_shift_3_ch4;  //44.1  KHz 
    default: pattern_frequency_ch4 = value_10K>>aud_period_shift_3_ch4;  //32    KHz 
  endcase
end

//see Table 3-10 in LLC
always@(*) begin: Pattern_Frequency_Ch5
  case(aud_sample_rate) 
    4'h6:    pattern_frequency_ch5 = value_16K>>aud_period_shift_1_ch5;  //192   KHz 
    4'h5:    pattern_frequency_ch5 = value_14K>>aud_period_shift_1_ch5;  //176.4 KHz 
    4'h4:    pattern_frequency_ch5 = value_16K>>aud_period_shift_2_ch5;  //96    KHz 
    4'h3:    pattern_frequency_ch5 = value_14K>>aud_period_shift_2_ch5;  //88.2  KHz 
    4'h2:    pattern_frequency_ch5 = value_16K>>aud_period_shift_3_ch5;  //48    KHz 
    4'h1:    pattern_frequency_ch5 = value_14K>>aud_period_shift_3_ch5;  //44.1  KHz 
    default: pattern_frequency_ch5 = value_10K>>aud_period_shift_3_ch5;  //32    KHz 
  endcase
end

//see Table 3-10 in LLC
always@(*) begin: Pattern_Frequency_Ch6
  case(aud_sample_rate) 
    4'h6:    pattern_frequency_ch6 = value_16K>>aud_period_shift_1_ch6;  //192   KHz 
    4'h5:    pattern_frequency_ch6 = value_14K>>aud_period_shift_1_ch6;  //176.4 KHz 
    4'h4:    pattern_frequency_ch6 = value_16K>>aud_period_shift_2_ch6;  //96    KHz 
    4'h3:    pattern_frequency_ch6 = value_14K>>aud_period_shift_2_ch6;  //88.2  KHz 
    4'h2:    pattern_frequency_ch6 = value_16K>>aud_period_shift_3_ch6;  //48    KHz 
    4'h1:    pattern_frequency_ch6 = value_14K>>aud_period_shift_3_ch6;  //44.1  KHz 
    default: pattern_frequency_ch6 = value_10K>>aud_period_shift_3_ch6;  //32    KHz 
  endcase
end

//see Table 3-10 in LLC
always@(*) begin: Pattern_Frequency_Ch7
  case(aud_sample_rate) 
    4'h6:    pattern_frequency_ch7 = value_16K>>aud_period_shift_1_ch7;  //192   KHz 
    4'h5:    pattern_frequency_ch7 = value_14K>>aud_period_shift_1_ch7;  //176.4 KHz 
    4'h4:    pattern_frequency_ch7 = value_16K>>aud_period_shift_2_ch7;  //96    KHz 
    4'h3:    pattern_frequency_ch7 = value_14K>>aud_period_shift_2_ch7;  //88.2  KHz 
    4'h2:    pattern_frequency_ch7 = value_16K>>aud_period_shift_3_ch7;  //48    KHz 
    4'h1:    pattern_frequency_ch7 = value_14K>>aud_period_shift_3_ch7;  //44.1  KHz 
    default: pattern_frequency_ch7 = value_10K>>aud_period_shift_3_ch7;  //32    KHz 
  endcase
end

//see Table 3-10 in LLC
always@(*) begin: Pattern_Frequency_Ch8
  case(aud_sample_rate) 
    4'h6:    pattern_frequency_ch8 = value_16K>>aud_period_shift_1_ch8;  //192   KHz 
    4'h5:    pattern_frequency_ch8 = value_14K>>aud_period_shift_1_ch8;  //176.4 KHz 
    4'h4:    pattern_frequency_ch8 = value_16K>>aud_period_shift_2_ch8;  //96    KHz 
    4'h3:    pattern_frequency_ch8 = value_14K>>aud_period_shift_2_ch8;  //88.2  KHz 
    4'h2:    pattern_frequency_ch8 = value_16K>>aud_period_shift_3_ch8;  //48    KHz 
    4'h1:    pattern_frequency_ch8 = value_14K>>aud_period_shift_3_ch8;  //44.1  KHz 
    default: pattern_frequency_ch8 = value_10K>>aud_period_shift_3_ch8;  //32    KHz 
  endcase
end


reg [13:0] sample_cntr_ch1;
reg [13:0] sample_cntr_ch2;
reg [13:0] sample_cntr_ch3;
reg [13:0] sample_cntr_ch4;
reg [13:0] sample_cntr_ch5;
reg [13:0] sample_cntr_ch6;
reg [13:0] sample_cntr_ch7;
reg [13:0] sample_cntr_ch8;

reg        gen_sample_ch1,gen_sample_ch1_q; 
reg        gen_sample_ch2,gen_sample_ch2_q;
reg        gen_sample_ch3,gen_sample_ch3_q;
reg        gen_sample_ch4,gen_sample_ch4_q;
reg        gen_sample_ch5,gen_sample_ch5_q;
reg        gen_sample_ch6,gen_sample_ch6_q;
reg        gen_sample_ch7,gen_sample_ch7_q;
reg       gen_sample_ch8,gen_sample_ch8_q;

reg [3:0] pulse_sync_axis_q;

always@(posedge axis_clk) begin
  if(~axis_resetn || ~aud_start_axis) begin
    sample_cntr_ch1 <= `FLOP_DELAY 'h0;
    sample_cntr_ch2 <= `FLOP_DELAY 'h0;
    sample_cntr_ch3 <= `FLOP_DELAY 'h0;
    sample_cntr_ch4 <= `FLOP_DELAY 'h0;
    sample_cntr_ch5 <= `FLOP_DELAY 'h0;
    sample_cntr_ch6 <= `FLOP_DELAY 'h0;
    sample_cntr_ch7 <= `FLOP_DELAY 'h0;
    sample_cntr_ch8 <= `FLOP_DELAY 'h0;

    gen_sample_ch1  <= `FLOP_DELAY 1'b0;
    gen_sample_ch2  <= `FLOP_DELAY 1'b0;
    gen_sample_ch3  <= `FLOP_DELAY 1'b0;
    gen_sample_ch4  <= `FLOP_DELAY 1'b0;
    gen_sample_ch5  <= `FLOP_DELAY 1'b0;
    gen_sample_ch6  <= `FLOP_DELAY 1'b0;
    gen_sample_ch7  <= `FLOP_DELAY 1'b0;
    gen_sample_ch8  <= `FLOP_DELAY 1'b0;
    
    gen_sample_ch1_q <= `FLOP_DELAY 1'b0; 
    gen_sample_ch2_q <= `FLOP_DELAY 1'b0;
    gen_sample_ch3_q <= `FLOP_DELAY 1'b0;
    gen_sample_ch4_q <= `FLOP_DELAY 1'b0;
    gen_sample_ch5_q <= `FLOP_DELAY 1'b0;
    gen_sample_ch6_q <= `FLOP_DELAY 1'b0;
    gen_sample_ch7_q <= `FLOP_DELAY 1'b0;
    gen_sample_ch8_q <= `FLOP_DELAY 1'b0;

    pulse_sync_axis_q <= `FLOP_DELAY 'h0;
  end else begin

    pulse_sync_axis_q <= `FLOP_DELAY {pulse_sync_axis, pulse_sync_axis_q[3:1]};

  //   if(pulse_sync_axis) begin

 //     if(sample_cntr_ch1==pattern_frequency_ch1) begin
 //       sample_cntr_ch1 <= `FLOP_DELAY 'h0; 
 //       gen_sample_ch1  <= `FLOP_DELAY 1'b1;
 //     end else begin
 //       sample_cntr_ch1 <= `FLOP_DELAY sample_cntr_ch1 + 1'b1;
 //       gen_sample_ch1  <= `FLOP_DELAY 1'b0;
 //     end

 //     if(sample_cntr_ch2==pattern_frequency_ch2) begin
 //       sample_cntr_ch2 <= `FLOP_DELAY 'h0;
 //       gen_sample_ch2  <= `FLOP_DELAY 1'b1;
 //     end else begin
 //       sample_cntr_ch2 <= `FLOP_DELAY sample_cntr_ch2 + 1'b1;
 //       gen_sample_ch2  <= `FLOP_DELAY 1'b0;
 //     end

 //     if(sample_cntr_ch3==pattern_frequency_ch3) begin
 //       sample_cntr_ch3 <= `FLOP_DELAY 'h0;
 //       gen_sample_ch3  <= `FLOP_DELAY 1'b1;
 //     end else begin
 //       sample_cntr_ch3 <= `FLOP_DELAY sample_cntr_ch3 + 1'b1;
 //       gen_sample_ch3  <= `FLOP_DELAY 1'b0;
 //     end

 //     if(sample_cntr_ch4==pattern_frequency_ch4) begin
 //       sample_cntr_ch4 <= `FLOP_DELAY 'h0;
 //       gen_sample_ch4  <= `FLOP_DELAY 1'b1;
 //     end else begin
 //       sample_cntr_ch4 <= `FLOP_DELAY sample_cntr_ch4 + 1'b1;
 //       gen_sample_ch4  <= `FLOP_DELAY 1'b0;
 //     end

 //     if(sample_cntr_ch5==pattern_frequency_ch5) begin
 //       sample_cntr_ch5 <= `FLOP_DELAY 'h0;
 //       gen_sample_ch5  <= `FLOP_DELAY 1'b1;
 //     end else begin
 //       sample_cntr_ch5 <= `FLOP_DELAY sample_cntr_ch5 + 1'b1;
 //       gen_sample_ch5  <= `FLOP_DELAY 1'b0;
 //     end

 //     if(sample_cntr_ch6==pattern_frequency_ch6) begin
 //       sample_cntr_ch6 <= `FLOP_DELAY 'h0;
 //       gen_sample_ch6  <= `FLOP_DELAY 1'b1;
 //     end else begin
 //       sample_cntr_ch6 <= `FLOP_DELAY sample_cntr_ch6 + 1'b1;
 //       gen_sample_ch6  <= `FLOP_DELAY 1'b0;
 //     end

 //     if(sample_cntr_ch7==pattern_frequency_ch7) begin
 //       sample_cntr_ch7 <= `FLOP_DELAY 'h0;
 //       gen_sample_ch7  <= `FLOP_DELAY 1'b1;
 //     end else begin
 //       sample_cntr_ch7 <= `FLOP_DELAY sample_cntr_ch7 + 1'b1;
 //       gen_sample_ch7  <= `FLOP_DELAY 1'b0;
 //     end

 //     if(sample_cntr_ch8==pattern_frequency_ch8) begin
 //       sample_cntr_ch8 <= `FLOP_DELAY 'h0;
 //       gen_sample_ch8  <= `FLOP_DELAY 1'b1;
 //     end else begin
 //       sample_cntr_ch8 <= `FLOP_DELAY sample_cntr_ch8 + 1'b1;
 //       gen_sample_ch8  <= `FLOP_DELAY 1'b0;
 //     end

   //  end else begin
 //       gen_sample_ch1  <= `FLOP_DELAY 1'b0;
 //       gen_sample_ch2  <= `FLOP_DELAY 1'b0;
 //       gen_sample_ch3  <= `FLOP_DELAY 1'b0;
 //       gen_sample_ch4  <= `FLOP_DELAY 1'b0;
 //       gen_sample_ch5  <= `FLOP_DELAY 1'b0;
 //       gen_sample_ch6  <= `FLOP_DELAY 1'b0;
 //       gen_sample_ch7  <= `FLOP_DELAY 1'b0;
 //       gen_sample_ch8  <= `FLOP_DELAY 1'b0;

   //  end //pulse_sync_axis

  end //axis_resetn
end

// Sawtooth peak-peak pulse
// [23:0] = {16 bit sample , 8'h00}
wire [39:0] Spp_diff_Ch1 = SppLUT[aud_period_ch1]; 
wire [39:0] Spp_diff_Ch2 = SppLUT[aud_period_ch2]; 
wire [39:0] Spp_diff_Ch3 = SppLUT[aud_period_ch3]; 
wire [39:0] Spp_diff_Ch4 = SppLUT[aud_period_ch4]; 
wire [39:0] Spp_diff_Ch5 = SppLUT[aud_period_ch5]; 
wire [39:0] Spp_diff_Ch6 = SppLUT[aud_period_ch6]; 
wire [39:0] Spp_diff_Ch7 = SppLUT[aud_period_ch7]; 
wire [39:0] Spp_diff_Ch8 = SppLUT[aud_period_ch8]; 

wire [23:0] Spp_Value_Ch1 = Spp_diff_Ch1[39:16]; wire [15:0] Diff_Ch1 = Spp_diff_Ch1[15:0];
wire [23:0] Spp_Value_Ch2 = Spp_diff_Ch2[39:16]; wire [15:0] Diff_Ch2 = Spp_diff_Ch2[15:0];
wire [23:0] Spp_Value_Ch3 = Spp_diff_Ch3[39:16]; wire [15:0] Diff_Ch3 = Spp_diff_Ch3[15:0];
wire [23:0] Spp_Value_Ch4 = Spp_diff_Ch4[39:16]; wire [15:0] Diff_Ch4 = Spp_diff_Ch4[15:0];
wire [23:0] Spp_Value_Ch5 = Spp_diff_Ch5[39:16]; wire [15:0] Diff_Ch5 = Spp_diff_Ch5[15:0];
wire [23:0] Spp_Value_Ch6 = Spp_diff_Ch6[39:16]; wire [15:0] Diff_Ch6 = Spp_diff_Ch6[15:0];
wire [23:0] Spp_Value_Ch7 = Spp_diff_Ch7[39:16]; wire [15:0] Diff_Ch7 = Spp_diff_Ch7[15:0];
wire [23:0] Spp_Value_Ch8 = Spp_diff_Ch8[39:16]; wire [15:0] Diff_Ch8 = Spp_diff_Ch8[15:0];

reg [23:0] sine_sample_ch;
reg [23:0] sine_tone;

reg [23:0] audio_sample_ch1;
reg [23:0] audio_sample_ch2;
reg [23:0] audio_sample_ch3;
reg [23:0] audio_sample_ch4;
reg [23:0] audio_sample_ch5;
reg [23:0] audio_sample_ch6;
reg [23:0] audio_sample_ch7;
reg [23:0] audio_sample_ch8;

reg [11:0] addr_cntr_ch1;
reg [11:0] addr_cntr_ch2;

reg [23:0] cntr_250ms_ch1;
reg [23:0] cntr_250ms_ch2;
reg [8:0] ping_pattern_ch1;
reg [8:0] ping_pattern_ch2;

reg       toggle_pat_read; 

always@(posedge axis_clk) begin
  if(~axis_resetn || ~aud_start_axis) begin
    audio_sample_ch1 <= `FLOP_DELAY 'h0; 
    audio_sample_ch2 <= `FLOP_DELAY 'h0; 
    audio_sample_ch3 <= `FLOP_DELAY 'h0; 
    audio_sample_ch4 <= `FLOP_DELAY 'h0; 
    audio_sample_ch5 <= `FLOP_DELAY 'h0; 
    audio_sample_ch6 <= `FLOP_DELAY 'h0; 
    audio_sample_ch7 <= `FLOP_DELAY 'h0; 
    audio_sample_ch8 <= `FLOP_DELAY 'h0;
    addr_cntr_ch1 <= `FLOP_DELAY 'h0; 
    addr_cntr_ch2 <= `FLOP_DELAY 'h0; 
    cntr_250ms_ch1<= `FLOP_DELAY 'h0;
    cntr_250ms_ch2<= `FLOP_DELAY 'h0;
    sine_sample_ch <= `FLOP_DELAY 'h0;
    sine_tone      <= `FLOP_DELAY 'h0;
    ping_pattern_ch1 <= `FLOP_DELAY 9'b1010_1010_1;
    ping_pattern_ch2 <= `FLOP_DELAY 9'b1010_1010_1;
    toggle_pat_read <= `FLOP_DELAY 1'b1;
  end else if(load_value) begin 
    audio_sample_ch1 <= `FLOP_DELAY Spp_Value_Ch1; 
    audio_sample_ch2 <= `FLOP_DELAY Spp_Value_Ch2; 
    audio_sample_ch3 <= `FLOP_DELAY Spp_Value_Ch3; 
    audio_sample_ch4 <= `FLOP_DELAY Spp_Value_Ch4; 
    audio_sample_ch5 <= `FLOP_DELAY Spp_Value_Ch5; 
    audio_sample_ch6 <= `FLOP_DELAY Spp_Value_Ch6; 
    audio_sample_ch7 <= `FLOP_DELAY Spp_Value_Ch7; 
    audio_sample_ch8 <= `FLOP_DELAY Spp_Value_Ch8; 
    addr_cntr_ch1 <= `FLOP_DELAY 'h0; 
    addr_cntr_ch2 <= `FLOP_DELAY 'h0; 
    cntr_250ms_ch1<= `FLOP_DELAY 'h0;
    cntr_250ms_ch2<= `FLOP_DELAY 'h0;
    ping_pattern_ch1 <= `FLOP_DELAY 9'b1010_1010_1;
    ping_pattern_ch2 <= `FLOP_DELAY 9'b1010_1010_1;
    toggle_pat_read <= `FLOP_DELAY 1'b1;
  end else begin
 
   //Ping Test Pattern
    if(pulse_sync_axis) begin
          addr_cntr_ch1 <= `FLOP_DELAY (addr_cntr_ch1==15) ?'h0 : addr_cntr_ch1 + 1'b1;
          sine_sample_ch[23:8] <= `FLOP_DELAY (ping_pattern_ch1[0])?SineLUT[addr_cntr_ch1]:'h00;
          sine_sample_ch[7:0]  <= `FLOP_DELAY 8'h00;
          sine_tone[23:8]  <= `FLOP_DELAY SineLUT[addr_cntr_ch1];
          sine_tone[7:0]   <= `FLOP_DELAY 8'h00;
          cntr_250ms_ch1       <= `FLOP_DELAY cntr_250ms_ch1 + 1'b1;
          //~250ms: shift the pattern. Insert silence when ping_pattern_chx[8]=0
          if(cntr_250ms_ch1==offset_addr_cntr)  begin
            cntr_250ms_ch1   <= `FLOP_DELAY 'h0;
            ping_pattern_ch1 <= `FLOP_DELAY {ping_pattern_ch1[0], ping_pattern_ch1[7:1]};
          end
//          audio_sample_ch1 <= `FLOP_DELAY sine_sample_ch;
    end
//    if(pulse_sync_axis) begin
//          audio_sample_ch2 <= `FLOP_DELAY sine_sample_ch;
//    end

    // Audio channel 1
    if (pulse_sync_axis) begin
      case (aud_pattern1)
        2'b00:                      // Silence
          audio_sample_ch1 <= `FLOP_DELAY sine_tone;//24'b0;
        2'b10:                      // Ping pattern
          audio_sample_ch1 <= `FLOP_DELAY sine_sample_ch;
        2'b11 : 
          audio_sample_ch1 <= `FLOP_DELAY audio_sample_ch1 + 1'b1;
        default:                    // Invalid setting
          audio_sample_ch1 <= `FLOP_DELAY 24'b0;
      endcase // case (aud_pattern1)
    end // if (pulse_sync_axis)
    
    
    // Audio channel 2
    if (pulse_sync_axis) begin
      case (aud_pattern2)
        2'b00:                      // Silence
          audio_sample_ch2 <= `FLOP_DELAY sine_tone;//24'b0;
        2'b10:                      // Ping pattern
          audio_sample_ch2 <= `FLOP_DELAY sine_sample_ch;
        2'b11 : 
          audio_sample_ch2 <= `FLOP_DELAY audio_sample_ch2 + 1'b1;
        default:                    // Invalid setting
          audio_sample_ch2 <= `FLOP_DELAY 24'b0;
      endcase // case (aud_pattern2)
    end // if (pulse_sync_axis)
    
    // Audio channel 3
    if (pulse_sync_axis) begin
      case (aud_pattern3)
        2'b00:                      // Silence
          audio_sample_ch3 <= `FLOP_DELAY 24'b0;
        2'b10:                      // Ping pattern
          audio_sample_ch3 <= `FLOP_DELAY sine_sample_ch;
        2'b11 : 
          audio_sample_ch3 <= `FLOP_DELAY audio_sample_ch3 + 1'b1;
        default:                    // Invalid setting
          audio_sample_ch3 <= `FLOP_DELAY 24'b0;
      endcase // case (aud_pattern3)
    end // if (pulse_sync_axis)
    
    // Audio channel 4
    if (pulse_sync_axis) begin
      case (aud_pattern4)
        2'b00:                      // Silence
          audio_sample_ch4 <= `FLOP_DELAY 24'b0;
        2'b10:                      // Ping pattern
          audio_sample_ch4 <= `FLOP_DELAY sine_sample_ch;
        2'b11 : 
          audio_sample_ch4 <= `FLOP_DELAY audio_sample_ch4 + 1'b1;
        default:                    // Invalid setting
          audio_sample_ch4 <= `FLOP_DELAY 24'b0;
      endcase // case (aud_pattern4)
    end // if (pulse_sync_axis)
    
    // Audio channel 5
    if (pulse_sync_axis) begin
      case (aud_pattern5)
        2'b00:                      // Silence
          audio_sample_ch5 <= `FLOP_DELAY 24'b0;
        2'b10:                      // Ping pattern
          audio_sample_ch5 <= `FLOP_DELAY sine_sample_ch;
        2'b11 : 
          audio_sample_ch5 <= `FLOP_DELAY audio_sample_ch5 + 1'b1;
        default:                    // Invalid setting
          audio_sample_ch5 <= `FLOP_DELAY 24'b0;
      endcase // case (aud_pattern5)
    end // if (pulse_sync_axis)
    
    // Audio channel 6
    if (pulse_sync_axis) begin
      case (aud_pattern6)
        2'b00:                      // Silence
          audio_sample_ch6 <= `FLOP_DELAY 24'b0;
        2'b10:                      // Ping pattern
          audio_sample_ch6 <= `FLOP_DELAY sine_sample_ch;
        2'b11 : 
          audio_sample_ch6 <= `FLOP_DELAY audio_sample_ch6 + 1'b1;
        default:                    // Invalid setting
          audio_sample_ch6 <= `FLOP_DELAY 24'b0;
      endcase // case (aud_pattern6)
    end // if (pulse_sync_axis)
    
    // Audio channel 7
    if (pulse_sync_axis) begin
      case (aud_pattern7)
        2'b00:                      // Silence
          audio_sample_ch7 <= `FLOP_DELAY 24'b0;
        2'b10:                      // Ping pattern
          audio_sample_ch7 <= `FLOP_DELAY sine_sample_ch;
        2'b11 : 
          audio_sample_ch7 <= `FLOP_DELAY audio_sample_ch7 + 1'b1;
        default:                    // Invalid setting
          audio_sample_ch7 <= `FLOP_DELAY 24'b0;
      endcase // case (aud_pattern7)
    end // if (pulse_sync_axis)
    
    // Audio channel 8
    if (pulse_sync_axis) begin
      case (aud_pattern8)
        2'b00:                      // Silence
          audio_sample_ch8 <= `FLOP_DELAY 24'b0;
        2'b10:                      // Ping pattern
          audio_sample_ch8 <= `FLOP_DELAY sine_sample_ch;
        2'b11 : 
          audio_sample_ch8 <= `FLOP_DELAY audio_sample_ch8 + 1'b1;
        default:                    // Invalid setting
          audio_sample_ch8 <= `FLOP_DELAY 24'b0;
      endcase // case (aud_pattern8)
    end // if (pulse_sync_axis)
    

//    if(pulse_sync_axis) begin
//      case(aud_pattern1)
//        2'b00: begin//Silence                             
//          audio_sample_ch1 <= `FLOP_DELAY 'h0;
//        end 
//
//        2'b01: begin //sawtooth
//          if(gen_sample_ch1) begin
//            if(audio_sample_ch1[23:8] == -Diff_Ch1) begin
//              audio_sample_ch1[23:8] <= `FLOP_DELAY Diff_Ch1;
//              audio_sample_ch1[7:0]  <= `FLOP_DELAY 'h00;
//            end else if(audio_sample_ch1[23:8] == -Spp_Value_Ch1[23:8]) begin
//              audio_sample_ch1[23:8] <= `FLOP_DELAY Spp_Value_Ch1[23:8];
//              audio_sample_ch1[7:0]  <= `FLOP_DELAY 'h00;
//            end else begin
//              audio_sample_ch1[23:8] <= audio_sample_ch1[23:8] + Diff_Ch1;
//            end
//          end
//        end
//
//        2'b10: begin //Sine
//          audio_sample_ch1 <= `FLOP_DELAY sine_sample_ch;
//        end 
//
//        2'b11: begin //Incrementing Pattern
//          audio_sample_ch1 <= `FLOP_DELAY audio_sample_ch1 + 'h1;
//        end
//
//        default: begin
//        end
//      endcase 
//    end
//
//    if(pulse_sync_axis) begin
//      case(aud_pattern2)
//        2'b00: begin//Silence                             
//          audio_sample_ch2 <= `FLOP_DELAY 'h0;
//        end 
//
//        2'b01: begin
//          if(gen_sample_ch2) begin
//            if(audio_sample_ch2[23:8] == -Diff_Ch2) begin
//              audio_sample_ch2[23:8] <= `FLOP_DELAY Diff_Ch2;
//              audio_sample_ch2[7:0]  <= `FLOP_DELAY 'h00;
//            end else if(audio_sample_ch2[23:8] == -Spp_Value_Ch2[23:8]) begin
//              audio_sample_ch2[23:8] <= `FLOP_DELAY Spp_Value_Ch2[23:8];
//              audio_sample_ch2[7:0]  <= `FLOP_DELAY 'h00;
//            end else begin
//              audio_sample_ch2[23:8] <= audio_sample_ch2[23:8] + Diff_Ch2;
//            end
//          end
//        end
//
//        2'b10: begin //Sine
//          audio_sample_ch2 <= `FLOP_DELAY sine_sample_ch;
//        end 
//
//        2'b11: begin //Incrementing Pattern
//          audio_sample_ch2 <= `FLOP_DELAY audio_sample_ch2 + 'h1;
//        end
//
//        default: begin
//        end
//      endcase 
//    end
//
//    if(pulse_sync_axis) begin
//      case(aud_pattern3)
//        2'b00: begin//Silence                             
//          audio_sample_ch3 <= `FLOP_DELAY 'h0;
//        end 
//
//        2'b01: begin
//          if(gen_sample_ch3) begin
//            if(audio_sample_ch3[23:8] == -Diff_Ch3) begin
//              audio_sample_ch3[23:8] <= `FLOP_DELAY Diff_Ch3;
//              audio_sample_ch3[7:0]  <= `FLOP_DELAY 'h00;
//            end else if(audio_sample_ch3[23:8] == -Spp_Value_Ch3[23:8]) begin
//              audio_sample_ch3[23:8] <= `FLOP_DELAY Spp_Value_Ch3[23:8];
//              audio_sample_ch3[7:0]  <= `FLOP_DELAY 'h00;
//            end else begin
//              audio_sample_ch3[23:8] <= audio_sample_ch3[23:8] + Diff_Ch3;
//            end
//          end
//        end
//
//        2'b10: begin 
//          audio_sample_ch3 <= `FLOP_DELAY sine_sample_ch;
//        end 
//
//        2'b11: begin //Incrementing Pattern
//          audio_sample_ch3 <= `FLOP_DELAY audio_sample_ch3 + 'h1;
//        end
//
//        default: begin
//        end
//      endcase 
//    end
//
//    if(pulse_sync_axis) begin
//      case(aud_pattern4)
//        2'b00: begin//Silence                             
//          audio_sample_ch4 <= `FLOP_DELAY 'h0;
//        end 
//
//        2'b01: begin
//          if(gen_sample_ch4) begin
//            if(audio_sample_ch4[23:8] == -Diff_Ch4) begin
//              audio_sample_ch4[23:8] <= `FLOP_DELAY Diff_Ch4;
//              audio_sample_ch4[7:0]  <= `FLOP_DELAY 'h00;
//            end else if(audio_sample_ch4[23:8] == -Spp_Value_Ch4[23:8]) begin
//              audio_sample_ch4[23:8] <= `FLOP_DELAY Spp_Value_Ch4[23:8];
//              audio_sample_ch4[7:0]  <= `FLOP_DELAY 'h00;
//            end else begin
//              audio_sample_ch4[23:8] <= audio_sample_ch4[23:8] + Diff_Ch4;
//            end
//          end
//        end
//
//
//        2'b10: begin //Sine wave only in 1 & 2 channels, Silence in other channels
//          audio_sample_ch4 <= `FLOP_DELAY sine_sample_ch;
//        end 
//
//        2'b11: begin //Incrementing Pattern
//          audio_sample_ch4 <= `FLOP_DELAY audio_sample_ch4 + 'h1;
//        end
//
//        default: begin
//        end
//      endcase 
//
//    end
//
//    if(pulse_sync_axis) begin
//      case(aud_pattern5)
//        2'b00: begin//Silence                             
//          audio_sample_ch5 <= `FLOP_DELAY 'h0;
//        end 
//
//        2'b01: begin
//          if(gen_sample_ch5) begin
//            if(audio_sample_ch5[23:8] == -Diff_Ch5) begin
//              audio_sample_ch5[23:8] <= `FLOP_DELAY Diff_Ch5;
//              audio_sample_ch5[7:0]  <= `FLOP_DELAY 'h00;
//            end else if(audio_sample_ch5[23:8] == -Spp_Value_Ch5[23:8]) begin
//              audio_sample_ch5[23:8] <= `FLOP_DELAY Spp_Value_Ch5[23:8];
//              audio_sample_ch5[7:0]  <= `FLOP_DELAY 'h00;
//            end else begin
//              audio_sample_ch5[23:8] <= audio_sample_ch5[23:8] + Diff_Ch5;
//            end
//          end
//        end
//
//
//        2'b10: begin //Sine wave only in 1 & 2 channels, Silence in other channels
//          audio_sample_ch5 <= `FLOP_DELAY sine_sample_ch;
//        end 
//
//        2'b11: begin //Incrementing Pattern
//          audio_sample_ch5 <= `FLOP_DELAY audio_sample_ch5 + 'h1;
//        end
//
//        default: begin
//        end
//      endcase 
//    end
//
//    if(pulse_sync_axis) begin
//      case(aud_pattern6)
//        2'b00: begin//Silence                             
//          audio_sample_ch6 <= `FLOP_DELAY 'h0;
//        end 
//
//        2'b01: begin
//          if(gen_sample_ch6) begin
//            if(audio_sample_ch6[23:8] == -Diff_Ch6) begin
//              audio_sample_ch6[23:8] <= `FLOP_DELAY Diff_Ch6;
//              audio_sample_ch6[7:0]  <= `FLOP_DELAY 'h00;
//            end else if(audio_sample_ch6[23:8] == -Spp_Value_Ch6[23:8]) begin
//              audio_sample_ch6[23:8] <= `FLOP_DELAY Spp_Value_Ch6[23:8];
//              audio_sample_ch6[7:0]  <= `FLOP_DELAY 'h00;
//            end else begin
//              audio_sample_ch6[23:8] <= audio_sample_ch6[23:8] + Diff_Ch6;
//            end
//          end
//        end
//
//
//        2'b10: begin //Sine wave only in 1 & 2 channels, Silence in other channels
//          audio_sample_ch6 <= `FLOP_DELAY sine_sample_ch;
//        end 
//
//        2'b11: begin //Incrementing Pattern
//          audio_sample_ch6 <= `FLOP_DELAY audio_sample_ch6 + 'h1;
//        end
//
//        default: begin
//        end
//      endcase 
//    end
//
//    if(pulse_sync_axis) begin
//      case(aud_pattern7)
//        2'b00: begin//Silence                             
//          audio_sample_ch7 <= `FLOP_DELAY 'h0;
//        end 
//
//        2'b01: begin
//          if(gen_sample_ch7) begin
//            if(audio_sample_ch7[23:8] == -Diff_Ch7) begin
//              audio_sample_ch7[23:8] <= `FLOP_DELAY Diff_Ch7;
//              audio_sample_ch7[7:0]  <= `FLOP_DELAY 'h00;
//            end else if(audio_sample_ch7[23:8] == -Spp_Value_Ch7[23:8]) begin
//              audio_sample_ch7[23:8] <= `FLOP_DELAY Spp_Value_Ch7[23:8];
//              audio_sample_ch7[7:0]  <= `FLOP_DELAY 'h00;
//            end else begin
//              audio_sample_ch7[23:8] <= audio_sample_ch7[23:8] + Diff_Ch7;
//            end
//          end
//        end
//
//        2'b10: begin //Sine wave only in 1 & 2 channels, Silence in other channels
//          audio_sample_ch7 <= `FLOP_DELAY sine_sample_ch;
//        end 
//
//        2'b11: begin //Incrementing Pattern
//          audio_sample_ch7 <= `FLOP_DELAY audio_sample_ch7 + 'h1;
//        end
//
//        default: begin
//        end
//      endcase 
//    end
//
//    if(pulse_sync_axis) begin
//      case(aud_pattern8)
//        2'b00: begin//Silence                             
//          audio_sample_ch8 <= `FLOP_DELAY 'h0;
//        end 
//
//        2'b01: begin
//          if(gen_sample_ch8) begin
//            if(audio_sample_ch8[23:8] == -Diff_Ch8) begin
//              audio_sample_ch8[23:8] <= `FLOP_DELAY Diff_Ch8;
//              audio_sample_ch8[7:0]  <= `FLOP_DELAY 'h00;
//            end else if(audio_sample_ch8[23:8] == -Spp_Value_Ch8[23:8]) begin
//              audio_sample_ch8[23:8] <= `FLOP_DELAY Spp_Value_Ch8[23:8];
//              audio_sample_ch8[7:0]  <= `FLOP_DELAY 'h00;
//            end else begin
//              audio_sample_ch8[23:8] <= audio_sample_ch8[23:8] + Diff_Ch8;
//            end
//          end
//        end
//
//        2'b10: begin //Sine wave only in 1 & 2 channels, Silence in other channels
//          audio_sample_ch8 <= `FLOP_DELAY sine_sample_ch;
//        end 
//
//        2'b11: begin //Incrementing Pattern
//          audio_sample_ch8 <= `FLOP_DELAY audio_sample_ch8 + 'h1;
//        end
//
//        default: begin
//        end
//      endcase 
//    end

  end
end


//------------------------------------------ Sample Holding Buffers -------------------------------------
reg [31:0] ch1_sample_queue [0:7];
reg [31:0] ch2_sample_queue [0:7];
reg [31:0] ch3_sample_queue [0:7];
reg [31:0] ch4_sample_queue [0:7];
reg [31:0] ch5_sample_queue [0:7];
reg [31:0] ch6_sample_queue [0:7];
reg [31:0] ch7_sample_queue [0:7];
reg [31:0] ch8_sample_queue [0:7];

reg [2:0] ch1_wr_index;
reg [2:0] ch2_wr_index;
reg [2:0] ch3_wr_index;
reg [2:0] ch4_wr_index;
reg [2:0] ch5_wr_index;
reg [2:0] ch6_wr_index;
reg [2:0] ch7_wr_index;
reg [2:0] ch8_wr_index;

reg [2:0] ch_rd_index;
reg [2:0] ch_rd_index_d;

reg [31:0] ch1_rd_data;
reg [31:0] ch2_rd_data;
reg [31:0] ch3_rd_data;
reg [31:0] ch4_rd_data;
reg [31:0] ch5_rd_data;
reg [31:0] ch6_rd_data;
reg [31:0] ch7_rd_data;
reg [31:0] ch8_rd_data;

reg [8:0] axis_ch_handshake;
reg       i_axis_tvalid_q;

// Samples data @ every audio sample rate
// generate SPDIF - preamble and other control bits here

reg [191:0] aud_blk_seq;
reg         gen_subframe_preamble;
reg        validity;
reg        userdata;
reg [191:0]channel_status;
wire       parity_sample1 = (^audio_sample_ch1)^validity^userdata^channel_status[191]; 
wire       parity_sample2 = (^audio_sample_ch2)^validity^userdata^channel_status[191]; 
wire       parity_sample3 = (^audio_sample_ch3)^validity^userdata^channel_status[191]; 
wire       parity_sample4 = (^audio_sample_ch4)^validity^userdata^channel_status[191]; 
wire       parity_sample5 = (^audio_sample_ch5)^validity^userdata^channel_status[191]; 
wire       parity_sample6 = (^audio_sample_ch6)^validity^userdata^channel_status[191]; 
wire       parity_sample7 = (^audio_sample_ch7)^validity^userdata^channel_status[191]; 
wire       parity_sample8 = (^audio_sample_ch8)^validity^userdata^channel_status[191]; 
wire [3:0] preamble_frame    = ((aud_blk_count==0) & ~gen_subframe_preamble) ?4'b0000 : 4'b0001;
wire [3:0] preamble_subframe = 4'b0010;
                                       
reg  [2:0]  i_axis_id_egress_q;

reg  [8:1] ch_en;

always@(posedge axis_clk) begin
  if (~axis_resetn)
    begin
      ch_en = 8'b0;
    end
  else
    begin
      if (load_value)
        begin
          if (aud_channel_count >= 1)
            ch_en[1] <= `FLOP_DELAY 1'b1;
          else
            ch_en[1] <= `FLOP_DELAY 1'b0;
          
          if (aud_channel_count >= 2)
            ch_en[2] <= `FLOP_DELAY 1'b1;
          else
            ch_en[2] <= `FLOP_DELAY 1'b0;
          
          if (aud_channel_count >= 3)
            ch_en[3] <= `FLOP_DELAY 1'b1;
          else
            ch_en[3] <= `FLOP_DELAY 1'b0;
          
          if (aud_channel_count >= 4)
            ch_en[4] <= `FLOP_DELAY 1'b1;
          else
            ch_en[4] <= `FLOP_DELAY 1'b0;
          
          if (aud_channel_count >= 5)
            ch_en[5] <= `FLOP_DELAY 1'b1;
          else
            ch_en[5] <= `FLOP_DELAY 1'b0;
          
          if (aud_channel_count >= 6)
            ch_en[6] <= `FLOP_DELAY 1'b1;
          else
            ch_en[6] <= `FLOP_DELAY 1'b0;
          
          if (aud_channel_count >= 7)
            ch_en[7] <= `FLOP_DELAY 1'b1;
          else
            ch_en[7] <= `FLOP_DELAY 1'b0;
          
          if (aud_channel_count >= 8)
            ch_en[8] <= `FLOP_DELAY 1'b1;
          else
            ch_en[8] <= `FLOP_DELAY 1'b0;
        end
    end
end
  

always@(posedge axis_clk) begin
  if(~axis_resetn || ~aud_start_axis) begin
    ch1_wr_index <= `FLOP_DELAY 'h0;
    ch2_wr_index <= `FLOP_DELAY 'h0;
    ch3_wr_index <= `FLOP_DELAY 'h0;
    ch4_wr_index <= `FLOP_DELAY 'h0;
    ch5_wr_index <= `FLOP_DELAY 'h0;
    ch6_wr_index <= `FLOP_DELAY 'h0;
    ch7_wr_index <= `FLOP_DELAY 'h0;
    ch8_wr_index <= `FLOP_DELAY 'h0;

    ch_rd_index  <= `FLOP_DELAY 'h0;

 //   i_axis_tvalid_q <= `FLOP_DELAY 1'b0;

    axis_ch_handshake <= `FLOP_DELAY 9'b0_1111_1111;
    i_axis_id_egress_q <= `FLOP_DELAY 'h0;
    axis_data_egress <= `FLOP_DELAY 'h0;

    aud_blk_seq <= `FLOP_DELAY 'h1;
    aud_blk_count <= `FLOP_DELAY 8'b0; // counts from 0 to 191 on tvalid =1
    gen_subframe_preamble <= `FLOP_DELAY 1'b0;

    // Change these to required vector later...192 bit
    validity <= `FLOP_DELAY 1'b0; //0: Use the sample, 1: Discard the sample
    userdata <= `FLOP_DELAY 1'b0;
    channel_status <= `FLOP_DELAY 192'h0;  

  end else begin

    // Load when a new value is programmed or
    // when start of new audio block
    if(load_value || (aud_blk_seq[0] & pulse_sync_axis_q[3]) ) begin
      channel_status[191:150] <= `FLOP_DELAY aud_spdif_channel_status;
      channel_status[149:  0] <= `FLOP_DELAY 'h0;           
      //$display("Audio Block Generated...");          
    //end else if(pulse_sync_axis_q[2] && gen_subframe_preamble) begin
    end else if(pulse_sync_axis_q[2]) begin
      channel_status <= `FLOP_DELAY {channel_status[190:0],channel_status[191]};
    end

    if(pulse_sync_axis_q[2]) begin
      ch1_wr_index <= `FLOP_DELAY ch1_wr_index + 1'b1;
      ch2_wr_index <= `FLOP_DELAY ch2_wr_index + 1'b1;
      ch3_wr_index <= `FLOP_DELAY ch3_wr_index + 1'b1;
      ch4_wr_index <= `FLOP_DELAY ch4_wr_index + 1'b1;
      ch5_wr_index <= `FLOP_DELAY ch5_wr_index + 1'b1;
      ch6_wr_index <= `FLOP_DELAY ch6_wr_index + 1'b1;
      ch7_wr_index <= `FLOP_DELAY ch7_wr_index + 1'b1;
      ch8_wr_index <= `FLOP_DELAY ch8_wr_index + 1'b1;

      gen_subframe_preamble <= `FLOP_DELAY ~gen_subframe_preamble;

      //if(gen_subframe_preamble)
      aud_blk_seq <= `FLOP_DELAY {aud_blk_seq[0],aud_blk_seq[191:1]};
      if(aud_blk_count == 8'd191)
         aud_blk_count <= `FLOP_DELAY 8'b0; // counts from 0 to 191 on tvalid =1
      else
         aud_blk_count <= `FLOP_DELAY aud_blk_count +1; // counts from 0 to 191 on tvalid =1

      ch1_sample_queue[ch1_wr_index] <= `FLOP_DELAY {parity_sample1,channel_status[191],userdata,validity,audio_sample_ch1,preamble_frame};
      ch2_sample_queue[ch2_wr_index] <= `FLOP_DELAY {parity_sample2,channel_status[191],userdata,validity,audio_sample_ch2,preamble_subframe};
      ch3_sample_queue[ch3_wr_index] <= `FLOP_DELAY {parity_sample3,channel_status[191],userdata,validity,audio_sample_ch3,preamble_frame};
      ch4_sample_queue[ch4_wr_index] <= `FLOP_DELAY {parity_sample4,channel_status[191],userdata,validity,audio_sample_ch4,preamble_subframe};
      ch5_sample_queue[ch5_wr_index] <= `FLOP_DELAY {parity_sample5,channel_status[191],userdata,validity,audio_sample_ch5,preamble_frame};
      ch6_sample_queue[ch6_wr_index] <= `FLOP_DELAY {parity_sample6,channel_status[191],userdata,validity,audio_sample_ch6,preamble_subframe};
      ch7_sample_queue[ch7_wr_index] <= `FLOP_DELAY {parity_sample7,channel_status[191],userdata,validity,audio_sample_ch7,preamble_frame};
      ch8_sample_queue[ch8_wr_index] <= `FLOP_DELAY {parity_sample8,channel_status[191],userdata,validity,audio_sample_ch8,preamble_subframe};
    end

    if(pulse_sync_axis_q[1]) begin
      ch_rd_index <= `FLOP_DELAY ch_rd_index + 1'b1; 
      axis_ch_handshake <= `FLOP_DELAY 9'b0_1111_1111;
    end else if(axis_tready) begin
      axis_ch_handshake <= `FLOP_DELAY {axis_ch_handshake[7:0],1'b0};
    end

    if(axis_tready && axis_ch_handshake[8]) begin
      i_axis_id_egress_q <= `FLOP_DELAY i_axis_id_egress_q + 1'b1;
      case(i_axis_id_egress_q)
        0:  begin axis_data_egress <= `FLOP_DELAY ch1_rd_data; axis_tvalid <= `FLOP_DELAY ch_en[1]; end
        1:  begin axis_data_egress <= `FLOP_DELAY ch2_rd_data; axis_tvalid <= `FLOP_DELAY ch_en[2]; end
        2:  begin axis_data_egress <= `FLOP_DELAY ch3_rd_data; axis_tvalid <= `FLOP_DELAY ch_en[3]; end
        3:  begin axis_data_egress <= `FLOP_DELAY ch4_rd_data; axis_tvalid <= `FLOP_DELAY ch_en[4]; end
        4:  begin axis_data_egress <= `FLOP_DELAY ch5_rd_data; axis_tvalid <= `FLOP_DELAY ch_en[5]; end
        5:  begin axis_data_egress <= `FLOP_DELAY ch6_rd_data; axis_tvalid <= `FLOP_DELAY ch_en[6]; end
        6:  begin axis_data_egress <= `FLOP_DELAY ch7_rd_data; axis_tvalid <= `FLOP_DELAY ch_en[7]; end
        7:  begin axis_data_egress <= `FLOP_DELAY ch8_rd_data; axis_tvalid <= `FLOP_DELAY ch_en[8]; end
      endcase    
    end else begin
      axis_tvalid <= `FLOP_DELAY 1'b0;
    end

      ch_rd_index_d <= `FLOP_DELAY ch_rd_index; 
  end
end

always@(posedge axis_clk) begin
  i_axis_tvalid_q <= `FLOP_DELAY (axis_tready & axis_ch_handshake[8]);// for hard IP TVALID has to be high for 2 ch 0 and ch1 only (RJ)
  axis_id_egress <= `FLOP_DELAY i_axis_id_egress_q;
end

always@(posedge axis_clk) begin
  if(~axis_resetn || ~aud_start_axis)begin
    ch1_rd_data <= `FLOP_DELAY 'h0;
    ch2_rd_data <= `FLOP_DELAY 'h0;
    ch3_rd_data <= `FLOP_DELAY 'h0;
    ch4_rd_data <= `FLOP_DELAY 'h0;
    ch5_rd_data <= `FLOP_DELAY 'h0;
    ch6_rd_data <= `FLOP_DELAY 'h0;
    ch7_rd_data <= `FLOP_DELAY 'h0;
    ch8_rd_data <= `FLOP_DELAY 'h0;
  end else begin 
    if(pulse_sync_axis_q[1]) begin
      ch1_rd_data <= `FLOP_DELAY ch1_sample_queue[ch_rd_index];
      ch2_rd_data <= `FLOP_DELAY ch2_sample_queue[ch_rd_index];
      ch3_rd_data <= `FLOP_DELAY ch3_sample_queue[ch_rd_index];
      ch4_rd_data <= `FLOP_DELAY ch4_sample_queue[ch_rd_index];
      ch5_rd_data <= `FLOP_DELAY ch5_sample_queue[ch_rd_index];
      ch6_rd_data <= `FLOP_DELAY ch6_sample_queue[ch_rd_index];
      ch7_rd_data <= `FLOP_DELAY ch7_sample_queue[ch_rd_index];
      ch8_rd_data <= `FLOP_DELAY ch8_sample_queue[ch_rd_index];
    end
  end
end


assign debug_port = {
                     //Diff_Ch1,                // [198:183]
                      
                     addr_cntr_ch1, //5
                     addr_cntr_ch2, //5
                     ping_pattern_ch2[0],               // [182]
                     ping_pattern_ch1[0],             // [181]
                     load_value,              // [180]
                     pulse_sync_axis,                   // [179]
                     gen_sample_ch1,          // [178]   
                     gen_sample_ch2,          // [177]   
                     gen_sample_ch3,          // [176]   
                     gen_sample_ch4,          // [175]   
                     gen_sample_ch5,          // [174]   
                     gen_sample_ch6,          // [173]   
                     &cntr_250ms_ch1,//gen_sample_ch7,          // [172]   
                     &cntr_250ms_ch2,//gen_sample_ch8,          // [171]   
                     aud_config_update_pedge, // [170]   
                     audio_sample_ch1[23:8],  // [169:154]
                     audio_sample_ch2[23:8],  // [153:138]
                     audio_sample_ch3[23:8],  // [137:122]
                     audio_sample_ch4[23:8],  // [121:106]
                     audio_sample_ch5[23:8],  // [105:90]
                     audio_sample_ch6[23:8],  // [89:74]
                     audio_sample_ch7[23:8],  // [73:58]
                     audio_sample_ch8[23:8],  // [57:42]
                     aud_sample_rate,         // [41:38] 
                     aud_channel_count,       // [37:34]
                     aud_pattern1,             // [33:32]
                     aud_period_ch1,          // [31:28]
                     aud_period_ch2,          // [27:24]
                     aud_period_ch3,          // [23:20]
                     aud_period_ch4,          // [19:16]
                     aud_period_ch5,          // [15:12]
                     aud_period_ch6,          // [11:8]
                     aud_period_ch7,          // [7:4]
                     aud_period_ch8           // [3:0]  
                    }; 
                     

endmodule




//------------------------------------------------------------------------------ 
// Copyright (c) 2010 Xilinx, Inc. 
// All Rights Reserved 
//------------------------------------------------------------------------------ 
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /   Vendor: Xilinx 
// \   \   \/    
//  \   \        
//  /   /        
// /___/   /\    Date Created: August 06, 2020
// \   \  /  \ 
//  \___\/\___\ 
// 
//------------------------------------------------------------------------------ 
/*
This video generator is used to create different test patterns as listed in 
DP compliance specification.
The Video is generated on a fixed clock connected

*/



`timescale 1 ns / 1 ps
`include "av_pat_gen_v2_0_1_defs.v"

  //CDC Defs
  `define CDC_PULSE      0
  `define CDC_LEVEL      1
  `define CDC_LEVEL_ACK  2
  //XPM_CDC defines
  `define USE_XPM_CDC_PULSE 
  `define USE_XPM_CDC_SINGLE
  `define USE_XPM_CDC_ARRAY_SINGLE 

//  `define XPM_CDC_VERSION "REV1.0"
  `define XPM_CDC_SIM_ASYNC_RAND 0
  `define XPM_CDC_SIM_ASSERT_CHK 0
  `define XPM_CDC_MTBF_FFS 3

	module av_pat_gen_v2_0_1 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		parameter integer C_vid_out_BPC	= 8,
		parameter integer C_vid_out_PPC	= 4,

		// Parameters of Axi Slave Bus Interface av_axi
		parameter integer C_av_axi_DATA_WIDTH	= 32,
		parameter integer C_av_axi_ADDR_WIDTH	= 12,

		// Parameters of Axi Master Bus Interface vid_out_axi4s
		parameter integer C_vid_out_axi4s_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface aud_out_axi4s
		parameter integer C_aud_out_axi4s_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface av_axi
		input wire  av_axi_aclk,
		input wire  aud_clk,
		input wire  av_axi_aresetn,
		input wire [C_av_axi_ADDR_WIDTH-1 : 0] av_axi_awaddr,
		input wire [2 : 0] av_axi_awprot,
		input wire  av_axi_awvalid,
		output wire  av_axi_awready,
		input wire [C_av_axi_DATA_WIDTH-1 : 0] av_axi_wdata,
		input wire [(C_av_axi_DATA_WIDTH/8)-1 : 0] av_axi_wstrb,
		input wire  av_axi_wvalid,
		output wire  av_axi_wready,
		output wire [1 : 0] av_axi_bresp,
		output wire  av_axi_bvalid,
		input wire  av_axi_bready,
		input wire [C_av_axi_ADDR_WIDTH-1 : 0] av_axi_araddr,
		input wire [2 : 0] av_axi_arprot,
		input wire  av_axi_arvalid,
		output wire  av_axi_arready,
		output wire [C_av_axi_DATA_WIDTH-1 : 0] av_axi_rdata,
		output wire [1 : 0] av_axi_rresp,
		output wire  av_axi_rvalid,
		input wire  av_axi_rready,
                input wire TPG_GEN_EN,
               		// Ports SDP_01 Interface  // Primary SDP Interface
		output wire          ext_sdp01_req_o,
        output wire [71 : 0] ext_sdp01_data_o,
        input wire           ext_sdp01_ack_i,
        input wire           ext_sdp01_vertical_blanking_i,
        input wire           ext_sdp01_horizontal_blanking_i,
        input wire [1 : 0]   ext_sdp01_line_cnt_mat_i,
        
        // Ports SDP_00 Interface  // Seconadary SDP Interface
		output wire          ext_sdp00_req_o,
        output wire [71 : 0] ext_sdp00_data_o,
        input wire           ext_sdp00_ack_i,
        input wire           ext_sdp00_vertical_blanking_i,
        input wire           ext_sdp00_horizontal_blanking_i,
        input wire [1 : 0]   ext_sdp00_line_cnt_mat_i,

		
	
		// Ports of Axi Master Bus Interface vid_in_axi4s
		input wire  vid_in_axi4s_tvalid,
		input wire  [C_vid_out_axi4s_TDATA_WIDTH-1 : 0] vid_in_axi4s_tdata,
		input wire   vid_in_axi4s_tuser,
		input wire   vid_in_axi4s_tlast,
		output wire  vid_in_axi4s_tready,

		// Ports of Axi Master Bus Interface aud_in_axi4s
	        input  wire  aud_in_axi4s_tvalid,
		input  wire [C_aud_out_axi4s_TDATA_WIDTH-1 : 0] aud_in_axi4s_tdata,
		input  wire [7 : 0] aud_in_axi4s_tid,
		output wire  aud_in_axi4s_tready,

		// Ports of Axi Master Bus Interface vid_out_axi4s
		input wire  vid_out_axi4s_aclk,
		input wire  vid_out_axi4s_aresetn,
		output wire  vid_out_axi4s_tvalid,
		output wire [C_vid_out_axi4s_TDATA_WIDTH-1 : 0] vid_out_axi4s_tdata,
		output wire  vid_out_axi4s_tuser,
		output wire  vid_out_axi4s_tlast,
		input wire  vid_out_axi4s_tready,

		// Ports of Axi Master Bus Interface aud_out_axi4s
		input wire  aud_out_axi4s_aclk,
		input wire  aud_out_axi4s_aresetn,
		output wire  aud_out_axi4s_tvalid,
		output wire [C_aud_out_axi4s_TDATA_WIDTH-1 : 0] aud_out_axi4s_tdata,
		output wire [7 : 0] aud_out_axi4s_tid,
		input wire  aud_out_axi4s_tready
	);

  localparam VAXI4S_WAIT_FOR_VSYNC = 3'b001;
  localparam VAXI4S_WAIT_FOR_PIXEL = 3'b010;
  localparam VAXI4S_GEN_TLAST      = 3'b100;

  reg [2:0] vaxi4s_mapper_state;

  wire [(`DISP_DTC_REGS_SIZE-1):0] disp_dtc_regs;
  wire [(`DISP_DTC_REGS_SIZE-1):0] disp_dtc_regs_w;
   wire [(`DISP_SDP_PYLD_SIZE-1):0] disp_sdp_data_regs;
  wire [(`DISP_SDP_CTRL_SIZE-1):0] disp_sdp_ctrl_regs;
  wire [2:0]                       hdcolorbar_cfg;
  wire [2:0]                       hdcolorbar_cfg_w;
  wire [7:0]                       misc0;
  wire [7:0]                       misc0_w;
  wire [7:0]                       misc1;
  wire [7:0]                       misc1_w;
  wire [2:0]                       test_pattern;
  wire [2:0]                       test_pattern_w;
  wire [13:0]                      bgnd_hcount;
  wire [13:0]                      bgnd_hcount_new;
  wire [13:0]                      bgnd_vcount;
  wire [13:0]                      bgnd_vcount_new;
  wire                             dual_pixel_mode;
  wire                             dual_pixel_mode_w;
  wire                             quad_pixel_mode;
  wire                             quad_pixel_mode_w;
  wire                             octa_pixel_mode;
  wire                             octa_pixel_mode_w;
  wire                             bgnd_hblnk;
  wire                             bgnd_vblnk;
  wire                             bgnd_hblnk_new;
  wire                             bgnd_vblnk_new;
  wire                             VGA_HSYNC_INT;
  wire                             VGA_VSYNC_INT;
  wire                             VGA_HSYNC_INT_NEW;
  wire                             VGA_VSYNC_INT_NEW;
  reg                              de;
  reg                              active;
  reg                              VGA_HSYNC;
  reg                              VGA_VSYNC;
  wire                             vid_enable_adj;
  reg                              vid_enable_adj_q;
  wire                             vid_de_fe;       
  wire                             vid_vsync_re;       
  reg                              hsync;
  reg                              vsync;
  wire [47:0]                      pixel0;
  wire [47:0]                      pixel1;
  wire [47:0]                      pixel2;
  wire [47:0]                      pixel3;

  wire [47:0]                      pixel4;
  wire [47:0]                      pixel5;
  wire [47:0]                      pixel6;
  wire [47:0]                      pixel7;
  wire vid_out_axi4s_tvalid_pg;
  wire vid_out_axi4s_tlast_pg;
  wire vid_out_axi4s_tuser_pg;
  wire [C_vid_out_axi4s_TDATA_WIDTH-1 : 0] vid_out_axi4s_tdata_pg;


  wire vid_out_axi4s_areset = ~vid_out_axi4s_aresetn;

// audio
   wire         axi_audreset;
   wire         axi_audstart;
   wire         axi_auddrop;
   wire         axi_config_update;
   
   wire         aud_reset;
   (* ASYNC_REG = "TRUE" *) reg  [  1:0] aud_start_sync;
   reg  [  1:0] aud_drop_sync;
   wire         aud_config_update;
   wire [  3:0] aud_sample_rate;
   wire [  3:0] aud_channel_count;
   wire [191:0] aud_channel_status;
   wire [  1:0] aud_pattern1;
   wire [  1:0] aud_pattern2;
   wire [  1:0] aud_pattern3;
   wire [  1:0] aud_pattern4;
   wire [  1:0] aud_pattern5;
   wire [  1:0] aud_pattern6;
   wire [  1:0] aud_pattern7;
   wire [  1:0] aud_pattern8;
   wire [  3:0] aud_period1;
   wire [  3:0] aud_period2;
   wire [  3:0] aud_period3;
   wire [  3:0] aud_period4;
   wire [  3:0] aud_period5;
   wire [  3:0] aud_period6;
   wire [  3:0] aud_period7;
   wire [  3:0] aud_period8;
   wire [ 23:0] offset_addr_cntr;

   (* ASYNC_REG = "TRUE" *) reg  [  1:0] axis_start_sync;
   reg  [  1:0] axis_drop_sync;
   reg  [  1:0] audio_stream_id_sync;
   wire [ 31:0] axis_tdata_from_patgen;
   wire [  2:0] axis_tid_from_patgen;
   wire         axis_tvalid_from_patgen;



localparam DETECT_BLOCK = 2'b01;
localparam PARSE_BLOCK  = 2'b10;
//(* mark_debug = "true" *)reg [1:0] aud_block_state = DETECT_BLOCK;
reg [1:0] aud_block_state = DETECT_BLOCK;
reg [1:0] aud_block_state_sync;
reg [1:0] aud_block_state_check;
reg [7:0] aud_block_state_check_cnt;
reg [191:0] channel_status_ch0;
reg [191:0] channel_status_ch1;
reg [191:0] channel_status_ch0_latch;
reg [191:0] channel_status_ch1_latch;
reg [191:0] channel_status_ch0_latch_sync;
reg [191:0] channel_status_ch1_latch_sync;
reg [31:0] axi4lite_timer;
wire [31:0] axi4lite_timer_offset;
wire        audio_chk_start;
wire [3:0]  audio_stream_id;
reg [2:0]   audio_chk_start_sync;
reg        axi4lite_timer_offset_toggle;
reg [31:0] ch0_sample_count;
reg [31:0] ch1_sample_count;
reg [31:0] ch0_sample_count_latch;
reg [31:0] ch1_sample_count_latch;
reg [31:0] ch0_sample_count_latch_sync;
reg [31:0] ch1_sample_count_latch_sync;
//(* mark_debug = "true" *)reg [3:0] axi4lite_timer_offset_toggle_sync;
reg [3:0] axi4lite_timer_offset_toggle_sync;

// Instantiation of Axi Bus Interface av_axi
	av_pat_gen_v2_0_1_av_axi # ( 
		.C_S_AXI_DATA_WIDTH(C_av_axi_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_av_axi_ADDR_WIDTH)
	) av_pat_gen_v2_0_1_av_axi_inst (
		.S_AXI_ACLK(av_axi_aclk),
		.S_AXI_ARESETN(av_axi_aresetn),
		.S_AXI_AWADDR(av_axi_awaddr),
		.S_AXI_AWPROT(av_axi_awprot),
		.S_AXI_AWVALID(av_axi_awvalid),
		.S_AXI_AWREADY(av_axi_awready),
		.S_AXI_WDATA(av_axi_wdata),
		.S_AXI_WSTRB(av_axi_wstrb),
		.S_AXI_WVALID(av_axi_wvalid),
		.S_AXI_WREADY(av_axi_wready),
		.S_AXI_BRESP(av_axi_bresp),
		.S_AXI_BVALID(av_axi_bvalid),
		.S_AXI_BREADY(av_axi_bready),
		.S_AXI_ARADDR(av_axi_araddr),
		.S_AXI_ARPROT(av_axi_arprot),
		.S_AXI_ARVALID(av_axi_arvalid),
		.S_AXI_ARREADY(av_axi_arready),
		.S_AXI_RDATA(av_axi_rdata),
		.S_AXI_RRESP(av_axi_rresp),
		.S_AXI_RVALID(av_axi_rvalid),
		.S_AXI_RREADY(av_axi_rready),
                .TPG_GEN_EN(TPG_GEN_EN),
                .disp_dtc_regs(disp_dtc_regs_w),
                .hdcolorbar_cfg(hdcolorbar_cfg_w),
                .misc0(misc0_w),
                .misc1(misc1_w),
                .test_pattern(test_pattern_w),
                .en_sw_pattern(),
                .dual_pixel_mode(dual_pixel_mode_w),
                .quad_pixel_mode(quad_pixel_mode_w),
                .octa_pixel_mode(octa_pixel_mode_w),
        .disp_sdp_data_regs(disp_sdp_data_regs),
        .disp_sdp_ctrl_regs(disp_sdp_ctrl_regs),
       .aud_reset                 (axi_audreset),
       .aud_start                 (axi_audstart),
       .aud_config_update         (axi_config_update),
       .aud_sample_rate           (aud_sample_rate),
       .aud_channel_count         (aud_channel_count),
       .aud_channel_status        (aud_channel_status),
       .aud_pattern1              (aud_pattern1),
       .aud_pattern2              (aud_pattern2),
       .aud_pattern3              (aud_pattern3),
       .aud_pattern4              (aud_pattern4),
       .aud_pattern5              (aud_pattern5),
       .aud_pattern6              (aud_pattern6),
       .aud_pattern7              (aud_pattern7),
       .aud_pattern8              (aud_pattern8),
       .aud_period1               (aud_period1),
       .aud_period2               (aud_period2),
       .aud_period3               (aud_period3),
       .aud_period4               (aud_period4),
       .aud_period5               (aud_period5),
       .aud_period6               (aud_period6),
       .aud_period7               (aud_period7),
       .aud_period8               (aud_period8),
       .offset_addr_cntr          (offset_addr_cntr),
       .aud_drop                 (axi_auddrop),
       .axi4lite_timer           (axi4lite_timer_offset), 
       .audio_chk_start          (audio_chk_start),
       .audio_stream_id          (audio_stream_id),
       .channel_status_ch0       (channel_status_ch0_latch_sync),
       .channel_status_ch1       (channel_status_ch1_latch_sync),
       .ch0_sample_cnt           (ch0_sample_count_latch_sync),
       .ch1_sample_cnt           (ch1_sample_count_latch_sync),
       .aud_block_state           (aud_block_state_sync)
	);

        xpm_cdc_array_single #(
//          .VERSION        (`XPM_CDC_VERSION       ),
          .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
          .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
          .WIDTH          (`DISP_DTC_REGS_SIZE    ),
          .SRC_INPUT_REG  (1                      )
        ) xpm_array_disp_dtc_regs_inst (
          .src_clk         ( av_axi_aclk ),
          .src_in          ( disp_dtc_regs_w ),
          .dest_clk        ( vid_out_axi4s_aclk ),
          .dest_out        ( disp_dtc_regs )
        );

        xpm_cdc_array_single #(
  //        .VERSION        (`XPM_CDC_VERSION       ),
          .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
          .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
          .WIDTH          (3    ),
          .SRC_INPUT_REG  (1                      )
        ) xpm_array_hdcolorbar_cfg_inst (
          .src_clk         ( av_axi_aclk ),
          .src_in          ( hdcolorbar_cfg_w ),
          .dest_clk        ( vid_out_axi4s_aclk ),
          .dest_out        ( hdcolorbar_cfg )
        );

        xpm_cdc_array_single #(
    //      .VERSION        (`XPM_CDC_VERSION       ),
          .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
          .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
          .WIDTH          (8    ),
          .SRC_INPUT_REG  (1                      )
        ) xpm_array_misc0_inst (
          .src_clk         ( av_axi_aclk ),
          .src_in          ( misc0_w ),
          .dest_clk        ( vid_out_axi4s_aclk ),
          .dest_out        ( misc0 )
        );

        xpm_cdc_array_single #(
      //    .VERSION        (`XPM_CDC_VERSION       ),
          .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
          .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
          .WIDTH          (8    ),
          .SRC_INPUT_REG  (1                      )
        ) xpm_array_misc1_inst (
          .src_clk         ( av_axi_aclk ),
          .src_in          ( misc1_w ),
          .dest_clk        ( vid_out_axi4s_aclk ),
          .dest_out        ( misc1 )
        );

        xpm_cdc_array_single #(
      //    .VERSION        (`XPM_CDC_VERSION       ),
          .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
          .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
          .WIDTH          (3    ),
          .SRC_INPUT_REG  (1                      )
        ) xpm_array_test_pattern_inst (
          .src_clk         ( av_axi_aclk ),
          .src_in          ( test_pattern_w ),
          .dest_clk        ( vid_out_axi4s_aclk ),
          .dest_out        ( test_pattern )
        );

        xpm_cdc_single #(
      //    .VERSION        (`XPM_CDC_VERSION       ),
          .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
          .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
          .SRC_INPUT_REG  (1                      )
        ) xpm_single_dual_pixel_mode_inst (
          .src_clk         ( av_axi_aclk ),
          .src_in          ( dual_pixel_mode_w ),
          .dest_clk        ( vid_out_axi4s_aclk ),
          .dest_out        ( dual_pixel_mode )
        );

        xpm_cdc_single #(
      //    .VERSION        (`XPM_CDC_VERSION       ),
          .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
          .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
          .SRC_INPUT_REG  (1                      )
        ) xpm_single_quad_pixel_mode_inst (
          .src_clk         ( av_axi_aclk ),
          .src_in          ( quad_pixel_mode_w ),
          .dest_clk        ( vid_out_axi4s_aclk ),
          .dest_out        ( quad_pixel_mode )
        );

/*
  av_pat_gen_v2_0_1_timing_new vtc_new_inst (
    .tc_hsblnk(disp_dtc_regs[`TC_HSBLNK]),   //input
    .tc_hssync(disp_dtc_regs[`TC_HSSYNC]),   //input
    .tc_hesync(disp_dtc_regs[`TC_HESYNC]),   //input
    .tc_heblnk(disp_dtc_regs[`TC_HEBLNK]),   //input
    .tc_hactive(disp_dtc_regs[`HRES]),   //input
    .tc_vactive(disp_dtc_regs[`VRES]),   //input
    .hcount(bgnd_hcount_new),                         //output
    .hsync(VGA_HSYNC_INT_NEW),                        //output
    .hblnk(bgnd_hblnk_new),                           //output
    .tc_vsblnk(disp_dtc_regs[`TC_VSBLNK]),   //input
    .tc_vssync(disp_dtc_regs[`TC_VSSYNC]),   //input
    .tc_vesync(disp_dtc_regs[`TC_VESYNC]),   //input
    .tc_veblnk(disp_dtc_regs[`TC_VEBLNK]),   //input
    .vcount(bgnd_vcount_new),                         //output
    .vsync(VGA_VSYNC_INT_NEW),                        //output
    .vblnk(bgnd_vblnk_new),                           //output
    .restart(vid_out_axi4s_areset),
    .clk(vid_out_axi4s_aclk),
    .new_tlast(new_tlast), // axis tlast
    .new_tuser(new_tuser), //axis tuser
    .new_tvalid(new_tvalid), //axis tvalid
    .blnk_enable(blnk_enable), // to be or'd with axis_enable and given to patgen
    .new_enable(axis_enable)
    );
*/

        xpm_cdc_single #(
      //    .VERSION        (`XPM_CDC_VERSION       ),
          .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
          .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
          .SRC_INPUT_REG  (1                      )
        ) xpm_single_octa_pixel_mode_inst (
          .src_clk         ( av_axi_aclk ),
          .src_in          ( octa_pixel_mode_w ),
          .dest_clk        ( vid_out_axi4s_aclk ),
          .dest_out        ( octa_pixel_mode )
        );

/*  av_pat_gen_v2_0_1_timing vtc_inst (
    .tc_hsblnk(disp_dtc_regs[`TC_HSBLNK]),   //input
    .tc_hssync(disp_dtc_regs[`TC_HSSYNC]),   //input
    .tc_hesync(disp_dtc_regs[`TC_HESYNC]),   //input
    .tc_heblnk(disp_dtc_regs[`TC_HEBLNK]),   //input
    .hcount(bgnd_hcount),                         //output
    .hsync(VGA_HSYNC_INT),                        //output
    .hblnk(bgnd_hblnk),                           //output
    .tc_vsblnk(disp_dtc_regs[`TC_VSBLNK]),   //input
    .tc_vssync(disp_dtc_regs[`TC_VSSYNC]),   //input
    .tc_vesync(disp_dtc_regs[`TC_VESYNC]),   //input
    .tc_veblnk(disp_dtc_regs[`TC_VEBLNK]),   //input
    .vcount(bgnd_vcount),                         //output
    .vsync(VGA_VSYNC_INT),                        //output
    .vblnk(bgnd_vblnk),                           //output
    .restart(vid_out_axi4s_areset),
    .clk(vid_out_axi4s_aclk));
*/
  always @ (posedge vid_out_axi4s_aclk) begin
    hsync     <= VGA_HSYNC_INT_NEW; //^ disp_dtc_regs_sync[`HSYNC_POLARITY];
    vsync     <= VGA_VSYNC_INT_NEW; //^ disp_dtc_regs_sync[`VSYNC_POLARITY];
    VGA_HSYNC <= hsync;
    VGA_VSYNC <= vsync;
    active    <= !bgnd_hblnk_new && !bgnd_vblnk_new;
    de        <= active;
    vid_enable_adj_q  <= vid_enable_adj;
  end

  assign vid_de_fe    = ~vid_enable_adj & vid_enable_adj_q;
  assign vid_vsync_re = vsync & ~VGA_VSYNC;
  assign pat_enable = disp_dtc_regs[`ENABLE];

  av_pat_gen_v2_0_1_video_pattern_new  #(
     .C_PPC(C_vid_out_PPC)
  )
  video_pattern_inst ( 
	  .clk (vid_out_axi4s_aclk),
	  .rst (vid_out_axi4s_areset | !pat_enable),
	  .misc0 (misc0),
	  .misc1 (misc1),
	  .vcount_in (disp_dtc_regs[`VRES]),
	  .hcount_in (disp_dtc_regs[`HRES]),
	  .dual_pixel_mode (dual_pixel_mode),
	  .quad_pixel_mode (quad_pixel_mode),
	  .octa_pixel_mode (octa_pixel_mode),
	  .bpc_out (),
	  .pattern (test_pattern),
	  .pixel0 (pixel0),
	  .pixel1 (pixel1),
	  .pixel2 (pixel2),
	  .pixel3 (pixel3),
	  .pixel4 (pixel4),
	  .pixel5 (pixel5),
	  .pixel6 (pixel6),
	  .pixel7 (pixel7),
          .tvalid (vid_out_axi4s_tvalid_pg),
          .tlast (vid_out_axi4s_tlast_pg),
          .tuser(vid_out_axi4s_tuser_pg),
          .tready(vid_out_axi4s_tready)
	  );


/*
  av_pat_gen_v2_0_1_video_pattern video_pattern_inst(
	  .clk (vid_out_axi4s_aclk),
	  .rst (vid_out_axi4s_areset),
	  .vid_enable (de),
	  .vid_enable_adj (vid_enable_adj),
	  .misc0 (misc0),
	  .misc1 (misc1),
	  .vcount (bgnd_vcount),
	  .hcount (bgnd_hcount),
	  .hsync (hsync),
	  .vsync (vsync),
	  .dual_pixel_mode (dual_pixel_mode),
	  .quad_pixel_mode (quad_pixel_mode),
	  .bpc_out (),
	  .pattern (test_pattern),
	  .pixel0 (pixel0),
	  .pixel1 (pixel1),
	  .pixel2 (pixel2),
	  .pixel3 (pixel3)
	  );
*/
wire [C_vid_out_axi4s_TDATA_WIDTH-1 : 0] axi4s_pixel_data;
reg  [C_vid_out_axi4s_TDATA_WIDTH-1 : 0] axi4s_pixel_data_r;
//assign axi4s_pixel_data = { 
//                            pixel3[47: 48-C_vid_out_BPC], pixel3[31: 32-C_vid_out_BPC], pixel3[15: 16-C_vid_out_BPC],
//                            pixel2[47: 48-C_vid_out_BPC], pixel2[31: 32-C_vid_out_BPC], pixel2[15: 16-C_vid_out_BPC],
//                            pixel1[47: 48-C_vid_out_BPC], pixel1[31: 32-C_vid_out_BPC], pixel1[15: 16-C_vid_out_BPC],
//                            pixel0[47: 48-C_vid_out_BPC], pixel0[31: 32-C_vid_out_BPC], pixel0[15: 16-C_vid_out_BPC]
//                          };

    generate if (C_vid_out_PPC==4)
    begin : gen_crc_4ppc

	assign axi4s_pixel_data = (misc0[2:1] != 2'b01) ?
                          { 
                            pixel3[47: 48-C_vid_out_BPC], pixel3[15: 16-C_vid_out_BPC], pixel3[31: 32-C_vid_out_BPC],
                            pixel2[47: 48-C_vid_out_BPC], pixel2[15: 16-C_vid_out_BPC], pixel2[31: 32-C_vid_out_BPC],
                            pixel1[47: 48-C_vid_out_BPC], pixel1[15: 16-C_vid_out_BPC], pixel1[31: 32-C_vid_out_BPC],
                            pixel0[47: 48-C_vid_out_BPC], pixel0[15: 16-C_vid_out_BPC], pixel0[31: 32-C_vid_out_BPC]
                          } :
                          { 
                            {{4*C_vid_out_BPC}{1'b0}},
                            pixel3[47: 48-C_vid_out_BPC], pixel3[15: 16-C_vid_out_BPC],
                            pixel2[47: 48-C_vid_out_BPC], pixel2[15: 16-C_vid_out_BPC],
                            pixel1[47: 48-C_vid_out_BPC], pixel1[15: 16-C_vid_out_BPC],
                            pixel0[47: 48-C_vid_out_BPC], pixel0[15: 16-C_vid_out_BPC]
                          };

    end else begin

	assign axi4s_pixel_data = (misc0[2:1] != 2'b01) ?
                          { 
                            pixel7[47: 48-C_vid_out_BPC], pixel7[15: 16-C_vid_out_BPC], pixel7[31: 32-C_vid_out_BPC],
                            pixel6[47: 48-C_vid_out_BPC], pixel6[15: 16-C_vid_out_BPC], pixel6[31: 32-C_vid_out_BPC],
                            pixel5[47: 48-C_vid_out_BPC], pixel5[15: 16-C_vid_out_BPC], pixel5[31: 32-C_vid_out_BPC],
                            pixel4[47: 48-C_vid_out_BPC], pixel4[15: 16-C_vid_out_BPC], pixel4[31: 32-C_vid_out_BPC],
                            pixel3[47: 48-C_vid_out_BPC], pixel3[15: 16-C_vid_out_BPC], pixel3[31: 32-C_vid_out_BPC],
                            pixel2[47: 48-C_vid_out_BPC], pixel2[15: 16-C_vid_out_BPC], pixel2[31: 32-C_vid_out_BPC],
                            pixel1[47: 48-C_vid_out_BPC], pixel1[15: 16-C_vid_out_BPC], pixel1[31: 32-C_vid_out_BPC],
                            pixel0[47: 48-C_vid_out_BPC], pixel0[15: 16-C_vid_out_BPC], pixel0[31: 32-C_vid_out_BPC]
                          } :
                          { 
                            {{8*C_vid_out_BPC}{1'b0}},
                            pixel7[47: 48-C_vid_out_BPC], pixel7[15: 16-C_vid_out_BPC],
                            pixel6[47: 48-C_vid_out_BPC], pixel6[15: 16-C_vid_out_BPC],
                            pixel5[47: 48-C_vid_out_BPC], pixel5[15: 16-C_vid_out_BPC],
                            pixel4[47: 48-C_vid_out_BPC], pixel4[15: 16-C_vid_out_BPC],
                            pixel3[47: 48-C_vid_out_BPC], pixel3[15: 16-C_vid_out_BPC],
                            pixel2[47: 48-C_vid_out_BPC], pixel2[15: 16-C_vid_out_BPC],
                            pixel1[47: 48-C_vid_out_BPC], pixel1[15: 16-C_vid_out_BPC],
                            pixel0[47: 48-C_vid_out_BPC], pixel0[15: 16-C_vid_out_BPC]
                          };

    end
    endgenerate//C_PPC_MODE

assign vid_out_axi4s_tdata_pg = axi4s_pixel_data;

reg [1:0] vsync_count;

/*
always@(posedge vid_out_axi4s_aclk) begin
  if( vid_out_axi4s_areset==1'b1 || disp_dtc_regs[`ENABLE]==1'b0 ) begin
    vid_out_axi4s_tvalid_pg <= 1'b0;
    vid_out_axi4s_tlast_pg  <= 1'b0;
    vid_out_axi4s_tuser_pg  <= 1'b0;
    vid_out_axi4s_tdata_pg  <= 'h0;
    vaxi4s_mapper_state  <= VAXI4S_WAIT_FOR_VSYNC;
    vsync_count <= 'h0;
  end else begin

    if(vid_vsync_re) vsync_count <= vsync_count + 1'b1;

    vid_out_axi4s_tuser_pg  <= 1'b0;
    vid_out_axi4s_tlast_pg  <= 1'b0;
    vid_out_axi4s_tvalid_pg <= 1'b0;
    axi4s_pixel_data_r   <= axi4s_pixel_data;
    vid_out_axi4s_tdata_pg  <= axi4s_pixel_data_r;

    case(vaxi4s_mapper_state)

      VAXI4S_WAIT_FOR_VSYNC: begin
        //Ignore inital few frames and then start AXI4S Conversion
        if(vsync & (&vsync_count)) begin
          vaxi4s_mapper_state  <= VAXI4S_WAIT_FOR_PIXEL;
        end
      end

      VAXI4S_WAIT_FOR_PIXEL: begin
        if(vid_enable_adj_q) begin
          vid_out_axi4s_tuser_pg  <= 1'b1;
          vaxi4s_mapper_state  <= VAXI4S_GEN_TLAST;
          vid_out_axi4s_tvalid_pg <= 1'b1;
        end
      end

      VAXI4S_GEN_TLAST: begin
        if(VGA_VSYNC) begin
          vid_out_axi4s_tlast_pg  <= 1'b0;
          vaxi4s_mapper_state  <= VAXI4S_WAIT_FOR_PIXEL;
        end else if(vid_de_fe) begin
          vid_out_axi4s_tlast_pg  <= 1'b1;
          vid_out_axi4s_tvalid_pg <= 1'b1;
        end else if(vid_enable_adj_q) begin
          vid_out_axi4s_tvalid_pg <= 1'b1;
        end 
      end

    endcase

  end
end
*/

// AUDIO Sniffer - Handles 2 channels

always@(posedge av_axi_aclk) begin
  if(av_axi_aresetn==1'b0 || audio_chk_start==1'b0) begin
    axi4lite_timer <= 'h0;
    axi4lite_timer_offset_toggle <= 1'b0;
  end else begin
    if(axi4lite_timer == axi4lite_timer_offset) begin
      axi4lite_timer <= 'h0;
      axi4lite_timer_offset_toggle <= ~axi4lite_timer_offset_toggle;
    end else begin
      axi4lite_timer <= axi4lite_timer + 1'b1;
    end
  end
end

wire axi4lite_timer_offset_toggle_sync_pulse = (axi4lite_timer_offset_toggle_sync[3] != axi4lite_timer_offset_toggle_sync[2]);
always@(posedge aud_out_axi4s_aclk) begin
  axi4lite_timer_offset_toggle_sync <= {axi4lite_timer_offset_toggle_sync[2:0], axi4lite_timer_offset_toggle};
  audio_chk_start_sync <= {audio_chk_start_sync[1:0], audio_chk_start};
end

always@(posedge aud_out_axi4s_aclk) begin
  if(aud_out_axi4s_aresetn == 1'b0 || audio_chk_start_sync[2] == 1'b0) begin
    ch0_sample_count <= 0;  
    ch1_sample_count <= 0;  
    aud_block_state_check <= 0;
    aud_block_state_check_cnt <= 0;
    aud_block_state <= DETECT_BLOCK;
  end else begin

    case(aud_block_state)
      DETECT_BLOCK: begin
        if(aud_out_axi4s_tid == 'h0 && aud_out_axi4s_tvalid == 1'b1 && aud_out_axi4s_tready == 1'b1) begin
          if(aud_out_axi4s_tdata[3:0] == 4'b0001) begin
            aud_block_state_check <= aud_block_state_check + 1'b1;
            if(aud_block_state_check == 2'b11) begin
              aud_block_state_check_cnt <= 0;
              aud_block_state <= PARSE_BLOCK;
              channel_status_ch0 <= {channel_status_ch0[190:0],aud_out_axi4s_tdata[30]};
            end
          end
        end
      end
      PARSE_BLOCK: begin
        if(aud_out_axi4s_tid == 'h0 && aud_out_axi4s_tvalid == 1'b1 && aud_out_axi4s_tready == 1'b1) begin
          if(aud_block_state_check_cnt==191) 
            aud_block_state_check_cnt <= 0; 
          else 
            aud_block_state_check_cnt <= aud_block_state_check_cnt + 1'b1;

          if(aud_block_state_check_cnt==191 && aud_out_axi4s_tdata[3:0] != 4'b0001) begin
            aud_block_state <= DETECT_BLOCK;
            aud_block_state_check <= 0;
          end

          if(aud_out_axi4s_tdata[3:0] == 4'b0010 || aud_out_axi4s_tdata[3:0] == 4'b0001) begin
            channel_status_ch0 <= {channel_status_ch0[190:0],aud_out_axi4s_tdata[30]};  
          end
          if(aud_out_axi4s_tdata[3:0] == 4'b0001) begin
            channel_status_ch0_latch <= channel_status_ch0;
          end
        end
      end
    endcase

    if(axi4lite_timer_offset_toggle_sync_pulse) begin
      ch0_sample_count_latch <= ch0_sample_count;
      ch1_sample_count_latch <= ch1_sample_count;
      ch0_sample_count <= 0;  
      ch1_sample_count <= 0;  
    end else if(aud_out_axi4s_tid == 'h0 && aud_out_axi4s_tvalid == 1'b1 && aud_out_axi4s_tready == 1'b1) begin
      ch0_sample_count <= ch0_sample_count + 1'b1;
    end else if(aud_out_axi4s_tid == 'h1 && aud_out_axi4s_tvalid == 1'b1 && aud_out_axi4s_tready == 1'b1) begin
      ch1_sample_count <= ch1_sample_count + 1'b1;
    end

  end
end

//Output MUX
assign vid_out_axi4s_tvalid = (test_pattern==0)?vid_in_axi4s_tvalid:vid_out_axi4s_tvalid_pg;
assign vid_out_axi4s_tlast  = (test_pattern==0)?vid_in_axi4s_tlast :vid_out_axi4s_tlast_pg;
assign vid_out_axi4s_tuser  = (test_pattern==0)?vid_in_axi4s_tuser :vid_out_axi4s_tuser_pg;
assign vid_out_axi4s_tdata  = (test_pattern==0)?vid_in_axi4s_tdata :vid_out_axi4s_tdata_pg;

assign vid_in_axi4s_tready = (test_pattern==0)?vid_out_axi4s_tready:1'b1;
// audio

  assign aud_out_axi4s_tvalid = ( axis_start_sync[1]) ? axis_tvalid_from_patgen    : aud_in_axi4s_tvalid;
  assign aud_out_axi4s_tid = ( axis_start_sync[1]) ? {audio_stream_id_sync[1], 1'b0, axis_tid_from_patgen}       : aud_in_axi4s_tid;
  assign aud_out_axi4s_tdata  = ( axis_start_sync[1]) ? axis_tdata_from_patgen     : aud_in_axi4s_tdata; 

assign aud_in_axi4s_tready = ( axis_start_sync[1]) ? 1'b1: aud_out_axi4s_tready;
//  assign axis_aud_pattern_tready_out = ( axis_drop_sync[1] && axis_start_sync[1]) ? 1'b1 : (~axis_start_sync[1]) ? axis_aud_pattern_tready_in : 1'b0; 
//  assign axis_tready_to_patgen       = ( axis_start_sync[1]) ? axis_aud_pattern_tready_in : 1'b0;
   
  // Audio generator
  av_pat_gen_v2_0_1_dport dport_aud_pat_gen_inst (
       .aud_clk                   (aud_clk),
       .aud_reset                 (aud_reset),
       .aud_start                 (aud_start_sync[1]),
       .aud_start_axis            (axis_start_sync[1]),
       .aud_sample_rate           (aud_sample_rate),
       .aud_channel_count         (aud_channel_count),
       .aud_spdif_channel_status  (aud_channel_status[191:150]),
       .aud_pattern1              (aud_pattern1),
       .aud_pattern2              (aud_pattern2),                      
       .aud_pattern3              (aud_pattern3),                      
       .aud_pattern4              (aud_pattern4),                      
       .aud_pattern5              (aud_pattern5),                      
       .aud_pattern6              (aud_pattern6),                      
       .aud_pattern7              (aud_pattern7),                      
       .aud_pattern8              (aud_pattern8),                      
       .aud_period_ch1            (aud_period1),
       .aud_period_ch2            (aud_period2),
       .aud_period_ch3            (aud_period3),
       .aud_period_ch4            (aud_period4),
       .aud_period_ch5            (aud_period5),
       .aud_period_ch6            (aud_period6),
       .aud_period_ch7            (aud_period7),
       .aud_period_ch8            (aud_period8),
       .aud_config_update         (aud_config_update),
       .offset_addr_cntr          (offset_addr_cntr),
      
       // AXI Streaming Signals
       .axis_clk                  (aud_out_axi4s_aclk),
       .axis_resetn               (aud_out_axi4s_aresetn),
       .axis_data_egress          (axis_tdata_from_patgen),
       .axis_id_egress            (axis_tid_from_patgen),
       .axis_tvalid               (axis_tvalid_from_patgen),
       .axis_tready               (aud_out_axi4s_tready), //axis_tready_to_patgen),
       .debug_port                () 
       );

  pulse_clkcross_aud
  AUD_RST_CLK_CROSS_INST
  (
    .in_clk    (av_axi_aclk),
    .in_pulse  (axi_audreset),
    .out_clk   (aud_clk),
    .out_pulse (aud_reset)
  );     
 
  pulse_clkcross_aud
  AUD_CFGUPD_CLK_CROSS_INST
  (
    .in_clk    (av_axi_aclk),
    .in_pulse  (axi_config_update),
    .out_clk   (aud_clk),
    .out_pulse (aud_config_update)
  ); 
 
  always @(posedge aud_clk)
  begin
    aud_start_sync <= {aud_start_sync[0], axi_audstart};
  end
 
  always @(posedge aud_out_axi4s_aclk)
  begin
    axis_start_sync <= {axis_start_sync[0], axi_audstart};
  end

  always @(posedge aud_out_axi4s_aclk)
  begin
    axis_drop_sync <= {axis_drop_sync[0], axi_auddrop};
  end

  always @(posedge aud_out_axi4s_aclk)
  begin
    audio_stream_id_sync <= {audio_stream_id_sync[0], audio_stream_id};
  end


  always @(posedge av_axi_aclk)
  begin
    channel_status_ch0_latch_sync <= channel_status_ch0_latch;
    channel_status_ch1_latch_sync <= channel_status_ch1_latch;
ch0_sample_count_latch_sync <= ch0_sample_count_latch;
ch1_sample_count_latch_sync <= ch1_sample_count_latch;
aud_block_state_sync <= aud_block_state;

  end

 // SDP Generator

av_pat_gen_v2_0_1_sdp #(.PRIMARY_SDP(1))
av_pat_gen_v2_0_1_sdp_primary_i(
  // Clocks & Resets
  .av_axi_aclk                    (av_axi_aclk          ),
  .vid_out_axi4s_aclk             (vid_out_axi4s_aclk   ),
  .vid_out_axi4s_aresetn          (vid_out_axi4s_aresetn),
  // Registers / Payld / Ctrl     
  .sdp_data_reg                   (disp_sdp_data_regs),
  .sdp_ctrl_reg                   (disp_sdp_ctrl_regs),
  // Ports SDP Interface          
  .ext_sdp_req_o                  (ext_sdp01_req_o                ),
  .ext_sdp_data_o                 (ext_sdp01_data_o               ),
  .ext_sdp_ack_i                  (ext_sdp01_ack_i                ),
  .ext_sdp_vertical_blanking_i    (ext_sdp01_vertical_blanking_i  ),
  .ext_sdp_horizontal_blanking_i  (ext_sdp01_horizontal_blanking_i),
  .ext_sdp_line_cnt_mat_i         (ext_sdp01_line_cnt_mat_i       ));
  
  av_pat_gen_v2_0_1_sdp #(.PRIMARY_SDP(0)) 
  av_pat_gen_v2_0_1_sdp_secondary_i(
  // Clocks & Resets
  .av_axi_aclk                    (av_axi_aclk          ),
  .vid_out_axi4s_aclk             (vid_out_axi4s_aclk   ),
  .vid_out_axi4s_aresetn          (vid_out_axi4s_aresetn),
  // Registers / Payld / Ctrl     
  .sdp_data_reg                   (disp_sdp_data_regs),
  .sdp_ctrl_reg                   (disp_sdp_ctrl_regs),
  // Ports SDP Interface          
  .ext_sdp_req_o                  (ext_sdp00_req_o                ),
  .ext_sdp_data_o                 (ext_sdp00_data_o               ),
  .ext_sdp_ack_i                  (ext_sdp00_ack_i                ),
  .ext_sdp_vertical_blanking_i    (ext_sdp00_vertical_blanking_i  ),
  .ext_sdp_horizontal_blanking_i  (ext_sdp00_horizontal_blanking_i),
  .ext_sdp_line_cnt_mat_i         (ext_sdp00_line_cnt_mat_i       ));





endmodule

module pulse_clkcross_aud
(
  input  in_clk,
  input  in_pulse,
  input  out_clk,
  output out_pulse
);

reg rIn_PulseCap = 1'b0;
reg rIn_Toggle = 1'b0;

always @(posedge in_clk)
begin
  rIn_PulseCap <= in_pulse;
  
  if (in_pulse && !rIn_PulseCap)
    rIn_Toggle <= ~rIn_Toggle;
end

(* ASYNC_REG = "TRUE" *) reg [2:0] rOut_Sync = 3'b000;
reg       rOut_Pulse = 1'b0;

always @(posedge out_clk)
begin
  rOut_Sync  <= {rOut_Sync[1:0], rIn_Toggle};
  rOut_Pulse <= rOut_Sync[2] ^ rOut_Sync[1];
end

assign out_pulse = rOut_Pulse;
endmodule



`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/01/2024 04:01:41 PM
// Design Name: 
// Module Name: av_pat_gen_v2_0_1_sdp
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ps
`include "av_pat_gen_v2_0_1_defs.v"

  //CDC Defs
  `define XPM_CDC_SIM_ASSERT_CHK 0
  `define XPM_CDC_MTBF_FFS 3

module av_pat_gen_v2_0_1_sdp#( parameter integer PRIMARY_SDP = 1)(

    // Clocks & Resets
    input wire  av_axi_aclk,
    input wire  vid_out_axi4s_aclk,
    input wire  vid_out_axi4s_aresetn,
    
    // Registers / Payld / Ctrl 
    input wire [(`DISP_SDP_PYLD_SIZE-1):0] sdp_data_reg,
    input wire [(`DISP_SDP_CTRL_SIZE-1):0] sdp_ctrl_reg,

    // Ports SDP Interface
    output reg           ext_sdp_req_o,
    output reg [71 : 0]  ext_sdp_data_o,
    input wire           ext_sdp_ack_i,
    input wire           ext_sdp_vertical_blanking_i,
    input wire           ext_sdp_horizontal_blanking_i,
    input wire [1 : 0]   ext_sdp_line_cnt_mat_i

    );
    
/////// Local Params Declaration /////////////////////////////////

  localparam SDP_IDLE = 3'h0;
  localparam SDP_REQ  = 3'h1;
  localparam SDP_PYLD = 3'h2;
  localparam SDP_ACK  = 3'h3;
 
/////// Reg & Wire Declaration /////////////////////////////////
    
  wire [(`DISP_SDP_PYLD_SIZE-1):0] pyld;
  wire [(`DISP_SDP_CTRL_SIZE-1):0] ctrl;
  wire        one_shot_posedge;
  wire        line_cnt_mat;

  reg [2:0]    sdp_fsm   ;
  reg [2:0]    iter;
  reg [1:0]    one_shot_reg;
    
    
    
////////////////////////////////// Main /////////////////////////////////

    
// CDC to vid_out clk domain
    
    // CDC Module  
    xpm_cdc_array_single #(
       //.VERSION        (`XPM_CDC_VERSION       ),
       .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
       .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
       .WIDTH          (`DISP_SDP_PYLD_SIZE    ),
       .SRC_INPUT_REG  (1                      )) 
      sdp_pyld_regs_cdc_i (
       .src_clk         ( av_axi_aclk        ),
       .src_in          ( sdp_data_reg       ),
       .dest_clk        ( vid_out_axi4s_aclk ),
       .dest_out        ( pyld               ));
       
    // CDC Module  
    xpm_cdc_array_single #(
       //.VERSION        (`XPM_CDC_VERSION       ),
       .SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
       .DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
       .WIDTH          (`DISP_SDP_CTRL_SIZE    ),
       .SRC_INPUT_REG  (1                      )) 
      sdp_pyld_ctrl_cdc_i (
       .src_clk         ( av_axi_aclk        ),
       .src_in          ( sdp_ctrl_reg       ),
       .dest_clk        ( vid_out_axi4s_aclk ),
       .dest_out        ( ctrl               ));       


   // One Shot Pos Edge detection
    always @(posedge vid_out_axi4s_aclk) begin
      one_shot_reg<= {one_shot_reg[0],ctrl[`SDP_CTRL_ONE_SHOT] };
    end
 
   assign one_shot_posedge = ~one_shot_reg[1] && one_shot_reg[0];
   
   // Line Count match
   
   assign line_cnt_mat = (ctrl[`SDP_CTRL_LINE_MAT_AND] == 1'b1) ? &ext_sdp_line_cnt_mat_i : |ext_sdp_line_cnt_mat_i;
   

// Choose between Primary & Secondary SDP Interfaces

generate
  if ( PRIMARY_SDP == 1) begin : primary_sdp

  //SDP FSM Logic
  always @(posedge vid_out_axi4s_aclk or negedge vid_out_axi4s_aresetn) begin
     if(~vid_out_axi4s_aresetn) begin
        sdp_fsm                          <= SDP_IDLE;
        ext_sdp_data_o                   <= 72'b0;
        ext_sdp_req_o                    <= 1'b0;
        iter                             <= 3'b0;
     end 
     else begin
       case (sdp_fsm) 
         SDP_IDLE : begin
           sdp_fsm <=  (ctrl[`SDP_CTRL_ENABLE] && (ctrl[`SDP_CTRL_AUTO]|| one_shot_posedge)) ? SDP_REQ : SDP_IDLE ; 
           ext_sdp_data_o                   <= 72'b0;
           ext_sdp_req_o                    <= 1'b0;
           iter                             <= 3'b0;
         end
         SDP_REQ :begin
           if(((ctrl[`SDP_CTRL_HBLANK_TRIG] && ~ext_sdp_horizontal_blanking_i)  || (ctrl[`SDP_CTRL_VBLANK_TRIG] && ext_sdp_vertical_blanking_i)) && line_cnt_mat ) begin
             sdp_fsm                          <= SDP_PYLD ; 
             ext_sdp_data_o                   <= 72'b0;
             ext_sdp_req_o                    <= 1'b0;
           iter                               <= 3'b0;
           end
           else begin
             sdp_fsm                          <= SDP_REQ;
             ext_sdp_data_o                   <= 72'b0;
             ext_sdp_req_o                    <= 1'b0;
           iter                               <= 3'b0;
           end
         end 
         SDP_PYLD :begin
           if( (~ctrl[`SDP_CTRL_SEC_ENABLE] && iter == 3'h4) ||  (ctrl[`SDP_CTRL_SEC_ENABLE] && iter == 3'h2)) begin
             sdp_fsm                          <= SDP_ACK; 
             ext_sdp_data_o                   <= ext_sdp_data_o;
             ext_sdp_req_o                    <= ext_sdp_req_o;
             iter                             <= iter;
           end
           else begin
             sdp_fsm                          <= SDP_PYLD;
             if (ctrl[`SDP_CTRL_SEC_ENABLE]) begin
               ext_sdp_data_o                   <= (iter == 2'h0)? pyld[143:72] : ((iter == 2'h31)? pyld[287:216] : 'h0);
             end
             else begin
               ext_sdp_data_o                   <= (iter == 2'h0)? pyld[71:0] : ((iter == 2'h1)? pyld[143:72] : ((iter == 2'h2)? pyld[215:144] : ((iter == 2'h3)? pyld[287:216] : 'h0)));
             end  
             ext_sdp_req_o                    <= 1'b1;
             iter                             <= iter + 1'b1;
           end
         end   
         SDP_ACK :begin
           if(ext_sdp_ack_i) begin
             sdp_fsm                          <= SDP_IDLE; 
             ext_sdp_data_o                   <= 72'b0;
             ext_sdp_req_o                    <= 1'b0;
             iter                             <= 3'b0;
           end
           else begin
             sdp_fsm                          <= SDP_ACK;
             ext_sdp_data_o                   <= ext_sdp_data_o;
             ext_sdp_req_o                    <= ext_sdp_req_o;
             iter                             <= iter;
           end
         end   
         default : begin
           sdp_fsm                          <= SDP_IDLE;
           ext_sdp_data_o                   <= 72'b0;
           ext_sdp_req_o                    <= 1'b0;
           iter                             <= 2'b0;
         end
       endcase
     end
   end
   
  end 
  else begin : secondary_sdp    // generate
  
    //SDP FSM Logic
  always @(posedge vid_out_axi4s_aclk or negedge vid_out_axi4s_aresetn) begin
     if(~vid_out_axi4s_aresetn) begin
        sdp_fsm                          <= SDP_IDLE;
        ext_sdp_data_o                   <= 72'b0;
        ext_sdp_req_o                    <= 1'b0;
        iter                             <= 3'b0;
     end 
     else begin
       case (sdp_fsm) 
         SDP_IDLE : begin
           sdp_fsm <=  (ctrl[`SDP_CTRL_ENABLE] && ctrl[`SDP_CTRL_SEC_ENABLE] && (ctrl[`SDP_CTRL_AUTO]|| one_shot_posedge)) ? SDP_REQ : SDP_IDLE ; 
           ext_sdp_data_o                   <= 72'b0;
           ext_sdp_req_o                    <= 1'b0;
           iter                             <= 3'b0;
         end
         SDP_REQ :begin
           if(((ctrl[`SDP_CTRL_HBLANK_TRIG] && ~ext_sdp_horizontal_blanking_i)  || (ctrl[`SDP_CTRL_VBLANK_TRIG] && ext_sdp_vertical_blanking_i)) && line_cnt_mat ) begin
             sdp_fsm                          <= SDP_PYLD ; 
             ext_sdp_data_o                   <= 72'b0;
             ext_sdp_req_o                    <= 1'b0;
           iter                               <= 3'b0;
           end
           else begin
             sdp_fsm                          <= SDP_REQ;
             ext_sdp_data_o                   <= 72'b0;
             ext_sdp_req_o                    <= 1'b0;
           iter                               <= 3'b0;
           end
         end 
         SDP_PYLD :begin
           if(iter == 3'h2) begin
             sdp_fsm                          <= SDP_ACK; 
             ext_sdp_data_o                   <= ext_sdp_data_o;
             ext_sdp_req_o                    <= ext_sdp_req_o;
             iter                             <= iter;
           end
           else begin
             sdp_fsm                          <= SDP_PYLD;
             ext_sdp_data_o                   <= (iter == 2'h0)? pyld[71:0] : ((iter == 2'h1)? pyld[215:144] : 'h0);
             ext_sdp_req_o                    <= 1'b1;
             iter                             <= iter + 1'b1;
           end
         end   
         SDP_ACK :begin
           if(ext_sdp_ack_i) begin
             sdp_fsm                          <= SDP_IDLE; 
             ext_sdp_data_o                   <= 72'b0;
             ext_sdp_req_o                    <= 1'b0;
             iter                             <= 3'b0;
           end
           else begin
             sdp_fsm                          <= SDP_ACK;
             ext_sdp_data_o                   <= ext_sdp_data_o;
             ext_sdp_req_o                    <= ext_sdp_req_o;
             iter                             <= iter;
           end
         end   
         default : begin
           sdp_fsm                          <= SDP_IDLE;
           ext_sdp_data_o                   <= 72'b0;
           ext_sdp_req_o                    <= 1'b0;
           iter                             <= 2'b0;
         end
       endcase
     end
   end
  
  end 
  endgenerate

endmodule

