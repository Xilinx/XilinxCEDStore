`timescale 1 ps / 1 ps

module ST_c2h #
   (
    parameter BIT_WIDTH = 64,
    parameter PATT_WIDTH = 16,

    parameter TM_DSC_BITS = 16
    )
    ( input  axi_aclk,
      input  axi_aresetn,
      input [31:0] control_reg,
      input  [15:0] txr_size,
      input  [10:0] num_pkt,
      input [TM_DSC_BITS-1:0]  credit_in,
      input                    credit_updt,
      input [TM_DSC_BITS-1:0]  credit_perpkt_in,
      input [TM_DSC_BITS-1:0]  credit_needed,
      input [15:0] buf_count,
      output [BIT_WIDTH-1:0] c2h_tdata,
      output [BIT_WIDTH/8-1:0] c2h_dpar,
      output c2h_tvalid,
      output c2h_tlast,
      input  c2h_tready

    );

localparam INC_DATA = (PATT_WIDTH == 16) ? ((BIT_WIDTH == 64 ) ? 4 : (BIT_WIDTH == 128 ) ? 8 : (BIT_WIDTH == 256 ) ? 16 : 32)
                                           :((BIT_WIDTH == 64 ) ? 8 : (BIT_WIDTH == 128 ) ? 16 : (BIT_WIDTH == 256 ) ? 32 : 64); // Total bytes per beat
localparam TCQ = 1;

reg [PATT_WIDTH-1:0] dat[0:INC_DATA-1];
(* mark_debug = "true" *) reg [12:0] count;
reg tlast;
reg tvalid;
(* mark_debug = "true" *) reg [15:0] max_count;
(* mark_debug = "true" *) reg [15:0] u_max_count;
(* mark_debug = "true" *) wire [15:0] t_max_count;
                          wire [15:0] max_count_tmp = (t_max_count > buf_count) ? buf_count : t_max_count;

(* mark_debug = "true" *)localparam [2:0] 
	SM_IDLE = 3'b000,
	SM_TXR  = 3'b001,
	SM_4BK  = 3'b010,
        SM_PKT  = 3'b011,
        SM_PER  = 3'b100;

(* mark_debug = "true" *) reg [2:0] sm_c2h;
wire loopback_st;
wire back_pres;
(* mark_debug = "true" *) reg [10:0] pkt_count;
(* mark_debug = "true" *) reg 	   start_c2h, start_c2h_d1, start_c2h_d2;
(* mark_debug = "true" *) reg [TM_DSC_BITS-1:0] credit_used_perpkt;
(* mark_debug = "true" *) reg [TM_DSC_BITS-1:0] tcredit_used;
   reg [TM_DSC_BITS-1:0] credit_in_sync;
//(* mark_debug = "true" *) wire [15:0] credit_perpkt_in;
wire [5:0] emty_byt_pos;
wire immediate_data;
wire cont_data_st; 
wire lst_credit_pkt; 
   reg 	   control_reg_1_d;
 
assign loopback_st = 0 ;   // bit 0 loopback mode
assign back_pres   = 0 ;   // bit 2, C2H back pressure
assign immediate_data = control_reg[2]; // immediate data, no c2h data only WB data, only 1 beat.
assign cont_data_st= control_reg[10];   // bit 4, C2H continouts data output stream until all packtes are done

assign c2h_tvalid = tvalid;
assign c2h_tlast = tlast;
assign t_max_count = ((txr_size%(BIT_WIDTH/8) > 0) || txr_size == 0 ) ? (txr_size)/(BIT_WIDTH/8) +1 : (txr_size)/(BIT_WIDTH/8);

assign emty_byt_pos =  ((txr_size%(BIT_WIDTH/8) > 0) ? txr_size%(BIT_WIDTH/8) : 6'b0) >> 1; 

//assign credit_perpkt_in = (credit_needed/num_pkt);
assign lst_credit_pkt   = (credit_perpkt_in - credit_used_perpkt) == 1;
		      
always @(posedge axi_aclk) begin
   control_reg_1_d <= control_reg[1];
end

   
always @(posedge axi_aclk)
   if (~axi_aresetn )
     credit_in_sync <= 0;
   else if (~start_c2h )
     credit_in_sync <= 0;
   else if ((start_c2h & control_reg[6]) | control_reg[7]) // new only for testing
     credit_in_sync <= 64;
   else if (start_c2h & credit_updt & ~immediate_data)
     credit_in_sync <= credit_in_sync + credit_in ;
     

always @(posedge axi_aclk) begin
   if (~axi_aresetn )
     start_c2h <= 0;
   else if (control_reg_1_d)
     start_c2h <= 1;
   else if (pkt_count >= num_pkt)
     start_c2h <= 0;
   else if (control_reg[7])
     start_c2h <= 1;

end
always @(posedge axi_aclk) begin
  start_c2h_d1 <= start_c2h;
  start_c2h_d2 <= start_c2h_d1;
end

reg first_transfer; // 1: First transfer. 0: Subsequent ones

always @(posedge axi_aclk) begin
   if (~axi_aresetn | loopback_st) begin
      sm_c2h <= SM_IDLE;
      tvalid <= 0;
      tlast <= 0;
      count <= 0;
      pkt_count <= 0;
      credit_used_perpkt <= 0;
      tcredit_used <= 0;
      max_count <= 0;
      u_max_count <= 0;
      
      first_transfer <= 0;
   end
   else
     case (sm_c2h)
       SM_IDLE : begin  // 0
	     if (start_c2h_d1 & ~start_c2h_d2 & immediate_data )
	       sm_c2h <= SM_TXR;
	     else if ((start_c2h_d1 & ~start_c2h_d2) && (tcredit_used < credit_in_sync)) begin
	       sm_c2h <= SM_TXR;
	       max_count <= (t_max_count > buf_count) ? buf_count : t_max_count;
	       u_max_count <= t_max_count;
	     end
	     count  <= 0;
	     tvalid <= 0;
	     tlast <= 0;
	     pkt_count <= 0;
	     tcredit_used <= 0;
	     credit_used_perpkt <= 0;
	     first_transfer <= 1;
       end
       SM_TXR : begin  // 1
	  if (c2h_tready | first_transfer) begin
	     tvalid<=1;
	     first_transfer <= 0;
	     if (immediate_data) begin
	       	tlast <= 1'b1;
	        sm_c2h <= SM_PKT;
	     end
	     else if (count == (max_count - 1) && lst_credit_pkt) begin
		   tlast <= 1'b1;
		   tcredit_used <= tcredit_used + 1;
		   sm_c2h <= SM_PKT;
	     end
	     else if (count == buf_count) begin
		   credit_used_perpkt <= credit_used_perpkt+1;
		   tcredit_used <= tcredit_used + 1;
		   u_max_count <= u_max_count - count;
		   count <= 0;
		   tvalid<= 1'b0;
		   first_transfer <= 1;
		   sm_c2h <= SM_4BK;
	     end
	     else begin
		   count <= count+1;
	     end
	  end
       end
       SM_4BK : begin  // 2
	  max_count <= (u_max_count > buf_count) ? buf_count : u_max_count;
//	  if (c2h_tready & (tcredit_used < credit_in_sync)) begin
      if (tcredit_used < credit_in_sync) begin
	     sm_c2h <= SM_TXR;
	  end
	  else if (tcredit_used == credit_needed) begin
	     sm_c2h <= SM_IDLE;
	     tvalid<= 1'b0;
	     tlast <= 1'b0;
	  end
	  else begin
	     tvalid<= 1'b0;
	  end
       end
       SM_PKT : begin  // 3
	  if (c2h_tready | first_transfer) begin
	     if (pkt_count >= (num_pkt - 1)) begin
		   sm_c2h <= SM_IDLE;
		   pkt_count <= pkt_count + 1'b1;
	     end
	     else if ( immediate_data ) begin
		   pkt_count <= pkt_count + 1'b1;
		   sm_c2h <= SM_TXR;
	     end
	     else if ( credit_in_sync > tcredit_used) begin
		   pkt_count <= pkt_count + 1'b1;
		   sm_c2h <= SM_TXR;
		   u_max_count <= t_max_count;
		   max_count <= (t_max_count > buf_count) ? buf_count : t_max_count;
	     end
	     else if (tcredit_used == credit_in_sync) begin
		   sm_c2h <= SM_PKT;
	     end
	     credit_used_perpkt <= 0;
	     tvalid<= 1'b0;
	     first_transfer <= 1;
	     tlast <= 1'b0;
	     count <= 0;
	  end
       end
     endcase // case (sm_c2h)
end
   
   
   
always @(posedge axi_aclk) begin
    if (~axi_aresetn | ~start_c2h | (cont_data_st & tlast)) begin
        for (integer j=0; j<INC_DATA; j++)
             dat[j] <= #TCQ j;
        end
    else if (c2h_tready & tlast & (|emty_byt_pos)) begin  // for continous data acrros different packets
        for (integer j=0; j<INC_DATA; j++)
             dat[j] <= #TCQ dat[emty_byt_pos]+j;
    end
    else if (c2h_tready & tvalid) begin
        for (integer j=0; j<INC_DATA; j++)
             dat[j] <= #TCQ dat[j]+INC_DATA;
        end
end

assign c2h_tdata = (BIT_WIDTH == 64)  ? {dat[3],dat[2],dat[1],dat[0]} :
                   (BIT_WIDTH == 128) ? {dat[7],dat[6],dat[5],dat[4],dat[3],dat[2],dat[1],dat[0]} :
                   (BIT_WIDTH == 256) ? {dat[15],dat[14],dat[13],dat[12],dat[11],dat[10],dat[9],dat[8],dat[7],dat[6],dat[5],dat[4],dat[3],dat[2],dat[1],dat[0]} :
                                        {dat[31],dat[30],dat[29],dat[28],dat[27],dat[26],dat[25],dat[24],dat[23],dat[22],dat[21],dat[20],dat[19],dat[18],dat[17],dat[16],dat[15],dat[14],dat[13],dat[12],dat[11],dat[10],dat[9],dat[8],dat[7],dat[6],dat[5],dat[4],dat[3],dat[2],dat[1],dat[0]};

   logic [BIT_WIDTH/8-1 : 0] dpar_val;
   // Data parity

   assign c2h_dpar = ~dpar_val;
   always_comb begin
      for (integer i=0; i< (BIT_WIDTH/8); i += 1) begin
	 dpar_val[i] = ^c2h_tdata[i*8 +: 8];
      end
   end

endmodule
