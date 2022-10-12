//
//  DeviceDetails.m
//  serial
//
//  Created by Jim Zajkowski on 2/27/20.
//

#import <Foundation/Foundation.h>

#import "DeviceDetails.h"

void getInterface(mach_port_t mach_port, UInt8 *MACAddress) {

    kern_return_t   result;

    // Look for IOEthernetInterface devices -- this will include AirPorts and other networks,
    // but we want the "primary" (IOPrimaryInterface == true) one.

    CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOEthernetInterfaceClass);
    if (matchingDict) {

        CFMutableDictionaryRef propertyMatchDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                                             &kCFTypeDictionaryKeyCallBacks,
                                                                             &kCFTypeDictionaryValueCallBacks);

        CFDictionarySetValue(propertyMatchDict, CFSTR(kIOPrimaryInterface), kCFBooleanTrue);
        CFDictionarySetValue(matchingDict, CFSTR(kIOPropertyMatchKey), propertyMatchDict);
        CFRelease(propertyMatchDict);

        io_iterator_t matchingServices;
        result = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices);

        if (result == KERN_SUCCESS) {
            io_object_t obj;
            io_object_t pobj;

            while ((obj = IOIteratorNext(matchingServices))) {
                CFTypeRef    MACAddressAsCFData;

                result = IORegistryEntryGetParentEntry(obj,
                                                       kIOServicePlane,
                                                       &pobj);

                MACAddressAsCFData = IORegistryEntryCreateCFProperty(pobj,
                                                                     CFSTR(kIOMACAddress),
                                                                     kCFAllocatorDefault,
                                                                     0);
                if (MACAddressAsCFData) {
                    CFDataGetBytes(MACAddressAsCFData, CFRangeMake(0, kIOEthernetAddressSize), MACAddress);
                    CFRelease(MACAddressAsCFData);
                }

                IOObjectRelease(pobj);
                IOObjectRelease(obj);
            }
        }
    }
}

// serial must be 20 bytes
void getSerialNumber(mach_port_t mach_port, char *serial) {

    kern_return_t   result;

    CFMutableDictionaryRef service_name = IOServiceMatching("IOPlatformExpertDevice");
    if (service_name) {
        io_iterator_t i;

        // retrieve the matching IOKit services
        result = IOServiceGetMatchingServices(mach_port, service_name, &i);

        if ((result == KERN_SUCCESS) && i) {
            io_object_t obj;
            bool done = false;

            do {
                obj = IOIteratorNext(i);

                if (obj) {
                    CFStringRef serialRef = (CFStringRef)IORegistryEntryCreateCFProperty(obj, CFSTR("IOPlatformSerialNumber"), kCFAllocatorDefault, 0);

                    if (serialRef) {
                        CFStringGetCString(serialRef, serial, 39, kCFStringEncodingMacRoman);
                        CFRelease(serialRef);

                    } else {
                        strcpy(serial, "unknown\0");
                    }

                    done = true;
                }

                IOObjectRelease(obj);

            } while (obj && !done);

            IOObjectRelease(i);
        }
    }
}

void getModelName(mach_port_t mach_port, char *model) {

    kern_return_t   result;

    CFMutableDictionaryRef service_name = IOServiceMatching("IOPlatformExpertDevice");
    if (service_name) {
        io_iterator_t i;

        // retrieve the matching IOKit services
        result = IOServiceGetMatchingServices(mach_port, service_name, &i);

        if ((result == KERN_SUCCESS) && i) {
            io_object_t obj;
            bool done = false;

            do {
                obj = IOIteratorNext(i);

                if (obj) {
                    // This is not string data.  Why?  No idea.
                    CFDataRef modelRef = (CFDataRef)IORegistryEntryCreateCFProperty(obj, CFSTR("model"), kCFAllocatorDefault, 0);
                    long length = CFDataGetLength(modelRef);
                    CFDataGetBytes(modelRef, CFRangeMake(0, MIN(128, length)), (UInt8 *)model);
                    CFRelease(modelRef);
                    done = true;
                }

                IOObjectRelease(obj);

            } while (obj && !done);

            IOObjectRelease(i);
        }
    }
}

void getDeviceUuid(mach_port_t mach_port, char *uuid) {
    kern_return_t   result;

    CFMutableDictionaryRef service_name = IOServiceMatching("IOPlatformExpertDevice");
    if (service_name) {
        io_iterator_t i;

        // retrieve the matching IOKit services
        result = IOServiceGetMatchingServices(mach_port, service_name, &i);

        if ((result == KERN_SUCCESS) && i) {
            io_object_t obj;
            bool done = false;

            do {
                obj = IOIteratorNext(i);

                if (obj) {
                    CFStringRef uuidRef = (CFStringRef)IORegistryEntryCreateCFProperty(obj, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
                    CFStringGetCString(uuidRef, uuid, 37, kCFStringEncodingMacRoman);
                    CFRelease(uuidRef);
                    done = true;
                }

                IOObjectRelease(obj);

            } while (obj && !done);

            IOObjectRelease(i);
        }
    }

}
