
//==============================================================================
// File        : rtddma_aguburstplan.v
// Project     : RTD-DMA
//------------------------------------------------------------------------------
// Description :
// Deterministic AXI burst planner.
//
// Responsibilities:
// - Convert AGU element stream into legal AXI bursts
// - Enforce deterministic burst boundaries
// - Prevent illegal 4KB crossings
// - Enforce ASIL-D bounded burst semantics
// - Prevent burst overruns
// - Align burst planning with outstanding limits
// - Support FIXED / INCR bursts
// - No speculative burst issue
//
// Safety:
// - Parallel legality checking
// - Immediate containment on illegal plan
// - No inferred latches
// - No tasks/functions
//
//==============================================================================
`timescale 1ns/1ps
`include "rtddmaparams.vh"
`include "rtddmafaultcodes.vh"
`include "rtddmaagudefs.vh"

module rtddma_aguburstplan
(
    input  wire                                     clk,
    input  wire                                     rst_n,

    //--------------------------------------------------------------------------
    // CONTROL
    //--------------------------------------------------------------------------

    input  wire                                     start_i,
    input  wire                                     stop_i,
    input  wire                                     clr_fault_i,

    //--------------------------------------------------------------------------
    // AGU INPUT
    //--------------------------------------------------------------------------

    input wire                                      addr_valid_i,
    
    output wire                                     addr_ready_o,
    input  wire [39:0]                              src_addr_i,
    input  wire [39:0]                              dst_addr_i,

    input  wire [3:0]                               burst_len_i,
    input  wire [1:0]                               burst_type_i,

    input  wire [1:0]                               src_width_i,
    input  wire [1:0]                               dst_width_i,

    input  wire [15:0]                              x_remaining_i,

    //--------------------------------------------------------------------------
    // ISSUE TRACKING
    //--------------------------------------------------------------------------

    input  wire [3:0]                               outstanding_cnt_i,
    input  wire                                     issue_ack_i,

    //--------------------------------------------------------------------------
    // OUTPUT
    //--------------------------------------------------------------------------

    output reg                                      burst_valid_o,

    output reg [39:0]                               burst_src_addr_o,
    output reg [39:0]                               burst_dst_addr_o,

    output reg [7:0]                                axi_arlen_o,
    output reg [7:0]                                axi_awlen_o,

    output reg [2:0]                                axi_arsize_o,
    output reg [2:0]                                axi_awsize_o,

    output reg [1:0]                                axi_arburst_o,
    output reg [1:0]                                axi_awburst_o,

    output reg [15:0]                               burst_bytes_o,

    //--------------------------------------------------------------------------
    // STATUS
    //--------------------------------------------------------------------------

    output reg                                      planner_busy_o,

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

reg [15:0] elem_bytes_q;
reg [15:0] burst_beats_q;
reg [15:0] total_burst_bytes_q;

wire burst_load;
wire burst_pop;

assign addr_ready_o =
       (state_q == `RTDDMA_AGU_ST_IDLE)
    || ((state_q == `RTDDMA_AGU_ST_ACTIVE) && issue_ack_i);

assign burst_load =
    addr_valid_i && addr_ready_o;

assign burst_pop =
    burst_valid_o && issue_ack_i;

///////////////////////////////////////////////////////////////////////////////
// WIDTH DECODER
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    case (src_width_i)

        2'b00: elem_bytes_q = 16'd1;
        2'b01: elem_bytes_q = 16'd2;
        2'b10: elem_bytes_q = 16'd4;
        2'b11: elem_bytes_q = 16'd8;

        default:
            elem_bytes_q = 16'd1;

    endcase
end

///////////////////////////////////////////////////////////////////////////////
// BURST PLANNER
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    if (x_remaining_i >= burst_len_i)
        burst_beats_q = burst_len_i;
    else
        burst_beats_q = x_remaining_i;

    total_burst_bytes_q =
        burst_beats_q * elem_bytes_q;
end

///////////////////////////////////////////////////////////////////////////////
// PARALLEL SAFETY CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_4kb_cross;
wire chk_zero_burst;
wire chk_burst_overflow;
wire chk_outstanding_overflow;
wire chk_illegal_burst;
wire chk_illegal_state;

wire [12:0] src_4kb_end;
wire [12:0] dst_4kb_end;

