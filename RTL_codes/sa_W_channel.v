`timescale 1ns / 1ps
module sa_W_channel #(
    parameter integer MST_AMT          = 3,
    parameter integer OUTSTANDING_AMT  = 8,
    parameter integer MST_ID_W         = (MST_AMT <= 1) ? 1 : $clog2(MST_AMT),
    parameter integer DATA_WIDTH       = 32,
    parameter integer TRANS_DATA_LEN_W = 3,
    parameter integer W_FIFO_DEPTH     = 32
) (
    input  wire                               ACLK_i,
    input  wire                               ARESETn_i,

    input  wire [DATA_WIDTH*MST_AMT-1:0]      dsp_WDATA_i,
    input  wire [MST_AMT-1:0]                 dsp_WLAST_i,
    input  wire [MST_AMT-1:0]                 dsp_WVALID_i,
    input  wire [MST_AMT-1:0]                 dsp_slv_sel_i,

    input  wire                               s_WREADY_i,

    input  wire [MST_ID_W-1:0]                AW_mst_id_i,
    input  wire [TRANS_DATA_LEN_W-1:0]        AW_AxLEN_i,
    input  wire                               AW_fifo_order_wr_en_i,

    output wire [MST_AMT-1:0]                 dsp_WREADY_o,

    output wire [DATA_WIDTH-1:0]              s_WDATA_o,
    output wire                               s_WLAST_o,
    output wire                               s_WVALID_o,

    output wire                               AW_stall_o,
    output reg                                AW_error_o,
    output reg                                wlast_error_o
);

    localparam integer DATA_INFO_W = DATA_WIDTH + 1;
    localparam integer ADDR_INFO_W = MST_ID_W + TRANS_DATA_LEN_W;
    localparam integer W_INFO_W    = DATA_WIDTH + 1;

    genvar mst_idx;

    wire pipeline_load;
    wire pipeline_can_advance;
    wire transaction_en;
    wire [ADDR_INFO_W-1:0] ADDR_info;
    wire [ADDR_INFO_W-1:0] ADDR_info_valid;

    wire [MST_ID_W-1:0]         Ax_mst_id_valid;
    wire [TRANS_DATA_LEN_W-1:0] Ax_AxLEN_valid;

    wire fifo_order_wr_en;
    wire fifo_order_rd_en;
    wire fifo_order_full;
    wire fifo_order_empt;
    wire fifo_order_wr_ready;

    wire aw_mst_id_valid;

    assign ADDR_info = {AW_mst_id_i, AW_AxLEN_i};
    assign {Ax_mst_id_valid, Ax_AxLEN_valid} = ADDR_info_valid;
    assign aw_mst_id_valid = (AW_mst_id_i < MST_AMT);

    assign fifo_order_wr_en =
        AW_fifo_order_wr_en_i &&
        ARESETn_i &&
        fifo_order_wr_ready &&
        aw_mst_id_valid;

    // LEVEL stall: independent of the request (no combinational loop upstream)
    assign AW_stall_o = ARESETn_i && !fifo_order_wr_ready;

    sync_fifo_sa_w #(
        .DATA_WIDTH (ADDR_INFO_W),
        .FIFO_DEPTH (OUTSTANDING_AMT)
    ) fifo_wdata_order (
        .clk            (ACLK_i),
        .rst_n          (ARESETn_i),
        .data_i         (ADDR_info),
        .data_o         (ADDR_info_valid),
        .rd_valid_i     (fifo_order_rd_en),
        .wr_valid_i     (fifo_order_wr_en),
        .empty_o        (fifo_order_empt),
        .full_o         (fifo_order_full),
        .wr_ready_o     (fifo_order_wr_ready),
        .rd_ready_o     (),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter        ()
    );
    wire [DATA_INFO_W-1:0] DATA_info       [MST_AMT-1:0];
    wire [DATA_INFO_W-1:0] DATA_info_valid [MST_AMT-1:0];

    wire fifo_wdata_wr_en    [MST_AMT-1:0];
    wire fifo_wdata_rd_en    [MST_AMT-1:0];
    wire fifo_wdata_empt     [MST_AMT-1:0];
    wire fifo_wdata_wr_ready [MST_AMT-1:0];

    wire [MST_AMT-1:0] mst_sel;
    wire [MST_AMT-1:0] selected_master_data_vec;

    wire [DATA_INFO_W-1:0] data_mux    [MST_AMT-1:0];
    wire [DATA_INFO_W-1:0] data_mux_or [0:MST_AMT];

    generate
        for (mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : MST_W_FIFO

            sync_fifo_sa_w #(
                .DATA_WIDTH (DATA_INFO_W),
                .FIFO_DEPTH (W_FIFO_DEPTH)
            ) fifo_wdata (
                .clk            (ACLK_i),
                .rst_n          (ARESETn_i),
                .data_i         (DATA_info[mst_idx]),
                .data_o         (DATA_info_valid[mst_idx]),
                .rd_valid_i     (fifo_wdata_rd_en[mst_idx]),
                .wr_valid_i     (fifo_wdata_wr_en[mst_idx]),
                .empty_o        (fifo_wdata_empt[mst_idx]),
                .full_o         (),
                .wr_ready_o     (fifo_wdata_wr_ready[mst_idx]),
                .rd_ready_o     (),
                .almost_empty_o (),
                .almost_full_o  (),
                .counter        ()
            );

        end
    endgenerate
    generate
        for (mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : MST_LOGIC

            assign mst_sel[mst_idx] =
                (Ax_mst_id_valid == mst_idx);

            assign DATA_info[mst_idx] = {
                dsp_WLAST_i[mst_idx],
                dsp_WDATA_i[DATA_WIDTH*(mst_idx+1)-1 -: DATA_WIDTH]
            };

            assign dsp_WREADY_o[mst_idx] =
                ARESETn_i &&
                dsp_slv_sel_i[mst_idx] &&
                fifo_wdata_wr_ready[mst_idx];

            assign fifo_wdata_wr_en[mst_idx] =
                dsp_WVALID_i[mst_idx] &&
                dsp_WREADY_o[mst_idx];

            assign selected_master_data_vec[mst_idx] =
                mst_sel[mst_idx] &&
                !fifo_wdata_empt[mst_idx];

            assign data_mux[mst_idx] =
                {DATA_INFO_W{mst_sel[mst_idx]}} &
                DATA_info_valid[mst_idx];

            // Pop only when a new beat is loaded into the output register.
            assign fifo_wdata_rd_en[mst_idx] =
                mst_sel[mst_idx] &&
                pipeline_load;

        end
    endgenerate
    assign data_mux_or[0] = {DATA_INFO_W{1'b0}};

    generate
        for (mst_idx = 0; mst_idx < MST_AMT; mst_idx = mst_idx + 1) begin : DATA_MUX_OR

            assign data_mux_or[mst_idx+1] =
                data_mux_or[mst_idx] | data_mux[mst_idx];

        end
    endgenerate

    wire [DATA_INFO_W-1:0] selected_data_info;
    wire                   source_wlast;
    wire [DATA_WIDTH-1:0]  selected_wdata;

    assign selected_data_info = data_mux_or[MST_AMT];
    assign {source_wlast, selected_wdata} = selected_data_info;

    assign transaction_en =
        !fifo_order_empt &&
        (|selected_master_data_vec);

       reg [TRANS_DATA_LEN_W:0] transfer_ctn_r;

    wire [TRANS_DATA_LEN_W:0] expected_beats;
    wire [TRANS_DATA_LEN_W:0] current_beat;
    wire expected_last_beat;

    assign expected_beats = {1'b0, Ax_AxLEN_valid} + 1'b1;
    assign current_beat   = transfer_ctn_r + 1'b1;
    assign expected_last_beat = (current_beat == expected_beats);

       reg [DATA_WIDTH-1:0] s_WDATA_o_r;
    reg                  s_WLAST_o_r;
    reg                  s_WVALID_o_r;

    wire [DATA_WIDTH-1:0] s_WDATA_o_nxt;
    wire                  s_WLAST_o_nxt;
    wire                  s_WVALID_o_nxt;

    wire [W_INFO_W-1:0] ssb_bwd_data;
    wire                ssb_bwd_valid;
    wire                ssb_bwd_ready;

    wire [W_INFO_W-1:0] ssb_fwd_data;
    wire                ssb_fwd_valid;
    wire                ssb_fwd_ready;

    wire output_buffer_push;

    assign ssb_bwd_data  = {s_WDATA_o_r, s_WLAST_o_r};
    assign ssb_bwd_valid = s_WVALID_o_r;
    assign ssb_fwd_ready = s_WREADY_i;

    assign output_buffer_push = ssb_bwd_valid && ssb_bwd_ready;

    assign pipeline_can_advance = !s_WVALID_o_r || ssb_bwd_ready;

    assign pipeline_load = transaction_en && pipeline_can_advance;

    assign s_WVALID_o_nxt = transaction_en;
    assign s_WDATA_o_nxt  = selected_wdata;

    // AWLEN determines outgoing WLAST
    assign s_WLAST_o_nxt = transaction_en && expected_last_beat;

    // Retire AW-order entry on the final AWLEN-derived beat
    assign fifo_order_rd_en = pipeline_load && expected_last_beat;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            s_WVALID_o_r <= 1'b0;
            s_WLAST_o_r  <= 1'b0;
            s_WDATA_o_r  <= {DATA_WIDTH{1'b0}};
        end
        else if (pipeline_can_advance) begin
            s_WVALID_o_r <= s_WVALID_o_nxt;
            s_WLAST_o_r  <= s_WLAST_o_nxt;
            s_WDATA_o_r  <= s_WDATA_o_nxt;
        end
    end

    skid_buffer_sa_w #(
        .SBUF_TYPE  (1),
        .DATA_WIDTH (W_INFO_W)
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

    assign {s_WDATA_o, s_WLAST_o} = ssb_fwd_data;
    assign s_WVALID_o = ssb_fwd_valid;
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            transfer_ctn_r <= {(TRANS_DATA_LEN_W+1){1'b0}};
            AW_error_o     <= 1'b0;
            wlast_error_o  <= 1'b0;
        end
        else begin
            // Invalid AW master ID
            if (AW_fifo_order_wr_en_i && !aw_mst_id_valid)
                AW_error_o <= 1'b1;

            // Source WLAST vs AWLEN, checked when a beat is really loaded
            if (pipeline_load) begin
                if (source_wlast != expected_last_beat)
                    wlast_error_o <= 1'b1;

                if (expected_last_beat)
                    transfer_ctn_r <= {(TRANS_DATA_LEN_W+1){1'b0}};
                else
                    transfer_ctn_r <= transfer_ctn_r + 1'b1;
            end
        end
    end

endmodule

