// c2h_prefill_sequence.sv — UVM sequence of C2H AXI4-Stream packets.
//
// Generates qdma_user_transaction items for qdma_user_driver. Each sequence
// item represents one C2H-ST descriptor's worth of data (DMA_BYTE_CNT bytes =
// num_beats × 64 bytes).
//
// Data pattern: incrementing 512-bit words seeded by QID so that each
// queue produces a unique, verifiable pattern.  The same pattern must be
// registered as expected data in dma_req_processor for integrity checks.

class c2h_prefill_sequence extends uvm_sequence#(qdma_user_transaction);
  `uvm_object_utils(c2h_prefill_sequence)

  bit [10:0]    qid;         // QDMA queue ID (11-bit internal width)
  int unsigned  num_beats;   // beats per descriptor (DMA_BYTE_CNT / 64)
  int unsigned  num_desc;    // number of descriptors (pidx)

  function new(string name = "c2h_prefill_sequence");
    super.new(name);
  endfunction

  // Generate the same 512-bit data word that register_c2h_expected_pattern
  // will store.  Must be kept in sync.
  static function bit [511:0] gen_c2h_word(bit [10:0] qid, int unsigned word_idx);
    bit [511:0] w;
    // Low 32 bits: word index; next 11 bits: QID; rest: inverted index for
    // bit diversity.  Simple, deterministic, unique per (qid, word_idx).
    w[31:0]   = word_idx[31:0];
    w[42:32]  = qid;
    w[63:43]  = ~word_idx[20:0];
    w[511:64] = {7{w[63:0]}};
    return w;
  endfunction

  task body();
    qdma_user_transaction txn;
    for (int d = 0; d < int'(num_desc); d++) begin
      txn = qdma_user_transaction::type_id::create(
              $sformatf("c2h_txn_q%0d_d%0d", qid, d));
      txn.qid        = {1'b0, qid};   // 12-bit field, zero-extend
      txn.is_h2c     = 1'b0;          // C2H direction
      txn.num_beats  = num_beats;
      txn.byte_count = num_beats * 64;
      txn.port_id    = '0;
      txn.mty        = '0;
      txn.data = new[num_beats];
      for (int b = 0; b < int'(num_beats); b++) begin
        txn.data[b] = gen_c2h_word(qid, d * num_beats + b);
      end
      start_item(txn);
      finish_item(txn);
    end
  endtask

endclass
