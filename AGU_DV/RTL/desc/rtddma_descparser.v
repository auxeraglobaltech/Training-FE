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
//
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
//  - Illegal state → FAULT transition
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


`include "rtddma_descfields.vh"
`include "rtddma_faultcodes.vh"

module rtddma_descparser
#(
    parameter AXI_ADDR_W = 32
)
(
    //--------------------------------------------------------------------------
    // Descriptor Payload Input
    //--------------------------------------------------------------------------

    input  wire [255:0] desc_payload_i,

    //--------------------------------------------------------------------------
    // Parser Control
    //--------------------------------------------------------------------------

    input  wire         parse_enable_i,

    //--------------------------------------------------------------------------
    // Sanitized Outputs
    //--------------------------------------------------------------------------

    output reg          desc_valid_o,

    output reg  [1:0]   route_mode_o,
    output reg  [1:0]   exec_mode_o,
    output reg  [3:0]   alu_op_o,

    output reg  [1:0]   src_width_o,
    output reg  [1:0]   dst_width_o,

    output reg  [3:0]   burst_len_o,
    output reg  [1:0]   burst_type_o,
    output reg  [1:0]   addr_mode_o,

    output reg  [8:0]   seq_id_o,

    output reg  [31:0]  src_addr_o,
    output reg  [31:0]  dst_addr_o,

    output reg  [15:0]  x_count_o,
    output reg  [15:0]  x_stride_o,

    output reg  [15:0]  y_count_o,
    output reg  [15:0]  y_stride_o,

    output reg  [5:0]   src_sync_o,
    output reg  [5:0]   dst_sync_o,

    output reg  [1:0]   sync_mode_o,

    output reg  [15:0]  exp_crc_o,

    output reg  [31:0]  next_desc_addr_o,

    output reg          eoc_o,
    output reg          swap_en_o,
    output reg          int_en_o,

    output reg  [1:0]   link_mode_o,

    output reg  [31:0]  desc_crc_o,

    //--------------------------------------------------------------------------
    // Fault Interface
    //--------------------------------------------------------------------------

    output reg          parser_fault_valid_o,
    output reg  [7:0]   parser_fault_code_o,
    output reg  [2:0]   parser_fault_severity_o
);

    //==========================================================================
    // RAW WORD EXTRACTION
    //==========================================================================

    wire [31:0] w0;
    wire [31:0] w1;
    wire [31:0] w2;
    wire [31:0] w3;
    wire [31:0] w4;
    wire [31:0] w5;
    wire [31:0] w6;
    wire [31:0] w7;

    assign w0 = desc_payload_i[`RTDDMA_DESC_W0_MSB:`RTDDMA_DESC_W0_LSB];
    assign w1 = desc_payload_i[`RTDDMA_DESC_W1_MSB:`RTDDMA_DESC_W1_LSB];
    assign w2 = desc_payload_i[`RTDDMA_DESC_W2_MSB:`RTDDMA_DESC_W2_LSB];
    assign w3 = desc_payload_i[`RTDDMA_DESC_W3_MSB:`RTDDMA_DESC_W3_LSB];
    assign w4 = desc_payload_i[`RTDDMA_DESC_W4_MSB:`RTDDMA_DESC_W4_LSB];
    assign w5 = desc_payload_i[`RTDDMA_DESC_W5_MSB:`RTDDMA_DESC_W5_LSB];
    assign w6 = desc_payload_i[`RTDDMA_DESC_W6_MSB:`RTDDMA_DESC_W6_LSB];
    assign w7 = desc_payload_i[`RTDDMA_DESC_W7_MSB:`RTDDMA_DESC_W7_LSB];

    //==========================================================================
    // FIELD EXTRACTION
    //==========================================================================

    wire valid_bit;

    wire [1:0] route_mode;
    wire [1:0] exec_mode;
    wire [3:0] alu_op;

    wire [1:0] src_width;
    wire [1:0] dst_width;

    wire [3:0] burst_len;
    wire [1:0] burst_type;
    wire [1:0] addr_mode;

    wire [8:0] seq_id;

    assign valid_bit  = w0[`RTDDMA_W0_VALID_BIT];

    assign route_mode =
        w0[`RTDDMA_W0_ROUTE_MODE_MSB:
           `RTDDMA_W0_ROUTE_MODE_LSB];

    assign exec_mode =
        w0[`RTDDMA_W0_EXEC_MODE_MSB:
           `RTDDMA_W0_EXEC_MODE_LSB];

    assign alu_op =
        w0[`RTDDMA_W0_ALU_OP_MSB:
           `RTDDMA_W0_ALU_OP_LSB];

    assign src_width =
        w0[`RTDDMA_W0_SRC_WIDTH_MSB:
           `RTDDMA_W0_SRC_WIDTH_LSB];

    assign dst_width =
        w0[`RTDDMA_W0_DST_WIDTH_MSB:
           `RTDDMA_W0_DST_WIDTH_LSB];

    assign burst_len =
        w0[`RTDDMA_W0_BURST_LEN_MSB:
           `RTDDMA_W0_BURST_LEN_LSB];

    assign burst_type =
        w0[`RTDDMA_W0_BURST_TYPE_MSB:
           `RTDDMA_W0_BURST_TYPE_LSB];

    assign addr_mode =
        w0[`RTDDMA_W0_ADDR_MODE_MSB:
           `RTDDMA_W0_ADDR_MODE_LSB];

    assign seq_id =
        w0[`RTDDMA_W0_SEQ_ID_MSB:
           `RTDDMA_W0_SEQ_ID_LSB];

    //==========================================================================
    // LEGALITY CHECKS
    //==========================================================================

    wire illegal_exec_mode;
    wire illegal_burst_type;
    wire illegal_link_mode;
    wire illegal_burst_len;
    wire illegal_alignment;

    assign illegal_exec_mode =
        (exec_mode == 2'b11);

    assign illegal_burst_type =
        (burst_type == 2'b10) ||
        (burst_type == 2'b11);

    assign illegal_link_mode =
        (w6[`RTDDMA_W6_LINK_MODE_MSB:
            `RTDDMA_W6_LINK_MODE_LSB] == 2'b11);

    assign illegal_burst_len =
        (burst_len == 4'd0);

    //--------------------------------------------------------------------------
    // Alignment precheck
    //--------------------------------------------------------------------------

    assign illegal_alignment =
        ((src_width == 2'b01) && (w1[0]   != 1'b0)) ||
        ((src_width == 2'b10) && (w1[1:0] != 2'b00)) ||
        ((src_width == 2'b11) && (w1[2:0] != 3'b000)) ||

        ((dst_width == 2'b01) && (w2[0]   != 1'b0)) ||
        ((dst_width == 2'b10) && (w2[1:0] != 2'b00)) ||
        ((dst_width == 2'b11) && (w2[2:0] != 3'b000));

    //==========================================================================
    // FAULT GENERATION
    //==========================================================================

    wire parser_fault;

    assign parser_fault =
        illegal_exec_mode  |
        illegal_burst_type |
        illegal_link_mode  |
        illegal_burst_len  |
        illegal_alignment;

    //==========================================================================
    // SANITIZED OUTPUT GENERATION
    //==========================================================================

    always @(*) begin

        //--------------------------------------------------------------------------
        // Safe Defaults
        //--------------------------------------------------------------------------

        desc_valid_o             = 1'b0;

        parser_fault_valid_o     = 1'b0;
        parser_fault_code_o      = `RTDDMA_FAULT_NONE;
        parser_fault_severity_o  = `RTDDMA_SEV_INFO;

        route_mode_o             = 2'b00;
        exec_mode_o              = 2'b00;
        alu_op_o                 = 4'b0000;

        src_width_o              = 2'b00;
        dst_width_o              = 2'b00;

        burst_len_o              = 4'd0;
        burst_type_o             = 2'b00;

        addr_mode_o              = 2'b00;

        seq_id_o                 = 9'd0;

        src_addr_o               = 32'd0;
        dst_addr_o               = 32'd0;

        x_count_o                = 16'd0;
        x_stride_o               = 16'd0;

        y_count_o                = 16'd0;
        y_stride_o               = 16'd0;

        src_sync_o               = 6'd0;
        dst_sync_o               = 6'd0;

        sync_mode_o              = 2'd0;

        exp_crc_o                = 16'd0;

        next_desc_addr_o         = 32'd0;

        eoc_o                    = 1'b0;
        swap_en_o                = 1'b0;
        int_en_o                 = 1'b0;

        link_mode_o              = 2'b00;

        desc_crc_o               = 32'd0;

        //--------------------------------------------------------------------------
        // Parse Enable
        //--------------------------------------------------------------------------

        if (parse_enable_i) begin

            if (valid_bit && !parser_fault) begin

                desc_valid_o = 1'b1;

                route_mode_o = route_mode;
                exec_mode_o  = exec_mode;
                alu_op_o     = alu_op;

                src_width_o  = src_width;
                dst_width_o  = dst_width;

                burst_len_o  = burst_len;
                burst_type_o = burst_type;

                addr_mode_o  = addr_mode;

                seq_id_o     = seq_id;

                src_addr_o   = w1;
                dst_addr_o   = w2;

                x_count_o    = w3[31:16];
                x_stride_o   = w3[15:0];

                y_count_o    = w4[31:16];
                y_stride_o   = w4[15:0];

                src_sync_o   = w5[31:26];
                dst_sync_o   = w5[25:20];

                sync_mode_o  = w5[19:18];

                exp_crc_o    = w5[15:0];

                next_desc_addr_o =
                    {w6[31:5], 5'b00000};

                eoc_o        = w6[4];
                swap_en_o    = w6[3];
                int_en_o     = w6[2];

                link_mode_o  = w6[1:0];

                desc_crc_o   = w7;

            end
            else begin

                parser_fault_valid_o    = 1'b1;
                parser_fault_severity_o = `RTDDMA_SEV_FATAL;

                if (!valid_bit)
                    parser_fault_code_o = `RTDDMA_FAULT_DESC_VALID;
                else if (illegal_exec_mode)
                    parser_fault_code_o = `RTDDMA_FAULT_DESC_OPCODE;
                else if (illegal_burst_type)
                    parser_fault_code_o = `RTDDMA_FAULT_DESC_RESERVED;
                else if (illegal_link_mode)
                    parser_fault_code_o = `RTDDMA_FAULT_DESC_LINK;
                else if (illegal_burst_len)
                    parser_fault_code_o = `RTDDMA_FAULT_DESC_RESERVED;
                else if (illegal_alignment)
                    parser_fault_code_o = `RTDDMA_FAULT_DESC_ALIGN;
                else
                    parser_fault_code_o = `RTDDMA_FAULT_INTERNAL_OVERFLOW;

            end
        end
    end

endmodule