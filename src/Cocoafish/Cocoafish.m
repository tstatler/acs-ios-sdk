//
//  Cocoafish.m
//  Cocoafish-ios-sdk
//
//  Created by Wei Kong on 1/3/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "Cocoafish.h"
#import "CCDownloadManager.h"

static Cocoafish *theDefaultCocoafish = nil;

@interface Cocoafish (PrivateMethods)
-(NSString *)getCookiePath;
-(void)saveUserSession;
-(void)restoreUserSession;
-(void) printCookieStorage;
//-(void)cleanupCacheDir;
-(id)initWithAppKey:(NSString *)appKey customAppIds:(NSDictionary *)customAppIds;
-(id)initWithOauthConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret customAppIds:(NSDictionary *)customAppIds;
-(void)initCommon:(NSDictionary *)customAppIds;
@end

@implementation Cocoafish
@synthesize _fbSessionDelegate;
@synthesize downloadManager = _downloadManager;
@synthesize cocoafishDir = _cocoafishDir;

-(id)initWithAppKey:(NSString *)appKey customAppIds:(NSDictionary *)customAppIds
{
	if (appKey == nil || [appKey length] == 0) {
		[NSException raise:@"Missing Cocoafish App Key" format:@"App Key is missing"];
	}
	if ((self = [super init])) {
		_appKey = [appKey copy];
		[self initCommon:customAppIds];
	}
	return self;
}


-(id)initWithOauthConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret customAppIds:(NSDictionary *)customAppIds
{
	if ([consumerKey length] == 0 || [consumerSecret length] == 0) {
		[NSException raise:@"Missing Cocoafish Oauth Consumer Key and/or Consumer Secret" format:@"Oauth info is missing"];
	}
	if ((self = [super init])) {
		_consumerKey = [consumerKey copy];
		_consumerSecret = [consumerSecret copy];
		[self initCommon:customAppIds];
	}
	return self;
}
	

-(void)initCommon:(NSDictionary *)customAppIds
{
    theDefaultCocoafish = self;

	// create Cocoafish dir if there is none
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
	NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
	_cocoafishDir = [[NSString alloc] initWithFormat:@"%@/CocoafishCache", documentsDirectory];
	//[self cleanupCacheDir];

	if (![[NSFileManager defaultManager] createDirectoryAtPath:_cocoafishDir withIntermediateDirectories:NO attributes:nil error:nil]) {
		NSLog(@"Failed to create %@, photo download will not work", _cocoafishDir);
	}
    
    _downloadManager = [[CCDownloadManager alloc] init];
	
	// initialize all the custom app Ids such as facebook
	if (customAppIds != nil) {
		NSString *customAppId = [customAppIds objectForKey:@"Facebook"];
		if (customAppId != nil) {
			_facebook = [[Facebook alloc] initWithAppId:customAppId];
			_facebookAppId = [customAppId copy];
			NSLog(@"Cocoafish: initialized facebook with app Id %@", customAppId);
		}
	}
	
	// restore currentUser info if there is any
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	_currentUser = [[[CCUser alloc] initWithId:[prefs stringForKey:@"cc_user_id"] first:[prefs stringForKey:@"cc_user_first_name"] last:[prefs stringForKey:@"cc_user_last_name"] email:[prefs stringForKey:@"cc_user_email"] username:[prefs stringForKey:@"cc_username"]] retain];
	if (_currentUser) {
		[self restoreUserSession];
        CCRequest *request = [Cocoafish restRequest:self httpMethod:@"GET" baseUrl:@"users/show/me.json" paramDict:nil attachment:nil];
        [request startAsynchronous];
	}
	
}

-(NSString *)getAppKey
{
	return _appKey;
}

-(NSString *)getOauthConsumerKey
{
	return _consumerKey;
}

-(NSString *)getOauthConsumerSecret
{
	return _consumerSecret;
}

-(CCUser *)getCurrentUser
{
	return _currentUser;
}

-(Facebook *)getFacebook
{
	return _facebook;
}

-(void)setCurrentUser:(CCUser *)user
{
	[_currentUser release];
	_currentUser = [user retain];
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	if (user) {
		[prefs setObject:user.objectId forKey:@"cc_user_id"];
		[prefs setObject:user.firstName forKey:@"cc_user_first_name"];
		[prefs setObject:user.lastName forKey:@"cc_user_last_name"];
		[prefs setObject:user.email forKey:@"cc_user_email"];
        [prefs setObject:user.username forKey:@"cc_username"];
	} else {
		[prefs removeObjectForKey:@"cc_user_id"];
		[prefs removeObjectForKey:@"cc_user_first_name"];
		[prefs removeObjectForKey:@"cc_user_last_name"];
		[prefs removeObjectForKey:@"cc_user_email"];
        [prefs removeObjectForKey:@"cc_username"];
		// logout from facebook too if applicable
		[_facebook logout:self];
	}
	[self saveUserSession];
	[prefs synchronize];

}

