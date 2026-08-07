`timescale 1ns/1ps

module axi_master #(parameter DATA_WIDTH = 32, parameter ADDRESS_WIDTH = 32, parameter WAIT_TIMER = 200, parameter SLAVE_ID = 4'b0011)
			 			(
					///////GLOBAL SIGNALS/////////////// 
			input 								axi_aclk, 
			input 								axi_areset_n, 

					//////WRITE ADDRESS CHANNEL///////// 
			output 				[ADDRESS_WIDTH-1:0] 		axi_awaddr,
			output 								axi_awvalid,
			input 								axi_awready,
			output 				[3:0] 				axi_awid,
			output 				[7:0] 				axi_awlen,
			output 				[1:0] 				axi_awburst,			

					//////WRITE DATA CHANNEL////////////
			output 		reg		[DATA_WIDTH-1:0] 		axi_wdata,
			output 		reg						axi_wvalid, 
			input 								axi_wready, 
			output 				[3:0] 				axi_wid,
			output 								axi_wlast,
			output 				[(DATA_WIDTH>>3)-1:0] 		axi_wstrb,

					//////WRITE RESPONSE CHANNEL////////
			input 				[1:0] 				axi_bresp,
			input 								axi_bvalid,
			output 								axi_bready,
			input 				[3:0] 				axi_bid,

					//////READ ADDRESS CHANNEL//////////
			output 				[ADDRESS_WIDTH-1:0]		axi_araddr,
			output 								axi_arvalid,
			input 								axi_arready,
			output 				[3:0] 				axi_arid,
			output 				[7:0] 				axi_arlen,
			output 				[1:0] 				axi_arburst,

					//////READ DATA CHANNEL////////////
			input 				[DATA_WIDTH-1:0] 		axi_rdata,
			input 								axi_rvalid,
			output 								axi_rready,
			input 				[3:0] 				axi_rid, 	
			input 								axi_rlast,
			input 				[1:0] 				axi_rresp,

					//////PROCESSOR TO MASTER INTERPHACE SIGNALS/////
			input 								master_wren,
			input 				[31:0]				master_waddr,
			input				[3:0]				master_wid,
			input				[7:0]				master_wlen,
			input				[1:0]				master_wburst,
			input 				[31:0]				master_wdata,
			input				[3:0]				master_wstrb,

			input 								master_rden,
			input 				[31:0]				master_raddr,
			input 				[7:0]				master_rlen,
			input 				[1:0]				master_rburst,
			input 				[3:0]				master_rid,
			output 				[31:0]				master_rdata
						);

//----------------write fsm states------------------//
localparam WIDL = 3'b000;
localparam WADR = 3'b001;
localparam WDTA = 3'b010;
localparam WWAIT = 3'b011;
localparam WDLY = 3'b100;	
localparam BRSP = 3'b101;

//----------------read fsm states-------------------//
localparam RIDL = 3'b000;
localparam RADR = 3'b001;
localparam RDLY = 3'b010;
localparam RDTA = 3'b011;
/*localparam RWAIT = 3'b011;	*/
localparam RRSP = 3'b100;

///////////////////////////
reg [2:0] wstate;
reg [2:0] wnextstate;
reg [2:0] rstate;
reg [2:0] rnextstate;

//----------------internal regs--------------------------//
reg [ADDRESS_WIDTH-1:0] awaddr_reg;
reg [7:0] awlen_reg;
reg [1:0] awburst_reg;
reg [DATA_WIDTH-1:0] wdata_reg;
reg [3:0] wstrb_reg; 
reg [3:0] wid_reg;
reg [3:0] awid_reg;
//reg axi_bready_reg;
reg [7:0] aw_len;

reg [3:0] arid_reg;
reg [ADDRESS_WIDTH-1:0] araddr_reg;
reg [DATA_WIDTH-1:0] rdata_reg;
reg [7:0] arlen_reg;
reg [1:0] arburst_reg;


/*integer*/ reg [7:0]  w_beat_cnt;//hardware overload if integer is used
/*integer*/reg [7:0] w_wait_timer;
wire w_timeout;
wire w_burst_actv;
//--------------------------------------WRITE FSM--------------------------------------------//
always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
		wstate <= WIDL;
	else
		wstate <= wnextstate;
end

always @(*)
begin
	case(wstate)
/*0*/		WIDL : begin
				if(master_wren)  
					wnextstate = WADR;
				else
					wnextstate = WIDL;
			end
/*1*/		WADR : begin
				if(axi_awready) 
					wnextstate = WDTA;
				else
					wnextstate = WADR;
			end
/*2*/		WDTA : begin
				if(axi_wlast && axi_wready) 
					wnextstate = WDLY;
				else if(!axi_wready && w_beat_cnt != 0 && w_burst_actv)
					wnextstate = WWAIT;
				else 	
					wnextstate = WDTA;
			end
/*3*/		WWAIT : begin
				if(axi_wready && w_burst_actv)
					wnextstate = WDTA;
				else if(w_timeout)
					wnextstate = WIDL;
				else
					wnextstate = WWAIT;
			end
/*4*/		WDLY: begin
				if(axi_bvalid && axi_bid == SLAVE_ID)
					wnextstate = BRSP;
				
				else
					wnextstate = WDLY;
			end		
/*5*/		BRSP : begin
				if(axi_bready)
					wnextstate = WIDL;
				else
					wnextstate = BRSP;
			end
	     default : begin
				wnextstate = WIDL;
		       end
		endcase
end
/////////////////////////////////////////////////////////Output signals
assign axi_awvalid = (wstate == WADR);
//assign axi_wvalid = (wstate == WDTA);
assign axi_bready = ((wstate == BRSP) && axi_bvalid);

always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
		axi_wvalid <= 1'b0;
	else
		axi_wvalid <= (wstate == WDTA);
end


//--------------
assign w_burst_actv = ((wstate != WIDL) && (w_beat_cnt <= (awlen_reg/*-1'd1*/)));

////////////////////////////////awid and wid registering//////////////////////////
always @(*)
	begin
		if(wstate == WADR)
			begin	
				awid_reg = master_wid;////////////////
			end

		else
			begin
				awid_reg = 4'b0;
			end
	end
assign axi_awid = awid_reg;

always @(*)
	begin
		if(wstate == WDTA)
			begin
				wid_reg = master_wid;/////////////////
			end

		else
			begin
				wid_reg = 4'b0;
			end	
	end

assign axi_wid = wid_reg;

//////////////////////////////////////////////////////// AW channel registering sigals//////////
always @(*)
begin 	
	if(wstate != WIDL)	
		begin
			awaddr_reg = master_waddr;////////////
			awlen_reg = master_wlen;/////////////
			awburst_reg = master_wburst;////////////
		end
	else 
		begin
			awaddr_reg = 32'b0;
			awlen_reg = 8'b0;				
			awburst_reg = 2'b0;
		end
end
assign axi_awaddr = awaddr_reg;
assign axi_awlen = awlen_reg;
assign axi_awburst = awburst_reg;


/////////////////////////////////////////////////////// W channel registering signals////////////

always @(*)
begin
	if(wstate == WDTA)
	begin
		wdata_reg = master_wdata;
		wstrb_reg = master_wstrb;
	end
	else 
	begin
		wdata_reg = 32'b0;
		wstrb_reg = 4'b0;
	end
end
//assign axi_wdata = wdata_reg;
assign axi_wstrb = wstrb_reg;

always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
		axi_wdata <= 32'b0;
	else
		axi_wdata <= wdata_reg;
end

/////////////////w_timeout logic/////////////////////////////
always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
	begin
		w_wait_timer <= 8'b0;
	end
	else
	begin
		if(wstate == WWAIT)
		begin
			w_wait_timer <= w_wait_timer + 8'd1;
		end
		else
		begin
			w_wait_timer <= 8'b0;
		end
	end
end
assign w_timeout = (w_wait_timer == WAIT_TIMER);	

////////////aw_len logic//////////

always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
		begin
			aw_len <= 8'b0;
		end
	else
		begin
			if(wstate == WADR) 
			begin
				 aw_len <= awlen_reg;
			end
		end
end


///////////////////////////////////////////////////// w_beat_cnt and wlast generation/////////////
always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
	begin
		w_beat_cnt <= 8'b0;
	end
	else
	begin
		if((wstate == WDTA) && (axi_wready))
		begin
			 w_beat_cnt <= w_beat_cnt + 8'd1;
		end
        else if(wstate == WWAIT)
        begin
            w_beat_cnt <= w_beat_cnt;
        end
        else
        begin
            w_beat_cnt <= 8'b0;
        end
	end
end
assign axi_wlast = (wstate == WDTA) && (w_beat_cnt == aw_len);


//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$//

//------------------------------------------------READ FSM-------------------------------------------------------------------//

always @(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
		rstate <= RIDL;
	else
		rstate <= rnextstate;
end

always @(*)
begin
	case(rstate)
/*0*/		RIDL : begin
				if(master_rden)
					rnextstate = RADR;
				else
					rnextstate = RIDL;
			end
/*1*/		RADR : begin
				if(axi_arready)
					rnextstate = RDLY;
				else
					rnextstate = RADR;
			end
/*2*/		RDLY : begin
				if(axi_rvalid && axi_rid == SLAVE_ID)
					rnextstate = RDTA;
				else 
					rnextstate = RDLY;
			end
/*3*/		RDTA : begin
				if(axi_rlast)
					rnextstate = RRSP;
				else 
					rnextstate = RDTA;
			end
/*4*/		RRSP : begin
					rnextstate = RIDL;
			end
	     default : begin
				rnextstate = RIDL;
		       end
		endcase
end
//////////////Output logic/////////
assign axi_arvalid = (rstate == RADR) ;
assign axi_rready = (rstate == RDTA) && axi_rvalid;

//--------------------------------arid and rid logic
always@(*)
	begin
		if(rstate == RADR)
			begin
				arid_reg = master_rid;////////////////
			end
		else
			begin
				arid_reg = 4'b0;
			end
	end
assign axi_arid = arid_reg;

///////////////////////////////////////////////// AR channel registering sigals//////////
always @(*)
	begin 	
		if(rstate == RADR)
			begin
				araddr_reg = master_raddr;////////////////
				arlen_reg = master_rlen;///////////////
				arburst_reg = master_rburst;////////////
			end
		else
			begin
				araddr_reg = 32'b0;
				arlen_reg = 8'b0;
				arburst_reg = 2'b0;
			end		
	end

assign axi_araddr = araddr_reg;
assign axi_arlen = arlen_reg;
assign axi_arburst = arburst_reg;

//------------------------------------
always@(posedge axi_aclk or negedge axi_areset_n)
begin
	if(!axi_areset_n)
		rdata_reg <= 0;
	else if(axi_rvalid && axi_rready)
		rdata_reg <= axi_rdata;
end
assign master_rdata = rdata_reg;
endmodule
