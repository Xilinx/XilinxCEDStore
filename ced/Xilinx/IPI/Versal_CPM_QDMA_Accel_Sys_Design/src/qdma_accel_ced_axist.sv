//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//-----------------------------------------------------------------------------
//
// Project    : CPM5-QDMA based Acceleration system design 
// File       : qdma_accel_ced_axist.sv
// Version    : 1.0
// Description: Following are the functionalities impelemnted in this module. 
//	1. Store H2C data into an AXI-Stream FIFO
//	2. Count the number of bytes received on H2C interface
//	3. For every 4K transfer before Tlast is asserted, fetch a descriptor
//		a. Fetch a descriptor for last few bytes after the last descriptor fetch. This could happen after detecting Tlast on H2C transfer. 
//	4. After H2C transfer is finished,  
//		a. Initiate C2H transfer. Drive rd_en of the H2C_ST fifo after assertion of Tlast on H2C_ST and confirming the availability of 
//		   descriptors for C2H transfer. 
//		b. Initiate Completion packet based on H2C transfer size. Take the pkt size from byte count module. 
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

module qdma_accel_ced_axist
  #( 
     parameter C_DATA_WIDTH      = 512,   // 64, 128, 256, or 512 bit only
     parameter QID_MAX           = 64,    // Number of QID currently enabled in the design. Host may choose to enable less Queue to enable at runtime
     parameter QID_WIDTH         = 12,    // Must be 12. Queue ID bit width
     parameter TM_DSC_BITS       = 16,    // Traffic Manager descriptor credit bit width
     parameter CRC_WIDTH         = 32,    // C2H CRC width
     parameter C_CNTR_WIDTH      = 32     // Counter bit width
     )
   (
    input user_reset_n,
    input user_clk,

    input  [31:0] control_reg_c2h,
    input  [31:0] control_reg_c2h2,
    input clr_h2c_match,
    input  [10:0] c2h_num_pkt,
    input  [31:0] cmpt_size,
    input  [255:0] wb_dat,
    input  logic [C_DATA_WIDTH-1 :0]     m_axis_h2c_tdata /* synthesis syn_keep = 1 */,
    //input  logic [C_DATA_WIDTH/8-1 :0]   m_axis_h2c_dpar /* synthesis syn_keep = 1 */,
    input  logic                         m_axis_h2c_tvalid /* synthesis syn_keep = 1 */,
    output logic                         m_axis_h2c_tready /* synthesis syn_keep = 1 */,
    input  logic                         m_axis_h2c_tlast /* synthesis syn_keep = 1 */,
    input  logic [QID_WIDTH-1:0]         m_axis_h2c_tuser_qid /* synthesis syn_keep = 1 */,
    input  logic [2:0]                   m_axis_h2c_tuser_port_id /* synthesis syn_keep = 1 */,
    input  logic                         m_axis_h2c_tuser_err /* synthesis syn_keep = 1 */,
    input  logic [31:0]                  m_axis_h2c_tuser_mdata /* synthesis syn_keep = 1 */,
    input  logic [5:0]                   m_axis_h2c_tuser_mty /* synthesis syn_keep = 1 */,
    input  logic                         m_axis_h2c_tuser_zero_byte /* synthesis syn_keep = 1 */,
    
    output logic [C_DATA_WIDTH-1 :0]     s_axis_c2h_tdata /* synthesis syn_keep = 1 */,  
    //output logic [C_DATA_WIDTH/8-1 :0]   s_axis_c2h_dpar /* synthesis syn_keep = 1 */,  
    output logic                         s_axis_c2h_ctrl_marker /* synthesis syn_keep = 1 */,
    output logic [15:0]                  s_axis_c2h_ctrl_len /* synthesis syn_keep = 1 */,
    output logic [QID_WIDTH-1:0]         s_axis_c2h_ctrl_qid /* synthesis syn_keep = 1 */,
    //output logic                         s_axis_c2h_ctrl_user_trig /* synthesis syn_keep = 1 */,
    output logic                         s_axis_c2h_ctrl_dis_cmpt /* synthesis syn_keep = 1 */,
    //output logic                         s_axis_c2h_ctrl_imm_data /* synthesis syn_keep = 1 */,
    output logic [6:0]                   s_axis_c2h_ctrl_ecc /* synthesis syn_keep = 1 */,
    output logic                         s_axis_c2h_tvalid /* synthesis syn_keep = 1 */,
    input  logic                         s_axis_c2h_tready /* synthesis syn_keep = 1 */,
    output logic                         s_axis_c2h_tlast /* synthesis syn_keep = 1 */,
    output logic [5:0]                   s_axis_c2h_mty /* synthesis syn_keep = 1 */,
    output logic [CRC_WIDTH-1:0]         s_axis_c2h_tcrc /* synthesis syn_keep = 1 */,
    output logic [C_DATA_WIDTH-1:0]      s_axis_c2h_cmpt_tdata,
    output logic [1:0]                   s_axis_c2h_cmpt_size,
    output logic [15:0]                  s_axis_c2h_cmpt_dpar,
    output logic                         s_axis_c2h_cmpt_tvalid,
    output logic                         s_axis_c2h_cmpt_tlast,
    input  logic                         s_axis_c2h_cmpt_tready,
    output logic [12:0]                  s_axis_c2h_cmpt_ctrl_qid,
    output logic [1:0]                   s_axis_c2h_cmpt_ctrl_cmpt_type,
    output logic [15:0]                  s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id,
    output logic [2:0]                   s_axis_c2h_cmpt_ctrl_port_id,
    output logic                         s_axis_c2h_cmpt_ctrl_marker,
    output logic                         s_axis_c2h_cmpt_ctrl_user_trig,
    output logic [2:0]                   s_axis_c2h_cmpt_ctrl_col_idx,
    output logic [2:0]                   s_axis_c2h_cmpt_ctrl_err_idx,
    output logic 		                 s_axis_c2h_cmpt_ctrl_no_wrb_marker,	
	
	output logic            			 dsc_crdt_in_vld,
    input  logic            			 dsc_crdt_in_rdy,
    output logic            			 dsc_crdt_in_dir, //C2H
    output logic            			 dsc_crdt_in_fence, //not coalesced
    output logic  [QID_WIDTH-1:0]   	 dsc_crdt_in_qid,
    output logic  [15:0]    			 dsc_crdt_in_crdt,
	
	output logic 						 c2h_sop,
	input logic  [1:0]					 c2h_dsc_byp_mode //00 = Internal, 01 = csh_byp , 10 = Simple bypass
    
    );
	
	localparam H2C_FIFO_TUSER_WIDTH = 22; //12 + 3 + 1 + 6 ; 
	
	logic  			              c2h_fifo_is_full;
    (* MARK_DEBUG="true" *) logic                         wb_is_full;
    (* MARK_DEBUG="true" *) logic                         cmpt_sent;
    (* MARK_DEBUG="true" *) logic 			              c2h_formed;
    (* MARK_DEBUG="true" *) logic 			              c2h_formed_to_cmpt;

    logic [QID_WIDTH-1:0]         qid_wb;          // QID to send. If credit_in == 0, send a packet to random ID, else takes the valid QID input
    logic [15:0]                  btt_wb;          // C2H Length to send in Writeback. It must match with the Length of the C2H transfer this Writeback is attached to
    logic                         marker_wb;       // C2H packet for this CMPT is a marker packet
	
	(* MARK_DEBUG="true" *) logic [15:0] 				byte_cnt_h2c;
	(* MARK_DEBUG="true" *) logic [15:0] 				byte_cnt_h2c_0;
	(* MARK_DEBUG="true" *) logic [15:0] 				byte_cnt_h2c_1;
	(* MARK_DEBUG="true" *) logic [15:0] 				byte_cnt_h2c_2;
	(* MARK_DEBUG="true" *) logic [15:0] 				byte_cnt_h2c_3;
	(* MARK_DEBUG="true" *) logic [15:0] 				byte_cnt_h2c_4;
	(* MARK_DEBUG="true" *) logic [15:0] 				byte_cnt_h2c_5;
	(* MARK_DEBUG="true" *) logic [15:0] 				byte_cnt_h2c_6;
	(* MARK_DEBUG="true" *) logic [15:0] 				byte_cnt_h2c_7;
	(* MARK_DEBUG="true" *) logic [15:0] 				byte_cnt_c2h_pkt;
	(* MARK_DEBUG="true" *) logic [7:0]	 				h2c_2_c2h_color;//setting of 1'b1 means H2C packet is in the FIFO, pkt length is captured, pkt is not yet sent on C2H. 

	
	
	logic [14:0] 				pkt_cnt_h2c;
	logic [14:0] 				pkt_cnt_c2h;
	
	(* MARK_DEBUG="true" *) logic		h2c_tready;				
	(* MARK_DEBUG="true" *) logic		h2c_tvalid;				
	(* MARK_DEBUG="true" *) logic		h2c_tlast;				
	logic								h2c_err;				
	(* MARK_DEBUG="true" *) logic	[H2C_FIFO_TUSER_WIDTH-1:0]	h2c_tuser;				
	logic 	[C_DATA_WIDTH-1 :0]			h2c_tdata;	
	
	(* MARK_DEBUG="true" *) logic		c2h_tready;				
	(* MARK_DEBUG="true" *) logic		c2h_tvalid;				
	(* MARK_DEBUG="true" *) logic		c2h_tlast;				
	(* MARK_DEBUG="true" *) logic	[H2C_FIFO_TUSER_WIDTH-1:0]	c2h_tuser;				
	logic 	[C_DATA_WIDTH-1 :0] 		c2h_tdata;
	(* MARK_DEBUG="true" *) logic 		[15:0]			byte_cnt_c2h;
	(* MARK_DEBUG="true" *) logic 		[15:0]			byte_cnt_c2h_cmpt;
	(* MARK_DEBUG="true" *) logic 		[2:0]			h2c_pkt_id;
	(* MARK_DEBUG="true" *) logic 		[2:0]			c2h_pkt_id;
	(* MARK_DEBUG="true" *) logic      			 		h2c_non_zero_pkt_rcvd;   
	(* MARK_DEBUG="true" *) logic [QID_WIDTH-1:0] 		c2h_qid;
	(* MARK_DEBUG="true" *) logic [QID_WIDTH-1:0] 		c2h_cmpt_qid;
	(* MARK_DEBUG="true" *) logic  						gen_dsc_fetch_h2c;
	(* MARK_DEBUG="true" *) logic  						h2c_sop;
	(* MARK_DEBUG="true" *) logic  						h2c_eop;
	(* MARK_DEBUG="true" *) logic  						c2h_eop;
	(* MARK_DEBUG="true" *) logic  						c2h_sop_fifo;
	(* MARK_DEBUG="true" *) logic  						h2c_tready_to_qdma;
	(* MARK_DEBUG="true" *) logic  						h2c_pkt_in_fifo;//Assert this when atleast one full packet is available in H2C FIFO.
	
	integer qid;

	assign h2c_sop = (h2c_eop & h2c_tvalid & m_axis_h2c_tready) ? 1'b1 : 1'b0;	
	
	always @(posedge user_clk) begin
		if (~user_reset_n)
			h2c_eop	<= 1'b1;//set to 1'b1 to assert h2c_sop for the first h2c packet.
		else if(h2c_tlast & h2c_tvalid & m_axis_h2c_tready)		
			h2c_eop <= 1'b1;
		else if(h2c_sop)
			h2c_eop	<= 1'b0;
		else
			h2c_eop <= h2c_eop;
	end
	
	assign c2h_eop = c2h_tlast & c2h_tvalid & c2h_tready;
	
	always @(posedge user_clk) begin
		if (~user_reset_n) 
			h2c_pkt_id	<= 3'h0;
		else if(h2c_tlast & h2c_tvalid & m_axis_h2c_tready)		
			h2c_pkt_id <= h2c_pkt_id + 1'b1;
		else
			h2c_pkt_id <= h2c_pkt_id;
	end	
	
	always @(posedge user_clk) begin
      if (~user_reset_n) 
		byte_cnt_h2c 		  <= 16'h0;		
	  else 
	  begin
		if(m_axis_h2c_tready && h2c_tvalid) 
		begin
			if(h2c_tlast)
				//byte_cnt_h2c 	 	  <= byte_cnt_h2c + (C_DATA_WIDTH/8) - m_axis_h2c_tuser_mty;//byte count stored = pkt size (in bytes)
				byte_cnt_h2c 	 	  <= 16'h0;
			else
				byte_cnt_h2c 		  <= byte_cnt_h2c + (C_DATA_WIDTH/8);	
		end
		else
			byte_cnt_h2c	<= byte_cnt_h2c;
	  end
	end
	//h2c_pkt_id is incremented on assertion of h2c_tlast of every packet
	//h2c_eop is asserted one cycle after h2c_tlast assertion and keeps asserted until the start of the next packet. 
	//on assertionof h2c_eop, byte_cnt_h2c is ready with the size of the packet stored in H2c FIFO. 
	//If h2c_2_c2h_color[h2c_pkt_id] is set to 1'b1 then it means all C2H has throttled for 8 packets. 
	//c2h_eop is asserted in the same cycle as c2h_tlast. on assertion of c2h_eop, h2c_2_c2h_color[c2h_pkt_id] is set to 1'b0
	
	always @(posedge user_clk) begin
      if (~user_reset_n) 
		h2c_tready_to_qdma	  <= 1'b1;
	  else if (h2c_eop & h2c_2_c2h_color[h2c_pkt_id])
		h2c_tready_to_qdma <= 1'b0;
	  else
		h2c_tready_to_qdma <= 1'b1;
	end
	
	always @(posedge user_clk) begin
      if (~user_reset_n) 
		begin			
			byte_cnt_h2c_0 		  <= 16'h0;	
			byte_cnt_h2c_1 		  <= 16'h0;	
			byte_cnt_h2c_2 		  <= 16'h0;	
			byte_cnt_h2c_3 		  <= 16'h0;	
			byte_cnt_h2c_4 		  <= 16'h0;	
			byte_cnt_h2c_5 		  <= 16'h0;	
			byte_cnt_h2c_6 		  <= 16'h0;	
			byte_cnt_h2c_7 		  <= 16'h0;	
		end else if(h2c_tlast & h2c_tvalid & m_axis_h2c_tready) begin
			case(h2c_pkt_id)
				3'h0: byte_cnt_h2c_0 <= byte_cnt_h2c + (C_DATA_WIDTH/8) - m_axis_h2c_tuser_mty;
				3'h1: byte_cnt_h2c_1 <= byte_cnt_h2c + (C_DATA_WIDTH/8) - m_axis_h2c_tuser_mty;
				3'h2: byte_cnt_h2c_2 <= byte_cnt_h2c + (C_DATA_WIDTH/8) - m_axis_h2c_tuser_mty;
				3'h3: byte_cnt_h2c_3 <= byte_cnt_h2c + (C_DATA_WIDTH/8) - m_axis_h2c_tuser_mty;
				3'h4: byte_cnt_h2c_4 <= byte_cnt_h2c + (C_DATA_WIDTH/8) - m_axis_h2c_tuser_mty;
				3'h5: byte_cnt_h2c_5 <= byte_cnt_h2c + (C_DATA_WIDTH/8) - m_axis_h2c_tuser_mty;
				3'h6: byte_cnt_h2c_6 <= byte_cnt_h2c + (C_DATA_WIDTH/8) - m_axis_h2c_tuser_mty;
				3'h7: byte_cnt_h2c_7 <= byte_cnt_h2c + (C_DATA_WIDTH/8) - m_axis_h2c_tuser_mty;
				default: begin
					byte_cnt_h2c_0 		  <= 16'h0;	
					byte_cnt_h2c_1 		  <= 16'h0;	
					byte_cnt_h2c_2 		  <= 16'h0;	
					byte_cnt_h2c_3 		  <= 16'h0;	
					byte_cnt_h2c_4 		  <= 16'h0;	
					byte_cnt_h2c_5 		  <= 16'h0;	
					byte_cnt_h2c_6 		  <= 16'h0;	
					byte_cnt_h2c_7 		  <= 16'h0;	
				end
			endcase
		end
	end	
	
	int i;
	always @(posedge user_clk) begin
      if (~user_reset_n) 		
		h2c_2_c2h_color	 	  <= 8'h0;				
	  else begin
		if (h2c_tlast & h2c_tvalid & m_axis_h2c_tready) begin
			for(i=0;i<8;i=i+1) begin
				if(i==h2c_pkt_id)
					h2c_2_c2h_color[h2c_pkt_id] <= 1'b1;
			end
	    end
	   	else if(c2h_eop) begin
			for(i=0;i<8;i=i+1) begin
				if(i==c2h_pkt_id)
					h2c_2_c2h_color[c2h_pkt_id] <= 1'b0;
			end
		end
		else			
			h2c_2_c2h_color	 	  <= h2c_2_c2h_color;	
	  end
    end	  

	always @(posedge user_clk) begin
      if (~user_reset_n) 
		h2c_pkt_in_fifo	<= 1'b0;
	  else begin
		if(|h2c_2_c2h_color)
			h2c_pkt_in_fifo	<= 1'b1;
		else
			h2c_pkt_in_fifo	<= 1'b0;	  
	  end	  
	end
		
	
	
	always @(posedge user_clk) begin
      if (~user_reset_n | c2h_sop) 
		byte_cnt_c2h_pkt <= 15'h0;
	  else begin
		if(s_axis_c2h_tready && s_axis_c2h_tvalid) begin
			if(s_axis_c2h_tlast)
				byte_cnt_c2h_pkt <= byte_cnt_c2h_pkt + C_DATA_WIDTH/8 - s_axis_c2h_mty;
			else
				byte_cnt_c2h_pkt <= byte_cnt_c2h_pkt + C_DATA_WIDTH/8;
		end	else
			byte_cnt_c2h_pkt <= byte_cnt_c2h_pkt;
		end
	end	

   
    // CRC Generator for C2H data bus
   crc32_gen #(
     .MAX_DATA_WIDTH   ( C_DATA_WIDTH      ),
     .CRC_WIDTH        (  CRC_WIDTH        ),
     .TCQ              ( 1                 )
   ) crc32_gen_i (
     // Clock and Resetd
     .clk              ( user_clk          ),
     .rst_n            ( user_reset_n      ),
     .in_par_err       ( 1'b0              ),
     .in_misc_err      ( 1'b0              ),
     .in_crc_dis       ( 1'b0              ),

     .in_data          ( s_axis_c2h_tdata  ),
     .in_vld           ( s_axis_c2h_tvalid & s_axis_c2h_tready ),
     .in_tlast         ( s_axis_c2h_tlast  ),
     .in_mty           ( s_axis_c2h_mty    ),
     .out_crc          ( s_axis_c2h_tcrc   )
   );
   
   // Parity Generator for C2H data bus
   assign s_axis_c2h_ctrl_ecc 	 	= 7'h0; // To be added
   assign s_axis_c2h_ctrl_marker 	= 1'b0; // To be added
   assign s_axis_c2h_ctrl_dis_cmpt 	= 1'b0; // To be added
   assign s_axis_c2h_ctrl_len 	 	= byte_cnt_c2h; 
   assign s_axis_c2h_ctrl_qid 	 	= c2h_qid; 
   assign s_axis_c2h_cmpt_ctrl_no_wrb_marker 	= 1'b0; 
   
   /*
   generate
   begin
     genvar pa;
     for (pa=0; pa < (C_DATA_WIDTH/8); pa = pa + 1) // Parity needs to be computed for every byte of data
     begin : parity_assign
       assign s_axis_c2h_dpar[pa] = !( ^ s_axis_c2h_tdata [8*(pa+1)-1:8*pa] );
     end
   end
   endgenerate
   */  
	   
	  
    assign s_axis_c2h_tvalid 				= 	c2h_tvalid & c2h_tready;
    assign s_axis_c2h_tlast					=	c2h_tlast;
    assign s_axis_c2h_mty					=	c2h_tuser[5:0];
    assign s_axis_c2h_tdata					=	c2h_tdata;
    assign c2h_tready						=	s_axis_c2h_tready & h2c_pkt_in_fifo;
    assign c2h_sop							=	c2h_sop_fifo;
    assign c2h_sop_fifo						=	c2h_tuser[6] & c2h_tready;
    assign c2h_pkt_id						=	c2h_tuser[9:7];
	//When c2h_sop is asserted, Take byte cnt of the c2h packet based on the c2h_pkt_id received from c2h_tuser port. This logic is expected to assert 
	//the signals on the same cycle as c2h_sop is asserted so the logic is written as combinatorial logic. 
	always @(*) 
	begin
		if(~user_reset_n)
			begin
				c2h_qid				= {QID_WIDTH {1'b0}};	
				byte_cnt_c2h		= 16'h0;
			end
		else begin		
			if(c2h_sop) begin
				c2h_qid		= c2h_tuser[21:10];
				case(c2h_pkt_id) 
					3'h0: byte_cnt_c2h	= byte_cnt_h2c_0;
					3'h1: byte_cnt_c2h	= byte_cnt_h2c_1;
					3'h2: byte_cnt_c2h	= byte_cnt_h2c_2;
					3'h3: byte_cnt_c2h	= byte_cnt_h2c_3;
					3'h4: byte_cnt_c2h	= byte_cnt_h2c_4;
					3'h5: byte_cnt_c2h	= byte_cnt_h2c_5;
					3'h6: byte_cnt_c2h	= byte_cnt_h2c_6;
					3'h7: byte_cnt_c2h	= byte_cnt_h2c_7;
				endcase
			end
			else 
				begin
					c2h_qid			= c2h_qid;
					byte_cnt_c2h	= byte_cnt_c2h;
				end
		end
	end
	
	assign h2c_tdata			= m_axis_h2c_tdata;
	assign h2c_tlast			= m_axis_h2c_tlast;
	assign h2c_err				= m_axis_h2c_tuser_err;
	assign h2c_tvalid			= (h2c_non_zero_pkt_rcvd & h2c_tready_to_qdma) ? m_axis_h2c_tvalid : 1'b0;
	assign h2c_tuser			= {m_axis_h2c_tuser_qid,h2c_pkt_id,h2c_sop,m_axis_h2c_tuser_mty};//tuser_width = 12 + 3 + 1 + 6 = 22
	assign m_axis_h2c_tready	= h2c_tready & h2c_tready_to_qdma;	 
   
  
	qdma_accel_ced_axist_h2c_2_c2h  #(
	.BYTE_CREDIT(4096),                 // Must be power of 2. Example design driver always issues 4KB descriptor, so we're limiting it to 4KB per credit.
	.DATA_WIDTH (C_DATA_WIDTH),                   // 64, 128, 256, or 512 bit only
	.QID_WIDTH  (QID_WIDTH),                   // Must be 11. Queue ID bit width 
	.TUSER_WIDTH  (H2C_FIFO_TUSER_WIDTH),                   // Must be 16. 16-bit is the maximum length the interface can handle.  
	.TCQ        (1)
	) qdma_accel_ced_axist_h2c_2_c2h_inst (
	// Global
	.user_clk		(user_clk),
	.user_reset_n	(user_reset_n),
	
	// Control Signals
	.knob			(knob),             // [0] = Start transfer immediately. [1] = Stop transfer immediately. [2] = Enable DROP test. [3] = Random BTT. [4] = Send Marker
													// [31:21] = Number of QID to use in DROP case.
	
	.h2c_tready		(h2c_tready),
	.h2c_tvalid		(h2c_tvalid), //Do not store zero byte packets
	.h2c_err		(h2c_err), 
	.h2c_tlast		(h2c_tlast),
	.h2c_tuser  	(h2c_tuser),
	.h2c_tdata		(h2c_tdata),
	
	.wb_is_full	(wb_is_full),       // CMPT Bus FIFO is full
	
	// QDMA C2H Bus
	.c2h_tdata			(c2h_tdata),
	.c2h_tlast			(c2h_tlast),
	.c2h_tvalid			(c2h_tvalid),  // Do not wait for c2h_tready before asserting c2h_tvalid
	.c2h_tready			(c2h_tready),
	.c2h_tuser			(c2h_tuser),
	
	.c2h_formed     	(c2h_formed),
	.c2h_fifo_is_full   (c2h_fifo_is_full)
	
	);
	
	//c2h_formed (valid) & cmpt_sent (ready) counts as one completion. so, c2h_formed should be high until cmpt_sent is pulsed.
	always @(posedge user_clk) begin
      if (~user_reset_n) begin 
		c2h_formed_to_cmpt <= 1'b0;
		byte_cnt_c2h_cmpt  <= 16'b0;
		c2h_cmpt_qid  	   <= 16'b0;
	  end
	  else begin
		if(c2h_formed) 
			begin
				c2h_formed_to_cmpt	<= 1'b1;
				byte_cnt_c2h_cmpt	<= byte_cnt_c2h;
				c2h_cmpt_qid		<= c2h_qid;
			end
		else if (c2h_formed_to_cmpt & ~cmpt_sent)
			begin
				c2h_formed_to_cmpt	<= c2h_formed_to_cmpt;
				byte_cnt_c2h_cmpt	<= byte_cnt_c2h_cmpt;
				c2h_cmpt_qid		<= c2h_cmpt_qid;
			end
		else
			begin 
				c2h_formed_to_cmpt <= 1'b0;
				byte_cnt_c2h_cmpt  <= 16'b0;
				c2h_cmpt_qid  	   <= 16'b0;
			end
	  end
	end
		

	
	ST_c2h_cmpt #(
    .DATA_WIDTH             ( C_DATA_WIDTH           ),
    .LEN_WIDTH              ( 16                     ),
    //.QID_WIDTH              ( QID_WIDTH              ),
    .TCQ                    ( 1                      )
  ) ST_c2h_cmpt_0 (
    .user_clk               ( user_clk               ),
    .user_reset_n           ( user_reset_n           ),
    
    .knob                   ( {30'b0, control_reg_c2h[21], 1'b1} ),
    .wb_dat                 ( wb_dat                 ),
    
    .c2h_formed             ( c2h_formed_to_cmpt ),
    .cmpt_size              ( cmpt_size              ),
    .qid_wb                 ( c2h_cmpt_qid            ),
    .btt_wb                 ( byte_cnt_c2h_cmpt      ),
    .marker_wb              ( 1'b0              ),
    .c2h_fifo_is_full       ( c2h_fifo_is_full ),
    .wb_is_full             ( wb_is_full             ),
    .cmpt_sent              ( cmpt_sent              ),
    
    .s_axis_c2h_cmpt_tdata  ( s_axis_c2h_cmpt_tdata  ),
    .s_axis_c2h_cmpt_size   ( s_axis_c2h_cmpt_size   ),
    .s_axis_c2h_cmpt_dpar   ( s_axis_c2h_cmpt_dpar   ),
    .s_axis_c2h_cmpt_tvalid ( s_axis_c2h_cmpt_tvalid ),
    .s_axis_c2h_cmpt_tlast  ( s_axis_c2h_cmpt_tlast  ),
    .s_axis_c2h_cmpt_tready ( s_axis_c2h_cmpt_tready ),
    
    .s_axis_c2h_cmpt_ctrl_qid             ( s_axis_c2h_cmpt_ctrl_qid             ),
    .s_axis_c2h_cmpt_ctrl_cmpt_type       ( s_axis_c2h_cmpt_ctrl_cmpt_type       ),
    .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ( s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
    .s_axis_c2h_cmpt_ctrl_port_id         ( s_axis_c2h_cmpt_ctrl_port_id         ),
    .s_axis_c2h_cmpt_ctrl_marker          ( s_axis_c2h_cmpt_ctrl_marker          ),
    .s_axis_c2h_cmpt_ctrl_user_trig       ( s_axis_c2h_cmpt_ctrl_user_trig       ),
    .s_axis_c2h_cmpt_ctrl_col_idx         ( s_axis_c2h_cmpt_ctrl_col_idx         ),
    .s_axis_c2h_cmpt_ctrl_err_idx         ( s_axis_c2h_cmpt_ctrl_err_idx         )
  );		

	
	assign h2c_non_zero_pkt_rcvd = m_axis_h2c_tvalid && m_axis_h2c_tready && ~m_axis_h2c_tuser_zero_byte;

	always @(posedge user_clk) begin
      if (~user_reset_n) 
		begin
			pkt_cnt_h2c <= 15'h0;
			pkt_cnt_c2h <= 15'h0;
		end
	   else
		begin
			if(h2c_non_zero_pkt_rcvd & h2c_tlast)
				pkt_cnt_h2c <= pkt_cnt_h2c + 1'b1;
			else
				pkt_cnt_h2c <= pkt_cnt_h2c;
			if(c2h_formed)
				pkt_cnt_c2h <= pkt_cnt_c2h + 1'b1;
			else
				pkt_cnt_c2h <= pkt_cnt_c2h;
		end
	end
	
	//Logic to drive descriptor credit interface ports
	
	always @(posedge user_clk) begin
      if (~user_reset_n) 
		begin
			dsc_crdt_in_vld 	<= 1'b0;
			dsc_crdt_in_dir		<= 1'b1;
			dsc_crdt_in_fence	<= 1'b0;
			dsc_crdt_in_qid		<= {QID_WIDTH{1'b0}};
			dsc_crdt_in_crdt	<= 16'h0;
		end
	  else
		begin
			if(gen_dsc_fetch_h2c & (c2h_dsc_byp_mode == 2'b10))
				begin
					dsc_crdt_in_vld 	<= gen_dsc_fetch_h2c && ~dsc_crdt_in_rdy;
	                dsc_crdt_in_qid		<= m_axis_h2c_tuser_qid;
					if(!byte_cnt_h2c [12])
						dsc_crdt_in_crdt	<= 1'b1;
					else
						dsc_crdt_in_crdt	<= byte_cnt_h2c[15:12] + |byte_cnt_h2c[11:0];
				end
			else
				begin
					dsc_crdt_in_vld 	<= 1'b0;
		            dsc_crdt_in_dir		<= dsc_crdt_in_dir;
	                dsc_crdt_in_fence	<= dsc_crdt_in_fence;
	                dsc_crdt_in_qid		<= dsc_crdt_in_qid;
					dsc_crdt_in_crdt	<= dsc_crdt_in_crdt;
				end
		 end
	end
	
	always @(posedge user_clk) begin
      if (~user_reset_n)
		begin
			gen_dsc_fetch_h2c <= 1'b0;
		end
	  else 
		begin
			if(h2c_tlast & h2c_non_zero_pkt_rcvd)	
				gen_dsc_fetch_h2c	 <= 1'b1;
			else if (gen_dsc_fetch_h2c & dsc_crdt_in_vld & dsc_crdt_in_rdy)				
				gen_dsc_fetch_h2c	 <= 1'b0;
			else
				gen_dsc_fetch_h2c	 <= gen_dsc_fetch_h2c;
		end
	end
	
endmodule