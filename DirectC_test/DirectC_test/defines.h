#ifndef __DEFINES_H
#define __DEFINES_H

#define CMD_SEND_CLK_INFO 			0x10
#define CMD_SEND_FIFO_ERR_FLAGS		0x20
#define CMD_SPI_TRANSFER  			0xA5
#define CMD_ENABLE_SPI 				0x11
#define CMD_DISABLE_SPI				0x21
//#define CMD_EN_SSOE					0x41
//#define CMD_DIS_SSOE				0x81
#define CMD_SEND_SPI_ST				0x12

//#define READ_FROM_SPI 			0x80

#define ST_UART_COMMAND_ERR			0xF5
#define ST_UART_BYTES_LOSS			0x7A
#define ERR_SPI_TIMEOUT				0x3E


#endif // __DEFINES_H
