// qdma_user_transaction.sv — UVM sequence item for QDMA user-side AXI4-Stream.
//
// Represents one AXI4-Stream packet in either H2C or C2H direction.
// num_beats is the number of 512-bit (64-byte) beats.

class qdma_user_transaction extends uvm_sequence_item;
  `uvm_object_utils(qdma_user_transaction)

  rand bit [11:0]   qid;          // QDMA queue ID
  rand bit [2:0]    port_id;      // QDMA/ST port ID observed on tuser_port_id
  rand int unsigned num_beats;    // number of 512-bit beats in this packet
  rand int unsigned byte_count;   // number of valid payload bytes in this packet
  rand bit [511:0]  data[];       // payload (one entry per beat)
  rand bit          is_h2c;       // 1=H2C, 0=C2H
  bit [5:0]         mty;          // empty bytes in last beat (from tuser_mty)

  constraint num_beats_pos_c { num_beats > 0; num_beats <= 64; }
  constraint byte_count_c    { byte_count > 0; byte_count <= (num_beats * 64); }
  constraint data_size_c     { data.size() == num_beats; }

  function new(string name = "qdma_user_transaction");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("qid=%0d port_id=%0d is_h2c=%0b num_beats=%0d byte_count=%0d",
                     qid, port_id, is_h2c, num_beats, byte_count);
  endfunction

  function void do_copy(uvm_object rhs);
    qdma_user_transaction rhs_t;
    super.do_copy(rhs);
    $cast(rhs_t, rhs);
    qid       = rhs_t.qid;
    port_id   = rhs_t.port_id;
    num_beats = rhs_t.num_beats;
    byte_count = rhs_t.byte_count;
    data      = rhs_t.data;
    is_h2c    = rhs_t.is_h2c;
    mty       = rhs_t.mty;
  endfunction

  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    qdma_user_transaction rhs_t;
    if (!$cast(rhs_t, rhs)) return 0;
    return (qid == rhs_t.qid &&
            port_id == rhs_t.port_id &&
            num_beats == rhs_t.num_beats &&
            byte_count == rhs_t.byte_count &&
            is_h2c == rhs_t.is_h2c);
  endfunction

endclass
