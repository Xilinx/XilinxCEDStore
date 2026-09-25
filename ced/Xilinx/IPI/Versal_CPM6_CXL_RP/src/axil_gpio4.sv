// MODULE : axil_gpio4
//
// DESCRIPTION:
// AXI4-Lite controlled GPIO output block, intended to be added directly to
// a Versal block design (via "Add Module...") and driven from the NOC. All
// AXI4-Lite ports are present with X_INTERFACE_INFO/X_INTERFACE_PARAMETER
// attributes so Vivado infers the S_AXI bus interface and CLK/RST
// association for graphical connection in IPI, even though a few ports
// (AWPROT/ARPROT) are not used internally.
//
// REGISTER MAP:
//  0x00 MODE    [3:0]  R/W - per-GPIO-bit output type; 1'b0=level, 1'b1=pulse
//                            bit[i] controls gpio_out[i]. [31:4] reserved.
//  0x04 STRETCH byte[i][3:0] R/W - pulse stretch for gpio_out[i]; total pulse
//                            width in cycles is STRETCH[i]+1 (0=1 cycle,
//                            15=16 cycles, max). byte[i][7:4] reserved,
//                            writes to those bits are dropped.
//  0x08 GPIO    [19:16] W  - mask; bit[16+i] must be 1 to update gpio_out[i]
//               [3:0]   W  - data; new value driven onto gpio_out[i] when
//                            mask bit[16+i] is set
//                            Read returns {28'h0, gpio_out}.
//
// In pulse mode, a masked write drives gpio_out[i] high for STRETCH[i]+1
// clocks, then it self-clears. In level mode, gpio_out[i] holds its written
// value until the next masked write.

