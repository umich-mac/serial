//
//  DeviceDetails.h
//  serial
//
//  Created by Jim Zajkowski on 2/27/20.
//

#ifndef DeviceDetails_h
#define DeviceDetails_h

#include <IOKit/IOKitLib.h>
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IONetworkInterface.h>
#include <IOKit/network/IOEthernetController.h>

void getInterface(mach_port_t mach_port, UInt8 *MACAddress);
void getSerialNumber(mach_port_t mach_port, char *serial);
void getModelName(mach_port_t mach_port, char *model);
void getDeviceUuid(mach_port_t mach_port, char *uuid);
void getProductName(mach_port_t mach_port, char *model);


#endif /* DeviceDetails_h */
