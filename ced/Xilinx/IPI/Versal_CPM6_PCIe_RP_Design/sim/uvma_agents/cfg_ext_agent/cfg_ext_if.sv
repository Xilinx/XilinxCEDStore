interface cfg_ext_if;
  
  wire        clk;
  wire        cfg_ext_read_received;
  wire        cfg_ext_write_received;
  wire [ 9:0] cfg_ext_register_number;
  wire [ 7:0] cfg_ext_function_number;
  wire [31:0] cfg_ext_write_data;
  wire [ 3:0] cfg_ext_write_byte_enable;
  wire [31:0] cfg_ext_read_data;
  wire        cfg_ext_read_data_valid;

  // Don't touch
  logic        i_cfg_ext_read_received     = 'z;
  logic        i_cfg_ext_write_received    = 'z;
  logic [ 9:0] i_cfg_ext_register_number   = 'z;
  logic [ 7:0] i_cfg_ext_function_number   = 'z;
  logic [31:0] i_cfg_ext_write_data        = 'z;
  logic [ 3:0] i_cfg_ext_write_byte_enable = 'z;
  logic [31:0] i_cfg_ext_read_data         = 'z;
  logic        i_cfg_ext_read_data_valid   = 'z;

  // Need to make this assign so the driver of block level TBs can drive
  // the i_* nets directly via the agent configured as a master, then
  // can move to top level TB and switch to an agent configured as a
  // passive slave and not have to worry about changing the interface,
  // only the configuration object
  assign cfg_ext_read_received     = i_cfg_ext_read_received;
  assign cfg_ext_write_received    = i_cfg_ext_write_received;
  assign cfg_ext_register_number   = i_cfg_ext_register_number;
  assign cfg_ext_function_number   = i_cfg_ext_function_number;
  assign cfg_ext_write_data        = i_cfg_ext_write_data;
  assign cfg_ext_write_byte_enable = i_cfg_ext_write_byte_enable;
  assign cfg_ext_read_data         = i_cfg_ext_read_data;
  assign cfg_ext_read_data_valid   = i_cfg_ext_read_data_valid;

  // Master agent will drive some of the i_* signals (wr/rd req)
  // Active slave agent will drive some other i_* signals (rd rsp)
  // Passive slave agent will just monitor the cfg* signals
  clocking cb @(posedge clk);
    default input #1step output posedge;
    output i_cfg_ext_read_received,
           i_cfg_ext_write_received,
           i_cfg_ext_register_number,
           i_cfg_ext_function_number,
           i_cfg_ext_write_data,
           i_cfg_ext_write_byte_enable,
           i_cfg_ext_read_data,
           i_cfg_ext_read_data_valid;
  endclocking

endinterface
