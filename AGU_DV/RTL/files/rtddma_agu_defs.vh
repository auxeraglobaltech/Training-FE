//==============================================================================
//  Project      : RTDDMA (Real-Time Deterministic DMA)
//  Module       : include
//  File         : rtdma_faultcodes.vh
//  Author       : S Rishik Nair
//  Created On   : 10-05-2026
//------------------------------------------------------------------------------
//  Description  :
//  -----------------------------------------------------------------------------
//   Centralized fault taxonomy for the RTDDMA ASIL-D DMA controller.
//  Encodes fault IDs, severities, escalation actions, and source IDs so that
//  every RTL block reports safety events in a uniform, analyzable format.
//
//------------------------------------------------------------------------------
//  Functional Overview :
//  -----------------------------------------------------------------------------
// - Defines global widths for fault code, severity, action, and source fields
//    used on all internal safety/fault buses.
//  - Enumerates fault severities from informational up to GLOBAL,
//    enforcing a monotonic ordering for prioritization and arbitration.
//  - Enumerates safety actions (IRQ, slice halt/drain, global halt, safe state)
//    that the safety controller or top-level FSM can trigger.
//  - Assigns unique source IDs for each functional block (desc path, AGU/MPU,
//    FIFOs, AXI channels, CDC, FSM, config, etc.) to support first-fault capture
//    and post-mortem diagnostics.
//  - Provides categorized fault codes for descriptor, AXI/fabric, MPU/address,
//    FIFO/memory, FSM/control, CDC/reset, config/security, payload/data,
//    and internal safety mechanisms (SEU/DMR).
//  - Supplies default classification macros mapping a fault code to a
//    recommended severity and action, with the option for the safety controller
//    to override at runtime.
//
//------------------------------------------------------------------------------
//  Interfaces / Usage :
//  -----------------------------------------------------------------------------
//- All RTL modules that detect an error must:
//      * Use these `RTDDMA_FAULT_*` codes instead of local encodings.
//      * Tag the originating block with `RTDDMA_SRC_*`.
//      * Classify severity via `RTDDMA_CLASS_SEV(code)` unless a local
//        override is justified and documented.
//      * Classify the reaction via `RTDDMA_CLASS_ACTION(code)` to select
//        IRQ-only, slice-level containment, or global safe-state actions.
//  - Typical fault record fields:
//      * fault_valid : 1b       (use `RTDDMA_FAULT_VALID` when asserted)
//      * fault_code  : 8b       (one of the `RTDDMA_FAULT_*` values)
//      * fault_sev   : 3b       (from `RTDDMA_SEV_*` or classification macro)
//      * fault_act   : 3b       (from `RTDDMA_ACTION_*` or classification macro)
//      * fault_src   : 6b       (one of the `RTDDMA_SRC_*` values)
//
/------------------------------------------------------------------------------
//  Key Safety Semantics (ASIL-D) :
//  -----------------------------------------------------------------------------
//  - Descriptor faults (validity, CRC, MPU, opcode, chaining, etc.) capture
//    broken or malicious descriptors and can escalate up to GLOBAL severity
//    (e.g. MPU violations) to force a system safe state.
//  - AXI/fabric faults (RRESP/BRESP errors, timeout, protocol violations,
//    starvation, babbling) are mapped to strong actions such as slice drain,
//    global halt, or safe state to prevent bus lockup or interference with
//    other masters.
//  - MPU/address faults enforce access control and alignment; violations are
//    treated as high severity and typically drive SAFE_STATE or GLOBAL_HALT.
//  - FIFO/memory faults distinguish corrected versus uncorrected ECC,
//    so that correctable errors are logged (INFO/CORRECTED) but do not
//    silently vanish, while uncorrectable ones can be fatal.
//  - FSM/control and CDC/reset faults (illegal state, timeout, metastability,
//    invalid reset sequences) detect control-path corruption and force a
//    deterministic fault transition instead of undefined behavior.
//  - Internal safety faults (SEU detected, DMR mismatch, internal over/underflow)
//    capture failures of safety mechanisms themselves, which are treated as at
//    least FATAL and often force slice halt or higher action.
//
//------------------------------------------------------------------------------
//  Default Classification Macros :
//  -----------------------------------------------------------------------------
//  - `RTDDMA_CLASS_SEV(code)`
//      * Provides a default severity per fault code, e.g.:
//        - FIFO ECC corrected ? CORRECTED (logged but contained).
//        - Descriptor CRC / sequence errors ? FATAL (slice must stop).
//        - Descriptor MPU and AXI babbling ? GLOBAL (full DMA safe-state).
//        - SEU detected ? FATAL (safety mechanism compromised).
//        - All others ? RECOVERABLE by default, unless overridden.
//  - `RTDDMA_CLASS_ACTION(code)`
//      * Provides a default reaction for a fault code, e.g.:
//        - Descriptor MPU violation ? SAFE_STATE transition.
//        - AXI babbling ? GLOBAL_HALT to protect shared fabric.
//        - AXI timeout ? SLICE_DRAIN to flush outstanding traffic.
//        - Descriptor CRC / SEU detected ? SLICE_HALT.
//        - All others ? IRQ (software handles, but event is not ignored).
//  - The safety controller may override these defaults dynamically based on
//    system mode, safety goal, or field updates.
//
//------------------------------------------------------------------------------
//  Professional Safety Rules (Design Constraints) :
//  -----------------------------------------------------------------------------
//  - No module may invent local fault encodings; all faults must use this
//    centralized scheme to keep FMEDA, FMEA, and safety metrics consistent.
//  - All FATAL and GLOBAL severity faults must be sticky until a controlled
//    safety reset or explicit clear, so they cannot be lost by transient events.
//  - First-fault capture has priority; once a fault record is latched, later
//    faults must not overwrite it without explicit policy, preserving debug
//    and diagnostic traceability.
//  - GLOBAL severity faults must terminate new AXI issues and drive the DMA
//    toward safe state, preventing continued unsafe bus activity.
//  - Correctable faults (e.g., ECC-corrected) must never disappear silently;
//    they must at least raise an INFO/CORRECTED event for latent fault metrics.
//
//==============================================================================
// PROFESSIONAL SAFETY RULES
//==============================================================================
//
// 1. No module may invent local fault encodings.
// 2. All fatal faults must be sticky.
// 3. First-fault capture has priority over subsequent faults.
// 4. GLOBAL severity faults must terminate AXI issue.
// 5. Correctable faults must never silently disappear.
//==============================================================================
//------------------------------------------------------------------------------
//  Assumptions / Integration Notes :
//  -----------------------------------------------------------------------------
//  - System safety documentation (ISO 26262 / IEC 61508) maps these fault codes
//    to safety goals and hardware safety requirements in the safety manual.
//  - Safety verification (fault injection, FMEDA correlation) assumes that
//    every safety-related module reports through this header and that
//    classification macros are used consistently unless justified otherwise.
//
//------------------------------------------------------------------------------
//  Limitations :
//  -----------------------------------------------------------------------------
//  - Haven't completed yet
//
//------------------------------------------------------------------------------
//  Dependencies :
//  -----------------------------------------------------------------------------
// nil
// 
//------------------------------------------------------------------------------
//  Revision History :
//  -----------------------------------------------------------------------------
//  Version | Date       | Author        | Description
//  --------|------------|---------------|-------------------------------
//   0.1    | 10-05-2026 | rishik        | Placehoolder version
//   1.0    | 11-05-2026 | rishik        | Descriptor-ready version
//   1.1    | 13-05-2026 | rishik        | AGU-code ready version
==============================================================================

