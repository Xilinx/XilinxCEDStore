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
`timescale 1ns / 1ps
`include "cdx5n_csi_defines.svh"

module csi_uport_req_gen 
 #(
    parameter  TCQ                        = 0,
    parameter CRDT_CNTR_WIDTH             = 13,
    parameter PR_CONTROL_RAM_WIDTH        = 128,
    parameter PR_DATA_RAM_WIDTH           = 128,
    parameter NPR_CONTROL_RAM_WIDTH       = 128,
    parameter NPR_DATA_RAM_WIDTH          = 128,
    parameter CMPL_CONTROL_RAM_WIDTH      = 256,
    parameter CMPL_DATA_RAM_WIDTH         = 32,
    parameter PR_CONTROL_RAM_ADDR_WIDTH   = 9,   // 32 location
    parameter PR_DATA_RAM_ADDR_WIDTH      = 9,   // 32 location
    parameter NPR_CONTROL_RAM_ADDR_WIDTH  = 9,   // 32 location
    parameter NPR_DATA_RAM_ADDR_WIDTH     = 9,   // 32 location
    parameter CMPL_CONTROL_RAM_ADDR_WIDTH = 9,   // 512 location
    parameter CMPL_DATA_RAM_ADDR_WIDTH    = 9    //128 locations
    )(
    // Ports 
    // Clocks / Resets
    input                                      clk,
    input                                      rst_n,
    //From MicroBlaze
     (*mark_debug = "true"*) input                                      initiate_pr_req_i,
     (*mark_debug = "true"*) input                                      initiate_npr_req_i,
     (*mark_debug = "true"*) input                                      initiate_cmpl_req_i,
    input   [PR_CONTROL_RAM_WIDTH-1:0]         mb_pr_control_data_i,
    input   [PR_DATA_RAM_WIDTH-1:0]            mb_pr_data_i,
    input   [NPR_CONTROL_RAM_WIDTH-1:0]        mb_npr_control_data_i,
    input   [NPR_DATA_RAM_WIDTH-1:0]           mb_npr_data_i,
     (*mark_debug = "true"*) input   [CMPL_CONTROL_RAM_WIDTH-1:0]       mb_cmpl_control_data_i,
     (*mark_debug = "true"*) input   [CMPL_DATA_RAM_WIDTH-1:0]          mb_cmpl_data_i,
    //To Microblaze                            
     (*mark_debug = "true"*) output logic                               pr_txn_in_process_o,
     (*mark_debug = "true"*) output logic                               npr_txn_in_process_o,
     (*mark_debug = "true"*) output logic                               cmpl_txn_in_process_o,
    output logic  [PR_CONTROL_RAM_ADDR_WIDTH-1:0]   pr_control_ram_rdaddr_o,
    output logic  [31:0]     pr_cmd_ram_read_count,
    output logic  [PR_DATA_RAM_ADDR_WIDTH-1:0]      pr_data_ram_rdaddr_o,
    output logic  [31:0]     pr_data_ram_read_count,
    output logic  [NPR_CONTROL_RAM_ADDR_WIDTH-1:0]  npr_control_ram_rdaddr_o,
    output logic  [31:0]     npr_cmd_ram_read_count,
    output logic  [NPR_DATA_RAM_ADDR_WIDTH-1:0]     npr_data_ram_rdaddr_o,
    output logic  [31:0]     npr_data_ram_read_count,
     (*mark_debug = "true"*) output logic  [CMPL_CONTROL_RAM_ADDR_WIDTH-1:0] cmpl_control_ram_rdaddr_o,
    output logic  [31:0]     cmpl_cmd_ram_read_count,
     (*mark_debug = "true"*) output logic  [CMPL_DATA_RAM_ADDR_WIDTH-1:0]    cmpl_data_ram_rdaddr_o,
    output logic  [31:0]     cmpl_data_ram_read_count,
    // rom Decoder Control Ram addr
     (*mark_debug = "true"*) input                                      cmpl_control_ram_ready_i,   
    //Credit Manager IF
     (*mark_debug = "true"*) input   [CRDT_CNTR_WIDTH-1:0]              local_crdts_avail_npr_i,
     (*mark_debug = "true"*) input   [CRDT_CNTR_WIDTH-1:0]              local_crdts_avail_pr_i,
     (*mark_debug = "true"*) input   [CRDT_CNTR_WIDTH-1:0]              local_crdts_avail_cmpl_i,
     (*mark_debug = "true"*) input                                      local_crdts_avail_npr_vld_i,
     (*mark_debug = "true"*) input                                      local_crdts_avail_pr_vld_i,
     (*mark_debug = "true"*) input                                      local_crdts_avail_cmpl_vld_i,
                                               
    //From Decoder                             
     (*mark_debug = "true"*) input                                      npr_requested_i,

    //From Encoder      
     (*mark_debug = "true"*) input                                      csi_after_pr_seq_valid_i,   
     (*mark_debug = "true"*) input   [7:0]                              csi_after_pr_seq_i,
    
    //To Encoder                               
     (*mark_debug = "true"*) output logic [319:0]                       pr_data_o,
     (*mark_debug = "true"*) output logic [319:0]                       pr_data_s1_o,
     (*mark_debug = "true"*) output logic [1:0]                         pr_data_valid_o,
     (*mark_debug = "true"*) output logic [319:0]                       cmpl_data_o,
     (*mark_debug = "true"*) output logic [319:0]                       cmpl_data_s1_o,
     (*mark_debug = "true"*) output logic [1:0]                         cmpl_data_valid_o,
     (*mark_debug = "true"*) output logic                               sop_o,
     (*mark_debug = "true"*) output logic                               eop_o,
     (*mark_debug = "true"*) output logic                               eop_s1_o,
     (*mark_debug = "true"*) output logic                               npr_sop_o,
     (*mark_debug = "true"*) output logic                               npr_eop_o,
     (*mark_debug = "true"*) output csi_capsule_t                       cap_header_o,
     (*mark_debug = "true"*) output csi_capsule_t                       npr_cap_header_o,
     (*mark_debug = "true"*) output  [1:0]                              flow_typ_o,
     (*mark_debug = "true"*) output logic [1:0]                         credits_used_o,
     
    input  [1:0]                                                        f2csi_prcmpl_rdy_i,
    input                                                               f2csi_npr_rdy_i
    
    );



logic   [31:0]   prev_pr_seed;
logic   [31:0]   prev_cmpl_seed;
logic   [3:0]    dw_count;
logic   [3:0]    dw_count_s1;
logic   [12:0]   rem_data ; 
wire    [12:0]   dw_len_actual;
logic   [31:0]   pr_in_seed;
logic   [31:0]   cmpl_in_seed;
logic            pr_req_initiated;
logic            cmpl_req_initiated;
logic   [9:0]    dw_len;
logic   [63:0]   initial_pr_seed0;
logic   [63:0]   initial_cmpl_seed0;    
logic   [15:0]   requester;
logic   [15:0]   completer;
logic            completer_set;
logic   [3:0]    csi_vc;
logic   [4:0]    csi_src;
logic   [8:0]    csi_dst_fifo;
logic   [4:0]    csi_dst;
logic            csi_is_managed;
logic            csi_poison;
logic   [2:0]    attr;
logic            secure;
logic            trusted;
logic            ide_enable;
logic   [7:0]    byte_enables;
logic   [31:0]   seed_value;
logic   [61:0]   addr;
logic   [9:0]    num_txn;
logic   [9:0]    rem_txns;
logic            stop_txn;
logic            initiate_pr_req;   
logic            initiate_cmpl_req;
logic            initiate_npr_req;  
logic   [9:0]    npr_dw_len;        
logic   [5:0]    req_type;  
logic   [15:0]   npr_requester;
logic   [15:0]   npr_completer;
logic            npr_completer_set;
logic   [3:0]    npr_csi_vc;
logic   [4:0]    npr_csi_src;
logic   [8:0]    npr_csi_dst_fifo;
logic   [4:0]    npr_csi_dst;
logic            npr_csi_is_managed;
logic            npr_csi_poison;
logic   [2:0]    npr_attr;
logic            npr_secure;
logic            npr_trusted;
logic            npr_ide_enable;
logic   [5:0]    npr_type;
logic   [7:0]    npr_byte_enables;
logic   [61:0]   npr_addr;
logic   [9:0]    npr_num_txn;
logic   [9:0]    npr_rem_txns;
logic            npr_stop_txn;
logic   [2:0]    npr_tc; 
logic   [2:0]    tc;          
logic   [6:0]    lower_addr;  
logic            is_first;    
logic            is_last;   
logic   [9:0]    tag;         
logic   [9:0]    npr_tag; 
logic   [12:0]   byte_count;  
//logic   [319:0]  pr_data_o;
//logic   [319:0]  pr_data_s1_o;
logic   [319:0]  pr_data_q;
logic   [319:0]  pr_data_s1_q;
//logic   [1:0]    pr_data_valid_o;
//logic   [319:0]  cmpl_data_o;
//logic   [319:0]  cmpl_data_s1_o;
logic   [319:0]  cmpl_data_q;
logic   [319:0]  cmpl_data_s1_q;
//logic   [1:0]    cmpl_data_valid_o;
//logic            sop_o;
//logic            eop_o;
//logic            eop_s1_o;
//logic            npr_sop_o;
//logic            npr_eop_o;
logic   [7:0]    csi_after_pr_seq;
logic            initiate_next_pr_cmd_req;
logic            initiate_next_npr_cmd_req;
logic            local_crdts_avail_cmpl_vld;
logic            local_crdts_avail_pr_vld;   
logic            local_crdts_avail_npr_vld;  
logic   [12:0]   local_crdts_avail_cmpl;     
logic   [12:0]   local_crdts_avail_pr;       
logic   [12:0]   local_crdts_avail_npr; 
logic            cmpl_data_read_d;      
logic            cmpl_data_read;
logic   [7:0]    ram_read_left;
 (*mark_debug = "true"*) logic             cmpl_control_ram_ready;    
