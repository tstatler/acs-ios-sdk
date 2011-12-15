//
//  RootViewController.m
//  APIs
//
//  Created by Wei Kong on 3/18/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "RootViewController.h"
#import "Cocoafish.h"
#import "LoginViewController.h"
#import "APIViewController.h"
#import "AlertPrompt.h"
#import "APIsAppDelegate.h"
#import "PhotoAddViewController.h"

@interface RootViewController ()

-(Boolean)checkTestPlace;
-(Boolean)checkTestPhoto;
-(Boolean)checkTestEvent;
-(Boolean)checkTestMessage;
-(Boolean)checkTestPost;
@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![[Cocoafish defaultCocoafish] getCurrentUser]) {
        // not logged in yet, show the login/signup window
        LoginViewController *controller = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        [self.navigationController pushViewController:controller animated:NO];
        [controller release];
    } else {
        UIBarButtonItem *button;
        
		// create the logout button	
		button = [[UIBarButtonItem alloc] initWithTitle:@"Delete Account" style:UIBarButtonItemStylePlain target:self action:@selector(deleteAccount)];
		self.navigationItem.rightBarButtonItem = button;
		[button release];
		
        button = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(startLogout)];
        self.navigationItem.leftBarButtonItem = button;
		[button release];
		
    }
    testPlace = ((APIsAppDelegate *)[UIApplication sharedApplication].delegate).testPlace;
    testPhoto = ((APIsAppDelegate *)[UIApplication sharedApplication].delegate).testPhoto;
    testEvent = ((APIsAppDelegate *)[UIApplication sharedApplication].delegate).testEvent;
    testMessage = ((APIsAppDelegate *)[UIApplication sharedApplication].delegate).testMessage;
    testPost = ((APIsAppDelegate *)[UIApplication sharedApplication].delegate).testPost;
    if (!testPlace) {
        // remove test place from last run
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *test_place_id = [prefs stringForKey:@"test_place_id"];
        if (test_place_id) {
            NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys:test_place_id, @"place_id", nil];
            CCRequest *request = [[CCRequest alloc] initWithDelegate:self httpMethod:@"DELETE" baseUrl:@"places/delete.json" paramDict:paramDict];
            [request startAsynchronous];
            [prefs removeObjectForKey:@"test_place_id"];
        }
    }

    [self.tableView reloadData];
}

-(void)startLogout
{
    if (testPlace) {
        NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testPlace.objectId, @"place_id", nil];

        CCRequest *request = [[CCRequest alloc] initWithDelegate:self httpMethod:@"DELETE" baseUrl:@"places/delete.json" paramDict:paramDict];

        [request startAsynchronous];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs removeObjectForKey:@"test_place_id"];
    }
    CCRequest *request = [[CCRequest alloc] initWithDelegate:self httpMethod:@"GET" baseUrl:@"users/logout.json" paramDict:nil];

    [request startAsynchronous];
}

-(void)deleteAccount
{
    if (testPlace) {
        NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testPlace.objectId, @"place_id", nil];
        CCRequest *request = [[CCRequest alloc] initWithDelegate:self httpMethod:@"DELETE" baseUrl:@"places/delete.json" paramDict:paramDict];

        [request startAsynchronous];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs removeObjectForKey:@"test_place_id"];
    }
    CCRequest *request = [[CCRequest alloc] initWithDelegate:self httpMethod:@"DELETE" baseUrl:@"users/delete.json" paramDict:nil];

    [request startAsynchronous];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    return NUM_SECTIONS;
}

// Some actions requires a test place to be creatd first
-(Boolean)checkTestPlace
{
    if (!testPlace) {
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"Missing test place" 
                              message:@"Please goto Places section and create a test place first!"
                              delegate:self 
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return NO;
    }
    return YES;
    
}

