interface rx_credit_if;
// PL -> Core (Output)

    // Return credit valid
    logic               cr_valid;

    // Credit value encoding
    //      - 3'b000: 0  credits
    //      - 3'b001: 1  credits
    //      - 3'b010: 2  credits
    //      - 3'b011: 4  credits
    //      - 3'b100: 8  credits
    //      - 3'b101: 16 credits
    //      - 3'b110: 32 credits
    //      - 3'b111: 64 credits
    logic [2:0]         cr;

// Core -> PL (Input)

    // Credit interface is active. 
    // 1'b0 after reset
    // 1'b1 indicates interface is active
    // Once 1'b1, signal ignored until next reset
    logic               cr_active;

    modport master (
        output cr_valid,
        output cr,
        input  cr_active
    );

    modport slave (
        input  cr_valid,
        input  cr,
        output cr_active
    );
endinterface
