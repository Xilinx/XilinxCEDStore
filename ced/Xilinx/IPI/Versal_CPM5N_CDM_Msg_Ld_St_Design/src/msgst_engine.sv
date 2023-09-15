`timescale 1 ns / 1 ps


module msgst_engine


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
    input [22:0] pci_pasid,
    input [15:0] pci_requester_id,

    input [63:0] psx_host_addr,
    input [22:0] psx_pasid,
    input [15:0] psx_requester_id,

    input [14:0] num_of_reqs,
    output      req_done,
    // Payload RAM read control input    
    input        pld_cmd_req,
      
    // MSGST adapter CDM interface
    cdx5n_cmpt_msgst_if.m    fab0_cmpt_msgst


);

    typedef enum logic [3:0]    {
        ST_IDLE = 0,ST_RD_CMD_RAM = 1,ST_CTRL_PKT = 2, ST_DATA_GEN = 3, ST_DATA_GEN1 = 4,ST_WAIT = 5 ,ST_PLD_RAM_WR1 = 6 ,ST_PLD_RAM_WR2 = 7
     } msgst_sm_type; 
         
    msgst_sm_type msgst_sm_cs, msgst_sm_ns;

    logic [14:0] pld_ram_addr_reg;
    logic [13:0] pld_ram_addr_reg1;
           
    logic [15:0] cmd_ram_addr_reg;
    logic [1:0]  cmd_ram_rdcnt;   
    logic [14:0]  req_cnt;   

    logic [95:0]  cmd_accumulator;
    logic [8:0]   pld_length;
    logic [8:0]   pld_length_offset;
    logic [4:0]   csi_dst_id;

    logic pld_cmd_req_pls;
    logic pld_cmd_req_ff;
    logic adptr_valid_reg;
    logic msgst_eop_reg;
	
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
    logic [7:0] seq_count;
    logic [8:0] nxt_length;

    logic [8:0] rand_length;
    logic [8:0] rand_length_nxt;
    logic feedback;
    
    logic [127:0][7:0] pld_ram_data_reg;
    
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
   
    assign msgst_eop_reg = (((msgst_sm_cs == ST_DATA_GEN && pld_length_offset <=32)  || 
                                                    (msgst_sm_cs == ST_DATA_GEN1 && nxt_length<=32 ) || (msgst_sm_cs == ST_CTRL_PKT && pld_length == 0)) || (msgst_sm_cs == ST_WAIT && (!cdm_ready) && nxt_length<=32)) ? 1'b1 : 1'b0; 
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
       if(msgst_sm_ns == ST_DATA_GEN   || msgst_sm_ns == ST_DATA_GEN1 || (msgst_sm_ns == ST_CTRL_PKT && pld_length == 0 )) 
         adptr_valid_reg <= 1'b1;
       else if(adptr_valid_reg && (!cdm_ready)) 
         adptr_valid_reg <= adptr_valid_reg;
       else
         adptr_valid_reg <= 1'b0;
     end
   end 


    // Payload length decrement counter
    always_ff @(posedge clk) begin
      if(!rst_n)
        nxt_length <= 8'b0;
      else begin 
        if(msgst_sm_cs == ST_CTRL_PKT)         
         nxt_length <= pld_length_offset;
        else if(msgst_sm_ns == ST_DATA_GEN1)
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
                if(req_cnt< num_of_reqs && cmd_ram_rdcnt == 2'b11) begin
                  msgst_sm_ns = ST_CTRL_PKT;
                  end
                else if(req_cnt == num_of_reqs) begin
                  msgst_sm_ns = ST_IDLE;
                  end
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

           ST_DATA_GEN :
             begin
               msgst_sm_ns = ST_PLD_RAM_WR1;
             end
           
           ST_PLD_RAM_WR1:
             begin               
               if(pld_length_offset<=32 && pld_length_offset != 0) 
                  msgst_sm_ns = ST_RD_CMD_RAM;
               else if(pld_length_offset>32 ) 
                  msgst_sm_ns = ST_DATA_GEN1;
              end

          
           ST_DATA_GEN1 :
             begin
               if(adptr_valid_reg && cdm_ready) 
                 msgst_sm_ns = ST_PLD_RAM_WR2;
               else if(adptr_valid_reg && (!cdm_ready)) 
                  msgst_sm_ns = ST_WAIT;
             end

           ST_PLD_RAM_WR2:
             begin
               if(nxt_length <=32)
                 msgst_sm_ns = ST_RD_CMD_RAM;
               else if(adptr_valid_reg && (!cdm_ready))
                  msgst_sm_ns = ST_WAIT;
               else
                  msgst_sm_ns = ST_DATA_GEN1;
             end

            ST_WAIT:
              begin
                if(adptr_valid_reg && cdm_ready) begin
                  msgst_sm_ns = ST_PLD_RAM_WR2;
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
         pld_length_offset <= pld_length + cmd_ram_din[30:26];
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
         start_offset <= cmd_accumulator[63:59];
       else if(msgst_sm_cs == ST_PLD_RAM_WR1)
         start_offset <= 5'b0;
       else
         start_offset <= start_offset;
     end
   end 

   // CSI DST ID
   always_ff @ (posedge clk ) begin 
     if(!rst_n) 
       csi_dst_id <= 9'b0;
     else begin
	 if(cmd_ram_rdcnt == 2) begin      
       csi_dst_id <= cmd_ram_din[26:22];
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
       cmd_ram_rdcnt    <= 2'b0;
       end
     else if(pld_cmd_req_pls || (cmd_ram_addr_reg == 16'h7FF8) ) begin 
       cmd_ram_addr_reg <= 16'b0;
       cmd_ram_rdcnt    <= 2'b0;
       end
     else begin
       if(msgst_sm_cs == ST_RD_CMD_RAM && cmd_ram_rdcnt != 2'b11 ) begin
          cmd_ram_addr_reg <= cmd_ram_addr_reg + 4'b0100;
          cmd_ram_rdcnt    <= cmd_ram_rdcnt + 1'b1;
          end
       else if (msgst_eop_reg && cdm_ready) begin
          cmd_ram_addr_reg <= cmd_ram_addr_reg + 4'b1000;
          end
         
       else begin                                       
          cmd_ram_addr_reg <= cmd_ram_addr_reg ;        
          cmd_ram_rdcnt    <= 2'b0;                     
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
       if(pld_ram_wen_pls[31]) 
          pld_ram_addr_reg <= pld_ram_addr_reg + 'h20;
       else 
          pld_ram_addr_reg <= pld_ram_addr_reg;         
     end                                                
    end                                                 
                                                        
   always_ff @ (posedge clk ) begin                     
     if(!rst_n) 
       pld_ram_addr_reg1 <= 14'b0;                       
     else 
       pld_ram_addr_reg1 <= pld_ram_addr_reg;                       
   end
 

   // Command bytes accumulator
   always_ff @ (posedge clk ) begin 
     if(!rst_n) begin 
       cmd_accumulator <= 96'b0;
       end
     else if(pld_cmd_req_pls) begin 
       cmd_accumulator <= 96'b0;
       end
     else begin
       if(msgst_sm_cs == ST_RD_CMD_RAM ) begin
        cmd_accumulator <= {cmd_ram_din,cmd_accumulator[95:32] } ;
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
       else if(msgst_sm_cs == ST_CTRL_PKT) begin
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
		if(msgst_sm_cs == ST_CTRL_PKT && csi_dst_id == 'h4)		
          host_addr_reg <= pci_host_addr_reg;
        else if(msgst_sm_cs == ST_CTRL_PKT && csi_dst_id == 'hC && (req_cnt == 0))
          host_addr_reg <= psx_host_addr_reg;
        else if (adptr_valid_reg && msgst_eop_reg)
         host_addr_reg <= host_addr_reg + pld_length ;        
        else
         host_addr_reg <= host_addr_reg;
     end
   end
   
 
   
   // output assignments

    assign cmd_ram_addr =  {16'b0,cmd_ram_addr_reg};
    assign cmd_ram_ren  =  (msgst_sm_cs == ST_RD_CMD_RAM && cmd_ram_rdcnt != 2'b11) ? 1'b1 : 1'b0 ;

    assign pld_ram_addr =  {17'b0,pld_ram_addr_reg};
    assign pld_ram_din   =  (sr_switch) ? pld_ram_data_reg[127:96] : pld_ram_data_reg[95:64]; 
    assign pld_ram_wen_gen  =  (sr_switch) ? pld_ram_wen_shift[127:96] : pld_ram_wen_shift[95:64]; 
    assign pld_ram_wen     = pld_ram_wen_pls; 
                            
                            
                            

    
    assign req_done     = ((req_cnt == num_of_reqs) && (num_of_reqs!=0)) ? 1'b1 : 1'b0;

    // MSGST data assigments 
    assign fab0_cmpt_msgst.intf.dat                   = {data_reg[31],data_reg[30],data_reg[29],data_reg[28],data_reg[27],data_reg[26],data_reg[25],data_reg[24],
                                                     data_reg[23],data_reg[22],data_reg[21],data_reg[20],data_reg[19],data_reg[18],data_reg[17],data_reg[16],
                                                     data_reg[15],data_reg[14],data_reg[13],data_reg[12],data_reg[11],data_reg[10],data_reg[9], data_reg[8],
                                                     data_reg[7], data_reg[6], data_reg[5], data_reg[4], data_reg[3], data_reg[2], data_reg[1], data_reg[0]};

    assign fab0_cmpt_msgst.intf.eop                   = msgst_eop_reg;

    assign fab0_cmpt_msgst.intf.ecc                   = 11'b0;
    assign fab0_cmpt_msgst.intf.length                = cmd_accumulator[8:0];
    assign fab0_cmpt_msgst.intf.op                    = cmd_accumulator[10:9];
  
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_op           = cmd_accumulator[53:52];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_line_size    = cmd_accumulator[48];

       // Address Assignments    
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr.u.imm.translated = cmd_accumulator[29];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr.u.imm.addr = host_addr_reg;
    
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr.use_addr_tbl__reserved = cmd_accumulator[28];

       // WC    
	assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_id           = 'd0;	    
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.wc_timeout_idx  = cmd_accumulator[51:49];

       // Addr_spc
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.u.imm.csi_dst_fifo = cmd_accumulator[91:83];    
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.u.imm.csi_dst      = cmd_accumulator[58:54];

    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.u.imm.fnc          = (csi_dst_id == 'h4) ? pci_requester_id_reg : ((csi_dst_id == 'hC) ? psx_requester_id_reg : pci_requester_id_reg );
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.u.imm.pasid        = (csi_dst_id == 'h4) ? pci_pasid_reg : ((csi_dst_id == 'hC) ? psx_pasid_reg : pci_pasid_reg );
    
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.addr_spc.use_addr_spc_tbl__reserved = cmd_accumulator[11];

    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.response_req    = cmd_accumulator[64];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.response_cookie = cmd_accumulator[76:65];    
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.start_offset    = cmd_accumulator[63:59];
    assign fab0_cmpt_msgst.intf.data_width            = cmd_accumulator[78:77];
    assign fab0_cmpt_msgst.intf.client_id             = cmd_accumulator[82:79];
    assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.st2m_ordered    = 1'b0;
   	assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.tph    = 11'd0;
   	assign fab0_cmpt_msgst.intf.u.cdm_bal.cdm.attr    = 3'd0;
    assign fab0_cmpt_msgst.intf.wait_pld_pkt_id      = 16'b0;     
    assign fab0_cmpt_msgst.vld                        = adptr_valid_reg;     
    assign cdm_ready                                  = fab0_cmpt_msgst.rdy;     
        

 
endmodule





