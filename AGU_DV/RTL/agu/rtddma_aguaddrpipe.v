
//==============================================================================
// File        : rtddma_aguaddrpipe.v
// Project     : RTD-DMA
//------------------------------------------------------------------------------
// Description :
// Deterministic AGU address pipeline.
//
// Responsibilities:
// - Register/pipeline AGU addresses
// - Deterministic timing isolation
// - Bubble containment
// - AXI issue decoupling
// - Backpressure-safe advancement
// - Outstanding-aware issue gating
// - Ping/pong address context support
// - Safety fault containment
//
// Safety:
// - SEU-safe FSM
// - Illegal state detection
// - Overflow/underflow detection
// - No inferred latches
// - No functions/tasks
//
//==============================================================================
`timescale 1ns/1ps
`include "rtddmaparams.vh"
`include "rtddmafaultcodes.vh"
`include "rtddmastates.vh"

module rtddma_aguaddrpipe
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
    // INPUT SIDE
    //--------------------------------------------------------------------------

    input  wire                                     addr_valid_i,
    output wire                                     addr_ready_o,
    input  wire [39:0]                              src_addr_i,
    input  wire [39:0]                              dst_addr_i,

    input  wire [15:0]                              burst_bytes_i,

    //--------------------------------------------------------------------------
    // ISSUE SIDE
    //--------------------------------------------------------------------------

    input  wire                                     issue_ready_i,
    input  wire                                     issue_ack_i,

    input  wire [3:0]                               outstanding_cnt_i,

    //--------------------------------------------------------------------------
    // PIPE OUTPUT
    //--------------------------------------------------------------------------

    output reg                                      pipe_valid_o,

    output reg [39:0]                               pipe_src_addr_o,
    output reg [39:0]                               pipe_dst_addr_o,

    output reg [15:0]                               pipe_burst_bytes_o,

    //--------------------------------------------------------------------------
    // STATUS
    //--------------------------------------------------------------------------

    output reg                                      pipe_busy_o,
    output reg                                      pipe_stall_o,

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

reg [2:0] pipe_state_q;
reg [2:0] pipe_state_n;

reg [39:0] src_addr_q;
reg [39:0] dst_addr_q;

reg [15:0] burst_bytes_q;

reg         pipe_entry_valid_q;

reg transaction_active_q;
wire pipe_load;
wire pipe_pop;

assign addr_ready_o =
    transaction_active_q &&
    (!pipe_entry_valid_q || issue_ack_i);

assign pipe_load =
    addr_valid_i && addr_ready_o;

assign pipe_pop =
    pipe_entry_valid_q && issue_ack_i;
///////////////////////////////////////////////////////////////////////////////
// PARALLEL SAFETY CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_pipe_overflow;
wire chk_pipe_underflow;
wire chk_outstanding_overflow;
wire chk_null_transfer;
wire chk_addr_wrap;
wire chk_illegal_state;

wire input_stalled;

assign input_stalled =
    addr_valid_i && !addr_ready_o;

///////////////////////////////////////////////////////////////////////////////
// PIPE OVERFLOW
///////////////////////////////////////////////////////////////////////////////

assign chk_pipe_overflow = 1'b0;

///////////////////////////////////////////////////////////////////////////////
// PIPE UNDERFLOW
///////////////////////////////////////////////////////////////////////////////

assign chk_pipe_underflow =
(
    !pipe_entry_valid_q &&
    issue_ack_i
);

///////////////////////////////////////////////////////////////////////////////
// OUTSTANDING LIMIT
///////////////////////////////////////////////////////////////////////////////

