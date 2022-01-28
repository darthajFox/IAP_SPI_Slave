/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 5.14.2
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QTextEdit>
#include <QtWidgets/QToolButton>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QAction *action;
    QAction *action_2;
    QWidget *centralWidget;
    QVBoxLayout *verticalLayout;
    QLabel *label;
    QHBoxLayout *horizontalLayout_2;
    QComboBox *deviceCombo;
    QPushButton *updateDevicesButton;
    QPushButton *connectButton;
    QSpacerItem *horizontalSpacer;
    QLabel *label_4;
    QHBoxLayout *horizontalLayout_3;
    QLineEdit *sendSpiDataLine;
    QPushButton *sendSPIData;
    QSpacerItem *horizontalSpacer_3;
    QHBoxLayout *horizontalLayout_4;
    QLabel *label_2;
    QSpacerItem *horizontalSpacer_5;
    QLabel *label_5;
    QHBoxLayout *horizontalLayout;
    QLineEdit *fileLine;
    QToolButton *toolButton;
    QPushButton *uploadButton;
    QSpacerItem *horizontalSpacer_2;
    QComboBox *actionBox;
    QHBoxLayout *horizontalLayout_5;
    QLabel *label_3;
    QSpacerItem *horizontalSpacer_4;
    QLabel *progressLabel;
    QPushButton *clockInfoButton;
    QPushButton *abortButton;
    QPushButton *runAction;
    QPushButton *testButton;
    QPushButton *clearConsole;
    QTextEdit *console;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName(QString::fromUtf8("MainWindow"));
        MainWindow->resize(913, 506);
        MainWindow->setMinimumSize(QSize(400, 300));
        MainWindow->setMaximumSize(QSize(16777215, 16777215));
        action = new QAction(MainWindow);
        action->setObjectName(QString::fromUtf8("action"));
        action_2 = new QAction(MainWindow);
        action_2->setObjectName(QString::fromUtf8("action_2"));
        centralWidget = new QWidget(MainWindow);
        centralWidget->setObjectName(QString::fromUtf8("centralWidget"));
        verticalLayout = new QVBoxLayout(centralWidget);
        verticalLayout->setSpacing(6);
        verticalLayout->setContentsMargins(11, 11, 11, 11);
        verticalLayout->setObjectName(QString::fromUtf8("verticalLayout"));
        label = new QLabel(centralWidget);
        label->setObjectName(QString::fromUtf8("label"));

        verticalLayout->addWidget(label);

        horizontalLayout_2 = new QHBoxLayout();
        horizontalLayout_2->setSpacing(6);
        horizontalLayout_2->setObjectName(QString::fromUtf8("horizontalLayout_2"));
        deviceCombo = new QComboBox(centralWidget);
        deviceCombo->setObjectName(QString::fromUtf8("deviceCombo"));
        deviceCombo->setMinimumSize(QSize(280, 0));

        horizontalLayout_2->addWidget(deviceCombo);

        updateDevicesButton = new QPushButton(centralWidget);
        updateDevicesButton->setObjectName(QString::fromUtf8("updateDevicesButton"));
        updateDevicesButton->setMaximumSize(QSize(80, 16777215));

        horizontalLayout_2->addWidget(updateDevicesButton);

        connectButton = new QPushButton(centralWidget);
        connectButton->setObjectName(QString::fromUtf8("connectButton"));
        connectButton->setEnabled(false);
        connectButton->setMaximumSize(QSize(90, 16777215));

        horizontalLayout_2->addWidget(connectButton);

        horizontalSpacer = new QSpacerItem(40, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);

        horizontalLayout_2->addItem(horizontalSpacer);


        verticalLayout->addLayout(horizontalLayout_2);

        label_4 = new QLabel(centralWidget);
        label_4->setObjectName(QString::fromUtf8("label_4"));

        verticalLayout->addWidget(label_4);

        horizontalLayout_3 = new QHBoxLayout();
        horizontalLayout_3->setSpacing(6);
        horizontalLayout_3->setObjectName(QString::fromUtf8("horizontalLayout_3"));
        sendSpiDataLine = new QLineEdit(centralWidget);
        sendSpiDataLine->setObjectName(QString::fromUtf8("sendSpiDataLine"));

        horizontalLayout_3->addWidget(sendSpiDataLine);

        sendSPIData = new QPushButton(centralWidget);
        sendSPIData->setObjectName(QString::fromUtf8("sendSPIData"));

        horizontalLayout_3->addWidget(sendSPIData);

        horizontalSpacer_3 = new QSpacerItem(40, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);

        horizontalLayout_3->addItem(horizontalSpacer_3);


        verticalLayout->addLayout(horizontalLayout_3);

        horizontalLayout_4 = new QHBoxLayout();
        horizontalLayout_4->setSpacing(6);
        horizontalLayout_4->setObjectName(QString::fromUtf8("horizontalLayout_4"));
        label_2 = new QLabel(centralWidget);
        label_2->setObjectName(QString::fromUtf8("label_2"));

        horizontalLayout_4->addWidget(label_2);

        horizontalSpacer_5 = new QSpacerItem(130, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);

        horizontalLayout_4->addItem(horizontalSpacer_5);

        label_5 = new QLabel(centralWidget);
        label_5->setObjectName(QString::fromUtf8("label_5"));
        label_5->setMinimumSize(QSize(200, 0));

        horizontalLayout_4->addWidget(label_5);


        verticalLayout->addLayout(horizontalLayout_4);

        horizontalLayout = new QHBoxLayout();
        horizontalLayout->setSpacing(6);
        horizontalLayout->setObjectName(QString::fromUtf8("horizontalLayout"));
        fileLine = new QLineEdit(centralWidget);
        fileLine->setObjectName(QString::fromUtf8("fileLine"));
        fileLine->setMinimumSize(QSize(200, 0));
        fileLine->setMaximumSize(QSize(200, 16777215));
        fileLine->setCursor(QCursor(Qt::OpenHandCursor));
        fileLine->setReadOnly(true);

        horizontalLayout->addWidget(fileLine);

        toolButton = new QToolButton(centralWidget);
        toolButton->setObjectName(QString::fromUtf8("toolButton"));

        horizontalLayout->addWidget(toolButton);

        uploadButton = new QPushButton(centralWidget);
        uploadButton->setObjectName(QString::fromUtf8("uploadButton"));
        uploadButton->setEnabled(false);

        horizontalLayout->addWidget(uploadButton);

        horizontalSpacer_2 = new QSpacerItem(0, 0, QSizePolicy::Expanding, QSizePolicy::Minimum);

        horizontalLayout->addItem(horizontalSpacer_2);

        actionBox = new QComboBox(centralWidget);
        actionBox->setObjectName(QString::fromUtf8("actionBox"));
        actionBox->setEnabled(true);
        actionBox->setMinimumSize(QSize(200, 0));

        horizontalLayout->addWidget(actionBox);


        verticalLayout->addLayout(horizontalLayout);

        horizontalLayout_5 = new QHBoxLayout();
        horizontalLayout_5->setSpacing(6);
        horizontalLayout_5->setObjectName(QString::fromUtf8("horizontalLayout_5"));
        label_3 = new QLabel(centralWidget);
        label_3->setObjectName(QString::fromUtf8("label_3"));

        horizontalLayout_5->addWidget(label_3);

        horizontalSpacer_4 = new QSpacerItem(40, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);

        horizontalLayout_5->addItem(horizontalSpacer_4);

        progressLabel = new QLabel(centralWidget);
        progressLabel->setObjectName(QString::fromUtf8("progressLabel"));
        progressLabel->setMinimumSize(QSize(100, 0));

        horizontalLayout_5->addWidget(progressLabel);

        clockInfoButton = new QPushButton(centralWidget);
        clockInfoButton->setObjectName(QString::fromUtf8("clockInfoButton"));

        horizontalLayout_5->addWidget(clockInfoButton);

        abortButton = new QPushButton(centralWidget);
        abortButton->setObjectName(QString::fromUtf8("abortButton"));

        horizontalLayout_5->addWidget(abortButton);

        runAction = new QPushButton(centralWidget);
        runAction->setObjectName(QString::fromUtf8("runAction"));

        horizontalLayout_5->addWidget(runAction);

        testButton = new QPushButton(centralWidget);
        testButton->setObjectName(QString::fromUtf8("testButton"));
        testButton->setEnabled(true);

        horizontalLayout_5->addWidget(testButton);

        clearConsole = new QPushButton(centralWidget);
        clearConsole->setObjectName(QString::fromUtf8("clearConsole"));

        horizontalLayout_5->addWidget(clearConsole);


        verticalLayout->addLayout(horizontalLayout_5);

        console = new QTextEdit(centralWidget);
        console->setObjectName(QString::fromUtf8("console"));
        QFont font;
        font.setFamily(QString::fromUtf8("Courier"));
        font.setPointSize(8);
        font.setBold(false);
        font.setItalic(false);
        font.setWeight(9);
        console->setFont(font);
        console->setStyleSheet(QString::fromUtf8("background:rgb(0, 0, 0);\n"
"color: white;\n"
"font: 75 8pt \"Courier\";"));

        verticalLayout->addWidget(console);

        MainWindow->setCentralWidget(centralWidget);

        retranslateUi(MainWindow);

        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QCoreApplication::translate("MainWindow", "\320\227\320\260\320\273\320\270\320\262\320\260\321\202\320\276\321\200", nullptr));
        action->setText(QCoreApplication::translate("MainWindow", "\320\237\320\276\320\264\320\272\320\273\321\216\321\207\320\270\321\202\321\214\321\201\321\217", nullptr));
        action_2->setText(QCoreApplication::translate("MainWindow", "\320\227\320\260\320\263\321\200\321\203\320\267\320\270\321\202\321\214 \320\277\321\200\320\276\321\210\320\270\320\262\320\272\321\203", nullptr));
        label->setText(QCoreApplication::translate("MainWindow", "\320\243\321\201\321\202\321\200\320\276\320\271\321\201\321\202\320\262\320\276", nullptr));
        updateDevicesButton->setText(QCoreApplication::translate("MainWindow", "\320\236\320\261\320\275\320\276\320\262\320\270\321\202\321\214", nullptr));
        connectButton->setText(QCoreApplication::translate("MainWindow", "\320\237\320\276\320\264\320\272\320\273\321\216\321\207\320\270\321\202\321\214\321\201\321\217", nullptr));
        label_4->setText(QCoreApplication::translate("MainWindow", "Send SPI data", nullptr));
        sendSPIData->setText(QCoreApplication::translate("MainWindow", "Send", nullptr));
        label_2->setText(QCoreApplication::translate("MainWindow", "\320\237\321\200\320\276\321\210\320\270\320\262\320\272\320\260", nullptr));
        label_5->setText(QCoreApplication::translate("MainWindow", "Action", nullptr));
        toolButton->setText(QCoreApplication::translate("MainWindow", "...", nullptr));
        uploadButton->setText(QCoreApplication::translate("MainWindow", "\320\227\320\260\320\263\321\200\321\203\320\267\320\270\321\202\321\214 \320\277\321\200\320\276\321\210\320\270\320\262\320\272\321\203", nullptr));
        label_3->setText(QCoreApplication::translate("MainWindow", "\320\232\320\276\320\275\321\201\320\276\320\273\321\214", nullptr));
        progressLabel->setText(QCoreApplication::translate("MainWindow", "Progress 0%", nullptr));
        clockInfoButton->setText(QCoreApplication::translate("MainWindow", "Clock Info", nullptr));
        abortButton->setText(QCoreApplication::translate("MainWindow", "Abort action", nullptr));
        runAction->setText(QCoreApplication::translate("MainWindow", "Run action", nullptr));
        testButton->setText(QCoreApplication::translate("MainWindow", "Test", nullptr));
        clearConsole->setText(QCoreApplication::translate("MainWindow", "Clear", nullptr));
        console->setHtml(QCoreApplication::translate("MainWindow", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:'Courier'; font-size:8pt; font-weight:72; font-style:normal;\">\n"
"<p style=\"-qt-paragraph-type:empty; margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px; font-size:12pt; font-weight:400;\"><br /></p></body></html>", nullptr));
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
