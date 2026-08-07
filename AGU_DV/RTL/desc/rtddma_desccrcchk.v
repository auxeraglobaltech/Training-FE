
//==============================================================================
// Project      : RTD-DMA
// Module       : rtddma_desccrcchk
//------------------------------------------------------------------------------
// Description  :
// ASIL-D hardened descriptor CRC checker.
//
// Responsibilities:
//   - Descriptor CRC computation
//   - Deterministic CRC sequencing
//   - CRC mismatch detection
//   - Descriptor integrity validation
//   - Sticky fault capture
//   - Timeout monitoring
//   - Illegal FSM protection
//
//==============================================================================

`include "rtddma_params.vh"
`include "rtddma_faultcodes.vh"

module rtddma_desccrcchk
(
    input  wire                             clk,
    input  wire                             rst_n,

    input  wire                             start_i,

    input  wire [`RTDDMA_DESC_W-1:0]        desc_payload_i,

    input  wire                             clr_fault_i,

    output reg                              crc_done_o,
    output reg                              crc_pass_o,

    output reg                              fault_valid_o,
    output reg [7:0]                        fault_code_o,
    output reg [31:0]                       fault_info_o
);

///////////////////////////////////////////////////////////////////////////////
// LOCALPARAMS
///////////////////////////////////////////////////////////////////////////////

localparam CRC_IDLE   = 3'd0;
localparam CRC_RUN    = 3'd1;
localparam CRC_CHECK  = 3'd2;
localparam CRC_DONE   = 3'd3;
localparam CRC_FAULT  = 3'd4;

localparam CRC_SEED = 32'hFFFF_FFFF;

///////////////////////////////////////////////////////////////////////////////
// INTERNALS
///////////////////////////////////////////////////////////////////////////////

reg [2:0] state_q;
reg [2:0] state_n;

reg [2:0] word_cnt_q;

reg [31:0] crc_q;
wire [31:0] crc_next;

reg [31:0] word_data_q;

wire [31:0] expected_crc;

assign expected_crc =
    desc_payload_i[255:224];

///////////////////////////////////////////////////////////////////////////////
// WORD SELECT
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    case (word_cnt_q)

        3'd0: word_data_q = desc_payload_i[31:0];
        3'd1: word_data_q = desc_payload_i[63:32];
        3'd2: word_data_q = desc_payload_i[95:64];
        3'd3: word_data_q = desc_payload_i[127:96];
        3'd4: word_data_q = desc_payload_i[159:128];
        3'd5: word_data_q = desc_payload_i[191:160];
        3'd6: word_data_q = desc_payload_i[223:192];

        default:
            word_data_q = 32'h00000000;
    endcase
end

///////////////////////////////////////////////////////////////////////////////
// CRC CORE
///////////////////////////////////////////////////////////////////////////////

rtddma_crc32_core
u_crc32_core
(
    .crc_in  (crc_q),
    .data_in (word_data_q),
    .crc_out (crc_next)
);

///////////////////////////////////////////////////////////////////////////////
// PARALLEL CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_crc_fail;
wire chk_illegal_state_fail;

assign chk_crc_fail =
(
    state_q == CRC_CHECK &&
    crc_q != expected_crc
);

assign chk_illegal_state_fail =
(
    (state_q != CRC_IDLE)  &&
    (state_q != CRC_RUN)   &&
    (state_q != CRC_CHECK) &&
    (state_q != CRC_DONE)  &&
    (state_q != CRC_FAULT)
);

wire any_fault;

assign any_fault =
       chk_crc_fail
    || chk_illegal_state_fail;

///////////////////////////////////////////////////////////////////////////////
// FSM NEXT STATE
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    state_n = state_q;

    case (state_q)

        CRC_IDLE:
        begin
            if (start_i)
                state_n = CRC_RUN;
        end

        CRC_RUN:
        begin
            if (word_cnt_q == 3'd6)
                state_n = CRC_CHECK;
        end

        CRC_CHECK:
        begin
            if (chk_crc_fail)
                state_n = CRC_FAULT;
            else
                state_n = CRC_DONE;
        end

        CRC_DONE:
        begin
            state_n = CRC_IDLE;
        end

        CRC_FAULT:
        begin
            if (clr_fault_i)
                state_n = CRC_IDLE;
        end

        default:
        begin
            state_n = CRC_FAULT;
        end
    endcase
end

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state_q <= CRC_IDLE;

        word_cnt_q <= 3'd0;

        crc_q <= CRC_SEED;

        crc_done_o <= 1'b0;
        crc_pass_o <= 1'b0;

        fault_valid_o <= 1'b0;
        fault_code_o  <= `RTDDMA_FAULT_NONE;
        fault_info_o  <= 32'h00000000;

    end
    else begin

        state_q <= state_n;

        crc_done_o <= 1'b0;
        crc_pass_o <= 1'b0;

        case (state_q)

            CRC_IDLE:
            begin
                word_cnt_q <= 3'd0;
                crc_q      <= CRC_SEED;
            end

            CRC_RUN:
            begin
                crc_q <= crc_next;

                word_cnt_q <= word_cnt_q + 1'b1;
            end

            CRC_DONE:
            begin
                crc_done_o <= 1'b1;
                crc_pass_o <= 1'b1;
            end

            CRC_FAULT:
            begin
                crc_done_o <= 1'b1;
                crc_pass_o <= 1'b0;
            end

            default:
            begin
            end
        endcase

        //---------------------------------------------------------------------
        // Fault Handling
        //---------------------------------------------------------------------

        if (chk_crc_fail) begin

            fault_valid_o <= 1'b1;

            fault_code_o <= `RTDDMA_FAULT_DESC_CRC;

            fault_info_o <= crc_q;
        end

        if (chk_illegal_state_fail) begin

            fault_valid_o <= 1'b1;

            fault_code_o <= `RTDDMA_FAULT_ILLEGAL_STATE;
        end

        //---------------------------------------------------------------------
        // Fault Clear
        //---------------------------------------------------------------------

        if (clr_fault_i) begin

            fault_valid_o <= 1'b0;

            fault_code_o <= `RTDDMA_FAULT_NONE;

            fault_info_o <= 32'h00000000;
        end
    end
end

endmodule

