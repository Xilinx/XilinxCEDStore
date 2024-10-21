# VCK190 Example Design : AXI DMA
## Objective
The Versal example design will show how to run AXI DMA standalone application example on vck190 and intended to demonstrate the AXI DMA standalone driver which is available as part of the Xilinx Vivado and Vitis.
## Required Hardware and Tools
2020.2 Vivado and Vitis

VCK190 ES1 

Boot Mode: JTAG
## Block Diagram

![Block Diagram](./Icons/Block_Diagram.JPG)

## Design Steps

#### 1. Open vivado and select XHub Stores in Tools tab

![Design steps](./Icons/XHub.JPG)

#### 2. Install AXI DMA Example Design

![Design steps](./Icons/Template.JPG)

#### 3. Close that window and select Open Example Project

![Design steps](./Icons/Open_Example.JPG)

#### 4. Create an axi dma vivado project and generate .pdi by selecting Generate Device Image and .xsa file using export hardware design.

![Design steps](./Icons/GDI.JPG)

![Design steps](./Icons/Export.JPG)


## Vitis Steps

#### 1. Lanch Vitis and create an application project with a new platform from hardware (XSA) in Vitis.

![Vitis Steps](./Icons/Vitis_new_proj.JPG)

#### 2. Browse an XSA file that is exported from Vivado by clicking '+" symbol and then next. 

![Vitis Steps](./Icons/XSA.JPG)

#### 3. Select CPU as A72_0 then click next and select Hello World template and finish.

![Vitis Steps](./Icons/Software_Details.JPG)

#### 4. Select the platform.spr file to import axi dma application example project as below and then build the project.

![Vitis Steps](./Icons/Application.JPG)

#### 5 Build the axi dma imported project and run this application on vck190 board.

## Console log:

#### [7.286837]Xilinx Versal Platform Loader and Manager
#### [11.819406]Release 2020.2   Sep 21 2020  -  08:19:45
#### [16.352565]Platform Version: v2.0 PMC: v2.0, PS: v2.0
#### [20.969096]STDOUT: PS UART
#### [23.320181]****************************************
#### [27.809262] 23.287425 ms for PrtnNum: 1, Size: 2224 Bytes
#### [32.725562]-------Loading Prtn No: 0x2
#### [36.627740] 0.509784 ms for PrtnNum: 2, Size: 48 Bytes
#### [40.786175]-------Loading Prtn No: 0x3
#### [78.493881] 34.313018 ms for PrtnNum: 3, Size: 57136 Bytes
#### [80.791728]-------Loading Prtn No: 0x4
#### [84.200806] 0.016468 ms for PrtnNum: 4, Size: 2512 Bytes
#### [89.020043]-------Loading Prtn No: 0x5
#### [92.431356] 0.018187 ms for PrtnNum: 5, Size: 3424 Bytes
#### [97.248925]-------Loading Prtn No: 0x6
#### [100.653243] 0.011862 ms for PrtnNum: 6, Size: 80 Bytes
#### [105.456287]+++++++Loading Image No: 0x2, Name: pl_cfi, Id: 0x18700000
#### [111.439628]-------Loading Prtn No: 0x7
#### [645.960959] 531.041762 ms for PrtnNum: 7, Size: 828160 Bytes
#### [648.512065]-------Loading Prtn No: 0x8
#### [906.054428] 254.060503 ms for PrtnNum: 8, Size: 379184 Bytes
#### [908.644153]+++++++Loading Image No: 0x3, Name: fpd, Id: 0x0420C003
#### [914.397656]-------Loading Prtn No: 0x9
#### [918.296828] 0.421790 ms for PrtnNum: 9, Size: 976 Bytes
#### [922.777659]***********Boot PDI Load: Done*************
#### [927.522034]3503.136143 ms: ROM Time
#### [930.694528]Total PLM Boot Time

#### --- Entering main() ---
#### Successfully ran XAxiDma_SimplePoll Example
#### --- Exiting main() ---

