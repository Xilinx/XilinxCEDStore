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
    $display("[%t] : Axi VIP: Wrote: 0x%x - 0x%x",$realtime, wrt.get_addr(), DATA); \
    wait(board.EP.csi_uport_axil_bvalid == 1'b1) \
    $display("[%t] : Axi VIP: Write done",$realtime); \
    TSK_CLK_EAT(50);
   

module axi_vip_master ();
import axi_vip_pkg::*;
import axi_vip_0_pkg::*;
axi_vip_0_mst_t agent;

  bit [31:0] payload ;
  bit [31:0] addr    = 'h0; //board.EP.C_AXIBAR_0[31:0]+board.EP.set_add[8];
  axi_transaction wrt;
  axi_transaction rdt;
  axi_transaction tout;
  logic [31:0] read_data;
  logic        write_done;
  integer      idx;
  initial begin
    agent = new("master vip agent", board.EP.U_DRIVER_UB_AXI4L.inst.IF);   
    agent.set_verbosity(0);
    agent.start_master();                   // agent start to run
    
    // Write
    wait(board.RP.cfg_ltssm_state == 'h10)
    
    payload = 'h0; 
    addr    = 'h0;
    wrt = agent.wr_driver.create_transaction();
    wrt.set_write_cmd(addr, XIL_AXI_BURST_TYPE_INCR,0,0,XIL_AXI_SIZE_4BYTE);
    wrt.set_data_beat(0, payload);
    agent.wr_driver.send(wrt);
    $display("[%t] : Axi VIP: Wrote: 0x%x - 0x%x",$realtime, wrt.get_addr(), payload);
    wait(board.EP.csi_uport_axil_bvalid)
       $display("[%t] : Axi VIP: Write done",$realtime);
       
    @(posedge EP.pl0_ref_clk_0);
       $display("[%t] : Receive start", $realtime);

    // READ
    rdt = agent.rd_driver.create_transaction();
    rdt.set_read_cmd(addr,XIL_AXI_BURST_TYPE_INCR, 0, 0, XIL_AXI_SIZE_4BYTE );
    rdt.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
    agent.rd_driver.send(rdt);
    agent.rd_driver.wait_rsp(tout);
    $display("[%t] : Axi VIP: Address = 0x%x : Data = 0x%x",$realtime, tout.get_addr(), tout.get_data_beat(0));
    
    `READ_AXI4L (32'h0,read_data, rdt, tout);

    //EP
    for (idx =0; idx < 3; idx =idx+1)
    begin
      $display("[%t] : Axi VIP: Reading from Function = %x",$realtime, idx);
      `WRITE_AXI4L(32'h40,idx,wrt);
      `READ_AXI4L (32'h1000,read_data, rdt, tout);
      //`READ_AXI4L (32'h1004,read_data, rdt, tout);
      //`READ_AXI4L (32'h1008,read_data, rdt, tout);
      //`READ_AXI4L (32'h100c,read_data, rdt, tout);
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
