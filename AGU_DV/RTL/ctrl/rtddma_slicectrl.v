//==============================================================================
//  Project      : RTDDMA (Real-Time Deterministic DMA)
//  Module       : rtddmaslicectrl
//  File         : rtddmaslicectrl.v
//  Author       : S Rishik Nair
//  Created On   : 05-05-2026
//==============================================================================
//------------------------------------------------------------------------------
//  Description  :
//------------------------------------------------------------------------------
//  ASIL-D hardened slice control FSM for a real-time deterministic DMA engine.
//  Orchestrates descriptor fetch, validation, execution, and AXI drain with
//  fault containment, timeout supervision, and safe halt/resume handling.
//
//------------------------------------------------------------------------------
//  Functional Overview :
//------------------------------------------------------------------------------
//  - Controls end-to-end DMA slice flow: Fetch → Validate → Execute → Drain
//  - Enforces handshake-driven, deterministic sequencing across all stages
//  - Monitors timeouts, faults, and illegal states with first-fault latching
//
//------------------------------------------------------------------------------
//  Interfaces :
//------------------------------------------------------------------------------
//  Inputs  :
//    - clk, rst_n           : Clock and active-low reset
//    - cfg_slice_en         : Enables slice operation
//    - start_event_async    : External trigger (synchronized internally)
//    - fetch_done/fault     : Descriptor fetch completion/status
//    - val_done/pass/fault  : Validation results
//    - exec_done/fault      : Execution status
//    - outstanding_rd/wr    : AXI outstanding transaction counters
//
//  Outputs :
//    - fetch_cmd_valid      : Initiates descriptor fetch
//    - val_req_valid        : Triggers validation stage
//    - exec_cmd_valid_a/b   : Redundant execution command signals
//    - issue_block          : Blocks new AXI requests during drain/fault
//    - slice_busy           : Indicates active or draining state
//    - slice_fault_active   : Sticky fault indication
//    - slice_complete_pulse : Indicates successful completion
//
//------------------------------------------------------------------------------
//  Key Features :
//------------------------------------------------------------------------------
//  - Deterministic one-hot FSM with illegal state detection
//  - Handshake-based control (no pulse-driven hazards)
//  - Independent per-stage timeout supervision (forward progress guarantee)
//  - AXI-safe drain using outstanding transaction tracking
//  - Redundant execution control with mismatch detection
//  - Safe halt with context preservation and controlled resume
//
//------------------------------------------------------------------------------
//  Safety (ASIL-D) Considerations :
//------------------------------------------------------------------------------
//  - No execution without successful validation (atomic commit boundary)
//  - All outputs default to safe values on reset/fault
//  - Illegal state or SEU → immediate transition to FAULT
//  - First detected fault is latched and held until cleared
//  - Timeouts enforce bounded latency and prevent deadlock
//  - Sequence guards prevent duplicate or out-of-order execution
//
//------------------------------------------------------------------------------
//  Failure Modes Covered :
//------------------------------------------------------------------------------
//  - Timeout / no forward progress
//  - Descriptor validation failure
//  - Execution/datapath faults
//  - AXI drain stall or incomplete transactions
//  - FSM state corruption (SEU)
//  - Redundant control signal mismatch
//
//------------------------------------------------------------------------------
//  Assumptions :
//------------------------------------------------------------------------------
//  - AXI subsystem correctly tracks outstanding_rd/wr
//  - Submodules follow valid/ready handshake protocol
//  - start_event_async is a pulse (internally synchronized)
//  - Clock is stable and reset is asynchronous active-low
//
//------------------------------------------------------------------------------
//  Limitations :
//------------------------------------------------------------------------------
//  - Single FSM (no TMR or lockstep redundancy at controller level)
//  - Does not guarantee datapath rollback on partial execution
//  - External modules must ensure protocol correctness and integrity
//
//------------------------------------------------------------------------------
//  Dependencies :
//------------------------------------------------------------------------------
//  - `include "rtdma_params.vh"
//
//------------------------------------------------------------------------------
//  Revision History :
//------------------------------------------------------------------------------
//  Version | Date       | Author              | Description
//  --------|------------|---------------------|-----------------------------
//   1.0    | 05-05-2026 | S Rishik Nair       | Initial ASIL-D hardened FSM
//==============================================================================

