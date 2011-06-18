//
//  CCKeyValuePair.m
//  Cocoafish-ios-sdk
//
//  Created by Wei Kong on 2/8/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCKeyValuePair.h"
#import "NSString+HTML.h"
#import "YAJL/YAJL.h"

@interface CCKeyValuePair ()

@property (nonatomic, retain, readwrite) NSString *key;
@property (nonatomic, retain, readwrite) NSString *value;
@property (nonatomic, retain, readwrite) NSDictionary *valueDictionary;
@end

@implementation CCKeyValuePair
@synthesize key = _key;
@synthesize value = _value;
@synthesize valueDictionary = _valueDictionary;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{
	if ((self = [super initWithJsonResponse:jsonResponse])) {
		self.key = [jsonResponse objectForKey:CC_JSON_KEY];
		NSString *jsonValue = [jsonResponse objectForKey:CC_JSON_VALUE];	

        jsonValue = [jsonValue stringByDecodingHTMLEntities];
        NSDictionary *valueJsonDictionary = nil;
        @try {
             valueJsonDictionary = [jsonValue yajl_JSON];
        } @catch (NSException *e) {
            // result is not a dictionary
        }
        if (valueJsonDictionary) {
            self.valueDictionary = valueJsonDictionary;
        } else {
            self.value = jsonValue;
        }
	}
	
	return self;
}

/*- (NSString *)description {
    return [NSString stringWithFormat:@"CCKeyValuePair\n\tkey: %@\n\tvalue: %@\n\t%@", 
            self.key, self.value, [super description]];
}*/

+(NSString *)modelName
{
    return @"keyvalue";
}

+(NSString *)jsonTag
{
    return @"keyvalues";
}

-(void)dealloc
{
	self.key = nil;
	self.value = nil;
    self.valueDictionary = nil;
	[super dealloc];
}


@end