// Some actions requires a test place to be creatd first
-(Boolean)checkTestPhoto
{
    Boolean ret = YES;
    if (ret && !testPhoto) {
        ret = NO;
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"Missing test photo" 
                              message:@"Please goto Photos section and upload a photo to user first!"
                              delegate:self 
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    return ret;
    
}

// Some actions requires a test place to be creatd first
-(Boolean)checkTestEvent
{
    Boolean ret = YES;
    if (ret && !testEvent) {
        ret = NO;
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"Missing test event" 
                              message:@"Please goto Events section and create a test event first!"
                              delegate:self 
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    return ret;
    
}

// Some actions requires a test place to be creatd first
-(Boolean)checkTestMessage
{
    Boolean ret = YES;
    if (ret && !testMessage) {
        ret = NO;
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"Missing test message" 
                              message:@"Please goto Messages section and send a test message first!"
                              delegate:self 
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    return ret;
    
}

// Some actions requires a test place to be creatd first
-(Boolean)checkTestPost
{
    Boolean ret = YES;
    if (ret && !testPost) {
        ret = NO;
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"Missing test post" 
                              message:@"Please goto Post section and submit a test post first!"
                              delegate:self 
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    return ret;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case USERS: 
            return 4;
        case PLACES:
            return 4;
        case CHECKINS:
            return 3;
        case STATUSES:
            return 2;
        case MESSAGES:
            return 8;
        case PHOTOS:
            return 6;
        case KEY_VALUES:
            return 4;
        case EVENTS:
            return 4;
        case CLIENTS:
            return 1;
        case POSTS:
            return 3;
        default:
            break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case USERS:
            return @"Users";
        case PLACES:
            return @"Places";
        case CHECKINS:
            return @"Checkins";
        case STATUSES:
            return @"Statuses";
        case MESSAGES:
            return @"Messages";
        case PHOTOS:
            return @"Photoes";
        case KEY_VALUES:
            return @"Key/Value Pairs";
        case EVENTS:
            return @"Events";
        case CLIENTS:
            return @"Clients";
        case POSTS:
            return @"Posts";
        default:
            break;
    }
    return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    switch (indexPath.section) {
        case USERS:
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Show user profile";
            } else if (indexPath.row == 1) {
                cell.textLabel.text = @"Show current user profile";
            } else if (indexPath.row == 2) {
                cell.textLabel.text = @"Update current user profile";
            } else if (indexPath.row == 3) {
                cell.textLabel.text = @"Search users";
            } 
            break;
        case PLACES:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Search places";
                    break;
                case 1:
                    cell.textLabel.text = @"Show the test place";
                    break;
                case 2:
                    if (testPlace) {
                        cell.textLabel.text = @"Delete the test place";
                    } else {
                        cell.textLabel.text = @"Create a test place";
                    }
                    break;
                case 3:
                default:
                    cell.textLabel.text = @"Update the test place";
                    break;
                
            }
            break;
        case CHECKINS:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Check into a place";
                    break;
                case 1: 
                    cell.textLabel.text = @"List checkins of a place";
                    break;
                case 2:
                default:
                    cell.textLabel.text = @"List a user's checkins";
                    break;
                    break;
            }
            break;
        case STATUSES:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Create Status";
                    break;
                case 1:
                default:
                    cell.textLabel.text = @"Show a user's statuses";
                    break;
            }
            break;
        case MESSAGES:
            switch (indexPath.row) {
                case 0:
                    if (!testMessage) {
                        cell.textLabel.text = @"Send a test message";
                    } else {
                        cell.textLabel.text = @"Delete the test message";
                    }
                    break;
                case 1:
                    cell.textLabel.text = @"Reply to a message";
                    break;
                case 2:
                    cell.textLabel.text = @"Show a message";
                    break;
                case 3:
                    cell.textLabel.text = @"Show Inbox Messages";
                    break;
                case 4:
                    cell.textLabel.text = @"Show Sent Messages";
                    break;
                case 5:
                    cell.textLabel.text = @"Show Message Threads";
                    break;
                case 6:
                    cell.textLabel.text = @"Show Messages in a Thread";
                    break;
                case 7:
                default:
                    cell.textLabel.text = @"Delete a message thread";
                    break;
            }
            
            break;
        case PHOTOS:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Upload a place photo";
                    break;
                case 1:
                    cell.textLabel.text = @"Show photos of a place";
                    break;
                case 2:
                    cell.textLabel.text = @"upload a user photo";
                    break;
                case 3:
                    cell.textLabel.text = @"Show a photo";
                    break;
                case 4:
                    cell.textLabel.text = @"Show photos of a user";
                    break;
                case 5:
                default:
                    cell.textLabel.text = @"Delete a photo";
                    break;
            }
            break;
        case KEY_VALUES:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Set Value for Key('Test')";
                    break;
                case 1:
                    cell.textLabel.text = @"Get Value of key('Test')";
                    break;
                case 2:
                    cell.textLabel.text = @"Append value of key('Test')";
                    break;
                case 3:
                default:
                    cell.textLabel.text = @"Delete a key/value('Test')";
                    break;
                }
                
            break;
        case EVENTS:
            switch (indexPath.row) {
                case 0:
                    if (!testEvent) {
                        cell.textLabel.text = @"Create a test event";
                    } else {
                        cell.textLabel.text = @"Delete the test event";
                    }
                    break;
                case 1:
                    cell.textLabel.text = @"Get an event";
                    break;
                case 2:
                    cell.textLabel.text = @"Update an event";
                    break;
                case 3:
                default:
                    cell.textLabel.text = @"Search events";
                    break;
            }
            
            break;
        case CLIENTS:
            cell.textLabel.text = @"Geolocate a client";
            break;
        case POSTS:
            switch (indexPath.row) {
                case 0:
                    if (!testPost) {
                        cell.textLabel.text = @"Create a test post";
                    } else {
                        cell.textLabel.text = @"Delete the test post";
                    }
                    break;
                case 1:
                    
                    cell.textLabel.text = @"Search user's posts";
                    break;
                case 2:
                    cell.textLabel.text = @"Add a review to the post";
                    
                default:
                    break;
            }
            break;
        default:
            break;
    }
    // Configure the cell.
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
	*/

    AlertPrompt *prompt;
    APIViewController *controller = [[APIViewController alloc] initWithNibName:@"APIViewController" bundle:nil];  
    CheckinViewController *checkinController;
    PhotoAddViewController *photoController;
    UIAlertView *alert;
    CCRequest *request = nil;
    NSDictionary *paramDict = nil;
    CCUser *currentUser = [[Cocoafish defaultCocoafish] getCurrentUser];
    UIImage *photoAttachment = [UIImage imageNamed:@"sample.png"];
    switch (indexPath.section) {
        case USERS:
            if (indexPath.row == 0) {
                // show user profile
                paramDict = [NSDictionary dictionaryWithObjectsAndKeys:currentUser.objectId, @"user_id",nil];

                request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"users/show.json" paramDict:paramDict] autorelease];
            } else if (indexPath.row == 1) {
                // show current user profile
                request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"users/show/me.json" paramDict:nil] autorelease];

            } else if (indexPath.row == 2) {
                // update user
                prompt = [AlertPrompt alloc];
                prompt = [prompt initWithTitle:@"Update User Email" message:@"Please enter your email" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" defaultInput:[[Cocoafish defaultCocoafish] getCurrentUser].email];
                lastIndexPath = [indexPath copy];
                [prompt show];
                [prompt release];
                [controller release];
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                return;

            } else if (indexPath.row == 3) {
                paramDict = [NSDictionary dictionaryWithObjectsAndKeys:currentUser.firstName, @"q", nil];
                request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"users/search.json" paramDict:nil] autorelease];

            } else {
                if ([[Cocoafish defaultCocoafish] getFacebook] == nil) {
                    // check if a facebook id is provided
                    alert = [[UIAlertView alloc] 
                                          initWithTitle:@"Error" 
                                          message:@"Please initialize Cocoafish with a valid facebook id first!"
                                          delegate:self 
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
                    [alert show];
                    [alert release];
                } else {
                    // unlink rom facebook
                    NSError *error;
                    [[Cocoafish defaultCocoafish] unlinkFromFacebook:&error];
                    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];

                return;
            }
            break;
        case PLACES:
            switch (indexPath.row) {
                case 0:
                    // show all places
                    paramDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:37.743961], @"latitude", [NSNumber numberWithDouble:-122.42202], @"longitude", [NSNumber numberWithDouble:5.0], @"distance", nil];
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"places/search.json" paramDict:nil] autorelease];

                    break;
                case 1:
                    // show the test place
                    if (![self checkTestPlace]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testPlace.objectId, @"place_id", nil];

                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"places/show.json" paramDict:paramDict] autorelease];

                    break;
                case 2:
                    if (testPlace) {
                        // delete the test place
                        paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testPlace.objectId, @"place_id", nil];

                        request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"DELETE" baseUrl:@"places/delete.json" paramDict:paramDict] autorelease];

                        
                    } else {
                        // create a test place
                        
                        // show all places
                        paramDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Cocoafish", @"name", @"58 South Park Ave.", @"address", @"San Francisco", @"city", @"California", @"state", @"94107-1807", @"postal_code", @"United States", @"country", @"http://cocoafish.com", @"website", @"cocoafish", @"twitter", [NSNumber numberWithDouble:37.743961], @"latitude", [NSNumber numberWithDouble:-122.42202], @"longitude", nil];
                       
                        request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"POST" baseUrl:@"places/create.json" paramDict:paramDict] autorelease];
                        [request addPhotoUIImage:photoAttachment paramDict:nil];

                        
                    }
                    break;
                case 3:
                default:
                    // update the test place
                    if (![self checkTestPlace]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    prompt = [AlertPrompt alloc];
                    prompt = [prompt initWithTitle:@"Change Place Name" message:@"Please enter new place name" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" defaultInput:testPlace.name];
                    lastIndexPath = [indexPath copy];
                    [prompt show];
                    [prompt release];
                    [controller release];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                    return;
                    break;
                    
            }
            break;
        case CHECKINS:
            switch (indexPath.row) {
                case 0:
                    // checkins require a test place to be created first
                    if (![self checkTestPlace]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    // check in to the test place
                    checkinController = [[CheckinViewController alloc] initWithNibName:@"CheckinViewController" bundle:nil];
                    
                    [self.navigationController pushViewController:checkinController  animated:YES];
                    [checkinController release];
                    return;
                    break;
                case 1: 
                    if (![self checkTestPlace]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    // get checkins of a place
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"checkins/search.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:testPlace.objectId, @"place_id", nil]] autorelease];

                    break;
                case 2:
                default:
                    // show a user's checkins
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"checkins/search.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:currentUser.objectId, @"user_id", nil]] autorelease];

                
                    break;
            }
            break;
        case STATUSES:
            switch (indexPath.row) {
                case 0:
                    // create a new user status
                    prompt = [AlertPrompt alloc];
                    prompt = [prompt initWithTitle:@"New Status" message:@"Please enter your status" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" defaultInput:@"Feeling good!"];
                    lastIndexPath = [indexPath copy];
                    [prompt show];
                    [prompt release];
                    [controller release];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                    
                    return;

                    break;
                case 1:
                default:
                    // get a user's statuses
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"statuses/search.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:[[Cocoafish defaultCocoafish] getCurrentUser].objectId, @"user_id", [NSDate distantPast], @"start_time", nil]] autorelease];

                    
                    break;
            }
            break;
        case PHOTOS:
            
            switch (indexPath.row) {
                case 0:
                    if (![self checkTestPlace]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    // Add a photo to a place
                    photoController = [[PhotoAddViewController alloc] initWithNibName:@"PhotoAddViewController" bundle:nil];
                    photoController.object = testPlace;
                    [self.navigationController pushViewController:photoController  animated:YES];
                    [photoController release];
                    return;
                    break;
                case 1:
                    if (![self checkTestPlace]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    // get Photos of a place
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"photos/search.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:testPlace.objectId, @"place_id", nil]] autorelease];

                    break;
                case 2:
                    // add a photo to a user
                    photoController = [[PhotoAddViewController alloc] initWithNibName:@"PhotoAddViewController" bundle:nil];
                    photoController.object = [[Cocoafish defaultCocoafish] getCurrentUser];
                    [self.navigationController pushViewController:photoController  animated:YES];
                    [photoController release];
                    return;
                    break;
                case 3:
                    // show a test photo
                    if (![self checkTestPhoto]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testPhoto.objectId, @"photo_id", nil];

                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"photos/show.json"  paramDict:paramDict] autorelease];

                    
                    break;
                case 4:
                    // show photos of a user
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"photos/search.json"  paramDict:[NSDictionary dictionaryWithObjectsAndKeys:currentUser.objectId, @"user_id", nil]] autorelease];

                    break;
                case 5:
                default:
                    // delete a photo
                    if (![self checkTestPhoto]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testPhoto.objectId, @"photo_id", nil];

                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"DELETE" baseUrl:@"photos/delete.json" paramDict:paramDict] autorelease];

                    break;
            }
            break;
        case KEY_VALUES:
            switch (indexPath.row) {
                case 0:
                    prompt = [AlertPrompt alloc];
                    prompt = [prompt initWithTitle:@"Enter a value for key 'Test'" message:@"Please enter a Value for Key 'Test'" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" defaultInput:@"Awesome!"];
                    lastIndexPath = [indexPath copy];
                    [prompt show];
                    [prompt release];
                    [controller release];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                
                    return;
                    break;
                case 1:
                    // get keyvalue
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"keyvalues/get.json"  paramDict:[NSDictionary dictionaryWithObjectsAndKeys:@"Test", @"name", nil]] autorelease];

                    break;
                case 2:
                    // append keyvalue
                    prompt = [AlertPrompt alloc];
                    prompt = [prompt initWithTitle:@"Enter a value to append for key 'Test'" message:@"Please enter a Value to append for Key 'Test'" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" defaultInput:@"More awesomeness!"];
                    lastIndexPath = [indexPath copy];
                    [prompt show];
                    [prompt release];
                    [controller release];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                    
                    return;
                    break;
                case 3:
                default:
                    // delete keyvalue
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"keyvalues/delete.json"  paramDict:[NSDictionary dictionaryWithObjectsAndKeys:@"Test", @"name", nil]] autorelease];

                    break;
            }
            break;
        case MESSAGES:
            switch (indexPath.row) {
                case 0:
                    // create a mesage
                    if (!testMessage) {
                        prompt = [AlertPrompt alloc];
                        prompt = [prompt initWithTitle:@"Enter a subject for Message 'Test'" message:@"Please enter a Subject for Message 'Test'" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" defaultInput:@"Hello from Cocoafish"];
                        lastIndexPath = [indexPath copy];
                        [prompt show];
                        [prompt release];
                        [controller release];
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        
                        return;

                    } else {
                        paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testMessage.objectId, @"message_id", nil];

                        request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"DELETE" baseUrl:@"messages/delete.json" paramDict:paramDict] autorelease];

                    }
                    break;
                case 1:
                    // reply a message
                    if (![self checkTestMessage]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    prompt = [AlertPrompt alloc];
                    prompt = [prompt initWithTitle:@"Enter a reply for message" message:@"Please enter a reply message" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" defaultInput:@"I have received it!"];
                    lastIndexPath = [indexPath copy];
                    [prompt show];
                    [prompt release];
                    [controller release];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                    
                    return;
                    break;
                case 2:
                    // show a message
                    if (![self checkTestMessage]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testMessage.objectId, @"message_id", nil];

                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"messages/show.json" paramDict:paramDict] autorelease];

                    break;
                case 3:
                    // show inbox messages
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"messages/show/inbox.json" paramDict:nil] autorelease];

                    break;
                case 4:
                    // show sent messages
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"messages/show/sent.json" paramDict:nil] autorelease];


                    break;
                case 5:
                    // show  message threads
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"messages/show/threads.json" paramDict:nil] autorelease];

                    break;
                case 6:
                    // show message in a message thread
                    if (![self checkTestMessage]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testMessage.threadId, @"thread_id", nil];

                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"messages/show/thread.json" paramDict:paramDict] autorelease];

                    
                    break;
                case 7:
                    // delete a message threads
                    if (![self checkTestMessage]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testMessage.threadId, @"thread_id", nil];

                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"DELETE" baseUrl:@"messages/delete/thread.json" paramDict:paramDict] autorelease];

                    break;
            }
            
            break;
        case EVENTS:
            switch (indexPath.row) {
                case 0:
                    if (!testEvent) {
                        if (![self checkTestPlace]) {
                            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                            return;
                        }
                        paramDict =[NSDictionary dictionaryWithObjectsAndKeys:@"Cocoafish Happy Hour", @"name", @"Bring your own drink", @"details", testPlace.objectId, @"place_id", [NSDate date], @"start_time", [NSDate distantFuture], @"end_time", nil];
                        request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"POST" baseUrl:@"events/create.json" paramDict:paramDict] autorelease];


                    } else {
                        paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testEvent.objectId, @"event_id", nil];

                        request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"DELETE" baseUrl:@"events/delete.json" paramDict:paramDict] autorelease];
                    }
                    break;
                case 1:
                    if (![self checkTestEvent]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testEvent.objectId, @"event_id", nil];

                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"events/show.json" paramDict:paramDict] autorelease];

                    break;
                case 2:
                    if (![self checkTestEvent]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    prompt = [AlertPrompt alloc];
                    prompt = [prompt initWithTitle:@"Enter a a new event name" message:@"Please enter a new Event name" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" defaultInput:testEvent.name];
                    lastIndexPath = [indexPath copy];
                    [prompt show];
                    [prompt release];
                    [controller release];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                    
                    return;
                    break;
                case 3:
                default:
                    if (![self checkTestPlace]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"events/search.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:testPlace.objectId, @"place_id", nil]] autorelease];

                    
                    break;
            }
            
            break;
        case CLIENTS:
            request = [[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"clients/geolocate.json" paramDict:nil];
            break;
        case POSTS:
            switch (indexPath.row) {
                case 0:
                    if (!testPost) {
                        request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"POST" baseUrl:@"posts/create.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:@"Good day", @"content", @"This is a title", @"title", nil]] autorelease];
                    } else {
                        // delete the post
                        request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"DELETE" baseUrl:@"posts/delete.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:testPost.objectId, @"post_id", nil]] autorelease];
                    }
                    break;
                case 1:
                    request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"GET" baseUrl:@"posts/search.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:currentUser.objectId, @"user_id", nil]] autorelease];
                    break;
                case 2:
                    if (![self checkTestPost]) {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                        return;
                    }
                    prompt = [AlertPrompt alloc];
                    prompt = [prompt initWithTitle:@"Enter a a rating" message:@"Please enter a rating for the post" delegate:self cancelButtonTitle:@"Cancel" okButtonTitle:@"Okay" defaultInput:@"10"];
                    lastIndexPath = [indexPath copy];
                    [prompt show];
                    [prompt release];
                    [controller release];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];

                    return;
                default:
                    break;
            }
                
            break;
        default:
            break;
    }
    [request startAsynchronous];
    
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc
{
    [lastIndexPath release];
    [super dealloc];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex])
    {
        NSString *entered = [(AlertPrompt *)alertView enteredText];
        APIViewController *controller = [[APIViewController alloc] initWithNibName:@"APIViewController" bundle:nil];  
        CCRequest *request = nil;
        UIImage *photoAttachment = [UIImage imageNamed:@"sample.png"];
        NSDictionary *paramDict = nil;

        if (lastIndexPath.section == USERS) {
            request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"PUT" baseUrl:@"users/update.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:entered, @"email", nil]] autorelease];

        } else if (lastIndexPath.section == STATUSES) {
            request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"POST" baseUrl:@"statuses/create.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:entered, @"message", nil]] autorelease];
            [request addPhotoUIImage:photoAttachment paramDict:nil];

        } else if (lastIndexPath.section == KEY_VALUES){
            if (lastIndexPath.row == 0) {
                // set key value
                request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"PUT" baseUrl:@"keyvalues/set.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:entered, @"value", @"Test", @"name", nil]] autorelease];
               // request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"PUT" baseUrl:@"keyvalues/set.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"1",@"2",nil], @"value", @"Test", @"name", nil]] autorelease];


            } else {
                // append key value
                request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"PUT" baseUrl:@"keyvalues/append.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:entered, @"value", @"Test", @"name", nil]] autorelease];

                
            }
        } else if (lastIndexPath.section == EVENTS) {
            paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testEvent.objectId, @"event_id", entered, @"name", nil];
            request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"PUT" baseUrl:@"events/update.json" paramDict:paramDict] autorelease];
            [request addPhotoUIImage:photoAttachment paramDict:nil];

        } else if (lastIndexPath.section == MESSAGES) {
            if (lastIndexPath.row == 0) {
                request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"POST" baseUrl:@"messages/create.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:entered, @"subject", @"Thanks for using Cocoafish", @"body", [NSArray arrayWithObject:[[Cocoafish defaultCocoafish] getCurrentUser].objectId], @"to_ids", nil]] autorelease];

            } else {
                paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testMessage.objectId, @"message_id", entered, @"body", nil];
                request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"POST" baseUrl:@"messages/reply.json" paramDict:paramDict] autorelease];


            }
        } else  if (lastIndexPath.section == POSTS) {
            request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"POST" baseUrl:@"reviews/create.json" paramDict:[NSDictionary dictionaryWithObjectsAndKeys:testPost.objectId, @"post_id", entered, @"rating", @"love it", @"content", nil]] autorelease];
        } else {
            paramDict = [NSDictionary dictionaryWithObjectsAndKeys:testPlace.objectId, @"place_id", entered, @"name", nil];

            request = [[[CCRequest alloc] initWithDelegate:controller httpMethod:@"PUT" baseUrl:@"places/update.json" paramDict:paramDict] autorelease];
            [request addPhotoUIImage:photoAttachment paramDict:nil];


        }
        [request startAsynchronous];
        [self.navigationController pushViewController:controller animated:YES];
        [controller release];
        [lastIndexPath release];
        lastIndexPath = nil;
    } 
}

