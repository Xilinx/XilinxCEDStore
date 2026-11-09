`timescale 1ns/1ps

module tb_top;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  import base_agent_pkg::*;
  import cxl_nfi_agent_pkg::*;
  import cxl31_tl_pkg::*;
  import cxl31_ll_pkg::*;
  import cxl_nfi_other_pkg::*;
  import params_pkg::*;

  bit clock;
  initial begin
    clock = 1'b0;
    forever clock = #5 !clock;
  end

  // Structure
  `include "test_env.sv"

  `include "custom_report_server.sv"
  `include "base_test.sv"
  // Tests
  `include "h2c_cache_qpacker_stress_test.sv"
  `include "h2c_mem_qpacker_stress_test.sv"
  `include "h2c_cachemem_qpacker_stress_test.sv"
  `include "c2h_cache_qpacker_stress_test.sv"
  `include "c2h_mem_qpacker_stress_test.sv"
  `include "c2h_cachemem_qpacker_stress_test.sv"
  `include "h2c_mem_api_test.sv"
  `include "h2c_cache_api_test.sv"
  `include "h2c_cache_mdh_api_test.sv"
  `include "c2h_mem_api_test.sv"
  `include "c2h_mem_mdh_api_test.sv"
  `include "c2h_cache_api_test.sv"
  `include "c2h_cache_mdh_api_test.sv"

  cxl_nfi_agent_if #(N) h2c_mst_if(), h2c_slv_if();
  cxl_nfi_agent_if #(N) c2h_mst_if(), c2h_slv_if();

  typedef enum bit [7:0] {/*F68*/ H0, H1, H2, H3, H4, H5, G0, G1, G2, G3, G4, G5, G6, NA, ADF,
                /* more for F256*/H6, H7, H8, H9, H10, H11, H12, H13, H14, H15,
                                      G7, G8, G9, G10, G11, G12, G13, G14, G15,
                                      PHY, DAT} slot_fmt_t;

  logic [1:0] h2c_f256_ssptr[3], c2h_f256_ssptr[3]; //ssptr = "slotset ptr" for each slotset

  bit [0:3] h2c_dec_sop_swz[0:2], c2h_dec_sop_swz[0:2];
  bit [0:3] h2c_dec_eop_swz[0:2], c2h_dec_eop_swz[0:2];
  bit [0:3] h2c_dec_mem_swz[0:2], c2h_dec_mem_swz[0:2];
  bit [0:3] h2c_dec_be_swz[0:2],  c2h_dec_be_swz[0:2];

  // Easier GUI debug because we read left to right
  always_comb begin
    for (int ii=0; ii<N; ii++) begin
      for (int jj=0; jj<4; jj++) begin
        h2c_dec_sop_swz[ii][jj] = h2c_mst_if.dec_sop[ii][jj];
        h2c_dec_eop_swz[ii][jj] = h2c_mst_if.dec_eop[ii][jj];
        h2c_dec_mem_swz[ii][jj] = h2c_mst_if.dec_mem[ii][jj];
        h2c_dec_be_swz[ii][jj]  = h2c_mst_if.dec_be[ii][jj];
        h2c_dec_sop_swz[ii][jj] = h2c_mst_if.dec_sop[ii][jj];
        h2c_dec_eop_swz[ii][jj] = h2c_mst_if.dec_eop[ii][jj];
        h2c_dec_mem_swz[ii][jj] = h2c_mst_if.dec_mem[ii][jj];
        h2c_dec_be_swz[ii][jj]  = h2c_mst_if.dec_be[ii][jj];
      end
    end
  end

  case ({MODE, N})
    {F256, 32'd1} : 
    begin
      initial begin
        h2c_f256_ssptr[0] = 2'd0;
        c2h_f256_ssptr[0] = 2'd0;
      end
      always @(posedge clock) begin
        if (h2c_mst_if.valid[0]) h2c_f256_ssptr[0] <= h2c_f256_ssptr[0]+1;
        if (c2h_mst_if.valid[0]) c2h_f256_ssptr[0] <= c2h_f256_ssptr[0]+1;
      end
    end
    {F256, 32'd2} : 
    begin
      initial begin
        h2c_f256_ssptr[0:1] = {2'd0, 2'd1};
        c2h_f256_ssptr[0:1] = {2'd0, 2'd1};
      end
      always @(posedge clock) begin
        if (h2c_mst_if.valid[0]) begin
          h2c_f256_ssptr[0] <= h2c_f256_ssptr[0]+2;
          h2c_f256_ssptr[1] <= h2c_f256_ssptr[1]+2;
        end
        if (c2h_mst_if.valid[0]) begin
          c2h_f256_ssptr[0] <= c2h_f256_ssptr[0]+2;
          c2h_f256_ssptr[1] <= c2h_f256_ssptr[1]+2;
        end
      end
    end
    {F256, 32'd3} : 
    begin
      initial begin
        h2c_f256_ssptr[0] = 2'd0;
        c2h_f256_ssptr[0] = 2'd0;
      end
      // Clock the lowest ss
      always @(posedge clock) begin
        case (h2c_f256_ssptr[0])
          0 : if (h2c_mst_if.valid[0]) h2c_f256_ssptr[0] <= 2'd3;
          3 : if (h2c_mst_if.valid[0]) h2c_f256_ssptr[0] <= h2c_mst_if.valid[1] ? 2'd2 : 2'd0;
          2 : if (h2c_mst_if.valid[0]) h2c_f256_ssptr[0] <= h2c_mst_if.valid[2] ? 2'd1 : 2'd1;
          1 : if (h2c_mst_if.valid[0]) h2c_f256_ssptr[0] <= 2'd0;
        endcase
        case (c2h_f256_ssptr[0])
          0 : if (c2h_mst_if.valid[0]) c2h_f256_ssptr[0] <= 2'd3;
          3 : if (c2h_mst_if.valid[0]) c2h_f256_ssptr[0] <= c2h_mst_if.valid[1] ? 2'd2 : 2'd0;
          2 : if (c2h_mst_if.valid[0]) c2h_f256_ssptr[0] <= c2h_mst_if.valid[2] ? 2'd1 : 2'd1;
          1 : if (c2h_mst_if.valid[0]) c2h_f256_ssptr[0] <= 2'd0;
        endcase
      end
      // Combinationally assign the split upper ss
      always_comb begin
        case (h2c_f256_ssptr[0])
          0 : h2c_f256_ssptr[1:2] = '{2'd1, 2'd2};
          3 : h2c_f256_ssptr[1:2] = h2c_mst_if.valid[1] ? '{2'd0, 2'd1} : '{'x, 'x};
          2 : h2c_f256_ssptr[1:2] = '{2'd3, h2c_mst_if.valid[2] ? 2'd0 : 'x};
          1 : h2c_f256_ssptr[1:2] = '{2'd2, 2'd3};
        endcase
        case (c2h_f256_ssptr[0])
          0 : c2h_f256_ssptr[1:2] = '{2'd1, 2'd2};
          3 : c2h_f256_ssptr[1:2] = c2h_mst_if.valid[1] ? '{2'd0, 2'd1} : '{'x, 'x};
          2 : c2h_f256_ssptr[1:2] = '{2'd3, c2h_mst_if.valid[2] ? 2'd0 : 'x};
          1 : c2h_f256_ssptr[1:2] = '{2'd2, 2'd3};
        endcase
      end
    end
  endcase

  function slot_fmt_t get_hslot_fmt(bit [3:0] fmt);
    case (fmt)
      0 : return H0;
      1 : return H1;
      2 : return H2;
      3 : return H3;
      4 : return H4;
      5 : return H5;
      6 : return H6;
      7 : return H7;
      8 : return H8;
      9 : return H9;
      10: return H10;
      11: return H11;
      12: return H12;
      13: return H13;
      14: return H14;
      15: return H15;
    endcase
  endfunction

  function int get_slot_mreq(bit [127:0] data);
    if (data[3:0] != 4) return 0;
    else return (data[4]); 
  endfunction

  function int get_slot_mrwd(bit [127:0] data);
    if (data[3:0] != 14) return 0;
    else return (data[4]); 
  endfunction

  function int get_slot_mndr(bit [127:0] data, bit hslot=0);
    if (!(data[3:0] inside {6,7})) return 0;
    else if (data[3:0]==6) return (hslot ? 0 : data[88]); 
    else if (data[3:0]==7) return (hslot ? data[4]+data[44] :
                                           data[4]+data[44]+data[84]
                                  ); 
  endfunction

  function int get_slot_mdrs(bit [127:0] data, bit hslot=0);
    if (data[3:0] != 15) return 0;
    else return (hslot ? data[4]+data[44] : 
                         data[4]+data[44]+data[84]
                ); 
  endfunction

  function int get_hslot_rollout(bit [111:0] dat);
    int ro;
    ro = 0;
    case (dat[3:0])
      12 : ro += 4*(dat[ 4]+dat[32]+dat[60]);
      13 : ro += dat[ 4]*(4+dat[19])+
                 dat[28]*(4+dat[43])+
                 dat[52]*(4+dat[67])+
                 dat[76]*(4+dat[91]);
      14 : ro += dat[ 4]*(4+dat[79]);
      15 : ro += dat[ 4]*(4+dat[35])+ 
                 dat[44]*(4+dat[75]);
    endcase
    return ro;
  endfunction

  function slot_fmt_t get_gslot_fmt(bit [3:0] fmt);
    case (fmt)
      0 : return G0;
      1 : return G1;
      2 : return G2;
      3 : return G3;
      4 : return G4;
      5 : return G5;
      6 : return G6;
      7 : return G7;
      8 : return G8;
      9 : return G9;
      10: return G10;
      11: return G11;
      12: return G12;
      13: return G13;
      14: return G14;
      15: return G15;
    endcase
  endfunction

  function int get_gslot_rollout(bit [127:0] dat);
    int ro;
    ro = 0;
    case (dat[3:0])
      12 : ro += 4*(dat[ 4]+dat[32]+dat[60]+dat[88]);
      13 : ro += dat[ 4]*(4+dat[19])+
                 dat[28]*(4+dat[43])+
                 dat[52]*(4+dat[67])+
                 dat[76]*(4+dat[91]);
      14 : ro += dat[ 4]*(4+dat[79]);
      15 : ro += dat[ 4]*(4+dat[35])+ 
                 dat[44]*(4+dat[75])+
                 dat[84]*(4+dat[115]);
    endcase
    return ro;
  endfunction

  // Helpers for Waves 
  // ss = "slotset"; for 68B, each slotset is a flit. for 256B, each slotset is 1/4 of a flit
  slot_fmt_t h2c_ss0_sf[0:3],   h2c_ss1_sf[0:3],   h2c_ss2_sf[0:3];
  int        h2c_ss0_mreq[0:3], h2c_ss1_mreq[0:3], h2c_ss2_mreq[0:3]; //68B:max 2/flit | 256B: max 4/128B
  bit [0:3]  h2c_ss0_mrwd,      h2c_ss1_mrwd,      h2c_ss2_mrwd;      //68B:max 1/flit | 256B: max 2/128B
  int        h2c_rolli[0:2];
  int        h2c_rollo[0:2];
  always@(h2c_mst_if.valid, h2c_mst_if.data) begin 
    // Flit 0 
    h2c_ss0_sf   = '{NA,NA,NA,NA};
    h2c_ss0_mreq = '{0, 0, 0, 0};
    h2c_ss0_mrwd = 4'h0;
    if (MODE==F68) begin
      if (h2c_mst_if.valid[0] && h2c_mst_if.adf[0]) begin
        h2c_ss0_sf = '{ADF,ADF,ADF,ADF};
      end
      else if (h2c_mst_if.valid[0] && !h2c_mst_if.data[0][0]) begin //protocol flit
        case (h2c_mst_if.data[0][5+:3])
          0 : h2c_ss0_sf[0] = H0;
          1 : h2c_ss0_sf[0] = H1;
          2 : h2c_ss0_sf[0] = H2;
          3 : h2c_ss0_sf[0] = H3;
          4 : begin
                h2c_ss0_sf[0] = H4;
                h2c_ss0_mrwd[0] = h2c_mst_if.data[0][32];
              end
          5 : begin
                h2c_ss0_sf[0] = H5;
                h2c_ss0_mreq[0] = h2c_mst_if.data[0][32];
              end
          default : h2c_ss0_sf[0] = NA;
        endcase
        case (h2c_mst_if.data[0][8+:3])
          0 : h2c_ss0_sf[1] = G0;
          1 : h2c_ss0_sf[1] = G1;
          2 : h2c_ss0_sf[1] = G2;
          3 : h2c_ss0_sf[1] = G3;
          4 : begin
                h2c_ss0_sf[1] = G4;
                h2c_ss0_mreq[1] = h2c_mst_if.data[0][128*1+0];
              end
          5 : begin
                h2c_ss0_sf[1] = G5;
                h2c_ss0_mrwd[1] = h2c_mst_if.data[0][128*1+0];
              end
          default : h2c_ss0_sf[1] = NA;
        endcase
        case (h2c_mst_if.data[0][11+:3])
          0 : h2c_ss0_sf[2] = G0;
          1 : h2c_ss0_sf[2] = G1;
          2 : h2c_ss0_sf[2] = G2;
          3 : h2c_ss0_sf[2] = G3;
          4 : begin
                h2c_ss0_sf[2] = G4;
                h2c_ss0_mreq[2] = h2c_mst_if.data[0][128*2+0];
              end
          5 : begin
                h2c_ss0_sf[2] = G5;
                h2c_ss0_mrwd[2] = h2c_mst_if.data[0][128*2+0];
              end
          default : h2c_ss0_sf[2] = NA;
        endcase
        case (h2c_mst_if.data[0][14+:3])
          0 : h2c_ss0_sf[3] = G0;
          1 : h2c_ss0_sf[3] = G1;
          2 : h2c_ss0_sf[3] = G2;
          3 : h2c_ss0_sf[3] = G3;
          4 : begin
                h2c_ss0_sf[3] = G4;
                h2c_ss0_mreq[3] = h2c_mst_if.data[0][128*3+0];
              end
          5 : begin
                h2c_ss0_sf[3] = G5;
                h2c_ss0_mrwd[3] = h2c_mst_if.data[0][128*3+0];
              end
          default : h2c_ss0_sf[3] = NA;
        endcase
      end
      // Flit 1 
      h2c_ss1_sf   = '{NA,NA,NA,NA};
      h2c_ss1_mreq = '{0, 0, 0, 0};
      h2c_ss1_mrwd = 4'h0;
      if (N > 1) begin
        if (h2c_mst_if.valid[1] && h2c_mst_if.adf[1])
          h2c_ss1_sf = '{ADF,ADF,ADF,ADF};
        else if (h2c_mst_if.valid[1] && !h2c_mst_if.data[1][0]) begin //protocol flit
          case (h2c_mst_if.data[1][5+:3])
            0 : h2c_ss1_sf[0] = H0;
            1 : h2c_ss1_sf[0] = H1;
            2 : h2c_ss1_sf[0] = H2;
            3 : h2c_ss1_sf[0] = H3;
            4 : begin
                  h2c_ss1_sf[0] = H4;
                  h2c_ss1_mrwd[0] = h2c_mst_if.data[1][32];
                end
            5 : begin
                  h2c_ss1_sf[0] = H5;
                  h2c_ss1_mreq[0] = h2c_mst_if.data[1][32];
                end
            default : h2c_ss1_sf[0] = NA;
          endcase
          case (h2c_mst_if.data[1][8+:3])
            0 : h2c_ss1_sf[1] = G0;
            1 : h2c_ss1_sf[1] = G1;
            2 : h2c_ss1_sf[1] = G2;
            3 : h2c_ss1_sf[1] = G3;
            4 : begin
                  h2c_ss1_sf[1] = G4;
                  h2c_ss1_mreq[1] = h2c_mst_if.data[1][128*1+0];
                end
            5 : begin
                  h2c_ss1_sf[1] = G5;
                  h2c_ss1_mrwd[1] = h2c_mst_if.data[1][128*1+0];
                end
            default : h2c_ss1_sf[1] = NA;
          endcase
          case (h2c_mst_if.data[1][11+:3])
            0 : h2c_ss1_sf[2] = G0;
            1 : h2c_ss1_sf[2] = G1;
            2 : h2c_ss1_sf[2] = G2;
            3 : h2c_ss1_sf[2] = G3;
            4 : begin
                  h2c_ss1_sf[2] = G4;
                  h2c_ss1_mreq[2] = h2c_mst_if.data[1][128*2+0];
                end
            5 : begin
                  h2c_ss1_sf[2] = G5;
                  h2c_ss1_mrwd[2] = h2c_mst_if.data[1][128*2+0];
                end
            default : h2c_ss1_sf[2] = NA;
          endcase
          case (h2c_mst_if.data[1][14+:3])
            0 : h2c_ss1_sf[3] = G0;
            1 : h2c_ss1_sf[3] = G1;
            2 : h2c_ss1_sf[3] = G2;
            3 : h2c_ss1_sf[3] = G3;
            4 : begin
                  h2c_ss1_sf[3] = G4;
                  h2c_ss1_mreq[3] = h2c_mst_if.data[1][128*3+0];
                end
            5 : begin
                  h2c_ss1_sf[3] = G5;
                  h2c_ss1_mrwd[3] = h2c_mst_if.data[1][128*3+0];
                end
            default : h2c_ss1_sf[3] = NA;
          endcase
        end
      end
      // Flit 2 
      h2c_ss2_sf   = '{NA,NA,NA,NA};
      h2c_ss2_mreq = '{0, 0, 0, 0};
      h2c_ss2_mrwd = 4'h0;
      if (N > 2) begin
        if (h2c_mst_if.valid[2] && h2c_mst_if.adf[2])
          h2c_ss2_sf = '{ADF,ADF,ADF,ADF};
        else if (h2c_mst_if.valid[2] && !h2c_mst_if.data[2][0]) begin //protocol flit
          case (h2c_mst_if.data[2][5+:3])
            0 : h2c_ss2_sf[0] = H0;
            1 : h2c_ss2_sf[0] = H1;
            2 : h2c_ss2_sf[0] = H2;
            3 : h2c_ss2_sf[0] = H3;
            4 : begin
                  h2c_ss2_sf[0] = H4;
                  h2c_ss2_mrwd[0] = h2c_mst_if.data[2][32];
                end
            5 : begin
                  h2c_ss2_sf[0] = H5;
                  h2c_ss2_mreq[0] = h2c_mst_if.data[2][32];
                end
            default : h2c_ss2_sf[0] = NA;
          endcase
          case (h2c_mst_if.data[2][8+:3])
            0 : h2c_ss2_sf[1] = G0;
            1 : h2c_ss2_sf[1] = G1;
            2 : h2c_ss2_sf[1] = G2;
            3 : h2c_ss2_sf[1] = G3;
            4 : begin
                  h2c_ss2_sf[1] = G4;
                  h2c_ss2_mreq[1] = h2c_mst_if.data[2][128*1+0];
                end
            5 : begin
                  h2c_ss2_sf[1] = G5;
                  h2c_ss2_mrwd[1] = h2c_mst_if.data[2][128*1+0];
                end
            default : h2c_ss2_sf[1] = NA;
          endcase
          case (h2c_mst_if.data[2][11+:3])
            0 : h2c_ss2_sf[2] = G0;
            1 : h2c_ss2_sf[2] = G1;
            2 : h2c_ss2_sf[2] = G2;
            3 : h2c_ss2_sf[2] = G3;
            4 : begin
                  h2c_ss2_sf[2] = G4;
                  h2c_ss2_mreq[2] = h2c_mst_if.data[2][128*2+0];
                end
            5 : begin
                  h2c_ss2_sf[2] = G5;
                  h2c_ss2_mrwd[2] = h2c_mst_if.data[2][128*2+0];
                end
            default : h2c_ss2_sf[2] = NA;
          endcase
          case (h2c_mst_if.data[2][14+:3])
            0 : h2c_ss2_sf[3] = G0;
            1 : h2c_ss2_sf[3] = G1;
            2 : h2c_ss2_sf[3] = G2;
            3 : h2c_ss2_sf[3] = G3;
            4 : begin
                  h2c_ss2_sf[3] = G4;
                  h2c_ss2_mreq[3] = h2c_mst_if.data[2][128*3+0];
                end
            5 : begin
                  h2c_ss2_sf[3] = G5;
                  h2c_ss2_mrwd[3] = h2c_mst_if.data[2][128*3+0];
                end
            default : h2c_ss2_sf[3] = NA;
          endcase
        end
      end
    end //if MODE==F68
    else if (MODE==F256) begin
      /* Slotset A */
      case (N)
        1 : h2c_rolli[0] = h2c_rollo[0];
        2 : h2c_rolli[0] = h2c_rollo[1];
        3 : h2c_rolli[0] = h2c_rollo[2];
      endcase
      if (h2c_mst_if.valid[0]) begin
        // Slot 0 (H-Slot)
        if (h2c_f256_ssptr[0] == 0) begin
          h2c_ss0_sf[0]   = get_hslot_fmt(h2c_mst_if.data[0][16+:4]);
          h2c_ss0_mreq[0] = get_slot_mreq(h2c_mst_if.data[0][127:16]); 
          h2c_ss0_mrwd[0] = get_slot_mrwd(h2c_mst_if.data[0][127:16]); 
          h2c_rollo[0]    = h2c_rolli[0] + get_hslot_rollout(h2c_mst_if.data[0][127:16]);
        end
        // Slot A
        else if (h2c_rolli[0]) begin
          h2c_ss0_sf[0] = DAT;
          h2c_rollo[0]  = h2c_rolli[0]-1;
        end
        else begin
          h2c_ss0_sf[0]   = get_gslot_fmt(h2c_mst_if.data[0][128*0+:4]);
          h2c_ss0_mreq[0] = get_slot_mreq(h2c_mst_if.data[0][0*128+:128]); 
          h2c_ss0_mrwd[0] = get_slot_mrwd(h2c_mst_if.data[0][0*128+:128]); 
          h2c_rollo[0]    = get_gslot_rollout(h2c_mst_if.data[0][0*128+:128]);
        end
        // Slot B (G-Slot)
        if (h2c_rollo[0]) begin
          h2c_ss0_sf[1] = DAT;
          h2c_rollo[0]--;
        end
        else begin
          h2c_ss0_sf[1]   = get_gslot_fmt(h2c_mst_if.data[0][128*1+:4]);
          h2c_ss0_mreq[1] = get_slot_mreq(h2c_mst_if.data[0][1*128+:128]); 
          h2c_ss0_mrwd[1] = get_slot_mrwd(h2c_mst_if.data[0][1*128+:128]); 
          h2c_rollo[0]    = get_gslot_rollout(h2c_mst_if.data[0][1*128+:128]);
        end
        // Slot C (G-Slot)
        if (h2c_rollo[0]) begin
          h2c_ss0_sf[2] = DAT;
          h2c_rollo[0]--;
        end
        else begin
          h2c_ss0_sf[2]   = get_gslot_fmt(h2c_mst_if.data[0][128*2+:4]);
          h2c_ss0_mreq[2] = get_slot_mreq(h2c_mst_if.data[0][2*128+:128]); 
          h2c_ss0_mrwd[2] = get_slot_mrwd(h2c_mst_if.data[0][2*128+:128]); 
          h2c_rollo[0]    = get_gslot_rollout(h2c_mst_if.data[0][2*128+:128]);
        end
        // Slot 15 (PHY)
        if (h2c_f256_ssptr[0] == 3)
          h2c_ss0_sf[3] = PHY;
        // Slot D (G-Slot)
        else if (h2c_rollo[0]) begin
          h2c_ss0_sf[3] = DAT;
          h2c_rollo[0]--;
        end
        else begin
          h2c_ss0_sf[3]   = get_gslot_fmt(h2c_mst_if.data[0][128*3+:4]);
          h2c_ss0_mreq[3] = get_slot_mreq(h2c_mst_if.data[0][3*128+:128]); 
          h2c_ss0_mrwd[3] = get_slot_mrwd(h2c_mst_if.data[0][3*128+:128]); 
          h2c_rollo[0]    = get_gslot_rollout(h2c_mst_if.data[0][3*128+:128]);
        end
      end
      /* Slotset B */
      if (N>1 && h2c_mst_if.valid[1]) begin
        // Slot 0 (H-Slot)
        if (h2c_f256_ssptr[1] == 0) begin
          h2c_ss1_sf[0]   = get_hslot_fmt(h2c_mst_if.data[1][16+:4]);
          h2c_ss1_mreq[0] = get_slot_mreq(h2c_mst_if.data[1][127:16]);
          h2c_ss1_mrwd[0] = get_slot_mrwd(h2c_mst_if.data[1][127:16]);
          h2c_rollo[1]    = h2c_rolli[1] + get_hslot_rollout(h2c_mst_if.data[1][127:16]);
        end
        // Slot A
        else if (h2c_rolli[1]) begin
          h2c_ss1_sf[0] = DAT;
          h2c_rollo[1] = h2c_rolli[1]-1;
        end
        else begin
          h2c_ss1_sf[0]   = get_gslot_fmt(h2c_mst_if.data[1][128*0+:4]);
          h2c_ss1_mreq[0] = get_slot_mreq(h2c_mst_if.data[1][1*128+:128]); 
          h2c_ss1_mrwd[0] = get_slot_mrwd(h2c_mst_if.data[1][1*128+:128]); 
          h2c_rollo[1]    = get_gslot_rollout(h2c_mst_if.data[1][0*128+:128]);
        end
        // Slot B (G-Slot)
        if (h2c_rollo[1]) begin
          h2c_ss1_sf[1] = DAT;
          h2c_rollo[1]--;
        end
        else begin
          h2c_ss1_sf[1]   = get_gslot_fmt(h2c_mst_if.data[1][128*1+:4]);
          h2c_ss1_mreq[1] = get_slot_mreq(h2c_mst_if.data[1][1*128+:128]); 
          h2c_ss1_mrwd[1] = get_slot_mrwd(h2c_mst_if.data[1][1*128+:128]); 
          h2c_rolli[1]    = get_gslot_rollout(h2c_mst_if.data[1][1*128+:128]);
        end
        // Slot C (G-Slot)
        if (h2c_rollo[1]) begin
          h2c_ss1_sf[2] = DAT;
          h2c_rolli[1]--;
        end
        else begin
          h2c_ss1_sf[2]   = get_gslot_fmt(h2c_mst_if.data[1][128*2+:4]);
          h2c_ss1_mreq[2] = get_slot_mreq(h2c_mst_if.data[1][2*128+:128]); 
          h2c_ss1_mrwd[2] = get_slot_mrwd(h2c_mst_if.data[1][2*128+:128]); 
          h2c_rolli[1]    = get_gslot_rollout(h2c_mst_if.data[1][2*128+:128]);
        end
        // Slot 15 (PHY)
        if (h2c_f256_ssptr[1] == 3)
          h2c_ss1_sf[3] = PHY;
        // Slot D (G-Slot)
        else if (h2c_rollo[1]) begin
          h2c_ss1_sf[3] = DAT;
          h2c_rollo[1]--;
        end
        else begin
          h2c_ss1_sf[3]   = get_gslot_fmt(h2c_mst_if.data[1][128*3+:4]);
          h2c_ss1_mreq[3] = get_slot_mreq(h2c_mst_if.data[1][3*128+:128]); 
          h2c_ss1_mrwd[3] = get_slot_mrwd(h2c_mst_if.data[1][3*128+:128]); 
          h2c_rolli[1]    = get_gslot_rollout(h2c_mst_if.data[1][3*128+:128]);
        end
      end
      /* Slotset C */
      if (N>2 && h2c_mst_if.valid[2]) begin
        // Slot 0 (H-Slot)
        if (h2c_f256_ssptr[2] == 0) begin
          h2c_ss2_sf[0]   = get_hslot_fmt(h2c_mst_if.data[2][16+:4]);
          h2c_ss2_mreq[0] = get_slot_mreq(h2c_mst_if.data[2][127:16]);
          h2c_ss2_mrwd[0] = get_slot_mrwd(h2c_mst_if.data[2][127:16]);
          h2c_rollo[2]    = h2c_rolli[2] + get_hslot_rollout(h2c_mst_if.data[2][127:16]);
        end
        // Slot A
        else if (h2c_rollo[2]) begin
          h2c_ss2_sf[0] = DAT;
          h2c_rollo[2]--;
        end
        else begin
          h2c_ss2_sf[0]   = get_gslot_fmt(h2c_mst_if.data[2][128*0+:4]);
          h2c_ss2_mreq[0] = get_slot_mreq(h2c_mst_if.data[2][0*128+:128]);
          h2c_ss2_mrwd[0] = get_slot_mrwd(h2c_mst_if.data[2][0*128+:128]);
          h2c_rollo[2]    = get_gslot_rollout(h2c_mst_if.data[2][0*128+:128]);
        end
        // Slot B (G-Slot)
        if (h2c_rollo[2]) begin
          h2c_ss2_sf[1] = DAT;
          h2c_rollo[2]--;
        end
        else begin
          h2c_ss2_sf[1]   = get_gslot_fmt(h2c_mst_if.data[2][128*1+:4]);
          h2c_ss2_mreq[1] = get_slot_mreq(h2c_mst_if.data[2][1*128+:128]);
          h2c_ss2_mrwd[1] = get_slot_mrwd(h2c_mst_if.data[2][1*128+:128]);
          h2c_rollo[2]    = get_gslot_rollout(h2c_mst_if.data[2][1*128+:128]);
        end
        // Slot C (G-Slot)
        if (h2c_rollo[2]) begin
          h2c_ss2_sf[2] = DAT;
          h2c_rollo[2]--;
        end
        else begin
          h2c_ss2_sf[2]   = get_gslot_fmt(h2c_mst_if.data[2][128*2+:4]);
          h2c_ss2_mreq[2] = get_slot_mreq(h2c_mst_if.data[2][2*128+:128]);
          h2c_ss2_mrwd[2] = get_slot_mrwd(h2c_mst_if.data[2][2*128+:128]);
          h2c_rollo[2]    = get_gslot_rollout(h2c_mst_if.data[2][2*128+:128]);
        end
        // Slot 15 (PHY)
        if (h2c_f256_ssptr[2] == 3)
          h2c_ss2_sf[3] = PHY;
        // Slot D (G-Slot)
        else if (h2c_rollo[2]) begin
          h2c_ss2_sf[3] = DAT;
          h2c_rollo[2]--;
        end
        else begin
          h2c_ss2_sf[3]   = get_gslot_fmt(h2c_mst_if.data[2][128*3+:4]);
          h2c_ss2_mreq[3] = get_slot_mreq(h2c_mst_if.data[2][3*128+:128]);
          h2c_ss2_mrwd[3] = get_slot_mrwd(h2c_mst_if.data[2][3*128+:128]);
          h2c_rollo[2]    = get_gslot_rollout(h2c_mst_if.data[2][3*128+:128]);
        end
      end
    end //if MODE==F256
  end

  slot_fmt_t c2h_ss0_sf[0:3],   c2h_ss1_sf[0:3],   c2h_ss2_sf[0:3];
  int        c2h_ss0_mndr[0:3], c2h_ss1_mndr[0:3], c2h_ss2_mndr[0:3]; //68B: max 2/flit | 256B: max 6/128B
  int        c2h_ss0_mdrs[0:3], c2h_ss1_mdrs[0:3], c2h_ss2_mdrs[0:3]; //68B: max 3/flit | 256B: max 3/128B
  int        c2h_rolli[0:2];
  int        c2h_rollo[0:2];
  always@(c2h_mst_if.valid, c2h_mst_if.data) begin 
    // Flit 0 
    c2h_ss0_sf   = '{NA,NA,NA,NA};
    c2h_ss0_mndr = '{0, 0, 0, 0};
    c2h_ss0_mdrs = '{0, 0, 0, 0};
    if (MODE==F68) begin
      if (c2h_mst_if.valid[0] && c2h_mst_if.adf[0])
        c2h_ss0_sf = '{ADF,ADF,ADF,ADF};
      else if (c2h_mst_if.valid[0] && !c2h_mst_if.data[0][0]) begin //protocol flit
        case (c2h_mst_if.data[0][5+:3])
          0 : begin
                c2h_ss0_sf[0] = H0;
                c2h_ss0_mndr[0] = c2h_mst_if.data[0][89];
              end
          1 : c2h_ss0_sf[0] = H1;
          2 : c2h_ss0_sf[0] = H2;
          3 : begin
                c2h_ss0_sf[0] = H3;
                c2h_ss0_mdrs[0] = c2h_mst_if.data[0][32];
                c2h_ss0_mndr[0] = c2h_mst_if.data[0][72];
              end
          4 : begin
                c2h_ss0_sf[0] = H4;
                c2h_ss0_mndr[0] = c2h_mst_if.data[0][32]+c2h_mst_if.data[0][60];
              end
          5 : begin
                c2h_ss0_sf[0] = H5;
                c2h_ss0_mdrs[0] = c2h_mst_if.data[0][32]+c2h_mst_if.data[0][72];
              end
          default : c2h_ss0_sf[0] = NA;
        endcase
        case (c2h_mst_if.data[0][8+:3])
          0 : c2h_ss0_sf[1] = G0;
          1 : c2h_ss0_sf[1] = G1;
          2 : c2h_ss0_sf[1] = G2;
          3 : c2h_ss0_sf[1] = G3;
          4 : begin
                c2h_ss0_sf[1] = G4;
                c2h_ss0_mdrs[1] = c2h_mst_if.data[0][128*1];
                c2h_ss0_mndr[1] = c2h_mst_if.data[0][128*1+40]+c2h_mst_if.data[0][128*1+68];
              end
          5 : begin
                c2h_ss0_sf[1] = G5;
                c2h_ss0_mndr[1] = c2h_mst_if.data[0][128*1]+c2h_mst_if.data[0][128*1+28];
              end
          6 : begin
                c2h_ss0_sf[1] = G6;
                c2h_ss0_mdrs[1] = c2h_mst_if.data[0][128*1]+c2h_mst_if.data[0][128*1+40]+c2h_mst_if.data[0][128*1+80];
              end
          default : c2h_ss0_sf[1] = NA;
        endcase
        case (c2h_mst_if.data[0][11+:3])
          0 : c2h_ss0_sf[2] = G0;
          1 : c2h_ss0_sf[2] = G1;
          2 : c2h_ss0_sf[2] = G2;
          3 : c2h_ss0_sf[2] = G3;
          4 : begin
                c2h_ss0_sf[2] = G4;
                c2h_ss0_mdrs[2] = c2h_mst_if.data[0][128*2];
                c2h_ss0_mndr[2] = c2h_mst_if.data[0][128*2+40]+c2h_mst_if.data[0][128*2+68];
              end
          5 : begin
                c2h_ss0_sf[2] = G5;
                c2h_ss0_mndr[2] = c2h_mst_if.data[0][128*2]+c2h_mst_if.data[0][128*2+28];
              end
          6 : begin
                c2h_ss0_sf[2] = G6;
                c2h_ss0_mdrs[2] = c2h_mst_if.data[0][128*2]+c2h_mst_if.data[0][128*2+40]+c2h_mst_if.data[0][128*2+80];
              end
          default : c2h_ss0_sf[2] = NA;
        endcase
        case (c2h_mst_if.data[0][14+:3])
          0 : c2h_ss0_sf[3] = G0;
          1 : c2h_ss0_sf[3] = G1;
          2 : c2h_ss0_sf[3] = G2;
          3 : c2h_ss0_sf[3] = G3;
          4 : begin
                c2h_ss0_sf[3] = G4;
                c2h_ss0_mdrs[3] = c2h_mst_if.data[0][128*3];
                c2h_ss0_mndr[3] = c2h_mst_if.data[0][128*3+40]+c2h_mst_if.data[0][128*3+68];
              end
          5 : begin
                c2h_ss0_sf[3] = G5;
                c2h_ss0_mndr[3] = c2h_mst_if.data[0][128*3]+c2h_mst_if.data[0][128*3+28];
              end
          6 : begin
                c2h_ss0_sf[3] = G6;
                c2h_ss0_mdrs[3] = c2h_mst_if.data[0][128*3]+c2h_mst_if.data[0][128*3+40]+c2h_mst_if.data[0][128*3+80];
              end
          default : c2h_ss0_sf[3] = NA;
        endcase
      end
      // Flit 1 
      c2h_ss1_sf   = '{NA,NA,NA,NA};
      c2h_ss1_mndr = '{0, 0, 0, 0};
      c2h_ss1_mdrs = '{0, 0, 0, 0};
      if (N > 1) begin
        if (c2h_mst_if.valid[1] && c2h_mst_if.adf[1])
          c2h_ss1_sf = '{ADF,ADF,ADF,ADF};
        else if (c2h_mst_if.valid[1] && !c2h_mst_if.data[1][0]) begin //protocol flit
          case (c2h_mst_if.data[1][5+:3])
            0 : begin
                  c2h_ss1_sf[0] = H0;
                  c2h_ss1_mndr[0] = c2h_mst_if.data[1][89];
                end
            1 : c2h_ss1_sf[0] = H1;
            2 : c2h_ss1_sf[0] = H2;
            3 : begin
                  c2h_ss1_sf[0] = H3;
                  c2h_ss1_mdrs[0] = c2h_mst_if.data[1][32];
                  c2h_ss1_mndr[0] = c2h_mst_if.data[1][72];
                end
            4 : begin
                  c2h_ss1_sf[0] = H4;
                  c2h_ss1_mndr[0] = c2h_mst_if.data[1][32]+c2h_mst_if.data[1][60];
                end
            5 : begin
                  c2h_ss1_sf[0] = H5;
                  c2h_ss1_mdrs[0] = c2h_mst_if.data[1][32]+c2h_mst_if.data[1][72];
                end
            default : c2h_ss1_sf[0] = NA;
          endcase
          case (c2h_mst_if.data[1][8+:3])
            0 : c2h_ss1_sf[1] = G0;
            1 : c2h_ss1_sf[1] = G1;
            2 : c2h_ss1_sf[1] = G2;
            3 : c2h_ss1_sf[1] = G3;
          4 : begin
                c2h_ss1_sf[1] = G4;
                c2h_ss1_mdrs[1] = c2h_mst_if.data[1][128*1];
                c2h_ss1_mndr[1] = c2h_mst_if.data[1][128*1+40]+c2h_mst_if.data[1][128*1+68];
              end
          5 : begin
                c2h_ss1_sf[1] = G5;
                c2h_ss1_mndr[1] = c2h_mst_if.data[1][128*1]+c2h_mst_if.data[1][128*1+28];
              end
          6 : begin
                c2h_ss1_sf[1] = G6;
                c2h_ss1_mdrs[1] = c2h_mst_if.data[1][128*1]+c2h_mst_if.data[1][128*1+40]+c2h_mst_if.data[1][128*1+80];
              end
            default : c2h_ss1_sf[1] = NA;
          endcase
          case (c2h_mst_if.data[1][11+:3])
            0 : c2h_ss1_sf[2] = G0;
            1 : c2h_ss1_sf[2] = G1;
            2 : c2h_ss1_sf[2] = G2;
            3 : c2h_ss1_sf[2] = G3;
            4 : begin
                  c2h_ss1_sf[2] = G4;
                  c2h_ss1_mdrs[2] = c2h_mst_if.data[1][128*2];
                  c2h_ss1_mndr[2] = c2h_mst_if.data[1][128*2+40]+c2h_mst_if.data[1][128*2+68];
                end
            5 : begin
                  c2h_ss1_sf[2] = G5;
                  c2h_ss1_mndr[2] = c2h_mst_if.data[1][128*2]+c2h_mst_if.data[1][128*2+28];
                end
            6 : begin
                  c2h_ss1_sf[2] = G6;
                  c2h_ss1_mdrs[2] = c2h_mst_if.data[1][128*2]+c2h_mst_if.data[1][128*2+40]+c2h_mst_if.data[1][128*2+80];
                end
            default : c2h_ss1_sf[2] = NA;
          endcase
          case (c2h_mst_if.data[1][14+:3])
            0 : c2h_ss1_sf[3] = G0;
            1 : c2h_ss1_sf[3] = G1;
            2 : c2h_ss1_sf[3] = G2;
            3 : c2h_ss1_sf[3] = G3;
            4 : begin
                  c2h_ss1_sf[3] = G4;
                  c2h_ss1_mdrs[3] = c2h_mst_if.data[1][128*3];
                  c2h_ss1_mndr[3] = c2h_mst_if.data[1][128*3+40]+c2h_mst_if.data[1][128*3+68];
                end
            5 : begin
                  c2h_ss1_sf[3] = G5;
                  c2h_ss1_mndr[3] = c2h_mst_if.data[1][128*3]+c2h_mst_if.data[1][128*3+28];
                end
            6 : begin
                  c2h_ss1_sf[3] = G6;
                  c2h_ss1_mdrs[3] = c2h_mst_if.data[1][128*3]+c2h_mst_if.data[1][128*3+40]+c2h_mst_if.data[1][128*3+80];
                end
            default : c2h_ss1_sf[3] = NA;
          endcase
        end
      end
      // Flit 2 
      c2h_ss2_sf   = '{NA,NA,NA,NA};
      c2h_ss2_mndr = '{0, 0, 0, 0};
      c2h_ss2_mdrs = '{0, 0, 0, 0};
      if (N > 2) begin
        if (c2h_mst_if.valid[2] && c2h_mst_if.adf[2])
          c2h_ss2_sf = '{ADF,ADF,ADF,ADF};
        else if (c2h_mst_if.valid[2] && !c2h_mst_if.data[2][0]) begin //protocol flit
          case (c2h_mst_if.data[2][5+:3])
            0 : begin
                  c2h_ss2_sf[0] = H0;
                  c2h_ss2_mndr[0] = c2h_mst_if.data[2][89];
                end
            1 : c2h_ss2_sf[0] = H1;
            2 : c2h_ss2_sf[0] = H2;
            3 : begin
                  c2h_ss2_sf[0] = H3;
                  c2h_ss2_mdrs[0] = c2h_mst_if.data[2][32];
                  c2h_ss2_mndr[0] = c2h_mst_if.data[2][72];
                end
            4 : begin
                  c2h_ss2_sf[0] = H4;
                  c2h_ss2_mndr[0] = c2h_mst_if.data[2][32]+c2h_mst_if.data[2][60];
                end
            5 : begin
                  c2h_ss2_sf[0] = H5;
                  c2h_ss2_mdrs[0] = c2h_mst_if.data[2][32]+c2h_mst_if.data[2][72];
                end
            default : c2h_ss2_sf[0] = NA;
          endcase
          case (c2h_mst_if.data[2][8+:3])
            0 : c2h_ss2_sf[1] = G0;
            1 : c2h_ss2_sf[1] = G1;
            2 : c2h_ss2_sf[1] = G2;
            3 : c2h_ss2_sf[1] = G3;
            4 : begin
                  c2h_ss2_sf[1] = G4;
                  c2h_ss2_mdrs[1] = c2h_mst_if.data[2][128*1];
                  c2h_ss2_mndr[1] = c2h_mst_if.data[2][128*1+40]+c2h_mst_if.data[2][128*1+68];
                end
            5 : begin
                  c2h_ss2_sf[1] = G5;
                  c2h_ss2_mndr[1] = c2h_mst_if.data[2][128*1]+c2h_mst_if.data[2][128*1+28];
                end
            6 : begin
                  c2h_ss2_sf[1] = G6;
                  c2h_ss2_mdrs[1] = c2h_mst_if.data[2][128*1]+c2h_mst_if.data[2][128*1+40]+c2h_mst_if.data[2][128*1+80];
                end
            default : c2h_ss2_sf[1] = NA;
          endcase
          case (c2h_mst_if.data[2][11+:3])
            0 : c2h_ss2_sf[2] = G0;
            1 : c2h_ss2_sf[2] = G1;
            2 : c2h_ss2_sf[2] = G2;
            3 : c2h_ss2_sf[2] = G3;
            4 : begin
                  c2h_ss2_sf[2] = G4;
                  c2h_ss2_mdrs[2] = c2h_mst_if.data[2][128*2];
                  c2h_ss2_mndr[2] = c2h_mst_if.data[2][128*2+40]+c2h_mst_if.data[2][128*2+68];
                end
            5 : begin
                  c2h_ss2_sf[2] = G5;
                  c2h_ss2_mndr[2] = c2h_mst_if.data[2][128*2]+c2h_mst_if.data[2][128*2+28];
                end
            6 : begin
                  c2h_ss2_sf[2] = G6;
                  c2h_ss2_mdrs[2] = c2h_mst_if.data[2][128*2]+c2h_mst_if.data[2][128*2+40]+c2h_mst_if.data[2][128*2+80];
                end
            default : c2h_ss2_sf[2] = NA;
          endcase
          case (c2h_mst_if.data[2][14+:3])
            0 : c2h_ss2_sf[3] = G0;
            1 : c2h_ss2_sf[3] = G1;
            2 : c2h_ss2_sf[3] = G2;
            3 : c2h_ss2_sf[3] = G3;
            4 : begin
                  c2h_ss2_sf[3] = G4;
                  c2h_ss2_mdrs[3] = c2h_mst_if.data[2][128*3];
                  c2h_ss2_mndr[3] = c2h_mst_if.data[2][128*3+40]+c2h_mst_if.data[2][128*3+68];
                end
            5 : begin
                  c2h_ss2_sf[3] = G5;
                  c2h_ss2_mndr[3] = c2h_mst_if.data[2][128*3]+c2h_mst_if.data[2][128*3+28];
                end
            6 : begin
                  c2h_ss2_sf[3] = G6;
                  c2h_ss2_mdrs[3] = c2h_mst_if.data[2][128*3]+c2h_mst_if.data[2][128*3+40]+c2h_mst_if.data[2][128*3+80];
                end
            default : c2h_ss2_sf[3] = NA;
          endcase
        end
      end
    end //if MODE==F68
    else if (MODE==F256) begin
      /* Slotset A */
      case (N)
        1 : c2h_rolli[0] = c2h_rollo[0];
        2 : c2h_rolli[0] = c2h_rollo[1];
        3 : c2h_rolli[0] = c2h_rollo[2];
      endcase
      if (c2h_mst_if.valid[0]) begin
        // Slot 0 (H-Slot)
        if (c2h_f256_ssptr[0] == 0) begin
          c2h_ss0_sf[0]   = get_hslot_fmt(c2h_mst_if.data[0][16+:4]);
          c2h_ss0_mndr[0] = get_slot_mndr(c2h_mst_if.data[0][127:16], 1); 
          c2h_ss0_mdrs[0] = get_slot_mdrs(c2h_mst_if.data[0][127:16], 1); 
          c2h_rollo[0]    = c2h_rolli[0] + get_hslot_rollout(c2h_mst_if.data[0][127:16]);
        end
        // Slot A
        else if (c2h_rolli[0]) begin
          c2h_ss0_sf[0] = DAT;
          c2h_rollo[0]  = c2h_rolli[0]-1;
        end
        else begin
          c2h_ss0_sf[0]   = get_gslot_fmt(c2h_mst_if.data[0][128*0+:4]);
          c2h_ss0_mndr[0] = get_slot_mndr(c2h_mst_if.data[0][0*128+:128]); 
          c2h_ss0_mdrs[0] = get_slot_mdrs(c2h_mst_if.data[0][0*128+:128]); 
          c2h_rollo[0]    = c2h_rolli[0] + get_gslot_rollout(c2h_mst_if.data[0][0*128+:128]);
        end
        // Slot B (G-Slot)
        if (c2h_rollo[0]) begin
          c2h_ss0_sf[1] = DAT;
          c2h_rollo[0]--;
        end
        else begin
          c2h_ss0_sf[1]   = get_gslot_fmt(c2h_mst_if.data[0][128*1+:4]);
          c2h_ss0_mndr[1] = get_slot_mndr(c2h_mst_if.data[0][1*128+:128]); 
          c2h_ss0_mdrs[1] = get_slot_mdrs(c2h_mst_if.data[0][1*128+:128]); 
          c2h_rollo[0]    = get_gslot_rollout(c2h_mst_if.data[0][1*128+:128]);
        end
        // Slot C (G-Slot)
        if (c2h_rollo[0]) begin
          c2h_ss0_sf[2] = DAT;
          c2h_rollo[0]--;
        end
        else begin
          c2h_ss0_sf[2]   = get_gslot_fmt(c2h_mst_if.data[0][128*2+:4]);
          c2h_ss0_mndr[2] = get_slot_mndr(c2h_mst_if.data[0][2*128+:128]); 
          c2h_ss0_mdrs[2] = get_slot_mdrs(c2h_mst_if.data[0][2*128+:128]); 
          c2h_rollo[0]    = get_gslot_rollout(c2h_mst_if.data[0][2*128+:128]);
        end
        // Slot 15 (PHY)
        if (c2h_f256_ssptr[0] == 3)
          c2h_ss0_sf[3] = PHY;
        // Slot D (G-Slot)
        else if (c2h_rollo[0]) begin
          c2h_ss0_sf[3] = DAT;
          c2h_rollo[0]--;
        end
        else begin
          c2h_ss0_sf[3]   = get_gslot_fmt(c2h_mst_if.data[0][128*3+:4]);
          c2h_ss0_mndr[3] = get_slot_mndr(c2h_mst_if.data[0][3*128+:128]); 
          c2h_ss0_mdrs[3] = get_slot_mdrs(c2h_mst_if.data[0][3*128+:128]); 
          c2h_rollo[0]    = get_gslot_rollout(c2h_mst_if.data[0][3*128+:128]);
        end
      end
      /* Slotset B */
      if (N>1 && c2h_mst_if.valid[1]) begin
        // Slot 0 (H-Slot)
        if (c2h_f256_ssptr[1] == 0) begin
          c2h_ss1_sf[0]   = get_hslot_fmt(c2h_mst_if.data[1][16+:4]);
          c2h_ss1_mndr[0] = get_slot_mndr(c2h_mst_if.data[1][127:16], 1);
          c2h_ss1_mdrs[0] = get_slot_mdrs(c2h_mst_if.data[1][127:16], 1);
          c2h_rollo[1]    = c2h_rolli[1] + get_hslot_rollout(c2h_mst_if.data[1][127:16]);
        end
        // Slot A
        else if (c2h_rollo[1]) begin
          c2h_ss1_sf[0] = DAT;
          c2h_rollo[1]--;
        end
        else begin
          c2h_ss1_sf[0]   = get_gslot_fmt(c2h_mst_if.data[1][128*0+:4]);
          c2h_ss1_mndr[0] = get_slot_mndr(c2h_mst_if.data[1][1*128+:128]); 
          c2h_ss1_mdrs[0] = get_slot_mdrs(c2h_mst_if.data[1][1*128+:128]); 
          c2h_rollo[1]    = get_gslot_rollout(c2h_mst_if.data[1][0*128+:128]);
        end
        // Slot B (G-Slot)
        if (c2h_rollo[1]) begin
          c2h_ss1_sf[1] = DAT;
          c2h_rollo[1]--;
        end
        else begin
          c2h_ss1_sf[1]   = get_gslot_fmt(c2h_mst_if.data[1][128*1+:4]);
          c2h_ss1_mndr[1] = get_slot_mndr(c2h_mst_if.data[1][1*128+:128]); 
          c2h_ss1_mdrs[1] = get_slot_mdrs(c2h_mst_if.data[1][1*128+:128]); 
          c2h_rollo[1]    = get_gslot_rollout(c2h_mst_if.data[1][1*128+:128]);
        end
        // Slot C (G-Slot)
        if (c2h_rollo[1]) begin
          c2h_ss1_sf[2] = DAT;
          c2h_rollo[1]--;
        end
        else begin
          c2h_ss1_sf[2]   = get_gslot_fmt(c2h_mst_if.data[1][128*2+:4]);
          c2h_ss1_mndr[2] = get_slot_mndr(c2h_mst_if.data[1][2*128+:128]); 
          c2h_ss1_mdrs[2] = get_slot_mdrs(c2h_mst_if.data[1][2*128+:128]); 
          c2h_rollo[1]    = get_gslot_rollout(c2h_mst_if.data[1][2*128+:128]);
        end
        // Slot 15 (PHY)
        if (c2h_f256_ssptr[1] == 3)
          c2h_ss1_sf[3] = PHY;
        // Slot D (G-Slot)
        else if (c2h_rollo[1]) begin
          c2h_ss1_sf[3] = DAT;
          c2h_rollo[1]--;
        end
        else begin
          c2h_ss1_sf[3]   = get_gslot_fmt(c2h_mst_if.data[1][128*3+:4]);
          c2h_ss1_mndr[3] = get_slot_mndr(c2h_mst_if.data[1][3*128+:128]); 
          c2h_ss1_mdrs[3] = get_slot_mdrs(c2h_mst_if.data[1][3*128+:128]); 
          c2h_rollo[1]    = get_gslot_rollout(c2h_mst_if.data[1][3*128+:128]);
        end
      end
      /* Slotset C */
      if (N>2 && c2h_mst_if.valid[2]) begin
        // Slot 0 (H-Slot)
        if (c2h_f256_ssptr[2] == 0) begin
          c2h_ss2_sf[0]   = get_hslot_fmt(c2h_mst_if.data[2][16+:4]);
          c2h_ss2_mndr[0] = get_slot_mndr(c2h_mst_if.data[2][127:16], 1);
          c2h_ss2_mdrs[0] = get_slot_mdrs(c2h_mst_if.data[2][127:16], 1);
          c2h_rollo[2]    = c2h_rolli[2] + get_hslot_rollout(c2h_mst_if.data[2][127:16]);
        end
        // Slot A
        else if (c2h_rollo[2]) begin
          c2h_ss2_sf[0] = DAT;
          c2h_rollo[2]--;
        end
        else begin
          c2h_ss2_sf[0]   = get_gslot_fmt(c2h_mst_if.data[2][128*0+:4]);
          c2h_ss2_mndr[0] = get_slot_mndr(c2h_mst_if.data[2][0*128+:128]);
          c2h_ss2_mdrs[0] = get_slot_mdrs(c2h_mst_if.data[2][0*128+:128]);
          c2h_rollo[2]    = get_gslot_rollout(c2h_mst_if.data[2][0*128+:128]);
        end
        // Slot B (G-Slot)
        if (c2h_rollo[2]) begin
          c2h_ss2_sf[1] = DAT;
          c2h_rollo[2]--;
        end
        else begin
          c2h_ss2_sf[1]   = get_gslot_fmt(c2h_mst_if.data[2][128*1+:4]);
          c2h_ss2_mndr[1] = get_slot_mndr(c2h_mst_if.data[2][1*128+:128]);
          c2h_ss2_mdrs[1] = get_slot_mdrs(c2h_mst_if.data[2][1*128+:128]);
          c2h_rollo[2]    = get_gslot_rollout(c2h_mst_if.data[2][1*128+:128]);
        end
        // Slot C (G-Slot)
        if (c2h_rollo[2]) begin
          c2h_ss2_sf[2] = DAT;
          c2h_rollo[2]--;
        end
        else begin
          c2h_ss2_sf[2]   = get_gslot_fmt(c2h_mst_if.data[2][128*2+:4]);
          c2h_ss2_mndr[2] = get_slot_mndr(c2h_mst_if.data[2][2*128+:128]);
          c2h_ss2_mdrs[2] = get_slot_mdrs(c2h_mst_if.data[2][2*128+:128]);
          c2h_rollo[2]    = get_gslot_rollout(c2h_mst_if.data[2][2*128+:128]);
        end
        // Slot 15 (PHY)
        if (c2h_f256_ssptr[2] == 3)
          c2h_ss2_sf[3] = PHY;
        // Slot D (G-Slot)
        else if (c2h_rollo[2]) begin
          c2h_ss2_sf[3] = DAT;
          c2h_rollo[2]--;
        end
        else begin
          c2h_ss2_sf[3]   = get_gslot_fmt(c2h_mst_if.data[2][128*3+:4]);
          c2h_ss2_mndr[3] = get_slot_mndr(c2h_mst_if.data[2][3*128+:128]);
          c2h_ss2_mdrs[3] = get_slot_mdrs(c2h_mst_if.data[2][3*128+:128]);
          c2h_rollo[2]    = get_gslot_rollout(c2h_mst_if.data[2][3*128+:128]);
        end
      end
    end //if MODE==F256
  end

  assign h2c_mst_if.clk = clock; assign h2c_slv_if.clk = clock;
  assign c2h_mst_if.clk = clock; assign c2h_slv_if.clk = clock;

  assign h2c_slv_if.data    = h2c_mst_if.data;
  assign h2c_slv_if.parity  = h2c_mst_if.parity;
  assign h2c_slv_if.viral   = h2c_mst_if.viral;
  assign h2c_slv_if.valid   = h2c_mst_if.valid;
  assign h2c_slv_if.adf     = h2c_mst_if.adf;
  assign h2c_mst_if.ready   = h2c_slv_if.ready;
  // decode assists not used by slave agent; can view in waves by looking at mst agent
  assign {h2c_slv_if.dec_sop, h2c_slv_if.dec_eop, h2c_slv_if.dec_be, h2c_slv_if.dec_mem} = '0;

  assign c2h_slv_if.data    = c2h_mst_if.data;
  assign c2h_slv_if.parity  = c2h_mst_if.parity;
  assign c2h_slv_if.viral   = c2h_mst_if.viral;
  assign c2h_slv_if.valid   = c2h_mst_if.valid;
  assign c2h_slv_if.adf     = c2h_mst_if.adf;
  assign c2h_mst_if.ready   = c2h_slv_if.ready;
  // decode assists not used by slave agent; can view in waves
  assign {c2h_slv_if.dec_sop, c2h_slv_if.dec_eop, c2h_slv_if.dec_be, c2h_slv_if.dec_mem} = '0;

  initial run_test("");

  initial begin
    uvm_config_db#(virtual cxl_nfi_agent_if #(N))::set(null, "*", "v_h2c_mst_if", h2c_mst_if);
    uvm_config_db#(virtual cxl_nfi_agent_if #(N))::set(null, "*", "v_h2c_slv_if", h2c_slv_if);
    uvm_config_db#(virtual cxl_nfi_agent_if #(N))::set(null, "*", "v_c2h_mst_if", c2h_mst_if);
    uvm_config_db#(virtual cxl_nfi_agent_if #(N))::set(null, "*", "v_c2h_slv_if", c2h_slv_if);
  end

endmodule
