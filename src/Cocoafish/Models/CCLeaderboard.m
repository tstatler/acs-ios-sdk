//
//  CCLeaderboard.m
//  Demo
//
//  Created by Wei Kong on 5/7/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCLeaderboard.h"
#import "CCUser.h"
@interface CCLeaderboard ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, readwrite) NSInteger score;
@property (nonatomic, retain, readwrite) CCUser *user;
@end

@implementation CCLeaderboard
@synthesize name = _name;
@synthesize score = _score;
@synthesize user = _user;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{
	if ((self = [super initWithJsonResponse:jsonResponse])) {
        @try {
            self.name = [jsonResponse objectForKey:CC_JSON_NAME];
            self.score = [[jsonResponse objectForKey:@"score"] intValue];	
			self.user = [[CCUser alloc] initWithJsonResponse:[jsonResponse objectForKey:CC_JSON_USER]];

		}
		@catch (NSException *e) {
			NSLog(@"Error: Failed to parse leaderboard object. Reason: %@", [e reason]);
			[self release];
			self = nil;
		}
	
	}
	
	return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CCLeaderboard\n\tname: %@\n\tscore: %d\n\t%@", 
            self.name, self.score, [super description]];
}

-(void)dealloc
{
	self.name = nil;
	self.user = nil;
	[super dealloc];
}

@end
