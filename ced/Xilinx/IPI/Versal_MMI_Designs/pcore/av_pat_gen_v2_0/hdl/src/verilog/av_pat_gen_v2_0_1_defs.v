`define ENABLE                0        // : std_ulogic;               -- global enable
`define VSYNC_POLARITY        1        // : std_ulogic;               -- active high or low vertical sync
`define HSYNC_POLARITY        2        // : std_ulogic;               -- active high or low horizontal sync
`define DATA_ENABLE_POLARITY  3        // : std_ulogic;               -- active high or low data enable
`define VSYNC_WIDTH           4  +:14   // : unsigned (8 downto 0);    -- vertical sync pulse width in lines
`define HSYNC_WIDTH           18 +:14   // : unsigned (8 downto 0);    -- horizontal sync pulse width in clocks
`define VRES                  32 +:14  // : unsigned (10 downto 0);   -- 2k max vres (0 to vres - 1)
`define HRES                  46 +:14  // : unsigned (10 downto 0);   -- 2k max hres (0 to hres - 1)
`define VERT_BACK_PORCH       60 +:14   // : unsigned (8 downto 0);    -- vertical sync back porch in lines
`define VERT_FRONT_PORCH      74 +:14   //  : unsigned (8 downto 0);    -- vertical sync front porch in lines
`define HORIZ_BACK_PORCH      88 +:14   //  : unsigned (8 downto 0);    -- horizontal sync back porch in clocks
`define HORIZ_FRONT_PORCH     102 +:14   //  : unsigned (8 downto 0);    -- horizontal sync front porch in clocks
`define FRAMELOCK_ENABLE      116      //  : std_ulogic;               -- enable framelocking
`define FRAMELOCK_DELAY       117 +:14  //  : unsigned (21 downto 0);   -- delay for framelock vertical sync
`define FRAMELOCK_ALIGN_HSYNC 131      //  : std_ulogic;               -- align the hsync and vsync in framelock mode
`define FRAMELOCK_LINE_FRAC   132 +:14 //  : unsigned (10 downto 0);   -- fractional line increment in framelock mode

`define TC_HSBLNK             146 +:14 // : unsigned (10 downto 0); -- h starts blank
`define TC_HSSYNC             160 +:14 // : unsigned (10 downto 0); -- h starts sync pulse
`define TC_HESYNC             174 +:14 // : unsigned (10 downto 0); -- h ends sync pulse
`define TC_HEBLNK             188 +:14 // : unsigned (10 downto 0); -- h ends blank 
`define TC_VSBLNK             202 +:14 // : unsigned (10 downto 0); -- v starts blank
`define TC_VSSYNC             216 +:14 // : unsigned (10 downto 0); -- v starts sync pulse
`define TC_VESYNC             230 +:14 // : unsigned (10 downto 0); -- v ends sync pulse
`define TC_VEBLNK             244 +:14 // : unsigned (10 downto 0); -- v ends blank 

`define DISP_DTC_REGS_SIZE    258

// SDP


`define DISP_SDP_PYLD_SIZE    288
`define DISP_SDP_CTRL_SIZE     13

// - SDP Base 0x100
`define SDP_PYLD0        0 +:32   // { HB3[7:0],  HB2[7:0],  HB1[7:0],  HB0[7:0]}  // Reg offset 0x0
`define SDP_PYLD1        32 +:32  // { DB3[7:0],  DB2[7:0],  DB1[7:0],  DB0[7:0]}  // Reg offset 0x4
`define SDP_PYLD2        64 +:32  // { DB7[7:0],  DB6[7:0],  DB5[7:0],  DB4[7:0]}  // Reg offset 0x8
`define SDP_PYLD3        96 +:32  // { DB11[7:0], DB10[7:0], DB9[7:0],  DB8[7:0]}  // Reg offset 0xC
`define SDP_PYLD4        128 +:32 // { DB15[7:0], DB14[7:0], DB13[7:0], DB12[7:0]} // Reg offset 0x10
`define SDP_PYLD5        160 +:32 // { DB19[7:0], DB18[7:0], DB17[7:0], DB16[7:0]} // Reg offset 0x14
`define SDP_PYLD6        192 +:32 // { DB23[7:0], DB22[7:0], DB21[7:0], DB20[7:0]} // Reg offset 0x18
`define SDP_PYLD7        224 +:32 // { DB27[7:0], DB26[7:0], DB25[7:0], DB24[7:0]} // Reg offset 0x1c
`define SDP_PYLD8        256 +:32 // { DB31[7:0], DB30[7:0], DB29[7:0], DB28[7:0]} // Reg offset 0x20

`define SDP_CTRL_HBLANK_TRIG  0         // : std_ulogic;          -- Trigger SDP in HBlank Interval
`define SDP_CTRL_VBLANK_TRIG  1         // : std_ulogic;          -- Trigger SDP in VBlank Interval
`define SDP_CTRL_ONE_SHOT     2         // : std_ulogic;          -- One SDP Packet and Stop
`define SDP_CTRL_AUTO         3         // : std_ulogic;          -- Continuous SDP Packets until bit is set to '0' or enable set to '0'
`define SDP_CTRL_LINE_MAT_AND 4         // : std_ulogic;          -- And of ext_sdp_line_cnt_mat bits[1:0] // else defaults to OR function of ext_sdp_line_cnt_mat bits[1:0]
`define SDP_CTRL_ENABLE       8         // : std_ulogic;          -- Enable // Generates SDP Per line based on above control signals
`define SDP_CTRL_SEC_ENABLE   12        // : std_ulogic;          -- Secondary SDP Bus sdp00 Enable
