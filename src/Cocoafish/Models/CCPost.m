//
//  CCPost.m
//  Demo
//
//  Created by Wei Kong on 7/28/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCPost.h"
#import "CCUser.h"

@interface CCPost ()
@property (nonatomic, retain, readwrite) NSString *title;
@property (nonatomic, retain, readwrite) NSString *content;
@property (nonatomic, retain, readwrite) CCUser *user;
@property (nonatomic, readwrite) NSInteger reviewsCount;
@property (nonatomic, readwrite) double ratingAverage;
@property (nonatomic, retain, readwrite) NSDictionary *ratingsSummary;
@end

@implementation CCPost
@synthesize title = _title;
@synthesize content = _content;
@synthesize user = _user;
@synthesize reviewsCount = _reviewsCount;
@synthesize ratingAverage = _ratingAverage;
@synthesize ratingsSummary = _ratingsSummary;


-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{
	self = [super initWithJsonResponse:jsonResponse];
	if (self) {
		@try {
            self.content = [jsonResponse objectForKey:@"content"];
			_user = [[CCUser alloc] initWithJsonResponse:[jsonResponse objectForKey:CC_JSON_USER]];            
        }
		@catch (NSException *e) {
			NSLog(@"Error: Failed to parse Post object. Reason: %@", [e reason]);
			[self release];
			self = nil;
		}
        self.title = [jsonResponse objectForKey:@"title"];
        NSString *tmpStr = [jsonResponse objectForKey:@"reviews_count"];
        if (tmpStr) {
            _reviewsCount = [tmpStr intValue];
        }
        tmpStr = [jsonResponse objectForKey:@"rating_average"];
        if (tmpStr) {
            _ratingAverage = [tmpStr doubleValue];
        }
        self.ratingsSummary = [jsonResponse objectForKey:@"ratings_summary"];
        
	}
	return self;
}

/*- (NSString *)description {
 return [NSString stringWithFormat:@"CCEvent:\n\tname=%@\n\tdetails=%@\n\tstartTime=%@\n\tendTime=%@\n\tuser=[\n\t%@\n\t]\n\tplace=[\n\t%@\n\t]\n\t%@",
 self.name, self.details, [self.startTime description], [self.endTime description], [self.user description],
 [self.place description], [super description]];
 }*/

+(NSString *)modelName
{
    return @"post";
}

+(NSString *)jsonTag
{
    return @"posts";
}

-(void)dealloc
{
	self.user = nil;
	self.title = nil;
	self.content = nil;
    self.ratingsSummary = nil;
	[super dealloc];
}
@end
