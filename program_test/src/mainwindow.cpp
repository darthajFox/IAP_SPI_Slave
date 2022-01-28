#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "usb.h"
#include "logger.h"
#include <QFileDialog>
#include <QCheckBox>

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    isConnected = false;

    connect(ui->updateDevicesButton, &QPushButton::clicked, this, &MainWindow::deviceUpdate);
    connect(ui->connectButton, &QPushButton::clicked, this, &MainWindow::deviceConnect);
    connect(ui->selectLED0, &QCheckBox::stateChanged, this, &MainWindow::setLED);
    connect(ui->selectLED1, &QCheckBox::stateChanged, this, &MainWindow::setLED);

    connect(ui->abortButton, &QPushButton::clicked, this, &MainWindow::abortUploading);
    connect(ui->checkFifoButton, &QPushButton::clicked, this, &MainWindow::checkFifoState);
    connect(ui->initButton, &QPushButton::clicked, this, &MainWindow::initStart);
    connect(ui->cntButton, &QPushButton::clicked, this, &MainWindow::sendCnt);

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
                            ui->fileLine->setText(QFileDialog::getOpenFileName(this, "Open file", "", "SPI image File (*.dat)"));
                            if(ui->fileLine->text() != "")
                                ui->uploadButton->setEnabled(1);
                        });
    connect(ui->uploadButton, &QPushButton::clicked,
            this, [=] ()
                        {
                            if(!isConnected)
                            {
                                logError("Connect the device");
                                return;
                            }
                            if(ui->fileLine->text() != "")
                                usb_upload(ui->fileLine->text());
                        });

}

MainWindow::~MainWindow()
{
    if(isConnected)
        usb_disconnect();

    delete ui;
}

void MainWindow::deviceUpdate()
{
    ui->deviceCombo->clear();

    QList<QString> comboList;
    if(usb_getDevicesList(&comboList) | comboList.isEmpty())
        return;

    ui->deviceCombo->addItems(comboList);
}

void MainWindow::deviceConnect()
{
    if(isConnected)
    {
        usb_disconnect();
        ui->connectButton->setText("Подключиться");
        isConnected = false;

        return;
    }

    if(usb_connect(ui->deviceCombo->currentIndex()))
        return;

    isConnected = true;
    ui->connectButton->setText("Отключиться");
}

void MainWindow::setLED() {
    if(!isConnected)
    {
        logError("Connect the device");
        return;
    }
    uint32_t command = 1;
    if(ui->selectLED0->checkState() == Qt::Checked) command = command | (1 << 8);
    if(ui->selectLED1->checkState() == Qt::Checked) command = command | (1 << 9);
    usb_sendCMD(command);
}

void MainWindow::abortUploading() {
    if(!isConnected)
    {
        logError("Connect the device");
        return;
    }
    usb_abort();
}

void MainWindow::checkFifoState() {
    if(!isConnected)
    {
        logError("Connect the device");
        return;
    }
    uint32_t answer;
    usb_sendCMD((1 << 2));
    answer = usb_recieveANS();
    logPrint(QString("Fifo almost empty: %1, fifo empty: %2, fifo full: %3, fifo error: %4").arg((answer >> 2) & 1).arg((answer >> 1) & 1).arg(answer & 1).arg((answer >> 3) & 1));
}

void MainWindow::initStart() {
    if(!isConnected)
    {
        logError("Connect the device");
        return;
    }
    usb_sendInitData();
}

void MainWindow::sendCnt() {
    if(!isConnected)
    {
        logError("Connect the device");
        return;
    }
    usb_sendCnt();
}
