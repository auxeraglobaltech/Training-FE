/*************************************************
File name:axi4_m_writeop_interleavingdata_test.sv
Description:

**************************************************/

class axi4_m_writeop_interleavingdata_test extends axi4_m_base_test;
 
  `uvm_component_utils(axi4_m_writeop_interleavingdata_test)
 
    
  //constructor
  function new(string name = "axi4_m_writeop_interleavingdata_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
 

  //uvm build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

 
 // run phase starting
  task run_phase(uvm_phase phase);

    phase.raise_objection(this);
	
    `uvm_info(get_name(),$sformatf("step 1 : inside test"),UVM_MEDIUM)
   
  repeat(40)
    begin
/************************************************************************/
    //scenario 1 - reset is asserted and all other inputs are randomized
	seq_inst.scenario = 1;
    seq_inst.axi_areset_n_seq = 0;
    seq_inst.start(env_inst.agent_inst.sequencer_inst);
/************************************************************************/
    //scenario 11 - reset = de-asserted, master_wren = 1, master_rden = 0 & master_wburst = 0(fixed burst)
    //interlaving data
	seq_inst.scenario = 11;
/*    
    seq_inst.axi_areset_n_seq  = 1;
    seq_inst.master_wren_seq   = 1;
    seq_inst.master_rden_seq   = 0;

    seq_inst.axi_awready_seq   = 1;
    seq_inst.axi_wready_seq    = 1;
    seq_inst.axi_bid_seq       = 4'b0011;
    seq_inst.axi_bresp_seq     = 2'b00;
    seq_inst.axi_bvalid_seq    = 1;

    seq_inst.master_waddr_seq  = 32'h00000400;
    seq_inst.master_wid_seq    = 4'b0011;
    seq_inst.master_wlen_seq   = 8'h04;
    seq_inst.master_wburst_seq = 2'b10;
    seq_inst.master_wstrb_seq  = 4'b1111;
*/    
    seq_inst.start(env_inst.agent_inst.sequencer_inst);
/************************************************************************/
    //scenario 16 - reset = de-asserted, master_wren = 0, master_rden = 0 & master_wburst = 0(fixed burst)
	seq_inst.scenario = 16;
/*    seq_inst.axi_areset_n_seq  = 1;

    seq_inst.master_wren_seq   = ~seq_inst.master_wren_seq;
    seq_inst.master_rden_seq   = 0;

    seq_inst.axi_awready_seq   = 1;
    seq_inst.axi_wready_seq    = 1;
    seq_inst.axi_bid_seq       = 4'b0011;
    seq_inst.axi_bresp_seq     = 2'b00;
    seq_inst.axi_bvalid_seq    = 1;

    seq_inst.master_waddr_seq  = 32'h00000400;
    seq_inst.master_wid_seq    = 4'b0011;
    seq_inst.master_wlen_seq   = 8'h04;
    seq_inst.master_wburst_seq = 2'b10;
    seq_inst.master_wstrb_seq  = 4'b1111;
*/
    seq_inst.start(env_inst.agent_inst.sequencer_inst);
/************************************************************************/
    //scenario 11 - reset = de-asserted, master_wren = 1, master_rden = 0 & master_wburst = 0(fixed burst)
/*	seq_inst.scenario = 12;
    seq_inst.axi_areset_n_seq  = 1;
    seq_inst.master_wren_seq   = 1;
    seq_inst.master_rden_seq   = 0;

    seq_inst.axi_awready_seq   = 1;
    seq_inst.axi_wready_seq    = 0;
    seq_inst.axi_bid_seq       = 4'b0011;
    seq_inst.axi_bresp_seq     = 2'b00;
    seq_inst.axi_bvalid_seq    = 1;

    seq_inst.master_waddr_seq  = 32'h00000400;
    seq_inst.master_wid_seq    = 4'b0011;
    seq_inst.master_wlen_seq   = 8'h04;
    seq_inst.master_wburst_seq = 2'b10;
    seq_inst.master_wstrb_seq  = 4'b1111;
    
    seq_inst.start(env_inst.agent_inst.sequencer_inst);
/************************************************************************/
    //scenario 11 - reset = de-asserted, master_wren = 0, master_rden = 0 & master_wburst = 0(fixed burst)
/*	seq_inst.scenario = 13;
    seq_inst.axi_areset_n_seq  = 1;

    seq_inst.master_wren_seq   = 0;
    seq_inst.master_rden_seq   = 0;

    seq_inst.axi_awready_seq   = 1;
    seq_inst.axi_wready_seq    = 1;
    seq_inst.axi_bid_seq       = 4'b0011;
    seq_inst.axi_bresp_seq     = 2'b00;
    seq_inst.axi_bvalid_seq    = 1;

    seq_inst.master_waddr_seq  = 32'h00000400;
    seq_inst.master_wid_seq    = 4'b0011;
    seq_inst.master_wlen_seq   = 8'h04;
    seq_inst.master_wburst_seq = 2'b10;
    seq_inst.master_wstrb_seq  = 4'b1111;

    seq_inst.start(env_inst.agent_inst.sequencer_inst);
/************************************************************************/

    end

	`uvm_info(get_name(),$sformatf("step 6 : inside test done "),UVM_MEDIUM)

    phase.drop_objection(this);

  //  uvm_test_done.set_drain_time(this,1000);
  
  endtask
 
endclass