`ifndef RTDDMA_FAULTCODES_VH
`define RTDDMA_FAULTCODES_VH

//==============================================================================
// ??GLOBAL FAULT WIDTHS
//==============================================================================

`define RTDDMA_FAULT_CODE_W          8
`define RTDDMA_FAULT_SEVERITY_W      3
`define RTDDMA_FAULT_ACTION_W        3
`define RTDDMA_FAULT_SRC_W           6

//==============================================================================
// ???FAULT VALIDITY
//==============================================================================

`define RTDDMA_FAULT_VALID           1'b1
`define RTDDMA_FAULT_NONE            8'h00

//==============================================================================
// ??FAULT SEVERITY LEVELS
//==============================================================================
//
// Severity increases monotonically.
//
// INFO      : diagnostic only
// CORRECTED : corrected by ECC/parity/etc
// RECOVERABLE : slice-local containment possible
// FATAL     : slice shutdown required
// GLOBAL    : entire DMA safe-state required
//
//==============================================================================

`define RTDDMA_SEV_INFO              3'd0
`define RTDDMA_SEV_CORRECTED         3'd1
`define RTDDMA_SEV_RECOVERABLE       3'd2
`define RTDDMA_SEV_FATAL             3'd3
`define RTDDMA_SEV_GLOBAL            3'd4

//==============================================================================
// ??SAFETY ACTIONS
//==============================================================================

`define RTDDMA_ACTION_NONE           3'd0
`define RTDDMA_ACTION_IRQ            3'd1
`define RTDDMA_ACTION_SLICE_HALT     3'd2
`define RTDDMA_ACTION_SLICE_DRAIN    3'd3
`define RTDDMA_ACTION_GLOBAL_HALT    3'd4
`define RTDDMA_ACTION_SAFE_STATE     3'd5

//==============================================================================
// FAULT SOURCE IDS
//==============================================================================
//
// Used by first-fault capture and telemetry.
//??????Warning: Final version available after complete code.  this is desc, crc part
//==============================================================================

`define RTDDMA_SRC_DESC_FETCH        6'd1
`define RTDDMA_SRC_DESC_PARSER       6'd2
`define RTDDMA_SRC_DESC_CRC          6'd3
`define RTDDMA_SRC_DESC_VALIDATOR    6'd4
`define RTDDMA_SRC_DESC_CHAIN        6'd5

