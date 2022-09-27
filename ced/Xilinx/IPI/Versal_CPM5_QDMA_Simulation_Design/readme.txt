##############################################################################
		CPM5 - QDMA Example Design
##############################################################################
This package contains the CPM5 - QDMA Example Design along with the
Testbench to exercise the same. Please use below version of tools to run the
simulation

Vivado Version  - 2022.2 E-EA
VCS Version     - S-2021.09

- For launching the simulation, under Project Manager -> Settings -> Simulation
	- Update Target Simulator as VCS
	- Update Compiled Library Location
	- Select Generate Simulation scripts only check box
- Click on Run Simulation under Flow Navigator.
- Above step will generate required script under 
  <project_name>/<project_name>.sim/sim_1/behav/vcs directory. 
  Go to the same directory
  	% cd <project_name>/<project_name>.sim/sim_1/behav/vcs
- Execute the following scripts
	% ./compile.sh
	% ./elaborate.sh
	% ./simulate.sh
  

NOTE : 
1. This design usage is limited for simulation purpose
2. The integrated testcase simulation will run for ~600us
##############################################################################
