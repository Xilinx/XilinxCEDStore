TANDEM PCIE

This example design is provided to show off the tandem PCIe configuration
method, hereafter "tPCIe capability", for Versal devices. The tPCIe  
capability may be required for a Versal device that has a PCIe endpoint
configured in a system that should meet the PCIe specification timing
requirement that the device be ready to link train 120 ms after power 
becomes valid. The tPCIe capability may also be desirable in a system to 
reduce the storage required for the stage one bitstream, at the expense  
of additional time, software, and design overhead required to program the
stage two bitstream to the device. When tandem PCIe is selected as the 
configuration method, the Vivado tools will split the full bitstream into 
two parts: stage one will contain, primarily, CPM configuration data,
PMC firmware, and NOC configuration, while stage two will contain all other
configuration data for the device, both hardware and software. Stage one
will be noticeably smaller than stage two, allowing it to be quickly 
loaded from an external device interface and programmed to the device after
power is stable and reset is deasserted. It is recommended to only use the
tandem PCIe configuration method if your system requires it.

Previous generations of AMD devices used the AMD MCAP Vendor Specific 
Extended Capability (VSEC) to enable the tandem PCIe solution, which 
relied on PCIe CfgWr TLPs and a hardened connection to the configuration 
engine to actually transfer the bitstream data to the device. While using
the MCAP VSEC is still an option for Versal devices, it is not recommended 
due to its slow throughput. For improved performance, the AMD DMAs should 
be employed, namely QDMA. For devices containing CPM5, the AMD QDMA is the
only hardened DMA engine available, while devices containing CPM4 may use 
either the AMD QDMA or XDMA engine. Detailed information about CPM and the
DMA engines can be found in PG346 and PG347. The programming datapath from CPM
to the configuration engine must now go through the NOC, so there are required
design elements that must be properly enabled and connected using Vivado. All
of these design elements are already embedded within this example design, but
they are listed below so they may cross-referenced to the example design.

  1. Create an instance of the CIPS IP and enable the CPM to NOC and NOC to 
     PMC interfaces in the CIPS GUI
  2. Create an instance of the AXI NOC IP and connect the CPM master
     to the AXI NOC and the AXI NOC to the PMC slave 
  3. Assign the pspmc_0_psv_pmc_slave_boot_stream slave to the CPM master 
     in the Address Editor

The QDMA driver that should be used with this design can be found on GitHub
at the below link and there is a set of example Linux shell scripts that can 
be used directly or referenced to test the QDMA user applications in the
scripts.tar tarball. Refer to the QDMA documentation for details on how to 
compile and install the driver on your host system.

  https://github.com/Xilinx/dma_ip_drivers

The following steps are an example of how a user may test the tPCIe capability
and other design elements, assuming that they've taken this example design
through bitstream generation and have a stage1.pdi and a stage2.pdi file and
are unfamiliar with the driver. The details of these commands and instructions 
can be found in the QDMA driver documentation; the steps are just listed here 
for ease of use. 

  1. Download or clone the dma_ip_drivers repo from GitHub to the host system
  2. Compile the QDMA driver and applications 

    $> cd <path>/dma_ip_drivers/QDMA/linux-kernel
    $> make TANDEM_BOOT_SUPPORTED=1 //FIXME: option will be changed later 

  3. Install the compiled binaries 

    $> make install

  4. Load the stage one bitstream to the device through JTAG or another method 
  5. Reboot the host system 
  6. Load the QDMA driver(s) 

    $> modprobe qdma-pf //physical functions
    $> modprobe qdma-vf //virtual functions (if necessary)

  7. Using sysfs, set the max number of queue pairs. This is set to 3 in this
     example because there will be 3 queues for data transfer: 1 H2C and 1 C2H
     memory mapped, and 1 H2C streaming. Assume the B:D.F is b3:00.0.

    $> echo 3 > /sys/bus/pci/devices/0000:b3:00.0/qdma/qmax

  8. Add the queues. Queue 0 is the memory-mapped host-to-card queue, Queue 1
     is the memory-mapped card-to-host queue, and Queue 2 is the streaming
     host-to-card queue

    $> dma-ctl qdmab3000 q add idx 0 mode mm dir h2c
    $> dma-ctl qdmab3000 q add idx 1 mode mm dir c2h
    $> dma-ctl qdmab3000 q add idx 2 mode st dir h2c

  9. Start the queues. Queue 0 will be used to transfer the stage two bitstream 
     to the configuration engine through the slave boot interface (SBI) and
     requires the aperture_sz parameter to be set

    $> dma-ctl qdmab3000 q start idx 0 dir h2c aperture_sz 4096
    $> dma-ctl qdmab3000 q start idx 1 dir c2h 
    $> dma-ctl qdmab3000 q start idx 2 dir h2c 

  10. Transfer the stage two bitstream to the device to be programmed, 
      targeting the SBI FIFO using address 0x102100000 

    $> dma-to-device -d /dev/qdmab30000-MM-0 -f <stage2.pdi> -s <size> -a 0x102100000

      !! IMPORTANT !! 
      If a device with CPM4 (not CPM5) is selected for this CED, it is required to 
      remove the driver (rmmod qdma-pf), then go back to Step 6 to re-initialize 
      the driver after loading the stage two bitstream to the device.

  11. (Optional) Perform H2C and C2H MM DMAs to BRAM and H2C ST DMA to the PL
      to verify that the stage two has successfully been programmed to the
      device
 
    // H2C MM DMA to BRAM
    $> dma-to-device -d /dev/qdmab30000-MM-0 -f /dev/urandom -s 32 -a 0x0 -c 1
    // H2C MM DMA from BRAM
    $> dma-from-device -d /dev/qdmab30000-MM-1 -f frombram.raw -s 32 -a 0x0 -c 1
    // H2C ST DMA to PL
    $> dma-to-device -d /dev/qdmab30000-ST-2 -f /dev/urandom -s 64 

