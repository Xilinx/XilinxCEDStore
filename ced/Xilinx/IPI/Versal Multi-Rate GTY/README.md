# VCK190/VMK180 Example Design : Multi-Rate GTY
## Objective
This example describes a Versal GTY multi-rate design using the following configuration:
* Two rates: 10G and 25G switchable line rates
* Single GTY lane connected through SFP on VCK190/VMK180 evaluation board


## Required Hardware and Tools
2020.2.2 Vivado

VCK190/VMK180

Boot Mode: JTAG
## Block Diagram
![image](https://user-images.githubusercontent.com/73725387/119939933-64376c80-bf43-11eb-9d4c-c0068b0ce008.png)

On the board, the design targets the following configuration:
* Single lane on Bank 105 GTY2, which connects to SFP0 (lower connector of the 2x SFP28 stack).
* Bank 105 REFCLK0, which is sourced from zSFP Si570 CLK. Default frequency is 156.25MHz.
* Bank 705 Si570 LPDDR4_CLK2 for APB3CLK. Default frequency is 200MHz.

## Design Steps
1. Download the example design from XHub Stores. Open example design and select the targeted Board (VCK190 or VMK180)
2. Add MGTREFCLK create_clock and vio set_false_path constraints
    * Create a xdc file
      File > Add Sources > Add or create constraints > Create file
![image](https://user-images.githubusercontent.com/73725387/119454889-e9294880-bced-11eb-8e2e-c6565687febd.png)

    * Add MGTREFCLK create_clock constraint to top level xdc:
    ```tcl
    create_clock -period 6.400 -name {gt_bridge_ip_0_diff_gt_ref_clock_clk_p[0]} [get_ports {gt_bridge_ip_0_diff_gt_ref_clock_clk_p[0]}]
    ```

    * Add false_path constraints for the VIO input/output pins. The VIO is in apb3clk domain and the probed pins are in GT/RXUSRCLK domain. There are clock domain crossings from and to the VIO and these paths can be safely ignored.
    
    ```tcl
    set_false_path -through [get_pins -hier *axis_vio*probe*out*]
    set_false_path -through [get_pins -hier *axis_vio*probe*in*]
    ```
3. Synthesize and open synthesized design
4. Set GT and REFCLK pin locations
    * The GT/REFCLK locations are defined during pin planning. After synthesis, set the pin locations as follows in the **I/O Ports** tab. **Note**: It is important to lock GT and REFCLK locations before implementation for optimized placement and routing.
    * Click **Save**.
    ![image](https://user-images.githubusercontent.com/73725387/100336581-36b93880-2f8b-11eb-8669-1f4662038feb.png)

5. Run implementation and generate PDI. Make sure timing is clean.

## Hardware Setup

#### Board Connections
* Connect power cable
* Connect USB-C/JTAG cable
* Insert SFP28 loopback module into the lower 2x SFP28 connector (SFP0)
![image](https://user-images.githubusercontent.com/73725387/100336967-a7605500-2f8b-11eb-8d83-a07fa2970935.png)

## Running the Design on VCK190/VMK180
#### 1. Initialization
Power up and program the pdi. Add all VIO probes to the dashboard. Hardware manager should look like the below post pdi programming.
* The default line rate is 10G (rate_sel = probe_out1[3:0] = 0x0)
* Link is up: link_status_out = 1
* TX/RX reset has completed: tx/rx_resetdone_out = 1
* LCPLL is locked: hsclk1_lcplllock = 1

![image](https://user-images.githubusercontent.com/73725387/100337338-19d13500-2f8c-11eb-99e9-1189303dd187.png)

#### 2. Rate change to 25G
* Change rate_sel = probe_out1[3:0] = 0x1. This will change the line rate to 25G (CONFIG1)
* Reset sequence is automatically applied. tx/rx_resetdone toggles and return back to 1 when rate change operation has completed

![image](https://user-images.githubusercontent.com/73725387/100337445-3bcab780-2f8c-11eb-9a27-9301f9719720.png)

#### 3. In-system IBERT Eye Scan
Versal ACAP has runtime IBERT capability built-in to all GTY designs. Let's run eye scans for 10G and 25G links.

* In **Serial I/O Links** Tab, choose **Create Links**.
* Create link for CH2.TX → CH2.RX. The design is only running single lane on GTY2.
* The created link and its link status is shown below. **Note**: Status is expected to show "No link" for an in-system IBERT setup. The data pattern is sourced from the custom design and not from IBERT. IBERT pattern checker receives unexpected data therefore IBERT link status is unknown.
* Right-click on **Link 0** and select **Create Scan**.
* Toggle between rate_sel = 0x0 and 0x1 to change line rates between 10G/25G.  Run scan after each rate change to obtain 10G and 25G eye scans.

![image](https://user-images.githubusercontent.com/73725387/100337683-906e3280-2f8c-11eb-8fb0-d1db3f29e05a.png)

![image](https://user-images.githubusercontent.com/73725387/100337708-98c66d80-2f8c-11eb-95f1-e1334de38752.png)

![image](https://user-images.githubusercontent.com/73725387/100337743-a2e86c00-2f8c-11eb-9186-1987bef74457.png)

![image](https://user-images.githubusercontent.com/73725387/100337790-ae3b9780-2f8c-11eb-8b18-bc0607c70f1d.png)

10G Eye Scan
![image](https://user-images.githubusercontent.com/73725387/100337832-b7c4ff80-2f8c-11eb-9797-990d1b16d3c1.png)

25G Eye Scan
![image](https://user-images.githubusercontent.com/73725387/100337857-bd224a00-2f8c-11eb-8179-a72459dad018.png)


#### 4. IBERT Debug Capability
The custom GTY design can also be converted to an IBERT design during runtime.
* In **hw_vio_1**, set rate_sel = probe_out1 = 0x0. This sets the GTY to default rate of 10G (CONFIG0).
* In **Serial I/O Links** tab, change TX/RX Pattern to PRBS 31. This switches the data source to IBERT pattern generator/checker.
* Status now shows the 10G line rate, with 0 bit errors.

![image](https://user-images.githubusercontent.com/73725387/100338048-f8bd1400-2f8c-11eb-9822-1b57992f556d.png)

![image](https://user-images.githubusercontent.com/73725387/100338081-007cb880-2f8d-11eb-85e8-fa388ddde8af.png)
**Note**: In the VIO, the bridge_ip/link_status_out is expected to go down since the pattern checker is now through IBERT and not through the generator/checker inside gt_bridge_ip.

10G Eye Scan
![image](https://user-images.githubusercontent.com/73725387/100338109-083c5d00-2f8d-11eb-8fef-c33ab6ff05b2.png)

* Change rate_sel = probe_out1 = 0x1. This changes the rate to 25G (CONFIG1).
* Change TX/RX Pattern to something else then back to PRBS 31. This allows IBERT to re-sync to the new line rate.
* Apply RX Reset to reset error counter.
* Status now shows the 25G line rate, with 0 bit errors.

![image](https://user-images.githubusercontent.com/73725387/100338291-40dc3680-2f8d-11eb-8322-ca7adc046d8c.png)
![image](https://user-images.githubusercontent.com/73725387/100338309-48034480-2f8d-11eb-9d03-281e32da11d2.png)
**Note**: In the VIO, the bridge_ip/link_status_out is expected to go down since the pattern checker is now through IBERT and not through the generator/checker inside gt_bridge_ip.

25G Eye Scan
![image](https://user-images.githubusercontent.com/73725387/100338324-4cc7f880-2f8d-11eb-861c-30da07f718a7.png)

The following **Appendix: Vivado Steps** in this README will walk through the steps to create this design in Vivado manually.

## Appendix: Vivado Steps
#### 1. Create project targeting VMK180 Board

![image](https://user-images.githubusercontent.com/73725387/100334028-189e0900-2f88-11eb-8f00-4ae519734286.png)

#### 2. Create Block Design

![image](https://user-images.githubusercontent.com/73725387/100334096-30758d00-2f88-11eb-87d5-41aaadc03f22.png)

#### 3. Create gt_bridge_ip
Add gt_bridge_ip to IPI. Configure the bridge_ip and transceiver through customization GUI. In this example, we will run one GT lane targeting two line rates, 10G and 25G.

* Set **Number of lanes** = 1. **TX/RX master clk source** = TX0/RX0
* Open the transceiver sub-GUI through **Transceiver Configs** button
![image](https://user-images.githubusercontent.com/73725387/100334207-53a03c80-2f88-11eb-92a1-565561706541.png)
* For **CONFIG0**, set **Line rate** = 10.3125, **PLL type** = LCPLL, **Requested reference clock** = 156.25. Check that the **Actual reference clock** is also 156.25.
* Click on the "+" button to add a new configuration **CONFIG1**.
* For **CONFIG1**, set **Line rate** = 25.78125, **PLL type** = LCPLL, **Requested reference clock** = 156.25. Check that the **Actual reference clock** is also 156.25.
![image](https://user-images.githubusercontent.com/73725387/100334551-cad5d080-2f88-11eb-848d-220eebab68b1.png)
![image](https://user-images.githubusercontent.com/73725387/100334584-d45f3880-2f88-11eb-85a1-62f2f101d939.png)
* Add a gt_quad_base IP to IPI. **Note**: This step is only required because we are running a customized connection for block automation to target Channel 2. If the design uses Channel 0, block automation can be run with gt_bridge_ip alone.
* Click on **Run Block Automation**. This will automatically instantiate the auxiliary blocks needed to connect GT clocks.
    *  Choose **Customized_Connection** and select gt_quad_base_0 **Lane_2**.

![image](https://user-images.githubusercontent.com/73725387/100334904-34ee7580-2f89-11eb-843a-eea09834371c.png)
![image](https://user-images.githubusercontent.com/73725387/100334954-433c9180-2f89-11eb-9142-41f7739daf0a.png)
![image](https://user-images.githubusercontent.com/73725387/100334969-4a639f80-2f89-11eb-94fe-8cd96750cdaa.png)
![image](https://user-images.githubusercontent.com/73725387/100335029-59e2e880-2f89-11eb-9d12-6f002a5cfdd2.png)
Open gt_quad_base IP to change APB3 clock frequency to 200 MHz. We will be using the LPDDR4 SI570 Clock2 on VMK180 to drive APB3CLK and its default frequency is 200 MHz.
![image](https://user-images.githubusercontent.com/73725387/119452345-19231c80-bceb-11eb-9054-d47b935b100d.png)


#### 4. Add VIO for hardware debug visibility
1. Keep MGTREFCLK and GT_Serial ports. Remove all other external ports which were automatically created by block automation. GTY controls and status monitoring will be done through VIO instead.
2. Instantiate VIO in block design
3. Customize for 4 inputs and 2 outputs, and connect as follows:
    * probe_in0 = gt_bridge_ip/link_status_out
    * probe_in1 = gt_bridge_ip/tx_resetdone_out
    * probe_in2 = gt_bridge_ip/rx_resetdone_out
    * probe_in3 = gt_quad_base/hsclk1_lcplllock
    * probe_out0 = gt_bridge_ip/gtreset_in
    * probe_out1 = gt_bridge_ip/rate_sel (4-bits)

![image](https://user-images.githubusercontent.com/73725387/100335596-0329de80-2f8a-11eb-9e16-1255f80dac0d.png)
![image](https://user-images.githubusercontent.com/73725387/100335633-0fae3700-2f8a-11eb-9545-24d0eef1a785.png)
![image](https://user-images.githubusercontent.com/73725387/100335654-15a41800-2f8a-11eb-8fed-868f84fe6d63.png)
![image](https://user-images.githubusercontent.com/73725387/100335667-1b99f900-2f8a-11eb-8797-d4e497b1dfa4.png)
![image](https://user-images.githubusercontent.com/73725387/100335698-218fda00-2f8a-11eb-8c97-ef760f7085ac.png)

#### 5. Add APB3CLK connections
1. The LPDDR4 clock input is differential which needs a IBUFDS differential input buffer.
    * In IPI, instantiate a **Utility Buffer**. Double-click to customize.
    * In **Board tab**, set to **lpddr4 sma clk2**.
2. Create a new external port and set clock frequency to 200MHz.
    * Right-click on the CLK_IN_D port of the utility buffer and select **Make External**.
    * Select the external port symbol. Change the created port name to apb3clk_gt in the **External Interface Properties** window.
    * Double-click on the external port and set frequency to 200MHz.
3. Connect **IBUF_OUT** to gt_bridge_ip_0/**apb3clk**, gt_quad_base_0/**apb3clk**, and axis_vio_0/**clk**.

![image](https://user-images.githubusercontent.com/73725387/100336035-84817100-2f8a-11eb-8c94-6a03395c44ca.png)

![image](https://user-images.githubusercontent.com/73725387/100336061-8d724280-2f8a-11eb-80bd-e900f5d19323.png)

![image](https://user-images.githubusercontent.com/73725387/100336076-93682380-2f8a-11eb-87a1-d6f4418c38b6.png)

![image](https://user-images.githubusercontent.com/73725387/100336090-99f69b00-2f8a-11eb-958d-869ca9536408.png)

#### 5. Add CIPS IP
The PMC is incorporated into the CIPS IP and must be configured for the Versal device to boot properly. Therefore, all Versal designs must include CIPS IP.
* In the **Board** tab, drag-and-drop the **CIPS fixed IO** instance onto the block design canvas. This will configure the CIPS IP with board preset.
* No other customization is needed. Debug cores will be automatically instantiated by the tool during opt_design.

![image](https://user-images.githubusercontent.com/73725387/100336271-d1654780-2f8a-11eb-8a4d-9a56647889e1.png)

#### 6. Create HDL wrapper
In the **Sources** window, right-click on the block design (design_1.bd) and select **Create HDL Wrapper**. Let Vivado manage.
![image](https://user-images.githubusercontent.com/73725387/100336397-fc4f9b80-2f8a-11eb-8241-6c0b46c27f70.png)

#### 7. Add REFCLK and VIO set_false_path constraints
* Create a xdc file
File > Add Sources > Add or create constraints > Create file

![image](https://user-images.githubusercontent.com/73725387/119454889-e9294880-bced-11eb-8e2e-c6565687febd.png)

* Add MGTREFCLK create_clock constraint to top level xdc:
```tcl
create_clock -period 6.400 -name {gt_bridge_ip_0_diff_gt_ref_clock_clk_p[0]} [get_ports {gt_bridge_ip_0_diff_gt_ref_clock_clk_p[0]}]
```

* Add false_path constraints for the VIO input/output pins. The VIO is in apb3clk domain and the probed pins are in GT/RXUSRCLK domain. There are clock domain crossings from and to the VIO and these paths can be safely ignored.
```tcl
set_false_path -through [get_pins -hier *axis_vio*probe*out*]
set_false_path -through [get_pins -hier *axis_vio*probe*in*]
```

#### 8. Synthesis and IO planning
* Run synthesis, and open synthesized design
* The GT/REFCLK locations are defined during pin planning. After synthesis, set the pin locations as follows in the **I/O Ports** tab. **Note**: It is important to lock GT and REFCLK locations before implementation for optimized placement and routing.
* Click **Save**. 
![image](https://user-images.githubusercontent.com/73725387/100336581-36b93880-2f8b-11eb-8669-1f4662038feb.png)
#### 9. Implementation and PDI generation
Run implementation and generate PDI. Make sure timing is clean.



