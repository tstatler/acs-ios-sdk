//
//  PlaceViewController.h
//  Demo
//
//  Created by Wei Kong on 10/17/10.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Cocoafish.h"
#import "CheckinViewController.h"

@class CheckinViewController;
@interface PlaceViewController : UITableViewController <CheckinViewControllerDelegate, CCRequestDelegate> {
	CCPlace *place;
	NSMutableArray *placeCheckins;
		
	NSMutableDictionary *imageDownloadsInProgress;  // the set of IconDownloader objects for each checkin photo
}

@property (nonatomic, retain) CCPlace *place;
@property (nonatomic, retain) NSMutableArray *placeCheckins;
@end
