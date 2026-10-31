interface cpi_if #(parameter bit [3:0] REQ, parameter bit [3:0] DATA, parameter bit [3:0] RSP, parameter P=1);

  wire clk;

  global_if#(P) glbl(); 
  assign glbl.clk = clk;

  /* VCS runs into issues when indexing into a variable-sized array, so we   */
  /* must set to the max width possible and just leave the unused interfaces */ 
  /* floating by not driving the clock and not using them in the agent.      */
  
  req_if#($clog2(P)) req[0:7]();
  for(genvar ii=0; ii<REQ; ii++) begin : GEN_REQ_CLK_ASSIGN
    assign req[ii].clk = clk;
  end

  data_if#($clog2(P)) data[0:7]();
  for (genvar jj=0; jj<DATA; jj++) begin : GEN_DATA_CLK_ASSIGN
    assign data[jj].clk = clk;
  end

  rsp_if#($clog2(P)) rsp[0:7]();
  for (genvar kk=0; kk<RSP; kk++) begin : GEN_RSP_CLK_ASSIGN
    assign rsp[kk].clk = clk;
  end

endinterface: cpi_if
