class axi_incr_unaligned_test extends test;
  `uvm_component_utils(axi_incr_unaligned_test)
  //env ev;
 // virtual axiif vif;
  function new(string name="axi_incr_unaligned_test",uvm_component parent);
    super.new(name,parent);
  endfunction
  //function void build_phase(uvm_phase phase);
   // super.build_phase(phase);
   /* if(!uvm_config_db#(virtual apbif)::get(this,"*","vif",vif))
      `uvm_fatal("NOVIF","virtual interface not present")*/
   // ev=env::type_id::create("ev",this);
  //endfunction
  task run_phase(uvm_phase phase);
  axi_incr_unaligned_sequence sq;
    phase.raise_objection(this);
     
    sq=axi_incr_unaligned_sequence::type_id::create("sq");
    sq.start(ev.agt.sqr);
   // phase.phase_done.set_drain_time(this, 100ns);
    #2us;
    phase.drop_objection(this);
  endtask
endclass

