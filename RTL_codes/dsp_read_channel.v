`timescale 1ns / 1ps
module dsp_read_channel
#(
    parameter SLV_AMT           = 2,
    parameter OUTSTANDING_AMT   = 8,
    parameter DATA_WIDTH        = 32,
    parameter ADDR_WIDTH        = 32,
    parameter TRANS_MST_ID_W    = 5,
    parameter TRANS_BURST_W     = 2,
    parameter TRANS_DATA_LEN_W  = 3,
    parameter TRANS_DATA_SIZE_W = 3,
    parameter TRANS_WR_RESP_W   = 2,
    parameter SLV_ID_W          = (SLV_AMT <= 1) ? 1 : $clog2(SLV_AMT),
    parameter SLV_ID_MSB_IDX    = 30,
    parameter SLV_ID_LSB_IDX    = 30,
    parameter DSP_RDATA_DEPTH   = 16,
    parameter DECERR_EN         = 1
)
(
    input  wire                                                 ACLK_i,
    input  wire                                                 ARESETn_i,

    input  wire [TRANS_MST_ID_W-1:0]                            m_ARID_i,
    input  wire [ADDR_WIDTH-1:0]                                m_ARADDR_i,
    input  wire [TRANS_BURST_W-1:0]                             m_ARBURST_i,
    input  wire [TRANS_DATA_LEN_W-1:0]                          m_ARLEN_i,
    input  wire [TRANS_DATA_SIZE_W-1:0]                         m_ARSIZE_i,
    input  wire                                                 m_ARVALID_i,
    output wire                                                 m_ARREADY_o,

    input  wire                                                 m_RREADY_i,
    output wire [TRANS_MST_ID_W-1:0]                            m_RID_o,
    output wire [DATA_WIDTH-1:0]                                m_RDATA_o,
    output wire [TRANS_WR_RESP_W-1:0]                           m_RRESP_o,
    output wire                                                 m_RLAST_o,
    output wire                                                 m_RVALID_o,

    input  wire [SLV_AMT-1:0]                                   sa_ARREADY_i,
    output wire [TRANS_MST_ID_W*SLV_AMT-1:0]                    sa_ARID_o,
    output wire [ADDR_WIDTH*SLV_AMT-1:0]                        sa_ARADDR_o,
    output wire [TRANS_BURST_W*SLV_AMT-1:0]                     sa_ARBURST_o,
    output wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]                  sa_ARLEN_o,
    output wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0]                 sa_ARSIZE_o,
    output wire [SLV_AMT-1:0]                                   sa_ARVALID_o,
    output wire [SLV_AMT-1:0]                                   sa_AR_outst_full_o,

    input  wire [TRANS_MST_ID_W*SLV_AMT-1:0]                    sa_RID_i,
    input  wire [DATA_WIDTH*SLV_AMT-1:0]                        sa_RDATA_i,
    input  wire [TRANS_WR_RESP_W*SLV_AMT-1:0]                   sa_RRESP_i,
    input  wire [SLV_AMT-1:0]                                   sa_RLAST_i,
    input  wire [SLV_AMT-1:0]                                   sa_RVALID_i,
    output wire [SLV_AMT-1:0]                                   sa_RREADY_o
);

    localparam OUTST_CTN_W = $clog2(OUTSTANDING_AMT) + 1;
    genvar slv_idx;

    wire [SLV_ID_W-1:0]         AR_R_slv_id;
    wire                        AR_R_disable;
    wire [OUTST_CTN_W-1:0]      Ax_outst_ctn;

    wire                        dsp_decerr_valid;
    wire [TRANS_MST_ID_W-1:0]   dsp_decerr_id;
    wire [TRANS_DATA_LEN_W-1:0] dsp_decerr_len;

    wire                        raw_m_ARREADY;
    wire                        dsp_AR_stall;

    assign m_ARREADY_o = raw_m_ARREADY && !dsp_AR_stall;

    wire [SLV_ID_W-1:0] ar_target_slv_id;
    assign ar_target_slv_id = m_ARADDR_i[SLV_ID_MSB_IDX:SLV_ID_LSB_IDX];

    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_LOGIC
            assign sa_AR_outst_full_o[slv_idx] = (Ax_outst_ctn >= OUTSTANDING_AMT) || dsp_AR_stall;
        end
    endgenerate

    dsp_Ax_channel #(
        .SLV_AMT            (SLV_AMT),
        .OUTSTANDING_AMT    (OUTSTANDING_AMT),
        .OUTST_CTN_W        (OUTST_CTN_W),
        .DATA_WIDTH         (DATA_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .TRANS_MST_ID_W     (TRANS_MST_ID_W),
        .TRANS_BURST_W      (TRANS_BURST_W),
        .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
        .TRANS_DATA_SIZE_W  (TRANS_DATA_SIZE_W),
        .SLV_ID_W           (SLV_ID_W),
        .SLV_ID_MSB_IDX     (SLV_ID_MSB_IDX),
        .SLV_ID_LSB_IDX     (SLV_ID_LSB_IDX)
    ) AR_channel (
        .ACLK_i             (ACLK_i),
        .ARESETn_i          (ARESETn_i),
        .m_AxID_i           (m_ARID_i),
        .m_AxADDR_i         (m_ARADDR_i),
        .m_AxBURST_i        (m_ARBURST_i),
        .m_AxLEN_i          (m_ARLEN_i),
        .m_AxSIZE_i         (m_ARSIZE_i),
        .m_AxVALID_i        (m_ARVALID_i && !dsp_AR_stall),
        .m_xVALID_i         (m_RVALID_o),
        .m_xREADY_i         (m_RREADY_i),
        .sa_AxREADY_i       (sa_ARREADY_i),
        .m_AxREADY_o        (raw_m_ARREADY),
        .sa_AxID_o          (sa_ARID_o),
        .sa_AxADDR_o        (sa_ARADDR_o),
        .sa_AxBURST_o       (sa_ARBURST_o),
        .sa_AxLEN_o         (sa_ARLEN_o),
        .sa_AxSIZE_o        (sa_ARSIZE_o),
        .sa_AxVALID_o       (sa_ARVALID_o),
        .sa_Ax_outst_ctn_o  (Ax_outst_ctn),
        .dsp_xDATA_slv_id_o (AR_R_slv_id),
        .dsp_xDATA_disable_o(AR_R_disable),
        .dsp_WRESP_slv_id_o (),
        .dsp_WRESP_shift_en_o(),
        .dsp_decerr_valid_o (dsp_decerr_valid),
        .dsp_decerr_id_o    (dsp_decerr_id),
        .dsp_decerr_len_o   (dsp_decerr_len),
        .dsp_decerr_ready_i (!dsp_AR_stall)
    );

    wire ar_handshake_done = m_ARVALID_i && m_ARREADY_o;

    dsp_R_channel #(
        .SLV_AMT            (SLV_AMT),
        .DATA_WIDTH         (DATA_WIDTH),
        .TRANS_MST_ID_W     (TRANS_MST_ID_W),
        .TRANS_RRESP_W      (TRANS_WR_RESP_W),
        .TRANS_WR_RESP_W    (TRANS_WR_RESP_W),
        .TRANS_DATA_LEN_W   (TRANS_DATA_LEN_W),
        .SLV_ID_W           (SLV_ID_W),
        .DSP_RDATA_DEPTH    (DSP_RDATA_DEPTH),
        .OUTSTANDING_AMT    (OUTSTANDING_AMT),
        .USE_AR_TRACK_FIFO  (1),
        .DECERR_EN          (DECERR_EN)
    ) R_channel (
        .ACLK_i             (ACLK_i),
        .ARESETn_i          (ARESETn_i),
        .m_RREADY_i         (m_RREADY_i),
        .sa_RID_i           (sa_RID_i),
        .sa_RDATA_i         (sa_RDATA_i),
        .sa_RRESP_i         (sa_RRESP_i),
        .sa_RLAST_i         (sa_RLAST_i),
        .sa_RVALID_i        (sa_RVALID_i),
        .dsp_AR_slv_id_i    (ar_target_slv_id),
        .dsp_AR_shift_en_i  (ar_handshake_done),
        .dsp_AR_disable_i   (1'b0),
        .dsp_AR_decerr_i    (dsp_decerr_valid),
        .dsp_AR_id_i        (dsp_decerr_id),
        .dsp_AR_len_i       (dsp_decerr_len),
        .dsp_AR_stall_o     (dsp_AR_stall),
        .m_RID_o            (m_RID_o),
        .m_RDATA_o          (m_RDATA_o),
        .m_RRESP_o          (m_RRESP_o),
        .m_RLAST_o          (m_RLAST_o),
        .m_RVALID_o         (m_RVALID_o),
        .sa_RREADY_o        (sa_RREADY_o),
        .err_clear_i        (1'b0),
        .dsp_RVALID_q1_o    (),
        .dsp_RREADY_q1_o    (),
        .dsp_RLAST_q1_o     (),
        .m_RLAST_handshake_o(),
        .err_invalid_slv_id_pulse_o (),
        .err_invalid_slv_id_sticky_o(),
        .err_ar_overflow_sticky_o   ()
    );

endmodule
