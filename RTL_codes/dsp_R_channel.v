`timescale 1ns / 1ps
module dsp_R_channel #(
    parameter integer SLV_AMT            = 2,
    parameter integer DATA_WIDTH         = 32,
    parameter integer TRANS_MST_ID_W     = 5,
    parameter integer TRANS_RRESP_W      = 2,
    parameter integer TRANS_WR_RESP_W    = 2,
    parameter integer TRANS_DATA_LEN_W   = 3,
    parameter integer SLV_ID_W           = (SLV_AMT <= 1) ? 1 : $clog2(SLV_AMT),
    parameter integer DSP_RDATA_DEPTH    = 16,
    parameter integer OUTSTANDING_AMT    = 8,
    parameter integer USE_AR_TRACK_FIFO  = 1,
    parameter integer DECERR_EN          = 1
)(
    input  wire ACLK_i,
    input  wire ARESETn_i,

    input  wire m_RREADY_i,

    input  wire [TRANS_MST_ID_W*SLV_AMT-1:0] sa_RID_i,
    input  wire [DATA_WIDTH*SLV_AMT-1:0]      sa_RDATA_i,
    input  wire [((TRANS_WR_RESP_W > 0) ? TRANS_WR_RESP_W : TRANS_RRESP_W)*SLV_AMT-1:0] sa_RRESP_i,
    input  wire [SLV_AMT-1:0]                 sa_RLAST_i,
    input  wire [SLV_AMT-1:0]                 sa_RVALID_i,

    input  wire [SLV_ID_W-1:0]          dsp_AR_slv_id_i,
    input  wire                          dsp_AR_shift_en_i,
    input  wire                          dsp_AR_disable_i,
    input  wire                          dsp_AR_decerr_i,
    input  wire [TRANS_MST_ID_W-1:0]    dsp_AR_id_i,
    input  wire [TRANS_DATA_LEN_W-1:0]  dsp_AR_len_i,
    output wire                          dsp_AR_stall_o,

    output wire [TRANS_MST_ID_W-1:0] m_RID_o,
    output wire [DATA_WIDTH-1:0]      m_RDATA_o,
    output wire [((TRANS_WR_RESP_W > 0) ? TRANS_WR_RESP_W : TRANS_RRESP_W)-1:0] m_RRESP_o,
    output wire                       m_RLAST_o,
    output wire                       m_RVALID_o,

    output wire [SLV_AMT-1:0] sa_RREADY_o,

    input  wire err_clear_i,
    output wire dsp_RVALID_q1_o,
    output wire dsp_RREADY_q1_o,
    output wire dsp_RLAST_q1_o,
    output wire m_RLAST_handshake_o,
    output wire err_invalid_slv_id_pulse_o,
    output wire err_invalid_slv_id_sticky_o,
    output wire err_ar_overflow_sticky_o
);

    localparam integer RESP_W = (TRANS_WR_RESP_W > 0) ? TRANS_WR_RESP_W : TRANS_RRESP_W;

    localparam integer DATA_INFO_W =
        TRANS_MST_ID_W + DATA_WIDTH + RESP_W + 1;

    localparam integer TRK_SLV_W =
        (DECERR_EN != 0)
            ? (((1 << SLV_ID_W) > SLV_AMT) ? SLV_ID_W : (SLV_ID_W + 1))
            : SLV_ID_W;

    localparam [TRK_SLV_W-1:0] DEC_CODE = SLV_AMT;

    localparam integer DEC_INFO_W = TRANS_MST_ID_W + TRANS_DATA_LEN_W;

`ifndef SYNTHESIS
    initial begin
        if (SLV_AMT < 1)            begin $display("%m: SLV_AMT must be >= 1"); $finish; end
        if (DATA_WIDTH < 1)         begin $display("%m: DATA_WIDTH must be >= 1"); $finish; end
        if (TRANS_MST_ID_W < 1)     begin $display("%m: TRANS_MST_ID_W must be >= 1"); $finish; end
        if (TRANS_DATA_LEN_W < 1)   begin $display("%m: TRANS_DATA_LEN_W must be >= 1"); $finish; end
        if (RESP_W < 1)             begin $display("%m: Response width must be >= 1"); $finish; end
        if (DSP_RDATA_DEPTH < 1)    begin $display("%m: DSP_RDATA_DEPTH must be >= 1"); $finish; end
        if (OUTSTANDING_AMT < 1)    begin $display("%m: OUTSTANDING_AMT must be >= 1"); $finish; end
        if (SLV_ID_W < ((SLV_AMT <= 1) ? 1 : $clog2(SLV_AMT)))
            begin $display("%m: SLV_ID_W (%0d) is insufficient for SLV_AMT (%0d)", SLV_ID_W, SLV_AMT); $finish; end
        if ((DECERR_EN != 0) && (USE_AR_TRACK_FIFO == 0))
            begin $display("%m: DECERR_EN requires USE_AR_TRACK_FIFO = 1"); $finish; end
        if ((DECERR_EN != 0) && (RESP_W < 2))
            begin $display("%m: DECERR_EN requires a response width >= 2"); $finish; end
    end
