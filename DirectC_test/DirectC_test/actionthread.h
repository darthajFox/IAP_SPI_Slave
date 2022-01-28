#ifndef UPLOADTHREAD_H
#define UPLOADTHREAD_H

#include <QObject>
#include <QThread>
#include <QSerialPort>

//extern bool abortFlag;
//extern FT_STATUS ftStatus;
//extern FT_HANDLE ftHandle;

class ActionThread : public QThread
{
    Q_OBJECT

    QString fileName;
    uint8_t numAction;
    QSerialPort *serialPort;
    QString portName;
    //QThread *parentThread;

public:
    enum ThreadJob{ACTION, TEST, CLOCK} jobType;

public:
    ActionThread(enum ThreadJob, const QString&, uint8_t, const QString&);
    ~ActionThread();

    void run() override;
    void performAction();
    void testSend();
    bool loadFirmware();
public:
    void abortThread();
};

#endif // UPLOADTHREAD_H
