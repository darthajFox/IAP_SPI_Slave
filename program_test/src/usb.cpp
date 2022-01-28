#include "usb.h"
#include <QFile>
#include <QThread>
#include "uploadthread.h"


#define BUFFER_SIZE 1024
#define WR_EP_ID 0x02
#define RD_EP_ID 0x82

FT_DEVICE_LIST_INFO_NODE* deviceInfo = nullptr;
FT_HANDLE ftHandle;
FT_STATUS ftStatus;
bool abortFlag = false;
UploadThread *uploadThread;

bool usb_getDevicesList(QList<QString> *array)
{
    DWORD deviceCount;
    ftStatus = FT_CreateDeviceInfoList(&deviceCount);

    if(FT_FAILED(ftStatus))
    {
        logError("Cannot create device list");
        return 1;
    }

    if(deviceCount == 0)
    {
        logWarning("Device not found");
        return 1;
    }

    logPrint(QString("Device detected: %1").arg(deviceCount));
    array->reserve(deviceCount);

    deviceInfo = new FT_DEVICE_LIST_INFO_NODE[deviceCount];
    ftStatus = FT_GetDeviceInfoList(deviceInfo, &deviceCount);

    if(FT_FAILED(ftStatus))
    {
        logError("Cannot get device list");
        return 1;
    }

    for(DWORD i = 0; i < deviceCount; i++)
    {
        array->push_back(QString("%1 %2").arg(deviceInfo[i].Description).arg(deviceInfo[i].SerialNumber));

        logPrint(QString("Device [%1]").arg(i));
        logPrint(QString("Flags = 0x%1\nUSB = %2\nType = %3\nGUID = 0x%4")
                 .arg(deviceInfo[i].Flags, 0, 16)
                 .arg(deviceInfo[i].Flags & FT_FLAGS_SUPERSPEED ? QString("3.0") :
                      deviceInfo[i].Flags & FT_FLAGS_HISPEED ? QString("2.0") :
                      deviceInfo[i].Flags & FT_FLAGS_OPENED ? QString("1.0") : QString("?"))
                 .arg(deviceInfo[i].Type)
                 .arg(deviceInfo[i].ID, 0, 16));

        logPrint(QString("Serial = %1").arg(deviceInfo[i].SerialNumber));
        logPrint(QString("Description = \"%1\"").arg(deviceInfo[i].Description));
    }

    return 0;
}

bool usb_connect(int id)
{
    if(deviceInfo == nullptr)
        return 1;

    ftStatus = FT_Create(&deviceInfo[id].SerialNumber, FT_OPEN_BY_SERIAL_NUMBER, &ftHandle);
    FT_SetSuspendTimeout(ftHandle, 0);

    QString deviceName = QString("%1 (Serial=0x%2)").arg(deviceInfo[id].Description).arg(deviceInfo[id].SerialNumber, 0, 16);

    if(FT_FAILED(ftStatus))
    {
        logError(QString("Cannot get to device %1").arg(deviceName));
        return 1;
    }

    logPrint(QString("Device %1 connected").arg(deviceName));
    abortFlag = false;

    return 0;
}

void usb_disconnect()
{
    abortFlag = true;
    FT_Close(ftHandle);
    logPrint("Device disconnected");
}

void usb_sendCMD(uint32_t command) {
    ulong byteWritten;
    ulong bufferSize = 4;
    uchar sendBuf[] = {(uchar)(command & 0xff),
                       (uchar)((command >> 8) & 0xff),
                       (uchar)((command >> 16) & 0xff),
                       (uchar)((command >> 24) & 0xff)};
    ftStatus = FT_WritePipe(ftHandle, WR_EP_ID, sendBuf, bufferSize, &byteWritten, NULL);

    if(FT_FAILED(ftStatus)) {
        logPrint(QString("Error occur while sending command, bytes written %1, status %2").arg(byteWritten).arg(ftStatus));
        abortFlag = true;
    }
    //logPrint(QString("Command %2 sent, bytes written %1, status %4").arg(byteWritten).arg(command, 8, 16).arg(ftStatus));
}

uint32_t usb_recieveANS() {
    ulong byteRead;
    ulong bufferSize = 4;
    uchar buffer[bufferSize];
    uint32_t answer;

    ftStatus = FT_ReadPipe(ftHandle, RD_EP_ID, buffer, bufferSize, &byteRead, NULL);

    if(FT_FAILED(ftStatus))
    {
        logError(QString("Failed recieveing answer, status %1").arg(ftStatus));
        abortFlag = true;
        return 1;
    }

    answer = (buffer[3] << 24) | (buffer[2] << 16) | (buffer[1] << 8) | buffer[0];
    return answer;
}

void usb_sendInitData() {
    uint32_t wordsWrittenToFifo = 0;
    ulong bytesSent = 0;
    uchar buffer[4];
    usb_sendCMD((1<<1) | (1 << 8));

//    buffer[0] = 0x00;
//    buffer[1] = 0x00;
//    buffer[2] = 0x00;
//    buffer[3] = 0x00; //

    buffer[0] = 0x0A;
    buffer[1] = 0x00;
    buffer[2] = 0x00; //
    buffer[3] = 0x00; //

//    buffer[8] =  0xAA;
//    buffer[9] =  0xCE;
//    buffer[10] = 0xBB;
//    buffer[11] = 0x00;

    ftStatus = FT_WritePipe(ftHandle, WR_EP_ID, buffer, 4, &bytesSent, NULL);

    if(FT_FAILED(ftStatus)) {
        logPrint(QString("Error occur while sending command, bytes written %1, status %2").arg(bytesSent).arg(ftStatus));
    }

    wordsWrittenToFifo = usb_recieveANS();
    if(wordsWrittenToFifo != 1)
        logError(QString("Init failed, words written %1").arg(wordsWrittenToFifo));
    else
        logPrint("Init successfuly");
}

//uint32_t usb_sendToFifo(uchar *data, uint8_t numBytes) {
//    uint32_t bytesWrittenToFifo = 0;
//    ulong bytesSent = 0;
//    uint8_t numWords = (numBytes >> 2) + (numBytes % 4 ? 1 : 0); //custom ceil
//    usb_sendCMD((1<<1) | (numWords << 8));

//    ftStatus = FT_WritePipe(ftHandle, WR_EP_ID, data, numBytes, &bytesSent, NULL);

//    if(FT_FAILED(ftStatus)) {
//        logPrint(QString("Error occur while sending command, bytes written %1, status %2").arg(bytesSent).arg(ftStatus));
//    }

//    bytesWritten = usb_recieveANS();
//    return bytesWritten;
//}

void usb_upload(const QString &file)
{
    usb_sendCMD(1<<3); // flash fifo command
    usb_sendInitData();
    QThread::msleep(100);

    uploadThread = new UploadThread(file, SEND_FIRMWARE);
    QObject::connect(uploadThread, &UploadThread::finished, uploadThread, &QObject::deleteLater);
    uploadThread->start();
}

void usb_sendCnt()
{
    usb_sendCMD(1<<3); // flash fifo command
    usb_sendInitData();
    QThread::msleep(100);

    uploadThread = new UploadThread(NULL, SEND_CNT);
    QObject::connect(uploadThread, &UploadThread::finished, uploadThread, &QObject::deleteLater);
    uploadThread->start();
    //uploadThread->sendCnt();
    //delete uploadThread;
}

void usb_abort() {
    abortFlag = true;
}
