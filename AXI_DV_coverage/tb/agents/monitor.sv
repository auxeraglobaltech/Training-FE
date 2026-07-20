class monitor extends uvm_monitor;

`uvm_component_utils(monitor)
  virtual axiif vif;
 
//analysis port

uvm_analysis_port#(axi_seq_item) ap;
 
//constructor

function new(string name, uvm_component parent);

  super.new(name, parent);

  ap=new("ap",this);

endfunction
 
//build phase

function void build_phase(uvm_phase phase);

super.build_phase(phase);

if(!uvm_config_db#(virtual axiif)::get(this,"*","vif",vif))
`uvm_fatal("NOVIF","virtual interface not found")

endfunction
 
function void connect_phase(uvm_phase phase);

super.connect_phase(phase);

endfunction
 
 
//run phase

task run_phase(uvm_phase phase);

fork
collect_write();
collect_read();
join

endtask
//Write Monitor
task collect_write();

    axi_seq_item txn;

    forever begin

      @(posedge vif.axi_aclk iff
        (vif.axi_awvalid && vif.axi_awready));

      txn = axi_seq_item::type_id::create("txn");

      txn.write   = 1;
      txn.awaddr  = vif.axi_awaddr;
      txn.awlen   = vif.axi_awlen;
      txn.awburst = vif.axi_awburst;
      txn.awid    = vif.axi_awid;

      txn.wdata_q.delete();
      txn.wstrb_q.delete();

      // collect write burst
      for(int i=0;i<=txn.awlen;i++) begin

        @(posedge vif.axi_aclk iff
          (vif.axi_wvalid && vif.axi_wready));

        txn.wdata_q.push_back(vif.axi_wdata);
        txn.wstrb_q.push_back(vif.axi_wstrb);

      end

      @(posedge vif.axi_aclk iff
        (vif.axi_bvalid && vif.axi_bready));

      txn.bresp = vif.axi_bresp;

      ap.write(txn);
      `uvm_info("MON",$sformatf("Write MON addr=%0h len=%0d",txn.awaddr,txn.awlen),UVM_LOW)
      end
      endtask
  //Read Monitor
  task collect_read();

    axi_seq_item txn;

    forever begin

      @(posedge vif.axi_aclk iff
        (vif.axi_arvalid && vif.axi_arready));

      txn = axi_seq_item::type_id::create("txn");

      txn.write   = 0;
      txn.araddr  = vif.axi_araddr;
      txn.arlen   = vif.axi_arlen;
      txn.arburst = vif.axi_arburst;
      txn.arid    = vif.axi_arid;

      txn.rdata_q.delete();
      txn.rresp_q.delete();

      for(int i=0;i<=txn.arlen;i++) begin

        @(posedge vif.axi_aclk iff
          (vif.axi_rvalid && vif.axi_rready));

        txn.rdata_q.push_back(vif.axi_rdata);
        txn.rresp_q.push_back(vif.axi_rresp);

      end

      ap.write(txn);
      `uvm_info("MON",$sformatf("READ MON addr=%0h len=%0d",txn.araddr,txn.arlen),UVM_LOW)
      end
      endtask
endclass
 
 
 
 
 
 
