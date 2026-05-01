##############################################################################
		CPM - Two Port Switch Example Design
##############################################################################
This package contains the CPM - Two Port Switch Example Design along with the
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
 The reset from the Upstream Port in the Switch Design is placed on pin P33 
 (J344, pin 9) of the board as defined in the constraints file. The customers 
 must physically route this reset to the Downstream Port and its link partner.

##############################################################################
