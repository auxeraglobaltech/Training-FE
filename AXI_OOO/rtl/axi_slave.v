`timescale 1ns/1ps

module axi_slave_ooo_delay #(
  parameter DATA_WIDTH    = 32,
  parameter ADDRESS_WIDTH = 32,
  parameter OUTSTANDING   = 8
)(
  input axi_aclk,
  input axi_areset_n,

  input  [ADDRESS_WIDTH-1:0] axi_awaddr,
  input                      axi_awvalid,
  output                     axi_awready,
  input  [3:0]               axi_awid,
  input  [7:0]               axi_awlen,
  input  [1:0]               axi_awburst,

  input  [DATA_WIDTH-1:0]    axi_wdata,
  input                      axi_wvalid,
  output                     axi_wready,
  input  [3:0]               axi_wid,
  input                      axi_wlast,
  input  [(DATA_WIDTH/8)-1:0] axi_wstrb,

  output [1:0]               axi_bresp,
  output                     axi_bvalid,
  input                      axi_bready,
  output [3:0]               axi_bid,

  input  [ADDRESS_WIDTH-1:0] axi_araddr,
  input                      axi_arvalid,
  output                     axi_arready,
  input  [3:0]               axi_arid,
  input  [7:0]               axi_arlen,
  input  [1:0]               axi_arburst,

  output [DATA_WIDTH-1:0]    axi_rdata,
  output                     axi_rvalid,
  input                      axi_rready,
  output [3:0]               axi_rid,
  output                     axi_rlast,
  output [1:0]               axi_rresp,

  output                     slave_wren,
  output [31:0]              slave_waddr,
  output [31:0]              slave_wdata,

  output                     slave_rden,
  output [31:0]              slave_raddr,
  input  [31:0]              slave_rdata
);

  integer i;

  function [31:0] next_addr;
    input [31:0] curr_addr;
    input [7:0]  len;
    input [1:0]  burst;

    reg [31:0] wrap_size;
    reg [31:0] wrap_base;
    reg [31:0] wrap_limit;
    reg [31:0] temp_next;

    begin
      case(burst)
        2'b00: next_addr = curr_addr;

        2'b01: next_addr = curr_addr + 4;

        2'b10: begin
          wrap_size  = (len + 1) * 4;
          wrap_base  = (curr_addr / wrap_size) * wrap_size;
          wrap_limit = wrap_base + wrap_size;
          temp_next  = curr_addr + 4;

          if(temp_next == wrap_limit)
            next_addr = wrap_base;
          else
            next_addr = temp_next;
        end

        default: next_addr = curr_addr;
      endcase
    end
  endfunction


  //---------------------------------------
  // WRITE OUTSTANDING STORAGE
  //---------------------------------------

  reg        wr_valid [0:OUTSTANDING-1];
  reg        wr_done  [0:OUTSTANDING-1];
  reg        wr_wait  [0:OUTSTANDING-1];

  reg [3:0]  wr_id    [0:OUTSTANDING-1];
  reg [31:0] wr_addr  [0:OUTSTANDING-1];
  reg [7:0]  wr_len   [0:OUTSTANDING-1];
  reg [1:0]  wr_burst [0:OUTSTANDING-1];
  reg [7:0]  wr_cnt   [0:OUTSTANDING-1];
  reg [7:0]  wr_delay [0:OUTSTANDING-1];

  reg [3:0]  b_id_reg;
  reg        bvalid_reg;
  reg [2:0] b_slot_reg;
  reg        slave_wren_reg;
  reg [31:0] slave_waddr_reg;
  reg [31:0] slave_wdata_reg;

  reg [2:0] aw_free_slot;
  reg       aw_free_found;

  always @(*) begin
    aw_free_found = 0;
    aw_free_slot  = 0;

    for(i=0; i<OUTSTANDING; i=i+1) begin
      if(!wr_valid[i] && !wr_done[i] && !wr_wait[i] && !aw_free_found) begin
        aw_free_found = 1;
        aw_free_slot  = i[2:0];
      end
    end
  end

  assign axi_awready = aw_free_found;

  reg [2:0] w_slot;
  reg       w_slot_found;

  always @(*) begin
    w_slot_found = 0;
    w_slot       = 0;

    for(i=0; i<OUTSTANDING; i=i+1) begin
      if(wr_valid[i] && (wr_id[i] == axi_wid) && !w_slot_found) begin
        w_slot_found = 1;
        w_slot       = i[2:0];
      end
    end
  end

  assign axi_wready = w_slot_found;

  reg [2:0] b_slot;
  reg       b_found;

  always @(*) begin
    b_found = 0;
    b_slot  = 0;

    for(i=0; i<OUTSTANDING; i=i+1) begin
      if(wr_done[i] && !b_found) begin
        b_found = 1;
        b_slot  = i[2:0];
      end
    end
  end

  assign axi_bvalid = bvalid_reg;
  assign axi_bid    = b_id_reg;
  assign axi_bresp  = 2'b00;

  assign slave_wren  = slave_wren_reg;
  assign slave_waddr = slave_waddr_reg;
  assign slave_wdata = slave_wdata_reg;


  always @(posedge axi_aclk or negedge axi_areset_n) begin
    if(!axi_areset_n) begin

      for(i=0; i<OUTSTANDING; i=i+1) begin
        wr_valid[i] <= 0;
        wr_done[i]  <= 0;
        wr_wait[i]  <= 0;
        wr_id[i]    <= 0;
        wr_addr[i]  <= 0;
        wr_len[i]   <= 0;
        wr_burst[i] <= 0;
        wr_cnt[i]   <= 0;
        wr_delay[i] <= 0;
      end

      b_id_reg        <= 0;
      bvalid_reg      <= 0;
      b_slot_reg      <= 3'd0;
      slave_wren_reg  <= 0;
      slave_waddr_reg <= 0;
      slave_wdata_reg <= 0;

    end
    else begin

      slave_wren_reg <= 0;

      //-------------------------------
      // Accept AW
      //-------------------------------
      if(axi_awvalid && axi_awready) begin
        wr_valid[aw_free_slot] <= 1;
        wr_done [aw_free_slot] <= 0;
        wr_wait [aw_free_slot] <= 0;
        wr_id   [aw_free_slot] <= axi_awid;
        wr_addr [aw_free_slot] <= axi_awaddr;
        wr_len  [aw_free_slot] <= axi_awlen;
        wr_burst[aw_free_slot] <= axi_awburst;
        wr_cnt  [aw_free_slot] <= 0;
        wr_delay[aw_free_slot] <= 0;
      end

      //-------------------------------
      // Accept W beats by WID
      //-------------------------------
      if(axi_wvalid && axi_wready) begin

        slave_wren_reg  <= 1;
        slave_waddr_reg <= wr_addr[w_slot];
        slave_wdata_reg <= axi_wdata;

        if((wr_cnt[w_slot] == wr_len[w_slot]) || axi_wlast) begin
          wr_valid[w_slot] <= 0;
          wr_wait [w_slot] <= 1;

          // Simulation-only random completion delay
          wr_delay[w_slot] <= $urandom_range(1,10);
        end
        else begin
          wr_cnt [w_slot] <= wr_cnt[w_slot] + 1;
          wr_addr[w_slot] <= next_addr(
                                wr_addr[w_slot],
                                wr_len[w_slot],
                                wr_burst[w_slot]);
        end
      end

      //-------------------------------
      // Write completion delay countdown
      //-------------------------------
      for(i=0; i<OUTSTANDING; i=i+1) begin
        if(wr_wait[i]) begin
          if(wr_delay[i] > 0)
            wr_delay[i] <= wr_delay[i] - 1;
          else begin
            wr_wait[i] <= 0;
            wr_done[i] <= 1;
          end
        end
      end

      //-------------------------------
      // BRESP generation
      //-------------------------------
      /*if(!bvalid_reg && b_found) begin
        bvalid_reg <= 1;
        b_id_reg   <= wr_id[b_slot];
      end
      else if(bvalid_reg && axi_bready) begin
        bvalid_reg      <= 0;
        wr_done[b_slot] <= 0;
      end*/
     if (!bvalid_reg) begin
  if (b_found) begin
    bvalid_reg <= 1'b1;
    b_id_reg   <= wr_id[b_slot];
    b_slot_reg <= b_slot;
  end
end
else if (bvalid_reg && axi_bready) begin
  bvalid_reg         <= 1'b0;
  wr_done[b_slot_reg] <= 1'b0;
end

    end
  end


  //---------------------------------------
  // READ OUTSTANDING STORAGE
  //---------------------------------------

  reg        rd_valid [0:OUTSTANDING-1];
  reg        rd_ready [0:OUTSTANDING-1];

  reg [3:0]  rd_id    [0:OUTSTANDING-1];
  reg [31:0] rd_addr  [0:OUTSTANDING-1];
  reg [7:0]  rd_len   [0:OUTSTANDING-1];
  reg [1:0]  rd_burst [0:OUTSTANDING-1];
  reg [7:0]  rd_delay [0:OUTSTANDING-1];

  reg        rd_active;
  reg [3:0]  rd_active_id;
  reg [31:0] rd_curr_addr;
  reg [7:0]  rd_active_len;
  reg [1:0]  rd_active_burst;
  reg [7:0]  rd_cnt;

  reg [2:0] ar_free_slot;
  reg       ar_free_found;

  always @(*) begin
    ar_free_found = 0;
    ar_free_slot  = 0;

    for(i=0; i<OUTSTANDING; i=i+1) begin
      if(!rd_valid[i] && !rd_ready[i] && !ar_free_found) begin
        ar_free_found = 1;
        ar_free_slot  = i[2:0];
      end
    end
  end

  assign axi_arready = ar_free_found;

  reg [2:0] rd_sel_slot;
  reg       rd_sel_found;

  always @(*) begin
    rd_sel_found = 0;
    rd_sel_slot  = 0;

    for(i=0; i<OUTSTANDING; i=i+1) begin
      if(rd_ready[i] && !rd_sel_found) begin
        rd_sel_found = 1;
        rd_sel_slot  = i[2:0];
      end
    end
  end

  assign axi_rvalid = rd_active;
  assign axi_rid    = rd_active_id;
  assign axi_rresp  = 2'b00;
  assign axi_rlast  = rd_active && (rd_cnt == rd_active_len);
  assign axi_rdata  = slave_rdata;

  assign slave_rden  = rd_active;
  assign slave_raddr = rd_curr_addr;

  always @(posedge axi_aclk or negedge axi_areset_n) begin
    if(!axi_areset_n) begin

      for(i=0; i<OUTSTANDING; i=i+1) begin
        rd_valid[i] <= 0;
        rd_ready[i] <= 0;
        rd_id[i]    <= 0;
        rd_addr[i]  <= 0;
        rd_len[i]   <= 0;
        rd_burst[i] <= 0;
        rd_delay[i] <= 0;
      end

      rd_active       <= 0;
      rd_active_id    <= 0;
      rd_curr_addr    <= 0;
      rd_active_len   <= 0;
      rd_active_burst <= 0;
      rd_cnt          <= 0;

    end
    else begin

      //-------------------------------
      // Accept AR
      //-------------------------------
      if(axi_arvalid && axi_arready) begin
        rd_valid[ar_free_slot] <= 1;
        rd_ready[ar_free_slot] <= 0;
        rd_id   [ar_free_slot] <= axi_arid;
        rd_addr [ar_free_slot] <= axi_araddr;
        rd_len  [ar_free_slot] <= axi_arlen;
        rd_burst[ar_free_slot] <= axi_arburst;

        // Simulation-only random completion latency
        rd_delay[ar_free_slot] <= $urandom_range(1,10);
      end

      //-------------------------------
      // Read completion delay countdown
      //-------------------------------
      for(i=0; i<OUTSTANDING; i=i+1) begin
        if(rd_valid[i] && !rd_ready[i]) begin
          if(rd_delay[i] > 0)
            rd_delay[i] <= rd_delay[i] - 1;
          else begin
            rd_ready[i] <= 1;
          end
        end
      end

      //-------------------------------
      // Start whichever read completes first
      //-------------------------------
      if(!rd_active && rd_sel_found) begin
        rd_active       <= 1;
        rd_active_id    <= rd_id[rd_sel_slot];
        rd_curr_addr    <= rd_addr[rd_sel_slot];
        rd_active_len   <= rd_len[rd_sel_slot];
        rd_active_burst <= rd_burst[rd_sel_slot];
        rd_cnt          <= 0;

        rd_valid[rd_sel_slot] <= 0;
        rd_ready[rd_sel_slot] <= 0;
      end

      //-------------------------------
      // Send R burst
      //-------------------------------
      else if(rd_active && axi_rready) begin
        if(rd_cnt == rd_active_len) begin
          rd_active <= 0;
          rd_cnt    <= 0;
        end
        else begin
          rd_cnt       <= rd_cnt + 1;
          rd_curr_addr <= next_addr(
                            rd_curr_addr,
                            rd_active_len,
                            rd_active_burst);
        end
      end

    end
  end

endmodule
