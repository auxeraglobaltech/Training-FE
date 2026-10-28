
`timescale 1ns/1ps

module sa_Ax_channel #(
    parameter integer MST_AMT           = 3,
    parameter integer OUTSTANDING_AMT   = 8,
    parameter [MST_AMT*32-1:0] MST_WEIGHT = {MST_AMT{32'd1}},
    parameter integer MST_ID_W          = (MST_AMT <= 1) ? 1 : $clog2(MST_AMT),
    parameter integer DATA_WIDTH        = 32,
    parameter integer ADDR_WIDTH        = 32,
    parameter integer TRANS_MST_ID_W    = 5,
    parameter integer TRANS_SLV_ID_W    = TRANS_MST_ID_W + MST_ID_W,
    parameter integer TRANS_BURST_W     = 2,
    parameter integer TRANS_DATA_LEN_W  = 3,
    parameter integer TRANS_DATA_SIZE_W = 3,
    parameter integer SLV_ID            = 0,
    parameter integer SLV_ID_MSB_IDX    = 30,
    parameter integer SLV_ID_LSB_IDX    = 30
) (
    input  wire                                 ACLK_i,
    input  wire                                 ARESETn_i,
    input  wire                                 xDATA_stall_i,
    input  wire [TRANS_MST_ID_W*MST_AMT-1:0]    dsp_AxID_i,
    input  wire [ADDR_WIDTH*MST_AMT-1:0]        dsp_AxADDR_i,
    input  wire [TRANS_BURST_W*MST_AMT-1:0]     dsp_AxBURST_i,
    input  wire [TRANS_DATA_LEN_W*MST_AMT-1:0]  dsp_AxLEN_i,
    input  wire [TRANS_DATA_SIZE_W*MST_AMT-1:0] dsp_AxSIZE_i,
    input  wire [MST_AMT-1:0]                   dsp_AxVALID_i,
    input  wire [MST_AMT-1:0]                   dsp_dispatcher_full_i,
    input  wire                                 s_AxREADY_i,
    output wire [MST_AMT-1:0]                   dsp_AxREADY_o,
    output wire [TRANS_SLV_ID_W-1:0]            s_AxID_o,
    output wire [ADDR_WIDTH-1:0]                s_AxADDR_o,
    output wire [TRANS_BURST_W-1:0]             s_AxBURST_o,
    output wire [TRANS_DATA_LEN_W-1:0]          s_AxLEN_o,
    output wire [TRANS_DATA_SIZE_W-1:0]         s_AxSIZE_o,
    output wire                                 s_AxVALID_o,
    output wire [TRANS_SLV_ID_W-1:0]            xDATA_AxID_o,
    output wire [TRANS_DATA_LEN_W-1:0]          xDATA_AxLEN_o,
    output wire [MST_ID_W-1:0]                  xDATA_mst_id_o,
    output wire                                 xDATA_crossing_flag_o,
    output wire                                 xDATA_fifo_order_wr_en_o
);
    localparam integer SLV_ID_MAP_W = SLV_ID_MSB_IDX - SLV_ID_LSB_IDX + 1;
    localparam integer ADDR_INFO_W =
        TRANS_MST_ID_W + ADDR_WIDTH + TRANS_BURST_W +
        TRANS_DATA_LEN_W + TRANS_DATA_SIZE_W;
    localparam integer AX_INFO_W =
        TRANS_SLV_ID_W + ADDR_WIDTH + TRANS_BURST_W +
        TRANS_DATA_LEN_W + TRANS_DATA_SIZE_W;
`ifndef SYNTHESIS
    initial begin
        if (MST_AMT < 1)            begin $display("sa_Ax_channel: MST_AMT must be > 0"); $finish; end
        if (OUTSTANDING_AMT < 1)    begin $display("sa_Ax_channel: OUTSTANDING_AMT must be > 0"); $finish; end
        if (ADDR_WIDTH < 12)        begin $display("sa_Ax_channel: ADDR_WIDTH must be >= 12"); $finish; end
        if (SLV_ID_MSB_IDX < SLV_ID_LSB_IDX) begin $display("sa_Ax_channel: SLV_ID_MSB_IDX < SLV_ID_LSB_IDX"); $finish; end
        if (SLV_ID_LSB_IDX < 0)     begin $display("sa_Ax_channel: SLV_ID_LSB_IDX negative"); $finish; end
        if (SLV_ID_MSB_IDX >= ADDR_WIDTH) begin $display("sa_Ax_channel: SLV_ID_MSB_IDX outside ADDR_WIDTH"); $finish; end
        if (SLV_ID >= (1 << SLV_ID_MAP_W)) begin $display("sa_Ax_channel: SLV_ID does not fit mapping field"); $finish; end
    end
