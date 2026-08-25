// - Base Driver Class
// - Users should extend drive_init() and drive_item(REQ req) to create an
//   extended agent that functions to drive an interface; can rely on default
//   run_phase task or overrwrite 
class base_driver#(type REQ,
                   type RSP,
                   type VIF,
                   type CFG,
                   type SHR) extends uvm_driver #(REQ,RSP);

  `uvm_component_param_utils(base_driver#(REQ,RSP,VIF,CFG,SHR))  

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"base_driver#(", 
                                   REQ::type_name,",",
                                   RSP::type_name,",",
                                   "VIF,",
                                   CFG::type_name,",",
                                   SHR::type_name,
                                   ")"};
  virtual function string get_type_name(); return type_name; endfunction

  VIF vif;
  CFG cfg;
  SHR shr;

  bit waiting, processing;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(VIF)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name, "Failed to get vif from config db") 
    if (!uvm_config_db#(CFG)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name, "Failed to get cfg from config db") 
    if (!uvm_config_db#(SHR)::get(this, "", "shr", shr))
      `uvm_fatal(get_type_name, "Failed to get shr from config db") 
  endfunction

  // Driver "pulls" sequence_item (blocking) from sequencer
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    drive_init(); 
    forever begin
      {waiting, processing} = 2'b10;
      seq_item_port.get_next_item(req); //blocking
      {waiting, processing} = 2'b01;
      drive_item(req);
      {waiting, processing} = 2'b00;
      seq_item_port.item_done();
    end
  endtask 

  // Empty method for extended classes to implement
  // Would implement as pure virtual method in abstract class but VCS complained
  virtual task drive_init(); endtask

  // Empty method for extended classes to implement
  // Would implement as pure virtual method in abstract class but VCS complained
  virtual task drive_item(REQ req); endtask

endclass
