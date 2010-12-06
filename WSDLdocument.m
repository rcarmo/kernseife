//
//  WSDLdocument.m
//  SOAP
//
//  Created by Oliver on 14.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "WSDLdocument.h"
#import "NSArray+XMLelement.h"
#import "NSString+Helpers.h"
#import "NSDate+xml.h"
#import "WebService.h"


@interface WSDLdocument ()
- (NSArray *)propertiesOfComplexType:(NSString *)complexTypeName;
@end


@implementation WSDLdocument


- (id) init
{
	if (self = [super init])
	{
		self.delegate = self;
	}
	
	return self;
}

- (void) dealloc
{
	[elementWalkerDict release];
	[super dealloc];
}

- (NSString *)description
{
	return [documentRoot description];
}

- (NSString *) serviceName
{
	return [service.attributes objectForKey:@"name"];
}

#pragma mark Type Conversions
- (NSString *)cocoaTypeForSoapType:(NSString *)soapType
{
	if ([soapType isEqualToString:@"@array"])
	{
		return @"NSArray *";
	}
	
	if ([soapType isEqualToString:@"string"])
	{
		return @"NSString *";
	}
	
	if ([soapType isEqualToString:@"boolean"])
	{
		return @"BOOL";
	}
	
	if ([soapType isEqualToString:@"dateTime"])
	{
		return @"NSDate *";
	}
	
	if ([soapType isEqualToString:@"int"])
	{
		return @"NSInteger";
	}
	
	if ([soapType isEqualToString:@"integer"])
	{
		return @"NSInteger";
	}
	
	if ([soapType isEqualToString:@"long"])
	{
		return @"long";
	}
	
	if ([soapType isEqualToString:@"double"])
	{
		return @"double";
	}
	
	if ([soapType isEqualToString:@"base64Binary"])
	{
		return @"NSData *";
	}
	
	if ([soapType isEqualToString:@"xml"])
	{
		return @"XMLdocument *";
	}
	
	// assume it's a complex type
	return [NSString stringWithFormat:@"%@ *", soapType];
}


- (NSString *)conversionFromNSStringToType:(NSString *)otherType variable:(NSString *)variable
{
	if ([otherType isEqualToString:@"NSString *"])
	{
		// no conversion necessary
		return variable;
	}
	else if ([otherType isEqualToString:@"NSInteger"])
	{
		// convert to int
		return [NSString stringWithFormat:@"[%@ intValue]", variable];
	}
	else if ([otherType isEqualToString:@"double"])
	{
		// convert to double
		return [NSString stringWithFormat:@"[%@ doubleValue]", variable];
	}
	else if ([otherType isEqualToString:@"NSDate *"])
	{
		// convert to NSDate
		return [NSString stringWithFormat:@"[%@ dateFromISO8601]", variable];
	}
	else if ([otherType isEqualToString:@"BOOL"])
	{
		// convert to BOOL
		
		//return [NSString stringWithFormat:@"[%@ isEqualToString:@\"true\"]?YES:NO", variable ];
		return [NSString stringWithFormat:@"[self isBoolStringYES:%@]", variable ];
	}
	else if ([otherType isEqualToString:@"NSData *"])
	{
		return [NSString stringWithFormat:@"[NSData dataWithBase64EncodedString:%@]", variable];
	}
	
	/* // we don't want this 
	 else if ([otherType isEqualToString:@"XMLdocument *"])
	 {
	 return [NSString stringWithFormat:@"[XMLdocument documentWithString:%@]", variable];
	 }
	 */
	
	return nil;
}

- (NSString *)conversionFromTypeToNSString:(NSString *)otherType variable:(NSString *)variable
{
	if ([otherType isEqualToString:@"NSString *"])
	{
		// no conversion necessary
		return variable;
	}
	else if ([otherType isEqualToString:@"NSInteger"])
	{
		return [NSString stringWithFormat:@"[NSNumber numberWithInt:%@]", variable];
	}
	else if ([otherType isEqualToString:@"long"])
	{
		return [NSString stringWithFormat:@"[NSNumber numberWithLong:%@]", variable];
	}
	else if ([otherType isEqualToString:@"BOOL"])
	{
		return [NSString stringWithFormat:@"[NSNumber numberWithBool:%@]", variable];
	}
	else if ([otherType isEqualToString:@"float"])
	{
		return [NSString stringWithFormat:@"[NSNumber numberWithFloat:%@]", variable];
	}
	else if ([otherType isEqualToString:@"double"])
	{
		return [NSString stringWithFormat:@"[NSNumber numberWithDouble:%@]", variable];
	}
	else if ([otherType isEqualToString:@"NSDate *"])
	{
		return [NSString stringWithFormat:@"[%@ ISO8601string]", variable];
	}
	else if ([otherType isEqualToString:@"NSData *"])
	{
		return [NSString stringWithFormat:@"[%@ base64Encoding]", variable];
	}
	else if ([otherType isEqualToString:@"XMLdocument *"])
	{
		return [NSString stringWithFormat:@"[%@ description]", variable];
	}	
	return nil;
}

