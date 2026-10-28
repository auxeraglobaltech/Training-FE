`timescale 1ns/1ps

module dsp_Ax_channel #(
    parameter integer SLV_AMT           = 2,
    parameter integer OUTSTANDING_AMT   = 8,
    parameter integer OUTST_CTN_W       = $clog2(OUTSTANDING_AMT) + 1,
    parameter integer DATA_WIDTH        = 32,
    parameter integer ADDR_WIDTH        = 32,
    parameter integer TRANS_MST_ID_W    = 5,
    parameter integer TRANS_BURST_W     = 2,
    parameter integer TRANS_DATA_LEN_W  = 3,
    parameter integer TRANS_DATA_SIZE_W = 3,
    parameter integer SLV_ID_W          = (SLV_AMT <= 1) ? 1 : $clog2(SLV_AMT),
    parameter integer SLV_ID_MSB_IDX    = 30,
    parameter integer SLV_ID_LSB_IDX    = 30
) (
    input  wire                                  ACLK_i,
    input  wire                                  ARESETn_i,

    input  wire [TRANS_MST_ID_W-1:0]              m_AxID_i,
    input  wire [ADDR_WIDTH-1:0]                  m_AxADDR_i,
    input  wire [TRANS_BURST_W-1:0]              m_AxBURST_i,
    input  wire [TRANS_DATA_LEN_W-1:0]            m_AxLEN_i,
    input  wire [TRANS_DATA_SIZE_W-1:0]          m_AxSIZE_i,
    input  wire                                  m_AxVALID_i,

    input  wire                                  m_xVALID_i,
    input  wire                                  m_xREADY_i,

    input  wire [SLV_AMT-1:0]                    sa_AxREADY_i,

    output wire                                  m_AxREADY_o,

    output wire [TRANS_MST_ID_W*SLV_AMT-1:0]      sa_AxID_o,
    output wire [ADDR_WIDTH*SLV_AMT-1:0]          sa_AxADDR_o,
    output wire [TRANS_BURST_W*SLV_AMT-1:0]      sa_AxBURST_o,
    output wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]    sa_AxLEN_o,
    output wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0]  sa_AxSIZE_o,
    output wire [SLV_AMT-1:0]                    sa_AxVALID_o,

    output wire [OUTST_CTN_W-1:0]                sa_Ax_outst_ctn_o,

    output wire [SLV_ID_W-1:0]                    dsp_xDATA_slv_id_o,
    output wire                                  dsp_xDATA_disable_o,

    output wire [SLV_ID_W-1:0]                    dsp_WRESP_slv_id_o,
    output wire                                  dsp_WRESP_shift_en_o,

    output wire                                  dsp_decerr_valid_o,
    output wire [TRANS_MST_ID_W-1:0]              dsp_decerr_id_o,
    output wire [TRANS_DATA_LEN_W-1:0]            dsp_decerr_len_o,
    input  wire                                  dsp_decerr_ready_i
);

    localparam integer ADDR_INFO_W = SLV_ID_W + TRANS_DATA_LEN_W;
    localparam integer AX_INFO_W   = TRANS_MST_ID_W + ADDR_WIDTH + TRANS_BURST_W + TRANS_DATA_LEN_W + TRANS_DATA_SIZE_W;
    localparam integer SLV_ID_MAP_W = SLV_ID_MSB_IDX - SLV_ID_LSB_IDX + 1;
    localparam [TRANS_BURST_W-1:0] AXI_BURST_RSVD = {TRANS_BURST_W{1'b1}};

    genvar slv_idx;
    wire [SLV_ID_MAP_W-1:0] in_addr_slv_mapping = m_AxADDR_i[SLV_ID_MSB_IDX:SLV_ID_LSB_IDX];
    wire in_addr_range_valid = (m_AxADDR_i[29:16] == 14'h0);
    wire in_addr_slv_valid   = (in_addr_slv_mapping < SLV_AMT) && in_addr_range_valid;
    wire in_burst_invalid    = (m_AxBURST_i == AXI_BURST_RSVD);
    wire in_route_ok         = in_addr_slv_valid && !in_burst_invalid;

       reg [OUTST_CTN_W-1:0] in_flight_cnt;
    wire in_hs  = m_AxVALID_i && m_AxREADY_o;
    wire out_hs = m_xVALID_i && m_xREADY_i;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            in_flight_cnt <= {OUTST_CTN_W{1'b0}};
        end else begin
            case ({in_hs && in_route_ok, out_hs})
                2'b10: in_flight_cnt <= in_flight_cnt + 1'b1;
                2'b01: if (in_flight_cnt > 0) in_flight_cnt <= in_flight_cnt - 1'b1;
                default: in_flight_cnt <= in_flight_cnt;
            endcase
        end
    end

    wire outst_limit_hit = (in_flight_cnt >= OUTSTANDING_AMT);

       assign dsp_decerr_valid_o = m_AxVALID_i && !in_route_ok;
    assign dsp_decerr_id_o    = m_AxID_i;
    assign dsp_decerr_len_o   = m_AxLEN_i;

       wire [AX_INFO_W-1:0] msb_bwd_data = {m_AxID_i, m_AxADDR_i, m_AxBURST_i, m_AxLEN_i, m_AxSIZE_i};
    wire msb_bwd_valid = m_AxVALID_i && in_route_ok && !outst_limit_hit;
    wire msb_bwd_ready;

    wire [AX_INFO_W-1:0] msb_fwd_data;
    wire msb_fwd_valid;
    wire msb_fwd_ready;

    skid_buffer #(
        .SBUF_TYPE  (1),
        .DATA_WIDTH (AX_INFO_W)
    ) mst_skid_buffer (
        .clk         (ACLK_i),
        .rst_n       (ARESETn_i),
        .bwd_data_i  (msb_bwd_data),
        .bwd_valid_i (msb_bwd_valid),
        .bwd_ready_o (msb_bwd_ready),
        .fwd_data_o  (msb_fwd_data),
        .fwd_valid_o (msb_fwd_valid),
        .fwd_ready_i (msb_fwd_ready)
    );

    wire [TRANS_MST_ID_W-1:0]    fwd_AxID;
    wire [ADDR_WIDTH-1:0]        fwd_AxADDR;
    wire [TRANS_BURST_W-1:0]     fwd_AxBURST;
    wire [TRANS_DATA_LEN_W-1:0]  fwd_AxLEN;
    wire [TRANS_DATA_SIZE_W-1:0] fwd_AxSIZE;

    assign {fwd_AxID, fwd_AxADDR, fwd_AxBURST, fwd_AxLEN, fwd_AxSIZE} = msb_fwd_data;

    wire [SLV_ID_MAP_W-1:0] fwd_slv_mapping = fwd_AxADDR[SLV_ID_MSB_IDX:SLV_ID_LSB_IDX];
    wire [SLV_AMT-1:0] slv_sel;
    generate
        for (slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_SELECT
            assign slv_sel[slv_idx] = (fwd_slv_mapping == slv_idx);
        end
    endgenerate
    wire [ADDR_INFO_W-1:0] addr_info = {fwd_slv_mapping[SLV_ID_W-1:0], fwd_AxLEN};
    wire [ADDR_INFO_W-1:0] addr_info_valid;
    wire [SLV_ID_W-1:0] slv_id;
    wire [TRANS_DATA_LEN_W-1:0] AxLEN_valid;
    wire fifo_xa_order_full;
    wire fifo_xa_order_empty;

    wire fwd_handshake = msb_fwd_valid && msb_fwd_ready;

    reg [TRANS_DATA_LEN_W-1:0] transfer_ctn_r;
    wire transfer_ctn_match = !fifo_xa_order_empty && (transfer_ctn_r == AxLEN_valid);
    wire fifo_xa_order_rd_en = transfer_ctn_match && (m_xVALID_i && m_xREADY_i);

    sync_fifo #(
        .DATA_WIDTH  (ADDR_INFO_W),
        .FIFO_DEPTH  (OUTSTANDING_AMT),
        .COUNT_WIDTH (OUTST_CTN_W)
    ) fifo_xaddr_order (
        .clk            (ACLK_i),
        .rst_n          (ARESETn_i),
        .data_i         (addr_info),
        .data_o         (addr_info_valid),
        .rd_valid_i     (fifo_xa_order_rd_en),
        .wr_valid_i     (fwd_handshake),
        .empty_o        (fifo_xa_order_empty),
        .full_o         (fifo_xa_order_full),
        .wr_ready_o     (),
        .rd_ready_o     (),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter        (sa_Ax_outst_ctn_o)
    );

    assign {slv_id, AxLEN_valid} = addr_info_valid;

    // Downstream slave signals
    assign msb_fwd_ready = (|(sa_AxREADY_i & slv_sel)) && !fifo_xa_order_full;

    generate
        for (slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_LOGIC
            assign sa_AxID_o   [TRANS_MST_ID_W*(slv_idx+1)-1 -: TRANS_MST_ID_W]       = fwd_AxID;
            assign sa_AxADDR_o [ADDR_WIDTH*(slv_idx+1)-1 -: ADDR_WIDTH]               = fwd_AxADDR;
            assign sa_AxBURST_o[TRANS_BURST_W*(slv_idx+1)-1 -: TRANS_BURST_W]         = fwd_AxBURST;
            assign sa_AxLEN_o  [TRANS_DATA_LEN_W*(slv_idx+1)-1 -: TRANS_DATA_LEN_W]   = fwd_AxLEN;
            assign sa_AxSIZE_o [TRANS_DATA_SIZE_W*(slv_idx+1)-1 -: TRANS_DATA_SIZE_W] = fwd_AxSIZE;
            assign sa_AxVALID_o[slv_idx] = msb_fwd_valid && slv_sel[slv_idx] && !fifo_xa_order_full;
        end
    endgenerate

    assign dsp_xDATA_slv_id_o   = fifo_xa_order_empty ? {SLV_ID_W{1'b0}} : slv_id;
    assign dsp_xDATA_disable_o  = fifo_xa_order_empty;
    assign dsp_WRESP_slv_id_o   = fifo_xa_order_empty ? {SLV_ID_W{1'b0}} : slv_id;
    assign dsp_WRESP_shift_en_o = fifo_xa_order_rd_en;
    assign m_AxREADY_o = ARESETn_i && (
        in_route_ok ? (msb_bwd_ready && !outst_limit_hit)
                    : dsp_decerr_ready_i
    );

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i)
            transfer_ctn_r <= {TRANS_DATA_LEN_W{1'b0}};
        else if (m_xVALID_i && m_xREADY_i) begin
            if (fifo_xa_order_empty || transfer_ctn_match)
                transfer_ctn_r <= {TRANS_DATA_LEN_W{1'b0}};
            else
                transfer_ctn_r <= transfer_ctn_r + 1'b1;
        end
    end

endmodule



