##############################################################################
		CPM - QDMA Example Design
##############################################################################
This package contains the CPM - QDMA Example Design along with the
Testbench to exercise the same. Please use below version of tools to run the
simulation

Vivado Version  - 2025.2
VCS Version     - V-2023.12-SP1
Questa Version  - 2025.2

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
2. The integrated testcase simulation will run for ~250us
##############################################################################