logic             cmpl_control_ram_ready_d;
 (*mark_debug = "true"*) logic             initiate_cmpl;
 (*mark_debug = "true"*) logic             initiate_next_cmpl_req;
 (*mark_debug = "true"*) logic             initiate_pending_cmpl;
logic             packet_2_present;
// (*mark_debug = "true"*) logic  [2:0]      credits_used_o;
// (*mark_debug = "true"*) logic                                   pr_txn_in_process_o;
// (*mark_debug = "true"*) logic                                   npr_txn_in_process_o;
// (*mark_debug = "true"*) logic                                   cmpl_txn_in_process_o;
//logic [PR_CONTROL_RAM_ADDR_WIDTH-1:0]   pr_control_ram_rdaddr_o;
//logic [PR_DATA_RAM_ADDR_WIDTH-1:0]      pr_data_ram_rdaddr_o;
//logic [NPR_CONTROL_RAM_ADDR_WIDTH-1:0]  npr_control_ram_rdaddr_o;
//logic [NPR_DATA_RAM_ADDR_WIDTH-1:0]     npr_data_ram_rdaddr_o;
// (*mark_debug = "true"*) logic [CMPL_CONTROL_RAM_ADDR_WIDTH-1:0] cmpl_control_ram_rdaddr_o;
// (*mark_debug = "true"*) logic [CMPL_DATA_RAM_ADDR_WIDTH-1:0]    cmpl_data_ram_rdaddr_o;

//Defination of CSI capsule type
typedef enum logic [5:0] {
  CSI_CT_RD_MEM     = 0,    //6'b00_00_00
  CSI_CT_RD_IO      = 1,    //6'b00_00_01
  CSI_CT_RD_CFG0    = 2,    //6'b00_00_10
  CSI_CT_RD_CFG1    = 3,    //6'b00_00_11
  CSI_CT_WR_MEM     = 4,    //6'b00_01_00
  CSI_CT_WR_IO      = 5,    //6'b00_01_01
  CSI_CT_WR_CFG0    = 6,    //6'b00_01_10
  CSI_CT_WR_CFG1    = 7,    //6'b00_01_11
  CSI_CT_FETCHADD   = 8,    //6'b00_10_00
  CSI_CT_SWAP       = 9,    //6'b00_10_01
  CSI_CT_CAS        = 10,   //6'b00_10_10
  CSI_CT_MESSAGE_RQ = 12,   //6'b00_11_00
  CSI_CT_INTERRUPT  = 13,   //6'b00_11_01
  CSI_CT_COMPLETION = 16,   //6'b01_00_00
  CSI_CT_IB_CTL     = 20,   //6'b01_01_00
  CSI_CT_OB_CTL     = 21,   //6'b01_01_01
  CSI_CT_BARRIER    = 22,   //6'b01_01_10
  CSI_CT_INVALID    = 31    //6'11_11_11
} csi_cap_type;

typedef enum logic [1:0] {
  CSI_PCIE_AT_UNTRANSLATED = 0,
  CSI_PCIE_AT_TRANSLATION_RQ = 1,
  CSI_PCIE_AT_TRANSLATED = 2,
  CSI_PCIE_AT_RESERVED = 3
} csi_pcie_addr_type;

typedef enum logic [2:0] {
    CSI_CMPT_STATUS_SC          = 3'b000,
    CSI_CMPT_STATUS_UR          = 3'b001,
    CSI_CMPT_STATUS_CRS         = 3'b010,
    CSI_CMPT_STATUS_CA          = 3'b100,
    CSI_CMPT_STATUS_FUNC_DIS    = 3'b110, 
    CSI_CMPT_STATUS_TIMEOUT     = 3'b111
} csi_cpl_status;

///////////////////Counters/////////////////////////////////

//logic [31:0]   pr_data_ram_read_count;
//logic [31:0]   pr_cmd_ram_read_count;
//logic [31:0]   npr_data_ram_read_count;
//logic [31:0]   npr_cmd_ram_read_count;
//logic [31:0]   cmpl_data_ram_read_count;
//logic [31:0]   cmpl_cmd_ram_read_count;

