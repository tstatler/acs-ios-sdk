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
    CCPhoto *_cover_photo;
    NSArray *_photos;
    CCUser *_user; // owner
}

@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, readonly) NSInteger size;
@property (nonatomic, retain, readonly) CCPhoto *cover_photo;
@property (nonatomic, retain, readonly) NSArray *photos;
@property (nonatomic, retain, readonly) CCUser *user;

@end
