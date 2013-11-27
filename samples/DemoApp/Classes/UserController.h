//
//  UserController.h
//  Demo
//
//  Created by Wei Kong on 10/15/10.
//  Copyright 2011 Appcelerator Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACSClient.h"

@interface UserController : UITableViewController <CCRequestDelegate, CCFBSessionDelegate> {

	NSArray *userCheckins; // list of places checked in
}

-(void)getUserCheckins;

@end
