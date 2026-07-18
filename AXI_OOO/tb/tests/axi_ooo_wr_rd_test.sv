class axi_ooo_wr_rd_test extends test;
`uvm_component_utils(axi_ooo_wr_rd_test)
function new(string name="axi_ooo_wr_rd_test",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction
  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    // Outstanding requests enabled
    uvm_config_db #(bit) ::set(this,"ev.agt.drv","outstanding_mode",1'b1);
    //OOO response mode enabled
    uvm_config_db #(bit) :: set(this,"ev.agt.drv","ooo_mode",1'b1);
    endfunction
    task run_phase(uvm_phase phase);

    axi_ooo_wr_rd_sequence sq;
    phase.raise_objection(this);

    sq = axi_ooo_wr_rd_sequence::type_id::create("sq");

    sq.start(ev.agt.sqr);

    #2us;

    phase.drop_objection(this);

  endtask

endclass
