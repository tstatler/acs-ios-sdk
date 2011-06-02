//
//  CCCheckin.m
//  Demo
//
//  Created by Wei Kong on 12/17/10.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCCheckin.h"
#import "CCUser.h"
#import "CCPlace.h"

@interface CCCheckin ()

@property (nonatomic, retain, readwrite) CCUser *user;
@property (nonatomic, retain, readwrite) CCPlace *place;
@property (nonatomic, retain, readwrite) NSString *message;

@end

@implementation CCCheckin
@synthesize user = _user;
@synthesize place = _place;
@synthesize message = _message;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{
	self = [super initWithJsonResponse:jsonResponse];
	if (self) {
        self.message = [jsonResponse objectForKey:CC_JSON_MESSAGE];
		@try {
			self.user = [[CCUser alloc] initWithJsonResponse:[jsonResponse objectForKey:CC_JSON_USER]];
			self.place = [[CCPlace alloc] initWithJsonResponse:[jsonResponse objectForKey:CC_JSON_PLACE]];
		}
		@catch (NSException *e) {
			NSLog(@"Error: Failed to parse checkin object. Reason: %@", [e reason]);
			[self release];
			self = nil;
            return self;
		}
        if (self.user == nil || self.place == nil) {
            NSLog(@"invalid checkin object from server: %@", jsonResponse);
            [self release];
            self = nil;
            return self;
        }
	}
	return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CCCheckin:\n\tmessage=%@\n\tuser=[\n\t%@\n\t]\n\tplace=[\n\t%@\n\t]\n\t%@",
                                    self.message, [self.user description],
                                    [self.place description], [super description]];
}

-(NSString *)modelName
{
    return @"checkin";
}

-(void)dealloc
{
	self.user = nil;
	self.place = nil;
	self.message = nil;
	[super dealloc];
}

@end
