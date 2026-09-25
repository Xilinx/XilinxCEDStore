##############################################################################
		CPM - PCIe BMD Example Design
##############################################################################
This package contains the CPM - PCIe BMD Example Design along with the
Testbench to exercise the same. Please use below version of tools to run the
simulation

Vivado Version  - 2025.1 
VCS Version     - W-2024.09-SP1
Questa Version  - 2024.3

- For launching the simulation, under Project Manager -> Settings -> Simulation
	- Update Target Simulator as VCS/Questa
	- Update Compiled Library Location
	- Select Generate Simulation scripts only check box
- Click on Run Simulation under Flow Navigator.
- Above step will generate required script under 
  <project_name>/<project_name>.sim/sim_1/behav/<vcs/questa> directory. 
  Go to the same directory
  	% cd <project_name>/<project_name>.sim/sim_1/behav/<vcs/questa>
- Execute the following scripts
	% ./compile.sh
	% ./elaborate.sh
	% ./simulate.sh
  

NOTE : 
1. This design usage is limited for simulation purpose
2. The integrated testcase simulation will run for ~600us
3. This design will not support xcvp1202-vsva2785-2MP-e-S board part
##############################################################################
