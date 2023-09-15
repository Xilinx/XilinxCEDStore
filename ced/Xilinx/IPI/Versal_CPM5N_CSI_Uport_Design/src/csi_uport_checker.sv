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

module csi_uport_checker 
 #(
  parameter  TCQ                   = 0,
  parameter CHECKER_FIX_PATTERN    = 1
  )(
        // Ports 
        // Clocks / Resets
                               input                   clk,
     (*mark_debug = "true"*)   input                   rst_n,
             
                               input [639:0]           pr_data_i,
                               input [319:0]           pr_data_p1_i,
     (*mark_debug = "true"*)   input [639:0]           cmpl_data_i,
                               input [319:0]           cmpl_data_p1_i,
                               input   [1:0]           pr_req_i,
     (*mark_debug = "true"*)   input   [1:0]           cmpl_req_i,
     (*mark_debug = "true"*)   input   [1:0]           dat_chk_st_i,
     (*mark_debug = "true"*)   input   [1:0]           dat_chk_dn_i,
     (*mark_debug = "true"*)   input   [1:0]           csi_flow_i,
     (*mark_debug = "true"*)   input   [8:0]           seg_len_i,
                               input   [63:0]          initial_pr_seed_i,
                               input   [63:0]          initial_cmpl_seed_i,
     (*mark_debug = "true"*)   input                   check_p1_i,
     (*mark_debug = "true"*)   input   [31:0]          in_data_crc_gen_i,
     (*mark_debug = "true"*)   input   [1:0]           barrier_cap_detected_i,
     (*mark_debug = "true"*)   input   [1:0]           iob_ctl_cap_detected_i,
     (*mark_debug = "true"*)   output logic [31:0]     cmpl_seed_ram_count,
     (*mark_debug = "true"*)   output logic [31:0]     pr_seed_ram_count,
     (*mark_debug = "true"*)   output logic [8:0]      cmpl_check_seed_ram_raddr,
     (*mark_debug = "true"*)   output logic [8:0]      pr_check_seed_ram_raddr,
     (*mark_debug = "true"*)   output reg              check_pass_o,
     (*mark_debug = "true"*)   output reg              error_o,
     (*mark_debug = "true"*)   output reg              check_err_o,
     (*mark_debug = "true"*)   output reg              check_pass_p1_o,
     (*mark_debug = "true"*)   output reg              error_p1_o,
     (*mark_debug = "true"*)   output reg              check_err_p1_o
       
    ); 

                        logic [639:0]              check_pr_data;
                        logic [639:0]              check_pr_data_pattern;
                        logic [639:0]              check_pr_data_pattern_reg;
                        logic [639:0]              input_pr_data;
(*mark_debug = "true"*) logic [639:0]              check_cmpl_data; 
(*mark_debug = "true"*) logic [639:0]              input_cmpl_data;
(*mark_debug = "true"*) logic [639:0]              check_cmpl_data_pattern; 
(*mark_debug = "true"*) logic [639:0]              check_cmpl_data_pattern_reg; 
                        logic [319:0]              check_pr_p1_data;
                        logic [319:0]              check_pr_p1_data_pattern;
                        logic [319:0]              check_pr_p1_data_pattern_reg;
                        logic [319:0]              input_pr_p1_data;
(*mark_debug = "true"*) logic [319:0]              check_cmpl_p1_data;  
(*mark_debug = "true"*) logic [319:0]              input_cmpl_p1_data;
(*mark_debug = "true"*) logic [319:0]              check_cmpl_p1_data_pattern;  
(*mark_debug = "true"*) logic [319:0]              check_cmpl_p1_data_pattern_reg;  
                        logic [639:0]              prev_check_pr_data;
                        logic [639:0]              prev_input_pr_data;
(*mark_debug = "true"*) logic [639:0]              prev_check_cmpl_data;    
(*mark_debug = "true"*) logic [639:0]              prev_input_cmpl_data;
                        logic [319:0]              prev_check_pr_p1_data;
                        logic [319:0]              prev_input_pr_p1_data;
                        logic [319:0]              prev_check_cmpl_p1_data; 
                        logic [319:0]              prev_input_cmpl_p1_data;
                        logic [31:0]               pr_in_seed0; 
                        logic [31:0]               cmpl_in_seed0;   
                        logic [31:0]               pr_in_seed1; 
                        logic [31:0]               cmpl_in_seed1;
                        logic [31:0]               prev_pr_seed;
                        logic [31:0]               prev_cmpl_seed;
