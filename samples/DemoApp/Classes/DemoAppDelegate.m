//
//  DemoAppDelegate.m
//  Demo
//
//  Created by Wei Kong on 10/7/10.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "DemoAppDelegate.h"
#import "MainViewController.h"
#import "Cocoafish.h"

// Your cocoafish oauth token/secret must be set before running this demo
//#define COCOAFISH_OAUTH_CONSUMER_KEY @"your consumer key here"
//#define COCOAFISH_OAUTH_CONSUMER_SECRET @"your consumer secret here"
#if !defined(COCOAFISH_OAUTH_CONSUMER_KEY) || !defined(COCOAFISH_OAUTH_CONSUMER_SECRET)
    #error : Please uncomment above lines and set your oauth key and secret
#endif

// If you want to add facebook support, please set the facebook app id here and pass it to initializeWithOauthConsumerKey.
static NSString * const facebookAppId = nil;


@implementation DemoAppDelegate

@synthesize window;
@synthesize tabBarController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    
	// Initialize Cocoafish
    [Cocoafish initializeWithOauthConsumerKey:COCOAFISH_OAUTH_CONSUMER_KEY consumerSecret:COCOAFISH_OAUTH_CONSUMER_SECRET customAppIds:nil];
   
    // Initialize Cocoafish with facebook App Id if you set one
 /*   [Cocoafish initializeWithOauthConsumerKey:COCOAFISH_OAUTH_CONSUMER_KEY consumerSecret:COCOAFISH_OAUTH_CONSUMER_SECRET customAppIds:[NSDictionary dictionaryWithObject:facebookAppId forKey:@"Facebook"]]; */
    
	 // Add the tab bar controller's view to the window and display.
    [window addSubview:tabBarController.view];
    [window makeKeyAndVisible];

    return YES;
}

// 4.2+
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	return [[[Cocoafish defaultCocoafish] getFacebook] handleOpenURL:url];
}

// pre 4.2
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	return [[[Cocoafish defaultCocoafish] getFacebook] handleOpenURL:url];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark UITabBarControllerDelegate methods

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

