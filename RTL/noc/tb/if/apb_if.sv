// ============================================================================
//  apb_if.sv  —  APB4 interface
// ----------------------------------------------------------------------------
//  Used by the UVM APB slave (reactive responder) agent and bound to the DUT's
//  flattened APB master ports in tb_top.  APB4 includes PSTRB and PSLVERR.
// ============================================================================
interface apb_if #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int STRB_WIDTH = DATA_WIDTH/8
) (
  input logic pclk,
  input logic presetn
);

  logic [ADDR_WIDTH-1:0] paddr;
  logic [2:0]            pprot;
  logic                  psel;
  logic                  penable;
  logic                  pwrite;
  logic [DATA_WIDTH-1:0] pwdata;
  logic [STRB_WIDTH-1:0] pstrb;
  logic [DATA_WIDTH-1:0] prdata;
  logic                  pready;
  logic                  pslverr;

  // Requester (the bridge inside the NoC drives this)
  modport requester (
    input  pclk, presetn,
    output paddr, pprot, psel, penable, pwrite, pwdata, pstrb,
    input  prdata, pready, pslverr
  );

  // Completer (the reactive APB slave agent drives the response side)
  modport completer (
    input  pclk, presetn,
    input  paddr, pprot, psel, penable, pwrite, pwdata, pstrb,
    output prdata, pready, pslverr
  );

  // ==========================================================================
  //  APB4 protocol assertions (embedded)
  // ==========================================================================
  // synopsys translate_off
  ap_setup_to_access : assert property (@(posedge pclk) disable iff(!presetn)
    (psel && !penable) |=> (psel && penable));
  ap_access_stable   : assert property (@(posedge pclk) disable iff(!presetn)
    (psel && penable && !pready) |=> $stable(paddr) && $stable(pwrite) &&
                                     $stable(pwdata) && $stable(pstrb));
  ap_penable_with_psel: assert property (@(posedge pclk) disable iff(!presetn) penable |-> psel);
  ap_enable_drops    : assert property (@(posedge pclk) disable iff(!presetn)
    (psel && penable && pready) |=> !penable);
  // synopsys translate_on

endinterface : apb_if
