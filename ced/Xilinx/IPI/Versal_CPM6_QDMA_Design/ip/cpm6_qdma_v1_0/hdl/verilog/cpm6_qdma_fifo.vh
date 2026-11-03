`ifndef CPM6_QDMA_FIFO_VH
`define CPM6_QDMA_FIFO_VH
//`include "dma5_axi4mm_axi_bridge.vh"


  module qdma_v5_0_12_GenericFIFO
  // import cpm6_qdma_v1_0_1_pkg::*;
    #( 
      parameter BUF_DATAWIDTH = 256,
      parameter LATE_EP_ON_WR = 1,
      parameter BUF_WE = BUF_DATAWIDTH/8,
      parameter BUF_DEPTH = 512,
      parameter BUF_PTR = $clog2(BUF_DEPTH),
      parameter AE_THRESHOLD = BUF_DEPTH >> 2,
      parameter AF_THRESHOLD = BUF_DEPTH - 2
    )
    (
        input clkin,
    input reset_n,
    input sync_reset_n,
        input [BUF_DATAWIDTH-1:0] DataIn,
        output [BUF_DATAWIDTH-1:0] DataOut,
    input WrEn,
    input RdEn,
    output almost_empty,
    output almost_full,
    output empty,
    output full
   );
(* ram_style = "DISTRIBUTED" *)
   reg [BUF_DATAWIDTH-1:0] MemArray [BUF_DEPTH-1:0];
   reg [BUF_PTR-1:0] WrPtr;
   reg [BUF_PTR-1:0] RdPtr;
   reg [BUF_PTR:0] FifoCntrWr;
   reg [BUF_PTR:0] FifoCntrRd;
   reg [BUF_PTR:0] FifoCntrRd_nxt;
   wire WriteQ, RdDeQ;
   reg almost_empty_ff;
   reg almost_full_ff;
   reg empty_ff;
   reg full_ff;
   assign WriteQ = WrEn;
   assign RdDeQ = RdEn;
   assign DataOut = MemArray[RdPtr];
   assign almost_empty = almost_empty_ff;
   assign almost_full = almost_full_ff;
   assign empty = empty_ff;
   assign full = full_ff;
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
         WrPtr <= 'd0;
    else if  (~sync_reset_n || ((WrPtr == (BUF_DEPTH-1)) && WrEn))
         WrPtr <= 'd0;
        else if (WrEn) begin
        WrPtr <= WrPtr + 'd1;
        end
    end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) 
         RdPtr <= 'd0;
        else if  (~sync_reset_n || ((RdPtr == (BUF_DEPTH-1)) && RdEn))
         RdPtr <= 'd0;
        else if (RdEn) begin
        RdPtr <= RdPtr + 'd1;
        end
    end

`ifdef SOFT_IP
     always @ (posedge clkin) begin
        if (WrEn)
            MemArray[WrPtr] <= DataIn;
    end
`else
    //always @ (posedge clkin) begin
    `XLREG_HARD(clkin, reset_n)
    for (int i = 0; i < BUF_DEPTH; i = i+1)
        MemArray[i] <= 'h0;
    `XLREG_END
    begin
        if (WrEn)
            MemArray[WrPtr] <= DataIn;
    end
