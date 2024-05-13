/************************************************************
    Task : TSK_SYSTEM_CONFIGURATION_CHECK_US (Fuji2)
    Description : Check that options selected for US are set correctly
    Checks - Max Link Speed/Width, Device/Vendor ID, CMPS
    *************************************************************/
task TSK_SYSTEM_CONFIGURATION_CHECK_US;
  begin

    error_check = 0;

    // Check Link Speed/Width
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h80, 4'hF);
    TSK_WAIT_FOR_READ_DATA;

    // if  (P_READ_DATA[19:16] == MAX_LINK_SPEED) begin
    //    if (P_READ_DATA[19:16] == 1)
    //       $display("[%t] :    Check Max Link Speed = 2.5GT/s - PASSED", $realtime);
    //    else if(P_READ_DATA[19:16] == 2)
    //       $display("[%t] :    Check Max Link Speed = 5.0GT/s - PASSED", $realtime);
    //    else if(P_READ_DATA[19:16] == 3)
    //       $display("[%t] :    Check Max Link Speed = 8.0GT/s - PASSED", $realtime);
    // end else begin
    //       $display("[%t] :    Check Max Link Speed - FAILED", $realtime);
    //       $display("[%t] : Data Error Mismatch, Parameter Data %s != Read Data %x", $realtime, MAX_LINK_SPEED, P_READ_DATA[19:16]);
    // end

    if (P_READ_DATA[19:16] == MAX_LINK_SPEED) begin
      if (P_READ_DATA[19:16] == 1)
        $display("[%t] :    Check Max Link Speed = 2.5GT/s - PASSED", $realtime);
      else if (P_READ_DATA[19:16] == 2)
        $display("[%t] :    Check Max Link Speed = 5.0GT/s - PASSED", $realtime);
      else if (P_READ_DATA[19:16] == 3)
        $display("[%t] :    Check Max Link Speed = 8.0GT/s - PASSED", $realtime);
      else if (P_READ_DATA[19:16] == 4)
        $display("[%t] :    Check Max Link Speed = 16.0GT/s - PASSED", $realtime);
      else if (P_READ_DATA[19:16] == 5)
        $display("[%t] :    Check Max Link Speed = 32.0GT/s - PASSED", $realtime);
    end else begin
      $display("[%t] :    Check Max Link Speed - FAILED", $realtime);
      $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime,
               MAX_LINK_SPEED, P_READ_DATA[19:16]);
    end


    if (P_READ_DATA[23:20] == LINK_CAP_MAX_LINK_WIDTH_USP)
      $display(
          "[%t] : Check Negotiated Link Width = %x - PASSED", $realtime, LINK_CAP_MAX_LINK_WIDTH_USP
      );
    else
      $display(
          "[%t] : Data Error Mismatch, Parameter Data %x != Read Data %x",
          $realtime,
          LINK_CAP_MAX_LINK_WIDTH_USP,
          P_READ_DATA[23:20]
      );


    // Check Device/Vendor ID
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h0, 4'hF);
    TSK_WAIT_FOR_READ_DATA;

    if (P_READ_DATA[31:16] != 16'hb34f) begin // Changed 9038 to b03f
      $display("[%t] :    Check Device/Vendor ID - FAILED", $realtime);
      $display("[%t] : Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime,
               16'hb34f, P_READ_DATA[31:16]); // Changed 7014 to b03f
      error_check = 1;
    end else begin
      $display("[%t] :   Upstream Check Device/Vendor ID Check PASSED = %x", $realtime,
               P_READ_DATA[31:16]);
    end


    // Read and Program Bus Number

    $display("[%t] :    writing Sub Bus No =2, Sec Bus No =2 and Primary Bus No = 1", $realtime);
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h18, 32'h00020201, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);


    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h18, 4'hF);
    TSK_WAIT_FOR_READ_DATA;
    DEFAULT_TAG = DEFAULT_TAG + 1;
    $display("[%t] :   Bus Number Read  = %x", $realtime, P_READ_DATA);



    if (error_check == 0) begin
      $display("[%t] : Upstream SYSTEM CHECK PASSED", $realtime);
    end else begin
      $display("[%t] : SYSTEM CHECK FAILED", $realtime);
      // $finish;
    end

  end
endtask


/************************************************************
    Task : TSK_SYSTEM_CONFIGURATION_CHECK_DS (Fuji4)
    Description : Check that options selected for US are set correctly
    Checks - Max Link Speed/Width, Device/Vendor ID
    *************************************************************/
task TSK_SYSTEM_CONFIGURATION_CHECK_DS;
  begin

    error_check = 0;

    // Check Device/Vendor ID
    TSK_TX_TYPE1_CONFIGURATION_READ(DEFAULT_TAG, 12'h0, 4'hF, COMPLETER_ID_DSP);
    TSK_WAIT_FOR_READ_DATA;

    if (P_READ_DATA[31:16] != 16'hb44f) begin // changed 9138 to b054
      $display("[%t] :    Check Device/Vendor ID - FAILED", $realtime);
      $display("[%t] : Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime,
               16'hb44f, P_READ_DATA[31:16]); // changed 7302 to b054
      error_check = 1;
    end else begin
      $display("[%t] :  Downstream Device/Vendor ID Check PASSED = %x", $realtime,
               P_READ_DATA[31:16]);
    end

    // Check Link Speed/Width
    TSK_TX_TYPE1_CONFIGURATION_READ(DEFAULT_TAG, 12'h80, 4'hF, COMPLETER_ID_DSP);
    TSK_WAIT_FOR_READ_DATA;

    // if  (P_READ_DATA[19:16] == MAX_LINK_SPEED) begin
    //    if (P_READ_DATA[19:16] == 1)
    //       $display("[%t] :    Check Max Link Speed = 2.5GT/s - PASSED", $realtime);
    //    else if(P_READ_DATA[19:16] == 2)
    //       $display("[%t] :    Check Max Link Speed = 5.0GT/s - PASSED", $realtime);
    //    else if(P_READ_DATA[19:16] == 3)
    //       $display("[%t] :    Check Max Link Speed = 8.0GT/s - PASSED", $realtime);
    // end else begin
    //       $display("[%t] :    Check Max Link Speed - FAILED", $realtime);
    //       $display("[%t] : Data Error Mismatch, Parameter Data %s != Read Data %x", $realtime, MAX_LINK_SPEED, P_READ_DATA[19:16]);
    // end
    
    if (P_READ_DATA[19:16] == MAX_LINK_SPEED) begin
      if (P_READ_DATA[19:16] == 1)
        $display("[%t] :    Check Max Link Speed = 2.5GT/s - PASSED", $realtime);
      else if (P_READ_DATA[19:16] == 2)
        $display("[%t] :    Check Max Link Speed = 5.0GT/s - PASSED", $realtime);
      else if (P_READ_DATA[19:16] == 3)
        $display("[%t] :    Check Max Link Speed = 8.0GT/s - PASSED", $realtime);
      else if (P_READ_DATA[19:16] == 4)
        $display("[%t] :    Check Max Link Speed = 16.0GT/s - PASSED", $realtime);
      else if (P_READ_DATA[19:16] == 5)
        $display("[%t] :    Check Max Link Speed = 32.0GT/s - PASSED", $realtime);
    end else begin
      $display("[%t] :    Check Max Link Speed - FAILED", $realtime);
      $display("[%t] :    Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime,
               MAX_LINK_SPEED, P_READ_DATA[19:16]);
    end

    if (P_READ_DATA[23:20] == LINK_CAP_MAX_LINK_WIDTH_DSP)
      $display(
          "[%t] : Check Negotiated Link Width = %x - PASSED", $realtime, LINK_CAP_MAX_LINK_WIDTH_DSP
      );
    else
      $display(
          "[%t] : Data Error Mismatch, Parameter Data %x != Read Data %x",
          $realtime,
          LINK_CAP_MAX_LINK_WIDTH_DSP,
          P_READ_DATA[23:20]
      );



    // Check Header Register
    TSK_TX_TYPE1_CONFIGURATION_READ(DEFAULT_TAG, 12'hc, 4'hF, COMPLETER_ID_DSP);
    TSK_WAIT_FOR_READ_DATA;

    if (P_READ_DATA[23:16] != 8'h01) begin
      $display("[%t] :    HEADER TYPE - FAILED", $realtime);
      $display("[%t] : Data Error Mismatch, Parameter Data %x != Read Data %x", $realtime,
               EP_DEV_ID, P_READ_DATA[23:16]);
    end else begin
      $display("[%t] : Downstream HEADER TYPE - PASSED", $realtime);
    end


    // Read and Program Bus Number

    $display("[%t] :    writing Downstream Sub Bus No =3, Sec Bus No =3 and Primary Bus No = 2",
             $realtime);
    TSK_TX_TYPE1_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h18, 32'h00030302, 4'hF, COMPLETER_ID_DSP);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    TSK_TX_TYPE1_CONFIGURATION_READ(DEFAULT_TAG, 12'h18, 4'hF, COMPLETER_ID_DSP);
    TSK_WAIT_FOR_READ_DATA;
    DEFAULT_TAG = DEFAULT_TAG + 1;
    $display("[%t] :   Downstream Bus Number Read  = %x", $realtime, P_READ_DATA);

    $display("[%t] :    writing Upstream Sub Bus No =3, Sec Bus No =2 and Primary Bus No = 1",
             $realtime);
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h18, 32'h00030201, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h18, 4'hF);
    TSK_WAIT_FOR_READ_DATA;
    DEFAULT_TAG = DEFAULT_TAG + 1;
    $display("[%t] : Upstream  Bus Number Read  = %x", $realtime, P_READ_DATA);

  end
endtask

task TSK_US_DS_MEM_INIT;
  begin

    error_check = 0;

    // Write Mem / Limit register USport
    $display("[%t] :   Upstream Mem / Limit value fe3 - fe5 ", $realtime);
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h20, 32'hfe5ffe30, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read Mem / Limit register
    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h20, 4'hF);
    TSK_WAIT_FOR_READ_DATA;
    DEFAULT_TAG = DEFAULT_TAG + 1;
    $display("[%t] :   Upstream Mem / Limit value = %x", $realtime, P_READ_DATA[31:0]);

    // Set MSE enable
    $display("[%t] :   Upstream MSE Enable ", $realtime);
    TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h4, 32'h07, 4'h1);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    //  Write Mem / Limit register DSport

    $display("[%t] :   Downstream Mem / Limit value fe3 - fe5 ", $realtime);
    TSK_TX_TYPE1_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h20, 32'hfe5ffe30, 4'hF, COMPLETER_ID_DSP);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

    // Read Mem / Limit register

    TSK_TX_TYPE1_CONFIGURATION_READ(DEFAULT_TAG, 12'h20, 4'hF, COMPLETER_ID_DSP);
    TSK_WAIT_FOR_READ_DATA;
    DEFAULT_TAG = DEFAULT_TAG + 1;
    $display("[%t] :   DownStream Mem / Limit value = %x", $realtime, P_READ_DATA[31:0]);

    // Set MSE enable

    $display("[%t] :   Downstream MSE Enable ", $realtime);
    TSK_TX_TYPE1_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h4, 32'h07, 4'h1, COMPLETER_ID_DSP);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);

  end
endtask


