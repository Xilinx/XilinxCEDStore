////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
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
////////////////////////////////////////////////////////////////////////

`timescale 1ps / 1ps

import pcie_intf_pkg::*;
import ps_param_pkg::*;

module config_mem_handler #(

    parameter RP_CTRL0 = ps_param_pkg::RP_CTRL0,
    parameter RP_CTRL1 = ps_param_pkg::RP_CTRL1,
    parameter NUM_BAR = 6, // Number of BARs
    parameter NUM_SLOTS = 3, // Number of slots
    parameter MAX_NUM_SLOTS = 3, // Maximum number of slots
    parameter EP_ROM_SIZE = 256, // Size of EP ROM
    parameter RP_ROM_SIZE = 256, // Size of RP ROM
    parameter TRAFFIC_COUNT = 64, // Count of traffic
    parameter MAX_PAYLOAD_SIZE = 128, // Payload size in each traffic count
    parameter TAG_COUNT = 32, // Number of tags 5-bit tag - depends on extended tag enabled field
    parameter ADDR_WIDTH = 64, // Address width
    parameter DATA_WIDTH = 32, // Data width
    parameter DW_SIZE = 32, // DW size
    parameter ADDR_BUF_DEPTH = 64, // Depth of the address buffer
    parameter MAX_PAYLOAD_SIZE_BYTE = 128, // Maximum payload size in bytes
    parameter LOWER_ADDR_WIDTH = 7, // Lower address width for checker RAM
    parameter ACTUAL_PAYLOAD_SIZE_SLOT = 1, // Actual payload size in slots
    parameter ACTUAL_PAYLOAD_SIZE_BYTE = 128, // Actual payload size in bytes
`ifdef RP_SIM_FAST
    parameter DETECT_RETRY_DELAY = 3_840,      // simulation: 10 us at 384 MHz
