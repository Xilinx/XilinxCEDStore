import pcie_intf_pkg::*;

interface plstr_tx_if (
    input logic clk
);
    // The monitor will sample this struct on clock edges
    tx_intf tx_intf;

    // Clocking block specifically for the monitor
    // This ensures proper signal sampling and prevents race conditions
    clocking monitor_cb @(posedge clk);
        input tx_intf;  // Sample the entire struct as one unit
    endclocking

    // Modport for the monitor - restricts access to just what's needed
    modport monitor_mp (
        clocking monitor_cb
    );
endinterface
