// - This interface is sufficient to connect to a net as either a driver or 
//   monitor, so long as there is only one driver of the net
// - Users can create their own interface as needed and pass that into the
//   reset agent using the VIF type parameter, which will be required if there
//   are multiple drivers of the net, such as when a user wants their TB to 
//   take precedence over an internal net
interface reset_if;

  // Connect to DUT
  logic clk;
  wire  reset;
 
  // Don't touch
  logic i_reset = 1'bz;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_reset net directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a 
  // passive slave and not have to worry about changing the interface,
  // only the configuration object
  assign reset = i_reset;

  clocking cb @(posedge clk);
    default input #1step output posedge;
    output i_reset;
  endclocking

endinterface
