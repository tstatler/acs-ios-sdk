//
//  RootViewController.h
//  APIs
//
//  Created by Wei Kong on 3/18/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Cocoafish.h"
#import "CheckinViewController.h"

typedef enum SECTIONS {
    USERS,
    PLACES,
    CHECKINS,
    STATUSES,
    MESSAGES,
    PHOTOS,
    KEY_VALUES,
    EVENTS,
    CLIENTS,
    POSTS,
    NUM_SECTIONS
} sections;

@interface RootViewController : UITableViewController <UIAlertViewDelegate, CCRequestDelegate, CCFBSessionDelegate> {
    CCPlace *testPlace;
    NSIndexPath *lastIndexPath;
    CCPhoto *testPhoto;
    CCEvent *testEvent;
    CCMessage *testMessage;
    CCPost *testPost;
}


@end
