Versal CPM5 QDMA Based Acceleration System Design

This example design will show-case end user application features to demonstrate system level operation for key features for Versal devices.

This design will cover the following functionalities:

  Segmented Configuration
  Load PLD image over PCIe to SBI – use QDMA driver.
  For the QDMA-MM data path - H2C/C2H:
    - Execution of H2C transfer
    - Generation of IPI Interrupt
    - Processing of H2C data
    - Triggering of an interrupt to the host via the usr_irq interface of CPM5-QDMA from the APU
    - Completion of C2H transfer
  The H2C data processing is initiated by an application on the APU (A72).
  Regarding the QDMA-ST data path - H2C/C2H:
    - Implementation of H2C transfer
    - Processing of H2C data
    - Retrieval of descriptors through the dsc_crdt/dsc_byp interfaces of CPM5-QDMA
    - Execution of C2H transfer
  The C2H-ST transfer is supported using:
    - Internal method
    - Simple bypass method
    - Csh bypass method
  Access to the following memory regions via the PCIe link will be demonstrated
    - OCM
    - RTCA
    - SBI
    - QSPI
    - CPM
    - Inter Processer Interrupt registers

NOTE: This design requires a baremetal application to be executing while performing MM transfers. Following
command needs to be executed after generating the PDI from Vivado. 

qdma_accel_sys.bif assumes that ipi_cdma_intr.elf and design_1_wrapper_pld.pdi are in the same directory as the bif file.  
bootgen -arch versal -image ./qdma_accel_sys.bif -o ./pld_with_elf.pdi -w

Following scripts are provided with the CED for reference. 
1. qdma_test_h2c_mm.sh -- Tests the MM data path of the design. 
2. qdma_test_h2c_st.sh -- Tests the ST data path of the design. This script requires h2c_data.txt file. 
3. access_PS_peripherals.sh -- Tests the access to the memory regions such as OCM, RTCA, SBI, QSPI, CPM.

The QDMA driver that should be used with this design can be found on GitHub
at the below link and there is a set of example Linux shell scripts that can 
be used directly or referenced to test the QDMA user applications in the
scripts.tar tarball. Refer to the QDMA documentation for details on how to 
compile and install the driver on your host system.

  https://github.com/Xilinx/dma_ip_drivers

The following steps are an example of how a user may test the qdma_accel_sys design,
assuming that they've taken this example design through bitstream generation and 
have a design_wrapper_1_boot.pdi and a pld_with_elf.pdi and are unfamiliar with the driver. 
The details of these commands and instructions can be found in the QDMA driver documentation; 
the steps are just listed here for ease of use. 

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

$> dma-to-device -d /dev/qdmab30000-MM-0 -f <stage2.pdi> -s <size> -a 0x20102100000

13. (Optional) Perform H2C and C2H MM DMAs to BRAM and H2C ST DMA to the PL
to verify that the stage two has successfully been programmed to the
device

// H2C MM DMA to DDR
$> dma-to-device -d /dev/qdmab30000-MM-0 -f /dev/urandom -s 32 -a 0x60000000000 -c 1
// H2C MM DMA from BRAM
$> dma-from-device -d /dev/qdmab30000-MM-1 -f frombram.raw -s 32 -a 0x60000000000 -c 1
// H2C ST DMA to PL
$> dma-to-device -d /dev/qdmab30000-ST-2 -f /dev/urandom -s 64