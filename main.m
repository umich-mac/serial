#include <stdio.h>

#include <CoreFoundation/CoreFoundation.h>
#import <CommonCrypto/CommonDigest.h>

#include "DeviceDetails.h"

int main(int argc, char *argv[])
{
	kern_return_t	kernResult; 
	mach_port_t     machPort;
    UInt8			macAddress[kIOEthernetAddressSize];
	char			serial[40] = "";
	char			model[128] = "";
    char            uuid[128]  = "";
	
	kernResult = IOMasterPort( MACH_PORT_NULL, &machPort );
	
	// if we got the master port
	if ( kernResult == KERN_SUCCESS  ) {

		getSerialNumber(machPort, serial);
		getModelName(machPort, model);
		getInterface(machPort, macAddress);
        getDeviceUuid(machPort, uuid);

        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5( uuid, (int)strlen(uuid), digest ); // This is the md5 call

        // https://www.hackerearth.com/practice/notes/get-the-modulo-of-a-very-large-number-that-cannot-be-stored-in-any-data-type-in-cc-1/
        int shard = 0;
        for (uint index = 0; index < CC_MD5_DIGEST_LENGTH; index++) {
            uint8 value = digest[index];
            shard = ((shard << 8) + value) % 100;
        }
        shard = (shard % 100) + 1; // add one, so we go 1-100 not 0-99

        // Shortcut -s mode
        if (argc == 2 && strcmp(argv[1], "-s") == 0) {
            getSerialNumber(machPort, serial);
            printf("%s\n", serial);
            exit(0);
        }
		
        // Shortcut -m mode
        if (argc == 2 && strcmp(argv[1], "-m") == 0) {
            getModelName(machPort, model);
            printf("%s\n", model);
            exit(0);
        }
		
        // MAC addresses here
        if (argc == 2 && strcasecmp(argv[1], "--mac") == 0) {
			getInterface(machPort, macAddress);
            printf("%02x:%02x:%02x:%02x:%02x:%02x\n", macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5]);
            exit(0);
        }
		
        // Shard only
        if (argc == 2 && strcasecmp(argv[1], "--shard") == 0) {
            printf("%d\n", shard);
            exit(0);
        }

        // Shard only (jamf version)
        if (argc == 2 && strcasecmp(argv[1], "--jamf-shard") == 0) {
            printf("<result>%d</result>\n", shard);
            exit(0);
        }
		
        // UUID only
        if (argc == 2 && strcasecmp(argv[1], "--uuid") == 0) {
			getDeviceUuid(machPort, uuid);
            printf("%s\n", uuid);
            exit(0);
        }
		
        // Otherwise: all the numbers
		printf("%s\n", serial);
		printf("%s\n", model);
		printf("%02x:%02x:%02x:%02x:%02x:%02x\n", macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5]);
        printf("%s\n", uuid);
        printf("%d\n", shard);
	}
	
	return 0;
	
}
