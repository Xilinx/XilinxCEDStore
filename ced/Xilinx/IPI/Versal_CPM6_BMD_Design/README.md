# Versal CPM6 BMD Example Design

| Item | Summary |
|---|---|
| **Primary Purpose** | Demonstrates PCIe Gen6 Bus Master DMA (BMD) capability of the Versal CPM6 hard IP |
| **Configurations** | Controller 0 only (`ctrl0`), Controller 1 only (`ctrl1`), or both controllers simultaneously (`dual`) |
| **Example Type** | IP Example Design |
| **Target Audience** | Verification/FPGA engineers validating the CPM6 PCIe hard IP |
| **Devices Supported** | Versal devices with CPM6 hard IP (supported part `xc2vp3602`) |
| **Tools Required** | Vivado 2026.1, VCS/Verdi version X-2025.06 with UVM 1.1, Avery PLI/apci-xactor version 2025.3_1 |
| **Simulators Validated** | VCS (waveform viewing via Verdi or DVE) |
| **Boards Validated** | N/A |
| **Pre-Built Images** | Not available |
| **Key Features Shown** | Write DMA, Read DMA, MSI/MSI-X/INTx interrupts, Extended Tag / 10-bit Tag, TPH, PASID, VSEC capabilities, dual-controller operation |
| **Not Intended For** | Production deployment, performance benchmarking |
| **Time to First Success** | ~20-25 minutes (compile + optimize + simulate, order of magnitude) |

---

## Options

| Option | Values | Description |
|---|---|---|
| `CTRL_CONFIG` | `Controller_0`, `Controller_1`, `Dual_Controller` | Controller selection |
| `CTRL_LANE_RATE` / `CTRL_LINK_WIDTH` | 16/32/64 GT/s, X1..X8 | Link speed and width |
| `DDR_EN` | true/false | Use LPDDR5 DDR (SoC platform: PS peripherals, NoC, BRAM, DDR). VPK360 (`vsvc3340`) only |
| `IDE` | true/false | PCIe Integrity and Data Encryption (VPK360 only). Forces `DDR_EN` on; not available with `Dual_Controller` |

### IDE
With `IDE` selected the CPM6 IDE capability and the Link and Selective IDE streams are enabled on the selected controller
(`CPM6_CTRLx_IDE_CAP_EN`, `CPM6_CTRLx_LINK_IDE_STREAM_EN`, `CPM6_CTRLx_SELECTIVE_IDE_STREAM_EN`; all three are 0 when `IDE` is off).
IDE keys are programmed by the SEC firmware on RPU R5_0, which reaches DDR through the NoC (PS `LPD_AXI_NOC0`, DDR in legacy mode).
The SoC platform (`platform/run.tcl`) therefore provides DDR, UART0/UART1, TTC0/TTC1 and the IPI1 master (R5_0).
The SEC firmware is not packaged in this CED yet: `fw/` holds a placeholder. See "Running the IDE firmware" below for how to load it
once you have the ELF.

**Simulation with IDE:** the default test is `test_bmd_ide_traffic`. It establishes Link IDE (stream 1, TC0) the same way as `test_bmd_ide_basic`
(keys programmed for the selected controller, CRS disabled, wait for the link stream to be secure) and then runs one BMD write over the secured link
with the root port's requests sent on the IDE stream. `test_bmd_ide_basic` establishes Link IDE only. Both extend the framework `test_ide_basic`.
With IDE the design contains the SoC platform NoC and LPDDR5, so the simulation uses the NoC bind (`XLNOC_DUT_INST` in `sim/verif/dut_inst.sv`)
and copies `nocattrs.dat` into the test run directory.

---

## Overview
This example design demonstrates Bus Master DMA (BMD) capability of the Versal CPM6 hard IP as a PCIe Endpoint. It supports three configurations -- Controller 0 only, Controller 1 only, or both controllers simultaneously -- selected at CED generation time.

By working through this example design, you will learn how to:
- Configure CPM6 lane rate (16/32/64 GT/s) and link width (X1/X2/X4/X8) for one or both controllers
- Drive PCIe Write/Read DMA traffic against the CPM6 hard IP through a UVM testbench
- Build and run the simulation using VCS, with optional Verdi/DVE waveform viewing

### Included Features
- **Write DMA** -- directed and randomized memory write traffic tests
- **Read DMA** -- directed and randomized memory read traffic tests
- **Combined Write+Read** -- concurrent, hand-editable traffic test (`test_bmd_write_read_custom`, default test)
- **Interrupts** -- INTx, MSI, MSI-X
- **Capabilities** -- TPH, PASID, VSEC, Extended Tag, 10-bit Tag
- **Error injection** -- bad data injection, Unsupported Request (UR) generation