assign src_4kb_end =
    src_addr_i[11:0] + total_burst_bytes_q;

assign dst_4kb_end =
    dst_addr_i[11:0] + total_burst_bytes_q;

assign chk_4kb_cross =
(
    src_4kb_end > 13'd4096 ||
    dst_4kb_end > 13'd4096
);

assign chk_zero_burst =
(
    burst_beats_q == 16'd0
);

assign chk_burst_overflow =
(
    total_burst_bytes_q > 16'd4096
);

assign chk_outstanding_overflow =
(
    outstanding_cnt_i >= `RTDDMA_MAX_OUTSTANDING
);

assign chk_illegal_burst =
(
    (burst_len_i == 4'd0)  ||
    (burst_len_i > 4'd15)
);

assign chk_illegal_state =
(
    (state_q != `RTDDMA_AGU_ST_IDLE)   &&
    (state_q != `RTDDMA_AGU_ST_ACTIVE) &&
    (state_q != `RTDDMA_AGU_ST_DONE)   &&
    (state_q != `RTDDMA_AGU_ST_ABORT)  &&
    (state_q != `RTDDMA_AGU_ST_FAULT)
);

wire any_fault;

assign any_fault =
       chk_4kb_cross
    || chk_zero_burst
    || chk_burst_overflow
    || chk_outstanding_overflow
    || chk_illegal_burst
    || chk_illegal_state;

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    state_n = state_q;

    case (state_q)

        `RTDDMA_AGU_ST_IDLE:
        begin

            if (burst_load) begin

                if (any_fault)
                    state_n = `RTDDMA_AGU_ST_FAULT;
                else
                    state_n = `RTDDMA_AGU_ST_ACTIVE;
            end
        end

         
       `RTDDMA_AGU_ST_ACTIVE:
begin
    if (stop_i)
        state_n = `RTDDMA_AGU_ST_ABORT;

    else if (any_fault)
        state_n = `RTDDMA_AGU_ST_FAULT;

    // Old burst accepted, but a replacement is also available.
    else if (burst_pop && burst_load)
        state_n = `RTDDMA_AGU_ST_ACTIVE;

    // Old burst accepted and no replacement is available.
    else if (burst_pop)
        state_n = `RTDDMA_AGU_ST_DONE;
