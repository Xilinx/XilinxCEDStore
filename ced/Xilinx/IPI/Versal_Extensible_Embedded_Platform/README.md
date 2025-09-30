An extensible platform is the foundation of the Vitis software acceleration flow. This platform enables Vitis to create AIE kernels and PL kernels. 
It gives the kernels access to DDR memory, an interrupt controller, and clocking resources. Extensible interfaces are marked with PFM properties and the platform is exported to Vitis using write_hw_platform to create an XSA.

## Instructions for VEK280 board AIE Simulation flow
For the designs targeting PL only applications with AIE, the default json and shim solution is being picked by AIE model and leads to simulation System C errors. To avoid such errors, please follow the simulation flow steps provided below.
   
1. Execute below commands in the terminal before launching vivado

		source Installarea/installs/lin64/Vitis/Installedversion/settings64.csh
		setenv JSON_DEVICE_FILE_PATH Installarea/installs/lin64/Vitis/Installedversion/aietools/data/aie_ml/devices/VC2802.json


2. In batch mode follow the below commands if trying to execute Non-AIE simulation flow on AIE based PL applications.

		launch_simulation -scripts_only
		update_compile_order -fileset sim_1
		set_property target_simulator {Vivado Simulator} [current_project]
		set_property -name {xsim.simulate.runtime} -value {0ns} -objects [current_fileset -simset]
		launch_simulation -simset sim_1 -mode behavioral
		close_sim
	
Notes : "Installarea" is the directory where the vivado is being installed.
		