`endif



   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
         FifoCntrWr <= 'd0;
        else if (~sync_reset_n) 
         FifoCntrWr <= 'd0;
        else if ((WrEn & RdDeQ) | (~WrEn & ~RdDeQ))begin
        FifoCntrWr <= FifoCntrWr;
        end
    else if (WrEn) begin
        FifoCntrWr <= FifoCntrWr +'d1;
    end
        else begin
        FifoCntrWr <= FifoCntrWr -'d1;
    end
    end

    always_comb begin
        if (~sync_reset_n) 
            FifoCntrRd_nxt = 'd0;
        else if ((RdEn & WriteQ) | (~RdEn & ~WriteQ)) begin
            FifoCntrRd_nxt = FifoCntrRd;
        end
        else if (WriteQ) begin
            FifoCntrRd_nxt = FifoCntrRd +'d1;
        end
        else begin
            FifoCntrRd_nxt = FifoCntrRd -'d1;
        end
    end

   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) 
         FifoCntrRd <= 'd0;
        else 
         FifoCntrRd <= FifoCntrRd_nxt;
    end

   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
            empty_ff <= 1'b1;
        else if (~sync_reset_n)
            empty_ff <= 1'b1;
        else if (LATE_EP_ON_WR) begin
            if((FifoCntrRd==0) || ((FifoCntrRd==1) && RdEn))
                empty_ff <= 1'b1;
            else if(FifoCntrRd>0)
                empty_ff <= 1'b0;
        end else begin
            if (FifoCntrRd_nxt == 0)
                empty_ff <= 1'b1;
            else
                empty_ff <= 1'b0;
        end
   end

   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
            almost_empty_ff <= 1'b1;
        else if (~sync_reset_n)
            almost_empty_ff <= 1'b1;
        else if(FifoCntrRd>(AE_THRESHOLD))
            almost_empty_ff <= 1'b0;
        else if(FifoCntrRd<=(AE_THRESHOLD))
            almost_empty_ff <= 1'b1;
   end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
        full_ff <= 1'b0;
        else if (~sync_reset_n)
        full_ff <= 1'b0;
    else if((FifoCntrWr==(BUF_DEPTH)) || ((FifoCntrWr==(BUF_DEPTH-1)) && WriteQ))
        full_ff <= 1'b1;
    else if(FifoCntrWr<BUF_DEPTH)
        full_ff <= 1'b0;
   end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
        almost_full_ff <= 1'b0;
        else if (~sync_reset_n)
        almost_full_ff <= 1'b0;
    else if(FifoCntrWr>(AF_THRESHOLD))
        almost_full_ff <= 1'b1;
    else if(FifoCntrWr<=(AF_THRESHOLD)) 
        almost_full_ff <= 1'b0;
   end
   endmodule

  module qdma_v5_0_12_GenericFIFO2
  // import cpm6_qdma_v1_0_1_pkg::*;
    #(parameter BUF_DATAWIDTH = 256,
      parameter LATE_EP_ON_WR = 1,
      parameter BUF_WE = BUF_DATAWIDTH/8,
      parameter BUF_DEPTH = 512,
      parameter BUF_PTR = (BUF_DEPTH <=2) ? 1:
                           (BUF_DEPTH <=4)    ? 2:
                           (BUF_DEPTH <=8)    ? 3:
                           (BUF_DEPTH <=16)   ? 4:
                           (BUF_DEPTH <=32)   ? 5:
                           (BUF_DEPTH <=64)   ? 6:
                           (BUF_DEPTH <=128)   ? 7:
                           (BUF_DEPTH <=256)   ? 8:
                           (BUF_DEPTH <=512)   ? 9:
                   (BUF_DEPTH <=1024)   ? 10 : -1,
      parameter AE_THRESHOLD = BUF_DEPTH >> 2,
      parameter AF_THRESHOLD = BUF_DEPTH - 2
    )
    (
        input clkin,
    input reset_n,
    input sync_reset_n,
        input [BUF_DATAWIDTH-1:0] DataIn,
        output [BUF_DATAWIDTH-1:0] DataOut,
    input WrEn,
    input RdEn,
    output almost_empty,
    output almost_full,
    output empty,
    output full
   );
(* ram_style = "DISTRIBUTED" *)
   reg [BUF_DATAWIDTH-1:0] MemArray [BUF_DEPTH-1:0];
   reg [BUF_PTR-1:0] WrPtr;
   reg [BUF_PTR-1:0] RdPtr;
   reg [BUF_PTR:0] FifoCntrWr;
   reg [BUF_PTR:0] FifoCntrRd;
   reg [BUF_PTR:0] FifoCntrRd_nxt;
   wire WriteQ, RdDeQ;
   reg almost_empty_ff;
   reg almost_full_ff;
   reg empty_ff;
   reg full_ff;
   assign WriteQ = WrEn;
   assign RdDeQ = RdEn;
   assign DataOut = MemArray[RdPtr];
   assign almost_empty = almost_empty_ff;
   assign almost_full = almost_full_ff;
   assign empty = empty_ff;
   assign full = full_ff;
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
         WrPtr <= 'd0;
    else if  (~sync_reset_n || ((WrPtr == (BUF_DEPTH-1)) && WrEn))
         WrPtr <= 'd0;
        else if (WrEn) begin
        WrPtr <= WrPtr + 'd1;
        end
    end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) 
         RdPtr <= 'd0;
        else if  (~sync_reset_n || ((RdPtr == (BUF_DEPTH-1)) && RdEn))
         RdPtr <= 'd0;
        else if (RdEn) begin
        RdPtr <= RdPtr + 'd1;
        end
    end

`ifdef SOFT_IP
     always @ (posedge clkin) begin
        if (WrEn)
            MemArray[WrPtr] <= DataIn;
    end
`else
    //always @ (posedge clkin) begin
    `XLREG_HARD(clkin, reset_n)
    for (int i = 0; i < BUF_DEPTH; i = i+1)
        MemArray[i] <= 'h0;
    `XLREG_END
    begin
        if (WrEn)
            MemArray[WrPtr] <= DataIn;
    end
`endif



   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
         FifoCntrWr <= 'd0;
        else if (~sync_reset_n) 
         FifoCntrWr <= 'd0;
        else if ((WrEn & RdDeQ) | (~WrEn & ~RdDeQ))begin
        FifoCntrWr <= FifoCntrWr;
        end
    else if (WrEn) begin
        FifoCntrWr <= FifoCntrWr +'d1;
    end
        else begin
        FifoCntrWr <= FifoCntrWr -'d1;
    end
    end

    always_comb begin
        if (~sync_reset_n) 
            FifoCntrRd_nxt = 'd0;
        else if ((RdEn & WriteQ) | (~RdEn & ~WriteQ)) begin
            FifoCntrRd_nxt = FifoCntrRd;
        end
        else if (WriteQ) begin
            FifoCntrRd_nxt = FifoCntrRd +'d1;
        end
        else begin
            FifoCntrRd_nxt = FifoCntrRd -'d1;
        end
    end

   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) 
         FifoCntrRd <= 'd0;
        else 
         FifoCntrRd <= FifoCntrRd_nxt;
    end

   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
            empty_ff <= 1'b1;
        else if (~sync_reset_n)
            empty_ff <= 1'b1;
        else if (LATE_EP_ON_WR) begin
            if((FifoCntrRd==0) || ((FifoCntrRd==1) && RdEn))
                empty_ff <= 1'b1;
            else if(FifoCntrRd>0)
                empty_ff <= 1'b0;
        end else begin
            if (FifoCntrRd_nxt == 0)
                empty_ff <= 1'b1;
            else
                empty_ff <= 1'b0;
        end
   end

   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
            almost_empty_ff <= 1'b1;
        else if (~sync_reset_n)
            almost_empty_ff <= 1'b1;
        else if(FifoCntrRd>(AE_THRESHOLD))
            almost_empty_ff <= 1'b0;
        else if(FifoCntrRd<=(AE_THRESHOLD))
            almost_empty_ff <= 1'b1;
   end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
        full_ff <= 1'b0;
        else if (~sync_reset_n)
        full_ff <= 1'b0;
    else if(((FifoCntrWr==(BUF_DEPTH)) || ((FifoCntrWr==(BUF_DEPTH-1)) && WriteQ) ) && ~RdEn)
        full_ff <= 1'b1;
    else if(FifoCntrWr<BUF_DEPTH)
        full_ff <= 1'b0;
   end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n)
        almost_full_ff <= 1'b0;
        else if (~sync_reset_n)
        almost_full_ff <= 1'b0;
    else if(FifoCntrWr>(AF_THRESHOLD))
        almost_full_ff <= 1'b1;
    else if(FifoCntrWr<=(AF_THRESHOLD)) 
        almost_full_ff <= 1'b0;
   end
   endmodule

  module qdma_v5_0_12_GenericFIFOAsyncNoHead
  // import cpm6_qdma_v1_0_1_pkg::*;
    #(parameter BUF_DATAWIDTH = 256,
      parameter BUF_WE = BUF_DATAWIDTH/8,
      parameter BUF_DEPTH = 512,
      parameter BUF_PTR = (BUF_DEPTH <=2) ? 1:
                           (BUF_DEPTH <=4)    ? 2:
                           (BUF_DEPTH <=8)    ? 3:
                           (BUF_DEPTH <=16)   ? 4:
                           (BUF_DEPTH <=32)   ? 5:
                           (BUF_DEPTH <=64)   ? 6:
                           (BUF_DEPTH <=128)   ? 7:
                           (BUF_DEPTH <=256)   ? 8:
                           (BUF_DEPTH <=512)   ? 9:
                   (BUF_DEPTH <=1024)   ? 10 : -1
    )
    (
        input clkin,
    input reset_n,
    input clkout,
    input reseto_n,
        input [BUF_DATAWIDTH-1:0] DataIn,
        output [BUF_DATAWIDTH-1:0] DataOut,
    input WrEn,
    input RdEn,
    output almost_empty,
    output almost_full,
    output empty,
    output full
   );
