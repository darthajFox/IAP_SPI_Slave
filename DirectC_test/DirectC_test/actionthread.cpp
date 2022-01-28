#include "actionthread.h"
#include "logger.h"
#include "spi.h"
#include <QFile>

// DirectC
#include "dpuser.h"
#include "dputil.h"   // display functions
//#include "dpDUTspi.h"
//#include "dpcom.h"
#include "dpalg.h"    // dp_top function

uint8_t *image_buffer;

ActionThread::ActionThread(ThreadJob job, const QString &file, uint8_t action, const QString& portNum)
{
    fileName = file;
    numAction = action;
    image_buffer = nullptr;
    portName = portNum;
    jobType = job;
    //serialPort = port;
    //parentThread = thread;
}

ActionThread::~ActionThread(){

    if(image_buffer != nullptr)
        delete [] image_buffer;
}

void ActionThread::run() {
//    switch(numAction) {
//        case PERF_ACTION: performAction() ;  break;
//    }

    logPrint(QString("Action thread id: %1").arg((uint64_t)QThread::currentThread(), 0, 16));

    serialPort = new QSerialPort();
    spi_init(serialPort, this);
    spi_connectDevice(portName);

    switch(jobType){
        case ACTION:
            performAction();
        break;

        case CLOCK:
            spi_getClockInfo();
        break;

        case TEST:
            testSend();
        break;
    }

    spi_disconnectDevice();

    delete serialPort;

    //serialPort->moveToThread(parentThread);
}


void ActionThread::performAction() {
    switch(numAction){
    case DP_PROGRAM_ACTION_CODE:
    case DP_VERIFY_ACTION_CODE:
        if(!loadFirmware()){
            logSrcMessage(QString("LoadFirmware error, exiting..."), "ActionThread");
            return;
        }
        break;
    }

    Action_code = numAction;
    logSrcMessage(QString("Action code: %1").arg(numAction), "ActionThread");
    dp_top();
}

void ActionThread::testSend(){
    uint8_t buffer[8];
    uint8_t buffer2[8];
    buffer[0] = 0x21;
    buffer[1] = 0x22;
    buffer[2] = 0x23;
    buffer[3] = 0x24;


    for(uint32_t i = 0; i < 0xffff; i++) {
        spi_transferBlock(4, buffer, 0, buffer2);
        if(i == 100){
            abortThread();
        }
    }
}

void ActionThread::abortThread(){
    spi_disconnectDevice();
    delete serialPort;
    this->terminate();
}

bool ActionThread::loadFirmware(){
    QFile firmware(fileName);

    if(!firmware.open(QIODevice::ReadOnly)) {
        logError("Can't open firmware file");
        return false;
    }

    uint64_t imageSize = firmware.size();
    logPrint(QString("image size = %1").arg(imageSize));
    //QThread::sleep(5);

    if(image_buffer != nullptr)
        delete [] image_buffer;

    image_buffer = new uint8_t[imageSize];
    firmware.read((char*)image_buffer, imageSize);
    firmware.close();

    logPrint("Load firmware successfully");

    return true;
}

