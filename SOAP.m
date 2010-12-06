#import <Foundation/Foundation.h>

#import "WSDLdocument.h"
//#import "AppNotifications.h"

//#import "APIAPPlyzer.h"
#import "NSString+Helpers.h"
//#import "NSData+Helpers.h"
//#import "DDData.h"


void showUsage()
{
	printf("SOAP objC Proxy Class Builder\n\n");
	printf("Usage: Kernseife <source>\n");
	printf("   <source> path or URL\n\n");
}


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	if (argc<2)
	{
		showUsage();
		exit(1);
	}
	
	NSString *source = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
	

	NSURL *url;
	
	if ([source hasPrefix:@"http://"])
	{
		url = [NSURL URLWithString:source];
	}
	else
	{
		// try as file
		url = [NSURL fileURLWithPath:source];
	}
	
	if (!url)
	{
		printf("ERROR: URL '%s' is not a file or URL\n", [source UTF8String]);
		exit(1);
	}
	
	WSDLdocument *wsdl = [[[WSDLdocument alloc] initWithContentsOfURL:url] autorelease];
	
	NSArray *ports = [wsdl portNames];
	
	if ([ports count]==0)
	{
		printf("ERROR: No ports found in WSDL\n");
		exit(1);
	}
	
	for (NSString *onePortName in ports)
	{
		printf("Writing class files for %s\n", [onePortName UTF8String]);
		
		[wsdl writeClassFilesForPort:onePortName];
		printf("Done. \n");
	}
		
    [pool drain];
    return 0;
}
