//
//  NSString+Helpers.h
//
//  Created by Oliver on 15.06.09.
//  Copyright 2009 drobnik.com. All rights reserved.
//

@interface NSString (Helpers)

// helper function
- (NSString *) getValueForNamedColumn:(NSString *)column_name  headerNames:(NSArray *)header_names;
- (NSDate *) dateFromString;
- (NSDate *) dateFromISO8601;
- (NSDate *) dateFromDottedTimestamp;
- (NSDate *) dateFromDottedDMY;
- (NSArray *) optionsFromSelect;
- (NSString *) stringByUrlEncoding;
- (NSString *) stringByUrlDecoding;
- (NSString *) stringWithLowercaseFirstLetter;
- (NSString *) stringWithUppercaseFirstLetter;

- (NSComparisonResult)compareDesc:(NSString *)aString;


// md5 maker
- (NSString * )md5;

+ (NSString *) stringFromFormattingBytes:(NSUInteger)bytes;

@end
