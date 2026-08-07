
//==============================================================================
// File        : rtddma_aguboundschk.v
// Project     : RTD-DMA
//------------------------------------------------------------------------------
// Description :
// Deterministic AGU bounds and overflow checker.
//
// Responsibilities:
// - Source/Destination range checking
// - Address overflow detection
// - Wrap detection
// - Gather/scatter legality
// - Transfer size legality
// - Burst containment validation
// - 4KB crossing protection
// - Deterministic safety containment
//
// Safety:
// - Parallel safety checking
// - No speculative approval
// - SEU-safe fail-close defaults
// - No tasks/functions
// - No inferred latches
//
//==============================================================================
`timescale 1ns/1ps
`include "rtddmaparams.vh"
`include "rtddmafaultcodes.vh"
`include "rtddmaagudefs.vh"

module rtddma_aguboundschk
(
    input  wire                                     clk,
    input  wire                                     rst_n,

    //--------------------------------------------------------------------------
    // CONTROL
    //--------------------------------------------------------------------------

    input  wire                                     start_i,
    input  wire                                     clr_fault_i,

    //--------------------------------------------------------------------------
    // ADDRESS INPUTS
    //--------------------------------------------------------------------------

    input  wire                                     addr_valid_i,

    input  wire [39:0]                              src_addr_i,
    input  wire [39:0]                              dst_addr_i,

    input  wire [39:0]                              src_end_addr_i,
    input  wire [39:0]                              dst_end_addr_i,

    //--------------------------------------------------------------------------
    // REGION LIMITS
    //--------------------------------------------------------------------------

    input  wire [39:0]                              src_region_base_i,
    input  wire [39:0]                              src_region_limit_i,

    input  wire [39:0]                              dst_region_base_i,
    input  wire [39:0]                              dst_region_limit_i,

    //--------------------------------------------------------------------------
    // TRANSFER INFO
    //--------------------------------------------------------------------------

    input  wire [15:0]                              burst_bytes_i,
    input  wire [1:0]                               addr_mode_i,

    input  wire                                     gather_enable_i,
    input  wire                                     scatter_enable_i,

    //--------------------------------------------------------------------------
    // OUTPUTS
    //--------------------------------------------------------------------------

    output reg                                      bounds_valid_o,
    output reg                                      bounds_pass_o,

    //--------------------------------------------------------------------------
    // FAULTS
    //--------------------------------------------------------------------------

    output reg                                      fault_valid_o,
    output reg [7:0]                                fault_code_o,
    output reg [31:0]                               fault_info_o
);

///////////////////////////////////////////////////////////////////////////////
// INTERNALS
///////////////////////////////////////////////////////////////////////////////

reg [2:0] state_q;
reg [2:0] state_n;

///////////////////////////////////////////////////////////////////////////////
// PARALLEL SAFETY CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_src_underflow;
wire chk_src_overflow;

wire chk_dst_underflow;
wire chk_dst_overflow;

wire chk_src_wrap;
wire chk_dst_wrap;

wire chk_4kb_cross;

wire chk_zero_transfer;

wire chk_gather_region;
wire chk_scatter_region;

wire chk_illegal_state;

///////////////////////////////////////////////////////////////////////////////
// SOURCE REGION CHECKS
///////////////////////////////////////////////////////////////////////////////

assign chk_src_underflow =
(
    src_addr_i < src_region_base_i
);

assign chk_src_overflow =
(
    src_end_addr_i > src_region_limit_i
);

///////////////////////////////////////////////////////////////////////////////
// DESTINATION REGION CHECKS
///////////////////////////////////////////////////////////////////////////////

assign chk_dst_underflow =
(
    dst_addr_i < dst_region_base_i
);

assign chk_dst_overflow =
(
    dst_end_addr_i > dst_region_limit_i
);

///////////////////////////////////////////////////////////////////////////////
// WRAP DETECTION
///////////////////////////////////////////////////////////////////////////////

