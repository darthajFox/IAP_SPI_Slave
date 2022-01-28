#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QFileDialog>
#include <QCheckBox>
#include <QPushButton>
#include <QSerialPort>
#include <QSerialPortInfo>

#include "logger.h"
#include "spi.h"

// DirectC
#include "dpuser.h"


MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    //log init
    logInit(ui->console, ui->progressLabel);

    // serial init
    deviceConnected = false;
    //serialPort = new QSerialPort();
    //spi_init(serialPort, this);

    // send SPI lineEdit
    ui->sendSpiDataLine->setInputMask("HH HH HH HH HH HH HH HH HH HH HH; ");
    ui->sendSpiDataLine->setCursorPosition(0);

    // fill actionBox
    ui->actionBox->addItem("NO_ACTION", DP_NO_ACTION_FOUND);
    ui->actionBox->addItem("DEVICE_INFO_ACTION", DP_DEVICE_INFO_ACTION_CODE);
    ui->actionBox->addItem("READ_IDCODE_ACTION", DP_READ_IDCODE_ACTION_CODE);
    ui->actionBox->addItem("ERASE_ACTION", DP_ERASE_ACTION_CODE);
    ui->actionBox->addItem("PROGRAM_ACTION", DP_PROGRAM_ACTION_CODE);
    ui->actionBox->addItem("VERIFY_ACTION", DP_VERIFY_ACTION_CODE);


    connect(ui->updateDevicesButton, &QPushButton::clicked, this, &MainWindow::deviceListUpdate);
    connect(ui->connectButton, &QPushButton::clicked, this, &MainWindow::deviceConnection);
//    connect(ui->selectLED0, &QCheckBox::stateChanged, this, &MainWindow::setLED);
//    connect(ui->selectLED1, &QCheckBox::stateChanged, this, &MainWindow::setLED);
//    connect(ui->abortButton, &QPushButton::clicked, this, &MainWindow::abortUploading);
    connect(ui->testButton, &QPushButton::clicked, this, &MainWindow::testDirectC);
//    connect(ui->initButton, &QPushButton::clicked, this, &MainWindow::initStart);
//    connect(ui->cntButton, &QPushButton::clicked, this, &MainWindow::sendCnt);

    connect(ui->sendSpiDataLine, &QLineEdit::cursorPositionChanged,
            this, [=] (int oldPos, int newPos) {
                int textSize = ui->sendSpiDataLine->text().size() - 6;
                textSize += textSize / 2;
                if(newPos > textSize) {
                    ui->sendSpiDataLine->setCursorPosition(textSize);
                    //logPrint(QString("text %1").arg(ui->sendSpiDataLine->text().size()));
                    logPrint(QString("textSize %1").arg(textSize));
                    //logPrint(QString("Cur pos %1").arg(ui->sendSpiDataLine->cursorPosition()));
                }
            });


    connect(ui->deviceCombo, QOverload<const QString &>::of(&QComboBox::currentIndexChanged),
            this, [=] (const QString &text)
                        {
                            if(text == "")
                                ui->connectButton->setEnabled(0);
                            else
                                ui->connectButton->setEnabled(1);
                        });
    connect(ui->toolButton, &QToolButton::clicked,
            this, [=] ()
                        {
                            QString prevText = ui->fileLine->text();
                            ui->fileLine->setText(QFileDialog::getOpenFileName(this, "Open file", "", "DAT image File (*.dat)"));
                            if(ui->fileLine->text() != "") {
                                ui->uploadButton->setEnabled(1);
                                //ui->testButton->setEnabled(1);
                            }
                        });
    connect(ui->uploadButton, &QPushButton::clicked, this, &MainWindow::programDevice);
    connect(ui->runAction, &QPushButton::clicked, this, &MainWindow::runAction);
    connect(ui->clearConsole, &QPushButton::clicked, ui->console, &QTextEdit::clear);
    connect(ui->abortButton, &QPushButton::clicked, this, &MainWindow::abortAction);
    //connect(ui->sendSPIData, &QPushButton::clicked, this, &MainWindow::sendSPIData);
    connect(ui->clockInfoButton, &QPushButton::clicked, this, &MainWindow::clockInfo);

    deviceListUpdate();
    ui->deviceCombo->setCurrentIndex(1);
    ui->fileLine->setText("D:/workspace/IAP SPI Slave/blink_led0.dat");

    logPrint(QString("Main thread id: %1").arg((uint64_t)QThread::currentThread(), 0, 16));
}

