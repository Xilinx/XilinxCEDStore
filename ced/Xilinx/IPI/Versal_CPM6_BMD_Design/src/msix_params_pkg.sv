// Generated MSI-X Parameters Package
package msix_params_pkg;
    // Fixed parameters
    localparam MSIX_MAX_VECTORS = 2048;
    localparam MSIX_PF_COUNT = 6;
    localparam MSIX_VF_COUNT = 8;
    
    // Vector counts for each segment
    localparam int SRIOV_FUNCTION_VECTOR_COUNT_PF_SEGMENT [0:5] = 
        '{'d411, 'd241, 'd206, 'd291, 'd211, 'd121};
    
    localparam int SRIOV_FUNCTION_VECTOR_COUNT_VF_SEGMENT_ONE_VFG [0:31] = 
        '{'d3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3, 'd3};
    
    localparam int SRIOV_FUNCTION_VECTOR_COUNT_VF_SEGMENT [0:7] = 
        '{'d3, 'd0, 'd1, 'd3, 'd2, 'd2, 'd3, 'd3};

    // Function mapping arrays    
    localparam int SRIOV_FUNCTION_TO_PF_NUMBER_PF_SEGMENT [0:5] = 
        '{'d0, 'd1, 'd2, 'd3, 'd4, 'd5};
    
    localparam int SRIOV_FUNCTION_TO_PF_NUMBER_VF_SEGMENT [0:5] [0:31] = '{
        '{32{'d0}}, '{32{'d1}}, '{32{'d2}}, '{32{'d3}}, '{32{'d4}}, '{32{'d5}}
    };
    
    localparam int SRIOV_FUNCTION_TO_PF_NUMBER_VF_SEGMENT_UNROLLED [0:7] = 
        '{'d0, 'd1, 'd2, 'd3, 'd4, 'd4, 'd5, 'd5};

    // SR-IOV configuration parameters
    localparam SRIOV_ENABLED = MSIX_VF_COUNT > 0;
    localparam int SRIOV_PFX_VF_COUNT [0:5] = '{1, 1, 1, 1, 2, 2};
    localparam int SRIOV_PFX_FIRST_VF_OFFSET [0:5] = '{6, 7, 8, 9, 10, 12};
    localparam int SRIOV_PFX_VECTOR_COUNT [0:5] = '{411, 241, 206, 291, 211, 121};
    localparam int SRIOV_VFGX_VECTOR_COUNT [0:5] = '{3, 0, 1, 3, 2, 3};

    // Combined function arrays
    localparam int SRIOV_FUNCTION_VECTOR_COUNT [0:13] = 
        '{411, 241, 206, 291, 211, 121, 3, 0, 1, 3, 2, 2, 3, 3};
    
    localparam int SRIOV_FUNCTION_VECTOR_COUNT_SUMMATION [0:14] = 
        '{0, 411, 652, 858, 1149, 1360, 1481, 1484, 1484, 1485, 1488, 1490, 1492, 1495, 1498};

    localparam SRIOV_TOTAL_VECTOR_COUNT = 1498;

    localparam int SRIOV_FUNCTION_TO_PF_NUMBER [0:13] = 
        '{0,1,2,3,4,5,0,1,2,3,4,4,5,5};
    
    localparam int SRIOV_FUNCTION_TO_VF_NUMBER [0:13] = 
        '{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1};
    
    localparam int SRIOV_PF_TO_ITS_LAST_VF_NUMBER [0:5] = 
        '{6, 7, 8, 9, 11, 13};

    // Memory layout parameters
    localparam MSIX_BAR_BASE_ADDRESS = 64'h0;
    localparam PBA_BAR_OFFSET = 64'h5da0;
    
    localparam [63:0] MSIX_MVT_BASE_ADDRESS = 64'h0;
    localparam [63:0] MSIX_MVT_END_ADDRESS = 64'h5da0;
    localparam [63:0] MSIX_PBA_BASE_ADDRESS = 64'h5da0;
    localparam [63:0] MSIX_PBA_END_ADDRESS = 64'h5e5c;

    localparam MSIX_BAR_NUM = 'd1;

endpackage
