class axi_coverage extends uvm_subscriber #(axi_seq_item);

  `uvm_component_utils(axi_coverage)

  axi_seq_item txn;
bit [3:0] cov_wstrb;
bit [1:0] cov_rresp;

  covergroup axi_cg;

    option.per_instance = 1;

    // WRITE ADDRESS CHANNEL

    cp_awid : coverpoint txn.awid {
      bins low_id[]  = {[0:3]};
      bins mid_id[]  = {[4:7]};
      bins high_id[] = {[8:15]};
    }

    cp_awaddr_align : coverpoint txn.awaddr[1:0] {
      bins aligned   = {2'b00};
      bins unaligned = {[1:3]};
    }

    cp_awlen : coverpoint txn.awlen {
      bins single_beat = {0};
      bins short_burst = {[1:3]};
      bins medium_burst = {[4:7]};
      bins long_burst = {[8:15]};
    }

    cp_awsize : coverpoint txn.awsize {
      bins byte_1 = {3'b000};
      bins byte_2 = {3'b001};
      bins byte_4 = {3'b010};
      bins byte_8 = {3'b011};
    }

    cp_awburst : coverpoint txn.awburst {
      bins fixed = {2'b00};
      bins incr  = {2'b01};
      bins wrap  = {2'b10};
      illegal_bins reserved = {2'b11};
    }

    // WRITE DATA CHANNEL

    cp_wstxnb : coverpoint cov_wstrb {
      bins all_bytes = {4'b1111};
      bins byte0     = {4'b0001};
      bins byte1     = {4'b0010};
      bins byte2     = {4'b0100};
      bins byte3     = {4'b1000};
      bins partial[] = {[1:14]};
      bins zero_stxnb = {4'b0000};
    }

    cp_wlast : coverpoint txn.wlast {
      bins low  = {0};
      bins high = {1};
    }

    // WRITE RESPONSE CHANNEL

    cp_bid : coverpoint txn.bid {
      bins bid[] = {[0:15]};
    }

    cp_bresp : coverpoint txn.bresp {
      bins okay   = {2'b00};
      bins exokay = {2'b01};
      bins slverr = {2'b10};
      bins decerr = {2'b11};
    }

    // READ ADDRESS CHANNEL

    cp_arid : coverpoint txn.arid {
      bins low_id[]  = {[0:3]};
      bins mid_id[]  = {[4:7]};
      bins high_id[] = {[8:15]};
    }

    cp_araddr_align : coverpoint txn.araddr[1:0] {
      bins aligned   = {2'b00};
      bins unaligned = {[1:3]};
    }

    cp_arlen : coverpoint txn.arlen {
      bins single_beat  = {0};
      bins short_burst  = {[1:3]};
      bins medium_burst = {[4:7]};
      bins long_burst   = {[8:15]};
    }

    cp_arsize : coverpoint txn.arsize {
      bins byte_1 = {3'b000};
      bins byte_2 = {3'b001};
      bins byte_4 = {3'b010};
      bins byte_8 = {3'b011};
    }

    cp_arburst : coverpoint txn.arburst {
      bins fixed = {2'b00};
      bins incr  = {2'b01};
      bins wrap  = {2'b10};
      illegal_bins reserved = {2'b11};
    }

    // READ DATA CHANNEL

    cp_rid : coverpoint txn.rid {
      bins rid[] = {[0:15]};
    }

    cp_rresp : coverpoint cov_rresp {
      bins okay   = {2'b00};
      bins exokay = {2'b01};
      bins slverr = {2'b10};
      bins decerr = {2'b11};
    }

    cp_rlast : coverpoint txn.rlast {
      bins low  = {0};
      bins high = {1};
    }
  // CROSS COVERAGE
  
    aw_burst_len_cross : cross cp_awburst, cp_awlen;

    ar_burst_len_cross : cross cp_arburst, cp_arlen;

    aw_size_burst_cross : cross cp_awsize, cp_awburst;

    ar_size_burst_cross : cross cp_arsize, cp_arburst;

    write_resp_id_cross : cross cp_bid, cp_bresp;

    read_resp_id_cross : cross cp_rid, cp_rresp;

    endgroup

     function new(string name = "axi_coverage",
               uvm_component parent = null);
    super.new(name, parent);
    axi_cg = new();
  endfunction
  function void write(axi_seq_item t);
  txn = t;
foreach (txn.wstrb_q[i]) begin
    cov_wstrb = txn.wstrb_q[i];
    axi_cg.sample();
  end

  foreach (txn.rresp_q[i]) begin
    cov_rresp = txn.rresp_q[i];
    axi_cg.sample();
  end
  
  axi_cg.sample();
endfunction
endclass



