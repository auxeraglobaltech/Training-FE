/*************************************************
File name:axi4_master_sequence.sv
Description:This module contains various sequences to be sent for test
**************************************************/
//axi4_master_seq is derived from uvm_sequence base class
class axi4_master_seq extends uvm_sequence#(axi4_master_seq_item);
  
  //factory registration
  `uvm_object_utils(axi4_master_seq)    
  axi4_master_seq_item seq_item_inst;   // seq_item handle

  //variables declaration for scenarios
  int         scenario            ;
  bit         axi_areset_n_seq    ;

  bit         axi_awready_seq     ;

  bit         axi_wready_seq      ;

  bit [3:0]   axi_bid_seq         ;
  bit [1:0]   axi_bresp_seq       ;
  bit         axi_bvalid_seq      ;

  bit         axi_arready_seq     ;

  bit [3:0]   axi_rid_seq         ;
  bit [31:0]  axi_rdata_seq       ;
  bit         axi_rlast_seq       ;
  bit         axi_rvalid_seq      ;
  bit [1:0]   axi_rresp_seq       ;

  bit         master_wren_seq     ;
  bit [31:0]  master_waddr_seq    ;
  bit [3:0]	  master_wid_seq      ;
  bit [7:0]   master_wlen_seq     ;
  bit [1:0]	  master_wburst_seq   ;
  bit [31:0]  master_wdata_seq    ;
  bit [3:0]	  master_wstrb_seq    ;

  bit         master_rden_seq     ;
  bit [31:0]  master_raddr_seq    ;
  bit [7:0]	  master_rlen_seq     ;
  bit [1:0]	  master_rburst_seq   ;
  bit [3:0]	  master_rid_seq      ;  


  //constructor
  function new(string name = "axi4_master_seq");
    super.new(name);
  endfunction
   
  //task body
  virtual task body();
    seq_item_inst = axi4_master_seq_item::type_id::create("seq_item_inst"); //creating object
    
    //scenario 1 - reset is asserted and all other inputs are randomized
   if(scenario == 1)    
   begin
    `uvm_info(get_name(),$sformatf("\n step 2d : inside sequence scenario == 1 "),UVM_MEDIUM)
	  repeat(10) 
      begin
      `uvm_do_with(seq_item_inst,
                   {seq_item_inst.axi_areset_n == axi_areset_n_seq;
                   });
      end
	end  
    
    //scenario 2 - reset is de-asserted and all other inputs are zero    
    if(scenario == 2) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 2"),UVM_MEDIUM)
	  repeat(10) begin
        `uvm_do_with(seq_item_inst,
                    {seq_item_inst.axi_areset_n  == axi_areset_n_seq;
                     seq_item_inst.axi_awready   == axi_awready_seq;
                     seq_item_inst.axi_wready    == axi_wready_seq;
                     seq_item_inst.axi_bid       == axi_bid_seq;
                     seq_item_inst.axi_bresp     == axi_bresp_seq;
                     seq_item_inst.axi_bvalid    == axi_bvalid_seq;
                     seq_item_inst.axi_arready   == axi_arready_seq;
                     seq_item_inst.axi_rid       == axi_rid_seq;
                     seq_item_inst.axi_rdata     == axi_rdata_seq;
                     seq_item_inst.axi_rlast     == axi_rlast_seq;
                     seq_item_inst.axi_rvalid    == axi_rvalid_seq;
                     seq_item_inst.axi_rresp     == axi_rresp_seq;
                     seq_item_inst.master_wren   == master_wren_seq;
                     seq_item_inst.master_waddr  == master_waddr_seq;
                     seq_item_inst.master_wid    == master_wid_seq;
                     seq_item_inst.master_wlen   == master_wlen_seq;
                     seq_item_inst.master_wburst == master_wburst_seq;
                     seq_item_inst.master_wdata  == master_wdata_seq;
                     seq_item_inst.master_wstrb  == master_wstrb_seq;
                     seq_item_inst.master_rden   == master_rden_seq;
                     seq_item_inst.master_raddr  == master_raddr_seq;
                     seq_item_inst.master_rlen   == master_rlen_seq;
                     seq_item_inst.master_rburst == master_rburst_seq;
                     seq_item_inst.master_rid    == master_rid_seq;                                          
                     });
	  end
	end


    //scenario 3 - reset = de-asserted, master_wren = 0, master_rden = 0 & all other inputs are randomized    
    if(scenario == 3) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 3"),UVM_MEDIUM)
	  repeat(10) begin
        `uvm_do_with(seq_item_inst,
                    {seq_item_inst.axi_areset_n  == axi_areset_n_seq;
                     seq_item_inst.master_wren   == master_wren_seq;
                     seq_item_inst.master_rden   == master_rden_seq;                                         
                     });
	  end
	end

 //scenario 4 
    if(scenario == 4) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 4"),UVM_MEDIUM)
	repeat(8) begin
    //a) reset = de-asserted, master_wren = 1, master_rden = 0 & axi_awready = 0    	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==1;master_rden==0;axi_awready==0;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_wlen==8'h04;
                      });
          master_waddr_seq=seq_item_inst.master_waddr;
          master_wburst_seq=seq_item_inst.master_wburst;
          master_wstrb_seq=seq_item_inst.master_wstrb;

          finish_item(seq_item_inst);
        end
       
       repeat(master_wlen_seq) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==0;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_wlen==8'h04;
                      master_waddr==master_waddr_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

    //b) reset = de-asserted, master_wren = 1, master_rden = 0 & axi_wready = 0    	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==1;master_rden==0;axi_awready==1;
                      axi_wready==0;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_wlen==8'h04;
                      });
          master_waddr_seq=seq_item_inst.master_waddr;
          master_wburst_seq=seq_item_inst.master_wburst;
          master_wstrb_seq=seq_item_inst.master_wstrb;

          finish_item(seq_item_inst);
        end
       
       repeat(master_wlen_seq) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==0;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_wlen==8'h04;
                      master_waddr==master_waddr_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

    //c) reset = de-asserted, master_wren = 1, master_rden = 0 & axi_bvalid = 0    	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==1;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==0;
                      master_wid==4'b0011;
                      master_wlen==8'h04;
                      });
          master_waddr_seq=seq_item_inst.master_waddr;
          master_wburst_seq=seq_item_inst.master_wburst;
          master_wstrb_seq=seq_item_inst.master_wstrb;

          finish_item(seq_item_inst);
        end
       
       repeat(master_wlen_seq) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==0;
                      master_wid==4'b0011;
                      master_wlen==8'h04;
                      master_waddr==master_waddr_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

      end
	end

    //scenario 5 - reset = de-asserted, master_wren = 1, master_rden = 0, master_wid != 3 & axi_bid != 3    
    if(scenario == 5) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 5"),UVM_MEDIUM)
	repeat(8) begin
	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==1;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0100;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0100;
                      master_wlen==8'h04;
                      });
          master_waddr_seq=seq_item_inst.master_waddr;
          master_wburst_seq=seq_item_inst.master_wburst;
          master_wstrb_seq=seq_item_inst.master_wstrb;

          finish_item(seq_item_inst);
        end
       
       repeat($urandom_range(10,20)) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0100;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0100;
                      master_wlen==8'h04;
                      master_waddr==master_waddr_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

     end
	end


    //scenario 6 - reset = de-asserted, master_wren = 1, master_rden = 0    
    if(scenario == 6) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 6"),UVM_MEDIUM)
//	repeat(8) begin
	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==1;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      });
          master_waddr_seq=seq_item_inst.master_waddr;
          master_wlen_seq=seq_item_inst.master_wlen;
          master_wburst_seq=seq_item_inst.master_wburst;
          master_wstrb_seq=seq_item_inst.master_wstrb;

          finish_item(seq_item_inst);
        end
       
       repeat(master_wlen_seq + 5) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

//     end
	end

    //scenario 7 - reset = de-asserted, master_wren = 1, master_rden = 0    
    if(scenario == 7) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 7"),UVM_MEDIUM)
//	repeat(8) begin
	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==1;master_rden==0;
                      });
          master_waddr_seq=seq_item_inst.master_waddr;
          master_wlen_seq=seq_item_inst.master_wlen;
          master_wburst_seq=seq_item_inst.master_wburst;
          master_wstrb_seq=seq_item_inst.master_wstrb;

          finish_item(seq_item_inst);
        end
       
       repeat(master_wlen_seq + 5) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

//     end
	end

    //scenario 8
    if(scenario == 8) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 8"),UVM_MEDIUM)
//	repeat(8) begin
    // a) reset = de-asserted, master_wren = 0, master_rden = 1 & arready = 0 
	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==1;axi_arready==0;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==1;axi_rlast==0;
                      });
          master_rid_seq=seq_item_inst.master_rid;
          master_raddr_seq=seq_item_inst.master_raddr;
          master_rlen_seq=seq_item_inst.master_rlen;
          master_rburst_seq=seq_item_inst.master_rburst;

          finish_item(seq_item_inst);
        end
       
       repeat(master_rlen_seq + 2) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==0;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==1;axi_rlast==0;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      master_rid==master_rid_seq;                      
                      });
          finish_item(seq_item_inst);
        end 

       repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==0;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==1;axi_rlast==1;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      master_rid==master_rid_seq;                                            
                      });
          finish_item(seq_item_inst);
        end 

       repeat(5) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==0;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==1;
                      axi_rlast==0;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      master_rid==master_rid_seq;
                      });
          finish_item(seq_item_inst);
        end 

// b) reset = de-asserted, master_wren = 0, master_rden = 1 & rvalid = 0 
	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==1;axi_arready==1;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==0;
                      axi_rlast==0;
                      master_rid==4'b0011;
                      });
          master_raddr_seq=seq_item_inst.master_raddr;
          master_rlen_seq=seq_item_inst.master_rlen;
          master_rburst_seq=seq_item_inst.master_rburst;

          finish_item(seq_item_inst);
        end
       
       repeat(master_rlen_seq + 2) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==1;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==0;
                      axi_rlast==0;
                      master_rid==4'b0011;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      });
          finish_item(seq_item_inst);
        end 

       repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==1;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==0;
                      axi_rlast==1;
                      master_rid==4'b0011;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      });
          finish_item(seq_item_inst);
        end 

       repeat(5) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==1;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==0;
                      axi_rlast==0;
                      master_rid==4'b0011;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      });
          finish_item(seq_item_inst);
        end 


//     end
	end

    //scenario 9 - - reset = de-asserted, master_wren = 0, master_rden = 1, master_rid != 3 & axi_rid != 3  
    if(scenario == 9) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 9"),UVM_MEDIUM)
//	repeat(8) begin 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==1;axi_arready==1;
                      axi_rid==4'b1011;axi_rresp==2'b00;axi_rvalid==1;
                      axi_rlast==0;
                      master_rid==4'b1011;
                      });
          master_raddr_seq=seq_item_inst.master_raddr;
          master_rlen_seq=seq_item_inst.master_rlen;
          master_rburst_seq=seq_item_inst.master_rburst;

          finish_item(seq_item_inst);
        end
       
       repeat(master_rlen_seq + 2) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==1;
                      axi_rid==4'b1011;axi_rresp==2'b00;axi_rvalid==1;
                      axi_rlast==0;
                      master_rid==4'b1011;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      });
          finish_item(seq_item_inst);
        end 

       repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==1;
                      axi_rid==4'b1011;axi_rresp==2'b00;axi_rvalid==1;
                      axi_rlast==1;
                      master_rid==4'b1011;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      });
          finish_item(seq_item_inst);
        end 

       repeat(5) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==1;
                      axi_rid==4'b1011;axi_rresp==2'b00;axi_rvalid==1;
                      axi_rlast==0;
                      master_rid==4'b1011;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      });
          finish_item(seq_item_inst);
        end 

//     end
	end

    //scenario 10 - - reset = de-asserted, master_wren = 0, master_rden = 1  
    if(scenario == 10) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 10"),UVM_MEDIUM)
//	repeat(8) begin 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==1;axi_arready==1;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==1;
                      axi_rlast==0;
                      master_rid==4'b0011;
                      });
          master_raddr_seq=seq_item_inst.master_raddr;
          master_rlen_seq=seq_item_inst.master_rlen;
          master_rburst_seq=seq_item_inst.master_rburst;

          finish_item(seq_item_inst);
        end
       
       repeat(master_rlen_seq + 2) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==1;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==1;
                      axi_rlast==0;
                      master_rid==4'b0011;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      });
          finish_item(seq_item_inst);
        end 

       repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==1;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==1;
                      axi_rlast==1;
                      master_rid==4'b0011;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      });
          finish_item(seq_item_inst);
        end 

       repeat(5) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_arready==1;
                      axi_rid==4'b0011;axi_rresp==2'b00;axi_rvalid==1;
                      axi_rlast==0;
                      master_rid==4'b0011;
                      master_raddr==master_raddr_seq;
                      master_rlen==master_rlen_seq;
                      master_rburst==master_rburst_seq;
                      });
          finish_item(seq_item_inst);
        end 

//     end
	end

    //scenario 11 - reset = de-asserted, master_wren = 1, master_rden = 0    
    //interleaving data
    if(scenario == 11) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 11"),UVM_MEDIUM)
//	repeat(4) begin
	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==1;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      });
          master_waddr_seq=seq_item_inst.master_waddr;
          master_wlen_seq=seq_item_inst.master_wlen;
          master_wburst_seq=seq_item_inst.master_wburst;
          master_wstrb_seq=seq_item_inst.master_wstrb;

          finish_item(seq_item_inst);
        end

       repeat(2) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 
        
        //axi_wready = 0
        repeat(190) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==0;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

       repeat(master_wlen_seq + 4) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

//     end
	end

    //scenario 12 - reset = de-asserted, master_wren = 1, master_rden = 0    
    //interleaving data - timeout
    if(scenario == 12) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 12"),UVM_MEDIUM)
//	repeat(8) begin
	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==1;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      });
          master_waddr_seq=seq_item_inst.master_waddr;
          master_wlen_seq=seq_item_inst.master_wlen;
          master_wburst_seq=seq_item_inst.master_wburst;
          master_wstrb_seq=seq_item_inst.master_wstrb;

          finish_item(seq_item_inst);
        end

       repeat(2) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 
        
        //axi_wready = 0
        repeat(205) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==0;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

       repeat(master_wlen_seq + 4) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

//     end
	end


    if(scenario == 13) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 5"),UVM_MEDIUM)
	  repeat(master_wlen_seq + 4) begin

        `uvm_do_with(seq_item_inst,
                    {seq_item_inst.axi_areset_n  == axi_areset_n_seq;
                     seq_item_inst.master_wren   == master_wren_seq;
                     seq_item_inst.master_rden   == master_rden_seq;

                     seq_item_inst.axi_awready   == axi_awready_seq;

                     seq_item_inst.axi_wready    == axi_wready_seq;
                     seq_item_inst.axi_bid       == axi_bid_seq;
                     seq_item_inst.axi_bresp     == axi_bresp_seq;
                     seq_item_inst.axi_bvalid    == axi_bvalid_seq;

                     seq_item_inst.master_waddr  == master_waddr_seq;
                     seq_item_inst.master_wid    == master_wid_seq;
                     seq_item_inst.master_wlen   == master_wlen_seq;
                     seq_item_inst.master_wburst == master_wburst_seq;
                     seq_item_inst.master_wstrb  == master_wstrb_seq;
                     });
	  end
	end

    //scenario  - reset = de-asserted, master_wren = 1, master_rden = 0 & axi_awready = 1 followed by 0 for 201 clks and then 1 for next clk    
    if(scenario == 14) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 4"),UVM_MEDIUM)
	  repeat(205) begin
        `uvm_do_with(seq_item_inst,
                    {seq_item_inst.axi_areset_n  == axi_areset_n_seq;
                     seq_item_inst.master_wren   == master_wren_seq;
                     seq_item_inst.master_rden   == master_rden_seq;

                     seq_item_inst.axi_awready   == axi_awready_seq;
                     seq_item_inst.axi_wready    == axi_wready_seq;
                     seq_item_inst.axi_bid       == axi_bid_seq;
                     seq_item_inst.axi_bresp     == axi_bresp_seq;
                     seq_item_inst.axi_bvalid    == axi_bvalid_seq;

                     seq_item_inst.master_waddr  == master_waddr_seq;
                     seq_item_inst.master_wid    == master_wid_seq;
                     seq_item_inst.master_wlen   == master_wlen_seq;
                     seq_item_inst.master_wburst == master_wburst_seq;
                     seq_item_inst.master_wstrb  == master_wstrb_seq;
                     });
	  end
	end

    if(scenario == 15) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 5"),UVM_MEDIUM)
      //for writeop
	  repeat(master_wlen_seq + 4) begin

        `uvm_do_with(seq_item_inst,
                    {seq_item_inst.axi_areset_n  == axi_areset_n_seq;
                     seq_item_inst.master_wren   == master_wren_seq;
                     seq_item_inst.master_rden   == master_rden_seq;

                     seq_item_inst.axi_awready   == axi_awready_seq;

                     seq_item_inst.axi_wready    == axi_wready_seq;
                     seq_item_inst.axi_bid       == axi_bid_seq;
                     seq_item_inst.axi_bresp     == axi_bresp_seq;
                     seq_item_inst.axi_bvalid    == axi_bvalid_seq;

                     seq_item_inst.master_waddr  == master_waddr_seq;
                     seq_item_inst.master_wid    == master_wid_seq;
                     seq_item_inst.master_wlen   == master_wlen_seq;
                     seq_item_inst.master_wburst == master_wburst_seq;
                     seq_item_inst.master_wstrb  == master_wstrb_seq;
                     });
	  end
	end
    //scenario 16 - reset = de-asserted, master_wren = 1, master_rden = 0    
    //interleaving data
    if(scenario == 16) begin
      `uvm_info(get_name(),$sformatf("\nstep 2 : inside scenario 11"),UVM_MEDIUM)
//	repeat(4) begin
	 
        repeat(1) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==1;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      });
          master_waddr_seq=seq_item_inst.master_waddr;
          master_wlen_seq=seq_item_inst.master_wlen;
          master_wburst_seq=seq_item_inst.master_wburst;
          master_wstrb_seq=seq_item_inst.master_wstrb;

          finish_item(seq_item_inst);
        end

       repeat(2) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 
        
        //axi_wready = 0
        repeat(100) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==0;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

        //axi_wready = 0
        repeat(2) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 
        //axi_wready = 0
        repeat(100) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==0;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

       repeat(master_wlen_seq + 4) begin
          start_item(seq_item_inst);
          assert(seq_item_inst.randomize() with {
                      axi_areset_n==1;master_wren==0;master_rden==0;axi_awready==1;
                      axi_wready==1;axi_bid==4'b0011;axi_bresp==2'b00;axi_bvalid==1;
                      master_wid==4'b0011;
                      master_waddr==master_waddr_seq;
                      master_wlen==master_wlen_seq;
                      master_wburst==master_wburst_seq;
                      master_wstrb==master_wstrb_seq;

                      });
          finish_item(seq_item_inst);
        end 

//     end
	end



`uvm_info(get_name(),$sformatf("step 5 : inside sequence done"),UVM_MEDIUM)

  endtask
   
endclass
