# Versal CPM5 QDMA Based Acceleration System Design
## Objective
This example design will show-case end user application features to demonstrate system level operation for key features for Versal devices.

This design will cover the following functionalities:

  * Segmented Configuration
    - Load PLD image over PCIe to SBI – use QDMA driver.
  * QDMA-MM data path - H2C/C2H: Following steps show a process of transferring data from Host machine to Accelerator logic inside PL, processing 
    the data and fetching the processed data back to host memory. 
    - Transfer the data in host memory to a DDR attached to the Versal Premium device. Use QDMA Driver running on PCIe host to perform the H2C DMA transfer.
    - Generate IPI Interrupt on completion of H2C DMA transfer. This IPI interrupt is targeted to PS APU in Versal Premium Device. 
    - A Baremetal Application running on the APU responds to IPI interrupt and programs AXI-DMA IP in the PL.
    - AXI-DMA IP transfers the data from DDR to the Accelerator logic in the PL. 
    - Accelerator logic performs the processing of H2C data and writes the output data back to DDR memory. 
    - PL will generate an interrupt to the host via the usr_irq interface of CPM5-QDMA. 
    - Use QDMA driver to perform C2H DMA transfer from DDR memory to Host memory.   
  * QDMA-ST data path - H2C/C2H:
    - Using QDMA driver, transfer the data in host memory to Accelerator logic to PL using H2C-ST DMA transfer
    - Process the H2C-ST data and store it in Stream FIFO
    - Perform C2H-ST data transfer
  * The C2H-ST transfer is supported using:
    - Internal method
    - Simple bypass method
    - Csh bypass method
  * Access to the following memory regions via the PCIe link will be demonstrated
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

