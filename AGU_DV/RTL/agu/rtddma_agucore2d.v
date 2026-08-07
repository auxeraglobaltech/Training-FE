

//==============================================================================
// File        : rtddma_agucore2d.v
// Project     : RTD-DMA
//------------------------------------------------------------------------------
// Description :
// Industrial-grade deterministic 2D AGU core.
//
// Features:
// - Linear / Stride / Gather / Scatter
// - Deterministic bounded issue
// - Parallel safety checking
// - No speculative advance
// - Outstanding-aware progression
// - Overflow detection
// - Alignment checking
// - Ping-pong aware addressing
// - Pure synthesizable Verilog
// - No functions/tasks
//
//==============================================================================
`timescale 1ns/1ps
`include "rtddmaparams.vh"
`include "rtddma_descfields.vh"
`include "rtddmafaultcodes.vh"
`include "rtddmaagudefs.vh"

module rtddma_agucore2d
(
    input  wire                                     clk,
    input  wire                                     rst_n,

    //--------------------------------------------------------------------------
    // CONTROL
    //--------------------------------------------------------------------------

    input  wire                                     start_i,
    input  wire                                     stop_i,
    input  wire                                     pause_i,
    input  wire                                     drain_i,
    input  wire                                     clr_fault_i,

    //--------------------------------------------------------------------------
    // DESCRIPTOR CONTEXT
    //--------------------------------------------------------------------------

    input  wire [31:0]                              src_addr_i,
    input  wire [31:0]                              dst_addr_i,

    input  wire [15:0]                              x_count_i,
    input  wire [15:0]                              y_count_i,

    input  wire [15:0]                              x_stride_i,
    input  wire signed [15:0]                       y_stride_i,

    input  wire [1:0]                               addr_mode_i,
    input  wire [3:0]                               burst_len_i,

    input  wire [1:0]                               src_width_i,
    input  wire [1:0]                               dst_width_i,

    input  wire                                     gather_enable_i,
    input  wire                                     scatter_enable_i,

    //--------------------------------------------------------------------------
    // GATHER/SCATTER POINTERS
    //--------------------------------------------------------------------------

    input  wire [31:0]                              gather_ptr_i,
    input  wire [31:0]                              scatter_ptr_i,

    //--------------------------------------------------------------------------
    // ISSUE HANDSHAKE
    //--------------------------------------------------------------------------

    input  wire                                     issue_ack_i,
    input  wire                                     downstream_ready_i,

    //--------------------------------------------------------------------------
    // AGU OUTPUT
    //--------------------------------------------------------------------------

    output reg                                      issue_valid_o,

    output reg [39:0]                               src_addr_o,
    output reg [39:0]                               dst_addr_o,

    output reg [15:0]                                burst_bytes_o,

    output reg                                      line_done_o,
    output reg                                      frame_done_o,

    output reg                                      busy_o,
    //--------------------------------------------------------------------------
   // CURRENT 2D LOOP INDICES
   //--------------------------------------------------------------------------

    output wire [15:0]                              x_idx_o,
    output wire [15:0]                              y_idx_o,

    //--------------------------------------------------------------------------
    // FAULTS
    //--------------------------------------------------------------------------

    output reg                                      fault_valid_o,
    output reg [7:0]                                fault_code_o,
    output reg [31:0]                               fault_info_o
);

///////////////////////////////////////////////////////////////////////////////
// INTERNAL REGISTERS
///////////////////////////////////////////////////////////////////////////////

reg [2:0] state_q;
reg [2:0] state_n;

reg [15:0] x_idx_q;
reg [15:0] y_idx_q;

assign x_idx_o = x_idx_q;
assign y_idx_o = y_idx_q;

reg [39:0] src_addr_q;
reg [39:0] dst_addr_q;

reg [39:0] src_row_base_q;
reg [39:0] dst_row_base_q;

reg [39:0] next_src_addr;
reg [39:0] next_dst_addr;

reg [39:0] gather_addr_q;
reg [39:0] scatter_addr_q;

reg [7:0] burst_bytes_q;

reg [31:0] elem_bytes_q;

///////////////////////////////////////////////////////////////////////////////
// WIDTH DECODER
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    case (src_width_i)

        2'b00: elem_bytes_q = 32'd1;
        2'b01: elem_bytes_q = 32'd2;
        2'b10: elem_bytes_q = 32'd4;
        2'b11: elem_bytes_q = 32'd8;

        default:
            elem_bytes_q = 32'd1;

    endcase
end

///////////////////////////////////////////////////////////////////////////////
// PARALLEL SAFETY CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_x_zero;
wire chk_y_zero;

wire chk_src_align;
wire chk_dst_align;

wire chk_addr_overflow;
wire chk_addr_wrap;

wire chk_gather_oob;
wire chk_scatter_oob;

wire chk_illegal_state;

assign chk_x_zero =
    (x_count_i == 16'd0);

assign chk_y_zero =
    (y_count_i == 16'd0);

assign chk_src_align =
(
    ((src_width_i == 2'b01) && src_addr_i[0])   ||
    ((src_width_i == 2'b10) && |src_addr_i[1:0])||
    ((src_width_i == 2'b11) && |src_addr_i[2:0])
);

assign chk_dst_align =
(
    ((dst_width_i == 2'b01) && dst_addr_i[0])   ||
    ((dst_width_i == 2'b10) && |dst_addr_i[1:0])||
    ((dst_width_i == 2'b11) && |dst_addr_i[2:0])
);

assign chk_addr_overflow =
(
    (next_src_addr < src_addr_q) ||
    (next_dst_addr < dst_addr_q)
);

assign chk_addr_wrap =
(
    (next_src_addr[39:32] != src_addr_q[39:32]) ||
    (next_dst_addr[39:32] != dst_addr_q[39:32])
);

assign chk_gather_oob =
(
    gather_enable_i &&
    (gather_ptr_i[1:0] != 2'b00)
);

assign chk_scatter_oob =
(
    scatter_enable_i &&
    (scatter_ptr_i[1:0] != 2'b00)
);

assign chk_illegal_state =
(
    (state_q != `RTDDMA_AGU_ST_IDLE)   &&
    (state_q != `RTDDMA_AGU_ST_ACTIVE) &&
    (state_q != `RTDDMA_AGU_ST_PAUSE)  &&
    (state_q != `RTDDMA_AGU_ST_DRAIN)  &&
    (state_q != `RTDDMA_AGU_ST_DONE)   &&
    (state_q != `RTDDMA_AGU_ST_ABORT)  &&
    (state_q != `RTDDMA_AGU_ST_FAULT)
);

