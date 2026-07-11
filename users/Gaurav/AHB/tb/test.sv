class ahb_base_test extends uvm_test;

   `uvm_component_utils(ahb_base_test)

   ahb_env env;

   function new(string name="ahb_base_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      env = ahb_env::type_id::create("env", this);

      `uvm_info(get_type_name(),"Build Phase Completed",UVM_LOW)
   endfunction

endclass

class ahb_reset_test extends ahb_base_test;

   `uvm_component_utils(ahb_reset_test)

   ahb_reset_seq seq;

   function new(string name = "ahb_reset_test", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);

      `uvm_info(get_type_name(),"Starting Reset Test",UVM_LOW)

      seq = ahb_reset_seq::type_id::create("seq");

      seq.start(env.agent.seqr);

      repeat(5) @(posedge env.agent.drv.vif.HCLK);

      `uvm_info(get_type_name(),"Reset Test Completed",UVM_LOW)

      phase.drop_objection(this);

   endtask

endclass

class ahb_write_test extends ahb_base_test;

   `uvm_component_utils(ahb_write_test)

   ahb_write_seq seq;

   function new(string name="ahb_write_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);

      seq = ahb_write_seq::type_id::create("seq");

      seq.start(env.agent.seqr);

      phase.drop_objection(this);

   endtask

endclass

class ahb_read_test extends ahb_base_test;

   `uvm_component_utils(ahb_read_test)

   ahb_read_seq seq;

   function new(string name="ahb_read_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);

      seq = ahb_read_seq::type_id::create("seq");

      seq.start(env.agent.seqr);

      phase.drop_objection(this);

   endtask

endclass

class ahb_idle_test extends ahb_base_test;

   `uvm_component_utils(ahb_idle_test)

   ahb_idle_seq seq;

   function new(string name="ahb_idle_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);

      seq = ahb_idle_seq::type_id::create("seq");

      seq.start(env.agent.seqr);

	#50ns;

      phase.drop_objection(this);

   endtask

endclass


class ahb_random_test extends ahb_base_test;

   `uvm_component_utils(ahb_random_test)

   ahb_random_seq seq;

   function new(string name="ahb_random_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);

      seq = ahb_random_seq::type_id::create("seq");

      seq.start(env.agent.seqr);

      phase.drop_objection(this);

   endtask

endclass

class ahb_back_to_back_write_test extends ahb_base_test;

   `uvm_component_utils(ahb_back_to_back_write_test)

   ahb_back_to_back_write_seq seq;

   function new(string name="ahb_back_to_back_write_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);

      seq = ahb_back_to_back_write_seq::type_id::create("seq");

      seq.start(env.agent.seqr);

      phase.drop_objection(this);

   endtask

endclass

class ahb_back_to_back_read_test extends ahb_base_test;

   `uvm_component_utils(ahb_back_to_back_read_test)

   ahb_back_to_back_read_seq seq;

   function new(string name="ahb_back_to_back_read_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);

      seq = ahb_back_to_back_read_seq::type_id::create("seq");

      seq.start(env.agent.seqr);

      phase.drop_objection(this);

   endtask

endclass

class ahb_mixed_rw_test extends ahb_base_test;

   `uvm_component_utils(ahb_mixed_rw_test)

   ahb_mixed_rw_seq seq;

   function new(string name="ahb_mixed_rw_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);

      seq = ahb_mixed_rw_seq::type_id::create("seq");

      seq.start(env.agent.seqr);

      phase.drop_objection(this);

   endtask

endclass

class ahb_write_read_test extends ahb_base_test;

   `uvm_component_utils(ahb_write_read_test)

   ahb_write_read_seq seq;

   function new(string name="ahb_write_read_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);

      seq = ahb_write_read_seq::type_id::create("seq");

      seq.start(env.agent.seqr);

      phase.drop_objection(this);

   endtask

endclass

class ahb_wrap4_write_test extends ahb_base_test;

   `uvm_component_utils(ahb_wrap4_write_test)

   ahb_wrap4_write_seq seq;

   function new(string name="ahb_wrap4_write_test", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   task run_phase(uvm_phase phase);

      phase.raise_objection(this);

      seq = ahb_wrap4_write_seq::type_id::create("seq");

      seq.start(env.agent.seqr);

      #20;

      phase.drop_objection(this);

   endtask

endclass