(* ram_style = "DISTRIBUTED" *)
   reg [BUF_DATAWIDTH-1:0] MemArray [BUF_DEPTH-1:0];
   reg [BUF_PTR-1:0] WrPtr;
   reg [BUF_PTR-1:0] RdPtr;
   reg [BUF_PTR:0] FifoCntrWr;
   reg [BUF_PTR:0] FifoCntrRd;
   wire WriteQ, RdDeQ;
   reg almost_empty_ff;
   reg almost_full_ff;
   reg empty_ff;
   reg full_ff;
   assign WriteQ = WrEn;
   assign RdDeQ = RdEn;

   assign DataOut = MemArray[RdPtr];

   assign almost_empty = almost_empty_ff;
   assign almost_full = almost_full_ff;
   assign empty = empty_ff;
   assign full = full_ff;
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
         WrPtr <= 'd0;
    end
        else if (WrEn) begin
        WrPtr <= WrPtr + 'd1;
        end
    end

    `XLREG_XDMA(clkin, reset_n) begin
         if (~reset_n) begin
            RdPtr <= 'd0;
    end else if (RdEn) begin
          RdPtr <= RdPtr + 'd1;
    end
   end

`ifdef SOFT_IP
   always @ (posedge clkin) begin
        if (WrEn)
           MemArray[WrPtr] <= DataIn;
    end
`else
   //always @ (posedge clkin) begin
    `XLREG_HARD(clkin, reset_n)
    for (int i = 0; i < BUF_DEPTH; i = i+1)
        MemArray[i] <= 'h0;
    `XLREG_END
    begin
        if (WrEn)
            MemArray[WrPtr] <= DataIn;
    end
`endif

   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
         FifoCntrWr <= 'd0;
    end
        else if ((WrEn & RdDeQ) | (~WrEn & ~RdDeQ))begin
        FifoCntrWr <= FifoCntrWr;
        end
    else if (WrEn) begin
        FifoCntrWr <= FifoCntrWr +'d1;
    end
        else begin
        FifoCntrWr <= FifoCntrWr -'d1;
    end
    end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
         FifoCntrRd <= 'd0;
    end
        else if ((RdEn & WriteQ) | (~RdEn & ~WriteQ)) begin
        FifoCntrRd <= FifoCntrRd;
        end
    else if (WriteQ) begin
        FifoCntrRd <= FifoCntrRd +'d1;
    end
        else begin
        FifoCntrRd <= FifoCntrRd -'d1;
    end
    end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
        almost_empty_ff <= 1'b1;
        empty_ff <= 1'b1;
    end
    else begin
        if(~WrEn && ((FifoCntrRd==0) || ((FifoCntrRd==1) && RdEn))) begin
            empty_ff <= 1'b1;
        end 
        else if(FifoCntrRd>0) begin
            empty_ff <= 1'b0;
        end

        if((FifoCntrRd==0) || ((FifoCntrRd==1) && RdEn)) begin
            almost_empty_ff <= 1'b1;
        end
        else if(FifoCntrRd>(BUF_DEPTH>>2)) begin
            almost_empty_ff <= 1'b0;
        end
        else if(FifoCntrRd<=(BUF_DEPTH>>2)) begin
            almost_empty_ff <= 1'b1;
        end
    end
   end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
        almost_full_ff <= 1'b0;
        full_ff <= 1'b0;
    end
    else begin
        if((FifoCntrWr==(BUF_DEPTH)) || ((FifoCntrWr==(BUF_DEPTH-1)) && WriteQ)) begin
            full_ff <= 1'b1;
        end     
        else if    (FifoCntrWr<BUF_DEPTH) begin
            full_ff <= 1'b0;
        end

        if((FifoCntrWr==(BUF_DEPTH)) || ((FifoCntrWr==(BUF_DEPTH-1)) && WriteQ)) begin
            almost_full_ff <= 1'b1;
        end
        else if(FifoCntrWr>(BUF_DEPTH-2)) begin
            almost_full_ff <= 1'b1;
        end
        else if(FifoCntrWr<=(BUF_DEPTH-2)) begin
            almost_full_ff <= 1'b0;
        end
    end
   end
   endmodule

  module qdma_v5_0_12_GenericFIFOAsync
  // import cpm6_qdma_v1_0_1_pkg::*;
    #(parameter BUF_DATAWIDTH = 256,
      parameter BUF_WE = BUF_DATAWIDTH/8,
      parameter BUF_DEPTH = 512,
      parameter BUF_PTR = (BUF_DEPTH <=2) ? 1:
                           (BUF_DEPTH <=4)    ? 2:
                           (BUF_DEPTH <=8)    ? 3:
                           (BUF_DEPTH <=16)   ? 4:
                           (BUF_DEPTH <=32)   ? 5:
                           (BUF_DEPTH <=64)   ? 6:
                           (BUF_DEPTH <=128)   ? 7:
                           (BUF_DEPTH <=256)   ? 8:
                           (BUF_DEPTH <=512)   ? 9:
                   (BUF_DEPTH <=1024)   ? 10 : -1,
      parameter AE_THRESHOLD = BUF_DEPTH >> 2,
      parameter AF_THRESHOLD = BUF_DEPTH - 2
    )
    (
        input clkin,
    input reset_n,
    input clkout,
    input reseto_n,
        input [BUF_DATAWIDTH-1:0] DataIn,
        output [BUF_DATAWIDTH-1:0] DataOut,
    input WrEn,
    input RdEn,
    output almost_empty,
    output almost_full,
    output empty,
    output full
   );