wire any_fault;

assign any_fault =
       chk_x_zero
    || chk_y_zero
    || chk_src_align
    || chk_dst_align
    || chk_addr_overflow
    || chk_addr_wrap
    || chk_gather_oob
    || chk_scatter_oob
    || chk_illegal_state;

///////////////////////////////////////////////////////////////////////////////
// NEXT ADDRESS GENERATION
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    next_src_addr = src_addr_q;
    next_dst_addr = dst_addr_q;

    case (addr_mode_i)

        `RTDDMA_ADDR_MODE_LINEAR:
        begin
            next_src_addr = src_addr_q + elem_bytes_q;
            next_dst_addr = dst_addr_q + elem_bytes_q;
        end

        `RTDDMA_ADDR_MODE_STRIDE:
        begin
            next_src_addr = src_addr_q + x_stride_i;
            next_dst_addr = dst_addr_q + x_stride_i;
        end

        `RTDDMA_ADDR_MODE_GATHER:
        begin
            next_src_addr = gather_addr_q;
            next_dst_addr = dst_addr_q + elem_bytes_q;
        end

        `RTDDMA_ADDR_MODE_SCATTER:
        begin
            next_src_addr = src_addr_q + elem_bytes_q;
            next_dst_addr = scatter_addr_q;
        end

        default:
        begin
            next_src_addr = src_addr_q;
            next_dst_addr = dst_addr_q;
        end

    endcase
