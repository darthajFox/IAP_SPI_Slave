#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QString>
#include <QSerialPort>
#include "actionthread.h"

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

private:
    Ui::MainWindow *ui;
    bool deviceConnected;
    QSerialPort *serialPort;

    ActionThread *actionThread;

    //uint8_t *firmwareImagePtr;

    void logClear();

    void deviceListUpdate();
    void deviceConnection();
    void programDevice();

    void testDirectC();
    void runAction();
    void abortAction();
    void sendSPIData();
    void clockInfo();

//    void setLED();
//    void checkFifoState();
//    void initStart();
//    void sendCnt();

};

#endif // MAINWINDOW_H
