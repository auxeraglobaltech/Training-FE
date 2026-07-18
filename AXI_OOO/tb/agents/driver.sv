class driver extends uvm_driver#(axi_seq_item);
  `uvm_component_utils(driver)
  virtual axiif vif;
   //Transaction Queues
   //Write channel Queues
  axi_seq_item aw_q[$];
  axi_seq_item w_q[$];
  axi_seq_item b_q[$];
  //Read channel queues
  axi_seq_item ar_q[$];
  axi_seq_item r_q[$];
  //Events
  event wr_done_e;
  event rd_done_e;

  bit outstanding_mode;
  bit ooo_mode;

  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axiif)::get(this,"*","vif",vif))
      `uvm_fatal("NOVIF","virtual interface not present")
    void'(uvm_config_db#(bit)::get(this, "", "outstanding_mode", outstanding_mode));
    void'(uvm_config_db#(bit)::get(this, "", "ooo_mode", ooo_mode));
    `uvm_info("DRV_CFG",$sformatf("outstanding_mode=%0b ooo_mode=%0b",outstanding_mode,ooo_mode),UVM_LOW)
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

   task run_phase(uvm_phase phase);
     wait(vif.axi_areset_n == 1);
     @(posedge vif.axi_aclk);
     vif.axi_awvalid <= 0;
     vif.axi_wvalid  <= 0;
     vif.axi_bready  <= 0;

     vif.axi_arvalid <= 0;
     vif.axi_rready  <= 0;

     vif.axi_wlast   <= 0;
     if(outstanding_mode || ooo_mode) 
       begin
       vif.axi_bready <= 1'b1;
       vif.axi_rready <= 1'b1;
       end
     fork
      get_transaction();
 
      drive_aw_channel();
      drive_w_channel();
      drive_b_channel();

      drive_ar_channel();
      drive_r_channel();
    join
   endtask
  //get transaction from the sequencer
    task get_transaction();

    axi_seq_item txn;

    forever begin

      seq_item_port.get_next_item(txn);
      //Write Transaction
       if(txn.write) 
         begin

          aw_q.push_back(txn);
          w_q.push_back(txn);
          if(!outstanding_mode)
          b_q.push_back(txn);
         `uvm_info("DRV",$sformatf("Write Transaction Received id=%0d addr=%0h len=%0d",txn.awid,txn.awaddr,txn.awlen),UVM_LOW)
          // wait until B channel completes
          if(!outstanding_mode)
            @(wr_done_e);
         end
         //Read Transaction
       else
         begin
          ar_q.push_back(txn);
          if(!outstanding_mode)
            r_q.push_back(txn);
          `uvm_info("DRV",$sformatf("Read Transaction Received id=%0d addr=%0h len=%0d",txn.arid,txn.araddr,txn.arlen),UVM_LOW)
         // wait until R channel completes
         if(!outstanding_mode)
           @(rd_done_e);
         end
        seq_item_port.item_done();
    end
    endtask
    //AW Channel
task drive_aw_channel();

    axi_seq_item txn;

    forever begin

      wait(aw_q.size() > 0);

      txn = aw_q.pop_front();

      @(posedge vif.axi_aclk);

      vif.axi_awvalid <= 1;
      vif.axi_awid    <= txn.awid;
      vif.axi_awaddr  <= txn.awaddr;
      vif.axi_awlen   <= txn.awlen;
     // vif.axi_awsize  <= tr.awsize;
      vif.axi_awburst <= txn.awburst;
      //Handshake
      `uvm_info("DRV_AW_DBG",$sformatf("Before AW wait:awvalid=%0b awready=%0b awid=%0d addr=%0h",vif.axi_awvalid,vif.axi_awready,txn.awid,txn.awaddr),UVM_LOW)
      // wait(vif.axi_awready);
      fork
  begin
    wait(vif.axi_awready);
  end
  begin
    repeat(50) @(posedge vif.axi_aclk);
     `uvm_error("DRV_AW",$sformatf("AWREADY TIMEOUT id=%0d addr=%0h len=%0d awvalid=%0b wready=%0b",txn.awid,txn.awaddr,txn.awlen,vif.axi_awvalid,vif.axi_awready))
  end
join_any
disable fork;

      @(posedge vif.axi_aclk);

      vif.axi_awvalid <= 0;
      `uvm_info("DRV",$sformatf("AW sent addr=%0h len=%0d",txn.awaddr,txn.awlen),UVM_LOW)
      
      end
      endtask
   //W channel  
    task drive_w_channel();

    axi_seq_item txn;

    forever begin

      wait(w_q.size() > 0);

      txn = w_q.pop_front();
      //Burst Beats
for(int i=0;i<=txn.awlen; i++) 
  begin

    @(posedge vif.axi_aclk);

    vif.axi_wvalid <= 1;
    vif.axi_wid    <= txn.wid;
    vif.axi_wdata  <= txn.wdata_q[i];
    vif.axi_wstrb  <= txn.wstrb_q[i];
   // Last Beat
   if(i == txn.awlen)
     vif.axi_wlast <= 1;
   else
     vif.axi_wlast <= 0;
 //Handshake
 wait(vif.axi_wready);
      end
