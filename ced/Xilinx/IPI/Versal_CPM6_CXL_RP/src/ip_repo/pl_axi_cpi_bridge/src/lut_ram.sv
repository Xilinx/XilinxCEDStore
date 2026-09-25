module lut_ram #(
  parameter     WIDTH,
  parameter     DEPTH,
  parameter     WEN_CTRL = "none", //"bit", "byte", "word", "none"
  parameter bit OFLOP = 0,
  parameter     INIT_MEM_SIM = "none",
  // CAN'T TOUCH
  localparam ADDR_W = $clog2(DEPTH),
  localparam WEN_W  = WEN_CTRL == "byte"               ? WIDTH/8 :
                      WEN_CTRL inside {"word", "none"} ? 1       :
                                                         WIDTH
                        
)(
  input               clk,
  input  [ WEN_W-1:0] wen,
  input  [ADDR_W-1:0] waddr,
  input  [ WIDTH-1:0] wdata,
  input  [ADDR_W-1:0] raddr,
  output [ WIDTH-1:0] rdata
);

  (* ram_style = "distributed" *) logic [WIDTH-1:0] ram[DEPTH];
  logic [WIDTH-1:0] rdata_ff;

  // Per-bit write-enable
  if (WEN_CTRL == "bit") begin
    always @(posedge clk)
      foreach(wdata[ii])
        if (wen[ii])
          ram[waddr][ii] <= wdata[ii];
  end
  // Per-byte write-enable
  else if (WEN_CTRL == "byte") begin
    always @(posedge clk)
      for (int ii=0; ii<WIDTH/8; ii++)
        if (wen[ii])
          ram[waddr][ii*8+:8] <= wdata[ii*8+:8];
  end
  // Word write-enable
  else if (WEN_CTRL == "word") begin
    always @(posedge clk)
      if (wen[0])
        ram[waddr] <= wdata;
  end
  // No write-enable
  else begin
    always @(posedge clk)
      ram[waddr] <= wdata;
  end

  always_ff @(posedge clk)
    rdata_ff <= ram[raddr];
     
  assign rdata = OFLOP ? rdata_ff : ram[raddr];
  
  `ifndef SYNTHESIS
  //synthesis off
  initial  begin
    // Config RAM programming emulation  
    case (1'b1)
      INIT_MEM_SIM=="zeroes" : foreach (ram[ii]) ram[ii] <= '0;
      INIT_MEM_SIM=="ones"   : foreach (ram[ii]) ram[ii] <= '1;
      // Randomize 32 bit words at a time, then the remaining do 1 bit at time
      INIT_MEM_SIM=="random" : foreach (ram[ii]) 
                                 for (int jj=0; jj<=WIDTH/32; jj++)
                                   if (jj!=WIDTH/32)
                                     ram[ii][jj*32+:32] <= $urandom;
                                   else begin 
                                     for (int kk=0; kk<(WIDTH%32); kk++)
                                       ram[ii][jj*32+kk] <= $urandom;
                                   end
      INIT_MEM_SIM!="none"   : $readmemb(INIT_MEM_SIM, ram);
    endcase
    if (!(WEN_CTRL inside {"none", "bit", "byte", "word"}))
      $fatal(0, $sformatf("Invalid parameter WEN_CTRL=\"%0s\"",WEN_CTRL));
  end
  //synthesis on
  `endif

endmodule
