`timescale 1ns/1ps
module apb_master(
	input		  PCLK,
	input		  PRESETn,

	output reg 	  PSEL,
	output reg 	  PENABLE,
	output reg [31:0] PADDR,
	output reg 	  PWRITE,
	output reg [31:0] PWDATA,

	input 	   [31:0] PRDATA,
	input 	   	  PREADY,
	input		  PSLVERR	
);

parameter NUM_TRANSFERS = 8;

localparam IDLE   = 2'b00;
localparam SETUP  = 2'b01;
localparam ACCESS = 2'b10;

reg [1:0] state,next_state;
reg [31:0] addr_reg, data_reg,read_reg;
reg write_reg,error_reg;
reg [3:0] transfer_count;

wire transfer;
assign transfer=(transfer_count < NUM_TRANSFERS);

// State Register
always @(posedge PCLK or negedge PRESETn)
	begin
	   if(!PRESETn)
	   	state <= IDLE;
	   else
		state <= next_state;
	end

always @(posedge PCLK or negedge PRESETn)
	begin
	  if(!PRESETn)
	    begin
		addr_reg <= 32'd0;
		data_reg <= 32'd0;
		write_reg <= 1'b0;
		read_reg  <= 32'd0;
		error_reg <= 1'b0;
		transfer_count <=4'd0;
	    end
	 else
	    begin
	     if(state==IDLE && transfer)
	      begin
		addr_reg  <= 32'h0000_0000;
		data_reg  <= 32'h1111_1111;
		write_reg <= 1'b1;
	      end
		
	else if(state==ACCESS && PREADY) 
	    begin
		if(!write_reg)
			read_reg <= PRDATA;
			error_reg <= PSLVERR;
			transfer_count <= transfer_count +1;
		if(transfer_count != NUM_TRANSFERS-1)
		  begin
			addr_reg <= addr_reg +4;
			data_reg <= data_reg +1;
			write_reg <= ~write_reg;
		  end
		end
		end
	  end
  
always @(*)
begin

    next_state = state;

    case(state)

        IDLE :
        begin
            if(transfer)
                next_state = SETUP;
            else
                next_state = IDLE;
        end

        SETUP :
        begin
            next_state = ACCESS;
        end

        ACCESS :
        begin

            if(!PREADY)
                next_state = ACCESS;

            else if(transfer_count == NUM_TRANSFERS)
                next_state = IDLE;

            else
                next_state = SETUP;

        end

        default :
            next_state = IDLE;

    endcase

end

always @(*)
begin

    PSEL = 1'b0;
    PENABLE = 1'b0;

    PADDR = 32'd0;
    PWRITE = 1'b0;
    PWDATA = 32'd0;

    case(state)

        IDLE :
        begin
            PSEL = 1'b0;
            PENABLE = 1'b0;
        end

        SETUP :
        begin
            PSEL = 1'b1;
            PENABLE = 1'b0;

            PADDR = addr_reg;
            PWRITE = write_reg;
            PWDATA = data_reg;
        end

        ACCESS :
        begin
            PSEL = 1'b1;
            PENABLE = 1'b1;

            PADDR = addr_reg;
            PWRITE = write_reg;
            PWDATA = data_reg;
        end

    endcase

end

endmodule
	
		
		 

