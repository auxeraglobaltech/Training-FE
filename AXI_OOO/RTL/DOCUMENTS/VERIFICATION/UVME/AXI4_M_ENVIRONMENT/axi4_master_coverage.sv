// Functional coverage_tb
// covergroup and cover points
// bins
// cross coverage
// command to enable coverage: xrun -coverage all
// to open Cadence IMC tool : imc & -> open UCDB file in IMC to read the coverage dump

class axi4_master_coverage extends uvm_subscriber #(axi4_master_seq_item); 
// uvm_subscriber is a standard uvm component to implement coverage : this will be analysis import 
    
  //factory registration
  `uvm_component_utils(axi4_master_coverage)
  
  axi4_master_seq_item txn;      // sequence item handle
  parameter DATA_WIDTH    = 32;
  parameter ADDRESS_WIDTH = 32;
     
  // Covergroup 
  covergroup covgroup_axi4_master;
  
    option.name         = "covgroup_axi4_master";
    option.comment      = "to check coverage of step size";  

    MASTER_WREN : coverpoint txn.master_wren // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    MASTER_WADDR : coverpoint txn.master_waddr // 32 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 4;
    }

    MASTER_WID : coverpoint txn.master_wid  // 4 bits
    {
      bins bin_0 = {[0:3]};
      bins bin_1 = {[4:7]};
      bins bin_2 = {[8:11]};
      bins bin_3 = {[12:15]};
    } 

    MASTER_WLEN : coverpoint txn.master_wlen // 8 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 4;
    }

    MASTER_WBURST : coverpoint txn.master_wburst // 2 bits
    { 
	  bins bin_value_0 = {0};
      bins bin_value_1 = {1};
      bins bin_value_2 = {2}; 
    }

    MASTER_WDATA : coverpoint txn.master_wdata // 32 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 16;
    }

    MASTER_WSTRB : coverpoint txn.master_wstrb  // 4 bits
    {
      bins bin_0 = {[0:3]};
      bins bin_1 = {[4:7]};
      bins bin_2 = {[8:11]};
      bins bin_3 = {[12:15]};
    } 

    MASTER_RDEN : coverpoint txn.master_rden // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    MASTER_RADDR : coverpoint txn.master_raddr // 32 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 4;
    }

    MASTER_RLEN : coverpoint txn.master_rlen // 8 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 4;
    }

    MASTER_RBURST : coverpoint txn.master_rburst // 2 bits
    { 
	  bins bin_value_0 = {0};
      bins bin_value_1 = {1};
      bins bin_value_2 = {2}; 
    }

    MASTER_RID : coverpoint txn.master_rid  // 4 bits
    {
      bins bin_0 = {[0:3]};
      bins bin_1 = {[4:7]};
      bins bin_2 = {[8:11]};
      bins bin_3 = {[12:15]};
    } 

    AXI_ARESET_N : coverpoint txn.axi_areset_n // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_AWREADY : coverpoint txn.axi_awready // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_WREADY : coverpoint txn.axi_wready // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_BRESP : coverpoint txn.axi_bresp // 2 bits
    { 
	  bins bin_value_0 = {0};
      bins bin_value_1 = {1};
      bins bin_value_2 = {2}; 
      bins bin_value_3 = {3};       
    }

    AXI_BVALID : coverpoint txn.axi_bvalid // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_BID : coverpoint txn.axi_bid  // 4 bits
    {
      bins bin_0 = {[0:3]};
      bins bin_1 = {[4:7]};
      bins bin_2 = {[8:11]};
      bins bin_3 = {[12:15]};
    } 
    
    AXI_ARREADY : coverpoint txn.axi_arready // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_RVALID : coverpoint txn.axi_rvalid // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_RID : coverpoint txn.axi_rid  // 4 bits
    {
      bins bin_0 = {[0:3]};
      bins bin_1 = {[4:7]};
      bins bin_2 = {[8:11]};
      bins bin_3 = {[12:15]};
    } 

    AXI_RLAST : coverpoint txn.axi_rlast // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_RRESP : coverpoint txn.axi_rresp // 2 bits
    { 
	  bins bin_value_0 = {0};
      bins bin_value_1 = {1};
      bins bin_value_2 = {2}; 
      bins bin_value_3 = {3};       
    }

    AXI_RDATA : coverpoint txn.axi_rdata // 32 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 16;
    }

    MASTER_RDATA : coverpoint txn.master_rdata // 32 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 16;
    }

    AXI_AWADDR : coverpoint txn.axi_awaddr // 32 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 4;
    }

    AXI_AWVALID : coverpoint txn.axi_awvalid // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_AWID : coverpoint txn.axi_awid  // 4 bits
    {
      bins bin_0 = {[0:3]};
      bins bin_1 = {[4:7]};
      bins bin_2 = {[8:11]};
      bins bin_3 = {[12:15]};
    } 
    
    AXI_AWLEN : coverpoint txn.axi_awlen // 8 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 4;
    }

    AXI_AWBURST : coverpoint txn.axi_awburst // 2 bits
    { 
	  bins bin_value_0 = {0};
      bins bin_value_1 = {1};
      bins bin_value_2 = {2};
      //bins bin_value_3 = {3};

    }

    AXI_WDATA : coverpoint txn.axi_wdata // 32 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 16;
    }

    AXI_WVALID : coverpoint txn.axi_wvalid // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_WID : coverpoint txn.axi_wid  // 4 bits
    {
      bins bin_0 = {[0:3]};
      bins bin_1 = {[4:7]};
      bins bin_2 = {[8:11]};
      bins bin_3 = {[12:15]};
    } 

    AXI_WLAST : coverpoint txn.axi_wlast // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_WSTRB : coverpoint txn.axi_wstrb  // 4 bits
    {
      bins bin_0 = {[0:3]};
      bins bin_1 = {[4:7]};
      bins bin_2 = {[8:11]};
      bins bin_3 = {[12:15]};
    } 

    AXI_BREADY : coverpoint txn.axi_bready // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_ARADDR : coverpoint txn.axi_araddr // 32 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 4;
    }

    AXI_ARVALID : coverpoint txn.axi_arvalid // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

    AXI_ARID : coverpoint txn.axi_arid  // 4 bits
    {
      bins bin_0 = {[0:3]};
      bins bin_1 = {[4:7]};
      bins bin_2 = {[8:11]};
      bins bin_3 = {[12:15]};
    } 

    AXI_ARLEN : coverpoint txn.axi_arlen // 8 bits - in this case use auto bin feature
    { 	  
      option.auto_bin_max = 4;
    }

    AXI_ARBURST_RBURST : coverpoint txn.axi_arburst // 2 bits
    { 
	  bins bin_value_0 = {0};
      bins bin_value_1 = {1};
      bins bin_value_2 = {2}; 
      //bins bin_value_3 = {3}; 
    }

    AXI_RREADY : coverpoint txn.axi_rready // 1 bit
    { 
      bins bin_value_0 = {0};
      bins bin_value_1 = {1};
    }

  //  CROSS_COVERAGE: cross AXI_ARESET_N, AXI_RREADY;    //cross coverage

  endgroup
  
  //constructor
  function new(string name, uvm_component parent);
    super.new(name,parent);
    covgroup_axi4_master = new();
  endfunction 

  //write function
  virtual function void write(input axi4_master_seq_item t);
      txn = new();
      $cast(txn, t);    
      covgroup_axi4_master.sample(); 
      //cover group will update bins only when cover group is sampled
  endfunction

endclass
