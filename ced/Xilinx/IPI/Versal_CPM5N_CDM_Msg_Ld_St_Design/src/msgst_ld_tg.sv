`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2022 09:14:14 AM
// Design Name: 
// Module Name: msgst_ld_tg
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


module msgst_ld_tg
#(
	parameter FAB_CLIENT_ID = 4'h1
)
(

    
	input fabric_clk,
	input fabric_rst_n,	
	
	output logic [31:0]	M_AXI_CDM_araddr,	
	output logic [2:0] 	M_AXI_CDM_arprot,	
	input  logic		M_AXI_CDM_arready,	
	output logic 		M_AXI_CDM_arvalid,	
	output logic [31:0]	M_AXI_CDM_awaddr,	
	output logic [2:0]	M_AXI_CDM_awprot,	
	input  logic		M_AXI_CDM_awready,	
	output logic 		M_AXI_CDM_awvalid,	
	output logic 		M_AXI_CDM_bready,	
	input  logic [1:0]	M_AXI_CDM_bresp,	
	input  logic		M_AXI_CDM_bvalid,	
	input  logic [31:0]	M_AXI_CDM_rdata,	
	output logic 		M_AXI_CDM_rready,	
	input  logic [1:0]	M_AXI_CDM_rresp,	
	input  logic		M_AXI_CDM_rvalid,	
	output logic [31:0]	M_AXI_CDM_wdata,
	input  logic		M_AXI_CDM_wready,	
	output logic [3:0]	M_AXI_CDM_wstrb,	
	output logic 		M_AXI_CDM_wvalid,
	
	input logic msgst_cmd_fill_bram,
	input logic msgld_cmd_fill_bram,
	input logic msgst_payload_fill_bram,	
	
	input logic [6:0]    msgst_num_of_CMD,
	input logic [6:0]    msgld_num_of_CMD,
	
	output logic msgst_req_fill_start,
	output logic msgld_req_fill_start,
	output logic msgst_payload_fill_start,
	
	input logic [4:0]	 msgstld_CSI_DST,
	input logic [8:0]	 msgstld_pld_length,
	input logic [11:0] msgst_resp_cookie_vio,
	input logic [11:0] msgld_resp_cookie_vio 
	
    );
	

	logic [5:0][31:0]   msgst_data_reg;
	logic [3:0][31:0]   msgld_data_reg;
	logic [7:0][31:0]   msgst_payload_data_reg;
	
	logic 			msgst_req_write_active;
	logic 			msgld_req_write_active;
	logic 			msgst_payload_write_active;	
	logic [31:0]	msgst_addr;
	logic [31:0]	msgld_addr;
	logic [31:0]	msgst_payload_addr;
	
	logic [2:0] 	msgst_cmd_loc;
	logic [1:0] 	msgld_cmd_loc;
	logic [2:0] 	msgst_payload_cmd_loc;
	
	//MSGST_CTRL0 (0x0)
//	logic [8:0]		msgst_pld_length = 9'h100;//Number of bytes in the payload
	logic [1:0]		msgst_op = 2'h0;//CDM_MSG_STORE_MSG (0), CDM_MSG_STORE_IRQ  (1)
	logic [15:0]	msgst_fnc = 16'h0;
	logic 			msgst_addr_translated = 1'b0;
	
	//MSGST_CTRL1 (0x4)
	logic [15:0] msgst_wc_id = 16'h0;
	logic 		 msgst_wc_line_size = 1'b1;//CDM_WC_LINE_SIZE_128B
	logic [2:0]	 msgst_wc_timeout_idx = 3'h7;
	logic [1:0]	 msgst_wc_op = 2'h0;//CDM_WC_OP_NONE
//	logic [4:0]	 msgst_CSI_DST = 5'h4;//4 for PCIe; C for PSX
	logic [4:0]	 msgst_start_offset = 5'h0;
	
	//MSGST_CTRL2 (0x8)
	logic		 msgst_response_req = 1'b1;
	logic [11:0] msgst_response_cookie;// = 12'hbdf;
	logic [1:0]	 msgst_data_width = 2'h1;
	logic [3:0]	 msgst_Client_id = FAB_CLIENT_ID;//Fab1 interface in CDM Mode
	logic [8:0]	 msgst_CSI_DST_FIFO = 9'h0;
	
	//MSGST_CTRL3 (0xC)
	logic 		 msgst_no_snoop = 1'b0;
	logic 		 msgst_ro = 1'b0;
	logic		 msgst_ido = 1'b0;
	logic		 msgst_st2m_ordered = 1'b0;
	logic [15:0] msgst_wait_pld_pkt_id = 16'h0;
	logic [7:0]	 msgst_Seed_value = 8'h1F;
	logic [1:0]	 msgst_type_of_pattern = 2'h0;//00=LFSR, 01=increment by 1, 10=flip the bits, etc
	logic 		 msgst_execute_rq = 1'b0;
	logic		 msgst_priviliged_mode_rq = 1'b0;
	
	//MSGST_CTRL4 (0x10)
	logic [15:0] msgst_irq_vector = 16'h0;
	logic 		 msgst_th = 1'b0;//tph
	logic [1:0]	 msgst_ph = 2'h0;//tph
	logic [7:0]	 msgst_st_hi = 8'h0;//tph
	
	//MSGST_CTRL5 (0x14)
	logic [10:0] msgst_ecc = 11'h0;
	logic 		 msgst_enable = 1'b0;
	logic [19:0] msgst_pasid = 20'h0;
	
	logic [6:0] num_msgst_cmd_loaded;
	logic [6:0] num_msgld_cmd_loaded;
	logic  msgst_cmd_load_finish;
	logic  msgld_cmd_load_finish;
	
	logic  msgst_cmd_reload;
	logic  msgld_cmd_reload;
	
	logic msgst_cmd_fill_bram_ff;
	logic msgst_cmd_fill_bram_pls;
	
	// Edge detection of msgst_cmd_fill_bram signal
    always_ff @(posedge fabric_clk) begin
      if(!fabric_rst_n)
        msgst_cmd_fill_bram_ff <= 1'b0;
      else
        msgst_cmd_fill_bram_ff <= msgst_cmd_fill_bram;
    end

    assign msgst_cmd_fill_bram_pls = msgst_cmd_fill_bram & (~msgst_cmd_fill_bram_ff);
	
	logic msgld_cmd_fill_bram_ff;
	logic msgld_cmd_fill_bram_pls;
	
	// Edge detection of msgld_cmd_fill_bram signal
    always_ff @(posedge fabric_clk) begin
      if(!fabric_rst_n)
        msgld_cmd_fill_bram_ff <= 1'b0;
      else
        msgld_cmd_fill_bram_ff <= msgld_cmd_fill_bram;
    end

    assign msgld_cmd_fill_bram_pls = msgld_cmd_fill_bram & (~msgld_cmd_fill_bram_ff);
	
	
	always_ff @ (posedge fabric_clk) 
	begin
		if(!fabric_rst_n) 
		begin
			msgst_response_cookie <= 12'h0;
		end
		else 
		begin
			if((msgst_cmd_fill_bram_pls || msgst_req_fill_start) && (msgst_cmd_loc == 3'h0))
				msgst_response_cookie <= msgst_response_cookie + 12'h111;
		end	
	end
	
	
	//reserved bits are set to 'h0
	assign msgst_data_reg[0][31:0] = {2'h0,msgst_addr_translated,1'b0,msgst_fnc,1'b0,msgst_op,msgstld_pld_length};//32'h00000100; 
	assign msgst_data_reg[1][31:0] = {msgst_start_offset,msgstld_CSI_DST,msgst_wc_op,msgst_wc_timeout_idx,msgst_wc_line_size,msgst_wc_id};//32'h010F0000;
	assign msgst_data_reg[2][31:0] = {4'h0,msgst_CSI_DST_FIFO,msgst_Client_id,msgst_data_width,{1'b1,msgst_response_cookie[10:0]},msgst_response_req};//32'h000037BF;
	assign msgst_data_reg[3][31:0] = {msgst_priviliged_mode_rq,msgst_execute_rq,msgst_type_of_pattern,msgst_Seed_value,msgst_wait_pld_pkt_id,msgst_st2m_ordered,msgst_ido,msgst_ro,msgst_no_snoop};//32'h01F00000;
	assign msgst_data_reg[4][31:0] = {5'h0,msgst_st_hi,msgst_ph,msgst_th,msgst_irq_vector};//32'h00000000;
	assign msgst_data_reg[5][31:0] = {msgst_pasid,msgst_enable,msgst_ecc};//32'h00000000;
	
	//MSGLD_CTRL0 (0x0)
	logic [8:0]	 msgld_length = 9'h100;
	logic [1:0]	 msgld_op = 2'h0;//CDM_MSG_LOAD_MSG (0),CDM_MSG_LOAD_BARRIER (1),CDM_MSG_LOAD_TRANSLATION_RQ (2)
	logic 		 msgld_data_width = 1'b1;
	logic 		 msgld_relaxed_read = 1'b0;
	logic [15:0] msgld_fnc = 16'h0;
	logic 		 msgld_addr_translated = 1'b0;
	
	//MSGLD_CTRL1 (0x4)
	logic [5:0]	 msgld_rc_id = (FAB_CLIENT_ID == 1'b1) ? 6'hB : 6'hA;//FAB0 = 6'hA, FAB1 = 6'hB
	logic [3:0]	 msgld_client_id = FAB_CLIENT_ID;//Fab1 interface in CDM Mode
	logic [1:0]	 msgld_ctrl1_op = 2'h0;
	logic [4:0]	 msgld_CSI_DST = 5'h4;//4 for PCIe; C for PSX
	logic [8:0]	 msgld_CSI_DST_FIFO = 9'h0;
	logic [4:0]	 msgld_start_offset = 5'h0;
	
	//MSGLD_CTRL2 (0x8)
	logic [11:0] msgld_response_cookie;// = 12'hbdf;
	logic 		 msgld_no_snoop = 1'b0;//attr
	logic 		 msgld_ro = 1'b0;//attr
	logic 		 msgld_ido = 1'b0;//attr
	logic [7:0]	 msgld_seeed = 8'h1F;
	logic [1:0]	 msgld_type_of_pattern = 2'h0;//00=LFSR, 01=increment by 1, 10=flip the bits, etc
	
	//MSGLD_CTRL3 (0xC)
	logic 		 msgld_enable = 1'b0;
	logic [19:0] msgld_pasid = 20'h0;
	logic 		 msgld_execute_rq = 1'b0;
	logic 		 msgld_priviliged_mode_rq = 1'b0;
	
	always_ff @ (posedge fabric_clk) 
	begin
		if(!fabric_rst_n) 
		begin
			msgld_response_cookie <= 12'h0;
		end
		else 
		begin
			if((msgld_cmd_fill_bram_pls || msgld_req_fill_start )  && (msgld_cmd_loc == 3'h0))
				msgld_response_cookie <= msgld_response_cookie + 12'h123;
		end
		
	end
	
	//reserved bits are set to 'h0
//	assign msgld_data_reg[0][31:0] = {msgld_addr_translated,1'b0,msgld_fnc,1'b0,msgld_relaxed_read,msgld_data_width,msgld_op,msgld_length};//32'h00000900;
	assign msgld_data_reg[0][31:0] = {msgld_addr_translated,1'b0,msgld_fnc,1'b0,msgld_relaxed_read,msgld_data_width,msgld_op,msgstld_pld_length};//32'h00000900;
	assign msgld_data_reg[1][31:0] = {1'b0,msgld_start_offset,msgld_CSI_DST_FIFO,msgstld_CSI_DST,msgld_ctrl1_op,msgld_client_id,msgld_rc_id};//32'h0000400A;
	assign msgld_data_reg[2][31:0] = {7'h0,msgld_type_of_pattern,msgld_seeed,msgld_ido,msgld_ro,msgld_no_snoop,{1'b0,msgld_response_cookie[10:0]}};//32'h000F8BDF;
	assign msgld_data_reg[3][31:0] = {9'h0,msgld_priviliged_mode_rq,msgld_execute_rq,msgld_pasid,msgld_enable};//32'h00000000;
	
	assign msgst_payload_data_reg[0][31:0] = 32'h03020100;
	assign msgst_payload_data_reg[1][31:0] = 32'h07060504;
	assign msgst_payload_data_reg[2][31:0] = 32'h0B0A0908;
	assign msgst_payload_data_reg[3][31:0] = 32'h0F0E0D0C;
	assign msgst_payload_data_reg[4][31:0] = 32'h13121110;
	assign msgst_payload_data_reg[5][31:0] = 32'h17161514;
	assign msgst_payload_data_reg[6][31:0] = 32'h1B1A1918;
	assign msgst_payload_data_reg[7][31:0] = 32'h1F1E1D1C;
	
	//Loading BRAM for MSGST, MSGST_Payload, MSGLD
   always_ff @ (posedge fabric_clk) 
   begin 
		if(!fabric_rst_n) 
		begin 
			M_AXI_CDM_araddr  	 <= 32'h0;
			M_AXI_CDM_arprot  	 <= 3'h0;
			M_AXI_CDM_arvalid 	 <= 1'b0;
			M_AXI_CDM_awaddr  	 <= 32'h0;
			M_AXI_CDM_awprot  	 <= 3'h0;
			M_AXI_CDM_awvalid 	 <= 1'b0;
			M_AXI_CDM_bready  	 <= 1'b0;
			M_AXI_CDM_rready  	 <= 1'b0;
			M_AXI_CDM_wdata 	 <= 32'h0;
			M_AXI_CDM_wstrb 	 <= 4'h0;
			M_AXI_CDM_wvalid  	 <= 1'b0;
			msgst_payload_fill_start  	 <= 1'b0;
			msgst_payload_addr		 	 <= 32'h8000;//This value is set in Vivado Address editor
			msgst_payload_cmd_loc	 	 <= 3'h0;
			msgst_payload_write_active<=1'b0;
			msgst_req_fill_start  <= 1'b0;
			msgst_addr		 	 <= 32'hA000;//This value is set in Vivado Address editor
			msgst_cmd_loc	 	 <= 3'h0;
			msgst_req_write_active <= 1'b0;
			msgld_req_fill_start  <= 1'b0;
			msgld_addr		 	 <= 32'h0000;//This value is set in Vivado Address editor
			msgld_cmd_loc	 	 <= 2'h0;
			msgld_req_write_active<=1'b0;
			num_msgst_cmd_loaded	<=7'b0;
			num_msgld_cmd_loaded	<=7'b0;
		end
		//Loading BRAM for MSGST CMD
		else if(msgst_cmd_fill_bram_pls || ((num_msgst_cmd_loaded != msgst_num_of_CMD)) ) 
		begin				
			if((num_msgst_cmd_loaded == 7'h0) && (msgst_req_fill_start == 1'b0))
			begin
				M_AXI_CDM_awaddr  		<= msgst_addr;
				M_AXI_CDM_awvalid 		<= 1'b1;
				msgst_req_fill_start	<= 1'b1;
			end
			
			if (M_AXI_CDM_awready && M_AXI_CDM_awvalid) 
			begin
				M_AXI_CDM_awvalid <= 1'b0;
				M_AXI_CDM_wvalid <= 1'b1;
				M_AXI_CDM_wdata	 <= msgst_data_reg [msgst_cmd_loc][31:0];
				M_AXI_CDM_wstrb	 <= 4'hF;
			end
			if (M_AXI_CDM_wready && M_AXI_CDM_wvalid) 
			begin
				M_AXI_CDM_bready	<= 1'b1;
				M_AXI_CDM_wvalid	<= 1'b0;
			end
			if (M_AXI_CDM_bvalid && M_AXI_CDM_bready) 
			begin
				M_AXI_CDM_bready 	<= 1'b0;														
				M_AXI_CDM_awaddr	<= M_AXI_CDM_awaddr	+ 32'h4;
				
				if((num_msgst_cmd_loaded == (msgst_num_of_CMD - 1'b1)) && (msgst_cmd_loc == 5))
					M_AXI_CDM_awvalid 	<= 1'b0;
				else
					M_AXI_CDM_awvalid 	<= 1'b1;
					
				if(msgst_cmd_loc == 5)
				begin
					msgst_cmd_loc <= 3'h0;
					num_msgst_cmd_loaded <= num_msgst_cmd_loaded + 1'b1;
				end
				else
					msgst_cmd_loc	<= msgst_cmd_loc + 3'h1;				
			end				
		end		
		//Loading BRAM for MSGLD CMD
		else if(msgld_cmd_fill_bram_pls || (num_msgld_cmd_loaded != msgld_num_of_CMD) ) 
		begin 
			if((num_msgld_cmd_loaded == 7'h0) && (msgld_req_fill_start == 1'b0))
			begin
				M_AXI_CDM_awaddr  		<= msgld_addr;
				M_AXI_CDM_awvalid 		<= 1'b1;
				msgld_req_fill_start	<= 1'b1;
			end
			
			if (M_AXI_CDM_awready && M_AXI_CDM_awvalid) 
			begin
				M_AXI_CDM_awvalid <= 1'b0;
				M_AXI_CDM_wvalid <= 1'b1;
				M_AXI_CDM_wdata	 <= msgld_data_reg [msgld_cmd_loc][31:0];
				M_AXI_CDM_wstrb	 <= 4'hF;
			end
			if (M_AXI_CDM_wready && M_AXI_CDM_wvalid) 
			begin
				M_AXI_CDM_bready	<= 1'b1;
				M_AXI_CDM_wvalid	<= 1'b0;
			end
			if (M_AXI_CDM_bvalid && M_AXI_CDM_bready) 
			begin
				M_AXI_CDM_bready 	<= 1'b0;							
				msgld_cmd_loc		<= msgld_cmd_loc + 2'h1;				
				M_AXI_CDM_awaddr	<= M_AXI_CDM_awaddr	+ 32'h4;				
				
				if((num_msgld_cmd_loaded ==(msgld_num_of_CMD - 1'b1))&& (msgld_cmd_loc == 3))
					M_AXI_CDM_awvalid 	<= 1'b0;
				else
					M_AXI_CDM_awvalid 	<= 1'b1;
				
				if(msgld_cmd_loc == 3)
					num_msgld_cmd_loaded = num_msgld_cmd_loaded +1'b1;
				
			end			
		end		
	 //Loading BRAM for MSGST Payload
		else if(msgst_payload_fill_bram || msgst_payload_fill_start ) 
		begin                     
			M_AXI_CDM_awaddr  	<= msgst_payload_addr;
			if(msgst_payload_fill_bram && ~msgst_payload_fill_start) 
				msgst_payload_fill_start <= 1'b1;
				
			if(~msgst_payload_write_active) 
			begin			
				M_AXI_CDM_awvalid 	<= 1'b1;
				msgst_payload_write_active <= 1'b1;
			end
			else 
			begin 
				if (M_AXI_CDM_awready && M_AXI_CDM_awvalid) 
				begin
					M_AXI_CDM_awvalid <= 1'b0;
					M_AXI_CDM_wvalid <= 1'b1;
					M_AXI_CDM_wdata	 <= msgst_payload_data_reg [msgst_payload_cmd_loc][31:0];
					M_AXI_CDM_wstrb	 <= 4'hF;
				end
				if (M_AXI_CDM_wready && M_AXI_CDM_wvalid) 
				begin
					M_AXI_CDM_bready	<= 1'b1;
					M_AXI_CDM_wvalid	<= 1'b0;
				end
				if (M_AXI_CDM_bvalid && M_AXI_CDM_bready) 
				begin
					M_AXI_CDM_bready <= 1'b0;
					msgst_payload_write_active <= 1'b0;
					if(~msgst_payload_fill_bram && (msgst_payload_cmd_loc == 7)) 
					begin
						msgst_payload_fill_start <= 1'b0;
						msgst_payload_cmd_loc	 <= 3'h0;
					end
					//if(msgst_payload_fill_bram || (~msgst_payload_fill_bram && (msgst_payload_cmd_loc != 7))) begin
					else 
					begin				
						msgst_payload_cmd_loc	<= msgst_payload_cmd_loc + 3'h1;
						msgst_payload_addr		<= msgst_payload_addr	+ 32'h4;
					end
				end
			end
		end
		if(msgst_cmd_load_finish && msgst_cmd_fill_bram_pls)
		begin
			num_msgst_cmd_loaded	<= 7'b0;
			msgst_req_fill_start	<= 1'b0;
		end
		if(msgld_cmd_load_finish && msgld_cmd_fill_bram_pls)
		begin
			num_msgld_cmd_loaded	<= 7'b0;
			msgld_req_fill_start	<= 1'b0;
		end
	end
	
	always_ff @ (posedge fabric_clk) 
   begin 
		if(!fabric_rst_n) 
		begin 
			msgst_cmd_load_finish <= 1'b0;
			msgld_cmd_load_finish <= 1'b0;
		end
		else
		begin
			if((num_msgst_cmd_loaded == msgst_num_of_CMD)&& (msgst_num_of_CMD != 0))
				msgst_cmd_load_finish <= 1'b1;	
			else
				msgst_cmd_load_finish <= 1'b0;
			if((num_msgld_cmd_loaded == msgld_num_of_CMD) && (msgld_num_of_CMD != 0))
				msgld_cmd_load_finish <= 1'b1;	
			else
				msgld_cmd_load_finish <= 1'b0;
		end
	end
endmodule
