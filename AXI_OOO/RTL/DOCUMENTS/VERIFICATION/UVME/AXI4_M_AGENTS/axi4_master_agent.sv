/**************************************************************
File name:axi4_master_agent.sv
Description: This module contains sequencer,driver and monitor 
handles & objects and connect phase
***************************************************************/
//axi4_master_agent is derived from uvm_agent base class
class axi4_master_agent extends uvm_agent;
   
   //factory registration
   `uvm_component_utils(axi4_master_agent) 
   
   axi4_master_sequencer sequencer_inst;   //sequencer handle
   axi4_master_driver    driver_inst;      //driver handle
   axi4_master_monitor   monitor_inst;     //monitor handle
   
   //constructor
   function new (string name = "axi4_master_agent", uvm_component parent);
     super.new(name, parent);
   endfunction
 
   //build phase
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     sequencer_inst = axi4_master_sequencer::type_id::create("sequencer_inst", this);
     driver_inst    = axi4_master_driver::type_id::create("driver_inst", this);
     monitor_inst   = axi4_master_monitor::type_id::create("monitor_inst", this);
   endfunction
 
   //connect phase
   function void connect_phase(uvm_phase phase);
     driver_inst.seq_item_port.connect(sequencer_inst.seq_item_export);
   endfunction
 
endclass
