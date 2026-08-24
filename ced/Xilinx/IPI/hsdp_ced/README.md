# hsdp_ced
A Vivado Configurable Example Design for the soft Aurora HSDP solution

This CED will allow the user to choose which GTY Quad and refclk input to use, and then create a 
fully functional Vivado project to enable HSDP using the soft Aurora interface.  All designs will be 
10.0Gbps with a 156.25 MHz refclk. Timing and location constraints will also be generated. 

To enable Vivado to access this CED, assuming the repo is in ~/temp/hsdp_ced use the following code in the 
Vivado tcl console:

```Tcl
set_param ced.repoPaths ~/temp/hsdp_ced
get_example_designs
```


