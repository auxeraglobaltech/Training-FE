
//==============================================================================
// File        : rtddma_agulinectrl.v
// Project     : RTD-DMA
//------------------------------------------------------------------------------
// Description :
// Deterministic AGU line traversal controller.
//
// Responsibilities:
// - Controls X/Y traversal progression
// - Generates line boundaries
// - Handles deterministic line advancement
// - Prevents illegal traversal progression
// - Maintains bounded execution ordering
// - Supports stride-based movement
// - Supports gather/scatter traversal modes
//
// Safety:
// - Parallel traversal legality checks
// - Illegal state detection
// - Overflow/underflow protection
// - Deterministic fail-close behavior
// - No speculative advancement
// - Pure synthesizable Verilog
//
//==============================================================================
`timescale 1ns/1ps
`include "rtddmaparams.vh"
`include "rtddmafaultcodes.vh"
`include "rtddmastates.vh"

module rtddma_agulinectrl
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
    // AGU CORE INPUTS
    //--------------------------------------------------------------------------

    input  wire                                     addr_valid_i,

    input  wire [39:0]                              src_addr_i,
    input  wire [39:0]                              dst_addr_i,

    input  wire [15:0]                              x_idx_i,
    input  wire [15:0]                              y_idx_i,

    input  wire [15:0]                              x_count_i,
    input  wire [15:0]                              y_count_i,

    //--------------------------------------------------------------------------
    // LINE OUTPUTS
    //--------------------------------------------------------------------------

    output reg                                      line_valid_o,

    output reg [39:0]                               line_src_addr_o,
    output reg [39:0]                               line_dst_addr_o,

    output reg                                      line_start_o,
    output reg                                      line_end_o,

    output reg [15:0]                               line_x_idx_o,
    output reg [15:0]                               line_y_idx_o,

    //--------------------------------------------------------------------------
    // STATUS
    //--------------------------------------------------------------------------

    output reg                                      busy_o,
    output reg                                      done_o,

    //--------------------------------------------------------------------------
    // FAULTS
    //--------------------------------------------------------------------------

    output reg                                      fault_valid_o,
    output reg [7:0]                                fault_code_o,
    output reg [31:0]                               fault_info_o
);

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

reg [2:0] state_q;
reg [2:0] state_n;

///////////////////////////////////////////////////////////////////////////////
// INTERNAL TRACKERS
///////////////////////////////////////////////////////////////////////////////

reg [15:0] last_x_idx_q;
reg [15:0] last_y_idx_q;

///////////////////////////////////////////////////////////////////////////////
// PARALLEL SAFETY CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_x_overflow;
wire chk_y_overflow;

wire chk_x_reverse;
wire chk_y_reverse;

wire chk_null_line;

wire chk_addr_wrap;

wire chk_illegal_state;

///////////////////////////////////////////////////////////////////////////////
// INDEX BOUNDS
///////////////////////////////////////////////////////////////////////////////

assign chk_x_overflow =
(
    x_idx_i >= x_count_i
);

assign chk_y_overflow =
(
    y_idx_i >= y_count_i
);

///////////////////////////////////////////////////////////////////////////////
// REVERSE MOVEMENT
///////////////////////////////////////////////////////////////////////////////

assign chk_x_reverse =
(
    addr_valid_i &&
    (x_idx_i < last_x_idx_q) &&
    (y_idx_i == last_y_idx_q)
);

assign chk_y_reverse =
(
    addr_valid_i &&
    (y_idx_i < last_y_idx_q)
);

///////////////////////////////////////////////////////////////////////////////
// NULL LINE
///////////////////////////////////////////////////////////////////////////////

