# ecam_pkg.tcl
#
# Config-space windows and standard PCI/PCIe/CXL ID tables. BASE below are
# fixed platform constants (confirmed directly, not .hwh-discovered -- same
# category as control::RST_PL_ADDR), and every ID table here is PCIe/CXL
# Base Spec data, true for any conformant device regardless of this CED's
# own RTL.

namespace eval ecam {
  # "rp" = this design's own Root Port (Ctrl1), Type 1 header.
  # "ep" = the one downstream/remote Endpoint attached to the link, reached
  # via the RP's own address translation, Type 0 header. ("Local"/"remote"
  # describe which side of the PCIe/CXL link -- do not confuse with
  # design::connect's JTAG target locality.)
  variable BASE
  array set BASE {rp 0xE0000000 ep 0xE0100000}
  variable TARGET_NAMES {rp ep}

  # Standard PCI header BAR-slot counts (PCIe Base Spec, header type 0 vs 1).
  # rp is Type 1 (bridge): BAR0/BAR1 only (offsets 0x10/0x14), then bus-number
  # + I/O/mem/prefetch window registers instead of BAR2-5.
  # ep is Type 0 (endpoint): BAR0-BAR5 (offsets 0x10-0x24).
  variable BAR_COUNT
  array set BAR_COUNT {rp 2 ep 6}

  # Standard PCI Capability ID -> name (PCIe Base Spec Ch. 7, 8-bit IDs)
  variable PCI_CAP_NAMES
  array set PCI_CAP_NAMES {
    0x00 {Null Cap.}                     0x01 {PCI Power Management}
    0x02 {AGP}                           0x03 {VPD}
    0x04 {Slot Identification}           0x05 {MSI}
    0x06 {CompactPCI Hot Swap}           0x07 {PCI-X}
    0x08 {HyperTransport}                0x09 {Vendor Specific}
    0x0A {Debug Port}                    0x0B {CompactPCI Central Resource Control}
    0x0C {PCI Hot-Plug}                  0x0D {PCI Bridge Subsystem Vendor ID}
    0x0E {AGP 8x}                        0x0F {Secure Device}
    0x10 {PCI Express}                   0x11 {MSI-X}
    0x12 {SATA Data/Index Configuration} 0x13 {Advanced Features (AF)}
    0x14 {Enhanced Allocation (EA)}      0x15 {Flattening Portal Bridge (FPB)}
  }

  # Standard PCIe Extended Capability ID -> name (PCIe Base Spec Ch. 7,
  # 16-bit IDs) -- pure PCIe-spec data, true for any conformant device.
  variable PCIE_EXT_CAP_NAMES
  array set PCIE_EXT_CAP_NAMES {
    0x0000 {Null Ext. Cap.}                        0x0001 {Advanced Error Reporting (AER)}
    0x0002 {Virtual Channel (VC)}                  0x0003 {Device Serial Number}
    0x0004 {Power Budgeting}                        0x0005 {Root Complex Link Declaration}
    0x0006 {Root Complex Internal Link Control}     0x0007 {Root Complex Event Collector Endpoint Association}
    0x0008 {Multi-Function Virtual Channel (MFVC)}  0x0009 {Virtual Channel (VC) with MFVC}
    0x000A {RCRB Header}                            0x000B {Vendor-Specific Extended (VSEC)}
    0x000C {Configuration Access Correlation (CAC)} 0x000D {Access Control Services (ACS)}
    0x000E {Alternative Routing-ID Interpretation (ARI)} 0x000F {Address Translation Services (ATS)}
    0x0010 {Single Root I/O Virtualization (SR-IOV)} 0x0011 {Multi-Root I/O Virtualization (MR-IOV)}
    0x0012 {Multicast}                              0x0013 {Page Request Interface (PRI)}
    0x0015 {Resizable BAR}                           0x0016 {Dynamic Power Allocation (DPA)}
    0x0017 {TPH Requester}                           0x0018 {Latency Tolerance Reporting (LTR)}
    0x0019 {Secondary PCI Express}                   0x001A {Protocol Multiplexing (PMUX)}
    0x001B {Process Address Space ID (PASID)}        0x001C {LN Requester (LNR)}
    0x001D {Downstream Port Containment (DPC)}       0x001E {L1 PM Substates}
    0x001F {Precision Time Measurement (PTM)}        0x0020 {PCI Express over M-PHY (M-PCIe)}
    0x0021 {FRS Queueing}                            0x0022 {Readiness Time Reporting}
    0x0023 {Designated Vendor-Specific Extended (DVSEC)} 0x0024 {VF Resizable BAR}
    0x0025 {Data Link Feature}                       0x0026 {Physical Layer 16.0 GT/s}
    0x0027 {Lane Margining at the Receiver}          0x0028 {Hierarchy ID}
    0x0029 {Native PCIe Enclosure Management (NPEM)} 0x002A {Physical Layer 32.0 GT/s}
    0x002B {Alternate Protocol}                      0x002C {System Firmware Intermediary (SFI)}
    0x002D {Shadow Functions}                        0x002E {Data Object Exchange (DOE)}
    0x002F {Device 3}                                0x0030 {Integrity and Data Encryption (IDE)}
    0x0031 {Physical Layer 64.0 GT/s}                0x0032 {Flit Logging}
    0x0033 {Flit Performance Measurement}            0x0034 {Flit Error Injection}
    0x0035 {Streamlined Virtual Channel (SVC)}        0x0036 {MMIO Register Block Locator (MRBL)}
  }