end

        `RTDDMA_AGU_ST_DONE:
        begin
            state_n = `RTDDMA_AGU_ST_IDLE;
        end

        `RTDDMA_AGU_ST_ABORT:
        begin
            state_n = `RTDDMA_AGU_ST_IDLE;
        end

        `RTDDMA_AGU_ST_FAULT:
        begin

            if (clr_fault_i)
                state_n = `RTDDMA_AGU_ST_IDLE;
        end

        default:
        begin
            state_n = `RTDDMA_AGU_ST_FAULT;
        end

    endcase
end

///////////////////////////////////////////////////////////////////////////////
// OUTPUTS / REGISTERS
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state_q <= `RTDDMA_AGU_ST_IDLE;

        burst_valid_o      <= 1'b0;

        burst_src_addr_o   <= 40'd0;
        burst_dst_addr_o   <= 40'd0;

        axi_arlen_o        <= 8'd0;
        axi_awlen_o        <= 8'd0;

        axi_arsize_o       <= 3'd0;
        axi_awsize_o       <= 3'd0;

        axi_arburst_o      <= 2'd0;
        axi_awburst_o      <= 2'd0;

        burst_bytes_o      <= 16'd0;

        planner_busy_o     <= 1'b0;

        fault_valid_o      <= 1'b0;
        fault_code_o       <= `RTDDMA_FAULT_NONE;
        fault_info_o       <= 32'd0;

    end
    else begin

        state_q <= state_n;


        case (state_q)

            //------------------------------------------------------------------
            // IDLE
            //------------------------------------------------------------------

            `RTDDMA_AGU_ST_IDLE:
            begin

                planner_busy_o <= 1'b0;

                if (burst_load && !any_fault) begin

                    planner_busy_o <= 1'b1;
		    burst_valid_o  <= 1'b1;

                    burst_src_addr_o <= src_addr_i;
                    burst_dst_addr_o <= dst_addr_i;

                    axi_arlen_o <= burst_beats_q - 1'b1;
                    axi_awlen_o <= burst_beats_q - 1'b1;

                    case (src_width_i)

                        2'b00: axi_arsize_o <= 3'd0;
                        2'b01: axi_arsize_o <= 3'd1;
                        2'b10: axi_arsize_o <= 3'd2;
                        2'b11: axi_arsize_o <= 3'd3;

                        default:
                            axi_arsize_o <= 3'd0;

                    endcase

                    case (dst_width_i)

                        2'b00: axi_awsize_o <= 3'd0;
                        2'b01: axi_awsize_o <= 3'd1;
                        2'b10: axi_awsize_o <= 3'd2;
                        2'b11: axi_awsize_o <= 3'd3;

                        default:
                            axi_awsize_o <= 3'd0;

                    endcase

                    axi_arburst_o <= burst_type_i;
                    axi_awburst_o <= burst_type_i;

                    burst_bytes_o <= total_burst_bytes_q;
                end
		else begin
               burst_valid_o <= 1'b0;
                     end
            end

            //------------------------------------------------------------------
            // ACTIVE
            //------------------------------------------------------------------

       `RTDDMA_AGU_ST_ACTIVE:
begin
    planner_busy_o <= 1'b1;

    // Current burst accepted and next input accepted in the same cycle.
    if (burst_pop && burst_load && !any_fault) begin

        burst_valid_o <= 1'b1;

        burst_src_addr_o <= src_addr_i;
        burst_dst_addr_o <= dst_addr_i;

        axi_arlen_o <= burst_beats_q - 1'b1;
        axi_awlen_o <= burst_beats_q - 1'b1;

        case (src_width_i)
            2'b00: axi_arsize_o <= 3'd0;
            2'b01: axi_arsize_o <= 3'd1;
            2'b10: axi_arsize_o <= 3'd2;
            2'b11: axi_arsize_o <= 3'd3;
            default: axi_arsize_o <= 3'd0;
        endcase

        case (dst_width_i)
            2'b00: axi_awsize_o <= 3'd0;
            2'b01: axi_awsize_o <= 3'd1;
            2'b10: axi_awsize_o <= 3'd2;
            2'b11: axi_awsize_o <= 3'd3;
            default: axi_awsize_o <= 3'd0;
        endcase

        axi_arburst_o <= burst_type_i;
        axi_awburst_o <= burst_type_i;

        burst_bytes_o <= total_burst_bytes_q;
    end

    // Hold current burst stable until acknowledged.
    else if (!burst_pop && !any_fault) begin
        burst_valid_o <= 1'b1;
    end

    // Current burst consumed with no replacement.
    else begin
        burst_valid_o <= 1'b0;
    end
end

            //------------------------------------------------------------------
            // DONE
            //------------------------------------------------------------------

            `RTDDMA_AGU_ST_DONE:
            begin

                planner_busy_o <= 1'b0;
		burst_valid_o <= 1'b0;

            end

            //------------------------------------------------------------------
            // ABORT
            //------------------------------------------------------------------

            `RTDDMA_AGU_ST_ABORT:
            begin

                planner_busy_o <= 1'b0;
		burst_valid_o <= 1'b0;

            end

            //------------------------------------------------------------------
            // FAULT
            //------------------------------------------------------------------

            `RTDDMA_AGU_ST_FAULT:
            begin

                planner_busy_o <= 1'b0;
		burst_valid_o <= 1'b0;

                fault_valid_o <= 1'b1;

                if (chk_4kb_cross)
                    fault_code_o <= `RTDDMA_FAULT_AGU_ADDR_WRAP;

                else if (chk_zero_burst)
                    fault_code_o <= `RTDDMA_FAULT_INTERNAL_UNDERFLOW;

                else if (chk_burst_overflow)
                    fault_code_o <= `RTDDMA_FAULT_AGU_ADDR_OVERFLOW;

                else if (chk_outstanding_overflow)
                    fault_code_o <= `RTDDMA_FAULT_OUTSTANDING_MISMATCH;

                else if (chk_illegal_burst)
                    fault_code_o <= `RTDDMA_FAULT_MPU_BURST;

                else
                    fault_code_o <= `RTDDMA_FAULT_FSM_ILLEGAL_STATE;

                fault_info_o <= src_addr_i[31:0];

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
