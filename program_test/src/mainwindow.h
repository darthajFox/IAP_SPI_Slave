#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QString>

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
    bool isConnected;

    void logClear();

    void deviceUpdate();
    void deviceConnect();
    void setLED();
    void abortUploading();
    void checkFifoState();
    void initStart();
    void sendCnt();

};

#endif // MAINWINDOW_H
