class data_init_crd_slv_seq extends uvm_sequence#(data_txn);

  `uvm_object_utils(data_init_crd_slv_seq)

  function new(string name = "data_init_crd_slv_seq");
    super.new(name);
  endfunction

  bit [7:0]    init_credit_ded[1:0][15:0];
  bit [7:0]    init_credit_shr;

  int unsigned sum_credits_ded;

  uvm_event init_crd_done;

  // We will create a series of single cycle txns so that all credits get returned since
  // we cannot specify a number of cycles in one transaction
  data_txn ctxn_q[$];

  virtual task body();

    data_txn ctxn = data_txn::type_id::create("ctxn");
    data_txn tmp;
    ctxn.credrtn = 1'b1;
    ctxn.data_block = 1'b0;

    calc_sum_credits_ded();

    if (!sum_credits_ded && !init_credit_shr)
      `uvm_fatal(get_type_name, "Must specify the number of credits to initially give")
    // Shared and dedicated credits can be returned at the same time,
    // so we find if there are more dedicated or shared credits then
    // loop through the greater number and add in the other credits.
    if (init_credit_shr >= sum_credits_ded) begin //more shared credits than dedicated credits
      ctxn.data_rxcrd_shared = 1'b1;
      repeat(init_credit_shr) begin
        if (init_credit_ded[0][ 0] || init_credit_ded[0][ 1] || init_credit_ded[0][ 2] || init_credit_ded[0][ 3] ||
            init_credit_ded[0][ 4] || init_credit_ded[0][ 5] || init_credit_ded[0][ 6] || init_credit_ded[0][ 7] ||
            init_credit_ded[0][ 8] || init_credit_ded[0][ 9] || init_credit_ded[0][10] || init_credit_ded[0][11] ||
            init_credit_ded[0][12] || init_credit_ded[0][13] || init_credit_ded[0][14] || init_credit_ded[0][15])
        begin
          ctxn.data_rxcrd_valid = 1'b1; 
          ctxn.data_rxcrd_protocol_id = 4'b1000;
          if      (init_credit_ded[0][ 0]) begin ctxn.data_rxcrd_vc_id = 4'h0; init_credit_ded[0][ 0]--; end
          else if (init_credit_ded[0][ 1]) begin ctxn.data_rxcrd_vc_id = 4'h1; init_credit_ded[0][ 1]--; end
          else if (init_credit_ded[0][ 2]) begin ctxn.data_rxcrd_vc_id = 4'h2; init_credit_ded[0][ 2]--; end
          else if (init_credit_ded[0][ 3]) begin ctxn.data_rxcrd_vc_id = 4'h3; init_credit_ded[0][ 3]--; end
          else if (init_credit_ded[0][ 4]) begin ctxn.data_rxcrd_vc_id = 4'h4; init_credit_ded[0][ 4]--; end
          else if (init_credit_ded[0][ 5]) begin ctxn.data_rxcrd_vc_id = 4'h5; init_credit_ded[0][ 5]--; end
          else if (init_credit_ded[0][ 6]) begin ctxn.data_rxcrd_vc_id = 4'h6; init_credit_ded[0][ 6]--; end
          else if (init_credit_ded[0][ 7]) begin ctxn.data_rxcrd_vc_id = 4'h7; init_credit_ded[0][ 7]--; end
          else if (init_credit_ded[0][ 8]) begin ctxn.data_rxcrd_vc_id = 4'h8; init_credit_ded[0][ 8]--; end
          else if (init_credit_ded[0][ 9]) begin ctxn.data_rxcrd_vc_id = 4'h9; init_credit_ded[0][ 9]--; end
          else if (init_credit_ded[0][10]) begin ctxn.data_rxcrd_vc_id = 4'hA; init_credit_ded[0][10]--; end
          else if (init_credit_ded[0][11]) begin ctxn.data_rxcrd_vc_id = 4'hB; init_credit_ded[0][11]--; end
          else if (init_credit_ded[0][12]) begin ctxn.data_rxcrd_vc_id = 4'hC; init_credit_ded[0][12]--; end
          else if (init_credit_ded[0][13]) begin ctxn.data_rxcrd_vc_id = 4'hD; init_credit_ded[0][13]--; end
          else if (init_credit_ded[0][14]) begin ctxn.data_rxcrd_vc_id = 4'hE; init_credit_ded[0][14]--; end
          else if (init_credit_ded[0][15]) begin ctxn.data_rxcrd_vc_id = 4'hF; init_credit_ded[0][15]--; end
        end
        else if (init_credit_ded[1][ 0] || init_credit_ded[1][ 1] || init_credit_ded[1][ 2] || init_credit_ded[1][ 3] ||
                 init_credit_ded[1][ 4] || init_credit_ded[1][ 5] || init_credit_ded[1][ 6] || init_credit_ded[1][ 7] ||
                 init_credit_ded[1][ 8] || init_credit_ded[1][ 9] || init_credit_ded[1][10] || init_credit_ded[1][11] ||
                 init_credit_ded[1][12] || init_credit_ded[1][13] || init_credit_ded[1][14] || init_credit_ded[1][15])
        begin
          ctxn.data_rxcrd_valid = 1'b1; 
          ctxn.data_rxcrd_protocol_id = 4'b1001;
          if      (init_credit_ded[1][ 0]) begin ctxn.data_rxcrd_vc_id = 4'h0; init_credit_ded[1][ 0]--; end
          else if (init_credit_ded[1][ 1]) begin ctxn.data_rxcrd_vc_id = 4'h1; init_credit_ded[1][ 1]--; end
          else if (init_credit_ded[1][ 2]) begin ctxn.data_rxcrd_vc_id = 4'h2; init_credit_ded[1][ 2]--; end
          else if (init_credit_ded[1][ 3]) begin ctxn.data_rxcrd_vc_id = 4'h3; init_credit_ded[1][ 3]--; end
          else if (init_credit_ded[1][ 4]) begin ctxn.data_rxcrd_vc_id = 4'h4; init_credit_ded[1][ 4]--; end
          else if (init_credit_ded[1][ 5]) begin ctxn.data_rxcrd_vc_id = 4'h5; init_credit_ded[1][ 5]--; end
          else if (init_credit_ded[1][ 6]) begin ctxn.data_rxcrd_vc_id = 4'h6; init_credit_ded[1][ 6]--; end
          else if (init_credit_ded[1][ 7]) begin ctxn.data_rxcrd_vc_id = 4'h7; init_credit_ded[1][ 7]--; end
          else if (init_credit_ded[1][ 8]) begin ctxn.data_rxcrd_vc_id = 4'h8; init_credit_ded[1][ 8]--; end
          else if (init_credit_ded[1][ 9]) begin ctxn.data_rxcrd_vc_id = 4'h9; init_credit_ded[1][ 9]--; end
          else if (init_credit_ded[1][10]) begin ctxn.data_rxcrd_vc_id = 4'hA; init_credit_ded[1][10]--; end
          else if (init_credit_ded[1][11]) begin ctxn.data_rxcrd_vc_id = 4'hB; init_credit_ded[1][11]--; end
          else if (init_credit_ded[1][12]) begin ctxn.data_rxcrd_vc_id = 4'hC; init_credit_ded[1][12]--; end
          else if (init_credit_ded[1][13]) begin ctxn.data_rxcrd_vc_id = 4'hD; init_credit_ded[1][13]--; end
          else if (init_credit_ded[1][14]) begin ctxn.data_rxcrd_vc_id = 4'hE; init_credit_ded[1][14]--; end
          else if (init_credit_ded[1][15]) begin ctxn.data_rxcrd_vc_id = 4'hF; init_credit_ded[1][15]--; end
        end
        else
          ctxn.data_rxcrd_valid = 1'b0;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
    end
    else begin //more dedicated credits than shared credits
      ctxn.data_rxcrd_valid  = 1'b1;
      ctxn.data_rxcrd_protocol_id = 4'b1000;
      ctxn.data_rxcrd_vc_id = 4'd0;
      repeat(init_credit_ded[0][ 0]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd1;
      repeat(init_credit_ded[0][ 1]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd2;
      repeat(init_credit_ded[0][ 2]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd3;
      repeat(init_credit_ded[0][ 3]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd4;
      repeat(init_credit_ded[0][ 4]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd5;
      repeat(init_credit_ded[0][ 5]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd6;
      repeat(init_credit_ded[0][ 6]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd7;
      repeat(init_credit_ded[0][ 7]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd8;
      repeat(init_credit_ded[0][ 8]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd9;
      repeat(init_credit_ded[0][ 9]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd10;
      repeat(init_credit_ded[0][10]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd11;
      repeat(init_credit_ded[0][11]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd12;
      repeat(init_credit_ded[0][12]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd13;
      repeat(init_credit_ded[0][13]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd14;
      repeat(init_credit_ded[0][14]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd15;
      repeat(init_credit_ded[0][15]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_protocol_id = 4'b1001;
      ctxn.data_rxcrd_vc_id = 4'd0;
      repeat(init_credit_ded[1][ 0]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd1;
      repeat(init_credit_ded[1][ 1]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd2;
      repeat(init_credit_ded[1][ 2]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd3;
      repeat(init_credit_ded[1][ 3]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd4;
      repeat(init_credit_ded[1][ 4]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd5;
      repeat(init_credit_ded[1][ 5]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd6;
      repeat(init_credit_ded[1][ 6]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd7;
      repeat(init_credit_ded[1][ 7]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd8;
      repeat(init_credit_ded[1][ 8]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd9;
      repeat(init_credit_ded[1][ 9]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd10;
      repeat(init_credit_ded[1][10]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd11;
      repeat(init_credit_ded[1][11]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd12;
      repeat(init_credit_ded[1][12]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd13;
      repeat(init_credit_ded[1][13]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd14;
      repeat(init_credit_ded[1][14]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
      ctxn.data_rxcrd_vc_id = 4'd15;
      repeat(init_credit_ded[1][15]) begin
        ctxn.data_rxcrd_shared = (init_credit_shr != 0);
        if (init_credit_shr) init_credit_shr--;
        // Push one txn (single cycle) on the q
        $cast(tmp, ctxn.clone);
        ctxn_q.push_back(tmp);
      end
    
    end
    // Drain all the transactions
    foreach (ctxn_q[ii]) begin
      start_item(ctxn_q[ii]);
      finish_item(ctxn_q[ii]);
    end
    init_crd_done.trigger();
  endtask 

  virtual function void calc_sum_credits_ded();
    foreach(init_credit_ded[ii,jj])
      sum_credits_ded += init_credit_ded[ii][jj];
  endfunction

endclass