`endif
    genvar mst_idx;
    // Per-master views
    wire [ADDR_INFO_W-1:0]       addr_info       [0:MST_AMT-1];
    wire [ADDR_INFO_W-1:0]       addr_info_valid [0:MST_AMT-1];
    wire [TRANS_MST_ID_W-1:0]    AxID_in         [0:MST_AMT-1];
    wire [ADDR_WIDTH-1:0]        AxADDR_i        [0:MST_AMT-1];
    wire [TRANS_BURST_W-1:0]     AxBURST_in      [0:MST_AMT-1];
    wire [TRANS_DATA_LEN_W-1:0]  AxLEN_in        [0:MST_AMT-1];
    wire [TRANS_DATA_SIZE_W-1:0] AxSIZE_in       [0:MST_AMT-1];
    wire [TRANS_MST_ID_W-1:0]    AxID_fifo       [0:MST_AMT-1];
    wire [ADDR_WIDTH-1:0]        AxADDR_valid    [0:MST_AMT-1];
    wire [TRANS_BURST_W-1:0]     AxBURST_fifo    [0:MST_AMT-1];
    wire [TRANS_DATA_LEN_W-1:0]  AxLEN_fifo      [0:MST_AMT-1];
    wire [TRANS_DATA_SIZE_W-1:0] AxSIZE_fifo     [0:MST_AMT-1];
    wire [ADDR_WIDTH-1:0]        AxADDR_valid_split [0:MST_AMT-1];
    wire [TRANS_DATA_LEN_W-1:0]  AxLEN_valid_split  [0:MST_AMT-1];
    wire splitter_invalid        [0:MST_AMT-1];
    wire fifo_addr_info_full     [0:MST_AMT-1];
    wire fifo_addr_info_empt     [0:MST_AMT-1];
    wire fifo_addr_info_wr_en    [0:MST_AMT-1];
    wire fifo_addr_info_rd_en    [0:MST_AMT-1];
    wire dsp_handshake_occur     [0:MST_AMT-1];
    wire dsp_AxVALID_dec         [0:MST_AMT-1];
    wire slv_addr_decoder        [0:MST_AMT-1];
    wire msk_addr_crossing_flag  [0:MST_AMT-1];
    wire msk_split_addr_sel_nxt  [0:MST_AMT-1];
    wire msk_split_addr_sel_en   [0:MST_AMT-1];
    wire rd_addr_info            [0:MST_AMT-1];
    reg  msk_split_addr_sel      [0:MST_AMT-1];
    // Flattened vectors used inside always @* (array reads in @* are unreliable)
    wire [MST_AMT*TRANS_MST_ID_W-1:0]    AxID_fifo_flat;
    wire [MST_AMT*ADDR_WIDTH-1:0]        AxADDR_split_flat;
    wire [MST_AMT*TRANS_BURST_W-1:0]     AxBURST_fifo_flat;
    wire [MST_AMT*TRANS_DATA_LEN_W-1:0]  AxLEN_split_flat;
    wire [MST_AMT*TRANS_DATA_SIZE_W-1:0] AxSIZE_fifo_flat;
    wire [MST_AMT-1:0]                   crossing_valid_flat;
    wire [MST_AMT-1:0] arb_req;
    wire [MST_AMT-1:0] arb_grant_valid;
    wire               arb_grant_ready;
    wire [MST_ID_W-1:0] granted_mst_id;
    wire               any_grant;
    reg [TRANS_SLV_ID_W-1:0]     AxID_o_nxt;
    reg [ADDR_WIDTH-1:0]         AxADDR_o_nxt;
    reg [TRANS_BURST_W-1:0]      AxBURST_o_nxt;
    reg [TRANS_DATA_LEN_W-1:0]   AxLEN_o_nxt;
    reg [TRANS_DATA_SIZE_W-1:0]  AxSIZE_o_nxt;
    wire                         AxVALID_o_nxt;
    wire slv_handshake_occur;
    wire tbr_trans_boot;
    wire xADDR_channel_shift_en;
    wire x_channel_shift_en;
    wire [AX_INFO_W-1:0] ssb_bwd_data;
    wire                 ssb_bwd_valid;
    wire                 ssb_bwd_ready;
    wire [AX_INFO_W-1:0] ssb_fwd_data;
    wire                 ssb_fwd_valid;
    wire                 ssb_fwd_ready;
    wire [TRANS_SLV_ID_W-1:0]    ssb_fwd_AxID;
    wire [ADDR_WIDTH-1:0]        ssb_fwd_AxADDR;
    wire [TRANS_BURST_W-1:0]     ssb_fwd_AxBURST;
    wire [TRANS_DATA_LEN_W-1:0]  ssb_fwd_AxLEN;
    wire [TRANS_DATA_SIZE_W-1:0] ssb_fwd_AxSIZE;
    reg [TRANS_SLV_ID_W-1:0]     AxID_o_r;
    reg [ADDR_WIDTH-1:0]         AxADDR_o_r;
    reg [TRANS_BURST_W-1:0]      AxBURST_o_r;
    reg [TRANS_DATA_LEN_W-1:0]   AxLEN_o_r;
    reg [TRANS_DATA_SIZE_W-1:0]  AxSIZE_o_r;
    reg                          AxVALID_o_r;
    // ------------------------------------------------------------------
    // Per-master FIFO + splitter
    // ------------------------------------------------------------------
    generate
        for (mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : GEN_MST_FIFO
            sync_fifo #(
                .FIFO_TYPE  (2),
                .DATA_WIDTH (ADDR_INFO_W),
                .FIFO_DEPTH (OUTSTANDING_AMT)
            ) fifo_Ax_channel (
                .clk            (ACLK_i),
                .rst_n          (ARESETn_i),
                .data_i         (addr_info[mst_idx]),
                .data_o         (addr_info_valid[mst_idx]),
                .rd_valid_i     (fifo_addr_info_rd_en[mst_idx]),
                .wr_valid_i     (fifo_addr_info_wr_en[mst_idx]),
                .empty_o        (fifo_addr_info_empt[mst_idx]),
                .full_o         (fifo_addr_info_full[mst_idx]),
                .wr_ready_o     (),
                .rd_ready_o     (),
                .almost_empty_o (),
                .almost_full_o  (),
                .counter        ()
            );
            splitting_4kb_masker #(
                .ADDR_WIDTH  (ADDR_WIDTH),
                .LEN_WIDTH   (TRANS_DATA_LEN_W),
                .SIZE_WIDTH  (TRANS_DATA_SIZE_W),
                .BURST_WIDTH (TRANS_BURST_W)
            ) splitting_4kb_masker_inst (
                .valid_i       (!fifo_addr_info_empt[mst_idx]),
                .ADDR_i        (AxADDR_valid[mst_idx]),
                .LEN_i         (AxLEN_fifo[mst_idx]),
                .SIZE_i        (AxSIZE_fifo[mst_idx]),
                .BURST_i       (AxBURST_fifo[mst_idx]),
                .mask_sel_i    (msk_split_addr_sel[mst_idx]),
                .ADDR_split_o  (AxADDR_valid_split[mst_idx]),
                .LEN_split_o   (AxLEN_valid_split[mst_idx]),
                .crossing_flag (msk_addr_crossing_flag[mst_idx]),
                .invalid_o     (splitter_invalid[mst_idx])
            );
        end
    endgenerate
    arbiter_iwrr_1cycle #(
        .P_REQUESTER_NUM   (MST_AMT),
        .P_NUM_GRANT_REQ_W (1)
    ) arbiter_inst (
        .clk             (ACLK_i),
        .rst_n           (ARESETn_i),
        .req_i           (arb_req),
        .req_weight_i    (MST_WEIGHT),
        .num_grant_req_i (1'b1),
        .grant_ready_i   (arb_grant_ready),
        .grant_valid_o   (arb_grant_valid)
    );
    onehot_encoder #(
        .INPUT_W  (MST_AMT),
        .OUTPUT_W (MST_ID_W)
    ) master_id_encoder_inst (
        .i (arb_grant_valid),
        .o (granted_mst_id)
    );
    skid_buffer #(
        .SBUF_TYPE  (3),
        .DATA_WIDTH (AX_INFO_W)
    ) slv_skid_buffer_inst (
        .clk         (ACLK_i),
        .rst_n       (ARESETn_i),
        .bwd_data_i  (ssb_bwd_data),
        .bwd_valid_i (ssb_bwd_valid),
        .bwd_ready_o (ssb_bwd_ready),
        .fwd_data_o  (ssb_fwd_data),
        .fwd_valid_o (ssb_fwd_valid),
        .fwd_ready_i (ssb_fwd_ready)
    );
    // ------------------------------------------------------------------
    // Per-master logic
    // ------------------------------------------------------------------
    generate
        for (mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : GEN_MST_LOGIC
            assign dsp_AxREADY_o[mst_idx] =
                ARESETn_i &&
                !dsp_dispatcher_full_i[mst_idx] &&
                !fifo_addr_info_full[mst_idx];
            assign AxID_in   [mst_idx] = dsp_AxID_i   [TRANS_MST_ID_W*(mst_idx+1)-1 -: TRANS_MST_ID_W];
            assign AxADDR_i  [mst_idx] = dsp_AxADDR_i [ADDR_WIDTH*(mst_idx+1)-1 -: ADDR_WIDTH];
            assign AxBURST_in[mst_idx] = dsp_AxBURST_i[TRANS_BURST_W*(mst_idx+1)-1 -: TRANS_BURST_W];
            assign AxLEN_in  [mst_idx] = dsp_AxLEN_i  [TRANS_DATA_LEN_W*(mst_idx+1)-1 -: TRANS_DATA_LEN_W];
            assign AxSIZE_in [mst_idx] = dsp_AxSIZE_i [TRANS_DATA_SIZE_W*(mst_idx+1)-1 -: TRANS_DATA_SIZE_W];
            assign slv_addr_decoder[mst_idx] =
                (AxADDR_i[mst_idx][SLV_ID_MSB_IDX:SLV_ID_LSB_IDX] == SLV_ID);
            assign dsp_AxVALID_dec[mst_idx] =
                slv_addr_decoder[mst_idx] && dsp_AxVALID_i[mst_idx];
            assign addr_info[mst_idx] = {
                AxID_in[mst_idx], AxADDR_i[mst_idx], AxBURST_in[mst_idx],
                AxLEN_in[mst_idx], AxSIZE_in[mst_idx]
            };
            assign dsp_handshake_occur[mst_idx] =
                dsp_AxVALID_dec[mst_idx] && dsp_AxREADY_o[mst_idx];
            assign fifo_addr_info_wr_en[mst_idx] = dsp_handshake_occur[mst_idx];
            assign {
                AxID_fifo[mst_idx], AxADDR_valid[mst_idx], AxBURST_fifo[mst_idx],
                AxLEN_fifo[mst_idx], AxSIZE_fifo[mst_idx]
            } = addr_info_valid[mst_idx];
            // Flattened copies for the output mux
            assign AxID_fifo_flat    [mst_idx*TRANS_MST_ID_W    +: TRANS_MST_ID_W]    = AxID_fifo[mst_idx];
            assign AxADDR_split_flat [mst_idx*ADDR_WIDTH        +: ADDR_WIDTH]        = AxADDR_valid_split[mst_idx];
            assign AxBURST_fifo_flat [mst_idx*TRANS_BURST_W     +: TRANS_BURST_W]     = AxBURST_fifo[mst_idx];
            assign AxLEN_split_flat  [mst_idx*TRANS_DATA_LEN_W  +: TRANS_DATA_LEN_W]  = AxLEN_valid_split[mst_idx];
            assign AxSIZE_fifo_flat  [mst_idx*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W] = AxSIZE_fifo[mst_idx];
            assign crossing_valid_flat[mst_idx] =
                !msk_split_addr_sel[mst_idx] && msk_addr_crossing_flag[mst_idx];
            // Entry consumed only when a valid beat is actually loaded
            assign rd_addr_info[mst_idx] =
                arb_grant_valid[mst_idx] &&
                xADDR_channel_shift_en &&
                AxVALID_o_nxt;
            // Pop after the whole burst, or after the 2nd half of a split;
            // also discard entries the splitter rejects.
            assign fifo_addr_info_rd_en[mst_idx] =
                (rd_addr_info[mst_idx] &&
                 (!msk_addr_crossing_flag[mst_idx] || msk_split_addr_sel[mst_idx])) ||
                splitter_invalid[mst_idx];
            assign msk_split_addr_sel_nxt[mst_idx] = !msk_split_addr_sel[mst_idx];
            assign msk_split_addr_sel_en[mst_idx] =
                (rd_addr_info[mst_idx] && msk_addr_crossing_flag[mst_idx]) ||
                splitter_invalid[mst_idx];
            assign arb_req[mst_idx] =
                !fifo_addr_info_empt[mst_idx] && !splitter_invalid[mst_idx];
`ifndef SYNTHESIS
            always @(posedge ACLK_i) begin
                if (ARESETn_i && splitter_invalid[mst_idx])
                    $display("%m: invalid Ax entry (reserved burst / bad split) discarded @%0t", $time);
            end
