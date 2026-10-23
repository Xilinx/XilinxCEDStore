// Create a custom report server so that UVM_[INFO, ERROR...] messages don't
// print the entire filepath, which is really annoying
class custom_report_server extends uvm_report_server;

  // Grab the last substring starting with '/'
  virtual function string fname_substr(string s);

    int ii;
    for (ii=s.len-1; ii>=0; ii--) begin
      if (s.getc(ii) == "/")
        return s.substr(ii+1, s.len-1);
      else if (!ii)
        return s;
    end

  endfunction

  // Literally copied from base/uvm_report_server.svh and changed in return statements:
  // filename -> fname_substr(filename)
  virtual function string compose_message(
      uvm_severity severity,
      string name,
      string id,
      string message,
      string filename,
      int    line
      );
    uvm_severity_type sv;
    string time_str;
    string line_str;

    sv = uvm_severity_type'(severity);
    $swrite(time_str, "%0t", $realtime);

    case(1)
      (name == "" && filename == ""):
         return {sv.name(), " @ ", time_str, " [", id, "] ", message};
      (name != "" && filename == ""):
         return {sv.name(), " @ ", time_str, ": ", name, " [", id, "] ", message};
      (name == "" && filename != ""):
           begin
             $swrite(line_str, "%0d", line);
             return {sv.name(), " ",fname_substr(filename), "(", line_str, ")", " @ ", time_str, " [", id, "] ", message};
           end
      (name != "" && filename != ""):
           begin
             $swrite(line_str, "%0d", line);
             return {sv.name(), " ", fname_substr(filename), "(", line_str, ")", " @ ", time_str, ": ", name, " [", id, "] ", message};
           end
    endcase
  endfunction

endclass
