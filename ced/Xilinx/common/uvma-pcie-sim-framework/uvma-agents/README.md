# uvma-agents; (U)niversal (V)erification (M)ethodology (A)MD Agents

This repository contains a *base_agent* that defines a convenient framework such that AMD-authored function-specific UVM agents, with several contained here, can be written with relative ease and brought into FPGA/ASIC UVM testbenches for verification of RTL code by simply extending the *base_agent* to create function-specific agents. The function-specific agents in this repository are all extended from the *base_agent*, which means that the very powerful object-oriented-programming technique - polymorphism - can be employed. As an example of this feature, consider a UVM scoreboard that can have a port that receives transactions of type base_txn, which can now be passed transactions of any type that are a derived class of base_txn, and assuming its methods all employ the "virtual" keyword, the base class handle will still call the drived class handle's methods. The agents contained here are designed to connect to AMD IP; for a short summary see the subsequent section and for a detailed list of information about a specific agent's capabilities, limitations, and usage, navigate to each agent's directory.

## Agent Summary
- [base_agent](base_agent/README.md) — Shared parameterized framework (cfg/txn/monitor/driver/sequencer/scoreboards) that every agent below extends.
- [aximon_agent](aximon_agent/README.md) — Passive AXI4 monitor that reconstructs granular and reassembled read/write transactions.
- [cfg_ext_agent](cfg_ext_agent/README.md) — Models the AMD/Xilinx PCIe hard-IP configuration-extend request/response interface; master, active slave, or passive monitor.
- [cpi_agent](cpi_agent/README.md) — Composite CXL-flavored CPI agent bundling GLOBAL/REQ/DATA/RSP sub-agents with per-channel credit-based flow control behind one virtual sequencer.
- [cxl_credit_agent](cxl_credit_agent/README.md) — Models AMD CPM6's internal CXL.cache/CXL.mem credit-return bus; master/slave, active/passive.
- [cxl_nfi_agent](cxl_nfi_agent/README.md) — Models CXL.cache/CXL.mem transaction-layer traffic over AMD's flit-mode NFI link interface in both 68B and 256B Flit Mode.
- [elbi_agent](elbi_agent/README.md) — Monitors and (in active-slave mode) responds to the ELBI sideband register bus of AMD PCIe/CXL IP.
- [gpdrv_agent](gpdrv_agent/README.md) — Generic 64-bit signal driver/monitor for sideband/GPIO-style wires, with a user-attachable value-decode callback.
- [gpmon_agent](gpmon_agent/README.md) — Passive monitor for PCIe link-training/status signals (LTSSM, speed, width, link status) via pluggable decode callbacks.
- [msix_user_agent](msix_user_agent/README.md) — Drives/monitors CPM6's MSI-X user sideband handshake (PF/VF/vector/op request plus grant) for IRQ send/check/clear.
- [reset_agent](reset_agent/README.md) — Configurable active-low/active-high reset agent; can drive assert/deassert/pulse sequences or passively monitor reset edges.
- [common](common/README.md) — Not an agent: shared simulation/reporting infrastructure (custom report server, sim Makefile, log parser) used by the agents' testbenches.

## UVM Background
If you are unfamiliar with UVM, it is **THE** predominant verification methodology in use today for FPGAs and ASICs. What exactly *is* UVM? UVM is a set of class-based SystemVerilog files that provide a framework for users to employ in their testbenches. UVM has a long and storied history, but the important thing is that the APIs and base class library that define UVM are now standardized via IEEE 1800.2. All of the files are open-source; any simulator (QuestaSim, VCS, etc.) installation comes with the UVM source code and usually the precompiled code as a library that you may import, or you may compile it yourself. It is important to note that UVM just gives you some well-defined structure that you could use in your testbench and many helpful APIs; it does not contain any agents to actually drive stimulus into or receive stimulus from your DUT and it does not *enforce* any sort of usage of its code. To actually *use* UVM effectively, you need to have agents (that's the purpose of this repository) and you need to use it as it's designed. You can make a screwdriver function as a hammer, but you're using it wrong in that case and making your life and the life of others more difficult. 

If you have never used UVM, but you know object oriented programming techniques and you are familiar with SystemVerilog, even if only the synthesizable constructs, you will pick it up quickly. Siemens has a great set of UVM training videos and books that function as a great introduction. Here is a recommended one to get started:

https://verificationacademy.com/topics/uvm-universal-verification-methodology/uvm-basics/

## Repo Rules
It is envisioned that these are automatically checked through the server side Git hooks, but that would require scripts being written and tested. For now, I will simply write them here and assume they will be followed.

### GOLDEN RULES
1. Packages are named pkg.\<agent\>.sv and the package type shall be 
   \<agent\>_pkg i.e.
```
   >>> pkg.<agent>.sv
     package <agent>_pkg; ... endpackage
```
2. There shall be only one class definition per file and that file
   shall be named <class type>.sv
3. A single .F file must compile the entire agent (know the difference 
   between how -f and -F differ from simulators)
4. A file that can be compiled with EITHER -f or -F should have the 
   suffix .f, a file that MUST be compiled with -F should have the .F
   suffix
5. All agents should extend the base_agent unless there is a very, very,
   VERY good reason not to. If you are creating custom things that don't
   extend from a base class, there **must** be a justification.

### FORMATTING GOLDEN RULES
1. No tabs
2. Indentation is 2 spaces