module axil_gpio4 #(
  parameter logic [3:0] GPIO_OUT_INIT = 4'h0,
  parameter logic [1:0] GPIO_0_STRETCH_INIT = 2'h3,
  parameter logic [1:0] GPIO_1_STRETCH_INIT = 2'h3,
  parameter logic [1:0] GPIO_2_STRETCH_INIT = 2'h3,
  parameter logic [1:0] GPIO_3_STRETCH_INIT = 2'h3
)(
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET s_axi_aresetn" *)
  input  wire         s_axi_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire         s_axi_aresetn,

  // Write Address Channel
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWADDR" *)
  input  wire [7:0]   s_axi_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWPROT" *)
  input  wire [2:0]   s_axi_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWVALID" *)
  input  wire         s_axi_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWREADY" *)
  output logic        s_axi_awready,

  // Write Data Channel
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WDATA" *)
  input  wire [31:0]  s_axi_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WSTRB" *)
  input  wire  [3:0]  s_axi_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WVALID" *)
  input  wire         s_axi_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WREADY" *)
  output logic        s_axi_wready,

  // Write Response Channel
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI BRESP" *)
  output logic [1:0]  s_axi_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI BVALID" *)
  output logic        s_axi_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI BREADY" *)
  input  wire         s_axi_bready,

  // Read Address Channel
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARADDR" *)
  input  wire [7:0]   s_axi_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARPROT" *)
  input  wire [2:0]   s_axi_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARVALID" *)
  input  wire         s_axi_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARREADY" *)
  output logic        s_axi_arready,

  // Read Data Channel
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RDATA" *)
  output logic [31:0] s_axi_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RRESP" *)
  output logic  [1:0]  s_axi_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RVALID" *)
  output logic        s_axi_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RREADY" *)
  input  wire         s_axi_rready,

  // GPIO outputs driven by this block
  output logic gpio_out_0,
  output logic gpio_out_1,
  output logic gpio_out_2,
  output logic gpio_out_3
);

  logic [3:0] gpio_out;

  assign gpio_out_0 = gpio_out[0];
  assign gpio_out_1 = gpio_out[1];
  assign gpio_out_2 = gpio_out[2];
  assign gpio_out_3 = gpio_out[3];

  localparam logic [7:0] ADDR_MODE    = 8'h0, 
                         ADDR_STRETCH = 8'h4, 
                         ADDR_GPIO    = 8'h8;

  localparam logic [1:0] OKAY = 2'b00;

  logic  slv_reg_wren;

  assign s_axi_awready = slv_reg_wren;
  assign s_axi_wready  = slv_reg_wren;

  // AW/W are only accepted together (single-outstanding write)
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      slv_reg_wren <= 1'b0;
    else if (slv_reg_wren)
      slv_reg_wren <= 1'b0;
    else if (!s_axi_bvalid && s_axi_awvalid && s_axi_wvalid)
      slv_reg_wren <= 1'b1;
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      s_axi_bvalid <= 1'b0;
    else if (slv_reg_wren)
      {s_axi_bvalid, s_axi_bresp} <= {1'b1, OKAY};
    else if (s_axi_bvalid && s_axi_bready)
      s_axi_bvalid <= 1'b0;
  end

  logic  slv_reg_rden;
  assign slv_reg_rden = s_axi_arready;

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      s_axi_arready <= 1'b0;
    else if (!s_axi_rvalid && s_axi_arvalid && !s_axi_arready)
      s_axi_arready <= 1'b1;
    else
      s_axi_arready <= 1'b0;
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn)
      s_axi_rvalid <= 1'b0;
    else if (slv_reg_rden) begin
      {s_axi_rvalid, s_axi_rresp} <= {1'b1, OKAY};
      case (s_axi_araddr)
        ADDR_MODE:    s_axi_rdata <= {28'h0, reg_mode};
        ADDR_STRETCH: s_axi_rdata <= {4'h0, reg_stretch[3], 4'h0, reg_stretch[2],
                                       4'h0, reg_stretch[1], 4'h0, reg_stretch[0]};
        ADDR_GPIO:    s_axi_rdata <= {28'h0, gpio_out};
        default:      s_axi_rdata <= 32'hFEED_DEAD;
      endcase
    end
    else if (s_axi_rvalid && s_axi_rready)
      s_axi_rvalid <= 1'b0;
  end

  logic [3:0] reg_mode;        // 0=level, 1=pulse, per gpio_out bit
  logic [3:0] reg_stretch [4]; // per-gpio pulse stretch; total pulse width
                                // in cycles is reg_stretch[i]+1
  logic [3:0] pulse_cnt   [4]; // extra cycles left to hold gpio_out[i] high

  wire gpio_wr_en    = slv_reg_wren && (s_axi_awaddr==ADDR_GPIO);
  wire mode_wr_en    = slv_reg_wren && (s_axi_awaddr==ADDR_MODE);
  wire stretch_wr_en = slv_reg_wren && (s_axi_awaddr==ADDR_STRETCH);

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      reg_mode <= '0;
    end else if (mode_wr_en) begin
      for (int i = 0; i < 4; i++)
        if (s_axi_wstrb[i/8])
          reg_mode[i] <= s_axi_wdata[i];
    end
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      for (int i = 0; i < 4; i++)
        reg_stretch[i] <= '0;
    end else if (stretch_wr_en) begin
      for (int i = 0; i < 4; i++)
        if (s_axi_wstrb[i])
          reg_stretch[i] <= s_axi_wdata[8*i +: 4]; // upper nibble of byte dropped
    end
  end

  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      gpio_out <= GPIO_OUT_INIT;
      for (int i = 0; i < 4; i++)
        pulse_cnt[i] <= '0;
    end
    else begin
      for (int i = 0; i < 4; i++) begin
        if (gpio_wr_en && s_axi_wstrb[i/8] && s_axi_wstrb[2+i/8] && s_axi_wdata[16+i]) begin
          gpio_out[i]  <= s_axi_wdata[i];
          pulse_cnt[i] <= reg_stretch[i];
        end
        else if (reg_mode[i] && gpio_out[i]) begin
          if (pulse_cnt[i] != 0)
            pulse_cnt[i] <= pulse_cnt[i] - 1'b1; // hold high for the stretch period
          else
            gpio_out[i] <= 1'b0; // pulse mode: self-clear after stretch cycles
        end
      end
    end
  end

endmodule
