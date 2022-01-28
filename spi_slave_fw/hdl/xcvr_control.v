///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: FSM.v
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
`define BLINK_DELAY 30'd50_000_000

module xcvr_control (

	input 				sys_clk,
	input 				sys_nrst,
	output reg [2:0] 	LED,
	
	// xcvr i/o
	input 				wr_rdy,
	input				rd_rdy,
	input				ft_data_valid,
	input				ft_done,
	input [31:0]		rd_data,

	output reg			wr_req,
	output reg			rd_req,
	output reg [9:0]	rd_word_cnt,
	output reg [31:0] 	wr_data,

	// FIFO i/o
	input 				fifo_empty,
	input				fifo_full,
	input 				fifo_almost_empty,

	output reg 			fifo_wr_req,
	output reg			fifo_sync_rst,
	output reg [15:0] 	fifo_wr_data,

	//output reg [2:0] 	FSM_state_debug,

	output reg			debug_check_fifo,
	output reg			debug_fill_fifo,

	// programer i/o
	input 		 		program_done,
	input				verify_done,
	input 				program_error,

	input 				spi_violation_err,
	input 				spi_process_err,
	output reg [15:0]	programmer_command
);


reg [7:0] 	cmd_opcode;
reg	[23:0]	cmd_data;
//reg 		continue;
reg [9:0]	fifo_written_cnt;

reg [4:0] 	wait_cnt;
localparam 	WAIT_DELAY = 5'd31;

reg [29:0] 	blink_cnt;

reg [6:0] 	main_FSM;
localparam 	s_IDLE 			= 7'b000_0001,
			s_READ_CMD  	= 7'b000_0010,
			s_EXEC_CMD 		= 7'b000_0100,
	//s_WAIT_FIFO_ALM_EMPTY 	= 7'b000_1000;
			s_FILL_FIFO		= 7'b001_0000,
			s_SEND_FIFO_CNT	= 7'b010_0000,
			s_WAIT_DONE 	= 7'b100_0000;

// always@(*) begin
// 	case(main_FSM) 
// 		s_IDLE: 		FSM_state_debug <= 3'd1;
// 		s_READ_CMD:		FSM_state_debug <= 3'd2;
// 		s_EXEC_CMD:		FSM_state_debug <= 3'd3;
// 		s_FILL_FIFO:	FSM_state_debug <= 3'd4;
// 		s_SEND_FIFO_CNT:FSM_state_debug <= 3'd5;
// 		s_WAIT_DONE:	FSM_state_debug <= 3'd6;
// 		default:		FSM_state_debug <= 3'd7;
// 	endcase
// end

always@(posedge sys_clk) begin
	if(!sys_nrst) begin
	// i/o
		LED <= 0;
		wr_req <= 0;
		rd_req <= 0;
		wr_data <= 0;
		rd_word_cnt <= 0;

		fifo_wr_req	<= 0;
		fifo_wr_data <= 0;
		fifo_sync_rst <= 0;

	// internal
		cmd_opcode <= 0;
		cmd_data <= 0;
		programmer_command <= 0;

		wait_cnt <= 0;
		blink_cnt <= 0;
		fifo_written_cnt <= 0;

		main_FSM <= s_IDLE;

		debug_check_fifo <= 0;
		debug_fill_fifo <= 0;
	end
	else begin

		wr_req <= 0;
		rd_req <= 0;
		fifo_wr_req <= 0;
		fifo_sync_rst <= 0;

		debug_check_fifo <= 0;
		debug_fill_fifo <= 0;

		if(blink_cnt == `BLINK_DELAY) begin
			LED[0] <= ~LED[0];
			blink_cnt <= 0;
		end
		else
			blink_cnt <= blink_cnt + 1'b1;

		case(main_FSM)
			s_IDLE: begin
				if(rd_rdy) begin
					rd_req <= 1'b1;
					rd_word_cnt <= 10'd1;
					main_FSM <= s_READ_CMD;
				end
				else begin
					programmer_command <= 0;

					cmd_opcode <= 0;
					cmd_data <= 0;
					fifo_written_cnt <= 0;
					wait_cnt <= 0;
					main_FSM <= s_IDLE;
				end
			end

			s_READ_CMD: begin
				if(ft_done) begin
					cmd_opcode <= rd_data[7:0];
					cmd_data  <= rd_data[31:8];
					main_FSM <= s_EXEC_CMD;
				end
				else begin
					main_FSM <= s_READ_CMD;
				end
			end

			s_EXEC_CMD: begin
				case(cmd_opcode)
					8'd1: begin 	// set LED
						LED[1] <= cmd_data[0];
						LED[2] <= cmd_data[1];
						main_FSM <= s_IDLE;
					end

					8'd2: begin 	//fill fifo
						debug_fill_fifo <= 1;
						if(rd_rdy) begin
							rd_word_cnt <= cmd_data[9:0];
							rd_req <= 1'b1;
							fifo_written_cnt <= 0;

							main_FSM <= s_FILL_FIFO;
						end
						else
							main_FSM <= s_EXEC_CMD;
					end

					8'd4: begin 	//check flags
						debug_check_fifo <= 1;
						if(wr_rdy) begin
							wr_data[7:0] <= {spi_process_err, spi_violation_err, program_error, program_done, verify_done, 
												fifo_almost_empty, fifo_empty, fifo_full};
							wr_data[31:8] <= 0;
							wr_req <= 1'b1;
							main_FSM <= s_WAIT_DONE;
						end
						else 
							main_FSM <= s_EXEC_CMD;
					end

					8'd6: begin 	// write programmer cmd
						programmer_command <= cmd_data[15:0];
						main_FSM <= s_IDLE;
					end

					8'd8: begin 	// flush fifo
						fifo_sync_rst <= 1'b1;

						main_FSM <= s_IDLE;
					end

					default: main_FSM <= s_IDLE;
				endcase
			end

			// s_WAIT_FIFO_ALM_EMPTY: begin
			// 	if(rd_rdy && fifo_almost_empty) begin
			// 		rd_req <= 1'b1;
			// 		fifo_written_cnt <= 0;
			// 		main_FSM <= s_FILL_FIFO;
			// 	end
			// 	else
			// 		main_FSM <= s_WAIT_FIFO_ALM_EMPTY;
			// end

			s_FILL_FIFO: begin
				if(ft_data_valid) begin
					fifo_wr_req <= 1'b1;
					fifo_wr_data <= rd_data[15:0];
					fifo_written_cnt <= fifo_written_cnt + 1'b1;

					if(ft_done) begin
						main_FSM <= s_SEND_FIFO_CNT;
					end
				end
				else
					main_FSM <= s_FILL_FIFO;
			end

			s_SEND_FIFO_CNT: begin
				if(wr_rdy) begin
					wr_data[9:0] <= fifo_written_cnt;
					wr_req <= 1'b1;
					main_FSM <= s_WAIT_DONE; 
				end
				else 
					main_FSM <= s_SEND_FIFO_CNT;
			end

			s_WAIT_DONE: begin
				if(ft_done) begin
					main_FSM <= s_IDLE;
				end
				else
					main_FSM <= s_WAIT_DONE;
			end

			default:
				main_FSM <= s_IDLE;
		endcase
	end
end

endmodule