- (NSString *)conversionFromTypeToObject:(NSString *)otherType variable:(NSString *)variable
{
	if ([otherType isEqualToString:@"NSString *"])
	{
		// no conversion necessary
		return variable;
	}
	else if ([otherType isEqualToString:@"NSInteger"])
	{
		// convert to int
		return [NSString stringWithFormat:@"[NSString stringWithFormat:@\"%%d\", %@]", variable];
	}
	else if ([otherType isEqualToString:@"double"])
	{
		// convert to double
		return [NSString stringWithFormat:@"[NSString stringWithFormat:@\"%%f\", %@]", variable];
	}
	else if ([otherType isEqualToString:@"NSDate *"])
	{
		// convert to NSDate
		return [NSString stringWithFormat:@"[%@ ISO8601string]", variable];
	}
	
	return nil;
}



#pragma mark Utils
// creates dictionary of types
- (void) elementWalker:(XMLelement *)element
{
	static NSMutableDictionary *currentDict;
	
	if (!elementWalkerDict)
	{
		elementWalkerDict = [[NSMutableDictionary dictionary] retain];
		currentDict = elementWalkerDict;
	}
	
	NSString *name = element.name;
	
	NSString *elementName = [element.attributes objectForKey:@"name"];
	NSString *elementType = [element.attributes objectForKey:@"type"];
	
	if ([name isEqualToString:@"complexType"])
	{
		currentDict = elementWalkerDict;
		
		// add to dictionary
		
		NSMutableDictionary *subElementsDict = [NSMutableDictionary dictionary];
		
		if (elementName)
		{
			[currentDict setObject:subElementsDict forKey:elementName];
		}
		else
		{
			NSLog(@"%@", element);
		}
		
		
		// new children go into this
		currentDict = subElementsDict;
	}
	else if (elementName && elementType)
	{
		[currentDict setObject:elementType forKey:elementName];
	}
	
	[element performActionOnElements:@selector(elementWalker:) target:self];
}

- (void)processingAfterLoading
{
	service = [self.documentRoot getNamedChild:@"service"];
	ports = [service getNamedChildren:@"port"];
	types = [documentRoot getNamedChild:@"types"];
	schema = [types getNamedChild:@"schema"];
}


