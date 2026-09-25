// qdma_periph_cfg.sv — Configuration object for the QDMA periphery monitor
class qdma_periph_cfg extends uvm_object;
   `uvm_object_utils(qdma_periph_cfg)

   // Log every W beat on s_axi_mem (with inter-beat gap timing)
   bit mem_log_all_beats = 1;

   // Decode known register offsets on s_axi_reg writes
   bit reg_decode_enable = 1;

   // Decode m_axil_dbi accesses into controller/DMA-channel/register name.
   // Decode is base-address-independent: slot/register live in addr[15:0]
   // regardless of which controller's base (0xFC2C0000 ctrl0 / 0xFC6C0000
   // ctrl1, CPM6_CTRL_REG_OFFSET=0x400000=bit22, core_top:113-117) is in use.
   // No base-address cfg field needed; ctrl0-vs-ctrl1 is read directly off addr[22].
   bit dbi_decode_enable = 1;

   // Enable protocol checks (BRESP/RRESP != OKAY)
   bit checks_enable = 1;

   // Timeout cycles (for future use — outstanding txn watchdog). 1000 is a
   // generous round upper bound relative to typical DMA/register access
   // latencies seen in this testbench, not tied to a specific spec value.
   int unsigned timeout_cycles = 1000;

   function new(string name = "qdma_periph_cfg");
      super.new(name);
   endfunction
endclass
