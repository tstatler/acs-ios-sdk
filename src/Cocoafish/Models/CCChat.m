//
//  CCChat.m
//  APIs
//
//  Created by Wei Kong on 6/17/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCChat.h"
#import "CCUser.h"

@interface CCChat()

@property (nonatomic, retain, readwrite) NSString *message;
@property (nonatomic, retain, readwrite) CCUser *from;
@property (nonatomic, retain, readwrite) CCUser *to;

@end

@implementation CCChat
@synthesize message = _message;
@synthesize from = _from;
@synthesize to = _to;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{
	if ((self = [super initWithJsonResponse:jsonResponse])) {
		self.message = [jsonResponse objectForKey:CC_JSON_MESSAGE];
        _from = [[CCUser alloc] initWithJsonResponse:[jsonResponse objectForKey:@"from"]];
        _to = [[CCUser alloc] initWithJsonResponse:[jsonResponse objectForKey:@"to"]];
	}
	
	return self;
}

/*- (NSString *)description {
 return [NSString stringWithFormat:@"CCStatus:\n\tmessage: '%@'\n\t%@",
 self.message, [super description]];
 }*/

+(NSString *)modelName
{
    return @"chat";
}

-(void)dealloc
{
	self.message = nil;
    self.from = nil;
    self.to = nil;
	[super dealloc];
}

@end