- (BOOL) namespaceIsXMLSchema:(NSString *)namespace
{
	// expand namespace appreviation
	NSString *longNamespace = [namespaces objectForKey:namespace];
	
	if ([longNamespace isEqualToString:@"http://www.w3.org/2001/XMLSchema"])
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (SOAPVersion) versionOfSOAPSchema:(NSString *)namespace
{
	if ([namespace isEqualToString:@"http://schemas.xmlsoap.org/wsdl/soap12/"])
	{
		return SOAPVersion1_2;
	}
	else if ([namespace isEqualToString:@"http://schemas.xmlsoap.org/wsdl/soap/"])
	{
		return SOAPVersion1_0;
	}
	else
	{
		return SOAPVersionNone;
	}
}


- (NSMutableArray *) addElementTypesToArray:(NSMutableArray *)elementArray element:(XMLelement *)element
{
	if ([element.name isEqualToString:@"choice"] || [element.name isEqualToString:@"sequence"])
	{
		for (XMLelement *oneChoice in element.children)
		{
			[self addElementTypesToArray:elementArray element:oneChoice];
		}
		
		return elementArray;
	}
	
	NSString *elementName = [element.attributes objectForKey:@"name"];
	NSString *elementType = [element.attributes objectForKey:@"type"];
	
	NSString *maxOccurs = [element.attributes objectForKey:@"maxOccurs"];
	
	if ([maxOccurs isEqualToString:@"unbounded"])
	{
		// is array, we don't care about other type
		NSArray *typeParts = [elementType componentsSeparatedByString:@":"];
		
		
		NSDictionary *elementDict = [NSDictionary dictionaryWithObjectsAndKeys:@"@array", @"type", [NSString stringWithFormat:@"arrayOf%@", elementName], @"name", [typeParts lastObject], @"typeInArray", nil];
		[elementArray addObject:elementDict];
		
		return elementArray;
	}
	
	if ([elementName isEqualToString:@"return"])
	{
		elementName = @"_return";  // reserved word in objC
	}
	
	if (!elementType)
	{
		// try as ref, like for group
		elementType = [element.attributes objectForKey:@"ref"];
	}
	
	NSArray *typeParts = [elementType componentsSeparatedByString:@":"];
	
	if ([typeParts count]==2)
	{
		NSString *namespace = [typeParts objectAtIndex:0];
		NSString *type = [typeParts objectAtIndex:1];
		
		if ([self namespaceIsXMLSchema:namespace])
		{
			NSDictionary *elementDict = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", elementName, @"name", nil];
			[elementArray addObject:elementDict];
		}
		else
		{
			// another complex type
			if ([element.name isEqualToString:@"group"])
			{
				// if a group, we need to copy it's elements here as well
				
				// find group element
				NSString *ref = [element.attributes objectForKey:@"ref"];
				NSString *ref_without_ns = [[ref componentsSeparatedByString:@":"] lastObject];
				
				XMLelement *thisGroupElement = [[schema getNamedChildren:@"group" WithAttribute:@"name" HasValue:ref_without_ns] lastObject];
				
				[self addElementTypesToArray:elementArray element:thisGroupElement];
			}
			else
			{
				if ([element.name isEqualToString:@"element"]||[element.name isEqualToString:@"attribute"])
				{
					NSString *elementName = [element.attributes objectForKey:@"name"];
					NSString *elementType = [element.attributes objectForKey:@"type"];
					
					NSArray *typeParts = [elementType componentsSeparatedByString:@":"];
					
					if ([typeParts count]==2)
					{
						NSString *namespace = [typeParts objectAtIndex:0];
						NSString *type = [typeParts objectAtIndex:1];
						
						if ([self namespaceIsXMLSchema:namespace])
						{
							NSDictionary *elementDict = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", elementName, @"name", nil];
							[elementArray addObject:elementDict];						
						}
						else
						{
							XMLelement *referencedElement = [[schema getNamedChildren:@"complexType" WithAttribute:@"name" HasValue:type] lastObject];
							
							[self addElementTypesToArray:elementArray element:referencedElement];
						}
					}
				}
			}
		}
	}
	else 
	{
		// could be a choice or sequence, also append these children
		
		// if complexType, we need to check if it's array  || [element.name isEqualToString:@"complexType"]
		
		if ([element.name isEqualToString:@"choice"] || [element.name isEqualToString:@"sequence"] || [element.name isEqualToString:@"complexType"] || [element.name isEqualToString:@"group"])
		{
			for (XMLelement *oneChoice in element.children)
			{
				[self addElementTypesToArray:elementArray element:oneChoice];
			}
		}
		else
		{
			if (element)
			{
				NSLog(@"%@", element);
			}
		}
	}
	
	return elementArray;
}


- (NSArray *)parametersOfMessage:(XMLelement *)message
{
	//NSString *messageName = [message.attributes objectForKey:@"name"];
	
	NSMutableArray *retArray = [NSMutableArray array];
	
	NSArray *messageParts = [message getNamedChildren:@"part"];
	
	if (!messageParts)
	{
		// NSLog(@"no input parts --- HTML?");
	}
	else
	{
		for (XMLelement *onePart in messageParts)
		{
			NSString *partElementName = [onePart.attributes objectForKey:@"name"];
			NSString *partElementType = [onePart.attributes objectForKey:@"type"];
			
			if (!partElementType)
			{
				// might be an element
				partElementType = [onePart.attributes objectForKey:@"element"];
			}
			
			NSArray *typeParts = [partElementType componentsSeparatedByString:@":"];
			
			if ([typeParts count]==2)
			{
				NSString *namespace = [typeParts objectAtIndex:0];
				NSString *type = [typeParts objectAtIndex:1];
				
				if ([self namespaceIsXMLSchema:namespace])
				{
					// simple standard type
					
					NSDictionary *oneParamter = [NSDictionary dictionaryWithObjectsAndKeys:partElementName, @"name", type, @"type", nil];
					[retArray addObject:oneParamter];
				}
				else
				{
					// must be defined type
					XMLelement *element = [[schema getNamedChildren:@"element" WithAttribute:@"name" HasValue:type] lastObject];
					
					if (!element)
					{
						NSLog(@"Not found element with name %@", type);
					}
					
					NSString *elementName = [onePart.attributes objectForKey:@"name"];	
					
					NSString *elementType = [element.attributes objectForKey:@"type"];
					
					if (elementType)
					{
						// simple type
						NSArray *typeParts = [elementType componentsSeparatedByString:@":"];
						
						NSDictionary *oneParamter = [NSDictionary dictionaryWithObjectsAndKeys:elementName, @"name", [typeParts lastObject], @"type", nil];
						[retArray addObject:oneParamter];
					}
					else
					{	
						XMLelement *elementChild = [element.children objectAtIndex:0];
						
						if ([elementChild.name isEqualToString:@"complexType"])
						{
							if ([elementChild.children count]==0)
							{
								// dummy non-parameter
							}
							else
							{
								elementChild = [elementChild.children objectAtIndex:0];
								
								/*	
								 NSMutableArray *typeArray = [NSMutableArray array];
								 [self addElementTypesToArray:typeArray element:elementChild];
								 
								 for (NSDictionary *oneParam in typeArray)
								 {
								 NSDictionary *oneParamter = [NSDictionary dictionaryWithObjectsAndKeys:[oneParam objectForKey:@"name"], @"name", [oneParam objectForKey:@"type"], @"type", nil];
								 [retArray addObject:oneParamter];
								 } */
								//-	
								if ([elementChild.name isEqualToString:@"sequence"])
								{
									// sequence of elements
									
									for (XMLelement *oneElement in elementChild.children)
									{
										NSString *elementName = [oneElement.attributes objectForKey:@"name"];
										NSString *elementType = [oneElement.attributes objectForKey:@"type"];
										
										
										if (!elementType)
										{
											// we assume that's too complicated = Xml
											NSDictionary *oneParamter = [NSDictionary dictionaryWithObjectsAndKeys:elementName, @"name", @"xml", @"type", nil];
											[retArray addObject:oneParamter];
										}
										else
										{
											NSArray *typeParts = [elementType componentsSeparatedByString:@":"];
											
											
											NSMutableArray *typeArray = [NSMutableArray array];
											[self addElementTypesToArray:typeArray element:elementChild];
											
											
											// if this complex type is actually an array, we don't care about the type
											if (([typeArray count]==1)&&[[[typeArray lastObject] objectForKey:@"type"]hasPrefix:@"@array"])
											{
												//NSDictionary *oneParameter = 
												//[NSDictionary dictionaryWithObjectsAndKeys:elementName, @"name", @"@array", @"type", nil];
												[retArray addObject:[typeArray lastObject]];
											}
											else
											{
												NSDictionary *oneParameter = [NSDictionary dictionaryWithObjectsAndKeys:elementName, @"name", [typeParts lastObject], @"type", nil];
												[retArray addObject:oneParameter];
											}
										}
										
										
										
										
										
									}
									
								}
								// -
							}
						}
						
					}
				}
			}
		}
	}
	
	if ([retArray count])
	{
		return [NSArray arrayWithArray:retArray];
	}
	else
	{
		return nil;
	}
}

- (NSArray *)operationsForPort:(XMLelement *)port
{
	// get the binding
	NSString *portBinding = [port.attributes objectForKey:@"binding"];
	
	NSArray *tmpArray = [portBinding componentsSeparatedByString:@":"];
	
	NSString *bindingType = [tmpArray lastObject];
	
	XMLelement *binding = [[documentRoot getNamedChildren:@"binding" WithAttribute:@"name" HasValue:bindingType] objectAtIndex:0];
	
	
	// get input/output for portType
	
	NSString *port_type = [[[binding.attributes objectForKey:@"type"] componentsSeparatedByString:@":"] lastObject];
	XMLelement *portType = [[documentRoot getNamedChildren:@"portType" WithAttribute:@"name" HasValue:port_type] objectAtIndex:0];
	
	// loop through port operations
	return [portType getNamedChildren:@"operation"];
}


- (NSArray *)portNames
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (XMLelement *onePort in ports)
	{
		[tmpArray addObject:[onePort.attributes objectForKey:@"name"]];
	}
	
	if ([tmpArray count])
	{
		return [NSArray arrayWithArray:tmpArray];
	}
	else
	{
		return nil;
	}
}