`define RTDDMA_SRC_AGU               6'd10
`define RTDDMA_SRC_MPU               6'd11
`define RTDDMA_SRC_FIFO              6'd12
`define RTDDMA_SRC_CRC_PAYLOAD       6'd13

`define RTDDMA_SRC_AXI_AR            6'd20
`define RTDDMA_SRC_AXI_AW            6'd21
`define RTDDMA_SRC_AXI_W             6'd22
`define RTDDMA_SRC_AXI_R             6'd23
`define RTDDMA_SRC_AXI_B             6'd24

`define RTDDMA_SRC_TIMEOUT           6'd30
`define RTDDMA_SRC_CFG               6'd31
`define RTDDMA_SRC_FSM               6'd32
`define RTDDMA_SRC_CDC               6'd33

//==============================================================================
// DESCRIPTOR FAULTS
//==============================================================================

`define RTDDMA_FAULT_DESC_VALID          8'h01
`define RTDDMA_FAULT_DESC_CRC            8'h02
`define RTDDMA_FAULT_DESC_SEQ            8'h03
`define RTDDMA_FAULT_DESC_MPU            8'h04
`define RTDDMA_FAULT_DESC_VMID           8'h05
`define RTDDMA_FAULT_DESC_OPCODE         8'h06
`define RTDDMA_FAULT_DESC_RESERVED       8'h07
`define RTDDMA_FAULT_DESC_ALIGN          8'h08
`define RTDDMA_FAULT_DESC_LINK           8'h09
`define RTDDMA_FAULT_DESC_CHAIN_OVF      8'h0A

//==============================================================================
// AXI / FABRIC FAULTS
//==============================================================================

`define RTDDMA_FAULT_AXI_RRESP           8'h206 
//  
`define RTDDMA_FAULT_AXI_BRESP           8'h21
`define RTDDMA_FAULT_AXI_TIMEOUT         8'h22
`define RTDDMA_FAULT_AXI_PROTOCOL        8'h23
`define RTDDMA_FAULT_AXI_STARVATION      8'h24
`define RTDDMA_FAULT_AXI_BABBLING        8'h25

//==============================================================================
// MPU / ADDRESS FAULTS
//==============================================================================

`define RTDDMA_FAULT_MPU_REGION          8'h30
`define RTDDMA_FAULT_MPU_PERMISSION      8'h31
`define RTDDMA_FAULT_MPU_ALIGN           8'h32
`define RTDDMA_FAULT_MPU_BURST           8'h33
//==============================================================================
// AGU / ADDRESS GENERATION FAULTS
//==============================================================================

`define RTDDMA_FAULT_AGU_ADDR_OVERFLOW      8'h34
`define RTDDMA_FAULT_AGU_ADDR_WRAP          8'h35
`define RTDDMA_FAULT_AGU_XCOUNT_ZERO        8'h36
`define RTDDMA_FAULT_AGU_YCOUNT_ZERO        8'h37
`define RTDDMA_FAULT_AGU_STRIDE_OVERFLOW    8'h38
`define RTDDMA_FAULT_AGU_GATHER_OOB         8'h39
`define RTDDMA_FAULT_AGU_SCATTER_OOB        8'h3A
`define RTDDMA_FAULT_AGU_DETERMINISM        8'h3B
//==============================================================================
// FIFO / MEMORY FAULTS
//==============================================================================

`define RTDDMA_FAULT_FIFO_OVERFLOW       8'h40
`define RTDDMA_FAULT_FIFO_UNDERFLOW      8'h41
`define RTDDMA_FAULT_FIFO_ECC_CORR       8'h42
`define RTDDMA_FAULT_FIFO_ECC_UNCORR     8'h43

//==============================================================================
// FSM / CONTROL FAULTS
//==============================================================================

`define RTDDMA_FAULT_FSM_ILLEGAL_STATE   8'h50
`define RTDDMA_FAULT_FSM_TIMEOUT         8'h51
`define RTDDMA_FAULT_STATE_MISMATCH      8'h52

//==============================================================================
// CDC / RESET FAULTS
//==============================================================================

