module cpi_perf_snapshot #(
  parameter bit ENABLE_CAPTURE = 1'b1
)(
  // From the CPI interface
  input         valid,
  input  [15:0] tag,
  // From free-running counter
  input  [31:0] cnt,
  // To the performance URAM
  output        write,
  output [43:0] concat
);

  assign write  = ENABLE_CAPTURE ? valid : 1'b0;
  // tag[15:12] uniquely identifies the instance, which is already
  // accounted for by attaching a snapshot to each RD/WR and Bridge
  assign concat = {cnt, tag[11:0]};

endmodule
