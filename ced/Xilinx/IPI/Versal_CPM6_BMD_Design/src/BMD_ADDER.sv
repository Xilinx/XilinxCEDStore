module BMD_ADDER #(
    parameter int WIDTH_A = 64,           // Width of first operand
    parameter int WIDTH_B = 64,           // Width of second operand

    parameter int MAX_WIDTH = (WIDTH_A > WIDTH_B) ? WIDTH_A : WIDTH_B,
    parameter int RESULT_WIDTH = MAX_WIDTH + 1,

    parameter int LATENCY = 4             // Number of pipeline stages
)(
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic [WIDTH_A-1:0]      a_in,
    input  logic [WIDTH_B-1:0]      b_in,
    input  logic                    valid_in,

    output logic [RESULT_WIDTH-1:0] sum_out,
    output logic                    valid_out,

    input  logic                    halt_i
);
    // Ensure at least one stage
    localparam int ACTUAL_LATENCY = (LATENCY < 1) ? 1 : LATENCY;

    // Calculate bits per stage (rounded up)
    localparam int BITS_PER_STAGE = (MAX_WIDTH + ACTUAL_LATENCY - 1) / ACTUAL_LATENCY;

    // Pipeline registers
    logic [ACTUAL_LATENCY:0][MAX_WIDTH-1:0]     a_r ;  // Zero-extended a
    logic [ACTUAL_LATENCY:0][MAX_WIDTH-1:0]     b_r ;  // Zero-extended b
    logic [ACTUAL_LATENCY:0][RESULT_WIDTH-1:0]  sum_r;
    logic [ACTUAL_LATENCY:0]                    valid_r;
    logic [ACTUAL_LATENCY-2:0]                  carry_r;

    // Input connections with zero extension
    always_comb begin
        a_r[0] = '0;
        b_r[0] = '0;
        a_r[0][WIDTH_A-1:0] = a_in;
        b_r[0][WIDTH_B-1:0] = b_in;
    end

    assign valid_r[0] = valid_in;
    assign sum_r[0] = '0;

    // Generate adder pipeline stages
    genvar i;
    generate
        for (i = 0; i < ACTUAL_LATENCY; i++) begin : g_adder_stages
            // Calculate bit range for this stage
            localparam int START_BIT = i * BITS_PER_STAGE;
            localparam int END_BIT = ((i+1) * BITS_PER_STAGE > MAX_WIDTH) ?
                                     MAX_WIDTH-1 : (i+1) * BITS_PER_STAGE - 1;
            localparam int STAGE_WIDTH = END_BIT - START_BIT + 1;

            // Intermediate calculation signals
            logic [STAGE_WIDTH:0] segment_sum;

            // Combinational logic for addition
            always_comb begin
                if (START_BIT == 0) begin
                    // First stage (no incoming carry)
                    segment_sum = {1'b0, a_r[i][END_BIT:START_BIT]} +
                                 {1'b0, b_r[i][END_BIT:START_BIT]};
                end else begin
                    // Later stages (with incoming carry)
                    segment_sum = {1'b0, a_r[i][END_BIT:START_BIT]} +
                                 {1'b0, b_r[i][END_BIT:START_BIT]} +
                                 33'(carry_r[i-1]);
                end
            end

            // Register the results
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    a_r[i+1] <= '0;
                    b_r[i+1] <= '0;
                    sum_r[i+1] <= '0;
                    valid_r[i+1] <= 1'b0;
                    if (i < ACTUAL_LATENCY-1) carry_r[i] <= 1'b0;
                end else begin
                    if (!halt_i) begin
                        // Pass through data
                        a_r[i+1] <= a_r[i];
                        b_r[i+1] <= b_r[i];
                        valid_r[i+1] <= valid_r[i];

                        // Copy previous sum results
                        sum_r[i+1] <= sum_r[i];

                        if (valid_r[i]) begin
                            // Store this stage's sum results
                            sum_r[i+1][END_BIT:START_BIT] <= segment_sum[STAGE_WIDTH-1:0];

                            // Handle the carry for the final result or next stage
                            if (i == ACTUAL_LATENCY-1 && END_BIT == MAX_WIDTH-1) begin
                                // Last stage: store carry in the MSB of the result
                                sum_r[i+1][RESULT_WIDTH-1] <= segment_sum[STAGE_WIDTH];
                            end else if (i < ACTUAL_LATENCY-1) begin
                                // Not last stage: propagate carry to next stage
                                carry_r[i] <= segment_sum[STAGE_WIDTH];
                            end
                        end
                    end
                end
            end
        end
    endgenerate

    // Final output connections
    assign sum_out = sum_r[ACTUAL_LATENCY];
    assign valid_out = valid_r[ACTUAL_LATENCY];
endmodule
