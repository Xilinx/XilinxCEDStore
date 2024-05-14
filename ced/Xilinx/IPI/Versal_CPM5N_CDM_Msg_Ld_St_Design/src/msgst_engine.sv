`timescale 1 ns / 1 ps

//`include "cdm_adapter_defines_pkg.sv"
//`include "cdx5n_dma5_defines_pkg.sv"
module msgst_engine
//import cdx5n_cdm_defines_pkg::*;
//import cdx5n_dma5_defines_pkg::*;

  (
    input clk,
    input rst_n,

    // Payload Ram write interface  
    output [255:0] pld_ram_din,
    output [31:0]  pld_ram_wen,
    output [31:0] pld_ram_addr,

    // Command Ram Read interface  
    input [31:0] cmd_ram_din,
    output       cmd_ram_ren,
    output [31:0] cmd_ram_addr,

  
    // Control and status register 
    input [63:0] pci_host_addr,
    input [63:0] pci_host_addr_mask,
    input [22:0] pci_pasid,
    input [15:0] pci_requester_id,

    input [63:0] psx_host_addr,
    input [63:0] psx_host_addr_mask,
    input [22:0] psx_pasid,
    input [15:0] psx_requester_id,

    input [14:0] num_of_reqs,
	input		msgst_infinite_pkt_run_start,	
	input		msgst_use_same_cmd,	
    output      req_done,
    // Payload RAM read control input
    //input        msgst_read,
    input        pld_cmd_req,
      
    // MSGST adapter CDM interface
    cdx5n_cmpt_msgst_if.m    fab0_cmpt_msgst,
	
	input 	[1:0] num_of_NoC_cfg, //00 = 1 NoC port, 01 = 2 Noc ports, 10 = 3 NoC ports, 11 = 4 NoC ports
	input	[6:0] Noc_port_switch_req_cnt

);

    typedef enum logic [3:0]    {
        ST_IDLE = 0,ST_RD_CMD_RAM = 1,ST_CTRL_PKT = 2, ST_DATA_GEN = 3, ST_DATA_GEN1 = 4,ST_WAIT = 5 ,ST_PLD_RAM_WR1 = 6 ,ST_PLD_RAM_WR2 = 7
     } msgst_sm_type; 
         
    msgst_sm_type msgst_sm_cs, msgst_sm_ns;

    logic [14:0] pld_ram_addr_reg;
    logic [14:0] pld_ram_addr_reg1;
