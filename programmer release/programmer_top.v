

module programmer_top
#(
    parameter   

)
(
    // APB BUS
    output                 IRQ_request,

    input                  PRESETN,
    input                  PCLK,
    input                  PSEL,
    input                  PENABLE,
    input                  PWRITE,
    output                 PSLVERR,
    output                 PREADY,
    input [7:0]            PADDR,
    input [APB_WIDTH-1:0]  PWDATA,
    output [APB_WIDTH-1:0] PRDATA,

    // SPI i/o
    input 			MISO,
	output			MOSI,
	output			SCK,
	output 			NSS
);




endmodule