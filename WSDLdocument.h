//
//  WSDLdocument.h
//  SOAP
//
//  Created by Oliver on 14.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMLdocument.h"

@interface WSDLdocument : XMLdocument <XMLdocumentDelegate>
{
	XMLelement *service;
	NSArray *ports;
	
	XMLelement *types;
	XMLelement *schema;
	
	// buffer
	NSMutableString *elementWalkerBuffer;
	NSMutableDictionary *elementWalkerDict;
}

- (NSArray *)portNames;


- (void)writeClassFilesForPort:(NSString *)portName;

@end
