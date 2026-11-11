// AXI-Lite context register package.
// Defines the 5-word context payload exported by axil_slave via regs_out.
//
// Logical context fields:
//   reg0 - size
//   reg1 - src_lo
//   reg2 - src_hi
//   reg3 - dst_lo
//   reg4 - dst_hi
//
// Notes:
// - The physical AXI-Lite banks/offsets are decoded in axil_slave.
// - write_req generation and transfer direction (is_c2h) are controlled
//   by axil_slave from the triggered bank, not from reg0[31].

package axil_slave_pkg;

    typedef struct packed {
        logic [31:0] reg4;   // [159:128] dst_hi (trigger)
        logic [31:0] reg3;   // [127: 96] dst_lo
        logic [31:0] reg2;   // [ 95: 64] src_hi
        logic [31:0] reg1;   // [ 63: 32] src_lo
        logic [31:0] reg0;   // [ 31:  0] size
    } axil_regs_t;

    // ------------------------------------------------------------------
    // PF/VF <-> DMA channel mapping functions.
    // NUM_PFS and NUM_VFS_PER_PF are module parameters on pl_example and
    // axil_slave. To resize the design edit the pl_example instantiation
    // in hdma_ddr_top.sv:
    //   .NUM_PFS(8)         — number of Physical Functions
    //   .NUM_VFS_PER_PF(7)  — VFs per PF (PF-relative index 0..N-1)
    //
    // Channel encoding: channel = vf_slot * NUM_PFS + pf_num
    //   pf_num  occupies channel[pf_w-1:0]
    //   vf_slot occupies channel[pf_w+vf_slot_w-1:pf_w]  (0=PF, 1..N=VF0..VFn-1)
    //
    // CPM6 AXI sideband vfunc_num is PF-RELATIVE (0..NUM_VFS_PER_PF-1).
    // pcie_msix_vfunc_num also uses the PF-relative convention.
    // ------------------------------------------------------------------

    // Forward: PF/VF sideband -> local channel
    // pf_w = $clog2(NUM_PFS),  vf_slot_w = $clog2(NUM_VFS_PER_PF + 1)
    function automatic logic [6:0] pf_vf_to_channel
        (input logic [2:0] pf_num, input logic [7:0] vfunc_num, input logic vfunc_active,
         input int pf_w, input int vf_slot_w);
        automatic int vf_slot;
        vf_slot = vfunc_active ? int'(vfunc_num) % (1 << vf_slot_w) + 1 : 0;
        pf_vf_to_channel = 7'((vf_slot << pf_w) | (int'(pf_num) % (1 << pf_w)));
    endfunction

    // Reverse: local channel -> PF number
    function automatic logic [2:0] channel_to_pf(input logic [6:0] chn, input int pf_w);
        channel_to_pf = 3'(int'(chn) % (1 << pf_w));
    endfunction

    // Reverse: local channel -> vfunc_active (1 if VF, 0 if PF)
    function automatic logic channel_to_vfunc_active(input logic [6:0] chn, input int pf_w, input int vf_slot_w);
        channel_to_vfunc_active = (int'(chn) >> pf_w) % (1 << vf_slot_w) != 0;
    endfunction

    // Reverse: local channel -> PF-relative vfunc_num (0..NUM_VFS_PER_PF-1)
    function automatic logic [7:0] channel_to_vfunc_num(input logic [6:0] chn, input int pf_w, input int vf_slot_w);
        automatic int slot;
        slot = (int'(chn) >> pf_w) % (1 << vf_slot_w);
        channel_to_vfunc_num = (slot != 0) ? 8'(slot - 1) : 8'h0;
    endfunction

    // ------------------------------------------------------------------
    // Function <-> DMA-channel ASSIGNMENT MAP
    //
    // Two small lookup tables decouple "which function" from "which hardware DMA channel":
    //   FUNC_TO_CHN : function index -> the channel that function's BAR1 register bank drives
    //   CHN_TO_FUNC : channel        -> the function that owns it (gets its MSI-X, status)
    // Function index fi = vf_slot * NUM_PFS + pf_num (PF n -> n; VF v of PF n -> (v+1)*NUM_PFS + n)
    // -- the same number the original hard-wired formula used as the channel, so with the default
    // identity tables (fi <-> channel) behavior is exactly as before. A channel may be owned by
    // only one function, but several channels may map to the SAME function in CHN_TO_FUNC (future
    // many-channels-per-function use); FUNC_TO_CHN then names that function's primary channel.
    // The tables are edited at the top of pl_example.sv and passed down as parameters.
    // The driver must program each CPM6 HDMA channel's FUNC_NUM register to match CHN_TO_FUNC.
    // 64 entries x 7 bits (CPM6 has 64 channels per direction).
    // ------------------------------------------------------------------
    typedef logic [64*7-1:0] chn_map_t;

    // idx >= 64 (only reachable with out-of-range sideband VF numbers) passes through unchanged, which
    // keeps the original formula's behavior for those inputs exactly.
    function automatic logic [6:0] map_get(input chn_map_t m, input int idx);
        map_get = (idx < 64) ? m[idx*7 +: 7] : 7'(idx);
    endfunction

    function automatic chn_map_t identity_map();
        chn_map_t m;
        m = '0;
        for (int i = 0; i < 64; i++) m[i*7 +: 7] = 7'(i);
        identity_map = m;
    endfunction

    // PF/VF sideband -> function index (canonical function id)
    function automatic logic [6:0] func_index
        (input logic [2:0] pf_num, input logic [7:0] vfunc_num, input logic vfunc_active,
         input int pf_w, input int vf_slot_w);
        func_index = pf_vf_to_channel(pf_num, vfunc_num, vfunc_active, pf_w, vf_slot_w);
    endfunction

    function automatic logic [6:0] func_to_chn(input logic [6:0] fi, input chn_map_t m);
        func_to_chn = map_get(m, int'(fi));
    endfunction

    function automatic logic [6:0] chn_to_func(input logic [6:0] ch, input chn_map_t m);
        chn_to_func = map_get(m, int'(ch));
    endfunction

    // Direction + local channel <-> global channel index (dma_irq[127:0] layout)
    // Works for any NUM_CHN <= 64 (local channel always fits in 6 bits).
    function automatic logic [6:0] glb_chn_calc(input logic is_c2h, input logic [6:0] chn);
        glb_chn_calc = {~is_c2h, chn[5:0]};
    endfunction

    function automatic logic glb_chn_is_c2h(input logic [6:0] glb_chn);
        glb_chn_is_c2h = ~glb_chn[6];
    endfunction

    function automatic logic [6:0] glb_chn_local(input logic [6:0] glb_chn);
        glb_chn_local = {1'b0, glb_chn[5:0]};
    endfunction

endpackage