(* ram_style = "DISTRIBUTED" *)
   reg [BUF_DATAWIDTH-1:0] MemArray [BUF_DEPTH-1:0];
(* max_fanout = 128 *) reg [BUF_PTR-1:0] WrPtr;
(* max_fanout = 128 *) reg [BUF_PTR-1:0] RdPtr;
   reg [BUF_PTR:0] FifoCntrWr;
   reg [BUF_PTR:0] FifoCntrRd;
   wire WriteQ, RdDeQ;
   reg almost_empty_ff;
   reg almost_full_ff;
   reg empty_ff;
   reg full_ff;
   assign WriteQ = WrEn;
   assign RdDeQ = RdEn;

   reg [BUF_DATAWIDTH-1:0] Head;

   assign almost_empty = almost_empty_ff;
   assign almost_full = almost_full_ff;
   assign empty = empty_ff;
   assign full = full_ff;
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
         WrPtr <= 'd0;
    end
        else if (WrEn) begin
        WrPtr <= WrPtr + 'd1;
        end
    end

    `XLREG_XDMA(clkin, reset_n) begin
           if (~reset_n) begin
             RdPtr <= 'd0;
    end
           else if ((RdEn && (FifoCntrRd>1) ) ||
         (WrEn && (FifoCntrRd==0) ) ||
         (RdEn && WrEn && (FifoCntrRd==1)))begin
               RdPtr <= RdPtr + 'd1;
           end
    end
`ifdef SOFT_IP
   always @(posedge clkin) begin
        if (WrEn)
            MemArray[WrPtr] <= DataIn;
    end
