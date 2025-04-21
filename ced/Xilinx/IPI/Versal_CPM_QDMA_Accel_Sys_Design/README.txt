Versal CPM5 QDMA Based Acceleration System Design

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
    
For additional details of the CED, please refer to the readme.md file available in the git repository of this CED. 
    
VPK120 board has two device variants with MP and MHP parts.

The VPK120 evaluation kit has a physical x16 edge connector and enables protocol support in two flavors depending on whether overdrive is used or not.
With overdrive, the VPK120 supports: Gen1/2/3/4x16 or Gen5x8.

Without overdrive, the VPK120 supports: Gen1/2/3x16 or Gen4x8.

Gen5 is not supported without overdrive.

Depending on the device selected during the CED creation, the target data rate is selected.

For MP part, design is generated with Gen4 x8 configuration.
For MHP part, design is generated with Gen5 x8 configuration.

NOTE: 
1. This design requires a baremetal application to be executing while performing MM transfers. Following
command needs to be executed after generating the PDI from Vivado. 

qdma_accel_sys.bif assumes that ipi_cdma_intr.elf and design_1_wrapper_boot.pdi are in the same directory as the bif file.  
bootgen -arch versal -image ./qdma_accel_sys.bif -o ./boot_with_elf.pdi -w

2. This CED is only provided for hardware test flow. Simulation is not supported. 

Required Hardware and Tools:

Vivado 2025.1
Vitis 2025.1

Design Steps:

1. Open Vivado and select XHub Stores in Tools tab
2. Install Versal_CPM_QDMA_Accel_Sys_Design
3. Close that window and select Open Example Project
4. Create Versal_CPM_QDMA_Accel_Sys_Design vivado project and generate .pdi by selecting Generate Device Image
This design requires a baremetal application to be executing while performing MM transfers. Following command needs to be executed after generating the PDI from Vivado. ipi_cdma_intr.elf and qdma_accel_sys.bif are provided in src directory of this CED.

qdma_accel_sys.bif assumes that ipi_cdma_intr.elf and design_1_wrapper_boot.pdi are in the same directory as the bif file.
bootgen -arch versal -image ./qdma_accel_sys.bif -o ./boot_with_elf.pdi -w

Test Scripts:

Pre-requisite to source this script: QDMA driver must be installed in the host and it is linked to the QDMA End point running on the VPK120 board.

Following scripts are provided with the CED for reference. They are available in scripts folder of this CED.

1. qdma_test_h2c_mm.sh -- Tests the MM data path of the design. This script performs the following steps.

   - Identify bus, device, function (BDF) numbers of the PCIe slot to which VPK120 board is connected to. This design is set with DEVICE_ID of "10EE". This value is used for the BDF identification process.
   - Create MM QID for H2C/C2H directions
   - Start the QID
   - Perform H2C-MM DMA transfer to 0x72000000000 DDR address.
   - Initiate IPI interrupt to A72 processor in Versal Premium device. IPI message sent through IPI interrupt consists of the following details.
     - DDR address used in H2C-MM DMA transfer
     - QID used in H2C-MM DMA transfer
     - Size of the H2C-MM DMA transfer
2. qdma_test_h2c_st.sh -- Tests the ST data path of the design. This script requires h2c_data.txt file. This script performs the following steps.

   - Identify bus, device, function (BDF) numbers of the PCIe slot to which VPK120 board is connected to. This design is set with DEVICE_ID of "10EE". This value is used for the BDF identification process.
   - This script has desc_bypass_en, pfetch_bypass_en, trfr_size0, trfr_size1, trfr_size2 variables.
   - desc_bypass_en, pfetch_bypass_en are used to set different C2H-ST use modes (Simple bypass, Csh bypass, Csh Internal) for C2H-ST QID.
      - Simple bypass mode --> desc_bypass_en = 1, pfetch_bypass_en = 1
      - Csh bypass mode --> desc_bypass_en = 1, pfetch_bypass_en = 0
      - Csh Internal mode --> desc_bypass_en = 0, pfetch_bypass_en = 0
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

The QDMA driver that should be used with this design can be found on GitHub
at the below link and there is a set of example Linux shell scripts that can 
be used directly or referenced to test the QDMA user applications in the
scripts.tar tarball. Refer to the QDMA documentation for details on how to 
compile and install the driver on your host system.

  https://github.com/Xilinx/dma_ip_drivers

