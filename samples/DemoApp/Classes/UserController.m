//
//  UserController.m
//  Demo
//
//  Created by Wei Kong on 10/15/10.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "UserController.h"
#import "LoginViewController.h"
#import "CocoafishLibrary.h"

@implementation UserController

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownloaded:) name:@"DownloadFinished" object:[Cocoafish defaultCocoafish]];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)handleDownloaded:(NSNotification *)notification
{
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	CCUser *currentUser = [[Cocoafish defaultCocoafish] getCurrentUser];
	if (!currentUser) {
		// show login window
		LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
		[self.navigationController pushViewController:loginViewController animated:NO];
		[loginViewController release];
		return;
	} else {
		UIBarButtonItem *button;

		// create the logout button	
		button = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(startLogout)];
		self.navigationItem.rightBarButtonItem = button;
		[button release];
		
	/*	if ([currentUser.facebookAccessToken length] > 0) {
			// create the link with facebook button
			button = [[UIBarButtonItem alloc] initWithTitle:@"Unlink Facebook" style:UIBarButtonItemStylePlain target:self action:@selector(unlinkFromFacebook)];
		} else {
			button = [[UIBarButtonItem alloc] initWithTitle:@"Link Facebook" style:UIBarButtonItemStylePlain target:self action:@selector(linkWithFacebook)];
		}
		self.navigationItem.leftBarButtonItem = button;
		[button release];*/
		
		self.navigationItem.title = [[[Cocoafish defaultCocoafish] getCurrentUser] firstName];
		
	}
	
	[self getUserCheckins];

	
	[self.tableView reloadData];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark -
#pragma mark getUserCheckins

-(void)getUserCheckins
{
    NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys:[[Cocoafish defaultCocoafish] getCurrentUser].objectId, @"user_id", nil];
	
    CCRequest *request = [[[CCRequest alloc] initWithDelegate:self httpMethod:@"GET" baseUrl:@"checkins/search.json" paramDict:paramDict] autorelease];

    [request startAsynchronous];
}


#pragma mark -
#pragma mark logout

// start the login process
- (void)startLogout
{	
    CCRequest *request = [[[CCRequest alloc] initWithDelegate:self httpMethod:@"GET" baseUrl:@"users/logout.json" paramDict:nil] autorelease];

    [request startAsynchronous];
}

// unlink from facebook
-(void)unlinkFromFacebook
{
	NSError *error;
	[[Cocoafish defaultCocoafish] unlinkFromFacebook:&error];
	if (error == nil) {
		UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Link With Facebook" style:UIBarButtonItemStylePlain target:self action:@selector(linkWithFacebook)];
		self.navigationItem.leftBarButtonItem = button;
		[button release];
	}
}

// link with facebook account
- (void)linkWithFacebook
{	
    if ([[Cocoafish defaultCocoafish] getFacebook] == nil) {
        
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:@"Error" 
                              message:@"Please initialize Cocoafish with a valid facebook id first!"
                              delegate:self 
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
	[[Cocoafish defaultCocoafish] facebookAuth:[NSArray arrayWithObjects:@"publish_stream", @"email", @"read_friendlists", @"offline_access", @"user_photos", nil] delegate:self];
}

#pragma mark -
#pragma mark CCRequest delegate methods
// successful logout
-(void)ccrequest:(CCRequest *)request didSucceed:(CCResponse *)response
{	
    if ([response.meta.methodName isEqualToString:@"logoutUser"]) {
        // show login window
        LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        [self.navigationController pushViewController:loginViewController animated:NO];
        [userCheckins release];
        userCheckins = nil;
        [loginViewController release];
    } else if ([response.meta.methodName isEqualToString:@"searchCheckins"]) {
        @synchronized (self) {
            [userCheckins release];
            userCheckins = [[response getObjectsOfType:[CCCheckin class]] retain];
            [self.tableView reloadData];
        }
    }
	
}

-(void)ccrequest:(CCRequest *)request didFailWithError:(NSError *)error
{

	NSString *msg = [NSString stringWithFormat:@"%@.",[error localizedDescription]];
	UIAlertView *alert = [[UIAlertView alloc] 
						  initWithTitle:@"Error" 
						  message:msg
						  delegate:self 
						  cancelButtonTitle:@"Ok"
						  otherButtonTitles:nil];
	[alert show];
	[alert release];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	return [userCheckins count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // Configure the cell...
	CCCheckin *checkin = [userCheckins objectAtIndex:indexPath.row];
	cell.imageView.image = nil;
    cell.imageView.image = [checkin.photo getImageForPhotoSize:@"thumb_100"];
	
    cell.textLabel.text = checkin.message;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", [[checkin place] name], timeElapsedFrom([checkin createdAt])];
	
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
	[userCheckins release];
    [super dealloc];
}


#pragma -
#pragma mark CCFBSessionDelegate methods
-(void)fbDidLogin
{
	NSLog(@"fbDidLogin");
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Unlink Facebook" style:UIBarButtonItemStylePlain target:self action:@selector(unlinkFromFacebook)];
	self.navigationItem.leftBarButtonItem = button;
	[button release];

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


