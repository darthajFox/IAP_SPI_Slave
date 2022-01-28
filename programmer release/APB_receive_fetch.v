

module APB_receive_fetch
#(
    parameter       //ADDR_WIDTH = 6,

)
(
    // input 		    	sys_clk,	
	// input 		    	sys_nrst,

    // APB BUS
    output reg             IRQ_request,

    input                  PRESETN,
    input                  PCLK,
    input                  PSEL,
    input                  PWRITE,
    input                  PENABLE,
    input [7:0]            PADDR,
    input [15:0]           PWDATA,
    output                 PREADY,
    output                 PSLVERR,
    output [15:0]          PRDATA,

    // fifo i/o
    input               fifo_empty,
    input               fifo_full,
    input [15:0]        fifo_rd_data,
    output              fifo_rd_en,
    output              fifo_wr_en,
    output reg [15:0]   fifo_wr_data,

    // program_fsm i/o


);

// ============= MEMORY MAP =============== 
// ADDR - REG NAME
// 0 - APB request ADDR 
// 1 - APB request DATA
// 3 - P0MAPCount
// 4 - P0SStatus
// 5 - P0TCRC
// 6  - P0CFlag0
// ...
// 13 - P0CFlag7
// 14 - P1NumOfParts
// 15 - P1SStatus
// 16 - P1MAPCount
// 17 - Calculated_CRC
// 18 - P1TCRC
// ===================
// 19 - Command
// 20 - ImageCRC
// 21 - Data word0 
// ..
// 52 - Data word31

localparam RD_MEMORY_SIZE = 53; // in 2B-words
localparam MEMEORY_SIZE = 12;

localparam APB_REQ_ADDR     = 0;
localparam APB_REQ_DATA     = 1;
localparam P0MAPCount       = 3;
localparam P0SStatus        = 4;
localparam P0TCRC           = 5; 
localparam P1NumOfParts     = 14;
localparam P1SStatus        = 15;
localparam P1MAPCount       = 16;
localparam Calc_CRC         = 17;
localparam P1TCRC           = 18;
localparam Command          = 19;
localparam ImageCRC         = 20;

localparam P0CFlag_0        = 6;    
localparam DataWord         = 21;

reg [15:0] memory [MEMEORY_SIZE-1:0];
reg [127:0] P0CFlag_reg;

wire [15:0] rd_memory_bus [MEMORY_SIZE-1:0];

// assign apb read bus
assign rd_memory_bus[APB_REQ_ADDR] = memory[APB_REQ_ADDR];
assign rd_memory_bus[APB_REQ_DATA] = memory[APB_REQ_DATA];
assign rd_memory_bus[P0MAPCount] = memory[P0MAPCount];
assign rd_memory_bus[P0SStatus] = memory[P0SStatus];
assign rd_memory_bus[P0TCRC] = memory[P0TCRC];
assign rd_memory_bus[P1NumOfParts] = memory[P1NumOfParts];
assign rd_memory_bus[P1SStatus] = memory[P1SStatus];
assign rd_memory_bus[P1MAPCount] = memory[P1MAPCount];
assign rd_memory_bus[Calc_CRC] = memory[Calc_CRC];
assign rd_memory_bus[P1TCRC] = memory[P1TCRC];
assign rd_memory_bus[Command] = memory[Command];
assign rd_memory_bus[ImageCRC] = memory[ImageCRC];

genvar g;
generate
    for(g = P0CFlag_0; g < P0CFlag_0+8; g = g+1)
    begin:assign_P0CFlag
        assign rd_memory_bus[g] = P0CFlag_reg[(g*16+15) : g*16];
    end

    for(g = DataWord; g < DataWord+32; g=g+1)
    begin:assign_DataWord
        assign rd_memory_bus[g] = 16'b0;
    end
endgenerate

// apb read transfer
wire PREADY_rd;
wire PSLVERR_rd;
assign PREADY_rd = PSEL & PENABLE & (!PWRITE);
assign PSLVERR_rd = PREADY_rd & (PADDR > RD_MEMORY_SIZE-1);

// apb write transfer
wire PREADY_wr;
wire PSLVERR_wr;
assign PREADY_wr = PSEL & PENABLE & PWRITE;
assign PSLVERR_wr = PREADY_wr & ((PADDR > RD_MEMORY_SIZE-1) | ( (PADDR>=P0CFlag_0)&(PADDR<=P0CFlag_0+7) ));

assign PREADY = PREADY_rd | PREADY_wr;
assign PSLVERR = PSLVERR_rd | PSLVERR_wr;

assign PRDATA = (PREADY_rd & !PSLVERR_rd) rd_memory_bus[PADDR] : 16'b0;

integer i;

always@(posedge PCLK) begin
    if(!PRESETN) begin
        for(i = 0; i < MEMEORY_SIZE; i = i+1) begin
            memory[i] <= 
        end
    end
    else begin
        



    end
end



endmodule


