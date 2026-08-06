interface gpdrv_if;

  // Connect to DUT
  logic       clk;
  wire [63:0] sig;

  // Don't touch
  logic [63:0] i_sig = 'z;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_sig net directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a 
  // passive slave and not have to worry about changing the interface,
  // only the configuration object. Technically a passive slave gpdrv
  // agent is the same thing as a gpmon agent, but that would require
  // a TB change, which is undesirable.
  assign sig = i_sig;

  clocking cb @(posedge clk);
    default input #1step output posedge;
    output i_sig;
  endclocking

endinterface
