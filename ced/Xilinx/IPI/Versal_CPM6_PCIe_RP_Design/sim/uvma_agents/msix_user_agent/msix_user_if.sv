interface msix_user_if;

  bit         agent_driven;

  // Connect to DUT
  wire        clk;

  wire  [ 2:0] user_func_num;
  wire  [ 7:0] user_vfunc_num;
  wire         user_vfunc_active;
  wire         user_req;
  wire  [10:0] user_vector_num;
  wire         user_grant;
  wire  [ 1:0] user_operation;
  wire         user_error;

  // Don't touch
  logic [ 2:0] i_user_func_num     = 'z;
  logic [ 7:0] i_user_vfunc_num    = 'z;
  logic        i_user_vfunc_active = 'z;
  logic        i_user_req          = 'z;
  logic [10:0] i_user_vector_num   = 'z;
  logic        i_user_grant        = 'z;
  logic [ 1:0] i_user_operation    = 'z;
  logic        i_user_error        = 'z;
  // this should be used to control an external mux in case a user
  // wants to combine this agent with separate RTL
  bit          select;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_sig net directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a 
  // passive slave and not have to worry about changing the interface,
  // only the configuration object. Technically a passive slave gpdrv
  // agent is the same thing as a gpmon agent, but that would require
  // a TB change, which is undesirable.
  assign user_func_num     = i_user_func_num;
  assign user_vfunc_num    = i_user_vfunc_num;
  assign user_vfunc_active = i_user_vfunc_active;
  assign user_req          = i_user_req;
  assign user_vector_num   = i_user_vector_num;
  assign user_grant        = i_user_grant;
  assign user_operation    = i_user_operation;
  assign user_error        = i_user_error;

  // Master agent will drive some of the i_* signals
  // Active slave agent: not supported
  // Passive slave agent will just monitor all signals
  clocking dcb @(posedge clk);
    output i_user_func_num,
           i_user_vfunc_num,
           i_user_vfunc_active,
           i_user_req,
           i_user_vector_num,
           i_user_operation,
           select;
  endclocking

  clocking mcb @(posedge clk);
    input user_func_num,
          user_vfunc_num,
          user_vfunc_active,
          user_req,
          user_vector_num,
          user_grant,
          user_operation,
          user_error;
  endclocking

endinterface
