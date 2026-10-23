// This package creates enums for the CXL Mailbox command
// submission and command return values for easier understanding
package cxl_mbox_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  // Upper Byte = Command Set
  typedef enum bit [15:8] { 
    // Generic CXL Component
    INFOSTS   = 8'h0,
    EVENTS    = 8'h1,
    FWUPDATE  = 8'h2,
    TIMESTAMP = 8'h3,
    LOGS      = 8'h4,
    FEATURES  = 8'h5,
    MAINT     = 8'h6,
    PBRCOMP   = 8'h7,
    // CXL Memory Device
    IDMEMDEV          = 8'h40,
    SZCFGANDLABEL     = 8'h41,
    HEALTH            = 8'h42,
    MEDIAANDPOISMGMT  = 8'h43,
    SANITZANDMEDIAOPS = 8'h44,
    PMEMDATARESTSEC   = 8'h45,
    SECURITYPASSTHRU  = 8'h46,
    SLDQOSTELEM       = 8'h47,
    DYNAMICCAPACITY   = 8'h48,
    GFDCOMPMGMT       = 8'h49
  } cxl_comp_mbox_cmd_set_e; 

  // Full Command = {Commmand Set, Sub-cmd}
  typedef enum bit [15:0] {
    // ---------------------------------------------
    // GENERIC CXL COMPONENT COMMANDS: 0x0000-0x3FFF
    // ---------------------------------------------
    INFOSTS_Identify = 16'h0001,
    INFOSTS_BckgrndOpSts       ,
    INFOSTS_GetRspMsgLim       ,
    INFOSTS_SetRspMsgLim       ,
    INFOSTS_ReqAbortBckgrndOp  ,
    // -- //
    EVENTS_GetEventRecs  = 16'h0100,
    EVENTS_ClrEventRecs            ,
    EVENTS_GetEventIrqPol          ,
    EVENTS_SetEventIrqPol          ,
    EVENTS_GetMCTPEventPol         ,
    EVENTS_SetMCTPEventPol         ,
    EVENTS_EventNotify             ,
    EVENTS_GFDEnhncEventNotify     ,
    EVENTS_GFDtoGAEEnhncEventNotify,
    EVENTS_GetGAMBuffer            ,
    EVENTS_SetGAMBuffer            ,
    // -- //
    FWUPDATE_GetFWInfo = 16'h0200,
    FWUPDATE_TxferFW             ,
    FWUPDATE_ActivateFW          ,
    // -- //
    TIMESTAMP_GetTimestamp = 16'h0300,
    TIMESTAMP_SetTimestamp           ,
    // -- //
    LOGS_GetSuppLogs = 16'h0400,
    LOGS_GetLog                ,
    LOGS_GetLogCaps            ,
    LOGS_ClrLog                ,
    LOGS_PopulateLog           ,
    LOGS_GetSuppLogsSublist    ,
    // -- //
    FEATURES_GetSuppFeatures = 16'h0500,
    FEATURES_GetFeature                ,
    FEATURES_SetFeature                ,
    // -- //
    MAINT_PerformMaint = 16'h0600,
    // -- //
    PBRCOMP_IdentifyPBRComp = 16'h0700,
    PBRCOMP_ClaimOwnership            ,
    PBRCOMP_ReadCDAT                  ,
    // ---------------------------------------------
    // TYPE SPECIFIC COMMANDS : 0x4000-0xBFFF
    //  -> CXL MEMORY DEVIVCE COMMAND SET 
    // ---------------------------------------------
    IDMEMDEV_Identify = 16'h4000,
    // -- //
    SZCFGANDLABEL_GetPartInfo = 16'h4100,
    SZCFGANDLABEL_SetPartInfo = 16'h4101,
    SZCFGANDLABEL_GetLSA      = 16'h4102,
    SZCFGANDLABEL_SetLSA      = 16'h4103,
    // -- //
    HEALTH_GetInfo       = 16'h4200,
    HEALTH_GetAlertCfg   = 16'h4201,
    HEALTH_SetAlertCfg   = 16'h4202,
    HEALTH_GetShutdownSt = 16'h4203,
    HEALTH_SetShutdownSt = 16'h4204,
    // -- //
    MEDIAANDPOISMGMT_GetList        = 16'h4300,
    MEDIAANDPOISMGMT_InjPois        = 16'h4301,
    MEDIAANDPOISMGMT_ClrPois        = 16'h4302,
    MEDIAANDPOISMGMT_GetScanCaps    = 16'h4303,
    MEDIAANDPOISMGMT_ScanMedia      = 16'h4304,
    MEDIAANDPOISMGMT_GetScanResults = 16'h4305,
    // -- //
    SANITZANDMEDIAOPS_Sani     = 16'h4400,
    SANITZANDMEDIAOPS_SecErase = 16'h4401,
    SANITZANDMEDIAOPS_MediaOps = 16'h4402,
    // -- //
    PMEMDATARESTSEC_GetSecSt        = 16'h4500,
    PMEMDATARESTSEC_SetPassphr      = 16'h4501,
    PMEMDATARESTSEC_DisPassphr      = 16'h4502,
    PMEMDATARESTSEC_Unlock          = 16'h4503,
    PMEMDATARESTSEC_FrzSecSt        = 16'h4504,
    PMEMDATARESTSEC_PassphrSecErase = 16'h4505,
    // -- //
    SECURITYPASSTHRU_Snd = 16'h4600,
    SECURITYPASSTHRU_Rcv = 16'h4601,
    // -- //
    SLDQOSTELEM_GetQoSCtrl = 16'h4700,
    SLDQOSTELEM_SetQoSCtrl = 16'h4701,
    SLDQOSTELEM_GetQoSSts  = 16'h4702,
    // -- //
    DYNAMICCAPACITY_GetCfg     = 16'h4800,
    DYNAMICCAPACITY_GetExtList = 16'h4801,
    DYNAMICCAPACITY_AddRsp     = 16'h4802,
    DYNAMICCAPACITY_Release    = 16'h4803,
    // -- //
    GFDCOMPMGMT_Identify           = 16'h4900,
    GFDCOMPMGMT_GetSts             = 16'h4901,
    GFDCOMPMGMT_GetDCRegionCfg     = 16'h4902,
    GFDCOMPMGMT_SetDCRegionCfg     = 16'h4903,
    GFDCOMPMGMT_GetDCregionExtList = 16'h4904,
    GFDCOMPMGMT_GetDMPCfg          = 16'h4905,
    GFDCOMPMGMT_SetDMPCfg          = 16'h4906,
    GFDCOMPMGMT_DynCapAdd          = 16'h4907,
    GFDCOMPMGMT_DynCapRls          = 16'h4908,
    GFDCOMPMGMT_DynCapAddRef       = 16'h4909,
    GFDCOMPMGMT_DynCapDelRef       = 16'h490A,
    GFDCOMPMGMT_DynCapListTags     = 16'h490B,
    GFDCOMPMGMT_GetSATEntry        = 16'h490C,
    GFDCOMPMGMT_SetSATEntry        = 16'h490D,
    GFDCOMPMGMT_GetQoSCtl          = 16'h490E,
    GFDCOMPMGMT_SetQoSCtl          = 16'h490F,
    GFDCOMPMGMT_GetQoSSts          = 16'h4910,
    GFDCOMPMGMT_GetQoSBWLim        = 16'h4911,
    GFDCOMPMGMT_SetQoSBWLim        = 16'h4912,
    GFDCOMPMGMT_GetGDTCfg          = 16'h4913,
    GFDCOMPMGMT_SetGDTCfg          = 16'h4914,
    // ---------------------------------------------
    // N/A; used as a catch all
    // VENDOR SPECIFIC COMMANDS : 0xC000-0xFFFF
    // ---------------------------------------------
    No_Command = 16'hFFFF
  } cxl_comp_mbox_cmd_opcode_e;

  typedef enum bit [15:0] {
    Success,           BckgrdCmdStarted,    InvalidInput,      Unsupported,
    InternalError,     RetryReqd,           Busy,              MediaDisabled,
    FWTxferInProg,     FWTxferOOO,          FWVerifFail,       InvalidSlot,
    ActFail_FWRoll,    ActFail_ColdRstReq,  InvalidHandle,     InvalidPhysAddr,
    InjectPoisonLimit, PermMediaFail,       Aborted,           InvalidSecuritySt,
    IncorrectPassphrs, UnsuppMboxCCI,       InvalidPayloadLen, InvalidLog,
    Interrupted,       UnsuppFeatVers,      UnsuppFeatSelVal,  FeatTxferInProg, 
    FeatTxferOOO,      ResourceExhaust,     InvalidExtentList, TxferOOO,       
    ReqAbortNoBackOp,
    // N/A
    NoRetCode
  } cxl_comp_mbox_cmd_retcode_e;

  typedef enum bit [1:0] {
    PROHIBIT, OPTIONAL, SUPPORTED
  } cxl_comp_cmd_supp_e;

  // A command is fully described by an opcode, an input and/or output 
  // payload, and a return code; payload_len used for ipayload
  typedef struct {
    cxl_comp_mbox_cmd_opcode_e  opcode;
    bit [20:0]                  payload_len;
    bit [ 7:0]                  ipayload[];
    bit [ 7:0]                  opayload[];
    cxl_comp_mbox_cmd_retcode_e retcode = NoRetCode;
  } cxl_comp_mbox_cmd_s; 

  // Intended to be used with an unpacked array (queue, dynamic array, 
  // associative array) for easy lookups e.g. a key:value pair with the 
  // key=cxl_comp_mbox_cmd_opcode_e (opcode)
  typedef struct {
    int                         exp_ipayload; //size in bytes; negative=variable->min=abs(val)
    bit [ 7:0]                  ipayload[];
    int                         exp_opayload; //size bytes; negative=variable->min=abs(val)
    bit [ 7:0]                  opayload[];
    cxl_comp_mbox_cmd_retcode_e valid_retcodes[];
    cxl_comp_mbox_cmd_retcode_e retcode = NoRetCode;
    cxl_comp_cmd_supp_e         presence;
  } cxl_comp_mbox_cmd_value_s; 

  // Intended to be used as a complete store of everything for a command
  typedef struct {
    cxl_comp_mbox_cmd_opcode_e  opcode;
    bit [20:0]                  payload_len;
    int                         exp_ipayload; //size in bytes; negative=variable->min=abs(val)
    bit [ 7:0]                  ipayload[];
    int                         exp_opayload; //size in bytes; negative=variable->min=abs(val)
    bit [ 7:0]                  opayload[];
    cxl_comp_mbox_cmd_retcode_e valid_retcodes[];
    cxl_comp_mbox_cmd_retcode_e retcode = NoRetCode;
  } cxl_comp_mbox_cmd_full_s; 

  // Lookup table for logs
  typedef enum bit [127:0] {
    CEL       = 'h173f3b62b196_798f_784b_41bf_b5c0a90d, //Command Effects Log
    VDL       = 'h863d401907d6_1f81_0c40_a911_d919185e, //Vendor Debug Log
    CSDL      = 'h6735f262995e_3e94_3243_b601_cfb4fab3, //Component State Dump Log
    DDR5_ECSL = 'h7c079e8f9411_03a0_0643_a9a7_600d72f1, //DDR5 Error Check Scrub (ECS) Log
    MEDIA_CL  = 'ha431f7bbbe99_a88c_5c4a_3ed1_2ca3dfe6, //Media Test Capability Log
    MEDIA_RSL = 'h020012ac4202_09b9_ec11_e48c_2255252c, //Media Test Results Short Log
    MEDIA_RLL = 'h7a58febbaaa6_4ea2_8e44_007a_3e0bfec1  //Media Test Results Long Log
  } log_uuid_e;

  typedef struct packed {
    bit [15:12] rsvd;
    bit         cfg_chng_cxl_rest;
    bit         cfg_chng_conv_rest;
    bit         cel_11_10_vld;
    bit         req_abort_bckgrnd_op_supp;
    bit         sec_mbox_supp;
    bit         bckgrnd_op;
    bit         sec_st_chng;
    bit         imm_log_chng;
    bit         imm_policy_chng;
    bit         imm_data_chng;
    bit         imm_cfg_chng;
    bit         cfg_chng_cold_reset;
  } cel_cmd_effect_s;

  // Command Effects Log Entry
  typedef struct packed {
    // 31:16
    cel_cmd_effect_s           cmd_effect;
    // 15:0
    cxl_comp_mbox_cmd_opcode_e opcode;
  } cel_entry_s;

endpackage
