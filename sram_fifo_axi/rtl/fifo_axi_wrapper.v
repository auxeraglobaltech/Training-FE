`timescale 1ns/1ps

module fifo_axi_wrapper #(
    parameter FIFO_DATA_WIDTH = 64,
    parameter FIFO_DEPTH      = 512,
    parameter FIFO_ADDR_WIDTH = 9,

    parameter AXI_DATA_WIDTH  = 512,
    parameter AXI_ADDR_WIDTH  = 32,
    parameter ID_WIDTH        = 4
)(
    input                           clk,
    input                           rst,

    // ============================================================
    // FIFO INTERFACE
    // ============================================================

    output reg                      fifo_rd_en,
    input  [FIFO_DATA_WIDTH-1:0]    fifo_rd_data,
    input                           fifo_empty,


    // ============================================================
    // USER READ INTERFACE
    // ============================================================

    input                           rd_req,
    output reg                      rd_ready,

    input  [AXI_ADDR_WIDTH-1:0]     rd_addr,

    output reg [AXI_DATA_WIDTH-1:0] rd_data,
    output reg                      rd_valid,

    input                           rd_data_ready,


    // ============================================================
    // AXI WRITE ADDRESS CHANNEL
    // ============================================================

    output reg [ID_WIDTH-1:0]       s_axi_awid,
    output reg [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    output reg [7:0]                s_axi_awlen,
    output reg [2:0]                s_axi_awsize,
    output reg [1:0]                s_axi_awburst,
    output reg                      s_axi_awlock,
    output reg [3:0]                s_axi_awcache,
    output reg [2:0]                s_axi_awprot,
    output reg                      s_axi_awvalid,

    input                           s_axi_awready,


    // ============================================================
    // AXI WRITE DATA CHANNEL
    // ============================================================

    output reg [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    output reg [(AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    output reg                      s_axi_wlast,
    output reg                      s_axi_wvalid,

    input                           s_axi_wready,


    // ============================================================
    // AXI WRITE RESPONSE CHANNEL
    // ============================================================

    input  [ID_WIDTH-1:0]           s_axi_bid,
    input  [1:0]                    s_axi_bresp,
    input                           s_axi_bvalid,

    output reg                      s_axi_bready,


    // ============================================================
    // AXI READ ADDRESS CHANNEL
    // ============================================================

    output reg [ID_WIDTH-1:0]       s_axi_arid,
    output reg [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    output reg [7:0]                s_axi_arlen,
    output reg [2:0]                s_axi_arsize,
    output reg [1:0]                s_axi_arburst,
    output reg                      s_axi_arlock,
    output reg [3:0]                s_axi_arcache,
    output reg [2:0]                s_axi_arprot,
    output reg                      s_axi_arvalid,

    input                           s_axi_arready,


    // ============================================================
    // AXI READ DATA CHANNEL
    // ============================================================

    input  [ID_WIDTH-1:0]           s_axi_rid,
    input  [AXI_DATA_WIDTH-1:0]     s_axi_rdata,
    input  [1:0]                    s_axi_rresp,
    input                           s_axi_rlast,
    input                           s_axi_rvalid,

    output reg                      s_axi_rready
);


    // ============================================================
    // LOCAL PARAMETERS
    // ============================================================

    localparam FIFO_WORDS_PER_AXI =
        AXI_DATA_WIDTH / FIFO_DATA_WIDTH;


    // ============================================================
    // FSM STATES
    // ============================================================

    localparam IDLE              = 4'd0;
    localparam FIFO_READ_REQ     = 4'd1;
    localparam FIFO_READ_CAPTURE = 4'd2;
    localparam AXI_AW            = 4'd3;
    localparam AXI_W             = 4'd4;
    localparam AXI_B             = 4'd5;
    localparam AXI_AR            = 4'd6;
    localparam AXI_R             = 4'd7;

    reg [3:0] state;


    // ============================================================
    // FIFO WORD COUNTER
    // ============================================================

    reg [3:0] fifo_word_count;


    // ============================================================
    // AXI WRITE DATA BUFFER
    // ============================================================

    reg [AXI_DATA_WIDTH-1:0] axi_data_buffer;


    // ============================================================
    // AXI WRITE ADDRESS
    // ============================================================

    reg [AXI_ADDR_WIDTH-1:0] current_axi_addr;


    // ============================================================
    // MAIN FSM
    // ============================================================

    always @(posedge clk) begin

        if (rst) begin

            state <= IDLE;

            // FIFO
            fifo_rd_en <= 1'b0;
            fifo_word_count <= 4'd0;
            axi_data_buffer <= {AXI_DATA_WIDTH{1'b0}};

            current_axi_addr <= {AXI_ADDR_WIDTH{1'b0}};


            // User read interface
            rd_ready <= 1'b0;
            rd_data <= {AXI_DATA_WIDTH{1'b0}};
            rd_valid <= 1'b0;


            // AXI Write Address
            s_axi_awid <= {ID_WIDTH{1'b0}};
            s_axi_awaddr <= {AXI_ADDR_WIDTH{1'b0}};
            s_axi_awlen <= 8'd0;
            s_axi_awsize <= 3'd6;
            s_axi_awburst <= 2'b01;
            s_axi_awlock <= 1'b0;
            s_axi_awcache <= 4'd0;
            s_axi_awprot <= 3'd0;
            s_axi_awvalid <= 1'b0;


            // AXI Write Data
            s_axi_wdata <= {AXI_DATA_WIDTH{1'b0}};
            s_axi_wstrb <= {(AXI_DATA_WIDTH/8){1'b0}};
            s_axi_wlast <= 1'b0;
            s_axi_wvalid <= 1'b0;


            // AXI Write Response
            s_axi_bready <= 1'b0;


            // AXI Read Address
            s_axi_arid <= {ID_WIDTH{1'b0}};
            s_axi_araddr <= {AXI_ADDR_WIDTH{1'b0}};
            s_axi_arlen <= 8'd0;
            s_axi_arsize <= 3'd6;
            s_axi_arburst <= 2'b01;
            s_axi_arlock <= 1'b0;
            s_axi_arcache <= 4'd0;
            s_axi_arprot <= 3'd0;
            s_axi_arvalid <= 1'b0;


            // AXI Read Data
            s_axi_rready <= 1'b0;

        end

        else begin

            // Default values
            fifo_rd_en <= 1'b0;
            rd_ready <= 1'b0;


            case (state)

                // ====================================================
                // IDLE
                // ====================================================

                IDLE: begin

                    fifo_word_count <= 4'd0;

                    // Priority 1: External read request
                    if (rd_req) begin

                        state <= AXI_AR;

                    end

                    // Priority 2: Move FIFO data to AXI RAM
                    else if (!fifo_empty) begin

                        axi_data_buffer <= {AXI_DATA_WIDTH{1'b0}};

                        state <= FIFO_READ_REQ;

                    end

                end


                // ====================================================
                // FIFO READ REQUEST
                // ====================================================

                FIFO_READ_REQ: begin

                    if (!fifo_empty) begin

                        fifo_rd_en <= 1'b1;

                        state <= FIFO_READ_CAPTURE;

                    end

                    else begin

                        state <= IDLE;

                    end

                end


                // ====================================================
                // FIFO READ CAPTURE
                // ====================================================

                FIFO_READ_CAPTURE: begin

                    axi_data_buffer[
                        fifo_word_count*FIFO_DATA_WIDTH +:
                        FIFO_DATA_WIDTH
                    ] <= fifo_rd_data;


                    if (fifo_word_count ==
                        FIFO_WORDS_PER_AXI - 1) begin

                        fifo_word_count <= 4'd0;

                        state <= AXI_AW;

                    end

                    else begin

                        fifo_word_count <=
                            fifo_word_count + 1'b1;

                        state <= FIFO_READ_REQ;

                    end

                end


                // ====================================================
                // AXI WRITE ADDRESS
                // ====================================================

                AXI_AW: begin

                    s_axi_awid <= {ID_WIDTH{1'b0}};
                    s_axi_awaddr <= current_axi_addr;
                    s_axi_awlen <= 8'd0;
                    s_axi_awsize <= 3'd6;
                    s_axi_awburst <= 2'b01;
                    s_axi_awlock <= 1'b0;
                    s_axi_awcache <= 4'd0;
                    s_axi_awprot <= 3'd0;

                    s_axi_awvalid <= 1'b1;

                    if (s_axi_awready) begin

                        s_axi_awvalid <= 1'b0;

                        state <= AXI_W;

                    end

                end


                // ====================================================
                // AXI WRITE DATA
                // ====================================================

                AXI_W: begin

                    s_axi_wdata <= axi_data_buffer;
                    s_axi_wstrb <= {(AXI_DATA_WIDTH/8){1'b1}};
                    s_axi_wlast <= 1'b1;
                    s_axi_wvalid <= 1'b1;

                    if (s_axi_wready) begin

                        s_axi_wvalid <= 1'b0;
                        s_axi_wlast <= 1'b0;

                        state <= AXI_B;

                    end

                end


                // ====================================================
                // AXI WRITE RESPONSE
                // ====================================================

                AXI_B: begin

                    s_axi_bready <= 1'b1;

                    if (s_axi_bvalid) begin

                        s_axi_bready <= 1'b0;

                        current_axi_addr <=
                            current_axi_addr +
                            (AXI_DATA_WIDTH / 8);

                        state <= IDLE;

                    end

                end


                // ====================================================
                // AXI READ ADDRESS
                // ====================================================

                AXI_AR: begin

                    s_axi_arid <= {ID_WIDTH{1'b0}};
                    s_axi_araddr <= rd_addr;
                    s_axi_arlen <= 8'd0;
                    s_axi_arsize <= 3'd6;
                    s_axi_arburst <= 2'b01;
                    s_axi_arlock <= 1'b0;
                    s_axi_arcache <= 4'd0;
                    s_axi_arprot <= 3'd0;

                    s_axi_arvalid <= 1'b1;

                    if (s_axi_arready) begin

                        s_axi_arvalid <= 1'b0;

                        state <= AXI_R;

                    end

                end


                // ====================================================
                // AXI READ DATA
                // ====================================================

                AXI_R: begin

                    s_axi_rready <= 1'b1;

                    if (s_axi_rvalid) begin

                        rd_data <= s_axi_rdata;
                        rd_valid <= 1'b1;

                        s_axi_rready <= 1'b0;

                        state <= IDLE;

                    end

                end


                default: begin

                    state <= IDLE;

                end

            endcase


            // ====================================================
            // READ DATA HANDSHAKE
            // ====================================================

            if (rd_valid && rd_data_ready) begin

                rd_valid <= 1'b0;

            end

        end

    end

endmodule
