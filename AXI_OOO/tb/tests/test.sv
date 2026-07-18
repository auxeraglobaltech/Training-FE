//`timescale 1ns/1ps
class test extends uvm_test;
  `uvm_component_utils(test)
  env ev;
 // virtual axiif vif;
  function new(string name="test",uvm_component parent);
    super.new(name,parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
   /* if(!uvm_config_db#(virtual apbif)::get(this,"*","vif",vif))
      `uvm_fatal("NOVIF","virtual interface not present")*/
    ev=env::type_id::create("ev",this);
  endfunction
  task run_phase(uvm_phase phase);
  axi_seq sq;
    phase.raise_objection(this);
     
    sq=axi_seq::type_id::create("sq");
    sq.start(ev.agt.sqr);
   // phase.phase_done.set_drain_time(this, 100ns);
    #2us;
    phase.drop_objection(this);
  endtask
endclass

