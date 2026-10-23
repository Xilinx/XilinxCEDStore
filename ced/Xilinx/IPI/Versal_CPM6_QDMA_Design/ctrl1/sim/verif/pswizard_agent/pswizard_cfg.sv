// pswizard_cfg.sv — Configuration object for the pswizard passive monitor agent
class pswizard_cfg extends uvm_object;
  `uvm_object_utils(pswizard_cfg)

  // Enable per-channel filtering: if non-zero only log transactions whose
  // address falls within [addr_filter_lo, addr_filter_hi].
  // When addr_filter_hi == 0 (default) all transactions are logged.
  bit [63:0] addr_filter_lo = 64'h0;
  bit [63:0] addr_filter_hi = 64'h0;  // 0 = no filter

  // Log verbosity: 0=NOC events+IRQ only, 1=also log data phase last beats
  int log_level = 1;

  bit          checks_enable  = 1;
  // 1000 cycles: a generous round upper bound relative to typical DMA/register
  // access latencies seen in this testbench. Not tied to a specific spec value --
  // reserved for a future outstanding-transaction watchdog, not currently wired up.
  int unsigned timeout_cycles = 1000;

  function new(string name = "pswizard_cfg");
    super.new(name);
  endfunction
endclass