  variable DVSEC_EXT_CAP_ID 0x0023   ;# Designated Vendor-Specific Ext Cap (standard PCIe ID)
  variable CXL_VENDOR_ID    0x1E98   ;# CXL Consortium Vendor ID, DVSEC Header 1

  # Host MMIO windows handed out to the EP's BARs by ecam::setup_ep_bars.
  # The low window is used by default; the high window is only used as a
  # fallback if the BAR footprint doesn't fit in the low one. Both sit
  # entirely above 4 GB, so only 64-bit Memory BARs can be placed in them.
  variable ALLOC_BASE_LOW  0x600000000
  variable ALLOC_SIZE_LOW  0x200000000  ;# 8 GB
  variable ALLOC_BASE_HIGH 0x8000000000
  variable ALLOC_SIZE_HIGH 0x4000000000 ;# 256 GB

  # Set by ecam::setup_ep_bars on success; checked by ecam::require_ep_bars_
  # setup, which ecam::setup_hdm's "decoder" mode calls before anything else
  # -- its Component Register block is only reachable via the ep's own BAR,
  # which must already be sized/placed.
  variable EP_BARS_SETUP 0

  # CXL DVSEC ID -> name (CXL 3.x Spec Ch. 8.1 -- Vendor ID 0x1E98 sub-structures)
  variable CXL_DVSEC_ID_NAMES
  array set CXL_DVSEC_ID_NAMES {
    0x0000 {PCIe DVSEC for CXL Devices}        0x0002 {Non-CXL Function Map DVSEC}
    0x0003 {CXL Extensions DVSEC for Ports}    0x0004 {GPF DVSEC for CXL Port}
    0x0005 {GPF DVSEC for CXL Device}          0x0007 {PCIe DVSEC for Flex Bus Port}
    0x0008 {Register Locator DVSEC}            0x0009 {MLD DVSEC}
    0x000A {PCIe DVSEC for Test Capability}
  }

  # HDM (Host-managed Device Memory) setup constants, used by
  # ecam::setup_hdm. Base is fixed well above the 1 TB a device typically
  # advertises, so the assigned HDM range never overlaps host memory below
  # that mark; the 8 TB size limit is a matching safety margin (both modes
  # -- DVSEC Range registers and HDM Decoder Capability -- reject a
  # size/combined-size beyond it rather than silently misprogramming).
  variable HDM_BASE           0x0000080000000000 ;# 8 TB
  variable MAX_HDM_RANGE_SIZE 0x0000080000000000 ;# 8 TB

  # Fixed offset from a Component Register block base (BAR base + Register
  # Locator DVSEC offset) to the CXL.cachemem register range holding the
  # CXL_Capability_Header (CXL 3.x Sec. 8.2.4.1).
  variable CXL_CACHEMEM_OFFSET 0x1000

  # CXL_Capability_ID -> name (CXL 3.x Table 8-22), for the CXL Capability
  # array ecam::setup_hdm walks to find the HDM Decoder Capability.
  variable CXL_CAP_ID_NAMES
  array set CXL_CAP_ID_NAMES {
    0x0000 {CXL NULL Capability}                    0x0001 {CXL Capability}
    0x0002 {CXL RAS Capability}                      0x0003 {CXL Security Capability}
    0x0004 {CXL Link Capability}                      0x0005 {CXL HDM Decoder Capability}
    0x0006 {CXL Extended Security Capability}         0x0007 {CXL IDE Capability}
    0x0008 {CXL Snoop Filter Capability}               0x0009 {CXL Timeout and Isolation Capability}
    0x000A {CXL.cachemem Extended Register Capability} 0x000B {CXL BI Route Table Capability}
    0x000C {CXL BI Decoder Capability}                 0x000D {CXL Cache ID Route Table Capability}
    0x000E {CXL Cache ID Decoder Capability}           0x000F {CXL Extended HDM Decoder Capability}
    0x0010 {CXL Extended Metadata Capability}
  }
}
