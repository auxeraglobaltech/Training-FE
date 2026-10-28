
`timescale 1ns / 1ps

module sa_R_channel #(
    parameter integer MST_AMT              = 3,
    parameter integer OUTSTANDING_AMT      = 8,

    parameter integer MST_ID_W =
        (MST_AMT <= 1) ? 1 : $clog2(MST_AMT),

    parameter integer DATA_WIDTH           = 32,
    parameter integer TRANS_MST_ID_W       = 5,

    parameter integer TRANS_SLV_ID_W =
        TRANS_MST_ID_W + MST_ID_W,

    parameter integer TRANS_RRESP_W        = 2,
    parameter integer TRANS_WR_RESP_W      = 0,
    parameter integer RECOVER_ON_MISMATCH  = 0
)(
    input  wire ACLK_i,
    input  wire ARESETn_i,

    // Dispatcher READY inputs
    input  wire [MST_AMT-1:0] dsp_RREADY_i,

    // Slave read-data channel
    input  wire [TRANS_SLV_ID_W-1:0] s_RID_i,
    input  wire [DATA_WIDTH-1:0]     s_RDATA_i,
    input  wire [((TRANS_WR_RESP_W > 0) ? TRANS_WR_RESP_W : TRANS_RRESP_W)-1:0] s_RRESP_i,
    input  wire                      s_RLAST_i,
    input  wire                      s_RVALID_i,

    // AR tracking inputs
    input  wire [TRANS_SLV_ID_W-1:0] AR_AxID_i,
    input  wire                      AR_crossing_flag_i,
    input  wire                      AR_shift_en_i,

    // Dispatcher outputs
    output wire [TRANS_MST_ID_W*MST_AMT-1:0] dsp_RID_o,
    output wire [DATA_WIDTH*MST_AMT-1:0]     dsp_RDATA_o,
    output wire [((TRANS_WR_RESP_W > 0) ? TRANS_WR_RESP_W : TRANS_RRESP_W)*MST_AMT-1:0] dsp_RRESP_o,
    output wire [MST_AMT-1:0]                dsp_RLAST_o,
    output wire [MST_AMT-1:0]                dsp_RVALID_o,

    // Slave READY output
    output wire s_RREADY_o,

    // AR backpressure
    output wire AR_stall_o,

    // Diagnostic & Software control
    input  wire err_clear_i,
    output wire decode_err_o,
    output reg  decode_err_pulse_o,
    output reg  decode_err_sticky_o,
    output wire id_beat_mismatch_o,
    output wire id_mismatch_err_o,
    output reg  id_mismatch_err_sticky_o,
    output reg  err_filter_overflow_sticky_o  // AR_shift_en while filter FIFO full (contract violation)
);

    localparam integer RESP_W = (TRANS_WR_RESP_W > 0) ? TRANS_WR_RESP_W : TRANS_RRESP_W;

    localparam integer FILTER_INFO_W =
        TRANS_SLV_ID_W + 1;

    localparam integer R_INFO_W =
        TRANS_SLV_ID_W + DATA_WIDTH +
        RESP_W + 1;

`ifndef SYNTHESIS
    initial begin
        if (MST_AMT < 1)          begin $display("%m: MST_AMT must be >= 1"); $finish; end
        if (DATA_WIDTH < 1)       begin $display("%m: DATA_WIDTH must be >= 1"); $finish; end
        if (TRANS_MST_ID_W < 1)   begin $display("%m: TRANS_MST_ID_W must be >= 1"); $finish; end
        if (RESP_W < 1)           begin $display("%m: Response width must be >= 1"); $finish; end
        if (OUTSTANDING_AMT < 1)  begin $display("%m: OUTSTANDING_AMT must be >= 1"); $finish; end
        if (MST_ID_W < ((MST_AMT <= 1) ? 1 : $clog2(MST_AMT)))
            begin $display("%m: MST_ID_W (%0d) is insufficient for MST_AMT (%0d)", MST_ID_W, MST_AMT); $finish; end
        if (TRANS_SLV_ID_W != (TRANS_MST_ID_W + MST_ID_W))
            begin $display("%m: TRANS_SLV_ID_W (%0d) must equal TRANS_MST_ID_W + MST_ID_W (%0d)",
                           TRANS_SLV_ID_W, TRANS_MST_ID_W + MST_ID_W); $finish; end
    end
