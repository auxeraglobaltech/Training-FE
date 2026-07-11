class apb_idle_test extends uvm_test;

	`uvm_component_utils(apb_idle_test)

	apb_env env;
	apb_idle_sequence seq;

	function new( string name = "apb_idle_test" ,
			uvm_component parent);
		super.new(name , parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		env = apb_env::type_id::create("env" , this);
	endfunction

	task run_phase(uvm_phase phase);
		
		phase.raise_objection(this);
		
		seq = apb_idle_sequence::type_id::create("seq");
		seq.start(env.agt.seqr);
		phase.drop_objection(this);
	endtask
endclass
