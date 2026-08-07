class agent extends uvm_agent;
  `uvm_component_utils(agent)
   agu_driver drv;
  // monitor mon;
   sequencer sqr;
   function new(string name="agent",uvm_component parent);
     super.new(name,parent);
   endfunction
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     drv=agu_driver::type_id::create("drv",this);
    // mon=monitor::type_id::create("mon",this);
     sqr=sequencer::type_id::create("sqr",this);
   endfunction

   function void connect_phase(uvm_phase phase);
     super.connect_phase(phase);
     drv.seq_item_port.connect(sqr.seq_item_export);
   endfunction
 endclass


