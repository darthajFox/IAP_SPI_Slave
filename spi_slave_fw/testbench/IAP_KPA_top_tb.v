`timescale 1ns/1ns

module IAP_KPA_top_tb();

	reg 			sys_clk;
	reg 			nrst;
	wire [7:0] 		LED;

	// FTDI i/o
	reg 			RXF_N;
	reg 			TXE_N;
	wire 			OE_N;
	wire 			RD_N;
	wire 			WR_N;
	wire [3:0]		BE;
	wire [31:0]		DATA;

	// SPI i/o
	reg 			SCK;
	reg				MOSI;
	reg 			nCS;
	wire 			MISO;


parameter CLK = 10;
parameter SPI_CLK = 50;
parameter DELAY = CLK*10;

reg [31:0] 	DATA_reg;
assign 	DATA = OE_N ? 32'bz : DATA_reg;

reg [3:0] 	BE_reg;	
assign 	BE = OE_N ? 4'bz : BE_reg;

IAP_KPA_top dut0(
	.clk100_in(sys_clk),
	.nrst_in(nrst),
	.LED(LED),

	.RXF_N(RXF_N),
	.TXE_N(TXE_N),
	.OE_N(OE_N),
	.RD_N(RD_N),
	.WR_N(WR_N),
	.BE(BE),
	.DATA(DATA),

	.SCK(SCK),
	.MOSI(MOSI),
	.MISO(MISO),
	.nCS(nCS)
);

initial
begin
    sys_clk = 0;
    forever #(CLK/2) sys_clk = !sys_clk;
end

initial begin
	SCK = 0;
	forever #(SPI_CLK/2) SCK = !SCK;
end



initial
begin
	nrst = 0;
	TXE_N = 1;
	RXF_N = 1;
	nCS = 1;


    #(DELAY*10);
    nrst = 1;
    // DATA_reg = 32'h00_00_01_01;
    // BE_reg = 4'hf;

    // #(DELAY*2);
    // RXF_N = 0;

    // @(posedge OE_N);
    // RXF_N = 1;


    #(DELAY*3);
    wait(SCK == 1);

    nCS = 0;
    put_data(8'h5A);

    // тайминги не рандомные, они пришли мне свыше!!!

    #10000;
    nCS = 1;
    
    #500;
    nCS = 0;
    put_data(8'h0b);

    #10000;
    nCS = 1;
    
    #500;
    nCS = 0;
    put_data(8'h0b);

    #10000;
    nCS = 1;
    
    #500;
    nCS = 0;
    put_data(8'h0b);

    #10000;
    nCS = 1;
    
    #500;
    nCS = 0;
    put_data(8'h5a);

    #10000;
    nCS = 1;
    
    #500;
    nCS = 0;
    put_data(8'h0b);


    #(DELAY*100);
    $stop;
end

task automatic put_data;
	input [7:0] data;
	integer i;
	begin
		i = 7;
		repeat(8) begin
			@(negedge SCK) MOSI <= data[i];
			i = i - 1;
		end
	end
endtask

endmodule