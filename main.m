#include <stdio.h>

#include <CoreFoundation/CoreFoundation.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IONetworkInterface.h>
#include <IOKit/network/IOEthernetController.h>

struct interface_info_t {
	char mac[20];
	char class[25];
	int primary;
};

// TODO: this code does not work on Snow Leopard.
int getInterfaces(mach_port_t mach_port, struct interface_info_t *info) {
	
	kern_return_t   result;
	int				max_unit = 0;
	
	// Look for IOEthernetInterface devices -- this will include AirPorts and other networks,
	// but we want the "primary" (IOPrimaryInterface == true) one.
	
	CFMutableDictionaryRef service_name = IOServiceNameMatching("IOEthernetInterface");
	if (service_name) {
		io_iterator_t i;
		
		// retrieve the matching IOKit services
		result = IOServiceGetMatchingServices(mach_port, service_name, &i);
		
		if ((result == KERN_SUCCESS) && i) {
			io_object_t obj;
			
			do {
				obj = IOIteratorNext(i);
				
				if (obj) {
					int unit;
					CFNumberRef unit_ref;
					
					unit_ref = (CFNumberRef)IORegistryEntryCreateCFProperty(obj, CFSTR("IOInterfaceUnit"), kCFAllocatorDefault, 0);
					CFNumberGetValue(unit_ref, kCFNumberIntType, &unit);
					
					CFRelease(unit_ref);
					
					if (unit < 12) {
						io_object_t pobj;
						
						if (max_unit < unit)
							max_unit = unit;
						
						CFBooleanRef prim_if = (CFBooleanRef)IORegistryEntryCreateCFProperty(obj, CFSTR("IOPrimaryInterface"), kCFAllocatorDefault, 0);
						if (CFBooleanGetValue(prim_if)) {
							info[unit].primary = 1;
						}
						CFRelease(prim_if);
						
						// MAC addresses are stored in the controller to the IOEthernetInterface, which is its parent.
						result = IORegistryEntryGetParentEntry(obj, kIOServicePlane, &pobj);
						
						// using the parent, get the mac address
						if (result == KERN_SUCCESS && pobj) {
							CFStringRef class_ref;
							CFDataRef data = IORegistryEntryCreateCFProperty(pobj, CFSTR("IOMACAddress"), kCFAllocatorDefault, 0);
							
							// format the mac into something readable; mac must be 18 bytes long
							const UInt8* raw = CFDataGetBytePtr(data);
							sprintf(info[unit].mac, "%2.2x:%2.2x:%2.2x:%2.2x:%2.2x:%2.2x", raw[0], raw[1], raw[2], raw[3], raw[4], raw[5]);
							
							CFRelease(data);
							
							class_ref = (CFStringRef)IORegistryEntryCreateCFProperty(pobj, CFSTR("IOClass"), kCFAllocatorDefault, 0);
							CFStringGetCString(class_ref, info[unit].class, 25, kCFStringEncodingMacRoman);

							IOObjectRelease(pobj);
							
						}
						
					} // if (prim_if)
				
					IOObjectRelease(obj);
				
				} // if (obj)
				
			} while (obj);

			IOObjectRelease(i);
		}
	}
	
	return max_unit;
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
   kern_return_t           kernResult; 
   mach_port_t             machPort;
   char					   serial[40] = "";
   char					   model[128] = "";
//   struct interface_info_t interfaces[12] = { { "", "", 0 } };
//   int					   max_unit = 0;
//   int					   i;
   
   kernResult = IOMasterPort( MACH_PORT_NULL, &machPort );
      
   // if we got the master port
   if ( kernResult == KERN_SUCCESS  ) {
      
//		max_unit = getInterfaces(machPort, interfaces);
		getSerialNumber(machPort, serial);
		getModelName(machPort, model);

		printf("%s\n", serial);
		printf("%s\n", model);
		
//		printf("\n");
		
//		printf("%s\n", interfaces[0].mac);
//		for (i = 0; i <= max_unit; i++) {
//			printf("en%d: %s %s", i, interfaces[i].mac, interfaces[i].class);
//			if (interfaces[i].primary) {
//				printf(" *\n");
//			} else {
//				printf("\n");
//			}
//		}
   }
   
   return 0;
   
}