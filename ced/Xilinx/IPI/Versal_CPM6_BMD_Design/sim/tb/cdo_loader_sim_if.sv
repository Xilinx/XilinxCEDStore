// Test can use this interface to for CDO programming control and status
interface cdo_loader_sim_if(input clk);

  logic cdo_go;
  logic cdo_done;

  clocking cb @(posedge clk);
    output cdo_go;
    input  cdo_done;
  endclocking 

  initial cdo_go <= '0;

  task assert_go;
    cb.cdo_go <= 1'b1;
    repeat(3) @(cb);
    cb.cdo_go <= 1'b0;
  endtask

  function bit get_done;
    return cb.cdo_done;
  endfunction

endinterface