#pragma mark -
#pragma mark facebook related
// handle application openurl call, used for facebook callback
-(BOOL)handleOpenURL:(NSURL *)url
{
	return [_facebook handleOpenURL:url];
}

-(void)facebookAuth:(NSArray *)permissions delegate:(id<CCFBSessionDelegate>)delegate
{
	_fbSessionDelegate = delegate;
	// we will always ask for offline access permissions
	NSMutableArray *ccPermissions = [NSMutableArray arrayWithArray:permissions];
	BOOL found = NO;
	for (NSString *permission in ccPermissions) {
		if ([permission caseInsensitiveCompare:@"offline_access"] == NSOrderedSame) {
			found = YES;
			break;
		}
	}
	if (!found) {
		[ccPermissions insertObject:@"offline_access" atIndex:0];
	}
	[_facebook authorize:permissions delegate:self];
}

-(void)unlinkFromFacebook:(NSError **)error
{
    CCRequest *request = [Cocoafish restRequest:nil httpMethod:@"DELETE" baseUrl:@"social/facebook/unlink.json" paramDict:nil attachment:nil];
    CCResponse *response = [request startSynchronous];
    if (response && [response.meta.status isEqualToString:CC_STATUS_OK]) {
        NSArray *users = [response getObjectsOfType:[CCUser class]];
        if ([users count] == 1) {
            CCUser *user = [users objectAtIndex:0];
            [[Cocoafish defaultCocoafish] setCurrentUser:user];
        }
    }
}

/**
 * Called when the user has logged in successfully.
 */
- (void)fbDidLogin {
	
	// login with cocoafish
	NSError *error = nil;
	CCUser *user = nil;
    NSDictionary *paramDict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:_facebookAppId, _facebook.accessToken, nil] forKeys:[NSArray arrayWithObjects:@"facebook_app_id", @"access_token", nil]];
    CCRequest *request = nil;
	if ([[Cocoafish defaultCocoafish] getCurrentUser] != nil) {
		// This is for linking facebook with the existing user
        request = [Cocoafish restRequest:nil httpMethod:@"POST" baseUrl:@"social/facebook/link.json" paramDict:paramDict attachment:nil];

    } else {
        request = [Cocoafish restRequest:nil httpMethod:@"POST" baseUrl:@"social/facebook/login.json" paramDict:paramDict attachment:nil];
    }

    CCResponse *response = [request startSynchronous];
    if (response && [response.meta.status isEqualToString:CC_STATUS_OK]) {
        NSArray *users = [response getObjectsOfType:[CCUser class]];
        if ([users count] == 1) {
            user = [users objectAtIndex:0];
        }
    }
	if (user == nil) {
		// Failed to register with the cocoafish server, logout from facebook
		[_facebook logout:self];
		if (_fbSessionDelegate && [_fbSessionDelegate respondsToSelector:@selector(fbDidNotLogin:error:)]) {
			[_fbSessionDelegate fbDidNotLogin:NO error:error];
		}
	} else {
        [[Cocoafish defaultCocoafish] setCurrentUser:user];
		if (_fbSessionDelegate && [_fbSessionDelegate respondsToSelector:@selector(fbDidLogin)]) {
			[_fbSessionDelegate fbDidLogin];
		}
	}
	_fbSessionDelegate = nil;
}

/**
 * Called when the user canceled the authorization dialog.
 */
-(void)fbDidNotLogin:(BOOL)cancelled {
	if (_fbSessionDelegate && [_fbSessionDelegate respondsToSelector:@selector(fbDidNotLogin:error:)]) {
		[_fbSessionDelegate fbDidNotLogin:cancelled error:nil];
	}
	_fbSessionDelegate = nil;
}

-(void)fbDidLogout {
	// Logout has to go through cocoafish server
}

#pragma mark -
#pragma mark user Cookie
-(NSString *)getCookiePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *cookieDataPath = [[documentsDirectory stringByAppendingPathComponent:@"cookieData.txt"] copy];
	return cookieDataPath;
}

// Save all of our cookies including the user and
-(void)saveUserSession
{
	NSString *cookieDataPath = [self getCookiePath];
	
	// debug
	NSLog(@"Storing cookies into file %@", cookieDataPath);
	
	NSHTTPCookieStorage* sharedCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray* cookies = [sharedCookieStorage cookies];
	
	// Create an array of dictionary objects
	NSMutableArray *cookieList = [[NSMutableArray alloc] init];
	for (NSHTTPCookie *cookie in cookies) {
		NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
									cookie.domain, NSHTTPCookieDomain,
									cookie.path, NSHTTPCookiePath,  // IMPORTANT!
									cookie.name, NSHTTPCookieName,
									cookie.value, NSHTTPCookieValue,
									nil];
		
		// Add the resulting dictionary to the array
		[cookieList addObject:properties];
	}
	
	// archive the cookies
	[NSKeyedArchiver archiveRootObject:cookieList toFile:cookieDataPath];
	
	// release memory
	[cookieDataPath release];
	[cookieList release];
}

