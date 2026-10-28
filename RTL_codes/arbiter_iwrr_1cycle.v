`timescale 1ns/1ps

module arbiter_iwrr_1cycle #(
    parameter integer P_REQUESTER_NUM   = 3,
    parameter integer P_NUM_GRANT_REQ_W = 3
) (
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire [P_REQUESTER_NUM-1:0]     req_i,
    input  wire [P_REQUESTER_NUM*32-1:0]  req_weight_i,
    input  wire [P_NUM_GRANT_REQ_W-1:0]   num_grant_req_i,
    input  wire                           grant_ready_i,
    output reg  [P_REQUESTER_NUM-1:0]     grant_valid_o
);

    localparam integer PTR_W =
        (P_REQUESTER_NUM <= 1) ? 1 : $clog2(P_REQUESTER_NUM);

    reg [PTR_W-1:0]              current_ptr_r;
    reg [PTR_W-1:0]              current_ptr_next;
    reg [P_REQUESTER_NUM*32-1:0] quota_r;
    reg [P_REQUESTER_NUM*32-1:0] quota_next;

    reg [PTR_W-1:0] last_selected_idx;
    reg             last_selected_valid;
    reg [31:0]      candidate_quota;
    reg [31:0]      selected_count;      // unsigned (was integer)

    integer offset;
    integer requester_idx;

    // zero-extended copy: unsigned 32-bit compare, no signed/unsigned mix
    wire [31:0] num_grant_ext = num_grant_req_i;

    wire any_grant = |grant_valid_o;

    always @* begin
        grant_valid_o       = {P_REQUESTER_NUM{1'b0}};
        quota_next          = quota_r;
        selected_count      = 32'd0;
        last_selected_idx   = {PTR_W{1'b0}};
        last_selected_valid = 1'b0;
        candidate_quota     = 32'd0;
        requester_idx       = 0;

        if (current_ptr_r >= P_REQUESTER_NUM)
            current_ptr_next = {PTR_W{1'b0}};
        else begin
            current_ptr_next  = current_ptr_r;
            last_selected_idx = current_ptr_r;
        end

        for (offset = 0; offset < P_REQUESTER_NUM; offset = offset + 1) begin
            if (current_ptr_r < P_REQUESTER_NUM)
                requester_idx = current_ptr_r + offset;
            else
                requester_idx = offset;

            if (requester_idx >= P_REQUESTER_NUM)
                requester_idx = requester_idx - P_REQUESTER_NUM;

            if (quota_r[requester_idx*32 +: 32] != 32'd0)
                candidate_quota = quota_r[requester_idx*32 +: 32];
            else
                candidate_quota = req_weight_i[requester_idx*32 +: 32];

            if (req_i[requester_idx] &&
                (candidate_quota != 32'd0) &&
                (selected_count < num_grant_ext)) begin

                grant_valid_o[requester_idx] = 1'b1;
                selected_count      = selected_count + 32'd1;
                last_selected_idx   = requester_idx[PTR_W-1:0];
                last_selected_valid = 1'b1;

                if (candidate_quota > 32'd1)
                    quota_next[requester_idx*32 +: 32] = candidate_quota - 32'd1;
                else
                    quota_next[requester_idx*32 +: 32] = 32'd0;
            end
        end

        if (last_selected_valid) begin
            if (quota_next[last_selected_idx*32 +: 32] != 32'd0)
                current_ptr_next = last_selected_idx;
            else if (last_selected_idx == P_REQUESTER_NUM - 1)
                current_ptr_next = {PTR_W{1'b0}};
            else
                current_ptr_next = last_selected_idx + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_ptr_r <= {PTR_W{1'b0}};
            quota_r       <= {(P_REQUESTER_NUM*32){1'b0}};
        end
        else if (grant_ready_i && any_grant) begin
            if (current_ptr_next < P_REQUESTER_NUM)
                current_ptr_r <= current_ptr_next;
            else
                current_ptr_r <= {PTR_W{1'b0}};
            quota_r <= quota_next;
        end
    end
endmodule


