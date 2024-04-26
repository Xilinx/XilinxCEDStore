`ifndef AXIDMA_FIFO_VH
`define AXIDMA_FIFO_VH
`include "qdma_mailbox_axi4mm_axi_bridge.vh"

  module pcie_qdma_mailbox_v1_0_3_GenericFIFO
    #(parameter BUF_DATAWIDTH = 256,
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

`endif // AXI_BRIDGE_VH
