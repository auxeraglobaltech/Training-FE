class axi_slave_mem_model extends uvm_component;
`uvm_component_utils(axi_slave_mem_model)
virtual axiif vif;
bit [31:0] mem [0:255];
/*function bit [31:0] get_next_addr(
  bit [31:0] curr_addr,
  bit [7:0]  len,
  bit [1:0]  burst
);

  bit [31:0] wrap_size;
  bit [31:0] wrap_base;
  bit [31:0] wrap_limit;
  bit [31:0] next_addr;

  case(burst)

    // FIXED
    2'b00: begin
      get_next_addr = curr_addr;
    end

    // INCR
    2'b01: begin
      get_next_addr = curr_addr + 4;
    end

    // WRAP
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

    default: begin
      get_next_addr = curr_addr;
    end

  endcase

endfunction*/
function new(string name,uvm_component parent);
    super.new(name,parent);
 endfunction
 function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axiif)::get(this,"","vif",vif))
        begin
          `uvm_fatal("MEM Model","Unable to get vif")
        end
        endfunction
 task run_phase(uvm_phase phase);
   
    fork
      write_memory();
      read_memory();
    join

  endtask

    task write_memory();

  forever begin

    @(posedge vif.axi_aclk);

    if(vif.slave_wren) begin

      mem[vif.slave_waddr[9:2]] = vif.slave_wdata;
      `uvm_info("MEM MODEL",$sformatf("Write Mem[%0h]=%0h",vif.slave_waddr,vif.slave_wdata),UVM_LOW)

         end

  end

endtask
     task read_memory();

  forever begin

    @(negedge vif.axi_aclk);

    if(!vif.axi_areset_n) begin
      vif.slave_rdata = 32'd0;
    end
      else begin
  if (vif.slave_raddr[9:2] inside {[0:255]})
    vif.slave_rdata = mem[vif.slave_raddr[9:2]];
  else
    vif.slave_rdata = 32'd0;
end

    if(vif.slave_rden) 
      begin
      `uvm_info("MEM Model",$sformatf("Read Mem[%0h]=%0h",vif.slave_raddr,mem[vif.slave_raddr[9:2]]),UVM_LOW)
      end
      end
      endtask 
      

  endclass

      

    

   