MainWindow::~MainWindow()
{
    if(deviceConnected) {
        deviceConnection();
    }

    //delete serialPort;

    delete ui;
}

void MainWindow::deviceListUpdate()
{
    ui->deviceCombo->clear();

    QList<QSerialPortInfo> portList;
    portList = QSerialPortInfo::availablePorts();
    foreach(const QSerialPortInfo &port, portList) {
        ui->deviceCombo->addItem(port.portName());
    }
}

void MainWindow::deviceConnection()
{
    if(!deviceConnected) {
        if(!ui->deviceCombo->count()) {
            logWarning("No device selected");
            return;
        }

//        if(!spi_connectDevice(ui->deviceCombo->currentText())) {
//            logError("Can't open serial");
//            return;
//        }

        ui->connectButton->setText("Отключиться");
        ui->uploadButton->setEnabled(0);
        ui->deviceCombo->setEnabled(0);
        deviceConnected = true;
        logPrint(QString("Port %1 opened").arg(ui->deviceCombo->currentText()));
        return;
    }
    else {
        //spi_disconnectDevice();
        logPrint(QString("Port %1 closed").arg(ui->deviceCombo->currentText()));
        ui->connectButton->setText("Подключиться");
        ui->uploadButton->setEnabled(1);
        ui->deviceCombo->setEnabled(1);
        deviceConnected = false;
    }
}

void MainWindow::programDevice() {

//    if(!firmwareLoaded) {
//        if(!loadFirmware()) {
//            logError("Error loading firmware");
//        }
//    }

}

void MainWindow::testDirectC() {
    if(!deviceConnected) {
        logError("Error no device openned");
        return;
    }

    actionThread = new ActionThread(ActionThread::TEST, ui->fileLine->text(), ui->actionBox->currentData().toUInt(), ui->deviceCombo->currentText());
    QObject::connect(actionThread, &ActionThread::finished, actionThread, &QObject::deleteLater);
    actionThread->start();
    //serialPort->moveToThread(actionThread);
}

void MainWindow::runAction(){

    if(!deviceConnected) {
        logError("Error no device openned");
        return;
    }

    actionThread = new ActionThread(ActionThread::ACTION, ui->fileLine->text(), ui->actionBox->currentData().toUInt(), ui->deviceCombo->currentText());
    QObject::connect(actionThread, &ActionThread::finished, actionThread, &QObject::deleteLater);
    actionThread->start();
    //serialPort->moveToThread(actionThread);
}

void MainWindow::abortAction(){
    actionThread->terminate();
}

void MainWindow::sendSPIData(){
    //int textSize = ui->sendSpiDataLine->text().size() - 6;
    //spi_sendRowData()
}

void MainWindow::clockInfo(){
    if(!deviceConnected) {
        logError("Error no device openned");
        return;
    }

    actionThread = new ActionThread(ActionThread::CLOCK, ui->fileLine->text(), ui->actionBox->currentData().toUInt(), ui->deviceCombo->currentText());
    QObject::connect(actionThread, &ActionThread::finished, actionThread, &QObject::deleteLater);
    actionThread->start();
}

//void MainWindow::setLED() {
//    if(!isConnected)
//    {
//        logError("Connect the device");
//        return;
//    }
//    uint32_t command = 1;
//    if(ui->selectLED0->checkState() == Qt::Checked) command = command | (1 << 8);
//    if(ui->selectLED1->checkState() == Qt::Checked) command = command | (1 << 9);
//    usb_sendCMD(command);
//}

//void MainWindow::abortUploading() {
//    if(!isConnected)
//    {
//        logError("Connect the device");
//        return;
//    }
//    usb_abort();
//}

//void MainWindow::checkFifoState() {
//    if(!isConnected)
//    {
//        logError("Connect the device");
//        return;
//    }
//    uint32_t answer;
//    usb_sendCMD((1 << 2));
//    answer = usb_recieveANS();
//    logPrint(QString("Fifo almost empty: %1, fifo empty: %2, fifo full: %3, fifo error: %4").arg((answer >> 2) & 1).arg((answer >> 1) & 1).arg(answer & 1).arg((answer >> 3) & 1));
//}

//void MainWindow::initStart() {
//    if(!isConnected)
//    {
//        logError("Connect the device");
//        return;
//    }
//    usb_sendInitData();
//}

//void MainWindow::sendCnt() {
//    if(!isConnected)
//    {
//        logError("Connect the device");
//        return;
//    }
//    usb_sendCnt();
//}
