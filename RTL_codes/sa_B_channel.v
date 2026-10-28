`timescale 1ns / 1ps

module sa_B_channel #(
    parameter MST_AMT                = 3,
    parameter OUTSTANDING_AMT        = 8,
    parameter MST_ID_W               = (MST_AMT > 1) ? $clog2(MST_AMT) : 1,
    parameter TRANS_MST_ID_W         = 5,
    parameter TRANS_SLV_ID_W         = TRANS_MST_ID_W + MST_ID_W,
    parameter TRANS_WR_RESP_W        = 2,
    parameter SAME_CYCLE_REALLOC_EN  = 0
) (
    input  wire                                  ACLK_i,
    input  wire                                  ARESETn_i,

    input  wire [MST_AMT-1:0]                    dsp_BREADY_i,

    input  wire [TRANS_SLV_ID_W-1:0]             s_BID_i,
    input  wire [TRANS_WR_RESP_W-1:0]            s_BRESP_i,
    input  wire                                  s_BVALID_i,

    input  wire [TRANS_SLV_ID_W-1:0]             AW_AxID_i,
    input  wire                                  AW_crossing_flag_i,
    input  wire                                  AW_track_en_i,

    input  wire                                  err_clear_i,

    output wire [TRANS_MST_ID_W*MST_AMT-1:0]     dsp_BID_o,
    output wire [TRANS_WR_RESP_W*MST_AMT-1:0]    dsp_BRESP_o,
    output wire [MST_AMT-1:0]                    dsp_BVALID_o,

    output wire                                  s_BREADY_o,
    output wire                                  AW_stall_o,

    output wire                                  err_unexpected_resp_sticky_o,
    output wire                                  err_aw_overflow_sticky_o
);

    localparam integer ID_W     = TRANS_SLV_ID_W;
    localparam integer RESP_W   = TRANS_WR_RESP_W;
    localparam integer B_INFO_W = ID_W + RESP_W;
    localparam integer TD       = OUTSTANDING_AMT;
    localparam integer PTR_W    = (TD > 1) ? $clog2(TD) : 1;

    genvar mst_idx;
    genvar slot_idx;

       wire [B_INFO_W-1:0] ssb_bwd_data;
    wire                ssb_bwd_valid;
    wire                ssb_bwd_ready;
    wire [B_INFO_W-1:0] ssb_fwd_data;
    wire                ssb_fwd_valid;
    wire                ssb_fwd_ready;

    wire [ID_W-1:0]     ssb_fwd_BID;
    wire [RESP_W-1:0]   ssb_fwd_BRESP;

    assign ssb_bwd_data  = {s_BID_i, s_BRESP_i};
    assign ssb_bwd_valid = s_BVALID_i;
    assign s_BREADY_o    = ssb_bwd_ready;

    skid_buffer_B #(
        .SBUF_TYPE  (1),
        .DATA_WIDTH (B_INFO_W)
    ) slv_skid_buffer (
        .clk         (ACLK_i),
        .rst_n       (ARESETn_i),
        .bwd_data_i  (ssb_bwd_data),
        .bwd_valid_i (ssb_bwd_valid),
        .bwd_ready_o (ssb_bwd_ready),
        .fwd_data_o  (ssb_fwd_data),
        .fwd_valid_o (ssb_fwd_valid),
        .fwd_ready_i (ssb_fwd_ready)
    );

    assign {ssb_fwd_BID, ssb_fwd_BRESP} = ssb_fwd_data;
    wire [MST_ID_W-1:0] mst_id;
    wire                mst_id_valid;
    wire                dsp_BREADY_valid;

    assign mst_id            = ssb_fwd_BID[ID_W-1 -: MST_ID_W];
    assign mst_id_valid      = (mst_id < MST_AMT);
    assign dsp_BREADY_valid  = mst_id_valid ? dsp_BREADY_i[mst_id] : 1'b0;

       reg [TD-1:0]        track_valid;
    reg [TD-1:0]        track_crossing;
    reg [TD-1:0]        track_absorbed;
    reg [TD*ID_W-1:0]   track_id_flat;
    reg [TD*RESP_W-1:0] track_resp_flat;
    reg [TD*TD-1:0]     older_flat;
    reg [TD*TD-1:0]     older_next_flat;

    wire ret_x;
    wire ret_p;
    reg [PTR_W-1:0] match_idx;
    reg [PTR_W-1:0] partner_idx;

    wire track_all_valid = &track_valid;
    wire retiring_any    = ret_x || ret_p;

    wire track_full = (SAME_CYCLE_REALLOC_EN != 0) ? (track_all_valid && !retiring_any)
                                                   : track_all_valid;

    assign AW_stall_o = track_full;
    wire do_alloc     = AW_track_en_i && !track_full;

    // Allocation logic
    reg             alloc_found;
    reg [PTR_W-1:0] alloc_idx;
    integer         a_i;

    always @* begin
        alloc_found = 1'b0;
        alloc_idx   = {PTR_W{1'b0}};

        for (a_i = 0; a_i < TD; a_i = a_i + 1) begin
            if (!track_valid[a_i] && !alloc_found) begin
                alloc_found = 1'b1;
                alloc_idx   = a_i[PTR_W-1:0];
            end
        end

        if (!alloc_found && (SAME_CYCLE_REALLOC_EN != 0)) begin
            if (ret_x) begin
                alloc_found = 1'b1;
                alloc_idx   = match_idx;
            end
            else if (ret_p) begin
                alloc_found = 1'b1;
                alloc_idx   = partner_idx;
            end
        end
    end
    reg [TD-1:0]    na_match;
    reg             match_found;
    integer         m_i, m_j;
    reg             m_has_older;

    always @* begin
        match_found = 1'b0;
        match_idx   = {PTR_W{1'b0}};
        na_match    = {TD{1'b0}};

        for (m_i = 0; m_i < TD; m_i = m_i + 1) begin
            na_match[m_i] = track_valid[m_i] && !track_absorbed[m_i] &&
                            (track_id_flat[m_i*ID_W +: ID_W] == ssb_fwd_BID);
        end

        for (m_i = 0; m_i < TD; m_i = m_i + 1) begin
            if (na_match[m_i]) begin
                m_has_older = 1'b0;
                for (m_j = 0; m_j < TD; m_j = m_j + 1) begin
                    if ((m_j != m_i) && na_match[m_j] && older_flat[m_j*TD + m_i]) begin
                        m_has_older = 1'b1;
                    end
                end
                if (!m_has_older && !match_found) begin
                    match_found = 1'b1;
                    match_idx   = m_i[PTR_W-1:0];
                end
            end
        end
    end
    reg [TD-1:0]    absorbed_match;
    reg             partner_found;
    integer         p_i, p_j;
    reg             p_has_older;

    always @* begin
        partner_found   = 1'b0;
        partner_idx     = {PTR_W{1'b0}};
        absorbed_match  = {TD{1'b0}};

        for (p_i = 0; p_i < TD; p_i = p_i + 1) begin
            absorbed_match[p_i] = track_valid[p_i] && track_absorbed[p_i] &&
                                  (track_id_flat[p_i*ID_W +: ID_W] == ssb_fwd_BID) &&
                                  (match_found && older_flat[p_i*TD + match_idx]);
        end

        for (p_i = 0; p_i < TD; p_i = p_i + 1) begin
            if (absorbed_match[p_i]) begin
                p_has_older = 1'b0;
                for (p_j = 0; p_j < TD; p_j = p_j + 1) begin
                    if ((p_j != p_i) && absorbed_match[p_j] && older_flat[p_j*TD + p_i]) begin
                        p_has_older = 1'b1;
                    end
                end
                if (!p_has_older && !partner_found) begin
                    partner_found = 1'b1;
                    partner_idx   = p_i[PTR_W-1:0];
                end
            end
        end
    end
    wire x_crossing = match_found && track_crossing[match_idx];

    wire is_absorb  = match_found &&  x_crossing;
    wire is_final   = match_found && !x_crossing;

    wire forward_to_master = ssb_fwd_valid && is_final && mst_id_valid;
    wire absorb_ok         = ssb_fwd_valid && is_absorb;

    wire unexpected_drain  = ssb_fwd_valid && (!match_found || (!mst_id_valid && is_final));

    assign ssb_fwd_ready = absorb_ok || unexpected_drain ||
                           (forward_to_master && dsp_BREADY_valid);

    wire slv_handshake_occur = ssb_fwd_valid && ssb_fwd_ready;
    wire do_absorb           = slv_handshake_occur && absorb_ok;
    wire mst_handshake_occur = forward_to_master && dsp_BREADY_valid;

    wire unmapped_retire = slv_handshake_occur && unexpected_drain && match_found && is_final;

    assign ret_x = mst_handshake_occur || unmapped_retire;
    assign ret_p = ret_x && partner_found;
    function [RESP_W-1:0] merge_resp;
        input [RESP_W-1:0] a;
        input [RESP_W-1:0] b;
        begin
            if      (a == 2'b11 || b == 2'b11) merge_resp = 2'b11;
            else if (a == 2'b10 || b == 2'b10) merge_resp = 2'b10;
            else if (a == 2'b01 && b == 2'b01) merge_resp = 2'b01;
            else                               merge_resp = 2'b00;
        end
    endfunction

    wire [RESP_W-1:0] partner_resp    = track_resp_flat[partner_idx*RESP_W +: RESP_W];
    wire [RESP_W-1:0] effective_BRESP = partner_found ? merge_resp(partner_resp, ssb_fwd_BRESP) : ssb_fwd_BRESP;
    integer n_i, n_j;

    always @* begin
        for (n_i = 0; n_i < TD; n_i = n_i + 1) begin
            for (n_j = 0; n_j < TD; n_j = n_j + 1) begin
                if (n_i == n_j) begin
                    older_next_flat[n_i*TD + n_j] = 1'b0;
                end
                else if (do_alloc && (n_i == alloc_idx)) begin
                    older_next_flat[n_i*TD + n_j] = 1'b0;
                end
                else if (do_alloc && (n_j == alloc_idx)) begin
                    // Other active valid entries are strictly older than the incoming allocated entry
                    older_next_flat[n_i*TD + n_j] = track_valid[n_i] && !((ret_x && (n_i == match_idx)) || (ret_p && (n_i == partner_idx)));
                end
                else if ((ret_x && (n_i == match_idx)) || (ret_p && (n_i == partner_idx)) ||
                         (ret_x && (n_j == match_idx)) || (ret_p && (n_j == partner_idx))) begin
                    older_next_flat[n_i*TD + n_j] = 1'b0;
                end
                else begin
                    older_next_flat[n_i*TD + n_j] = older_flat[n_i*TD + n_j];
                end
            end
        end
    end

       reg unexpected_sticky_q;
    reg overflow_sticky_q;

    assign err_unexpected_resp_sticky_o = unexpected_sticky_q;
    assign err_aw_overflow_sticky_o     = overflow_sticky_q;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            older_flat          <= {(TD*TD){1'b0}};
            unexpected_sticky_q <= 1'b0;
            overflow_sticky_q   <= 1'b0;
        end
        else begin
            older_flat <= older_next_flat;

            if (err_clear_i) begin
                unexpected_sticky_q <= 1'b0;
                overflow_sticky_q   <= 1'b0;
            end
            else begin
                if (slv_handshake_occur && unexpected_drain)
                    unexpected_sticky_q <= 1'b1;
                if (AW_track_en_i && track_full)
                    overflow_sticky_q   <= 1'b1;
            end
        end
    end

    // Per-slot sequential state update
    generate
        for (slot_idx = 0; slot_idx < TD; slot_idx = slot_idx + 1) begin : TRACKER_SLOT
            wire slot_alloc   = do_alloc && (alloc_idx == slot_idx);
            wire slot_retire  = (ret_x && (match_idx == slot_idx)) ||
                                (ret_p && (partner_idx == slot_idx));
            wire slot_absorb  = do_absorb && (match_idx == slot_idx);

            always @(posedge ACLK_i or negedge ARESETn_i) begin
                if (!ARESETn_i) begin
                    track_valid[slot_idx]                       <= 1'b0;
                    track_crossing[slot_idx]                   <= 1'b0;
                    track_absorbed[slot_idx]                   <= 1'b0;
                    track_id_flat[slot_idx*ID_W +: ID_W]       <= {ID_W{1'b0}};
                    track_resp_flat[slot_idx*RESP_W +: RESP_W] <= {RESP_W{1'b0}};
                end
                else begin
                    if (slot_alloc) begin
                        track_valid[slot_idx]                       <= 1'b1;
                        track_crossing[slot_idx]                   <= AW_crossing_flag_i;
                        track_absorbed[slot_idx]                   <= 1'b0;
                        track_id_flat[slot_idx*ID_W +: ID_W]       <= AW_AxID_i;
                        track_resp_flat[slot_idx*RESP_W +: RESP_W] <= {RESP_W{1'b0}};
                    end
                    else if (slot_retire) begin
                        track_valid[slot_idx]                       <= 1'b0;
                        track_crossing[slot_idx]                   <= 1'b0;
                        track_absorbed[slot_idx]                   <= 1'b0;
                        track_id_flat[slot_idx*ID_W +: ID_W]       <= {ID_W{1'b0}};
                        track_resp_flat[slot_idx*RESP_W +: RESP_W] <= {RESP_W{1'b0}};
                    end
                    else if (slot_absorb) begin
                        track_absorbed[slot_idx]                   <= 1'b1;
                        track_resp_flat[slot_idx*RESP_W +: RESP_W] <= ssb_fwd_BRESP;
                    end
                end
            end
        end
    endgenerate

       generate
        for (mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : MST_LOGIC
            assign dsp_BVALID_o[mst_idx] = forward_to_master && (mst_id == mst_idx);

            assign dsp_BID_o[TRANS_MST_ID_W*(mst_idx+1)-1 -: TRANS_MST_ID_W]
                = ssb_fwd_BID[TRANS_MST_ID_W-1:0];

            assign dsp_BRESP_o[RESP_W*(mst_idx+1)-1 -: RESP_W]
                = effective_BRESP;
        end
    endgenerate

endmodule
