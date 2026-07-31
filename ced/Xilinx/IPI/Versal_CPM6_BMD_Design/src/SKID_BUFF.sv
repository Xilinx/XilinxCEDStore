// Circular skid buffer with two registers and ajustable data width
module SKID_BUFF #(
    parameter int                       SKD_DATA_WIDTH
)(
    input  logic                        clk,
    input  logic                        rst_n,

    input  logic [SKD_DATA_WIDTH-1:0]   s_data,
    input  logic                        s_valid,
    output logic                        s_ready,

    output logic [SKD_DATA_WIDTH-1:0]   m_data,
    output logic                        m_valid,
    input  logic                        m_ready
);

logic [1:0]                     regs_valid,     next_regs_valid;
logic                           regs_wr_ptr,    next_regs_wr_ptr;
logic                           regs_rd_ptr,    next_regs_rd_ptr;
logic [1:0][SKD_DATA_WIDTH-1:0] regs,           next_regs;

assign s_ready = !(&regs_valid);

assign m_data  = regs[regs_rd_ptr];
assign m_valid = regs_valid[regs_rd_ptr];

always @(posedge clk) begin
    if (!rst_n) begin
        regs_valid      <= '0;
        regs_wr_ptr     <= '0;
        regs_rd_ptr     <= '0;
        regs            <= '0;
    end else begin
        regs_valid      <= next_regs_valid;
        regs_wr_ptr     <= next_regs_wr_ptr;
        regs_rd_ptr     <= next_regs_rd_ptr;
        regs            <= next_regs;
    end
end

always_comb begin
    next_regs_valid     = regs_valid;
    next_regs_wr_ptr    = regs_wr_ptr;
    next_regs_rd_ptr    = regs_rd_ptr;
    next_regs           = regs;

    if (s_valid && !regs_valid[regs_wr_ptr]) begin
        next_regs_valid[regs_wr_ptr] = 1'b1;
        next_regs[regs_wr_ptr]       = s_data;
        next_regs_wr_ptr             = !regs_wr_ptr;
    end

    if (m_ready && regs_valid[regs_rd_ptr]) begin
        next_regs_valid[regs_rd_ptr] = 1'b0;
        next_regs_rd_ptr             = !regs_rd_ptr;
    end
end

endmodule
