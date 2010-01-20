#include <stdio.h>

#include <CoreFoundation/CoreFoundation.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IONetworkInterface.h>
#include <IOKit/network/IOEthernetController.h>

void getInterface(mach_port_t mach_port, UInt8 *MACAddress) {
	
	kern_return_t   result;
	
	// Look for IOEthernetInterface devices -- this will include AirPorts and other networks,
	// but we want the "primary" (IOPrimaryInterface == true) one.
	
	CFMutableDictionaryRef matchingDict = IOServiceNameMatching(kIOEthernetInterfaceClass);
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
			
			while (obj = IOIteratorNext(matchingServices)) {
				CFTypeRef	MACAddressAsCFData;        
				
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
					CFDataGetBytes(modelRef, CFRangeMake(0,128), (void *)model);
					CFRelease(modelRef);
					done = true;
				}
				
				IOObjectRelease(obj);
				
			} while (obj && !done);
			
			IOObjectRelease(i);
		}
	}
}

int main(int argc, char *argv[])
{
	kern_return_t	kernResult; 
	mach_port_t     machPort;
    UInt8			macAddress[kIOEthernetAddressSize];
	char			serial[40] = "";
	char			model[128] = "";
	
	kernResult = IOMasterPort( MACH_PORT_NULL, &machPort );
	
	// if we got the master port
	if ( kernResult == KERN_SUCCESS  ) {
		
		getSerialNumber(machPort, serial);
		getModelName(machPort, model);
		getInterface(machPort, macAddress);
		
		printf("%s\n", serial);
		printf("%s\n", model);
		printf("%02x:%02x:%02x:%02x:%02x:%02x\n", macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5]);
		
	}
	
	return 0;
	
}