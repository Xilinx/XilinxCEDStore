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

module csi_uport_encode 
 #(
  parameter  TCQ                   = 0
    )(
        // Ports 
        // Clocks / Resets
        input                          clk,
        input                          rst_n,
             
        //From Generator     
        input    [319:0]               pr_data_i,   
        input    [319:0]               cmpl_data_i,
        input    [319:0]               pr_data_s1_i,    
        input    [319:0]               cmpl_data_s1_i,
        input    [1:0]                 pr_data_valid_i,
        input    [1:0]                 cmpl_data_valid_i,
        input                          sop_i,
        input                          eop_i,
        input                          eop_s1_i,
        input                          npr_sop_i,
        input                          npr_eop_i,
        input  [1:0]                   flow_typ_i,
        input csi_capsule_t            cap_header_i,
        input csi_capsule_t            npr_cap_header_i,
        input  [2:0]                   credits_used_i,
        
        //To Credit Manager
        output logic [12:0]            pr_local_credits_used_o,
        output logic                   pr_local_credits_avail_o,
        output logic [12:0]            npr_local_credits_used_o,
        output logic                   npr_local_credits_avail_o,
        output logic [12:0]            cmpl_local_credits_used_o,
        output logic                   cmpl_local_credits_avail_o,
        
        //To Request Generator
        output logic [17:0]            csi_after_pr_seq_o,
        output logic                   csi_after_pr_seq_valid_o,
        
        //To CSI
        cdx5n_fab_2s_seg_if.out        f2csi_prcmpl_o,
        cdx5n_fab_1s_seg_if.out        f2csi_npr_o
        
    ); 
 
logic     [2:0]     current_state, state_next;  
logic     [0:0]     current_npr_state, state_next_npr; 

//To Request Generator
//logic     [17:0]    csi_after_pr_seq_o;
//logic               csi_after_pr_seq_valid_o;

//To Credit Manager
//logic     [12:0]    pr_local_credits_used_o;
//logic               pr_local_credits_avail_o;
//logic     [12:0]    npr_local_credits_used_o;
//logic               npr_local_credits_avail_o;
//logic     [12:0]    cmpl_local_credits_used_o;
//logic               cmpl_local_credits_avail_o;

logic     [1:0]     flow_type;
logic     [1:0]     flow_type_d;
csi_capsule_t       cap_header;
csi_capsule_t       npr_cap_header;
logic     [319:0]   pr_data;     
logic     [319:0]   pr_data_s1;  
logic     [319:0]   npr_data;
logic     [319:0]   cmpl_data;
logic     [319:0]   cmpl_data_s1;
logic     [1:0]     pr_data_valid;
logic               npr_data_valid;
logic     [1:0]     cmpl_data_valid;
logic     [2:0]     credits_used;
logic     [2:0]     credits_used_d;
logic     [2:0]     credits_used_d1;
logic               eop;
logic               eop_s1;
logic               sop; 

//PR - CMPL states     
localparam [2:0] // states required for Data extraction
    st_idle = 3'b000,
    st_sop = 3'b001, 
    st_payload = 3'b010,
    st_eop = 3'b011,
    st_sop_eop = 3'b100;

//NPR states
localparam [0:0] // states required for Data extraction
    st_npr_idle = 1'b0,
    st_npr_sop_eop = 1'b1;

/////////////////////////////////////////////////////////////////////////////
//                    state Assignments                                    //
////////////////////////////////////////////////////////////////////////////
always @(posedge clk)
begin
    if(!rst_n) // go to state idle if reset
    begin
        current_state     <= st_idle;
        current_npr_state <= st_npr_idle;
    end
    else // otherwise update the states
    begin
        current_state     <= state_next;
        current_npr_state <= state_next_npr;
    end
end

