/*************************************************************************
File name:axi4_master_sequencer.sv
Description: This module acts as a sequencer is a mediator who establishes 
a connection between sequence and driver via handshaking
**************************************************************************/

//axi4_master_sequencer is derived from uvm_sequencer base class
class axi4_master_sequencer extends uvm_sequencer#(axi4_master_seq_item);
  
  //factory registration
  `uvm_component_utils(axi4_master_sequencer)    

  //constructor
  function new(string name = "axi4_master_sequencer", uvm_component parent);
    super.new(name,parent);     
  endfunction 
  
endclass