#pragma mark Writing Class Files
// constructs objC prototype for .h and .m
- (NSString *)prototypeForOperation:(XMLelement *)operation
{
	NSString *operationName = [operation.attributes objectForKey:@"name"];
	
	NSMutableString *retStr = [NSMutableString string];
	
	// input
	XMLelement *input = [operation getNamedChild:@"input"];
	
	NSString *input_msg = [input.attributes objectForKey:@"message"];
	NSArray *tmpArray = [input_msg componentsSeparatedByString:@":"];
	XMLelement *inputMessage = [[documentRoot getNamedChildren:@"message" WithAttribute:@"name" HasValue:[tmpArray lastObject]] objectAtIndex:0];
	
	NSArray *inputParameters = [self parametersOfMessage:inputMessage];
	
	XMLelement *output = [operation getNamedChild:@"output"];
	NSString *output_msg = [output.attributes objectForKey:@"message"];
	tmpArray = [output_msg componentsSeparatedByString:@":"];
	XMLelement *outputMessage = [[documentRoot getNamedChildren:@"message" WithAttribute:@"name" HasValue:[tmpArray lastObject]] objectAtIndex:0];
	
	NSArray *outputParameters = [self parametersOfMessage:outputMessage];
	
	NSString *returnParamType;
	
	if (![outputParameters count])
	{
		returnParamType = @"void";
	}
	else
	{
		NSDictionary *returnParam = [outputParameters lastObject];
		
		NSString *returnSoapType = [returnParam objectForKey:@"type"];
		returnParamType = [self cocoaTypeForSoapType:returnSoapType];
		
		if (!returnParamType)
		{
			// complex type
			returnParamType = [NSString stringWithFormat:@"%@ *", returnSoapType];
		}
	}
	
	if ([outputParameters count]>1)
	{
		NSLog(@"Multiple return parameters not supported");
	}
	
	[retStr appendFormat:@"- (%@) %@", returnParamType, [operationName stringWithLowercaseFirstLetter]]; 
	
	
	for (int i=0; i<[inputParameters count];i++)
	{
		
		NSDictionary *inParam = [inputParameters objectAtIndex:i];
		NSString *inParamSoapType = [inParam objectForKey:@"type"];
		NSString *inParamType = [self cocoaTypeForSoapType:inParamSoapType];
		NSString *inParamName = [[inParam objectForKey:@"name"] stringWithLowercaseFirstLetter];
		
		//NSString *inParamCocoaType = [self cocoaTypeForSoapType:inParamSoapType];
		
		if (!inParamType)
		{
			// complex type
			inParamType = [NSString stringWithFormat:@"%@ *", inParamSoapType];
		}
		
		// first param with With
		if (!i)
		{
			[retStr appendString:@"With"]; 
			[retStr appendFormat:@"%@:(%@)%@", [inParamName stringWithUppercaseFirstLetter], inParamType, inParamName];
		}
		else 
		{
			[retStr appendString:@" "]; 
			[retStr appendFormat:@"%@:(%@)%@", inParamName, inParamType, inParamName];
		}
	}
	
	return [NSString stringWithString:retStr];
}



