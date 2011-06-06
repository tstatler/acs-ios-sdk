//
//  CCCollection.h
//  ZipLyne
//
//  Created by Wei Kong on 6/3/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCObject.h"

@class CCPhoto;
@class CCUser;
@interface CCCollection : CCObject {
@private
    NSString *_name;
    NSInteger _size;
    CCPhoto *_coverPhoto;
    NSArray *_photos;
    CCUser *_user; // owner
    NSArray *_collections; // sub collections
}

@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, readonly) NSInteger size;
@property (nonatomic, retain, readonly) CCPhoto *coverPhoto;
@property (nonatomic, retain, readonly) NSArray *photos;
@property (nonatomic, retain, readonly) CCUser *user;
@property (nonatomic, retain, readonly) NSArray *collections;

@end
