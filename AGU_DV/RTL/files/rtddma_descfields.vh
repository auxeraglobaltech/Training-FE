//==============================================================================
//  Project      : RTDDMA (Real-Time Deterministic DMA)
//  Module       : <module_name>
//  File         : <file_name>.v
//  Author       : <your_name>
//  Created On   : <date>
//------------------------------------------------------------------------------
//  Description  :
//  -----------------------------------------------------------------------------
//  <Brief 2–3 line description of what this module does>
//  <Example: Descriptor response capture unit with ASIL-D safety checks>
//
//------------------------------------------------------------------------------
//  Functional Overview :
//  -----------------------------------------------------------------------------
//  - <Key function 1>
//  - <Key function 2>
//  - <Key function 3>

//------------------------------------------------------------------------------
//  Interfaces :
//  -----------------------------------------------------------------------------
//  Inputs  :
//    - <signal> : <description>
//  Outputs :
//    - <signal> : <description>
//
//------------------------------------------------------------------------------
//  Key Features :
//  -----------------------------------------------------------------------------
//  - Deterministic FSM (no unbounded states)
//  - Timeout protection
//  - AXI protocol compliance
//  - Fault detection and escalation
//
//------------------------------------------------------------------------------
//  Safety (ASIL-D) Considerations :
//  -----------------------------------------------------------------------------
//  - No execution without validated inputs
//  - Safe default outputs on fault/reset
//  - Illegal state ? FAULT transition
//  - Timeout-based forward progress guarantee
//  - Fault signals are sticky until cleared
//
//------------------------------------------------------------------------------
//  Failure Modes Covered :
//  -----------------------------------------------------------------------------
//  - Timeout / no-progress
//  - Protocol violation (AXI)
//  - Internal state corruption
//  - Data integrity failure
//
//------------------------------------------------------------------------------
//  Assumptions :
//  -----------------------------------------------------------------------------
//  - AXI interface is compliant
//  - Reset is synchronous/asynchronous (define clearly)
//  - Clock is stable
//
//------------------------------------------------------------------------------
//  Limitations :
//  -----------------------------------------------------------------------------
//  - <Any constraints or unsupported modes>
//
//------------------------------------------------------------------------------
//  Dependencies :
//  -----------------------------------------------------------------------------
//  - `include "rtddma_params.vh"
//  - `include "rtddma_states.vh"
//
//------------------------------------------------------------------------------
//  Revision History :
//  -----------------------------------------------------------------------------
//  Version | Date       | Author        | Description
//  --------|------------|---------------|-------------------------------
//   1.0    | <date>     | <name>        | Initial version
//==============================================================================

`ifndef RTDDMA_DESCFIELDS_VH
`define RTDDMA_DESCFIELDS_VH

//==============================================================================
// DESCRIPTOR GLOBAL DEFINITIONS
//==============================================================================

`define RTDDMA_DESC_W                256
`define RTDDMA_DESC_WORD_W           32
`define RTDDMA_DESC_NUM_WORDS        8

//==============================================================================
// WORD OFFSETS
//==============================================================================

`define RTDDMA_DESC_W0_LSB           0
`define RTDDMA_DESC_W0_MSB           31

`define RTDDMA_DESC_W1_LSB           32
`define RTDDMA_DESC_W1_MSB           63

`define RTDDMA_DESC_W2_LSB           64
`define RTDDMA_DESC_W2_MSB           95

`define RTDDMA_DESC_W3_LSB           96
`define RTDDMA_DESC_W3_MSB           127

`define RTDDMA_DESC_W4_LSB           128
`define RTDDMA_DESC_W4_MSB           159

`define RTDDMA_DESC_W5_LSB           160
`define RTDDMA_DESC_W5_MSB           191

`define RTDDMA_DESC_W6_LSB           192
`define RTDDMA_DESC_W6_MSB           223

`define RTDDMA_DESC_W7_LSB           224
`define RTDDMA_DESC_W7_MSB           255

//==============================================================================
// W0 : CTRL_CFG
//==============================================================================

// VALID
`define RTDDMA_W0_VALID_BIT          31

// ROUTE MODE
`define RTDDMA_W0_ROUTE_MODE_MSB     30
`define RTDDMA_W0_ROUTE_MODE_LSB     29

// EXEC MODE
`define RTDDMA_W0_EXEC_MODE_MSB      28
`define RTDDMA_W0_EXEC_MODE_LSB      27

// ALU OP
`define RTDDMA_W0_ALU_OP_MSB         26
`define RTDDMA_W0_ALU_OP_LSB         23