DESIGN FUNCTION EXCHANGE (DFX)

This example design may optionally be generated to include scripts and settings
to demonstrate the DFX feature, which is used to create partial bitstream(s) for
specific partitions within a design. This is a useful feature for users that 
want to have a static portion of a design that has hot-swappable functions 
embedded within it. As elementary examples, it would be possible to swap a 32 
bit count down timer for a 16 bit up counter, swap hardcoded filter coefficients 
of an FIR filter, or re-sizing BRAM storage for a module. The possibilities are 
endless as to how a user may employ DFX within their system and more complex 
examples are contained within UG909. The definition of reconfigurable partitions
and creation of them must be done through very specific workflows within Vivado
and it is recommended to generate this example design, explore how they work,
and only then integrate them into a project. The DFX workflows are supported in
both the non-project and project mode with Vivado; reference UG909 and UG947 
for more complete details. This example design will use Vivado in project mode,
contain two simple reconfigurable partitions, each with two reconfigurable
modules, and the method of delivery of those partial bitstreams to the
configuration engine is identical to the Stage 2 bitstream of the tPCIe portion
of this example design; namely the QDMA engine of CPM.

The first reconfigurable partition is a simple counter connected to the VIO IP
core for status and control. By default, it is a 16 bit wide counter, but the
other module implementation is an 8 bit wide counter. Because partition 
boundaries must be identical between implementations, the other 8 bits of the
counter are tied to zero. By using the Vivado Hardware Manager and setting the
VIO IP core output connected to the counter enable signal and examining the VIO
IP core input connected to the counter output, it is easy to see which module 
implementation has been programmed to the device by simply confirming whether 
all 16 bits are changing or only 8 bits.

The second reconfigurable parition is inserted between the write data path of
the addressable BRAM in the design. By default, it is a simple passthrough, but
the alternative implementation reverses the data, nibble-by-nibble. For 
example, writing 0x76543210 to the BRAM will return 0x01234567 when read. This
provides for an easy way to confirm which module implementation has been 
programmed to the device by writing and reading a BRAM word. The BRAM can be
targeted from the host, across the PCIe link, by targeting the correct PCIe
BAR, or a user may target the BRAM from the JTAG connection, if it exists. 

  1. To generate the static and reconfigurable bitstreams for this example
     project, only one additional step must be taken beyond what is already 
     configured at design generation: after synthesis has been ran, source 
     the make_cfg_runs.tcl scripts OR use the Dynamic Function eXchange 
     Wizard to create configuration runs for implementation.

    $> source [get_files -of [get_filesets utils_1] make_cfg_runs.tcl] 

  2. After bitstream generation has completed, notice that additional .pdi
     files (partial bitstreams) have been created in addition to the full
     bitstream image. To deliver a partial bitstream to the device, use the
     QDMA engine of CPM to initiate an AXI-MM H2C transfer to the SBI, as
     described in the tPCIe section above. The partial bitstreams will be 
     named <instance pathname>_partial.pdi.
