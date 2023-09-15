// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////
`include "board_common.vh"

module pci_exp_usrapp_com ();


/* Local variables */

reg   [31:0]           rx_file_ptr;
reg   [7:0]            frame_store_rx[5119:0];
integer                frame_store_rx_idx;
reg   [31:0]           tx_file_ptr;
reg   [7:0]            frame_store_tx[5119:0];
integer                frame_store_tx_idx;

reg   [31:0]           log_file_ptr;
integer                _frame_store_idx;

event                  rcvd_cpld, rcvd_memrd, rcvd_memwr;
event                  rcvd_cpl, rcvd_memrd64, rcvd_memwr64;
event                  rcvd_msg, rcvd_msgd, rcvd_cfgrd0;
event                  rcvd_cfgwr0, rcvd_cfgrd1, rcvd_cfgwr1;
event                  rcvd_iord, rcvd_iowr;

initial begin

  frame_store_rx_idx = 0;
  frame_store_tx_idx = 0;

  rx_file_ptr = $fopen("rx.dat");

  if (!rx_file_ptr) begin

    $write("ERROR: Could not open rx.dat.\n");
    $finish;

  end

  tx_file_ptr = $fopen("tx.dat");

  if (!tx_file_ptr) begin

    $write("ERROR: Could not open tx.dat.\n");
    $finish;
  end
end

  /************************************************************
  Task : TSK_PARSE_FRAME
  Inputs : None
  Outputs : None
  Description : Parse frame data
  *************************************************************/

  task TSK_PARSE_FRAME;
  input    log_file;

  reg   [1:0]   fmt;
  reg   [4:0]   f_type;
  reg   [2:0]   traffic_class;
  reg     td;
  reg      ep;
  reg  [1:0]   attr;
  reg  [9:0]   length;
  reg     payload;
  reg  [15:0]   requester_id;
  reg  [15:0]   completer_id;
  reg  [7:0]   tag;
  reg  [7:0]   byte_enables;
  reg  [7:0]  message_code;
  reg  [31:0]   address_low;
  reg  [31:0]   address_high;
  reg  [9:0]   register_address;
  reg   [2:0]   completion_status;
  reg  [31:0]  _log_file_ptr;
  integer    _frame_store_idx;

  begin

  if (log_file == `RX_LOG)
    _log_file_ptr = rx_file_ptr;
  else
    _log_file_ptr = tx_file_ptr;

  if (log_file == `RX_LOG) begin

    _frame_store_idx = frame_store_rx_idx;
    frame_store_rx_idx = 0;

  end else begin

    _frame_store_idx = frame_store_tx_idx;
    frame_store_tx_idx = 0;

  end

  if (log_file == `RX_LOG) begin

    $display("[%t] : TSK_PARSE_FRAME on Receive", $realtime);

    end
  else begin

    $display("[%t] : TSK_PARSE_FRAME on Transmit", $realtime);

    end          

  TSK_DECIPHER_FRAME (fmt, f_type, traffic_class, td, ep, attr, length, log_file);  

  // decode the packets received based on fmt and f_type

  casex({fmt, f_type})

    `PCI_EXP_MEM_READ32 : begin

      $fdisplay(_log_file_ptr, "[%t] : Memory Read-32 Frame \n", $time);
      payload = 0;
      TSK_3DW(fmt, f_type, traffic_class, td, ep, attr, length, payload, _frame_store_idx, _log_file_ptr, log_file);
      
      if (log_file == `RX_LOG)
        -> rcvd_memrd;
    end

    `PCI_EXP_IO_READ : begin

      $fdisplay(_log_file_ptr, "[%t] : IO Read Frame \n", $time);
      payload = 0;
      TSK_3DW(fmt, f_type, traffic_class, td, ep, attr, length, payload, _frame_store_idx, _log_file_ptr, log_file);

      if (log_file == `RX_LOG)
        -> rcvd_iord;
    end

    `PCI_EXP_CFG_READ0 : begin

      $fdisplay(_log_file_ptr, "[%t] : Config Read Type 0 Frame \n", $time);
      payload = 0;
      TSK_3DW(fmt, f_type, traffic_class, td, ep, attr, length, payload, _frame_store_idx, _log_file_ptr, log_file);

      if (log_file == `RX_LOG) 
        -> rcvd_cfgrd0;
    end

    `PCI_EXP_COMPLETION_WO_DATA: begin

      $fdisplay(_log_file_ptr, "[%t] : Completion Without Data Frame \n", $time);
      payload = 0;
      TSK_3DW(fmt, f_type, traffic_class, td, ep, attr, length, payload, _frame_store_idx, _log_file_ptr, log_file);

      if (log_file == `RX_LOG) 
        -> rcvd_cpl;
    end

    `PCI_EXP_MEM_READ64: begin

      $fdisplay(_log_file_ptr, "[%t] : Memory Read-64 Frame \n", $time);
      payload = 0;
      TSK_4DW(fmt, f_type, traffic_class, td, ep, attr, length, payload,  _frame_store_idx, _log_file_ptr, log_file);

      if (log_file == `RX_LOG) 
        -> rcvd_memrd64;
    end

    `PCI_EXP_MSG_NODATA: begin

      $fdisplay(_log_file_ptr, "[%t] : Message With No Data Frame \n", $time);
      payload = 0;
      TSK_4DW(fmt, f_type, traffic_class, td, ep, attr, length, payload,  _frame_store_idx, _log_file_ptr, log_file);

      if (log_file == `RX_LOG) 
        -> rcvd_msg;
    end

    `PCI_EXP_MEM_WRITE32: begin

      $fdisplay(_log_file_ptr, "[%t] : Memory Write-32 Frame \n", $time);
      payload = 1;
      TSK_3DW(fmt, f_type, traffic_class, td, ep, attr, length, payload, _frame_store_idx, _log_file_ptr, log_file);
      $fdisplay(_log_file_ptr, "\n");

      if (log_file == `RX_LOG) 
        -> rcvd_memwr;
    end

    `PCI_EXP_IO_WRITE: begin

      $fdisplay(_log_file_ptr, "[%t] : IO Write Frame \n", $time);
      payload = 1;
      TSK_3DW(fmt, f_type, traffic_class, td, ep, attr, length, payload, _frame_store_idx, _log_file_ptr, log_file);
      $fdisplay(_log_file_ptr, "\n");

      if (log_file == `RX_LOG) 
        -> rcvd_iowr;
    end

    `PCI_EXP_CFG_WRITE0: begin

      $fdisplay(_log_file_ptr, "[%t] : Config Write Type 0 Frame \n", $time);
      payload = 1;
      TSK_3DW(fmt, f_type, traffic_class, td, ep, attr, length, payload, _frame_store_idx, _log_file_ptr, log_file);
      $fdisplay(_log_file_ptr, "\n");

      if (log_file == `RX_LOG) 
        -> rcvd_cfgwr0;
    end

    `PCI_EXP_COMPLETION_DATA: begin

      $fdisplay(_log_file_ptr, "[%t] : Completion With Data Frame \n", $time);
      payload = 1;
      TSK_3DW(fmt, f_type, traffic_class, td, ep, attr, length, payload, _frame_store_idx, _log_file_ptr, log_file);
      $fdisplay(_log_file_ptr, "\n");

      if (log_file == `RX_LOG) 
        -> rcvd_cpld;
    end

    `PCI_EXP_MEM_WRITE64: begin

      $fdisplay(_log_file_ptr, "[%t] : Memory Write-64 Frame \n", $time);
      payload = 1;
      TSK_4DW(fmt, f_type, traffic_class, td, ep, attr, length, payload,  _frame_store_idx, _log_file_ptr, log_file);
      $fdisplay(_log_file_ptr, "\n");

      if (log_file == `RX_LOG) 
        -> rcvd_memwr64;
    end

    `PCI_EXP_MSG_DATA: begin

      $fdisplay(_log_file_ptr, "[%t] : Message With Data Frame \n", $time);
      payload = 1;
      TSK_4DW(fmt, f_type, traffic_class, td, ep, attr, length, payload,  _frame_store_idx, _log_file_ptr, log_file);
      $fdisplay(_log_file_ptr, "\n");

      if (log_file == `RX_LOG) 
        -> rcvd_msgd;
    end

    default: begin
      $fdisplay(_log_file_ptr, "[%t] : Not a valid frame \n", $time);
      $display(_log_file_ptr, "[%t] : Received an invalid frame \n", $time);
      $system("date +'%X--%x : Received an invalid frame' >> time.log");
      $finish(2);
    end

  endcase
  end
  endtask // TSK_PARSE_FRAME

  /************************************************************
  Task : TSK_DECIPHER_FRAME
  Inputs : None
  Outputs : fmt, f_type, traffic_class, td, ep, attr, length
  Description : Deciphers frame
  *************************************************************/

  task TSK_DECIPHER_FRAME;
  output [1:0]   fmt;
  output [4:0]   f_type;
  output [2:0]   traffic_class;
  output     td;
  output     ep;
  output [1:0]   attr;
  output [9:0]   length;
  input    txrx;

  begin

    fmt = (txrx ? frame_store_tx[0] : frame_store_rx[0]) >> 5;
    f_type = txrx ? frame_store_tx[0] : frame_store_rx[0];
    traffic_class = (txrx ? frame_store_tx[1] : frame_store_rx[1]) >> 4;
    td = (txrx ? frame_store_tx[2] : frame_store_rx[2]) >> 7;
    ep = (txrx ? frame_store_tx[2] : frame_store_rx[2]) >> 6;
    attr = (txrx ? frame_store_tx[2] : frame_store_rx[2]) >> 4;
    length = (txrx ? frame_store_tx[2] : frame_store_rx[2]);
    length = (length << 8) | (txrx ? frame_store_tx[3] : frame_store_rx[3]);

  end

  endtask // TSK_DECIPHER_FRAME


  /************************************************************
  Task : TSK_3DW
  Inputs : fmt, f_type, traffic_class, td, ep, attr, length, 
  payload, _frame_store_idx
  Outputs : None
  Description : Gets variables and prints frame 
  *************************************************************/

  task TSK_3DW;
  input   [1:0]   fmt;
  input   [4:0]   f_type;
  input   [2:0]   traffic_class;
  input     td;
  input     ep;
  input   [1:0]   attr;
  input   [9:0]   length;
  input      payload;
  input  [31:0]  _frame_store_idx;
  input  [31:0]  _log_file_ptr;
  input     txrx;

  reg [15:0] requester_id;
  reg [7:0] tag;
  reg [7:0] byte_enables;
  reg [31:0] address_low;
  reg [15:0] completer_id;
  reg [9:0] register_address;
  reg [2:0] completion_status;
  reg [63:0] dword_data; // this will be used to recontruct bytes of data and sent to tx_app
 
  integer    _i;

  begin
    $fdisplay(_log_file_ptr, "\t Traffic Class: 0x%h", traffic_class);
    $fdisplay(_log_file_ptr, "\t TD: %h", td);
    $fdisplay(_log_file_ptr, "\t EP: %h", ep);
    $fdisplay(_log_file_ptr, "\t Attributes: 0x%h", attr);
    $fdisplay(_log_file_ptr, "\t Length: 0x%h", length);

    casex({fmt, f_type})

    `PCI_EXP_CFG_READ0, 
    `PCI_EXP_CFG_WRITE0: begin

      requester_id = txrx ? {frame_store_tx[4], frame_store_tx[5]} : {frame_store_rx[4], frame_store_rx[5]};
      tag = txrx ? frame_store_tx[6] : frame_store_rx[6];
      byte_enables = txrx ? frame_store_tx[7] : frame_store_rx[7];
      completer_id = {txrx ? frame_store_tx[8] : frame_store_rx[8], txrx ? frame_store_tx[9] : frame_store_rx[9]};
      register_address = txrx ? frame_store_tx[10] : frame_store_rx[10];
      register_address = (register_address << 8) | (txrx ? frame_store_tx[11] : frame_store_rx[11]);

      $fdisplay(_log_file_ptr, "\t Requester Id: 0x%h", requester_id);
      $fdisplay(_log_file_ptr, "\t Tag: 0x%h", tag);
      $fdisplay(_log_file_ptr, "\t Last and First Byte Enables: 0x%h", byte_enables);
      $fdisplay(_log_file_ptr, "\t Completer Id: 0x%h", completer_id);
      $fdisplay(_log_file_ptr, "\t Register Address: 0x%h \n", register_address);

      if (payload == 1) begin

        for (_i = 12; _i < _frame_store_idx; _i = _i + 1) begin

          $fdisplay(_log_file_ptr, "\t 0x%h", txrx ? frame_store_tx[_i] : frame_store_rx[_i]);

        end
      end
    end

    `PCI_EXP_COMPLETION_WO_DATA,
    `PCI_EXP_COMPLETION_DATA: begin

      completer_id = txrx ? {frame_store_tx[4], frame_store_tx[5]} : {frame_store_rx[4], frame_store_rx[5]};
      completion_status = txrx ? (frame_store_tx[6] >> 5) : (frame_store_rx[6] >> 5);
      requester_id = txrx ? {frame_store_tx[8], frame_store_tx[9]} : {frame_store_rx[8], frame_store_rx[9]};
      tag = txrx ? frame_store_tx[10] : frame_store_rx[10];
      $fdisplay(_log_file_ptr, "\t Completer Id: 0x%h", completer_id);
      $fdisplay(_log_file_ptr, "\t Completion Status: 0x%h", completion_status);
      $fdisplay(_log_file_ptr, "\t Requester Id: 0x%h ", requester_id);
      $fdisplay(_log_file_ptr, "\t Tag: 0x%h \n", tag);

      if (payload == 1) begin      
                                
         dword_data = 64'h0000_0000_0000_0000;
				
	 for (_i = 12; _i < _frame_store_idx; _i = _i + 1) begin
				    				    
		$fdisplay(_log_file_ptr, "\t 0x%h", txrx ? frame_store_tx[_i] : frame_store_rx[_i]);
		if (!txrx) begin // if we are called from rx
				       
			dword_data = dword_data << 8; // build a dword to send to tx app
			dword_data = dword_data | {56'h0000_0000_0000_00,frame_store_rx[_i]}; 
		end  
	end
        `TX_TASKS.TSK_SET_READ_DATA(4'hf,dword_data); // send the data to the tx_app
      end
    
    
    end

    // memory reads, io reads, memory writes and io writes
    default: begin

      requester_id = txrx ? {frame_store_tx[4], frame_store_tx[5]} : {frame_store_rx[4], frame_store_rx[5]};
      tag = txrx ? frame_store_tx[6] : frame_store_rx[6];
      byte_enables = txrx ? frame_store_tx[7] : frame_store_rx[7];
      address_low = txrx ? frame_store_tx[8] : frame_store_rx[8];
      address_low = (address_low << 8) | (txrx ? frame_store_tx[9] : frame_store_rx[9]);
      address_low = (address_low << 8) | (txrx ? frame_store_tx[10] : frame_store_rx[10]);
      address_low = (address_low << 8) | (txrx ? frame_store_tx[11] : frame_store_rx[11]);
      $fdisplay(_log_file_ptr, "\t Requester Id: 0x%h", requester_id);
      $fdisplay(_log_file_ptr, "\t Tag: 0x%h", tag);
      $fdisplay(_log_file_ptr, "\t Last and First Byte Enables: 0x%h", byte_enables);
      $fdisplay(_log_file_ptr, "\t Address Low: 0x%h \n", address_low);
      if (payload == 1) begin

        for (_i = 12; _i < _frame_store_idx; _i = _i + 1) begin
  
          $fdisplay(_log_file_ptr, "\t 0x%h", (txrx ? frame_store_tx[_i] : frame_store_rx[_i]));
        end

      end
      
    end
  endcase 
  end
  endtask // TSK_3DW


  /************************************************************
  Task : TSK_4DW
  Inputs : fmt, f_type, traffic_class, td, ep, attr, length
  payload, _frame_store_idx
  Outputs : None
  Description : Gets variables and prints frame 
  *************************************************************/
  
  task TSK_4DW;
  input [1:0]   fmt;
  input [4:0]   f_type;
  input [2:0]   traffic_class;
  input         td;
  input     ep;
  input [1:0]   attr;
  input [9:0]   length;
  input      payload;
  input  [31:0]  _frame_store_idx;
  input  [31:0]  _log_file_ptr;
  input    txrx;
  
  reg [15:0]   requester_id;
  reg [7:0]   tag;
  reg [7:0]   byte_enables;
  reg [7:0]   message_code;
  reg [31:0]   address_high;
  reg [31:0]   address_low;
  reg [2:0]   msg_type;
  
  integer    _i;
  
  begin

    $fdisplay(_log_file_ptr, "\t Traffic Class: 0x%h", traffic_class);
    $fdisplay(_log_file_ptr, "\t TD: %h", td);
    $fdisplay(_log_file_ptr, "\t EP: %h", ep);
    $fdisplay(_log_file_ptr, "\t Attributes: 0x%h", attr);
    $fdisplay(_log_file_ptr, "\t Length: 0x%h", length);
  
    requester_id = txrx ? {frame_store_tx[4], frame_store_tx[5]} : {frame_store_rx[4], frame_store_rx[5]};
    tag = txrx ? frame_store_tx[6] : frame_store_rx[6];
    byte_enables = txrx ? frame_store_tx[7] : frame_store_rx[7];
    message_code = txrx ? frame_store_tx[7] : frame_store_rx[7];
    address_high = txrx ? frame_store_tx[8] : frame_store_rx[8];
    address_high = (address_high << 8) | (txrx ? frame_store_tx[9] : frame_store_rx[9]);
    address_high = (address_high << 8) | (txrx ? frame_store_tx[10] : frame_store_rx[10]);
    address_high = (address_high << 8) | (txrx ? frame_store_tx[11] : frame_store_rx[11]);
    address_low = txrx ? frame_store_tx[12] : frame_store_rx[12];
    address_low = (address_low << 8) | (txrx ? frame_store_tx[13] : frame_store_rx[13]);
    address_low = (address_low << 8) | (txrx ? frame_store_tx[14] : frame_store_rx[14]);
    address_low = (address_low << 8) | (txrx ? frame_store_tx[15] : frame_store_rx[15]);
    
    $fdisplay(_log_file_ptr, "\t Requester Id: 0x%h", requester_id);
    $fdisplay(_log_file_ptr, "\t Tag: 0x%h", tag);
    
    casex({fmt, f_type})
  
      `PCI_EXP_MEM_READ64,
      `PCI_EXP_MEM_WRITE64: begin
  
        $fdisplay(_log_file_ptr, "\t Last and First Byte Enables: 0x%h", byte_enables);
        $fdisplay(_log_file_ptr, "\t Address High: 0x%h", address_high);
        $fdisplay(_log_file_ptr, "\t Address Low: 0x%h \n", address_low);
        if (payload == 1) begin
  
          for (_i = 16; _i < _frame_store_idx; _i = _i + 1) begin
  
            $fdisplay(_log_file_ptr, "\t 0x%h", txrx ? frame_store_tx[_i] : frame_store_rx[_i]);
  
          end
        end
      end
    
      `PCI_EXP_MSG_NODATA,
      `PCI_EXP_MSG_DATA: begin
  
        msg_type = f_type;
        $fdisplay(_log_file_ptr, "\t Message Type: 0x%h", msg_type);
        $fdisplay(_log_file_ptr, "\t Message Code: 0x%h", message_code);
        $fdisplay(_log_file_ptr, "\t Address High: 0x%h", address_high);
        $fdisplay(_log_file_ptr, "\t Address Low: 0x%h \n", address_low);
  
        if (payload == 1) begin
  
          for (_i = 16; _i < _frame_store_idx; _i = _i + 1) begin
  
            $fdisplay(_log_file_ptr, "\t 0x%h", txrx ? frame_store_tx[_i] : frame_store_rx[_i]);
          end
        end
      end
    endcase
    end
  endtask // TSK_4DW

  
   /************************************************************
        Task : TSK_READ_DATA
        Inputs : None
        Outputs : None
        Description : Consume clocks.
   *************************************************************/

  task TSK_READ_DATA;
    input    last;
    input    txrx;
    input  [63:0]  trn_d;
    input    trn_rem;
    integer   _i;
    reg  [7:0]  _byte;
    reg  [63:0]  _msk;
    reg  [3:0]  _rem;
                begin

      _msk = 64'hff00000000000000;
      _rem = (last ? ((trn_rem == 1) ? 4 : 8) : 8);

      for (_i = 0; _i < _rem; _i = _i + 1) begin

        _byte = (trn_d & (_msk >> (_i * 8))) >> (((7) - _i) * 8);

        if (txrx) begin

          board.RP.com_usrapp.frame_store_tx[board.RP.com_usrapp.frame_store_tx_idx] = _byte;
          board.RP.com_usrapp.frame_store_tx_idx = board.RP.com_usrapp.frame_store_tx_idx + 1;

        end else begin

          board.RP.com_usrapp.frame_store_rx[board.RP.com_usrapp.frame_store_rx_idx] = _byte;
          board.RP.com_usrapp.frame_store_rx_idx = board.RP.com_usrapp.frame_store_rx_idx + 1;
        end

      end 
                end
   endtask // TSK_READ_DATA

   /************************************************************
        Task : TSK_READ_DATA_128
        Inputs : None
        Outputs : None
        Description : Consume clocks.
   *************************************************************/

  task TSK_READ_DATA_128;
    input    first;
    input    last;
    input    txrx;
    input  [127:0]  trn_d;
    input  [1:0]  trn_rem;
    integer   _i;
    reg  [7:0]  _byte;
    reg  [127:0]  _msk;
    reg  [4:0]  _rem;
    reg  [3:0]  _strt_pos;
                begin

      _msk =   128'hff000000000000000000000000000000;
      _rem = (trn_rem[1] ? (trn_rem[0] ? 4 : 8) : (trn_rem[0] ? 12 : 16)) ;
      _strt_pos = 4'd15;

      for (_i = 0; _i < _rem; _i = _i + 1) begin

        _byte = (trn_d & (_msk >> (_i * 8))) >> (((_strt_pos) - _i) * 8);

        if (txrx) begin

          board.RP.com_usrapp.frame_store_tx[board.RP.com_usrapp.frame_store_tx_idx] = _byte;
          board.RP.com_usrapp.frame_store_tx_idx = board.RP.com_usrapp.frame_store_tx_idx + 1;

        end else begin

          board.RP.com_usrapp.frame_store_rx[board.RP.com_usrapp.frame_store_rx_idx] = _byte;
          board.RP.com_usrapp.frame_store_rx_idx = board.RP.com_usrapp.frame_store_rx_idx + 1;
        end

      end 
                end
   endtask // TSK_READ_DATA_128

   /************************************************************
        Task : TSK_READ_DATA_256
        Inputs : None
        Outputs : None
        Description : Consume clocks.
   *************************************************************/

  task TSK_READ_DATA_256;
    input    first;
    input    last;
    input    txrx;
    input  [255:0]  trn_d;
    input  [2:0]  trn_rem;
    integer   _i;
    reg  [7:0]  _byte;
    reg  [255:0]  _msk;
    reg  [5:0]  _rem;
    reg  [4:0]  _strt_pos;
                begin

//      _msk = ((first && trn_rem[2]) ? 
//             (trn_rem[1] ? 256'h000000000000000000000000000000000000000000000000ff00000000000000 : 256'h00000000000000000000000000000000ff000000000000000000000000000000): 
//             (trn_rem[1] ? 256'h0000000000000000ff0000000000000000000000000000000000000000000000 : 256'hff00000000000000000000000000000000000000000000000000000000000000)); 

      _msk = 256'hff00000000000000000000000000000000000000000000000000000000000000;

       casex (trn_rem)
           3'b000 : _rem = 32;
           3'b001 : _rem = 28;
           3'b010 : _rem = 24;
           3'b011 : _rem = 20;
           3'b100 : _rem = 16;
           3'b101 : _rem = 12;
           3'b110 : _rem =  8;
           3'b111 : _rem =  4;
           default  : _rem = 32;
        endcase

      //_strt_pos = ((first && trn_rem[2]) ? (trn_rem[1] ? 4'd7 : 4'd15) : (trn_rem[1] ? 4'd23 : 4'd31));
      _strt_pos = 5'd31; //((first && trn_rem[2]) ? (trn_rem[1] ? 5'd23 : 5'd31) : (trn_rem[1] ? 5'd7 : 5'd15));

      for (_i = 0; _i < _rem; _i = _i + 1) begin

        _byte = (trn_d & (_msk >> (_i * 8))) >> (((_strt_pos) - _i) * 8);

        if (txrx) begin

          board.RP.com_usrapp.frame_store_tx[board.RP.com_usrapp.frame_store_tx_idx] = _byte;
          board.RP.com_usrapp.frame_store_tx_idx = board.RP.com_usrapp.frame_store_tx_idx + 1;

        end else begin

          board.RP.com_usrapp.frame_store_rx[board.RP.com_usrapp.frame_store_rx_idx] = _byte;
          board.RP.com_usrapp.frame_store_rx_idx = board.RP.com_usrapp.frame_store_rx_idx + 1;
        end

      end 
                end
   endtask // TSK_READ_DATA_256

   /************************************************************
        Task : TSK_READ_DATA_512
        Inputs : None
        Outputs : None
        Description : Consume clocks.
   *************************************************************/

  task TSK_READ_DATA_512;
    input    first;
    input    last;
    input    txrx;
    input  [511:0]  trn_d;
    input  [3:0]  trn_rem;
    integer   _i;
    reg  [7:0]  _byte;
    reg  [511:0]  _msk;
    reg  [6:0]  _rem;
    reg  [5:0]  _strt_pos;
                begin

      _msk = 512'hff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;

       casex (trn_rem)
           4'b0000 : _rem = 64;
           4'b0001 : _rem = 60;
           4'b0010 : _rem = 56;
           4'b0011 : _rem = 52;
           4'b0100 : _rem = 48;
           4'b0101 : _rem = 44;
           4'b0110 : _rem = 40;
           4'b0111 : _rem = 36;
           4'b0000 : _rem = 32;
           4'b0001 : _rem = 28;
           4'b0010 : _rem = 24;
           4'b0011 : _rem = 20;
           4'b0100 : _rem = 16;
           4'b0101 : _rem = 12;
           4'b0110 : _rem =  8;
           4'b0111 : _rem =  4;
           default  : _rem = 64;
        endcase

      _strt_pos = 6'd63;

      for (_i = 0; _i < _rem; _i = _i + 1) begin

        _byte = (trn_d & (_msk >> (_i * 8))) >> (((_strt_pos) - _i) * 8);

        if (txrx) begin

          board.RP.com_usrapp.frame_store_tx[board.RP.com_usrapp.frame_store_tx_idx] = _byte;
          board.RP.com_usrapp.frame_store_tx_idx = board.RP.com_usrapp.frame_store_tx_idx + 1;

        end else begin

          board.RP.com_usrapp.frame_store_rx[board.RP.com_usrapp.frame_store_rx_idx] = _byte;
          board.RP.com_usrapp.frame_store_rx_idx = board.RP.com_usrapp.frame_store_rx_idx + 1;
        end

      end 
                end
   endtask // TSK_READ_DATA_512

  task TSK_READ_DATA_1024;
    input    first;
    input    last;
    input    txrx;
    input  [1023:0]  trn_d;
    input  [4:0]  trn_rem;
    integer   _i;
    reg  [7:0]  _byte;
    reg  [1023:0]  _msk;
    reg  [7:0]  _rem;
    reg  [6:0]  _strt_pos;
                begin

      _msk = {8'hff, 1016'h0};

       casex (trn_rem)
           5'b00000 : _rem = 128;
           5'b00001 : _rem = 124;
           5'b00010 : _rem = 120;
           5'b00011 : _rem = 116;
           5'b00100 : _rem = 112;
           5'b00101 : _rem = 108;
           5'b00110 : _rem = 104;
           5'b00111 : _rem = 100;
           5'b00000 : _rem = 96;
           5'b00001 : _rem = 92;
           5'b00010 : _rem = 88;
           5'b00011 : _rem = 84;
           5'b00100 : _rem = 80;
           5'b00101 : _rem = 76;
           5'b00110 : _rem = 72;
           5'b00111 : _rem = 68;
           5'b01000 : _rem = 64;
           5'b01001 : _rem = 60;
           5'b01010 : _rem = 56;
           5'b01011 : _rem = 52;
           5'b01100 : _rem = 48;
           5'b01101 : _rem = 44;
           5'b01110 : _rem = 40;
           5'b01111 : _rem = 36;
           5'b01000 : _rem = 32;
           5'b01001 : _rem = 28;
           5'b01010 : _rem = 24;
           5'b01011 : _rem = 20;
           5'b01100 : _rem = 16;
           5'b01101 : _rem = 12;
           5'b01110 : _rem =  8;
           5'b01111 : _rem =  4;
           default  : _rem = 128;
        endcase

      _strt_pos = 7'd127;

      for (_i = 0; _i < _rem; _i = _i + 1) begin

        _byte = (trn_d & (_msk >> (_i * 8))) >> (((_strt_pos) - _i) * 8);

        if (txrx) begin

          board.RP.com_usrapp.frame_store_tx[board.RP.com_usrapp.frame_store_tx_idx] = _byte;
          board.RP.com_usrapp.frame_store_tx_idx = board.RP.com_usrapp.frame_store_tx_idx + 1;

        end else begin

          board.RP.com_usrapp.frame_store_rx[board.RP.com_usrapp.frame_store_rx_idx] = _byte;
          board.RP.com_usrapp.frame_store_rx_idx = board.RP.com_usrapp.frame_store_rx_idx + 1;
        end

      end 
                end
   endtask // TSK_READ_DATA_1024
   
   
`include "pci_exp_expect_tasks.vh"

endmodule // pci_exp_usrapp_com
