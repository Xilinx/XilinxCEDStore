// Create a custom report server so that UVM_[INFO, ERROR...] messages don't
// print the entire filepath, which is really annoying
//
// Extends uvm_default_report_server, not uvm_report_server: in this
// environment's UVM-1.2 base library (installed under $VCS_HOME/etc/
// uvm-1.2/base/uvm_report_server.svh), uvm_report_server is declared
// `virtual class` with quit-count/message-database/etc. accessors as
// `pure virtual` - only uvm_default_report_server (which extends it)
// provides concrete implementations. Extending the abstract base directly
// failed elaboration with Error-[SV-VMNI] "Virtual method not implemented"
// for set_max_quit_count/get_max_quit_count/set_quit_count/get_quit_count.
// compose_message() (overridden below) is still a real, non-pure virtual
// method on uvm_default_report_server (same signature), so the override
// continues to work unchanged.
class custom_report_server extends uvm_default_report_server;

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
    // NOTE: was "uvm_severity_type sv;" / "sv = uvm_severity_type'(severity);"
    // - uvm_severity_type is only a `ifndef UVM_NO_DEPRECATED typedef alias
    // for uvm_severity (see base/uvm_object_globals.svh in the installed
    // uvm-1.2 library); avery_vcs.f unconditionally sets
    // +define+UVM_NO_DEPRECATED for Avery VIP compilation, which compiles
    // out that alias entirely, so referencing it here failed with
    // Error-[SE] "Token 'uvm_severity_type' not recognized as a type" the
    // first time this file was ever compiled together with Avery. severity
    // is already a uvm_severity, so no cast is needed.
    uvm_severity sv;
    string time_str;
    string line_str;

    sv = severity;
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
