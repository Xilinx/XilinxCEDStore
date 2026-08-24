##**************************************************************************
##
## TX/RX out clock clock constraints
##
# GT X0Y0
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[0].u_ch/u_gthe4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[0].u_ch/u_gthe4_channel/TXOUTCLK}] -include_generated_clocks]
create_clock -period 4.000 [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[0].u_ch/u_gthe4_channel/DMONITOROUTCLK}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[0].u_ch/u_gthe4_channel/DMONITOROUTCLK}]]
# GT X0Y1
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[1].u_ch/u_gthe4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[1].u_ch/u_gthe4_channel/TXOUTCLK}] -include_generated_clocks]
create_clock -period 4.000 [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[1].u_ch/u_gthe4_channel/DMONITOROUTCLK}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[1].u_ch/u_gthe4_channel/DMONITOROUTCLK}]]
# GT X0Y2
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[2].u_ch/u_gthe4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[2].u_ch/u_gthe4_channel/TXOUTCLK}] -include_generated_clocks]
create_clock -period 4.000 [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[2].u_ch/u_gthe4_channel/DMONITOROUTCLK}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[2].u_ch/u_gthe4_channel/DMONITOROUTCLK}]]
# GT X0Y3
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[3].u_ch/u_gthe4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[3].u_ch/u_gthe4_channel/TXOUTCLK}] -include_generated_clocks]
create_clock -period 4.000 [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[3].u_ch/u_gthe4_channel/DMONITOROUTCLK}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[0].u_q/CH[3].u_ch/u_gthe4_channel/DMONITOROUTCLK}]]
# GT X0Y4
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[0].u_ch/u_gthe4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[0].u_ch/u_gthe4_channel/TXOUTCLK}] -include_generated_clocks]
create_clock -period 4.000 [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[0].u_ch/u_gthe4_channel/DMONITOROUTCLK}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[0].u_ch/u_gthe4_channel/DMONITOROUTCLK}]]
# GT X0Y5
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[1].u_ch/u_gthe4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[1].u_ch/u_gthe4_channel/TXOUTCLK}] -include_generated_clocks]
create_clock -period 4.000 [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[1].u_ch/u_gthe4_channel/DMONITOROUTCLK}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[1].u_ch/u_gthe4_channel/DMONITOROUTCLK}]]
# GT X0Y6
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[2].u_ch/u_gthe4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[2].u_ch/u_gthe4_channel/TXOUTCLK}] -include_generated_clocks]
create_clock -period 4.000 [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[2].u_ch/u_gthe4_channel/DMONITOROUTCLK}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[2].u_ch/u_gthe4_channel/DMONITOROUTCLK}]]
# GT X0Y7
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[3].u_ch/u_gthe4_channel/RXOUTCLK}] -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[3].u_ch/u_gthe4_channel/TXOUTCLK}] -include_generated_clocks]
create_clock -period 4.000 [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[3].u_ch/u_gthe4_channel/DMONITOROUTCLK}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {spartan_ultrascaleplus_ibert_ddr_i/example_ibert_ultrascale_0/inst/u_ibert_gth_core/inst/QUAD[1].u_q/CH[3].u_ch/u_gthe4_channel/DMONITOROUTCLK}]]