`else
  //always @(posedge clkin) begin
   `XLREG_HARD(clkin, reset_n)
    for (int i = 0; i < BUF_DEPTH; i = i+1)
        MemArray[i] <= 'h0;
   `XLREG_END
    begin
        if (WrEn)
            MemArray[WrPtr] <= DataIn;
    end
`endif    

   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
         FifoCntrWr <= 'd0;
    end
        else if ((WrEn & RdDeQ) | (~WrEn & ~RdDeQ))begin
        FifoCntrWr <= FifoCntrWr;
        end
    else if (WrEn) begin
        FifoCntrWr <= FifoCntrWr +'d1;
    end
        else begin
        FifoCntrWr <= FifoCntrWr -'d1;
    end
    end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
         FifoCntrRd <= 'd0;
    end
        else if ((RdEn & WriteQ) | (~RdEn & ~WriteQ)) begin
        FifoCntrRd <= FifoCntrRd;
        end
    else if (WriteQ) begin
        FifoCntrRd <= FifoCntrRd +'d1;
    end
        else begin
        FifoCntrRd <= FifoCntrRd -'d1;
    end
    end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
        almost_empty_ff <= 1'b1;
        empty_ff <= 1'b1;
    end
    else begin
        if((FifoCntrRd==0) || ((FifoCntrRd==1) && RdEn)) begin
            empty_ff <= 1'b1;
        end 
        else if(FifoCntrRd>0) begin
            empty_ff <= 1'b0;
        end

        if((FifoCntrRd==0) || ((FifoCntrRd==1) && RdEn)) begin
            almost_empty_ff <= 1'b1;
        end
        else if(FifoCntrRd>(AE_THRESHOLD)) begin
            almost_empty_ff <= 1'b0;
        end
        else if(FifoCntrRd<=(AE_THRESHOLD)) begin
            almost_empty_ff <= 1'b1;
        end
    end
   end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
        almost_full_ff <= 1'b0;
        full_ff <= 1'b0;
    end
    else begin
        if((FifoCntrWr==(BUF_DEPTH)) || ((FifoCntrWr==(BUF_DEPTH-1)) && WriteQ)) begin
            full_ff <= 1'b1;
        end     
        else if    (FifoCntrWr<BUF_DEPTH) begin
            full_ff <= 1'b0;
        end

        if((FifoCntrWr==(BUF_DEPTH)) || ((FifoCntrWr==(BUF_DEPTH-1)) && WriteQ)) begin
            almost_full_ff <= 1'b1;
        end
        else if(FifoCntrWr>(AF_THRESHOLD)) begin
            almost_full_ff <= 1'b1;
        end
        else if(FifoCntrWr<=(AF_THRESHOLD)) begin
            almost_full_ff <= 1'b0;
        end
    end
   end

   `XLREG_XDMA(clkin, reset_n) begin
          if (~reset_n) begin
        Head <= 1'b0;
    end 
    else begin
        if ((WrEn && (FifoCntrRd == 0)) || (WrEn && RdEn && (FifoCntrRd == 1)))
            Head <= DataIn;
        else if (RdEn || (FifoCntrRd == 0))
               Head <= MemArray[RdPtr];
    end
    end
    assign DataOut = Head;

   endmodule

  module qdma_v5_0_12_GenericFIFOHead
  // import cpm6_qdma_v1_0_1_pkg::*;
    #(parameter BUF_DATAWIDTH = 256,
      parameter NP2_SIZE      = 0,    // Non power of 2 size
      parameter BUF_WE = BUF_DATAWIDTH/8,
      parameter BUF_DEPTH = 512,
      parameter BUF_PTR = (BUF_DEPTH <=2) ? 1:
                           (BUF_DEPTH <=4)    ? 2:
                           (BUF_DEPTH <=8)    ? 3:
                           (BUF_DEPTH <=16)   ? 4:
                           (BUF_DEPTH <=32)   ? 5:
                           (BUF_DEPTH <=64)   ? 6:
                           (BUF_DEPTH <=128)   ? 7:
                           (BUF_DEPTH <=256)   ? 8:
                           (BUF_DEPTH <=512)   ? 9:
                   (BUF_DEPTH <=1024)   ? 10 : -1,
      parameter AE_THRESHOLD = BUF_DEPTH >> 2,
      parameter AF_THRESHOLD = BUF_DEPTH - 2
    )
    (
        input clkin,
    input reset_n,
    input sync_reset_n,
    input [BUF_DATAWIDTH-1:0] DataIn,
    output [BUF_DATAWIDTH-1:0] DataOut,
    input WrEn,
    input WrAlloc,
    input RdEn,
    output almost_empty,
    output almost_full,
    output empty,
    output full
   );

(* ram_style = "DISTRIBUTED" *)
   reg [BUF_DATAWIDTH-1:0] MemArray [BUF_DEPTH-1:0];
      reg [BUF_DATAWIDTH-1:0] MemArrayRd;
   reg [BUF_PTR-1:0] WrPtr;
   reg [BUF_PTR-1:0] RdPtr;
   reg [BUF_PTR:0] FifoCntrWr;
   reg [BUF_PTR:0] FifoCntrRd;
   wire WriteQ, RdDeQ;
   reg almost_empty_ff;
   reg almost_full_ff;
   reg empty_ff;
   reg full_ff;
   assign WriteQ = WrEn;
   assign RdDeQ = RdEn;

   reg [BUF_DATAWIDTH-1:0] Head;

   assign almost_empty = almost_empty_ff;
   assign almost_full = almost_full_ff;
   assign empty = empty_ff;
   assign full = full_ff;

   `XLREG_XDMA(clkin, reset_n) begin
       if (~reset_n) begin
           WrPtr <= 'd0;
       end
       else if (~sync_reset_n)
           WrPtr <= 'd0;
       else if (WrEn) begin
           if (NP2_SIZE && (WrPtr == (BUF_DEPTH-1)))
               WrPtr <= '0;
           else
               WrPtr <= WrPtr + 'd1;
       end
    end

   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
            RdPtr <= 'd0;
        end
        else if (~sync_reset_n)
            RdPtr <= 'd0;
        else if ((RdEn && (FifoCntrRd>1) ) || (WrEn && (FifoCntrRd==0) ) || (RdEn && WrEn && (FifoCntrRd==1)))
        begin
            if (NP2_SIZE && (RdPtr == (BUF_DEPTH-1)))
                RdPtr <= '0;
            else
                RdPtr <= RdPtr + 'd1;
        end
    end


`ifdef SOFT_IP
   always @(posedge clkin) begin
        if (WrEn)
            MemArray[WrPtr] <= DataIn;
    end
`else
   //always @(posedge clkin) begin
   `XLREG_HARD(clkin, reset_n)
    for (int i = 0; i < BUF_DEPTH; i = i+1)
        MemArray[i] <= 'h0;
   `XLREG_END
    begin
        if (WrEn)
            MemArray[WrPtr] <= DataIn;
    end