`include "rtdma_params.vh"

module rtddmaslicectrl (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        cfg_slice_en,
    input  wire        start_event_async,
    input  wire        clear_fault_pulse,
    input  wire        global_safe_halt,

    // Fetch
    output reg         fetch_cmd_valid,
    input  wire        fetch_cmd_ready,
    input  wire        fetch_done,
    input  wire        fetch_fault,
    input  wire [3:0]  fetch_fault_type,

    // Validate
    output reg         val_req_valid,
    input  wire        val_done,
    input  wire        val_pass,
    input  wire        val_fault,
    input  wire [3:0]  val_fault_type,
    output reg         ctx_accept_pulse,

    // Execute
    output reg         exec_cmd_valid_a,
    output reg         exec_cmd_valid_b,
    input  wire        exec_cmd_ready,
    input  wire        exec_done,
    input  wire        exec_fault,
    input  wire [3:0]  exec_fault_type,

    // Drain
    output reg         issue_block,
    input  wire [7:0]  outstanding_rd,
    input  wire [7:0]  outstanding_wr,

    // Timeouts
    input  wire [15:0] fetch_timeout_cfg,
    input  wire [15:0] val_timeout_cfg,
    input  wire [15:0] exec_timeout_cfg,
    input  wire [15:0] drain_timeout_cfg,

    // Status
    output wire        slice_busy,
    output reg         slice_fault_active,
    output reg [3:0]   latched_fault_src,
    output reg [3:0]   latched_fault_type,
    output reg         slice_complete_pulse
);

    // ============================================================
    // START EVENT SYNC (2-flop)
    // ============================================================
    reg start_ff1, start_ff2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_ff1 <= 0;
            start_ff2 <= 0;
        end else begin
            start_ff1 <= start_event_async;
            start_ff2 <= start_ff1;
        end
    end
    wire start_event = start_ff1 & ~start_ff2;

    // ============================================================
    // STATES (ONE HOT)
    // ============================================================
    localparam S_IDLE          = 11'b00000000001;
    localparam S_FETCH_REQ     = 11'b00000000010;
    localparam S_FETCH_WAIT    = 11'b00000000100;
    localparam S_VALIDATE_REQ  = 11'b00000001000;
    localparam S_VALIDATE_WAIT = 11'b00000010000;
    localparam S_EXECUTE       = 11'b00000100000;
    localparam S_DRAIN         = 11'b00001000000;
    localparam S_COMPLETE      = 11'b00010000000;
    localparam S_FAULT         = 11'b00100000000;
    localparam S_SAFE_HALT     = 11'b01000000000;
    localparam S_RESUME_EVAL   = 11'b10000000000;

    reg [10:0] state, next_state_raw, next_state_safe;

    // ============================================================
    // STATE VALIDITY (NO FUNCTION)
    // ============================================================
    wire current_valid;
    wire next_valid;

    assign current_valid =
        (state == S_IDLE) || (state == S_FETCH_REQ) || (state == S_FETCH_WAIT) ||
        (state == S_VALIDATE_REQ) || (state == S_VALIDATE_WAIT) ||
        (state == S_EXECUTE) || (state == S_DRAIN) || (state == S_COMPLETE) ||
        (state == S_FAULT) || (state == S_SAFE_HALT) || (state == S_RESUME_EVAL);

    assign next_valid =
        (next_state_raw == S_IDLE) || (next_state_raw == S_FETCH_REQ) ||
        (next_state_raw == S_FETCH_WAIT) || (next_state_raw == S_VALIDATE_REQ) ||
        (next_state_raw == S_VALIDATE_WAIT) || (next_state_raw == S_EXECUTE) ||
        (next_state_raw == S_DRAIN) || (next_state_raw == S_COMPLETE) ||
        (next_state_raw == S_FAULT) || (next_state_raw == S_SAFE_HALT) ||
        (next_state_raw == S_RESUME_EVAL);

    always @* begin
        if (!current_valid || !next_valid)
            next_state_safe = S_FAULT;
        else
            next_state_safe = next_state_raw;
    end

    // ============================================================
    // TIMEOUTS (>= FIX)
    // ============================================================
    reg [15:0] f_cnt, v_cnt, e_cnt, d_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            f_cnt <= 0; v_cnt <= 0; e_cnt <= 0; d_cnt <= 0;
        end else begin
            f_cnt <= (state == S_FETCH_WAIT)    ? f_cnt + 1 : 0;
            v_cnt <= (state == S_VALIDATE_WAIT) ? v_cnt + 1 : 0;
            e_cnt <= (state == S_EXECUTE)       ? e_cnt + 1 : 0;
            d_cnt <= (state == S_DRAIN)         ? d_cnt + 1 : 0;
        end
    end

    wire fetch_tmo = (f_cnt >= fetch_timeout_cfg);
    wire val_tmo   = (v_cnt >= val_timeout_cfg);
    wire exec_tmo  = (e_cnt >= exec_timeout_cfg);
    wire drain_tmo = (d_cnt >= drain_timeout_cfg);

    // ============================================================
    // SEQUENCE GUARDS
    // ============================================================
    reg fetch_issued, val_issued, exec_issued;

    // ============================================================
    // VALIDATION LATCH
    // ============================================================
    reg val_pass_latched;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            val_pass_latched <= 0;
        else if (val_done)
            val_pass_latched <= val_pass;
    end

    // ============================================================
    // STATE REGISTER
    // ============================================================
    reg [10:0] pre_halt_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            pre_halt_state <= S_IDLE;
            fetch_issued <= 0;
            val_issued <= 0;
            exec_issued <= 0;
        end else begin
            if (global_safe_halt && state != S_SAFE_HALT) begin
                pre_halt_state <= state;
                state <= S_SAFE_HALT;
            end else if (!global_safe_halt && state == S_SAFE_HALT) begin
                state <= S_RESUME_EVAL;
            end else begin
                state <= next_state_safe;
            end

            if (state == S_IDLE) begin
                fetch_issued <= 0;
                val_issued   <= 0;
                exec_issued  <= 0;
            end

            if (fetch_cmd_valid && fetch_cmd_ready) fetch_issued <= 1;
            if (val_req_valid && val_done)          val_issued   <= 1;
            if (exec_cmd_valid_a && exec_cmd_ready) exec_issued  <= 1;
        end
    end

    // ============================================================
    // OUTPUT LOGIC
    // ============================================================
    wire drain_empty = (outstanding_rd == 0) && (outstanding_wr == 0);
    assign slice_busy = (state != S_IDLE) || !drain_empty;

    always @* begin
        next_state_raw = state;

        fetch_cmd_valid = 0;
        val_req_valid = 0;
        exec_cmd_valid_a = 0;
        exec_cmd_valid_b = 0;
        ctx_accept_pulse = 0;
        slice_complete_pulse = 0;
        issue_block = 1;

        case (state)

        S_IDLE:
            if (cfg_slice_en && start_event)
                next_state_raw = S_FETCH_REQ;

        S_FETCH_REQ: begin
            issue_block = 0;
            if (!fetch_issued) fetch_cmd_valid = 1;
            if (fetch_cmd_ready) next_state_raw = S_FETCH_WAIT;
        end

        S_FETCH_WAIT: begin
            issue_block = 0;
            if (fetch_fault || fetch_tmo)
                next_state_raw = S_FAULT;
            else if (fetch_done && fetch_issued)
                next_state_raw = S_VALIDATE_REQ;
        end

        S_VALIDATE_REQ: begin
            if (!val_issued) val_req_valid = 1;
            if (val_done) next_state_raw = S_VALIDATE_WAIT;
        end

        S_VALIDATE_WAIT: begin
            if (val_fault || val_tmo)
                next_state_raw = S_FAULT;
            else if (val_pass_latched) begin
                ctx_accept_pulse = 1;
                next_state_raw = S_EXECUTE;
            end
        end

        S_EXECUTE: begin
            issue_block = 0;
            if (!exec_issued) begin
                exec_cmd_valid_a = 1;
                exec_cmd_valid_b = 1;
            end

            if (exec_fault || exec_tmo)
                next_state_raw = S_FAULT;
            else if (exec_done && exec_issued)
                next_state_raw = S_DRAIN;
        end

        S_DRAIN: begin
            if (drain_tmo)
                next_state_raw = S_FAULT;
            else if (drain_empty)
                next_state_raw = S_COMPLETE;
        end

        S_COMPLETE: begin
            slice_complete_pulse = 1;
            next_state_raw = S_IDLE;
        end

        S_SAFE_HALT: begin
            issue_block = 1;
        end

        S_RESUME_EVAL: begin
            if (pre_halt_state == S_EXECUTE || pre_halt_state == S_DRAIN)
                next_state_raw = S_DRAIN;
            else
                next_state_raw = S_IDLE;
        end

        S_FAULT: begin
            if (clear_fault_pulse && !global_safe_halt)
                next_state_raw = drain_empty ? S_IDLE : S_DRAIN;
        end

        default:
            next_state_raw = S_FAULT;

        endcase
    end

    // ============================================================
    // REDUNDANCY CHECK
    // ============================================================
    wire exec_mismatch = (exec_cmd_valid_a != exec_cmd_valid_b);

    // ============================================================
    // FAULT LATCH
    // ============================================================
    localparam SRC_NONE=0, SRC_FETCH=1, SRC_VAL=2, SRC_EXEC=3,
               SRC_DRAIN=4, SRC_SEU=5, SRC_GLOBAL=6;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slice_fault_active <= 0;
            latched_fault_src  <= SRC_NONE;
            latched_fault_type <= 0;
        end else if (clear_fault_pulse) begin
            slice_fault_active <= 0;
            latched_fault_src  <= SRC_NONE;
            latched_fault_type <= 0;
        end else if (!slice_fault_active) begin

            if (exec_mismatch) begin
                slice_fault_active <= 1;
                latched_fault_src  <= SRC_EXEC;
                latched_fault_type <= 4'hD;
            end
            else if (!current_valid || !next_valid) begin
                slice_fault_active <= 1;
                latched_fault_src  <= SRC_SEU;
                latched_fault_type <= 4'hF;
            end
            else if (global_safe_halt) begin
                slice_fault_active <= 1;
                latched_fault_src  <= SRC_GLOBAL;
            end
            else if (fetch_fault || fetch_tmo) begin
                slice_fault_active <= 1;
                latched_fault_src  <= SRC_FETCH;
                latched_fault_type <= fetch_fault_type;
            end
            else if (val_fault || val_tmo) begin
                slice_fault_active <= 1;
                latched_fault_src  <= SRC_VAL;
                latched_fault_type <= val_fault_type;
            end
            else if (exec_fault || exec_tmo) begin
                slice_fault_active <= 1;
                latched_fault_src  <= SRC_EXEC;
                latched_fault_type <= exec_fault_type;
            end
            else if (drain_tmo) begin
                slice_fault_active <= 1;
                latched_fault_src  <= SRC_DRAIN;
            end
        end
    end

endmodule