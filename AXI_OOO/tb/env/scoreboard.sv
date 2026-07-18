/*class scoreboard extends uvm_scoreboard;

  `uvm_component_utils(scoreboard)
   uvm_analysis_imp #(axi_seq_item, scoreboard) imp;

  bit [31:0] mem[0:255];

  function new(string name="scoreboard", uvm_component parent);
    super.new(name,parent);
    imp = new("imp",this);
  endfunction 

  function bit [31:0] get_next_addr(
    bit [31:0] curr_addr,
    bit [7:0]  len,
    bit [1:0]  burst
  );

    bit [31:0] wrap_size;
    bit [31:0] wrap_base;
    bit [31:0] wrap_limit;
    bit [31:0] next_addr;

    case(burst)

      2'b00: get_next_addr = curr_addr;

      2'b01: get_next_addr = curr_addr + 4;

      2'b10: begin
        wrap_size  = (len + 1) * 4;
        wrap_base  = (curr_addr / wrap_size) * wrap_size;
        wrap_limit = wrap_base + wrap_size;
        next_addr  = curr_addr + 4;

        if(next_addr == wrap_limit)
          get_next_addr = wrap_base;
        else
          get_next_addr = next_addr;
      end

      default: get_next_addr = curr_addr;

    endcase

  endfunction
  
  function void write(axi_seq_item txn);

    bit [31:0] curr_addr;
    bit [31:0] exp_data;

    //Write transaction 
       if(txn.write) begin

      if(txn.bid !== txn.awid) begin
        `uvm_error("SB",$sformatf("BID MISMATCH: AWID=%0d BID=%0d addr=%0h",txn.awid,txn.bid,txn.awaddr))
        end
        else begin
          `uvm_info("SB",$sformatf("BID MATCH : AWID=%0d BID=%0d",txn.awid,txn.bid),UVM_LOW)
          end
           if(txn.bresp != 2'b00) begin
             `uvm_error("SB",$sformatf("BRESP ERROR:BID=%0d BRESP =%0d",txn.bid ,txn.bresp))
             end
              curr_addr = txn.awaddr;

      for(int i=0; i<txn.wdata_q.size(); i++) begin

        mem[curr_addr[9:2]] = txn.wdata_q[i];
        `uvm_info("SB",$sformatf("WRITE MEM id =%0d addr=%0h data=%0h",txn.awid,curr_addr,txn.wdata_q[i]),UVM_LOW)
        curr_addr = get_next_addr(curr_addr, txn.awlen,txn.awburst);
          end

    end

    //Read Transaction
    else begin
      if(txn.rid !== txn.arid) begin
          `uvm_error("SB",$sformatf("RID MISMATCH:ARID=%0d RID=%0d addr=%0h",txn.arid,txn.rid,txn.araddr))
          end
          else begin
              `uvm_info("SB",$sformatf("RID MATCH: ARID=%0d RID=%0d",txn.arid,txn.rid),UVM_LOW)
               end
               curr_addr = txn.araddr;

      for(int i=0; i<txn.rdata_q.size(); i++) begin

        exp_data = mem[curr_addr[9:2]];

        if(txn.rresp_q[i] != 2'b00) begin
            `uvm_error("SB",$sformatf("RRESP ERROR: RID =%0d beat =%0d RRESP=%0d",txn.rid,i+1,txn.rresp_q[i]))
            end
        if(txn.rdata_q[i] == exp_data) begin
              `uvm_info("SB",$sformatf("MATCH RID=%0d beat=%0d addr=%0h exp=%0h act=%0h",txn.rid,i+1,curr_addr,exp_data,txn.rdata_q[i]),UVM_LOW)
           end
           else begin
          `uvm_error("SB",$sformatf("MISMATCH RID=%0d beat=%0d addr=%0h exp=%0h act=%0h",txn.rid,i+1,curr_addr,exp_data,txn.rdata_q[i]))
          end
          curr_addr = get_next_addr(curr_addr,txn.arlen,txn.arburst);
      end

    end

  endfunction
  endclass*/
  `ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

`uvm_analysis_imp_decl(_aw)
`uvm_analysis_imp_decl(_w)
`uvm_analysis_imp_decl(_b)
`uvm_analysis_imp_decl(_ar)
`uvm_analysis_imp_decl(_r)

