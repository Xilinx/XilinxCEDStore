interface cxl_credit_agent_if();

  bit        agent_driven;
  
  wire       clk;

  wire       vld;
  wire [3:0] dat;
  wire [3:0] req;
  wire [3:0] rsp;

  // Don't touch
  logic       i_vld = 'z;
  logic [3:0] i_dat = 'z;
  logic [3:0] i_req = 'z;
  logic [3:0] i_rsp = 'z;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_* nets directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a
  // passive slave and not have to worry about changing the interface,
  // only the configuration object
  assign vld = i_vld;
  assign dat = i_dat;
  assign req = i_req;
  assign rsp = i_rsp;

  // dcb = "driver cb"
  clocking dcb @(posedge clk);
    output i_vld,
           i_dat,
           i_req,
           i_rsp;
  endclocking

  // mcb = "monitor cb" ; not qualified by anything
  clocking mcb @(posedge clk);
    input vld,
          dat,
          req,
          rsp;
  endclocking

endinterface 
