#include "logger.h"
#include <iostream>

void logPrint(const QString &text)
{
    std::cout << text.toStdString() << std::endl;
}

void logWarning(const QString &text)
{
    logPrint(QString("[WARNING]" + text));
}

void logError(const QString &text)
{
    logPrint(QString("[ERROR]" + text));
}
