//
//  CCPost.h
//  Demo
//
//  Created by Wei Kong on 7/28/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCObjectWithPhoto.h"

@class CCUser;
@interface CCPost : CCObjectWithPhoto {
@private
    NSString *_title;
    NSString *_content;
	CCUser *_user;
    NSInteger _reviewsCount;
    double _ratingAverage;
    NSDictionary *_ratingsSummary;
}

@property (nonatomic, retain, readonly) NSString *title;
@property (nonatomic, retain, readonly) NSString *content;
@property (nonatomic, retain, readonly) CCUser *user;
@property (nonatomic, readonly) NSInteger reviewsCount;
@property (nonatomic, readonly) double ratingAverage;
@property (nonatomic, retain, readonly) NSDictionary *ratingsSummary;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse;

@end
