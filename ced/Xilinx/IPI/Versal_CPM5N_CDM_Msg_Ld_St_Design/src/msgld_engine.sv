`timescale 1 ps / 1 ps

module msgld_engine
(
    input clk,
    input rst_n,
 
    // Payload Ram Read interface  
    output [255:0] pld_ram_dout,
    output [31:0]  pld_ram_wen,
    output [31:0] pld_ram_addr,

   // MSGST/MSGLD Response Ram write interface  
    output logic [31:0] rsp_ram_dout,
    output logic [3:0]  rsp_ram_wen,
    output [31:0] rsp_ram_addr,

    // Command Ram Read interface  
    input [31:0]  cmd_ram_din,
    output        cmd_ram_ren,
    output [31:0] cmd_ram_addr,

    // Control and status register 
    input [63:0] pci_host_addr,
    input [22:0] pci_pasid,
    input [15:0] pci_requester_id,

    input [63:0] psx_host_addr,
    input [22:0] psx_pasid,
    input [15:0] psx_requester_id,

    input [14:0]  num_of_reqs,
    output       req_done,
    input        cmd_rd_start,

    input        start_pkt_count,
    output [31:0]  pkt_pass_count,
    output [31:0]  pkt_fail_count,

    // MSGLD/MSGST Response interface
    cdx5n_mm_byp_out_rsp_if.s               fab0_byp_out_msgld_dat,

    // MSGLD Request interface
    cdx5n_dsc_crd_in_msgld_req_if.m         fab0_dsc_crd_msgld_req
    
);

 typedef enum logic [2:0]    {
        ST_REQ_IDLE = 0, ST_RD_CMD_RAM = 1, ST_CTRL_PKT = 2, ST_WAIT = 3 ,ST_DELAY = 4, ST_FIFO_FULL=5
     } msgld_req_sm_type; 

 msgld_req_sm_type msgld_req_sm_cs, msgld_req_sm_ns;


 typedef enum logic [1:0]    {
        ST_DATA_IDLE = 0, ST_CHK_START = 1,ST_LIVE_CHK = 2,ST_MSGLD_LEN_FIFO_RD = 3
     } msgld_data_sm_type; 

 msgld_data_sm_type msgld_data_sm_cs, msgld_data_sm_ns;

  logic        cdm_ready;
  logic [14:0]  req_cnt;
  logic [14:0]  rsp_cnt;
  logic        eop_valid;
  logic        msgld_data_valid;
  logic [255:0] msgld_data;
  logic [11:0] rsp_cookie;
  logic [31:0] pld_ram_addr_reg;
  logic [8:0]   pld_length;
  logic [31:0] rsp_ram_addr_reg;
  logic [3:0]  rsp_ram_wen_reg;
  logic [15:0] cmd_ram_addr_reg;
  logic [1:0]  cmd_ram_rdcnt;   
  logic adptr_valid_reg;
  logic [95:0]  cmd_accumulator;
  logic        cmd_rd_start_pls;
  logic        cmd_rd_start_ff;
  logic [63:0] pci_host_addr_reg;
  logic [22:0] pci_pasid_reg;
  logic [15:0] pci_requester_id_reg;
  logic [63:0] psx_host_addr_reg;
  logic [22:0] psx_pasid_reg;
  logic [15:0] psx_requester_id_reg;
  logic [63:0] host_addr_reg;
  logic [4:0]  csi_dst_id;
  logic [2:0]  delay_cnt;
 
  
   logic [5:0] mask_sel;
   logic [31:0] data_byte_mask;
   logic [31:0][7:0]   data_reg;
   logic [8:0] nxt_length;
   logic [8:0] fifo_out_len;
   logic [11:0] fifo_out_rsp_cki;
   logic pld_len_fifo_rd;
   logic pld_len_fifo_wr;
   logic pld_len_fifo_empty;
   logic pld_len_fifo_full;
   logic msgld_fifo_empty;
   logic msgld_fifo_rd;
   logic msgld_fifo_full;
   logic msgld_fifo_rd_reg;
   logic msgld_fifo_rd_reg1;
   logic data_error;
   logic data_error_reg;
   logic data_error_pls;
   logic msgld_data_valid_reg;
   logic msgld_data_valid_reg1;
   logic [7:0] seq_count;

    logic [31:0]  pass_count;
    logic [31:0]  fail_count;
    logic [39:0]  msgld_req_log;
    logic [39:0]  fifo_log_data;
    logic [7:0]  count_seed;
    logic [1:0]  dump_wr_cnt;
    logic [1:0]  dump_wr;
    logic [1023:0] error_dump_reg;
    logic [255:0] pld_ram_data_reg;
    logic [4:0] start_offset;
    logic [8:0] length_offset;

  assign eop_valid = fab0_byp_out_msgld_dat.intf.eop & fab0_byp_out_msgld_dat.vld & (~msgld_fifo_full);
  assign msgld_data_valid = fab0_byp_out_msgld_dat.vld;
  
  assign fab0_byp_out_msgld_dat.rdy = (~msgld_fifo_full);
  

  
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


  always_ff @ (posedge clk) begin 
    if(!rst_n) begin 
      msgld_data_valid_reg <= 1'b0;
      msgld_data_valid_reg1 <= 1'b0;
      end
    else begin 
         msgld_data_valid_reg <= msgld_data_valid;
         msgld_data_valid_reg1 <= msgld_data_valid_reg;
         end
  end

  always_ff @ (posedge clk) begin 
    if(!rst_n) begin 
      msgld_fifo_rd_reg <= 1'b0;
      msgld_fifo_rd_reg1 <= 1'b0;
      end
    else begin 
         msgld_fifo_rd_reg <= msgld_fifo_rd;
         msgld_fifo_rd_reg1 <= msgld_fifo_rd_reg;
         end
  end

 // sequence counter
  always_ff @ (posedge clk) begin 
    if(!rst_n) begin 
      seq_count <= 8'h00;
      end
    else if(cmd_rd_start_pls) begin                     
      seq_count <= 8'h00;
      end
    else begin
      if(msgld_data_sm_cs == ST_CHK_START && msgld_fifo_rd_reg)
        seq_count <= count_seed;
      else if ((msgld_data_sm_cs == ST_LIVE_CHK && msgld_fifo_rd_reg1) && (mask_sel !=0)) 
        seq_count <= data_reg[mask_sel-1] + 1'b1;
    end
  end

    // Data comparison and error counter
   always_ff @ (posedge clk) begin 
     if(!rst_n) 
       data_error <= 1'b0;
     else begin
       if (pld_len_fifo_rd || cmd_rd_start_pls) 
         data_error <= 1'b0;
       else if((data_reg != msgld_data) && msgld_fifo_rd_reg1)  
          data_error <= 1'b1;
       else 
          data_error <= data_error;
     end
   end
          
   // Edge detection of data error signal
    always_ff @(posedge clk) begin
      if(!rst_n)
        data_error_reg <= 1'b0;
      else
        data_error_reg <= data_error;
    end

    assign data_error_pls = data_error & (~data_error_reg);

  //Pass and fail counters
  always_ff @ (posedge clk) begin 
    if(!rst_n) begin 
      pass_count <= 32'b0;
      fail_count <= 32'b0;
      end
    else if(!start_pkt_count) begin
      pass_count <= 32'b0;
      fail_count <= 32'b0;
      end
    else begin
      if(start_pkt_count && data_error_pls ) begin // Fail count
        pass_count <= pass_count ;
        fail_count <= fail_count + 1'b1;
        end
      else if(((data_reg == msgld_data) && msgld_fifo_rd_reg1)  && msgld_data_sm_cs == ST_DATA_IDLE && (!data_error)) begin 
        pass_count <= pass_count + 1'b1;
        fail_count <= fail_count ;
        end
      else begin
        pass_count <= pass_count ;
        fail_count <= fail_count;
        end
      end
    end
    assign pkt_pass_count = pass_count;
    assign pkt_fail_count = fail_count;

   // Error dump register
   always_ff @ (posedge clk) begin 
     if(!rst_n) 
       error_dump_reg <= 1024'b0;
     else begin
       if((data_reg != msgld_data) && msgld_fifo_rd_reg1 && dump_wr_cnt == 0) begin  
         error_dump_reg[255:0]   <=  {195'b0,pass_count,count_seed,fifo_out_rsp_cki,nxt_length};
         error_dump_reg[511:256] <= data_reg;
         error_dump_reg[767:512] <= msgld_data;
         end
       else 
          error_dump_reg <= error_dump_reg;
     end
   end

  
    always @ (*) begin
      case (dump_wr_cnt)
         2'b01 : pld_ram_data_reg = error_dump_reg[255:0];
         2'b10 : pld_ram_data_reg = error_dump_reg[511:256];
         2'b11 : pld_ram_data_reg = error_dump_reg[767:512];
         2'b00 : pld_ram_data_reg = error_dump_reg[767:512];
      endcase
    end
   
         

   // Payload Dump error write generation
   always_ff @ (posedge clk) begin 
     if(!rst_n) begin 
       dump_wr <= 1'b0;
       dump_wr_cnt <= 2'b0;
       end
    else if(!start_pkt_count) begin                     
       dump_wr <= 1'b0;
       dump_wr_cnt <= 2'b0;
       end
     else begin
       if(((data_reg != msgld_data) && msgld_fifo_rd_reg1) && dump_wr_cnt != 3) begin 
         dump_wr <= 1'b1;
         dump_wr_cnt <= dump_wr_cnt + 1'b1;
         end
       else begin
         dump_wr <= 1'b0;
         dump_wr_cnt <= dump_wr_cnt;
         end
     end
   end

   // Payload RAM address data generatio for error dump
   always_ff @ (posedge clk) begin 
     if(!rst_n) 
       pld_ram_addr_reg <= 32'b0; 
     else if(cmd_rd_start_pls) 
       pld_ram_addr_reg <= 32'b0; 
     else begin
       if(dump_wr)
         pld_ram_addr_reg <= pld_ram_addr_reg + 32'h20; 
       else
         pld_ram_addr_reg <= pld_ram_addr_reg;
     end
   end


   assign mask_sel = (nxt_length>32) ? 6'h20 : nxt_length;


   // Payload length decrement counter
    always_ff @(posedge clk) begin
      if(!rst_n)
        nxt_length <= 8'b0;
      else begin 
        if(msgld_data_sm_cs == ST_CHK_START)         
         nxt_length <= length_offset;        
        else if(msgld_fifo_rd && (!msgld_fifo_empty) &&(nxt_length>32) )
          nxt_length <= nxt_length - 32;
        else
          nxt_length <= nxt_length; 
      end    
    end

   // Edge detection of pld_cmd_req_signal
    always_ff @(posedge clk) begin
      if(!rst_n)
        cmd_rd_start_ff <= 1'b0;
      else
        cmd_rd_start_ff <= cmd_rd_start;
    end

    assign cmd_rd_start_pls = cmd_rd_start & (~cmd_rd_start_ff);

    // Response counter 
    always_ff @(posedge clk) begin
      if(!rst_n)
        rsp_cnt <= 15'b0;
      else
		if (cmd_rd_start_pls == 1'd1)
			rsp_cnt <= 15'b0;
        else if(eop_valid && (rsp_cnt != num_of_reqs)) begin
          rsp_cnt <= rsp_cnt + 1'b1;
          end
        else begin
          rsp_cnt <= rsp_cnt; 
        end    
         
    end
    
    // Delay count between Requests
     always_ff @(posedge clk) begin
      if(!rst_n)
        delay_cnt <= 3'b0;
      else 
         if(msgld_req_sm_cs == ST_DELAY) begin  
         delay_cnt <= delay_cnt + 1'b1;
         end
    end

   // State machine to Handle Load Request generation
    always @ (*) begin
        msgld_req_sm_ns =  msgld_req_sm_cs;
 
        case (msgld_req_sm_cs)
            ST_REQ_IDLE:
              begin
                if(cmd_rd_start_pls) begin
                  msgld_req_sm_ns = ST_RD_CMD_RAM;
                end
                else begin
                  msgld_req_sm_ns = ST_REQ_IDLE;
                end
              end

            ST_RD_CMD_RAM:
              begin
                if(req_cnt< num_of_reqs && cmd_ram_rdcnt == 2'b11) begin
                    msgld_req_sm_ns = ST_CTRL_PKT;
                  end
                else if(req_cnt == num_of_reqs) begin
                  msgld_req_sm_ns = ST_REQ_IDLE;
                  end
              end

            ST_CTRL_PKT:
              begin
                if (pld_len_fifo_full)
                  msgld_req_sm_ns = ST_FIFO_FULL;
                else if(adptr_valid_reg && (!cdm_ready))
                  msgld_req_sm_ns = ST_WAIT;
                else if(adptr_valid_reg && cdm_ready)
                  msgld_req_sm_ns = ST_RD_CMD_RAM;
                else
                  msgld_req_sm_ns = ST_CTRL_PKT;
              end

            ST_FIFO_FULL:
              begin
                if (!pld_len_fifo_full)
                  msgld_req_sm_ns = ST_RD_CMD_RAM;
              end

            ST_DELAY :
              begin
                  if(delay_cnt == 7) begin
                    msgld_req_sm_ns = ST_RD_CMD_RAM;
                  end
              end

            ST_WAIT:
              begin
                if(adptr_valid_reg && cdm_ready) begin
                  msgld_req_sm_ns = ST_RD_CMD_RAM;
                end
              end

               
        endcase
    end 

    // State machine to Handle Data Checker
    always @ (*) begin
        msgld_data_sm_ns = msgld_data_sm_cs;
 
        case (msgld_data_sm_cs)
            ST_DATA_IDLE:
              begin
                if((!msgld_fifo_empty) && (!pld_len_fifo_empty)) begin
                  msgld_data_sm_ns = ST_MSGLD_LEN_FIFO_RD;
                end
                else begin
                  msgld_data_sm_ns = ST_DATA_IDLE;
                end
              end
     
           ST_MSGLD_LEN_FIFO_RD:
             begin
               msgld_data_sm_ns = ST_CHK_START;
             end

            ST_CHK_START:
              begin                
                if(length_offset<=32 && length_offset != 0) 
                  msgld_data_sm_ns = ST_DATA_IDLE;                
                else if(length_offset>32 ) 
                  msgld_data_sm_ns = ST_LIVE_CHK;
              end

            ST_LIVE_CHK:
              begin
               if(nxt_length <=32) 
                 msgld_data_sm_ns = ST_DATA_IDLE;
               else
                  msgld_data_sm_ns = ST_LIVE_CHK;
              end
        endcase
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
        if(cmd_rd_start_pls) begin 
          pci_host_addr_reg    <= pci_host_addr;
          pci_pasid_reg        <= pci_pasid;
          pci_requester_id_reg <= pci_requester_id;
          psx_host_addr_reg    <= psx_host_addr;
          psx_pasid_reg        <= psx_pasid;
          psx_requester_id_reg <= psx_requester_id;
		end
     end
   end


   // CSI DST ID
   always_ff @ (posedge clk ) begin 
     if(!rst_n) 
       csi_dst_id <= 9'b0;
     else begin
	 if(cmd_ram_rdcnt == 2) begin
       csi_dst_id <= cmd_ram_din[16:12];
       end
      end
   end

 
   // MSGLD REQ State register
   always_ff @ (posedge clk ) begin 
     if(!rst_n) 
       msgld_req_sm_cs <= ST_REQ_IDLE;
     else 
       msgld_req_sm_cs <= msgld_req_sm_ns;
      end

   // MSGLD Data State register
   always_ff @ (posedge clk ) begin 
     if(!rst_n) 
       msgld_data_sm_cs <= ST_DATA_IDLE;
     else 
       msgld_data_sm_cs <= msgld_data_sm_ns;
      end

   // Msg Load request Counter
   always_ff @ (posedge clk) begin 
     if(!rst_n) begin 
       req_cnt <= 15'b0;
       end
     else if(cmd_rd_start_pls || msgld_req_sm_cs == ST_REQ_IDLE) begin 
       req_cnt <= 15'b0;
       end
     else begin
       if(adptr_valid_reg && cdm_ready) begin
         req_cnt <= req_cnt + 1'b1;
         end
       else begin
         req_cnt <= req_cnt;
       end
       end
     end

   // Command Ram read address and enable generation 
   always_ff @ (posedge clk ) begin 
     if(!rst_n) begin 
       cmd_ram_addr_reg <= 16'b0;
       cmd_ram_rdcnt    <= 2'b0;
       end     
	 else if(cmd_rd_start_pls || (cmd_ram_addr_reg == 16'h4CC8)) begin	
       cmd_ram_addr_reg <= 16'b0;
       cmd_ram_rdcnt    <= 2'b0;
       end
     else begin
       if(msgld_req_sm_cs == ST_RD_CMD_RAM && cmd_ram_rdcnt != 2'b11 ) begin
          cmd_ram_addr_reg <= cmd_ram_addr_reg + 4'b0100;
          cmd_ram_rdcnt    <= cmd_ram_rdcnt + 1'b1;
          end
       else begin 
          cmd_ram_addr_reg <= cmd_ram_addr_reg ;
          cmd_ram_rdcnt    <= 2'b0;
          end
     end
    end
   
   // Command bytes accumulator
   always_ff @ (posedge clk ) begin 
     if(!rst_n) begin 
       cmd_accumulator <= 96'b0;
       end
     else if(cmd_rd_start_pls) begin 
       cmd_accumulator <= 96'b0;
       end
     else begin
       if(msgld_req_sm_cs == ST_RD_CMD_RAM ) begin
        cmd_accumulator <= {cmd_ram_din,cmd_accumulator[95:32] } ;
       end
     end
   end


   // Response Cookie register
   always_ff @ (posedge clk ) begin 
     if(!rst_n) 
       rsp_cookie <= 12'b0;
     else begin
	   if(eop_valid) begin
         rsp_cookie = fab0_byp_out_msgld_dat.intf.u.cdm.response_cookie;
         end
       else begin
         rsp_cookie <= rsp_cookie;
         end
      end
   end
  // Fill the Response cookie RAM address generation
   always_ff @ (posedge clk ) begin 
     if(!rst_n) begin 
       rsp_ram_addr_reg <= 32'b0;
       end
     else if(cmd_rd_start_pls) begin 
       rsp_ram_addr_reg <= 32'b0;
       end
     else 
       if(eop_valid) begin
         rsp_ram_addr_reg  <= rsp_ram_addr_reg + 4'h4;
         end
      else begin
         rsp_ram_addr_reg <= rsp_ram_addr_reg ;
         end
    end 

   // Respinse write enable generation
   always_ff @ (posedge clk ) begin 
     if(!rst_n) 
       rsp_ram_wen_reg <= 4'b0;
     else begin
       if(eop_valid)
         rsp_ram_wen_reg <= 4'b0011;
       else
         rsp_ram_wen_reg <= 4'b0;
     end
   end
 
     
    // Valid generation
   always_ff @ (posedge clk) begin 
     if(!rst_n) begin 
       adptr_valid_reg <= 1'b0;
       end
     else begin
       if((msgld_req_sm_cs == ST_CTRL_PKT || msgld_req_sm_cs == ST_WAIT) && (!cdm_ready))  
         adptr_valid_reg <= 1'b1;
       else
         adptr_valid_reg <= 1'b0;
     end
   end

   // Payload Length
   always_ff @ (posedge clk ) begin 
     if(!rst_n) 
       pld_length <= 9'b0;
     else begin
	 if(cmd_ram_rdcnt == 1) begin
       pld_length <= cmd_ram_din[8:0];
       end
      end
   end
  // Host address generation Per requests
   always_ff @ (posedge clk) begin 
     if(!rst_n) begin 
       host_addr_reg <= 'b0;
       end
     else begin		
        if (adptr_valid_reg && cdm_ready)
         host_addr_reg <= host_addr_reg + pld_length ;		
		else if(msgld_req_sm_cs == ST_CTRL_PKT && csi_dst_id == 'h4 ) 		
          host_addr_reg <= pci_host_addr_reg;
        else if(msgld_req_sm_cs == ST_CTRL_PKT && csi_dst_id == 'hC && (req_cnt == 0))
          host_addr_reg <= psx_host_addr_reg;
        else
         host_addr_reg <= host_addr_reg;
     end
   end

    // FIFO for logging the length
    // Type of start_offset, pattern, seed, response_cookie, pld_length
   assign msgld_req_log =  {cmd_accumulator[62:58],cmd_accumulator[88:87],cmd_accumulator[86:79],cmd_accumulator[75:64],pld_length};
  
  //length_fifo and msgld_fifo are part of a block design for versal cpm5n
  msgld_fifos_wrapper msgld_fifos_wrapper_inst
   (
	
	//msgld_fifo
	.FIFO_READ_0_empty(msgld_fifo_empty),
    .FIFO_READ_0_rd_data(msgld_data),
    .FIFO_READ_0_rd_en(msgld_fifo_rd),
	
    .FIFO_WRITE_0_full(msgld_fifo_full),
    .FIFO_WRITE_0_wr_data(fab0_byp_out_msgld_dat.intf.dsc),
    .FIFO_WRITE_0_wr_en(msgld_data_valid),
	
	.data_count_0(),
    .data_valid_0(),
    .overflow_0(),
    .prog_empty_0(),
    .prog_full_0(),
    .rd_data_count_0(),
    .rd_rst_busy_0(),
    .rst_0(~rst_n),
    .underflow_0(),
    .wr_ack_0(),
    .wr_clk_0(clk),
    .wr_data_count_0(),
    .wr_rst_busy_0(),
	
	//length fifo
    .FIFO_READ_1_empty(pld_len_fifo_empty),
    .FIFO_READ_1_rd_data(fifo_log_data),
    .FIFO_READ_1_rd_en(pld_len_fifo_rd),
    
    .FIFO_WRITE_1_full(pld_len_fifo_full),
    .FIFO_WRITE_1_wr_data(msgld_req_log),
    .FIFO_WRITE_1_wr_en(pld_len_fifo_wr),
	
    .data_count_1(),
    .prog_empty_1(),
    .prog_full_1(),
    .rd_data_count_1(),
    .rd_rst_busy_1(),
    .rst_1(~rst_n),
    .wr_clk_1(clk),
    .wr_data_count_1(),
    .wr_rst_busy_1());

  assign fifo_out_len = fifo_log_data[8:0];
  assign count_seed = fifo_log_data[28:21];
  assign fifo_out_rsp_cki = fifo_log_data[20:9];  
  assign length_offset = (msgld_data_sm_cs == ST_CHK_START ) ? (fifo_log_data[8:0] + fifo_log_data[35:31]): 9'b0;
  
   always_ff @ (posedge clk) begin 
     if(!rst_n) 
       start_offset <= 5'b0;
     else begin
       if(msgld_data_sm_cs == ST_CHK_START)
         start_offset <= fifo_log_data[35:31];
       else
         start_offset <= 5'b0;
       end
    end     
  
   assign pld_len_fifo_rd = (msgld_data_sm_cs == ST_MSGLD_LEN_FIFO_RD ) ? 1'b1 : 1'b0;
   assign pld_len_fifo_wr = ((msgld_req_sm_cs == ST_CTRL_PKT && adptr_valid_reg) || (msgld_req_sm_cs == ST_FIFO_FULL && (!pld_len_fifo_full))) ? 1'b1:1'b0; 


  assign msgld_fifo_rd =  ((msgld_data_sm_cs == ST_MSGLD_LEN_FIFO_RD && (!msgld_fifo_empty) ) ||
                            (msgld_data_sm_cs == ST_LIVE_CHK && (!msgld_fifo_empty) && (nxt_length>32) && (!msgld_fifo_rd_reg) && (!msgld_fifo_rd_reg1) )) ? 1'b1 : 1'b0;
// Output assignments
   assign cmd_ram_addr =  {16'b0,cmd_ram_addr_reg};
   assign cmd_ram_ren  =  (msgld_req_sm_cs == ST_RD_CMD_RAM && cmd_ram_rdcnt != 2'b11) ? 1'b1 : 1'b0 ;


  assign pld_ram_addr =  {17'b0,pld_ram_addr_reg};
  assign pld_ram_dout   = pld_ram_data_reg;  

   assign pld_ram_wen     = (dump_wr) ? 32'hFFFFFFFF:32'h0;


   assign  rsp_ram_addr = rsp_ram_addr_reg;
   assign  rsp_ram_wen =  rsp_ram_wen_reg;
   assign  rsp_ram_dout = {14'b0,fab0_byp_out_msgld_dat.intf.u.cdm.err_status,fab0_byp_out_msgld_dat.intf.u.cdm.status,fab0_byp_out_msgld_dat.intf.u.cdm.zero_byte,rsp_cookie};
   assign req_done = ((rsp_cnt == num_of_reqs) && (num_of_reqs!=0) && msgld_fifo_empty) ? 1'b1 :1'b0;


   // MSGLD Request assigments
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.relaxed_read = cmd_accumulator[12]; 
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.data_width = cmd_accumulator[11]; 
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.response_cookie = cmd_accumulator[75:64];
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.length = cmd_accumulator[8:0];
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.start_offset = cmd_accumulator[62:58];
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.op = cmd_accumulator[10:9];
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.attr.ido = 1'b0;
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.attr.ro  = 1'b0;
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.attr.no_snoop = 1'b0;

   // Address Assignments 
  assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.addr.u.imm.addr = host_addr_reg;
  assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.addr.u.imm.translated = cmd_accumulator[31] ;
  assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.addr.use_addr_tbl__reserved = cmd_accumulator[30];

   // Addr_spc
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.addr_spc.u.imm.csi_dst_fifo = cmd_accumulator[57:49];
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.addr_spc.u.imm.csi_dst      = cmd_accumulator[48:44];
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.addr_spc.u.imm.fnc          = (csi_dst_id == 'h4) ? pci_requester_id_reg : ((csi_dst_id == 'hC) ? psx_requester_id_reg : pci_requester_id_reg );
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.addr_spc.u.imm.pasid        = (csi_dst_id == 'h4) ? pci_pasid_reg : ((csi_dst_id == 'hC) ? psx_pasid_reg : pci_pasid_reg );
   assign fab0_dsc_crd_msgld_req.intf.cmd.msgld.addr_spc.use_addr_spc_tbl__reserved = cmd_accumulator[13];

   assign fab0_dsc_crd_msgld_req.intf.rc_id = cmd_accumulator[37:32];
   assign fab0_dsc_crd_msgld_req.intf.client_id = cmd_accumulator[41:38];
   assign fab0_dsc_crd_msgld_req.intf.op = cmd_accumulator[43:42];
   assign fab0_dsc_crd_msgld_req.vld = adptr_valid_reg;  
   assign cdm_ready = fab0_dsc_crd_msgld_req.rdy;     
   
    


endmodule



