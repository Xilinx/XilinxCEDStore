class cseq_cxl_mbox extends cseq_cpm6_pcie_core_mbox;

  `uvm_object_utils(cseq_cxl_mbox)

  // CXL Mailbox (Primary or Secondary) info for decoding
  int        cxl_mbox_pf;
  int        cxl_mbox_bar;
  bit [31:0] cxl_mbox_base_addr;

  event doorbell_set;
  event doorbell_clr;

  // snapshot the latest command 
  cxl_comp_mbox_cmd_s cmd;

  // An assoc. array of classes that handle commands; user must build it
  // by calling add_cmd_obj
  cxl_comp_cmd_obj cmd_obj[cxl_comp_mbox_cmd_opcode_e];

  // RC* = "return code <# options> <iteration>"
  // - 3
  `define RC3a  Success, InternalError, RetryReqd
  `define RC3b  Success, InternalError, Unsupported
  `define RC3c  Success, InternalError, InvalidInput
  // - 4
  `define RC4a  Success, InternalError, RetryReqd,   InvalidPayloadLen
  `define RC4b  Success, InternalError, RetryReqd,   InvalidInput
  `define RC4c  Success, InternalError, RetryReqd,   Unsupported
  `define RC4d  Success, InternalError, Unsupported, ReqAbortNoBackOp
  // - 5
  `define RC5a  Success, InternalError, RetryReqd,   InvalidPayloadLen, Unsupported
  `define RC5b  Success, InternalError, RetryReqd,   InvalidPayloadLen, InvalidInput
  `define RC5c  Success, InternalError, Unsupported, InvalidInput,      InvalidLog
  // - 6
  `define RC6a  Success, InternalError, RetryReqd,   InvalidPayloadLen, InvalidInput, \
                Unsupported
  `define RC6b  Success, InternalError, RetryReqd,   InvalidPayloadLen, MediaDisabled, \
                Unsupported
  // - 7
  `define RC7a  Success,      InternalError, RetryReqd, InvalidPayloadLen, \
                InvalidInput, MediaDisabled, Busy
  `define RC7b  Success,      InternalError, RetryReqd, InvalidPayloadLen, \
                InvalidInput, Unsupported,   UnsuppFeatSelVal
  // - 8
  `define RC8a  Success, InternalError, RetryReqd,     InvalidPayloadLen, \
                Busy,    InvalidInput,  InvalidLog,    MediaDisabled
  `define RC8b  Success, InternalError, RetryReqd,     InvalidPayloadLen, \
                Busy,    InvalidInput,  MediaDisabled, InvalidHandle
  // - 9
  `define RC9   Success, InternalError, Unsupported,  InvalidLog, BckgrdCmdStarted, \
                Aborted, Interrupted,   InvalidInput, Busy
  // - 13
  `define RC13a Success, InternalError,    RetryReqd,   InvalidPayloadLen, InvalidSecuritySt, \
                Aborted, Unsupported,      InvalidSlot, ActFail_FWRoll,    ActFail_ColdRstReq, \
                Busy,    BckgrdCmdStarted, InvalidInput
  `define RC13b Success, InternalError,    RetryReqd,   InvalidPayloadLen, InvalidSecuritySt, \
                Aborted, Unsupported,      TxferOOO,    BckgrdCmdStarted,  InvalidPhysAddr, \
                Busy,    ResourceExhaust,  InvalidInput
  // - 15
  `define RC15  Success, InternalError, RetryReqd,    InvalidPayloadLen, BckgrdCmdStarted, \
                Busy,    Unsupported,   InvalidInput, MediaDisabled,     FWVerifFail, \
                Aborted, FWTxferInProg, FWTxferOOO,   InvalidSlot,       InvalidSecuritySt

  // use this as a reference; this matches the column for Type 1/2/3 device+Mailbox
  const cxl_comp_mbox_cmd_value_s cmd_ref[cxl_comp_mbox_cmd_opcode_e] = '{
    // ------------------------------
    // GENERIC CXL COMPONENT COMMANDS
    // ------------------------------
    INFOSTS_Identify          : '{ 0, {}, 12, {}, {`RC3a}, NoRetCode, PROHIBIT},
    INFOSTS_BckgrndOpSts      : '{ 0, {},  8, {}, {`RC4a}, NoRetCode, PROHIBIT},
    INFOSTS_GetRspMsgLim      : '{ 0, {},  1, {}, {`RC3a}, NoRetCode, PROHIBIT},
    INFOSTS_SetRspMsgLim      : '{ 1, {},  1, {}, {`RC5b}, NoRetCode, PROHIBIT},
    INFOSTS_ReqAbortBckgrndOp : '{ 1, {},  1, {}, {`RC4d}, NoRetCode, OPTIONAL},
    // -- //
    EVENTS_GetEventRecs             : '{ 1, {}, -32, {}, {`RC7a}, NoRetCode, SUPPORTED},
    EVENTS_ClrEventRecs             : '{-6, {},   0, {}, {`RC8b}, NoRetCode, SUPPORTED},
    EVENTS_GetEventIrqPol           : '{ 0, {},   5, {}, {`RC4a}, NoRetCode, SUPPORTED},
    EVENTS_SetEventIrqPol           : '{ 5, {},   0, {}, {`RC5b}, NoRetCode, SUPPORTED},
    EVENTS_GetMCTPEventPol          : '{ 0, {},   2, {}, {`RC4a}, NoRetCode, PROHIBIT},
    EVENTS_SetMCTPEventPol          : '{ 2, {},   2, {}, {`RC5b}, NoRetCode, PROHIBIT},
    EVENTS_EventNotify              : '{ 2, {},   0, {}, {`RC4b}, NoRetCode, PROHIBIT},
    EVENTS_GFDEnhncEventNotify      : '{40, {},   0, {}, {`RC4b}, NoRetCode, PROHIBIT},
    EVENTS_GFDtoGAEEnhncEventNotify : '{32, {},   0, {}, {`RC3c}, NoRetCode, PROHIBIT},
    EVENTS_GetGAMBuffer             : '{ 8, {},   0, {}, {`RC3c}, NoRetCode, PROHIBIT},
    EVENTS_SetGAMBuffer             : '{ 8, {},   0, {}, {`RC3c}, NoRetCode, PROHIBIT},
    // -- / :
    FWUPDATE_GetFWInfo  : '{   0, {}, 60, {}, {`RC5a }, NoRetCode, OPTIONAL},
    FWUPDATE_TxferFW    : '{-128, {},  0, {}, {`RC15 }, NoRetCode, OPTIONAL},
    FWUPDATE_ActivateFW : '{   2, {},  0, {}, {`RC13a}, NoRetCode, OPTIONAL},
    // -- //
    TIMESTAMP_GetTimestamp : '{ 0, {}, 8, {}, {`RC5b}, NoRetCode, OPTIONAL},
    TIMESTAMP_SetTimestamp : '{ 8, {}, 0, {}, {`RC4a}, NoRetCode, OPTIONAL},
    // -- //
    LOGS_GetSuppLogs        : '{ 0, {}, -8, {}, {`RC4a}, NoRetCode, SUPPORTED},
    LOGS_GetLog             : '{24, {}, -1, {}, {`RC8a}, NoRetCode, SUPPORTED},
    LOGS_GetLogCaps         : '{16, {},  4, {}, {`RC5c}, NoRetCode, OPTIONAL},
    LOGS_ClrLog             : '{16, {},  0, {}, {`RC5c}, NoRetCode, OPTIONAL},
    LOGS_PopulateLog        : '{16, {},  0, {}, {`RC9 }, NoRetCode, OPTIONAL},
    LOGS_GetSuppLogsSublist : '{ 2, {}, -8, {}, {`RC5a}, NoRetCode, OPTIONAL},
    // -- //
    FEATURES_GetSuppFeatures : '{ 8, {}, -8, {}, {`RC6a}, NoRetCode, OPTIONAL},
    FEATURES_GetFeature      : '{21, {}, -1, {}, {`RC7b}, NoRetCode, OPTIONAL},
    FEATURES_SetFeature      : '{21, {}, -1, {}, {`RC7b}, NoRetCode, OPTIONAL},
    // -- //
    MAINT_PerformMaint       : '{-2, {},  0, {}, {`RC13b}, NoRetCode, OPTIONAL},
    // -- //
    PBRCOMP_IdentifyPBRComp : '{ 0, {},  38, {}, {`RC4c}, NoRetCode, OPTIONAL}, 
    PBRCOMP_ClaimOwnership  : '{21, {},  36, {}, {`RC5b}, NoRetCode, OPTIONAL},
    PBRCOMP_ReadCDAT        : '{20, {}, -16, {}, {`RC5b}, NoRetCode, PROHIBIT},
    // ------------------------------
    // CXL MEMORY DEVICE COMMANDS
    //  - Not adding all at this time, only adding a few
    // ------------------------------
    IDMEMDEV_Identify : '{ 0, {}, 69, {}, {`RC4a}, NoRetCode, SUPPORTED},
    // -- //
    HEALTH_GetInfo       : '{ 0, {}, 18, {}, {`RC5a}, NoRetCode, SUPPORTED}, 
    HEALTH_GetAlertCfg   : '{ 0, {}, 16, {}, {`RC6a}, NoRetCode, SUPPORTED},
    HEALTH_SetAlertCfg   : '{12, {},  0, {}, {`RC6a}, NoRetCode, SUPPORTED},
    HEALTH_GetShutdownSt : '{ 0, {},  1, {}, {`RC6b}, NoRetCode, SUPPORTED},
    HEALTH_SetShutdownSt : '{ 1, {},  0, {}, {`RC6b}, NoRetCode, SUPPORTED} 
  }; 
  
  // Mailbox register offsets
  typedef enum bit [31:0] {
    MBOX_CAPS           = 'h0,
    MBOX_CTRL           = 'h4,
    MBOX_COMMAND        = 'h8,
    MBOX_STATUS         = 'h10,
    MBOX_BKGRD_CMD_STS  = 'h18,
    MBOX_PAYLOAD_BASE   = 'h20 
  } mbox_offset_e;
  
  protected int max_payload_size = -1; //in bytes; Mailbox Capabilities Register (2^8 to 2^20)

  function new(string name = "cseq_cxl_mbox");
    super.new(name);
    print_irqs = 0; //there is no local source
  endfunction

  virtual task do_action;
    bit    [31:0]    addr; //full addr
    mbox_offset_e    offset;
    bit    [31:0]    data;
    bit    [ 3:0]    wr_be;
    cxl_comp_cmd_obj cur_cmd_obj;
    // run base class's action to get ELBI mailbox txn request
    super.do_action;
    // check if ELBI mailbox txn may be targeting the CXL mailbox
    if (&{txn.pf==cxl_mbox_pf, txn.bar==cxl_mbox_bar}) begin
      // Just get mailbox's command payload registers size once
      if (max_payload_size==-1) begin
        max_payload_size = (1 << mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][cxl_mbox_base_addr][4:0]);
        if (!(mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][cxl_mbox_base_addr][4:0] inside {[8:20]}))
          `uvm_fatal(get_type_name, "MailboxCapabilitiesRegister.PayloadSize must be [8:20]")
      end
      // calculate byte offset
      offset = mbox_offset_e'(txn.masked_addr-cxl_mbox_base_addr);
      // detect out of bounds condition
      if (offset > (max_payload_size+32)) return;
      // detect mailbox commands for lower DW of txn
      data  = txn.u_txfer ? txn.data_1     : txn.data_0;
      wr_be = txn.u_txfer ? txn.wr_be[7:4] : txn.wr_be[3:0];
      case (offset)
        MBOX_CAPS    : //check if partner is writing and flag it
          if (!txn.rd && wr_be) 
            `uvm_error(get_type_name, "Mailbox Caps. Register (Offset: 0x0) is RO")
        MBOX_CTRL    : //check if doorbell was set and grab command
          if (!txn.rd && wr_be[0] && data[0]) begin
            clear_cmd;
            addr = cxl_mbox_base_addr+MBOX_COMMAND;
            cmd.opcode             = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][15: 0];
            cmd.payload_len[15: 0] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][31:16];
            addr = cxl_mbox_base_addr+MBOX_COMMAND+4;
            cmd.payload_len[20:16] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][ 4: 0];
            // Get payload
            addr = cxl_mbox_base_addr+MBOX_PAYLOAD_BASE;
            // Extend the ipayload by a DW at a time
            repeat ((cmd.payload_len/4)+|(cmd.payload_len%4)) begin
              cmd.ipayload = new[cmd.ipayload.size+4] (cmd.ipayload);
              cmd.ipayload[cmd.ipayload.size-4] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][0*8+:8];
              cmd.ipayload[cmd.ipayload.size-3] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][1*8+:8];
              cmd.ipayload[cmd.ipayload.size-2] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][2*8+:8];
              cmd.ipayload[cmd.ipayload.size-1] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][3*8+:8];
              addr+=4;
            end
            // Trim to bytes instead of DWs
            cmd.ipayload = new[cmd.payload_len] (cmd.ipayload);
            // print to log
            print_req;
            // Set the event
            `uvm_info(get_type_name, $sformatf("Setting doorbell for command %0s (0x%h)", cmd.opcode.name, cmd.opcode), UVM_NONE)
            ->doorbell_set;
            // handle the command
            cur_cmd_obj = get_cmd_obj(cmd.opcode);
            if (cur_cmd_obj != null) begin
              `uvm_info(get_type_name, $sformatf("CXL Mailbox can handle %0s command",cmd.opcode.name), UVM_LOW)
              // Fork it so this is not blocking
              fork
                cur_cmd_obj.perform; 
              join_none
            end
            else
              `uvm_error(get_type_name, $sformatf("CXL Mailbox not set up to handle handle %0s command",cmd.opcode.name))
          end
        MBOX_COMMAND : /*do nothing; will grab command later*/ ;
        MBOX_STATUS  : //check if partner is writing and flag it
          if (!txn.rd && wr_be) 
            `uvm_error(get_type_name, "Mailbox Status Register (Offset: 0x10) is RO")
        MBOX_BKGRD_CMD_STS : //check if partner is writing and flag it
          if (!txn.rd && wr_be) 
            `uvm_error(get_type_name, "Mailbox Bckgrnd Command Status Register (Offset: 0x18) is RO")
      endcase
      // detect mailbox commands for upper DW of txn
      if (txn.len==2) begin
        offset = mbox_offset_e'(offset+4);
        data   = txn.data_1;
        wr_be  = txn.wr_be[7:4];
        case (offset)
          MBOX_CTRL    : //check if doorbell was set and grab command
            if (!txn.rd && wr_be[0] && data[0]) begin
              clear_cmd;
              addr = cxl_mbox_base_addr+MBOX_COMMAND;
              cmd.opcode             = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][15: 0];
              cmd.payload_len[15: 0] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][31:16];
              addr = cxl_mbox_base_addr+MBOX_COMMAND+4;
              cmd.payload_len[20:16] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][ 4: 0];
              // Get payload
              addr = cxl_mbox_base_addr+MBOX_PAYLOAD_BASE;
              // Extend the ipayload by a DW at a time
              repeat ((cmd.payload_len/4)+|(cmd.payload_len%4)) begin
                cmd.ipayload = new[cmd.ipayload.size+4] (cmd.ipayload);
                cmd.ipayload[cmd.ipayload.size-4] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][0*8+:8];
                cmd.ipayload[cmd.ipayload.size-3] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][1*8+:8];
                cmd.ipayload[cmd.ipayload.size-2] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][2*8+:8];
                cmd.ipayload[cmd.ipayload.size-1] = mbox[MMIO][cxl_mbox_pf][cxl_mbox_bar][addr][3*8+:8];
                addr+=4;
              end
              // Trim to bytes instead of DWs
              cmd.ipayload = new[cmd.payload_len] (cmd.ipayload);
              // print to log
              print_req;
              // Set the event
              `uvm_info(get_type_name, $sformatf("Setting doorbell for command %0s (0x%h)", cmd.opcode.name, cmd.opcode), UVM_NONE)
              ->doorbell_set;
              foreach (cmd.ipayload[bb]) begin
                `uvm_info("DOORBELL_SET", $sformatf("cmd.ipayload[%0d]=0x%h",bb,cmd.ipayload[bb]), UVM_LOW)
              end
              // handle the command
              cur_cmd_obj = get_cmd_obj(cmd.opcode);
              if (cur_cmd_obj != null) begin
                `uvm_info(get_type_name, $sformatf("CXL Mailbox can handle %0s command",cmd.opcode.name), UVM_LOW)
                fork
                  cur_cmd_obj.perform; 
                join_none
              end
              else
                `uvm_error(get_type_name, $sformatf("CXL Mailbox not set up to handle handle %0s command",cmd.opcode.name))
            end
          MBOX_COMMAND : /*do nothing; will grab command later*/ ;
          MBOX_STATUS  : //check if partner is writing and flag it
            if (!txn.rd && wr_be) 
              `uvm_error(get_type_name, "Mailbox Status Register (Offset: 0x10) is RO")
          MBOX_BKGRD_CMD_STS : //check if partner is writing and flag it
            if (!txn.rd && wr_be) 
              `uvm_error(get_type_name, "Mailbox Bckgrnd Command Status Register (Offset: 0x18) is RO")
        endcase
      end
    end
  endtask

  // ---------------------------------
  // Helper methods                   
  // ---------------------------------

  virtual function void print_req;
    `uvm_info(get_type_name, 
              $sformatf("CXL Mailbox rcv'd command: Opcode=%0s ('h%h) and PayloadLen=%0d",
                cmd.opcode.name, cmd.opcode, cmd.payload_len), 
              UVM_LOW)
  endfunction

  // -- *_cmd methods -- //

  virtual function void clear_cmd;
    cmd = '{No_Command, 0, {}, {}, NoRetCode};
  endfunction

  virtual function bit add_cmd_obj(cxl_comp_cmd_obj obj);
    string  msg;
    int     qi[$];
    if (cmd_obj.exists(obj.opcode)) begin
      msg = $sformatf("Replacing the existence of command %0s",obj.opcode.name);
      `uvm_warning(get_type_name, msg)
    end
    obj.parent          = this;
    cmd_obj[obj.opcode] = obj;
  endfunction

  virtual function cxl_comp_cmd_obj get_cmd_obj(cxl_comp_mbox_cmd_opcode_e opcode);
    string msg;
    if (!exists_cmd_obj(opcode)) begin
      msg = $sformatf("Object for command %0s does not exist",opcode.name);
      `uvm_warning(get_type_name, msg)
      return null;
    end
    return cmd_obj[opcode];
  endfunction

  virtual function bit exists_cmd_obj(cxl_comp_mbox_cmd_opcode_e opcode);
    return cmd_obj.exists(opcode);
  endfunction
  
endclass
