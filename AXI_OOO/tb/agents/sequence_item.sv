class axi_seq_item extends uvm_sequence_item;
 parameter DATA_WIDTH    = 32;
 parameter ADDRESS_WIDTH = 32;
 //Control
 rand bit write;
 //Write Address Channel
  rand bit [3:0]  awid;
  rand bit [31:0] awaddr;
  rand bit [7:0]  awlen;
  rand bit [2:0]  awsize;
  rand bit [1:0]  awburst; 

  //Write Data Channel
  rand bit [31:0] wdata_q[$];
  rand bit [3:0]  wstrb_q[$];
  rand bit[3:0] wid;

  //Read Address Channel
  rand bit [3:0]  arid;
  rand bit [31:0] araddr;
  rand bit [7:0]  arlen;
  rand bit [2:0]  arsize;
  rand bit [1:0]  arburst;
   

  //Response Fields

  bit [1:0] bresp;
  bit [3:0] bid;
  bit [3:0] rid;
  bit [1:0] rresp_q[$];
  bit [31:0] rdata_q[$];
  bit[31:0] axi_rdata;
  bit axi_rlast;

  //Constraints
   constraint c_awlen {
    awlen inside {[0:7]};
  }
  
    constraint c_arlen {
    arlen inside {[0:7]};
  }
  
   constraint c_q_size {
    wdata_q.size() == awlen + 1;
    wstrb_q.size() == awlen + 1;
  }
  constraint c_wstrb {
    foreach(wstrb_q[i])
      wstrb_q[i] == 4'hF;
  }
   constraint c_size {
    awsize == 3'b010;
    arsize == 3'b010;
  }
/*  constraint c_addr_align {
     awaddr % (2**awsize) == 0;
     araddr % (2**arsize) == 0;
  }*/
  constraint c_wrap_len {
  if(awburst == 2'b10)
    awlen inside {1,3,7,15};

  if(arburst == 2'b10)
    arlen inside {1,3,7,15};
}
 /* constraint c_id{
    awid==4'b0011;
    wid==4'b0011;
    arid==4'b0011;
  }*/
  constraint c_id {
  wid == awid;
  awid inside {[0:7]};
  arid inside {[0:7]};
}
 `uvm_object_utils(axi_seq_item)
  //constructor
  function new(string name="axi_seq_item");
  super.new(name);
  endfunction
endclass

