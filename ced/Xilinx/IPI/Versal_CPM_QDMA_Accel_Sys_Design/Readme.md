# Versal CPM5 QDMA Based Acceleration System Design
## Objective
This example design demonstrates the following functionalities with Versal CPM5 QDMA:

This design will cover the following functionalities:

  * Segmented Configuration    
    - Loading of PLD image over PCIe to SBI using QDMA driver.
  * QDMA-MM H2C/C2H data path:

    Using MM, the example design demonstrates the transfer of data from a host machine to an accelerator logic within a Programmable Logic (PL) device, processing that data, and then retrieving the 
    processed data back into the host memory. This is done with the following steps:
    - Begin by transferring the data from the host memory to a DDR attached to the Versal Premium device, utilizing the QDMA Driver running on PCIe host to perform the H2C DMA transfer.
    - Upon completion of H2C DMA transfer, generate an IPI Interrupt targeted to the A72 APU within the Versal Premium Device. 
    - A Baremetal Application running on the APU responds to the IPI interrupt and programs AXI-DMA IP in the PL.
    - Following this, AXI-DMA IP transfers the data from DDR to the Accelerator logic located in the PL. 
    - The Accelerator logic then processes the H2C data and subsequently writes the output data back to the DDR memory. 
    - Afterward, the PL generates an interrupt to the host via the usr_irq interface of CPM5-QDMA. 
    - Finally, utilize the QDMA driver to perform C2H DMA transfer from DDR memory back into the Host memory.   
  * QDMA-ST H2C/C2H data path:
    - Using QDMA driver, transfer the data in host memory to Accelerator logic to PL using H2C-ST DMA transfer
    - Process the H2C-ST data and store it in Stream FIFO
    - Perform C2H-ST data transfer
      - The C2H-ST transfer is supported using:
        - Internal method
        - Simple bypass method
        - Csh bypass method
  * Access to Memory Regions
    - Access to the following memory regions via the PCIe link will be demonstrated
      - OCM
      - RTCA
      - SBI
      - QSPI
      - CPM
      - Inter Processer Interrupt registers

VPK120 board has two device variants with MP and MHP parts. 

* The VPK120 evaluation kit has a physical x16 edge connector and enables protocol support in two flavors depending on whether overdrive is used or not.

With overdrive, the VPK120 supports: Gen1/2/3/4x16 or Gen5x8.

Without overdrive, the VPK120 supports: Gen1/2/3x16 or Gen4x8.

Gen5 is not supported without overdrive.

Depending on the device selected during the CED creation, the target data rate is selected. 
 * For MP part, design is generated with Gen4 x8 configuration. 
 * For MHP part, design is generated with Gen5 x8 configuration.

Note:
This CED is only provided for hardware test flow. Simulation is not supported. 

