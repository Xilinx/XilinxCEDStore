interface msi_if;
    logic [2:0]                                        pl_msi_func_num;
    logic [7:0]                                        pl_msi_vfunc_num;
    logic                                              pl_msi_vfunc_active;
    logic [2:0]                                        pl_msi_tc;
    logic [4:0]                                        pl_msi_vector;
    logic                                              pl_issue_msi_req;
    logic                                              select_pl;
    logic                                              pl_done;

    modport master (
        output  pl_msi_func_num,
        output  pl_msi_vfunc_num,
        output  pl_msi_vfunc_active,
        output  pl_msi_tc,
        output  pl_msi_vector,
        output  pl_issue_msi_req,
        output  select_pl,
        input   pl_done
    );

    modport slave (
        input   pl_msi_func_num,
        input   pl_msi_vfunc_num,
        input   pl_msi_vfunc_active,
        input   pl_msi_tc,
        input   pl_msi_vector,
        input   pl_issue_msi_req,
        input   select_pl,
        output  pl_done
    );
endinterface : msi_if