- (NSMutableArray *)iterateThroughGroupingsForElement:(XMLelement *)element intoArray:(NSMutableArray *)typeArray
{
	if (!element) return typeArray;
	
	if ([element.children count])
	{
		for (XMLelement *oneChild in element.children)
		{
			[self iterateThroughGroupingsForElement:oneChild intoArray:typeArray];
		}
	}
	else
	{
		NSString *elementName = [element.attributes objectForKey:@"name"];
		if ([elementName isEqualToString:@"return"])
		{
			elementName = @"_return";  // reserved word in objC
		}
		
		NSString *elementType = [element.attributes objectForKey:@"type"];
		NSArray *typeParts = [elementType componentsSeparatedByString:@":"];
		
		
		NSString *maxOccurs = [element.attributes objectForKey:@"maxOccurs"];
		
		if ([maxOccurs isEqualToString:@"unbounded"])
		{
			// is array, we don't care about other type
			NSArray *typeParts = [elementType componentsSeparatedByString:@":"];
			
			
			NSDictionary *elementDict = [NSDictionary dictionaryWithObjectsAndKeys:@"@array", @"type", [NSString stringWithFormat:@"%@", elementName], @"name", [typeParts lastObject], @"typeInArray", nil];
			[typeArray addObject:elementDict];
			
			return typeArray;
		}
		
		if ([typeParts count]==2)
		{
			NSString *namespace = [typeParts objectAtIndex:0];
			NSString *type = [typeParts objectAtIndex:1];
			
			if ([self namespaceIsXMLSchema:namespace])
			{
				NSDictionary *elementDict = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", elementName, @"name", nil];
				[typeArray addObject:elementDict];						
			}
			else
			{
				// peak and simplify
				
				NSArray *peakType = [self propertiesOfComplexType:type];
				NSLog(@"%@", peakType);
				
				if ([peakType count]==1)
				{
					// only one sub-element let's simplify
					NSMutableDictionary *simplifyType = [NSMutableDictionary dictionaryWithDictionary:[peakType lastObject]];
					[simplifyType setObject:elementName forKey:@"name"];
					NSDictionary *elementDict = [NSDictionary dictionaryWithDictionary:simplifyType];
					[typeArray addObject:elementDict];
				}
				else
				{
					NSDictionary *elementDict = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", elementName, @"name", nil];
					[typeArray addObject:elementDict];
				}
			}
		}
		else
		{
			// groups could be referenced here:
			if ([element.name isEqualToString:@"group"])
			{
				NSString *ref = [element.attributes objectForKey:@"ref"];
				NSArray *refParts = [ref componentsSeparatedByString:@":"];
				
				XMLelement *groupElement = [[schema getNamedChildren:@"group" WithAttribute:@"name" HasValue:[refParts lastObject]] lastObject];
				
				[self iterateThroughGroupingsForElement:groupElement intoArray:typeArray];
			}
			else
			{
				NSLog(@"strang: %@", element);
			}
		}
	}
	return typeArray;
}

- (NSArray *)propertiesOfComplexType:(NSString *)complexTypeName
{
	// get schema element
	XMLelement *schemaElement = [[schema getNamedChildren:@"complexType" WithAttribute:@"name" HasValue:complexTypeName] lastObject];
	
	
	NSMutableArray *typeArray = [NSMutableArray array];
	[self iterateThroughGroupingsForElement:schemaElement intoArray:typeArray];
	
	return [NSArray arrayWithArray:typeArray];
}


