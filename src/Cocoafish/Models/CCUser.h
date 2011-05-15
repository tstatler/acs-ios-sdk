//
//  CCUser.h
//  Demo
//
//  Created by Wei Kong on 12/16/10.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCObjectWithPhoto.h"

@interface CCUser : CCObjectWithPhoto <NSCopying> {

	NSString *_firstName;
	NSString *_lastName;
	NSString *_email;
	NSString *_username;
//	Boolean	_facebookAuthorized;
@private
    NSString *_facebookAccessToken;
}

@property (nonatomic, retain, readwrite) NSString *firstName;
@property (nonatomic, retain, readwrite) NSString *lastName;
@property (nonatomic, retain, readwrite) NSString *email;
@property (nonatomic, retain, readwrite) NSString *username;
//@property (nonatomic, readonly) Boolean facebookAuthorized;
@property (nonatomic, retain, readwrite) NSString *facebookAccessToken;

-(id)initWithId:(NSString *)objectId first:(NSString *)first last:(NSString *)last email:(NSString *)email username:(NSString *)username;

@end


