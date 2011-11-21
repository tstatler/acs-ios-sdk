//
//  CocoafishLibrary.m
//  Cocoafish-ios-demo
//
//  Created by Michael Goff on 7/9/08.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CocoafishLibrary.h"

// check iphone
BOOL isIphone() {
	NSString *deviceType = [UIDevice currentDevice].model;
	if ([deviceType isEqualToString:@"iPhone"]) {
		return YES;
	} else {
		return NO;
	}
}

// check ipad
BOOL isIPad()
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
	return NO;
#endif
}
// get the float iOS version such as 4.1
float osVersion() {
	UIDevice *myCurrentDevice = [UIDevice currentDevice];
	return [[myCurrentDevice systemVersion] floatValue];
}

NSString* timeElapsedFrom(NSDate *startDate)
{
	NSDate *currentDate = [NSDate date];
	
	NSTimeInterval ti = [currentDate timeIntervalSinceDate:startDate];
	
	int diff;
	NSString *unit;
	NSString *plural;
	if (ti < 60) {
		return NSLocalizedString(@"less than a minute ago", nil);
	} else if (ti < 3600) {
		diff = round(ti / 60);
		unit = NSLocalizedString(@"minute", nil);
	} else if (ti < 86400) {
		diff = round(ti / 60 / 60);
		unit = NSLocalizedString(@"hour", nil);
	} else if (ti < 2629743) {
		diff = round(ti / 60 / 60 / 24);
		unit = NSLocalizedString(@"day", nil);
	} else if (ti < 31556916) {
		diff = round(ti / 30 / 60 / 60 / 24);
		unit = NSLocalizedString(@"month", nil);
	} else {
		diff = round(ti / 12 / 30 / 60 / 60 / 24);
		unit = NSLocalizedString(@"year", nil);
	}   
	if (diff > 1) {
		plural = NSLocalizedString(@"s", nil);
	} else {
		plural = @"";
	}
	NSString *ago = NSLocalizedString(@"ago", nil);
	return [NSString stringWithFormat:@"%d %@%@ %@", diff, unit, plural, ago];
}

BOOL validateEmail(NSString *candidate) {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    return [emailTest evaluateWithObject:candidate];
}
