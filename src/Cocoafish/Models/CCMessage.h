//
//  CCMessage.h
//  Demo
//
//  Created by Wei Kong on 4/5/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCObject.h"

@class CCUser;
@interface CCMessage : CCObject {
@private
    NSString *threadId;
    NSString *status;
    NSString *subject;
    NSString *body;
    CCUser *from;
    NSArray *to; // list of users the message was sent to
}

@property (nonatomic, retain, readonly) NSString *threadId;
@property (nonatomic, retain, readonly) NSString *status;
@property (nonatomic, retain, readonly) NSString *subject;
@property (nonatomic, retain, readonly) NSString *body;
@property (nonatomic, retain, readonly) CCUser *from;
@property (nonatomic, retain, readonly) NSArray *to;

@end