//////////////////////Assign Statements /////////////////////////////// 
assign dw_len_actual  = (dw_len == 'd0) ? 'd4096 : dw_len;
assign flow_typ_o     = pr_data_valid_o ? 2'd2 : 2'd1;

///////////////////////////////////////////////////////////////////////
//                     local Credit Valid                            //         
//////////////////////////////////////////////////////////////////////
always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin
        local_crdts_avail_cmpl_vld <= 'b0;
        local_crdts_avail_pr_vld   <= 'b0;
        local_crdts_avail_npr_vld  <= 'b0;
        local_crdts_avail_cmpl     <= 'd0;
        local_crdts_avail_pr       <= 'd0;
        local_crdts_avail_npr      <= 'd0;
    end
    else
    begin
        if((eop_o || eop_s1_o) & pr_data_valid_o & f2csi_prcmpl_rdy_i)
        begin
            if (pr_req_initiated)
                local_crdts_avail_pr_vld   <= 'b0;
        end
        else if(local_crdts_avail_pr_vld_i)
        begin
            local_crdts_avail_pr_vld   <= 'd1;
            local_crdts_avail_pr       <= local_crdts_avail_pr_i;
        end
        if((eop_o || eop_s1_o) & cmpl_data_valid_o & f2csi_prcmpl_rdy_i)
        begin
            if(cmpl_req_initiated)
                local_crdts_avail_cmpl_vld <= 'b0;      
        end
        else if(local_crdts_avail_cmpl_vld_i)
        begin
            local_crdts_avail_cmpl_vld <= 'd1;
            local_crdts_avail_cmpl     <= local_crdts_avail_cmpl_i;
        end
        if((initiate_npr_req && (local_crdts_avail_npr >= 'd2) && local_crdts_avail_npr_vld) && f2csi_npr_rdy_i)
        begin
            local_crdts_avail_npr_vld  <= 'b0;
        end
        else if(local_crdts_avail_npr_vld_i)
        begin
            local_crdts_avail_npr_vld  <= 'd1;
            local_crdts_avail_npr      <= local_crdts_avail_npr_i;
        end 
    end
end

always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin 
        cmpl_control_ram_ready   <= 'd0; 
        cmpl_control_ram_ready_d <= 'd0;  
        cmpl_data_read_d         <= 'd0;   
    end
    else
    begin 
        if((cmpl_req_initiated && (f2csi_prcmpl_rdy_i == 2'b11)) || cmpl_control_ram_ready_i)
        begin
            cmpl_data_read_d       <= 'd0;        
        end
        else if(cmpl_data_read && (f2csi_prcmpl_rdy_i == 2'b11))
            cmpl_data_read_d       <= 'b1;
        if(cmpl_req_initiated && (f2csi_prcmpl_rdy_i == 2'b11))
        begin
            cmpl_control_ram_ready_d <= 'd0;        
        end
        else if(cmpl_control_ram_ready == 'b1)
            cmpl_control_ram_ready_d <= 'd1;    
        if(cmpl_control_ram_ready && initiate_cmpl_req && (f2csi_prcmpl_rdy_i == 2'b11))
        begin
            cmpl_control_ram_ready <= 'd0;        
        end
        else if(cmpl_control_ram_ready_i == 'b1)
            cmpl_control_ram_ready <= 'd1;      
    end
end        

assign cmpl_data_read = (cmpl_control_ram_ready_d == 1'b1 && initiate_cmpl_req == 1'b1 && (!pr_txn_in_process_o) && 
                         (!cmpl_data_read_d) && (f2csi_prcmpl_rdy_i == 2'b11));
                

always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin 
        ram_read_left       <= 'd0;   
    end
    else
    begin 
        if(cmpl_control_ram_ready_i)
        begin
            if(cmpl_data_read && (f2csi_prcmpl_rdy_i == 2'b11))
                ram_read_left <= ram_read_left;
            else
                ram_read_left <= ram_read_left + 'd1;   
        end 
        else if(cmpl_data_read && (f2csi_prcmpl_rdy_i == 2'b11))
            ram_read_left <= ram_read_left - 'd1;           
    end
end


///////////////////////////////////////////////////////////////////////
//                     Data Extraction from Ram                      // 
//////////////////////////////////////////////////////////////////////
always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin
        requester                 <= 'd0;
        completer                 <= 'd0;
        completer_set             <= 'd0;
        csi_vc                    <= 'd0;
        csi_src                   <= 'd0;
        csi_dst_fifo              <= 'd0;
        csi_dst                   <= 'd0;
        csi_is_managed            <= 'd0;
        csi_poison                <= 'd0;
        attr                      <= 'd0;
        secure                    <= 'd0;
        trusted                   <= 'd0;
        ide_enable                <= 'd0;
        byte_enables              <= 'd0;
        num_txn                   <= 'd0;
        stop_txn                  <= 'd0;
        dw_len                    <= 'd0;
        addr                      <= 'd0;
        seed_value                <= 'd0;
        tc                        <= 'd0;
        lower_addr                <= 'd0;
        is_first                  <= 'd0;
        tag                       <= 'd0;
        byte_count                <= 'd0;
        is_last                   <= 'd0;
        npr_requester             <= 'd0;
        npr_completer             <= 'd0;
        npr_completer_set         <= 'd0;
        npr_csi_vc                <= 'd0;
        npr_csi_src               <= 'd0;
        npr_csi_dst_fifo          <= 'd0;
        npr_csi_dst               <= 'd0;
        npr_csi_is_managed        <= 'd0;
        npr_csi_poison            <= 'd0;
        npr_attr                  <= 'd0;
        npr_secure                <= 'd0;
        npr_trusted               <= 'd0;
        npr_ide_enable            <= 'd0;
        npr_type                  <= 'd0;
        npr_byte_enables          <= 'd0;
        npr_num_txn               <= 'd0;
        npr_stop_txn              <= 'd0;
        npr_tc                    <= 'd0;
        npr_dw_len                <= 'd0;
        npr_addr                  <= 'd0;
        pr_control_ram_rdaddr_o   <= 'd0;
        npr_control_ram_rdaddr_o  <= 'd0;
        cmpl_control_ram_rdaddr_o <= 'd0;
        cmpl_data_ram_rdaddr_o    <= 'd0;
        packet_2_present          <= 'b0;
        req_type                  <= 'd0;
        pr_cmd_ram_read_count     <= 'd0;
        npr_cmd_ram_read_count    <= 'd0;
        cmpl_cmd_ram_read_count   <= 'd0;
        cmpl_data_ram_read_count  <= 'd0;
    end                 
    else
    begin
        if(((initiate_pr_req_i == 1'b1) & (cmpl_txn_in_process_o == 1'b0) & (!cmpl_data_read)) ||
                (initiate_next_pr_cmd_req && (f2csi_prcmpl_rdy_i == 2'b11)))
        begin
            requester               <= mb_pr_control_data_i[15:0];
            completer               <= mb_pr_control_data_i[31:16];
            completer_set           <= mb_pr_control_data_i[32];
            csi_vc                  <= mb_pr_control_data_i[36:33];
            csi_src                 <= mb_pr_control_data_i[41:37];
            csi_dst_fifo            <= mb_pr_control_data_i[50:42];
            csi_dst                 <= mb_pr_control_data_i[55:51];
            csi_is_managed          <= mb_pr_control_data_i[56];
            csi_poison              <= mb_pr_control_data_i[57];
            attr                    <= mb_pr_control_data_i[60:58];
            secure                  <= mb_pr_control_data_i[61];
            trusted                 <= mb_pr_control_data_i[62];
            ide_enable              <= mb_pr_control_data_i[63];
            num_txn                 <= mb_pr_control_data_i[81:72];
            stop_txn                <= mb_pr_control_data_i[82];
            tc                      <= mb_pr_control_data_i[85:83];
            seed_value              <= mb_pr_data_i[31:0];
            addr                    <= mb_pr_data_i[93:32];
            dw_len                  <= mb_pr_data_i[103:94];
            byte_enables            <= mb_pr_data_i[111:104];
            pr_cmd_ram_read_count   <= pr_cmd_ram_read_count + 'd1; 
            if(mb_pr_control_data_i[82])    
            begin
                pr_control_ram_rdaddr_o <= 'd0;
            end
            else
            begin
                pr_control_ram_rdaddr_o <= pr_control_ram_rdaddr_o + 'd16;
            end         
        end
        else if(initiate_pr_req && (f2csi_prcmpl_rdy_i == 2'b11))
        begin
            seed_value              <= mb_pr_data_i[31:0];
            addr                    <= mb_pr_data_i[93:32];
            dw_len                  <= mb_pr_data_i[103:94];        
            byte_enables            <= mb_pr_data_i[111:104];       
        end
        if(initiate_next_cmpl_req && (f2csi_prcmpl_rdy_i == 2'b11))
        begin
            requester                 <= mb_cmpl_control_data_i[143:128];
            completer                 <= mb_cmpl_control_data_i[159:144];
            csi_vc                    <= mb_cmpl_control_data_i[163:160];
            csi_src                   <= mb_cmpl_control_data_i[168:164];
            csi_dst                   <= mb_cmpl_control_data_i[173:169];
            csi_is_managed            <= mb_cmpl_control_data_i[174];
            csi_poison                <= mb_cmpl_control_data_i[175];
            attr                      <= mb_cmpl_control_data_i[178:176];
            tc                        <= mb_cmpl_control_data_i[181:179];
            tag                       <= mb_cmpl_control_data_i[191:182];
            lower_addr                <= mb_cmpl_control_data_i[198:192];
            is_first                  <= mb_cmpl_control_data_i[199];
            byte_count                <= mb_cmpl_control_data_i[211:200];
            is_last                   <= mb_cmpl_control_data_i[212];
            dw_len                    <= mb_cmpl_control_data_i[222:213];
            req_type                  <= mb_cmpl_control_data_i[228:223];
            seed_value                <= mb_cmpl_data_i[31:0];
            packet_2_present          <= 1'b0;
            cmpl_control_ram_rdaddr_o <= cmpl_control_ram_rdaddr_o + 'd1;
            cmpl_data_ram_rdaddr_o    <= cmpl_data_ram_rdaddr_o + 'd4;
            cmpl_cmd_ram_read_count   <= cmpl_cmd_ram_read_count + 'd1; 
            cmpl_data_ram_read_count  <= cmpl_data_ram_read_count + 'd1;        
        end     
        else if((cmpl_data_read || initiate_pending_cmpl) && (f2csi_prcmpl_rdy_i == 2'b11))
        begin
            requester                 <= mb_cmpl_control_data_i[15:0];
            completer                 <= mb_cmpl_control_data_i[31:16];
            csi_vc                    <= mb_cmpl_control_data_i[35:32];
            csi_src                   <= mb_cmpl_control_data_i[40:36];
            csi_dst                   <= mb_cmpl_control_data_i[45:41];
            csi_is_managed            <= mb_cmpl_control_data_i[46];
            csi_poison                <= mb_cmpl_control_data_i[47];
            attr                      <= mb_cmpl_control_data_i[50:48];
            tc                        <= mb_cmpl_control_data_i[53:51];
            tag                       <= mb_cmpl_control_data_i[63:54];
            lower_addr                <= mb_cmpl_control_data_i[70:64];
            is_first                  <= mb_cmpl_control_data_i[71];
            byte_count                <= mb_cmpl_control_data_i[83:72];
            is_last                   <= mb_cmpl_control_data_i[84];
            dw_len                    <= mb_cmpl_control_data_i[94:85];
            req_type                  <= mb_cmpl_control_data_i[100:95];
            packet_2_present          <= mb_cmpl_control_data_i[101];
            seed_value                <= mb_cmpl_data_i[31:0];
            cmpl_data_ram_rdaddr_o    <= cmpl_data_ram_rdaddr_o + 'd4;
            cmpl_data_ram_read_count  <= cmpl_data_ram_read_count + 'd1;
            if(mb_cmpl_control_data_i[95] == 'b0)                                 // if 2 NPR request present at one Ram location
            begin
                cmpl_control_ram_rdaddr_o <= cmpl_control_ram_rdaddr_o + 'd1;
                cmpl_cmd_ram_read_count   <= cmpl_cmd_ram_read_count + 'd1; 
            end
        end
        if(initiate_npr_req_i == 1'b1 || (initiate_next_npr_cmd_req && f2csi_npr_rdy_i))
        begin
            npr_requester              <= mb_npr_control_data_i[15:0];
            npr_completer              <= mb_npr_control_data_i[31:16];
            npr_completer_set          <= mb_npr_control_data_i[32];
            npr_csi_vc                 <= mb_npr_control_data_i[36:33];
            npr_csi_src                <= mb_npr_control_data_i[41:37];
            npr_csi_dst_fifo           <= mb_npr_control_data_i[50:42];
            npr_csi_dst                <= mb_npr_control_data_i[55:51];
            npr_csi_is_managed         <= mb_npr_control_data_i[56];
            npr_csi_poison             <= mb_npr_control_data_i[57];
            npr_attr                   <= mb_npr_control_data_i[60:58];
            npr_secure                 <= mb_npr_control_data_i[61];
            npr_trusted                <= mb_npr_control_data_i[62];
            npr_ide_enable             <= mb_npr_control_data_i[63];
            npr_num_txn                <= mb_npr_control_data_i[81:72];
            npr_stop_txn               <= mb_npr_control_data_i[82];
            npr_tc                     <= mb_npr_control_data_i[85:83];
            npr_type                   <= mb_npr_data_i[95:90];
            npr_byte_enables           <= mb_npr_data_i[89:82];
            npr_tag                    <= mb_npr_data_i[81:72];
            npr_dw_len                 <= mb_npr_data_i[71:62];
            npr_addr                   <= mb_npr_data_i[61:0];
            npr_control_ram_rdaddr_o   <= npr_control_ram_rdaddr_o + 'd16;
            npr_cmd_ram_read_count     <= npr_cmd_ram_read_count + 'd1; 
        end
        else if(initiate_npr_req && f2csi_npr_rdy_i)
        begin
            npr_type                   <= mb_npr_data_i[95:90];
            npr_byte_enables           <= mb_npr_data_i[89:82];
            npr_tag                    <= mb_npr_data_i[81:72];
            npr_dw_len                 <= mb_npr_data_i[71:62];
            npr_addr                   <= mb_npr_data_i[61:0];  
        end
    end
end 

////////////////////////////////////////////////////////////////
////               Requent generation logic                 ////
///////////////////////////////////////////////////////////////

always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin
        pr_in_seed                <= 'd0;
        cmpl_in_seed              <= 'd0;
        pr_req_initiated          <= 'd0;
        cmpl_req_initiated        <= 'd0;
        dw_count                  <= 'd0;
        dw_count_s1               <= 'd0;
        pr_data_ram_rdaddr_o      <= 'd0;
        npr_data_ram_rdaddr_o     <= 'd0;
        rem_txns                  <= 'd0;
        npr_rem_txns              <= 'd0;
        pr_txn_in_process_o       <= 'b0;
        npr_txn_in_process_o      <= 'b0;
        cmpl_txn_in_process_o     <= 'b0;
        sop_o                     <= 'b0;
        eop_o                     <= 'b0;
        eop_s1_o                  <= 'b0;
        cap_header_o              <= 'd0;
        npr_cap_header_o          <= 'd0;
        npr_sop_o                 <= 'b0;
        npr_eop_o                 <= 'b0;
        sop_o                     <= 'b0;
        initiate_pr_req           <= 'b0;
        initiate_npr_req          <= 'b0;
        initiate_cmpl_req         <= 'b0;
        rem_data                  <= 'b0;
        initiate_next_pr_cmd_req  <= 'b0;
        initiate_next_npr_cmd_req <= 'b0;
        initiate_next_cmpl_req    <= 'b0;
        credits_used_o            <= 'd0;
        initiate_pending_cmpl     <= 'd0;
        pr_data_ram_read_count    <= 'd0;
        npr_data_ram_read_count   <= 'd0;
    end
    else
    begin   
        if(f2csi_prcmpl_rdy_i == 2'b11)
        begin
            if(initiate_cmpl_req_i || initiate_next_cmpl_req)
            begin
                initiate_cmpl_req         <= 'b1;
                cmpl_txn_in_process_o     <= 'b0;
                sop_o                     <= 'b0;
                eop_o                     <= 'b0;
                eop_s1_o                  <= 'b0;
                rem_data                  <= 'd0;
                initiate_next_pr_cmd_req  <= 'b0;
                initiate_next_cmpl_req    <= 'd0;
                initiate_pending_cmpl     <= 'd0;
            end     
            else if(cmpl_data_read)
            begin
                initiate_cmpl_req         <= 'b1;
                cmpl_txn_in_process_o     <= 'b1;
                sop_o                     <= 'b0;
                eop_o                     <= 'b0;
                eop_s1_o                  <= 'b0;
                rem_data                  <= 'd0;
                initiate_next_pr_cmd_req  <= 'b0;
                initiate_next_cmpl_req    <= 'd0;
                initiate_pending_cmpl     <= 'd0;
            end
            else if(cmpl_req_initiated == 1'b1 )
            begin
                if(eop_o == 1'b1 || eop_s1_o == 1'b1)
                begin
                    dw_count                   <= 'd0;
                    dw_count_s1                <= 'd0;
                    pr_req_initiated           <= 'd0;
                    cmpl_req_initiated         <= 'd0;
                    sop_o                      <= 'b0;
                    eop_o                      <= 'b0;
                    eop_s1_o                   <= 'b0;
                    initiate_next_pr_cmd_req   <= 'b0;
                    rem_data                   <= 'd0;
                    if(packet_2_present)
                    begin
                        initiate_next_cmpl_req <= 'b1;      
                        cmpl_txn_in_process_o  <= 'b1;
                        initiate_pending_cmpl  <= 'b0;
                    end
                    else if(ram_read_left > 'd0)
                    begin
                        initiate_next_cmpl_req <= 'b0;
                        initiate_pending_cmpl  <= 'b1;  
                        cmpl_txn_in_process_o  <= 'b1;
                    end
                    else
                    begin
                        initiate_next_cmpl_req <= 'b0;      
                        cmpl_txn_in_process_o  <= 'b0;
                        initiate_pending_cmpl  <= 'b0;
                    end
                end
                else if(rem_data <= 'd10)
                begin
                    dw_count                 <= rem_data;
                    dw_count_s1              <= 'd0;
                    cmpl_req_initiated       <= 'd1;
                    pr_req_initiated         <= 'd0;
                    sop_o                    <= 'b0;
                    eop_o                    <= 'b1;
                    eop_s1_o                 <= 'b0;
                    rem_data                 <= 'd0;
                    initiate_next_pr_cmd_req <= 'b0;
                    initiate_next_cmpl_req   <= 'b0;
                    initiate_pending_cmpl    <= 'b0;
                    if(rem_data > 'd5)
                        credits_used_o       <= 'd2;
                    else                     
                        credits_used_o       <= 'd1;
                end
                else if(rem_data <= 'd20)
                begin
                    dw_count                 <= 'd10;
                    dw_count_s1              <= rem_data -'d10;
                    pr_req_initiated         <= 'd0;
                    cmpl_req_initiated       <= 'd1;
                    sop_o                    <= 'b0;
                    eop_o                    <= 'b0;
                    eop_s1_o                 <= 'b1;
                    rem_data                 <= 'd0;
                    initiate_pr_req          <= 'b0;    
                    initiate_next_pr_cmd_req <= 'b0;
                    initiate_next_cmpl_req   <= 'b0;
                    initiate_pending_cmpl    <= 'b0;
                    if(rem_data > 'd15)
                        credits_used_o       <= 'd4;
                    else                     
                        credits_used_o       <= 'd3;
                end     
                else
                begin
                    dw_count                 <= 'd10;
                    dw_count_s1              <= 'd10;
                    cmpl_req_initiated       <= 'd1;
                    pr_req_initiated         <= 'd0;        
                    cmpl_txn_in_process_o    <= 'b1;
                    sop_o                    <= 'b0;
                    eop_o                    <= 'b0;
                    eop_s1_o                 <= 'b0;
                    initiate_next_pr_cmd_req <= 'b0;
                    initiate_next_cmpl_req   <= 'b0;
                    initiate_pending_cmpl    <= 'b0;
                    rem_data                 <= rem_data - 'd20;
                    credits_used_o           <= 'd4;
                end 
            end 
            else if(((initiate_cmpl_req && cmpl_control_ram_ready_d) || initiate_next_cmpl_req || initiate_pending_cmpl) && 
                    ((local_crdts_avail_cmpl*5) > (dw_len_actual + 'd7)) && local_crdts_avail_cmpl_vld && cmpl_data_read_d && 
                    (req_type == CSI_CT_RD_MEM))       // CMPL generation
            begin
                cmpl_in_seed             <= seed_value;
                pr_req_initiated         <= 'd0;
                cmpl_req_initiated       <= 'd1;    
                sop_o                    <= 1'b1;       
                cmpl_txn_in_process_o    <= 'b1;               // At sop_o- 224 bit header, 96 bit data (max) can be transmitted
                initiate_next_pr_cmd_req <= 'b0;
                initiate_next_cmpl_req   <= 'b0;
                initiate_pending_cmpl    <= 'b0;
                cap_header_o             <= {11'd0,84'd0,is_last,is_first,byte_count,lower_addr,tag,tc,CSI_CMPT_STATUS_SC,
                                          CSI_PCIE_AT_UNTRANSLATED,CSI_CT_COMPLETION,requester,completer,attr,
                                          3'd0,csi_is_managed,csi_poison,8'd0,1'b1,csi_dst,csi_src,csi_vc,
                                           dw_len,1'b0,1'b1,2'd1,CSI_CT_COMPLETION};
                if(dw_len == 'd1 || dw_len == 'd2 || dw_len == 'd3) 
                begin           
                    dw_count              <= dw_len;
                    dw_count_s1           <= 'd0;
                    eop_o                 <= 'd1;
                    eop_s1_o              <= 1'b0;
                    credits_used_o        <= 'd2;
                    rem_data              <= 'd0;
                end 
                else 
                begin
                    dw_count              <= 'd3;
                    if(dw_len > 'd13) 
                    begin
                        dw_count_s1       <= 'd10;
                        eop_o             <= 1'b0;
                        eop_s1_o          <= 1'b0;
                        rem_data          <= dw_len_actual - 'd13; 
                        credits_used_o    <= 'd4;
                    end 
                    else
                    begin
                        dw_count_s1       <= dw_len - 'd3;
                        eop_o             <= 1'b0;
                        eop_s1_o          <= 1'b1;
                        rem_data          <= 'd0;
                        if(dw_len > 'd8)
                            credits_used_o    <= 'd4;
                        else    
                            credits_used_o    <= 'd3;
                    end     
                end 
            end
            else if(initiate_pr_req_i || initiate_next_pr_cmd_req) 
            begin
                initiate_pr_req          <= 'b1;
                pr_txn_in_process_o      <= 'b1;
                rem_txns                 <= mb_pr_control_data_i[81:72]; //num_txn; karthik change feb11
                sop_o                    <= 'b0;
                eop_o                    <= 'b0;
                eop_s1_o                 <= 'b0;
                rem_data                 <= 'd0;
                initiate_next_pr_cmd_req <= 'b0;    
            end
            else if(pr_req_initiated == 1'b1 )
            begin
                if(eop_o == 1'b1 || eop_s1_o == 1'b1)
                begin
                    dw_count               <= 'd0;
                    dw_count_s1            <= 'd0;
                    pr_req_initiated       <= 'd0;
                    cmpl_req_initiated     <= 'd0;
                    sop_o                  <= 'b0;
                    eop_o                  <= 'b0;
                    eop_s1_o               <= 'b0;
                    initiate_next_cmpl_req <= 'b0;
                    initiate_pending_cmpl  <= 'b0;
                    if(rem_txns > 'd0)                            //39
                    begin                                
                        ////Initiatting data ram read
                        initiate_pr_req          <= 'b1;
                        pr_data_ram_rdaddr_o     <= pr_data_ram_rdaddr_o + 'd16;            
                        pr_data_ram_read_count   <= pr_data_ram_read_count + 'd1;                       
                        pr_txn_in_process_o      <= 'b1;    
                        rem_data                 <=  dw_len_actual;
                        initiate_next_pr_cmd_req <= 'b0;
                    end 
                    else 
                    begin
                        if(stop_txn == 1'b1)
                        begin
                            initiate_pr_req          <= 'b0;        
                            pr_txn_in_process_o      <= 'b0;    
                            rem_data                 <= 'd0;
                            pr_data_ram_rdaddr_o     <= 'd0;
                            pr_data_ram_read_count   <= pr_data_ram_read_count + 'd1;
                            initiate_next_pr_cmd_req <= 'b0;    
                        end
                        else
                        begin
                            initiate_pr_req          <= 'b0;        
                            pr_txn_in_process_o      <= 'b1;    
                            rem_data                 <= 'd0;    
                            pr_data_ram_rdaddr_o     <= pr_data_ram_rdaddr_o + 'd16;
                            pr_data_ram_read_count   <= pr_data_ram_read_count + 'd1;
                            initiate_next_pr_cmd_req <= 'b1;                
                        end
                    end
                end
                else if(rem_data <= 'd10)
                begin
                    dw_count                 <= rem_data;
                    dw_count_s1              <= 'd0;
                    pr_req_initiated         <= 'd1;
                    cmpl_req_initiated       <= 'd0;
                    sop_o                    <= 'b0;
                    eop_o                    <= 'b1;
                    eop_s1_o                 <= 'b0;
                    rem_data                 <= 'd0;
                    initiate_pr_req          <= 'b0;    
                    initiate_next_pr_cmd_req <= 'b0;
                    initiate_next_cmpl_req   <= 'b0;
                    initiate_pending_cmpl    <= 'b0;
                    if(rem_data > 'd5)
                        credits_used_o       <= 'd2;
                    else                     
                        credits_used_o       <= 'd1;
                end
                else if(rem_data <= 'd20)
                begin
                    dw_count                 <= 'd10;
                    dw_count_s1              <= rem_data -'d10;
                    pr_req_initiated         <= 'd1;
                    cmpl_req_initiated       <= 'd0;
                    sop_o                    <= 'b0;
                    eop_o                    <= 'b0;
                    eop_s1_o                 <= 'b1;
                    rem_data                 <= 'd0;
                    initiate_pr_req          <= 'b0;    
                    initiate_next_pr_cmd_req <= 'b0;
                    initiate_next_cmpl_req   <= 'b0;
                    initiate_pending_cmpl    <= 'b0;
                    if(rem_data > 'd15)
                        credits_used_o       <= 'd4;
                    else                     
                        credits_used_o       <= 'd3;
                end 
                else
                begin
                    dw_count                 <= 'd10;
                    dw_count_s1              <= 'd10;
                    pr_req_initiated         <= 'd1;
                    cmpl_req_initiated       <= 'd0;
                    initiate_pr_req          <= 'b0;        
                    pr_txn_in_process_o      <= 'b1;
                    sop_o                    <= 'b0;
                    eop_o                    <= 'b0;        
                    eop_s1_o                 <= 'b0;        
                    rem_data                 <= rem_data - 'd20;
                    initiate_next_pr_cmd_req <= 'b0;
                    initiate_next_cmpl_req   <= 'b0;
                    initiate_pending_cmpl    <= 'b0;
                    credits_used_o           <= 'd4;
                end 
            end
            else if(initiate_pr_req && ((local_crdts_avail_pr*5/*converting to dw_len*/) > (dw_len_actual + 'd7/*header dw_len*/)) 
                    && local_crdts_avail_pr_vld) //credits are calculated based on segment width - to convert it to dw_len multiplying it by 5
            begin
                pr_in_seed               <= seed_value;
                cmpl_req_initiated       <= 'd0;
                pr_req_initiated         <= 'd1;
                sop_o                    <= 1'b1;   
                pr_txn_in_process_o      <= 'b1;                     // At sop_o- 224 bit header, 96 bit data (max) can be transmitted
                initiate_pr_req          <= 'b0;
                initiate_next_pr_cmd_req <= 'b0;
                initiate_next_cmpl_req   <= 'b0;
                initiate_pending_cmpl    <= 'b0;
                cap_header_o             <= {10'd0,1'd0,7'd0,ide_enable,trusted,secure,10'd0,11'd0,tc,23'd0,byte_enables,
                                          CSI_PCIE_AT_UNTRANSLATED,addr,completer_set,completer,requester,attr,
                                          3'd0,csi_is_managed,csi_poison,9'd0,csi_dst,csi_dst_fifo,
                                           dw_len,1'b0,1'b1,2'd2,CSI_CT_WR_MEM};
                if(rem_txns == 'd0)
                    rem_txns          <= 'd0;
                else
                    rem_txns          <= rem_txns - 'd1;
                if(dw_len == 'd1 || dw_len == 'd2 || dw_len == 'd3) 
                begin           
                    dw_count              <= dw_len;
                    dw_count_s1           <= 'd0;
                    eop_o                 <= 1'b1;
                    eop_s1_o              <= 1'b0;
                    credits_used_o        <= 'd2;
                    rem_data              <= 'd0;
                end 
                else 
                begin
                    dw_count              <= 'd3;
                    if(dw_len > 'd13) 
                    begin
                        dw_count_s1       <= 'd10;
                        eop_o             <= 1'b0;
                        eop_s1_o          <= 1'b0;
                        rem_data          <= dw_len_actual - 'd13; 
                        credits_used_o    <= 'd4;
                    end 
                    else
                    begin
                        dw_count_s1       <= dw_len - 'd3;
                        eop_o             <= 1'b0;
                        eop_s1_o          <= 1'b1;
                        rem_data          <= 'd0;
                        if(dw_len > 'd8)
                            credits_used_o    <= 'd4;
                        else    
                            credits_used_o    <= 'd3;
                    end 
                end 
            end
            else
            begin
                eop_o                    <= 'd0;
                eop_s1_o                 <= 'd0;
                sop_o                    <= 'd0;
                initiate_next_pr_cmd_req <= 'b0;
                initiate_next_cmpl_req   <= 'b0;
                initiate_pending_cmpl    <= 'b0;
            end 
        end 
        if(f2csi_npr_rdy_i == 1'b1)
        begin
            if(initiate_npr_req_i || initiate_next_npr_cmd_req)
            begin
                initiate_npr_req          <= 'b1;
                npr_txn_in_process_o      <= 'b1;
                npr_sop_o                 <= 'b0;
                npr_eop_o                 <= 'b0;
                npr_rem_txns              <= mb_npr_control_data_i[81:72];
                initiate_next_npr_cmd_req <= 'b0;
            end
            else if(initiate_npr_req && (local_crdts_avail_npr >= 'd2) && local_crdts_avail_npr_vld) 
            begin
                npr_sop_o                 <= 'b1;
                npr_eop_o                 <= 'b1;
            if(npr_type == CSI_CT_BARRIER)
            begin
            npr_cap_header_o          <= {11'd0,7'd0,3'd0,/*npr_ide_enable,npr_trusted,npr_secure,*/npr_tag,11'd0,3'd0/*npr_tc*/,23'd0,8'd0/*npr_byte_enables*/,
                                      CSI_PCIE_AT_UNTRANSLATED,npr_addr,npr_completer_set,npr_completer,npr_requester,3'd0/*npr_attr*/,
                                      3'd0,2'd0/*npr_csi_is_managed,npr_csi_poison*/,csi_after_pr_seq_i,1'b0,npr_csi_dst,npr_csi_dst_fifo,
                                       10'd1/*npr_dw_len*/,1'b0,1'b0,2'd0,CSI_CT_BARRIER};  
            /*npr_cap_header_o          <= {11'd0,7'd0,npr_ide_enable,npr_trusted,npr_secure,npr_tag,11'd0,npr_tc,23'd0,npr_byte_enables,
                                      CSI_PCIE_AT_UNTRANSLATED,npr_addr,npr_completer_set,npr_completer,npr_requester,npr_attr,
                                      3'd0,npr_csi_is_managed,npr_csi_poison,csi_after_pr_seq_i,1'b0,npr_csi_dst,npr_csi_dst_fifo,
                                       npr_dw_len,1'b0,1'b0,2'd0,CSI_CT_BARRIER};   */
            end                        
            else
            begin
            npr_cap_header_o          <= {11'd0,7'd0,npr_ide_enable,npr_trusted,npr_secure,npr_tag,11'd0,npr_tc,23'd0,npr_byte_enables,
                                      CSI_PCIE_AT_UNTRANSLATED,npr_addr,npr_completer_set,npr_completer,npr_requester,npr_attr,
                                      3'd0,npr_csi_is_managed,npr_csi_poison,csi_after_pr_seq_i,1'b0,npr_csi_dst,npr_csi_dst_fifo,
                                       npr_dw_len,1'b0,1'b0,2'd0,CSI_CT_RD_MEM};        
            end                 
            if(npr_rem_txns == 'd0)
                    npr_rem_txns          <= 'd0;
                else
                    npr_rem_txns          <= npr_rem_txns - 'd1;
                if(npr_rem_txns > 'd1)
                begin                                
                     ////Initiatting data ram read
                     initiate_npr_req      <= 'b1;
                     npr_data_ram_rdaddr_o <= npr_data_ram_rdaddr_o + 'd16;     
                     npr_data_ram_read_count   <= npr_data_ram_read_count + 'd1;    
                     npr_txn_in_process_o  <= 'b1;
                     initiate_next_npr_cmd_req <= 'b0;  
                end 
                else 
                begin
                    if(npr_stop_txn == 1'b1)
                    begin
                        initiate_npr_req          <= 'b0;       
                        npr_txn_in_process_o      <= 'b0;   
                        initiate_next_npr_cmd_req <= 'b0;   
                        npr_data_ram_rdaddr_o     <= 'd0;   
                        npr_data_ram_read_count   <= npr_data_ram_read_count + 'd1;
                    end
                    else
                    begin
                        initiate_npr_req          <= 'b0;       
                        npr_txn_in_process_o      <= 'b1;   
                        initiate_next_npr_cmd_req <= 'b1;    
                        npr_data_ram_rdaddr_o     <= npr_data_ram_rdaddr_o + 'd16;      
                        npr_data_ram_read_count   <= npr_data_ram_read_count + 'd1;
                    end
                end
            end
            else
            begin
                npr_sop_o             <= 'b0;
                npr_eop_o             <= 'b0;   
                initiate_next_npr_cmd_req <= 'b0;       
            end
        end 
    end
end 

////////////////////////////////////////////////////////////////////
////               Registering Previously sent data             ////
///////////////////////////////////////////////////////////////////

always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin
       prev_pr_seed     <= 'd0;
       prev_cmpl_seed   <= 'd0;
    end
    else
    begin
        if(dw_count_s1 == 'd0)
        begin
            case(dw_count)
            4'd0:  begin
                prev_pr_seed   <= pr_in_seed + 'd1;
                prev_cmpl_seed <= cmpl_in_seed + 'd1;
            end    
            4'd1: begin 
                prev_pr_seed   <= pr_data_o[31:0];
                prev_cmpl_seed <= cmpl_data_o[31:0];
            end    
            4'd2: begin 
                prev_pr_seed   <= pr_data_o[63:32];
                prev_cmpl_seed <= cmpl_data_o[63:32];
            end    
            4'd3:   begin 
                prev_pr_seed   <= pr_data_o[95:64];
                prev_cmpl_seed <= cmpl_data_o[95:64];
            end    
            4'd4:   begin 
                prev_pr_seed   <= pr_data_o[127:96];
                prev_cmpl_seed <= cmpl_data_o[127:96];
            end    
            4'd5:  begin 
                prev_pr_seed   <= pr_data_o[159:128];
                prev_cmpl_seed <= cmpl_data_o[159:128];
            end    
            4'd6:   begin 
                prev_pr_seed   <= pr_data_o[191:160];
                prev_cmpl_seed <= cmpl_data_o[191:160];
            end    
            4'd7:   begin 
                prev_pr_seed   <= pr_data_o[223:192];
                prev_cmpl_seed <= cmpl_data_o[223:192];
            end    
            4'd8:   begin 
                prev_pr_seed   <= pr_data_o[255:224];
                prev_cmpl_seed <= cmpl_data_o[255:224];
            end    
            4'd9:   begin 
                prev_pr_seed   <= pr_data_o[287:256];
                prev_cmpl_seed <= cmpl_data_o[287:256];
            end    
            4'd10:  begin 
                prev_pr_seed   <= pr_data_o[319:288];
                prev_cmpl_seed <= cmpl_data_o[319:288];
            end  
            default: begin 
                prev_pr_seed   <= pr_in_seed + 'd1;
                prev_cmpl_seed <= cmpl_in_seed + 'd1;
            end    
            endcase
        end
        else
        begin
            case(dw_count_s1)
            4'd1: begin 
                prev_pr_seed   <= pr_data_s1_o[31:0];
                prev_cmpl_seed <= cmpl_data_s1_o[31:0];
            end    
            4'd2: begin 
                prev_pr_seed   <= pr_data_s1_o[63:32];
                prev_cmpl_seed <= cmpl_data_s1_o[63:32];
            end    
            4'd3:   begin 
                prev_pr_seed   <= pr_data_s1_o[95:64];
                prev_cmpl_seed <= cmpl_data_s1_o[95:64];
            end    
            4'd4:   begin 
                prev_pr_seed   <= pr_data_s1_o[127:96];
                prev_cmpl_seed <= cmpl_data_s1_o[127:96];
            end    
            4'd5:  begin 
                prev_pr_seed   <= pr_data_s1_o[159:128];
                prev_cmpl_seed <= cmpl_data_s1_o[159:128];
            end    
            4'd6:   begin 
                prev_pr_seed   <= pr_data_s1_o[191:160];
                prev_cmpl_seed <= cmpl_data_s1_o[191:160];
            end    
            4'd7:   begin 
                prev_pr_seed   <= pr_data_s1_o[223:192];
                prev_cmpl_seed <= cmpl_data_s1_o[223:192];
            end    
            4'd8:   begin 
                prev_pr_seed   <= pr_data_s1_o[255:224];
                prev_cmpl_seed <= cmpl_data_s1_o[255:224];
            end    
            4'd9:   begin 
                prev_pr_seed   <= pr_data_s1_o[287:256];
                prev_cmpl_seed <= cmpl_data_s1_o[287:256];
            end    
            4'd10:  begin 
                prev_pr_seed   <= pr_data_s1_o[319:288];
                prev_cmpl_seed <= cmpl_data_s1_o[319:288];
            end  
            default: begin 
                prev_pr_seed   <= pr_in_seed + 'd1;
                prev_cmpl_seed <= cmpl_in_seed + 'd1;
            end    
            endcase
        end     
    end
end    

////////////////////////////////////////////////////////////////////
////                   Data output to Encoder                   ////
///////////////////////////////////////////////////////////////////
always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin
       pr_data_q        <= 'd0;
       pr_data_s1_q     <= 'd0;
       cmpl_data_q      <= 'd0;
       cmpl_data_s1_q   <= 'd0;
    end
    else
    begin
       pr_data_q        <= pr_data_o;
       cmpl_data_q      <= cmpl_data_o;
       pr_data_s1_q     <= pr_data_s1_o;
       cmpl_data_s1_q   <= cmpl_data_s1_o;
    end
end 

    
    
always_comb
begin 
    case(dw_count)
        'd1: begin 
            if(pr_req_initiated)
            begin
                pr_data_valid_o    = 'b01;
                cmpl_data_valid_o  = 'd0;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_pr_seed == pr_in_seed)
                    pr_data_o = {288'd0,(pr_in_seed + 'd1)};
                else    
                    pr_data_o = {288'd0,pr_in_seed};
            end
            else if (cmpl_req_initiated)
            begin
                pr_data_o          = pr_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                cmpl_data_valid_o  = 'b01;
                pr_data_valid_o    = 'd0;
                if(prev_cmpl_seed == cmpl_in_seed)
                    cmpl_data_o = {288'd0,(cmpl_in_seed + 'd1)};
                else    
                    cmpl_data_o = {288'd0,cmpl_in_seed};
            end
            else
            begin
                pr_data_o          = pr_data_q;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                pr_data_valid_o    = 'd0;
                cmpl_data_valid_o  = 'd0;
            end
        end
        'd2: begin  
            if(pr_req_initiated)
            begin
                pr_data_valid_o    = 'b01;
                cmpl_data_valid_o  = 'd0;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_pr_seed == pr_in_seed)
                    pr_data_o = {256'd0,pr_in_seed,(pr_in_seed + 'd1)};
                else    
                    pr_data_o = {256'd0,(pr_in_seed + 'd1),pr_in_seed};
            end
            else if (cmpl_req_initiated)
            begin
                cmpl_data_valid_o  = 'b01;
                pr_data_valid_o    = 'd0;
                pr_data_o          = pr_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_cmpl_seed == cmpl_in_seed)
                    cmpl_data_o = {256'd0,cmpl_in_seed,(cmpl_in_seed + 'd1)};
                else    
                    cmpl_data_o = {256'd0,(cmpl_in_seed + 'd1),cmpl_in_seed};
            end
            else
            begin
                pr_data_o          = pr_data_q;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                pr_data_valid_o    = 'd0;
                cmpl_data_valid_o  = 'd0;
            end
        end
        'd3: begin  
            if(pr_req_initiated)
            begin
                cmpl_data_valid_o  = 'd0;
                cmpl_data_o        = cmpl_data_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(dw_count_s1 > 'd0)
                    pr_data_valid_o = 'b11;
                else    
                    pr_data_valid_o = 'b01;                 
                if(prev_pr_seed == pr_in_seed)
                begin
                    pr_data_o      = {224'd0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    case(dw_count_s1)
                    'd1: pr_data_s1_o = {'d0,pr_in_seed};
                    'd2: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed};
                    'd3: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    'd4: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    'd5: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    'd6: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed};
                    'd7: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed};
                    'd8: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    'd9: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    'd10: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),
                                             pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    default: pr_data_s1_o = pr_data_s1_q;                    
                    endcase                      
                end 
                else
                begin                   
                    pr_data_o = {224'd0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    case(dw_count_s1)
                    'd1: pr_data_s1_o = {'d0,(pr_in_seed + 'd1)};
                    'd2: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1)};
                    'd3: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    'd4: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    'd5: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1)};
                    'd6: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1)};
                    'd7: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    'd8: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    'd9: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),
                                             pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    'd10: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    default: pr_data_s1_o = pr_data_s1_q;           
                    endcase                 
                end 
            end
            else if (cmpl_req_initiated)
            begin
                pr_data_valid_o    = 'd0;
                pr_data_o          = pr_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                if(dw_count_s1 > 'd0)
                    cmpl_data_valid_o = 'b11;
                else    
                    cmpl_data_valid_o = 'b01;
                if(prev_cmpl_seed == cmpl_in_seed)
                begin
                    cmpl_data_o = {224'd0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    case(dw_count_s1)
                    'd1: cmpl_data_s1_o = {'d0,cmpl_in_seed};
                    'd2: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd3: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd4: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd5: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd6: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd7: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd8: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd9: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd10: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),
                                             cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    default: cmpl_data_s1_o = cmpl_data_s1_q;           
                    endcase
                end 
                else  
                begin               
                    cmpl_data_o = {224'd0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    case(dw_count_s1)
                    'd1: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1)};
                    'd2: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd3: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd4: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd5: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1)};
                    'd6: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1)};
                    'd7: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd8: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd9: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),
                                             cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd10: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),
                                             cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    default: cmpl_data_s1_o = cmpl_data_s1_q;       
                    endcase
                end 
            end
            else
            begin
                pr_data_o          = pr_data_q;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                pr_data_valid_o    = 'd0;
                cmpl_data_valid_o  = 'd0;
            end
        end
        'd4: begin   
            if(pr_req_initiated)
            begin
                pr_data_valid_o    = 'b01;
                cmpl_data_valid_o  = 'd0;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_pr_seed == pr_in_seed)
                    pr_data_o = {192'd0,{2{pr_in_seed,(pr_in_seed + 'd1)}}};
                else    
                    pr_data_o = {192'd0,{2{(pr_in_seed + 'd1),pr_in_seed}}};
            end
            else if (cmpl_req_initiated)
            begin
                pr_data_o          = pr_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                cmpl_data_valid_o  = 'b01;
                pr_data_valid_o    = 'd0;
                if(prev_cmpl_seed == cmpl_in_seed)
                    cmpl_data_o = {192'd0,{2{cmpl_in_seed,(cmpl_in_seed + 'd1)}}};
                else    
                    cmpl_data_o = {192'd0,{2{(cmpl_in_seed + 'd1),cmpl_in_seed}}};
            end
            else
            begin
                pr_data_o          = pr_data_q;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                pr_data_valid_o    = 'd0;
                cmpl_data_valid_o  = 'd0;
            end
        end
        'd5: begin   
            if(pr_req_initiated)
            begin
                pr_data_valid_o    = 'b01;
                cmpl_data_valid_o  = 'd0;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_pr_seed == pr_in_seed)
                    pr_data_o = {160'd0,(pr_in_seed + 'd1),{2{pr_in_seed,(pr_in_seed + 'd1)}}};
                else    
                    pr_data_o = {160'd0,pr_in_seed,{2{(pr_in_seed + 'd1),pr_in_seed}}};
            end
            else if (cmpl_req_initiated)
            begin
                cmpl_data_valid_o  = 'b01;
                pr_data_valid_o    = 'd0;
                pr_data_o          = pr_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_cmpl_seed == cmpl_in_seed)
                    cmpl_data_o = {160'd0,(cmpl_in_seed + 'd1),{2{cmpl_in_seed,(cmpl_in_seed + 'd1)}}};
                else    
                    cmpl_data_o = {160'd0,cmpl_in_seed,{2{(cmpl_in_seed + 'd1),cmpl_in_seed}}};
            end
            else
            begin
                pr_data_o          = pr_data_q;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                pr_data_valid_o    = 'd0;
                cmpl_data_valid_o  = 'd0;
            end
        end
        'd6: begin    
            if(pr_req_initiated)
            begin
                pr_data_valid_o    = 'b01;
                cmpl_data_valid_o  = 'd0;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q; 
                if(prev_pr_seed == pr_in_seed)
                    pr_data_o = {128'd0,{3{pr_in_seed,(pr_in_seed + 'd1)}}};
                else    
                    pr_data_o = {128'd0,{3{(pr_in_seed + 'd1),pr_in_seed}}};
            end
            else if (cmpl_req_initiated)
            begin
                pr_data_o          = pr_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                cmpl_data_valid_o = 'b01;
                pr_data_valid_o   = 'd0;
                if(prev_cmpl_seed == cmpl_in_seed)
                    cmpl_data_o = {128'd0,{3{cmpl_in_seed,(cmpl_in_seed + 'd1)}}};
                else    
                    cmpl_data_o = {128'd0,{3{(cmpl_in_seed + 'd1),cmpl_in_seed}}};
            end
            else
            begin
                pr_data_o          = pr_data_q;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                pr_data_valid_o    = 'd0;
                cmpl_data_valid_o  = 'd0;
            end
        end
        'd7: begin    
            if(pr_req_initiated)
            begin
                pr_data_valid_o    = 'b01;
                cmpl_data_valid_o  = 'd0;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_pr_seed == pr_in_seed)
                    pr_data_o = {96'd0,(pr_in_seed + 'd1),{3{pr_in_seed,(pr_in_seed + 'd1)}}};
                else    
                    pr_data_o = {96'd0,pr_in_seed,{3{(pr_in_seed + 'd1),pr_in_seed}}};
            end
            else if (cmpl_req_initiated)
            begin
                cmpl_data_valid_o  = 'b01;
                pr_data_valid_o    = 'd0;
                pr_data_o          = pr_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_cmpl_seed == cmpl_in_seed)
                    cmpl_data_o = {96'd0,(cmpl_in_seed + 'd1),{3{cmpl_in_seed,(cmpl_in_seed + 'd1)}}};
                else    
                    cmpl_data_o = {96'd0,cmpl_in_seed,{3{(cmpl_in_seed + 'd1),cmpl_in_seed}}};
            end
            else
            begin
                pr_data_o          = pr_data_q;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                pr_data_valid_o    = 'd0;
                cmpl_data_valid_o  = 'd0;
            end
        end
        'd8: begin    
            if(pr_req_initiated)
            begin
                pr_data_valid_o    = 'b01;
                cmpl_data_valid_o  = 'd0;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_pr_seed == pr_in_seed)
                    pr_data_o = {64'd0,{4{pr_in_seed,(pr_in_seed + 'd1)}}};
                else    
                    pr_data_o = {64'd0,{4{(pr_in_seed + 'd1),pr_in_seed}}};
            end
            else if (cmpl_req_initiated)
            begin
                cmpl_data_valid_o = 'b01;
                pr_data_valid_o   = 'd0;
                pr_data_o          = pr_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_cmpl_seed == cmpl_in_seed)
                    cmpl_data_o = {64'd0,{4{cmpl_in_seed,(cmpl_in_seed + 'd1)}}};
                else    
                    cmpl_data_o = {64'd0,{4{(cmpl_in_seed + 'd1),cmpl_in_seed}}};
            end
            else
            begin
                pr_data_o          = pr_data_q;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                pr_data_valid_o    = 'd0;
                cmpl_data_valid_o  = 'd0;
            end
        end
        'd9: begin 
            if(pr_req_initiated)
            begin
                pr_data_valid_o    = 'b01;
                cmpl_data_valid_o  = 'd0;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_pr_seed == pr_in_seed)
                    pr_data_o = {32'd0,(pr_in_seed + 'd1),{4{pr_in_seed,(pr_in_seed + 'd1)}}};
                else    
                    pr_data_o = {32'd0,pr_in_seed,{4{(pr_in_seed + 'd1),pr_in_seed}}};
            end
            else if (cmpl_req_initiated)
            begin
                cmpl_data_valid_o  = 'b01;
                pr_data_valid_o    = 'd0;
                pr_data_o          = pr_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(prev_cmpl_seed == cmpl_in_seed)
                    cmpl_data_o = {32'd0,(cmpl_in_seed + 'd1),{4{cmpl_in_seed,(cmpl_in_seed + 'd1)}}};
                else    
                    cmpl_data_o = {32'd0,cmpl_in_seed,{4{(cmpl_in_seed + 'd1),cmpl_in_seed}}};
            end
            else
            begin
                pr_data_o          = pr_data_q;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                pr_data_valid_o    = 'd0;
                cmpl_data_valid_o  = 'd0;
            end
        end
        'd10: begin 
            if(pr_req_initiated)
            begin
                cmpl_data_valid_o  = 'd0;
                cmpl_data_o        = cmpl_data_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                if(dw_count_s1 > 'd0)
                    pr_data_valid_o = 'b11;
                else    
                    pr_data_valid_o = 'b01;                 
                if(prev_pr_seed == pr_in_seed)
                begin
                    pr_data_o = {5{pr_in_seed,(pr_in_seed + 'd1)}};
                    case(dw_count_s1)
                    'd1: pr_data_s1_o = {'d0,(pr_in_seed + 'd1)};
                    'd2: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1)};
                    'd3: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    'd4: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    'd5: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1)};
                    'd6: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1)};
                    'd7: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    'd8: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    'd9: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),
                                             pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    'd10: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1)};
                    default: pr_data_s1_o = pr_data_s1_q;       
                    endcase                          
                end 
                else
                begin                   
                    pr_data_o = {5{(pr_in_seed + 'd1),pr_in_seed}};     
                    case(dw_count_s1)
                    'd1: pr_data_s1_o = {'d0,pr_in_seed};
                    'd2: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed};
                    'd3: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    'd4: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    'd5: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    'd6: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed};
                    'd7: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed};
                    'd8: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    'd9: pr_data_s1_o = {'d0,pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,
                                             (pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    'd10: pr_data_s1_o = {'d0,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),
                                             pr_in_seed,(pr_in_seed + 'd1),pr_in_seed,(pr_in_seed + 'd1),pr_in_seed};
                    default: pr_data_s1_o = pr_data_s1_q;       
                    endcase     
                end 
            end
            else if (cmpl_req_initiated)
            begin
                pr_data_valid_o   = 'd0;
                pr_data_o          = pr_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                if(dw_count_s1 > 'd0)
                    cmpl_data_valid_o = 'b11;
                else    
                    cmpl_data_valid_o = 'b01;
                if(prev_cmpl_seed == cmpl_in_seed)
                begin
                    cmpl_data_o = {5{cmpl_in_seed,(cmpl_in_seed + 'd1)}};
                    case(dw_count_s1)
                    'd1: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1)};
                    'd2: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd3: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd4: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd5: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1)};
                    'd6: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1)};
                    'd7: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd8: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd9: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),
                                             cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    'd10: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),
                                             cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1)};
                    default: cmpl_data_s1_o = cmpl_data_s1_q;       
                    endcase
                end 
                else  
                begin               
                    cmpl_data_o = {224'd0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    case(dw_count_s1)
                    'd1: cmpl_data_s1_o = {'d0,cmpl_in_seed};
                    'd2: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd3: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd4: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd5: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd6: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd7: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd8: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd9: cmpl_data_s1_o = {'d0,cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,
                                             (cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    'd10: cmpl_data_s1_o = {'d0,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),
                                             cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed,(cmpl_in_seed + 'd1),cmpl_in_seed};
                    default: cmpl_data_s1_o = cmpl_data_s1_q;       
                    endcase
                end 
            end
            else
            begin
                pr_data_o          = pr_data_q;
                cmpl_data_o        = cmpl_data_q;
                pr_data_s1_o       = pr_data_s1_q;
                cmpl_data_s1_o     = cmpl_data_s1_q;
                pr_data_valid_o    = 'd0;
                cmpl_data_valid_o  = 'd0;
            end
        end 
        default: begin
            cmpl_data_s1_o     = 'd0;
            cmpl_data_o        = 'd0;
            pr_data_o          = 'd0;
            pr_data_s1_o       = 'd0;
            pr_data_valid_o    = 'd0;
            cmpl_data_valid_o  = 'd0;           
        end
    endcase
end     

endmodule   

