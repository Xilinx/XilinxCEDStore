# chipscopy_ced
Configurable Example Design to illustrate features of ChipScope debug cores and hard blocks.

This CED creates a design for either the VCK190 or the VMK180 that illustrates features of
ChipScope.  This includes fabric debug cores like ILA, but also instantiates Versal hard
blocks that can be queried/controlled at runtime, like the GT Quads, NoC, and DDRMCs. These
designs can then be used in either the Vivado Hardware Manager or with the [ChipScoPy API](https://github.com/Xilinx/chipscopy)
in hardware.