(*mark_debug = "true"*) logic                      check_p1;

//////////////////////////////////////////////////////////////////////////
logic [1:0]    cmpl_req_q;
logic [639:0]  cmpl_data_q;
logic [1:0]    pr_req_q;
logic [639:0]  pr_data_q;
logic [319:0]  pr_data_p1_q;
logic [319:0]  cmpl_data_p1_q;
logic [8:0]    seg_len_q;
logic [1:0]    dat_chk_st_q;
logic [1:0]    barrier_cap_detected_q;
logic [1:0]    iob_ctl_cap_detected_q;
logic [1:0]    barrier_cap_detected_q1;
logic [1:0]    iob_ctl_cap_detected_q1;


always_ff @(posedge clk)
begin
    if(!rst_n)
    begin
        cmpl_req_q       <= 'd0;
        cmpl_data_q      <= 'd0;
        cmpl_data_p1_q   <= 'd0;
        pr_req_q         <= 'd0;
        pr_data_q        <= 'd0;
        pr_data_p1_q     <= 'd0;
        seg_len_q        <= 'd0;
        barrier_cap_detected_q  <= 'b0;
        iob_ctl_cap_detected_q  <= 'b0;
        barrier_cap_detected_q1  <= 'b0;
        iob_ctl_cap_detected_q1  <= 'b0;

        dat_chk_st_q     <= 'd0;
    end
    else
    begin
       cmpl_req_q         <= cmpl_req_i;
       cmpl_data_q        <= cmpl_data_i;
       cmpl_data_p1_q     <= cmpl_data_p1_i;
       pr_data_p1_q       <= pr_data_p1_i;
       pr_req_q           <= pr_req_i;
       pr_data_q          <= pr_data_i;
       seg_len_q          <= seg_len_i;
       barrier_cap_detected_q  <= barrier_cap_detected_i;
       iob_ctl_cap_detected_q  <= iob_ctl_cap_detected_i;
       barrier_cap_detected_q1  <= barrier_cap_detected_q;
       iob_ctl_cap_detected_q1  <= iob_ctl_cap_detected_q;

       dat_chk_st_q       <= dat_chk_st_i;
    end
end

///////////////////Retaining previous Data/////////////////////////////////

always_ff @(posedge clk)
begin
    if(!rst_n)
    begin
        prev_input_pr_data      <= 'd0;
        prev_input_cmpl_data    <= 'd0;
        prev_check_pr_data      <= 'd0;
        prev_check_cmpl_data    <= 'd0;
        prev_check_cmpl_p1_data <= 'd0;
        prev_check_pr_p1_data   <= 'd0;
        prev_input_cmpl_p1_data <= 'd0;
        prev_input_cmpl_p1_data <= 'd0;
    end
    else
    begin
       prev_input_pr_data      <=  input_pr_data;
       prev_input_cmpl_data    <= input_cmpl_data;
       prev_check_pr_data      <= check_pr_data;
       prev_check_cmpl_data    <= check_cmpl_data;
       prev_check_cmpl_p1_data <= check_cmpl_p1_data;
       prev_check_pr_p1_data   <= check_pr_p1_data;
       prev_input_cmpl_p1_data <= input_cmpl_p1_data;
       prev_input_cmpl_p1_data <= input_cmpl_p1_data;
    end
end


////////////////////Comparison and error detection Logic//////////////////////////////
    
