`timescale 1ns/1ns

module programmer_tb();

	reg 			sys_clk;
	reg 			sys_nrst;

	// programmer i/o
    reg             fifo_empty;
    reg [15:0]      fifo_rd_data;
    wire            fifo_rd_en;
    
    reg [15:0]  	command_reg;
    wire            program_done;
    wire            verify_done;
    wire            program_error;
    wire            spi_violation_err;
    wire            spi_process_err;

	// SPI i/o
	wire 			SCK;
	wire			MOSI;
	wire 			NSS;
	reg 			MISO;


parameter CLK = 10;
parameter DELAY = CLK*10;


programmer #(
    .FLASH_OFFSET                    (0),
    .MAX_COMPONENT_NUMBER            (4)
) 
programmer_dut(
    .sys_clk           (sys_clk           ),
    .sys_nrst          (sys_nrst          ),
    
    .out_fifo_empty    (fifo_empty        ),
    .out_fifo_rd_data  (fifo_rd_data      ),
    .out_fifo_rd_en    (fifo_rd_en        ),

    .command           (command_reg       ),
    .program_done      (program_done      ),
    .verify_done       (verify_done       ),
    .program_error     (program_error     ),
    .spi_violation_err (spi_violation_err ),
    .spi_process_err   (spi_process_err   ),

    .MISO              (MISO              ),
    .MOSI              (MOSI              ),
    .SCK               (SCK               ),
    .NSS               (NSS               )
);


initial
begin
    sys_clk = 0;
    forever #(CLK/2) sys_clk = !sys_clk;
end

integer imageFile;
integer digestFile;

reg [7:0] byte;
always@(negedge sys_clk) begin
    fifo_empty = ($feof(imageFile) != 0);
    if(fifo_rd_en && !fifo_empty) begin
        $fread(byte, imageFile);
        fifo_rd_data[7:0] = byte;
        $fread(byte, imageFile);
        fifo_rd_data[15:8] = byte;
    end
end

reg [7:0]   spi_cmd;
reg [7:0]   spi_data;
reg         spi_cmd_val;
integer spi_cnt;
always@(negedge NSS) begin
    spi_cnt = 7;
    spi_cmd_val = 0;
    repeat(8) begin
        @(negedge SCK);
        if(spi_cnt == 1) MISO = 1;
        else MISO = 0; 

        @(posedge SCK) spi_cmd[spi_cnt] = MOSI;
        spi_cnt = spi_cnt - 1;
    end
    spi_cmd_val = 1;
    @(posedge NSS);
    spi_cmd_val = 0;
end

always@(posedge SCK) begin
    if(!NSS && spi_cmd_val) begin
        if(spi_cnt == -1)
            spi_cnt = 7;

        spi_data[spi_cnt] = MOSI;
        spi_cnt = spi_cnt - 1;
    end
end

reg flag;
wire cond = (spi_cmd_val && (spi_cmd == 8'h01));

initial
begin
    imageFile = $fopen("image_blink_led0.dat", "rb");
    digestFile = $fopen("binary_digest.bin", "rb");
    sys_nrst = 0;
    MISO = 0;
    command_reg = 0;
    flag = 0;
    #DELAY;

    sys_nrst = 1;
    #DELAY;

    command_reg = {12'b0, 4'b0110};
    #(DELAY*1000);
    command_reg = 0;

    // digest 1
    wait(spi_cmd_val && (spi_cmd == 8'h01));
    flag = 1;

    // #(DELAY*100);
    // wait(spi_cmd_val && (spi_cmd == 8'h01));
    //ddf7c6e71af1ec783ae3ac629984e579a8843f82
    repeat(4) put_data(0);
    repeat(12) begin
        $fread(byte, digestFile);
        put_data(byte);
    end

    #DELAY;
    wait(spi_cmd_val && (spi_cmd == 8'h01));
    repeat(16) begin
        $fread(byte, digestFile);
        put_data(byte);
    end

    #DELAY;
    wait(spi_cmd_val && (spi_cmd == 8'h01));
    repeat(4) begin
        $fread(byte, digestFile);
        put_data(byte);
    end

    // digest 2
    #DELAY;
    wait(spi_cmd_val && (spi_cmd == 8'h01));
    repeat(4) put_data(0);
    repeat(12) begin
        $fread(byte, digestFile);
        put_data(byte);
    end

    #DELAY;
    wait(spi_cmd_val && (spi_cmd == 8'h01));
    repeat(16) begin
        $fread(byte, digestFile);
        put_data(byte);
    end

    #DELAY;
    wait(spi_cmd_val && (spi_cmd == 8'h01));
    repeat(4) begin
        $fread(byte, digestFile);
        put_data(byte);
    end

    // digest 3
    #DELAY;
    wait(spi_cmd_val && (spi_cmd == 8'h01));
    repeat(4) put_data(0);
    repeat(12) begin
        $fread(byte, digestFile);
        put_data(byte);
    end

    #DELAY;
    wait(spi_cmd_val && (spi_cmd == 8'h01));
    repeat(16) begin
        $fread(byte, digestFile);
        put_data(byte);
    end

    #DELAY;
    wait(spi_cmd_val && (spi_cmd == 8'h01));
    repeat(4) begin
        $fread(byte, digestFile);
        put_data(byte);
    end

    wait((program_done ==1) | (program_error == 1));

    // put_data(8'hec); //1
    // put_data(8'hd3);
    // put_data(8'hec);
    // put_data(8'h84);
    // put_data(8'hff);
    // put_data(8'hb7);
    // put_data(8'h98);
    // put_data(8'hbb);
    // put_data(8'hd5);
    // put_data(8'h73); 
    // put_data(8'hc6); 
    // put_data(8'h09); // 12
    

    #(DELAY*100);
    $fclose(imageFile);
    $stop;
end

task automatic put_data;
	input [7:0] data;
	integer i;
	begin
		i = 7;
		repeat(8) begin
			@(negedge SCK) MISO <= data[i];
			i = i - 1;
		end
	end
endtask

endmodule



