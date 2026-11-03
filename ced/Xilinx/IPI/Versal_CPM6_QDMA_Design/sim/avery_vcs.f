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
