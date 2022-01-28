#include "spi.h"

#include "logger.h"
#include "defines.h"

#define UART_BUFFER_SIZE 1024

uint8_t buffer[UART_BUFFER_SIZE];

QSerialPort *serialPort;
bool serialOpenned = false;
ActionThread *actionThread;

bool spi_connectDevice(const QString &portName)
{
    if(!serialOpenned) {
        serialPort->setPortName(portName);

        if(!serialPort->open(QIODevice::ReadWrite)) {
            //logError("Can't open serial");
            return false;
        }
        serialOpenned = true;
        //logPrint(QString("Port %1 opened").arg(portName));
        return true;
    }
    else
        return false;
}

void spi_disconnectDevice() {
    if(serialOpenned) {
        serialPort->close();
        serialOpenned = false;
        //logPrint(QString("Port %1 closed").arg(serialPort->portName()));
    }
}

void spi_init(QSerialPort *port, ActionThread *thread) {
    serialPort = port;
    actionThread = thread;
    serialPort->setBaudRate(464000);
    serialPort->setDataBits(QSerialPort::Data8);
    serialPort->setFlowControl(QSerialPort::NoFlowControl);
    serialPort->setParity(QSerialPort::NoParity);
    serialPort->setStopBits(QSerialPort::OneStop);
}

bool spi_transferBlock(uint8_t wrBytes, uint8_t *wrBuffer, uint8_t rdBytes, uint8_t *rdBuffer) {

    buffer[0] = CMD_SPI_TRANSFER;
    buffer[1] = wrBytes;
    buffer[2] = rdBytes;

    for(uint8_t i = 0; i < wrBytes; i++){
        buffer[i+3] = wrBuffer[i];
    }

    if(serialPort->write((char*)buffer, (3 + wrBytes)) != (3 + wrBytes)){
        logError("Serial write error: not all bytes send!!!");
        return false;
    }
    //serialPort->flush();

    uint8_t timeout = 20;
    while((serialPort->bytesAvailable() < 2) && timeout){
        timeout--;
        serialPort->waitForReadyRead(1);
    }

    if(!timeout){
        logError(QString("Serial read timeout!!! bytesAvailable: %1").arg(serialPort->bytesAvailable()));
        //return false;
    }

    buffer[0] = 0x00;
    serialPort->read((char*)buffer, 1);

    uint8_t numBytes;
    if(wrBytes) {
        numBytes = serialPort->read((char*)wrBuffer, wrBytes);
        if(numBytes != wrBytes){
            logError(QString("spi_transferBlock: loss of write bytes: read: %1 expect: %2").arg(numBytes).arg(wrBytes));
            actionThread->abortThread();
            return false;
        }
    }

    if(rdBytes) {
        numBytes = serialPort->read((char*)rdBuffer, rdBytes);
        if(numBytes != rdBytes){
            logError(QString("spi_transferBlock: loss of read bytes: read: %1 expect: %2").arg(numBytes).arg(rdBytes));
            actionThread->abortThread();
            return false;
        }
    }


    if(buffer[0] != CMD_SPI_TRANSFER){
        logError(QString("spi_transferBlock: wrong device answer!!!"));
        actionThread->abortThread();
        return false;
    }

    //serialPort->clear(QSerialPort::AllDirections);
    return true;
}

bool spi_transferTransaction(uint8_t wrBytes, uint8_t *wrBuffer, uint8_t numBlocks){

    if(!numBlocks)
        return true;

    if(serialPort->write((char*)wrBuffer, wrBytes) != wrBytes){
        logError("Serial write error: not all bytes send!!!");
        return false;
    }

    uint8_t timeout;

    for(int i = 0; i < numBlocks; i++) {

        timeout = 2;
        while(!serialPort->bytesAvailable() && timeout){
            timeout--;
            serialPort->waitForReadyRead(10);
        }

        if(!timeout){
            logError(QString("Serial read timeout!!! bytesAvailable: %1").arg(serialPort->bytesAvailable()));
            //return false;
        }

        buffer[0] = 0x00;
        serialPort->read((char*)buffer, 1);

        if(buffer[0] != CMD_SPI_TRANSFER){
            logError(QString("spi_transferTransaction: wrong device answer!!!"));
            actionThread->abortThread();
            return false;
        }
    }

    return true;
}

bool spi_getClockInfo(){
    RCC_ClocksTypeDef clockInfo;
    buffer[0] = CMD_SEND_CLK_INFO;

    uint8_t numBytes;
    numBytes = serialPort->write((char*)buffer, 1);

    if(numBytes != 1) {
        logError("Serial write error: not all bytes send!!!");
        return false;
    }

    if(!serialPort->waitForReadyRead(1000)){
        logError(QString("Serial read timeout!!!"));
        //return false;
    }

    buffer[0] = 0x00;
    serialPort->read((char*)buffer, 1);
    serialPort->read((char*)(&clockInfo), sizeof(clockInfo));

    if(buffer[0] != CMD_SEND_CLK_INFO){
        logError(QString("spi_getClockInfo: wrong device answer!!!"));
        actionThread->abortThread();
        return false;
    }

    logSrcMessage(QString("SYSCLK_Frequency: %1").arg(clockInfo.SYSCLK_Frequency), "getClockInfo");
    logSrcMessage(QString("HCLK_Frequency: %1").arg(clockInfo.HCLK_Frequency), "getClockInfo");
    logSrcMessage(QString("PCLK1_Frequency: %1").arg(clockInfo.PCLK1_Frequency), "getClockInfo");
    logSrcMessage(QString("PCLK2_Frequency: %1").arg(clockInfo.PCLK2_Frequency), "getClockInfo");
    //logSrcMessage(QString("ADCCLK_Frequency: %1").arg(clockInfo.ADCCLK_Frequency), "getClockInfo");

    return true;
}

bool spi_sendRowData(uint8_t bytes, uint8_t *data){
    serialPort->write((char*)data, bytes);

    if(!serialPort->waitForReadyRead(1000)){
        logError(QString("Serial read timeout!!!"));
        return false;
    }

    uint8_t numBytes = 0;
    numBytes = serialPort->read((char*)buffer, UART_BUFFER_SIZE);

    QString answer;
    for(int i = 0; i < numBytes; i++) {
        answer += QString("%1 ").arg(buffer[i], 2, 16, QChar('0'));
    }

    logSrcMessage(answer, "sendRowData");

    return true;
}
