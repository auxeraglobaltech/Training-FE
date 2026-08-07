class agu_basic_1d_test extends test;
  `uvm_component_utils(agu_basic_1d_test)
   function new(string name="agu_basic_1d_test",uvm_component parent);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
  agu_basic_1d_sequence sq;
    phase.raise_objection(this);
     
    sq=agu_basic_1d_sequence::type_id::create("sq");
    sq.start(ev.agt.sqr);
       #2us;
    phase.drop_objection(this);
  endtask
endclass

