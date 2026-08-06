// Forward declaration of seq_enum class
typedef class seq_enum;

// UVM Callback class for seq_enum
class seq_enum_callback extends uvm_callback;

  `uvm_object_utils(seq_enum_callback)

  function new(string name = "seq_enum_callback");
    super.new(name);
  endfunction

  // Callback methods; these are tightly coupled to seq_enum
  virtual task pre_start(seq_enum seq);  endtask

  virtual task post_start(seq_enum seq); endtask

  virtual task post_enum(seq_enum seq);  endtask

endclass