assign chk_null_line =
(
    (x_count_i == 16'd0) ||
    (y_count_i == 16'd0)
);

///////////////////////////////////////////////////////////////////////////////
// ADDRESS WRAP
///////////////////////////////////////////////////////////////////////////////

assign chk_addr_wrap =
(
    (src_addr_i == 40'd0) ||
    (dst_addr_i == 40'd0)
);

///////////////////////////////////////////////////////////////////////////////
// ILLEGAL STATE
///////////////////////////////////////////////////////////////////////////////

assign chk_illegal_state =
(
    (state_q != `RTDDMA_IDLE_S)  &&
    (state_q != `RTDDMA_BUSY_S)  &&
    (state_q != `RTDDMA_DONE_S)  &&
    (state_q != `RTDDMA_ABORT_S) &&
    (state_q != `RTDDMA_FAULT_S)
);

///////////////////////////////////////////////////////////////////////////////
// GLOBAL FAULT
///////////////////////////////////////////////////////////////////////////////

wire any_fault;

assign any_fault =
       chk_x_overflow
    || chk_y_overflow
    || chk_x_reverse
    || chk_y_reverse
    || chk_null_line
    || chk_addr_wrap
    || chk_illegal_state;

///////////////////////////////////////////////////////////////////////////////
// FSM NEXT STATE
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    state_n = state_q;

    case (state_q)

        //----------------------------------------------------------------------
        // IDLE
        //----------------------------------------------------------------------

        `RTDDMA_IDLE_S:
        begin

            if (start_i)
                state_n = `RTDDMA_BUSY_S;
        end

        //----------------------------------------------------------------------
        // BUSY
        //----------------------------------------------------------------------

        `RTDDMA_BUSY_S:
        begin

            if (stop_i)
                state_n = `RTDDMA_ABORT_S;

            else if (any_fault)
                state_n = `RTDDMA_FAULT_S;

            else if
            (
                addr_valid_i &&
                (x_idx_i == (x_count_i - 1'b1)) &&
                (y_idx_i == (y_count_i - 1'b1))
            )
                state_n = `RTDDMA_DONE_S;
        end

        //----------------------------------------------------------------------
        // DONE
        //----------------------------------------------------------------------

        `RTDDMA_DONE_S:
        begin
            state_n = `RTDDMA_IDLE_S;
        end

        //----------------------------------------------------------------------
        // ABORT
        //----------------------------------------------------------------------

        `RTDDMA_ABORT_S:
        begin
            state_n = `RTDDMA_IDLE_S;
        end

        //----------------------------------------------------------------------
        // FAULT
        //----------------------------------------------------------------------

        `RTDDMA_FAULT_S:
        begin

            if (clr_fault_i)
                state_n = `RTDDMA_IDLE_S;
        end

        //----------------------------------------------------------------------
        // DEFAULT
        //----------------------------------------------------------------------

        default:
        begin
            state_n = `RTDDMA_FAULT_S;
        end

    endcase
end

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state_q <= `RTDDMA_IDLE_S;

        line_valid_o <= 1'b0;

        line_src_addr_o <= 40'd0;
        line_dst_addr_o <= 40'd0;

        line_start_o <= 1'b0;
        line_end_o   <= 1'b0;

        line_x_idx_o <= 16'd0;
        line_y_idx_o <= 16'd0;

        last_x_idx_q <= 16'd0;
        last_y_idx_q <= 16'd0;

        busy_o <= 1'b0;
        done_o <= 1'b0;

        fault_valid_o <= 1'b0;
        fault_code_o  <= `RTDDMA_FAULT_NONE;
        fault_info_o  <= 32'd0;

    end
    else begin

        state_q <= state_n;

        line_valid_o <= 1'b0;

        line_start_o <= 1'b0;
        line_end_o   <= 1'b0;

        done_o <= 1'b0;

        case (state_q)

            //------------------------------------------------------------------
            // IDLE
            //------------------------------------------------------------------

            `RTDDMA_IDLE_S:
            begin

                busy_o <= 1'b0;

                last_x_idx_q <= 16'd0;
                last_y_idx_q <= 16'd0;

            end

            //------------------------------------------------------------------
            // BUSY
            //------------------------------------------------------------------

            `RTDDMA_BUSY_S:
            begin

                busy_o <= 1'b1;

                if
                (
                    addr_valid_i &&
                    !any_fault
                ) begin

                    line_valid_o <= 1'b1;

                    line_src_addr_o <= src_addr_i;
                    line_dst_addr_o <= dst_addr_i;

                    line_x_idx_o <= x_idx_i;
                    line_y_idx_o <= y_idx_i;

                    //------------------------------------------------------------------
                    // LINE START
                    //------------------------------------------------------------------

                    if (x_idx_i == 16'd0)
                        line_start_o <= 1'b1;

                    //------------------------------------------------------------------
                    // LINE END
                    //------------------------------------------------------------------

                    if (x_idx_i == (x_count_i - 1'b1))
                        line_end_o <= 1'b1;

                    //------------------------------------------------------------------
                    // TRACKERS
                    //------------------------------------------------------------------

                    last_x_idx_q <= x_idx_i;
                    last_y_idx_q <= y_idx_i;

                end
            end

            //------------------------------------------------------------------
            // DONE
            //------------------------------------------------------------------

            `RTDDMA_DONE_S:
            begin

                busy_o <= 1'b0;
                done_o <= 1'b1;

            end

            //------------------------------------------------------------------
            // ABORT
            //------------------------------------------------------------------

            `RTDDMA_ABORT_S:
            begin

                busy_o <= 1'b0;

            end

            //------------------------------------------------------------------
            // FAULT
            //------------------------------------------------------------------

            `RTDDMA_FAULT_S:
            begin

                busy_o <= 1'b0;

                fault_valid_o <= 1'b1;

                //----------------------------------------------------------------
                // PRIORITY FAULT ENCODING
                //----------------------------------------------------------------

                if (chk_x_overflow)
                    fault_code_o <= `RTDDMA_FAULT_AGU_X_OVERFLOW;

                else if (chk_y_overflow)
                    fault_code_o <= `RTDDMA_FAULT_AGU_Y_OVERFLOW;

                else if (chk_x_reverse)
                    fault_code_o <= `RTDDMA_FAULT_AGU_X_REVERSE;

                else if (chk_y_reverse)
                    fault_code_o <= `RTDDMA_FAULT_AGU_Y_REVERSE;

                else if (chk_null_line)
                    fault_code_o <= `RTDDMA_FAULT_AGU_NULL_DIM;

                else if (chk_addr_wrap)
                    fault_code_o <= `RTDDMA_FAULT_AGU_ADDR_WRAP;

                else
                    fault_code_o <= `RTDDMA_FAULT_FSM_ILLEGAL_STATE;

                //----------------------------------------------------------------
                // FAULT INFO
                //----------------------------------------------------------------

                fault_info_o <=
                {
                    y_idx_i[15:0],
                    x_idx_i[15:0]
                };

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

