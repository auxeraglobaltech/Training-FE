class agu_basic_2d_test extends test;
  `uvm_component_utils(agu_basic_2d_test)
   function new(string name="agu_basic_2d_test",uvm_component parent);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
  agu_basic_2d_seq sq;
    phase.raise_objection(this);
     
    sq=agu_basic_2d_seq::type_id::create("sq");
    sq.start(ev.agt.sqr);
       #2us;
    phase.drop_objection(this);
  endtask
endclass

