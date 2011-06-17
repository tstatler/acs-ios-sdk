//
//  CCChat.h
//  APIs
//
//  Created by Wei Kong on 6/17/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCObject.h"

@class CCUser;

@interface CCChat : CCObject {
    NSString *_message;
    CCUser *_from;
    CCUser *_to;
}

@property (nonatomic, retain, readonly) NSString *message;
@property (nonatomic, retain, readonly) CCUser *from;
@property (nonatomic, retain, readonly) CCUser *to;

@end
