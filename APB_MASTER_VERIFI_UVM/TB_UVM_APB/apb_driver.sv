class apb_driver extends uvm_driver #(apb_trans);

    virtual apb_interface vif;

    apb_trans tr;

    // Analysis port to send expected transaction to scoreboard
    uvm_analysis_port #(apb_trans) drv_ap;


    `uvm_component_utils(apb_driver)


    function new(string name = "apb_driver",
                 uvm_component parent);

        super.new(name,parent);

        drv_ap = new("drv_ap", this);

    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db #(virtual apb_interface)::get(
                this,
                "",
                "vif",
                vif))

            `uvm_fatal("DRV",
                       "VIRTUAL INTERFACE NOT FOUND");

    endfunction



    task run_phase(uvm_phase phase);

        forever begin

            seq_item_port.get_next_item(tr);	//telling sequencer to get next transaction


            // Send expected transaction to scoreboard
            drv_ap.write(tr);


            drive_transfer(tr);


            seq_item_port.item_done();

        end

    endtask



    task drive_transfer(apb_trans tr);

        @(vif.drv_cb);


        vif.drv_cb.transfer       <= tr.transfer;
        vif.drv_cb.write          <= tr.write;
        vif.drv_cb.read           <= tr.read;
        vif.drv_cb.apb_paddr      <= tr.apb_paddr;
        vif.drv_cb.apb_write_data <= tr.apb_write_data;


        while(!vif.pready)
            @(vif.drv_cb);


        @(vif.drv_cb);

        vif.drv_cb.transfer <= 0;
        vif.drv_cb.write    <= 0;
        vif.drv_cb.read     <= 0;


    endtask


endclass

