/* - Taken from running the example back-to-back TB from $AVERY_PCIE and
     seeing what was necessary for compilation, then copying and pasting
     what seemed necessary into this file
   - Run the tools_setup script to get paths, env. vars, etc. set up
*/
//-CFLAGS -DVCS

+define+AVERY_UVM
+define+UVM_NO_DEPRECATED
+define+AVERY_NAMED_CONSTRUCTOR
+define+AVERY_VCS

+incdir+$AVERY_PCIE/src.uvm
+incdir+$AVERY_PCIE/src.VCS
+incdir+$AVERY_PCIE/src
+incdir+$AVERY_SIM/src.IEEE

$AVERY_SIM/src/avery_pkg.sv
$AVERY_PCIE/src/apci_pkg.sv
$AVERY_PCIE/src/apci_pkg_test.sv
$AVERY_PCIE/src/apci_pipe_intf.sv
$AVERY_PCIE/src/apci_mpipe_box.sv