---

## Choosing a Configuration

| Configuration | `CTRL_CONFIG.VALUE` | DUT Module | Description |
|---|---|---|---|
| Controller 0 only | `Controller_0` | `ctrl0_bmd_ep` | Single Endpoint on Controller 0 |
| Controller 1 only | `Controller_1` | `ctrl1_bmd_ep` | Single Endpoint on Controller 1 |
| Dual Controller | `Dual_Controller` | `dual_ctrl_bmd_ep` | Both Controller 0 and Controller 1 active as independent Endpoints |

### Architecture Overview
```
tb_top
 └─ ctrl_inst
     └─ dut_inst (ctrl0_bmd_ep / ctrl1_bmd_ep / dual_ctrl_bmd_ep -- see table above)
         ├─ design_1_wrapper           -- Vivado-generated BD wrapper; contains the
         │                                encrypted CPM6 hard IP (GT quads, PCIe hard
         │                                block) -- not visible in waveform/source view
         └─ pcie_app_versal_bmd_top_i  -- open user logic (BMD_AXIST_*): DMA engine,
                                          CSR register file, interrupt control, TPH/VSEC
                                          (instantiated per active controller)
```
A UVM testbench (Avery PCIe VIP as Root Complex, one instance per active controller) drives configuration and traffic against the DUT and checks responses via scoreboards.

---

## Getting Started

### Generating the Example
1. Download and unzip the CPM6 Secure IP package (provided separately) from https://account.amd.com/en/member/cpm6-simulation.html
2. Set the following environment variables (tcsh or bash shell):
   - `AVERY_PLI` -- Avery PLI binary location
     ```
     tcsh: setenv AVERY_PLI <path to avery pli install>
     bash: export AVERY_PLI=<path to avery pli install>
     ```
   - `AVERY_PCIE` -- Avery PCIe source libraries
     ```
     tcsh: setenv AVERY_PCIE <path to avery apci xactor install>
     bash: export AVERY_PCIE=<path to avery apci xactor install>
     ```
   - `CPM6_SECUREIP` -- directory where the CPM6 Secure IP package was extracted
     ```
     tcsh: setenv CPM6_SECUREIP <path to extracted cpm6 secureip>
     bash: export CPM6_SECUREIP=<path to extracted cpm6 secureip>
     ```
   - `VIVADO_CLIBS` -- directory containing your precompiled VCS simulation libraries for the selected Vivado/VCS version
     ```
     tcsh: setenv VIVADO_CLIBS <path to compiled simlibs>
     bash: export VIVADO_CLIBS=<path to compiled simlibs>
     ```
   Verify:
   ```
   echo $VCS_HOME       # should show X-2025.06 path
   echo $AVERY_PLI      # should show avery_pli-2025.3_1 path
   echo $AVERY_PCIE     # should show apcievip-2025.3_1 path
   echo $CPM6_SECUREIP  # should show your extracted path
   echo $VIVADO_CLIBS   # should show your compiled simlib path
   ```
3. Via the GUI: File → Project → New (or IP Catalog → Example Designs) and select "Versal CPM6 BMD Design".

   Alternately, users can use command line options in the Vivado Tcl console -- substitute `CTRL_CONFIG.VALUE` from the table above for your chosen configuration:
   ```
   create_project <project_name> <output_dir>/<project_name> -part <supported_part>
   create_bd_design "cpm6_bmd" -mode batch
   instantiate_example_design -template xilinx.com:design:cpm6_bmd:1.0 \
       -design cpm6_bmd -options { CTRL_CONFIG.VALUE Controller_0 }
   ```
4. This single step also generates the VCS simulation scripts and copies the `sim/` directory alongside the Vivado project -- no separate `launch_simulation` step is needed.

**Expected outcome:**
The Vivado project is created, and `<project_name>/sim/` contains the `Makefile`, `test/`, `tb/`, and `verif/` directories ready to build.

### Simulating the Example
1. `cd <project_name>/sim`
2. `make cos` -- compile + optimize + simulate (runs the default test, `test_bmd_write_read_custom`)
3. `make cos DUMP=1` -- same, with waveform dump enabled
4. `make s TEST=<test_name>` -- re-simulate only, with a different test (see the full list below)

**Expected outcome:**
Simulation completes with `UVM_ERROR : 0` and `UVM_FATAL : 0` in the report summary at the end of `vcs.sim.log`.

