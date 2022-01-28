QT       += core gui serialport

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

CONFIG += c++11

CONFIG += warn_off

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    DirectC/G4Algo/dpG4alg.c \
    DirectC/G4Algo/dpG4spi.c \
    DirectC/G5Algo/dpG5alg.cpp \
    DirectC/G5Algo/dpG5spi.cpp \
    DirectC/dpDUTspi.cpp \
    DirectC/dpalg.cpp \
    DirectC/dpcom.cpp \
    DirectC/dputil.cpp \
    actionthread.cpp \
    logger.cpp \
    main.cpp \
    mainwindow.cpp \
    spi.cpp \

HEADERS += \
    DirectC/G4Algo/dpG4alg.h \
    DirectC/G4Algo/dpG4spi.h \
    DirectC/G5Algo/dpG5alg.h \
    DirectC/G5Algo/dpG5spi.h \
    DirectC/dpDUTspi.h \
    DirectC/dpalg.h \
    DirectC/dpcom.h \
    DirectC/dpuser.h \
    DirectC/dputil.h \
    actionthread.h \
    defines.h \
    logger.h \
    mainwindow.h \
    spi.h \

FORMS += \
    mainwindow.ui

INCLUDEPATH += "$$PWD\DirectC"
INCLUDEPATH += "$$PWD\DirectC\G5Algo"

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
