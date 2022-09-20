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
`timescale 1 ns / 1 ps

    module csi_uport_axil_reg #
    (
    parameter TCQ                = 0,
    parameter C_S_AXI_ADDR_WIDTH = 32,
    parameter C_S_AXI_DATA_WIDTH = 32
    )
    (
        //R/W regsiter
    output logic           soft_rst_o,
    output logic           counter_rst_o,
    output logic [7:0]     npr_dest_id_o,
    output logic [7:0]     cmpl_dest_id_o,
    output logic [7:0]     pr_dest_id_o,
    output logic [12:0]    init_local_crdts_npr_o,
    output logic [12:0]    init_local_crdts_cmpl_o,
    output logic [12:0]    init_local_crdts_pr_o,
    output logic [31:0]    init_value_pr_from_mb_0_o,
    output logic [31:0]    init_value_pr_from_mb_1_o,
    output logic           mb_initialize_pr_done_o,
    output logic [31:0]    init_value_cmpl_from_mb_0_o,
    output logic [31:0]    init_value_cmpl_from_mb_1_o,
    output logic           mb_initialize_cmpl_done_o,
    output logic           invalid_axilm_addr_o,
    output logic           initiate_pr_req_o,
    output logic           initiate_npr_req_o,
    output logic           initiate_cmpl_req_o,
    output logic           ld_init_local_pr_credits_o,
    output logic           ld_init_local_npr_credits_o,
    output logic           ld_init_local_cmpl_credits_o,
    input  logic           pr_txn_in_process_i,
    input  logic           npr_txn_in_process_i,
    input  logic           cmpl_txn_in_process_i,
    input  logic [31:0]    npr_err_count_i,
    input  logic [31:0]    npr_pass_count_i,
    input  logic [31:0]    cmpl_err_count_i,
    input  logic [31:0]    cmpl_pass_count_i,
    input  logic [31:0]    pr_err_count_i,
    input  logic [31:0]    pr_pass_count_i,

    input  logic [31:0]    npr_sop_received_count_i ,
    input  logic [31:0]    cmpl_sop_received_count_i,
    input  logic [31:0]    pr_sop_received_count_i  ,
    input  logic [31:0]    npr_eop_received_count_i ,
    input  logic [31:0]    cmpl_eop_received_count_i,
    input  logic [31:0]    pr_eop_received_count_i  ,
    input  logic [31:0]    npr_ibctl_rxd_cnt_i      ,
    input  logic [31:0]    npr_obctl_rxd_cnt_i      ,
    input  logic [31:0]    cmpl_ibctl_rxd_cnt_i     ,
    input  logic [31:0]    cmpl_obctl_rxd_cnt_i     ,
    input  logic [31:0]    npr_sop_sent_cnt_i       ,
    input  logic [31:0]    npr_eop_sent_cnt_i       ,
    input  logic [31:0]    cmpl_sop_sent_cnt_i      ,
    input  logic [31:0]    cmpl_eop_sent_cnt_i      ,
    input  logic [31:0]    pr_sop_sent_cnt_i        ,
    input  logic [31:0]    pr_eop_sent_cnt_i        ,
    input  logic [31:0]    pr_data_ram_read_count_i,
    input  logic [31:0]    npr_data_ram_read_count_i,
    input  logic [31:0]    cmpl_data_ram_read_count_i,
    input  logic [31:0]    pr_cmd_ram_read_count_i,
    input  logic [31:0]    npr_cmd_ram_read_count_i,
    input  logic [31:0]    cmpl_cmd_ram_read_count_i,
    input  logic [31:0]    cmpl_seed_ram_count_i,
    input  logic [31:0]    pr_seed_ram_count_i,
    


    input  logic [31:0]    dest_crdts_released_npr_i,
    input  logic [31:0]    dest_crdts_released_cmpl_i,
    input  logic [31:0]    dest_crdts_released_pr_i,
    
    input  logic [31:0]    s_aximm00_arvalid_cnt_i,
    input  logic [31:0]    s_aximm00_awvalid_cnt_i,
    input  logic [31:0]    s_aximm00_rvalid_cnt_i,
    input  logic [31:0]    s_aximm00_wvalid_cnt_i,
    input  logic [31:0]    s_aximm00_rlast_cnt_i,
    input  logic [31:0]    s_aximm00_wlast_cnt_i,

    input  logic [31:0]    m_aximm00_arvalid_cnt_i,
    input  logic [31:0]    m_aximm00_awvalid_cnt_i,
    input  logic [31:0]    m_aximm00_rvalid_cnt_i,
    input  logic [31:0]    m_aximm00_wvalid_cnt_i,
    input  logic [31:0]    m_aximm00_rlast_cnt_i,
    input  logic [31:0]    m_aximm00_wlast_cnt_i,
    input  logic [31:0]    m_aximm00_arready_cnt_i,
    input  logic [31:0]    m_aximm00_awready_cnt_i,
    
    

        //axi4lite interface//// 
  input  logic                             axi_aclk,
  input  logic                             axi_aresetn,
         
  input  logic  [C_S_AXI_ADDR_WIDTH-1:0]   axi_awaddr,
  output logic                             axi_awready,
  input  logic                             axi_awvalid,
         
  input  logic  [C_S_AXI_ADDR_WIDTH-1:0]   axi_araddr,
  output logic                             axi_arready,
  input  logic                             axi_arvalid,
         
  input  logic  [C_S_AXI_DATA_WIDTH-1:0]   axi_wdata,
  input  logic  [(C_S_AXI_DATA_WIDTH/8)-1 : 0]            axi_wstrb,
  output logic                             axi_wready,
  input  logic                             axi_wvalid,
         
  output logic  [C_S_AXI_DATA_WIDTH-1:0]   axi_rdata,
  output logic  [1:0]                      axi_rresp,
  input  logic                             axi_rready,
  output logic                             axi_rvalid,
         
  output logic  [1:0]                      axi_bresp,
  input  logic                             axi_bready,
  output logic                             axi_bvalid
        
    );

  reg   [7:0]   wr_addr;
  reg   [7:0]   rd_addr;
  reg           wr_req;
  reg           rd_req;

  reg           reset_released;
  reg           reset_released_r;

 
  reg mb_pr_value_init_dn, mb_pr_value_init_dn_s1;
  reg mb_cmpl_value_init_dn, mb_cmpl_value_init_dn_s1;
  
  logic initiate_npr_req_s1, initiate_npr_req;
  logic initiate_pr_req_s1, initiate_pr_req;
  logic initiate_cmpl_req_s1, initiate_cmpl_req;
  logic ld_init_local_pr_credits, ld_init_local_npr_credits, ld_init_local_cmpl_credits;
  logic ld_init_local_pr_credits_s1, ld_init_local_npr_credits_s1, ld_init_local_cmpl_credits_s1;
   
logic npr_txn_in_process, pr_txn_in_process, cmpl_txn_in_process; 
//******************************************************************************
  //A write address phase is accepted only when there is no pending read or
  //write transactions. when both read and write transactions occur on the
  //same clock read transaction will get the highest priority and processed
  //first. write transaction will not be accepted until the read transaction
  //is completed. 
  //******************************************************************************
  assign axi_awready = ((~wr_req) && (!(rd_req || axi_arvalid))) && reset_released_r;
  assign axi_bresp = 2'b00;
  assign axi_rresp = 2'b00;
  assign axi_wready = wr_req && ~axi_bvalid;
  assign axi_arready = ~rd_req && ~wr_req && reset_released_r;


  //******************************************************************************
  //According to xilinx guide lines after reset the AWREADY and ARREADY siganls
  //should be low atleast for one clock cycle. To achieve this a signal 
  //reset_released is taken and anded with axi_awready and axi_arready signals,
  //so that the output will show a logic '0' when in reset
  //******************************************************************************
  always @(posedge axi_aclk or negedge axi_aresetn)
  begin
      if(~axi_aresetn) begin
          reset_released   <= 1'b0;
          reset_released_r <= 1'b0;
      end else begin
          reset_released   <= 1'b1;
          reset_released_r <= reset_released;
      end 
  end

  //******************************************************************************
  //AXI Lite trasaction decoding and address latching logic. 
  //when axi_a*valid signal is asserted by the master the address is latched 
  //and wr_req or rd_req signal is asserted until data phase is completed 
  //******************************************************************************


  always @(posedge axi_aclk or negedge axi_aresetn)
  begin
      if(~axi_aresetn)begin
          wr_req <= 1'b0;
          rd_req <= 1'b0;
          wr_addr <= 8'h00;
          rd_addr <= 8'h00;
      end else begin
          if(axi_awvalid && axi_awready) begin
              wr_req <= 1'b1;
              wr_addr <= axi_awaddr;
          end else if (axi_bvalid && axi_bready) begin
              wr_req <= 1'b0;
              wr_addr <= 8'h00;
          end else begin
              wr_req <= wr_req;
              wr_addr <= wr_addr;
          end

          if(axi_arvalid && axi_arready) begin
              rd_req <= 1'b1;
              rd_addr <= axi_araddr;
          end else if (axi_rvalid && axi_rready) begin
              rd_req <= 1'b0;
              rd_addr <= rd_addr;
          end else begin
              rd_req <= rd_req;
              rd_addr <= rd_addr;
          end
      end
  end
  
 
 
always @(posedge axi_aclk or negedge axi_aresetn)
  begin
      if(~axi_aresetn) begin
        pr_txn_in_process <= 'b0;
        npr_txn_in_process <= 'b0;
        cmpl_txn_in_process <= 'b0;
        end
      else begin
        pr_txn_in_process  <= pr_txn_in_process_i;
        npr_txn_in_process <= npr_txn_in_process_i; 
        cmpl_txn_in_process <= cmpl_txn_in_process_i;  
      end
 end 
  
  
   //******************************************************************************
  //AXI Lite read trasaction processing logic. 
  //when a read transaction is received, depending on address bits [5:2] the
  //data is recovered and sent on to axi_rdata signal along with axi_rvalid.  
  //The address bits [1:0] are not considred and it is expected that the
  //address is word aligned and reads complete word information. 
  //******************************************************************************
  always @(posedge axi_aclk or negedge axi_aresetn)
  begin
      if(~axi_aresetn)begin
          axi_rvalid <= 1'b0;
          axi_rdata <= 32'd0;
      end else begin
          if(rd_req) begin
              if(axi_rvalid && axi_rready) begin
                  axi_rvalid <= 1'b0;
              end else begin
                  axi_rvalid <= 1'b1;
              end
              if(~axi_rvalid) begin
                 case (rd_addr[7:0]) 
                     8'h00: axi_rdata <= {24'd0,npr_dest_id_o};
                     8'h04: axi_rdata <= {24'd0,cmpl_dest_id_o};
                     8'h08: axi_rdata <= {24'd0,pr_dest_id_o};
                     8'h0C: axi_rdata <= {19'd0,init_local_crdts_npr_o};
                     8'h10: axi_rdata <= {19'd0,init_local_crdts_cmpl_o};
                     8'h14: axi_rdata <= {19'd0,init_local_crdts_pr_o};
                     8'h18: axi_rdata <= init_value_pr_from_mb_0_o;
                     8'h1C: axi_rdata <= init_value_pr_from_mb_1_o;
                     8'h24: axi_rdata <= {29'd0,pr_txn_in_process,cmpl_txn_in_process,npr_txn_in_process};
                     8'h28: axi_rdata <= {22'd0,counter_rst_o,soft_rst_o,2'b0,ld_init_local_pr_credits,ld_init_local_cmpl_credits,ld_init_local_npr_credits,initiate_pr_req,initiate_cmpl_req,initiate_npr_req};
                     8'h2C: axi_rdata <= init_value_cmpl_from_mb_0_o;
                     8'h30: axi_rdata <= init_value_cmpl_from_mb_1_o;
                     8'h34: axi_rdata <= npr_err_count_i;
                     8'h38: axi_rdata <= npr_pass_count_i;
                     8'h3C: axi_rdata <= cmpl_err_count_i;
                     8'h40: axi_rdata <= cmpl_pass_count_i;
                     8'h44: axi_rdata <= pr_err_count_i;
                     8'h48: axi_rdata <= pr_pass_count_i;
                     8'h4c: axi_rdata <= s_aximm00_arvalid_cnt_i;
                     8'h50: axi_rdata <= s_aximm00_awvalid_cnt_i;
                     8'h54: axi_rdata <= s_aximm00_rvalid_cnt_i;
                     8'h58: axi_rdata <= s_aximm00_wvalid_cnt_i;
                     8'h5c: axi_rdata <= s_aximm00_rlast_cnt_i;
                     8'h60: axi_rdata <= s_aximm00_wlast_cnt_i;
                     8'h64: axi_rdata <= m_aximm00_arvalid_cnt_i;
                     8'h68: axi_rdata <= m_aximm00_awvalid_cnt_i;
                     8'h6c: axi_rdata <= m_aximm00_rvalid_cnt_i;
                     8'h70: axi_rdata <= m_aximm00_wvalid_cnt_i;
                     8'h74: axi_rdata <= m_aximm00_rlast_cnt_i;
                     8'h78: axi_rdata <= m_aximm00_wlast_cnt_i;
                     8'h7c: axi_rdata <= m_aximm00_awready_cnt_i;
                     8'h80: axi_rdata <= m_aximm00_arready_cnt_i;
                     8'h84: axi_rdata <= dest_crdts_released_npr_i;
                     8'h88: axi_rdata <= dest_crdts_released_cmpl_i;
                     8'h8c: axi_rdata <= dest_crdts_released_pr_i;

                     8'h90: axi_rdata <= npr_sop_received_count_i     ;
                     8'h98: axi_rdata <= cmpl_sop_received_count_i    ;
                     8'ha0: axi_rdata <= pr_sop_received_count_i      ;
                     8'h94: axi_rdata <= npr_eop_received_count_i     ;
                     8'h9c: axi_rdata <= cmpl_eop_received_count_i    ;
                     8'ha4: axi_rdata <= pr_eop_received_count_i      ;
                     8'ha8: axi_rdata <= npr_ibctl_rxd_cnt_i          ;
                     8'hac: axi_rdata <= npr_obctl_rxd_cnt_i          ;
                     8'hb0: axi_rdata <= cmpl_ibctl_rxd_cnt_i         ;
                     8'hb4: axi_rdata <= cmpl_obctl_rxd_cnt_i         ;
                     8'hb8: axi_rdata <= npr_sop_sent_cnt_i         ;
                     8'hbc: axi_rdata <= npr_eop_sent_cnt_i         ;
                     8'hc0: axi_rdata <= cmpl_sop_sent_cnt_i            ;
                     8'hc4: axi_rdata <= cmpl_eop_sent_cnt_i            ;
                     8'hc8: axi_rdata <= pr_sop_sent_cnt_i          ;
                     8'hcc: axi_rdata <= pr_eop_sent_cnt_i          ;
                     8'hd0: axi_rdata <= npr_cmd_ram_read_count_i;
                     8'hd4: axi_rdata <= cmpl_cmd_ram_read_count_i;
                     8'hd8: axi_rdata <= pr_cmd_ram_read_count_i;
                     8'hdc: axi_rdata <= npr_data_ram_read_count_i;
                     8'he0: axi_rdata <= cmpl_data_ram_read_count_i;
                     8'he4: axi_rdata <= pr_data_ram_read_count_i;
                     8'he8: axi_rdata <= cmpl_seed_ram_count_i;
                     8'hec: axi_rdata <= pr_seed_ram_count_i;

                     default: axi_rdata <= 32'd0;
                 endcase
              end
          end else begin
              axi_rvalid <= 1'b0;
              axi_rdata <= 32'd0;
          end
      end 
  end




 //******************************************************************************
  //AXI Lite write trasaction processing logic. 
  //when a write transaction is received, depending on address bits [5:2] the
  //data is written in to the corresponding register.  
  //The address bits [1:0] are not considred and it is expected that the
  //address is word aligned and writes into entire register.  
  //******************************************************************************
  always @(posedge axi_aclk or negedge axi_aresetn)
  begin
      if(~axi_aresetn)begin
          soft_rst_o <= 'b0;
          counter_rst_o <= 'b0;
          npr_dest_id_o <= 'h0;
          cmpl_dest_id_o <= 'h0;
          pr_dest_id_o <= 'h0;
          init_local_crdts_npr_o <= 'h0;
          init_local_crdts_cmpl_o <= 'h0;
          init_local_crdts_pr_o <= 'h0;
          init_value_pr_from_mb_0_o <= 'h0;
          init_value_pr_from_mb_1_o <= 'h0;
          init_value_cmpl_from_mb_0_o <= 'h0;
          init_value_cmpl_from_mb_1_o <= 'h0;
          mb_pr_value_init_dn <= 'b0;
          mb_cmpl_value_init_dn <='b0;
          initiate_cmpl_req <= 'b0;
          initiate_npr_req <= 'b0;
          initiate_pr_req <= 'b0;
          ld_init_local_pr_credits <= 1'b0;
          ld_init_local_npr_credits <= 1'b0;
          ld_init_local_cmpl_credits <= 1'b0;
      end else begin
          if(wr_req && axi_wvalid && ~axi_bvalid) begin
              case (wr_addr[7:0]) 
                  8'h00 : npr_dest_id_o    <= {24'b0, axi_wdata[7:0]};
                  8'h04 : cmpl_dest_id_o   <= {24'b0, axi_wdata[7:0]};
                  8'h08 : pr_dest_id_o     <= {24'b0, axi_wdata[7:0]};
                  8'h0C : init_local_crdts_npr_o     <= {19'b0, axi_wdata[12:0]};
                  8'h10 : init_local_crdts_cmpl_o    <= {19'b0, axi_wdata[12:0]};
                  8'h14 : init_local_crdts_pr_o      <= {19'b0, axi_wdata[12:0]};
                  8'h18 : init_value_pr_from_mb_0_o  <= axi_wdata;
                  8'h1C : begin
                            init_value_pr_from_mb_1_o  <= axi_wdata;
                            mb_pr_value_init_dn        <= 'b1;  
                          end
                  8'h28 : begin
                             soft_rst_o    <= axi_wdata[8];
                             counter_rst_o <= axi_wdata[9];
                             initiate_npr_req <= axi_wdata[0];
                             initiate_pr_req <= axi_wdata[2];
                             initiate_cmpl_req <= axi_wdata[1];
                             ld_init_local_pr_credits <= axi_wdata[5];
                             ld_init_local_npr_credits <= axi_wdata[3];
                             ld_init_local_cmpl_credits <= axi_wdata[4];
                         end
                  8'h2C : init_value_cmpl_from_mb_0_o  <= axi_wdata;
                  8'h30 : begin
                            init_value_cmpl_from_mb_1_o  <= axi_wdata;
                            mb_cmpl_value_init_dn        <= 'b1;    
                          end
              endcase
          end else begin
              mb_pr_value_init_dn  <= 'b0;
              soft_rst_o <= 'b0;
              counter_rst_o <= 'b0;
          end
      end 
  end




  //********************************************************************************
  //write response channel logic. 
  //This logic will generate BVALID signal for the write transaction. 
  //********************************************************************************
  always @(posedge axi_aclk or negedge axi_aresetn)
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


//Generate a pulse after the mb initialises initial data value for PR
//This is used to initialize data checker
`XSRREG_AXIMM(axi_aclk, axi_aresetn, mb_pr_value_init_dn_s1, mb_pr_value_init_dn, 1'b0)
`XSRREG_AXIMM(axi_aclk, axi_aresetn, mb_cmpl_value_init_dn_s1, mb_cmpl_value_init_dn, 1'b0)

`XSRREG_AXIMM(axi_aclk, axi_aresetn, initiate_pr_req_s1, initiate_pr_req, 1'b0)
`XSRREG_AXIMM(axi_aclk, axi_aresetn, initiate_npr_req_s1, initiate_npr_req, 1'b0)
`XSRREG_AXIMM(axi_aclk, axi_aresetn, initiate_cmpl_req_s1, initiate_cmpl_req, 1'b0)


`XSRREG_AXIMM(axi_aclk, axi_aresetn, ld_init_local_pr_credits_s1, ld_init_local_pr_credits, 1'b0)
`XSRREG_AXIMM(axi_aclk, axi_aresetn, ld_init_local_npr_credits_s1, ld_init_local_npr_credits, 1'b0)
`XSRREG_AXIMM(axi_aclk, axi_aresetn, ld_init_local_cmpl_credits_s1, ld_init_local_cmpl_credits, 1'b0)
 
 always_comb begin
    mb_initialize_pr_done_o = mb_pr_value_init_dn & ~mb_pr_value_init_dn_s1; 
    mb_initialize_cmpl_done_o = mb_cmpl_value_init_dn & ~mb_cmpl_value_init_dn_s1;  

    initiate_pr_req_o   = initiate_pr_req & ~ initiate_pr_req_s1;
    initiate_npr_req_o  = initiate_npr_req & ~ initiate_npr_req_s1;
    initiate_cmpl_req_o = initiate_cmpl_req & ~ initiate_cmpl_req_s1;
    //initiate_cmpl_req_o = initiate_cmpl_req ;
    
    ld_init_local_pr_credits_o = ld_init_local_pr_credits & ~ld_init_local_pr_credits_s1;
    ld_init_local_npr_credits_o = ld_init_local_npr_credits & ~ld_init_local_npr_credits_s1;
    ld_init_local_cmpl_credits_o = ld_init_local_cmpl_credits & ~ld_init_local_cmpl_credits_s1;
 end
 
 
 endmodule
