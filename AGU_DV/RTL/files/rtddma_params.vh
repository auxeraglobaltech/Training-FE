//==============================================================================
//  Project      : RTDDMA (Real-Time Deterministic DMA)
//  Module       : include
//  File         : rtddma_params.vh
//------------------------------------------------------------------------------
//  Description  :
//   Centralized parameters and width definitions for RTDDMA.
//==============================================================================

`ifndef RTDDMA_PARAMS_VH
`define RTDDMA_PARAMS_VH

//==============================================================================
// GLOBAL WIDTHS
//==============================================================================
`define RTDDMA_ADDR_W            32
`define RTDDMA_DATA_W            128
`define RTDDMA_DESC_W            256
`define RTDDMA_SEQID_W           8
`define RTDDMA_STATE_W           4

//==============================================================================
// DESCRIPTOR WORD OFFSETS (32-bit words)
//==============================================================================
`define RTDDMA_DESC_W0_MSB       31
`define RTDDMA_DESC_W0_LSB       0
`define RTDDMA_DESC_W1_MSB       63
`define RTDDMA_DESC_W1_LSB       32
`define RTDDMA_DESC_W2_MSB       95
`define RTDDMA_DESC_W2_LSB       64
`define RTDDMA_DESC_W3_MSB       127
`define RTDDMA_DESC_W3_LSB       96
`define RTDDMA_DESC_W4_MSB       159
`define RTDDMA_DESC_W4_LSB       128
`define RTDDMA_DESC_W5_MSB       191
`define RTDDMA_DESC_W5_LSB       160
`define RTDDMA_DESC_W6_MSB       223
`define RTDDMA_DESC_W6_LSB       192
`define RTDDMA_DESC_W7_MSB       255
`define RTDDMA_DESC_W7_LSB       224

//==============================================================================
// DESCRIPTOR W0 BIT FIELDS (From rtddma_descparser)
//==============================================================================
`define RTDDMA_W0_VALID_BIT      0
`define RTDDMA_W0_ROUTE_MODE_MSB 2
`define RTDDMA_W0_ROUTE_MODE_LSB 1
`define RTDDMA_W0_EXEC_MODE_MSB  4
`define RTDDMA_W0_EXEC_MODE_LSB  3
`define RTDDMA_W0_ALU_OP_MSB     8
`define RTDDMA_W0_ALU_OP_LSB     5
`define RTDDMA_W0_SRC_WIDTH_MSB  10
`define RTDDMA_W0_SRC_WIDTH_LSB  9
`define RTDDMA_W0_DST_WIDTH_MSB  12
`define RTDDMA_W0_DST_WIDTH_LSB  11
`define RTDDMA_W0_BURST_LEN_MSB  16
`define RTDDMA_W0_BURST_LEN_LSB  13
`define RTDDMA_W0_BURST_TYPE_MSB 18
`define RTDDMA_W0_BURST_TYPE_LSB 17
`define RTDDMA_W0_ADDR_MODE_MSB  20
`define RTDDMA_W0_ADDR_MODE_LSB  19
`define RTDDMA_W0_SEQ_ID_MSB     31
`define RTDDMA_W0_SEQ_ID_LSB     24

//==============================================================================
// DESCRIPTOR W6 BIT FIELDS (Link & Control)
//==============================================================================
`define RTDDMA_W6_LINK_MODE_MSB  1
`define RTDDMA_W6_LINK_MODE_LSB  0

`endif
