`include "uvm_macros.svh"
import uvm_pkg::*;

module axi_assertions #(parameter ADDR_WIDTH = 32,
                        parameter DATA_WIDTH = 32,
                        parameter ID_WIDTH   = 4)
(
  input logic                  axi_aclk,
  input logic                  axi_areset_n,

  // Write address channel
  input logic                  axi_awvalid,
  input logic                  axi_awready,
  input logic [ID_WIDTH-1:0]   axi_awid,
  input logic [ADDR_WIDTH-1:0] axi_awaddr,
  input logic [7:0]            axi_awlen,
  input logic [2:0]            axi_awsize,
  input logic [1:0]            axi_awburst,

  // Write data channel
  input logic                  axi_wvalid,
  input logic                  axi_wready,
  input logic [DATA_WIDTH-1:0] axi_wdata,
  input logic [DATA_WIDTH/8-1:0] axi_wstrb,
  input logic                  axi_wlast,

  // Write response channel
  input logic                  axi_bvalid,
  input logic                  axi_bready,
  input logic [ID_WIDTH-1:0]   axi_bid,
  input logic [1:0]            axi_bresp,

  // Read address channel
  input logic                  axi_arvalid,
  input logic                  axi_arready,
  input logic [ID_WIDTH-1:0]   axi_arid,
  input logic [ADDR_WIDTH-1:0] axi_araddr,
  input logic [7:0]            axi_arlen,
  input logic [2:0]            axi_arsize,
  input logic [1:0]            axi_arburst,

  // Read data channel
  input logic                  axi_rvalid,
  input logic                  axi_rready,
  input logic [ID_WIDTH-1:0]   axi_rid,
  input logic [DATA_WIDTH-1:0] axi_rdata,
  input logic [1:0]            axi_rresp,
  input logic                  axi_rlast
);
/* default clocking cb @(posedge axi_aclk);
  endclocking
 default disable iff (!axi_areset_n);*/

 //AW channel assertions

  property p_aw_payload_stable;
   @(posedge axi_aclk)
  disable iff (!axi_areset_n)

    axi_awvalid && !axi_awready
    |=> $stable({
        
          axi_awid,
          axi_awaddr,
          axi_awlen,
          axi_awburst
        });
  endproperty
   assert property (p_aw_payload_stable)
    `uvm_info("ASSERT",$sformatf("%0t:p_payload stable_hold",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "AW payload changed while stalled")
  property p_awburst_legal;
   @(posedge axi_aclk)
  disable iff (!axi_areset_n)
    axi_awvalid |-> axi_awburst inside {2'b00, 2'b01, 2'b10};
  endproperty

  assert property (p_awburst_legal)
   `uvm_info("ASSERT",$sformatf("%0t:p_awburst_legal",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "Illelegal AWBURST value")
      property p_awaddr_aligned;
    @(posedge axi_aclk)
  disable iff (!axi_areset_n)
    axi_awvalid
    |=> ((axi_awaddr % (4)) == 0);
  endproperty
  assert property (p_awaddr_aligned)
   `uvm_info("ASSERT",$sformatf("%0t:p_awaddr_aligned",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "Address not aligned to awsize")

        //W channel assertions
property p_w_payload_stable;
  @(posedge axi_aclk)
  disable iff (!axi_areset_n)
    axi_wvalid && !axi_wready
    |=> $stable({
          axi_wdata,
          axi_wstrb,
          axi_wlast
        });
  endproperty
        assert property (p_w_payload_stable)
 `uvm_info("ASSERT",$sformatf("%0t:p_w_payload stable",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "W Payload changed")
    
//B channel assertions
property p_b_payload_stable;
 @(posedge axi_aclk)
  disable iff (!axi_areset_n)
    axi_bvalid && !axi_bready
    |=> $stable({
          axi_bid,
          axi_bresp
        });
  endproperty
   assert property (p_b_payload_stable)
   `uvm_info("ASSERT",$sformatf("%0t:p_b_payload stable",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "B Payload changed")
         property p_bresp_legal;
          @(posedge axi_aclk)
  disable iff (!axi_areset_n)
    axi_bvalid |-> axi_bresp inside {
      2'b00,
      2'b01,
      2'b10,
      2'b11
    };
  endproperty
assert property (p_bresp_legal)
    `uvm_info("ASSERT",$sformatf("%0t:p_bresp_legal",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "Ilegal Bresponse")

        //AR channel assertions
        property p_ar_payload_stable;
         @(posedge axi_aclk)
  disable iff (!axi_areset_n)
    axi_arvalid && !axi_arready
    |=> $stable({
          axi_arid,
          axi_araddr,
          axi_arlen,
          axi_arsize,
          axi_arburst
        });
  endproperty
     assert property (p_ar_payload_stable)
      `uvm_info("ASSERT",$sformatf("%0t ar_payload stable_hold",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "AR payload changed while stalled")

  property p_arburst_legal;
  @(posedge axi_aclk)
  disable iff (!axi_areset_n)
    axi_arvalid |-> axi_arburst inside {2'b00, 2'b01, 2'b10};
  endproperty
   assert property (p_arburst_legal)
     `uvm_info("ASSERT",$sformatf("%0t:p_arburst_legal",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "Illelegal ARBURST value")

        property p_araddr_aligned;
     @(posedge axi_aclk)
  disable iff (!axi_areset_n)

    axi_arvalid
    |-> ((axi_araddr % (1 << axi_arsize)) == 0);
  endproperty

  assert property (p_araddr_aligned)

   `uvm_info("ASSERT",$sformatf("%0t:p_araddr_aligned",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "Address not aligned to arsize")

        property p_r_payload_stable;
     @(posedge axi_aclk)
  disable iff (!axi_areset_n)
    axi_rvalid && !axi_rready
    |=> $stable({
          axi_rid,
          axi_rdata,
          axi_rresp,
          axi_rlast
        });
  endproperty
assert property (p_r_payload_stable)
 `uvm_info("ASSERT",$sformatf("%0t:p_r_payload stable",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "R Payload changed")


property p_rresp_legal;
@(posedge axi_aclk)
  disable iff (!axi_areset_n)


    axi_rvalid |-> axi_rresp inside {
      2'b00,
      2'b01,
      2'b10,
      2'b11
    };
  endproperty

  a_rresp_legal:
    assert property (p_rresp_legal)
    `uvm_info("ASSERT",$sformatf("%0t:p_rresp_legal",$time),UVM_MEDIUM)
    else 
        `uvm_error("ASSERT", "Ilegal Rresponse")


endmodule





   

