// This module implements the double-dabble algorithm to convert a binary
// number to binary coded decimal (BCD) one. It is sequential and has a load
// and done signal to show perform operations. 
module bin2bcd_seq #(
  parameter     IW,               //input width (binary bits)
  parameter bit HOLD_DONE = 1'b0, //default done to be single cycle assertion
  // CAN'T TOUCH
  // Output width (BCD bits) minimally valid up to IW=23 
  localparam OW = IW<4  ? IW : 
                  IW<7  ? IW+1 :
                  IW<10 ? IW+2 :
                  IW<17 ? IW+3 :
                  IW<20 ? IW+4 :
                  IW<24 ? IW+5 : 1,
  localparam STAGES = (IW-1)/3 // number of pipeline stages 
)(
  input                 clk,
  input                 load,
  input        [IW-1:0] bin,
  output logic          in_prog,
  output logic          done,
  output logic [OW-1:0] bcd
);

  // Must hardcode for a single BCD digit
  if (IW<4) begin : BCD_1
    assign in_prog = 1'b0;
    always_ff @(posedge clk) begin
      if (load)
        {done, bcd} <= {1'b1, bin};
      else if (!HOLD_DONE)
        done <= 1'b0;
    end
  end : BCD_1
  else begin : BCD_N

    // Number 
    logic [$clog2(STAGES):0] cnt;

    logic    [OW-1:0]   pipe[0:(IW-1)/3];
    logic  [8+OW-1:0-8] subpipe[0:((IW-1)/3)-1][0:2]; 
    //append 8 bits on left and right so that the algorithm index 
    //isn't going into the weeds
  
    // Init for sim
    initial begin
      in_prog <= '0;
      done <= '0;
    end

    // Latch in the data
    always @(posedge clk) begin
      if (load) begin
        done    <= 1'b0;
        in_prog <= 1'b1;
        pipe[0] <= bin;
        cnt     <= STAGES-1'b1; 
      end
      else if (in_prog) begin
        cnt <= cnt - 1'b1; 
        // Take each pipeline stage from subpipe
        for (int ii=1; ii<=(IW-1)/3; ii++)
          // Last pipeline may needn't all stages
          if (ii==((IW-1)/3))
            pipe[ii] = subpipe[ii-1][((IW-4)%3)][OW-1:0];
          else
            pipe[ii] = subpipe[ii-1][2][OW-1:0];
        // Mark when done
        if (!cnt) begin
          in_prog <= 1'b0;
          done    <= 1'b1;
        end
      end
      else if (!HOLD_DONE)
        done <= 1'b0;
    end
   
    assign bcd = pipe[(IW-1)/3]; 

    always_comb begin
      // The algorithm iterates through blocks of 4 bits repeatedly, unrolling
      // this loop. It has IW-3 operations in series in the worst case when not
      // pipelined. When pipelined as such, we break it up into a worst case of 3
      // and we have floor(IW-1)/3) stages;
      int p, i, j;
      for (p=0; p<(IW-1)/3; p++) begin // number of pipeline stages
        for (i=0; i<=(p==((IW-1)/3)-1?(IW-4)%3:2); i++) begin // depth of pipeline stage {0,1,2}
          // initialize each stage as passthrough
          subpipe[p][i] = !i ? {pipe[p], 8'b0} : subpipe[p][i-1]; 
          // Go through each pipeline
          for (j=0; j<=p; j++) begin // width of each level of pipeline
            if (subpipe[p][i][IW-i-p*3+4*j -: 4] > 4)  
              subpipe[p][i][IW-i-p*3+4*j -: 4] = subpipe[p][i][IW-i-p*3+4*j -: 4] + 4'd3;
          end
        end   
      end
    end

  end : BCD_N

  initial begin
    if (IW>23)
      $fatal("IW=%0d exceeds the maximum",IW);
  end

endmodule
