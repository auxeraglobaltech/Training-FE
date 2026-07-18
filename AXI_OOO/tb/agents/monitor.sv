class monitor extends uvm_monitor;

`uvm_component_utils(monitor)
  virtual axiif vif;
 
//analysis port

uvm_analysis_port#(axi_seq_item) aw_ap;
uvm_analysis_port#(axi_seq_item) w_ap;
uvm_analysis_port#(axi_seq_item) b_ap;
uvm_analysis_port#(axi_seq_item) ar_ap;
uvm_analysis_port#(axi_seq_item) r_ap;

 // Pending / completed write transactions by ID
  axi_seq_item wr_pending_q   [int][$];
  axi_seq_item wr_completed_q [int][$];

  // Pending read transactions by ID
  axi_seq_item rd_pending_q[int][$];

 
//constructor

function new(string name="monitor", uvm_component parent);

  super.new(name, parent);

  aw_ap=new("aw_ap",this);
  w_ap=new("w_ap",this);
  b_ap=new("b_ap",this);
  ar_ap=new("ar_ap",this);
  r_ap=new("r_ap",this);

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
 collect_aw();
 collect_w();
 collect_b();

 collect_ar();
 collect_r();
join

endtask
task collect_aw();

    axi_seq_item txn;

    forever begin

      @(posedge vif.axi_aclk iff
        (vif.axi_awvalid && vif.axi_awready));

      txn = axi_seq_item::type_id::create("txn");

      txn.write   = 1;
      txn.awid    = vif.axi_awid;
      txn.awaddr  = vif.axi_awaddr;
      txn.awlen   = vif.axi_awlen;
      txn.awburst = vif.axi_awburst;
      txn.awsize  = 3'b010;


      txn.wdata_q.delete();
      txn.wstrb_q.delete();

      wr_pending_q[txn.awid].push_back(txn);
      aw_ap.write(txn);
      `uvm_info("MON_AW",$sformatf("AW id =%0d addr=%0h len =%0d burst=%0b",txn.awid,txn.awaddr,txn.awlen,txn.awburst),UVM_LOW)
      end
      endtask
 task collect_w();
   axi_seq_item txn;
   int id;
   forever begin
    @(posedge vif.axi_aclk iff
        (vif.axi_wvalid && vif.axi_wready));

      id = vif.axi_wid;

      if(wr_pending_q[id].size() == 0) begin
        `uvm_error("MON_W",$sformatf("W beat received but no pending AW for WID =%0d ",id))
        end
        else begin
        txn = wr_pending_q[id][0];

        txn.wdata_q.push_back(vif.axi_wdata);
        txn.wstrb_q.push_back(vif.axi_wstrb);
        `uvm_info("MON_W",$sformatf("W id=%0d beat=%0d data=%0h last=%0b",id,txn.wdata_q.size(),vif.axi_wdata,vif.axi_wlast),UVM_LOW)
        if(vif.axi_wlast)
          begin
          txn = wr_pending_q[id].pop_front();
          wr_completed_q[id].push_back(txn);
          w_ap.write(txn);
          `uvm_info("MON_W",$sformatf("W burst complete id=%0d beats=%0d",id,txn.wdata_q.size()),UVM_LOW)
          end
          end
          end
          endtask
          //B Monitor
          task collect_b();
          axi_seq_item txn;
          int id;
          forever begin
             @(posedge vif.axi_aclk iff
            (vif.axi_bvalid && vif.axi_bready));

            id = vif.axi_bid;

           if(wr_completed_q[id].size() == 0) begin
             `uvm_error("MON_B",$sformatf("BRESP received but no complete write for BID=%0d",id))
             end
             else begin
              txn = wr_completed_q[id].pop_front();

              txn.bid   = vif.axi_bid;
              txn.bresp = vif.axi_bresp;
              `uvm_info("MON_B_DEBUG",$sformatf("Sending B to scoreboard BID=%0d BRESP=%0d",txn.bid,txn.bresp),UVM_LOW)
              b_ap.write(txn);
            `uvm_info("MON_B",$sformatf("B response id = %0d bresp =%0d addr=%0h beats=%0d ",txn.bid,txn.bresp,txn.awaddr,txn.wdata_q.size()),UVM_LOW)
              end
              end
              endtask
             //AR Monitor
  task collect_ar();

    axi_seq_item txn;

    forever begin

      @(posedge vif.axi_aclk iff
        (vif.axi_arvalid && vif.axi_arready));

      txn = axi_seq_item::type_id::create("txn");

      txn.write   = 0;
      txn.arid    = vif.axi_arid;
      txn.araddr  = vif.axi_araddr;
      txn.arlen   = vif.axi_arlen;
      txn.arburst = vif.axi_arburst;
      txn.arsize  = 3'b010;

      txn.rdata_q.delete();
      txn.rresp_q.delete();

      rd_pending_q[txn.arid].push_back(txn);
      ar_ap.write(txn);
      `uvm_info("MON_AR",$sformatf("AR id=%0d addr=%0h len=%0d burst=%0b",txn.arid,txn.araddr,txn.arlen,txn.arburst),UVM_LOW) 
          end
          endtask
          //R Monitor
          task collect_r();
          axi_seq_item txn;
          int id;
           forever begin

      @(posedge vif.axi_aclk iff
        (vif.axi_rvalid && vif.axi_rready));

      id = vif.axi_rid;

      if(rd_pending_q[id].size() == 0) begin
          `uvm_error("MON_R",$sformatf("RDATA received but no pending AR for RID =%0d",id))
          end
          else begin
        txn = rd_pending_q[id].pop_front();

        txn.rid = vif.axi_rid;
        txn.rdata_q.delete();
        txn.rresp_q.delete();
        txn.axi_rlast = 1'b0;
        forever begin
          txn.rdata_q.push_back(vif.axi_rdata);
          txn.rresp_q.push_back(vif.axi_rresp);
          `uvm_info("MON_R",$sformatf("R id=%0d beat =%0d data=%0h last=%0b",txn.rid,txn.rdata_q.size(),vif.axi_rdata,vif.axi_rlast),UVM_LOW)
           if(vif.axi_rlast)
               begin
                txn.axi_rlast=1'b1;   
                break;
               end
          @(posedge vif.axi_aclk iff
            (vif.axi_rvalid && vif.axi_rready));

        end
        r_ap.write(txn);
        `uvm_info("MON_R",$sformatf("R burst complete id =%0d addr=%0h beats=%0d",txn.rid,txn.araddr,txn.rdata_q.size()),UVM_LOW)
        end
        end
        endtask
              
endclass
 
 
 
 
 
 