- (NSString *)headerForComplexTypes
{
	NSMutableString *tmpString = [NSMutableString string];
	NSMutableString *tmpClassesString = [NSMutableString string];
	
	for (XMLelement *element in schema.children)
	{
		
		// each complexType will become a class
		
		if ([element.name isEqualToString:@"complexType"])
		{
			NSString *className = [element.attributes objectForKey:@"name"];
			// get types
			
			NSArray *properties = [self propertiesOfComplexType:className];
			
			if ([className isEqualToString:@"RunInstancesType"])
			{
				NSLog(@"%@", element);
			}
			
			//XMLelement *child = [element.children lastObject];  // should be only one
			
			
			// check if it's array, we don't need a class for that
			
			
			//NSMutableDictionary *elementTypeDict = [NSMutableDictionary dictionary];
			//NSMutableArray *elementTypeArray = [NSMutableArray array];
			//[self addElementTypesToDictionary:elementTypeDict element:child];
			
			//NSArray *sortedKeys = [[elementTypeDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
			
			
			//[self addElementTypesToArray:elementTypeArray element:child];
			
			//NSLog(@"class: %@\n%@", className, properties);
			
			//if (([elementTypeArray count]>=1)&&(![[[elementTypeArray lastObject] objectForKey:@"type"] isEqualToString:@"@array"]))
			{
				[tmpClassesString appendFormat:@"@class %@;\n", className];
				
				// write ivars
				
				[tmpString appendFormat:@"@interface %@ : NSObject\n", className];
				[tmpString appendString:@"{\n"];
				
				for (NSDictionary *oneElement in properties)
				{
					NSString *elementName = [oneElement objectForKey:@"name"];
					NSString *elementType = [oneElement objectForKey:@"type"];
					NSString *elementCocoaType = [self cocoaTypeForSoapType:elementType];
					
					NSString *comment = @"";
					if ([elementType isEqualToString:@"@array"])
					{
						comment = [NSString stringWithFormat:@" // %@", [oneElement objectForKey:@"typeInArray"]];
					}
					
					[tmpString appendFormat:@"\t%@ %@;%@\n", elementCocoaType, elementName, comment];
				}
				
				[tmpString appendString:@"}\n"];
				
				// write properties
				
				for (NSDictionary *oneElement in properties)
				{
					NSString *elementName = [oneElement objectForKey:@"name"];
					NSString *elementType = [oneElement objectForKey:@"type"];
					NSString *elementCocoaType = [self cocoaTypeForSoapType:elementType];
					NSString *retainType = ([elementCocoaType hasSuffix:@"*"]?@"retain":@"assign");
					
					[tmpString appendFormat:@"\t@property (nonatomic, %@) %@ %@;\n", retainType, elementCocoaType, elementName];
				}
				
				[tmpString appendString:@"@end\n\n\n"];
			}
		}
	}
	
	NSMutableString *retString = [NSMutableString string];
	[retString appendString:@"// NOTE: defining all complex type as class so that the order does not matter\n\n"];
	[retString appendString:tmpClassesString];
	[retString appendString:@"\n\n#pragma mark Complex Type Interface Definitions \n\n"];
	[retString appendString:tmpString];
	
	return [NSString stringWithString:retString];
}

- (NSString *)implementationForComplexTypes
{
	NSMutableString *tmpString = [NSMutableString string];
	
	for (XMLelement *element in schema.children)
	{
		
		// each complexType will become a class
		
		if ([element.name isEqualToString:@"complexType"])
		{
			NSString *className = [element.attributes objectForKey:@"name"];
			NSArray *properties = [self propertiesOfComplexType:className];

			
			NSMutableString *tmpDeallocString = [NSMutableString string];
			
			
			//XMLelement *child = [element.children lastObject];  // should be only one
			
			//NSMutableArray *elementTypeArray = [NSMutableArray array];
			//[self addElementTypesToArray:elementTypeArray element:child];
			
			//if (([elementTypeArray count]>=1)&&(![[[elementTypeArray lastObject] objectForKey:@"type"] isEqualToString:@"@array"]))
			{
				
				
				[tmpString appendFormat:@"@implementation %@\n", className];
				
				for (NSDictionary *oneElement in properties)
				{
					NSString *elementName = [oneElement objectForKey:@"name"];
					NSString *elementType = [oneElement objectForKey:@"type"];
					
					if ([elementType hasSuffix:@"*"])
					{
						[tmpDeallocString appendFormat:@"\t[%@ release];\n", elementName];
					}
					
					[tmpString appendFormat:@"\t@synthesize %@;\n", elementName];
				}
				
				[tmpString appendString:@"\n-(NSString *) description\n"];
				[tmpString appendString:@"{\n"];
				[tmpString appendString:@"\tNSMutableString *tmpRet = [NSMutableString string];\n"];
				
				for (NSDictionary *oneElement in properties)
				{
					NSString *elementName = [oneElement objectForKey:@"name"];
					[tmpString appendFormat:@"\t[tmpRet appendFormat:@\"<%@>%%@</%@>\", [self valueForKey:@\"%@\"]];\n", elementName, elementName, elementName];
				}
				
				[tmpString appendString:@"\treturn [NSString stringWithString:tmpRet];\n"];
				[tmpString appendString:@"}\n"];
				
				
				[tmpString appendString:@"\n-(void) dealloc\n"];
				[tmpString appendString:@"{\n"];
				[tmpString appendString:tmpDeallocString];
				[tmpString appendString:@"\t[super dealloc];\n"];
				[tmpString appendString:@"}\n"];
				
				[tmpString appendString:@"@end\n\n\n"];
			}
		}
	}
	
	return [NSString stringWithString:tmpString];
}

