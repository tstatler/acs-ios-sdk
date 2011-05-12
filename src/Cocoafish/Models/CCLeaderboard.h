//
//  CCLeaderboard.h
//  Demo
//
//  Created by Wei Kong on 5/7/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "CCObject.h"
@class CCUser;
@interface CCLeaderboard : CCObject {
	NSString *_name;
	NSInteger _score;
    CCUser *_user;
}

@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, readonly) NSInteger score;
@property (nonatomic, retain, readonly) CCUser *user;

@end
