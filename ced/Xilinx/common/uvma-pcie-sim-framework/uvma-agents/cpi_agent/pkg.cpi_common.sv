package cpi_common_pkg;

  // For req/data/rsp agent
  typedef enum bit {CACHE, MEM} api_msg_t;
  typedef enum bit {USP, DSP}   port_t;
  typedef enum     {ASAP, CUSTOM, LO, MED, HI} generic_ctl_t;

  // For global agent
  typedef enum {DISCONNECTED, CONNECTING, CONNECTED, 
                DISCONNECTING, DENY, ILLEGAL} conn_state_t;
  typedef enum {CONNECT, DISCONNECT} conn_action_t;

endpackage