`endif
    
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
         FifoCntrWr <= 'd0;
    end
    else if (~sync_reset_n)
         FifoCntrWr <= 'd0;
        else if ((WrAlloc & RdDeQ) | (~WrAlloc & ~RdDeQ))begin
        FifoCntrWr <= FifoCntrWr;
        end
    else if (WrAlloc) begin
        FifoCntrWr <= FifoCntrWr +'d1;
    end
        else begin
        FifoCntrWr <= FifoCntrWr -'d1;
    end
    end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
         FifoCntrRd <= 'd0;
    end
        else if (~sync_reset_n)
         FifoCntrRd <= 'd0;
        else if ((RdEn & WriteQ) | (~RdEn & ~WriteQ)) begin
        FifoCntrRd <= FifoCntrRd;
        end
    else if (WriteQ) begin
        FifoCntrRd <= FifoCntrRd +'d1;
    end
        else begin
        FifoCntrRd <= FifoCntrRd -'d1;
    end
    end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
        almost_empty_ff <= 1'b1;
        empty_ff <= 1'b1;
    end
        else if (~sync_reset_n) begin
        almost_empty_ff <= 1'b1;
        empty_ff <= 1'b1;
    end
    else begin
        if((FifoCntrRd==0) || ((FifoCntrRd==1) && RdEn)) begin
            empty_ff <= 1'b1;
        end 
        else if(FifoCntrRd>0) begin
            empty_ff <= 1'b0;
        end

        if((FifoCntrRd==0) || ((FifoCntrRd==1) && RdEn)) begin
            almost_empty_ff <= 1'b1;
        end
        else if(FifoCntrRd>(AE_THRESHOLD)) begin
            almost_empty_ff <= 1'b0;
        end
        else if(FifoCntrRd<=(AE_THRESHOLD)) begin
            almost_empty_ff <= 1'b1;
        end
    end
   end
   `XLREG_XDMA(clkin, reset_n) begin
        if (~reset_n) begin
        almost_full_ff <= 1'b0;
        full_ff <= 1'b0;
    end
        else if (~sync_reset_n) begin
        almost_full_ff <= 1'b0;
        full_ff <= 1'b0;
    end
    else begin
        if((FifoCntrWr>=(BUF_DEPTH+1)) || ((FifoCntrWr==(BUF_DEPTH)) && WrAlloc)) begin
            full_ff <= 1'b1;
        end     
        else if    (FifoCntrWr<(BUF_DEPTH+1)) begin
            full_ff <= 1'b0;
        end

        if((FifoCntrWr>=(BUF_DEPTH+1)) || ((FifoCntrWr==(BUF_DEPTH)) && WrAlloc)) begin
            almost_full_ff <= 1'b1;
        end
        else if((FifoCntrWr>AF_THRESHOLD) || ((FifoCntrWr == AF_THRESHOLD) && WrAlloc)) begin
            almost_full_ff <= 1'b1;
        end
        else if(FifoCntrWr<=(AF_THRESHOLD)) begin
            almost_full_ff <= 1'b0;
        end
    end
   end

assign MemArrayRd = MemArray[RdPtr];
   `XLREG_XDMA(clkin, reset_n) begin
          if (~reset_n) begin
        Head <= 1'b0;
    end 
    else if (~sync_reset_n) begin
        Head <= 1'b0;
    end
    else begin
        if ((WrEn && (FifoCntrRd == 0)) || (WrEn && RdEn && (FifoCntrRd == 1)))
            Head <= DataIn;
        else if (RdEn || (FifoCntrRd == 0))
            Head <= MemArrayRd;
    end
    end
    assign DataOut = Head;

   endmodule

  module qdma_v5_0_12_GenericFIFOHead2
    // import cpm6_qdma_v1_0_1_pkg::*;
    #(parameter BUF_DATAWIDTH = 256,
      parameter TCQ = 0,
      parameter BUF_WE = BUF_DATAWIDTH/8,
      parameter BUF_DEPTH = 512,
      parameter BUF_PTR = (BUF_DEPTH <=2) ? 1:
                           (BUF_DEPTH <=4)    ? 2:
                           (BUF_DEPTH <=8)    ? 3:
                           (BUF_DEPTH <=16)   ? 4:
                           (BUF_DEPTH <=32)   ? 5:
                           (BUF_DEPTH <=64)   ? 6:
                           (BUF_DEPTH <=128)   ? 7:
                           (BUF_DEPTH <=256)   ? 8:
                           (BUF_DEPTH <=512)   ? 9:
                   (BUF_DEPTH <=1024)   ? 10 : -1,
      parameter AE_THRESHOLD = BUF_DEPTH >> 2,
      parameter AF_THRESHOLD = BUF_DEPTH - 2
    )
    (
    input clkin,
    input reset_n,
    input sync_reset_n,
    input [BUF_DATAWIDTH-1:0] DataIn,
    output [BUF_DATAWIDTH-1:0] DataOut,
    input WrEn,
    input RdEn,
    output almost_empty,
    output almost_full,
    output empty,
    output full
   );

(* ram_style = "DISTRIBUTED" *)
   reg [BUF_DATAWIDTH-1:0] MemArray [BUF_DEPTH-1:0];
   reg [BUF_DATAWIDTH-1:0] MemRd;
   reg [BUF_PTR-1:0] WrPtr;
   reg [BUF_PTR-1:0] RdPtr;
   reg [BUF_PTR:0] FifoCntrWr;
   reg [BUF_PTR:0] FifoCntrRd;
   wire WriteQ, RdDeQ;
   reg almost_empty_ff;
   reg almost_full_ff;
   reg empty_ff;
   reg full_ff;
   assign WriteQ = WrEn;
   assign RdDeQ = RdEn;

   reg [BUF_DATAWIDTH-1:0] Head;

   assign almost_empty = almost_empty_ff;
   assign almost_full = almost_full_ff;
   assign empty = empty_ff;
   assign full = full_ff;

   `XLREG_XDMA (clkin, reset_n)
    begin
        if (~reset_n)
            WrPtr <= #(TCQ) 'd0;
        else if (~sync_reset_n)
            WrPtr <= #(TCQ) 'd0;
        else if (WrEn && (BUF_DEPTH > 1)) begin
            WrPtr <= #(TCQ) WrPtr + 'd1;
        end
    end

   `XLREG_XDMA (clkin, reset_n)
    begin
        if (~reset_n)
            RdPtr <= #(TCQ) 'd0;
        else if (~sync_reset_n) begin
            RdPtr <= #(TCQ) 'd0;
        end
        else if (BUF_DEPTH > 1)
        begin
            if ((RdEn && (FifoCntrRd>1) ) ||
                (WrEn && (FifoCntrRd==0) ) ||
                (RdEn && WrEn && (FifoCntrRd==1)))begin
                   RdPtr <= #(TCQ) RdPtr + 'd1;
            end
        end
    end
    
`ifdef SOFT_IP
   always @(posedge clkin) begin
        if (WrEn)
            MemArray[WrPtr] <= #(TCQ) DataIn;
    end