//    logic [13:0] pld_ram_addr_reg1;
    //logic        pld_ram_ren_reg;
       
    logic [15:0] cmd_ram_addr_reg;
    //logic        cmd_ram_ren_reg;
    logic [2:0]  cmd_ram_rdcnt;   
    logic [14:0]  req_cnt;   

    logic [191:0]  cmd_accumulator;
    logic [8:0]   pld_length;
    logic [8:0]   pld_length_offset;
    logic [4:0]   csi_dst_id;

    logic pld_cmd_req_pls;
    logic pld_cmd_req_ff;
    logic adptr_valid_reg;
    logic msgst_eop_reg;
    logic msgst_eop_nxt;
	
	logic cdm_ready;
    logic [63:0] pci_host_addr_reg;
    logic [22:0] pci_pasid_reg;
    logic [15:0] pci_requester_id_reg;
    logic [63:0] psx_host_addr_reg;
    logic [22:0] psx_pasid_reg;
    logic [15:0] psx_requester_id_reg;
    logic [63:0] host_addr_reg;
   
    logic [5:0] mask_sel;
    logic [31:0] data_byte_mask;
    logic [31:0][7:0]   data_reg;
    logic [31:0][7:0]   data_reg1;
    logic [7:0] seq_count;
    logic [8:0] nxt_length;

    // to be removed for synth
    logic [8:0] rand_length;
    logic [8:0] rand_length_nxt;
    logic feedback;
    //logic [63:0][7:0] pld_ram_data_reg;
    logic [127:0][7:0] pld_ram_data_reg;
    //logic [63:0] pld_ram_wen_reg;
    logic [127:0] pld_ram_wen_reg;
    logic [127:0] pld_ram_wen_shift;

    logic [5:0] prev_mask_sel;
    logic [5:0] next_mask_sel;
    logic [63:0][7:0] data_extn_reg;
    logic [63:0] wen_extn_reg;
    logic [31:0] pld_ram_wen_gen;
    logic [31:0] pld_ram_wen_ff;
    logic [31:0] pld_ram_wen_pls;
  
    logic sr_switch;
    logic [4:0] start_offset;
	
	logic [7:0]       crc;              
	logic [31:0] pld_pkt_id;	
  logic [5:0] ap_id;

	logic dest_host;
	logic dest_psx;
   

    // Data Mask selection of the different Payload lengths
    always_comb begin
      case (mask_sel)
        6'h0  : data_byte_mask = 32'h0;
        6'h1  : data_byte_mask = 32'h1;
        6'h2  : data_byte_mask = 32'h3;
        6'h3  : data_byte_mask = 32'h7;
        6'h4  : data_byte_mask = 32'hF;
        6'h5  : data_byte_mask = 32'h1F;
        6'h6  : data_byte_mask = 32'h3F;
        6'h7  : data_byte_mask = 32'h7F;
        6'h8  : data_byte_mask = 32'hFF;
        6'h9  : data_byte_mask = 32'h1FF;
        6'hA  : data_byte_mask = 32'h3FF;
        6'hB  : data_byte_mask = 32'h7FF;
        6'hC  : data_byte_mask = 32'hFFF;
        6'hD  : data_byte_mask = 32'h1FFF;
        6'hE  : data_byte_mask = 32'h3FFF;
        6'hF  : data_byte_mask = 32'h7FFF;
        6'h10 : data_byte_mask = 32'hFFFF;
        6'h11 : data_byte_mask = 32'h1FFFF;
        6'h12 : data_byte_mask = 32'h3FFFF;
        6'h13 : data_byte_mask = 32'h7FFFF;
        6'h14 : data_byte_mask = 32'hFFFFF;
        6'h15 : data_byte_mask = 32'h1FFFFF;
        6'h16 : data_byte_mask = 32'h3FFFFF;
        6'h17 : data_byte_mask = 32'h7FFFFF;
        6'h18 : data_byte_mask = 32'hFFFFFF;
        6'h19 : data_byte_mask = 32'h1FFFFFF;
        6'h1A : data_byte_mask = 32'h3FFFFFF;
        6'h1B : data_byte_mask = 32'h7FFFFFF;
        6'h1C : data_byte_mask = 32'hFFFFFFF;
        6'h1D : data_byte_mask = 32'h1FFFFFFF;
        6'h1E : data_byte_mask = 32'h3FFFFFFF;
        6'h1F : data_byte_mask = 32'h7FFFFFFF;
        6'h20 : data_byte_mask = 32'hFFFFFFFF;
        default : data_byte_mask = 32'hFFFFFFFF;
      endcase
   end

    genvar i;
    generate
        for (i=0; i < 32; i++) begin            
            assign data_reg[i][7:0] = (data_byte_mask[i]) ? (((start_offset!=0) && i < start_offset)? 8'b0:(seq_count + ((i-start_offset)*1))): 8'b0;

        end
    endgenerate

   
    assign mask_sel = (nxt_length>32) ? 6'h20 : nxt_length;
//    assign msgst_eop_reg = (((msgst_sm_cs == ST_DATA_GEN && pld_length <=32)  || 
//                                                    (msgst_sm_cs == ST_DATA_GEN1 && nxt_length<=32 ) || (msgst_sm_cs == ST_CTRL_PKT && pld_length == 0)) || (msgst_sm_cs == ST_WAIT && (!cdm_ready))) ? 1'b1 : 1'b0; 
   
   
    assign msgst_eop_nxt = (((msgst_sm_cs == ST_DATA_GEN && pld_length_offset <=32)  || 
                                                    (msgst_sm_cs == ST_DATA_GEN && nxt_length<=32 ) || (msgst_sm_cs == ST_CTRL_PKT && pld_length == 0)) || (msgst_sm_cs == ST_WAIT && nxt_length<=32)) ? 1'b1 : 1'b0; 
	//Srinadh - aligning msgst_eop_reg with last cycle of msgst_tready
	always_ff @ (posedge clk) begin 
		if(!rst_n) 
			msgst_eop_reg <= 1'b0;
		else
			msgst_eop_reg <= msgst_eop_nxt;
	end
	
   // Data Shift selection for payload ram writes
   always_ff @ (posedge clk) begin 
     if(!rst_n) begin 
       prev_mask_sel <= 6'b0;
       next_mask_sel <= 6'b0;
       data_extn_reg <= 512'b0;
       wen_extn_reg <= 64'b0;
       end
     else if(pld_cmd_req_pls) begin                     
       prev_mask_sel <= 6'b0;
       next_mask_sel <= 6'b0;
       data_extn_reg <= 512'b0;
       wen_extn_reg <= 64'b0;
       end                       
     else begin
       if(adptr_valid_reg && cdm_ready) begin
         prev_mask_sel <= prev_mask_sel + next_mask_sel;
         next_mask_sel <= mask_sel;
         data_extn_reg <= data_reg;
         wen_extn_reg  <= data_byte_mask;
         end
       else begin
         prev_mask_sel <= prev_mask_sel;
         next_mask_sel <= next_mask_sel;
         data_extn_reg <= data_extn_reg;
         wen_extn_reg  <= wen_extn_reg;
         end
     end
   end
       

   assign pld_ram_data_reg = {data_extn_reg,data_extn_reg} << (prev_mask_sel * 8);
   assign pld_ram_wen_shift = {wen_extn_reg,wen_extn_reg} << (prev_mask_sel);
	
	always_ff @ (posedge clk) begin 
    if(!rst_n)
		ap_id <= 6'h0;      
    else begin 
         //if(req_cnt[6:0] == 7'h7F)
         if(req_cnt[6:0] == Noc_port_switch_req_cnt)
			begin
				case (num_of_NoC_cfg)
					2'b00: 
					ap_id <= 6'h0; 
					2'b01: 
					ap_id [0] <= !ap_id[0];
					2'b10:
					begin
						if(ap_id == 2'b10)
							ap_id <= 2'b00;
						else
							ap_id <= ap_id + 1'b1;
					end
					2'b11:
					ap_id <= ap_id + 1'b1;
				endcase			
			end
         end
	 end

   always_ff @ (posedge clk) begin 
     if(!rst_n) begin 
       sr_switch <= 1'b0;
       end
     else begin
       if(pld_ram_wen_shift[96]) 
          sr_switch <= 1'b1;
       else if(pld_ram_wen_shift[64])
          sr_switch <= 1'b0;
       else
          sr_switch <= sr_switch;
     end
  end

    genvar j;
    generate
        for (j=0; j < 32; j++) begin  
          always_ff @ (posedge clk) begin 
            if(!rst_n) 
              pld_ram_wen_ff[j] <= 1'b0;
            else 
              pld_ram_wen_ff[j] <= pld_ram_wen_gen[j];
          end
          assign pld_ram_wen_pls[j] =  pld_ram_wen_gen[j] & (~pld_ram_wen_ff[j]);
        end
    endgenerate

    // sequence counter
  always_ff @ (posedge clk) begin 
    if(!rst_n) begin 
      seq_count <= 8'h00;
      end
    //else if(pld_cmd_req_pls) begin                     
    else if(msgst_sm_cs == ST_CTRL_PKT) begin                     
      seq_count <=  cmd_accumulator[39:32]; // Seed value upadate at every request
      end
    else begin
      if((adptr_valid_reg && cdm_ready) && (mask_sel !=0)) 
        seq_count <= data_reg[mask_sel-1] + 1'b1;
    end
  end

   // Valid generation
   always_ff @ (posedge clk) begin 
     if(!rst_n) begin 
       adptr_valid_reg <= 1'b0;
       end
     else begin
       //if(msgst_sm_ns == ST_DATA_GEN   || msgst_sm_ns == ST_DATA_GEN1 || (msgst_sm_ns == ST_CTRL_PKT && pld_length == 0 )) 
       if(msgst_sm_ns == ST_DATA_GEN || (msgst_sm_ns == ST_CTRL_PKT && pld_length == 0 ) || msgst_sm_ns == ST_WAIT) 
         adptr_valid_reg <= 1'b1;
       else
         adptr_valid_reg <= 1'b0;
     end
   end 


    // Payload length decrement counter
    always_ff @(posedge clk) begin
      if(!rst_n)
        nxt_length <= 8'b0;
      else begin 
        //if(pld_cmd_req_pls)
        //if(msgst_sm_cs == ST_RD_CMD_RAM)
        if((msgst_sm_ns == ST_CTRL_PKT) || (((msgst_sm_ns == ST_DATA_GEN) || (msgst_sm_ns == ST_WAIT)) && (nxt_length <= 32)) && cdm_ready)
         //nxt_length <= pld_length;
         nxt_length <= pld_length_offset;
        else if(adptr_valid_reg && cdm_ready)
          nxt_length <= nxt_length - 32;		
        else
          nxt_length <= nxt_length; 
      end    
    end


    // Edge detection of pld_cmd_req_signal
    always_ff @(posedge clk) begin
      if(!rst_n)
        pld_cmd_req_ff <= 1'b0;
      else
        pld_cmd_req_ff <= pld_cmd_req;
    end

    assign pld_cmd_req_pls = pld_cmd_req & (~pld_cmd_req_ff);

   // State machine to Handle Payload Ram read and control data generation
    always @ (*) begin
        msgst_sm_ns             = msgst_sm_cs;
 
        case (msgst_sm_cs)
            ST_IDLE:
              begin
                if(pld_cmd_req_pls) begin
                  msgst_sm_ns = ST_RD_CMD_RAM;
                  end
                else begin
                  msgst_sm_ns = ST_IDLE;
                  end
              end

            ST_RD_CMD_RAM:
              begin
                if(((req_cnt < num_of_reqs) || msgst_infinite_pkt_run_start) && cmd_ram_rdcnt == 3'b110) 
                  msgst_sm_ns = ST_CTRL_PKT;                  
                else if((req_cnt == num_of_reqs) && !msgst_infinite_pkt_run_start)				
				  msgst_sm_ns = ST_IDLE;
              end            

            ST_CTRL_PKT:
              begin
                if(pld_length != 0)  begin
                  msgst_sm_ns = ST_DATA_GEN;
                  end
                else begin
                  msgst_sm_ns = ST_RD_CMD_RAM;
                  end
              end
			  
			  ST_DATA_GEN:
				begin
					if((req_cnt == num_of_reqs) && !msgst_infinite_pkt_run_start) 
						msgst_sm_ns = ST_IDLE;					
					else if((nxt_length <=32) && adptr_valid_reg && cdm_ready)
					begin
						if(!msgst_use_same_cmd)						
							msgst_sm_ns = ST_RD_CMD_RAM;
						else											
							msgst_sm_ns = ST_DATA_GEN;													
					end						
					else if(adptr_valid_reg && (!cdm_ready))
						msgst_sm_ns = ST_WAIT;
					else
						msgst_sm_ns = ST_DATA_GEN;
				end

            ST_WAIT:
              begin
                if(cdm_ready) 
				begin
					if((nxt_length <=32) && !msgst_use_same_cmd)
						msgst_sm_ns = ST_RD_CMD_RAM;
					else
						msgst_sm_ns = ST_DATA_GEN;
                end
              end

             default : 
                  msgst_sm_ns = ST_IDLE;
        endcase
    end 

   // State register
   always_ff @ (posedge clk ) begin 
     if(!rst_n) 
       msgst_sm_cs <= ST_IDLE;
     else 
       msgst_sm_cs <= msgst_sm_ns;
      end

   // Payload Length
   always_ff @ (posedge clk ) begin 
     if(!rst_n) begin 
       pld_length <= 9'b0;
       pld_length_offset <= 9'b0;
       end
     else begin
       if(cmd_ram_rdcnt == 1) 
         pld_length <= cmd_ram_din[8:0];
       else if(cmd_ram_rdcnt == 2) 
         //pld_length_offset <= pld_length + cmd_ram_din[30:26];
         pld_length_offset <= pld_length + cmd_ram_din[31:27];//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx
       else begin
         pld_length <= pld_length;
         pld_length_offset <= pld_length_offset;
         end
     end
   end

   // start offset
   always_ff @ (posedge clk ) begin 
     if(!rst_n) 
       start_offset <= 5'b0;
     else begin
       if(msgst_sm_cs == ST_CTRL_PKT) 
         //start_offset <= cmd_accumulator[62:58];
         start_offset <= cmd_accumulator[63:59];//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx
       else if(msgst_sm_cs == ST_PLD_RAM_WR1)
         start_offset <= 5'b0;
       else
         start_offset <= start_offset;
     end
   end 

   // CSI DST ID
   always_ff @ (posedge clk ) begin 
     if(!rst_n) 
       csi_dst_id <= 5'b0;
     else begin
	 if(cmd_ram_rdcnt == 2) begin
       //csi_dst_id <= cmd_ram_din[25:21];
       csi_dst_id <= cmd_ram_din[26:22];//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx
       end
      end
   end
   
    always_ff @ (posedge clk ) begin 
     if(!rst_n) begin
       dest_host <= 1'b0;
       dest_psx <= 1'b0;
	   end
     else begin
	 if(csi_dst_id == 5'h4 || csi_dst_id == 5'h5 || csi_dst_id == 5'h6 || csi_dst_id == 5'h7) 
		dest_host <= 1'b1;
	 else if(csi_dst_id == 5'hC)
		dest_psx <= 1'b1;
	 else begin
		dest_host <= 1'b0;
        dest_psx <= 1'b0;
	 end
     end
   end
 
   //  Host address register
   always_ff @ (posedge clk) begin 
     if(!rst_n) begin 
       pci_host_addr_reg <= 64'b0;
       pci_pasid_reg     <= 23'b0;
       pci_requester_id_reg <= 16'b0;
       psx_host_addr_reg <= 64'b0;
       psx_pasid_reg     <= 23'b0;
       psx_requester_id_reg <= 16'b0;
       end
     else begin
        if(pld_cmd_req_pls) begin 
          pci_host_addr_reg    <= pci_host_addr;
          pci_pasid_reg        <= pci_pasid;
          pci_requester_id_reg <= pci_requester_id;
          psx_host_addr_reg    <= psx_host_addr;
          psx_pasid_reg        <= psx_pasid;
          psx_requester_id_reg <= psx_requester_id;
		end
     end
   end


   // Command Ram read address and enable generation 
   always_ff @ (posedge clk ) begin 
     if(!rst_n) begin 
       cmd_ram_addr_reg <= 16'b0;
       cmd_ram_rdcnt    <= 3'b0;
       end
     //else if(pld_cmd_req_pls || (cmd_ram_addr_reg == 16'h7FF8) ) begin 
     else if(pld_cmd_req_pls || (cmd_ram_addr_reg == 16'h80) ) begin //cmd_ram size is h'100
       cmd_ram_addr_reg <= 16'b0;
       cmd_ram_rdcnt    <= 3'b0;
       end
     else begin
       if(msgst_sm_cs == ST_RD_CMD_RAM && cmd_ram_rdcnt != 3'b110 ) begin
          cmd_ram_addr_reg <= cmd_ram_addr_reg + 4'b0100;
          cmd_ram_rdcnt    <= cmd_ram_rdcnt + 1'b1;
          end
       //else if (msgst_eop_reg && cdm_ready) begin
       else if (cmd_ram_rdcnt == 3'b110) begin
          //cmd_ram_addr_reg <= cmd_ram_addr_reg + 4'b1000;
          //cmd_ram_addr_reg <= cmd_ram_addr_reg;//Srinadh - adjusting the address to get to the first cycle of second msgst command
          cmd_ram_addr_reg <= 16'b0;//Srinadh - reading same command
		  cmd_ram_rdcnt    <= 3'b0;
          end         
       else begin                                       
          cmd_ram_addr_reg <= cmd_ram_addr_reg ;        
          cmd_ram_rdcnt    <= 3'b0;                     
          end                                           
     end                                                
    end                                                 
                                                        
   // Payload Ram read address and enable generation    
   always_ff @ (posedge clk ) begin                     
     if(!rst_n) begin                                   
       pld_ram_addr_reg <= 15'b0;                       
       end                                              
     else if(pld_cmd_req_pls) begin                     
       pld_ram_addr_reg <= 15'b0;                       
       end                                             
     else begin                                         
       //if(msgst_sm_cs == ST_DATA_GEN || msgst_sm_cs == ST_DATA_GEN1) begin
       if(pld_ram_wen_pls[31]) 
          pld_ram_addr_reg <= pld_ram_addr_reg + 'h20;
       else 
          pld_ram_addr_reg <= pld_ram_addr_reg;         
     end                                                
    end                                                 
                                                        
   always_ff @ (posedge clk ) begin                     
     if(!rst_n) 
       pld_ram_addr_reg1 <= 15'b0;                       
     else 
       pld_ram_addr_reg1 <= pld_ram_addr_reg;                       
   end
 

   // Command bytes accumulator
   always_ff @ (posedge clk ) begin 
     if(!rst_n) begin 
       cmd_accumulator <= 192'b0;
       end
     else if(pld_cmd_req_pls) begin 
       cmd_accumulator <= 192'b0;
       end
     else begin
       if(msgst_sm_cs == ST_RD_CMD_RAM ) begin
        cmd_accumulator <= {cmd_ram_din,cmd_accumulator[191:32]} ;
       end
     end
   end
     
   // Msg Store request Counter
   always_ff @ (posedge clk) begin 
     if(!rst_n) begin 
       req_cnt <= 15'b0;
       end
     else begin
       if(pld_cmd_req_pls == 1'd1) begin
         req_cnt <= 15'b0;
         end
       //else if((msgst_sm_cs == ST_CTRL_PKT) || (msgst_use_same_cmd && (msgst_sm_cs == ST_DATA_GEN)) && cdm_ready) begin
       else if(msgst_eop_nxt && cdm_ready) begin
         req_cnt <= req_cnt + 1'b1;
         end
       else begin
         req_cnt <= req_cnt;
       end
       end
     end
	 

  // Host address generation Per requests
   always_ff @ (posedge clk) begin 
     if(!rst_n) begin 
       host_addr_reg <= 64'b0;
       end
     else begin
		if(msgst_sm_cs == ST_CTRL_PKT && dest_host && (req_cnt == 0)) 
          host_addr_reg <= pci_host_addr_reg;
        else if(msgst_sm_cs == ST_CTRL_PKT && dest_psx && (req_cnt == 0))
          host_addr_reg <= psx_host_addr_reg;        
        else if (adptr_valid_reg && cdm_ready && msgst_eop_nxt)
         host_addr_reg <= host_addr_reg + pld_length ;        
        else
         host_addr_reg <= host_addr_reg;
     end
   end
   
 
   
   // output assignments

    assign cmd_ram_addr =  {16'b0,cmd_ram_addr_reg};
    assign cmd_ram_ren  =  (msgst_sm_cs == ST_RD_CMD_RAM && cmd_ram_rdcnt != 3'b110) ? 1'b1 : 1'b0 ;

    assign pld_ram_addr =  {17'b0,pld_ram_addr_reg};
    assign pld_ram_din   =  (sr_switch) ? pld_ram_data_reg[127:96] : pld_ram_data_reg[95:64]; 
    assign pld_ram_wen_gen  =  (sr_switch) ? pld_ram_wen_shift[127:96] : pld_ram_wen_shift[95:64]; 
    assign pld_ram_wen     = pld_ram_wen_pls; 
	
	always_ff @ (posedge clk) begin 
		if(!rst_n) 
			pld_pkt_id <= 32'b0;
		else
			//if(msgst_eop_reg)
			if(msgst_eop_nxt)
				pld_pkt_id <= pld_pkt_id + 1'b1;
			else
				pld_pkt_id <= pld_pkt_id;
	end
	
	assign data_reg1[0] = (seq_count == 8'h00) ? pld_length[7:0]  : data_reg[0];
	assign data_reg1[1] = (seq_count == 8'h00) ? pld_pkt_id[7:0]  : data_reg[1];
	assign data_reg1[2] = (seq_count == 8'h00) ? pld_pkt_id[15:8] : data_reg[2];
	assign data_reg1[3] = (seq_count == 8'h00) ? pld_pkt_id[23:16]: data_reg[3];
	assign data_reg1[4] = (seq_count == 8'h00) ? pld_pkt_id[31:24]: data_reg[4];
	
	 genvar k;
    generate
        for (k=5; k < 31; k++) begin            
            assign data_reg1[k][7:0] = data_reg[k];
        end
    endgenerate

	generate
	genvar crc_i;
	for (crc_i = 0; crc_i < 8; crc_i = crc_i+1) begin 		
		assign crc[crc_i] = data_reg1[30][crc_i] ^ data_reg1[26][crc_i] ^ data_reg1[21][crc_i] ^ data_reg1[17][crc_i] ^ data_reg1[13][crc_i] ^ data_reg1[10][crc_i] ^ data_reg1[7][crc_i] ^ data_reg1[1][crc_i];
	end
	endgenerate	
	
	assign data_reg1[31][7:0] = crc;
                            
                            

//	assign adptr_valid  = adptr_valid_reg;      
    assign req_done     = ((req_cnt == num_of_reqs) && (num_of_reqs!=0)) ? 1'b1 : 1'b0;

    // MSGST data assigments 
 // always @(*) begin
 //    if(msgst_sm_cs == ST_PLD_RAM_RD || msgst_sm_cs == ST_EOP_WT_1 || msgst_sm_cs == ST_EOP_WT_2) begin
    assign fab0_cmpt_msgst.intf.dat                   = {data_reg1[31],data_reg1[30],data_reg1[29],data_reg1[28],data_reg1[27],data_reg1[26],data_reg1[25],data_reg1[24],
                                                     data_reg1[23],data_reg1[22],data_reg1[21],data_reg1[20],data_reg1[19],data_reg1[18],data_reg1[17],data_reg1[16],
                                                     data_reg1[15],data_reg1[14],data_reg1[13],data_reg1[12],data_reg1[11],data_reg1[10],data_reg1[9], data_reg1[8],
                                                     data_reg1[7], data_reg1[6], data_reg1[5], data_reg1[4], data_reg1[3], data_reg1[2], data_reg1[1], data_reg1[0]};

    assign fab0_cmpt_msgst.intf.eop                   = msgst_eop_nxt;
//    assign fab0_cmpt_msgst.intf.eop                   = msgst_eop_reg;

    //assign fab0_cmpt_msgst.intf.ecc                   = 11'b0;
    assign fab0_cmpt_msgst.intf.ecc                   = cmd_accumulator[170:160];
    assign fab0_cmpt_msgst.intf.length                = cmd_accumulator[8:0];
    assign fab0_cmpt_msgst.intf.op                    = cmd_accumulator[10:9];
    //assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_op           = cmd_accumulator[12:11];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_op           = cmd_accumulator[53:52];//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_line_size    = cmd_accumulator[48];

       // Address Assignments 
    //assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr.u.imm.translated = cmd_accumulator[31];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr.u.imm.translated = cmd_accumulator[29];//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr.u.imm.addr = dest_host ? {pci_host_addr_mask [63:12], host_addr_reg[11:0]} : dest_psx ? {ap_id,psx_host_addr_mask[57:12], host_addr_reg[11:0]} :64'h0;
    //assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr.use_addr_tbl__reserved = cmd_accumulator[30];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr.use_addr_tbl__reserved = cmd_accumulator[28];//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx

       // WC
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_id           = cmd_accumulator[47:32];
	//assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_id           = 'd0;	//Using this field for seed now
    //assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_timeout_idx  = cmd_accumulator[52:49];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_timeout_idx  = cmd_accumulator[51:49];//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx

       // Addr_spc
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.u.imm.csi_dst_fifo = cmd_accumulator[91:83];
    //assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.u.imm.csi_dst_fifo = 'd0;	//Not using this for seed now
    //assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.u.imm.csi_dst      = cmd_accumulator[57:53];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.u.imm.csi_dst      = cmd_accumulator[58:54];//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx

    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.u.imm.fnc          = dest_host ? pci_requester_id_reg : (dest_psx ? psx_requester_id_reg : pci_requester_id_reg );
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.u.imm.pasid        = dest_host ? pci_pasid_reg : (dest_psx ? psx_pasid_reg : pci_pasid_reg );

    //assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.use_addr_spc_tbl__reserved = cmd_accumulator[13];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.use_addr_spc_tbl__reserved = cmd_accumulator[11];//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx

    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.response_req    = cmd_accumulator[64];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.response_cookie = cmd_accumulator[76:65];
    //assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.start_offset    = cmd_accumulator[62:58];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.start_offset    = cmd_accumulator[63:59];//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx
    assign fab0_cmpt_msgst.intf.data_width            = cmd_accumulator[78:77];
    assign fab0_cmpt_msgst.intf.client_id             = cmd_accumulator[82:79];
    /*assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.st2m_ordered    = 1'b0;
   	assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.tph    = 11'd0;
   	assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.attr    = 3'd0;
    assign fab0_cmpt_msgst.intf.wait_pld_pkt_id      = 16'b0;  */
	
	assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.st2m_ordered    = cmd_accumulator[99];
   	assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.tph    = cmd_accumulator[154:144];
   	assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.attr    = cmd_accumulator[98:96];
    assign fab0_cmpt_msgst.intf.wait_pld_pkt_id      = cmd_accumulator[115:100];
	
    assign fab0_cmpt_msgst.vld                        = adptr_valid_reg;     
    assign cdm_ready                                  = fab0_cmpt_msgst.rdy;     
        
    // end
  //end 
 
endmodule