## Block Diagram
Following is the block diagram of various modules in the design.  
![image](https://github.com/user-attachments/assets/36f82093-7727-438d-983e-c01256f5fed5)


Following is a brief description about the design. 
 - The PL logic in the design is highlighted in Red boxes. This consists of 
      - Example accelerator logic for MM/ST data path.
      - AXI-DMA IP for DMA transfer from DDR to PL.
      - AXI-smart connect to connect from FPD NoC to PL, AXI-DMA to DDR and PL.
      - DSC-Bypass suport for QDMA-ST mode. 
      - Generation of CMPT packet for C2H-ST DMA transfer with CPM5-QDMA IP. 
      - Descriptor fetch using DSC_CRDT interface of CPM5-QDMA IP. 
      - User interrupt generation using usr_irq interface of CPM5-QDMA IP. 
 - QDMA inside CPM5 is enabled to perform the DMA transfer to/from host memory. 
 - Both PCIe NoC ports from CPM5 block are connected to DDR through AXI-NoC.
 - PCIe NoC1 port is connected to PMC peripherals. NoC remap is enabled in this path and address translation is enabled in both CPM5 and AXI-NoC IP. 
 - Baremetal application running on APU accesses the AXI-DMA IP registers through FPD-NoC port. 
## Functional Description

### Address Remap
Following snapshot shows address remap settings in AXI-NoC IP. This feature is used to access various register spaces of PMC, CPM, IPI peripherals are accessed using one of the PCIe BARs. 

![image](https://github.com/user-attachments/assets/f87986cc-0573-445b-b74d-d42a28707a31)

The table below provides different memory regions accessible through PCIe link. This table demonstrates two levels of address translations. 
1. AXI-Bridge functionality available in CPM5 is used to translate PCIe BAR offset to different offsets accessible through PCIe NoC. PCIe BAR size is set to 128MB and PCIe base address is translated to 0x201_0000_0000. 
2. Second translation is performed inside AXI-NoC. This translation matches the addresses coming from PCIe NoC port to the PMC, CPM, IPI peripherals address regions.
![image](https://github.com/user-attachments/assets/f3149479-af60-4212-9a53-e429ff10381b)


### MM Data flow
Following flowchart describes the data path flow for Memory mapped mode of transfer:
![image](https://github.com/user-attachments/assets/5370c0eb-e6d4-41e7-a7c4-b57103b5e106)


### ST Data flow
Following flowchart describes the data path flow for Stream mode of transfer:
![image](https://github.com/user-attachments/assets/1a5882fa-b2c6-49ef-bb47-4188c082491c)



## Required Hardware and Tools
 - Vivado 2025.1  
 - Vitis 2025.1

## Design Steps

#### 1. Open Vivado and select XHub Stores in Tools tab

#### 2. Install Versal_CPM_QDMA_Accel_Sys_Design

#### 3. Close that window and select Open Example Project

#### 4. Create Versal_CPM_QDMA_Accel_Sys_Design vivado project and generate .pdi by selecting Generate Device Image

This design requires a baremetal application to be executing while performing MM transfers. Following command needs to be executed after generating the PDI from Vivado. ipi_cdma_intr.elf and qdma_accel_sys.bif are provided in src directory of this CED. 

qdma_accel_sys.bif assumes that ipi_cdma_intr.elf and design_1_wrapper_pld.pdi are in the same directory as the bif file.  
bootgen -arch versal -image ./qdma_accel_sys.bif -o ./boot_with_elf.pdi -w

## CPM Configuration
Following snapshots show the configuration done in CPM GUI inside Versal CIPS IP.  
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

![image](https://github.com/user-attachments/assets/85abf016-1cdf-491b-b9fd-de953c0bbc75)


![image](https://github.com/user-attachments/assets/0be791f6-d156-4df3-a5a9-d9ffe0806c0d)


![image](https://github.com/user-attachments/assets/bb1e0eab-aff9-414d-9881-2975babe0ce5)


![image](https://github.com/user-attachments/assets/edc55176-d45e-4ca2-9726-9f111de17d01)


![image](https://github.com/user-attachments/assets/c8e086d5-c55e-4c82-915c-540cc4bbd951)


![image](https://github.com/user-attachments/assets/0d1ea2bb-bbc2-4d6c-b466-bdcf6537f1ce)


![image](https://github.com/user-attachments/assets/bc98d36e-2d27-4853-acef-22328415d906)



## Test Scripts

### Pre-requisite to source this script: QDMA driver must be installed in the host and it is linked to the QDMA End point running on the VPK120 board.

Following scripts are provided with the CED for reference. They are available in scripts folder of this CED. 
1. qdma_test_h2c_mm.sh -- Tests the MM data path of the design. This script performs the following steps. 
  - Identify bus, device, function (BDF) numbers of the PCIe slot to which VPK120 board is connected to. This design is set with DEVICE_ID of "10EE". This value is        used for the BDF identification process. 
  - Create MM QID for H2C/C2H directions
  - Start the QID
  - Perform H2C-MM DMA transfer to 0x72000000000 DDR address.
  - Initiate IPI interrupt to A72 processor in Versal Premium device. IPI message sent through IPI interrupt consists of the following details. 
    - DDR address used in H2C-MM DMA transfer
    - QID used in H2C-MM DMA transfer
    - Size of the H2C-MM DMA transfer
  
2. qdma_test_h2c_st.sh -- Tests the ST data path of the design. This script requires h2c_data.txt file. This script performs the following steps. 
  - Identify bus, device, function (BDF) numbers of the PCIe slot to which VPK120 board is connected to. This design is set with DEVICE_ID of "10EE". This value is        used for the BDF identification process.
  - This script has desc_bypass_en, pfetch_bypass_en, trfr_size0, trfr_size1, trfr_size2 variables.
    - desc_bypass_en, pfetch_bypass_en are used to set different C2H-ST use modes (Simple bypass, Csh bypass, Csh Internal) for C2H-ST QID. 
    #### Simple bypass mode --> desc_bypass_en = 1, pfetch_bypass_en = 1
    #### Csh bypass mode --> desc_bypass_en = 1, pfetch_bypass_en = 0
    #### Csh Internal mode --> desc_bypass_en = 0, pfetch_bypass_en = 0
    - trfr_size0 - size of DMA transfer with Csh Internal mode
    - trfr_size1 - size of DMA transfer with Csh bypass mode
    - trfr_size2 - size of DMA transfer with simple bypass mode
   - Create ST QID for H2C-ST direction
   - Create ST QID for C2H-ST direction based on desc_bypass_en, pfetch_bypass_en
   - Start the QID H2C-ST and C2H-ST directions.
   - Perform H2C-ST DMA transfer to PL
  
3. access_PS_peripherals.sh -- Tests the access to the memory regions such as OCM, RTCA, SBI, QSPI, CPM.
  - This script assumes BDF value of 01000 to access the PMC peripherals. 

4. host_profile_noc0_1.sh -- Programs host profile registers of QDMA to perform MM transfers to NoC Ch#0 and Ch#

## Hardware Test flow

### Following steps need to be run on the machine with JTAG connection to the VPK120 board. 

#### 1. Program Boot image using JTAG

#### 2. Setup TeraTerm terminal with the settings shown in the figure below. How to identify the teraterm port to use?

![image](https://github.com/user-attachments/assets/5dc9fc04-26d9-4ba5-9e89-34afd8b3255f)


#### 3. Launch xsdb and read SBI_CONTROL register at 0xF1220004 address. This register needs to be set to 0x29 to load the PLD PDI from host. This step is essential to get dma transfer step to load pld pdi using QDMA driver. 

![image](https://github.com/user-attachments/assets/50cdd45b-5bf3-4f71-b622-b4217c6ac585)


If the JTAG cable is connected to a remote host, use the command "conn -host <host_name or host IP address> before connecting to the board using "ta" command (shown below)

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


Following snapshot shows the PLM log after programming boot.pdi to VPK120 board.

![image](https://github.com/user-attachments/assets/166f663a-9ffb-4287-9022-f5c54730807e)

Following snapshot shows the PLM log after programming pld.pdi to VPK120 board using QDMA driver. 

![image](https://github.com/user-attachments/assets/2c4553d0-5d0a-4f36-bfa7-70fd4c1c9626)

Following snapshot shows the result of sourcing the access_PS_peripherals.sh. This script tries to access the PMC peripherals - RTCA, OCM, QSPI, CPM, SBI

![image](https://github.com/user-attachments/assets/ab4beb0e-b385-4895-91aa-24ce706d55c4)

Following snapshot shows the output on TeraTerm after sourcing H2C_MM test script in PCIe Host.

![image](https://github.com/user-attachments/assets/55adb2c3-f28c-4c3e-b8a3-d4fa4282498c)

## References
#### PG347 - https://docs.amd.com/r/en-US/pg347-cpm-dma-bridge?tocId=oTd_ZrdYcOWw7fqmc3hb9g
#### QDMA Linux Driver documentation (Master page) - https://xilinx.github.io/dma_ip_drivers/master/QDMA/linux-kernel/html/index.html
#### QDMA Driver Source - https://github.com/Xilinx/dma_ip_drivers
#### Inter Processor Interrupts - https://docs.amd.com/r/en-US/am011-versal-acap-trm/Inter-Processor-Interrupts
#### Address remapping feature with AXI-NoC - https://docs.amd.com/r/en-US/pg313-network-on-chip/Address-Re-mapping
