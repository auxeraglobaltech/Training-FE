class agu_fixed_addr_mode_test extends test;

`uvm_component_utils(agu_fixed_addr_mode_test)

function new(string name="agu_fixed_addr_mode_test",
             uvm_component parent=null);

super.new(name,parent);

endfunction

task run_phase(uvm_phase phase);

agu_fixed_addr_sequence sq;

phase.raise_objection(this);

sq=agu_fixed_addr_sequence::type_id::create("sq");

sq.start(ev.agt.sqr);
#2us;
phase.drop_objection(this);

endtask

endclass
