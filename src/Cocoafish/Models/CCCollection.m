//
//  CCCollection.m
//  ZipLyne
//
//  Created by Wei Kong on 6/3/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCCollection.h"
#import "CCPhoto.h"
#import "CCUser.h"

@interface CCCollection ()

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, readwrite) NSInteger size;
@property (nonatomic, retain, readwrite) CCPhoto *cover_photo;
@property (nonatomic, retain, readwrite) NSArray *photos;
@property (nonatomic, retain, readwrite) CCUser *user;
@end

@implementation CCCollection

@synthesize name = _name;
@synthesize size = _size;
@synthesize cover_photo = _cover_photo;
@synthesize photos = _photos;
@synthesize user = _user;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{
	self = [super initWithJsonResponse:jsonResponse];
	if (self) {
        
		self.name = [jsonResponse objectForKey:@"name"];
		self.size = [[jsonResponse objectForKey:@"size"] intValue];
		_cover_photo = [[CCPhoto alloc] initWithJsonResponse:[jsonResponse objectForKey:@"cover_photo"]];
        _user = [[CCUser alloc] initWithJsonResponse:[jsonResponse objectForKey:@"user"]];
        self.photos = [CCPhoto arrayWithJsonResponse:jsonResponse class:[CCPhoto class]];
	}
	return self;
}


// class name on the server
+(NSString *)modelName
{
   return @"collection";
}

-(void)dealloc
{
    self.name = nil;
    self.cover_photo = nil;
    self.user = nil;
    self.photos = nil;
    [super dealloc];
}
@end