#### Available Tests
**Write (DMA):**
`test_bmd_write_min_size_min_count`, `test_bmd_write_min_size_max_count`, `test_bmd_write_max_size_min_count`, `test_bmd_write_max_size_max_count`

**Read (DMA):**
`test_bmd_read_min_size_min_count`, `test_bmd_read_min_size_max_count`, `test_bmd_read_max_size_min_count`, `test_bmd_read_max_size_max_count`

**Interrupts:** `test_bmd_intx`, `test_bmd_msi`, `test_bmd_msix`

**Capabilities:** `test_bmd_tph`, `test_bmd_pasid`, `test_bmd_vsec`, `test_bmd_10b_tag`, ...

**Error tests:** `test_bmd_inject_bad_data`, `test_bmd_send_ur`, ...

**IDE (IDE option, default test with IDE):** `test_bmd_ide_traffic`, `test_bmd_ide_basic`

**Custom (write + read, concurrent, hand-editable):**
`test_bmd_write_read_custom` (default) -- runs write and read DMA together. `wr_size`/`wr_count`/`rd_size`/`rd_count` are hardcoded in the test source -- edit `test/tests/ext/traffic/other/test_bmd_write_read_custom.sv` directly to change the traffic shape for a quick one-off run.

See the Makefile header for the complete test list.

### Implementation Flow through PDI Generation
This CED is built using the standard Vivado IP Integrator flow (`create_bd_design` + `instantiate_example_design`) -- the same flow used by designs that support synthesis, implementation, and PDI/bitstream generation on hardware.

### Building Embedded Software Requirements
Without the `IDE` option there is no embedded software component; all traffic generation and checking is done by the UVM testbench.

With the `IDE` option the CPM6 IDE keys are programmed by the SEC firmware running on RPU core R5_0
(https://github.com/AMD-AECG-SSW/cpm6-endpoint-firmware). The firmware is built outside this CED and is not included yet.
Put the ELF in `fw/` as `fw/ide_fw.elf` (placeholder name) and use it in the steps below.

### Running the Example in Hardware
This example design has been validated on hardware.

#### Running the IDE firmware (IDE option)
The firmware runs on R5_0 from DDR, so the IDE option is required (it adds the DDR). Placeholders in `<>` are yours to fill in; `<fw_elf>` is the
firmware ELF that is not packaged yet (for example `fw/ide_fw.elf`).

1. Generate the design with `IDE` selected and run the implementation through PDI generation. The implementation run directory contains
   `impl_1_<top>_boot.pdi` and `impl_1_<top>_pld.pdi` (`<top>` is `ctrl0_bmd_ep` or `ctrl1_bmd_ep`).
2. Power-cycle the VPK360 and connect to it with `hw_server`.
3. Program both PDIs and start the firmware on R5_0 with xsdb:
   ```tcl
   connect -url <hw_server_url>
   targets -set -filter {name =~ "Versal*"}
   rst -sys
   after 2000
   device program {<path>/impl_1_<top>_boot.pdi}
   after 2000
   device program {<path>/impl_1_<top>_pld.pdi}
   after 2000
   targets                                          ;# note the target id of "Cortex-R5 #0"
   targets -set -filter {name =~ "Cortex-R5 #0"}    ;# or: targets <id>
   rst -proc
   dow {<fw_elf>}
   con
   ```
4. Check that `targets` shows R5 #0 as Running. The firmware console is UART0 (PS_MIO_16:17).
5. Reboot the host so that it enumerates the endpoint after the firmware is running, then check it with `lspci -d 10ee:`.
6. Establish Link IDE from the host with your IDE host tooling.

---

## How to Explore or Extend This Design

Common next steps:
- Edit `test/tests/ext/traffic/other/test_bmd_write_read_custom.sv` directly to change the write/read TLP size and count for a quick one-off traffic shape (values are hardcoded in the test source, not passed as overrides)
- Change `CTRL_LANE_RATE` / `CTRL_LINK_WIDTH` options at CED generation time to test other link speed/width combinations
- Run one of the capability-focused tests (e.g. `test_bmd_10b_tag`, `test_bmd_tph`, `test_bmd_pasid`) to exercise a specific PCIe feature in isolation

**Caution:**
Changes to the scoreboards (`test/scoreboards/`) or capability sequences (`test/sequences/capability/`) affect correctness checking across all tests and all configurations -- verify carefully before relying on results from a modified scoreboard.

---

## Support
This example design is provided as is.
For questions, see AMD Adaptive Support or the related repository documentation.
