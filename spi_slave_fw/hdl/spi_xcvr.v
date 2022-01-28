
module spi_xcvr #(
		parameter CLK_RATIO = 3
	)
(	
	input 				sys_clk,
	input 				sys_nrst,

	// control i/o
	input 				enable,
	input 				wr_req,
	input [7:0] 		wr_data,

	output reg 			busy,
	output reg 			done,
	output reg [7:0] 	rd_data,

	// SPI i/o
	input 				MISO,
	output	 			SCK,
	output reg 			MOSI,
	output reg 			NSS
);



reg 		transmit_en;
reg [7:0]	wr_data_reg;
reg [3:0] 	bit_cnt;

reg [3:0] 	spi_FSM;
localparam 	s_IDLE 	= 4'b0001,  
			s_WAIT	= 4'b0010,
			s_TRSMT	= 4'b0100;

always@(posedge sys_clk) begin
	if(!sys_nrst) begin
		busy <= 0;
		done <= 0;

		NSS <= 1'b1;

		transmit_en <= 0;

		spi_FSM <= s_IDLE;
	end
	else begin
		done <= 0;
		
		case(spi_FSM) 
			s_IDLE: begin
				if(enable) begin
					NSS <= 0;
					
					if(wr_req) begin
						transmit_en <= 1'b1;
						wr_data_reg <= wr_data;
						busy <= 1'b1;
						spi_FSM <= s_TRSMT;
					end
					else
						spi_FSM <= s_WAIT;
				end
				else begin
					NSS <= 1'b1;
					transmit_en <= 0;
					spi_FSM <= s_IDLE;
				end
			end

			s_WAIT: begin  // hold NSS asserted
				if(enable & wr_req) begin
					transmit_en <= 1'b1;
					busy <= 1'b1;
					wr_data_reg <= wr_data;
					spi_FSM <= s_TRSMT;
				end
				else 
				if(!enable) begin
					spi_FSM <= s_IDLE;
				end
				else
					spi_FSM <= s_WAIT;
			end

			s_TRSMT: begin
				if(bit_cnt == 4'd8) begin
					busy <= 0;
					done <= 1'b1;
					transmit_en <= 0;

					if(enable) begin
						spi_FSM <= s_WAIT;
					end
					else begin
						spi_FSM <= s_IDLE;
					end
				end
				else
					spi_FSM <= s_TRSMT;
			end
		endcase
	end
end

// SCK gen
reg 		SCK_reg;

reg [$clog2(CLK_RATIO-1):0] clk_cnt;

assign SCK = SCK_reg || NSS;

always@(posedge sys_clk) begin
	if(NSS) begin
		SCK_reg <= 1'b1;
		clk_cnt <= 0;
		MOSI <= 0;
		bit_cnt <= 0;
	end
	else begin
		if(bit_cnt == 4'd8) begin
			bit_cnt <= 0;
		end
		
		if(clk_cnt == (CLK_RATIO - 1'b1)) begin
			clk_cnt <= 0;

			if(transmit_en) begin
				SCK_reg <= !SCK_reg;

				if(SCK_reg) begin // falling edge - TX
					MOSI <= wr_data_reg[7 - bit_cnt];
					//wr_data_reg <= {wr_data_reg[6:0], 1'b0};
				end

				if(!SCK_reg) begin // rising edge - RX
					rd_data <= {rd_data[6:0], MISO};
					bit_cnt <= bit_cnt + 1'b1;
				end
			end
		end
		else
			clk_cnt <= clk_cnt + 1'b1;
	end
end

// // TX 
// always@(negedge SCK_reg) begin
// 	if(!SCK_en) begin
// 		MOSI <= 0;
// 	end
// 	else begin
// 		MOSI <= wr_data_reg[7];
// 		wr_data_reg <= {wr_data_reg[6:0], 1'b0};
// 	end
// end

// // RX 
// reg [2:0] 	bit_cnt;

// always@(posedge SCK_reg) begin
// 	if(!SCK_en) begin
// 		bit_cnt <= 0;
// 	end
// 	else begin
// 		rd_data <= {rd_data[6:0], MISO};
// 		bit_cnt <= bit_cnt + 1'b1;
// 	end
// end


endmodule