`else   
      //always @(posedge clkin) begin
    `XLREG_HARD(clkin, reset_n)
     for (int i = 0; i < BUF_DEPTH; i = i+1)
         MemArray[i] <= 'h0;
    `XLREG_END
     begin
         if (WrEn)
             MemArray[WrPtr] <= #(TCQ) DataIn;
     end
`endif
     
   `XLREG_XDMA (clkin, reset_n)
    begin
        if (~reset_n) 
            FifoCntrWr <= #(TCQ) 'd0;
        else if (~sync_reset_n)
            FifoCntrWr <= #(TCQ) 'd0;
        else if ((WrEn & RdDeQ) | (~WrEn & ~RdDeQ))begin
            FifoCntrWr <= #(TCQ) FifoCntrWr;
        end
        else if (WrEn) begin
            FifoCntrWr <= #(TCQ) FifoCntrWr +'d1;
        end
        else begin
            FifoCntrWr <= #(TCQ) FifoCntrWr -'d1;
        end
    end
   `XLREG_XDMA (clkin, reset_n)
    begin
        if (~reset_n) begin
         FifoCntrRd <= #(TCQ) 'd0;
        end
        else if (~sync_reset_n) begin
         FifoCntrRd <= #(TCQ) 'd0;
        end
        else if ((RdEn & WriteQ) | (~RdEn & ~WriteQ)) begin
        FifoCntrRd <= #(TCQ) FifoCntrRd;
        end
    else if (WriteQ) begin
        FifoCntrRd <= #(TCQ) FifoCntrRd +'d1;
    end
        else begin
        FifoCntrRd <= #(TCQ) FifoCntrRd -'d1;
    end
    end
   `XLREG_XDMA (clkin, reset_n)
    begin
        if (~reset_n) begin
        almost_empty_ff <= #(TCQ) 1'b1;
        empty_ff <= #(TCQ) 1'b1;
    end
       else if (~sync_reset_n) begin
        almost_empty_ff <= #(TCQ) 1'b1;
        empty_ff <= #(TCQ) 1'b1;
    end
    else begin
        if(((FifoCntrRd==0) && ~WrEn) || ((FifoCntrRd==1) && RdEn && ~WrEn)) begin
            empty_ff <= #(TCQ) 1'b1;
        end 
        else  begin
            empty_ff <= #(TCQ) 1'b0;
        end

        if((FifoCntrRd==0) || ((FifoCntrRd==1) && RdEn && ~WrEn)) begin
            almost_empty_ff <= #(TCQ) 1'b1;
        end
        else if(FifoCntrRd>(AE_THRESHOLD)) begin
            almost_empty_ff <= #(TCQ) 1'b0;
        end
        else if(FifoCntrRd<=(AE_THRESHOLD)) begin
            almost_empty_ff <= #(TCQ) 1'b1;
        end
    end
   end

   `XLREG_XDMA (clkin, reset_n)
    begin
        if (~reset_n) begin
        almost_full_ff <= #(TCQ) 1'b0;
        full_ff <= #(TCQ) 1'b0;
    end
        else if (~sync_reset_n) begin
        almost_full_ff <= #(TCQ) 1'b0;
        full_ff <= #(TCQ) 1'b0;
    end
    else begin
        if(((FifoCntrWr==(BUF_DEPTH+1)) && (~RdEn || WriteQ)) || ((FifoCntrWr==BUF_DEPTH) && WriteQ && ~RdEn)) begin
            full_ff <= #(TCQ) 1'b1;
        end     
        else 
        begin
            full_ff <= #(TCQ) 1'b0;
        end

        if((FifoCntrWr>(BUF_DEPTH)) || ((FifoCntrWr==BUF_DEPTH) && WriteQ)) begin
            almost_full_ff <= #(TCQ) 1'b1;
        end
        else if((FifoCntrWr>AF_THRESHOLD) || ((FifoCntrWr == AF_THRESHOLD) && WriteQ)) begin
            almost_full_ff <= #(TCQ) 1'b1;
        end
        else if(FifoCntrWr<=(AF_THRESHOLD)) begin
            almost_full_ff <= #(TCQ) 1'b0;
        end
    end
   end

