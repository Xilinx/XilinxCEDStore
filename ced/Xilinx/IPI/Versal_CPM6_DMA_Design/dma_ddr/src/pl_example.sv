////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
////////////////////////////////////////////////////////////////////////
module pl_example(
    input         clk,
    input         reset_n,

    // m_pl_axil_0 interface (Master AXI) - NOT USED
    // input  [11:0]  m_pl_axil_awuser,
    // input  [63:0]  m_pl_axil_awaddr,
    // input  [2:0]   m_pl_axil_awprot,
    // input          m_pl_axil_awvalid,
    // output logic   m_pl_axil_awready,
    // input  [31:0]  m_pl_axil_wdata,
    // input  [3:0]   m_pl_axil_wstrb,
    // input          m_pl_axil_wvalid,
    // output logic   m_pl_axil_wready,
    // output logic [1:0] m_pl_axil_bresp,
    // output logic   m_pl_axil_bvalid,
    // input          m_pl_axil_bready,
    // input  [11:0]  m_pl_axil_aruser,
    // input  [63:0]  m_pl_axil_araddr,
    // input  [2:0]   m_pl_axil_arprot,
    // input          m_pl_axil_arvalid,
    // output logic   m_pl_axil_arready,
    // output logic [31:0] m_pl_axil_rdata,
    // output logic [1:0]  m_pl_axil_rresp,
    // output logic        m_pl_axil_rvalid,
    // input               m_pl_axil_rready,

    // DMA interrupt bitmap, one bit per channel.
    input  [127:0] dma_irq,

    // MSI-X interface.
    output logic [10:0] pcie_msix_vector_num,
    output logic [2:0]  pcie_msix_func_num,
    output logic        pcie_msix_vfunc_active,
    output logic [7:0]  pcie_msix_vfunc_num,
    output logic [1:0]  pcie_msix_operation,
    output logic        pcie_msix_req,
    input               pcie_msix_error,
    input               pcie_msix_grant
);

localparam logic [1:0]
    SM_INT_IDLE = 2'b00,
    SM_INT_REQ  = 2'b01;

logic [1:0] sm_int;
logic [6:0] chn_num;

logic [6:0] grant_chn;
logic       grant_vld;
logic       rr_advance;
logic [6:0] c2h_chn_num, h2c_chn_num;
logic       c2h_chn_vld, h2c_chn_vld;

// One-shot interrupt gating: prevents re-sending while dma_irq stays high
// after the host has been notified but not yet cleared the IRQ bit.
logic [127:0] irq_sent_latched; // set on grant, cleared when dma_irq bit drops
logic [127:0] dma_irq_eligible; // dma_irq masked by irq_sent_latched

// Re-arm a channel automatically once its dma_irq bit drops (host cleared it).
assign dma_irq_eligible = dma_irq & ~irq_sent_latched;

assign c2h_chn_num = (chn_num <= 7'd63) ? chn_num : 7'd0;
assign c2h_chn_vld = (chn_num <= 7'd63);
assign h2c_chn_num = (chn_num > 7'd63) ? (chn_num - 7'd64) : 7'd0;
assign h2c_chn_vld = (chn_num > 7'd63);

assign pcie_msix_vector_num = c2h_chn_vld ? {c2h_chn_num, 2'b00} :
                              h2c_chn_vld ? ({h2c_chn_num, 2'b00} + 11'd2) :
                              11'h0;
assign pcie_msix_operation    = 2'b00;
assign pcie_msix_func_num     = 3'h0;
assign pcie_msix_vfunc_active = 1'b0;
assign pcie_msix_vfunc_num    = 8'h00;

// AXI-Lite slave instantiation - NOT USED (debug interface disabled)
// axil_slave u_axil_slave (
//     .clk               (clk),
//     .reset_n           (reset_n),
//     .s_axil_awaddr     (m_pl_axil_awaddr),
//     .s_axil_awprot     (m_pl_axil_awprot),
//     .s_axil_awvalid    (m_pl_axil_awvalid),
//     .s_axil_awready    (m_pl_axil_awready),
//     .s_axil_wdata      (m_pl_axil_wdata),
//     .s_axil_wstrb      (m_pl_axil_wstrb),
//     .s_axil_wvalid     (m_pl_axil_wvalid),
//     .s_axil_wready     (m_pl_axil_wready),
//     .s_axil_bresp      (m_pl_axil_bresp),
//     .s_axil_bvalid     (m_pl_axil_bvalid),
//     .s_axil_bready     (m_pl_axil_bready),
//     .s_axil_araddr     (m_pl_axil_araddr),
//     .s_axil_arprot     (m_pl_axil_arprot),
//     .s_axil_arvalid    (m_pl_axil_arvalid),
//     .s_axil_arready    (m_pl_axil_arready),
//     .s_axil_rdata      (m_pl_axil_rdata),
//     .s_axil_rresp      (m_pl_axil_rresp),
//     .s_axil_rvalid     (m_pl_axil_rvalid),
//     .s_axil_rready     (m_pl_axil_rready),
//     .s_axil_awuser     (m_pl_axil_awuser),
//     .s_axil_aruser     (m_pl_axil_aruser),
//     .dma_irq           (dma_irq),
//     .h2c_chn_num      (h2c_chn_num),
//     .c2h_chn_num      (c2h_chn_num),
//     .irq_status        (irq_status),
//     .msix_dbg_snapshot (msix_dbg_snapshot),
//     .msix_dbg_events   (msix_dbg_events),
//     .dma_irq_eligible0 (dma_irq_eligible0)
// );

// One-shot latch: set when MSI-X grant fires (not on error — interrupt not delivered).
// Auto-clears when dma_irq bit drops (host has cleared the interrupt).
always_ff @(posedge clk) begin
    if (!reset_n) begin
        irq_sent_latched <= '0;
    end else begin
        // Auto-clear bits where the DMA engine has already dropped the IRQ
        irq_sent_latched <= irq_sent_latched & dma_irq;
        // Set bit for the channel that just received its MSI-X grant
        if ((sm_int == SM_INT_REQ) && pcie_msix_grant)
            irq_sent_latched[chn_num] <= 1'b1;
    end
end

always_ff @(posedge clk) begin
    if (!reset_n) begin
        sm_int        <= SM_INT_IDLE;
        chn_num       <= 7'd0;
        pcie_msix_req <= 1'b0;
    end else begin
        case (sm_int)
            SM_INT_IDLE: begin
                pcie_msix_req <= 1'b0;
                if (grant_vld && dma_irq_eligible[grant_chn]) begin
                    chn_num       <= grant_chn;
                    pcie_msix_req <= 1'b1;
                    sm_int        <= SM_INT_REQ;
                end
            end

            SM_INT_REQ: begin
                if (pcie_msix_grant || pcie_msix_error) begin
                    pcie_msix_req <= 1'b0;
                    sm_int        <= SM_INT_IDLE;
                end
            end

            default: sm_int <= SM_INT_IDLE;
        endcase
    end
end

assign rr_advance = (sm_int == SM_INT_REQ) && (pcie_msix_grant || pcie_msix_error);

rr_arbiter_128 u_rr_arbiter (
    .clk        (clk),
    .reset_n    (reset_n),
    .req        (dma_irq_eligible),
    .advance    (rr_advance),
    .served_chn (chn_num),
    .grant_chn  (grant_chn),
    .grant_vld  (grant_vld)
);

endmodule
