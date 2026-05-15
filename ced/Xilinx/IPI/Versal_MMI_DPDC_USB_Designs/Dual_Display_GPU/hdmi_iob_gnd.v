



module hdmi_iob_gnd (
  output             HDMI_CTRL_scl_i,
  input              HDMI_CTRL_scl_t,
  inout              HDMI_CTRL_scl_io,

  output             HDMI_CTRL_sda_i,
  input              HDMI_CTRL_sda_t,
  inout              HDMI_CTRL_sda_io,

  output             TX_DDC_OUT_scl_i,
  input              TX_DDC_OUT_scl_t,
  inout              TX_DDC_OUT_scl_io,

  output             TX_DDC_OUT_sda_i,
  input              TX_DDC_OUT_sda_t,
  inout              TX_DDC_OUT_sda_io

);

  wire out_lut_ground0;
  wire out_lut_ground1;
  wire out_lut_ground2;
  wire out_lut_ground3;

  IOBUF HDMI_CTRL_scl_iobuf
       (.I(out_lut_ground0),
        .IO(HDMI_CTRL_scl_io),
        .O(HDMI_CTRL_scl_i),
        .T(HDMI_CTRL_scl_t));
  IOBUF HDMI_CTRL_sda_iobuf
       (.I(out_lut_ground1),
        .IO(HDMI_CTRL_sda_io),
        .O(HDMI_CTRL_sda_i),
        .T(HDMI_CTRL_sda_t));
  IOBUF TX_DDC_OUT_scl_iobuf
       (.I(out_lut_ground2),
        .IO(TX_DDC_OUT_scl_io),
        .O(TX_DDC_OUT_scl_i),
        .T(TX_DDC_OUT_scl_t));
  IOBUF TX_DDC_OUT_sda_iobuf
       (.I(out_lut_ground3),
        .IO(TX_DDC_OUT_sda_io),
        .O(TX_DDC_OUT_sda_i),
        .T(TX_DDC_OUT_sda_t));

// The following is to workarund the ground routing problem going to IOB
(* dont_touch = "yes" *) LUT1 #(.INIT(2'b0))  lut_tmp0 (.O(out_lut_ground0),.I0());
(* dont_touch = "yes" *) LUT1 #(.INIT(2'b0))  lut_tmp1 (.O(out_lut_ground1),.I0());
(* dont_touch = "yes" *) LUT1 #(.INIT(2'b0))  lut_tmp2 (.O(out_lut_ground2),.I0());
(* dont_touch = "yes" *) LUT1 #(.INIT(2'b0))  lut_tmp3 (.O(out_lut_ground3),.I0());

endmodule