## System Architecture
The block diagram below illustrates the architecture of the provided example design:
![image](https://github.com/user-attachments/assets/36f82093-7727-438d-983e-c01256f5fed5)

Following is a brief description about the design. 
 - The PL logic in the design is highlighted in Red boxes. This consists of the following components:
      - Example accelerator logic for MM/ST data path.
      - AXI-DMA IP for DMA transfer from DDR to PL.
      - AXI-smart connect for connections between FPD NoC to PL, AXI-DMA to DDR and PL.
      - DSC-Bypass suport for QDMA-ST mode. 
      - Generation of CMPT packet for C2H-ST DMA transfer using CPM5-QDMA IP. 
      - Descriptor fetch using the DSC_CRDT interface of CPM5-QDMA IP. 
      - User interrupt generation using the usr_irq interface of CPM5-QDMA IP. 
 - QDMA within CPM5 is enabled to perform DMA transfer to/from host memory. 
 - Both PCIe NoC ports from the CPM5 block are connected to DDR through AXI-NoC.
 - PCIe NoC1 port is connected to PMC peripherals. with NoC remap enabled in this path and address translation is enabled in both CPM5 and AXI-NoC IP. 
 - A Baremetal application running on APU accesses the AXI-DMA IP registers through the FPD-NoC port. 

## Functional Description
### Address Remap
The following snapshot shows address remap settings in the AXI-NoC IP. This feature is utilized to access various register spaces of PMC, CPM, and IPI peripherals through one of the PCIe BARs. 

![image](https://github.com/user-attachments/assets/f87986cc-0573-445b-b74d-d42a28707a31)

The table below presents various memory regions accessible through the PCIe link. This table illustrates two levels of address translations. 
1. The AXI-Bridge functionality in CPM5 is used to translate PCIe BAR offset to different offsets accessible through the PCIe NoC. The PCIe BAR size is set to 128MB and the PCIe base address is translated to 0x201_0000_0000. 
2. The second translation occurs within the AXI-NoC. This translation aligns the addresses coming from the PCIe NoC port with the address regions of the PMC, CPM, IPI peripherals.
![image](https://github.com/user-attachments/assets/f3149479-af60-4212-9a53-e429ff10381b)


### MM Data flow
The following flowchart depicts the data path flow for the Memory mapped (MM) mode of transfer:
![image](https://github.com/user-attachments/assets/5370c0eb-e6d4-41e7-a7c4-b57103b5e106)


### ST Data flow
The following flowchart illustrates the data path flow for Stream (ST) mode of transfer:
![image](https://github.com/user-attachments/assets/1a5882fa-b2c6-49ef-bb47-4188c082491c)

## Required Hardware and Tools
 - Vivado 2025.1  
 - Vitis 2025.1

## Design Steps

#### 1. Open Vivado and click on "open Example Project"
![image](https://github.com/user-attachments/assets/b86dc364-8d21-4720-894c-f4ada44d99a7)

#### 2. "Open Example Project" pop-up is launched by Vivado. Click Next on this page. 
![image](https://github.com/user-attachments/assets/ddbfcf3f-3c42-488e-93f8-002f043d868c)

#### 3. In "Select Project Template" page, there are "Templates" and "Description" section. In the Templates section, look for "Versal CPM5 QDMA Based Acceleration System design" template. There is a search icon at the top of the Templates section to perform search. Click Next after selecting this CED template.

![image](https://github.com/user-attachments/assets/0f50995f-6558-4997-8428-4e2f14a5cb8b)

#### 4. Select project name and project location.

![image](https://github.com/user-attachments/assets/dc4c3d4f-dd8e-4048-9b5e-473ae631d9ac)

#### 5. This CED targets VPK120 board. This board has two variants of the Versal Premium device. By default, xcvp1202-vsva2785-2MP-e-S device is selected. Alternatively, a MHP part can be selected by using "Switch Part" option in this page. 
![image](https://github.com/user-attachments/assets/3c3c9c32-abd2-456a-80ac-9b5155754acd)

When "Switch Part" option is clicked, a pop-up will be launched with option to select either xcvp1202-vsva2785-2MP-e-S or xcvp1202-vsva2785-2MHP-e-S device for the VPK120 board. This CED supports both parts. When "MP" device is selected CPM5-QDMA is set to Gen4 x8 configuration. For "MHP" device, CPM5-QDMA is set to Gen5 x8 configuration.

![image](https://github.com/user-attachments/assets/19e0b7ac-c2b9-42ab-967a-6e68e2625482)

#### 6. "Select Design and Preset" page is launched. The options on this page are fixed. Click Next on this page. 
![image](https://github.com/user-attachments/assets/6f8fc8a9-ac77-435b-8cc6-aead6b2cbe7c)

#### 8. This is the final page - "New Project Summary". It lists the options selected in the previous pages. 
  - CED template - Versal CPM5 QDMA Based Acceleration System design
  - Board - Versal VPK120 Evaluation Platform
  - Part - xcvp1202-vsva2785-2MP-e-S (in this example)
  - Family - Versal Premium
  - Package - vsva2785
  - Speed Grade : -2MP (in this example)
Click "Finish" on this page. This will initiate CED creation process.
  
![image](https://github.com/user-attachments/assets/c589b992-415d-45cb-9d05-b959cd0b3afd)

#### 9. After the CED has been created, generate .pdi by selecting Generate Device Image step in the "Flow Navigator" section of Vivado GUI. 

#### 10. This design requires a baremetal application to be executing while performing MM transfers. Following command needs to be executed after generating the PDI from Vivado. ipi_cdma_intr.elf and qdma_accel_sys.bif are provided in src directory of this CED. 

qdma_accel_sys.bif assumes that ipi_cdma_intr.elf and design_1_wrapper_pld.pdi are in the same directory as the bif file.  
bootgen -arch versal -image ./qdma_accel_sys.bif -o ./boot_with_elf.pdi -w

## CPM Configuration
The following snapshots show the configuration done in CPM GUI inside Versal CIPS IP.  
![image](https://github.com/user-attachments/assets/00d60df3-677d-4d6b-baad-a410885c3b8b)

![image](https://github.com/user-attachments/assets/d53fe957-b31c-4651-a51f-0b57a6793cc8)

![image](https://github.com/user-attachments/assets/913f238c-58c9-4ce5-8dc0-3cd576e1e02d)


![image](https://github.com/user-attachments/assets/7abb9b0d-0f6a-4ff6-9825-44d15f6bf545)


![image](https://github.com/user-attachments/assets/7d612835-9dca-4f15-8c38-cf7a9fc8ff17)


![image](https://github.com/user-attachments/assets/32b322b0-86c1-45ee-b286-7cd6ea2519de)


![image](https://github.com/user-attachments/assets/07ece90d-d95b-400c-825c-6a5f14a6e939)


![image](https://github.com/user-attachments/assets/3080c48a-e3d5-47bd-bdbc-5e7c77f05328)


![image](https://github.com/user-attachments/assets/348cbda9-7691-4f8c-ba0b-54c32bf5ede4)


## PMC Configuration
The following snapshots show the design PMC configuration inside Versal CIPS IP.

![image](https://github.com/user-attachments/assets/85abf016-1cdf-491b-b9fd-de953c0bbc75)


![image](https://github.com/user-attachments/assets/0be791f6-d156-4df3-a5a9-d9ffe0806c0d)


![image](https://github.com/user-attachments/assets/bb1e0eab-aff9-414d-9881-2975babe0ce5)


![image](https://github.com/user-attachments/assets/edc55176-d45e-4ca2-9726-9f111de17d01)


![image](https://github.com/user-attachments/assets/c8e086d5-c55e-4c82-915c-540cc4bbd951)


![image](https://github.com/user-attachments/assets/0d1ea2bb-bbc2-4d6c-b466-bdcf6537f1ce)


![image](https://github.com/user-attachments/assets/bc98d36e-2d27-4853-acef-22328415d906)



## Test Scripts

As a prerequisite to run this script, ensure that the QDMA driver (found in the link below) is installed on the host and connected to the QDMA endpoint running on the VPK120 board. 

https://github.com/Xilinx/dma_ip_drivers

Following scripts are provided with the CED for reference. They are available in scripts folder of this CED. 
### qdma_test_h2c_mm.sh
This script tests the MM data path of the design and performs the following steps. 
  1. Identify the bus, device, function (BDF) numbers of the PCIe slot to which the VPK120 board is connected. This design is set with DEVICE_ID of "10EE", which is used for the BDF identification process.
  2. Create MM QID for both H2C/C2H directions
  3. Start the QID
  4. Perform an H2C-MM DMA transfer to the 0x72000000000 DDR address.
  5. Initiate an IPI interrupt to the A72 processor in the Versal Premium device. The IPI message sent through the IPI interrupt consists of the following information.
     - DDR address used in H2C-MM DMA transfer
     - QID used in H2C-MM DMA transfer
     - Size of the H2C-MM DMA transfer
  
### qdma_test_h2c_st.sh
This script tests the ST data path of the design and requires the h2c_data.txt file. It performs the following steps. 
  1. Identify the bus, device, function (BDF) numbers of the PCIe slot to which the VPK120 board is connected. This design is set with DEVICE_ID of "10EE", which is used for the BDF identification process.
  2. This script includes variables such as desc_bypass_en, pfetch_bypass_en, trfr_size0, trfr_size1, and trfr_size2.
     - desc_bypass_en, pfetch_bypass_en are used to set different C2H-ST use modes (Simple bypass, Csh bypass, Csh Internal) for C2H-ST QID. 
       - Simple bypass mode --> desc_bypass_en = 1, pfetch_bypass_en = 1
       - Csh bypass mode --> desc_bypass_en = 1, pfetch_bypass_en = 0
       - Csh Internal mode --> desc_bypass_en = 0, pfetch_bypass_en = 0
     - trfr_size0 - size of DMA transfer with Csh Internal mode
     - trfr_size1 - size of DMA transfer with Csh bypass mode
     - trfr_size2 - size of DMA transfer with simple bypass mode
   3. Create a ST QID for the H2C-ST direction
   4. Create a ST QID for the C2H-ST direction based on desc_bypass_en and pfetch_bypass_en values.
   5. Start the QID H2C-ST and C2H-ST directions.
   6. Perform a H2C-ST DMA transfer to the PL
  
### access_PS_peripherals.sh 
This script tests access to the memory regions such as OCM, RTCA, SBI, QSPI, CPM. 
It is important to note that this script presumes a BDF value of 01000 for accessing the PMC peripherals.

### host_profile_noc0_1.sh
This script programs host profile registers of QDMA to perform MM transfers to NoC Ch#0 and Ch#1.

## Hardware Test Flow

The test setup for the CED will include the following components. 
1. VPK120 board inserted to the PCIe slot of a Gen5/Gen4 server.
2. Connect the JTAG cable to a machine with Vivado 2025.1 installed.
3. Install TeraTerm (or) similar software to view the PLM log and prints from Baremetal application.

Test steps for this CED require the following components.
1. Vivado 2025.1 - to program the boot image.
2. XSDB - to program SBI_CTRL register.
3. QDMA driver - to perform DMA transactions.
4. TeraTerm - to review the PLM log and prints from the Baremetal application. 

In the remainder of this section, the steps are assumed to be performed on two machines. One machine (Ex: laptop) with Vivado, Tera Term softwares installed and the second machine being the PCIe host. 

### The Following steps need to be run on the machine with JTAG connection to the VPK120 board. 

#### 1. Program Boot image using JTAG

#### 2. Setup TeraTerm terminal with the settings shown in the figure below. How to identify the teraterm port to use?

![image](https://github.com/user-attachments/assets/5dc9fc04-26d9-4ba5-9e89-34afd8b3255f)

#### 3. Launch xsdb and read SBI_CONTROL register at 0xF1220004 address. This register needs to be set to 0x29 to load the PLD PDI from host. This step is essential for the DMA transfer step to load the PLD PDI using the QDMA driver. 

![image](https://github.com/user-attachments/assets/50cdd45b-5bf3-4f71-b622-b4217c6ac585)

If the JTAG cable is connected to a remote host, use the command "conn -host <host_name or host_IP_address>" before connecting to the board using "ta" command as shown below.

![image](https://github.com/user-attachments/assets/b05c4938-8626-4b20-b9d9-dccdef0b4110)

### Following steps need to be run on the PCIe host in which VPK120 board is connected through a PCIe slot. 

The details of these commands and instructions can be found in the QDMA driver documentation. The steps are just listed here for ease of use. 

#### Please note that the commands provided in this section assumes VPK120 board to a PCIe slot and host has assigned the PCIe slot with a BDF value of 01000.

1. Download or clone the dma_ip_drivers repo from GitHub to the host system
2. Compile the QDMA driver and applications

> cd <path>/dma_ip_drivers/QDMA/linux-kernel

> make TANDEM_BOOT_SUPPORTED=1 

3. Install the compiled binaries

> make install

4. Load the stage one bitstream (boot_with_elf.pdi) to the device through JTAG or another method
5. Reboot the host system
6. Load the QDMA driver(s)

> modprobe qdma-pf //physical functions
> modprobe qdma-vf //virtual functions (if necessary)

7. Source host_profile script to use mm_chn1. This is required since SBI interface in PMC is connected through PCIe NoC CH#1. 

> source ./host_profile_noc0_1.sh

8. Using sysfs, set the max number of queue pairs. This is arbitrarily chosen
as 3 in this example, and also assume the B:D.F is 01:00.0.

> echo 10 > /sys/bus/pci/devices/0000:01:00.0/qdma/qmax

9. Add the queues. Queue 0 is the memory-mapped host-to-card queue, Queue 1
is the memory-mapped card-to-host queue, and Queue 2 is the streaming
host-to-card queue

> dma-ctl qdma01000 q add idx 0 mode mm dir h2c
> dma-ctl qdma01000 q add idx 1 mode mm dir c2h

10. Start the queues. Queue 0 will be used to transfer the stage two bitstream
to the configuration engine through the slave boot interface (SBI) and
requires the aperture_sz parameter to be set

> dma-ctl qdma01000 q start idx 0 dir h2c aperture_sz 4096 mm_chn 1
> dma-ctl qdma01000 q start idx 1 dir c2h

11. Transfer the stage two (pld_with_elf.pdi) bitstream to the device to be programmed,
targeting the SBI FIFO using address 0x102100000

> dma-to-device -d /dev/qdma010000-MM-0 -f <stage2.pdi> -s <size> -a 0x20102100000


The following snapshot shows the PLM log after programming boot.pdi to VPK120 board.

![image](https://github.com/user-attachments/assets/166f663a-9ffb-4287-9022-f5c54730807e)

The following snapshot shows the PLM log after programming pld.pdi to VPK120 board using QDMA driver. 

![image](https://github.com/user-attachments/assets/2c4553d0-5d0a-4f36-bfa7-70fd4c1c9626)

The following snapshot shows the result of sourcing the access_PS_peripherals.sh. This script tries to access the PMC peripherals - RTCA, OCM, QSPI, CPM, SBI

![image](https://github.com/user-attachments/assets/ab4beb0e-b385-4895-91aa-24ce706d55c4)

The following snapshot shows the output on TeraTerm after sourcing H2C_MM test script in PCIe Host.

![image](https://github.com/user-attachments/assets/55adb2c3-f28c-4c3e-b8a3-d4fa4282498c)

## References
#### PG347 - https://docs.amd.com/r/en-US/pg347-cpm-dma-bridge?tocId=oTd_ZrdYcOWw7fqmc3hb9g
#### QDMA Linux Driver documentation (Master page) - https://xilinx.github.io/dma_ip_drivers/master/QDMA/linux-kernel/html/index.html
#### QDMA Driver Source - https://github.com/Xilinx/dma_ip_drivers
#### Inter Processor Interrupts - https://docs.amd.com/r/en-US/am011-versal-acap-trm/Inter-Processor-Interrupts
#### Address remapping feature with AXI-NoC - https://docs.amd.com/r/en-US/pg313-network-on-chip/Address-Re-mapping
