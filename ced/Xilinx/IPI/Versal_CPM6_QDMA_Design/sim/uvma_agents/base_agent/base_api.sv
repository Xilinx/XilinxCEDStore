// - Base API Class
// - Contains a sequencer handle so users can create "BFM-like" functions
//   like "write" that will, under the hood, create sequences and start
//   them on the sequencer e.g. agent.api.write(addr, data) 
// - Provides an easy to understand interface for commonly used base
//   sequences 
class base_api#(type SQR) extends uvm_component;

  `uvm_component_param_utils(base_api#(SQR))

  // uvm*param_utils don't define get_type_name() and type_name
  const static string type_name = {"base_api#(", SQR::type_name, ")"};
  virtual function string get_type_name(); return type_name; endfunction

  SQR sqr; //gets assigned handle in agent class

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass
