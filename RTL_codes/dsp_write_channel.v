`timescale 1ns / 1ps

module dsp_write_channel #(
    // Dispatcher configuration
    parameter SLV_AMT           = 2,
    parameter OUTSTANDING_AMT   = 8,
    // Transaction configuration
    parameter DATA_WIDTH        = 32,
    parameter ADDR_WIDTH        = 32,
    parameter TRANS_MST_ID_W    = 5,    // Bus width of master transaction ID 
    parameter TRANS_BURST_W     = 2,    // Width of xBURST 
    parameter TRANS_DATA_LEN_W  = 3,    // Bus width of xLEN
    parameter TRANS_DATA_SIZE_W = 3,    // Bus width of xSIZE
    parameter TRANS_WR_RESP_W   = 2,
    // Slave configuration
    parameter SLV_ID_W          = (SLV_AMT <= 1) ? 1 : $clog2(SLV_AMT),
    parameter SLV_ID_MSB_IDX    = 30,
    parameter SLV_ID_LSB_IDX    = 30
) (
    // Global signals
    input  wire                                                 ACLK_i,
    input  wire                                                 ARESETn_i,

    // Master Write Address Channel
    input  wire [TRANS_MST_ID_W-1:0]                            m_AWID_i,
    input  wire [ADDR_WIDTH-1:0]                                m_AWADDR_i,
    input  wire [TRANS_BURST_W-1:0]                             m_AWBURST_i,
    input  wire [TRANS_DATA_LEN_W-1:0]                          m_AWLEN_i,
    input  wire [TRANS_DATA_SIZE_W-1:0]                         m_AWSIZE_i,
    input  wire                                                 m_AWVALID_i,
    output wire                                                 m_AWREADY_o,

    // Master Write Data Channel
    input  wire [DATA_WIDTH-1:0]                                m_WDATA_i,
    input  wire                                                 m_WLAST_i,
    input  wire                                                 m_WVALID_i,
    output wire                                                 m_WREADY_o,

    // Master Write Response Channel
    input  wire                                                 m_BREADY_i,
    output wire [TRANS_MST_ID_W-1:0]                            m_BID_o,
    output wire [TRANS_WR_RESP_W-1:0]                           m_BRESP_o,
    output wire                                                 m_BVALID_o,

    // Slave Arbitration - Write Address Channel
    input  wire [SLV_AMT-1:0]                                   sa_AWREADY_i,
    output wire [TRANS_MST_ID_W*SLV_AMT-1:0]                     sa_AWID_o,
    output wire [ADDR_WIDTH*SLV_AMT-1:0]                         sa_AWADDR_o,
    output wire [TRANS_BURST_W*SLV_AMT-1:0]                      sa_AWBURST_o,
    output wire [TRANS_DATA_LEN_W*SLV_AMT-1:0]                  sa_AWLEN_o,
    output wire [TRANS_DATA_SIZE_W*SLV_AMT-1:0]                 sa_AWSIZE_o,
    output wire [SLV_AMT-1:0]                                   sa_AWVALID_o,
    output wire [SLV_AMT-1:0]                                   sa_AW_outst_full_o,

    // Slave Arbitration - Write Data Channel
    input  wire [SLV_AMT-1:0]                                   sa_WREADY_i,
    output wire [DATA_WIDTH*SLV_AMT-1:0]                        sa_WDATA_o,
    output wire [SLV_AMT-1:0]                                   sa_WLAST_o,
    output wire [SLV_AMT-1:0]                                   sa_WVALID_o,

    // Slave Arbitration - Write Response Channel
    input  wire [TRANS_MST_ID_W*SLV_AMT-1:0]                    sa_BID_i,
    input  wire [TRANS_WR_RESP_W*SLV_AMT-1:0]                   sa_BRESP_i,
    input  wire [SLV_AMT-1:0]                                   sa_BVALID_i,
    output wire [SLV_AMT-1:0]                                   sa_BREADY_o
);

    localparam OUTST_CTN_W = $clog2(OUTSTANDING_AMT) + 1;

    // Internal routing and handshake wires
    wire [SLV_ID_W-1:0]     AW_W_slv_id;
    wire                    AW_W_disable;

    wire [SLV_ID_W-1:0]     AW_B_slv_id;
    wire                    AW_B_shift_en;

    wire [OUTST_CTN_W-1:0]  AW_outst_ctn;
    wire [OUTST_CTN_W-1:0]  B_outst_ctn;

    wire                    W_AW_WVALID;
    wire                    W_AW_WREADY;

    wire                    b_channel_stall;

    // DECERR signals from AW channel
    wire                    dsp_decerr_valid;
    wire [TRANS_MST_ID_W-1:0] dsp_decerr_id;
    wire [TRANS_DATA_LEN_W-1:0] dsp_decerr_len;
    wire                    dsp_decerr_ready;

    // Backpressure to slave arbiter when combined limits are met
    genvar slv_idx;
    generate
        for(slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : SLV_LOGIC
            assign sa_AW_outst_full_o[slv_idx] = ((AW_outst_ctn + B_outst_ctn) >= OUTSTANDING_AMT) || b_channel_stall;
        end
    endgenerate

    // ------------------------------------------------------------
    // AW Channel Instance
    // ------------------------------------------------------------
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
    ) AW_channel (
        .ACLK_i             (ACLK_i),
        .ARESETn_i          (ARESETn_i),
        .m_AxID_i           (m_AWID_i),
        .m_AxADDR_i         (m_AWADDR_i),
        .m_AxBURST_i        (m_AWBURST_i),
        .m_AxLEN_i          (m_AWLEN_i),
        .m_AxSIZE_i         (m_AWSIZE_i),
        .m_AxVALID_i        (m_AWVALID_i),
        .m_xVALID_i         (W_AW_WVALID),
        .m_xREADY_i         (W_AW_WREADY),
        .sa_AxREADY_i       (sa_AWREADY_i),
        .m_AxREADY_o        (m_AWREADY_o),
        .sa_AxID_o          (sa_AWID_o),
        .sa_AxADDR_o        (sa_AWADDR_o),
        .sa_AxBURST_o       (sa_AWBURST_o),
        .sa_AxLEN_o         (sa_AWLEN_o),
        .sa_AxSIZE_o        (sa_AWSIZE_o),
        .sa_AxVALID_o       (sa_AWVALID_o),
        .sa_Ax_outst_ctn_o  (AW_outst_ctn),
        .dsp_xDATA_slv_id_o (AW_W_slv_id),
        .dsp_xDATA_disable_o(AW_W_disable),
        .dsp_WRESP_slv_id_o (AW_B_slv_id),
        .dsp_WRESP_shift_en_o(AW_B_shift_en),
        // Connect DECERR interface to prevent deadlock on unmapped write
        .dsp_decerr_valid_o (dsp_decerr_valid),
        .dsp_decerr_id_o    (dsp_decerr_id),
        .dsp_decerr_len_o   (dsp_decerr_len),
        .dsp_decerr_ready_i (dsp_decerr_ready)
    );
    wire normal_WREADY;
    dsp_W_channel #(
        .SLV_AMT            (SLV_AMT),
        .DATA_WIDTH         (DATA_WIDTH),
        .SLV_ID_W           (SLV_ID_W)
    ) W_channel (
        .ACLK_i             (ACLK_i),
        .ARESETn_i          (ARESETn_i),
        .m_WDATA_i          (m_WDATA_i),
        .m_WLAST_i          (m_WLAST_i),
        .m_WVALID_i         (m_WVALID_i),
        .m_WREADY_o         (normal_WREADY),
        .sa_WREADY_i        (sa_WREADY_i),
        .sa_WDATA_o         (sa_WDATA_o),
        .sa_WLAST_o         (sa_WLAST_o),
        .sa_WVALID_o        (sa_WVALID_o),
        .dsp_AW_slv_id_i    (AW_W_slv_id),
        .dsp_AW_disable_i   (AW_W_disable),
        .dsp_AW_WVALID_o    (W_AW_WVALID),
        .dsp_AW_WREADY_o    (W_AW_WREADY)
    );

       reg                       decerr_bvalid_r;
    reg [TRANS_MST_ID_W-1:0]  decerr_bid_r;
    reg                       decerr_w_drain;

    assign dsp_decerr_ready = !decerr_bvalid_r;

    // Drain rejected WDATA so master does not hang on data phase
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            decerr_w_drain  <= 1'b0;
            decerr_bvalid_r <= 1'b0;
            decerr_bid_r    <= {TRANS_MST_ID_W{1'b0}};
        end else begin
            if (dsp_decerr_valid && dsp_decerr_ready) begin
                decerr_w_drain  <= 1'b1;
                decerr_bvalid_r <= 1'b1;
                decerr_bid_r    <= dsp_decerr_id;
            end else begin
                if (decerr_w_drain && m_WVALID_i && m_WLAST_i && m_WREADY_o)
                    decerr_w_drain <= 1'b0;

                if (decerr_bvalid_r && m_BREADY_i)
                    decerr_bvalid_r <= 1'b0;
            end
        end
    end

    // Gated WREADY accepts normal write data OR absorbs rejected write burst
    assign m_WREADY_o = decerr_w_drain ? 1'b1 : normal_WREADY;

       wire [TRANS_MST_ID_W-1:0] norm_BID;
    wire [TRANS_WR_RESP_W-1:0]norm_BRESP;
    wire                      norm_BVALID;

    dsp_B_channel #(
        .SLV_AMT            (SLV_AMT),
        .OUTSTANDING_AMT    (OUTSTANDING_AMT),
        .OUTST_CTN_W        (OUTST_CTN_W),
        .TRANS_MST_ID_W     (TRANS_MST_ID_W),
        .TRANS_WR_RESP_W    (TRANS_WR_RESP_W),
        .SLV_ID_W           (SLV_ID_W),
        .AW_EVENT_PER_SUB_BURST (0)
    ) B_channel (
        .ACLK_i                 (ACLK_i),
        .ARESETn_i              (ARESETn_i),
        .m_BREADY_i             (decerr_bvalid_r ? 1'b0 : m_BREADY_i),
        .sa_BID_i               (sa_BID_i),
        .sa_BRESP_i             (sa_BRESP_i),
        .sa_BVALID_i            (sa_BVALID_i),
        .dsp_AW_slv_id_i        (AW_B_slv_id),
        .dsp_AW_shift_en_i      (AW_B_shift_en),
        .dsp_AW_crossing_flag_i (1'b0),
        .m_BID_o                (norm_BID),
        .m_BRESP_o              (norm_BRESP),
        .m_BVALID_o             (norm_BVALID),
        .sa_B_outst_ctn_o       (B_outst_ctn),
        .sa_BREADY_o            (sa_BREADY_o),
        .dsp_AW_stall_o         (b_channel_stall)
    );

    // MUX DECERR response vs Normal Slave response
    assign m_BVALID_o = decerr_bvalid_r ? 1'b1        : norm_BVALID;
    assign m_BID_o    = decerr_bvalid_r ? decerr_bid_r: norm_BID;
    assign m_BRESP_o  = decerr_bvalid_r ? 2'b11       : norm_BRESP; // 2'b11 = DECERR

endmodule
