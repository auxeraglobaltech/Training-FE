// ============================================================================
//  noc_bind.sv  —  bind the arbitration checker into every arbiter
// ----------------------------------------------------------------------------
//  AXI/APB protocol assertions live inside axi_if/apb_if (interfaces cannot
//  contain bound module instances).  Module->module bind is allowed, so the
//  arbiter checker is bound here to every noc_arbiter instance (the write/read
//  arbiters inside the slave ports and bridges).  .* matches by signal name.
// ============================================================================
bind noc_arbiter arb_sva u_arb_sva (.*);
