# Firmware placeholder (IDE)

When the `IDE` option is selected, the CPM6 IDE keys are programmed by the SEC firmware running on RPU core R5_0.

The firmware is not packaged in this CED yet. Build it separately and put the ELF here as `ide_fw.elf` (placeholder name).
The steps to load and start it on R5_0 are in the top-level `README.md`, section "Running the IDE firmware".

This folder is not used by the CED generation flow, the PDI build or the simulation.
