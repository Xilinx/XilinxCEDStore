# ZynqMP Example Design : AXI DMA
## Objective
This ZynqMP example design demonstrates how to run the AXI DMA standalone application on the ZCU102 board. It showcases the functionality of the AXI DMA standalone driver, which is included in the Xilinx Vivado and Vitis toolchains.

## Required Hardware and Tools

Software: Xilinx Vivado and Vitis 2025.1

Hardware: ZCU102 Evaluation Board

Boot Mode: JTAG

## Block Diagram

![Block Diagram](./Icons/Block_Diagram.jpg)

## Vivado Design Steps

#### 1. Launch Vivado and select "Open Example Project".

![Vivado Design steps](./Icons/Open_Example.jpg)

#### 2. Choose "Zynq UltraScale+ MPSoC Design – AXI DMA".

#### 3. Generate the bitstream (.bit) and hardware description (.xsa) by selecting "Generate Bitstream" and "Export Hardware".

![Vivado Design steps](./Icons/GB.jpg)

![Vivado Design steps](./Icons/Export.jpg)


## Vitis Steps

#### 1. Launch Vitis and create a new platform project.

![Vitis Steps](./Icons/vitis_platform.jpg)

#### 2. Browse and select the .xsa file exported from Vivado, then click Next. 

![Vitis Steps](./Icons/vitis_xsa.jpg)

#### 3. Import the AXI DMA SG Interrupt Application Example using the vitis-comp.json file and build the project.

![Vitis Steps](./Icons/app.jpg)

#### 4 Build the imported AXI DMA project and run the application on the ZCU102 board.

#### 5 Console Output:

![Vitis Steps](./Icons/log.jpg)
