class apb_env extends uvm_env;

    apb_agent agt;
    apb_scoreboard scb;
    apb_coverage cov;


    `uvm_component_utils(apb_env)


    function new(string name = "apb_env",
                 uvm_component parent);

        super.new(name,parent);

    endfunction



    function void build_phase(uvm_phase phase);

        super.build_phase(phase);


        agt = apb_agent::type_id::create("agt", this);

        scb = apb_scoreboard::type_id::create("scb", this);

	cov = apb_coverage::type_id::create("cov" , this);

    endfunction



    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);


        // Actual transaction from monitor
        agt.mon.ap.connect(scb.actual_export);


        // Expected transaction from driver
        agt.drv.drv_ap.connect(scb.expected_export);

	// Monitor to Coverage
	agt.mon.ap.connect(cov.analysis_export);
    endfunction


endclass