// Restore the user's session
-(void)restoreUserSession {
	NSString *cookieDataPath = [self getCookiePath];	
	NSMutableArray *cookieDictionary = [NSKeyedUnarchiver unarchiveObjectWithFile:cookieDataPath];
	NSHTTPCookieStorage* sharedCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	for (NSDictionary *dict in cookieDictionary) {
		NSHTTPCookie *newCookie = [NSHTTPCookie cookieWithProperties:dict];
		[sharedCookieStorage setCookie:newCookie];
		
		// Debug
		NSLog(@"Restored cookie %@", newCookie);
	}
	
	// release memory
	[cookieDataPath release];
}

-(void) printCookieStorage {
	NSHTTPCookieStorage* sharedCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray* cookies = [sharedCookieStorage cookies] ;
	NSLog(@"cookies: %@", cookies);
}


/*-(void)cleanupCacheDir
{
	[[NSFileManager defaultManager] removeItemAtPath:_cocoafishDir error:nil];
}*/

-(void)dealloc
{
	//[self cleanupCacheDir];
	[_currentUser release];
	[_appKey release];
	[_consumerKey release];
	[_consumerSecret release];
	[_downloadManager release];
	[_cocoafishDir release];
	[super dealloc];
}

#pragma CCRequest delegate methods

-(void)request:(CCRequest *)request didSucceed:(CCResponse *)response
{
    NSArray *users = [response getObjectsOfType:[CCUser class]];
    if ([users count] == 1) {
        CCUser *user = [users objectAtIndex:0];
        [[Cocoafish defaultCocoafish] setCurrentUser:user];
    }
}

+(void)initializeWithAppKey:(NSString *)appKey customAppIds:(NSDictionary *)customAppIds
{
    @synchronized(theDefaultCocoafish) {
        if (theDefaultCocoafish != nil) {
            return;
        }
        theDefaultCocoafish = [[Cocoafish alloc] initWithAppKey:appKey customAppIds:customAppIds];
    }
}

+(void)initializeWithOauthConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret customAppIds:(NSDictionary *)customAppIds
{
    @synchronized(theDefaultCocoafish) {
        if (theDefaultCocoafish != nil) {
            return;
        }
        theDefaultCocoafish = [[Cocoafish alloc] initWithOauthConsumerKey:consumerKey consumerSecret:consumerSecret customAppIds:customAppIds];
    }
}

+(Cocoafish *)defaultCocoafish
{
    @synchronized(theDefaultCocoafish) {
        if (theDefaultCocoafish == nil) {
            [NSException raise:@"Uninitialized" format:@"Use [Cocoafish initializeWithAppId:customAppIds:] to initialize Cocoafish"];
        }
        return theDefaultCocoafish;
    }
}

#pragma Rest Request

+(CCRequest *)restRequest:(id)delegate httpMethod:(NSString *)httpMethod baseUrl:(NSString *)baseUrl paramDict:(NSDictionary *)paramtDict attachment:(CCAttachment *)attachment
{
    if (!([httpMethod isEqualToString:@"DELETE"] || [httpMethod isEqualToString:@"GET"] || [httpMethod isEqualToString:@"POST"] || [httpMethod isEqualToString:@"PUT"])) {
        [NSException raise:@"request Type not supported. Supported types are 'DELETE', 'POST', 'GET', 'PUT'" format:@"unknown request Type: %@", httpMethod];
    }
    
    NSMutableArray *paramArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *keys = [paramtDict allKeys];
    if ([httpMethod isEqualToString:@"GET"] || [httpMethod isEqualToString:@"DELETE"]) {
        if ([paramtDict count] > 0) {
            for (NSString *key in keys) {
                id valueObject = [paramtDict valueForKey:key];
                NSString *value = nil;
                // URL encode string
                if ([valueObject isKindOfClass:[NSArray class]]) {
                    // concatenate the array
                    value = [valueObject componentsJoinedByString:@","];
                } else {
                    value = (NSString *)valueObject;
                }
                value = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

                [paramArray addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
            }
        }
    }
    
    NSString *urlPath = [CCRequest generateFullRequestUrl:baseUrl additionalParams:paramArray];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
    CCRequest *request =[ [[CCRequest alloc] initWithURL:url httpMethod:httpMethod requestDelegate:delegate attachment:attachment] autorelease];
    
    if ([httpMethod isEqualToString:@"POST"] || [httpMethod isEqualToString:@"PUT"]) {
        for (NSString *key in keys) {
            NSString *value = [paramtDict valueForKey:key];
            [request setPostValue:value forKey:key];
            
        }
        if (attachment) {
            [request setData:[attachment attachmentData] withFileName:attachment.fileName andContentType:attachment.contentType forKey:attachment.postKey];
        }
    }
    [request addOauthHeaderToRequest];
    return request;

}


@end