// SRC WIDTH
`define RTDDMA_W0_SRC_WIDTH_MSB      22
`define RTDDMA_W0_SRC_WIDTH_LSB      21

// DST WIDTH
`define RTDDMA_W0_DST_WIDTH_MSB      20
`define RTDDMA_W0_DST_WIDTH_LSB      19

// BURST LEN
`define RTDDMA_W0_BURST_LEN_MSB      18
`define RTDDMA_W0_BURST_LEN_LSB      15

// BURST TYPE
`define RTDDMA_W0_BURST_TYPE_MSB     14
`define RTDDMA_W0_BURST_TYPE_LSB     13

// ADDR MODE
`define RTDDMA_W0_ADDR_MODE_MSB      12
`define RTDDMA_W0_ADDR_MODE_LSB      11

// SECURE HINT
`define RTDDMA_W0_SECURE_HINT_BIT    10

// FAULT OVERRIDE
`define RTDDMA_W0_FAULT_OVR_BIT      9

// SEQ ID
`define RTDDMA_W0_SEQ_ID_MSB         8
`define RTDDMA_W0_SEQ_ID_LSB         0

//==============================================================================
// W1 : SRC_ADDR
//==============================================================================

`define RTDDMA_W1_SRC_ADDR_MSB       31
`define RTDDMA_W1_SRC_ADDR_LSB       0

//==============================================================================
// W2 : DST_ADDR
//==============================================================================

`define RTDDMA_W2_DST_ADDR_MSB       31
`define RTDDMA_W2_DST_ADDR_LSB       0

//==============================================================================
// W3 : X_DIM
//==============================================================================

`define RTDDMA_W3_XCOUNT_MSB         31
`define RTDDMA_W3_XCOUNT_LSB         16

`define RTDDMA_W3_XSTRIDE_MSB        15
`define RTDDMA_W3_XSTRIDE_LSB        0

//==============================================================================
// W4 : Y_DIM
//==============================================================================

`define RTDDMA_W4_YCOUNT_MSB         31
`define RTDDMA_W4_YCOUNT_LSB         16

`define RTDDMA_W4_YSTRIDE_MSB        15
`define RTDDMA_W4_YSTRIDE_LSB        0

//==============================================================================
// W5 : SYNC_CFG
//==============================================================================

`define RTDDMA_W5_SRC_SYNC_MSB       31
`define RTDDMA_W5_SRC_SYNC_LSB       26

`define RTDDMA_W5_DST_SYNC_MSB       25
`define RTDDMA_W5_DST_SYNC_LSB       20

`define RTDDMA_W5_SYNC_MODE_MSB      19
`define RTDDMA_W5_SYNC_MODE_LSB      18

`define RTDDMA_W5_EXP_CRC_MSB        15
`define RTDDMA_W5_EXP_CRC_LSB        0

//==============================================================================
// W6 : LINK_CFG
//==============================================================================

`define RTDDMA_W6_NEXT_PTR_MSB       31
`define RTDDMA_W6_NEXT_PTR_LSB       5

`define RTDDMA_W6_EOC_BIT            4
`define RTDDMA_W6_SWAP_EN_BIT        3
`define RTDDMA_W6_INT_EN_BIT         2

`define RTDDMA_W6_LINK_MODE_MSB      1
`define RTDDMA_W6_LINK_MODE_LSB      0

//==============================================================================
// W7 : DESC_CRC
//==============================================================================

`define RTDDMA_W7_DESC_CRC_MSB       31
`define RTDDMA_W7_DESC_CRC_LSB       0

//==============================================================================
// ENUMERATED VALUES
//==============================================================================

// ROUTE MODES
`define RTDDMA_ROUTE_M2M             2'b00
`define RTDDMA_ROUTE_P2M             2'b01
`define RTDDMA_ROUTE_M2P             2'b10
`define RTDDMA_ROUTE_P2P             2'b11

// EXEC MODES
`define RTDDMA_EXEC_CONT             2'b00
`define RTDDMA_EXEC_ELEMENT          2'b01
`define RTDDMA_EXEC_LINE             2'b10

// BURST TYPES
`define RTDDMA_BURST_FIXED           2'b00
`define RTDDMA_BURST_INCR            2'b01

// LINK MODES
`define RTDDMA_LINK_STOP             2'b00
`define RTDDMA_LINK_WAIT             2'b01
`define RTDDMA_LINK_AUTO             2'b10

`endif
