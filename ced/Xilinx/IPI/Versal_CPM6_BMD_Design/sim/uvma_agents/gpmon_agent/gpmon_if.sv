interface gpmon_if;

  wire         clk;
  logic [63:0] sig;

  clocking cb @(posedge clk);
    input sig;
  endclocking

endinterface
