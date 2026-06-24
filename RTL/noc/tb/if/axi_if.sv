// ============================================================================
//  axi_if.sv  —  AXI4 interface (parameterised width / ID)
// ----------------------------------------------------------------------------
//  Used by the UVM master/slave agents and bound to the DUT's flattened ports
//  in tb_top.  The NoC's master-facing ports use ID_WIDTH=4; its slave-facing
//  ports (to S0/S1) use the remapped SLV_ID_WIDTH=5.
//
//  USER/REGION/QOS-extras are omitted (optional in AXI4); QOS is kept because
//  it drives arbitration priority.
// ============================================================================
interface axi_if #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int STRB_WIDTH = DATA_WIDTH/8,
  parameter int ID_WIDTH   = 4
) (
  input logic aclk,
  input logic aresetn
);

  // ---- Write address channel (AW) ----
  logic [ID_WIDTH-1:0]   awid;
  logic [ADDR_WIDTH-1:0] awaddr;
  logic [7:0]            awlen;
  logic [2:0]            awsize;
  logic [1:0]            awburst;
  logic                  awlock;
  logic [3:0]            awcache;
  logic [2:0]            awprot;
  logic [3:0]            awqos;
  logic                  awvalid;
  logic                  awready;

  // ---- Write data channel (W) ----
  logic [DATA_WIDTH-1:0] wdata;
  logic [STRB_WIDTH-1:0] wstrb;
  logic                  wlast;
  logic                  wvalid;
  logic                  wready;

  // ---- Write response channel (B) ----
  logic [ID_WIDTH-1:0]   bid;
  logic [1:0]            bresp;
  logic                  bvalid;
  logic                  bready;

  // ---- Read address channel (AR) ----
  logic [ID_WIDTH-1:0]   arid;
  logic [ADDR_WIDTH-1:0] araddr;
  logic [7:0]            arlen;
  logic [2:0]            arsize;
  logic [1:0]            arburst;
  logic                  arlock;
  logic [3:0]            arcache;
  logic [2:0]            arprot;
  logic [3:0]            arqos;
  logic                  arvalid;
  logic                  arready;

  // ---- Read data channel (R) ----
  logic [ID_WIDTH-1:0]   rid;
  logic [DATA_WIDTH-1:0] rdata;
  logic [1:0]            rresp;
  logic                  rlast;
  logic                  rvalid;
  logic                  rready;

  // Master modport (drives requests, receives responses)
  modport master (
    input  aclk, aresetn,
    output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awvalid,
    input  awready,
    output wdata, wstrb, wlast, wvalid,
    input  wready,
    input  bid, bresp, bvalid,
    output bready,
    output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arvalid,
    input  arready,
    input  rid, rdata, rresp, rlast, rvalid,
    output rready
  );

  // Slave modport (receives requests, drives responses)
  modport slave (
    input  aclk, aresetn,
    input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awvalid,
    output awready,
    input  wdata, wstrb, wlast, wvalid,
    output wready,
    output bid, bresp, bvalid,
    input  bready,
    input  arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arvalid,
    output arready,
    output rid, rdata, rresp, rlast, rvalid,
    input  rready
  );

  // ==========================================================================
  //  Protocol assertions (embedded — interfaces may hold concurrent assertions)
  //  VALID held until READY, and payload stable while a transfer is stalled.
  // ==========================================================================
  // synopsys translate_off
  ap_aw_hold: assert property (@(posedge aclk) disable iff(!aresetn) (awvalid && !awready) |=> awvalid);
  ap_w_hold : assert property (@(posedge aclk) disable iff(!aresetn) (wvalid  && !wready ) |=> wvalid );
  ap_b_hold : assert property (@(posedge aclk) disable iff(!aresetn) (bvalid  && !bready ) |=> bvalid );
  ap_ar_hold: assert property (@(posedge aclk) disable iff(!aresetn) (arvalid && !arready) |=> arvalid);
  ap_r_hold : assert property (@(posedge aclk) disable iff(!aresetn) (rvalid  && !rready ) |=> rvalid );

  ap_aw_stbl: assert property (@(posedge aclk) disable iff(!aresetn) (awvalid && !awready)
                 |=> $stable(awaddr) && $stable(awlen) && $stable(awsize) && $stable(awburst));
  ap_ar_stbl: assert property (@(posedge aclk) disable iff(!aresetn) (arvalid && !arready)
                 |=> $stable(araddr) && $stable(arlen) && $stable(arsize) && $stable(arburst));
  ap_w_stbl : assert property (@(posedge aclk) disable iff(!aresetn) (wvalid && !wready)
                 |=> $stable(wdata) && $stable(wstrb) && $stable(wlast));
  ap_b_stbl : assert property (@(posedge aclk) disable iff(!aresetn) (bvalid && !bready) |=> $stable(bresp));
  ap_r_stbl : assert property (@(posedge aclk) disable iff(!aresetn) (rvalid && !rready)
                 |=> $stable(rdata) && $stable(rresp) && $stable(rlast));
  // synopsys translate_on

endinterface : axi_if
