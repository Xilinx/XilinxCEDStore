/*
Copyright (C) 2019, Xilinx Inc - All rights reserved
*
* Licensed under the Apache License, Version 2.0 (the "License"). You may
* not use this file except in compliance with the License. A copy of the
* License is located at
*
*     http://www.apache.org/licenses/LICENSE-2.0

*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
* License for the specific language governing permissions and limitations
* under the License.
*/
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (lin64) Build 2514510 Mon Apr 15 08:01:32 MDT 2019
//Date        : Tue Apr 16 16:48:13 2019
//Host        : xhdrdevl100 running 64-bit CentOS Linux release 7.4.1708 (Core)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (ddr3_sdram_addr,
    ddr3_sdram_ba,
    ddr3_sdram_cas_n,
    ddr3_sdram_ck_n,
    ddr3_sdram_ck_p,
    ddr3_sdram_cke,
    ddr3_sdram_dm,
    ddr3_sdram_dq,
    ddr3_sdram_dqs_n,
    ddr3_sdram_dqs_p,
    ddr3_sdram_odt,
    ddr3_sdram_ras_n,
    ddr3_sdram_reset_n,
    ddr3_sdram_we_n,
    dip_switches_16bits_tri_i,
    iic0_main_scl_io,
    iic0_main_sda_io,
    led_8bits_tri_o,
    mdio_mdc_1_mdc,
    mdio_mdc_1_mdio_io,
    phy_reset_out_1,
    push_buttons_5bits_tri_i,
    reset,
    rgmii_1_rd,
    rgmii_1_rx_ctl,
    rgmii_1_rxc,
    rgmii_1_td,
    rgmii_1_tx_ctl,
    rgmii_1_txc,
    rs232_uart_rxd,
    rs232_uart_txd,
    spi_flash_io0_io,
    spi_flash_io1_io,
    spi_flash_io2_io,
    spi_flash_io3_io,
    spi_flash_ss_io,
    sys_diff_clock_clk_n,
    sys_diff_clock_clk_p);
  output [14:0]ddr3_sdram_addr;
  output [2:0]ddr3_sdram_ba;
  output ddr3_sdram_cas_n;
  output [0:0]ddr3_sdram_ck_n;
  output [0:0]ddr3_sdram_ck_p;
  output [0:0]ddr3_sdram_cke;
  output [1:0]ddr3_sdram_dm;
  inout [15:0]ddr3_sdram_dq;
  inout [1:0]ddr3_sdram_dqs_n;
  inout [1:0]ddr3_sdram_dqs_p;
  output [0:0]ddr3_sdram_odt;
  output ddr3_sdram_ras_n;
  output ddr3_sdram_reset_n;
  output ddr3_sdram_we_n;
  input [15:0]dip_switches_16bits_tri_i;
  inout iic0_main_scl_io;
  inout iic0_main_sda_io;
  output [7:0]led_8bits_tri_o;
  output mdio_mdc_1_mdc;
  inout mdio_mdc_1_mdio_io;
  output [0:0]phy_reset_out_1;
  input [4:0]push_buttons_5bits_tri_i;
  input reset;
  input [3:0]rgmii_1_rd;
  input rgmii_1_rx_ctl;
  input rgmii_1_rxc;
  output [3:0]rgmii_1_td;
  output rgmii_1_tx_ctl;
  output rgmii_1_txc;
  input rs232_uart_rxd;
  output rs232_uart_txd;
  inout spi_flash_io0_io;
  inout spi_flash_io1_io;
  inout spi_flash_io2_io;
  inout spi_flash_io3_io;
  inout spi_flash_ss_io;
  input sys_diff_clock_clk_n;
  input sys_diff_clock_clk_p;

  wire [14:0]ddr3_sdram_addr;
  wire [2:0]ddr3_sdram_ba;
  wire ddr3_sdram_cas_n;
  wire [0:0]ddr3_sdram_ck_n;
  wire [0:0]ddr3_sdram_ck_p;
  wire [0:0]ddr3_sdram_cke;
  wire [1:0]ddr3_sdram_dm;
  wire [15:0]ddr3_sdram_dq;
  wire [1:0]ddr3_sdram_dqs_n;
  wire [1:0]ddr3_sdram_dqs_p;
  wire [0:0]ddr3_sdram_odt;
  wire ddr3_sdram_ras_n;
  wire ddr3_sdram_reset_n;
  wire ddr3_sdram_we_n;
  wire [15:0]dip_switches_16bits_tri_i;
  wire iic0_main_scl_i;
  wire iic0_main_scl_io;
  wire iic0_main_scl_o;
  wire iic0_main_scl_t;
  wire iic0_main_sda_i;
  wire iic0_main_sda_io;
  wire iic0_main_sda_o;
  wire iic0_main_sda_t;
  wire [7:0]led_8bits_tri_o;
  wire mdio_mdc_1_mdc;
  wire mdio_mdc_1_mdio_i;
  wire mdio_mdc_1_mdio_io;
  wire mdio_mdc_1_mdio_o;
  wire mdio_mdc_1_mdio_t;
  wire [0:0]phy_reset_out_1;
  wire [4:0]push_buttons_5bits_tri_i;
  wire reset;
  wire [3:0]rgmii_1_rd;
  wire rgmii_1_rx_ctl;
  wire rgmii_1_rxc;
  wire [3:0]rgmii_1_td;
  wire rgmii_1_tx_ctl;
  wire rgmii_1_txc;
  wire rs232_uart_rxd;
  wire rs232_uart_txd;
  wire spi_flash_io0_i;
  wire spi_flash_io0_io;
  wire spi_flash_io0_o;
  wire spi_flash_io0_t;
  wire spi_flash_io1_i;
  wire spi_flash_io1_io;
  wire spi_flash_io1_o;
  wire spi_flash_io1_t;
  wire spi_flash_io2_i;
  wire spi_flash_io2_io;
  wire spi_flash_io2_o;
  wire spi_flash_io2_t;
  wire spi_flash_io3_i;
  wire spi_flash_io3_io;
  wire spi_flash_io3_o;
  wire spi_flash_io3_t;
  wire spi_flash_ss_i;
  wire spi_flash_ss_io;
  wire spi_flash_ss_o;
  wire spi_flash_ss_t;
  wire sys_diff_clock_clk_n;
  wire sys_diff_clock_clk_p;

  design_1 design_1_i
       (.ddr3_sdram_addr(ddr3_sdram_addr),
        .ddr3_sdram_ba(ddr3_sdram_ba),
        .ddr3_sdram_cas_n(ddr3_sdram_cas_n),
        .ddr3_sdram_ck_n(ddr3_sdram_ck_n),
        .ddr3_sdram_ck_p(ddr3_sdram_ck_p),
        .ddr3_sdram_cke(ddr3_sdram_cke),
        .ddr3_sdram_dm(ddr3_sdram_dm),
        .ddr3_sdram_dq(ddr3_sdram_dq),
        .ddr3_sdram_dqs_n(ddr3_sdram_dqs_n),
        .ddr3_sdram_dqs_p(ddr3_sdram_dqs_p),
        .ddr3_sdram_odt(ddr3_sdram_odt),
        .ddr3_sdram_ras_n(ddr3_sdram_ras_n),
        .ddr3_sdram_reset_n(ddr3_sdram_reset_n),
        .ddr3_sdram_we_n(ddr3_sdram_we_n),
        .dip_switches_16bits_tri_i(dip_switches_16bits_tri_i),
        .iic0_main_scl_i(iic0_main_scl_i),
        .iic0_main_scl_o(iic0_main_scl_o),
        .iic0_main_scl_t(iic0_main_scl_t),
        .iic0_main_sda_i(iic0_main_sda_i),
        .iic0_main_sda_o(iic0_main_sda_o),
        .iic0_main_sda_t(iic0_main_sda_t),
        .led_8bits_tri_o(led_8bits_tri_o),
        .mdio_mdc_1_mdc(mdio_mdc_1_mdc),
        .mdio_mdc_1_mdio_i(mdio_mdc_1_mdio_i),
        .mdio_mdc_1_mdio_o(mdio_mdc_1_mdio_o),
        .mdio_mdc_1_mdio_t(mdio_mdc_1_mdio_t),
        .phy_reset_out_1(phy_reset_out_1),
        .push_buttons_5bits_tri_i(push_buttons_5bits_tri_i),
        .reset(reset),
        .rgmii_1_rd(rgmii_1_rd),
        .rgmii_1_rx_ctl(rgmii_1_rx_ctl),
        .rgmii_1_rxc(rgmii_1_rxc),
        .rgmii_1_td(rgmii_1_td),
        .rgmii_1_tx_ctl(rgmii_1_tx_ctl),
        .rgmii_1_txc(rgmii_1_txc),
        .rs232_uart_rxd(rs232_uart_rxd),
        .rs232_uart_txd(rs232_uart_txd),
        .spi_flash_io0_i(spi_flash_io0_i),
        .spi_flash_io0_o(spi_flash_io0_o),
        .spi_flash_io0_t(spi_flash_io0_t),
        .spi_flash_io1_i(spi_flash_io1_i),
        .spi_flash_io1_o(spi_flash_io1_o),
        .spi_flash_io1_t(spi_flash_io1_t),
        .spi_flash_io2_i(spi_flash_io2_i),
        .spi_flash_io2_o(spi_flash_io2_o),
        .spi_flash_io2_t(spi_flash_io2_t),
        .spi_flash_io3_i(spi_flash_io3_i),
        .spi_flash_io3_o(spi_flash_io3_o),
        .spi_flash_io3_t(spi_flash_io3_t),
        .spi_flash_ss_i(spi_flash_ss_i),
        .spi_flash_ss_o(spi_flash_ss_o),
        .spi_flash_ss_t(spi_flash_ss_t),
        .sys_diff_clock_clk_n(sys_diff_clock_clk_n),
        .sys_diff_clock_clk_p(sys_diff_clock_clk_p));
  IOBUF iic0_main_scl_iobuf
       (.I(iic0_main_scl_o),
        .IO(iic0_main_scl_io),
        .O(iic0_main_scl_i),
        .T(iic0_main_scl_t));
  IOBUF iic0_main_sda_iobuf
       (.I(iic0_main_sda_o),
        .IO(iic0_main_sda_io),
        .O(iic0_main_sda_i),
        .T(iic0_main_sda_t));
  IOBUF mdio_mdc_1_mdio_iobuf
       (.I(mdio_mdc_1_mdio_o),
        .IO(mdio_mdc_1_mdio_io),
        .O(mdio_mdc_1_mdio_i),
        .T(mdio_mdc_1_mdio_t));
  IOBUF spi_flash_io0_iobuf
       (.I(spi_flash_io0_o),
        .IO(spi_flash_io0_io),
        .O(spi_flash_io0_i),
        .T(spi_flash_io0_t));
  IOBUF spi_flash_io1_iobuf
       (.I(spi_flash_io1_o),
        .IO(spi_flash_io1_io),
        .O(spi_flash_io1_i),
        .T(spi_flash_io1_t));
  IOBUF spi_flash_io2_iobuf
       (.I(spi_flash_io2_o),
        .IO(spi_flash_io2_io),
        .O(spi_flash_io2_i),
        .T(spi_flash_io2_t));
  IOBUF spi_flash_io3_iobuf
       (.I(spi_flash_io3_o),
        .IO(spi_flash_io3_io),
        .O(spi_flash_io3_i),
        .T(spi_flash_io3_t));
  IOBUF spi_flash_ss_iobuf
       (.I(spi_flash_ss_o),
        .IO(spi_flash_ss_io),
        .O(spi_flash_ss_i),
        .T(spi_flash_ss_t));
endmodule
