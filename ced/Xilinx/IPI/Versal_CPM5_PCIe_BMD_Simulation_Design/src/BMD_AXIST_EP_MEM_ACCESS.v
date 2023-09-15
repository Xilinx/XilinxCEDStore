// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

`define BMD_AXIST_MEM_ACCESS_WR_RST     3'b000
`define BMD_AXIST_MEM_ACCESS_WR_WAIT    3'b001
`define BMD_AXIST_MEM_ACCESS_WR_READ    3'b010
`define BMD_AXIST_MEM_ACCESS_WR_WRITE   3'b100

(* DowngradeIPIdentifiedWarnings = "yes" *)
module BMD_AXIST_EP_MEM_ACCESS #( parameter NUM_GP_PORTS = 20 ) (
								 
								 clk,
								 rst_n,
								 
								 // Misc. control ports
								 
								 cfg_neg_max_link_width, // I [3:0]
								 
								 cfg_prg_max_payload_size,  // I [1:0]
								 cfg_max_rd_req_size,       // I [2:0]
								 cfg_bus_mstr_enable,
								 
								 // Read Access
								 
								 addr_i,        // I [6:0]     
								 rd_be_i,       // I [3:0] 
								 rd_data_o,     // O [31:0]
								 
								 // Write Access
								 
								 wr_be_i,       // I [7:0]
								 wr_data_i,     // I [31:0]
								 wr_en_i,       // I 
								 wr_busy_o,     // O 
								 
								 init_rst_o,    // O
								 
								 mrd_start_o,   // O
								 mrd_int_dis_o, // O
								 mrd_done_o,    // O
								 mrd_addr_o,    // O [31:0]
								 mrd_len_o,     // O [31:0]
								 mrd_count_o,   // O [31:0]
								 mrd_done_i,    // I
								 mrd_tlp_tc_o,  // O [2:0]
								 mrd_64b_en_o,  // O
								 mrd_phant_func_dis1_o, 
								 mrd_up_addr_o, // O [7:0]
								 mrd_relaxed_order_o, 
								 mrd_nosnoop_o,      
								 mrd_wrr_cnt_o,    
								 
								 
								 mwr_start_o,   // O
								 mwr_int_dis_o, // O
								 mwr_done_i,    // I
								 mwr_addr_o,    // O [31:0]
								 mwr_len_o,     // O [31:0]
								 mwr_count_o,   // O [31:0]
								 mwr_data_o,    // O [31:0]
								 mwr_tlp_tc_o,  // O [2:0]
								 mwr_64b_en_o,  // O
								 mwr_phant_func_dis1_o, 
								 mwr_up_addr_o, // O [7:0]
								 mwr_relaxed_order_o, 
								 mwr_nosnoop_o,      
								 mwr_wrr_cnt_o,     
								 mwr_zerolen_en_o, 
								 

								 cpl_ur_found_i, //I [7:0]
								 cpl_ur_tag_i,   // I [7:0]
								 
								 cpld_data_o,    // O [31:0]
								 cpld_found_i,   // I [31:0]
								 cpld_data_size_i,// I [31:0]
								 cpld_malformed_i,// I
								 cpld_data_err_i, // I

								 rd_metering_o,   // O
                         tags_all_back_i,
								 
							//gp_data_upstream,// I
							//gp_data_dnstream,// O
								 trn_wait_count
								 
								 );
   
   input            clk;
   input            rst_n;
   
   /*
    * Misc. control ports
    */
   
   input [3:0] 	    cfg_neg_max_link_width;
   
   input [1:0] 	    cfg_prg_max_payload_size;
   input [2:0] 	    cfg_max_rd_req_size;
   input            cfg_bus_mstr_enable;
   
   /*
    *  Read Port
    */
   
   input [6:0] 	    addr_i;
   input [3:0] 	    rd_be_i;
   output [31:0]    rd_data_o;
   
   /*
    *  Write Port
    */
   
   input [7:0] 	    wr_be_i;
   input [31:0]     wr_data_i;
   input            wr_en_i;
   output           wr_busy_o;
   
   output           init_rst_o;
   
   output           mrd_start_o;
   output           mrd_int_dis_o;
   output           mrd_done_o;
   output [31:0]    mrd_addr_o;
   output [15:0]    mrd_len_o;
   output [2:0]     mrd_tlp_tc_o;
   output           mrd_64b_en_o;
   output           mrd_phant_func_dis1_o;
   output [7:0]     mrd_up_addr_o;
   output [15:0]    mrd_count_o;
   input            mrd_done_i;
   output           mrd_relaxed_order_o;
   output           mrd_nosnoop_o;
   output [7:0]     mrd_wrr_cnt_o;
   
   output           mwr_start_o;
   output           mwr_int_dis_o;
   input            mwr_done_i;
   output [31:0]    mwr_addr_o;
   output [15:0]    mwr_len_o;
   output [15:0]    mwr_count_o;
   output [31:0]    mwr_data_o;
   output [2:0]     mwr_tlp_tc_o;
   output           mwr_64b_en_o;
   output           mwr_phant_func_dis1_o;
   output [7:0]     mwr_up_addr_o;
   output           mwr_relaxed_order_o;
   output           mwr_nosnoop_o;
   output [7:0]     mwr_wrr_cnt_o;
   output           mwr_zerolen_en_o;
   
   input [7:0] 	    cpl_ur_found_i;
   input [7:0] 	    cpl_ur_tag_i;
   
   output [31:0]    cpld_data_o;
   input [31:0]     cpld_found_i;
   input [31:0]     cpld_data_size_i;
   input            cpld_malformed_i;
   input            cpld_data_err_i;
   output           rd_metering_o;
   input            tags_all_back_i;
   
   output [3:0]     trn_wait_count;