`define RTDDMA_FAULT_CDC_META            8'h60
`define RTDDMA_FAULT_RESET_SEQUENCE      8'h61

//==============================================================================
// CONFIG / SECURITY FAULTS
//==============================================================================

`define RTDDMA_FAULT_CFG_PARITY          8'h70
`define RTDDMA_FAULT_CFG_LOCK            8'h71
`define RTDDMA_FAULT_CFG_PRIV            8'h72
`define RTDDMA_FAULT_CFG_MASTER_ID       8'h73

//==============================================================================
// PAYLOAD / DATA FAULTS
//==============================================================================

`define RTDDMA_FAULT_PAYLOAD_CRC         8'h80
`define RTDDMA_FAULT_PAYLOAD_E2E         8'h81
//==============================================================================
// PING PONG / SWAP FAULTS
//==============================================================================

`define RTDDMA_FAULT_SWAP_COLLISION         8'hA0
`define RTDDMA_FAULT_SWAP_UNSAFE_BOUNDARY   8'hA1
`define RTDDMA_FAULT_PP_BUFFER_OVERLAP      8'hA2
`define RTDDMA_FAULT_PP_STATE_MISMATCH      8'hA3

//==============================================================================
// FREEDOM FROM INTERFERENCE FAULTS
//==============================================================================

`define RTDDMA_FAULT_FFI_VMID_CROSS         8'hB0
`define RTDDMA_FAULT_FFI_SLICE_CROSS        8'hB1
`define RTDDMA_FAULT_FFI_QOS_VIOLATION      8'hB2
`define RTDDMA_FAULT_FFI_PRIORITY_ESCALATE  8'hB3

//==============================================================================
// PREFETCH / CHAIN FAULTS
//==============================================================================

`define RTDDMA_FAULT_PREFETCH_OVERFLOW      8'hC0
`define RTDDMA_FAULT_PREFETCH_REPLAY        8'hC1
`define RTDDMA_FAULT_CHAIN_LOOP             8'hC2
`define RTDDMA_FAULT_CHAIN_DEPTH            8'hC3
//==============================================================================
// INTERNAL SAFETY FAULTS
//==============================================================================

`define RTDDMA_FAULT_SEU_DETECTED        8'hF0
`define RTDDMA_FAULT_DMR_MISMATCH        8'hF1
`define RTDDMA_FAULT_INTERNAL_OVERFLOW   8'hF2
`define RTDDMA_FAULT_INTERNAL_UNDERFLOW  8'hF3

//==============================================================================
// DEFAULT SEVERITY CLASSIFICATION
//==============================================================================

//
// NOTE:
// Safety controller may override these dynamically.
//
//==============================================================================

`define RTDDMA_CLASS_SEV(code)                               \
(                                                            \
    ((code) == `RTDDMA_FAULT_FIFO_ECC_CORR)       ? `RTDDMA_SEV_CORRECTED : \
    ((code) == `RTDDMA_FAULT_DESC_CRC)            ? `RTDDMA_SEV_FATAL : \
    ((code) == `RTDDMA_FAULT_DESC_SEQ)            ? `RTDDMA_SEV_FATAL : \
    ((code) == `RTDDMA_FAULT_DESC_MPU)            ? `RTDDMA_SEV_GLOBAL : \
    ((code) == `RTDDMA_FAULT_AXI_TIMEOUT)         ? `RTDDMA_SEV_FATAL : \
    ((code) == `RTDDMA_FAULT_AXI_BABBLING)        ? `RTDDMA_SEV_GLOBAL : \
    ((code) == `RTDDMA_FAULT_SEU_DETECTED)        ? `RTDDMA_SEV_FATAL : \
                                                     `RTDDMA_SEV_RECOVERABLE \
)

//==============================================================================
// DEFAULT ACTION CLASSIFICATION
//==============================================================================

`define RTDDMA_CLASS_ACTION(code)                            \
(                                                            \
    ((code) == `RTDDMA_FAULT_DESC_MPU)            ? `RTDDMA_ACTION_SAFE_STATE : \
    ((code) == `RTDDMA_FAULT_AXI_BABBLING)        ? `RTDDMA_ACTION_GLOBAL_HALT : \
    ((code) == `RTDDMA_FAULT_AXI_TIMEOUT)         ? `RTDDMA_ACTION_SLICE_DRAIN : \
    ((code) == `RTDDMA_FAULT_DESC_CRC)            ? `RTDDMA_ACTION_SLICE_HALT : \
    ((code) == `RTDDMA_FAULT_SEU_DETECTED)        ? `RTDDMA_ACTION_SLICE_HALT : \
                                                     `RTDDMA_ACTION_IRQ \
)


`endif
