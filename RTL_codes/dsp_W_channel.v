`timescale 1ns / 1ps
module dsp_W_channel #(
    parameter integer SLV_AMT    = 2,
    parameter integer DATA_WIDTH = 32,
    parameter integer SLV_ID_W   = (SLV_AMT <= 1) ? 2 : $clog2(SLV_AMT) + 1
) (
    input  wire                          ACLK_i,
    input  wire                          ARESETn_i,

    // Master write-data channel
    input  wire [DATA_WIDTH-1:0]         m_WDATA_i,
    input  wire                          m_WLAST_i,
    input  wire                          m_WVALID_i,
    output wire                          m_WREADY_o,

    // Slave write-data channels
    input  wire [SLV_AMT-1:0]            sa_WREADY_i,
    output wire [DATA_WIDTH*SLV_AMT-1:0] sa_WDATA_o,
    output wire [SLV_AMT-1:0]            sa_WLAST_o,
    output wire [SLV_AMT-1:0]            sa_WVALID_o,

    // AW dispatcher coordination
    input  wire [SLV_ID_W-1:0]           dsp_AW_slv_id_i,
    input  wire                          dsp_AW_disable_i,
    output wire                          dsp_AW_WVALID_o,
    output wire                          dsp_AW_WREADY_o
);

    localparam integer W_INFO_W = SLV_AMT + DATA_WIDTH + 1;

    genvar slv_idx;

        reg [SLV_ID_W-1:0] burst_slv_id_reg;
    reg                burst_active_reg;
    reg                pending_last_reg;

    wire [SLV_ID_W-1:0] active_slv_id =
        burst_active_reg ? burst_slv_id_reg : dsp_AW_slv_id_i;

    // Numerical check for out-of-range slave IDs
    wire slv_id_valid = (active_slv_id < SLV_AMT);

    wire active_enable =
        (burst_active_reg || !dsp_AW_disable_i) && slv_id_valid;

    // Block new burst if previous WLAST is still draining out
    wire allow_input = active_enable && (burst_active_reg || !pending_last_reg);

    wire [SLV_AMT-1:0] bwd_slv_sel;

    one_hot_decoder #(
        .SLV_AMT  (SLV_AMT),
        .SLV_ID_W (SLV_ID_W)
    ) u_one_hot_decoder (
        .dsp_AW_slv_id_i  (active_slv_id),
        .dsp_AW_disable_i (!active_enable),
        .slv_sel_o        (bwd_slv_sel)
    );

       wire [W_INFO_W-1:0] msb_bwd_data;
    wire [W_INFO_W-1:0] msb_fwd_data;

    wire msb_bwd_valid;
    wire msb_bwd_ready;

    wire msb_fwd_valid;
    wire msb_fwd_ready;

    wire [SLV_AMT-1:0]    fwd_slv_sel;
    wire [DATA_WIDTH-1:0] fwd_WDATA;
    wire                  fwd_WLAST;

    assign msb_bwd_data = {
        (allow_input ? bwd_slv_sel : {SLV_AMT{1'b0}}),
        (allow_input ? m_WDATA_i   : {DATA_WIDTH{1'b0}}),
        (allow_input ? m_WLAST_i   : 1'b0)
    };

    assign msb_bwd_valid = m_WVALID_i && allow_input;
    assign m_WREADY_o    = msb_bwd_ready && allow_input;

    wire in_handshake      = msb_bwd_valid && msb_bwd_ready;
    wire in_last_handshake = in_handshake && m_WLAST_i;
    skid_buffer_dsp_w #(
        .SBUF_TYPE  (1),
        .DATA_WIDTH (W_INFO_W)
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

    assign {
        fwd_slv_sel,
        fwd_WDATA,
        fwd_WLAST
    } = msb_fwd_data;

    wire fwd_handshake  = msb_fwd_valid && msb_fwd_ready;
    wire fwd_burst_done = fwd_handshake && fwd_WLAST;

       always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            burst_slv_id_reg <= {SLV_ID_W{1'b0}};
            burst_active_reg <= 1'b0;
            pending_last_reg <= 1'b0;
        end
        else begin
            if (in_handshake) begin
                if (m_WLAST_i) begin
                    burst_active_reg <= 1'b0;
                end
                else if (!burst_active_reg) begin
                    burst_slv_id_reg <= dsp_AW_slv_id_i;
                    burst_active_reg <= 1'b1;
                end
            end

            case ({in_last_handshake, fwd_burst_done})
                2'b10:   pending_last_reg <= 1'b1;
                2'b01:   pending_last_reg <= 1'b0;
                default: ;
            endcase
        end
    end
    assign msb_fwd_ready   = |(sa_WREADY_i & fwd_slv_sel);
    assign dsp_AW_WVALID_o = msb_fwd_valid && (|fwd_slv_sel);
    assign dsp_AW_WREADY_o = fwd_handshake;

      generate
        for (slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : GEN_SLV_LOGIC
            assign sa_WDATA_o[DATA_WIDTH*(slv_idx+1)-1 -: DATA_WIDTH] = fwd_WDATA;
            assign sa_WLAST_o[slv_idx]                                = fwd_WLAST;
            assign sa_WVALID_o[slv_idx]                               = msb_fwd_valid && fwd_slv_sel[slv_idx];
        end
    endgenerate

endmodule


