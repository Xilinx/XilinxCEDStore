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
![Versal_CPM_QDMA_Accel_Sys_Design_block_diagram](https://media.gitenterprise.xilinx.com/user/2450/files/fdd96895-11f1-4026-a5e6-579b79317a46)

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

![image](https://media.gitenterprise.xilinx.com/user/2450/files/7d13d338-07ac-408c-baed-025eb152d655)

The table below presents various memory regions accessible through the PCIe link. This table illustrates two levels of address translations. 
1. The AXI-Bridge functionality in CPM5 is used to translate PCIe BAR offset to different offsets accessible through the PCIe NoC. The PCIe BAR size is set to 128MB and the PCIe base address is translated to 0x201_0000_0000. 
2. The second translation occurs within the AXI-NoC. This translation aligns the addresses coming from the PCIe NoC port with the address regions of the PMC, CPM, IPI peripherals.
![image](https://media.gitenterprise.xilinx.com/user/2450/files/bcf1bdf9-f774-4caf-a301-b5b512600289)

### MM Data flow
The following flowchart depicts the data path flow for the Memory mapped (MM) mode of transfer:
![image](https://media.gitenterprise.xilinx.com/user/2450/files/fe1aac2e-b216-41a1-a7ac-db50071f4fcc)

### ST Data flow
The following flowchart illustrates the data path flow for Stream (ST) mode of transfer:
![image](https://media.gitenterprise.xilinx.com/user/2450/files/87063e89-e4b7-458a-90a1-b8e26b2ff5b6)


## Tool Requirements
 - Vivado 2025.1  
 - Vitis 2025.1

## Design Steps

#### 1. Open Vivado and click on "open Example Project"
![image](https://media.gitenterprise.xilinx.com/user/2450/files/e786e542-9e1d-468b-b227-ed51c0732253)

#### 2. "Open Example Project" pop-up is launched by Vivado. Click Next on this page. 
![image](https://media.gitenterprise.xilinx.com/user/2450/files/8c76d50e-c361-4c83-b6eb-41c23c075cd0)

#### 3. In "Select Project Template" page, there are "Templates" and "Description" section. In the Templates section, look for "Versal CPM5 QDMA Based Acceleration System design" template. There is a search icon at the top of the Templates section to perform search. Click Next after selecting this CED template.
![image](https://media.gitenterprise.xilinx.com/user/2450/files/862d5788-c91e-48de-84e0-690179e1e27f)

#### 4. Select project name and project location.
![image](https://media.gitenterprise.xilinx.com/user/2450/files/d5ef9084-ac73-44d7-90a6-f3e4f9bb0927)

#### 5. This CED targets VPK120 board. This board has two variants of the Versal Premium device. By default, xcvp1202-vsva2785-2MP-e-S device is selected. Alternatively, a MHP part can be selected by using "Switch Part" option in this page. 
![image](https://media.gitenterprise.xilinx.com/user/2450/files/756a9f30-9e32-44ad-a487-1adc97eef084)

When "Switch Part" option is clicked, a pop-up will be launched with option to select either xcvp1202-vsva2785-2MP-e-S or xcvp1202-vsva2785-2MHP-e-S device for the VPK120 board. This CED supports both parts. When "MP" device is selected CPM5-QDMA is set to Gen4 x8 configuration. For "MHP" device, CPM5-QDMA is set to Gen5 x8 configuration.

![image](https://media.gitenterprise.xilinx.com/user/2450/files/67de8512-874d-4c1f-a7a0-796337f7cec0)

#### 6. "Select Design and Preset" page is launched. The options on this page are fixed. Click Next on this page. 
![image](https://media.gitenterprise.xilinx.com/user/2450/files/21200584-6876-48a6-b0cb-27618c6b89e7)

#### 7. This is the final page - "New Project Summary". It lists the options selected in the previous pages. 
  - CED template - Versal CPM5 QDMA Based Acceleration System design
  - Board - Versal VPK120 Evaluation Platform
  - Part - xcvp1202-vsva2785-2MP-e-S (in this example)
  - Family - Versal Premium
  - Package - vsva2785
  - Speed Grade : -2MP (in this example)
Click "Finish" on this page. This will initiate CED creation process.
![image](https://media.gitenterprise.xilinx.com/user/2450/files/38218274-570b-4454-b326-47dae8c5c904)

#### 8. After the CED has been created, generate .pdi by selecting Generate Device Image step in the "Flow Navigator" section of Vivado GUI. 

#### 9. This design requires a baremetal application to be executing while performing MM transfers. Following command needs to be executed after generating the PDI from Vivado. ipi_cdma_intr.elf and qdma_accel_sys.bif are provided in src directory of this CED. 

qdma_accel_sys.bif assumes that ipi_cdma_intr.elf and design_1_wrapper_pld.pdi are in the same directory as the bif file.  
bootgen -arch versal -image ./qdma_accel_sys.bif -o ./boot_with_elf.pdi -w

## CPM Configuration
The following snapshots show the configuration done in CPM GUI inside Versal CIPS IP.  
![image](https://media.gitenterprise.xilinx.com/user/2450/files/a3a5d39d-3086-4578-a558-dce5c90c6a85)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/c241e080-36b0-4670-9bdd-e127e78d1978)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/6eca83d9-f6d4-47ad-bb61-b44c9861ab90)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/2251a957-44ef-4af4-9fda-f413b4a61adb)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/6cda2954-d037-4123-af2e-8b2faaa923f5)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/e730f0dc-b190-4ca6-990a-f85c701b6d89)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/91d14150-9827-4baa-a763-149732d3530f)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/aa96b895-6f0e-423b-b3a7-510e61d07428)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/a1e7edd2-c6f2-4496-ab2c-5386ee6524d7)

## PMC Configuration
The following snapshots show the design PMC configuration inside Versal CIPS IP.

![image](https://media.gitenterprise.xilinx.com/user/2450/files/adddd576-9e38-4e29-8682-45ea82553940)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/2eb07068-f778-4a6d-be60-48215f4d3cc6)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/15f6a9d2-9299-45e4-a960-f806060ee79a)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/eb6f0daf-e5ea-4880-9e54-beb6090a5179)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/0dff63b5-5050-4160-918a-3923e1721e50)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/f9b773d3-f47f-433f-a095-b7894cfcbf10)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/de71fc6c-8fb6-4782-8f6b-bb3ef83fb6d8)


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

### Following steps need to be run on the machine with JTAG connection to the VPK120 board. 

#### 1. Program Boot image using JTAG

#### 2. Setup TeraTerm terminal with the settings shown in the figure below. How to identify the teraterm port to use?

![image](https://media.gitenterprise.xilinx.com/user/2450/files/42a42f7d-68e4-4c52-9f98-abc33444695d)

#### 3. Launch xsdb and read SBI_CONTROL register at 0xF1220004 address. This register needs to be set to 0x29 to load the PLD PDI from host. This step is essential to get dma transfer step to load pld pdi using QDMA driver. 

![image](https://media.gitenterprise.xilinx.com/user/2450/files/3c781485-bade-4a26-8e0f-c220c0b3d342)

If the JTAG cable is connected to a remote host, use the command "conn -host <host_name or host IP address> before connecting to the board using "ta" command (shown below)

![image](https://media.gitenterprise.xilinx.com/user/2450/files/b592a6da-8537-49e8-b09b-71b7df6f7da8)

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

![image](https://media.gitenterprise.xilinx.com/user/2450/files/cb03b486-ded3-4051-8b70-66b8529f53b9)

Following snapshot shows the PLM log after programming pld.pdi to VPK120 board using QDMA driver. 

![image](https://media.gitenterprise.xilinx.com/user/2450/files/7232b22d-2a28-4d2d-a8b7-e4f2cb56d09a)

Following snapshot shows the result of sourcing the access_PS_peripherals.sh. This script tries to access the PMC peripherals - RTCA, OCM, QSPI, CPM, SBI

![image](https://media.gitenterprise.xilinx.com/user/2450/files/aee0cf64-78f1-46db-9c57-429ac9f8e104)

Following snapshot shows the output on TeraTerm after sourcing H2C_MM test script in PCIe Host.

![image](https://media.gitenterprise.xilinx.com/user/2450/files/c82c2afb-ebb9-4917-a0dc-152543dff0d2)

## References
#### PG347 - https://docs.amd.com/r/en-US/pg347-cpm-dma-bridge?tocId=oTd_ZrdYcOWw7fqmc3hb9g
#### QDMA Linux Driver documentation (Master page) - https://xilinx.github.io/dma_ip_drivers/master/QDMA/linux-kernel/html/index.html
#### QDMA Driver Source - https://github.com/Xilinx/dma_ip_drivers
#### Inter Processor Interrupts - https://docs.amd.com/r/en-US/am011-versal-acap-trm/Inter-Processor-Interrupts
#### Address remapping feature with AXI-NoC - https://docs.amd.com/r/en-US/pg313-network-on-chip/Address-Re-mapping
