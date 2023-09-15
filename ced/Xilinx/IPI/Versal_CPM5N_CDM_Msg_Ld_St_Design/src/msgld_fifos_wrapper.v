//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (lin64) Build 3627241 Sun Aug 28 20:17:06 MDT 2022
//Date        : Tue Aug 30 12:17:48 2022
//Host        : xsjrdevl155 running 64-bit CentOS Linux release 7.5.1804 (Core)
//Command     : generate_target msgld_fifos_wrapper.bd
//Design      : msgld_fifos_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module msgld_fifos_wrapper
   (FIFO_READ_0_empty,
    FIFO_READ_0_rd_data,
    FIFO_READ_0_rd_en,
    FIFO_READ_1_empty,
    FIFO_READ_1_rd_data,
    FIFO_READ_1_rd_en,
    FIFO_WRITE_0_full,
    FIFO_WRITE_0_wr_data,
    FIFO_WRITE_0_wr_en,
    FIFO_WRITE_1_full,
    FIFO_WRITE_1_wr_data,
    FIFO_WRITE_1_wr_en,
    data_count_0,
    data_count_1,
    data_valid_0,
    overflow_0,
    prog_empty_0,
    prog_empty_1,
    prog_full_0,
    prog_full_1,
    rd_data_count_0,
    rd_data_count_1,
    rd_rst_busy_0,
    rd_rst_busy_1,
    rst_0,
    rst_1,
    underflow_0,
    wr_ack_0,
    wr_clk_0,
    wr_clk_1,
    wr_data_count_0,
    wr_data_count_1,
    wr_rst_busy_0,
    wr_rst_busy_1);
  output FIFO_READ_0_empty;
  output [255:0]FIFO_READ_0_rd_data;
  input FIFO_READ_0_rd_en;
  output FIFO_READ_1_empty;
  output [39:0]FIFO_READ_1_rd_data;
  input FIFO_READ_1_rd_en;
  output FIFO_WRITE_0_full;
  input [255:0]FIFO_WRITE_0_wr_data;
  input FIFO_WRITE_0_wr_en;
  output FIFO_WRITE_1_full;
  input [39:0]FIFO_WRITE_1_wr_data;
  input FIFO_WRITE_1_wr_en;
  output [10:0]data_count_0;
  output [10:0]data_count_1;
  output data_valid_0;
  output overflow_0;
  output prog_empty_0;
  output prog_empty_1;
  output prog_full_0;
  output prog_full_1;
  output [0:0]rd_data_count_0;
  output [0:0]rd_data_count_1;
  output rd_rst_busy_0;
  output rd_rst_busy_1;
  input rst_0;
  input rst_1;
  output underflow_0;
  output wr_ack_0;
  input wr_clk_0;
  input wr_clk_1;
  output [10:0]wr_data_count_0;
  output [10:0]wr_data_count_1;
  output wr_rst_busy_0;
  output wr_rst_busy_1;

  wire FIFO_READ_0_empty;
  wire [255:0]FIFO_READ_0_rd_data;
  wire FIFO_READ_0_rd_en;
  wire FIFO_READ_1_empty;
  wire [39:0]FIFO_READ_1_rd_data;
  wire FIFO_READ_1_rd_en;
  wire FIFO_WRITE_0_full;
  wire [255:0]FIFO_WRITE_0_wr_data;
  wire FIFO_WRITE_0_wr_en;
  wire FIFO_WRITE_1_full;
  wire [39:0]FIFO_WRITE_1_wr_data;
  wire FIFO_WRITE_1_wr_en;
  wire [10:0]data_count_0;
  wire [10:0]data_count_1;
  wire data_valid_0;
  wire overflow_0;
  wire prog_empty_0;
  wire prog_empty_1;
  wire prog_full_0;
  wire prog_full_1;
  wire [0:0]rd_data_count_0;
  wire [0:0]rd_data_count_1;
  wire rd_rst_busy_0;
  wire rd_rst_busy_1;
  wire rst_0;
  wire rst_1;
  wire underflow_0;
  wire wr_ack_0;
  wire wr_clk_0;
  wire wr_clk_1;
  wire [10:0]wr_data_count_0;
  wire [10:0]wr_data_count_1;
  wire wr_rst_busy_0;
  wire wr_rst_busy_1;

  msgld_fifos msgld_fifos_i
       (.FIFO_READ_0_empty(FIFO_READ_0_empty),
        .FIFO_READ_0_rd_data(FIFO_READ_0_rd_data),
        .FIFO_READ_0_rd_en(FIFO_READ_0_rd_en),
        .FIFO_READ_1_empty(FIFO_READ_1_empty),
        .FIFO_READ_1_rd_data(FIFO_READ_1_rd_data),
        .FIFO_READ_1_rd_en(FIFO_READ_1_rd_en),
        .FIFO_WRITE_0_full(FIFO_WRITE_0_full),
        .FIFO_WRITE_0_wr_data(FIFO_WRITE_0_wr_data),
        .FIFO_WRITE_0_wr_en(FIFO_WRITE_0_wr_en),
        .FIFO_WRITE_1_full(FIFO_WRITE_1_full),
        .FIFO_WRITE_1_wr_data(FIFO_WRITE_1_wr_data),
        .FIFO_WRITE_1_wr_en(FIFO_WRITE_1_wr_en),
        .data_count_0(data_count_0),
        .data_count_1(data_count_1),
        .data_valid_0(data_valid_0),
        .overflow_0(overflow_0),
        .prog_empty_0(prog_empty_0),
        .prog_empty_1(prog_empty_1),
        .prog_full_0(prog_full_0),
        .prog_full_1(prog_full_1),
        .rd_data_count_0(rd_data_count_0),
        .rd_data_count_1(rd_data_count_1),
        .rd_rst_busy_0(rd_rst_busy_0),
        .rd_rst_busy_1(rd_rst_busy_1),
        .rst_0(rst_0),
        .rst_1(rst_1),
        .underflow_0(underflow_0),
        .wr_ack_0(wr_ack_0),
        .wr_clk_0(wr_clk_0),
        .wr_clk_1(wr_clk_1),
        .wr_data_count_0(wr_data_count_0),
        .wr_data_count_1(wr_data_count_1),
        .wr_rst_busy_0(wr_rst_busy_0),
        .wr_rst_busy_1(wr_rst_busy_1));
endmodule
