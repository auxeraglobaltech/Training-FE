`timescale 1ns / 1ps
module dsp_B_channel #(
    parameter SLV_AMT                 = 2,
    parameter OUTSTANDING_AMT         = 8,
    parameter OUTST_CTN_W             = $clog2(OUTSTANDING_AMT) + 1,
    parameter TRANS_MST_ID_W          = 5,
    parameter TRANS_WR_RESP_W         = 2,
    parameter SLV_ID_W                = (SLV_AMT > 1) ? $clog2(SLV_AMT) : 1,
    parameter AW_EVENT_PER_SUB_BURST  = 0
) (
    input  wire                                  ACLK_i,
    input  wire                                  ARESETn_i,

    input  wire                                  m_BREADY_i,

    input  wire [TRANS_MST_ID_W*SLV_AMT-1:0]     sa_BID_i,
    input  wire [TRANS_WR_RESP_W*SLV_AMT-1:0]    sa_BRESP_i,
    input  wire [SLV_AMT-1:0]                    sa_BVALID_i,

    // Qualified AW dispatch event
    input  wire [SLV_ID_W-1:0]                   dsp_AW_slv_id_i,
    input  wire                                  dsp_AW_shift_en_i,
    input  wire                                  dsp_AW_crossing_flag_i,

    output wire [TRANS_MST_ID_W-1:0]             m_BID_o,
    output wire [TRANS_WR_RESP_W-1:0]            m_BRESP_o,
    output wire                                  m_BVALID_o,

    output wire [OUTST_CTN_W-1:0]                sa_B_outst_ctn_o,
    output wire [SLV_AMT-1:0]                    sa_BREADY_o,

    output wire                                  dsp_AW_stall_o
);

    localparam RESP_INFO_W = TRANS_MST_ID_W + TRANS_WR_RESP_W;

`ifndef SYNTHESIS
    initial begin
        if (SLV_AMT < 1) begin
            $display("\%m: dsp_B_channel: SLV_AMT must be >= 1"); $finish;
        end
        if (OUTSTANDING_AMT < 1) begin
            $display("\%m: dsp_B_channel: OUTSTANDING_AMT must be >= 1"); $finish;
        end
    end
`endif

    genvar slv_idx;
    integer i;
    reg [OUTST_CTN_W-1:0] outstanding_count;
    wire master_output_handshake;

    wire b_order_full;
    wire outst_full       = (outstanding_count >= OUTSTANDING_AMT) || b_order_full;
    assign dsp_AW_stall_o = outst_full;

    wire aw_qual_inc = (AW_EVENT_PER_SUB_BURST != 0) ? (dsp_AW_shift_en_i && !dsp_AW_crossing_flag_i)
                                                     : dsp_AW_shift_en_i;

    wire aw_accepted = aw_qual_inc && !dsp_AW_stall_o;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            outstanding_count <= {OUTST_CTN_W{1'b0}};
        end
        else begin
            case ({aw_accepted, master_output_handshake})
                2'b10: begin
                    if (outstanding_count < OUTSTANDING_AMT)
                        outstanding_count <= outstanding_count + 1'b1;
                end
                2'b01: begin
                    if (outstanding_count > {OUTST_CTN_W{1'b0}})
                        outstanding_count <= outstanding_count - 1'b1;
                end
                default: begin
                    outstanding_count <= outstanding_count;
                end
            endcase
        end
    end

    assign sa_B_outst_ctn_o = outstanding_count;
    wire [SLV_ID_W-1:0] expected_slv_id;
    wire                b_order_empty;

    fifo_B #(
        .DATA_WIDTH (SLV_ID_W),
        .FIFO_DEPTH (OUTSTANDING_AMT)
    ) u_b_order_fifo (
        .clk        (ACLK_i),
        .rst_n      (ARESETn_i),
        .data_i     (dsp_AW_slv_id_i),
        .data_o     (expected_slv_id),
        .wr_valid_i (aw_accepted),
        .rd_valid_i (master_output_handshake),
        .empty_o    (b_order_empty),
        .full_o     (b_order_full),
        .wr_ready_o (),
        .rd_ready_o (),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter    ()
    );

       wire [RESP_INFO_W-1:0] resp_info       [SLV_AMT-1:0];
    wire [RESP_INFO_W-1:0] resp_info_valid [SLV_AMT-1:0];

    wire fifo_wresp_wr_en [SLV_AMT-1:0];
    wire fifo_wresp_rd_en [SLV_AMT-1:0];
    wire fifo_wresp_empty [SLV_AMT-1:0];
    wire fifo_wresp_full  [SLV_AMT-1:0];

    wire [RESP_INFO_W*SLV_AMT-1:0] resp_info_valid_flat;
    wire [SLV_AMT-1:0]             fifo_wresp_empty_flat;

    generate
        for (slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_FIFO
            assign resp_info[slv_idx] = {
                sa_BID_i[TRANS_MST_ID_W*(slv_idx+1)-1 -: TRANS_MST_ID_W],
                sa_BRESP_i[TRANS_WR_RESP_W*(slv_idx+1)-1 -: TRANS_WR_RESP_W]
            };

            assign fifo_wresp_wr_en[slv_idx] = sa_BVALID_i[slv_idx] && sa_BREADY_o[slv_idx];
            assign sa_BREADY_o[slv_idx]      = !fifo_wresp_full[slv_idx];

            fifo_B #(
                .DATA_WIDTH(RESP_INFO_W),
                .FIFO_DEPTH(OUTSTANDING_AMT)
            ) fifo_WRESP_slv (
                .clk            (ACLK_i),
                .rst_n          (ARESETn_i),
                .data_i         (resp_info[slv_idx]),
                .data_o         (resp_info_valid[slv_idx]),
                .wr_valid_i     (fifo_wresp_wr_en[slv_idx]),
                .rd_valid_i     (fifo_wresp_rd_en[slv_idx]),
                .empty_o        (fifo_wresp_empty[slv_idx]),
                .full_o         (fifo_wresp_full[slv_idx]),
                .wr_ready_o     (),
                .rd_ready_o     (),
                .almost_empty_o (),
                .almost_full_o  (),
                .counter        ()
            );

            assign resp_info_valid_flat[RESP_INFO_W*(slv_idx+1)-1 -: RESP_INFO_W] = resp_info_valid[slv_idx];
            assign fifo_wresp_empty_flat[slv_idx] = fifo_wresp_empty[slv_idx];
        end
    endgenerate
    wire [SLV_ID_W-1:0] active_grant_idx = expected_slv_id;
    wire                active_valid     = !b_order_empty && !fifo_wresp_empty_flat[expected_slv_id];

    reg [RESP_INFO_W-1:0] sel_resp_info;
    always @* begin
        sel_resp_info = {RESP_INFO_W{1'b0}};
        for (i = 0; i < SLV_AMT; i = i + 1) begin
            if (active_grant_idx == i) begin
                sel_resp_info = resp_info_valid_flat[i*RESP_INFO_W +: RESP_INFO_W];
            end
        end
    end

    assign m_BVALID_o = active_valid;
    assign {m_BID_o, m_BRESP_o} = sel_resp_info;

    assign master_output_handshake = m_BVALID_o && m_BREADY_i;

    generate
        for (slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_RD_EN
            assign fifo_wresp_rd_en[slv_idx] = master_output_handshake && (active_grant_idx == slv_idx);
        end
    endgenerate

endmodule

