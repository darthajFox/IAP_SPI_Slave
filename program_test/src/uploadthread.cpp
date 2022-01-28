#include "uploadthread.h"
#include "logger.h"
#include <QFile>

#define BUFFER_SIZE 2048
#define WR_EP_ID 0x02
#define RD_EP_ID 0x82

UploadThread::UploadThread(const QString &fileName, enum Action action)
{
    file = fileName;
    numAction = action;
}

void UploadThread::run() {
    switch(numAction) {
        case SEND_FIRMWARE: sendFirmware() ;  break;
        case SEND_CNT: sendCnt() ;            break;
    }
}

void UploadThread::sendFirmware() {
    QFile firmware(file);
    if(!firmware.open(QIODevice::ReadOnly))
    {
        logError(QString("Cannot open file %1").arg(file));
        return;
    }

    logPrint("Sending firmware...");

    /* Чтение и отправка прошивки */

    //char byteBuffer;
    int pack_cnt = 0;
    ULONG totalBytes = 0;
    ULONG bytesTransferred = 0;
    ulong bytesRead;
    uint32_t answer;
    UCHAR transmitterBuffer[BUFFER_SIZE];
    UCHAR readBuffer[BUFFER_SIZE/2];

    // flush fifo
    usb_sendCMD(8u);
    QThread::msleep(20);


    while(!firmware.atEnd())
    {
        bytesRead = firmware.read((char*)readBuffer, BUFFER_SIZE/2);

        // start program
        usb_sendCMD((6 << 8) | 6u);

        // get fifo state
        usb_sendCMD(4u);
        answer = usb_recieveANS();

        while(!((answer & (1 << 2)) || abortFlag)) { // while fifo isn't almost empty
            QThread::msleep(1);
            usb_sendCMD(4u);
            answer = usb_recieveANS();
        }

        if(answer & (7 << 5)){

            logPrint(QString("Program error occur %1 %2 %3").arg(answer&(1 << 7)).arg(answer&(1 << 6)).arg(answer&(1 << 5)));
            break;
        }

        // check abort condition
        if(abortFlag) {
            abortFlag = false;
            logPrint(QString("Uplading aborted on package %1").arg(pack_cnt));
            break;
        }

        if(bytesRead != (BUFFER_SIZE/2))
            logWarning(QString("Not full buffer size was read on package #%1").arg(pack_cnt));

        if(bytesRead % 2 != 0)
            logWarning(QString("Odd number of bytes read from file"));

        // filling transmitterBuffer
        for(int i = 0; i < (bytesRead/2); i++) {
            transmitterBuffer[i*4] = readBuffer[i*2];
            transmitterBuffer[i*4+1] = readBuffer[i*2+1];
            transmitterBuffer[i*4+2] = 0x00;
            transmitterBuffer[i*4+3] = 0x00;
        }


        // send data to fifo
        logPrint(QString("Sending package #%1").arg(pack_cnt));

        usb_sendCMD(((bytesRead/2) << 8) | 2u);                                                                 // check state here later!!!!!!!!!!!!
        ftStatus = FT_WritePipe(ftHandle, WR_EP_ID, transmitterBuffer, 2*bytesRead, &bytesTransferred, NULL);

        if(FT_FAILED(ftStatus)) {
            logPrint(QString("Error sending data, bytes written %1, status %2").arg(totalBytes).arg(ftStatus));
            return;
        }

        // get result
        answer = usb_recieveANS() * 4;

        if((bytesRead*2 == bytesTransferred) && (bytesTransferred == answer))
            logPrint(QString("package #%1 sent successfully").arg(pack_cnt));
        else
            logWarning(QString("package #%1 with issues: read %2, trasferred %3, written %4").arg(pack_cnt).arg(bytesRead).arg(bytesTransferred).arg(answer));

        totalBytes += bytesTransferred;
        pack_cnt++;
    }

    /* Отправляем остатки */

//    if(cur > 0)
//    {
//        ftStatus = FT_WritePipe(ftHandle, 0x02, transmitterBuffer, BUFFER_SIZE, &bytesTransferred, NULL);
//        totalBytes += bytesTransferred;
//    }
    //delete [] transmitterBuffer;

    //FT_AbortPipe(ftHandle, WR_EP_ID);

    logPrint(QString("Sent %1 bytes").arg(totalBytes));

    firmware.close();
}

void UploadThread::sendCnt() {

    int pack_cnt = 0;
    ULONG totalBytes = 0;
    uint32_t answer;
    uint64_t counter = 0;
    ULONG bytesTransferred = 0;

    UCHAR transmitterBuffer[BUFFER_SIZE];

    while(counter <= 1000000) {

        // get fifo state
        usb_sendCMD((1 << 2));
        answer = usb_recieveANS();

        // check fifo_empty_error
        if(answer & (1 << 3)) {
            logError(QString("Fifo empty error occur, package sent %1, bytes sent %2").arg(pack_cnt).arg(totalBytes));
            break;
        }

        while(!((answer & (1 << 2)) || abortFlag)) { // while fifo isn't almost empty
            QThread::msleep(1);
            usb_sendCMD((1 << 2));
            answer = usb_recieveANS();
        }

        // check abort request
        if(abortFlag) {
            abortFlag = false;
            logPrint(QString("Uplading aborted on package %1").arg(pack_cnt));
            return;
        }

        for(int i = 0; i < BUFFER_SIZE; i+= 4) {
//            if(counter == 500000)
//                transmitterBuffer[i] = 23;
//            else
                transmitterBuffer[i] = (counter & 0xff);

            transmitterBuffer[i+1] = ((counter >> 8) & 0xff);
            transmitterBuffer[i+2] = ((counter >> 16) & 0xff);
            transmitterBuffer[i+3] = ((counter >> 24) & 0xff);
            counter++;
        }

        usb_sendCMD(((BUFFER_SIZE/4) << 8) | (1 << 1));
        ftStatus = FT_WritePipe(ftHandle, WR_EP_ID, transmitterBuffer, BUFFER_SIZE, &bytesTransferred, NULL);

        if(FT_FAILED(ftStatus)) {
            logPrint(QString("Error sending data, bytes written %1, status %2").arg(totalBytes).arg(ftStatus));
            return;
        }

        // get result
        answer = usb_recieveANS() * 4;

        if(BUFFER_SIZE == bytesTransferred)
            logPrint(QString("package #%1 sent successfully").arg(pack_cnt));
        else
            logWarning(QString("package #%1 with issues: trasferred %2, written %3").arg(pack_cnt).arg(bytesTransferred).arg(answer));

        pack_cnt++;
        totalBytes += bytesTransferred;
        //QThread::msleep(1);
    }

    logPrint(QString("Sent %1 bytes, job done!!!").arg(totalBytes));
}
