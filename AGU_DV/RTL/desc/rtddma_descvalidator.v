
//==============================================================================
// Project      : RTD-DMA
// Module       : rtddma_descvalidator
// File         : rtddma_descvalidator.v
//------------------------------------------------------------------------------
// Description  :
// ASIL-D Hardened Deterministic Descriptor Validator
//
// Parallel Validation Fabric:
//   STAGE0 : Structural + CRC + Format
//   STAGE1 : Security + MPU + VMID
//   STAGE2 : Runtime + QoS + Chain + Overflow
//
// Deterministic bounded-latency validation.
// No speculative descriptor acceptance.
// Atomic context commit only after ALL checks pass.
//
//------------------------------------------------------------------------------
// Safety Features
//------------------------------------------------------------------------------
// - Parallel validation architecture
// - Sticky first-fault capture
// - FSM parity protection
// - Illegal state detection
// - Descriptor parity protection
// - Active context parity protection
// - Timeout watchdog
// - MPU-before-issue enforcement
// - Anti-replay sequence validation
// - Chain runaway prevention
// - AXI legality validation
// - Overflow detection
// - Safe fail-stop behavior
//
//------------------------------------------------------------------------------
// Included Headers
//------------------------------------------------------------------------------
// `include "rtddma_params.vh"
// `include "rtddma_states.vh"
// `include "rtddma_descfields.vh"
// `include "rtddma_faultcodes.vh"
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

`include "rtddma_params.vh"
`include "rtddma_states.vh"
`include "rtddma_descfields.vh"
`include "rtddma_faultcodes.vh"