`endif
            always @(posedge ACLK_i or negedge ARESETn_i) begin
                if (!ARESETn_i)
                    msk_split_addr_sel[mst_idx] <= 1'b0;
                else if (splitter_invalid[mst_idx])
                    msk_split_addr_sel[mst_idx] <= 1'b0;
                else if (msk_split_addr_sel_en[mst_idx])
                    msk_split_addr_sel[mst_idx] <= msk_split_addr_sel_nxt[mst_idx];
            end
        end
    endgenerate
    // ------------------------------------------------------------------
    // Shift / handshake control
    // ------------------------------------------------------------------
    assign any_grant = |arb_grant_valid;
    assign slv_handshake_occur = ssb_bwd_valid && ssb_bwd_ready;
    assign tbr_trans_boot = AxVALID_o_nxt && !AxVALID_o_r;
    assign xADDR_channel_shift_en = slv_handshake_occur || tbr_trans_boot;
    assign x_channel_shift_en = xADDR_channel_shift_en && !xDATA_stall_i;
    // FIX: arbiter only advances when a beat is really issued (not on stall)
    assign arb_grant_ready = xADDR_channel_shift_en && AxVALID_o_nxt;
    assign AxVALID_o_nxt = any_grant && !xDATA_stall_i;
    always @* begin
        AxID_o_nxt    = {TRANS_SLV_ID_W{1'b0}};
        AxADDR_o_nxt  = {ADDR_WIDTH{1'b0}};
        AxBURST_o_nxt = {TRANS_BURST_W{1'b0}};
        AxLEN_o_nxt   = {TRANS_DATA_LEN_W{1'b0}};
        AxSIZE_o_nxt  = {TRANS_DATA_SIZE_W{1'b0}};
        if (any_grant && (granted_mst_id < MST_AMT)) begin
            AxID_o_nxt    = {granted_mst_id,
                             AxID_fifo_flat[granted_mst_id*TRANS_MST_ID_W +: TRANS_MST_ID_W]};
            AxADDR_o_nxt  = AxADDR_split_flat[granted_mst_id*ADDR_WIDTH +: ADDR_WIDTH];
            AxBURST_o_nxt = AxBURST_fifo_flat[granted_mst_id*TRANS_BURST_W +: TRANS_BURST_W];
            AxLEN_o_nxt   = AxLEN_split_flat[granted_mst_id*TRANS_DATA_LEN_W +: TRANS_DATA_LEN_W];
            AxSIZE_o_nxt  = AxSIZE_fifo_flat[granted_mst_id*TRANS_DATA_SIZE_W +: TRANS_DATA_SIZE_W];
        end
    end
    assign xDATA_AxID_o   = AxID_o_nxt;
    assign xDATA_mst_id_o = AxID_o_nxt[TRANS_SLV_ID_W-1 -: MST_ID_W];
    assign xDATA_AxLEN_o  = AxLEN_o_nxt;
    assign xDATA_crossing_flag_o =
        (any_grant && (granted_mst_id < MST_AMT)) ?
        crossing_valid_flat[granted_mst_id] : 1'b0;
    assign xDATA_fifo_order_wr_en_o = AxVALID_o_nxt && x_channel_shift_en;
    // ------------------------------------------------------------------
    // Output skid buffer
    // ------------------------------------------------------------------
    assign s_AxID_o    = ssb_fwd_AxID;
    assign s_AxADDR_o  = ssb_fwd_AxADDR;
    assign s_AxBURST_o = ssb_fwd_AxBURST;
    assign s_AxLEN_o   = ssb_fwd_AxLEN;
    assign s_AxSIZE_o  = ssb_fwd_AxSIZE;
    assign s_AxVALID_o = ssb_fwd_valid;
    assign ssb_bwd_data = {AxID_o_r, AxADDR_o_r, AxBURST_o_r, AxLEN_o_r, AxSIZE_o_r};
    assign ssb_bwd_valid = AxVALID_o_r;
    assign ssb_fwd_ready = s_AxREADY_i;
    assign {ssb_fwd_AxID, ssb_fwd_AxADDR, ssb_fwd_AxBURST,
            ssb_fwd_AxLEN, ssb_fwd_AxSIZE} = ssb_fwd_data;
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            AxID_o_r    <= {TRANS_SLV_ID_W{1'b0}};
            AxADDR_o_r  <= {ADDR_WIDTH{1'b0}};
            AxBURST_o_r <= {TRANS_BURST_W{1'b0}};
            AxLEN_o_r   <= {TRANS_DATA_LEN_W{1'b0}};
            AxSIZE_o_r  <= {TRANS_DATA_SIZE_W{1'b0}};
        end
        else if (x_channel_shift_en) begin
            AxID_o_r    <= AxID_o_nxt;
            AxADDR_o_r  <= AxADDR_o_nxt;
            AxBURST_o_r <= AxBURST_o_nxt;
            AxLEN_o_r   <= AxLEN_o_nxt;
            AxSIZE_o_r  <= AxSIZE_o_nxt;
        end
    end
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i)
            AxVALID_o_r <= 1'b0;
        else if (xADDR_channel_shift_en)
            AxVALID_o_r <= AxVALID_o_nxt;
    end
endmodule
    
