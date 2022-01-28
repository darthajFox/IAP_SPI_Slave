#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QTextEdit>
#include <QLabel>

class Logger : public QObject
{
    Q_OBJECT

public:
    Logger();

signals:
    void appendMsg(const QString&);
    void updateProgress(const QString&);
};


void logInit(QTextEdit*, QLabel*);
void logPrint(const QString&);
void logSrcMessage(const QString&, const QString&);
void logWarning(const QString&);
void logError(const QString&);


#endif // LOGGER_H
