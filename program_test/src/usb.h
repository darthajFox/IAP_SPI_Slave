#ifndef USB_H
#define USB_H

#include "logger.h"
#include "FTD3XX.h"
#include <QVector>
#include <QString>

bool usb_getDevicesList(QList<QString>*);
bool usb_connect(int);
void usb_disconnect();
void usb_upload(const QString&);

void usb_sendCMD(uint32_t);
uint32_t usb_recieveANS();

void usb_sendInitData();
void usb_sendCnt();
//uint32_t usb_sendToFifo(uchar*, uint8_t);
void usb_abort();

#endif // USB_H
