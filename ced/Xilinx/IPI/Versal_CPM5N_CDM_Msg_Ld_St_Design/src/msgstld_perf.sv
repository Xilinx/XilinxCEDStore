`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Advanced Micro Devices
// Engineer: Srinadh Utukuru
// 
// Create Date: 
// Design Name: 
// Module Name: msgstld_perf
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This Module analyzes the MSGST/MSGLD packets sent and generates counts for busy, idle, active duration. 
//				Busy -- rdy is LOW and vld is HIGH
// 				Idle -- rdy is HIGH and vld is LOW
//				active -- rdy is HIGH and vld is HIGH
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module msgstld_perf #
(
	// Width of S_AXI data bus
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	// Width of S_AXI address bus
	parameter integer C_S_AXI_ADDR_WIDTH	= 10
)
(
	 // MSGST adapter CDM interface
	input											cdm_top_msgst_tready,
	input											cdm_top_msgst_tvalid,
	input											cdm_top_msgst_eop,
	// MSGLD/MSGST Response interface	
	input 											cdm_top_msgld_dat_tready,
	input 											cdm_top_msgld_dat_tvalid,
	input								 			cdm_top_msgld_dat_eop,
	input [11:0]									cdm_top_msgld_dat_response_cookie,
	input [255:0]									cdm_top_msgld_dat_data,
	input [2:0]										cdm_top_msgld_dat_err_status,
	input								 			cdm_top_msgld_dat_error,
	input [1:0]										cdm_top_msgld_dat_status,
		
    // MSGLD Request interface		
    input								 			cdm_top_msgld_req_tready,	
	input								 			cdm_top_msgld_req_tvalid,
			
	//axi4lite interface//// 		
	input  wire                             		axi_aclk,
	input  wire                             		axi_aresetn,
		
	input  wire  [C_S_AXI_ADDR_WIDTH-1:0]   		axi_awaddr,
	output wire                             		axi_awready,
	input  wire                             		axi_awvalid,
	
	input  wire  [C_S_AXI_DATA_WIDTH-1:0]   		axi_wdata,
	input  wire  [(C_S_AXI_DATA_WIDTH/8)-1 : 0]     axi_wstrb,
	output wire                             		axi_wready,
	input  wire                             		axi_wvalid,

	output wire  [1:0]           					axi_bresp,
	input  wire                             		axi_bready,
	output reg                              		axi_bvalid,
		
	input  wire  [C_S_AXI_ADDR_WIDTH-1:0]   		axi_araddr,
	output wire                             		axi_arready,
	input  wire                             		axi_arvalid,

	output reg   [C_S_AXI_DATA_WIDTH-1:0]           axi_rdata,
	output wire  [1:0]           					axi_rresp,
	input  wire                             		axi_rready,
	output reg                              		axi_rvalid	

);
	
	
	logic [31:0] msgst_active_cnt;
	logic [31:0] msgst_idle_cnt;
	logic [31:0] msgst_busy_cnt;
	
	logic [31:0] msgld_req_active_cnt;
	logic [31:0] msgld_req_idle_cnt;
	logic [31:0] msgld_req_busy_cnt;
	
	logic [31:0] msgld_dat_active_cnt;
	logic [31:0] msgld_dat_idle_cnt;
	logic [31:0] msgld_dat_busy_cnt;
	
	logic [31:0] msgst_active_cnt_snapshot;
	logic [31:0] msgst_idle_cnt_snapshot;
	logic [31:0] msgst_busy_cnt_snapshot;
	
	logic [31:0] msgld_req_active_cnt_snapshot;
	logic [31:0] msgld_req_idle_cnt_snapshot;
	logic [31:0] msgld_req_busy_cnt_snapshot;
	
	logic [31:0] msgld_dat_active_cnt_snapshot;
	logic [31:0] msgld_dat_idle_cnt_snapshot;
	logic [31:0] msgld_dat_busy_cnt_snapshot;
	
	logic  msgst_active_cnt_is_read;
	logic  msgst_idle_cnt_is_read;
	logic  msgst_busy_cnt_is_read;
	
	logic  msgld_req_active_cnt_is_read;
	logic  msgld_req_idle_cnt_is_read;
	logic  msgld_req_busy_cnt_is_read;
	
	logic  msgld_dat_active_cnt_is_read;
	logic  msgld_dat_idle_cnt_is_read;
	logic  msgld_dat_busy_cnt_is_read;
	
	logic [63:0] msgst_pass_cnt;
	logic [63:0] msgst_fail_cnt;
	
	logic [63:0] msgld_pass_cnt;
	logic [63:0] msgld_fail_cnt;
	
	logic [31:0] msgstld_perf_ctrl;
	logic [31:0] msgld_req_dat_err;
	logic [31:0] msgst_req_dat_err;
	
	logic [31:0] msgst_rsp_pkt_rcvd;
	logic [31:0] msgld_rsp_pkt_rcvd;
	logic [31:0] msgst_req_pkt_sent;
	logic [31:0] msgld_req_pkt_sent;
	
	logic [31:0] free_run_cnt;
	
	
	reg	   		rd_req;
	reg   [C_S_AXI_ADDR_WIDTH-1:0]    rd_addr;
	
	reg           					wr_req;
	reg   [C_S_AXI_ADDR_WIDTH-1:0]  wr_addr;
	
	reg           					reset_released;
	reg           					reset_released_r;
	
	logic [7:0] msgld_rsp_pld_length;
	logic [7:0] crc_rcvd;
	logic [11:0] prev_response_cookie;
	logic [255:0] msgld_rsp_payload;
	logic [31:0] msgld_rsp_pld_pkt_id;
	logic [7:0] crc;
	logic crc_pass;
	logic crc_pass_full_pkt;	
	logic crc_fail_full_pkt;	
	logic msgld_rsp_pkt_started;
	logic msgld_rsp_sop;
	logic msgld_rsp_eop;
	logic [7:0] byte_cnt_rcvd;
	logic byte_cnt_err;
	logic msgld_rsp_dat_err;
	logic msgld_rsp_err_rcvd;
	logic [2:0] msgld_rsp_dat_err_status;
	logic [1:0] msgld_rsp_dat_status;
	
	logic msgst_rsp_dat_err;
	logic [2:0] msgst_rsp_dat_err_status;
	logic [1:0] msgst_rsp_dat_status;
	
	logic msgld_rsp_pkt_pass;
	logic msgld_rsp_pkt_fail;
	logic run_cntrs;
	logic msgst_fail_cnt_ce;
	logic msgst_pass_cnt_ce;
	
	logic msgld_dat_busy_cnt_ce;
	logic msgld_dat_idle_cnt_ce;
	logic msgld_dat_active_cnt_ce;
	
	logic msgld_req_busy_cnt_ce;
	logic msgld_req_idle_cnt_ce;
	logic msgld_req_active_cnt_ce;
	
	logic msgst_busy_cnt_ce;
	logic msgst_idle_cnt_ce;
	
	logic restart_cntrs;
	logic cntr_snapshot_vld;
	logic perf_cntr_sclr;
	
	logic cdm_top_msgst_tvalid_pls;
	logic cdm_top_msgst_tvalid_ff;
	logic cdm_top_msgld_req_tvalid_pls;
	logic cdm_top_msgld_req_tvalid_ff;
	
	logic start_counting;
	
	
	
	/*	Counters */
	
	//MSGST counters
	c_counter_binary_0 msgst_active_cnt_i (
  .CLK(axi_aclk),   
  .CE(msgst_active_cnt_ce),      
  .SCLR(perf_cntr_sclr),  
  .Q(msgst_active_cnt)       
    );
    
    c_counter_binary_0 msgst_idle_cnt_i (
  .CLK(axi_aclk),    
  .CE(msgst_idle_cnt_ce),      
  .SCLR(perf_cntr_sclr),  
  .Q(msgst_idle_cnt)       
    );
    	
     c_counter_binary_0 msgst_busy_cnt_i (
  .CLK(axi_aclk),   
  .CE(msgst_busy_cnt_ce),      
  .SCLR(perf_cntr_sclr), 
  .Q(msgst_busy_cnt)        
    );
	
	//MSGLD_REQ counters
	c_counter_binary_0 msgld_req_active_cnt_i (
  .CLK(axi_aclk),   
  .CE(msgld_req_active_cnt_ce),      
  .SCLR(perf_cntr_sclr),  
  .Q(msgld_req_active_cnt)       
    );
    
    c_counter_binary_0 msgld_req_idle_cnt_i (
  .CLK(axi_aclk),    
  .CE(msgld_req_idle_cnt_ce),      
  .SCLR(perf_cntr_sclr),  
  .Q(msgld_req_idle_cnt)       
    );
    
     c_counter_binary_0 msgld_req_busy_cnt_i (
  .CLK(axi_aclk),   
  .CE(msgld_req_busy_cnt_ce),      
  .SCLR(perf_cntr_sclr), 
  .Q(msgld_req_busy_cnt)        
    );


	//MSGLD_DAT counters
	c_counter_binary_0 msgld_dat_active_cnt_i (
  .CLK(axi_aclk),   
  .CE(msgld_dat_active_cnt_ce),      
  .SCLR(perf_cntr_sclr),  
  .Q(msgld_dat_active_cnt)       
    );
    
    c_counter_binary_0 msgld_dat_idle_cnt_i (
  .CLK(axi_aclk),    
  .CE(msgld_dat_idle_cnt_ce),      
  .SCLR(perf_cntr_sclr),  
  .Q(msgld_dat_idle_cnt)       
    );
    
     c_counter_binary_0 msgld_dat_busy_cnt_i (
  .CLK(axi_aclk),   
  .CE(msgld_dat_busy_cnt_ce),      
  .SCLR(perf_cntr_sclr), 
  .Q(msgld_dat_busy_cnt)        
    );
	
	//Packet counts
	c_counter_binary_0 msgst_pass_cnt_i (
  .CLK(axi_aclk),   
  .CE(msgst_pass_cnt_ce),      
  .SCLR(perf_cntr_sclr), 
  .Q(msgst_pass_cnt)        
    );
	
	c_counter_binary_0 msgst_fail_cnt_i (
  .CLK(axi_aclk),   
  .CE(msgst_fail_cnt_ce),      
  .SCLR(perf_cntr_sclr), 
  .Q(msgst_fail_cnt)        
    );
	
	c_counter_binary_0 msgld_pass_cnt_i (
  .CLK(axi_aclk),   
  .CE(msgld_rsp_pkt_pass),      
  .SCLR(perf_cntr_sclr), 
  .Q(msgld_pass_cnt)        
    );
	
	c_counter_binary_0 msgld_fail_cnt_i (
  .CLK(axi_aclk),   
  .CE(msgld_rsp_pkt_fail),      
  .SCLR(perf_cntr_sclr), 
  .Q(msgld_fail_cnt)        
    );
	
	c_counter_binary_0 free_run_cnt_i (
  .CLK(axi_aclk),   
  .CE(1'b1),      
  .SCLR(perf_cntr_sclr), 
  .Q(free_run_cnt)        
    );
	
	/*	Registers */
	
	assign axi_awready = ((~wr_req) && (!(rd_req || axi_arvalid))) && reset_released_r;

	assign axi_bresp = 2'b00;

	assign axi_rresp = 2'b00;

	assign axi_wready = wr_req && ~axi_bvalid;

	assign axi_arready = ~rd_req && ~wr_req && reset_released_r;
	
	assign msgst_fail_cnt_ce 		= cdm_top_msgld_dat_tready && cdm_top_msgld_dat_tvalid && cdm_top_msgld_dat_eop && cdm_top_msgld_dat_response_cookie[11] && (|cdm_top_msgld_dat_err_status);
	assign msgst_pass_cnt_ce 		= cdm_top_msgld_dat_tready && cdm_top_msgld_dat_tvalid && cdm_top_msgld_dat_eop && cdm_top_msgld_dat_response_cookie[11] && ~(|cdm_top_msgld_dat_err_status);
	
	assign msgld_dat_busy_cnt_ce 	= ~cdm_top_msgld_dat_tready;
	assign msgld_dat_idle_cnt_ce	= ~cdm_top_msgld_dat_tvalid && cdm_top_msgld_dat_tready;
	assign msgld_dat_active_cnt_ce	= cdm_top_msgld_dat_tvalid && cdm_top_msgld_dat_tready;
	
	assign msgld_req_busy_cnt_ce	= ~cdm_top_msgld_req_tready;
	assign msgld_req_idle_cnt_ce	= ~cdm_top_msgld_req_tvalid && cdm_top_msgld_req_tready;
	assign msgld_req_active_cnt_ce	= cdm_top_msgld_req_tvalid && cdm_top_msgld_req_tready;
	
	assign msgst_busy_cnt_ce		= ~cdm_top_msgst_tready;
	assign msgst_idle_cnt_ce		= ~cdm_top_msgst_tvalid && cdm_top_msgst_tready;
	assign msgst_active_cnt_ce		= cdm_top_msgst_tvalid && cdm_top_msgst_tready;
	assign perf_cntr_sclr			= ~axi_aresetn || msgstld_perf_ctrl[0] || restart_cntrs || ~start_counting ;	
	
	always @(posedge axi_aclk)
	  begin
		if(~axi_aresetn) 
			cdm_top_msgst_tvalid_ff <= 1'b0;		
		else
			cdm_top_msgst_tvalid_ff <= cdm_top_msgst_tvalid;
	  end
	  
	  assign cdm_top_msgst_tvalid_pls = cdm_top_msgst_tvalid & (~cdm_top_msgst_tvalid_ff);
	  
	  always @(posedge axi_aclk)
	  begin
		if(~axi_aresetn) 
			cdm_top_msgld_req_tvalid_ff <= 1'b0;		
		else
			cdm_top_msgld_req_tvalid_ff <= cdm_top_msgld_req_tvalid;
	  end
	  
	  assign cdm_top_msgld_req_tvalid_pls = cdm_top_msgld_req_tvalid & (~cdm_top_msgld_req_tvalid_ff);
	  
	  always @(posedge axi_aclk)
	  begin
		if(~axi_aresetn) 
			start_counting	<= 1'b0;
		else
			begin
				if((cdm_top_msgst_tvalid_pls || cdm_top_msgld_req_tvalid_pls) && ~start_counting )
					start_counting	<= 1'b1;
				else
					start_counting	<= start_counting;
			end			
	  end
	
	  always @(posedge axi_aclk)
	  begin
		if(~axi_aresetn) 
		begin
			reset_released   <= 1'b0;	
			reset_released_r <= 1'b0;
		end 
		else 
		begin
			reset_released   <= 1'b1;
			reset_released_r <= reset_released;
		end 
     end
	 
	always @(posedge axi_aclk)
	begin
		if(~axi_aresetn)
			begin
				wr_req <= 1'b0;
				rd_req <= 1'b0;
				wr_addr <= {C_S_AXI_ADDR_WIDTH {1'b0}};
				rd_addr <= {C_S_AXI_ADDR_WIDTH {1'b0}};
			end 
		else 
		begin
			if(axi_awvalid && axi_awready) 
				begin
				wr_req <= 1'b1;
				wr_addr <= axi_awaddr;
				end 
			else if (axi_bvalid && axi_bready) 
				begin
					wr_req <= 1'b0;
					wr_addr <= {C_S_AXI_ADDR_WIDTH {1'b0}};
				end 
			else 
				begin
					wr_req <= wr_req;
					wr_addr <= wr_addr;
				end
				
			if(axi_arvalid && axi_arready) 
				begin
					rd_req <= 1'b1;
					rd_addr <= axi_araddr;
				end 
			else if (axi_rvalid && axi_rready) 
				begin              
					rd_req <= 1'b0;              
					rd_addr <= rd_addr;
				end 
			else 
				begin
					rd_req <= rd_req;
					rd_addr <= rd_addr;
				end
			end
		end 
		
	always @(posedge axi_aclk)
		begin
			if(~axi_aresetn)
				begin
					msgst_active_cnt_is_read	<= 1'b0;
					msgst_idle_cnt_is_read		<= 1'b0;
					msgst_busy_cnt_is_read		<= 1'b0;
					
					msgld_req_active_cnt_is_read	<= 1'b0;
					msgld_req_idle_cnt_is_read		<= 1'b0;
					msgld_req_busy_cnt_is_read		<= 1'b0;
					
					msgld_dat_active_cnt_is_read	<= 1'b0;
					msgld_dat_idle_cnt_is_read		<= 1'b0;
					msgld_dat_busy_cnt_is_read		<= 1'b0;
					restart_cntrs					<= 1'b0;
					cntr_snapshot_vld				<= 1'b0;
				end 
			else 
				begin
					if(rd_req) 
						begin
							if(axi_rvalid && axi_rready)
								begin
									case (rd_addr[9:0])
										10'h308:msgst_active_cnt_is_read <= 1'b1;
										10'h310:msgst_idle_cnt_is_read 	 <= 1'b1;
										10'h318:msgst_busy_cnt_is_read 	 <= 1'b1;
										
										10'h320:msgld_req_active_cnt_is_read <= 1'b1;
										10'h328:msgld_req_idle_cnt_is_read 	 <= 1'b1;
										10'h330:msgld_req_busy_cnt_is_read 	 <= 1'b1;
										
										10'h338:msgld_dat_active_cnt_is_read <= 1'b1;
										10'h340:msgld_dat_idle_cnt_is_read 	 <= 1'b1;
										10'h348:msgld_dat_busy_cnt_is_read 	 <= 1'b1;
										
										default:
											begin
												msgst_active_cnt_is_read	<= msgst_active_cnt_is_read;
												msgst_idle_cnt_is_read		<= msgst_idle_cnt_is_read;
												msgst_busy_cnt_is_read		<= msgst_busy_cnt_is_read;
												
												msgld_req_active_cnt_is_read	<= msgld_req_active_cnt_is_read;
												msgld_req_idle_cnt_is_read		<= msgld_req_idle_cnt_is_read;
												msgld_req_busy_cnt_is_read		<= msgld_req_busy_cnt_is_read;
												
												msgld_dat_active_cnt_is_read	<= msgld_dat_active_cnt_is_read;
												msgld_dat_idle_cnt_is_read		<= msgld_dat_idle_cnt_is_read;
												msgld_dat_busy_cnt_is_read		<= msgld_dat_busy_cnt_is_read;
											end
									endcase
								end
						end
					if(free_run_cnt == 32'd2000000000) //8-second count for 250MHz clock
						begin
							restart_cntrs		<= 1'b1;
							cntr_snapshot_vld	<= 1'b1;
							msgst_active_cnt_snapshot <= msgst_active_cnt;
							msgst_idle_cnt_snapshot	  <= msgst_idle_cnt;
							msgst_busy_cnt_snapshot	  <= msgst_busy_cnt;
							
							msgld_req_active_cnt_snapshot	<= msgld_req_active_cnt;
							msgld_req_idle_cnt_snapshot		<= msgld_req_idle_cnt;
							msgld_req_busy_cnt_snapshot		<= msgld_req_busy_cnt;
							
							msgld_dat_active_cnt_snapshot	<= msgld_dat_active_cnt;
							msgld_dat_idle_cnt_snapshot		<= msgld_dat_idle_cnt;
							msgld_dat_busy_cnt_snapshot		<= msgld_dat_busy_cnt;
						end
					else
						begin
							restart_cntrs		<= 1'b0;
						end
					if(msgst_active_cnt_is_read && msgst_idle_cnt_is_read && msgst_busy_cnt_is_read)
						begin
							msgst_active_cnt_is_read	<= 1'b0;
							msgst_idle_cnt_is_read		<= 1'b0;
							msgst_busy_cnt_is_read		<= 1'b0;						
						end
					if(msgld_req_active_cnt_is_read && msgld_req_idle_cnt_is_read && msgld_req_busy_cnt_is_read)
						begin
							msgld_req_active_cnt_is_read	<= 1'b0;
							msgld_req_idle_cnt_is_read		<= 1'b0;
							msgld_req_busy_cnt_is_read		<= 1'b0;						
						end
					if(msgld_dat_active_cnt_is_read && msgld_dat_idle_cnt_is_read && msgld_dat_busy_cnt_is_read)
						begin
							msgld_dat_active_cnt_is_read	<= 1'b0;
							msgld_dat_idle_cnt_is_read		<= 1'b0;
							msgld_dat_busy_cnt_is_read		<= 1'b0;
							cntr_snapshot_vld				<= 1'b0;
						end
				end
		end
     
	
	always @(posedge axi_aclk)
		begin
			if(~axi_aresetn)
				begin
					axi_rvalid <= 1'b0;		
					axi_rdata <= 32'd0;
				end 
			else 
				begin
					if(rd_req) 
						begin
							if(axi_rvalid && axi_rready) 
								begin
									axi_rvalid <= 1'b0;
								end 
							else 
								begin
									axi_rvalid <= 1'b1;
								end
							if(~axi_rvalid) 
								begin
									case (rd_addr[9:0])			
										10'h300: axi_rdata <= msgstld_perf_ctrl;
										
										// MSGST
										10'h304: axi_rdata <= msgst_active_cnt[31:0];
										10'h308: axi_rdata <= msgst_active_cnt_snapshot[31:0];
										10'h30C: axi_rdata <= msgst_idle_cnt[31:0];		
										10'h310: axi_rdata <= msgst_idle_cnt_snapshot[31:0];		
										10'h314: axi_rdata <= msgst_busy_cnt[31:0];
										10'h318: axi_rdata <= msgst_busy_cnt_snapshot[31:0];
				
										// MSGLD_REQ		
										10'h31C: axi_rdata <= msgld_req_active_cnt[31:0];
										10'h320: axi_rdata <= msgld_req_active_cnt_snapshot[31:0];
										10'h324: axi_rdata <= msgld_req_idle_cnt[31:0];	
										10'h328: axi_rdata <= msgld_req_idle_cnt_snapshot[31:0];	
										10'h32C: axi_rdata <= msgld_req_busy_cnt[31:0];
										10'h330: axi_rdata <= msgld_req_busy_cnt_snapshot[31:0];
										
										//MSGLD_DAT 								
										10'h334: axi_rdata <= msgld_dat_active_cnt[31:0];	
										10'h338: axi_rdata <= msgld_dat_active_cnt_snapshot[31:0];	
										10'h33C: axi_rdata <= msgld_dat_idle_cnt[31:0];
										10'h340: axi_rdata <= msgld_dat_idle_cnt_snapshot[31:0];
										10'h344: axi_rdata <= msgld_dat_busy_cnt[31:0];					
										10'h348: axi_rdata <= msgld_dat_busy_cnt_snapshot[31:0];	
										
										//Packet counts
										10'h34C: axi_rdata <= msgst_pass_cnt[31:0];	
										10'h350: axi_rdata <= msgst_pass_cnt[63:32];	
										10'h354: axi_rdata <= msgst_fail_cnt[31:0];
										10'h358: axi_rdata <= msgst_fail_cnt[63:32];
										10'h35C: axi_rdata <= msgld_pass_cnt[31:0];	
										10'h360: axi_rdata <= msgld_pass_cnt[63:32];	
										10'h364: axi_rdata <= msgld_fail_cnt[31:0];
										10'h368: axi_rdata <= msgld_fail_cnt[63:32];																							
										10'h36C: axi_rdata <= msgst_rsp_pkt_rcvd;										
										10'h370: axi_rdata <= msgld_rsp_pkt_rcvd;										
										10'h374: axi_rdata <= msgst_req_pkt_sent;										
										10'h378: axi_rdata <= msgld_req_pkt_sent;	
										//Error status
										10'h37C: axi_rdata <= msgld_req_dat_err;										
										10'h380: axi_rdata <= msgst_req_dat_err;
										
										10'h384: axi_rdata <= free_run_cnt[31:0];
										10'h388: axi_rdata <= {31'h0,cntr_snapshot_vld};
					
										default: axi_rdata <= 32'h0000DEAD;
									endcase
								end
						end 
					else 
						begin
							axi_rvalid <= 1'b0;		
							axi_rdata <= 32'd0;
						end
				end 
		end
	
	
	
	always @(posedge axi_aclk)
	begin
		if(~axi_aresetn)
			begin
				msgstld_perf_ctrl <= 32'h0;
			end 
		else 
			begin
				if( axi_wready && axi_wvalid) 
					begin
						case (wr_addr[9:0])
							10'h300: msgstld_perf_ctrl <= axi_wdata;												
						endcase
					end
				else
					begin
						msgstld_perf_ctrl <= msgstld_perf_ctrl;
					end
			end
	end
	
	always_ff @ (posedge axi_aclk) 
	begin 
		if((!axi_aresetn) || msgstld_perf_ctrl[0]) 
			begin
			prev_response_cookie 	<= 12'b0;
			byte_cnt_rcvd 			<= 8'b0;
			msgld_rsp_pkt_started 			<= 1'b0;
			msgld_rsp_sop 			<= 1'b0;
			msgld_rsp_eop 			<= 1'b0;
			crc_rcvd				<= 8'b0;
			msgld_rsp_pld_length				<= 8'b0;
			msgld_rsp_pld_pkt_id				<= 32'b0;
			msgld_rsp_payload					<= 256'b0;
			msgld_rsp_dat_err			<= 1'b0;
			msgld_rsp_dat_err_status	<= 3'b0;
			msgld_rsp_dat_status		<= 2'b0;
			end
		else
			begin
				if(cdm_top_msgld_dat_response_cookie[11] == 1'b0 && cdm_top_msgld_dat_tvalid && cdm_top_msgld_dat_tready)//response_cookie[11] is set to 1'b0 for MSGLD packets
				begin
					//if (cdm_top_msgld_dat_response_cookie != prev_response_cookie)
					if (!cdm_top_msgld_dat_eop && !msgld_rsp_pkt_started && cdm_top_msgld_dat_tvalid )
						begin
						msgld_rsp_pkt_started	<= 1'b1;
						msgld_rsp_sop			<= 1'b1;				
						msgld_rsp_pld_length 	<= cdm_top_msgld_dat_data[7:0];
						msgld_rsp_pld_pkt_id	<= cdm_top_msgld_dat_data[39:8];
						crc_rcvd 				<= cdm_top_msgld_dat_data[255:248];
						msgld_rsp_payload		<= cdm_top_msgld_dat_data;
						byte_cnt_rcvd			<= 8'h20;
						prev_response_cookie 	<= cdm_top_msgld_dat_response_cookie;
						end
					else
						if(msgld_rsp_pkt_started)
							begin
							msgld_rsp_sop			<= 1'b0;
							msgld_rsp_payload		<= cdm_top_msgld_dat_data;
							crc_rcvd 	<= cdm_top_msgld_dat_data[255:248];
							byte_cnt_rcvd	<= byte_cnt_rcvd + 8'h20;
							end
						else
							byte_cnt_rcvd <= byte_cnt_rcvd;
					if(cdm_top_msgld_dat_eop)
						begin
						msgld_rsp_pkt_started	<= 1'b0;
						msgld_rsp_eop	<= 1'b1;
						msgld_rsp_dat_err 			<= cdm_top_msgld_dat_error;
						msgld_rsp_dat_err_status 	<= cdm_top_msgld_dat_err_status;
						msgld_rsp_dat_status 		<= cdm_top_msgld_dat_status;
						end
					else
						msgld_rsp_eop			<= 1'b0;
				end
				else
				begin
					msgld_rsp_pkt_started <= 1'b0;
					msgld_rsp_sop			<= 1'b0;
					msgld_rsp_eop			<= 1'b0;
					msgld_rsp_dat_err			<= 1'b0;
					msgld_rsp_dat_err_status	<= 3'b0;
					msgld_rsp_dat_status		<= 2'b0;
				end
			end			
	end

	generate
	genvar crc_i;
	for (crc_i = 0; crc_i < 8; crc_i = crc_i+1) begin 
		assign crc[crc_i] = msgld_rsp_payload[240+crc_i] ^ msgld_rsp_payload[208+crc_i] ^ msgld_rsp_payload[168+crc_i] ^ msgld_rsp_payload[136+crc_i] ^ msgld_rsp_payload[104+crc_i] ^ msgld_rsp_payload[80+crc_i] ^ msgld_rsp_payload[56+crc_i] ^ msgld_rsp_payload[8+crc_i];
	end
	endgenerate
	

	always_ff @ (posedge axi_aclk) begin 
		if((!axi_aresetn) || msgstld_perf_ctrl[0]) 
			crc_pass			<= 1'b0;
		else
			if(msgld_rsp_pkt_started || msgld_rsp_eop) begin
				if((crc_rcvd != crc) || (!msgld_rsp_sop && !crc_pass))
					crc_pass	<= 1'b0;
				else
					crc_pass	<= 1'b1;
			end
			else							
				crc_pass		  <= crc_pass;			
				
	end
	//capturing response to MSGLD packets -- executes 1-cycle after EOP is asserted on MSGLD_DAT interface
	always_ff @ (posedge axi_aclk) begin 
		if((!axi_aresetn) || msgstld_perf_ctrl[0]) 
		begin 
			crc_pass_full_pkt			<= 1'b0;
			crc_fail_full_pkt			<= 1'b0;
			byte_cnt_err				<= 1'b0;
			msgld_rsp_err_rcvd			<= 1'b0;			
		end	
		else begin
		if(msgld_rsp_eop)//response_cookie[11] is set to 1'b0 for MSGLD packets
			begin				
				if(crc_pass &&(crc_rcvd == crc))
				begin
					crc_pass_full_pkt <= 1'b1;
					crc_fail_full_pkt <= 1'b0;
				end
				else
				begin
					crc_pass_full_pkt <= 1'b0;
					crc_fail_full_pkt <= 1'b1;
				end
				
				if(byte_cnt_rcvd == msgld_rsp_pld_length)
					byte_cnt_err <= 1'b0;
				else
					byte_cnt_err <= 1'b1;	
				if(msgld_rsp_dat_err || (|msgld_rsp_dat_err_status) || (|msgld_rsp_dat_status))
					msgld_rsp_err_rcvd <= 1'b1;
				else
					msgld_rsp_err_rcvd <= 1'b0;
			end
		else
			begin
				crc_pass_full_pkt			<= 1'b0;
				crc_fail_full_pkt			<= 1'b0;
				byte_cnt_err				<= 1'b0;
				msgld_rsp_err_rcvd			<= 1'b0;
			end
		end
	end
	
	//Executes 2 cycles after EOP is asserted on MSGLD_DAT interface
	always_ff @ (posedge axi_aclk) 
	begin 
		if((!axi_aresetn) || msgstld_perf_ctrl[0]) 
		begin
			msgld_rsp_pkt_pass	<= 1'b0;
			msgld_rsp_pkt_fail	<= 1'b0;
		end
		else 
		begin
			//if(crc_pass_full_pkt && !byte_cnt_err && !msgld_rsp_err_rcvd )
			if(msgld_rsp_eop && !(msgld_rsp_dat_err || (|msgld_rsp_dat_err_status) || (|msgld_rsp_dat_status)) )
				msgld_rsp_pkt_pass <= 1'b1;				
			else			
				msgld_rsp_pkt_pass <= 1'b0;
				
			//if(crc_fail_full_pkt || byte_cnt_err || msgld_rsp_err_rcvd)
			if(msgld_rsp_eop && (msgld_rsp_dat_err || (|msgld_rsp_dat_err_status) || (|msgld_rsp_dat_status)) )
				msgld_rsp_pkt_fail <= 1'b1;
			else
				msgld_rsp_pkt_fail <= 1'b0;
		end
	end
	
	assign msgld_req_dat_err = {msgld_rsp_dat_status,msgld_rsp_dat_err_status,msgld_rsp_dat_err,byte_cnt_err,crc_fail_full_pkt,crc_pass_full_pkt};
	
	//capturing response to MSGST packets
	always_ff @ (posedge axi_aclk) begin 
		if((!axi_aresetn) || msgstld_perf_ctrl[0]) 
		begin 
			msgst_rsp_dat_err			<= 1'b0;
			msgst_rsp_dat_err_status	<= 3'b0;
			msgst_rsp_dat_status		<= 2'b0;
		end	
		else begin
		if(cdm_top_msgld_dat_response_cookie[11] == 1'b1)//response_cookie[11] is set to 1'b1 for MSGST packets
			begin									
				if(cdm_top_msgld_dat_eop && cdm_top_msgld_dat_tvalid && cdm_top_msgld_dat_tready)
					begin
					msgst_rsp_dat_err 			<= cdm_top_msgld_dat_error;
					msgst_rsp_dat_err_status 	<= cdm_top_msgld_dat_err_status;
					msgst_rsp_dat_status 		<= cdm_top_msgld_dat_status;
					end
				else
					begin
					msgst_rsp_dat_err 		 <= msgst_rsp_dat_err;
					msgst_rsp_dat_err_status <= msgst_rsp_dat_err_status;
					msgst_rsp_dat_status 	 <= msgst_rsp_dat_status;
					end		
			end
		end
	end
	
	assign msgst_req_dat_err = {msgst_rsp_dat_status,msgst_rsp_dat_err_status,msgst_rsp_dat_err};
	
	
	always_ff @ (posedge axi_aclk) 
	begin 
		if((!axi_aresetn) || msgstld_perf_ctrl[0])
			begin
			msgst_rsp_pkt_rcvd <= 32'b0;
			msgld_rsp_pkt_rcvd <= 32'b0;
			end
		else
			begin
				if(cdm_top_msgld_dat_response_cookie[11] == 1'b1)
					begin
						if(cdm_top_msgld_dat_eop && cdm_top_msgld_dat_tvalid && cdm_top_msgld_dat_tready)
							msgst_rsp_pkt_rcvd <= msgst_rsp_pkt_rcvd + 1'b1;
						else
							msgst_rsp_pkt_rcvd <= msgst_rsp_pkt_rcvd;
					end
				else
					begin
						if(cdm_top_msgld_dat_eop && cdm_top_msgld_dat_tvalid && cdm_top_msgld_dat_tready)
							msgld_rsp_pkt_rcvd <= msgld_rsp_pkt_rcvd + 1'b1;
						else
							msgld_rsp_pkt_rcvd <= msgld_rsp_pkt_rcvd;
					end
			
			end
	end

	always_ff @ (posedge axi_aclk) 
	begin 
		if((!axi_aresetn) || msgstld_perf_ctrl[0])
			begin
			msgst_req_pkt_sent <= 32'b0;
			msgld_req_pkt_sent <= 32'b0;
			end
		else
			begin
				if(cdm_top_msgst_eop && cdm_top_msgst_tvalid && cdm_top_msgst_tready)
					msgst_req_pkt_sent <= msgst_req_pkt_sent + 1'b1;
				else
					msgst_req_pkt_sent <= msgst_req_pkt_sent;
						
				if(cdm_top_msgld_req_tvalid && cdm_top_msgld_req_tready)
					msgld_req_pkt_sent <= msgld_req_pkt_sent + 1'b1;
				else
					msgld_req_pkt_sent <= msgld_req_pkt_sent;

			end
	end
	
  //********************************************************************************

  //write response channel logic. 

  //This logic will generate BVALID signal for the write transaction. 

  //********************************************************************************

  always @(posedge axi_aclk)

  begin

      if(~axi_aresetn) begin

          axi_bvalid <= 1'b0;

      end else begin

          if(wr_req && axi_wvalid && ~axi_bvalid) begin

              axi_bvalid <= 1'b1;

          end else if(axi_bready) begin

              axi_bvalid <= 1'b0;

          end else begin

              axi_bvalid <= axi_bvalid;

          end

      end

  end 
endmodule