module rtddma_descvalidator
(
    input  wire                                 clk,
    input  wire                                 rst_n,

    //--------------------------------------------------------------------------
    // Descriptor Input
    //--------------------------------------------------------------------------

    input  wire                                 desc_valid_i,
    input  wire [`RTDDMA_DESC_W-1:0]            desc_payload_i,
    input  wire [31:0]                          desc_crc_calc_i,

    //--------------------------------------------------------------------------
    // Security / Runtime Inputs
    //--------------------------------------------------------------------------

    input  wire [`RTDDMA_SEQ_ID_W-1:0]          expected_seq_i,
    input  wire                                 vmid_ok_i,
    input  wire                                 priv_ok_i,

    input  wire [`RTDDMA_ADDR_W-1:0]            mpu_base_i,
    input  wire [`RTDDMA_ADDR_W-1:0]            mpu_limit_i,

    input  wire                                 slice_busy_i,
    input  wire                                 outstanding_busy_i,
    input  wire                                 fifo_nonempty_i,

    input  wire [7:0]                           current_chain_depth_i,

    //--------------------------------------------------------------------------
    // Outputs
    //--------------------------------------------------------------------------

    output reg                                  ctx_accept_pulse_o,
    output reg                                  ctx_reject_pulse_o,
    output reg                                  exec_enable_o,

    output reg [`RTDDMA_DESC_W-1:0]             active_ctx_o,

    //--------------------------------------------------------------------------
    // Fault Outputs
    //--------------------------------------------------------------------------

    output reg                                  fault_valid_o,
    output reg [7:0]                            fault_code_o,
    output reg [3:0]                            fault_state_o,
    output reg [31:0]                           fault_info_o
);

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

reg [`RTDDMA_STATE_W-1:0] state_q;
reg [`RTDDMA_STATE_W-1:0] state_d;

///////////////////////////////////////////////////////////////////////////////
// FSM PARITY
///////////////////////////////////////////////////////////////////////////////

reg  state_parity_q;
wire state_parity_calc;
wire state_parity_error;

assign state_parity_calc  = ^state_q;
assign state_parity_error = (state_parity_calc != state_parity_q);

///////////////////////////////////////////////////////////////////////////////
// SHADOW DESCRIPTOR
///////////////////////////////////////////////////////////////////////////////

reg  [`RTDDMA_DESC_W-1:0] shadow_desc_q;
reg                       shadow_desc_parity_q;

wire shadow_desc_parity_calc;
wire shadow_desc_parity_error;

assign shadow_desc_parity_calc  = ^shadow_desc_q;
assign shadow_desc_parity_error =
    (shadow_desc_parity_calc != shadow_desc_parity_q);

///////////////////////////////////////////////////////////////////////////////
// ACTIVE CONTEXT PARITY
///////////////////////////////////////////////////////////////////////////////

reg active_ctx_parity_q;

wire active_ctx_parity_calc;
wire active_ctx_parity_error;

assign active_ctx_parity_calc  = ^active_ctx_o;
assign active_ctx_parity_error =
    (active_ctx_parity_calc != active_ctx_parity_q);

///////////////////////////////////////////////////////////////////////////////
// WORD EXTRACTION
///////////////////////////////////////////////////////////////////////////////

wire [31:0] w0;
wire [31:0] w1;
wire [31:0] w2;
wire [31:0] w3;
wire [31:0] w4;
wire [31:0] w5;
wire [31:0] w6;
wire [31:0] w7;

assign w0 = `RTDDMA_DESC_W0(shadow_desc_q);
assign w1 = `RTDDMA_DESC_W1(shadow_desc_q);
assign w2 = `RTDDMA_DESC_W2(shadow_desc_q);
assign w3 = `RTDDMA_DESC_W3(shadow_desc_q);
assign w4 = `RTDDMA_DESC_W4(shadow_desc_q);
assign w5 = `RTDDMA_DESC_W5(shadow_desc_q);
assign w6 = `RTDDMA_DESC_W6(shadow_desc_q);
assign w7 = `RTDDMA_DESC_W7(shadow_desc_q);

///////////////////////////////////////////////////////////////////////////////
// FIELD EXTRACTION
///////////////////////////////////////////////////////////////////////////////

wire        valid_bit;
wire [1:0]  route_mode;
wire [1:0]  exec_mode;
wire [3:0]  alu_op;
wire [1:0]  src_width;
wire [1:0]  dst_width;
wire [3:0]  burst_len;
wire [1:0]  burst_type;
wire [1:0]  addr_mode;
wire [8:0]  seq_id;

wire [`RTDDMA_ADDR_W-1:0] src_addr;
wire [`RTDDMA_ADDR_W-1:0] dst_addr;
wire [`RTDDMA_ADDR_W-1:0] next_desc_addr;

assign valid_bit      = `RTDDMA_DESC_VALID(w0);
assign route_mode     = `RTDDMA_DESC_ROUTE_MODE(w0);
assign exec_mode      = `RTDDMA_DESC_EXEC_MODE(w0);
assign alu_op         = `RTDDMA_DESC_ALU_OP(w0);
assign src_width      = `RTDDMA_DESC_SRC_WIDTH(w0);
assign dst_width      = `RTDDMA_DESC_DST_WIDTH(w0);
assign burst_len      = `RTDDMA_DESC_BURST_LEN(w0);
assign burst_type     = `RTDDMA_DESC_BURST_TYPE(w0);
assign addr_mode      = `RTDDMA_DESC_ADDR_MODE(w0);
assign seq_id         = `RTDDMA_DESC_SEQ_ID(w0);

assign src_addr       = w1;
assign dst_addr       = w2;

assign next_desc_addr =
    `RTDDMA_DESC_NEXT_PTR(w6);

///////////////////////////////////////////////////////////////////////////////
// SIZE DECODE
///////////////////////////////////////////////////////////////////////////////

reg [2:0] src_size_bytes;
reg [2:0] dst_size_bytes;

always @(*) begin

    case (src_width)

        2'b00: src_size_bytes = 3'd1;
        2'b01: src_size_bytes = 3'd2;
        2'b10: src_size_bytes = 3'd4;
        2'b11: src_size_bytes = 3'd8;

        default:
            src_size_bytes = 3'd1;
    endcase
end

always @(*) begin

    case (dst_width)

        2'b00: dst_size_bytes = 3'd1;
        2'b01: dst_size_bytes = 3'd2;
        2'b10: dst_size_bytes = 3'd4;
        2'b11: dst_size_bytes = 3'd8;

        default:
            dst_size_bytes = 3'd1;
    endcase
end

///////////////////////////////////////////////////////////////////////////////
// LOOP / TRANSFER SIZE
///////////////////////////////////////////////////////////////////////////////

wire [15:0] x_count;
wire [15:0] y_count;

assign x_count = w3[31:16];
assign y_count = w4[31:16];

wire [31:0] total_bytes_src;
wire [31:0] total_bytes_dst;

assign total_bytes_src =
    x_count * y_count * src_size_bytes;

assign total_bytes_dst =
    x_count * y_count * dst_size_bytes;

///////////////////////////////////////////////////////////////////////////////
// STAGE0 CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_crc_fail;
wire chk_valid_fail;
wire chk_seq_fail;

wire chk_route_fail;
wire chk_exec_fail;
wire chk_alu_fail;
wire chk_addrmode_fail;

wire chk_burst_fail;
wire chk_bursttype_fail;

wire chk_reserved_fail;

wire chk_src_align_fail;
wire chk_dst_align_fail;

assign chk_crc_fail =
    (desc_crc_calc_i != w7);

assign chk_valid_fail =
    (valid_bit != 1'b1);

assign chk_seq_fail =
    (seq_id != expected_seq_i);

assign chk_route_fail =
    (route_mode > 2'b11);

assign chk_exec_fail =
    (exec_mode > 2'b10);

assign chk_alu_fail =
    (alu_op > 4'h8);

assign chk_addrmode_fail =
    (addr_mode > 2'b11);

assign chk_burst_fail =
(
    (burst_len == 4'd0) ||
    (burst_len > 4'd16)
);

assign chk_bursttype_fail =
    (burst_type > 2'b01);

assign chk_reserved_fail =
    (w0[10:9] != 2'b00);

assign chk_src_align_fail =
(
    (src_width == 2'b01) &&
    (src_addr[0] != 1'b0)
)
||
(
    (src_width == 2'b10) &&
    (src_addr[1:0] != 2'b00)
)
||
(
    (src_width == 2'b11) &&
    (src_addr[2:0] != 3'b000)
);

assign chk_dst_align_fail =
(
    (dst_width == 2'b01) &&
    (dst_addr[0] != 1'b0)
)
||
(
    (dst_width == 2'b10) &&
    (dst_addr[1:0] != 2'b00)
)
||
(
    (dst_width == 2'b11) &&
    (dst_addr[2:0] != 3'b000)
);

///////////////////////////////////////////////////////////////////////////////
// STAGE1 CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_vmid_fail;
wire chk_priv_fail;

wire chk_src_mpu_fail;
wire chk_dst_mpu_fail;

wire chk_link_align_fail;
wire chk_link_mpu_fail;

assign chk_vmid_fail =
    (vmid_ok_i != 1'b1);

assign chk_priv_fail =
    (priv_ok_i != 1'b1);

assign chk_src_mpu_fail =
(
    (src_addr < mpu_base_i) ||
    (src_addr > mpu_limit_i)
);

assign chk_dst_mpu_fail =
(
    (dst_addr < mpu_base_i) ||
    (dst_addr > mpu_limit_i)
);

assign chk_link_align_fail =
    (next_desc_addr[4:0] != 5'b00000);

assign chk_link_mpu_fail =
(
    (next_desc_addr < mpu_base_i) ||
    (next_desc_addr > mpu_limit_i)
);

///////////////////////////////////////////////////////////////////////////////
// STAGE2 CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_src_overflow_fail;
wire chk_dst_overflow_fail;

wire chk_xcount_fail;
wire chk_ycount_fail;

wire chk_timeout_fail;

wire chk_chain_depth_fail;

wire chk_busy_commit_fail;

wire chk_self_link_fail;

assign chk_src_overflow_fail =
(
    (src_addr + total_bytes_src) < src_addr
);

assign chk_dst_overflow_fail =
(
    (dst_addr + total_bytes_dst) < dst_addr
);

assign chk_xcount_fail =
    (x_count == 16'd0);

assign chk_ycount_fail =
    (y_count == 16'd0);

assign chk_timeout_fail =
    (w5[15:6] == 10'd0);

assign chk_chain_depth_fail =
    (current_chain_depth_i >= 8'd16);

assign chk_busy_commit_fail =
(
    slice_busy_i |
    outstanding_busy_i |
    fifo_nonempty_i
);

assign chk_self_link_fail =
    (next_desc_addr == src_addr);

///////////////////////////////////////////////////////////////////////////////
// PARALLEL AGGREGATION
///////////////////////////////////////////////////////////////////////////////

wire any_stage0_fail;
wire any_stage1_fail;
wire any_stage2_fail;

assign any_stage0_fail =
       chk_crc_fail
    || chk_valid_fail
    || chk_seq_fail
    || chk_route_fail
    || chk_exec_fail
    || chk_alu_fail
    || chk_addrmode_fail
    || chk_burst_fail
    || chk_bursttype_fail
    || chk_reserved_fail
    || chk_src_align_fail
    || chk_dst_align_fail;

assign any_stage1_fail =
       chk_vmid_fail
    || chk_priv_fail
    || chk_src_mpu_fail
    || chk_dst_mpu_fail
    || chk_link_align_fail
    || chk_link_mpu_fail;

assign any_stage2_fail =
       chk_src_overflow_fail
    || chk_dst_overflow_fail
    || chk_xcount_fail
    || chk_ycount_fail
    || chk_timeout_fail
    || chk_chain_depth_fail
    || chk_busy_commit_fail
    || chk_self_link_fail;

///////////////////////////////////////////////////////////////////////////////
// TIMEOUT WATCHDOG
///////////////////////////////////////////////////////////////////////////////

reg [15:0] timeout_cnt_q;

wire validation_timeout;

assign validation_timeout =
    (timeout_cnt_q >= 16'd1024);

///////////////////////////////////////////////////////////////////////////////
// FIRST FAULT STICKY
///////////////////////////////////////////////////////////////////////////////

reg first_fault_seen_q;

///////////////////////////////////////////////////////////////////////////////
// PRIORITY ENCODER
///////////////////////////////////////////////////////////////////////////////

reg [7:0]  pri_fault_code;
reg [31:0] pri_fault_info;

always @(*) begin

    pri_fault_code = `RTDDMA_FAULT_NONE;
    pri_fault_info = 32'h00000000;

    if (chk_crc_fail) begin
        pri_fault_code = `RTDDMA_FAULT_DESC_CRC;
    end
    else if (chk_src_mpu_fail) begin
        pri_fault_code = `RTDDMA_FAULT_SRC_MPU;
        pri_fault_info = src_addr;
    end
    else if (chk_dst_mpu_fail) begin
        pri_fault_code = `RTDDMA_FAULT_DST_MPU;
        pri_fault_info = dst_addr;
    end
    else if (chk_vmid_fail) begin
        pri_fault_code = `RTDDMA_FAULT_VMID;
    end
    else if (chk_seq_fail) begin
        pri_fault_code = `RTDDMA_FAULT_SEQ;
    end
    else if (chk_src_align_fail) begin
        pri_fault_code = `RTDDMA_FAULT_SRC_ALIGN;
        pri_fault_info = src_addr;
    end
    else if (chk_dst_align_fail) begin
        pri_fault_code = `RTDDMA_FAULT_DST_ALIGN;
        pri_fault_info = dst_addr;
    end
    else if (chk_busy_commit_fail) begin
        pri_fault_code = `RTDDMA_FAULT_BUSY_COMMIT;
    end
end

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    state_d = state_q;

    case (state_q)

        `RTDDMA_ST_IDLE: begin

            if (desc_valid_i)
                state_d = `RTDDMA_ST_FREEZE;
        end

        `RTDDMA_ST_FREEZE: begin

            state_d = `RTDDMA_ST_CHECK0;
        end

        `RTDDMA_ST_CHECK0: begin

            if (validation_timeout)
                state_d = `RTDDMA_ST_FAULT;
            else if (any_stage0_fail)
                state_d = `RTDDMA_ST_REJECT;
            else
                state_d = `RTDDMA_ST_CHECK1;
        end

        `RTDDMA_ST_CHECK1: begin

            if (validation_timeout)
                state_d = `RTDDMA_ST_FAULT;
            else if (any_stage1_fail)
                state_d = `RTDDMA_ST_REJECT;
            else
                state_d = `RTDDMA_ST_CHECK2;
        end

        `RTDDMA_ST_CHECK2: begin

            if (validation_timeout)
                state_d = `RTDDMA_ST_FAULT;
            else if (any_stage2_fail)
                state_d = `RTDDMA_ST_REJECT;
            else
                state_d = `RTDDMA_ST_ACCEPT;
        end

        `RTDDMA_ST_ACCEPT: begin

            state_d = `RTDDMA_ST_IDLE;
        end

        `RTDDMA_ST_REJECT: begin

            state_d = `RTDDMA_ST_IDLE;
        end

        default: begin

            state_d = `RTDDMA_ST_FAULT;
        end
    endcase
end

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state_q                 <= `RTDDMA_ST_IDLE;
        state_parity_q          <= 1'b0;

        shadow_desc_q           <= {`RTDDMA_DESC_W{1'b0}};
        shadow_desc_parity_q    <= 1'b0;

        active_ctx_o            <= {`RTDDMA_DESC_W{1'b0}};
        active_ctx_parity_q     <= 1'b0;

        timeout_cnt_q           <= 16'd0;

        ctx_accept_pulse_o      <= 1'b0;
        ctx_reject_pulse_o      <= 1'b0;

        exec_enable_o           <= 1'b0;

        first_fault_seen_q      <= 1'b0;

        fault_valid_o           <= 1'b0;
        fault_code_o            <= `RTDDMA_FAULT_NONE;
        fault_state_o           <= 4'd0;
        fault_info_o            <= 32'h0;

    end
    else begin

        state_q <= state_d;

        state_parity_q <= ^state_d;

        ctx_accept_pulse_o <= 1'b0;
        ctx_reject_pulse_o <= 1'b0;

        //----------------------------------------------------------------------
        // Timeout
        //----------------------------------------------------------------------

        if (state_q != `RTDDMA_ST_IDLE)
            timeout_cnt_q <= timeout_cnt_q + 1'b1;
        else
            timeout_cnt_q <= 16'd0;

        //----------------------------------------------------------------------
        // Freeze
        //----------------------------------------------------------------------

        if (state_q == `RTDDMA_ST_FREEZE) begin

            shadow_desc_q <= desc_payload_i;

            shadow_desc_parity_q <=
                ^desc_payload_i;
        end

        //----------------------------------------------------------------------
        // Accept
        //----------------------------------------------------------------------

        if (state_q == `RTDDMA_ST_ACCEPT) begin

            ctx_accept_pulse_o <= 1'b1;

            active_ctx_o <= shadow_desc_q;

            active_ctx_parity_q <=
                ^shadow_desc_q;

            exec_enable_o <= 1'b1;
        end

        //----------------------------------------------------------------------
        // Reject
        //----------------------------------------------------------------------

        if (state_q == `RTDDMA_ST_REJECT) begin

            ctx_reject_pulse_o <= 1'b1;

            exec_enable_o <= 1'b0;
        end

        //----------------------------------------------------------------------
        // Fault Capture
        //----------------------------------------------------------------------

        if (
            any_stage0_fail ||
            any_stage1_fail ||
            any_stage2_fail ||
            validation_timeout ||
            state_parity_error ||
            shadow_desc_parity_error ||
            active_ctx_parity_error
        ) begin

            if (!first_fault_seen_q) begin

                first_fault_seen_q <= 1'b1;

                fault_valid_o <= 1'b1;

                fault_code_o  <= pri_fault_code;

                fault_state_o <= state_q;

                fault_info_o  <= pri_fault_info;
            end
        end
    end
end

endmodule

`default_nettype wire