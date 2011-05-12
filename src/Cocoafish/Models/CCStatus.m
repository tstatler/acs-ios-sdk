//
//  CCStatus.m
//  Cocoafish-ios-sdk
//
//  Created by Wei Kong on 2/6/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCStatus.h"
#import "CCUser.h"

@interface CCStatus ()

@property (nonatomic, retain, readwrite) NSString *message;
@property (nonatomic, retain, readwrite) CCUser *user;

@end

@implementation CCStatus
@synthesize message = _message;
@synthesize user = _user;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{
	if ((self = [super initWithJsonResponse:jsonResponse])) {
		self.message = [jsonResponse objectForKey:CC_JSON_MESSAGE];
        self.user = [[CCUser alloc] initWithJsonResponse:[jsonResponse objectForKey:CC_JSON_USER]];
	}
	
	return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CCStatus:\n\tmessage: '%@'\n\t%@",
            self.message, [super description]];
}

-(void)dealloc
{
	self.message = nil;
    self.user = nil;
	[super dealloc];
}

@end
