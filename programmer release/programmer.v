
// SPI commands
`define SPI_ISC_ENABLE 		8'h0B
`define SPI_ISC_DISABLE 	8'h0C
//`define SPI_ISC_DATA 		32'h29_00_00_01 		// little endian
`define SPI_ISC_DATA 		32'h01_00_00_29 		// big endian

`define SPI_FRAME_INIT 		8'hAE
`define	SPI_PROGRAM_CMD		8'h01
`define	SPI_VERIFY_CMD		8'h02
`define	SPI_RELEASE			8'h23
`define	SPI_FRAME_DATA		8'hEE
`define	SPI_HWSTATUS		8'h00
`define SPI_READ_DATA 		8'h01
`define SPI_WRITE_DATA 		8'hF2

//`define SPI_WAIT_DELAY			500
`define SPI_WAIT_DELAY			200 // for tb

`define SPI_BUSY_BIT  			0
`define SPI_READY_BIT			1
`define SPI_VIOLATION_BIT		2			// transmit error
`define SPI_PROCESS_BIT			3			// process data error
`define SPI_ISC_DATA_SIZE 		4
`define SPI_FRAME_DATA_SIZE 	16

// Image params
`define	TP_BLOCK_SIZE			32768
`define CRC16_START_VAL 		16'hffff
`define CRC16_POLY				16'h8408

// error codes
`define SPI_VIOLATION_ERROR  	16'h00_01
`define SPI_PROCESS_ERROR	 	16'h00_02
`define ISC_ENABLE_ERROR 		16'h00_04
`define DIGEST_CHECK_ERROR		16'h00_08


module programmer#(
	parameter FLASH_OFFSET = 0,
	parameter FLASH_APB_ADDRESS = 0,
	parameter MAX_COMPONENT_NUMBER = 4
)
(
	input 			sys_clk,	
	input 			sys_nrst,

	// BUS i/o

	// SPI i/o
	input 			MISO,
	output			MOSI,
	output			SCK,
	output 			NSS,

	// control i/o
	input [15:0] 	command,

	input 			out_fifo_empty,
	input [15:0]	out_fifo_rd_data,
	output			out_fifo_rd_en,

	output reg 		program_done,
	output reg 		verify_done,
	output reg 		program_error,

	output reg 		spi_violation_err,
	output reg 		spi_process_err
);

reg 		spi_enable;
reg 		spi_wr_req;
reg  [7:0]	spi_wr_data;
wire [7:0]	spi_rd_data;
wire 		spi_busy;
wire 		spi_done;

spi_xcvr #(48) spi_xcvr_0 (
	.sys_clk(sys_clk),
	.sys_nrst(sys_nrst),

	.enable(spi_enable),
	.wr_req(spi_wr_req),
	.wr_data(spi_wr_data),

	.busy(spi_busy),
	.done(spi_done),
	.rd_data(spi_rd_data),

	.MISO(MISO),
	.MOSI(MOSI),
	.SCK(SCK),
	.NSS(NSS)
);

wire		fifo_wr_en;
wire 		fifo_rd_en;
wire [15:0] fifo_wr_data;
reg 		fifo_sync_rst;
wire [15:0]	fifo_rd_data;
wire 		fifo_full;
wire 		fifo_empty;

buffer_fifo fifo_0(
	.clock	(!sys_clk),
	.data	(fifo_wr_data),
	.rdreq	(fifo_rd_en),
	.sclr	(!sys_nrst | fifo_sync_rst),
	.wrreq	(fifo_wr_en),
	.empty  (fifo_empty),
	.full   (fifo_full),
	.q		(fifo_rd_data)
);


reg [15:0]		command_reg;


reg [15:0]		fetch_buffer;
reg [31:0]		fetch_size;
reg [31:0]		fetch_cnt; 	
reg 			fetch_error;

reg [15:0]  	calc_CRC;
reg [3:0]		CRC_cnt;
//reg  			CRC_en;

