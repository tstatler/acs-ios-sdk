//
//  MainViewController.m
//  Demo
//
//  Created by Wei Kong on 10/7/10.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "MainViewController.h"
#import "Cocoafish.h"

@implementation MainViewController
@synthesize viewSwitchButton, mapViewController, listViewController;
@synthesize processingRequest;

/* // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// init the view controllers
	if (mapViewController == nil) {
		mapViewController = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:nil];
	}
	[self.view addSubview:mapViewController.view];

	if (listViewController == nil) {
		listViewController = [[ListViewController alloc] initWithNibName:@"ListViewController" bundle:nil];
	}
	
    CCRequest *request = [[[CCRequest alloc] initWithDelegate:self httpMethod:@"GET" baseUrl:@"places/search.json" paramDict:nil] autorelease];
    [request startAsynchronous];
	
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[processingRequest release];

    [super dealloc];
}

-(IBAction)getPlaces 
{
    CCRequest *request = [[[CCRequest alloc] initWithDelegate:self httpMethod:@"GET" baseUrl:@"places/search.json" paramDict:nil] autorelease];
    [request startAsynchronous];
}

-(IBAction)switchView {
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.25];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	//[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:del.rootNavigator.view cache:YES];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
	
	if (listViewController.view.superview == nil) {
		
		[listViewController viewWillAppear:YES];
		[mapViewController viewWillDisappear:YES];
		//	self.navigationItem.title = @"Search";
		[mapViewController.view removeFromSuperview];
		
		[self.view addSubview:listViewController.view];
		[viewSwitchButton setTitle:@"Map View"];
		
		[listViewController viewDidAppear:YES];
		[mapViewController viewDidDisappear:YES];
	} else if (mapViewController.view.superview == nil) {
		[mapViewController viewWillAppear:YES];
		[listViewController viewWillDisappear:YES];
		[listViewController.view removeFromSuperview];
		
		[self.view addSubview:mapViewController.view];
		[viewSwitchButton setTitle:@"List View"];
		[mapViewController viewDidAppear:YES];
		[listViewController viewDidDisappear:YES];

	}
	
	[UIView commitAnimations];
	
}

#pragma mark -
#pragma mark CCRequest delegate methods
-(void)ccrequest:(CCRequest *)request didSucceed:(CCResponse *)response
{
    NSArray *places = [response getObjectsOfType:[CCPlace class]];
     [mapViewController showPlaces:places];
    [listViewController showPlaces:places];
}

-(void)ccrequest:(CCRequest *)request didFailWithError:(NSError *)error 
{
	
}

@end

