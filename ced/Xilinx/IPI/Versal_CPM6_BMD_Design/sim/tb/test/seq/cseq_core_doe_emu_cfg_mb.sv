class cseq_core_doe_emu_cfg_mb extends cseq_core_doe_discovery_cfg_mb;

  `uvm_object_utils(cseq_core_doe_emu_cfg_mb)

  int sock_client;


  function new(string name = "cseq_core_doe_emu_cfg_mb");
    super.new(name);

    sock_client = socket_client_create("xsjpvs02", 2323);
    if (sock_client < 0) begin
      `uvm_fatal("SOCK_CONN", "Failed to connect socket client")
    end
  endfunction

  virtual task generate_response(output bit err);
    byte send_data[];
    byte rcv_data[];
    int  rcv_len;
    err = 0;
    doe_data_rd.delete();

    super.generate_response(err);

    //Send DOE over socket to external DOE emulator
    if (err) begin
      send_data = new[doe_data.size()*4 + 12];
      send_data[0] = 8'h00;
      send_data[1] = 8'h00;
      send_data[2] = 8'h00;
      send_data[3] = 8'h01;
      send_data[4] = 8'h00;
      send_data[5] = 8'h00;
      send_data[6] = 8'h00;
      send_data[7] = 8'h02;
      send_data[8] = (doe_data.size()*4 >> 24) & 8'hFF;
      send_data[9] = (doe_data.size()*4 >> 16) & 8'hFF;
      send_data[10] = (doe_data.size()*4 >> 8) & 8'hFF;
      send_data[11] = (doe_data.size()*4) & 8'hFF;
      foreach (doe_data[i]) begin
        send_data[12 + i*4 + 3] = (doe_data[i] >> 24) & 8'hFF;
        send_data[12 + i*4 + 2] = (doe_data[i] >> 16) & 8'hFF;
        send_data[12 + i*4 + 1] = (doe_data[i] >> 8) & 8'hFF;
        send_data[12 + i*4 + 0] = (doe_data[i]) & 8'hFF;
      end
      socket_send(sock_client, send_data, send_data.size());
      //Receive DOE response from socket
      rcv_data = new[4];
      socket_recv_exact(sock_client, rcv_data, 4);
      socket_recv_exact(sock_client, rcv_data, 4);
      socket_recv_exact(sock_client, rcv_data, 4);
      rcv_len = {rcv_data[0], rcv_data[1], rcv_data[2], rcv_data[3]};
      rcv_data = new[rcv_len];
      socket_recv_exact(sock_client, rcv_data, rcv_len);
      for (int i = 0; i < rcv_len/4; i++) begin
        doe_data_rd.push_back({rcv_data[i*4 + 3], rcv_data[i*4 + 2], rcv_data[i*4 + 1], rcv_data[i*4 + 0]});
      end
    end
  endtask
endclass