`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Design Name: 	
// Module Name:    		AXI_Slave_Block2 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 1st revision
// Revision 1.1 - File Created
//			1.2 - Bug Fixes
//			1.3 - Bug Fixes
//
//////////////////////////////////////////////////////////////////////////////////
module axi_slave #(parameter DATA_WIDTH = 32, parameter ADDRESS_WIDTH = 32, parameter WAIT_TIMER = 200, parameter SLAVE_ID = 4'b0011)
			 			(
					///////GLOBAL SIGNALS/////////////// 
			input 								axi_aclk, 
			input 								axi_areset_n, 

					//////WRITE ADDRESS CHANNEL///////// 
			input 				[ADDRESS_WIDTH-1:0] 		axi_awaddr,
			input 								axi_awvalid,
			output 								axi_awready,
			input 				[3:0] 				axi_awid,
			input 				[7:0] 				axi_awlen,
			input 				[1:0] 				axi_awburst,			

					//////WRITE DATA CHANNEL////////////
			input 				[DATA_WIDTH-1:0] 		axi_wdata,
			input 								axi_wvalid, 
			output 								axi_wready, 
			input 				[3:0] 				axi_wid,
			input 								axi_wlast,
			input 				[(DATA_WIDTH>>3)-1:0] 		axi_wstrb,

					//////WRITE RESPONSE CHANNEL////////
			output 				[1:0] 				axi_bresp,
			output 								axi_bvalid,
			input 								axi_bready,
			output 				[3:0] 				axi_bid,

					//////READ ADDRESS CHANNEL//////////
			input 				[ADDRESS_WIDTH-1:0]		axi_araddr,
			input 								axi_arvalid,
			output 								axi_arready,
			input 				[3:0] 				axi_arid,
			input 				[7:0] 				axi_arlen,
			input 				[1:0] 				axi_arburst,

					//////READ DATA CHANNEL////////////
			output 				[DATA_WIDTH-1:0] 		axi_rdata,
			output 								axi_rvalid,
			input 								axi_rready,
			output 				[3:0] 				axi_rid, 	
			output 								axi_rlast,
			output 				[1:0] 				axi_rresp,

					////// SLAVE TO MEMORY OUTPUTS//
			output 								slave_wren,
			output 				[31:0]				slave_waddr,
			output 				[31:0]				slave_wdata,

			output 								slave_rden,
			output 				[31:0]				slave_raddr,
			input 				[31:0]				slave_rdata 
						);

	////////STATE PARAMETERS/////////////
	//WRITE OPERATION////
	localparam WIDL = 3'b000;
	localparam WADR = 3'b001; 
	//localparam awzr = 3'b010;
	localparam WDTA = 3'b010;
	localparam WWAIT = 3'b011;
	localparam BRSP = 3'b100;

	//READ OPERATION////
	localparam RIDL = 3'b000;
	localparam RADR = 3'b001;
	localparam RWAIT = 3'b010;
	localparam RDTA = 3'b011;
	localparam RRSP = 3'b100;
	//localparam rzro = 3'b10;
	//localparam rwai = 3'b100;


	/////////RESPONSE STATES/////
	reg [2:0]wstate;	   // 
	reg [2:0]wnextstate;       // 
	/////////READ STATES/////////
	reg [2:0] rstate;	   //
	reg [2:0] rnextstate;	   //
	/////////////////////////////





///////////////////////// SLAVE REGISTERS////////////////////////////
//-- HANDSHAKING OUTPUT REGISTERS-------
//reg [1:0] bresp_reg;
reg rvalid_reg;

//----ADDRESS REGISTERS------------
reg [ADDRESS_WIDTH-1:0] strt_araddr_reg; //reqd for wrap burst
reg [ADDRESS_WIDTH-1:0] strt_awaddr_reg;//reqd for wrap burst

reg [ADDRESS_WIDTH-1:0] i_araddr_reg; 					
reg [ADDRESS_WIDTH-1:0] i_awaddr_reg; 

reg [ADDRESS_WIDTH-1:0] awaddr_reg; 					
reg [ADDRESS_WIDTH-1:0] araddr_reg;						
//--- CONTROL SIGNAL REGISTERS---------
reg [7:0] awlen_reg;
reg [1:0] awburst_reg;
reg [7:0] s_awlen;

reg [7:0] arlen_reg;
reg [1:0] arburst_reg;

//---- DATA REGISTERS------------
reg [DATA_WIDTH-1:0] WR_reg;						
//reg [DATA_WIDTH-1:0] RD_reg;							


//----- OUTPUT REGISTERS ----------------
reg [DATA_WIDTH-1:0] rdata_reg_out;
//reg [DATA_WIDTH-1:0] axi_rdata_reg;
reg  [1:0] bresp_reg_out;
reg [3:0] bid_reg_out;
reg [3:0] rid_reg_out;

//--------- INTERNAL CONTROL SIGNALS-------------
//integer byte_addr;	//not used						
integer w_beat_cnt;							
wire w_burst_actv;							
integer w_wait_timer;
						
wire w_timeout; 							

integer r_beat_cnt;
reg [31:0] wrap_size;
reg [ADDRESS_WIDTH-1:0] wrap_base;
reg [ADDRESS_WIDTH-1:0] wrap_limit;
reg [ADDRESS_WIDTH-1:0] next_addr;

//integer rvalid_cnt ;	

wire [DATA_WIDTH-1:0] WR_wire; 					

//-- RVALID EDGE DETECTION SIGNAL-----------------------------
//reg rvalid_edge_dly;			
//wire rvalid_edge_op;			

//----- WREADY DELAY SIGNAL FOR ENABLE ----------------
reg wready_delay;

reg axi_wlast_delay;
//reg axi_bready_delay;

////
/*reg axi_awvalid_reg;

always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n) 
	axi_awvalid_reg <= 1'b0;
	else 
	axi_awvalid_reg <= axi_awvalid;
end	*/
/////////////////////////////////////////////////////////////////////////////////////// WRITE HANDSHAKING FSM ////////////////////////////////////////////////////////////////////

//WRITE PRESENT STATE LOGIC (SEQUENTIAL)
always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n) 
	wstate <= WIDL;
	else 
	wstate <= wnextstate;
end

// WRITE NEXT STATE LOGIC (combinational)
always @(*)
begin
	
	case(wstate)
/*0*/	WIDL:	begin
				if ((axi_awvalid) && (axi_awid == SLAVE_ID))
				wnextstate = WADR;									
				else 
				wnextstate = WIDL;									
				end
/*1*/	WADR:	begin											
				if ((axi_wvalid /*axi_awvalid_reg*/) && (axi_wid == SLAVE_ID))	
				wnextstate = WDTA;
				else 											
				wnextstate = WADR;
				end
/*2*/	WDTA:	begin												
				if (/*axi_wlast*/ axi_wlast_delay)										
				wnextstate = BRSP;
				else if (w_burst_actv && !axi_wvalid)
				wnextstate = WWAIT;
				else
				wnextstate = WDTA;
				end
/*3*/	WWAIT:	begin 
				if (axi_wvalid && w_burst_actv)
				wnextstate = WDTA;
				else if (w_timeout)
				wnextstate = WIDL;
				else 
				wnextstate = WWAIT;
				end
		
/*4*/	BRSP:	begin											
				if (axi_bready /*axi_bready_delay*/)									
				wnextstate = WIDL;								
				else 
				wnextstate = BRSP;								
				end
	
	
	default :	begin
				wnextstate = WIDL;
				end
	endcase
end
// WRITE OUTPUT LOGIC (COMBINATIONAL LOGIC)
assign axi_awready = ((wstate == WADR) /* && (wstate != WDTA)*/ && axi_awvalid /*axi_awvalid_reg*/);
assign axi_wready = ((wstate == WDTA) /* && (wstate != BRSP)*/ && axi_wvalid);
assign axi_bvalid = ((wstate == BRSP)); 

////

//----------- WRITE BURST PROGRESS SIGNAL-----------------------------
assign w_burst_actv = ((wstate != WIDL) && (w_beat_cnt <= (s_awlen-1'd1)));


//////////////////////////////////////////////////////////////////////////////////

always@(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
	axi_wlast_delay <= 1'b0;
	else 
	axi_wlast_delay <= axi_wlast;
end
	
///////
/*always@(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
	axi_bready_delay <= 1'b0;
	else 
	axi_bready_delay <= axi_bready;
end	*/

///////////////////////////// WRITE CHANNEL LATCHING //////////////
//------WRITE START ADDRESS LATCHING----------------------WRITE CONTROL SIGNAL REGISTERING---------
always @(posedge axi_aclk or negedge axi_areset_n)
	begin 
		if (!axi_areset_n)
		begin
			//strt_awaddr_reg <= {ADDRESS_WIDTH{1'b0}};
			awlen_reg <= 8'd0;
			awburst_reg <= 2'd0;
			i_awaddr_reg <= {ADDRESS_WIDTH{1'b0}};
			
		end 
		//else 
	//	begin 
    else if (axi_awvalid && axi_awready) begin
		  // if(wstate == WADR)
		    //  begin
			//strt_awaddr_reg <= axi_awaddr;
	 		awlen_reg <= axi_awlen;
			awburst_reg <= axi_awburst;
			i_awaddr_reg <= axi_awaddr;
			
		      end 
		end
	

//-------s_awlen---------------//

always @(posedge axi_aclk or negedge axi_areset_n)
	begin
		if (!axi_areset_n)
			begin
				s_awlen <= 8'b0;
			end
		else 
			begin
				s_awlen <= awlen_reg;
			end
	end


/////////////Combined the control signal logic with strt awaddr registering logic  ^//////////////////////
		//-------------- WRITE CONTROL SIGNAL REGISTERING-----------------

		/*always @(posedge axi_aclk or negedge axi_areset_n)
		begin
			if (!axi_areset_n)
			begin
				awlen_reg <= 8'd0;
				awburst_reg <= 2'd0;
			end
			else
			begin 
				if (axi_awvalid && axi_awready)
				begin
					awlen_reg <= axi_awlen;
					awburst_reg <= axi_awburst;
				end
			end
		end*/

//---------- WRITE ADDRESS CALCULATION W.R.T BURST --------------

//always @(posedge axi_aclk or negedge axi_areset_n)
//begin
 	//if (!axi_areset_n)
	//begin
	//	awaddr_reg <= {ADDRESS_WIDTH{1'b0}};
	//	w_beat_cnt <= 32'd0;
	//end
   /*	else begin 
		if (axi_awvalid && axi_awready)  
		begin
			awaddr_reg <= strt_awaddr_reg;    
			w_beat_cnt <= 32'd0;
			$display("here awaddr reg %h is assigned with strt awaddr reg %h at time %t", awaddr_reg, awaddr_reg, $time);
		end	*/

	//else
	//begin
	//	if(wstate == WDTA)
	//	begin
			/*	if (awburst_reg == 2'b00) 									
				awaddr_reg <= awaddr_reg;
				else if (awburst_reg == 2'b01)
				begin
					if ((w_beat_cnt <=(awlen_reg+1'd1)) && axi_wready)	
					begin
						awaddr_reg <= awaddr_reg + 1'd1;						
						w_beat_cnt <= w_beat_cnt +32'd1;
						$display(" I am here" );
					end
				end
				else 
				w_beat_cnt <= 32'd0;	*/

		//	case(awburst_reg)
			//2'b00:      begin
			//		awaddr_reg <= i_awaddr_reg;
			//	    end
			//2'b01:      begin
			//		        if ( axi_wready)
              //              begin
				//		        w_beat_cnt <= w_beat_cnt + 32'd1;
                  //              if(w_beat_cnt <= 32'd1)
					//	            awaddr_reg <= i_awaddr_reg + 32'd1;
                      //          else if(w_beat_cnt <=(s_awlen ))
						//            awaddr_reg <= awaddr_reg + 32'd1;
					      //  end
				       // end
			//2'b10:	    begin
				//	if((w_beat_cnt <= (s_awlen )) && axi_wready)
				//	begin
				//		w_beat_cnt <= w_beat_cnt + 32'd1;
				//		if((w_beat_cnt) == s_awlen)
				//			awaddr_reg <= strt_awaddr_reg;
				//		else
				//			awaddr_reg <= awaddr_reg + 32'd1;
				//	end
				//    end
		//	default:    begin
				//	awaddr_reg <= {ADDRESS_WIDTH{1'b0}};						
				//	w_beat_cnt <= 32'd0;
			//	    end
		//	endcase
	//	end
//	end
//end
always @(posedge axi_aclk or negedge axi_areset_n)
begin
  if (!axi_areset_n) begin
    awaddr_reg <= {ADDRESS_WIDTH{1'b0}};
    w_beat_cnt <= 32'd0;
  end
  else if (axi_awvalid && axi_awready) begin
    awaddr_reg <= axi_awaddr;
    w_beat_cnt <= 32'd0;
  end
  else if (axi_wvalid && axi_wready) begin

    if (w_beat_cnt == awlen_reg) begin
      w_beat_cnt <= 32'd0;
    end
    else begin
      w_beat_cnt <= w_beat_cnt + 1;

      case (awburst_reg)

        // FIXED
        2'b00: begin
          awaddr_reg <= awaddr_reg;
        end

        // INCR, 32-bit data = +4 bytes
        2'b01: begin
          awaddr_reg <= awaddr_reg + 4;
        end

        // WRAP
        2'b10: begin
          wrap_size  = (awlen_reg + 1) * 4;
          wrap_base  = (awaddr_reg / wrap_size) * wrap_size;
          wrap_limit = wrap_base + wrap_size;
          next_addr  = awaddr_reg + 4;

          if (next_addr == wrap_limit)
            awaddr_reg <= wrap_base;
          else
            awaddr_reg <= next_addr;
        end

        default: begin
          awaddr_reg <= awaddr_reg;
        end

      endcase
    end
  end
end

/////////////////////strt_awaddr_reg registering for wrap burst only//////
always@(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
		strt_awaddr_reg <= 32'd0;
	else
		strt_awaddr_reg <= axi_awaddr;
end


//------ WRITE DATA REGISTERING W.R.T BYTE STROBE ---------
always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if (!axi_areset_n)
	begin
		WR_reg <= 32'd0;
		//byte_addr = 32'd0;
	end
	else
	begin
		if (wstate == WADR)
		WR_reg <= 32'd0;
		else if (wstate == WDTA)
			begin 
		/*	if (axi_wstrb[0] == 1'b1)

				WR_reg[7:0]	<= axi_wdata[7:0];
				$display("at time %t, writing 7:0 bits for strb [0] %b, %b", axi_wdata[7:0], WR_reg[7:0], $time, );
			if (axi_wstrb[1] == 1'b1)
				WR_reg[15:8] <= axi_wdata[15:8];
				$display("at time %t, writing 15:8 bits for strb [1] %b, %b", axi_wdata[15:8], WR_reg[15:8], $time);
			if (axi_wstrb[2] == 1'b1)
				WR_reg[23:16] <= axi_wdata[23:16];	
				$display("at time %t, writing 23:16 bits for strb [2] %b, %b", axi_wdata[23:16], WR_reg[23:16], $time);			
			if (axi_wstrb[3] == 1'b1)
				WR_reg[31:24] <= axi_wdata[31:24];
				$display("at time %t, writing 31:24 bits for strb [3] %b, %b", axi_wdata[31:24], WR_reg[31:24], $time);*/
                         
                        WR_reg <= WR_wire; 
			end
	end 
end
assign WR_wire = {axi_wdata[31:24] & {8{axi_wstrb[3]}}, axi_wdata[23:16] & {8{axi_wstrb[2]}}, axi_wdata[15:8] & {8{axi_wstrb[1]}}, axi_wdata[7:0] & {8{axi_wstrb[0]}}};


//---------- WRITE WAIT STATE TIMER-------------
always @(posedge axi_aclk or negedge axi_areset_n)
begin 
	if (!axi_areset_n)
		w_wait_timer <= 32'd0;
	else
	begin
		if ((wstate == WWAIT) && !(wstate == WDTA))
			w_wait_timer <= w_wait_timer + 32'd1; 
		else 
			w_wait_timer <= 32'd0;
	end 
end
assign w_timeout = (w_wait_timer == WAIT_TIMER);

//---------- BRESPONCE GENERATION-------------				

always @(/*posedge axi_aclk or negedge axi_areset_n*/ * ) 		
begin 
	/*if (!axi_areset_n)
	begin
		bresp_reg_out <= 2'b00;				
		bid_reg_out <= 4'h0;
	end	
	else begin	*/
			if (/*axi_bvalid*/wstate == BRSP)
			begin
		     
				bresp_reg_out = 2'b00;
				bid_reg_out = SLAVE_ID;
				
			end 
			else  begin
				bresp_reg_out = 2'b00;
				bid_reg_out = 4'b0;
			end
	     //end
end	
assign axi_bid = bid_reg_out;
assign axi_bresp = bresp_reg_out;

///////////////////////////////////////////////////////////////////////////////////// READ HANDSHAKING FSM /////////////////////////////////////////////////////////////////////////////////

// PRESENT STATE LOGIC
always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
	rstate <= RIDL;
	else 
	rstate <= rnextstate;
end

// NEXT STATE LOGIC
always @(*)
begin
	
	case(rstate)
/*0*/	RIDL:	begin
					if ((axi_arvalid) && (axi_arid == SLAVE_ID))
					rnextstate = RADR;
					else 
					rnextstate = RIDL;
				end
/*1*/	RADR:	begin
					
					rnextstate = RWAIT;
				end
/*2*/	RWAIT:	begin							
					rnextstate = RDTA;
				end 
/*3*/	RDTA:	begin		
				/*	if (axi_rready && !axi_rlast)
					rnextstate = RDTA;
					else 	*/	
					if (axi_rlast && axi_rready)
					rnextstate =RRSP;
					else 
					rnextstate = RDTA;		
				end	
/*4*/	RRSP:	begin											
					rnextstate = RIDL;
				end
	default :	begin
					rnextstate = RIDL;
				end 
	endcase
end

//OUTPUT LOGIC
assign axi_arready = ((rstate == RADR) /*&& (rstate != RDTA)*/  && axi_arvalid); 
assign axi_rresp = (rstate == RRSP) ? 2'b00 : 2'b00;						



//-------- READ ADDRESS LATCHING---------
//always @(posedge axi_aclk or negedge axi_areset_n)
//begin 
//	if (!axi_areset_n)
	//	begin
			//strt_araddr_reg <= {ADDRESS_WIDTH{1'b0}};
		//	arlen_reg <= 8'd0;
		//	arburst_reg <= 2'd0;
		//	i_araddr_reg <= {ADDRESS_WIDTH{1'b0}};
	//	end
//	else 
	//begin
	//	if (/*axi_arvalid && axi_arready*/ rstate == RADR)
	//	begin
			//strt_araddr_reg <= axi_araddr; 
		//	arlen_reg <= axi_arlen;
		//	arburst_reg <= axi_arburst;
		//	i_araddr_reg <= axi_araddr;
	//	end 
		/* else 
			strt_araddr_reg <= strt_araddr_reg;  */ //not required coz already retains previous value
//	end
//end
always @(posedge axi_aclk or negedge axi_areset_n)
begin
  if (!axi_areset_n) begin
    arlen_reg    <= 8'd0;
    arburst_reg  <= 2'd0;
    i_araddr_reg <= {ADDRESS_WIDTH{1'b0}};
  end
  else if (axi_arvalid && axi_arready) begin
    arlen_reg    <= axi_arlen;
    arburst_reg  <= axi_arburst;
    i_araddr_reg <= axi_araddr;
  end
end

//----- RVALID GENERATION W.R.T BURST
always @(/*posedge axi_aclk or negedge axi_areset_n*/ *)
begin
	/*if (!axi_areset_n)
	rvalid_reg <= 1'd0;
	else
	begin		*/
		if ((rstate == RDTA) /*&& !(axi_rready)*/)  //rvalid is independent of rready
		begin
			if (r_beat_cnt <= arlen_reg/* + 2'd2*/)
				rvalid_reg = 1'd1;
			else
				rvalid_reg = 1'd0;
		end
		else 
			rvalid_reg = 1'd0;
	//end
end  
//assign axi_rvalid = rvalid_reg;
assign axi_rvalid = (rstate == RDTA);

/*
//--------------- RVALID EDGE DETECTION-------
always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if (!axi_areset_n)
		rvalid_edge_dly <= 1'b0;
	else
		rvalid_edge_dly <= axi_rvalid;
end
assign rvalid_edge_op = (axi_rvalid && ~rvalid_edge_dly);

//------ RVALID COUNT AND RLAST GENERATION---------
always @(posedge axi_aclk)
begin 
	if (!axi_areset_n)
		rvalid_cnt <= 32'd0;
	else
	begin
		if (axi_arvalid && axi_arready)
			rvalid_cnt <= 32'd0;
		else if (rvalid_edge_op)
		begin
			if (rvalid_cnt <=arlen_reg+1'd1) 
				rvalid_cnt <= rvalid_cnt + 1'd1;
			else 
				rvalid_cnt <= 32'd0;
		end
	end
end
assign axi_rlast = (rvalid_cnt == (arlen_reg+1'd1)) ? axi_rvalid : 1'd0; //axi_rvalid is replaced by rvalid_reg		*/

//////////////////RLAST////////////////
assign axi_rlast = ((r_beat_cnt == arlen_reg) && (rstate == RDTA)) ;//? 1'd1 : 1'd0;


//---- READ ADDRESS CALCULATION W.R.T BURST-------
//always @(posedge axi_aclk or negedge axi_areset_n)
//begin
 //	if (!axi_areset_n)
//	begin
	//	araddr_reg <= {ADDRESS_WIDTH{1'b0}};
	//	r_beat_cnt <= 32'd0;
//	end
    //	else if (axi_arvalid && axi_arready)
	//begin
	//	araddr_reg <= axi_araddr;
	//	r_beat_cnt <= 32'd0;
//	end   
	
//	else
//	begin
	//	if (axi_rvalid && axi_rready)
		//	begin
				/*	if (arburst_reg == 2'b00)
						araddr_reg <= araddr_reg;
					else if (arburst_reg == 2'b01)
					begin
						if (r_beat_cnt <= (arlen_reg-1'd1) && axi_rready)
						begin
							araddr_reg <= araddr_reg +1'd1; 
							r_beat_cnt <= r_beat_cnt+1'd1;
						end
						else 
							r_beat_cnt <= 32'd0;
					end	*/
			//	case (arburst_reg)
			//	2'b00: 	 begin
			//			araddr_reg <= i_araddr_reg;
			//	       	 end
			//	2'b01: 	 begin
			//			    if ( axi_rready)
			//			    begin
			//				    r_beat_cnt <= r_beat_cnt+1'd1;
             //                   if(r_beat_cnt == 32'd1)
              //                      araddr_reg <= i_araddr_reg;
              //                  else if(r_beat_cnt <= arlen_reg)
			//				        araddr_reg <= araddr_reg +32'd1; 
			//			    end
			//	       	 end
		//		2'b10:	    begin
		//				if((r_beat_cnt <= (arlen_reg-1'd1)) && axi_rready)
		//				begin
		//					r_beat_cnt <= r_beat_cnt + 1'd1;
		//					if(r_beat_cnt == arlen_reg-1'd1)
		//						araddr_reg <= strt_araddr_reg - 32'd1;
		//					else
		//						araddr_reg <= araddr_reg + 32'd1;
		//				end
		//		    	end
	//			default: begin
		//				araddr_reg <= {ADDRESS_WIDTH{1'b0}};
		//				r_beat_cnt <= 32'd0;
			//		 end
		//		endcase
		//	end
//	end
//end
always @(posedge axi_aclk or negedge axi_areset_n)
begin
  if (!axi_areset_n) begin
    araddr_reg  <= {ADDRESS_WIDTH{1'b0}};
    r_beat_cnt  <= 32'd0;
  end

  // New read burst accepted
  else if (axi_arvalid && axi_arready) begin
    araddr_reg <= axi_araddr;
    r_beat_cnt <= 32'd0;
  end

  // Read data beat accepted
  else if (axi_rvalid && axi_rready) begin

    if (r_beat_cnt == arlen_reg) begin
      r_beat_cnt <= 32'd0;
    end
    else begin
      r_beat_cnt <= r_beat_cnt + 1'b1;

      case (arburst_reg)

        // FIXED burst: address remains same
        2'b00: begin
          araddr_reg <= araddr_reg;
        end

        // INCR burst: word address increments by 1
        2'b01: begin
          araddr_reg <= araddr_reg + 4;
        end

        // WRAP burst
        2'b10: begin
          wrap_size  = (arlen_reg + 1) * 4;
          wrap_base  = (araddr_reg / wrap_size) * wrap_size;
          wrap_limit = wrap_base + wrap_size;
          next_addr  = araddr_reg + 4;

          if (next_addr == wrap_limit)
            araddr_reg <= wrap_base;
          else
            araddr_reg <= next_addr;
        end

        default: begin
          araddr_reg <= araddr_reg;
        end

      endcase
    end
  end
end 
//-----------str_araddr_reg registering---------------//
always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
		strt_araddr_reg <= 0;
	else 
		strt_araddr_reg <= axi_araddr;
end


////////// READ DATA ASSIGNMENT///////////

 always @(/*posedge axi_aclk or negedge axi_areset_n*/ *)
 begin
	/*if (!axi_areset_n)
		begin
			rdata_reg_out <= {DATA_WIDTH{1'b0}};
			rid_reg_out <= 4'h0;
		end
	else begin	*/
		if (axi_rvalid)
		begin
			rdata_reg_out <= slave_rdata;
			rid_reg_out <= SLAVE_ID; 
		end
		else 
		  begin
			rdata_reg_out <= 0;
			rid_reg_out <= 4'b0; 
		  end
end
/*always @(posedge axi_aclk or negedge axi_areset_n)
begin
  if (!axi_areset_n) begin
    axi_rdata_reg <= {DATA_WIDTH{1'b0}};
    rid_reg_out   <= 4'h0;
  end
  else if (axi_rvalid && axi_rready) begin
    axi_rdata_reg <= slave_rdata;
    rid_reg_out   <= SLAVE_ID;
  end
end*/


//------ RDATA ASSIGNMENT-----------------
//assign axi_rdata = (axi_rready) ? rdata_reg_out : 32'd0; 	
assign axi_rdata = rdata_reg_out;
assign axi_rid = rid_reg_out;

//------------- OUTPUT GENERATION FOR MEMORY----------

// axi_wready ONE CLOCK CYCLE DELAY TO GENERATE ENBALE FOR MEMORY---------  
always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if (!axi_areset_n)
		wready_delay <= 1'b0;
	else
		wready_delay <= axi_wready;
end

assign slave_wren = (wready_delay);
assign slave_waddr = awaddr_reg; 
assign slave_wdata = WR_reg;
assign slave_rden = (rstate == RWAIT);
assign slave_raddr = araddr_reg;


endmodule