end

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    state_n = state_q;

    case (state_q)

        `RTDDMA_AGU_ST_IDLE:
        begin

            if (start_i) begin

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

            else if (pause_i)
                state_n = `RTDDMA_AGU_ST_PAUSE;

            else if (drain_i)
                state_n = `RTDDMA_AGU_ST_DRAIN;

            else if (any_fault)
                state_n = `RTDDMA_AGU_ST_FAULT;

            else if
            (
                issue_ack_i &&
                (x_idx_q == (x_count_i - 1'b1)) &&
                (y_idx_q == (y_count_i - 1'b1))
            )
                state_n = `RTDDMA_AGU_ST_DONE;
        end

        `RTDDMA_AGU_ST_PAUSE:
        begin
            if (!pause_i)
                state_n = `RTDDMA_AGU_ST_ACTIVE;
        end

        `RTDDMA_AGU_ST_DRAIN:
        begin
            if (!drain_i)
                state_n = `RTDDMA_AGU_ST_ACTIVE;
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
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state_q         <= `RTDDMA_AGU_ST_IDLE;

        x_idx_q         <= 16'd0;
        y_idx_q         <= 16'd0;

        src_addr_q      <= 40'd0;
        dst_addr_q      <= 40'd0;

	src_row_base_q <= 40'd0;
        dst_row_base_q <= 40'd0;

        gather_addr_q   <= 40'd0;
        scatter_addr_q  <= 40'd0;

        issue_valid_o   <= 1'b0;

        line_done_o     <= 1'b0;
        frame_done_o    <= 1'b0;

        busy_o          <= 1'b0;

        fault_valid_o   <= 1'b0;
        fault_code_o    <= `RTDDMA_FAULT_NONE;
        fault_info_o    <= 32'd0;

    end
    else begin

        state_q <= state_n;

        issue_valid_o <= 1'b0;
        line_done_o   <= 1'b0;
        frame_done_o  <= 1'b0;

        case (state_q)

            `RTDDMA_AGU_ST_IDLE:
            begin

                busy_o <= 1'b0;

                if (start_i && !any_fault) begin

                    busy_o <= 1'b1;

                    x_idx_q <= 16'd0;
                    y_idx_q <= 16'd0;

                    src_addr_q <= {8'd0, src_addr_i};
                    dst_addr_q <= {8'd0, dst_addr_i};

		    src_row_base_q <= {8'd0, src_addr_i};
                    dst_row_base_q <= {8'd0, dst_addr_i};

                    gather_addr_q  <= {8'd0, gather_ptr_i};
                    scatter_addr_q <= {8'd0, scatter_ptr_i};
                end
            end

            `RTDDMA_AGU_ST_ACTIVE:
            begin

                busy_o <= 1'b1;

                if (downstream_ready_i) begin

                    issue_valid_o <= 1'b1;

                    src_addr_o <= src_addr_q;
                    dst_addr_o <= dst_addr_q;

                    burst_bytes_o <=
                        burst_len_i << src_width_i;
                end

                if (issue_ack_i) begin

                    src_addr_q <= next_src_addr;
                    dst_addr_q <= next_dst_addr;

                    if (x_idx_q == (x_count_i - 1'b1)) begin

                        x_idx_q <= 16'd0;

                        line_done_o <= 1'b1;

                        if (y_idx_q == (y_count_i - 1'b1)) begin

                            y_idx_q <= y_idx_q;

                            frame_done_o <= 1'b1;

                        end
                      /*  else begin

                            y_idx_q <= y_idx_q + 1'b1;

                            src_addr_q <=
                                src_addr_q + y_stride_i;

                            dst_addr_q <=
                                dst_addr_q + y_stride_i;
                        end*/
		       else begin

                     y_idx_q <= y_idx_q + 1'b1;

    src_row_base_q <=
        src_row_base_q +
        {{24{y_stride_i[15]}}, y_stride_i};

    dst_row_base_q <=
        dst_row_base_q +
        {{24{y_stride_i[15]}}, y_stride_i};

    src_addr_q <=
        src_row_base_q +
        {{24{y_stride_i[15]}}, y_stride_i};

    dst_addr_q <=
        dst_row_base_q +
        {{24{y_stride_i[15]}}, y_stride_i};

end
                    end
                    else begin

                        x_idx_q <= x_idx_q + 1'b1;
                    end
                end
            end

            `RTDDMA_AGU_ST_DONE:
            begin
                busy_o <= 1'b0;
            end

            `RTDDMA_AGU_ST_ABORT:
            begin
                busy_o <= 1'b0;
            end

            `RTDDMA_AGU_ST_FAULT:
            begin

                busy_o <= 1'b0;

                fault_valid_o <= 1'b1;

                if (chk_x_zero)
                    fault_code_o <= `RTDDMA_FAULT_AGU_XCOUNT_ZERO;

                else if (chk_y_zero)
                    fault_code_o <= `RTDDMA_FAULT_AGU_YCOUNT_ZERO;

                else if (chk_src_align)
                    fault_code_o <= `RTDDMA_FAULT_MPU_ALIGN;

                else if (chk_dst_align)
                    fault_code_o <= `RTDDMA_FAULT_MPU_ALIGN;

                else if (chk_addr_overflow)
                    fault_code_o <= `RTDDMA_FAULT_AGU_ADDR_OVERFLOW;

                else if (chk_addr_wrap)
                    fault_code_o <= `RTDDMA_FAULT_AGU_ADDR_WRAP;

                else if (chk_gather_oob)
                    fault_code_o <= `RTDDMA_FAULT_AGU_GATHER_OOB;

                else if (chk_scatter_oob)
                    fault_code_o <= `RTDDMA_FAULT_AGU_SCATTER_OOB;

                else
                    fault_code_o <= `RTDDMA_FAULT_FSM_ILLEGAL_STATE;

                fault_info_o <= src_addr_q;

                if (clr_fault_i) begin

                    fault_valid_o <= 1'b0;
                    fault_code_o  <= `RTDDMA_FAULT_NONE;
                end
            end
        endcase
    end
end

endmodule

