//==============================================================================
//  Project      : RTDDMA (Real-Time Deterministic DMA)
//  Module       : include
//  File         : rtddma_faultcodes.vh
//------------------------------------------------------------------------------
//  Description  :
//   Centralized fault taxonomy for the RTDDMA ASIL-D DMA controller.
//==============================================================================

`ifndef RTDDMA_FAULTCODES_VH
`define RTDDMA_FAULTCODES_VH

//==============================================================================
// GLOBAL FAULT WIDTHS
//==============================================================================
`define RTDDMA_FAULT_CODE_W          8
`define RTDDMA_FAULT_SEVERITY_W      3
`define RTDDMA_FAULT_ACTION_W        3
`define RTDDMA_FAULT_SRC_W           6

//==============================================================================
// FAULT VALIDITY
//==============================================================================
`define RTDDMA_FAULT_VALID           1'b1
`define RTDDMA_FAULT_NONE            8'h00

//==============================================================================
// FAULT SEVERITY LEVELS
//==============================================================================
`define RTDDMA_SEV_INFO              3'd0
`define RTDDMA_SEV_CORRECTED         3'd1
`define RTDDMA_SEV_RECOVERABLE       3'd2
`define RTDDMA_SEV_FATAL             3'd3
`define RTDDMA_SEV_GLOBAL            3'd4

//==============================================================================
// SAFETY ACTIONS
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
`define RTDDMA_FAULT_DESC_VALID          8'h01 // from descparser
`define RTDDMA_FAULT_DESC_CRC            8'h02 // from descrcchk
`define RTDDMA_FAULT_SEQ                 8'h03 // from descchainctrl
`define RTDDMA_FAULT_DESC_MPU            8'h04
`define RTDDMA_FAULT_DESC_VMID           8'h05
`define RTDDMA_FAULT_DESC_OPCODE         8'h06 // from descparser
`define RTDDMA_FAULT_DESC_RESERVED       8'h07 // from descparser
`define RTDDMA_FAULT_DESC_ALIGN          8'h08 // from descparser & descreqgen & descchainctrl
`define RTDDMA_FAULT_DESC_LINK           8'h09 // from descparser
`define RTDDMA_FAULT_CHAIN_DEPTH         8'h0A // from descchainctrl
`define RTDDMA_FAULT_CHAIN_LOOP          8'h0B // from descchainctrl
`define RTDDMA_FAULT_DOUBLE_FETCH        8'h0C // from descfetchtop
`define RTDDMA_FAULT_DOUBLE_ISSUE        8'h0D // from descreqgen
`define RTDDMA_FAULT_DESC_TIMEOUT        8'h0E // from descfetchtop, descreqgen, descrespcapture
`define RTDDMA_FAULT_REQGEN              8'h0F // from descfetchtop
`define RTDDMA_FAULT_RESPCAP             8'h10 // from descfetchtop
`define RTDDMA_FAULT_PARSER              8'h11 // from descfetchtop
`define RTDDMA_FAULT_DESC_VALIDATION     8'h12 // from descfetchtop
`define RTDDMA_FAULT_CTXLOAD             8'h13 // from descfetchtop
`define RTDDMA_FAULT_DESC_OVERFLOW       8'h14 // from descrespcapture
`define RTDDMA_FAULT_EARLY_RLAST         8'h15 // from descrespcapture
`define RTDDMA_FAULT_MISSING_RLAST       8'h16 // from descrespcapture

//==============================================================================
// AXI / FABRIC FAULTS
//==============================================================================
`define RTDDMA_FAULT_AXI_RESP            8'h20 // from descreqgen & descrespcapture
`define RTDDMA_FAULT_AXI_RRESP           8'h21 
`define RTDDMA_FAULT_AXI_BRESP           8'h22
`define RTDDMA_FAULT_AXI_TIMEOUT         8'h23
`define RTDDMA_FAULT_AXI_PROTOCOL        8'h24
`define RTDDMA_FAULT_AXI_STARVATION      8'h25
`define RTDDMA_FAULT_AXI_BABBLING        8'h26

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
`define RTDDMA_FAULT_AGU_ADDR_OVERFLOW   8'h34
`define RTDDMA_FAULT_AGU_ADDR_WRAP       8'h35
`define RTDDMA_FAULT_AGU_XCOUNT_ZERO     8'h36
`define RTDDMA_FAULT_AGU_YCOUNT_ZERO     8'h37
`define RTDDMA_FAULT_AGU_STRIDE_OVERFLOW 8'h38
`define RTDDMA_FAULT_AGU_GATHER_OOB      8'h39
`define RTDDMA_FAULT_AGU_SCATTER_OOB     8'h3A
`define RTDDMA_FAULT_AGU_DETERMINISM     8'h3B

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
`define RTDDMA_FAULT_ILLEGAL_STATE       8'h50 // from multiple modules
`define RTDDMA_FAULT_FSM_ILLEGAL_STATE   8'h50 // Alias
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
// PING PONG / SWAP / CTX FAULTS
//==============================================================================
`define RTDDMA_FAULT_SWAP_COLLISION      8'hA0
`define RTDDMA_FAULT_SWAP_UNSAFE_BOUNDARY 8'hA1
`define RTDDMA_FAULT_PP_BUFFER_OVERLAP   8'hA2
`define RTDDMA_FAULT_PP_STATE_MISMATCH   8'hA3
`define RTDDMA_FAULT_BUSY_COMMIT         8'hA4 // from descctxload
`define RTDDMA_FAULT_SLICE_HALTED        8'hA5 // from descctxload & descreqgen
`define RTDDMA_FAULT_INVALID_CTX         8'hA6 // from descctxload
`define RTDDMA_FAULT_SWAP_ILLEGAL        8'hA7 // from descctxload
`define RTDDMA_FAULT_CTX_PARITY          8'hA8 // from descctxload

//==============================================================================
// FREEDOM FROM INTERFERENCE FAULTS
//==============================================================================
`define RTDDMA_FAULT_FFI_VMID_CROSS      8'hB0
`define RTDDMA_FAULT_FFI_SLICE_CROSS     8'hB1
`define RTDDMA_FAULT_FFI_QOS_VIOLATION   8'hB2
`define RTDDMA_FAULT_FFI_PRIORITY_ESCALATE 8'hB3

//==============================================================================
// INTERNAL SAFETY FAULTS
//==============================================================================
`define RTDDMA_FAULT_INTERNAL_OVERFLOW   8'hF2 // from descparser

