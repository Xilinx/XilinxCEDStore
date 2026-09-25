# H10 char board : constraints a port named pcie_rst_n, typically
# driven by VIO, to J344, pin 9. Intended for connection to the
# X-PCIE-03 board when PERST# is an input to the FPGA. 

set_property IOSTANDARD LVCMOS15 [get_ports {pcie_rst_n[0]}]
set_property PACKAGE_PIN P33 [get_ports {pcie_rst_n[0]}]
