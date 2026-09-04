module freerun_cnt32 #(
  parameter bit USE_DSP = 1'b1
)(
  input        clk,
  output logic [31:0] cnt
);

  // 32 bits of freerunning counter:
  // -> 17.2 sec @ 250MHz
  // -> 12.8 sec @ 333MHz
  // -> 11.3 sec @ 380MHz
  if (USE_DSP) begin : GEN_DSP58
    logic [57:0] cnt_full;
    assign cnt = cnt_full[31:0];
  
    DSP58 #(
      .MASK                     (58'h3FF_FFFF_0000_0000), // 58-bit mask value for pattern detect (1=ignore)
      .PATTERN                  (58'h000_0000_FFFF_FFFF), // 58-bit pattern match for pattern detect
      .AMULTSEL                 ("A"),
      .A_INPUT                  ("DIRECT"),
      .BMULTSEL                 ("B"),
      .B_INPUT                  ("DIRECT"),
      .DSP_MODE                 ("INT24"),
      .PREADDINSEL              ("A"),
      .RND                      (58'h0),
      .USE_MULT                 ("NONE"),
      .USE_SIMD                 ("ONE58"),
      .USE_WIDEXOR              ("FALSE"),
      .XORSIMD                  ("XOR24_34_58_116"),
      .AUTORESET_PATDET         ("RESET_MATCH"),
      .AUTORESET_PRIORITY       ("RESET"),
      .SEL_MASK                 ("MASK"),
      .SEL_PATTERN              ("PATTERN"),
      .USE_PATTERN_DETECT       ("PATDET"),
      .IS_ALUMODE_INVERTED      (4'b0000),
      .IS_CARRYIN_INVERTED      (1'b0),
      .IS_CLK_INVERTED          (1'b0),
      .IS_INMODE_INVERTED       (5'b0),
      .IS_NEGATE_INVERTED       (3'b0),
      .IS_OPMODE_INVERTED       (9'b0),
      .IS_RSTALLCARRYIN_INVERTED(1'b0),
      .IS_RSTALUMODE_INVERTED   (1'b0),
      .IS_RSTA_INVERTED         (1'b0),
      .IS_RSTB_INVERTED         (1'b0),
      .IS_RSTCTRL_INVERTED      (1'b0),
      .IS_RSTC_INVERTED         (1'b0),
      .IS_RSTD_INVERTED         (1'b0),
      .IS_RSTINMODE_INVERTED    (1'b0),
      .IS_RSTM_INVERTED         (1'b0),
      .IS_RSTP_INVERTED         (1'b0),
      .AREG                     (0),
      .BREG                     (0),
      .CREG                     (1),
      .PREG                     (1),
      .ALUMODEREG               (0),
      .OPMODEREG                (0),
      .INMODEREG                (0),
      .ACASCREG                 (0),
      .ADREG                    (0),
      .BCASCREG                 (0),
      .CARRYINREG               (0),
      .CARRYINSELREG            (0),
      .DREG                     (0),
      .MREG                     (0),
      .RESET_MODE               ("SYNC")
    ) freerun_counter (
      // Cascade inputs
      .ACIN         ('0),
      .BCIN         ('0),
      .CARRYCASCIN  ('0),
      .MULTSIGNIN   ('0),
      .PCIN         ('0),
      // Cascade outputs
      .ACOUT        (),
      .BCOUT        (),
      .CARRYCASCOUT (),
      .MULTSIGNOUT  (),
      .PCOUT        (),
      // Reset / clock enable inputs
      .CEA1         (1'b0),
      .CEA2         (1'b0),
      .CEAD         (1'b0),
      .CEALUMODE    (1'b0),
      .CEB1         (1'b0),
      .CEB2         (1'b0),
      .CEC          (1'b1),
      .CECARRYIN    (1'b0),
      .CECTRL       (1'b0),
      .CED          (1'b0),
      .CEINMODE     (1'b0),
      .CEM          (1'b0),
      .CEP          (1'b1),
      .ASYNC_RST    (1'b0),
      .RSTA         (1'b1),
      .RSTALLCARRYIN(1'b1),
      .RSTALUMODE   (1'b1),
      .RSTB         (1'b1),
      .RSTC         (1'b1),
      .RSTCTRL      (1'b1),
      .RSTD         (1'b1),
      .RSTINMODE    (1'b1),
      .RSTM         (1'b1),
      .RSTP         (1'b0),
      // Unused outputs
      .OVERFLOW     (),
      .UNDERFLOW    (),
      .PATTERNBDETECT(),
      .PATTERNDETECT(),
      .CARRYOUT     (),
      .XOROUT       (),
      // Unused inputs
      .INMODE       ('0),
      .NEGATE       ('0),
      .A            ('0),
      .B            ('0),
      .C            ('0),
      .D            ('0),
      .CLK          (clk),
      // ALUMODE = 4'h0 -> P = Z+W+X+Y+CIN, targeting P = P+0+0+0+1
      .ALUMODE      (4'h0),
      // OPMODE[8:7]=2'h0 Wmux=0, [6:4]=3'h2 Zmux=P, [3:2]=2'h0 Ymux=0, [1:0]=2'h0 Xmux=0
      .OPMODE       ({2'h0,3'h2,2'h0,2'h0}),
      .CARRYIN      (1'b1),
      .CARRYINSEL   (3'h0),
      .P            (cnt_full)
    );
  end : GEN_DSP58
  else begin : GEN_FFS
    initial cnt <= '0; //for sim
    always @(posedge clk) cnt <= cnt+1'b1;
  end : GEN_FFS

endmodule