// successful
-(void)ccrequest:(CCRequest *)request didSucceed:(CCResponse *)response
{	
    if ([response.meta.methodName isEqualToString:@"logoutUser"] ||
        [response.meta.methodName isEqualToString:@"deleteUser"]) {
        ((APIsAppDelegate *)[UIApplication sharedApplication].delegate).testPlace = nil;
        ((APIsAppDelegate *)[UIApplication sharedApplication].delegate).testEvent = nil;
        ((APIsAppDelegate *)[UIApplication sharedApplication].delegate).testPhoto = nil;
        ((APIsAppDelegate *)[UIApplication sharedApplication].delegate).testMessage = nil;
        ((APIsAppDelegate *)[UIApplication sharedApplication].delegate).testPost = nil;
        testPlace = nil;
        testEvent = nil;
        testPhoto = nil;
        testMessage = nil;
        testPost = nil;
    
        // show login window
        LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        [self.navigationController pushViewController:loginViewController animated:NO];
        [loginViewController release];
    } 
}

#pragma -
#pragma mark CCFBSessionDelegate methods
-(void)fbDidLogin
{
	NSLog(@"fbDidLogin");

    [self.tableView reloadData];
    
}

-(void)fbDidNotLogin:(BOOL)cancelled error:(NSError *)error
{
	if (error == nil) {
		// user failed to login to facebook or cancelled the login
		return;
	}
	NSString *msg = [NSString stringWithFormat:@"%@",[error localizedDescription]];
	UIAlertView *alert = [[UIAlertView alloc] 
						  initWithTitle:@"Failed to link with Facebook" 
						  message:msg
						  delegate:self 
						  cancelButtonTitle:@"Ok"
						  otherButtonTitles:nil];
	[alert show];
	[alert release];
}

@end