assign MemRd = MemArray[RdPtr];

   `XLREG_XDMA(clkin, reset_n) begin
       if (~reset_n) begin
           Head <= #(TCQ) 1'b0;
       end 
       else if (~sync_reset_n) begin
           Head <= #(TCQ) 1'b0;
       end 
       else begin
       if ((WrEn && (FifoCntrRd == 0)) || (WrEn && RdEn && (FifoCntrRd == 1)))
           Head <= #(TCQ) DataIn;
       else if (RdEn || (FifoCntrRd == 0))
           Head <= #(TCQ) MemRd;
    end
    end
    assign DataOut = Head;

   endmodule

/*
module GenericBRAMFIFOHead #(
    parameter TCQ = 0,
    parameter BUF_DATAWIDTH = 256,
    parameter BUF_WE = BUF_DATAWIDTH/8,
    parameter BUF_DEPTH = 512,
    parameter BUF_PTR = (BUF_DEPTH <=2) ? 1:
                           (BUF_DEPTH <=4)    ? 2:
                           (BUF_DEPTH <=8)    ? 3:
                           (BUF_DEPTH <=16)   ? 4:
                           (BUF_DEPTH <=32)   ? 5:
                           (BUF_DEPTH <=64)   ? 6:
                           (BUF_DEPTH <=128)   ? 7:
                           (BUF_DEPTH <=256)   ? 8:
                           (BUF_DEPTH <=512)   ? 9:
                   (BUF_DEPTH <=1024)   ? 10 : -1,
      parameter AE_THRESHOLD = BUF_DEPTH >> 2,
      parameter AF_THRESHOLD = BUF_DEPTH - 2
    )
    (
        input                 clk,
    input                rst,
    input                srst,
        input [BUF_DATAWIDTH-1:0]    DataIn,
        output [BUF_DATAWIDTH-1:0]    DataOut,
    input                WrEn,
    input                RdEn,
    output                almost_empty,
    output                almost_full,
    output                empty,
    output                full
   );

(* ram_style = "BLOCK" *)
reg [BUF_DATAWIDTH-1:0]    MemArray [BUF_DEPTH-1:0];

reg [BUF_PTR-1:0]        WrPtr;
reg [BUF_PTR-1:0]        WrPtr_nxt;

reg [BUF_PTR-1:0]        RdPtr_nxt;
reg [BUF_PTR-1:0]        RdPtr;

reg [BUF_PTR:0]            FifoCntr_nxt;
reg [BUF_PTR:0]            FifoCntr;

reg                almost_empty_nxt;
reg                almost_empty_ff;
reg                almost_full_nxt;
reg                almost_full_ff;
reg                empty_nxt;
reg                empty_ff;
reg                full_nxt;
reg                full_ff;

wire [BUF_DATAWIDTH-1:0]        Head_nxt;
reg [BUF_DATAWIDTH-1:0]        Head;

assign almost_empty    = almost_empty_ff;
assign almost_full    = almost_full_ff;
assign empty        = empty_ff;
assign full        = full_ff;

always @(*) begin
    WrPtr_nxt = WrPtr;
    if (srst)
        WrPtr_nxt = 'h0;
    else if (WrEn)
        WrPtr_nxt = WrPtr + 'd1;
end
`XSRREG_XDMA(clk, ~rst, WrPtr, WrPtr_nxt, 'h0)

always @(*) begin
    RdPtr_nxt = RdPtr;
           if (srst) begin
             RdPtr_nxt = 'h0;
    end
           else if ((RdEn && (FifoCntr > 1) ) ||
         (WrEn && (FifoCntr == 0) ) ||
         (RdEn && WrEn && (FifoCntr == 1)))begin
               RdPtr_nxt = RdPtr + 'd1;
           end
    end
`XSRREG_XDMA(clk, ~rst, RdPtr, RdPtr_nxt, 'h0)

//always @(posedge clk) begin
   `XLREG_HARD(clkin, reset_n)
    for (int i = 0; i < BUF_DEPTH; i = i+1)
        MemArray[i] <= 'h0;
   `XLREG_END
    begin
        if (WrEn)
            MemArray[WrPtr] <= DataIn;
    end

always @(*) begin
    FifoCntr_nxt = FifoCntr;
        if (srst)
        FifoCntr_nxt = 'd0;
    else if ((RdEn & WrEn) | (~RdEn & ~WrEn)) 
        FifoCntr_nxt = FifoCntr;
    else if (WrEn) 
        FifoCntr_nxt = FifoCntr +'d1;
    else 
        FifoCntr_nxt = FifoCntr -'d1;
end
`XSRREG_XDMA(clk, ~rst, FifoCntr, FifoCntr_nxt, 'h0)

always @(*) begin
    almost_empty_nxt    = almost_empty_ff;
    empty_nxt        = empty_ff;

        if (srst) begin
        almost_empty_nxt= 1'b1;
        empty_nxt    = 1'b1;
    end
    else begin
        if((FifoCntr==0) || ((FifoCntr==1) && RdEn))
            empty_nxt = 1'b1;
        else if(FifoCntr > 0) 
            empty_nxt = 1'b0;

        if((FifoCntr==0) || ((FifoCntr==1) && RdEn))
            almost_empty_nxt = 1'b1;
        else if(FifoCntr > AE_THRESHOLD)
            almost_empty_nxt = 1'b0;
        else if(FifoCntr <= AE_THRESHOLD)
            almost_empty_nxt = 1'b1;
    end
end
`XSRREG_XDMA(clk, ~rst, almost_empty_ff, almost_empty_nxt, 'h0)
`XSRREG_XDMA(clk, ~rst, empty_ff, empty_nxt, 'h0)


always @(*) begin
    full_nxt = full_ff;
    almost_full_nxt = almost_full_ff;
        if (srst) begin
        almost_full_nxt    = 1'b0;
        full_nxt     = 1'b0;
    end
    else begin
        if((FifoCntr==(BUF_DEPTH)) || ((FifoCntr==(BUF_DEPTH-1)) && WrEn)) 
            full_nxt = 1'b1;
        else if    (FifoCntr<BUF_DEPTH) 
            full_nxt = 1'b0;

        if((FifoCntr==(BUF_DEPTH)) || ((FifoCntr==(BUF_DEPTH-1)) && WrEn))
            almost_full_nxt = 1'b1;
        else if(FifoCntr > AF_THRESHOLD) 
            almost_full_nxt = 1'b1;
        else if(FifoCntr <= AF_THRESHOLD) 
            almost_full_nxt = 1'b0;
    end
end
`XSRREG_XDMA(clk, ~rst, almost_full_ff, almost_full_nxt, 'h0)
`XSRREG_XDMA(clk, ~rst, full_ff, full_nxt, 'h0)

assign    Head_nxt =     (srst) ? 'h0 :
            ((WrEn && (FifoCntr == 0)) || (WrEn && RdEn && (FifoCntr == 1))) ?  DataIn : 
            (RdEn || (FifoCntr == 0)) ?  MemArray[RdPtr] :
                Head;

`XSRREG_XDMA(clk, ~rst, Head, Head_nxt, 'h0)
assign DataOut = Head;

endmodule
*/
`endif // AXI_BRIDGE_VH
