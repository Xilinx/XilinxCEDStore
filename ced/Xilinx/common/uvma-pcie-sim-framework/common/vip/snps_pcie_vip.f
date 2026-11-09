/* - Taken from Synopsys VIP User Guide and Mike Muse recommendation 
   - Run the tools_setup script to enable all paths, env. vars, etc.
*/

+incdir+$DESIGNWARE_HOME/vip/svt/common/latest/sverilog/include
// Simulator dependent: add on compile application cmd line
//+incdir+$DESIGNWARE_HOME/vip/svt/common/latest/sverilog/src/[vcs,mti]

+incdir+$DESIGNWARE_HOME/vip/svt/pcie_svt/latest/sverilog/include
// Simulator dependent: add on compile application cmd line
//+incdir+$DESIGNWARE_HOME/vip/svt/pcie_svt/latest/sverilog/src/[vcs,mti]
//+incdir+$DESIGNWARE_HOME/vip/svt/pcie_svt/latest/verilog/src/[vcs,mti]

// Simulator dependent: add on compile application cmd line
//+define+QUESTA    //iff questa simulator
//+define+MODELTECH //iff questa simulator
//+define+VCS       //iff vcs simulator

+define+UVM_PACKER_MAX_BYTES=8192
+define+UVM_DISABLE_AUTO_ITEM_RECORDING
+define+DESIGNWARE_INCDIR=$DESIGNWARE_HOME
+define+SVT_PCIE_ENABLE_GEN5
+define+SVT_PCIE_ENABLE_10_BIT_TAGS
+define+SVT_UVM_TECHNOLOGY
+define+SVT_LOADER_UTIL_ENABLE_DWHOME_INCDIRS
+define+SYNOPSYS_SV