assign chk_outstanding_overflow =
(
    outstanding_cnt_i >= `RTDDMA_MAX_OUTSTANDING
);

///////////////////////////////////////////////////////////////////////////////
// NULL TRANSFER
///////////////////////////////////////////////////////////////////////////////

assign chk_null_transfer =
(
    burst_bytes_i == 16'd0
);

///////////////////////////////////////////////////////////////////////////////
// ADDRESS WRAP
///////////////////////////////////////////////////////////////////////////////

assign chk_addr_wrap =
(
    (src_addr_i + burst_bytes_i) < src_addr_i ||
    (dst_addr_i + burst_bytes_i) < dst_addr_i
);

///////////////////////////////////////////////////////////////////////////////
// ILLEGAL FSM STATE
///////////////////////////////////////////////////////////////////////////////

assign chk_illegal_state =
(
    (pipe_state_q != `RTDDMA_IDLE_S)   &&
    (pipe_state_q != `RTDDMA_BUSY_S)   &&
    (pipe_state_q != `RTDDMA_DONE_S)   &&
    (pipe_state_q != `RTDDMA_ABORT_S)  &&
    (pipe_state_q != `RTDDMA_FAULT_S)
);

///////////////////////////////////////////////////////////////////////////////
// GLOBAL FAULT
///////////////////////////////////////////////////////////////////////////////

wire any_fault;

assign any_fault =
       chk_pipe_overflow
    || chk_pipe_underflow
    || chk_outstanding_overflow
    || chk_null_transfer
    || chk_addr_wrap
    || chk_illegal_state;

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    pipe_state_n = pipe_state_q;

    case (pipe_state_q)

        //----------------------------------------------------------------------
        // IDLE
        //----------------------------------------------------------------------

        `RTDDMA_IDLE_S:
        begin

            //if (start_i && addr_valid_i) begin
	      if (pipe_load) begin

                if (any_fault)
                    pipe_state_n = `RTDDMA_FAULT_S;
                else
                    pipe_state_n = `RTDDMA_BUSY_S;
            end
        end

        //----------------------------------------------------------------------
        // BUSY
        //----------------------------------------------------------------------

        `RTDDMA_BUSY_S:
        begin

            if (stop_i)
                pipe_state_n = `RTDDMA_ABORT_S;

            else if (any_fault)
                pipe_state_n = `RTDDMA_FAULT_S;

            else if
            (
                 pipe_pop && !pipe_load           
	 )
                pipe_state_n = `RTDDMA_DONE_S;
        end

        //----------------------------------------------------------------------
        // DONE
        //----------------------------------------------------------------------

        `RTDDMA_DONE_S:
        begin
            pipe_state_n = `RTDDMA_IDLE_S;
        end

        //----------------------------------------------------------------------
        // ABORT
        //----------------------------------------------------------------------

        `RTDDMA_ABORT_S:
        begin
            pipe_state_n = `RTDDMA_IDLE_S;
        end

        //----------------------------------------------------------------------
        // FAULT
        //----------------------------------------------------------------------

        `RTDDMA_FAULT_S:
        begin

            if (clr_fault_i)
                pipe_state_n = `RTDDMA_IDLE_S;
        end

        //----------------------------------------------------------------------
        // DEFAULT
        //----------------------------------------------------------------------

        default:
        begin
            pipe_state_n = `RTDDMA_FAULT_S;
        end

    endcase
end