assign chk_src_wrap =
(
    src_end_addr_i < src_addr_i
);

assign chk_dst_wrap =
(
    dst_end_addr_i < dst_addr_i
);

///////////////////////////////////////////////////////////////////////////////
// 4KB CROSSING
///////////////////////////////////////////////////////////////////////////////

wire [12:0] src_4kb_sum;
wire [12:0] dst_4kb_sum;

assign src_4kb_sum =
    src_addr_i[11:0] + burst_bytes_i;

assign dst_4kb_sum =
    dst_addr_i[11:0] + burst_bytes_i;

assign chk_4kb_cross =
(
    (src_4kb_sum > 13'd4096) ||
    (dst_4kb_sum > 13'd4096)
);

///////////////////////////////////////////////////////////////////////////////
// ZERO TRANSFER
///////////////////////////////////////////////////////////////////////////////

assign chk_zero_transfer =
(
    burst_bytes_i == 16'd0
);

///////////////////////////////////////////////////////////////////////////////
// GATHER / SCATTER
///////////////////////////////////////////////////////////////////////////////

assign chk_gather_region =
(
    gather_enable_i &&
    (
        (src_addr_i < src_region_base_i) ||
        (src_end_addr_i > src_region_limit_i)
    )
);

assign chk_scatter_region =
(
    scatter_enable_i &&
    (
        (dst_addr_i < dst_region_base_i) ||
        (dst_end_addr_i > dst_region_limit_i)
    )
);

///////////////////////////////////////////////////////////////////////////////
// ILLEGAL FSM STATE
///////////////////////////////////////////////////////////////////////////////

assign chk_illegal_state =
(
    (state_q != `RTDDMA_AGU_ST_IDLE)   &&
    (state_q != `RTDDMA_AGU_ST_ACTIVE) &&
    (state_q != `RTDDMA_AGU_ST_DONE)   &&
    (state_q != `RTDDMA_AGU_ST_FAULT)
);

///////////////////////////////////////////////////////////////////////////////
// GLOBAL FAULT
///////////////////////////////////////////////////////////////////////////////

wire any_fault;

assign any_fault =
       chk_src_underflow
    || chk_src_overflow
    || chk_dst_underflow
    || chk_dst_overflow
    || chk_src_wrap
    || chk_dst_wrap
    || chk_4kb_cross
    || chk_zero_transfer
    || chk_gather_region
    || chk_scatter_region
    || chk_illegal_state;

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    state_n = state_q;

    case (state_q)

        //----------------------------------------------------------------------
        // IDLE
        //----------------------------------------------------------------------

        `RTDDMA_AGU_ST_IDLE:
        begin

            if (addr_valid_i) begin

                if (any_fault)
                    state_n = `RTDDMA_AGU_ST_FAULT;
                else
                    state_n = `RTDDMA_AGU_ST_ACTIVE;
            end
        end

        //----------------------------------------------------------------------
        // ACTIVE
        //----------------------------------------------------------------------

        `RTDDMA_AGU_ST_ACTIVE:
        begin

            if (any_fault)
                state_n = `RTDDMA_AGU_ST_FAULT;
            else
                state_n = `RTDDMA_AGU_ST_DONE;
        end

        //----------------------------------------------------------------------
        // DONE
        //----------------------------------------------------------------------

        `RTDDMA_AGU_ST_DONE:
        begin
            state_n = `RTDDMA_AGU_ST_IDLE;
        end

        //----------------------------------------------------------------------
        // FAULT
        //----------------------------------------------------------------------

        `RTDDMA_AGU_ST_FAULT:
        begin

            if (clr_fault_i)
                state_n = `RTDDMA_AGU_ST_IDLE;
        end

        //----------------------------------------------------------------------
        // DEFAULT
        //----------------------------------------------------------------------

        default:
        begin
            state_n = `RTDDMA_AGU_ST_FAULT;
        end

    endcase
end

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state_q <= `RTDDMA_AGU_ST_IDLE;

        bounds_valid_o <= 1'b0;
        bounds_pass_o  <= 1'b0;

        fault_valid_o  <= 1'b0;
        fault_code_o   <= `RTDDMA_FAULT_NONE;
        fault_info_o   <= 32'd0;

    end
    else begin

        state_q <= state_n;

        bounds_valid_o <= 1'b0;
        bounds_pass_o  <= 1'b0;

        case (state_q)

            //------------------------------------------------------------------
            // IDLE
            //------------------------------------------------------------------

            `RTDDMA_AGU_ST_IDLE:
            begin

                if (addr_valid_i && !any_fault) begin

                    bounds_valid_o <= 1'b1;
                    bounds_pass_o  <= 1'b1;

                end
            end

            //------------------------------------------------------------------
            // ACTIVE
            //------------------------------------------------------------------

            `RTDDMA_AGU_ST_ACTIVE:
            begin

                bounds_valid_o <= 1'b1;

                if (!any_fault)
                    bounds_pass_o <= 1'b1;
                else
                    bounds_pass_o <= 1'b0;
            end

            //------------------------------------------------------------------
            // DONE
            //------------------------------------------------------------------

            `RTDDMA_AGU_ST_DONE:
            begin

                bounds_valid_o <= 1'b0;
                bounds_pass_o  <= 1'b0;

            end

            //------------------------------------------------------------------
            // FAULT
            //------------------------------------------------------------------

            `RTDDMA_AGU_ST_FAULT:
            begin

                fault_valid_o <= 1'b1;

                bounds_valid_o <= 1'b1;
                bounds_pass_o  <= 1'b0;

                //----------------------------------------------------------------
                // PRIORITIZED FAULT CLASSIFICATION
                //----------------------------------------------------------------

                if (chk_src_underflow)
                    fault_code_o <= `RTDDMA_FAULT_MPU_REGION;

                else if (chk_src_overflow)
                    fault_code_o <= `RTDDMA_FAULT_MPU_REGION;

                else if (chk_dst_underflow)
                    fault_code_o <= `RTDDMA_FAULT_MPU_REGION;

                else if (chk_dst_overflow)
                    fault_code_o <= `RTDDMA_FAULT_MPU_REGION;

                else if (chk_src_wrap)
                    fault_code_o <= `RTDDMA_FAULT_AGU_ADDR_WRAP;

                else if (chk_dst_wrap)
                    fault_code_o <= `RTDDMA_FAULT_AGU_ADDR_WRAP;

                else if (chk_4kb_cross)
                    fault_code_o <= `RTDDMA_FAULT_MPU_BURST;

                else if (chk_zero_transfer)
                    fault_code_o <= `RTDDMA_FAULT_INTERNAL_UNDERFLOW;

                else if (chk_gather_region)
                    fault_code_o <= `RTDDMA_FAULT_AGU_GATHER_OOB;

                else if (chk_scatter_region)
                    fault_code_o <= `RTDDMA_FAULT_AGU_SCATTER_OOB;

                else
                    fault_code_o <= `RTDDMA_FAULT_FSM_ILLEGAL_STATE;

                //----------------------------------------------------------------
                // FAULT INFO
                //----------------------------------------------------------------

                if
                (
                    chk_src_underflow ||
                    chk_src_overflow  ||
                    chk_src_wrap
                )
                    fault_info_o <= src_addr_i[31:0];

                else
                    fault_info_o <= dst_addr_i[31:0];

                //----------------------------------------------------------------
                // CLEAR
                //----------------------------------------------------------------

                if (clr_fault_i) begin

                    fault_valid_o <= 1'b0;
                    fault_code_o  <= `RTDDMA_FAULT_NONE;
                    fault_info_o  <= 32'd0;

                end
            end
        endcase
    end
end

endmodule

