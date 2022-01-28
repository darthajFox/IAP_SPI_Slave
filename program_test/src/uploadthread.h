#ifndef UPLOADTHREAD_H
#define UPLOADTHREAD_H

#include <QObject>
#include <QThread>
#include "usb.h"

extern bool abortFlag;
extern FT_STATUS ftStatus;
extern FT_HANDLE ftHandle;

enum Action {SEND_FIRMWARE, SEND_CNT};

class UploadThread : public QThread
{
    Q_OBJECT


    QString file;
    enum Action numAction;

public:
    UploadThread(const QString&, enum Action);

    void run() override;
    void sendFirmware();
    void sendCnt();

};

#endif // UPLOADTHREAD_H
