# Define the top level system clock of the design
create_clock -period 10 -name sysClk [get_ports sysClk]

# Define the clocks for the GTX blocks
create_clock -name gt0_txusrclk_i -period 12.8 [get_pins mgtEngine/ROCKETIO_WRAPPER_TILE_i/gt0_ROCKETIO_WRAPPER_TILE_i/gtxe2_i/TXOUTCLK]
create_clock -name gt2_txusrclk_i -period 12.8 [get_pins mgtEngine/ROCKETIO_WRAPPER_TILE_i/gt2_ROCKETIO_WRAPPER_TILE_i/gtxe2_i/TXOUTCLK]
create_clock -name gt4_txusrclk_i -period 12.8 [get_pins mgtEngine/ROCKETIO_WRAPPER_TILE_i/gt4_ROCKETIO_WRAPPER_TILE_i/gtxe2_i/TXOUTCLK]
create_clock -name gt6_txusrclk_i -period 12.8 [get_pins mgtEngine/ROCKETIO_WRAPPER_TILE_i/gt6_ROCKETIO_WRAPPER_TILE_i/gtxe2_i/TXOUTCLK]

# IO delays
set_input_delay -clock sysClk 0.0 [get_ports or1200_clmode]
set_input_delay -clock sysClk 0.0 [get_ports or1200_pic_ints]
set_input_delay -clock sysClk 3.0 [get_ports DataIn_pad_0_i[*]]
set_input_delay -clock sysClk 3.0 [get_ports LineState_pad_0_i[*]]
set_input_delay -clock sysClk 3.0 [get_ports RxActive_pad_0_i]
set_input_delay -clock sysClk 3.0 [get_ports RxError_pad_0_i]
set_input_delay -clock sysClk 3.0 [get_ports RxValid_pad_0_i]
set_input_delay -clock sysClk 3.0 [get_ports TxReady_pad_0_i]
set_input_delay -clock sysClk 3.0 [get_ports VStatus_pad_0_i[*]]
set_input_delay -clock sysClk 3.0 [get_ports usb_vbus_pad_0_i]
set_input_delay -clock sysClk 3.0 [get_ports DataIn_pad_1_i[*]]
set_input_delay -clock sysClk 3.0 [get_ports LineState_pad_1_i[*]]
set_input_delay -clock sysClk 3.0 [get_ports RxActive_pad_1_i]
set_input_delay -clock sysClk 3.0 [get_ports RxError_pad_1_i]
set_input_delay -clock sysClk 3.0 [get_ports RxValid_pad_1_i]
set_input_delay -clock sysClk 3.0 [get_ports TxReady_pad_1_i]
set_input_delay -clock sysClk 3.0 [get_ports VStatus_pad_1_i[*]]
set_input_delay -clock sysClk 3.0 [get_ports usb_vbus_pad_1_i]
set_input_delay -clock sysClk 0.0 [get_ports reset]

set_output_delay -clock sysClk 0.0 [get_ports or1200_pm_out[*]]
set_output_delay -clock sysClk 0.0 [get_ports TermSel_pad_0_o]
set_output_delay -clock sysClk 0.0 [get_ports TxValid_pad_0_o]
set_output_delay -clock sysClk 0.0 [get_ports VControl_Load_pad_0_o]
set_output_delay -clock sysClk 0.0 [get_ports XcvSelect_pad_0_o]
set_output_delay -clock sysClk 0.0 [get_ports TermSel_pad_1_o]
set_output_delay -clock sysClk 0.0 [get_ports TxValid_pad_1_o]
set_output_delay -clock sysClk 0.0 [get_ports VControl_Load_pad_1_o]
set_output_delay -clock sysClk 0.0 [get_ports XcvSelect_pad_1_o]
set_output_delay -clock sysClk 0.0 [get_ports OpMode_pad_0_o[*]]
set_output_delay -clock sysClk 0.0 [get_ports OpMode_pad_1_o[*]]
set_output_delay -clock sysClk 0.0 [get_ports SuspendM_pad_0_o]
set_output_delay -clock sysClk 0.0 [get_ports SuspendM_pad_1_o]
set_output_delay -clock sysClk 0.0 [get_ports VControl_pad_0_o[*]]
set_output_delay -clock sysClk 0.0 [get_ports VControl_pad_1_o[*]]
set_output_delay -clock sysClk 0.0 [get_ports phy_rst_pad_0_o]
set_output_delay -clock sysClk 0.0 [get_ports phy_rst_pad_1_o]
set_output_delay -clock sysClk 0.0 [get_ports DataOut_pad_0_o[*]]
set_output_delay -clock sysClk 0.0 [get_ports DataOut_pad_1_o[*]]

# Timing exceptions
set_false_path -from [get_ports GTPRESET_IN]

# Multi-cycle paths for ALU:
set_multicycle_path -through [get_pins cpuEngine/or1200_cpu/or1200_alu/*] 2
set_multicycle_path -through [get_pins cpuEngine/or1200_cpu/or1200_alu/*] 1 -hold
