// ============================================================================
//  wb_if.sv  —  UberDDR3 native pipelined Wishbone interface (+ calib status)
// ----------------------------------------------------------------------------
//  One WB transfer = one 128-bit DDR3 burst word.  Address is the word address
//  {row,bank,col}.  calib_complete is observed by the env so traffic only
//  starts after calibration.
// ============================================================================
interface wb_if #(
  parameter int ADDR_BITS = 24,
  parameter int DATA_BITS = 128,
  parameter int SEL_BITS  = 16,
  parameter int AUX_WIDTH = 16
) (input logic clk, input logic rst_n);

  // request (master -> controller)
  logic                 wb_cyc;
  logic                 wb_stb;
  logic                 wb_we;
  logic [ADDR_BITS-1:0] wb_addr;
  logic [DATA_BITS-1:0] wb_data;     // write data
  logic [SEL_BITS-1:0]  wb_sel;
  logic [AUX_WIDTH-1:0] aux;
  // response (controller -> master)
  logic                 wb_stall;
  logic                 wb_ack;
  logic                 wb_err;
  logic [DATA_BITS-1:0]  wb_rdata;    // read data (o_wb_data)
  logic [AUX_WIDTH-1:0] o_aux;
  // status
  logic                 calib_complete;

  // master modport (drives requests, observes responses)
  modport master (
    input  clk, rst_n, wb_stall, wb_ack, wb_err, wb_rdata, o_aux, calib_complete,
    output wb_cyc, wb_stb, wb_we, wb_addr, wb_data, wb_sel, aux
  );
  // passive monitor
  modport mon (
    input  clk, rst_n, wb_cyc, wb_stb, wb_we, wb_addr, wb_data, wb_sel, aux,
           wb_stall, wb_ack, wb_err, wb_rdata, o_aux, calib_complete
  );

endinterface : wb_if
