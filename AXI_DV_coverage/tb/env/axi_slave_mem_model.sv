class axi_slave_mem_model extends uvm_component;
`uvm_component_utils(axi_slave_mem_model)
virtual axiif vif;
bit [31:0] mem [0:255];
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

endfunction
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
    //Write Backend Model
   task write_memory();

    bit [31:0] curr_addr;
    int burst_len;

    forever begin
    //Wait for AW handshake
   @(posedge vif.axi_aclk iff
       (vif.axi_awvalid &&
        vif.axi_awready));

   curr_addr =vif.axi_awaddr;

   burst_len =vif.axi_awlen + 1;
   `uvm_info("MEM_MODEL ",$sformatf("Write Burst start addr=%0h beats=%0d",curr_addr,burst_len),UVM_LOW)
   //Receive W burst
    for(int i=0;i<burst_len;i++) 
        begin
        @(posedge vif.axi_aclk iff
         (vif.axi_wvalid &&
          vif.axi_wready));
        //Store data
        mem[curr_addr[9:2]]= vif.axi_wdata;
        `uvm_info("MEM Model",$sformatf("Write Mem[%0h]=%0h",curr_addr,vif.axi_wdata),UVM_LOW)
        //Increment address
       curr_addr = get_next_addr(
                    curr_addr,
                    vif.axi_awlen,
                    vif.axi_awburst);
       end

    end

 endtask
        
   /* task read_memory();

  forever begin

    @(negedge vif.axi_aclk);

    if(!vif.axi_areset_n) begin
      vif.slave_rdata = 32'd0;
    end
    else begin
      vif.slave_rdata = mem[vif.slave_raddr[9:2]];
    end

    if(vif.axi_rvalid && vif.axi_rready) begin
      `uvm_info("MEM Model",$sformatf("Read Mem[%0h]=%0h",vif.slave_raddr,mem[vif.slave_raddr[9:2]]),UVM_LOW)
      end
      end
      endtask*/
task read_memory();

  bit [31:0] curr_addr;
  int burst_len;

  forever begin

    @(posedge vif.axi_aclk iff
      (vif.axi_arvalid && vif.axi_arready));

    curr_addr = vif.axi_araddr;
    burst_len = vif.axi_arlen + 1;
    `uvm_info("MEM_MODEL ",$sformatf("Read Burst start addr=%0h beats=%0d",curr_addr,burst_len),UVM_LOW)
for(int i = 0; i < burst_len; i++) begin
       @(negedge vif.axi_aclk);
      vif.slave_rdata <= mem[curr_addr[9:2]];
      `uvm_info("MEM Model",$sformatf("Read Mem[%0h]=%0h",curr_addr,mem[curr_addr[9:2]]),UVM_LOW)
 @(posedge vif.axi_aclk iff
        (vif.axi_rvalid && vif.axi_rready));

      curr_addr = get_next_addr(
                    curr_addr,
                    vif.axi_arlen,
                    vif.axi_arburst);
  
  end

  end

endtask      


  endclass

      

    

   


