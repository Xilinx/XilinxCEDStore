// Used to appropriately set data on completions being sent to BMD
class bmd_mem_callback_c extends apci_callbacks;
    apci_device     bfm_handle;
    bit [31:0]      pattern;
    bit             inject_bad_data;
    bit             injected;
    bit [31:0]      bad_data;
    bit [7:0]       bad_byte;

    function new(apci_device    bfm_handle      = null,
                 bit [31:0]     pattern         = '0,
                 bit            inject_bad_data = 1'b0,
                 bit [31:0]     bad_data        = '0,
                 bit [7:0]      bad_byte        = '0);
        // Initialize injected tracker
        this.injected = 1'b0;
        // Initialize class variables with new params
        this.bfm_handle         = bfm_handle;
        this.pattern            = pattern;
        this.inject_bad_data    = inject_bad_data;
        this.bad_data           = bad_data;
        this.bad_byte           = bad_byte;
    endfunction

    virtual function void clear();
        inject_bad_data = '0;
        bad_data        = '0;
        bad_byte        = '0;
        pattern         = '0;
    endfunction

    virtual function void read_mem_cb(
            input bit             is_host_mem,
            input bit[63:0]       addr       ,
            input bit[31:0]       ndw        ,
            input bit[3:0]        first_be   ,
            input bit[3:0]        last_be    ,
            ref   bit[31:0]       va[]       ,
            input avery_data_base src         );

        int injection_index;

        // Randomize index to inject
        injection_index = $urandom_range(0, ndw - 1);

        // Loop through each DW of received read
        for(int j=0; j < ndw; j++) begin
            // If we are at the injection index, have been instructed to inject,
            // and have not injected yet, then set the payload DW to 'bad_data'
            if (j == injection_index && inject_bad_data && !injected) begin
                va[j] = bad_data;
                this.injected = 1'b1;
            // Otherwise just set to standard pattern
            end else begin
                va[j] = pattern;
            end
        end

        // Handle first byte enable (if valid) and fill disabled bytes with 'bad_byte'
        // so that we know DUT is actually checking byte enables
        if (first_be != 4'b0000 || ndw != 1) begin
            va[0][7:0]   = first_be[0] == 1'b1 ? va[0][7:0]   : bad_byte;
            va[0][15:8]  = first_be[1] == 1'b1 ? va[0][15:8]  : bad_byte;
            va[0][23:16] = first_be[2] == 1'b1 ? va[0][23:16] : bad_byte;
            va[0][31:24] = first_be[3] == 1'b1 ? va[0][31:24] : bad_byte;
        end

        // If last byte enable is valid (number of dwords > 1) then perform
        // the same operation as above
        if (ndw > 1) begin
            va[ndw-1][7:0]   = last_be[0] == 1'b1 ? va[ndw-1][7:0]   : bad_byte;
            va[ndw-1][15:8]  = last_be[1] == 1'b1 ? va[ndw-1][15:8]  : bad_byte;
            va[ndw-1][23:16] = last_be[2] == 1'b1 ? va[ndw-1][23:16] : bad_byte;
            va[ndw-1][31:24] = last_be[3] == 1'b1 ? va[ndw-1][31:24] : bad_byte;
        end
    endfunction
endclass