@(posedge vif.axi_aclk);
  vif.axi_wvalid <= 0;
  vif.axi_wlast  <= 0;
  `uvm_info("DRV",$sformatf("W Burst sent beats=%0d",txn.awlen+1),UVM_LOW)
  end
  endtask
  //B Channel 
   task drive_b_channel();

    axi_seq_item txn;

    forever begin
   if(outstanding_mode || ooo_mode) 
       begin
     vif.axi_bready<=1'b1;
      @(posedge vif.axi_aclk);
      if(vif.axi_bvalid && vif.axi_bready) 
          begin
      `uvm_info("DRV_B_OOO",$sformatf("BRESP RECEIVED BID=%0d BRESP=%0d",vif.axi_bid,vif.axi_bresp),UVM_LOW)
          end
       end

    else begin

      wait(b_q.size() > 0);

      txn = b_q.pop_front();
      @(posedge vif.axi_aclk);
      vif.axi_bready<=1;
      //Wait for response
      wait(vif.axi_bvalid && vif.axi_bready);
      txn.bresp=vif.axi_bresp;
      txn.bid=vif.axi_bid;
      `uvm_info("DRV",$sformatf("Write Response BID =%0d BRESP =%0d",txn.bid,txn.bresp),UVM_LOW)
  @(posedge vif.axi_aclk);
    vif.axi_bready <= 0;
     wait(!vif.axi_bvalid);
      -> wr_done_e;
    end
    end

  endtask
  //AR Channel
 task drive_ar_channel();

    axi_seq_item txn;
forever begin

      wait(ar_q.size() > 0);

      txn = ar_q.pop_front();

      @(posedge vif.axi_aclk);

      vif.axi_arvalid <= 1;
      vif.axi_arid    <= txn.arid;
      vif.axi_araddr  <= txn.araddr;
      vif.axi_arlen   <= txn.arlen;
     // vif.axi_arsize  <= txn.arsize;
      vif.axi_arburst <= txn.arburst;
      //Handshake
       wait(vif.axi_arready);

      @(posedge vif.axi_aclk);

      vif.axi_arvalid <= 0;
      `uvm_info("DRV",$sformatf("AR sent addr=%0h len=%0d",txn.araddr,txn.arlen),UVM_LOW)
      
    end
    endtask
// R channel
 task drive_r_channel();

    axi_seq_item txn;
    int beat_count;
    int exp_beats;
    int timeout_count;
   forever begin
     if(outstanding_mode || ooo_mode)
       begin
        vif.axi_rready <= 1'b1;

      @(posedge vif.axi_aclk);

      if(vif.axi_rvalid && vif.axi_rready) 
          begin
        `uvm_info("DRV_R_OOO",$sformatf("RID=%0d RDATA=%0h RLAST=%0b RESP=%0d",vif.axi_rid,vif.axi_rdata,vif.axi_rlast,vif.axi_rresp),UVM_LOW)
          end
       end
       else begin


      wait(r_q.size() > 0);

      txn = r_q.pop_front();
      beat_count = 0;
      exp_beats  = txn.arlen + 1;
      timeout_count=0;
      vif.axi_rready <= 1;
      //Collect Burst read data

        while(beat_count < exp_beats) begin

        @(posedge vif.axi_aclk);
 //`uvm_info("DRV_DBG",$sformatf("rvalid=%0b rready=%0b rlast=%0b rdata=%0h beat_count=%0d exp=%0d",vif.axi_rvalid,vif.axi_rready,vif.axi_rlast,vif.axi_rdata,beat_count,exp_beats),UVM_LOW)
        if(vif.axi_rvalid && vif.axi_rready) begin

          txn.rdata_q.push_back(
            vif.axi_rdata);

          txn.rresp_q.push_back(
            vif.axi_rresp);
          txn.rid=vif.axi_rid;
          beat_count++;
          timeout_count=0;
        `uvm_info("DRV",$sformatf("RDATA RID =%0d beat=%0d data=%0h last=%0b",vif.axi_rid,beat_count,vif.axi_rdata,vif.axi_rlast),UVM_LOW)
        /*   if((beat_count == exp_beats) && !vif.axi_rlast)
               `uvm_warning("DRV","Expected last read beat reached but rlast is not high")
        `uvm_info("DRV",$sformatf("RDATA beat=%0d data=%0h last=%0b",beat_count,vif.axi_rdata,vif.axi_rlast),UVM_LOW)*/
    
        end
        else begin
        timeout_count++;
      end
       if(timeout_count > 100) begin
         `uvm_error("DRV",$sformatf("Read Timeout addr=%0h len =%0h received =%0d expected=%0d",txn.araddr,txn.arlen,beat_count,exp_beats))
         break;
         end
       end
      
      @(posedge vif.axi_aclk);
      vif.axi_rready <= 0;
     `uvm_info("DRV",$sformatf("Read Burst received  beats=%0d",beat_count),UVM_LOW)
      -> rd_done_e;
      
      end
     /* forever begin
      //wait for read request
       wait(r_q.size() > 0);

      txn = r_q.pop_front();
      beat_count=0;
      //Accept read data
       while(1) begin

      @(posedge vif.axi_aclk iff
       (vif.axi_rvalid));
       //Accept data
       vif.axi_rready<=1'b1;
       beat_count++;
      `uvm_info("DRV",$sformatf("RDATA beat=%0d data=%0h last=%0b",beat_count,vif.axi_rdata,vif.axi_rlast),UVM_LOW)
      //Burst Complete
      if(vif.axi_rlast)
          begin
          @(posedge vif.axi_aclk);
          vif.axi_rready<=0;
          `uvm_info("DRV",$sformatf("Read Burst received  beats=%0d",beat_count),UVM_LOW)
           break;
           end
           end
           end*/
      end
      endtask


endclass



