class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
   uvm_analysis_imp #(axi_seq_item,scoreboard) imp;
   //virtual abpif vif;
   bit [31:0] mem[0:255];
   function new(string name="scoreboard",uvm_component parent);
     super.new(name,parent);
       imp=new("imp",this);
   endfunction
    function void build_phase(uvm_phase phase);
     super.build_phase(phase);
    endfunction
    //Address calculation
    function bit [31:0] get_next_addr(
    bit [31:0] curr_addr,
    bit [7:0] len,
    bit [1:0] burst
  );
    bit [31:0] wrap_size;
    bit [31:0] wrap_base;
    bit [31:0] wrap_limit;
    bit [31:0] next_addr;
 case(burst)

      // FIXED
      2'b00:
        get_next_addr = curr_addr;

      // INCR
      2'b01:
        get_next_addr = curr_addr + 4;

      // WRAP
      2'b10: begin

        wrap_size  = (len + 1)*4;
        wrap_base  = (curr_addr/wrap_size)*wrap_size;
        wrap_limit = wrap_base + wrap_size;
        next_addr  = curr_addr + 4;

        if(next_addr == wrap_limit)
          get_next_addr = wrap_base;
        else
          get_next_addr = next_addr;
      end

      default:
        get_next_addr = curr_addr;

    endcase

  endfunction
    
  function void write(axi_seq_item txn);
    //scoreboard logic
    bit [31:0] curr_addr;
    bit [31:0] exp_data;

    curr_addr = txn.write ?
                txn.awaddr :
                txn.araddr;

    //------------------------------------
    // WRITE TRANSACTION
    //------------------------------------
    if(txn.write) begin

      for(int i=0;i<txn.wdata_q.size();i++) begin

        mem[curr_addr[9:2]] = txn.wdata_q[i];
        `uvm_info("SB",$sformatf("WRITE MEM[%0h]=%0h",curr_addr,txn.wdata_q[i]),UVM_LOW)
        curr_addr = get_next_addr(curr_addr,txn.awlen,txn.awburst);
      end
    end
    //READ TRANSACTION
    else begin

      for(int i=0;i<txn.rdata_q.size();i++) begin

        exp_data = mem[curr_addr[9:2]];

        if(txn.rdata_q[i] == exp_data)
          `uvm_info("SB",$sformatf("MATCH Beat=%0d addr=%0h exp=%0h act=%0h",i+1,curr_addr,exp_data,txn.rdata_q[i]),UVM_LOW)
        else
            `uvm_error("SB",$sformatf("MISMATCH beat =%0d addr=%0h exp=%0h act=%0h",i+1,curr_addr,exp_data,txn.rdata_q[i]))
        curr_addr = get_next_addr(curr_addr,txn.arlen,txn.arburst);
end

    end
        
     endfunction
   
 endclass
 