Following steps need to be run on the machine with JTAG connection to the VPK120 board.
1. Program Boot image using JTAG
2. Setup TeraTerm terminal with the settings shown in the figure below. How to identify the teraterm port to use?
3. Launch xsdb and read SBI_CONTROL register at 0xF1220004 address. This register needs to be set to 0x29 to load 
the PLD PDI from host. This step is essential to get dma transfer step to load pld pdi using QDMA driver.
Note: If the JTAG cable is connected to a remote host, use the command "conn -host <host_name or host IP address> 
before connecting to the board using "ta" command (shown below)

The following steps are an example of how a user may test the qdma_accel_sys design,
assuming that they've taken this example design through bitstream generation and 
have a design_wrapper_1_boot.pdi and a pld_with_elf.pdi and are unfamiliar with the driver. 
The details of these commands and instructions can be found in the QDMA driver documentation; 
the steps are just listed here for ease of use. 

Please note that the commands provided in this section assumes VPK120 board to a PCIe slot and 
host has assigned the PCIe slot with a BDF value of 01000.

1. Download or clone the dma_ip_drivers repo from GitHub to the host system
2. Compile the QDMA driver and applications

$> cd <path>/dma_ip_drivers/QDMA/linux-kernel
$> make TANDEM_BOOT_SUPPORTED=1 

3. Install the compiled binaries

$> make install

4. Load the stage one bitstream (design_1_wrapper_boot.pdi) to the device through JTAG or another method
5. Reboot the host system

6. Make sure SBI_CTRL register (0xF1220004) is set to 0x29 using XSDB. 
7. Load the QDMA driver(s)

$> modprobe qdma-pf //physical functions
$> modprobe qdma-vf //virtual functions (if necessary)

8. Source host_profile script to use mm_chn1. 

source ./host_profile_noc0_1.sh

9. Using sysfs, set the max number of queue pairs. This is arbitrarily chosen
as 3 in this example, and also assume the B:D.F is b3:00.0.

$> echo 10 > /sys/bus/pci/devices/0000:b3:00.0/qdma/qmax

10. Add the queues. Queue 0 is the memory-mapped host-to-card queue, Queue 1
is the memory-mapped card-to-host queue, and Queue 2 is the streaming
host-to-card queue

$> dma-ctl qdmab3000 q add idx 0 mode mm dir h2c
$> dma-ctl qdmab3000 q add idx 1 mode mm dir c2h

11. Start the queues. Queue 0 will be used to transfer the stage two bitstream
to the configuration engine through the slave boot interface (SBI) and
requires the aperture_sz parameter to be set

$> dma-ctl qdmab3000 q start idx 0 dir h2c aperture_sz 4096 mm_chn 1
$> dma-ctl qdmab3000 q start idx 1 dir c2h

12. Transfer the stage two (pld_with_elf.pdi) bitstream to the device to be programmed,
targeting the SBI FIFO using address 0x102100000

$> dma-to-device -d /dev/qdmab3000-MM-0 -f <stage2.pdi> -s <size> -a 0x20102100000

13. (Optional) Perform H2C and C2H MM DMAs to BRAM and H2C ST DMA to the PL
to verify that the stage two has successfully been programmed to the
device

// H2C MM DMA to DDR
$> dma-to-device -d /dev/qdmab3000-MM-0 -f /dev/urandom -s 32 -a 0x60000000000 -c 1
// H2C MM DMA from BRAM
$> dma-from-device -d /dev/qdmab3000-MM-1 -f frombram.raw -s 32 -a 0x60000000000 -c 1
// H2C ST DMA to PL
$> dma-to-device -d /dev/qdmab3000-ST-2 -f /dev/urandom -s 64

References:
PG347 - https://docs.amd.com/r/en-US/pg347-cpm-dma-bridge?tocId=oTd_ZrdYcOWw7fqmc3hb9g
QDMA Linux Driver documentation (Master page) - https://xilinx.github.io/dma_ip_drivers/master/QDMA/linux-kernel/html/index.html
QDMA Driver Source - https://github.com/Xilinx/dma_ip_drivers
Inter Processor Interrupts - https://docs.amd.com/r/en-US/am011-versal-acap-trm/Inter-Processor-Interrupts
Address remapping feature with AXI-NoC - https://docs.amd.com/r/en-US/pg313-network-on-chip/Address-Re-mapping