reg 			start_program;
reg [15:0] 		program_error_code;
reg [31:0]		program_buffer;	
reg [11:0]		delay_cnt;
reg [4:0]		byte_cnt;
reg [10:0] 		step_cnt;
reg [1:0]		digest_cnt;


reg  			fifo_rd_req;
reg 			fifo_rd_done;
reg				fifo_wr_req;
reg 			fifo_wr_done;
reg 			rw_flag;	// 	1 - write flag, 0 - read flag

reg [4:0] 		component_num;
reg [4:0]		component_cnt;
reg [21:0]		component_size [MAX_COMPONENT_NUMBER-1:0];
reg [21:0] 		block_cnt;

// temp logic
reg 		out_fifo_rd_req;
reg 		out_fifo_rd_done;
assign out_fifo_rd_en = out_fifo_rd_req & !out_fifo_empty;


integer i;
wire [7:0] 	image_header_size;
assign image_header_size = 8'd6 + (component_num << 2);

// fifo logic
assign fifo_rd_en = fifo_rd_req & !fifo_empty;
assign fifo_wr_en = fifo_wr_req & !fifo_full;
assign fifo_wr_data = (command_reg[1:0] == 2'b10) ? fetch_buffer : 16'b0;

// FSMs
reg [7:0] 		fetch_FSM;
reg [7:0]		fetch_FSM_next;
localparam 		s_fetch_IDLE 			= 8'b0000_0001,
				s_fetch_READ_FIFO		= 8'b0000_0010,
				s_fetch_READ_FLASH		= 8'b0000_0100,
				s_fetch_WRITE_FIFO		= 8'b0000_1000,
				s_fetch_WRITE_FLASH		= 8'b0001_0000,
				s_fetch_CALC_CRC		= 8'b0010_0000,
				s_fetch_RECEIVE_IMAGE	= 8'b0100_0000,
				s_fetch_LOAD_IMAGE		= 8'b1000_0000;


reg [11:0] 		program_FSM;
reg [11:0] 		program_FSM_next;
localparam  	s_program_IDLE  				= 12'b0000_0000_0001,
/*program fsm*/ s_program_SPI_WAIT_1			= 12'b0000_0000_0010,
				s_program_SPI_WAIT_2			= 12'b0000_0000_1111,
				s_program_GET_HWSTATUS			= 12'b0000_0000_0100,
				s_program_ISC_ENABLE			= 12'b0000_0000_1000, // enable ISC mode
				s_program_ISC_STATUS 			= 12'b0000_0001_0000,
				s_program_FRAME_INIT			= 12'b0000_0010_0000,
				s_program_READ_COMPONENT_NUMBER = 12'b0000_0100_0000,
				s_program_READ_COMPONENT_SIZE	= 12'b0000_1000_0000,
				s_program_PROCESS_COMPONENTS 	= 12'b0001_0000_0000,
				s_program_PROCESS_DIGEST		= 12'b0010_0000_0000,
				s_program_ISC_DISABLE			= 12'b0100_0000_0000,
				s_program_SPI_RELEASE			= 12'b1000_0000_0000;

localparam 		s_INIT  			= 11'b000_0000_0001,
/*sub fsm*/		s_SELECT_COMPONENT 	= 11'b000_0000_0010,
				s_CHECK_DEVICE		= 11'b000_0000_0100,
				s_START_TRSMT		= 11'b000_0000_1000,
				s_READ_FIFO			= 11'b000_0001_0000,
				s_SEND_BLOCK_DATA	= 11'b000_0010_0000,
				s_SET_BLOCK			= 11'b000_0100_0000,

				s_SEND_CMD			= 11'b000_1000_0000,
				s_SEND_DUMMY		= 11'b001_0000_0000,
				s_READ_DUMMY 		= 11'b010_0000_0000,
				s_READ_DIGEST		= 11'b100_0000_0000;


always@(posedge sys_clk) begin
	if(!sys_nrst) begin
		fifo_rd_req <= 0;
		fifo_wr_req <= 0;
		
		fetch_FSM <= s_fetch_IDLE;
		//=======================
		
		spi_enable <= 0;
		spi_wr_req <= 0;

		command_reg <= 0;

		program_error_code <= 0;
		spi_violation_err <= 0;
		spi_process_err <= 0;
		program_error <= 0;

		verify_done <= 0;

		delay_cnt <= 0;
		program_FSM <= s_program_IDLE;
	end
	else begin
		
		fifo_rd_req <= 0;
		fifo_wr_req <= 0;
		spi_wr_req <= 0;
		start_program <= 0;
		fifo_sync_rst <= 0;

		

		//temp
		out_fifo_rd_req <= 0;

		case(fetch_FSM)
			s_fetch_IDLE: begin
				// if(command_reg[0]) begin // receive image
				// 	fetch_cnt <= 0;
				// 	fetch_error <= 0;
				// 	fetch_FSM <= s_fetch_READ_FIFO;
				// end
				// else
				if(command_reg[3:1] != 0) begin // start fetch image
					fetch_cnt <= 0;
					fetch_error <= 0;
					calc_CRC <= `CRC16_START_VAL;
					CRC_cnt <= 0;
					component_cnt <= 0;
					component_num <= 0;
					fifo_sync_rst <= 1'b1;
					for(i=0; i<MAX_COMPONENT_NUMBER; i=i+1)
						component_size[i] <= 0;
					verify_done <= 0;

					fetch_FSM <= s_fetch_READ_FLASH;
				end
				else begin
					command_reg <= command;

					fetch_FSM <= s_fetch_IDLE;
				end
			end

			s_fetch_READ_FIFO: begin
				
			end

			s_fetch_READ_FLASH: begin
				if(out_fifo_rd_done) begin
					fetch_cnt <= fetch_cnt + 32'd2;
					fetch_buffer <= out_fifo_rd_data;
					fetch_FSM <= s_fetch_LOAD_IMAGE;
				end
				else begin
					out_fifo_rd_req <= 1'b1;
				end
			end

			s_fetch_LOAD_IMAGE: begin
				if(fetch_cnt <= 3'd6) begin // read image sizes
					fetch_FSM <= s_fetch_CALC_CRC;
					fetch_FSM_next <= s_fetch_READ_FLASH;

					case(fetch_cnt[2:1])
						2'd1: fetch_size[15:0] <= fetch_buffer;
						2'd2: fetch_size[31:16] <= fetch_buffer;
						2'd3: component_num <= fetch_buffer[4:0];
						default: begin
							fetch_error <= 1'b1;
							fetch_FSM <= s_fetch_IDLE;
						end
					endcase
				end
				else
				if(fetch_cnt <= image_header_size) begin // read component size
					if(fetch_cnt[1] == 0) begin
						component_size[component_cnt][15:0] <= fetch_buffer;
					end
					else begin
						component_size[component_cnt][21:16] <= fetch_buffer[5:0];
						component_cnt <= component_cnt + 1'b1;
					end
					
					if(component_num > MAX_COMPONENT_NUMBER) begin
						fetch_error <= 1'b1;
						fetch_FSM <= s_fetch_IDLE;
					end
					else begin
						fetch_FSM <= s_fetch_CALC_CRC;
						fetch_FSM_next <= s_fetch_READ_FLASH;
					end
				end
				else
				if(fetch_cnt == image_header_size + 8'd2) begin // check header CRC
					if(calc_CRC != fetch_buffer) begin // CRC error
						fetch_error <= 1'b1;
						fetch_FSM <= s_fetch_IDLE;
					end
					else begin
						if(command_reg[2]) 
							start_program <= 1'b1;
						fetch_FSM <= s_fetch_CALC_CRC;
						fetch_FSM_next <= s_fetch_READ_FLASH;
					end
				end
				else
				if(fetch_cnt < fetch_size) begin
					fetch_FSM <= (command_reg[3] | command_reg[2]) ? s_fetch_WRITE_FIFO : s_fetch_CALC_CRC;
					fetch_FSM_next <= s_fetch_READ_FLASH;
				end
				else begin
					if(command_reg[1]) begin
						if(calc_CRC != fetch_buffer) begin
							fetch_error <= 1'b1;	
						end
						else begin
							verify_done <= 1;
						end
					end

					// if((calc_CRC != fetch_buffer) & command_reg[1]) begin // image CRC error
					// 	fetch_error <= 1'b1;
					// end

					command_reg <= 0;
					fetch_FSM <= s_fetch_IDLE;
				end
			end

			s_fetch_CALC_CRC: begin
				if(CRC_cnt == 4'd15) begin
					CRC_cnt <= 0;
					fetch_FSM <= fetch_FSM_next;
				end
				else
					CRC_cnt <= CRC_cnt + 1'b1;

				calc_CRC <= {1'b0, calc_CRC[15:1]} ^ ((calc_CRC[0] ^ fetch_buffer[CRC_cnt]) ? `CRC16_POLY : 16'h00_00);
			end

			s_fetch_WRITE_FIFO: begin
				if(fifo_wr_done) begin
					fetch_FSM <= s_fetch_READ_FLASH;
				end
				else
					fifo_wr_req <= 1'b1;
			end

			s_fetch_WRITE_FLASH: begin
				
			end
		endcase
 //////////////////////////////////////////////////////////////////////

		case(program_FSM) 
			s_program_IDLE: begin
				if(start_program) begin
					program_done <= 0;
					program_error <= 0;
					program_error_code <= 0;
					program_FSM_next <= s_program_ISC_ENABLE;
					program_FSM <= s_program_GET_HWSTATUS;
				end
				else begin
					spi_enable <= 0;
				end
			end

			s_program_SPI_WAIT_1: begin
				if(delay_cnt == `SPI_WAIT_DELAY) begin
					delay_cnt <= 0;
					program_FSM <= s_program_GET_HWSTATUS; // s_program_GET_HWSTATUS;
				end
				else 
					delay_cnt <= delay_cnt + 1'b1;
			end

			s_program_GET_HWSTATUS: begin
				if(!spi_enable) begin
					if(!spi_busy) begin
						spi_enable <= 1'b1;
						spi_wr_req <= 1'b1;
						spi_wr_data <= `SPI_HWSTATUS;
					end
				end
				else begin
					if(spi_done) begin
						spi_enable <= 0;

						if(spi_rd_data[`SPI_VIOLATION_BIT] | spi_rd_data[`SPI_PROCESS_BIT]) begin // error occur
							spi_violation_err <= spi_rd_data[`SPI_VIOLATION_BIT];
							spi_process_err <= spi_rd_data[`SPI_PROCESS_BIT];

							if(spi_rd_data[`SPI_VIOLATION_BIT]) 
								program_error_code <= `SPI_VIOLATION_ERROR;
							else
								program_error_code <= `SPI_PROCESS_ERROR;
							
							program_error <= 1'b1;
							program_FSM <= s_program_IDLE;							
						end
						else if(spi_rd_data[`SPI_READY_BIT] & !spi_rd_data[`SPI_BUSY_BIT]) begin // target ready
							program_FSM <= s_program_SPI_WAIT_2; //program_FSM_next;							
						end
						else begin  // target busy
							delay_cnt <= 0;
							program_FSM <= s_program_SPI_WAIT_1;
						end
					end
				end
			end

			s_program_SPI_WAIT_2: begin
				if(delay_cnt == `SPI_WAIT_DELAY) begin
					delay_cnt <= 0;
					program_FSM <= program_FSM_next; // s_program_GET_HWSTATUS;
				end
				else 
					delay_cnt <= delay_cnt + 1'b1;
			end

			s_program_ISC_ENABLE: begin
				if(!spi_enable) begin
					if(!spi_busy) begin
						spi_enable <= 1'b1;
						spi_wr_req <= 1'b1;
						spi_wr_data <= `SPI_ISC_ENABLE;

						program_buffer <= `SPI_ISC_DATA;
						byte_cnt <= `SPI_ISC_DATA_SIZE;
					end
				end
				else begin
					if(spi_done) begin
						if(byte_cnt != 0) begin
							byte_cnt <= byte_cnt - 1'b1;

							spi_wr_req <= 1'b1;
							spi_wr_data <= program_buffer[(byte_cnt-1)*8 +: 8];
						end
						else begin
							spi_enable <= 0;
							program_FSM <= s_program_SPI_WAIT_1;
							program_FSM_next <= s_program_ISC_STATUS;
						end
					end
				end
			end

			s_program_ISC_STATUS: begin
				if(!spi_enable) begin
					if(!spi_busy) begin
						spi_enable <= 1'b1;
						spi_wr_req <= 1'b1;
						spi_wr_data <= `SPI_READ_DATA;
						
						//byte_cnt <= `SPI_ISC_DATA_SIZE;
					end
				end
				else begin
					if(spi_done) begin
						spi_enable <= 0;

						if(spi_rd_data[0]) begin
							program_error <= 1'b1;
							program_error_code <= `ISC_ENABLE_ERROR;
							program_FSM <= s_program_IDLE;
						end
						else begin
							program_FSM <= s_program_SPI_WAIT_1;
							program_FSM_next <= s_program_FRAME_INIT;
						end
					end
				end
			end

			s_program_FRAME_INIT: begin
				if(!spi_enable) begin
					if(!spi_busy) begin
						spi_enable <= 1'b1;
						spi_wr_req <= 1'b1;
						spi_wr_data <= `SPI_FRAME_INIT;
						
						byte_cnt = 1'b1;
					end
				end
				else begin
					if(spi_done) begin
						if(byte_cnt != 0) begin
							byte_cnt <= byte_cnt - 1'b1;

							spi_wr_req <= 1'b1;
							spi_wr_data <= {6'b0, command_reg[3:2]};
						end					
						else begin
							spi_enable <= 0;
							step_cnt <= s_INIT;
							program_FSM <= s_program_PROCESS_COMPONENTS;
						end	
					end
				end
			end

			// s_program_READ_COMPONENT_NUMBER: begin
			// 	fifo_rd_req <= 1'b1;

			// 	if(fifo_rd_done) begin
			// 		fifo_rd_req <= 0;

			// 		component_num <= fifo_rd_data[4:0];
			// 		step_cnt <= 0;
			// 		byte_cnt <= 0;
			// 		program_FSM <= s_program_READ_COMPONENT_SIZE;
			// 	end
			// end

			// s_program_READ_COMPONENT_SIZE: begin
			// 	fifo_rd_req <= 1'b1;

			// 	if(fifo_rd_done) begin
			// 		// if((step_cnt == component_num - 1'b1) && (byte_cnt[0] == 1'b1)) begin
			// 		// 	fifo_rd_req <= 0;
			// 		// 	program_FSM <= s_program_PROCESS_COMPONENTS;
			// 		// end

			// 		case(byte_cnt[0]) begin
			// 			4'd0: begin
			// 				component_size[step_cnt][15:0] <= fifo_rd_data;
			// 				byte_cnt <= byte_cnt + 1'b1;
			// 			end
			// 			4'd1: begin
			// 				component_size[step_cnt][21:16] <= fifo_rd_data[5:0];
			// 				byte_cnt <= 0;

			// 				if(step_cnt == component_num - 1'b1) begin
			// 					fifo_rd_req <= 0;
			// 					step_cnt <= s_INIT;
			// 					program_FSM <= s_program_PROCESS_COMPONENTS;
			// 				end
			// 				else 
			// 					step_cnt <= step_cnt + 1'b1;
			// 			end
			// 		end
			// 	end
			// end

			s_program_PROCESS_COMPONENTS: begin
				// if(spi_done) begin
					
				// end

				case(step_cnt)

					s_INIT: begin // init
						block_cnt <= 0;
						component_cnt <= 0;
						step_cnt <= s_CHECK_DEVICE;
					end

					s_SELECT_COMPONENT: begin
						block_cnt <= 0;
						component_cnt <= component_cnt + 1'b1;

						if(component_cnt == (component_num - 1'b1)) begin
							program_FSM <= s_program_SPI_WAIT_1;
							program_FSM_next <= s_program_ISC_DISABLE;
						end
						else
							step_cnt <= s_CHECK_DEVICE;
					end

					s_CHECK_DEVICE: begin	// check hwstatus
						program_FSM <= s_program_SPI_WAIT_1;
						program_FSM_next <= s_program_PROCESS_COMPONENTS;
						step_cnt <= s_START_TRSMT;
					end

					s_START_TRSMT: begin	// start block transmit
						spi_enable <= 1'b1;
						spi_wr_req <= 1'b1;
						spi_wr_data <= `SPI_FRAME_DATA;

						byte_cnt <= 0;
						step_cnt <= s_READ_FIFO;
					end

					s_READ_FIFO: begin // read fifo
						fifo_rd_req <= 1'b1;

						if(fifo_rd_done) begin
							fifo_rd_req <= 0;
							step_cnt <= s_SEND_BLOCK_DATA;
							program_buffer[15:0] <= fifo_rd_data;
						end
					end

					s_SEND_BLOCK_DATA: begin	// send 2 byte
						if(!spi_busy & !spi_wr_req) begin
							spi_wr_req <= 1'b1;
							byte_cnt <= byte_cnt + 1'b1;
							
							if(byte_cnt[0] == 1'b1) begin
								if(byte_cnt == (`SPI_FRAME_DATA_SIZE - 1'b1))
									step_cnt <= s_SET_BLOCK;
								else
									step_cnt <= s_READ_FIFO;
							end

							case(byte_cnt[0])
								1'b0: spi_wr_data <= program_buffer[7:0];
								1'b1: spi_wr_data <= program_buffer[15:8];
							endcase
						end
					end

					s_SET_BLOCK: begin // sum-up
						if(!spi_busy & !spi_wr_req) begin
							spi_enable <= 0;
							block_cnt <= block_cnt + 1'b1;

							if(block_cnt == (component_size[component_cnt] - 1'b1)) begin
								step_cnt <= s_INIT; // check digest here
								digest_cnt <= 0;
								program_FSM <= s_program_PROCESS_DIGEST;
							end
							else
								step_cnt <= s_CHECK_DEVICE;
						end
					end
				endcase
			end
			
			s_program_PROCESS_DIGEST: begin
				case(step_cnt) 
					s_INIT: begin
						byte_cnt <= 0;
						digest_cnt <= digest_cnt + 1'b1;
						rw_flag <= 1'b1;	// 1 - write cmd, 0 - read answer
						
						if(digest_cnt == 2'd3) begin
							step_cnt <= s_SELECT_COMPONENT;
							program_FSM <= s_program_PROCESS_COMPONENTS;
						end
						else
							step_cnt <= s_CHECK_DEVICE;
					end

					s_CHECK_DEVICE: begin	// check hwstatus
						program_FSM <= s_program_SPI_WAIT_1;
						program_FSM_next <= s_program_PROCESS_DIGEST;
						step_cnt <= s_START_TRSMT;
					end

					s_START_TRSMT: begin	// start block transmit
						spi_enable <= 1'b1;
						spi_wr_req <= 1'b1;
						spi_wr_data <= rw_flag ? `SPI_WRITE_DATA : `SPI_READ_DATA;

						byte_cnt <= 0;
						step_cnt <= rw_flag ? s_SEND_CMD : s_READ_DUMMY;
					end

					s_SEND_CMD: begin
						if(!spi_busy & !spi_wr_req) begin
							spi_wr_req <= 1'b1;
							spi_wr_data <= {{6{1'b0}}, digest_cnt};

							step_cnt <= s_SEND_DUMMY;
						end
					end

					s_SEND_DUMMY: begin
						if(!spi_busy & !spi_wr_req) begin
							spi_wr_req <= 1'b1;
							spi_wr_data <= 8'b0;

							byte_cnt <= byte_cnt + 1'b1;
							
							if(byte_cnt == (`SPI_FRAME_DATA_SIZE - 2'd1)) begin
								spi_enable <= 0;
								spi_wr_req <= 0;
								rw_flag <= 0;
								step_cnt <= s_CHECK_DEVICE;	
							end
						end						
					end

					s_READ_DUMMY: begin
						if(!spi_busy & !spi_wr_req) begin
							spi_wr_req <= 1'b1;
							spi_wr_data <= 8'b0;

							byte_cnt <= byte_cnt + 1'b1;

							if((digest_cnt == 2'd1 && byte_cnt == 5'd4) ||
							   (digest_cnt == 2'd2 && byte_cnt == 0	  ) ||
							   (digest_cnt == 2'd3 && byte_cnt == 0   )) begin
								byte_cnt <= 0;
								step_cnt <= s_READ_FIFO;
							end
						end
					end

					s_READ_FIFO: begin
						fifo_rd_req <= 1'b1;
						
						if(fifo_rd_done) begin
							fifo_rd_req <= 0;
							program_buffer[15:0] <= fifo_rd_data;
							step_cnt <= s_READ_DIGEST;
						end
					end

					s_READ_DIGEST: begin
						if(!spi_busy & !spi_wr_req) begin
							spi_wr_req <= 1'b1;
							spi_wr_data <= 8'd0;

							byte_cnt <= byte_cnt + 1'b1;

							if(spi_rd_data != (byte_cnt[0] ? program_buffer[15:8] : program_buffer[7:0])) begin // digest error handle
								spi_enable <= 0;
								spi_wr_req <= 0;
								program_error_code <= `DIGEST_CHECK_ERROR;
								program_error <= 1'b1;
								program_FSM <= s_program_IDLE;
							end

							if(byte_cnt[0] == 1'b1) begin
								if( (digest_cnt == 2'd1 && byte_cnt == 5'd11) ||
									(digest_cnt == 2'd2 && byte_cnt == 5'd15) ||
									(digest_cnt == 2'd3 && byte_cnt == 5'd3 )) begin
									spi_enable <= 0;
									spi_wr_req <= 0;
									step_cnt <= s_INIT;
								end
								else
									step_cnt <= s_READ_FIFO;
							end
						end
					end
				endcase
			end

			s_program_ISC_DISABLE: begin
				if(!spi_enable) begin
					if(!spi_busy & !spi_wr_req) begin
						spi_enable <= 1'b1;
						spi_wr_req <= 1'b1;
						spi_wr_data <= `SPI_ISC_DISABLE;
					end
				end
				else begin
					if(spi_done) begin
						spi_enable <= 0;
						program_FSM <= s_program_SPI_WAIT_1;
						program_FSM_next <= s_program_SPI_RELEASE;
					end
				end
			end

			s_program_SPI_RELEASE: begin
				if(!spi_enable) begin
					if(!spi_busy & !spi_wr_req) begin
						spi_enable <= 1'b1;
						spi_wr_req <= 1'b1;
						spi_wr_data <= `SPI_RELEASE;
					end
				end
				else begin
					if(spi_done) begin
						spi_enable <= 0;
						program_done <= 1'b1;
						program_FSM <= s_program_IDLE;
					end
				end
			end

			default: begin
				// handle fsm error				
			end
		endcase
	end
end


always@(negedge sys_clk) begin
	if(!sys_nrst) begin
		fifo_rd_done <= 0;
		fifo_wr_done <= 0;
		out_fifo_rd_done <= 0;
	end
	else begin
		fifo_rd_done <= fifo_rd_en;
		fifo_wr_done <= fifo_wr_en;
		out_fifo_rd_done <= out_fifo_rd_en;
	end
end


endmodule