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


`define READ_AXI4L(ADDR, DATA, rdt, tout) \
    rdt.set_read_cmd(ADDR,XIL_AXI_BURST_TYPE_INCR, 0, 0, XIL_AXI_SIZE_4BYTE );  \
    rdt.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN); \
    agent.rd_driver.send(rdt); \
    agent.rd_driver.wait_rsp(tout); \
    DATA = tout.get_data_beat(0); \
    $display("[%t] : Axi VIP: Address = 0x%x : Data = 0x%x",$realtime, tout.get_addr(), DATA); \
    TSK_CLK_EAT(50);

`define WRITE_AXI4L(ADDR, DATA, wrt) \
    wrt.set_write_cmd(ADDR, XIL_AXI_BURST_TYPE_INCR,0,0,XIL_AXI_SIZE_4BYTE); \
    wrt.set_data_beat(0, DATA); \
    agent.wr_driver.send(wrt); \
    wait(board.EP.csi_uport_axil_bvalid == 1'b1) \
    TSK_CLK_EAT(50);
 
`define WRITE_AXI4L_VERBOSE(ADDR, DATA, wrt) \
    wrt.set_write_cmd(ADDR, XIL_AXI_BURST_TYPE_INCR,0,0,XIL_AXI_SIZE_4BYTE); \
    wrt.set_data_beat(0, DATA); \
    agent.wr_driver.send(wrt); \
    $display("[%t] : Axi VIP: Wrote: 0x%x - 0x%x",$realtime, wrt.get_addr(), DATA); \
    wait(board.EP.csi_uport_axil_bvalid == 1'b1) \
    TSK_CLK_EAT(50);
    

module axi_vip_master ();
import axi_vip_pkg::*;
import axi_vip_0_pkg::*;
axi_vip_0_mst_t agent;

  localparam CSI_UPORT_ADDR                   =  32'hD0000000;
  localparam UPORT_NPR_CMD_RAM_BASE_ADDR      =  32'hD0010000;
  localparam UPORT_PR_CMD_RAM_BASE_ADDR       =  32'hD0020000;
  localparam UPORT_CMPL_PAYLOAD_RAM_BASE_ADDR =  32'hD0040000;
  localparam UPORT_NPR_PAYLOAD_RAM_BASE_ADDR  =  32'hD0080000;
  localparam UPORT_PR_PAYLOAD_RAM_BASE_ADDR   =  32'hD00C0000;
  
  bit [31:0] payload ;
  bit [31:0] addr    = 'h0; 
  axi_transaction wrt;
  axi_transaction rdt;
  axi_transaction tout;
  logic [31:0] read_data;
  logic        write_done;

  integer idx;
  integer dw64_cnt=1;
  integer mask1,mask2;
  integer payload_len = 0;

  assign  mask1 = 32'h00000003;
  assign  mask2 = 32'h000003FC;
    
  initial begin

 
    agent = new("master vip agent", board.EP.U_DRIVER_UB_AXI4L.inst.IF);   
    agent.set_verbosity(0);
    agent.start_master();                   // agent start to run
    board.EP.U_DRIVER_UB_AXI4L.inst.IF.clr_xilinx_slave_ready_check();
    board.EP.U_DRIVER_UB_AXI4L.inst.IF.clr_xilinx_slave_ready_check();
    board.EP.U_DRIVER_UB_AXI4L.inst.IF.clr_xilinx_slave_ready_check();
    
    // Write
    wait(board.RP.cfg_ltssm_state == 'h10)
    
    payload = 'h0; 
    addr    = 'h0;
    wrt = agent.wr_driver.create_transaction();
    rdt = agent.rd_driver.create_transaction();
    
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h00), 32'h00000000, wrt) ;   // NPR dest id  (Uport ---> )
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h04), 32'h00000001, wrt) ;   // CMPL dest id (Uport ---> )
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h08), 32'h00000002, wrt) ;   // PR dest id   (Uport ---> )
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h0C), 32'h00000059, wrt) ;   // NPR init local credits
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h10), 32'h00000118, wrt) ;   // CMPL init local credits
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h14), 32'h00000080, wrt) ;   // PR init local credits
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h18), 32'ha5a5a5a5, wrt) ;   // seed value 0 for PR (-->Uport)
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h1C), 32'ha5a5a5a6, wrt) ;   // seed value 1 for PR (-->Uport)
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h2C), 32'hc6c6c6c6, wrt) ;   // seed value 0 for CMPL (-->Uport)
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h30), 32'hc6c6c6c7, wrt) ;   // seed value 1 for CMPL (-->Uport)
    
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h28), 32'h300     , wrt) ;  // reset counters, encode & req_gen logic
     //Load Initial credit for all the flow
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h28), 32'h038     , wrt) ;  
    //Enabling CMPL txn at user port if it receives NPR
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h28), 32'h002     , wrt) ;  
    `WRITE_AXI4L((CSI_UPORT_ADDR +32'h28), 32'h000     , wrt) ;  
   
   
    //filling CMPL payload ram which has seed values for CMPL generation
    $display("[%t] : Axi VIP: filling CMPL payload ram",$realtime);
    for(int h_idx=0; h_idx<64; h_idx=h_idx+1)
    begin
       `WRITE_AXI4L((UPORT_CMPL_PAYLOAD_RAM_BASE_ADDR + 4*h_idx), (32'hc9c9c9c9 + 4*h_idx), wrt) ;  
    end

    // UserPort to PCIe - PR and NPR init seq
    $display("[%t] : Axi VIP: filling PR/NPR RAM",$realtime);
    for (int pr_c_ram_loop=0; pr_c_ram_loop<4; pr_c_ram_loop=pr_c_ram_loop+1)
    begin // pr_c_ram_loop
        `WRITE_AXI4L((UPORT_PR_CMD_RAM_BASE_ADDR+16*pr_c_ram_loop+32'h000), 32'h00000000, wrt) ;// Completer ID, Requester ID 
        `WRITE_AXI4L((UPORT_PR_CMD_RAM_BASE_ADDR+16*pr_c_ram_loop+32'h004), 32'h00200100, wrt) ;// -->PSX (0x00600100)   
        `WRITE_AXI4L((UPORT_PR_CMD_RAM_BASE_ADDR+16*pr_c_ram_loop+32'h008), 32'h000404FF, wrt) ;//one PR txn for each cmd ram   
	`WRITE_AXI4L((UPORT_PR_CMD_RAM_BASE_ADDR+16*pr_c_ram_loop+32'h00C), 32'h00000000, wrt) ;
    
    end 
    for (int pr_d_ram_loop=0; pr_d_ram_loop<4; pr_d_ram_loop=pr_d_ram_loop+1)
    begin // pr_d_ram_loop
	`WRITE_AXI4L((UPORT_PR_PAYLOAD_RAM_BASE_ADDR+16*pr_d_ram_loop+32'h000), 32'hc6c6c6c6, wrt) ;                     // Seed
	`WRITE_AXI4L((UPORT_PR_PAYLOAD_RAM_BASE_ADDR+16*pr_d_ram_loop+32'h004), (32'h30000000+16*pr_d_ram_loop), wrt);   // Addr[31:0]
	`WRITE_AXI4L((UPORT_PR_PAYLOAD_RAM_BASE_ADDR+16*pr_d_ram_loop+32'h008), (32'h00000000+(pr_d_ram_loop<<30)), wrt);// {dw_len[1:0],Addr_high[61:0]}
	`WRITE_AXI4L((UPORT_PR_PAYLOAD_RAM_BASE_ADDR+16*pr_d_ram_loop+32'h00C), 32'h0000ff04, wrt) ;                     // {res, byte_en[7:0],dw_len[9:2]}
    
    end 
    for (int npr_c_ram_loop=0; npr_c_ram_loop<4; npr_c_ram_loop=npr_c_ram_loop+1)
    begin // npr_c_ram_loop
    
	`WRITE_AXI4L((UPORT_NPR_CMD_RAM_BASE_ADDR+16*npr_c_ram_loop+32'h000), 32'h00000000, wrt) ;// Completer ID, Requester ID - 32'h0000_0100
        `WRITE_AXI4L((UPORT_NPR_CMD_RAM_BASE_ADDR+16*npr_c_ram_loop+32'h004), 32'h00200100, wrt) ;// -->PSX (0x00600100)   
        //`WRITE_AXI4L((UPORT_NPR_CMD_RAM_BASE_ADDR+16*npr_c_ram_loop+32'h008), 32'h000401FF, wrt) ;//one PR txn for each cmd ram   
	if(npr_c_ram_loop == 3) begin
          `WRITE_AXI4L((UPORT_NPR_CMD_RAM_BASE_ADDR+16*npr_c_ram_loop+32'h008), 32'h000404FF, wrt) ;//  
        end else begin
          `WRITE_AXI4L((UPORT_NPR_CMD_RAM_BASE_ADDR+16*npr_c_ram_loop+32'h008), 32'h000404FF, wrt) ;//  
        end
    	`WRITE_AXI4L((UPORT_NPR_CMD_RAM_BASE_ADDR+16*npr_c_ram_loop+32'h00C), 32'h00000000, wrt) ;

    end 
    for (int npr_d_ram_loop=0; npr_d_ram_loop<4; npr_d_ram_loop=npr_d_ram_loop+1)
    begin // npr_d_ram_loop
    	payload_len = (npr_d_ram_loop+1);//32dw
    	
	`WRITE_AXI4L((UPORT_NPR_PAYLOAD_RAM_BASE_ADDR+16*npr_d_ram_loop+32'h000), (32'h10000000 + 32*npr_d_ram_loop), wrt) ;            //Target read address >> 2 (axi memory at 0x4000_0000)
	`WRITE_AXI4L((UPORT_NPR_PAYLOAD_RAM_BASE_ADDR+16*npr_d_ram_loop+32'h004), (32'h00000000 +(((mask1)&(payload_len))<<30)), wrt) ; //dw_len = 48 (40(hex)>>2=10hex)
        if(npr_d_ram_loop==0) begin //for dw=1 lbe should be zero
	  `WRITE_AXI4L((UPORT_NPR_PAYLOAD_RAM_BASE_ADDR+16*npr_d_ram_loop+32'h008), (32'h003c1000 +(npr_d_ram_loop<<8)+(((mask2)&(payload_len)) >> 2 )), wrt) ;
	end else begin 
	  `WRITE_AXI4L((UPORT_NPR_PAYLOAD_RAM_BASE_ADDR+16*npr_d_ram_loop+32'h008), (32'h03fc1000 +(npr_d_ram_loop<<8)+(((mask2)&(payload_len)) >> 2 )), wrt) ; //lbe,fbe[89:82] & npr_tag [81:72] = 0x10, dw_len = 18 (040>>2)
	end
	`WRITE_AXI4L((UPORT_NPR_PAYLOAD_RAM_BASE_ADDR+16*npr_d_ram_loop+32'h00C), 32'h00000000, wrt) ;
    
    end // npr_d_ram_loop
    
    wait(board.RP.trig_uport_gen == 'h1)
    //reg 0x24 gives info about if any txn is in progress
    //reg 0x28 is used to initiate any txn from uport to PCIe  //NPR : bit0    //CMPL: bit1    //PR  : bit2
    for (int iter=0; iter<4;iter=iter+1)
    begin
      $display("[%t] : Axi VIP: PR Trigger - Iteration : [%d] ",$realtime, iter);
      do
      begin 
        `READ_AXI4L ((CSI_UPORT_ADDR+32'h024),read_data, rdt, tout);// check if txn is in progress (uport --> PCIe))
      end while ((read_data & 32'h1) || (read_data & 32'h4));       // bit[0] in reg 0x24 for NPR txn
      `WRITE_AXI4L((CSI_UPORT_ADDR+32'h028), 32'h4, wrt) ;          // initiate PR&NPR  transaction from Uport -->  ;; bit[0]NPR and bit[2]PR in reg 0x28
      `WRITE_AXI4L((CSI_UPORT_ADDR+32'h028), 32'h0, wrt) ;
    end
    for (int iter=0; iter<4;iter=iter+1)
    begin
      $display("[%t] : Axi VIP: NPR Trigger - Iteration : [%d] ",$realtime, iter);
      do
      begin 
        `READ_AXI4L ((CSI_UPORT_ADDR+32'h024),read_data, rdt, tout);//check if txn is in progress (uport --> PCIe))
      end while ((read_data & 32'h1) || (read_data & 32'h4));       // bit[0] in reg 0x24 for NPR txn
      `WRITE_AXI4L((CSI_UPORT_ADDR+32'h028), 32'h1, wrt) ;          // initiate PR&NPR  transaction from Uport -->  ;; bit[0]NPR and bit[2]PR in reg 0x28
      `WRITE_AXI4L((CSI_UPORT_ADDR+32'h028), 32'h0, wrt) ;
    end
 
  end
  

    /************************************************************
    Task : TSK_CLK_EAT
    Inputs : None
    Outputs : None
    Description : Consume clocks.
    *************************************************************/
    task TSK_CLK_EAT;
        input    [31:0]            clock_count;
        integer            i_;
        begin
            for (i_ = 0; i_ < clock_count; i_ = i_ + 1) begin
                @(posedge EP.pl0_ref_clk_0);
            end
        end
    endtask // TSK_CLK_EAT

endmodule : axi_vip_master 
