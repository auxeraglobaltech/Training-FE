/*****************************************************************
File name:axi4_master_scoreboard.sv
Description:This module checks the functionality of the DUT. 
It receives transactions from the monitor using the analysis port
*****************************************************************/
`uvm_analysis_imp_decl (_con1)

class axi4_master_scoreboard extends uvm_scoreboard;
  
  //factory registration
  `uvm_component_utils(axi4_master_scoreboard) 
  
   //Declare TLM Analysis port : to receive transactions from Monitor
   uvm_analysis_imp_con1 #(axi4_master_seq_item,axi4_master_scoreboard) sb_port_con1; 
   
   axi4_master_seq_item queue_seq_item_inst[$]; //queue handle
   axi4_master_seq_item sb_seq_item_inst;       //sb handle
   axi4_master_seq_item seq_item_inst;          //seq_item handle

   //**************WRITE FSM STATES*****************/
   localparam WIDL  = 3'b000;
   localparam WADR  = 3'b001;
   localparam WDTA  = 3'b010;
   localparam WWAIT = 3'b011;
   localparam WDLY  = 3'b100;	
   localparam BRSP  = 3'b101;

   //**************READ FSM STATES*****************/
   localparam RIDL = 3'b000;
   localparam RADR = 3'b001;
   localparam RDLY = 3'b010;
   localparam RDTA = 3'b011;
   localparam RRSP = 3'b100;

   //*******SLAVE DEVICE ID & WAIT TIMER***********/
   localparam SLAVE_ID   = 4'b0011;
   localparam WAIT_TIMER = 8'd200;

   //**************INTERNAL REGISTERS**************/
   //reg
   bit [2:0] sb_wstate;
   bit [2:0] sb_wnextstate;

   //reg
   reg [7:0] sb_w_beat_cnt;
   reg [7:0] sb_w_wait_timer;
   reg       sb_w_timeout;
   reg       sb_w_burst_actv;
  
   bit [2:0] sb_rstate;
   bit [2:0] sb_rnextstate;


  //constructor
  function new (string name = "axi4_master_scoreboard", uvm_component parent = null);
    super.new (name, parent);
  endfunction
  
  //build_phase
  function void build_phase (uvm_phase phase);
  super.build_phase(phase);
    sb_port_con1	 = new("sb_port_con1", this);
    sb_seq_item_inst = axi4_master_seq_item::type_id::create("sb_seq_item_inst");
  endfunction

 /**************************************************************************************************/
  /*                             COMPARE FUNCTION : SCOREBOARD VS RTL                               */
  /**************************************************************************************************/
  function void compare(logic [31:0] sb_data, logic [31:0] rtl_data, string label);
    if(sb_data === rtl_data)
      `uvm_info("SCOREBOARD PASS",$sformatf("signal : %0s, scoreboard : %0h, rtl : %0h", label, sb_data, rtl_data), UVM_MEDIUM)
    else
        `uvm_error("SCOREBOARD FAIL",$sformatf("signal : %0s, scoreboard : %0h, rtl : %0h", label, sb_data, rtl_data))
  endfunction

  /**************************************************************************************************/
  /*                                        WRITE FUNCTION                                          */
  /**************************************************************************************************/
  //write function
  virtual function void write_con1 (input axi4_master_seq_item seq_item_inst);  
    `uvm_info("Scoreboard", $sformatf("Inside write function"), UVM_LOW)
      queue_seq_item_inst.push_back(seq_item_inst);
   endfunction

  //run phase  
  task run_phase(uvm_phase phase);

  forever
    begin
      //wait untill queue gets the data
      wait(queue_seq_item_inst.size()> 0);

      //collect the data from queue to seq_item_inst
      seq_item_inst = queue_seq_item_inst.pop_front();

    //seq_item_inst.print();
    //sb_seq_item_inst.print();
    if(!seq_item_inst.axi_areset_n) begin                                       // During reset assert condition
        sb_seq_item_inst.axi_awaddr     = 32'b00000000000000000000000000000000;
        sb_seq_item_inst.axi_awvalid    = 1'b0;
        sb_seq_item_inst.axi_awid       = 4'b0000;
        sb_seq_item_inst.axi_awlen      = 8'b00000000;
        sb_seq_item_inst.axi_awburst    = 2'b00;

        sb_seq_item_inst.axi_wdata     = 32'b00000000000000000000000000000000;
        sb_seq_item_inst.axi_wvalid    = 1'b0;
        sb_seq_item_inst.axi_wid       = 4'b0000;
        sb_seq_item_inst.axi_wlast     = 1'b0;
        sb_seq_item_inst.axi_wstrb     = 4'b0000;

        sb_seq_item_inst.axi_bready    = 1'b0;

        sb_seq_item_inst.axi_araddr    = 32'b00000000000000000000000000000000;
        sb_seq_item_inst.axi_arvalid   = 1'b0;
        sb_seq_item_inst.axi_arid      = 4'b0000;
        sb_seq_item_inst.axi_arlen     = 8'b00000000;
        sb_seq_item_inst.axi_arburst   = 2'b00;
            
        sb_seq_item_inst.master_rdata  = 32'b00000000000000000000000000000000;
        sb_seq_item_inst.axi_rready    = 1'b0;

        sb_w_beat_cnt                  = 8'b00000000;
        sb_w_wait_timer                = 8'b00000000;
        sb_w_timeout                   = 1'b0;
        sb_w_burst_actv                = 1'b0;
        sb_wstate                      = WIDL;
        sb_rstate                      = RIDL;

    end
//
    else if(seq_item_inst.axi_areset_n) begin                                   //During reset de-assert condition 
    
    case(sb_wstate)
        WIDL    :   begin
                        sb_wnextstate = (seq_item_inst.master_wren) ? WADR : WIDL;      
			        end

		WADR    :   begin
                        sb_wnextstate = (seq_item_inst.axi_awready) ? WDTA : WADR;
			        end

                    
		WDTA    :   begin
                        sb_wnextstate = (seq_item_inst.axi_wlast && seq_item_inst.axi_wready) ? WDLY : ((!seq_item_inst.axi_wready && sb_w_beat_cnt != 0 && sb_w_burst_actv) ? WWAIT : WDTA); 
                    end


		WWAIT   :   begin
                        sb_wnextstate = (seq_item_inst.axi_wready && sb_w_burst_actv) ? WDTA : ((sb_w_timeout) ? WIDL : WWAIT);
			        end


		WDLY    :   begin
                        sb_wnextstate = (seq_item_inst.axi_bvalid && (seq_item_inst.axi_bid == SLAVE_ID)) ? BRSP : WDLY;
			        end		

        BRSP    :   begin
                        sb_wnextstate = (seq_item_inst.axi_bready) ? WIDL : BRSP;
			        end


	    default :   begin
				        sb_wnextstate = WIDL;
		            end
    endcase

    sb_wstate <= sb_wnextstate;
    
    sb_w_beat_cnt = ((sb_wstate == WDTA) && (seq_item_inst.axi_wready)) ? (sb_w_beat_cnt + 8'd1) : ((sb_wstate == WWAIT) ? sb_w_beat_cnt : 8'b0);
    
    sb_w_burst_actv = ((sb_wstate != WIDL) && (sb_w_beat_cnt <= (seq_item_inst.master_wlen)));

    sb_w_wait_timer = (sb_wstate == WWAIT) ? (sb_w_wait_timer + 8'd1) : 8'b0;

    sb_w_timeout = (sb_w_wait_timer == WAIT_TIMER) ? 1'b1 : 1'b0;	

    sb_seq_item_inst.axi_awlen      = (sb_wstate != WIDL) ? seq_item_inst.master_wlen : 8'b0;
    sb_seq_item_inst.axi_awburst    = (sb_wstate != WIDL) ? seq_item_inst.master_wburst : 2'b0;
    sb_seq_item_inst.axi_awaddr     = (sb_wstate != WIDL) ? seq_item_inst.master_waddr : 32'b0;
    sb_seq_item_inst.axi_awvalid    = (sb_wstate == WADR) ? 1'b1 : 1'b0;
    sb_seq_item_inst.axi_awid       = (sb_wstate == WADR) ? seq_item_inst.master_wid : 4'b0;   
    
//     
    sb_seq_item_inst.axi_wid        = (sb_wstate == WDTA) ? seq_item_inst.master_wid : 4'b0;
    sb_seq_item_inst.axi_wstrb      = (sb_wstate == WDTA) ? seq_item_inst.master_wstrb : 4'b0;
    
    sb_seq_item_inst.axi_wdata      <= (sb_wstate == WDTA) ? seq_item_inst.master_wdata : 32'b0;
    sb_seq_item_inst.axi_wlast      <= (sb_wstate == WDTA) && (sb_w_beat_cnt == sb_seq_item_inst.axi_awlen);
    sb_seq_item_inst.axi_wvalid     <= (sb_wstate == WDTA) ? 1'b1 : 1'b0;
//
    sb_seq_item_inst.axi_bready     = ((sb_wstate == BRSP) && seq_item_inst.axi_bvalid) ? 1'b1 : 1'b0;


/***************************************************************************************************************/
 /*                     COMPARISON OF WRITE ADDRESS CHANNEL SCOREBOARD VS RTL SIGNALS                           */
 /***************************************************************************************************************/                
//
    compare(.sb_data(sb_seq_item_inst.axi_awaddr), .rtl_data(seq_item_inst.axi_awaddr), .label("AXI AW_ADDR"));     // AXI_WRITE_ADDRESS
    compare(.sb_data(sb_seq_item_inst.axi_awvalid), .rtl_data(seq_item_inst.axi_awvalid), .label("AXI AW_VALID"));  // AXI_WRITE_ADDRESS_VALID
    compare(.sb_data(sb_seq_item_inst.axi_awid), .rtl_data(seq_item_inst.axi_awid), .label("AXI AW_ID"));           // AXI_WRITE_ADDRESS_ID
    compare(.sb_data(sb_seq_item_inst.axi_awlen), .rtl_data(seq_item_inst.axi_awlen), .label("AXI AW_LENGTH"));     // AXI_WRITE_LENGTH
    compare(.sb_data(sb_seq_item_inst.axi_awburst), .rtl_data(seq_item_inst.axi_awburst), .label("AXI AW_BURST"));  // AXI_WRITE_BURST
//
/****************************************************************************************************************/

 /***************************************************************************************************************/
 /*                         COMPARISON OF WRITE DATA CHANNEL SCOREBOARD VS RTL SIGNALS                          */
 /***************************************************************************************************************/                
//    
    compare(.sb_data(sb_seq_item_inst.axi_wdata), .rtl_data(seq_item_inst.axi_wdata), .label("AXI W_DATA"));        // AXI_WRITE_DATA
    compare(.sb_data(sb_seq_item_inst.axi_wvalid), .rtl_data(seq_item_inst.axi_wvalid), .label("AXI W_VALID"));     // AXI_WRITE_DATA_VALID
    compare(.sb_data(sb_seq_item_inst.axi_wid), .rtl_data(seq_item_inst.axi_wid), .label("AXI W_ID"));              // AXI_WRITE_DATA_ID
    compare(.sb_data(sb_seq_item_inst.axi_wlast), .rtl_data(seq_item_inst.axi_wlast), .label("AXI W_LAST"));        // AXI_WRITE_DATA_LAST BEAT
    compare(.sb_data(sb_seq_item_inst.axi_wstrb), .rtl_data(seq_item_inst.axi_wstrb), .label("AXI W_STROBE"));      // AXI_WRITE_STROBE
//
/****************************************************************************************************************/

 /***************************************************************************************************************/
 /*                        COMPARISON OF WRITE RESPONSE CHANNEL SCOREBOARD VS RTL SIGNAL                        */
 /***************************************************************************************************************/                
    compare(.sb_data(sb_seq_item_inst.axi_bready), .rtl_data(seq_item_inst.axi_bready), .label("AXI B_READY"));     // AXI_WRITE_RESPONSE_READY
/****************************************************************************************************************/
    case(sb_rstate)
        RIDL    :   begin
                        sb_rnextstate = (seq_item_inst.master_rden) ? RADR : RIDL;      
			        end

		RADR    :   begin
                        sb_rnextstate = (seq_item_inst.axi_arready) ? RDLY : RADR;
			        end
                    
		RDLY    :   begin
                        sb_rnextstate = (seq_item_inst.axi_rvalid && (seq_item_inst.axi_rid == SLAVE_ID)) ? RDTA : RDLY;
                    end

		RDTA   :   begin
                        sb_rnextstate = (seq_item_inst.axi_rlast) ? RRSP : RDTA;
			        end

        RRSP    :   begin
                        sb_rnextstate = RIDL;
			        end

	    default :   begin
				        sb_rnextstate = RIDL;
		            end
    endcase
    
    sb_rstate <= sb_rnextstate;    

    sb_seq_item_inst.axi_arid   = (sb_rstate == RADR) ? seq_item_inst.master_rid : 4'b0;  

    sb_seq_item_inst.axi_arlen      = (sb_rstate == RADR) ? seq_item_inst.master_rlen : 8'b0;
    sb_seq_item_inst.axi_arburst    = (sb_rstate == RADR) ? seq_item_inst.master_rburst : 2'b0;
    sb_seq_item_inst.axi_araddr     = (sb_rstate == RADR) ? seq_item_inst.master_raddr : 32'b0;

    sb_seq_item_inst.axi_arvalid    = (sb_rstate == RADR) ? 1'b1 : 1'b0;    
//
    sb_seq_item_inst.axi_rready     = ((sb_rstate == RDTA) && seq_item_inst.axi_rvalid) ? 1'b1 : 1'b0;

    sb_seq_item_inst.master_rdata   <= (seq_item_inst.axi_rvalid && sb_seq_item_inst.axi_rready) ? seq_item_inst.axi_rdata : sb_seq_item_inst.master_rdata;


 /***************************************************************************************************************/
 /*                     COMPARISON OF READ ADDRESS CHANNEL SCOREBOARD VS RTL SIGNALS                            */
 /***************************************************************************************************************/                
    compare(.sb_data(sb_seq_item_inst.axi_araddr), .rtl_data(seq_item_inst.axi_araddr), .label("AXI AR_ADDR"));     // AXI_READ_ADDRESS
    compare(.sb_data(sb_seq_item_inst.axi_arvalid), .rtl_data(seq_item_inst.axi_arvalid), .label("AXI AR_VALID"));  // AXI_READ_ADDRESS_VALID
    compare(.sb_data(sb_seq_item_inst.axi_arid), .rtl_data(seq_item_inst.axi_arid), .label("AXI AR_ID"));           // AXI_READ_ADDRESS_ID
    compare(.sb_data(sb_seq_item_inst.axi_arlen), .rtl_data(seq_item_inst.axi_arlen), .label("AXI AR_LENGTH"));     // AXI_READ_LENGTH
    compare(.sb_data(sb_seq_item_inst.axi_arburst), .rtl_data(seq_item_inst.axi_arburst), .label("AXI AR_BURST"));  // AXI_READ_BURST
/****************************************************************************************************************/
   
 /***************************************************************************************************************/
 /*                        COMPARISON OF READ DATA & RESPONSE CHANNEL SCOREBOARD VS RTL SIGNAL                  */
 /***************************************************************************************************************/                
   compare(.sb_data(sb_seq_item_inst.master_rdata), .rtl_data(seq_item_inst.master_rdata), .label("MASTER RDATA")); // AXI_READ_DATA
   compare(.sb_data(sb_seq_item_inst.axi_rready), .rtl_data(seq_item_inst.axi_rready), .label("AXI R_READY"));      // AXI_READ_RESPONSE_READY
/****************************************************************************************************************/
   //endfunction
   end
   end
   endtask

  
endclass