`else
    parameter DETECT_RETRY_DELAY = 76_800_000, // Cycles between device-detect retries (200 ms at 384 MHz pl0_ref_clk)
`endif
    parameter IDE_EN = 0 // 1: hold traffic in WAIT_FOR_GO until traffic_go, and service AXI config-bridge requests
)
(
    input  logic                                                     clk,
    input  logic                                                     rst_n,
    input  logic                                                     link_down,

    input  logic                                                     halt, // Halt signal to stop processing

    //From COMPLETION
    input  logic                                                     completion_received, // Completion received signal
    input  logic [31:0]                                              cpl_data, // Data received in completion

    // TAG
    input  logic                                                     req_ready, // Request ready signal
    input  logic [$clog2(TAG_COUNT)-1:0]                             tag_id, // Tag IDs for requested tags
    input  logic                                                     tag_valid, // Validity of requested tags
    input  logic [$clog2(TAG_COUNT):0]                               free_tag_count,

    //to packet gen
    output tx_pkt_intf [NUM_SLOTS-1:0]                               tx_pkt_data_reg2, // TX packet data interface

    // Tag Manager Interface
    output logic                                                     final_req_valid, // Request valid signal
    output logic [1:0]                                               final_req_count, // Number of tags requested (1 or 2)

    // Checker RAM Interface
    output logic [(LOWER_ADDR_WIDTH+DATA_WIDTH-1):0]                 mem_checker_wr_data, // Data to write to the checker RAM
    output logic [$clog2(TAG_COUNT)-1:0]                             mem_checker_wr_addr, // Address to write to the checker RAM
    output logic                                                     mem_checker_wr_en, // Write enable signal for the checker RAM

    output logic [(DATA_WIDTH-1):0]                                  cfg_checker_wr_data, // Data to write to the checker RAM
    output logic [$clog2(TAG_COUNT)-1:0]                             cfg_checker_wr_addr,
    output logic                                                     cfg_checker_wr_en, // Write enable signal for the checker RAM
    
    output rp_cfg_intf                                               rp_cfg_data,
    output logic                                                     rp_rom_config_done,
    input  logic                                                     overall_rp_config_done,
    input  logic                                                     traffic_go, // start memory traffic (first CPM->PL IDE IRQ)

    // AXI4-Lite config bridge request interface (serviced in WAIT_FOR_GO and DONE)
    input  logic                                                     axi_req_valid,
    input  logic                                                     axi_req_wr,
    input  logic [31:0]                                              axi_req_addr,
    input  logic [31:0]                                              axi_req_wdata,
    output logic                                                     axi_req_accept,
    input  logic                                                     axi_req_done,
    output logic                                                     axi_cfg_ready,
    output logic [15:0]                                              ep_total_config_count,
    input  logic                                                     ep_config_match,
    output logic [$clog2(TAG_COUNT)-1:0]                             tag_to_match,
    output logic                                                     bar_read_done,
    output logic                                                     rp_start_reg,
    output logic [3:0]                                               dbg_state
);



    localparam NUM_EP_DETECT_RETRY = 5; // Number of retries for EP detection
    localparam TRAFFIC_COUNT_WIDTH = $clog2(TRAFFIC_COUNT) + 1; // Width for traffic count

    // EP State encoding
    typedef enum logic [3:0] {  
        IDLE = 4'b0000,
        DEVICE_DETECT = 4'b0001,
        BAR_CONFIG1 = 4'b0010,
        BAR_CONFIG2 = 4'b0011,
        BAR_CONFIG3 = 4'b0100,
        WAIT_FOR_COMPLETION = 4'b0101,
        PROCESS_DATA_EP = 4'b0110,
        PROCESS_DATA_RP = 4'b0111,
        TRAFFIC_GEN_1 = 4'b1000,
        TRAFFIC_GEN_2 = 4'b1001,
        WAIT_FOR_BAR_CALC = 4'b1010,
        DONE = 4'b1011,
        WAIT_FOR_CONFIG_DONE = 4'b1100,
        WAIT_FOR_GO = 4'b1101,
        AXI_WAIT = 4'b1110,
        DETECT_RETRY_WAIT = 4'b1111
    } state_t;

    state_t current_state, next_state;

    // Delay between device-detect retries (EP may return CRS/UR for a while after reset)
    logic [$clog2(DETECT_RETRY_DELAY+1)-1:0] detect_retry_cnt;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            detect_retry_cnt <= '0;
        else if (link_down || current_state != DETECT_RETRY_WAIT)
            detect_retry_cnt <= '0;
        else if (detect_retry_cnt != DETECT_RETRY_DELAY)
            detect_retry_cnt <= detect_retry_cnt + 1'b1;
    end

    // AXI config bridge: one config TLP at a time, only when idle and all tags are back
    logic axi_idle_ok;
    logic axi_issue_ok;
    logic all_tags_free_q; // registered "no tag outstanding" (timing at pl0_ref_clk)
    logic axi_ret_done;   // 1: return to DONE after the access, 0: return to WAIT_FOR_GO
    assign axi_idle_ok    = IDE_EN && (((current_state == WAIT_FOR_GO) && !traffic_go) || (current_state == DONE));
    assign axi_issue_ok   = axi_idle_ok && axi_req_valid && !halt && req_ready && all_tags_free_q;
    assign axi_req_accept = axi_issue_ok;
    assign axi_cfg_ready  = (axi_idle_ok && all_tags_free_q) || (current_state == AXI_WAIT); // not ready while any tag is outstanding

    // One cycle late is safe: in WAIT_FOR_GO/DONE the only tag allocator is the
    // bridge issue itself, after which the FSM leaves the issuing state.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            all_tags_free_q <= 1'b0;
        else
            all_tags_free_q <= (free_tag_count == TAG_COUNT);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            axi_ret_done <= 1'b0;
        else if (axi_issue_ok)
            axi_ret_done <= (current_state == DONE);
    end

    ////////////////// REGISTERS AND SIGNALS //////////////////
    // Control signals and counters
    logic [$clog2(NUM_EP_DETECT_RETRY)-1:0]     retry_counter, retry_counter_reg;           // Counter for retrying device detect
    logic                                       no_ep_found, no_ep_found_reg;               // Flag for no EP found
    logic                                       config_cycle, config_cycle_reg;             // Cycle for config, used to determine if sending header or data for NUM_SLOTS == 1
    logic [$clog2(NUM_BAR)-1:0]                 bar_count, bar_count_reg;                   // Counter for BAR configuration
    logic                                       bar_config_start, bar_config_start_reg;     // Flag to indicate BAR config start
    logic                                       rp_start;                     // Flag to indicate RP start
    logic                                       ep_config_done, rp_config_done;             // Flags to indicate EP and RP config done
    logic [1:0]                                 read_count;                // Number of addresses to read (0-2)
    logic                                       traffic_gen_reg, traffic_gen; // Flag to indicate traffic generation
    logic                                       device_detect_done, device_detect_done_reg; // Flag to indicate device detect done
    logic [1:0]                                 write_count, write_count_reg;               // Counter for traffic generation
    logic                                       start_processing, start_processing_reg;     // Flag to indicate start of processing BARs
    logic [$clog2(MAX_PAYLOAD_SIZE_BYTE)-1:0]   payload_size_reg;                           // Current payload size in bytes

    ////////////////// BAR HANDLER SIGNALS //////////////////
    logic [NUM_BAR-1:0][DATA_WIDTH-1:0]         bar_cpl_data;                            // BAR values
    logic [NUM_BAR-1:0][DATA_WIDTH-1:0]         bar_cpl_addr;                            // BAR addresses
    logic [NUM_BAR-1:0][DATA_WIDTH-1:0]         bar_sizes;                               // BAR sizes calculated by bar_handler
    logic [NUM_BAR-1:0][DATA_WIDTH-1:0]         bar_bases;                               // BAR base addresses calculated by bar_handler
    logic                                       bar_processing_done;                     // Signal indicating BAR processing is complete
    logic [NUM_BAR-1:0]                         is_64bit_bar;                            // 1 for 64-bit BAR, 0 for 32-bit BAR
    logic                                       is_all_64bit_bar;

    ////////////////// RP CONFIG ADDRESS DATA TYPE READ //////////////////
    logic [ADDR_WIDTH-1:0]                      cfg_rd_wr_addr;                          // Address for config read/write
    logic [DATA_WIDTH-1:0]                      cfg_rd_wr_data;                          // Data for config write
    logic                                       cfg_rd_wr_valid;                         // Valid signal for config read/write
    logic                                       cfg_rd_wr_type;                          // Type of config operation (read/write)
    logic [DATA_WIDTH-1:0]                      cfg_rd_wr_expected_data;                 // Expected data for config read/write

    ////////////////// EP CONFIG ADDRESS DATA TYPE READ //////////////////
    logic [ADDR_WIDTH-1:0]                      ep_cfg_rd_wr_addr;                       // Address for EP config read/write
    logic [DATA_WIDTH-1:0]                      ep_cfg_rd_wr_data;                       // Data for EP config write
    logic                                       ep_cfg_rd_wr_valid;                      // Valid signal for EP config read/write
    logic                                       ep_cfg_rd_wr_type;                       // Type of EP config operation (read/write)
    logic [DATA_WIDTH-1:0]                      ep_cfg_rd_wr_expected_data;              // Expected data for EP config read/write

    // EP ROM signals
    logic [EP_ROM_SIZE-1:0][ADDR_WIDTH-1:0]     ep_rom_addr;                             // Addresses for EP ROM
    logic [EP_ROM_SIZE-1:0][DATA_WIDTH-1:0]     ep_rom_data;                             // Data for EP ROM
    logic [EP_ROM_SIZE-1:0][1:0]                ep_rom_type;                             // Types for EP ROM
    logic [EP_ROM_SIZE-1:0][DATA_WIDTH-1:0]     ep_rom_expected_data;                    // Expected data for EP ROM
            
    // RP ROM signals        
    logic [RP_ROM_SIZE-1:0][ADDR_WIDTH-1:0]     rp_rom_addr;                             // Addresses for RP ROM
    logic [RP_ROM_SIZE-1:0][DATA_WIDTH-1:0]     rp_rom_data;                             // Data for RP ROM
    logic [RP_ROM_SIZE-1:0][1:0]                rp_rom_type;                             // Types for RP ROM
    logic [RP_ROM_SIZE-1:0][DATA_WIDTH-1:0]     rp_rom_expected_data;                    // Expected data for RP ROM

    logic [ADDR_WIDTH-1:0]                      ep_rom_addr_rom [EP_ROM_SIZE];           // Unpacked array
    logic [DATA_WIDTH-1:0]                      ep_rom_data_rom [EP_ROM_SIZE];           // Unpacked array
    logic [1:0]                                 ep_rom_type_rom [EP_ROM_SIZE];           // Unpacked array
    logic [DATA_WIDTH-1:0]                      ep_rom_expected_data_rom [EP_ROM_SIZE];  // Unpacked array

    logic [ADDR_WIDTH-1:0]                      rp_rom_addr_rom [RP_ROM_SIZE];           // Unpacked array
    logic [DATA_WIDTH-1:0]                      rp_rom_data_rom [RP_ROM_SIZE];           // Unpacked array
    logic [1:0]                                 rp_rom_type_rom [RP_ROM_SIZE];           // Unpacked array
    logic [DATA_WIDTH-1:0]                      rp_rom_expected_data_rom [RP_ROM_SIZE];  // Unpacked array

    logic                                       rp_rom_config_done_wire;

    rp_cfg_intf                                 rp_cfg_data_wire;                       // RP CFG wire

    // ROM pointers
    logic [$clog2(EP_ROM_SIZE):0]               ep_rom_ptr, ep_rom_ptr_reg;              // Pointer for EP ROM
    logic [$clog2(RP_ROM_SIZE):0]               rp_rom_ptr, rp_rom_ptr_reg;              // Pointer for RP ROM
    logic                                       stop_ep_rom_read;

    ////////////////// INTERFACE SIGNALS FOR TX_PKT_IF //////////////////
    tx_pkt_intf [NUM_SLOTS-1:0]                 tx_pkt_data;                             // TX packet data interface
    tx_pkt_intf [NUM_SLOTS-1:0]                 tx_pkt_data_reg;                         // Registered TX packet data interface
    tx_pkt_intf [NUM_SLOTS-1:0]                 tx_pkt_data_halt;                       // Halted TX packet data interface

    //////////// based on traffic gen logic
    logic [$clog2(TRAFFIC_COUNT):0] traffic_count, traffic_count_reg;
            
    //////////////// MEMORY ADDRESS GENERATION /////////////////////         
    logic [ADDR_WIDTH-1:0]                      read_addr_0;                // Addresses to be read from the buffer
    logic [ADDR_WIDTH-1:0]                      read_addr_0_reg;        // Registered addresses to be read from the buffer
    logic                                       buffer_empty;                            // Indicates if the buffer is empty
    logic                                       buffer_full;                             // Indicates if the buffer is full
    logic                                       read_enable;                             // Enable signal for reading from the address buffer


    //////////// VALID TRAFFIC GENERTION SIGNALS ///////////////
    logic [NUM_SLOTS-1:0]                       hdr_p_valid, hdr_p_valid_reg;           // Valid signals for posted header packets
    logic [NUM_SLOTS-1:0]                       hdr_np_valid, hdr_np_valid_reg;         // Valid signals for non-posted header packets
    logic [NUM_SLOTS-1:0]                       end_data_valid, end_data_valid_reg;     // Valid signals for end data packets
    logic [NUM_SLOTS-1:0]                       data_valid, data_valid_reg;             // Valid signals for data packets

    logic                                       traffic_enable, traffic_enable_reg;     // Enable signal for traffic generation
    logic                                       traffic_write, traffic_write_reg;       // Enable signal for traffic write

    logic [$clog2(TAG_COUNT)-1:0]               tag_id_reg;                       // Registered tag IDs for requested tags

    logic [DATA_WIDTH-1:0]                      ep_cfg_rd_wr_expected_data_reg, ep_cfg_rd_wr_expected_data_reg2; //store expected data to send to checker RAM
    logic                                       req_ready_reg;

    logic                                       halt_reg; // Registered halt signal

    ////////////// CONFIG COMPLETE ///////////////
    logic                                       overall_config_done;                   // Overall configuration done signal

    logic [15:0]                                ep_cfg_count, ep_cfg_count_reg;                     // EP config read count signal

    logic [(LOWER_ADDR_WIDTH+DATA_WIDTH-1):0]   mem_checker_wr_data_wire;
    logic [$clog2(TAG_COUNT)-1:0]               mem_checker_wr_addr_wire;
    logic                                       mem_checker_wr_en_wire;

    logic [(DATA_WIDTH-1):0]                    cfg_checker_wr_data_wire;
    logic [$clog2(TAG_COUNT)-1:0]               cfg_checker_wr_addr_wire;
    logic                                       cfg_checker_wr_en_wire;

    // Assignments for Config done stages
    assign overall_config_done = ep_config_match && overall_rp_config_done;
    assign dbg_state = current_state;   // state_t is enum logic [3:0]

    assign rp_rom_config_done_wire = rp_config_done && (current_state != PROCESS_DATA_RP);

    // SLOT based Payload Size
    assign payload_size_reg = (ACTUAL_PAYLOAD_SIZE_BYTE <= 64) ? 'b1 : 'b10; // SLOT based payload size

    assign ep_total_config_count = NUM_BAR*2 + EP_ROM_SIZE; // Total count for EP config

    assign bar_read_done = start_processing_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rp_rom_config_done <= 1'b0; 
        end else if (link_down) begin
            rp_rom_config_done <= 1'b0;
        end else begin
            rp_rom_config_done <= rp_rom_config_done_wire;
        end
    end

    ///////////////// BAR HANDLER INSTANCE /////////////////
    bar_handler #(
        .NUM_BAR(NUM_BAR),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) bar_handler_inst (
        .clk(clk),
        .rst_n(rst_n),
        .link_down(link_down),
        .start_processing(start_processing_reg), // Start processing when BAR config starts
        .bar_values(bar_cpl_data),             // Input BAR values
        .bar_sizes(bar_sizes),               // Output BAR sizes
        .bar_bases(bar_bases),               // Output BAR base addresses
        .processing_done(bar_processing_done), // Processing done signal
        .is_all_64bit_bar(is_all_64bit_bar),
        .is_64bit_bar(is_64bit_bar)           // Output 64-bit BAR flags
    );
    ///////////////////////////////////////////////////////////



    ///////////////// STATE UPDATE /////////////////
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else if (link_down)
            current_state <= IDLE; // Reset to IDLE on link down
        else
            current_state <= next_state;
    end


    ///////////////// CONTROL SIGNAL REGISTERING /////////////////
    always_ff @(posedge clk or negedge rst_n ) begin
        if(!rst_n) begin
            retry_counter_reg <= '0; // Reset retry counter
            no_ep_found_reg <= 1'b0; // Reset no EP found flag
            config_cycle_reg <= 1'b0; // Reset config cycle
            bar_count_reg <= '0; // Reset BAR count
            bar_config_start_reg <= 1'b0; // Reset BAR config start flag
            ep_rom_ptr_reg <= '0; // Reset EP ROM pointer
            rp_rom_ptr_reg <= '0; // Reset RP ROM pointer
            rp_start_reg <= 1'b0; // Reset RP start flag
            traffic_gen_reg <= 1'b0; // Reset traffic gen flag
            device_detect_done_reg <= 1'b0; // Reset device detect done flag
            write_count_reg <= 2'b0; // Reset write count
            start_processing_reg <= 1'b0; // Reset start processing flag
            traffic_enable_reg <= 1'b0; // Reset traffic enable flag
            traffic_write_reg <= 1'b0; // Reset traffic write flag
        end
        else if (link_down) begin
            retry_counter_reg <= '0; // Reset retry counter on link down
            no_ep_found_reg <= 1'b0; // Reset no EP found flag on link down
            config_cycle_reg <= 1'b0; // Reset config cycle on link down
            bar_count_reg <= '0; // Reset BAR count on link down
            bar_config_start_reg <= 1'b0; // Reset BAR config start flag on link down
            ep_rom_ptr_reg <= '0; // Reset EP ROM pointer on link down
            rp_rom_ptr_reg <= '0; // Reset RP ROM pointer on link down
            rp_start_reg <= 1'b0; // Reset RP start flag on link down
            traffic_gen_reg <= 1'b0; // Reset traffic gen flag on link down
            device_detect_done_reg <= 1'b0; // Reset device detect done flag on link down
            write_count_reg <= 2'b0; // Reset write count on link down
            start_processing_reg <= 1'b0; // Reset start processing flag on link down
            traffic_enable_reg <= 1'b0; // Reset traffic enable flag on link down
            traffic_write_reg <= 1'b0; // Reset traffic write flag on link down
        end
        else begin
            retry_counter_reg <= retry_counter; // Increment retry counter
            no_ep_found_reg <= no_ep_found; // Update no EP found flag
            config_cycle_reg <= config_cycle; // Update config cycle
            bar_count_reg <= bar_count; // Update BAR count
            bar_config_start_reg <= bar_config_start; // Update BAR config start flag
            ep_rom_ptr_reg <= ep_rom_ptr; // Update EP ROM pointer
            rp_rom_ptr_reg <= rp_rom_ptr; // Update RP ROM pointer
            rp_start_reg <= rp_start; // Update RP start flag
            traffic_gen_reg <= traffic_gen; // Update traffic gen flag
            device_detect_done_reg <= device_detect_done; // Update device detect done flag
            write_count_reg <= write_count; // Update write count
            start_processing_reg <= start_processing; // Update start processing flag
            traffic_enable_reg <= traffic_enable; // Update traffic enable flag
            traffic_write_reg <= traffic_write; // Update traffic write flag
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            traffic_count_reg <= '0;
            ep_cfg_count_reg <= '0;
        end else if (link_down) begin
            traffic_count_reg <= '0; 
            ep_cfg_count_reg <= '0;
        end else if (current_state == PROCESS_DATA_RP) begin
            traffic_count_reg <= (TRAFFIC_COUNT_WIDTH)'(TRAFFIC_COUNT); // Reset traffic count when processing RP data
        end else begin
            traffic_count_reg <= traffic_count; // Keep previous value of traffic count
            ep_cfg_count_reg <= ep_cfg_count;        
        end

    end
    /////////////////////////////////////////////////////////////////////


    //////////////////// ADDING BAR ADDR AND CPL DATA ///////////////////////

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            foreach (bar_cpl_data[i]) begin
                bar_cpl_data[i] <= '0; // Reset BAR completion data
            end
            foreach (bar_cpl_addr[i]) begin
                bar_cpl_addr[i] <= '0; // Reset BAR addresses
            end
        end else if (link_down) begin
            foreach (bar_cpl_data[i]) begin
                bar_cpl_data[i] <= '0; // Reset BAR completion data on link down
            end
            foreach (bar_cpl_addr[i]) begin
                bar_cpl_addr[i] <= '0; // Reset BAR addresses on link down
            end
        end else begin
            // Register BAR completion data when valid
            if (completion_received && current_state == WAIT_FOR_COMPLETION && bar_config_start_reg && !start_processing_reg) begin
                bar_cpl_data[bar_count_reg] <= cpl_data; // Store completion data for the current BAR
            end

            // Register BAR address when valid
            if (current_state == BAR_CONFIG2 && !halt && req_ready) begin
                bar_cpl_addr[bar_count_reg] <= ep_cfg_rd_wr_addr; // Store address for the current BAR
            end
        end
    end
    /////////////////////////////////////////////////////////////



    //////////////// CONTROL PATH in STATE MACHINE /////////////////////////
    always_comb begin
        // Default next state
        next_state = current_state;
        retry_counter = retry_counter_reg; 
        no_ep_found = no_ep_found_reg; // Update no EP found flag
        config_cycle = config_cycle_reg; // Update config cycle
        bar_count = bar_count_reg; // Keep previous value of bar_count
        bar_config_start = bar_config_start_reg; // Keep previous value of bar_config_start
        ep_rom_ptr = ep_rom_ptr_reg; // Keep previous value of ep_rom_ptr
        rp_rom_ptr = rp_rom_ptr_reg; // Keep previous value of rp_rom_ptr
        rp_start = rp_start_reg; // Keep previous value of rp_start
        traffic_gen = traffic_gen_reg; // Keep previous value of traffic_gen
        device_detect_done = device_detect_done_reg; // Keep previous value of device_detect_done
        write_count = write_count_reg; // Keep previous value of write_count
        start_processing = start_processing_reg; // Keep previous value of start_processing
        traffic_enable = traffic_enable_reg; // Keep previous value of traffic_enable
        traffic_write = traffic_write_reg; // Keep previous value of traffic_write

        case (current_state)
            IDLE: begin
                if (!no_ep_found_reg & !halt) begin ///keep on retrying device detect? 
                    next_state = DEVICE_DETECT;
                end
                else begin
                    next_state = IDLE; // Stay in IDLE if no conditions met
                end
            end

            DEVICE_DETECT: begin
                    next_state = WAIT_FOR_COMPLETION; // Move to BAR_CONFIG1 state
                    retry_counter = retry_counter + 1; // Increment retry counter
                    config_cycle = 1'b0;
            end

            DETECT_RETRY_WAIT: begin
                // Retry only once the delay has elapsed and the read can actually be sent
                if (detect_retry_cnt == DETECT_RETRY_DELAY && !halt && req_ready)
                    next_state = DEVICE_DETECT;
            end

            BAR_CONFIG1: begin
                bar_config_start = 1; // Set BAR config start flag
                if(NUM_SLOTS == 1 & !config_cycle_reg) begin
                    next_state = BAR_CONFIG1; // Stay in DEVICE_DETECT state for single slot
                    config_cycle = 1'b1; // Set config cycle to 1
                end else begin
                    next_state = BAR_CONFIG2; // Move to BAR_CONFIG1 state
                    config_cycle = 1'b0; // Reset config cycle
                end
            end

            BAR_CONFIG2: begin
                    next_state = WAIT_FOR_COMPLETION; // Move to BAR_CONFIG2 state
            end

            BAR_CONFIG3: begin                    
                if(NUM_SLOTS == 1 & !config_cycle_reg) begin
                    next_state = BAR_CONFIG3; // Stay in BAR_CONFIG3 state for single slot
                    config_cycle = 1'b1; // Set config cycle to 1
                end 
                else if(bar_count_reg < NUM_BAR-1) begin
                    next_state = BAR_CONFIG3; // Move to next BAR config state
                    bar_count = bar_count_reg + 1; // Increment BAR count
                    config_cycle = 1'b0; // Reset config cycle
                end
                else begin
                    next_state = PROCESS_DATA_RP;
                end
            end


            WAIT_FOR_COMPLETION: begin
                if(completion_received) begin 
                    if(rp_start) begin
                        if(rp_config_done) begin
                            next_state = WAIT_FOR_CONFIG_DONE; // Move to WAIT_FOR_CONFIG_DONE state
                        end else begin
                            next_state = PROCESS_DATA_RP; // Move to RP config state
                            rp_rom_ptr = rp_rom_ptr_reg + 1; // Increment RP ROM pointer
                            traffic_write = 1'b1;
                        end
                    end else if (bar_config_start_reg) begin
                        if(bar_count_reg < NUM_BAR-1) begin
                            next_state = BAR_CONFIG1; // Move to BAR_CONFIG1 state
                            bar_count = bar_count_reg + 1; // Increment BAR count
                            ep_rom_ptr = ep_rom_ptr_reg + 1; // Increment EP ROM pointer
                        end
                        else begin
                            next_state = PROCESS_DATA_EP;
                            ep_rom_ptr = ep_rom_ptr_reg + 1; // Increment EP ROM pointer
                            bar_count = 0; // Reset BAR count
                            start_processing = 1'b1; // Start processing BARs
                        end
                    end else if ((cpl_data != 32'hffffffff)) begin 
                        next_state = BAR_CONFIG1; // Move to BAR_CONFIG state
                        ep_rom_ptr = ep_rom_ptr_reg + 1; // Increment EP ROM pointer
                    end else if(retry_counter_reg <= NUM_EP_DETECT_RETRY) begin
                        next_state = IDE_EN ? DETECT_RETRY_WAIT : DEVICE_DETECT; // IDE_EN: wait before retrying device detect
                    end
                    else begin
                        next_state = IDLE; // Move to IDLE state if no conditions met
                        no_ep_found = 1'b1; // Set no EP found flag
                    end
                end
                else begin
                    next_state = WAIT_FOR_COMPLETION; // Stay in WAIT_FOR_COMPLETION state if no completion received
                end
            end

            WAIT_FOR_CONFIG_DONE: begin
                if(overall_config_done) begin
                    if (IDE_EN) begin
                        next_state = WAIT_FOR_GO; // Enumeration/BAR/RP config complete; hold traffic until go
                    end else begin
                        next_state = TRAFFIC_GEN_1;
                        traffic_enable = 1'b1;
                    end
                end else begin
                    next_state = WAIT_FOR_CONFIG_DONE; // Stay in WAIT_FOR_CONFIG_DONE state
                end
            end

            WAIT_FOR_GO: begin
                if(traffic_go) begin
                    next_state = TRAFFIC_GEN_1;
                    traffic_enable = 1'b1;
                end else if(axi_issue_ok) begin
                    next_state = AXI_WAIT; // Service an AXI config access
                end else begin
                    next_state = WAIT_FOR_GO; // Hold until traffic_go
                end
            end

            AXI_WAIT: begin
                if(axi_req_done) begin
                    next_state = axi_ret_done ? DONE : WAIT_FOR_GO;
                end
            end

            PROCESS_DATA_EP: begin
                next_state = PROCESS_DATA_EP; // Stay in PROCESS_DATA_EP state

                if(!halt & req_ready)  begin
                    if(NUM_SLOTS == 1) begin
                        if(!config_cycle_reg && !ep_cfg_rd_wr_type) begin
                            config_cycle = 1'b1; // Set config cycle to 1
                        end else if (ep_config_done) begin
                            next_state = WAIT_FOR_BAR_CALC; // Move to WAIT_FOR_BAR_CALC state
                            config_cycle = 1'b0; // Reset config cycle
                        end else begin
                            config_cycle = 1'b0; // Reset config cycle
                            ep_rom_ptr = ep_rom_ptr_reg + 1; // Increment EP ROM pointer
                        end
                    end else begin
                        if(ep_config_done) begin
                            next_state = WAIT_FOR_BAR_CALC; // Move to WAIT_FOR_BAR_CALC state
                        end else begin
                            ep_rom_ptr = ep_rom_ptr_reg + 1; // Increment EP ROM pointer
                            config_cycle = 1'b0; // Reset config cycle
                        end
                    end
                end
            end

            WAIT_FOR_BAR_CALC:
                if(bar_processing_done) begin
                    next_state = BAR_CONFIG3; // Move to BAR_CONFIG3 state onece all BAR bases calculated
                end else begin
                    next_state = WAIT_FOR_BAR_CALC; // Stay in WAIT_FOR_BAR_CALC state
            end

            PROCESS_DATA_RP: begin
                rp_start = 1'b1; // Set RP start flag
                next_state = WAIT_FOR_COMPLETION;             
            end

            TRAFFIC_GEN_1: begin // Just Initiate everything state
                traffic_gen = 1'b1; // Set traffic gen reg2 flag
                next_state = TRAFFIC_GEN_2; // Move to TRAFFIC_GEN_2 state
            end

            TRAFFIC_GEN_2: begin
                if(traffic_count_reg == 1) begin
                    if(|hdr_np_valid_reg && !halt_reg) begin
                        next_state = halt ? TRAFFIC_GEN_2 : DONE; // Move to DONE state if traffic sent count is 0
                    end
                end
                else if(!halt && traffic_count_reg == 0) begin
                    next_state = DONE; // Move to DONE state if traffic sent count is 0
                end
                else begin
                    next_state = TRAFFIC_GEN_2; // Move back to TRAFFIC_GEN_2 state
                end
            end

            DONE: begin
                next_state = axi_issue_ok ? AXI_WAIT : DONE; // Stay in DONE once all traffic done (AXI config accesses still serviced)
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end
    ///////////////////////////////////////////////////////

    //////////////////// EP and RP CONFIG DONE FLAGS ///////////////////////
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ep_config_done <= '0; // Reset EP config done flag on link down
            rp_config_done <= '0; // Reset RP config done flag on link down
        end
        else if (link_down) begin
            ep_config_done <= '0; // Reset EP config done flag on link down
            rp_config_done <= '0; // Reset RP config done flag on link down
        end
        else begin
            ep_config_done <= ep_config_done ? ep_config_done : ep_rom_ptr == EP_ROM_SIZE - 1;
            rp_config_done <= rp_rom_ptr_reg == RP_ROM_SIZE - 1; // Check if RP config is done
        end
    end
    ///////////////////////////////////////////////////////////////////////



    ///*******************************************************************************/
    ///         SLOT and PL DBI TRANSACTION GEN
    ///*******************************************************************************/


    /////////////// ADD TAG and PIPELINE PKTS ////////////////////////
    // Pipeline stage to register TX_PKT_IF signals
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || link_down) begin
            foreach (tx_pkt_data_reg[i]) begin
                tx_pkt_data_reg[i].pkt_valid <= '0;
                tx_pkt_data_reg[i].pkt_type <= '0;
                tx_pkt_data_reg[i].pkt_addr_data <= '0;
                tx_pkt_data_reg[i].pkt_info <= 2'b00;
                tx_pkt_data_reg[i].pkt_tag <= '0; 
            end

            foreach(tx_pkt_data_reg2[i]) begin
                tx_pkt_data_reg2[i].pkt_valid <= '0;
                tx_pkt_data_reg2[i].pkt_type <= '0;
                tx_pkt_data_reg2[i].pkt_addr_data <= '0;
                tx_pkt_data_reg2[i].pkt_info <= 2'b00;
                tx_pkt_data_reg2[i].pkt_tag <= '0; 
            end
        end else if (!halt) begin
            foreach (tx_pkt_data_reg[i]) begin
                tx_pkt_data_reg[i].pkt_valid <= tx_pkt_data[i].pkt_valid;
                tx_pkt_data_reg[i].pkt_type <= tx_pkt_data[i].pkt_type;
                tx_pkt_data_reg[i].pkt_addr_data <= tx_pkt_data[i].pkt_addr_data;
                tx_pkt_data_reg[i].pkt_info <= tx_pkt_data[i].pkt_info;
                tx_pkt_data_reg[i].pkt_tag <= tx_pkt_data[i].pkt_tag; // Register tag from input data
            end
            foreach(tx_pkt_data_reg2[i]) begin
                tx_pkt_data_reg2[i].pkt_valid <= tx_pkt_data_reg[i].pkt_valid;
                tx_pkt_data_reg2[i].pkt_type <= tx_pkt_data_reg[i].pkt_type;
                tx_pkt_data_reg2[i].pkt_addr_data <= tx_pkt_data_reg[i].pkt_addr_data;
                tx_pkt_data_reg2[i].pkt_info <= tx_pkt_data_reg[i].pkt_info;
                tx_pkt_data_reg2[i].pkt_tag <= (tx_pkt_data_reg[i].pkt_valid && !tx_pkt_data_reg[i].pkt_type && (^tx_pkt_data_reg[i].pkt_info[1:0])) ? 
                                            (tag_id) : tx_pkt_data_reg[i].pkt_tag; // cfg hdr then tag in this cycle, if data hdr then tag from previous cycle
            end
        end 
    end
    //////////////////////////////////////////////////

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tag_to_match <= '0;
        end else if (link_down) begin
            tag_to_match <= '0;
        end else begin
            foreach (tx_pkt_data_reg2[i]) begin
                if (tx_pkt_data_reg2[i].pkt_valid && !tx_pkt_data_reg2[i].pkt_type && (^tx_pkt_data_reg2[i].pkt_info[1:0])) begin
                    tag_to_match <= tx_pkt_data_reg2[i].pkt_tag; // Update tag to match for cfg read header packets
                end
            end
        end
    end

    ///////////////////// SEND TO CHECKER ///////////////////////
    // Send data to checker interface

    // check each tx_pkt_data_reg2 -> if hdr then extract tag, lower address bits and data (mem: tag, cfg: expected_data_reg2?)
    always_comb begin
        // Default values for checker write signals
        cfg_checker_wr_en_wire = '0; // Disable write to checker by default
        cfg_checker_wr_addr_wire = '0; // Default address for checker write
        cfg_checker_wr_data_wire = '0; // Default data for checker write

        mem_checker_wr_en_wire = '0; // Disable write to checker by default
        mem_checker_wr_addr_wire = '0; // Default address for checker write
        mem_checker_wr_data_wire = '0; // Default data for checker write

        // Iterate through each packet in tx_pkt_data_reg2
        foreach (tx_pkt_data_reg2[i]) begin
            // Extract tag, lower address bits and data
            // mem rd: tag, cfg rd: expected_data_reg2?
            if (tx_pkt_data_reg2[i].pkt_valid && !tx_pkt_data_reg2[i].pkt_type && tx_pkt_data_reg2[i].pkt_info[2]) begin
                // Header packet
                if(!(^tx_pkt_data_reg2[i].pkt_info[1:0])) begin
                    // Mem Rd
                    mem_checker_wr_en_wire = 1; // Enable write to checker
                    mem_checker_wr_addr_wire = tx_pkt_data_reg2[i].pkt_tag; // Use tag as address
                    mem_checker_wr_data_wire = {tx_pkt_data_reg2[i].pkt_addr_data[6:0], 32'({'0 , tx_pkt_data_reg2[i].pkt_tag})};
                end
                else if(^tx_pkt_data_reg2[i].pkt_info[1:0]) begin
                    // Cfg Rd
                    cfg_checker_wr_en_wire = 1; // Enable write to checker
                    cfg_checker_wr_addr_wire = tx_pkt_data_reg2[i].pkt_tag; // Use tag as address
                    // for BAR read - expected data is not used - handle in cpl checker - skip BAR address range
                    cfg_checker_wr_data_wire = 32'({'0 , ep_cfg_rd_wr_expected_data_reg2});
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cfg_checker_wr_en <= '0;
            cfg_checker_wr_addr <= '0;
            cfg_checker_wr_data <= '0;

            mem_checker_wr_en <= '0;
            mem_checker_wr_addr <= '0;
            mem_checker_wr_data <= '0;
        end else if (link_down) begin
            cfg_checker_wr_en <= '0;
            cfg_checker_wr_addr <= '0;
            cfg_checker_wr_data <= '0;

            mem_checker_wr_en <= '0;
            mem_checker_wr_addr <= '0;
            mem_checker_wr_data <= '0;
        end else begin
            cfg_checker_wr_en <= cfg_checker_wr_en_wire;
            cfg_checker_wr_addr <= cfg_checker_wr_addr_wire;
            cfg_checker_wr_data <= cfg_checker_wr_data_wire;

            mem_checker_wr_en <= mem_checker_wr_en_wire;
            mem_checker_wr_addr <= mem_checker_wr_addr_wire;
            mem_checker_wr_data <= mem_checker_wr_data_wire;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : blockName
        if (!rst_n) begin
            ep_cfg_rd_wr_expected_data_reg <= '0; // Reset expected data for EP config read/write
            ep_cfg_rd_wr_expected_data_reg2 <= '0; // Reset expected data for EP config read/write
        end else if (link_down) begin
            ep_cfg_rd_wr_expected_data_reg  <= '0; // Reset expected data on link down
            ep_cfg_rd_wr_expected_data_reg2 <= '0; // Reset expected data on link down
        end else begin
            // Normal operation
            ep_cfg_rd_wr_expected_data_reg  <= ep_cfg_rd_wr_expected_data; // Keep previous value of expected data
            ep_cfg_rd_wr_expected_data_reg2 <= ep_cfg_rd_wr_expected_data_reg; // Register expected data for config read/write
        end
    end


    ///////////////////////////////////////////////////////


    ////////// TAG HANDLER -- instantiate at top level with checker//////////

    always_ff @(posedge clk or negedge rst_n ) begin
        if (!rst_n) begin
            tag_id_reg <= '0;
        end else if (link_down) begin
            tag_id_reg <= '0;
        end else if (!halt_reg) begin
            tag_id_reg <= tag_id;
        end
    end

    ////////// TAG HANDLER END//////////


    ////////// TAG req ready register///////////////////////////////
    
    always_ff @(posedge clk or negedge rst_n ) begin
        if (!rst_n) begin
            req_ready_reg <= '0; // Reset request ready register
        end else if (link_down) begin
            req_ready_reg <= '0; // Reset request ready register on link down
        end else if (!halt) begin
            req_ready_reg <= req_ready;
        end
    end




    /////////////////////  DATAPATH   /////////////////////////////////
    always_comb begin
        // Default values for TX_PKT_IF
        foreach (tx_pkt_data[i]) begin
            tx_pkt_data[i].pkt_valid = '0;
            tx_pkt_data[i].pkt_type = '0;
            tx_pkt_data[i].pkt_addr_data = '0;
            tx_pkt_data[i].pkt_info = 3'b000;
            tx_pkt_data[i].pkt_tag = '0; // Default tag value
        end

        // Default values for RP_CFG_IF
        rp_cfg_data_wire.valid = '0;
        rp_cfg_data_wire.addr = '0;
        rp_cfg_data_wire.data = '0;
        rp_cfg_data_wire.cfg_type = '0;
        rp_cfg_data_wire.expected_data = '0;

        final_req_valid = '0; 
        final_req_count = '0; 

        read_enable = '0;
        read_count = 2'b01;
        traffic_count = traffic_count_reg; // Use registered traffic count

        ep_cfg_count = ep_cfg_count_reg; // Use registered EP config read count


        // Route data based on current state
        case (current_state)
            IDLE: begin
                // No data to send in IDLE state
                foreach (tx_pkt_data[i]) begin
                    tx_pkt_data[i].pkt_valid = '0;
                    tx_pkt_data[i].pkt_type = '0;
                    tx_pkt_data[i].pkt_addr_data = '0;
                    tx_pkt_data[i].pkt_info = 3'b000;
                end
                    rp_cfg_data_wire.valid = '0;
                    rp_cfg_data_wire.addr = '0;
                    rp_cfg_data_wire.data = '0;
                    rp_cfg_data_wire.cfg_type = '0;
                    rp_cfg_data_wire.expected_data = '0;

                    final_req_count = 2'b01; // Set final request count
            end

            DEVICE_DETECT: begin
                // Send data to TX_PKT_IF
                    final_req_count = 2'b01; // Set final request count

                    if(!halt & req_ready) begin
                        tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal    
                        tx_pkt_data[0].pkt_type      = 1'b0;  // Type of packet
                        tx_pkt_data[0].pkt_addr_data = ep_cfg_rd_wr_addr; // Address/Data
                        tx_pkt_data[0].pkt_info      = 3'b101; // Info for the packet
                        final_req_valid = 1'b1; // Set final request valid signal
                        ep_cfg_count = ep_cfg_count_reg + 1;
                    end
            end

            BAR_CONFIG1: begin

                final_req_count = 2'b01; // Set final request count

                if (NUM_SLOTS > 1) begin
                    // Send HDR to TX_PKT_IF
                    tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal
                    tx_pkt_data[0].pkt_type      = 1'b0;  // Type of packet // HDR
                    tx_pkt_data[0].pkt_addr_data = ep_cfg_rd_wr_addr; // Address/Data
                    tx_pkt_data[0].pkt_info      = 3'b110; // Info for the packet // CFG WR

                    // Send data to TX_PKT_IF
                    tx_pkt_data[1].pkt_valid     = 1'b1; // Valid signal    
                    tx_pkt_data[1].pkt_type      = 1'b1;  // Type of packet
                    tx_pkt_data[1].pkt_addr_data = ep_cfg_rd_wr_data; // Address/Data
                    tx_pkt_data[1].pkt_info      = 3'b011; // Info for the packet 
                    if(!halt & req_ready) begin
                        final_req_valid = 1'b1; // Set final request valid signal
                    end
                    ep_cfg_count = ep_cfg_count_reg + 1;
                end else begin
                    if (config_cycle_reg == 0) begin
                        // Send HDR in the first cycle
                        tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal
                        tx_pkt_data[0].pkt_type      = 1'b0;  // Type of packet // HDR
                        tx_pkt_data[0].pkt_addr_data = ep_cfg_rd_wr_addr; // Address/Data
                        tx_pkt_data[0].pkt_info      = 3'b110; // Info for the packet // CFG WR
                        if(!halt) begin
                            final_req_valid = 1'b1; // Set final request valid signal
                        end
                        ep_cfg_count = ep_cfg_count_reg + 1;
                    end else if (config_cycle_reg == 1) begin
                        // Send data in the second cycle
                        tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal
                        tx_pkt_data[0].pkt_type      = 1'b1;  // Type of packet
                        tx_pkt_data[0].pkt_addr_data = ep_cfg_rd_wr_data; // Address/Data // Taken from rom
                        tx_pkt_data[0].pkt_info      = 3'b011; // Info for the packet 
                    end
                end
            end
            
            BAR_CONFIG2: begin
                final_req_count = 2'b01; // Set final request count

                if(!halt & req_ready) begin
                    // Send data to TX_PKT_IF
                    tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal
                    tx_pkt_data[0].pkt_type      = 1'b0;  // Type of packet // HDR
                    tx_pkt_data[0].pkt_addr_data = ep_cfg_rd_wr_addr; // Address/Data
                    tx_pkt_data[0].pkt_info      = 3'b101; // Info for the packet // CFG RD
                    final_req_valid = 1'b1; // Set final request valid signal
                    ep_cfg_count = ep_cfg_count_reg + 1; // Increment EP config read count
                end
            end


            BAR_CONFIG3: begin

                final_req_count = 2'b01; // Set final request count

                if (NUM_SLOTS > 1) begin
                    // Send HDR to TX_PKT_IF
                    tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal
                    tx_pkt_data[0].pkt_type      = 1'b0;  // Type of packet // HDR
                    tx_pkt_data[0].pkt_addr_data = bar_cpl_addr[bar_count_reg]; // Address/Data
                    tx_pkt_data[0].pkt_info      = 3'b110; // Info for the packet // CFG WR

                    // Send data to TX_PKT_IF
                    tx_pkt_data[1].pkt_valid     = 1'b1; // Valid signal    
                    tx_pkt_data[1].pkt_type      = 1'b1;  // Type of packet
                    tx_pkt_data[1].pkt_addr_data = bar_bases[bar_count_reg]; // Address/Data
                    tx_pkt_data[1].pkt_info      = 3'b011; // Info for the packet 
                    if(!halt & req_ready) begin
                        final_req_valid = 1'b1; // Set final request valid signal
                    end
                    ep_cfg_count = ep_cfg_count_reg + 1;
                end else begin
                    if (config_cycle_reg == 0) begin
                        // Send HDR in the first cycle
                        tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal
                        tx_pkt_data[0].pkt_type      = 1'b0;  // Type of packet // HDR
                        tx_pkt_data[0].pkt_addr_data = bar_cpl_addr[bar_count_reg]; // Address/Data
                        tx_pkt_data[0].pkt_info      = 3'b110; // Info for the packet // CFG WR
                        if(!halt) begin
                            final_req_valid = 1'b1; // Set final request valid signal
                        end
                        ep_cfg_count = ep_cfg_count_reg + 1;
                    end else if (config_cycle_reg == 1) begin
                        // Send data in the second cycle
                        tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal
                        tx_pkt_data[0].pkt_type      = 1'b1;  // Type of packet
                        tx_pkt_data[0].pkt_addr_data = bar_bases[bar_count_reg]; // Address/Data
                        tx_pkt_data[0].pkt_info      = 3'b011; // Info for the packet 
                    end
                end
            end

            PROCESS_DATA_EP: begin

                final_req_count = 2'b01; // Set final request count

                if (NUM_SLOTS > 1) begin
                    // Send HDR to TX_PKT_IF
                    tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal
                    tx_pkt_data[0].pkt_type      = 1'b0;  // Type of packet // HDR
                    tx_pkt_data[0].pkt_addr_data = ep_cfg_rd_wr_addr; // Address/Data
                    tx_pkt_data[0].pkt_info      = ep_cfg_rd_wr_type ? 3'b101 : 3'b110; // Info for the packet // CFG RD

                    // Send data to TX_PKT_IF
                    if(!ep_cfg_rd_wr_type) begin
                        tx_pkt_data[1].pkt_valid     = 1'b1; // Valid signal
                        tx_pkt_data[1].pkt_type      = 1'b1;  // Type of packet
                        tx_pkt_data[1].pkt_addr_data = ep_cfg_rd_wr_data; // Address/Data
                        tx_pkt_data[1].pkt_info      = 3'b011; // Info for the packet 
                    end

                    if(!halt & req_ready) begin
                        final_req_valid = 1'b1; // Set final request valid signal
                        ep_cfg_count = ep_cfg_count_reg + 1;
                    end     
                end else begin
                    if (config_cycle_reg == 0) begin
                        // Send HDR in the first cycle
                        tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal
                        tx_pkt_data[0].pkt_type      = 1'b0;  // Type of packet // HDR
                        tx_pkt_data[0].pkt_addr_data = ep_cfg_rd_wr_addr; // Address/Data
                        tx_pkt_data[0].pkt_info      = ep_cfg_rd_wr_type ? 3'b101 : 3'b110; // Info for the packet // CFG RD
                        if(!halt) begin
                            final_req_valid = 1'b1; // Set final request valid signal
                            ep_cfg_count = ep_cfg_count_reg + 1;                        
                        end
                    end else if (config_cycle_reg == 1 && !ep_cfg_rd_wr_type) begin
                        // Send data in the second cycle
                        tx_pkt_data[0].pkt_valid     = 1'b1; // Valid signal
                        tx_pkt_data[0].pkt_type      = 1'b1;  // Type of packet
                        tx_pkt_data[0].pkt_addr_data = ep_cfg_rd_wr_data; // Address/Data
                        tx_pkt_data[0].pkt_info      = 3'b011; // Info for the packet 
                    end
                end
            end
            
            TRAFFIC_GEN_1: begin
                if(!traffic_gen_reg) begin
                    final_req_valid = 1'b1; // Initiate tag request
                    final_req_count = 2'b01; // Initiate tag request count
                    read_enable = 1'b1; // Initiate read valid signal
                    read_count = 2'b01; // Set read count to 1 for traffic gen

                end
            end
            
            TRAFFIC_GEN_2: begin 
                for (int i = 0; i < NUM_SLOTS; i++) begin
                    if(!halt_reg) begin
                        traffic_count = (|hdr_np_valid_reg) ? (traffic_count_reg - 1) : traffic_count_reg; // Decrement traffic sent count
                        if(NUM_SLOTS==1) begin
                            read_enable = (|hdr_np_valid_reg); //Read request at the last slot (i.e. NP slot for the current address)
                        end
                        if(NUM_SLOTS==2 || NUM_SLOTS==3) begin
                            read_enable = (|hdr_p_valid_reg);
                        end
                        read_count = 2'b01; // Set read count to 1 for traffic gen

                        final_req_valid = (|end_data_valid_reg && |data_valid_reg);
                        final_req_count = 2'b01;

                        tx_pkt_data[i].pkt_valid = data_valid_reg[i] || hdr_p_valid_reg[i] || hdr_np_valid_reg[i]; // Set valid signal based on data valid or header valid
                        tx_pkt_data[i].pkt_type = (data_valid_reg[i]) ? 1'b1 : 1'b0; // Set type based on data/header valid
                        if(hdr_p_valid_reg[i] || hdr_np_valid_reg[i]) begin
                            if(NUM_SLOTS==1) begin
                                tx_pkt_data[i].pkt_addr_data = read_addr_0[ADDR_WIDTH-1:0];
                            end
                            if(NUM_SLOTS==2) begin
                                tx_pkt_data[i].pkt_addr_data = hdr_np_valid_reg[i] ? read_addr_0_reg[ADDR_WIDTH-1:0] : read_addr_0[ADDR_WIDTH-1:0];
                            end
                            if(NUM_SLOTS==3) begin
                                tx_pkt_data[i].pkt_addr_data = (payload_size_reg == 1) ? read_addr_0[ADDR_WIDTH-1:0] : (hdr_np_valid_reg[i] ? read_addr_0_reg[ADDR_WIDTH-1:0] : read_addr_0[ADDR_WIDTH-1:0]);
                            end
                            tx_pkt_data[i].pkt_info = (hdr_np_valid_reg[i]) ?  {1'b1, {2{is_all_64bit_bar}}} : {1'b0, {2{is_all_64bit_bar}}}; //  memory type bit Mem32 - 2'b00  ->  MEM info packet  // easier logic? // Replicate the memory type bit Mem64 - 2'b11
                            tx_pkt_data[i].pkt_tag = (hdr_np_valid_reg[i]) ? (i==0 ? tag_id_reg : tag_id) : '0; // Set tag based on NP header valid
                        end else begin
                            tx_pkt_data[i].pkt_addr_data = 64'({'0, tag_id});
                            tx_pkt_data[i].pkt_info = {2'b10, end_data_valid_reg[i]}; // Set info based on end data valid
                        end
                    end
                    else begin
                        tx_pkt_data[i].pkt_valid = tx_pkt_data_halt[i].pkt_valid;
                        tx_pkt_data[i].pkt_type = tx_pkt_data_halt[i].pkt_type;
                        tx_pkt_data[i].pkt_addr_data = tx_pkt_data_halt[i].pkt_addr_data;
                        tx_pkt_data[i].pkt_info = tx_pkt_data_halt[i].pkt_info;
                        tx_pkt_data[i].pkt_tag = tx_pkt_data_halt[i].pkt_tag;
                    end
                end
            end

            PROCESS_DATA_RP: begin
                // Send data to RP_CFG_IF
                rp_cfg_data_wire.valid       =  cfg_rd_wr_valid; // Valid signal
                rp_cfg_data_wire.addr        =  cfg_rd_wr_addr ;  // Address for config read/write
                rp_cfg_data_wire.data        =  cfg_rd_wr_data ;  // Data for config write
                rp_cfg_data_wire.cfg_type    =  cfg_rd_wr_type ; // Type of config operation (read/write)
                rp_cfg_data_wire.expected_data = cfg_rd_wr_expected_data;

                foreach (tx_pkt_data[i]) begin
                    tx_pkt_data[i].pkt_valid = '0;
                    tx_pkt_data[i].pkt_type = '0;
                    tx_pkt_data[i].pkt_addr_data = '0;
                    tx_pkt_data[i].pkt_info = 2'b00;
                end
            end

            default: begin
                // Default values for both interfaces
                foreach (tx_pkt_data[i]) begin
                    tx_pkt_data[i].pkt_valid = '0;
                    tx_pkt_data[i].pkt_type = '0;
                    tx_pkt_data[i].pkt_addr_data = '0;
                    tx_pkt_data[i].pkt_info = 2'b00;
                end

                rp_cfg_data_wire.valid = '0;
                rp_cfg_data_wire.addr = '0;
                rp_cfg_data_wire.data = '0;
                rp_cfg_data_wire.cfg_type = '0;
                rp_cfg_data_wire.expected_data = '0;
            end
        endcase

        // AXI config bridge request: one config RD/WR TLP (header slot 0, data slot 1 for a write)
        if (axi_issue_ok) begin
            tx_pkt_data[0].pkt_valid     = 1'b1;
            tx_pkt_data[0].pkt_type      = 1'b0;  // HDR
            tx_pkt_data[0].pkt_addr_data = 64'(axi_req_addr);
            tx_pkt_data[0].pkt_info      = axi_req_wr ? 3'b110 : 3'b101; // CFG WR : CFG RD
            if (axi_req_wr && NUM_SLOTS > 1) begin
                tx_pkt_data[1].pkt_valid     = 1'b1;
                tx_pkt_data[1].pkt_type      = 1'b1;  // DATA
                tx_pkt_data[1].pkt_addr_data = 64'(axi_req_wdata);
                tx_pkt_data[1].pkt_info      = 3'b011;
            end
            final_req_valid = 1'b1;
            final_req_count = 2'b01;
            ep_cfg_count    = ep_cfg_count_reg + 1;
        end
    end


    ///////////////////////////////////////////////////////
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_pkt_data_halt <= '{default: '0}; // Reset TX_PKT_IF data on link down
            halt_reg <= 1'b0; // Reset halt register
        end else if (link_down) begin
            tx_pkt_data_halt <= '{default: '0}; // Reset TX_PKT_IF data on link down
            halt_reg <= 1'b0; // Reset halt register
        end else begin
            foreach (tx_pkt_data[i]) begin
                tx_pkt_data_halt[i] <= tx_pkt_data[i]; // Update TX_PKT_IF data when not halted
            end
            halt_reg <= halt; // Update halt register
        end
    end

    ///////////////////// RP CONFIG REG //////////////////////////////////////////////
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rp_cfg_data <= '{default: '0};
        end else if (link_down) begin
            rp_cfg_data <= '{default: '0};
        end else begin
            rp_cfg_data <= rp_cfg_data_wire;
        end
    end
    ////////////////////////////////////////////////////////////////////////////////////

    ///////////////////// VALID GEN USED IN TRAFFIC GEN /////////////////////////////////
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hdr_p_valid_reg <= '0; // Reset header posted valid register
            hdr_np_valid_reg <= '0; // Reset header non-posted valid register
            end_data_valid_reg <= '0; // Reset end data valid register
            data_valid_reg <= '0; // Reset data valid register
        end else if (link_down) begin
            hdr_p_valid_reg <= '0; // Reset header posted valid register on link down
            hdr_np_valid_reg <= '0; // Reset header non-posted valid register on link down
            end_data_valid_reg <= '0; // Reset end data valid register on link down
            data_valid_reg <= '0; // Reset data valid register on link down
        end else begin
            // Register header posted valid, non-posted valid, end data valid and data valid signals
            hdr_p_valid_reg <= hdr_p_valid; // Register header posted valid
            hdr_np_valid_reg <= hdr_np_valid; // Register header non-posted valid
            end_data_valid_reg <= end_data_valid; // Register end data valid
            data_valid_reg <= data_valid; // Register data valid
        end
    end
    ///////////////////////////////////////////////////////////////////////////////

    ///////////// TRAFFIC VALID GENERATION //////////////
        traffic_valid_generator #(
            .MAX_PAYLOAD_SIZE(MAX_PAYLOAD_SIZE),
            .NUM_SLOTS(NUM_SLOTS),
            .TAG_COUNT(TAG_COUNT),
            .TRAFFIC_COUNT(TRAFFIC_COUNT),
            .ACTUAL_PAYLOAD_SIZE_BYTE(ACTUAL_PAYLOAD_SIZE_BYTE)
        ) traffic_gen_inst (
            .clk(clk),
            .rst_n(rst_n),
            .link_down(link_down),
            .halt(halt),
            .free_tag_count(free_tag_count),
            .traffic_enable(traffic_enable),
            .traffic_count(TRAFFIC_COUNT),
            .hdr_p_valid(hdr_p_valid),
            .hdr_np_valid(hdr_np_valid),
            .end_data_valid(end_data_valid),
            .data_valid(data_valid)
        );

    ///////////////////////////////////////////////////


    ///*******************************************************************************/
    ///         ADDRESS GENERATION MEMORY TRAFFIC 
    ///*******************************************************************************/

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_addr_0_reg <= '0; // Reset read address 0 register on link down
        end else if (link_down) begin
            read_addr_0_reg <= '0; // Reset read address 0 register on link down
        end else if (!halt_reg) begin
            read_addr_0_reg <= read_addr_0; // Update read address 0 register
        end else begin
            read_addr_0_reg <= read_addr_0_reg; // Maintain current value if halted
        end
    end


    address_gen #(
            .ADDR_WIDTH(ADDR_WIDTH),
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_BUF_DEPTH(ADDR_BUF_DEPTH),
            .NUM_BAR(NUM_BAR),
            .MAX_PAYLOAD_SIZE_BYTE(MAX_PAYLOAD_SIZE_BYTE),
            .DW_SIZE(DW_SIZE),
            .TRAFFIC_COUNT(TRAFFIC_COUNT),
            .ACTUAL_PAYLOAD_SIZE_BYTE(ACTUAL_PAYLOAD_SIZE_BYTE)
    ) addr_gen_inst (
            .clk(clk),
            .rst_n(rst_n),
            .link_down(link_down),
            .halt(halt),
            .traffic_write(traffic_write_reg),
            .traffic_count(TRAFFIC_COUNT_WIDTH'((TRAFFIC_COUNT))),
            .read_addr_0(read_addr_0),
            .read_enable(read_enable),
            .read_count(read_count),
            .is_all_64bit_bar(is_all_64bit_bar),
            .is_64bit_bar(is_64bit_bar),
            .bar_bases(bar_bases),
            .bar_sizes(bar_sizes),
            .buffer_empty(buffer_empty),
            .buffer_full(buffer_full),
            .bar_processing_done(bar_processing_done)
        );




    ///*******************************************************************************/
    ///         ADDRESS GENERATION CONFIG 
    ///*******************************************************************************/

    initial begin
        $readmemh("../mem/ep_rom_addr.hex", ep_rom_addr_rom);   // Load addresses from ep_rom
        $readmemh("../mem/ep_rom_data.hex", ep_rom_data_rom);   // Load data from ep_rom
        $readmemh("../mem/ep_rom_type.hex", ep_rom_type_rom);   // Load types from ep_rom
        $readmemh("../mem/ep_rom_expected_data.hex", ep_rom_expected_data_rom); // Load expected data from ep_rom

        if(RP_CTRL1)
            $readmemh("../mem/rp_rom_addr_ctrl1.hex", rp_rom_addr_rom); // Load addresses for rp_rom_*
        else if (RP_CTRL0)
            $readmemh("../mem/rp_rom_addr_ctrl0.hex", rp_rom_addr_rom); // Load addresses for rp_rom_*
        
        $readmemh("../mem/rp_rom_data.hex", rp_rom_data_rom); // Load data for rp_rom_*
        $readmemh("../mem/rp_rom_type.hex", rp_rom_type_rom); // Load types for rp_rom_*
        $readmemh("../mem/rp_rom_expected_data.hex", rp_rom_expected_data_rom); // Load expected data for rp_rom_*
    end

    always_comb begin
        for (int i = 0; i < EP_ROM_SIZE; i++) begin
            ep_rom_addr[i] = ep_rom_addr_rom[i];
            ep_rom_data[i] = ep_rom_data_rom[i];
            ep_rom_type[i] = ep_rom_type_rom[i];
            ep_rom_expected_data[i] = ep_rom_expected_data_rom[i];
        end
    end

    always_comb begin
        for (int i = 0; i < RP_ROM_SIZE; i++) begin
            rp_rom_addr[i] = rp_rom_addr_rom[i];
            rp_rom_data[i] = rp_rom_data_rom[i];
            rp_rom_type[i] = rp_rom_type_rom[i];
            rp_rom_expected_data[i] = rp_rom_expected_data_rom[i];
        end
    end

    always_comb begin
        cfg_rd_wr_valid = '0;
        cfg_rd_wr_addr = '0;
        cfg_rd_wr_data = '0;
        cfg_rd_wr_type = 1'b0; // Default to no operation
        cfg_rd_wr_expected_data = '0;

        if(rp_config_done || !rst_n) begin
            cfg_rd_wr_valid         = 1'b0;
            cfg_rd_wr_addr          = '0; // Reset address for RP config
            cfg_rd_wr_data          = '0; // Reset data for RP config
            cfg_rd_wr_type          = 1'b0; // Reset type for RP config
            cfg_rd_wr_expected_data = '0; // Reset expected data for RP config
        end else if(current_state == PROCESS_DATA_RP) begin
            cfg_rd_wr_valid         = 1'b1;
            cfg_rd_wr_addr          = rp_rom_addr[rp_rom_ptr_reg]; // Get address from RP ROM
            cfg_rd_wr_data          = rp_rom_data[rp_rom_ptr_reg]; // Get data from RP ROM
            cfg_rd_wr_type          = rp_rom_type[rp_rom_ptr_reg]; // Get type from RP ROM
            cfg_rd_wr_expected_data = rp_rom_expected_data[rp_rom_ptr_reg]; // Get expected data from RP ROM
        end
    end

    always_comb begin
        ep_cfg_rd_wr_valid = '0;
        ep_cfg_rd_wr_addr = '0;
        ep_cfg_rd_wr_data = '0;
        ep_cfg_rd_wr_type = 1'b0; // Default to no operation
        ep_cfg_rd_wr_expected_data = '0;


        if(!stop_ep_rom_read) begin
            ep_cfg_rd_wr_valid         = 1'b1;
            ep_cfg_rd_wr_addr          = ep_rom_addr[ep_rom_ptr_reg]; // Get address from EP ROM
            ep_cfg_rd_wr_data          = ep_rom_data[ep_rom_ptr_reg]; // Get data from EP ROM
            ep_cfg_rd_wr_type          = ep_rom_type[ep_rom_ptr_reg]; // Get type from EP ROM
            ep_cfg_rd_wr_expected_data = ep_rom_expected_data[ep_rom_ptr_reg]; // Get expected data for EP config
        end else begin
            ep_cfg_rd_wr_valid         = 1'b0;
            ep_cfg_rd_wr_addr          = '0; // Reset address for EP config
            ep_cfg_rd_wr_data          = '0; // Reset data for EP config
            ep_cfg_rd_wr_type          = 1'b0; // Reset type for EP config
            ep_cfg_rd_wr_expected_data = '0; // Reset expected data for EP config
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stop_ep_rom_read <= 1'b0; // Reset stop EP ROM read signal
        end else if (link_down) begin
            stop_ep_rom_read <= 1'b0; // Reset stop EP ROM read signal on link down
        end else if (!halt) begin
            stop_ep_rom_read <= stop_ep_rom_read ? stop_ep_rom_read : (current_state == WAIT_FOR_BAR_CALC);
        end
    end

endmodule