`endif

    genvar mst_idx;

        wire [FILTER_INFO_W-1:0] filter_info;
    wire [FILTER_INFO_W-1:0] filter_info_valid;

    wire fifo_filter_wr_en;
    wire fifo_filter_rd_en;
    wire fifo_filter_full;
    wire fifo_filter_empty;

    wire crossing_flag_valid;
    wire [TRANS_SLV_ID_W-1:0] ARID_valid;

    wire filter_ARID_match;
    wire filter_condition;
    wire filter_RLAST;

    wire ssb_fwd_handshake;

    wire [MST_ID_W-1:0] mst_id;
    wire mst_id_valid;

    wire [R_INFO_W-1:0] ssb_bwd_data;
    wire ssb_bwd_valid;
    wire ssb_bwd_ready;

    wire [R_INFO_W-1:0] ssb_fwd_data;
    wire ssb_fwd_valid;
    wire ssb_fwd_ready;

    wire [TRANS_SLV_ID_W-1:0] ssb_fwd_RID;
    wire [DATA_WIDTH-1:0]     ssb_fwd_RDATA;
    wire [RESP_W-1:0]         ssb_fwd_RRESP;
    wire                      ssb_fwd_RLAST;

    sync_fifo_r #(
        .DATA_WIDTH(FILTER_INFO_W),
        .FIFO_DEPTH(OUTSTANDING_AMT)
    ) fifo_rlast_filter (
        .clk(ACLK_i),
        .rst_n(ARESETn_i),
        .data_i(filter_info),
        .data_o(filter_info_valid),
        .rd_valid_i(fifo_filter_rd_en),
        .wr_valid_i(fifo_filter_wr_en),
        .empty_o(fifo_filter_empty),
        .full_o(fifo_filter_full),
        .wr_ready_o(),
        .rd_ready_o(),
        .almost_empty_o(),
        .almost_full_o(),
        .counter()
    );

    skid_buffer_r #(
        .SBUF_TYPE(1),
        .DATA_WIDTH(R_INFO_W)
    ) slv_skid_buffer (
        .clk(ACLK_i),
        .rst_n(ARESETn_i),
        .bwd_data_i(ssb_bwd_data),
        .bwd_valid_i(ssb_bwd_valid),
        .bwd_ready_o(ssb_bwd_ready),
        .fwd_data_o(ssb_fwd_data),
        .fwd_valid_o(ssb_fwd_valid),
        .fwd_ready_i(ssb_fwd_ready)
    );
    assign filter_info = {
        AR_crossing_flag_i,
        AR_AxID_i
    };

    assign AR_stall_o        = fifo_filter_full;
    assign fifo_filter_wr_en = AR_shift_en_i && !fifo_filter_full;

    // Upstream pushed an AR entry while the filter FIFO was full: the entry is
    // lost and later RLAST filtering would be wrong, so flag it (sticky).
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i)
            err_filter_overflow_sticky_o <= 1'b0;
        else if (err_clear_i)
            err_filter_overflow_sticky_o <= 1'b0;
        else if (AR_shift_en_i && fifo_filter_full)
            err_filter_overflow_sticky_o <= 1'b1;
    end
    assign {
        crossing_flag_valid,
        ARID_valid
    } = filter_info_valid;

    assign filter_ARID_match =
        !fifo_filter_empty &&
        mst_id_valid &&
        (ARID_valid == ssb_fwd_RID);

    assign id_beat_mismatch_o = ssb_fwd_valid && mst_id_valid && !filter_ARID_match;

    assign id_mismatch_err_o =
        ssb_fwd_handshake &&
        ssb_fwd_RLAST &&
        mst_id_valid &&
        !filter_ARID_match;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i)
            id_mismatch_err_sticky_o <= 1'b0;
        else if (err_clear_i)
            id_mismatch_err_sticky_o <= 1'b0;
        else if (id_mismatch_err_o)
            id_mismatch_err_sticky_o <= 1'b1;
    end
    assign filter_condition =
        crossing_flag_valid &&
        filter_ARID_match;

    assign filter_RLAST =
        ssb_fwd_RLAST && !filter_condition;

    assign fifo_filter_rd_en =
        (ssb_fwd_handshake && ssb_fwd_RLAST && filter_ARID_match) ||
        ((RECOVER_ON_MISMATCH != 0) && id_mismatch_err_o && !fifo_filter_empty);
    assign ssb_fwd_handshake =
        ssb_fwd_valid && ssb_fwd_ready;

    assign s_RREADY_o = ssb_bwd_ready;

    assign ssb_bwd_data = {
        s_RID_i,
        s_RDATA_i,
        s_RRESP_i,
        s_RLAST_i
    };

    assign ssb_bwd_valid = s_RVALID_i;

    assign {
        ssb_fwd_RID,
        ssb_fwd_RDATA,
        ssb_fwd_RRESP,
        ssb_fwd_RLAST
    } = ssb_fwd_data;

        assign mst_id       = ssb_fwd_RID[TRANS_SLV_ID_W-1 -: MST_ID_W];
    assign mst_id_valid = (mst_id < MST_AMT);

    assign decode_err_o = ssb_fwd_valid && !mst_id_valid;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            decode_err_pulse_o  <= 1'b0;
            decode_err_sticky_o <= 1'b0;
        end
        else begin
            decode_err_pulse_o <= ssb_fwd_handshake && !mst_id_valid;

            if (err_clear_i)
                decode_err_sticky_o <= 1'b0;
            else if (decode_err_o)
                decode_err_sticky_o <= 1'b1;
        end
    end

    // Drain invalid response beats to prevent permanent bus hang
    assign ssb_fwd_ready =
        mst_id_valid
        ? dsp_RREADY_i[mst_id]
        : 1'b1;

       generate
        for (mst_idx = 0; mst_idx < MST_AMT;
             mst_idx = mst_idx + 1) begin : MST_LOGIC

            // FIX: compare with the genvar directly (no genvar part-select)
            assign dsp_RVALID_o[mst_idx] =
                mst_id_valid &&
                (mst_id == mst_idx) &&
                ssb_fwd_valid;

            assign dsp_RID_o[TRANS_MST_ID_W*(mst_idx+1)-1 -: TRANS_MST_ID_W]
                = ssb_fwd_RID[TRANS_MST_ID_W-1:0];

            assign dsp_RDATA_o[DATA_WIDTH*(mst_idx+1)-1 -: DATA_WIDTH]
                = ssb_fwd_RDATA;

            assign dsp_RRESP_o[RESP_W*(mst_idx+1)-1 -: RESP_W]
                = ssb_fwd_RRESP;

            assign dsp_RLAST_o[mst_idx] =
                mst_id_valid &&
                (mst_id == mst_idx) &&
                ssb_fwd_valid &&
                filter_RLAST;

        end
    endgenerate

endmodule


