
module programmer_top(

	//general i/o
	input 			clk100_in,
	input 			nrst_in,
	output [7:0] 	LED,

	// FTDI i/o
	input 			RXF_N,
	input 			TXE_N,
	output 			OE_N,
	output 			RD_N,
	output 			WR_N,
	inout [3:0]		BE,
	inout [31:0]	DATA,

	// SPI i/o
	input 			MISO,
	output 			SCK,
	output			MOSI,
	output 			NSS,

	output [11:0]	debug_io
);

wire sys_clk100;
wire pll_rst = 1'b0;
wire pll_locked;

ft_pll pll_0(
	.refclk   (clk100_in),   //  refclk.clk
	.rst      (pll_rst),      //   reset.reset
	.outclk_0 (sys_clk100),	 // outclk0.clk
	.locked   (pll_locked)
);

wire		ft_rd_req;
wire 		ft_wr_req;
wire [31:0]	ft_wr_data;
wire [9:0]	ft_rd_word_cnt;
wire 		ft_wr_rdy;
wire 		ft_rd_rdy;
wire [31:0]	ft_rd_data;
wire 		ft_done;
wire 		ft_busy;
wire 		ft_data_valid;

ftdi_xcvr xcvr_0(
	.ft_clk(sys_clk100),
	.sys_nrst(nrst_in),

	.TXE_N(TXE_N),
	.RXF_N(RXF_N),
	.OE_N(OE_N),
	.RD_N(RD_N),
	.WR_N(WR_N),
	.BE(BE),
	.DATA(DATA),

	.rd_req(ft_rd_req),
	.wr_req(ft_wr_req),
	.wr_data(ft_wr_data),
	.rd_word_cnt(ft_rd_word_cnt),

	.wr_rdy(ft_wr_rdy),
	.rd_rdy(ft_rd_rdy),

	.rd_data(ft_rd_data),
	.done(ft_done),
	.busy(ft_busy),
	.data_valid(ft_data_valid)
);

wire 		fifo_empty;
wire 		fifo_full;
wire 		fifo_almost_empty;
wire		fifo_wr_req;
wire [15:0]	fifo_wr_data;
wire 		fifo_sync_rst;

xcvr_control xcvr_control_0(
	.sys_clk(sys_clk100),
	.sys_nrst(nrst_in),
	.LED(LED[2:0]),

	// ftdi
	.wr_rdy(ft_wr_rdy),
	.rd_rdy(ft_rd_rdy),
	.ft_data_valid(ft_data_valid),
	.ft_done(ft_done),
	.rd_data(ft_rd_data),

	.wr_req(ft_wr_req),
	.rd_req(ft_rd_req),
	.rd_word_cnt(ft_rd_word_cnt),
	.wr_data(ft_wr_data),

	// fifo
	.fifo_empty(fifo_empty),
	.fifo_full(fifo_full),
	.fifo_almost_empty(fifo_almost_empty),
	.fifo_wr_req(fifo_wr_req),
	.fifo_sync_rst(fifo_sync_rst),
	.fifo_wr_data(fifo_wr_data),

	.debug_check_fifo(debug_check_fifo),
	.debug_fill_fifo(debug_fill_fifo),

	// programmer
	.program_done(program_done),
	.verify_done(verify_done),
	.program_error(program_error),

	.spi_violation_err(spi_violation_err),
	.spi_process_err(spi_process_err),
	.programmer_command(programmer_cmd)
);

wire 		fifo_rd_en;
wire [15:0]	fifo_rd_data;

fifo16_2k  fifo_0(
	.clock(!sys_clk100),
	.sclr(!nrst_in | fifo_sync_rst),
	.wrreq(fifo_wr_req),
	.data(fifo_wr_data),

	.rdreq(fifo_rd_en),
	.q(fifo_rd_data),

	.full(fifo_full),
	.empty(fifo_empty),
	.almost_empty(fifo_almost_empty)
);

// wire read_data_valid;
// wire write_enable;

// hispi hispi_0(
// 	.sys_clk(sys_clk100),
// 	.sys_nrst(nrst_in),

// 	.SCK(SCK),
// 	.MOSI(MOSI),
// 	.nCS(nCS),
// 	.MISO(MISO),

// 	.fifo_empty(fifo_empty),
// 	.fifo_request(fifo_rd_req),
// 	.fifo_data(fifo_rd_data),

// 	.fifo_empty_error(fifo_empty_error)
// 	//.read_data_valid(read_data_valid),
// 	//.write_enable(write_enable)
// );

wire [15:0] programmer_cmd;
wire 	program_done;
wire 	verify_done;
wire 	program_error;
wire 	spi_violation_err;
wire 	spi_process_err;

programmer 
#(
	.FLASH_OFFSET                    (0),
	.MAX_COMPONENT_NUMBER            (4)
)
u_programmer(
	.sys_clk           (sys_clk100        ),
	.sys_nrst          (nrst_in           ),
	.MISO              (MISO              ),
	.MOSI              (MOSI              ),
	.SCK               (SCK               ),
	.NSS               (NSS               ),
	.command           (programmer_cmd    ),
	.out_fifo_empty    (fifo_empty    ),
	.out_fifo_rd_data  (fifo_rd_data  ),
	.out_fifo_rd_en    (fifo_rd_en    ),
	.program_done      (program_done      ),
	.verify_done       (verify_done       ),
	.program_error     (program_error     ),
	.spi_violation_err (spi_violation_err ),
	.spi_process_err   (spi_process_err   )
);


//assign debug_io[8]	= MISO;
//assign debug_io[7:6] = {read_data_valid, write_enable};
//assign debug_io[3:0] = {fifo_empty_error, debug_fill_fifo, debug_check_fifo, fifo_empty};

assign LED[4] = fifo_empty;
assign LED[6:5] = {program_done, program_error};
assign LED[7] = verify_done;

assign debug_io[3:0] = {fifo_wr_req, fifo_rd_en, fifo_almost_empty, fifo_sync_rst};
assign debug_io[5:4] = {spi_violation_err, spi_process_err};
assign debug_io[7:6] = {program_error, program_done};
assign debug_io[11:8] = {MISO, MOSI, SCK, NSS};


endmodule