always @(posedge clk)
begin  
    if(rst_n == 1'b0)
    begin
        pr_seed_ram_count         <= 'd0;
        cmpl_seed_ram_count       <= 'd0;
        pr_check_seed_ram_raddr   <= 'd0;
        cmpl_check_seed_ram_raddr <= 'd0;
        pr_in_seed0               <= 'd0;
        pr_in_seed1               <= 'd0;
        cmpl_in_seed0             <= 'd0;
        cmpl_in_seed1             <= 'd0;
    end
    else
    begin   
        if(dat_chk_st_i[0] == 'b1 && (!iob_ctl_cap_detected_i) && (!barrier_cap_detected_i))
        begin
            if(csi_flow_i == 'd2)
            begin
                pr_seed_ram_count        <= pr_seed_ram_count + 'd1;
                pr_check_seed_ram_raddr  <= pr_check_seed_ram_raddr + 'h8;
            end
            else if (csi_flow_i == 'd1)
            begin
                cmpl_seed_ram_count       <= cmpl_seed_ram_count + 'd1;
                cmpl_check_seed_ram_raddr <= cmpl_check_seed_ram_raddr + 'h8;
            end 
        end 
        if(dat_chk_st_q[0] == 'b1)
        begin
            pr_in_seed0              <= initial_pr_seed_i[31:0];
            pr_in_seed1              <= initial_pr_seed_i[63:32];
            cmpl_in_seed0            <= initial_cmpl_seed_i[31:0];
            cmpl_in_seed1            <= initial_cmpl_seed_i[63:32];
        end
    end
end     
    
always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin
        check_pass_o              <= 'd0;
        check_err_o               <= 'd0;
        error_o                   <= 'd0;
        check_p1                  <= 'd0;
    end
    else
    begin
        check_p1         <= check_p1_i;     
        if(pr_req_q[0] && seg_len_q[4:0] > 'd0 && seg_len_q[4:0] <= 'd20)
        begin
            //if(check_pr_data == input_pr_data)
            if(check_pr_data_pattern == input_pr_data)
            begin
               check_pass_o <= 'd1;
               check_err_o  <= 'd0;
            end   
            else
            begin
               check_pass_o <= 'd0;
               check_err_o  <= 'd1;
               error_o      <= 'd1;
            end   
        end 
        else if(cmpl_req_q[0] && seg_len_q[4:0] > 'd0 && seg_len_q[4:0] <= 'd20 &&
                (!barrier_cap_detected_q1[0]) && (!iob_ctl_cap_detected_q1[0]))      //aug1_karthik_change
        begin
            //if(check_cmpl_data == input_cmpl_data)
            if(check_cmpl_data_pattern == input_cmpl_data)
            begin
               check_pass_o <= 'd1;
               check_err_o  <= 'd0;
            end
            else
            begin
               check_pass_o <= 'd0;
               check_err_o  <= 'd1;
               error_o      <= 'd1;
            end         
        end
        else
        begin
            check_pass_o  <= 'd0;
            check_err_o   <= 'd0;
        end
    end
end 

always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin
        check_pass_p1_o     <= 'd0;
        check_err_p1_o      <= 'd0;
        error_p1_o          <= 'd0;
    end
    else
    begin       
        if(check_p1 && pr_req_q[1] && seg_len_q[8:5] > 'd0 && seg_len_q[8:5] <= 'd3)
        begin
            //if(check_pr_p1_data == input_pr_p1_data)
            if(check_pr_p1_data_pattern == input_pr_p1_data)
            begin
               check_pass_p1_o <= 'd1;
               check_err_p1_o  <= 'd0;
            end   
            else
            begin
               check_pass_p1_o <= 'd0;
               check_err_p1_o  <= 'd1;
               error_p1_o      <= 'd1;
            end   
        end 
        else if(cmpl_req_q[1] && check_p1 && seg_len_q[8:5] > 'd0 && seg_len_q[8:5] <= 'd3 &&
                (!barrier_cap_detected_q1[1]) && (!iob_ctl_cap_detected_q1[1]))
        begin
            //if(check_cmpl_p1_data == input_cmpl_p1_data)
            if(check_cmpl_p1_data_pattern == input_cmpl_p1_data)
            begin
               check_pass_p1_o <= 'd1;
               check_err_p1_o  <= 'd0;
            end
            else
            begin
               check_pass_p1_o <= 'd0;
               check_err_p1_o  <= 'd1;
               error_p1_o      <= 'd1;
            end         
        end
        else
        begin
            check_pass_p1_o  <= 'd0;
            check_err_p1_o   <= 'd0;
        end
    end
end 

always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin
      check_cmpl_data_pattern_reg    <= 'd0;
      check_cmpl_p1_data_pattern_reg <= 'd0;
      check_pr_data_pattern_reg      <= 'd0;
      check_pr_p1_data_pattern_reg   <= 'd0;
    end
    else
    begin
      check_cmpl_data_pattern_reg    <= check_cmpl_data_pattern; 
      check_cmpl_p1_data_pattern_reg <= check_cmpl_p1_data_pattern; 
      check_pr_data_pattern_reg      <= check_pr_data_pattern; 
      check_pr_p1_data_pattern_reg   <= check_pr_p1_data_pattern; 
    end
end
assign check_cmpl_data_pattern    = f_prcmpl_data_pattern_gen(check_cmpl_data,check_cmpl_data_pattern_reg,cmpl_in_seed0, seg_len_q[4:0]);
assign check_cmpl_p1_data_pattern = f_prcmpl_p1_data_pattern_gen(check_cmpl_p1_data,check_cmpl_p1_data_pattern_reg,cmpl_in_seed0, seg_len_q[8:5]);

assign check_pr_data_pattern    = f_prcmpl_data_pattern_gen(check_pr_data,check_pr_data_pattern_reg,pr_in_seed0, seg_len_q[4:0]);
assign check_pr_p1_data_pattern = f_prcmpl_p1_data_pattern_gen(check_pr_p1_data,check_pr_p1_data_pattern_reg,pr_in_seed0, seg_len_q[8:5]);
////////////////////Counter logic//////////////////////////////

always_ff @(posedge clk)
begin
    if(rst_n == 1'b0)
    begin
       prev_pr_seed     <= 'd0;
       prev_cmpl_seed   <= 'd0;
    end
    else
    begin
        if(dat_chk_st_q[0] == 'd1)
        begin
            prev_pr_seed   <= pr_in_seed1;
            prev_cmpl_seed <= cmpl_in_seed1;     
        end
        else
        begin
            if(pr_req_q[1])
            begin
                case(seg_len_q[8:5])
                'd0:  begin
                    prev_pr_seed   <= pr_in_seed1;
                    prev_cmpl_seed <= cmpl_in_seed1;
                end    
                'd1: begin 
                    prev_pr_seed   <= check_pr_p1_data[31:0];
                    prev_cmpl_seed <= check_cmpl_p1_data[31:0];
                end    
                'd2: begin 
                    prev_pr_seed   <= check_pr_p1_data[63:32];
                    prev_cmpl_seed <= check_cmpl_p1_data[63:32];
                end    
                'd3:   begin 
                    prev_pr_seed   <= check_pr_p1_data[95:64];
                    prev_cmpl_seed <= check_cmpl_p1_data[95:64];
                end  
                default: begin 
                    prev_pr_seed   <= pr_in_seed1;
                    prev_cmpl_seed <= cmpl_in_seed1;
                end    
                endcase
            end
            else
            begin
                case(seg_len_q[4:0])
                'd0:  begin
                    prev_pr_seed   <= pr_in_seed1;
                    prev_cmpl_seed <= cmpl_in_seed1;
                end    
                'd1: begin 
                    prev_pr_seed   <= check_pr_data[31:0];
                    prev_cmpl_seed <= check_cmpl_data[31:0];
                end    
                'd2: begin 
                    prev_pr_seed   <= check_pr_data[63:32];
                    prev_cmpl_seed <= check_cmpl_data[63:32];
                end    
                'd3:   begin 
                    prev_pr_seed <= check_pr_data[95:64];
                    prev_cmpl_seed <= check_cmpl_data[95:64];
                end    
                'd4:   begin 
                    prev_pr_seed <= check_pr_data[127:96];
                    prev_cmpl_seed <= check_cmpl_data[127:96];
                end    
                'd5:  begin 
                    prev_pr_seed <= check_pr_data[159:128];
                    prev_cmpl_seed <= check_cmpl_data[159:128];
                end    
                'd6:   begin 
                    prev_pr_seed <= check_pr_data[191:160];
                    prev_cmpl_seed <= check_cmpl_data[191:160];
                end    
                'd7:   begin 
                    prev_pr_seed <= check_pr_data[223:192];
                    prev_cmpl_seed <= check_cmpl_data[223:192];
                end    
                'd8:   begin 
                    prev_pr_seed <= check_pr_data[255:224];
                    prev_cmpl_seed <= check_cmpl_data[255:224];
                end    
                'd9:   begin 
                    prev_pr_seed <= check_pr_data[287:256];
                    prev_cmpl_seed <= check_cmpl_data[287:256];
                end    
                'd10:  begin 
                    prev_pr_seed <= check_pr_data[319:288];
                    prev_cmpl_seed <= check_cmpl_data[319:288];
                end     
                'd11:  begin 
                    prev_pr_seed <= check_pr_data[351:320];
                    prev_cmpl_seed <= check_cmpl_data[351:320];
                end    
                'd12: begin 
                    prev_pr_seed <= check_pr_data[383:352];
                    prev_cmpl_seed <= check_cmpl_data[383:352];
                end    
                'd13: begin 
                    prev_pr_seed <= check_pr_data[415:384];
                    prev_cmpl_seed <= check_cmpl_data[415:384];
                end    
                'd14:   begin 
                    prev_pr_seed <= check_pr_data[447:416];
                    prev_cmpl_seed <= check_cmpl_data[447:416];
                end    
                'd15:   begin 
                    prev_pr_seed <= check_pr_data[479:448];
                    prev_cmpl_seed <= check_cmpl_data[479:448];
                end    
                'd16:  begin 
                    prev_pr_seed <= check_pr_data[511:480];
                    prev_cmpl_seed <= check_cmpl_data[511:480];
                end    
                'd17:   begin 
                    prev_pr_seed <= check_pr_data[543:512];
                    prev_cmpl_seed <= check_cmpl_data[543:512];
                end    
                'd18:   begin 
                    prev_pr_seed <= check_pr_data[575:544];
                    prev_cmpl_seed <= check_cmpl_data[575:544];
                end    
                'd19:   begin 
                    prev_pr_seed <= check_pr_data[607:576];
                    prev_cmpl_seed <= check_cmpl_data[607:576];
                end    
                'd20:   begin 
                    prev_pr_seed <= check_pr_data[639:608];
                    prev_cmpl_seed <= check_cmpl_data[639:608];
                end       
                default: begin 
                    prev_pr_seed   <= pr_in_seed1;
                    prev_cmpl_seed <= cmpl_in_seed1;
                end    
                endcase
            end     
        end
    end
end        
    
always_comb
begin
    case(seg_len_q[8:5])
        'd1: begin 
            input_pr_p1_data = {'d0,pr_data_p1_q[31:0]};
            input_cmpl_p1_data = {'d0,cmpl_data_p1_q[31:0]};
            if(prev_pr_seed == pr_in_seed0)
                check_pr_p1_data = {'d0,pr_in_seed1};
            else
                check_pr_p1_data = {'d0,pr_in_seed0};
            if(prev_cmpl_seed == cmpl_in_seed0)
                check_cmpl_p1_data = {'d0,cmpl_in_seed1};
            else
                check_cmpl_p1_data = {'d0,cmpl_in_seed0}; 
        end
        'd2: begin 
            input_pr_p1_data = {'d0,pr_data_p1_q[63:0]};
            input_cmpl_p1_data = {'d0,cmpl_data_p1_q[63:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_p1_data = {'d0,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_p1_data = {'d0,pr_in_seed1,pr_in_seed0};  
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_p1_data = {'d0,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_p1_data = {'d0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd3: begin 
            input_pr_p1_data = {'d0,pr_data_q[95:0]};         // TODO : Check this 
            input_cmpl_p1_data = {'d0,cmpl_data_q[95:0]};
            //input_pr_p1_data = {'d0,pr_data_p1_q[95:0]};         // TODO : Check this 
            //input_cmpl_p1_data = {'d0,cmpl_data_p1_q[95:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_p1_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_p1_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0}; 
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_p1_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_p1_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end 
        default: begin 
            input_pr_p1_data = prev_input_pr_p1_data;
            input_cmpl_p1_data = prev_input_cmpl_p1_data;
            check_pr_p1_data = prev_check_pr_p1_data;
            check_cmpl_p1_data = prev_check_cmpl_p1_data; 
        end
    endcase
end

always_comb
begin
    case(seg_len_q[4:0])
        'd1: begin 
            input_pr_data = {'d0,pr_data_q[31:0]};
            input_cmpl_data = {'d0,cmpl_data_q[31:0]};
            if(prev_pr_seed == pr_in_seed0)
                check_pr_data = {'d0,pr_in_seed1};
            else
                check_pr_data = {'d0,pr_in_seed0};
            if(prev_cmpl_seed == cmpl_in_seed0)
                check_cmpl_data = {'d0,cmpl_in_seed1};
            else
                check_cmpl_data = {'d0,cmpl_in_seed0}; 
        end
        'd2: begin 
            input_pr_data = {'d0,pr_data_q[63:0]};
            input_cmpl_data = {'d0,cmpl_data_q[63:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0};  
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd3: begin 
            input_pr_data = {'d0,pr_data_q[95:0]};
            input_cmpl_data = {'d0,cmpl_data_q[95:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0}; 
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd4: begin 
            input_pr_data = {'d0,pr_data_q[127:0]};
            input_cmpl_data = {'d0,cmpl_data_q[127:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};  
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd5: begin 
            input_pr_data = {'d0,pr_data_q[159:0]};
            input_cmpl_data = {'d0,cmpl_data_q[159:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};  
            end 
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd6: begin 
            input_pr_data = {'d0,pr_data_q[191:0]};
            input_cmpl_data = {'d0,cmpl_data_q[191:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0}; 
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd7: begin 
            input_pr_data = {'d0,pr_data_q[223:0]};
            input_cmpl_data = {'d0,cmpl_data_q[223:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0};  
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd8: begin 
            input_pr_data = {'d0,pr_data_q[255:0]};
            input_cmpl_data = {'d0,cmpl_data_q[255:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0}; 
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd9: begin 
            input_pr_data = {'d0,pr_data_q[287:0]};
            input_cmpl_data = {'d0,cmpl_data_q[287:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1};   
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0}; 
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {32'd0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                   cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd10: begin 
            input_pr_data = {'d0,pr_data_q[319:0]};
            input_cmpl_data = {'d0,cmpl_data_q[319:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd11: begin 
            input_pr_data = {'d0,pr_data_q[351:0]};
            input_cmpl_data = {'d0,cmpl_data_q[351:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd12: begin 
            input_pr_data = {'d0,pr_data_q[383:0]};
            input_cmpl_data = {'d0,cmpl_data_q[383:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd13: begin 
            input_pr_data = {'d0,pr_data_q[415:0]};
            input_cmpl_data = {'d0,cmpl_data_q[415:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd14: begin 
            input_pr_data = {'d0,pr_data_q[447:0]};
            input_cmpl_data = {'d0,cmpl_data_q[447:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd15: begin 
            input_pr_data = {'d0,pr_data_q[479:0]};
            input_cmpl_data = {'d0,cmpl_data_q[479:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd16: begin 
            input_pr_data = {'d0,pr_data_q[511:0]};
            input_cmpl_data = {'d0,cmpl_data_q[511:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd17: begin 
            input_pr_data = {'d0,pr_data_q[543:0]};
            input_cmpl_data = {'d0,cmpl_data_q[543:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd18: begin 
            input_pr_data = {'d0,pr_data_q[575:0]};
            input_cmpl_data = {'d0,cmpl_data_q[575:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd19: begin 
            input_pr_data = {'d0,pr_data_q[607:0]};
            input_cmpl_data = {'d0,cmpl_data_q[607:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {'d0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {'d0,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {'d0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {'d0,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        'd20: begin 
            input_pr_data = {'d0,pr_data_q[639:0]};
            input_cmpl_data = {'d0,cmpl_data_q[639:0]};
            if(prev_pr_seed == pr_in_seed0)
            begin
                check_pr_data = {pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1};
            end
            else
            begin
                check_pr_data = {pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,
                                 pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0,
                                 pr_in_seed1,pr_in_seed0,pr_in_seed1,pr_in_seed0};   
            end  
            if(prev_cmpl_seed == cmpl_in_seed0)
            begin
                check_cmpl_data = {cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1};
            end
            else
            begin
                check_cmpl_data = {cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,
                                  cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,
                                  cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0,cmpl_in_seed1,cmpl_in_seed0};   
            end  
        end
        default: begin 
            input_pr_data = prev_input_pr_data;
            input_cmpl_data = prev_input_cmpl_data;
            check_pr_data = prev_check_pr_data;
            check_cmpl_data = prev_check_cmpl_data; 
        end
    endcase
end 


function automatic logic [639:0] f_prcmpl_data_pattern_gen;
  input [639:0] check_prcmpl_data; 
  input [639:0] check_prcmpl_data_pattern; 
  input [31:0]  prcmpl_in_seed;
  input [4:0]   seg_len;

    if(CHECKER_FIX_PATTERN)
    begin
      case(seg_len[4:0])
        'd1:     f_prcmpl_data_pattern_gen = {{19{32'b0}}, {01{prcmpl_in_seed}}};
        'd2:     f_prcmpl_data_pattern_gen = {{18{32'b0}}, {02{prcmpl_in_seed}}};
        'd3:     f_prcmpl_data_pattern_gen = {{17{32'b0}}, {03{prcmpl_in_seed}}};
        'd4:     f_prcmpl_data_pattern_gen = {{16{32'b0}}, {04{prcmpl_in_seed}}};
        'd5:     f_prcmpl_data_pattern_gen = {{15{32'b0}}, {05{prcmpl_in_seed}}};
        'd6:     f_prcmpl_data_pattern_gen = {{14{32'b0}}, {06{prcmpl_in_seed}}};
        'd7:     f_prcmpl_data_pattern_gen = {{13{32'b0}}, {07{prcmpl_in_seed}}};
        'd8:     f_prcmpl_data_pattern_gen = {{12{32'b0}}, {08{prcmpl_in_seed}}};
        'd9:     f_prcmpl_data_pattern_gen = {{11{32'b0}}, {09{prcmpl_in_seed}}};
        'd10:    f_prcmpl_data_pattern_gen = {{10{32'b0}}, {10{prcmpl_in_seed}}};
        'd11:    f_prcmpl_data_pattern_gen = {{09{32'b0}}, {11{prcmpl_in_seed}}};
        'd12:    f_prcmpl_data_pattern_gen = {{08{32'b0}}, {12{prcmpl_in_seed}}};
        'd13:    f_prcmpl_data_pattern_gen = {{07{32'b0}}, {13{prcmpl_in_seed}}};
        'd14:    f_prcmpl_data_pattern_gen = {{06{32'b0}}, {14{prcmpl_in_seed}}};
        'd15:    f_prcmpl_data_pattern_gen = {{05{32'b0}}, {15{prcmpl_in_seed}}};
        'd16:    f_prcmpl_data_pattern_gen = {{04{32'b0}}, {16{prcmpl_in_seed}}};
        'd17:    f_prcmpl_data_pattern_gen = {{03{32'b0}}, {17{prcmpl_in_seed}}};
        'd18:    f_prcmpl_data_pattern_gen = {{02{32'b0}}, {18{prcmpl_in_seed}}};
        'd19:    f_prcmpl_data_pattern_gen = {{01{32'b0}}, {19{prcmpl_in_seed}}};
        'd20:    f_prcmpl_data_pattern_gen = {{00{32'b0}}, {20{prcmpl_in_seed}}};
        default: f_prcmpl_data_pattern_gen = check_prcmpl_data_pattern;
      endcase
    end
    else
    begin
      f_prcmpl_data_pattern_gen = check_prcmpl_data;
    end

endfunction

function automatic logic [319:0] f_prcmpl_p1_data_pattern_gen;
  input [319:0] check_prcmpl_p1_data; 
  input [319:0] check_prcmpl_p1_data_pattern; 
  input [31:0]  prcmpl_in_seed;
  input [4:0]   seg_len_p1;

    if(CHECKER_FIX_PATTERN)
    begin
      case(seg_len_p1[4:0])
        'd1:     f_prcmpl_p1_data_pattern_gen = {{9{32'b0}}, {01{prcmpl_in_seed}}};
        'd2:     f_prcmpl_p1_data_pattern_gen = {{8{32'b0}}, {02{prcmpl_in_seed}}};
        'd3:     f_prcmpl_p1_data_pattern_gen = {{7{32'b0}}, {03{prcmpl_in_seed}}};
        default: f_prcmpl_p1_data_pattern_gen = check_prcmpl_p1_data_pattern;
      endcase
    end
    else
    begin
      f_prcmpl_p1_data_pattern_gen = check_prcmpl_p1_data;
    end

endfunction



endmodule   