/////////////////////////////////////////////////////////////////////////////
//                        Data Register                                    //
////////////////////////////////////////////////////////////////////////////
always @(posedge clk)
begin
    if(!rst_n) // go to state idle if reset
    begin
        pr_data         <= 'd0;
        pr_data_valid   <= 'b0;
        cmpl_data       <= 'd0;
        cmpl_data_valid <= 'b0;
        flow_type       <= 'd0;
        flow_type_d     <= 'd0;  
        cap_header      <= 'd0;
        npr_cap_header  <= 'd0;
        credits_used_d  <= 'd0;
        credits_used    <= 'd0;
    end
    else // otherwise update the states
    begin
        if(f2csi_prcmpl_o.rdy == 'b11)
        begin
           pr_data         <= pr_data_i;
           pr_data_s1      <= pr_data_s1_i;
           pr_data_valid   <= pr_data_valid_i;
           cmpl_data       <= cmpl_data_i;
           cmpl_data_s1    <= cmpl_data_s1_i;
           cmpl_data_valid <= cmpl_data_valid_i;
           cap_header      <= cap_header_i; 
           flow_type       <= flow_typ_i;
           flow_type_d     <= flow_type;
           credits_used_d  <= credits_used_i;
           credits_used    <= credits_used_d;
        end
        if(f2csi_npr_o.rdy == 'b1)
        begin
           npr_cap_header  <= npr_cap_header_i;
        end
    end
end


/////////////////////////////////////////////////////////////////////////////
//            PR- CMPL state machine                                       //
////////////////////////////////////////////////////////////////////////////

always_comb   
begin
   // store current state as next
    state_next = current_state; // required: when no case statement is satisfied
    case(current_state)
        st_idle: begin
            if(f2csi_prcmpl_o.rdy == 'b11)
            begin
                if(pr_data_valid_i[0] == 1'b1 || cmpl_data_valid_i[0] == 1'b1)
                begin
                    if(sop_i == 1'b1 && (eop_i == 1'b1 || eop_s1_i == 1'b1)) 
                    begin
                        state_next = st_sop_eop;
                    end 
                    else if (sop_i == 1'b1)
                    begin
                        state_next = st_sop;
                    end
                end 
                else
                begin
                    state_next = st_idle;
                end
            end 
            else
            begin   
                state_next = current_state;
            end
        end
        st_sop: begin
            if(f2csi_prcmpl_o.rdy == 'b11)
            begin
                if(pr_data_valid_i[0] == 1'b1 || cmpl_data_valid_i[0] == 1'b1) 
                begin
                    if(eop_i == 'b1 || eop_s1_i == 1'b1)
                        state_next = st_eop;
                    else    
                        state_next = st_payload;
                end 
                else
                begin
                    state_next = st_idle;
                end
            end 
            else
            begin   
                state_next = current_state;
            end
        end
        st_payload: begin
            if(f2csi_prcmpl_o.rdy == 'b11)
            begin
                if((eop_i == 1'b1 || eop_s1_i == 1'b1) && (pr_data_valid_i[0] == 1'b1 || cmpl_data_valid_i[0] == 1'b1)) 
                begin
                    state_next = st_eop;
                end 
                else 
                begin
                    state_next = st_payload;
                end
            end 
            else
            begin   
                state_next = current_state;
            end
        end
        st_eop: begin
            if(f2csi_prcmpl_o.rdy == 'b11)
            begin
                if(pr_data_valid_i[0] == 1'b1 || cmpl_data_valid_i[0] == 1'b1) 
                begin
                    if(sop_i)
                        state_next = st_sop;
                    else 
                        state_next = st_idle;
                end 
                else
                    state_next = st_idle;
            end 
            else
            begin   
                state_next = current_state;
            end
        end
        st_sop_eop: begin
            if(f2csi_prcmpl_o.rdy == 'b11)
            begin
                if(pr_data_valid_i[0] == 1'b1 || cmpl_data_valid_i[0] == 1'b1) 
                begin
                    if(sop_i == 1'b1 && (eop_i == 1'b1 || eop_s1_i == 1'b1)) 
                        state_next = st_sop_eop;
                    else if(sop_i)
                        state_next = st_sop;
                    else 
                        state_next = st_idle;
                end
                else
                    state_next = st_idle;   
            end 
            else
            begin   
                state_next = current_state;
            end 
        end
        default: begin
            state_next = st_idle;
        end     
    endcase
end

always @(posedge clk)
begin
    if(!rst_n) 
    begin
        f2csi_prcmpl_o.seg <= 'd0;
        f2csi_prcmpl_o.vld <= 'd0;
        f2csi_prcmpl_o.sop <= 'd0;
        f2csi_prcmpl_o.eop <= 'd0;
        f2csi_prcmpl_o.err <= 'd0;
    end
    else 
    begin
        if(f2csi_prcmpl_o.rdy == 'b11)
        begin
            case(current_state)
            st_idle: begin
                f2csi_prcmpl_o.vld  <= 'd0;
                f2csi_prcmpl_o.sop  <= 'd0;
                f2csi_prcmpl_o.eop  <= 'd0;
                f2csi_prcmpl_o.err  <= 'd0;
            end
            st_sop: begin
                if(pr_data_valid[1] || cmpl_data_valid[1])
                begin
                    f2csi_prcmpl_o.vld  <= 'd3;
                end 
                else
                    f2csi_prcmpl_o.vld  <= 'd1;
                f2csi_prcmpl_o.sop  <= 'd1;
                f2csi_prcmpl_o.eop  <= 'd0;
                f2csi_prcmpl_o.err  <= 'd0;
                if(flow_type == 'd2)       //PR
                begin
                    f2csi_prcmpl_o.seg[0]  <= {pr_data[95:0],cap_header};
                    f2csi_prcmpl_o.seg[1]  <= pr_data_s1;
                end
                else if(flow_type == 'd1)         //CMPL
                begin
                    f2csi_prcmpl_o.seg[0]  <= {cmpl_data[95:0],cap_header};
                    f2csi_prcmpl_o.seg[1]  <= cmpl_data_s1;
                end
            end
            st_payload: begin
                if(pr_data_valid[1] || cmpl_data_valid[1])
                begin
                    f2csi_prcmpl_o.vld  <= 'd3;
                end 
                else
                    f2csi_prcmpl_o.vld  <= 'd1;
                f2csi_prcmpl_o.sop  <= 'd0;
                f2csi_prcmpl_o.eop  <= 'd0;
                f2csi_prcmpl_o.err  <= 'd0;
                if(flow_type == 'd2)       //PR
                begin
                    f2csi_prcmpl_o.seg[0]  <= pr_data;
                    f2csi_prcmpl_o.seg[1]  <= pr_data_s1;
                end
                else if(flow_type == 'd1)         //CMPL
                begin
                    f2csi_prcmpl_o.seg[0]  <= cmpl_data;
                    f2csi_prcmpl_o.seg[1]  <= cmpl_data_s1;
                end
            end
            st_eop: begin
                if(pr_data_valid[1] || cmpl_data_valid[1])
                begin
                    f2csi_prcmpl_o.vld  <= 'd3;
                    f2csi_prcmpl_o.eop  <= 'd2;
                end 
                else
                begin
                    f2csi_prcmpl_o.vld  <= 'd1;
                    f2csi_prcmpl_o.eop  <= 'd1;
                end 
                f2csi_prcmpl_o.sop  <= 'd0;
                f2csi_prcmpl_o.err  <= 'd0;
                if(flow_type == 'd2)       //PR
                begin
                    f2csi_prcmpl_o.seg[0]  <= pr_data;
                    f2csi_prcmpl_o.seg[1]  <= pr_data_s1;
                end
                else if(flow_type == 'd1)         //CMPL
                begin
                    f2csi_prcmpl_o.seg[0]  <= cmpl_data;
                    f2csi_prcmpl_o.seg[1]  <= cmpl_data_s1;
                end
            end
            st_sop_eop: begin
                if(pr_data_valid[1] || cmpl_data_valid[1])
                begin
                    f2csi_prcmpl_o.vld  <= 'd3;
                    f2csi_prcmpl_o.eop  <= 'd2;
                end 
                else
                begin
                    f2csi_prcmpl_o.vld  <= 'd1;
                    f2csi_prcmpl_o.eop  <= 'd1;
                end 
                f2csi_prcmpl_o.sop  <= 'd1;
                f2csi_prcmpl_o.err  <= 'd0;
                if(flow_type == 'd2)       //PR
                begin
                    f2csi_prcmpl_o.seg[0]  <= {pr_data[95:0],cap_header};
                    f2csi_prcmpl_o.seg[1]  <= pr_data_s1;
                end
                else if(flow_type == 'd1)         //CMPL
                begin
                    f2csi_prcmpl_o.seg[0]  <= {cmpl_data[95:0],cap_header};
                    f2csi_prcmpl_o.seg[1]  <= cmpl_data_s1;
                end
            end
            default: begin
                f2csi_prcmpl_o.seg  <= 'd0;
                f2csi_prcmpl_o.vld  <= 'd0;
                f2csi_prcmpl_o.sop  <= 'd0;
                f2csi_prcmpl_o.eop  <= 'd0;
                f2csi_prcmpl_o.err  <= 'd0;
            end
            endcase
        end
    end
end


/////////////////////////////////////////////////////////////////////////////
//            PR- CMPL local credit used info                              //
////////////////////////////////////////////////////////////////////////////

always @(posedge clk)
begin
    if(!rst_n) 
    begin
        pr_local_credits_used_o     <= 'd0;
        pr_local_credits_avail_o    <= 'b0;
        cmpl_local_credits_used_o   <= 'd0;
        cmpl_local_credits_avail_o  <= 'b0;
        csi_after_pr_seq_o          <= 'd0;
    end
    else 
    begin
        if(f2csi_prcmpl_o.sop[0] && f2csi_prcmpl_o.vld[0] && (f2csi_prcmpl_o.rdy == 'b11))
        begin
            if(f2csi_prcmpl_o.eop[1])
            begin
               if(flow_type_d == 2'd2)
               begin
                   csi_after_pr_seq_o          <= csi_after_pr_seq_o + 'd1;
                   pr_local_credits_used_o     <= credits_used;
                   pr_local_credits_avail_o    <= 1'b1;
                   cmpl_local_credits_avail_o  <= 1'b0;
               end
               else if(flow_type_d == 2'd1)
               begin
                   cmpl_local_credits_used_o   <= credits_used;
                   cmpl_local_credits_avail_o  <= 1'b1;
                   pr_local_credits_avail_o    <= 1'b0;
               end
               else
               begin
                   cmpl_local_credits_avail_o  <= 1'b0;
                   pr_local_credits_avail_o    <= 1'b0;
               end
            end
            else if(f2csi_prcmpl_o.eop[0])
            begin
               if(flow_type_d == 2'd2)
               begin
                   csi_after_pr_seq_o          <= csi_after_pr_seq_o + 'd1;
                   pr_local_credits_used_o     <= 'd2;                   /*header_dw+ dw_len = 2 credits min*/
                   pr_local_credits_avail_o    <= 1'b1;
                   cmpl_local_credits_avail_o  <= 1'b0;
               end
               else if(flow_type_d == 2'd1)
               begin
                   cmpl_local_credits_used_o   <= 'd2;
                   cmpl_local_credits_avail_o  <= 1'b1;
                   pr_local_credits_avail_o    <= 1'b0;
               end
               else
               begin
                   cmpl_local_credits_avail_o  <= 1'b0;
                   pr_local_credits_avail_o    <= 1'b0;
               end
            end
            else
            begin
                pr_local_credits_avail_o       <= 1'b0;
                cmpl_local_credits_avail_o     <= 1'b0;
                if(f2csi_prcmpl_o.vld[1])
                begin
                    if(flow_type_d == 2'd2)
                    begin
                       pr_local_credits_used_o     <= credits_used;
                    end
                    else if(flow_type_d == 2'd1)
                    begin
                       cmpl_local_credits_used_o   <= credits_used;
                    end
                end
                else
                begin
                    if(flow_type_d == 2'd2)
                    begin
                       pr_local_credits_used_o     <= 'd2;
                    end
                    else if(flow_type_d == 2'd1)
                    begin
                       cmpl_local_credits_used_o   <= 'd2;
                    end
                end
            end 
        end
        else if((|f2csi_prcmpl_o.eop) && (f2csi_prcmpl_o.rdy == 2'b11) && f2csi_prcmpl_o.vld[0])
        begin
            if(flow_type_d == 2'd2)
            begin
                csi_after_pr_seq_o             <= csi_after_pr_seq_o + 'd1;
                pr_local_credits_used_o        <= pr_local_credits_used_o + credits_used;
                pr_local_credits_avail_o       <= 1'b1;
                cmpl_local_credits_avail_o     <= 1'b0;
            end                                
            else if(flow_type_d == 2'd1)        
            begin                              
                cmpl_local_credits_used_o      <= cmpl_local_credits_used_o + credits_used;
                cmpl_local_credits_avail_o     <= 1'b1;
                pr_local_credits_avail_o       <= 1'b0;
            end
            else
            begin
                cmpl_local_credits_avail_o     <= 1'b0;
                pr_local_credits_avail_o       <= 1'b0;
            end
        end
        else if(f2csi_prcmpl_o.vld[1] && (f2csi_prcmpl_o.rdy == 2'b11))
        begin
            pr_local_credits_avail_o           <= 1'b0;
            cmpl_local_credits_avail_o         <= 1'b0;
            if(flow_type_d == 2'd2)
            begin
                pr_local_credits_used_o        <= pr_local_credits_used_o + credits_used;
            end                               
            else if(flow_type_d == 2'd1)       
            begin                             
                cmpl_local_credits_used_o      <= cmpl_local_credits_used_o + credits_used;
            end
        end
        else if(f2csi_prcmpl_o.vld[0] && (f2csi_prcmpl_o.rdy == 2'b11))
        begin
            pr_local_credits_avail_o           <= 1'b0;
            cmpl_local_credits_avail_o         <= 1'b0;
            if(flow_type_d == 2'd2)
            begin
                pr_local_credits_used_o        <= pr_local_credits_used_o + 'd2;
            end                               
            else if(flow_type_d == 2'd1)       
            begin                             
                cmpl_local_credits_used_o      <= cmpl_local_credits_used_o + 'd2;
            end
        end
        else
        begin
            pr_local_credits_avail_o           <= 1'b0;
            cmpl_local_credits_avail_o         <= 1'b0;
        end
    end
end


/////////////////////////////////////////////////////////////////////////////
//            NPR state machine                                            //
////////////////////////////////////////////////////////////////////////////

always_comb   
begin
   // store current state as next
    state_next_npr = current_npr_state; // required: when no case statement is satisfied
    case(current_npr_state)
        st_npr_idle: begin
            if(f2csi_npr_o.rdy == 'b1)
            begin
                if(npr_sop_i == 1'b1 && npr_eop_i == 1'b1) 
                begin
                    state_next_npr = st_npr_sop_eop;
                end 
                else
                begin
                    state_next_npr = current_npr_state;
                end
            end
            else
            begin
                state_next_npr = current_npr_state;
            end         
        end 
        st_npr_sop_eop: begin
            if(f2csi_npr_o.rdy == 'b1)
            begin
                if(npr_sop_i == 1'b1 && npr_eop_i == 1'b1) 
                    state_next_npr = st_npr_sop_eop;
                else 
                    state_next_npr = st_npr_idle;   
            end     
            else
            begin
                state_next_npr = current_npr_state;
            end     
        end
        default: begin
            state_next_npr = st_npr_idle;
        end     
    endcase
end
    
always @(posedge clk)
begin
    if(!rst_n) 
    begin
        f2csi_npr_o.seg             <= 'd0;
        f2csi_npr_o.vld             <= 'd0;
        f2csi_npr_o.sop             <= 'd0;
        f2csi_npr_o.eop             <= 'd0;
        f2csi_npr_o.err             <= 'd0;
        csi_after_pr_seq_valid_o    <= 'd0;
    end
    else 
    begin
        if(f2csi_npr_o.rdy == 'b1)
        begin
            case(current_npr_state)
            st_npr_idle: begin
                f2csi_npr_o.vld             <= 'd0;
                f2csi_npr_o.sop             <= 'd0;
                f2csi_npr_o.eop             <= 'd0;
                f2csi_npr_o.err             <= 'd0;
                csi_after_pr_seq_valid_o    <= 'd0;
            end
            st_npr_sop_eop: begin
                f2csi_npr_o.seg             <= {96'd0,npr_cap_header};
                f2csi_npr_o.vld             <= 'd1;
                f2csi_npr_o.sop             <= 'd1;
                f2csi_npr_o.eop             <= 'd1;
                f2csi_npr_o.err             <= 'd0;
                csi_after_pr_seq_valid_o    <= 'd1;
            end
            endcase
        end 
    end 
end


/////////////////////////////////////////////////////////////////////////////
//                NPR local credit used info                              //
////////////////////////////////////////////////////////////////////////////

always @(posedge clk)
begin
    if(!rst_n) 
    begin
        npr_local_credits_used_o    <= 'd0;
        npr_local_credits_avail_o   <= 'b0;
    end
    else 
    begin
        if(f2csi_npr_o.eop && f2csi_npr_o.vld && f2csi_npr_o.rdy)
        begin
            npr_local_credits_used_o     <= 'd2;
            npr_local_credits_avail_o    <= 1'b1;
        end
        else
        begin
            npr_local_credits_avail_o    <= 1'b0;
        end
    end
end

endmodule   
            
