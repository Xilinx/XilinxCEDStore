# VCK190 Example Design : Combine Within GT Quad
## Objective
This example introduces the design flow on combing different IP within one quad with the Xilinx Vivado Integrated Design Environment.

## Required Tools
2020.2 Vivado

## Design Steps
1. Creating a project
   * On Windows, select Start  → All Programs → Xilinx Design Tools → Vivado 2020.2 → Vivado 2020.2 to launch the Vivado® Design Suite.
   * As an alternative, click the Vivado 2020.2 Desktop icon to start the Vivado IDE.
   The Vivado IDE Getting Started page, shown in the following figure, contains links to open or create projects and to view documentation.
![vivado_getstarted](https://user-images.githubusercontent.com/79898696/111562982-17604880-87d2-11eb-9311-a7645851ec3d.png)

2. Creating an IP integrator design
   In the IP Integrator, Create Block design Now, you create a customization for the ACAP PHY for PCIE IP in IP Integrator.
   *    In the Flow Navigator, select Create Block Design and name pcie_jesd.
   ![step2_1](https://user-images.githubusercontent.com/79898696/111563647-4d51fc80-87d3-11eb-8edc-6ed4e419b0a1.png)
   *    Click the **Add IP** button in the block design canvas. Alternatively, you can also right-click on the design canvas to open the context menu, and select **Add IP**.
   *    In the search field of the IP catalog, type pcie to find the ACAP PHY for PCIE IP.
   *    Select **ACAP PHY for PCIE IP** core and press Enter on the keyboard, or double-click the core in the IP catalog. Yet another way of adding an IP is dragging and dropping the IP from the IP catalog to the block design canvas. In this case, you would search for the IP, select it and drag-and-drop it on the block design canvas.
   *    Double-click this **ACAP PHY for PCIE** IP. In the Customize IP dialog box, change the following:
   Set Maxim Link speed to **5GT/S** and Leave everything else with the default settings on this tab.
   ![step2_5](https://user-images.githubusercontent.com/79898696/111564328-8343b080-87d4-11eb-850b-c489c849217e.png)
   * Use Run Block Automation to generate pcie_phy_versal_0_support module and connection
3. Add JESD204C TX/RX
In this step, you need to add JESD204C TX and JESD204C RX respectively.
   * In the search field of the IP catalog, type **jesd** to find the **JESD204C IP**.
   * Select **JESD204C** IP core and press Enter on the keyboard, or double-click the core in the IP catalog.
   * Double-click the **JESD204C** IP. In the Customize IP dialog box, change the following:
    a. set **Lanes Per link** to **1**.
    b.	Select **Line Coding** to **8B10B** and Leave everything else with the default settings on this tab.
    ![step3_3](https://user-images.githubusercontent.com/79898696/111567252-986f0e00-87d9-11eb-900c-0663fcf1fa2d.png)
   * Right-Click or CTRL+E, set Block property name to jesd204c_tx. 
   * Customize jesd204c_rx as steps above:
   ![step3_5](https://user-images.githubusercontent.com/79898696/111567372-ceac8d80-87d9-11eb-88cd-f18d281e925d.png)
4. Run Block Design Automation
**Note**: Run jesd204c_tx and jesd204c_rx respectively.
![step4_1](https://user-images.githubusercontent.com/79898696/111567716-5f836900-87da-11eb-86f0-1e5c7ae64dd5.png)
5.  Connect interface between GT quad IP and JESD TX/RX.
Now we need to connect the interfaces:
    * 	Connect apb3clk to s_axi_aclk, rx_core_clk, tx_core_clk
    * 	Connect GT_RX0 of jesd204c_rx to GT_RX0_EXT of gt_bridge_ip_0
    * 	Connect GT_TX0 of jesd204c_tx to GT_TX0_EXT of gt_bridge_ip_0
    * 	Click F6 in IP integrator confirm Validation is passed without any issue. Block design can be shown as below:
    ![step5_4](https://user-images.githubusercontent.com/79898696/111567973-dd477480-87da-11eb-9fab-ecad307f7df9.png)
6. Create pcie_jesd_wrapper module port and add top level constraints in XDC.
    * Make 4 lane ports external 
    * create wrapper module: pcie_jesd_wrapper.
    * Add below tcl in XDC
     ```tcl
     set gt_quads [get_cells -hierarchical -filter  PRIMITIVE_SUBGROUP==GT]
    #set_property LOC GTY_REFCLK_X0Y6 [get_cells -hierarchical -filter REF_NAME==IBUFDS_GTE5]
    #set_property LOC GTY_QUAD_X0Y3   [get_cells $gt_quads -filter NAME=~*/gt_quad_0/*]
    set_property PACKAGE_PIN W39 [get_ports pcie_refclk_clk_p]
    set_property PACKAGE_PIN U39 [get_ports jesd_refclk_clk_p]
    set_property PACKAGE_PIN AB46 [get_ports {rxp_0[0]}]
7. Run implementation 
![step7_1](https://user-images.githubusercontent.com/79898696/111572557-c6f1e680-87e3-11eb-9d8e-4b69f66cbef4.PNG)


