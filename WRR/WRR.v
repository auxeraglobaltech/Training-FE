`timescale 1ns/1ps

module iwrr_arbiter #(
    parameter N          = 4,
    parameter MAX_WEIGHT = 4,
    parameter PTR_WIDTH  = 2,
    parameter WT_WIDTH   = 3
)(
    input                   clk,
    input                   rst_n,

    input  [N-1:0]          req,

    input  [WT_WIDTH-1:0]   weight0,
    input  [WT_WIDTH-1:0]   weight1,
    input  [WT_WIDTH-1:0]   weight2,
    input  [WT_WIDTH-1:0]   weight3,

    output [N-1:0]          grant
);

    /*
     * State registers
     */
    reg [WT_WIDTH-1:0] round;
    reg [PTR_WIDTH-1:0] ptr;
    reg [N-1:0] served;

    /*
     * Combinational signals
     */
    wire [N-1:0] eligible;
    wire [N-1:0] grant_next;


    /*
     * ------------------------------------------------
     * Eligibility
     * ------------------------------------------------
     */
    assign eligible[0] = req[0] &&
                         !served[0] &&
                         (weight0 >= round);

    assign eligible[1] = req[1] &&
                         !served[1] &&
                         (weight1 >= round);

    assign eligible[2] = req[2] &&
                         !served[2] &&
                         (weight2 >= round);

    assign eligible[3] = req[3] &&
                         !served[3] &&
                         (weight3 >= round);


    /*
     * ------------------------------------------------
     * Round-robin priority encoder
     * ------------------------------------------------
     */
    assign grant_next =
        (ptr == 2'd0) ?
            (eligible[0] ? 4'b0001 :
             eligible[1] ? 4'b0010 :
             eligible[2] ? 4'b0100 :
             eligible[3] ? 4'b1000 :
                           4'b0000) :

        (ptr == 2'd1) ?
            (eligible[1] ? 4'b0010 :
             eligible[2] ? 4'b0100 :
             eligible[3] ? 4'b1000 :
             eligible[0] ? 4'b0001 :
                           4'b0000) :

        (ptr == 2'd2) ?
            (eligible[2] ? 4'b0100 :
             eligible[3] ? 4'b1000 :
             eligible[0] ? 4'b0001 :
             eligible[1] ? 4'b0010 :
                           4'b0000) :

            (eligible[3] ? 4'b1000 :
             eligible[0] ? 4'b0001 :
             eligible[1] ? 4'b0010 :
             eligible[2] ? 4'b0100 :
                           4'b0000);


    assign grant = grant_next;


    /*
     * ------------------------------------------------
     * Sequential logic
     * ------------------------------------------------
     */
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            round  <= {{(WT_WIDTH-1){1'b0}},1'b1};
            ptr    <= {PTR_WIDTH{1'b0}};
            served <= {N{1'b0}};

        end

        else begin

            /*
             * Grant generated
             */
            if (grant_next != {N{1'b0}}) begin

                /*
                 * Mark requester as served
                 */
                served <= served | grant_next;

                /*
                 * Update pointer
                 */
                case (grant_next)

                    4'b0001: ptr <= 2'd1;
                    4'b0010: ptr <= 2'd2;
                    4'b0100: ptr <= 2'd3;
                    4'b1000: ptr <= 2'd0;

                    default: ptr <= {PTR_WIDTH{1'b0}};

                endcase

            end

            /*
             * No eligible requester.
             * Move to next IWRR round.
             */
            else begin

                served <= {N{1'b0}};
                ptr    <= {PTR_WIDTH{1'b0}};

                if (round == MAX_WEIGHT)
                    round <= {{(WT_WIDTH-1){1'b0}},1'b1};
                else
                    round <= round + {{(WT_WIDTH-1){1'b0}},1'b1};

            end

        end

    end

endmodule




