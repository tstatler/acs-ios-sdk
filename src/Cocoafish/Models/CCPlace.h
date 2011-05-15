//
//  CCPlace.h
//  Demo
//
//  Created by Wei Kong on 12/15/10.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCObjectWithPhoto.h"
#import <CoreLocation/CoreLocation.h>

@interface CCPlace : CCObjectWithPhoto <NSCopying> {

@protected
	NSString *_name;
	NSString *_address;
	NSString *_crossStreet;
	NSString *_city;
	NSString *_state; 
    NSString *_postalCode;
	NSString *_country;
	NSString *_phone;
    NSString *_website;
    NSString *_twitter;
	CLLocation *_location;
}

@property (nonatomic, retain, readwrite) NSString *name;
@property (nonatomic, retain, readwrite) NSString *address;
@property (nonatomic, retain, readwrite) NSString *crossStreet;
@property (nonatomic, retain, readwrite) NSString *city;
@property (nonatomic, retain, readwrite) NSString *state;
@property (nonatomic, retain, readwrite) NSString *postalCode;
@property (nonatomic, retain, readwrite) NSString *country;
@property (nonatomic, retain, readwrite) NSString *phone;
@property (nonatomic, retain, readwrite) NSString *website;
@property (nonatomic, retain, readwrite) NSString *twitter;
@property (nonatomic, retain, readwrite) CLLocation *location;

@end
