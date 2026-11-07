/* - Taken from Synopsys VIP User Guide and Mike Muse recommendation 
   - Run the tools_setup script to enable all paths, env. vars, etc.
*/

+incdir+$DESIGNWARE_HOME/vip/svt/common/latest/sverilog/include
// Simulator dependent: add on compile application cmd line
//+incdir+$DESIGNWARE_HOME/vip/svt/common/latest/sverilog/src/[vcs,mti]

+incdir+$DESIGNWARE_HOME/vip/svt/amba_svt/latest/sverilog/include
// Simulator dependent: add on compile application cmd line
//+incdir+$DESIGNWARE_HOME/vip/svt/amba_svt/latest/sverilog/src/[vcs,mti]

// Simulator dependent: add on compile application cmd line
//+define+QUESTA //iff questa simulator
//+define+VCS //iff vcs simulator

+define+DESIGNWARE_INCDIR=$DESIGNWARE_HOME
+define+SVT_LOADER_UTIL_ENABLE_DWHOME_INCDIRS
+define+UVM_DISABLE_AUTO_ITEM_RECORDING
+define+SVT_UVM_TECHNOLOGY
