///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: ftdi_xcvr.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::PolarFire> <Die::MPF100T> <Package::FCG484>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 
//`timescale 1ns/1ns

module ftdi_xcvr(
	input 			ft_clk,
	input 			sys_nrst,

	// xcvr i/o
	input 			TXE_N,
	input 			RXF_N,
	output reg  	OE_N,
	output reg		RD_N,
	output reg 		WR_N,
	inout [3:0] 	BE,
	inout [31:0]	DATA,

	// control i/o
	input				rd_req,
	input 				wr_req,
	input [31:0]		wr_data,
	input [9:0]			rd_word_cnt,
	
	output 				wr_rdy,
	output 				rd_rdy,

	output reg [31:0]	rd_data,
	output reg			done,				
	output reg 			busy,
	output reg  		data_valid
);


localparam 	SIG_DELAY = 6;
reg [SIG_DELAY:0] 	TXE_delay;
reg [SIG_DELAY:0]	RXF_delay;

assign wr_rdy = TXE_delay[SIG_DELAY] & !TXE_N & !busy;	//!TXE_N & !busy;
assign rd_rdy = RXF_delay[SIG_DELAY] & !RXF_N & !busy;	//!RXF_N & !busy;	

// inout ports
reg [31:0] 	DATA_reg;
assign 	DATA = OE_N ? DATA_reg : 32'bz;

reg [3:0] 	BE_reg;	
assign 	BE = OE_N ? BE_reg : 4'bz;

// front detect
reg 	wr_req_q;
reg 	rd_req_q;

reg [9:0]		word_cnt;

reg [3:0] 		ft_FSM;
localparam 		s_IDLE		= 4'b0001,
				s_READ		= 4'b0010,
				s_WRITE 	= 4'b0100,
				s_FINISH 	= 4'b1000;

always@(posedge ft_clk) begin
	if(!sys_nrst) begin
		OE_N <= 1'b1;
		RD_N <= 1'b1;
		WR_N <= 1'b1;
		
		rd_data <= 0;
		busy <= 0;
		done <= 0;
		data_valid <= 0;
	
		rd_req_q <= 0;
		wr_req_q <= 0;
		
		TXE_delay <= 0;
		RXF_delay <= 0;

		DATA_reg <= 0;
		BE_reg 	<= 0;

		word_cnt <= 0;

		ft_FSM <= s_IDLE;
	end
	else begin

		TXE_delay <= {TXE_delay[SIG_DELAY-1:0], !TXE_N};
		RXF_delay <= {RXF_delay[SIG_DELAY-1:0], !RXF_N};

		wr_req_q <= wr_req;
		rd_req_q <= rd_req;
		done <= 0;
		data_valid <= 0;

		case(ft_FSM) 
			s_IDLE: begin
				if((rd_req_q == 0) && (rd_req == 1) && !RXF_N && !busy) begin
					OE_N <= 0;

					word_cnt <= rd_word_cnt;
					busy <= 1'b1;
					ft_FSM <= s_READ;
				end
				else
				if((wr_req_q == 0) && (wr_req == 1) && !TXE_N && !busy) begin
					WR_N <= 0;
					DATA_reg <= wr_data;
					BE_reg <= 4'b1111;

					busy <= 1'b1;
					ft_FSM <= s_WRITE;
				end
				else begin
					OE_N <= 1'b1;
					RD_N <= 1'b1;
					WR_N <= 1'b1;
					busy <= 0;

					ft_FSM <= s_IDLE;
				end
			end

			s_READ: begin
				if(word_cnt == 0) begin
					OE_N <= 1'b1;
					RD_N <= 1'b1;

					done <= 1'b1;
					data_valid <= 1'b1;
					rd_data <= DATA;
					ft_FSM <= s_IDLE;
				end
				else
				if(RXF_N) begin
					OE_N <= 1'b1;
					RD_N <= 1'b1;

					done <= 1'b1;
					ft_FSM <= s_IDLE;
				end
				else begin
					word_cnt <= word_cnt - 1'b1;

					if(RD_N) begin
						RD_N <= 0;
					end
					else begin
						data_valid <= 1'b1;
						rd_data <= DATA;
					end
				end
			end

			s_WRITE: begin
				WR_N <= 1'b1;
				done <= 1'b1;
				ft_FSM <= s_IDLE;
			end

			default:
				ft_FSM <= s_IDLE;
		endcase
	end
end

endmodule