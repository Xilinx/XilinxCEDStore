// This provides a way to send the captured data through UVM analysis ports
class tx_str_transaction extends uvm_sequence_item;

// 00, posted, 01, non-posted, 10, completion, 11, non-posted w/ data
logic [pcie_str_pkg::START_TYPE_WIDTH-1:0]  ttype;
logic [pcie_str_pkg::TX_SLOT_WIDTH-1:0]     header;
logic [pcie_str_pkg::DATA_SLOT_WIDTH-1:0]   data[];

`uvm_object_utils_begin(tx_str_transaction)
    `uvm_field_int(ttype, UVM_ALL_ON)
    `uvm_field_int(header, UVM_ALL_ON)
    `uvm_field_array_int(data, UVM_ALL_ON)
`uvm_object_utils_end

function new(string name = "tx_str_transaction");
    super.new(name);
endfunction

endclass
