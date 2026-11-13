// - cfg_ext_if with a built in responder
// - Used so another device may snoop this interface when driven by a
//   master agent; an alternative to a master agent to a slave agent
interface cfg_ext_rsp_if;

  wire        clk;

  logic        cfg_ext_read_received;
  logic        cfg_ext_write_received;
  logic [ 9:0] cfg_ext_register_number;
  logic [ 7:0] cfg_ext_function_number;
  logic [31:0] cfg_ext_write_data;
  logic [ 3:0] cfg_ext_write_byte_enable;
  logic [31:0] cfg_ext_read_data;
  logic        cfg_ext_read_data_valid;

  clocking rcb @(posedge clk iff cfg_ext_read_received); 
    input  cfg_ext_register_number,
           cfg_ext_function_number;
    output cfg_ext_read_data,
           cfg_ext_read_data_valid;
  endclocking

  clocking wcb @(posedge clk iff cfg_ext_write_received); 
    input  cfg_ext_register_number,
           cfg_ext_function_number,
           cfg_ext_write_data,
           cfg_ext_write_byte_enable;
  endclocking

  bit [7:0] cfgspace[bit [11:0]];

  // Built-in writer
  initial begin : wrtr
    forever begin
      @(wcb);
      for (bit [1:0] ii=0; ii<4; ii++)
        if (wcb.cfg_ext_write_byte_enable[ii]) 
          cfgspace[{wcb.cfg_ext_register_number,ii}] = wcb.cfg_ext_write_data[ii*8+:8];
    end
  end

  // Built-in responder
  bit [9:0] addr;
  initial begin : rspdr
    cfg_ext_read_data_valid <= 1'b0;
    cfg_ext_read_data       <= '0;
    forever begin
      @(rcb);
      addr = {rcb.cfg_ext_register_number, 2'h0};
      repeat($urandom_range(9)) @(posedge clk);
      rcb.cfg_ext_read_data_valid  <= 1'b1;
      rcb.cfg_ext_read_data[ 0+:8] <= cfgspace.exists(addr)   ? cfgspace[addr]   : 'x;
      rcb.cfg_ext_read_data[ 8+:8] <= cfgspace.exists(addr+1) ? cfgspace[addr+1] : 'x;
      rcb.cfg_ext_read_data[16+:8] <= cfgspace.exists(addr+2) ? cfgspace[addr+2] : 'x;
      rcb.cfg_ext_read_data[24+:8] <= cfgspace.exists(addr+3) ? cfgspace[addr+3] : 'x;
      @(posedge clk);
      rcb.cfg_ext_read_data_valid <= 1'b0;
    end
  end

endinterface