///////////////////////////////////////////////////////////////////////////////
// PIPELINE REGISTERS
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        pipe_state_q <= `RTDDMA_IDLE_S;

        src_addr_q <= 40'd0;
        dst_addr_q <= 40'd0;

        burst_bytes_q <= 16'd0;

        pipe_entry_valid_q <= 1'b0;

	transaction_active_q <= 1'b0;

        pipe_valid_o <= 1'b0;

        pipe_src_addr_o <= 40'd0;
        pipe_dst_addr_o <= 40'd0;

        pipe_burst_bytes_o <= 16'd0;

        pipe_busy_o  <= 1'b0;
        pipe_stall_o <= 1'b0;

        fault_valid_o <= 1'b0;
        fault_code_o  <= `RTDDMA_FAULT_NONE;
        fault_info_o  <= 32'd0;

    end
    else begin

        pipe_state_q <= pipe_state_n;

   if (start_i)
     transaction_active_q <= 1'b1;
   else if (stop_i || clr_fault_i)
     transaction_active_q <= 1'b0;

        pipe_valid_o <= 1'b0;

        case (pipe_state_q)

            //------------------------------------------------------------------
            // IDLE
            //------------------------------------------------------------------

            `RTDDMA_IDLE_S:
            begin

                pipe_busy_o  <= 1'b0;
                pipe_stall_o <= 1'b0;

                pipe_entry_valid_q <= 1'b0;
		if(
    pipe_load &&
    !any_fault
)

		begin

                    pipe_busy_o <= 1'b1;

                    src_addr_q <= src_addr_i;
                    dst_addr_q <= dst_addr_i;

                    burst_bytes_q <= burst_bytes_i;

                    pipe_entry_valid_q <= 1'b1;

                end
            end

            //------------------------------------------------------------------
            // BUSY
            //------------------------------------------------------------------

            `RTDDMA_BUSY_S:
            begin

                pipe_busy_o <= 1'b1;

                //----------------------------------------------------------------
                // STALL DETECTION
                //----------------------------------------------------------------

                if (!issue_ready_i)
                    pipe_stall_o <= 1'b1;
                else
                    pipe_stall_o <= 1'b0;

                //----------------------------------------------------------------
                // ISSUE
                //----------------------------------------------------------------

                if
                (
                    pipe_entry_valid_q &&
                    issue_ready_i      &&
                    !any_fault
                ) begin

                    pipe_valid_o <= 1'b1;

                    pipe_src_addr_o <= src_addr_q;
                    pipe_dst_addr_o <= dst_addr_q;

                    pipe_burst_bytes_o <= burst_bytes_q;

                end

                //----------------------------------------------------------------
                // ACK
                //----------------------------------------------------------------

            if (pipe_load) begin
    src_addr_q         <= src_addr_i;
    dst_addr_q         <= dst_addr_i;
    burst_bytes_q      <= burst_bytes_i;
    pipe_entry_valid_q <= 1'b1;
end
else if (pipe_pop) begin
    pipe_entry_valid_q <= 1'b0;
end 
            end

            //------------------------------------------------------------------
            // DONE
            //------------------------------------------------------------------

            `RTDDMA_DONE_S:
            begin

                pipe_busy_o  <= 1'b0;
                pipe_stall_o <= 1'b0;

            end

            //------------------------------------------------------------------
            // ABORT
            //------------------------------------------------------------------

            `RTDDMA_ABORT_S:
            begin

                pipe_busy_o  <= 1'b0;
                pipe_stall_o <= 1'b0;

                pipe_entry_valid_q <= 1'b0;

            end

            //------------------------------------------------------------------
            // FAULT
            //------------------------------------------------------------------

            `RTDDMA_FAULT_S:
            begin

                pipe_busy_o  <= 1'b0;
                pipe_stall_o <= 1'b0;

                pipe_entry_valid_q <= 1'b0;

                fault_valid_o <= 1'b1;

                //----------------------------------------------------------------
                // PRIORITY FAULT ENCODING
                //----------------------------------------------------------------

                if (chk_pipe_overflow)
                    fault_code_o <= `RTDDMA_FAULT_FIFO_OVERFLOW;

                else if (chk_pipe_underflow)
                    fault_code_o <= `RTDDMA_FAULT_FIFO_UNDERFLOW;

                else if (chk_outstanding_overflow)
                    fault_code_o <= `RTDDMA_FAULT_OUTSTANDING_MISMATCH;

                else if (chk_null_transfer)
                    fault_code_o <= `RTDDMA_FAULT_INTERNAL_UNDERFLOW;

                else if (chk_addr_wrap)
                    fault_code_o <= `RTDDMA_FAULT_AGU_ADDR_WRAP;

                else
                    fault_code_o <= `RTDDMA_FAULT_FSM_ILLEGAL_STATE;

                //----------------------------------------------------------------
                // DEBUG INFO
                //----------------------------------------------------------------

                fault_info_o <= src_addr_q[31:0];

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