- (void)writeClassFilesForPort:(NSString *)portName
{
	XMLelement *port = [ports elementWhereAttribute:@"name" HasValue:portName];
	
	
	if (!port)
	{
		NSLog(@"Invalid port name '%@'", portName);
		return;
	}
	
	NSString *portBinding = [port.attributes objectForKey:@"binding"];
	XMLelement *address = [port getNamedChild:@"address"];
	NSString *address_url = [address.attributes objectForKey:@"location"];
	
	
	//  
	// get the binding
	
	NSArray *tmpArray = [portBinding componentsSeparatedByString:@":"];
	NSString *bindingType = [tmpArray lastObject];
	XMLelement *binding = [[documentRoot getNamedChildren:@"binding" WithAttribute:@"name" HasValue:bindingType] objectAtIndex:0];
	
	XMLelement *subBinding = [binding getNamedChild:@"binding"];
	
	//NSString *transport = [subBinding.attributes objectForKey:@"transport"];
	
	
	
	NSArray *operations = [self operationsForPort:port];
	
	
	NSMutableString *classHeader = [NSMutableString string];
	NSMutableString *classBody = [NSMutableString string];
	
	// Patched: added service and portname to filename (otherwise multiple ports in the same service would overwrite others)
	NSString *headerFilename = [NSString stringWithFormat:@"%@-%@.h",[self serviceName], portName];
	NSString *bodyFilename = [NSString stringWithFormat:@"%@-%@.m", [self serviceName], portName];
	
	
	// HEADER
	
	[classHeader appendFormat:@"// %@.h \n\n", [self serviceName]];
	[classHeader appendString:@"#import <Foundation/Foundation.h>\n"];
	[classHeader appendString:@"#import \"WebService.h\"\n\n"];
	[classHeader appendString:@"#import \"NSString+Helpers.h\"\n"];
	[classHeader appendString:@"#import \"NSDate+xml.h\"\n\n"];
	[classHeader appendString:@"#import \"NSDataAdditions.h\"\n\n"];
	
	
	// add classes for complex data types
	
	[classHeader appendString:[self headerForComplexTypes]];
	
	// main class for service
	[classHeader appendString:@"#pragma mark -\n"];
	[classHeader appendString:@"#pragma mark Main WebService Interface\n"];
	
	[classHeader appendFormat:@"@interface %@ : WebService\n{\n}\n\n", [self serviceName]];
	
	for (XMLelement *oneOperation in operations)
	{
		
		NSString *prototype = [self prototypeForOperation:oneOperation];
		[classHeader appendFormat:@"%@;\n", prototype];
		
	}
	
	[classHeader appendString:@"\n@end"];
	
	// BODY
	
	[classBody appendFormat:@"// %@.m \n\n", [self serviceName]];
	[classBody appendFormat:@"#import \"%@.h\"\n", [self serviceName]];
	[classBody appendString:@"#import \"XMLdocument.h\"\n\n"];
	
	[classBody appendString:[self implementationForComplexTypes]];
	
	[classBody appendFormat:@"@implementation %@\n\n", [self serviceName]];
	
	for (XMLelement *oneOperation in operations)
	{
		NSString *operationName = [oneOperation.attributes objectForKey:@"name"];
		
		NSString *prototype = [self prototypeForOperation:oneOperation];
		[classBody appendFormat:@"%@\n{\n", prototype];
		
		// get input parameters
		
		// input
		XMLelement *input = [oneOperation getNamedChild:@"input"];
		
		NSString *input_msg = [input.attributes objectForKey:@"message"];
		NSArray *tmpArray = [input_msg componentsSeparatedByString:@":"];
		XMLelement *inputMessage = [[documentRoot getNamedChildren:@"message" WithAttribute:@"name" HasValue:[tmpArray lastObject]] objectAtIndex:0];
		
		NSArray *inputParameters = [self parametersOfMessage:inputMessage];
		
		// output
		XMLelement *output = [oneOperation getNamedChild:@"output"];
		NSString *output_msg = [output.attributes objectForKey:@"message"];
		tmpArray = [output_msg componentsSeparatedByString:@":"];
		XMLelement *outputMessage = [[documentRoot getNamedChildren:@"message" WithAttribute:@"name" HasValue:[tmpArray lastObject]] objectAtIndex:0];
		NSArray *outputParameters = [self parametersOfMessage:outputMessage];
		
		// to know how to encode it we need to look it up in the binding
		XMLelement *operationInBinding = [[binding getNamedChildren:@"operation" WithAttribute:@"name" HasValue:operationName] lastObject];
		XMLelement *suboperation = [operationInBinding getNamedChild:@"operation"];
		
		SOAPVersion soapVersion = [self versionOfSOAPSchema:suboperation.namespace];
		NSString *resultString;
		
		if (soapVersion!=SOAPVersionNone)
		{
			// SOAP
			NSString *soapAction = [suboperation.attributes objectForKey:@"soapAction"];
			// operationName is set
			// namespace: 
			
			NSString *targetNamespace = [documentRoot.attributes objectForKey:@"targetNamespace"];
			
			[classBody appendFormat:@"\tNSString *location = @\"%@\";\n", address_url];
			
			[classBody appendString:@"\tNSMutableArray *paramArray = [NSMutableArray array];\n"];
			
			
			for (NSDictionary *oneParam in inputParameters)
			{
				NSString *paramName = [oneParam objectForKey:@"name"];
				NSString *paramSoapType = [oneParam objectForKey:@"type"];
				NSString *paramType = [self cocoaTypeForSoapType:paramSoapType];
				
				if (!paramType)
				{
					// complex type
					paramType = [NSString stringWithFormat:@"%@ *", paramSoapType];
				}
				
				
				NSString *methodParamName = [[oneParam objectForKey:@"name"] stringWithLowercaseFirstLetter];
				NSString *convertedVariable = [self conversionFromTypeToNSString:paramType variable:methodParamName];
				
				if (!convertedVariable) convertedVariable = methodParamName;
				
				if ([paramType hasSuffix:@"*"])
				{
					[classBody appendFormat:@"\t[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@\"%@\", @\"name\",%@?%@:@\"\", @\"value\", nil]];\n", paramName, methodParamName, convertedVariable];
				}
				else
				{
					[classBody appendFormat:@"\t[paramArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@\"%@\", @\"name\",%@, @\"value\", nil]];\n", paramName, convertedVariable];
				}

			}
			
			if (soapVersion==SOAPVersion1_0)
			{
				[classBody appendFormat:@"\tNSURLRequest *request = [self makeSOAPRequestWithLocation:location Parameters:paramArray Operation:@\"%@\" Namespace:@\"%@\" Action:@\"%@\" SOAPVersion:SOAPVersion1_0];\n", operationName, targetNamespace, soapAction];
			}
			else if (soapVersion==SOAPVersion1_2)
			{
				[classBody appendFormat:@"\tNSURLRequest *request = [self makeSOAPRequestWithLocation:location Parameters:paramArray Operation:@\"%@\" Namespace:@\"%@\" Action:@\"%@\" SOAPVersion:SOAPVersion1_2];\n", operationName, targetNamespace, soapAction];
			}
			
			
			resultString = @"\tNSString *result = [self returnValueFromSOAPResponse:xml];\n";
		}
		else if ([suboperation.namespace isEqualToString:@"http://schemas.xmlsoap.org/wsdl/http/"])
		{
			// HTTP GET / POST
			NSString *verb = [subBinding.attributes objectForKey:@"verb"];	
			
			if (!verb)
			{
				[classBody appendString:@"#error HTTP Transport specified, but no VERB\n"];
			}
			
			NSString *path = [suboperation.attributes objectForKey:@"location"];
			
			NSString *location = [address_url stringByAppendingString:path];
			[classBody appendFormat:@"\tNSString *location = @\"%@\";\n", location];
			
			[classBody appendString:@"\tNSMutableDictionary *paramDict = [NSMutableDictionary dictionary];\n"];
			
			
			for (NSDictionary *oneParam in inputParameters)
			{
				NSString *paramName = [oneParam objectForKey:@"name"];
				NSString *methodParamName = [[oneParam objectForKey:@"name"] stringWithLowercaseFirstLetter];
				
				[classBody appendFormat:@"\t[paramDict setObject:%@ forKey:@\"%@\"];\n", methodParamName, paramName];
			}
			
			[classBody appendFormat:@"\tNSURLRequest *request = [self make%@RequestWithLocation:location Parameters:paramDict];\n", verb];
			resultString = @"\tNSString *result = xml.documentRoot.text;\n";
		}	
		else
		{
			[classBody appendFormat:@"#error Unknown transport with schema '%@'\n", suboperation.namespace];;
		}
		
		[classBody appendString:@"\tNSURLResponse *response;\n"];
		[classBody appendString:@"\tNSError *error;\n"];
		[classBody appendString:@"\tNSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];\n"];
		[classBody appendString:@"\tXMLdocument *xml = [XMLdocument documentWithData:data];\n"];
		
		if (outputParameters)
		{
			
			NSDictionary *outParam = [outputParameters objectAtIndex:0];
			NSString *outParamType = [self cocoaTypeForSoapType:[outParam objectForKey:@"type"]];
			
			NSString *convertedVariable = [self conversionFromNSStringToType:outParamType variable:@"result"];
			//if (!convertedVariable) convertedVariable = outParamType;
			
			if (convertedVariable)
			{
				[classBody appendString:resultString];
				[classBody appendFormat:@"\treturn (%@) %@;\n", outParamType, convertedVariable];
			}
			else
			{
				NSString *otherType = [outParam objectForKey:@"type"];
				
				if ([otherType isEqualToString:@"xml"])
				{
					[classBody appendString:@"\treturn [self returnXMLDocumentFromSOAPResponse:xml];  // unknown complex type \n"];
				}
				else if ([otherType hasPrefix:@"@array"])
				{	
					NSString *typeInArray = [outParam objectForKey:@"typeInArray"];
					[classBody appendFormat:@"\treturn [self returnArrayFromSOAPResponse:xml withClass:[%@ class]];  //array \n", typeInArray];
				}
				else
				{
					[classBody appendFormat:@"\treturn [self returnComplexTypeFromSOAPResponse:xml asClass:[%@ class]];  // complex type \n", otherType];
				}
				
				//[classBody appendFormat:@"#error complex type '%@' not yet implemented\n", [outParam objectForKey:@"type"]];
			}
		}
		
		[classBody appendFormat:@"}\n\n", prototype];
	}
	
	[classBody appendString:@"\n@end"];
	
	
	//NSLog(@"%@", classHeader);
	//NSLog(@"%@", classBody);
	
	// 
	[classHeader writeToFile:headerFilename  atomically:NO encoding:NSUTF8StringEncoding error:nil];
	[classBody writeToFile:bodyFilename atomically:NO encoding:NSUTF8StringEncoding error:nil];
	
}

#pragma mark delegate methods
- (void) xmlDocumentDidFinish:(XMLdocument *)xmlDocuments
{
	[self processingAfterLoading];
}

@end
