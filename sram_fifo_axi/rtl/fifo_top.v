`timescale 1ns/1ps

module fifo_top #(
    parameter DATA_WIDTH      = 64,
    parameter FIFO_DEPTH      = 512,
    parameter FIFO_ADDR_WIDTH = 9,

    parameter AXI_DATA_WIDTH  = 512,
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_ID_WIDTH    = 4
)(
    input clk,
    input rst,

    // ============================================================
    // TRANSITION INPUT
    // ============================================================

    input                       trans_valid,
    output                      trans_ready,
    input  [DATA_WIDTH-1:0]     trans_data,
    input  [6:0]                trans_width,

    // ============================================================
    // FIFO STATUS
    // ============================================================

    output                      fifo_full,
    output                      fifo_empty,

    // ============================================================
    // READ REQUEST INTERFACE
    // ============================================================

    input                       rd_req,
    output                      rd_ready,

    input  [AXI_ADDR_WIDTH-1:0] rd_addr,

    output [AXI_DATA_WIDTH-1:0] rd_data,
    output                      rd_valid,
    input                       rd_data_ready
);


    // ============================================================
    // TRANSITION PACKER -> FIFO
    // ============================================================

    wire                    fifo_wr_en;
    wire [DATA_WIDTH-1:0]   fifo_wr_data;


    // ============================================================
    // FIFO -> AXI WRAPPER
    // ============================================================

    wire                    fifo_rd_en;
    wire [DATA_WIDTH-1:0]   fifo_rd_data;


    // ============================================================
    // AXI WRITE ADDRESS CHANNEL
    // ============================================================

    wire [AXI_ID_WIDTH-1:0]     s_axi_awid;
    wire [AXI_ADDR_WIDTH-1:0]   s_axi_awaddr;
    wire [7:0]                  s_axi_awlen;
    wire [2:0]                  s_axi_awsize;
    wire [1:0]                  s_axi_awburst;
    wire                        s_axi_awlock;
    wire [3:0]                  s_axi_awcache;
    wire [2:0]                  s_axi_awprot;
    wire                        s_axi_awvalid;
    wire                        s_axi_awready;


    // ============================================================
    // AXI WRITE DATA CHANNEL
    // ============================================================

    wire [AXI_DATA_WIDTH-1:0]       s_axi_wdata;
    wire [(AXI_DATA_WIDTH/8)-1:0]   s_axi_wstrb;
    wire                            s_axi_wlast;
    wire                            s_axi_wvalid;
    wire                            s_axi_wready;


    // ============================================================
    // AXI WRITE RESPONSE CHANNEL
    // ============================================================

    wire [AXI_ID_WIDTH-1:0]     s_axi_bid;
    wire [1:0]                  s_axi_bresp;
    wire                        s_axi_bvalid;
    wire                        s_axi_bready;


    // ============================================================
    // AXI READ ADDRESS CHANNEL
    // ============================================================

    wire [AXI_ID_WIDTH-1:0]     s_axi_arid;
    wire [AXI_ADDR_WIDTH-1:0]   s_axi_araddr;
    wire [7:0]                  s_axi_arlen;
    wire [2:0]                  s_axi_arsize;
    wire [1:0]                  s_axi_arburst;
    wire                        s_axi_arlock;
    wire [3:0]                  s_axi_arcache;
    wire [2:0]                  s_axi_arprot;
    wire                        s_axi_arvalid;
    wire                        s_axi_arready;


    // ============================================================
    // AXI READ DATA CHANNEL
    // ============================================================

    wire [AXI_ID_WIDTH-1:0]     s_axi_rid;
    wire [AXI_DATA_WIDTH-1:0]   s_axi_rdata;
    wire [1:0]                  s_axi_rresp;
    wire                        s_axi_rlast;
    wire                        s_axi_rvalid;
    wire                        s_axi_rready;


    // ============================================================
    // 1. TRANSITION PACKER
    // ============================================================

    transition_packer #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_transition_packer (

        .clk(clk),
        .rst(rst),

        .trans_valid(trans_valid),
        .trans_ready(trans_ready),

        .trans_data(trans_data),
        .trans_width(trans_width),

        .fifo_wr_en(fifo_wr_en),
        .fifo_wr_data(fifo_wr_data),

        .fifo_full(fifo_full)
    );


    // ============================================================
    // 2. FIFO BUFFER
    // ============================================================

    fifo_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) u_fifo_buffer (

        .clk(clk),
        .rst(rst),

        .wr_en(fifo_wr_en),
        .wr_data(fifo_wr_data),

        .rd_en(fifo_rd_en),
        .rd_data(fifo_rd_data),

        .full(fifo_full),
        .empty(fifo_empty)
    );


    // ============================================================
    // 3. FIFO AXI WRAPPER
    // ============================================================

    fifo_axi_wrapper #(
        .FIFO_DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .ID_WIDTH(AXI_ID_WIDTH)
    ) u_fifo_axi_wrapper (

        .clk(clk),
        .rst(rst),

        // --------------------------------------------------------
        // FIFO Interface
        // --------------------------------------------------------

        .fifo_rd_en(fifo_rd_en),
        .fifo_rd_data(fifo_rd_data),
	.fifo_empty(fifo_empty),
        // --------------------------------------------------------
        // User Read Interface
        // --------------------------------------------------------

        .rd_req(rd_req),
        .rd_ready(rd_ready),

        .rd_addr(rd_addr),

        .rd_data(rd_data),
        .rd_valid(rd_valid),
        .rd_data_ready(rd_data_ready),

        // --------------------------------------------------------
        // AXI Write Address
        // --------------------------------------------------------

        .s_axi_awid(s_axi_awid),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awlen(s_axi_awlen),
        .s_axi_awsize(s_axi_awsize),
        .s_axi_awburst(s_axi_awburst),
        .s_axi_awlock(s_axi_awlock),
        .s_axi_awcache(s_axi_awcache),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        // --------------------------------------------------------
        // AXI Write Data
        // --------------------------------------------------------

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        // --------------------------------------------------------
        // AXI Write Response
        // --------------------------------------------------------

        .s_axi_bid(s_axi_bid),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        // --------------------------------------------------------
        // AXI Read Address
        // --------------------------------------------------------

        .s_axi_arid(s_axi_arid),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize),
        .s_axi_arburst(s_axi_arburst),
        .s_axi_arlock(s_axi_arlock),
        .s_axi_arcache(s_axi_arcache),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        // --------------------------------------------------------
        // AXI Read Data
        // --------------------------------------------------------

        .s_axi_rid(s_axi_rid),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rlast(s_axi_rlast),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready)
    );


    // ============================================================
    // 4. AXI RAM
    // ============================================================

    axi_ram #(
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .ID_WIDTH(AXI_ID_WIDTH)
    ) u_axi_ram (

        .clk(clk),
        .rst(rst),

        // --------------------------------------------------------
        // AXI Write Address
        // --------------------------------------------------------

        .s_axi_awid(s_axi_awid),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awlen(s_axi_awlen),
        .s_axi_awsize(s_axi_awsize),
        .s_axi_awburst(s_axi_awburst),
        .s_axi_awlock(s_axi_awlock),
        .s_axi_awcache(s_axi_awcache),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        // --------------------------------------------------------
        // AXI Write Data
        // --------------------------------------------------------

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        // --------------------------------------------------------
        // AXI Write Response
        // --------------------------------------------------------

        .s_axi_bid(s_axi_bid),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        // --------------------------------------------------------
        // AXI Read Address
        // --------------------------------------------------------

        .s_axi_arid(s_axi_arid),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize),
        .s_axi_arburst(s_axi_arburst),
        .s_axi_arlock(s_axi_arlock),
        .s_axi_arcache(s_axi_arcache),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        // --------------------------------------------------------
        // AXI Read Data
        // --------------------------------------------------------

        .s_axi_rid(s_axi_rid),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rlast(s_axi_rlast),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready)
    );

endmodule