// wire [(NUM_GP_PORTS*32-1):0] gp_data_upstream; // input
// wire [(NUM_GP_PORTS*32-1):0] gp_data_dnstream; // output
   
   wire [31:0] 	    mem_rd_data;
   wire [31:0] 		w_pre_wr_data;
   reg                  mem_write_en;
   reg [31:0] 		pre_wr_data;
   reg [31:0] 		mem_wr_data;
   reg [3:0] 		wr_mem_state;  
(* mark_debug *) wire [31:0] mem_rd_data_dbg = mem_rd_data;
(* mark_debug *) wire  [3:0] wr_mem_state_dbg = wr_mem_state;  
(* mark_debug *) wire  [7:0] wr_be_dbg = wr_be_i;
(* mark_debug *) wire [31:0] wr_data_dbg = wr_data_i;
(* mark_debug *) wire        wr_en_dbg = wr_en_i;
(* mark_debug *) wire        wr_busy_dbg = wr_busy_o;
   
   /*
    * Memory Write Controller 
    */
   
   wire [6:0] 			  mem_addr = addr_i; 
   
   /*
    *  Extract current data bytes. These need to be swizzled
    *  memory storage format : 
    *    data[31:0] = { byte[3], byte[2], byte[1], byte[0] (lowest addr) }  
    */
   
   wire [7:0] 			  w_pre_wr_data_b3 = pre_wr_data[31:24];
   wire [7:0] 			  w_pre_wr_data_b2 = pre_wr_data[23:16];
   wire [7:0] 			  w_pre_wr_data_b1 = pre_wr_data[15:08];
   wire [7:0] 			  w_pre_wr_data_b0 = pre_wr_data[07:00];
   
   /*
    *  Extract new data bytes from payload
    *  TLP Payload format : 
    *    data[31:0] = { byte[0] (lowest addr), byte[2], byte[1], byte[3] }  
    */
   
   wire [7:0] 			  w_wr_data_b3 = wr_data_i[31:24];
   wire [7:0] 			  w_wr_data_b2 = wr_data_i[23:16];
   wire [7:0] 			  w_wr_data_b1 = wr_data_i[15:8];
   wire [7:0] 			  w_wr_data_b0 = wr_data_i[7:0];
   
   always @(posedge clk ) begin
      
      if ( !rst_n ) begin
	 
         pre_wr_data    <= 32'b0;
         mem_write_en   <= 1'b0;
         mem_wr_data    <= 32'b0;
	 
         wr_mem_state <= `BMD_AXIST_MEM_ACCESS_WR_RST;
         
      end else begin
	 
         case ( wr_mem_state )
           `BMD_AXIST_MEM_ACCESS_WR_RST : begin
              mem_write_en <= 1'b0;
              if (wr_en_i) begin // read state
                 wr_mem_state <= `BMD_AXIST_MEM_ACCESS_WR_READ ;
              end else begin
                 wr_mem_state <= `BMD_AXIST_MEM_ACCESS_WR_RST;
              end
           end
           `BMD_AXIST_MEM_ACCESS_WR_READ : begin
              mem_write_en <= 1'b0;
              pre_wr_data  <= mem_rd_data; 
              wr_mem_state <= `BMD_AXIST_MEM_ACCESS_WR_WRITE;
           end
           `BMD_AXIST_MEM_ACCESS_WR_WRITE : begin
             // Merge new enabled data and write target location
             mem_wr_data  <= {{wr_be_i[3] ? w_wr_data_b3 : w_pre_wr_data_b3},
                              {wr_be_i[2] ? w_wr_data_b2 : w_pre_wr_data_b2},
                              {wr_be_i[1] ? w_wr_data_b1 : w_pre_wr_data_b1},
                              {wr_be_i[0] ? w_wr_data_b0 : w_pre_wr_data_b0}};
             mem_write_en <= 1'b1;
             wr_mem_state <= `BMD_AXIST_MEM_ACCESS_WR_RST;

            end
         endcase
      end
    end
   /* 
    * Write controller busy 
     */
    assign wr_busy_o = wr_en_i | (wr_mem_state != `BMD_AXIST_MEM_ACCESS_WR_RST);


   // Handle Read byte enables
   assign rd_data_o = {{rd_be_i[3] ? mem_rd_data[31:24] : 8'h0},
                       {rd_be_i[2] ? mem_rd_data[23:16] : 8'h0}, 
                       {rd_be_i[1] ? mem_rd_data[15:8] : 8'h0}, 
                       {rd_be_i[0] ? mem_rd_data[7:0] : 8'h0}};
   
    BMD_AXIST_EP_MEM #( .NUM_GP_PORTS(NUM_GP_PORTS) ) EP_MEM (
							      
							      .clk(clk),
							      .rst_n(rst_n),
							      
							      .cfg_neg_max_lnk_width(cfg_neg_max_link_width),
							      
							      .cfg_prg_max_payload_size(cfg_prg_max_payload_size), 
							      .cfg_max_rd_req_size(cfg_max_rd_req_size),          
							      .cfg_bus_mstr_enable (cfg_bus_mstr_enable),
							      
							      .a_i(mem_addr[6:0]),                  // I [6:0]
							      .wr_en_i(mem_write_en),               // I
							      .rd_d_o(mem_rd_data),                 // O [31:0]
							      .wr_d_i(mem_wr_data),                 // I [31:0]
							      
							      .init_rst_o(init_rst_o),              // O
							      
							      .mrd_start_o(mrd_start_o),            // O
							      .mrd_int_dis_o(mrd_int_dis_o),        // O
							      .mrd_done_o(mrd_done_o),              // O
							      .mrd_addr_o(mrd_addr_o),              // O [31:0]
							      .mrd_len_o(mrd_len_o),                // O [31:0]
							      .mrd_count_o(mrd_count_o),            // O [31:0]
							      .mrd_done_i(mrd_done_i),              // I
							      .mrd_tlp_tc_o(mrd_tlp_tc_o),          // O [2:0]
							      .mrd_64b_en_o(mrd_64b_en_o),          // O
							      .mrd_phant_func_dis1_o(mrd_phant_func_dis1_o), 
							      .mrd_up_addr_o(mrd_up_addr_o),        // O [7:0]
							      .mrd_relaxed_order_o(mrd_relaxed_order_o), 
							      .mrd_nosnoop_o(mrd_nosnoop_o),        // O
							      .mrd_wrr_cnt_o(mrd_wrr_cnt_o),        // O [7:0]
							      
							      .mwr_start_o(mwr_start_o),            // O
							      .mwr_int_dis_o(mwr_int_dis_o),        // O
							      .mwr_done_i(mwr_done_i),              // I
							      .mwr_addr_o(mwr_addr_o),              // O [31:0]
							      .mwr_len_o(mwr_len_o),                // O [31:0]
							      .mwr_count_o(mwr_count_o),            // O [31:0]
							      .mwr_data_o(mwr_data_o),              // O [31:0]
							      .mwr_tlp_tc_o(mwr_tlp_tc_o),          // O [2:0]
							      .mwr_64b_en_o(mwr_64b_en_o),          // O
							      .mwr_phant_func_dis1_o(mwr_phant_func_dis1_o),
							      .mwr_up_addr_o(mwr_up_addr_o),        // O [7:0]
							      .mwr_relaxed_order_o(mwr_relaxed_order_o), 
							      .mwr_nosnoop_o(mwr_nosnoop_o),        // O
							      .mwr_wrr_cnt_o(mwr_wrr_cnt_o),        // O [7:0]
        						  .mwr_zerolen_en_o(mwr_zerolen_en_o),  // O
							      
							      
							      .cpl_ur_found_i(cpl_ur_found_i),      // I
							      .cpl_ur_tag_i(cpl_ur_tag_i),          // I [7:0]
							      
							      .cpld_data_o(cpld_data_o),            // O [31:0]
							      .cpld_found_i(cpld_found_i),          // I [31:0]
							      .cpld_data_size_i(cpld_data_size_i),  // I [31:0]
							      .cpld_malformed_i(cpld_malformed_i),  // I
                                  //FIXME PS
							      .cpld_data_err_i(cpld_data_err_i),               // I
							      .rd_metering_o(rd_metering_o),        // O
                           .tags_all_back_i(tags_all_back_i),
							      
							    //.gp_data_upstream(gp_data_upstream),  // I
							    //.gp_data_dnstream(gp_data_dnstream),  // O
							      
							      .trn_wait_count(trn_wait_count)
							      
							      );
   
   
endmodule
