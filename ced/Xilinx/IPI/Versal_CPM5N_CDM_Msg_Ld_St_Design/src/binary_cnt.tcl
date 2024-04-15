create_ip -name c_counter_binary -vendor xilinx.com -library ip -version 12.0 -module_name c_counter_binary_0
set_property -dict [list \
  CONFIG.CE {true} \
  CONFIG.Final_Count_Value {FFFFFFFFFFFFFFFE} \
  CONFIG.Output_Width {64} \
  CONFIG.Restrict_Count {true} \
  CONFIG.SCLR {true} \
] [get_ips c_counter_binary_0]