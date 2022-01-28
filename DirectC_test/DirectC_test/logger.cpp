#include "logger.h"

QTextEdit *console = nullptr;
Logger logger;

bool updateProgressFlag = false;

Logger::Logger(){

}

void logInit(QTextEdit *console, QLabel *progress)
{
    //console = widget;
    QObject::connect(&logger, &Logger::appendMsg, console, &QTextEdit::append);
    QObject::connect(&logger, &Logger::updateProgress, progress, &QLabel::setText);
}

void logPrint(const QString &text)
{
//    if(console != nullptr)
//        console->append(text);
    logger.appendMsg(text);
}

void logWarning(const QString &text)
{
    logPrint(QString("<span style=\"color:yellow\">[WARNING]</span> ") + text);
}

void logError(const QString &text)
{
    logPrint(QString("<span style=\"color:red\">[Error]</span> ") + text);
}

void logSrcMessage(const QString &text, const QString &src) {
    logPrint(QString("<span style=\"color:green\">[%1] </span> ").arg(src) + text);

    if(src == "dp_disp_text" && text == "\rProgress: ") {
        updateProgressFlag = true;
        return;
    }

    if(updateProgressFlag && src == "dp_disp_val") {
        logger.updateProgress("Progress:" + text + " %");
    }

    updateProgressFlag = false;
}