`endif

    genvar slv_idx;

    wire [DATA_INFO_W-1:0] data_info        [0:SLV_AMT-1];
    wire [DATA_INFO_W-1:0] data_info_valid [0:SLV_AMT-1];

    wire fifo_rdata_wr_en [0:SLV_AMT-1];
    wire fifo_rdata_rd_en [0:SLV_AMT-1];
    wire fifo_rdata_empty [0:SLV_AMT-1];
    wire fifo_rdata_full  [0:SLV_AMT-1];

    wire sa_handshake_occur [0:SLV_AMT-1];

    wire [DATA_INFO_W*SLV_AMT-1:0] data_info_valid_flat;
    wire [SLV_AMT-1:0]              fifo_rdata_empty_flat;

    wire [DATA_INFO_W-1:0] msb_bwd_data;
    wire                    msb_bwd_valid;
    wire                    msb_bwd_ready;

    wire [DATA_INFO_W-1:0] msb_fwd_data;
    wire                    msb_fwd_valid;
    wire                    msb_fwd_ready;

    wire [TRANS_MST_ID_W-1:0] msb_fwd_RID;
    wire [DATA_WIDTH-1:0]      msb_fwd_RDATA;
    wire [RESP_W-1:0]          msb_fwd_RRESP;
    wire                       msb_fwd_RLAST;

    wire sbuf_bwd_handshake;
    wire m_axi_handshake;

    assign sbuf_bwd_handshake = msb_bwd_valid && msb_bwd_ready;
    assign m_axi_handshake    = m_RVALID_o && m_RREADY_i;

    wire [SLV_ID_W-1:0]  selected_slv_id;
    wire                  selected_slv_id_valid;

    wire [TRK_SLV_W-1:0] tracked_slv_id;
    wire                  fifo_track_empty;
    wire                  fifo_track_full;
    wire                  fifo_track_wr_en;
    wire                  fifo_track_rd_en;
    wire                  invalid_slv_id_detected;
    wire                  ingress_invalid_slv_id;
    wire                  legacy_burst_completing;

    wire                    tracked_is_dec;
    wire                    dec_beat_valid;
    wire [DATA_INFO_W-1:0]  dec_beat_data;
    wire                    dec_info_full;

    wire ar_push_req;
    wire ar_overflow;

    assign ar_push_req = dsp_AR_shift_en_i && !dsp_AR_disable_i;
    assign ar_overflow = ar_push_req && dsp_AR_stall_o;

    generate
        if (USE_AR_TRACK_FIFO != 0) begin : AR_TRACKING_FIFO_GEN

            reg fifo_err_pulse_q;
            reg fifo_err_sticky_q;

            wire                 ar_is_dec;
            wire                 ar_slv_ok;
            wire [TRK_SLV_W-1:0] trk_id_ext;
            wire [TRK_SLV_W-1:0] trk_wdata;

            assign ar_is_dec  = (DECERR_EN != 0) && dsp_AR_decerr_i;
            assign ar_slv_ok  = (dsp_AR_slv_id_i < SLV_AMT);
            assign trk_id_ext = dsp_AR_slv_id_i;
            assign trk_wdata  = ar_is_dec ? DEC_CODE : trk_id_ext;

            assign err_invalid_slv_id_pulse_o  = fifo_err_pulse_q;
            assign err_invalid_slv_id_sticky_o = fifo_err_sticky_q;

            assign ingress_invalid_slv_id = ar_push_req && !ar_is_dec && !ar_slv_ok;

            assign dsp_AR_stall_o = fifo_track_full || dec_info_full;

            assign fifo_track_wr_en = ar_push_req && !dsp_AR_stall_o &&
                                      (ar_is_dec || ar_slv_ok);

            assign invalid_slv_id_detected = !fifo_track_empty && !tracked_is_dec &&
                                             (tracked_slv_id >= SLV_AMT);

            assign fifo_track_rd_en = (sbuf_bwd_handshake && msb_bwd_data[0]) ||
                                      invalid_slv_id_detected;

            assign legacy_burst_completing = 1'b0;

            // Depth sized to OUTSTANDING_AMT + 2 to prevent silent skid overflow
            sync_fifo #(
                .DATA_WIDTH(TRK_SLV_W),
                .FIFO_DEPTH(OUTSTANDING_AMT + 2)
            ) fifo_slv_tracker (
                .clk(ACLK_i),
                .rst_n(ARESETn_i),
                .data_i(trk_wdata),
                .data_o(tracked_slv_id),
                .rd_valid_i(fifo_track_rd_en),
                .wr_valid_i(fifo_track_wr_en),
                .empty_o(fifo_track_empty),
                .full_o(fifo_track_full),
                .wr_ready_o(),
                .rd_ready_o(),
                .almost_empty_o(),
                .almost_full_o(),
                .counter()
            );

            assign selected_slv_id       = tracked_slv_id[SLV_ID_W-1:0];
            assign selected_slv_id_valid = !fifo_track_empty &&
                                           !invalid_slv_id_detected &&
                                           !tracked_is_dec;

            always @(posedge ACLK_i or negedge ARESETn_i) begin
                if (!ARESETn_i) begin
                    fifo_err_pulse_q  <= 1'b0;
                    fifo_err_sticky_q <= 1'b0;
                end
                else begin
                    fifo_err_pulse_q <= ingress_invalid_slv_id || invalid_slv_id_detected;

                    if (err_clear_i)
                        fifo_err_sticky_q <= 1'b0;
                    else if (ingress_invalid_slv_id || invalid_slv_id_detected)
                        fifo_err_sticky_q <= 1'b1;
                end
            end

            if (DECERR_EN != 0) begin : DECERR_GEN

                wire [DEC_INFO_W-1:0]       dec_info_head;
                wire                        dec_info_empty;
                wire                        dec_info_full_w;
                wire                        dec_info_wr;
                wire                        dec_info_rd;
                wire                        dec_accept;
                wire                        dec_last;
                reg  [TRANS_DATA_LEN_W-1:0] dec_beat_cnt;

                assign dec_info_wr = fifo_track_wr_en && ar_is_dec;

                sync_fifo #(
                    .DATA_WIDTH(DEC_INFO_W),
                    .FIFO_DEPTH(OUTSTANDING_AMT + 2)
                ) fifo_dec_info (
                    .clk(ACLK_i),
                    .rst_n(ARESETn_i),
                    .data_i({dsp_AR_id_i, dsp_AR_len_i}),
                    .data_o(dec_info_head),
                    .rd_valid_i(dec_info_rd),
                    .wr_valid_i(dec_info_wr),
                    .empty_o(dec_info_empty),
                    .full_o(dec_info_full_w),
                    .wr_ready_o(),
                    .rd_ready_o(),
                    .almost_empty_o(),
                    .almost_full_o(),
                    .counter()
                );

                assign dec_info_full  = dec_info_full_w;

                assign tracked_is_dec = !fifo_track_empty && (tracked_slv_id == DEC_CODE);
                assign dec_beat_valid = tracked_is_dec && !dec_info_empty;

                assign dec_last   = (dec_beat_cnt == dec_info_head[TRANS_DATA_LEN_W-1:0]);
                assign dec_accept = dec_beat_valid && msb_bwd_ready;
                assign dec_info_rd = dec_accept && dec_last;

                assign dec_beat_data = {
                    dec_info_head[DEC_INFO_W-1 -: TRANS_MST_ID_W],
                    {DATA_WIDTH{1'b0}},
                    {RESP_W{1'b1}}, // DECERR = 2'b11
                    dec_last
                };

                always @(posedge ACLK_i or negedge ARESETn_i) begin
                    if (!ARESETn_i)
                        dec_beat_cnt <= {TRANS_DATA_LEN_W{1'b0}};
                    else if (dec_accept) begin
                        if (dec_last)
                            dec_beat_cnt <= {TRANS_DATA_LEN_W{1'b0}};
                        else
                            dec_beat_cnt <= dec_beat_cnt + 1'b1;
                    end
                end

            end
            else begin : NO_DECERR
                assign dec_info_full  = 1'b0;
                assign tracked_is_dec = 1'b0;
                assign dec_beat_valid = 1'b0;
                assign dec_beat_data  = {DATA_INFO_W{1'b0}};
            end

        end
        else begin : LEGACY_BURST_LOCK_GEN

            reg                 legacy_burst_active;
            reg [SLV_ID_W-1:0]  legacy_active_slv_id;
            reg                 legacy_err_pulse_q;
            reg                 legacy_err_sticky_q;

            assign err_invalid_slv_id_pulse_o  = legacy_err_pulse_q;
            assign err_invalid_slv_id_sticky_o = legacy_err_sticky_q;

            assign tracked_slv_id          = {TRK_SLV_W{1'b0}};
            assign fifo_track_empty        = 1'b0;
            assign fifo_track_full         = 1'b0;
            assign fifo_track_wr_en        = 1'b0;
            assign fifo_track_rd_en        = 1'b0;
            assign invalid_slv_id_detected = 1'b0;
            assign tracked_is_dec          = 1'b0;
            assign dec_beat_valid          = 1'b0;
            assign dec_beat_data           = {DATA_INFO_W{1'b0}};
            assign dec_info_full           = 1'b0;

            assign ingress_invalid_slv_id  = ar_push_req && (dsp_AR_slv_id_i >= SLV_AMT);

            assign legacy_burst_completing = sbuf_bwd_handshake && msb_bwd_data[0];

            assign dsp_AR_stall_o = legacy_burst_active && !legacy_burst_completing;

            assign selected_slv_id       = legacy_active_slv_id;
            assign selected_slv_id_valid = legacy_burst_active && (selected_slv_id < SLV_AMT);

            always @(posedge ACLK_i or negedge ARESETn_i) begin
                if (!ARESETn_i) begin
                    legacy_burst_active  <= 1'b0;
                    legacy_active_slv_id <= {SLV_ID_W{1'b0}};
                    legacy_err_pulse_q   <= 1'b0;
                    legacy_err_sticky_q  <= 1'b0;
                end
                else begin
                    legacy_err_pulse_q <= ingress_invalid_slv_id;

                    if (err_clear_i)
                        legacy_err_sticky_q <= 1'b0;
                    else if (ingress_invalid_slv_id)
                        legacy_err_sticky_q <= 1'b1;

                    if (!legacy_burst_active || legacy_burst_completing) begin
                        if (ar_push_req) begin
                            if (dsp_AR_slv_id_i < SLV_AMT) begin
                                legacy_active_slv_id <= dsp_AR_slv_id_i;
                                legacy_burst_active  <= 1'b1;
                            end
                            else begin
                                legacy_burst_active  <= 1'b0;
                            end
                        end
                        else if (legacy_burst_completing) begin
                            legacy_burst_active <= 1'b0;
                        end
                    end
                end
            end

        end
    endgenerate

    reg ar_overflow_sticky_q;

    assign err_ar_overflow_sticky_o = ar_overflow_sticky_q;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i)
            ar_overflow_sticky_q <= 1'b0;
        else if (err_clear_i)
            ar_overflow_sticky_q <= 1'b0;
        else if (ar_overflow)
            ar_overflow_sticky_q <= 1'b1;
    end

    generate
        for (slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_FIFO

            sync_fifo #(
                .DATA_WIDTH(DATA_INFO_W),
                .FIFO_DEPTH(DSP_RDATA_DEPTH)
            ) fifo_rdata (
                .clk(ACLK_i),
                .rst_n(ARESETn_i),
                .data_i(data_info[slv_idx]),
                .data_o(data_info_valid[slv_idx]),
                .rd_valid_i(fifo_rdata_rd_en[slv_idx]),
                .wr_valid_i(fifo_rdata_wr_en[slv_idx]),
                .empty_o(fifo_rdata_empty[slv_idx]),
                .full_o(fifo_rdata_full[slv_idx]),
                .wr_ready_o(),
                .rd_ready_o(),
                .almost_empty_o(),
                .almost_full_o(),
                .counter()
            );

            assign data_info_valid_flat[DATA_INFO_W*(slv_idx+1)-1 -: DATA_INFO_W] =
                data_info_valid[slv_idx];
            assign fifo_rdata_empty_flat[slv_idx] = fifo_rdata_empty[slv_idx];

        end
    endgenerate

    skid_buffer #(
        .SBUF_TYPE(3),
        .DATA_WIDTH(DATA_INFO_W)
    ) mst_skid_buffer (
        .clk(ACLK_i),
        .rst_n(ARESETn_i),
        .bwd_data_i(msb_bwd_data),
        .bwd_valid_i(msb_bwd_valid),
        .bwd_ready_o(msb_bwd_ready),
        .fwd_data_o(msb_fwd_data),
        .fwd_valid_o(msb_fwd_valid),
        .fwd_ready_i(msb_fwd_ready)
    );

    generate
        for (slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_LOGIC

            assign data_info[slv_idx] = {
                sa_RID_i  [TRANS_MST_ID_W*(slv_idx+1)-1 -: TRANS_MST_ID_W],
                sa_RDATA_i[DATA_WIDTH*(slv_idx+1)-1     -: DATA_WIDTH],
                sa_RRESP_i[RESP_W*(slv_idx+1)-1         -: RESP_W],
                sa_RLAST_i[slv_idx]
            };

            assign sa_handshake_occur[slv_idx] =
                sa_RVALID_i[slv_idx] &&
                sa_RREADY_o[slv_idx];

            assign fifo_rdata_wr_en[slv_idx] =
                sa_handshake_occur[slv_idx];

            assign fifo_rdata_rd_en[slv_idx] =
                sbuf_bwd_handshake &&
                selected_slv_id_valid &&
                (selected_slv_id == slv_idx);

            assign sa_RREADY_o[slv_idx] =
                !fifo_rdata_full[slv_idx];

        end
    endgenerate

    reg [DATA_INFO_W-1:0] sel_data_info;
    reg                   sel_fifo_empty;
    integer i;

    always @* begin
        sel_data_info  = {DATA_INFO_W{1'b0}};
        sel_fifo_empty = 1'b1;
        for (i = 0; i < SLV_AMT; i = i + 1) begin
            if (selected_slv_id_valid && (selected_slv_id == i)) begin
                sel_data_info  = data_info_valid_flat[i*DATA_INFO_W +: DATA_INFO_W];
                sel_fifo_empty = fifo_rdata_empty_flat[i];
            end
        end
    end

    assign msb_bwd_data  = tracked_is_dec ? dec_beat_data  : sel_data_info;
    assign msb_bwd_valid = tracked_is_dec ? dec_beat_valid
                                          : (selected_slv_id_valid && !sel_fifo_empty);

    assign msb_fwd_ready = m_RREADY_i;

    assign {
        msb_fwd_RID,
        msb_fwd_RDATA,
        msb_fwd_RRESP,
        msb_fwd_RLAST
    } = msb_fwd_data;

    assign m_RID_o    = msb_fwd_RID;
    assign m_RDATA_o  = msb_fwd_RDATA;
    assign m_RRESP_o  = msb_fwd_RRESP;
    assign m_RLAST_o  = msb_fwd_RLAST;
    assign m_RVALID_o = msb_fwd_valid;

    assign dsp_RVALID_q1_o     = msb_bwd_valid;
    assign dsp_RREADY_q1_o     = msb_bwd_ready;
    assign dsp_RLAST_q1_o      = sbuf_bwd_handshake && msb_bwd_data[0];
    assign m_RLAST_handshake_o = m_axi_handshake && m_RLAST_o;

endmodule


