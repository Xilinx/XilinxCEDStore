// Prefetch configuration types required by the vendored tag-allocator module.
//
// Sourced from the QDMA v5.1 reference register header. Only the four prefetch
// configuration structures are carried across; the remaining types that module
// references already exist in this IP's MDMA defines header.
//
// The fence field in the second structure is the credit fence from the prefetch
// module to the fetch engine. It is the ordering control the descriptor path
// currently lacks, and is the reason this header is needed rather than a
// parameter.

// The four configuration structures keep the reference layouts but carry this
// IP's own names. This header is included at compilation-unit scope, and the
// mailbox sub-core declares the reference names there too, so reusing them
// collides when both are synthesized together.

`ifndef __CPM6_QDMA_PFCH_TYPES__SVH__
`define __CPM6_QDMA_PFCH_TYPES__SVH__

   typedef struct packed {
      // Start eviction when free-list count is at or below this threshold.
      logic [15:0]  evt_pfch_fl_th;
      // Allow prefetch when free-list count is at or above this threshold.
      logic [15:0]  pfch_fl_th;
   } cpm6_qdma_pfch_cfg_t;

   typedef struct packed {
      // Start eviction at or above this active-queue count; must stay below pfch_qcnt.
      logic [15:0]  evt_qcnt_th;
      // Maximum active prefetch queue count.
      logic [15:0]  pfch_qcnt;
   } cpm6_qdma_pfch_cfg_1_t;

   typedef struct packed {
      // Credit fence from the prefetch module to the fetch engine.
      logic                       fence;
      logic [30-17-$bits(mdma_c2h_alloc_max_desc_t)-$bits(mdma_c2h_alloc_max_desc_t):0] rsvd;
      logic                       var_desc_no_drop;
      logic [15:0]                pfch_ll_sz_th;
      mdma_c2h_alloc_max_desc_t   var_desc_num_pfch;
      mdma_c2h_alloc_max_desc_t   num_pfch;
   } cpm6_qdma_pfch_cfg_2_t;

   typedef struct packed {
      logic [14:0]  glb_evt_timer_tick;
      logic         disable_glb_evt_timer;
      logic [14:0]  evt_timer_tick;
      logic         disable_evt_timer;
   } cpm6_qdma_pfch_cfg_4_t;


   // Prefetch cache entry.
   //
   // Mirrors the reference implementation's cache-entry layout. The descriptor itself is
   // 64 bits: a C2H stream descriptor carries a host address and nothing else, in every
   // mode. The transfer length travels BESIDE it in this entry rather than inside it,
   // filled from the queue's buffer size when the descriptor is cached. That is what lets
   // the descriptor format stay identical to a conventional QDMA descriptor while the
   // converter downstream still receives a length.
   //
   // Two fields from the reference layout are deliberately omitted: a process address
   // space identifier and an available-index, neither of which has a consumer here.
   //
   // The two chain fields are retained although nothing drives them yet. They belong to
   // the variable-descriptor feature, where a descriptor carries its own length instead of
   // taking a fixed per-queue buffer size, so the engine must accumulate bytes rather than
   // count descriptors and links the descriptors covering one packet. Fixed-size buffers
   // are what is implemented here, so the feature is dormant — the fields are kept so the
   // entry layout stays comparable with the reference rather than diverging for the sake
   // of four unused bits.
   typedef struct packed {
      mdma_desc_cnt_t            cnt;
      mdma_c2h_desc_err_type_e   err_type;
      logic [15:0]               desc_chain_idx;
      logic [2:0]                desc_chain_flag;
      logic                      err;
      logic [1:0]                at;
      mdma_fnid_t                fnc;
      mdma_dma_buf_len_t         len;
      logic [63:0]               dsc;
   } cpm6_qdma_pfch_entry_t;

   localparam int PFCH_ENTRY_BITS = $bits(cpm6_qdma_pfch_entry_t);


   // Per-queue prefetch context, as carried on the direct context-access response.
   //
   // Laid out in the style of the hardware and software context structures this IP
   // already defines, so the three read alike at the access point. Ordered with the
   // hardware-owned bits at the top, because those are the only two written back:
   // the rest is software's to set and this engine's to obey.
   //
   // The error pair is what makes the write path worth having. Both bits live in a
   // prefetch tag, and a tag is reclaimed when its queue goes idle — which is
   // precisely what a queue that has stopped on an error does. Without a round
   // trip through this structure the queue is re-tagged looking healthy and retries
   // the fetch that failed.
   // The bypass bit here is the CACHE bypass, and is not the descriptor-bypass bit
   // of the software context. The two are distinct and together select the stream
   // mode: descriptor bypass decides whether descriptors are routed out to the
   // user, cache bypass decides whether this engine prefetches for the queue at
   // all. Only the second is this engine's concern — a queue whose descriptors go
   // to the user is still prefetched for unless cache bypass is also set — so this
   // is the only one of the pair carried here, and the engine never sees the other.
   typedef struct packed {
      logic         err;          // a descriptor fetch for this queue returned an error
      logic         stop;         // queue withheld from prefetch until software clears it
      logic         valid;
      logic         pfch_en;
      logic         bypass;       // cache bypass: this engine does not fetch for the queue
      logic [3:0]   pfch_need;    // descriptors to keep ahead of the consumer index
      logic [1:0]   q_prio;
      logic [6:0]   _r0;
   } cpm6_qdma_pfch_ctxt_t;

   localparam int PFCH_CTXT_BITS = $bits(cpm6_qdma_pfch_ctxt_t);

`endif
