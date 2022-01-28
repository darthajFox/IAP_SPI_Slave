#ifndef SPI_H
#define SPI_H

#include <QString>
#include <QSerialPort>
#include <QObject>
#include "actionthread.h"

typedef struct
{
    uint32_t SYSCLK_Frequency;  /*!< returns SYSCLK clock frequency expressed in Hz */
    uint32_t HCLK_Frequency;    /*!< returns HCLK clock frequency expressed in Hz */
    uint32_t PCLK1_Frequency;   /*!< returns PCLK1 clock frequency expressed in Hz */
    uint32_t PCLK2_Frequency;   /*!< returns PCLK2 clock frequency expressed in Hz */
    uint32_t ADCCLK_Frequency;  /*!< returns ADCCLK clock frequency expressed in Hz */
} RCC_ClocksTypeDef;

//class SPI : public QObject
//{

//public slots:
//    void transferBlock(uint8_t, uint8_t*, uint8_t, uint8_t*);
//};

bool spi_connectDevice(const QString&);
void spi_disconnectDevice();

void spi_init(QSerialPort*, ActionThread*);
bool spi_transferBlock(uint8_t, uint8_t*, uint8_t, uint8_t*);
bool spi_transferTransaction(uint8_t, uint8_t*, uint8_t);
bool spi_getClockInfo();
bool spi_sendRowData(uint8_t, uint8_t*);

#endif // SPI_H