//==============================================================================
// CLASSIFICATION MACROS
//==============================================================================

`define RTDDMA_CLASS_SEV(code)                                           \
(                                                                        \
    ((code) == `RTDDMA_FAULT_FIFO_ECC_CORR)       ? `RTDDMA_SEV_CORRECTED : \
    ((code) == `RTDDMA_FAULT_DESC_CRC)            ? `RTDDMA_SEV_FATAL : \
    ((code) == `RTDDMA_FAULT_SEQ)                 ? `RTDDMA_SEV_FATAL : \
    ((code) == `RTDDMA_FAULT_DESC_MPU)            ? `RTDDMA_SEV_GLOBAL : \
    ((code) == `RTDDMA_FAULT_AXI_TIMEOUT)         ? `RTDDMA_SEV_FATAL : \
    ((code) == `RTDDMA_FAULT_AXI_BABBLING)        ? `RTDDMA_SEV_GLOBAL : \
                                                    `RTDDMA_SEV_RECOVERABLE \
)

`define RTDDMA_CLASS_ACTION(code)                                        \
(                                                                        \
    ((code) == `RTDDMA_FAULT_DESC_MPU)            ? `RTDDMA_ACTION_SAFE_STATE : \
    ((code) == `RTDDMA_FAULT_AXI_BABBLING)        ? `RTDDMA_ACTION_GLOBAL_HALT : \
    ((code) == `RTDDMA_FAULT_AXI_TIMEOUT)         ? `RTDDMA_ACTION_SLICE_DRAIN : \
    ((code) == `RTDDMA_FAULT_DESC_CRC)            ? `RTDDMA_ACTION_SLICE_HALT : \
                                                    `RTDDMA_ACTION_IRQ \
)

`endif
