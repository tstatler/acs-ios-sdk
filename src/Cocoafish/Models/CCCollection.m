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
@property (nonatomic, retain, readwrite) CCPhoto *coverPhoto;
@property (nonatomic, retain, readwrite) NSArray *photos;
@property (nonatomic, retain, readwrite) CCUser *user;
@property (nonatomic, retain, readwrite) NSArray *collections;
@end

@implementation CCCollection

@synthesize name = _name;
@synthesize size = _size;
@synthesize coverPhoto = _coverPhoto;
@synthesize photos = _photos;
@synthesize user = _user;
@synthesize collections = _subCollections;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{
	self = [super initWithJsonResponse:jsonResponse];
	if (self) {
        
		self.name = [jsonResponse objectForKey:@"name"];
		self.size = [[jsonResponse objectForKey:@"size"] intValue];
		_coverPhoto = [[CCPhoto alloc] initWithJsonResponse:[jsonResponse objectForKey:@"cover_photo"]];
        _user = [[CCUser alloc] initWithJsonResponse:[jsonResponse objectForKey:@"user"]];
        self.photos = [CCPhoto arrayWithJsonResponse:jsonResponse class:[CCPhoto class]];
        self.collections = [CCCollection arrayWithJsonResponse:jsonResponse class:[CCCollection class]];
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
    self.coverPhoto = nil;
    self.user = nil;
    self.photos = nil;
    self.collections = nil;
    [super dealloc];
}
@end