class axi_mem_model extends uvm_object;

  `uvm_object_utils(axi_mem_model)

  bit [31:0] mem [bit [31:0]];

  function new(string name = "axi_mem_model");
    super.new(name);
  endfunction

function void write_mem(bit [31:0] addr,
                          bit [31:0] data,
                          bit [3:0]  wstrb);

    if (!mem.exists(addr))
      mem[addr] = 32'h0;

    if (wstrb[0]) mem[addr][7:0]   = data[7:0];
    if (wstrb[1]) mem[addr][15:8]  = data[15:8];
    if (wstrb[2]) mem[addr][23:16] = data[23:16];
    if (wstrb[3]) mem[addr][31:24] = data[31:24];

  endfunction

 function bit [31:0] read_mem(bit [31:0] addr);

    if (mem.exists(addr))
      return mem[addr];
    else
      return 32'h0;

  endfunction

endclass

class scoreboard extends uvm_component;

  `uvm_component_utils(scoreboard)

  uvm_analysis_imp_aw #(axi_seq_item, scoreboard) aw_imp;
  uvm_analysis_imp_w  #(axi_seq_item, scoreboard) w_imp;
  uvm_analysis_imp_b  #(axi_seq_item, scoreboard) b_imp;
  uvm_analysis_imp_ar #(axi_seq_item, scoreboard) ar_imp;
  uvm_analysis_imp_r  #(axi_seq_item, scoreboard) r_imp;

  axi_mem_model mem_model;  

  axi_seq_item pending_aw_q[$];

  axi_seq_item exp_wr_q[int][$];
  axi_seq_item exp_rd_q[int][$];
  axi_seq_item pending_b_q[int][$];
  int rd_beat_count[int];
  
  function new(string name = "scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    aw_imp = new("aw_imp", this);
    w_imp  = new("w_imp",  this);
    b_imp  = new("b_imp",  this);
    ar_imp = new("ar_imp", this);
    r_imp  = new("r_imp",  this);

    mem_model = axi_mem_model::type_id::create("mem_model");

  endfunction

 function bit [31:0] get_next_addr(bit [31:0] addr,
                                    bit [1:0]  burst,
                                    bit [2:0]  size,
                                    bit [7:0]  len,
                                    bit [31:0] start_addr);

    bit [31:0] beat_bytes;
    bit [31:0] wrap_size;
    bit [31:0] wrap_base;
    bit [31:0] wrap_limit;
    bit [31:0] next_addr;

    beat_bytes = 1 << size;

    case (burst)

      2'b00: begin
        next_addr = addr;
      end

      2'b01: begin
        next_addr = addr + beat_bytes;
      end

      2'b10: begin
        wrap_size  = beat_bytes * (len + 1);
        wrap_base  = (start_addr / wrap_size) * wrap_size;
        wrap_limit = wrap_base + wrap_size;

        next_addr = addr + beat_bytes;

        if (next_addr >= wrap_limit)
          next_addr = wrap_base;
      end

      default: begin
        next_addr = addr;
      end

    endcase

    return next_addr;

  endfunction

 function void copy_axi_item(ref axi_seq_item dst,
                            input  axi_seq_item src);

  dst.write = src.write;
 // dst.read  = src.read;

  dst.awid    = src.awid;
  dst.awaddr  = src.awaddr;
  dst.awlen   = src.awlen;
  dst.awburst = src.awburst;
  dst.awsize  = src.awsize;

  dst.wid = src.wid;

  dst.arid    = src.arid;
  dst.araddr  = src.araddr;
  dst.arlen   = src.arlen;
  dst.arburst = src.arburst;
  dst.arsize  = src.arsize;

  dst.bid   = src.bid;
  dst.bresp = src.bresp;

  dst.rid       = src.rid;
 // dst.rresp_q     = src.rresp_q;
  dst.axi_rlast = src.axi_rlast;

  dst.wdata_q = src.wdata_q;
  dst.wstrb_q = src.wstrb_q;
  dst.rdata_q = src.rdata_q;
  dst.rresp_q = src.rresp_q;

endfunction

 function void write_aw(axi_seq_item txn);
 axi_seq_item aw_tr;
aw_tr = axi_seq_item::type_id::create("aw_tr");
    //aw_tr.copy(txn);
    copy_axi_item(aw_tr, txn);
 pending_aw_q.push_back(aw_tr);
 `uvm_info("AXI_SCB",$sformatf("AW Received AWID=%0d AWADDR=%0h AWLEN=%0d",txn.awid,txn.awaddr,txn.awlen),UVM_MEDIUM)
 endfunction

 function void write_w(axi_seq_item txn);
 axi_seq_item aw_tr;
    axi_seq_item exp_tr;
    bit [31:0] addr;
    bit [31:0] start_addr;
    if (pending_aw_q.size() == 0) begin
        `uvm_error("AXI_SCB","W data received but no pending aw transactions")
        return;
        end
        aw_tr=pending_aw_q.pop_front();
         exp_tr = axi_seq_item::type_id::create("exp_wr_tr");
   // exp_tr.copy(aw_tr);
   copy_axi_item(exp_tr, aw_tr);

    exp_tr.wdata_q = txn.wdata_q;
    exp_tr.wstrb_q = txn.wstrb_q;
    exp_tr.bresp = 2'b00;
    exp_tr.bid=aw_tr.awid;
     addr       = aw_tr.awaddr;
    start_addr = aw_tr.awaddr;

    foreach (txn.wdata_q[i]) begin

      mem_model.write_mem(addr,
                          txn.wdata_q[i],
                          txn.wstrb_q[i]);
      `uvm_info("AXI_SB",$sformatf("MEM WRITE:ID=%0d ADDR=%0h DATA=%0h WSTRB=%0h",aw_tr.awid,addr,txn.wdata_q[i],txn.wstrb_q[i]),UVM_HIGH)
       addr = get_next_addr(addr,
                           aw_tr.awburst,
                           aw_tr.awsize,
                           aw_tr.awlen,
                           start_addr);
    end

    exp_wr_q[aw_tr.awid].push_back(exp_tr);

    // Check if BRESP already arrived
    `uvm_info("AXI_SCB",$sformatf("WRITE EXPECTED STORED ID=%0d COUNT =%0d ",aw_tr.awid,exp_wr_q[aw_tr.awid].size()),UVM_LOW)

while (pending_b_q.exists(aw_tr.awid) &&
    pending_b_q[aw_tr.awid].size() > 0) begin

   axi_seq_item b_tr;

   b_tr = pending_b_q[aw_tr.awid].pop_front();
   `uvm_info("AXI_SCB",$sformatf("Replaying early BRESP for BID=%0d",b_tr.bid),UVM_LOW)

   write_b(b_tr);

end
   
    endfunction


/*function void write_b(axi_seq_item txn);

    axi_seq_item exp_tr;
    int id;

    id = txn.bid;
    if (!exp_wr_q.exists(id) || exp_wr_q[id].size() == 0) begin
        `uvm_error("AXI_SB",$sformatf("Unexpected BRESP received for BID=%0d",id))
        return;
        end
           exp_tr = exp_wr_q[id].pop_front();
           if (id != exp_tr.awid)
               `uvm_error("AXI_SCB",$sformatf("BID/AWID mismatch AWID=%0d BID=%0d",exp_tr.awid,id))
            if (txn.bresp !== exp_tr.bresp) begin
                `uvm_error("AXI_SB",$sformatf("BRESP MISMATCH BID=%0d EXP=%0h ACT=%0h ",
                id,exp_tr.bresp,txn.bresp))
                end
                else
                    begin
                    `uvm_info("AXI_SCB",$sformatf("WRITE RESPONSE PASS BID=%0d",id),UVM_MEDIUM)
                    end
                    endfunction*/
function void write_b(axi_seq_item txn);

   axi_seq_item exp_tr;
   axi_seq_item b_tr;
   int id;

   id = txn.bid;
 // BRESP arrived before expected write transaction
 if (!exp_wr_q.exists(id) || exp_wr_q[id].size() == 0) begin

      b_tr = axi_seq_item::type_id::create("b_tr");

      // Copy only required fields manually
      b_tr.bid   = txn.bid;
      b_tr.bresp = txn.bresp;
      b_tr.write = 1;

      pending_b_q[id].push_back(b_tr);
`uvm_info("AXI SCB",$sformatf("Early BRESP stored for BID=%0d",id),UVM_MEDIUM) 
return;
end
 // Expected write transaction exists
exp_tr = exp_wr_q[id].pop_front();
//Compare BID
 if(exp_tr.bid != txn.bid)
     `uvm_error("AXI_SCB",$sformatf("BID mismatch EXP=%0d ACT=%0d",exp_tr.bid,txn.bid))
     //Compare BRESP
     if(exp_tr.bresp != txn.bresp)
         `uvm_error("AXI_SCB",$sformatf("BRESP mismatch BID=%0d EXP=%0d ACT=%0d",txn.bid,exp_tr.bresp,txn.bresp))
         else
             `uvm_info("AXI_SCB",$sformatf("WRITE RESPONSE PASS BID=%0d BRESP=%0d",txn.bid,txn.bresp),UVM_LOW)
             endfunction
 

function void write_ar(axi_seq_item txn);


    axi_seq_item exp_tr;
    bit [31:0] addr;
    bit [31:0] start_addr;
    bit [31:0] exp_data;

    exp_tr = axi_seq_item::type_id::create("exp_rd_tr");
   // exp_tr.copy(txn);
     copy_axi_item(exp_tr, txn);
    exp_tr.rdata_q.delete();

    addr       = txn.araddr;
    start_addr = txn.araddr;

    for (int i = 0; i <= txn.arlen; i++) begin

      exp_data = mem_model.read_mem(addr);
      exp_tr.rdata_q.push_back(exp_data);
      `uvm_info("AXI_SB",$sformatf("Expected READ ARID =%0d ADDR =%0h DATA=%0h",txn.arid,addr,exp_data),UVM_HIGH)
      addr = get_next_addr(addr,
                           txn.arburst,
                           txn.arsize,
                           txn.arlen,
                           start_addr);
    end
     exp_rd_q[txn.arid].push_back(exp_tr);
`uvm_info("AXI_SCB",$sformatf("Expected read burst stored for ARID=%0d BEATS=%0d",txn.arid,txn.arlen+1),UVM_MEDIUM)

     endfunction
function void write_r(axi_seq_item txn);

    axi_seq_item exp_tr;
    bit [31:0] exp_data;
    bit[31:0] act_data;
    int id;

    id = txn.rid;

      if (!exp_rd_q.exists(id) || exp_rd_q[id].size() == 0) begin
          `uvm_error("AXI_SCB",$sformatf("Unexpected RDATA received for RID =%0d",id))
          return;
          end
           exp_tr = exp_rd_q[id].pop_front();
           if (id != exp_tr.arid)
               `uvm_error("AXI SCB",$sformatf("RID/ARID MISMATCH ARID=%0d RID=%0d ",exp_tr.arid,id))
                /* if (!rd_beat_count.exists(id))
                   rd_beat_count[id] = 0;
                   rd_beat_count[id]++;
                   act_data = txn.rdata_q.pop_front();
            if (exp_tr.rdata_q.size() == 0) begin
                `uvm_error("AXI_SB",$sformatf("Extra RDATA received for RID =%0d DATA=%0h",id,act_data))
                return;
                end
                 exp_data = exp_tr.rdata_q.pop_front();

    if (act_data !== exp_data) begin
        `uvm_error("AXI_SB",$sformatf("RDATA Mismatch RID=%0d BEAT=%0d EXP=%0h ACT=%0h",id,rd_beat_count[id],exp_data,act_data))
        end
        else begin
       `uvm_info("AXI_SB",$sformatf("RADATA PASS RID =%0d BEAT=%0d DATA=%0h",id,rd_beat_count[id],act_data),UVM_MEDIUM)

            end

        exp_rd_q[id][0] = exp_tr;*/
 if (txn.rdata_q.size() != exp_tr.rdata_q.size()) 
     begin
     `uvm_error("AXI_SCB",$sformatf("READ BEAT COUNT MISMATCH RID=%0d EXP=%0d ACT=%0d ",id,exp_tr.rdata_q.size(),txn.rdata_q.size()))
     end
      for (int i = 0; i < txn.rdata_q.size(); i++) begin

    exp_data = exp_tr.rdata_q[i];
    act_data = txn.rdata_q[i];

    if (act_data !== exp_data) 
        begin
        `uvm_error("AXI_SCB",$sformatf("RDATA MISMATCH RID=%0d BEAT =%0d EXP=%0h ACT=%0h ",id,i+1,exp_data,act_data))
        end
else begin
    `uvm_info("AXI_SB",$sformatf("RDATA PASS RID=%0d BEAT=%0d DATA=%0h",id,i+1,act_data),UVM_MEDIUM)
    end
    end

   /* if (txn.axi_rlast) begin
          if (exp_tr.rdata_q.size() != 0) begin
              `uvm_error("AXI_SCB",$sformatf("RLAST came early for RID =%0d Remaining beats=%0d",id,exp_tr.rdata_q.size()))
              end
              else begin
                  void'(exp_rd_q[id].pop_front());
                  `uvm_info("AXI_SCB",$sformatf("READ BURST PASS RID=%0d",id),UVM_MEDIUM)
                  end
                  end
                  else begin
                    if (exp_tr.rdata_q.size() == 0) begin
                        `uvm_error("AXI SB",$sformatf("RLAST missing for RID=%0d ",id))
                        end
                        end
                        endfunction*/
                         if (!txn.axi_rlast) 
                             begin
                             `uvm_error("AXI SB",$sformatf("RLAST missing for RID=%0d ",id))
                             end
                             else begin
                              `uvm_info("AXI_SCB",$sformatf("READ BURST PASS RID=%0d",id),UVM_MEDIUM)
                                 end
                                 endfunction



function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    foreach (exp_wr_q[id]) begin
      if (exp_wr_q[id].size() != 0) begin
 `uvm_error("AXI_SCB",$sformatf("Pending Write Response left for ID=%0d COUNT=%0d ",id,exp_wr_q[id].size()))
          end
          end
 foreach (exp_rd_q[id]) begin
      if (exp_rd_q[id].size() != 0) begin
          `uvm_error ("AXI_SB",$sformatf("Pending READ RESPONSES left for ID=%0d COUNT=%0d",id,exp_rd_q[id].size()))
          end
          end
          endfunction
          endclass
          `endif
          
  


 










