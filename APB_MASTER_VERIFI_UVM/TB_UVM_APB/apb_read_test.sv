class apb_read_test extends uvm_test;

    `uvm_component_utils(apb_read_test)

    apb_env env;
    apb_read_seq seq;

    function new(string name = "apb_read_test",
                 uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = apb_env::type_id::create("env", this);
    endfunction


    task run_phase(uvm_phase phase);

        phase.raise_objection(this);

        `uvm_info(get_type_name(),
                  "Starting APB Read Test",
                  UVM_LOW)

        seq = apb_read_seq::type_id::create("seq");

        seq.start(env.agt.seqr);

        phase.drop_objection(this);

    endtask

endclass

