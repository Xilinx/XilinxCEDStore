This example design is designed to illustrate the capabilities of using the 
PCIe link for debug instead of using the JTAG connection to the device. This
is known as "HSDP-over-PCIe" and there are software and hardware components
of getting this debug methodology to work. The appendix of PG346 contains a
detailed description of the hardware and software components, but much of the
information is contained here for brevity. There is an associated driver that 
must be used in tandem with this design, the latest version is found on GitHub
at this link: https://github.com/Xilinx/hsdp-pcie-driver.

There are two modes to use HSDP-over-PCIe; they are known as mgmt mode and 
user mode. Mgmt mode is more robust; it has higher throughput, can be used for 
the hardened debug cores like IBERT, SYSMON, and DDRMC, as well as user debug 
cores, and can issue direct AXI reads and writes to the NOC. User mode requires 
fewer design requirements, but can only be used for user debug cores, so it is 
more limiting. This example design can perform both mgmt mode and user mode 
debug for comparison. The mgmt mode debug design requirements and driver setup 
process is different between CPM4 and CPM5 due to different slave bridge address
translation features.

This section is going to discuss the driver's parameters that must correlate to
the design for the driver to work. The configuration header file is found at
<parent-path>/hsdp-pcie-driver/src/hsdp_pcie_user_config.h and should already 
be configured to work with this example design, see the comments in the file.
The struct mgmt_bar_space_info should be set for mgmt mode debug and the struct
user_bar_space_info, ergo struct debug_hub_info, should be set for user mode 
debug. The following pseudo-code adds comments to each field for clarity.

  /* User mode debug */
  struct debug_hub_info {
    .axi_address, // address of the debug hub, can use NOC NMU remapping 
    .bar_index,   // PCIe BAR to target reads and writes to reach debug hub
    .bar_offset,  // PCIe BAR address offset to reach debug hub
    .size         // size of the debug hub in the memory map
  }

  /* CPM4 mgmt mode debug */
  struct mgmt_bar_space_info {
    .type,                  // = MT_CPM4
    .dma_bar_index,         // = PCIe BAR to target HSDP_DMA register block at 
                            //   address 0xFE5F0000
    .dma_bar_offset,        // = PCIe BAR address offset to hit above address
    .bridge_ctl_bar_index,  // = PCIe BAR to target slave bridge register block 
                            //   which defaults to 0x600000000
    .bridge_ctl_bar_offset, // = PCIe BAR address offset to hit above address
    .bridge_bar_index,      // = AXI BAR that the DPC DMA needs to configure and
                            //   target when accessing host memory 
    .bridge_bar_offset,     // = AXI BAR aperture base address for the DPC DMA
                            //   to target when accessing host memory
    .bridge_bar_size        // = AXI BAR aperture size for the DPC DMA to target
                            //   when accessing host memory
  }

  /* CPM5 mgmt mode debug */
  struct mgmt_bar_space_info {
    .type,                  // = MT_CPM5
    .dma_bar_index,         // = PCIe BAR to target HSDP_DMA register block at 
                            //   address 0xFE5F0000
    .dma_bar_offset,        // = PCIe BAR address offset to hit above address
    .bridge_ctl_bar_index,  // = PCIe BAR to target the CPM5_DMA[0,1]_ATTR 
                            //   register block at 0xFCE[1,9]0000
    .bridge_ctl_bar_offset, // = PCIe BAR address offset to hit above address
    .bridge_ctl_bar_table_entry, // = BDF table entry to be configured from the
                                 //   CPM5_DMA[0,1]_CSR register block at 
                                 //   0xFCE[2,9]0000 so the DPC DMA can target
                                 //   it
    .bridge_bar_offset,     // = AXI window (subdivided from AXI BAR) aperture 
                                 base address for the DPC DMA to target when 
                            //   accessing host memory; goes to BDF table entry
    .bridge_bar_size        // = AXI window (subdivided from AXI BAR) size for
                            //   the DPC DMA to target when accessing host 
                            //   memory; goes to BDF table entry
  }
 
This section is going to discuss the steps to take after loading the bitstream
to the device to begin debugging over the PCIe link. It assumes the driver has
been downloaded or cloned to the host PC, the driver configuration file has
been reviewed, the bitstream programmed to the device successfully, and the 
PCIe link has been established.

  Step 1 : Compile and load the driver to the kernel
    
    $> cd <parent-path/hsdp-pcie-driver 
    $> make install
    $> make insmod

  Step 2 : Launch hw_server on the debug Host PC

    $> hw_server -e "set dpc-pcie /dev/hsdp_mgmt_<BB:DD.F>" //mgmt mode
      OR
    $> hw_server -e "set pcie-debug-hub /dev/hsdp_user_<BB:DD.F>_<name>"

  Step 3 : Open Vivado Hardware Manager and connect to the hw_server instance
  
  Step 4 : Debug in the Vivado IDE after specifying probes file (.ltx) to 
           Vivado IDE 
             - capture and view ILA waveforms 
             - control and view VIO signals 
             - review hardened debug cores (if mgmt mode)

           !IMPORTANT! : The default probes file from Vivado will specify the
                         debug hub's address offset as 0x2010000000 for a CPM4
                         example design, which is correct when originating 
                         from the PMC master. This means that it will work with 
                         a JTAG or mgmt mode debug session. However, the address 
                         offset needs to be 0xFE600000 for user mode debug due 
                         to the example design configuration. You must modify 
                         the probes file so the address info is set to that 
                         value for user mode debug to work properly.

  Step 5 : If mgmt mode debug, connect to the debug host using XSDB and 
           specify target "DPC" and issue mrd and mwr commands 
  
