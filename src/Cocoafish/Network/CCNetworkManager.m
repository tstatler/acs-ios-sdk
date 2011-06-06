//
//  CCNetworkManager.m
//  Demo
//
//  Created by Wei Kong on 12/14/10.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCNetworkManager.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "Cocoafish.h"
#import "CCResponse.h"
#import "CCConstants.h"
#import "OAuthCore.h"
#import "CCRequest.h"

// Encode a string to embed in an URL.
/*NSString* encodeToPercentEscapeString(NSString *string) {
    return (NSString *)
    CFURLCreateStringByAddingPercentEscapes(NULL,
                                            (CFStringRef) string,
                                            NULL,
                                            (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                            kCFStringEncodingUTF8);
}*/

# pragma -
# pragma mark CCNetworkManager PrivateMethods
@interface CCNetworkManager (PrivateMethods)
-(void)setDelegate:(id)delegate;
-(void)addNewRequest:(ASIHTTPRequest *)newRequest;
-(void)removeFinishedRequest:(ASIHTTPRequest *)finishedRequest;
-(NSError *)serverErrorFromResponse:(CCResponse *)jsonResponse;
-(void)performAsyncRequest:(ASIHTTPRequest *)request callback:(SEL)callback;
-(void)loginRequestDone:(ASIHTTPRequest *)request;
-(void)logoutRequestDone:(ASIHTTPRequest *)request;
-(void)createRequestDone:(ASIHTTPRequest *)request;
-(void)getRequestDone:(ASIHTTPRequest *)request;
-(void)updateRequestDone:(ASIHTTPRequest *)request;
-(void)deleteRequestDone:(ASIHTTPRequest *)request;
-(void)requestFailed:(ASIHTTPRequest *)request;
-(void)addOauthHeaderToRequest:(ASIHTTPRequest *)request;
-(Class)parseResultArray:(NSDictionary *)jsonResponse resultArray:(NSMutableArray **)resultArray;
-(NSDictionary *)parseJsonResponse:(NSDictionary *)jsonResponse;
-(NSString *)generateFullRequestUrl:(NSString *)partialUrl additionalParams:(NSArray *)additionalParams;
-(CCUser *)facebookAuth:(NSString *)fbAppId accessToken:(NSString *)accessToken error:(NSError **)error isLogin:(Boolean)isLogin;
-(void)processImageBeforeUpload:(CCUploadImage *)image;
@end

# pragma -
# pragma mark CCNetworkManager implementations
@implementation CCNetworkManager

-(id)initWithDelegate:(id)delegate {
	if ((self = [super init])) {
		[self setDelegate:delegate];
		// init the operation queue
		_operationQueue = [[NSOperationQueue alloc] init];
        _photoProcessingQueue = [[NSOperationQueue alloc] init];
		_requestSet = [[NSMutableSet alloc] init];
        
	}
	return self;
}

-(id)init {
	if ((self = [super init])) {
		// init the operation queue
		_operationQueue = [[NSOperationQueue alloc] init];
        _photoProcessingQueue = [[NSOperationQueue alloc] init];
		_requestSet = [[NSMutableSet alloc] init];
        
	}
	return self;
}

-(void)setDelegate:(id)delegate
{
	// Sanity Check
	if (![delegate conformsToProtocol:@protocol(CCNetworkManagerDelegate)]) {
		[NSException raise:@"CCNetworkManagerDelegate Exception"
					format:@"Parameter does not conform to CCNetworkManagerDelegate protocol at line %d", (int)__LINE__];
	}
	_delegate = delegate;
}

# pragma -
# pragma mark requests Management
-(void)addNewRequest:(ASIHTTPRequest *)newRequest
{
	@synchronized(self) {
		[_requestSet addObject:newRequest];
	}
    [self retain];
}

-(void)removeFinishedRequest:(ASIHTTPRequest *)finishedRequest
{
	@synchronized(self) {
		[_requestSet removeObject:finishedRequest];
	}
    [self release];
}

-(void)cancelAllRequests
{
	@synchronized(self) {
		NSArray *allRequests = [_requestSet allObjects];
		for (ASIHTTPRequest *request in allRequests) {
			[request clearDelegatesAndCancel];
		}
		[_requestSet removeAllObjects];
	}
}

// Generate NSError from json Response
-(NSError *)serverErrorFromResponse:(CCResponse *)jsonResponse
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
	if (jsonResponse && [jsonResponse.meta.message length] > 0) {
		[userInfo setObject:[NSString stringWithFormat:@"%@", jsonResponse.meta.message] forKey:NSLocalizedDescriptionKey];
	}
	if (jsonResponse.meta.method) {
		[userInfo setObject:jsonResponse.meta.method forKey:@"remote_method"];
	}
	NSError *error = [NSError errorWithDomain:CC_DOMAIN code:CC_SERVER_ERROR userInfo:userInfo];
	return error;
}

-(void)performAsyncRequest:(ASIHTTPRequest *)request callback:(SEL)callback
{
	[self addOauthHeaderToRequest:request];
    
	request.timeOutSeconds = CC_TIMEOUT;
    
	// set callbacks
	[request setDelegate:self];
	[request setDidFinishSelector:callback];
	[request setDidFailSelector:@selector(requestFailed:)];
    
	[_operationQueue addOperation:request];
    
	[self addNewRequest:request];
    
}

-(void)addOauthHeaderToRequest:(ASIHTTPRequest *)request
{
	if (![[Cocoafish defaultCocoafish] getOauthConsumerKey] || ![[Cocoafish defaultCocoafish] getOauthConsumerSecret]) {
		// nothing to add
		return;
	}
	BOOL postRequest = NO;
	if ([request isKindOfClass:[ASIFormDataRequest class]]) {
		postRequest = YES;
	}
	NSData *body = nil;
    
	if (postRequest) {
		[request buildPostBody];
		body = [request postBody];
	}
    
	NSString *header = OAuthorizationHeader([request url],
											[request requestMethod],
											body,
											[[Cocoafish defaultCocoafish] getOauthConsumerKey],
											[[Cocoafish defaultCocoafish] getOauthConsumerSecret],
											@"",
											@"");
	[request addRequestHeader:@"Authorization" value:header];
}

-(NSString *)generateFullRequestUrl:(NSString *)partialUrl additionalParams:(NSArray *)additionalParams
{
	NSString *url = nil;
	NSString *appKey = [[Cocoafish defaultCocoafish] getAppKey];
    NSString *paramsString = nil;
    if ([additionalParams count] > 0) {
        paramsString = [additionalParams componentsJoinedByString:@"&"];
        paramsString = [paramsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
	if ([appKey length] > 0) {
		if (paramsString) {
			url = [NSString stringWithFormat:@"%@/%@?key=%@&%@", CC_BACKEND_URL, partialUrl, appKey, 
                   paramsString];
		} else {
			url = [NSString stringWithFormat:@"%@/%@?key=%@", CC_BACKEND_URL, partialUrl, appKey];
		}
	} else if (paramsString) {
		url = [NSString stringWithFormat:@"%@/%@?%@", CC_BACKEND_URL, partialUrl, paramsString];
	} else {
		url = [NSString stringWithFormat:@"%@/%@", CC_BACKEND_URL, partialUrl];
	}
	return url;
}


-(void)processImageBeforeUpload:(CCUploadImage *)image
{   
    [image processAndSetPhotoData];
    [self performAsyncRequest:image.request callback:image.didFinishSelector];
    
}

#pragma mark -
#pragma mark Cocoafish API calls

#pragma mark - Users related
-(void)registerUser:(CCUser *)user password:(NSString *)password passwordConfirmation:(NSString *)passwordConfirmation image:(CCUploadImage *)image
{
	NSString *urlPath = [self generateFullRequestUrl:@"users/create.json" additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    
	// set the form
    if ([user.email length] > 0) {
        [request setPostValue:user.email forKey:@"email"];
    }
    if ([user.firstName length] > 0) {
        [request setPostValue:user.firstName forKey:@"first_name"];
    }
    if ([user.lastName length] > 0) {
        [request setPostValue:user.lastName forKey:@"last_name"];
    }
    if ([user.username length] > 0) {
        [request setPostValue:user.username forKey:@"username"];
    }
	[request setPostValue:password forKey:@"password"];
	[request setPostValue:passwordConfirmation forKey:@"password_confirmation"];
    
    if (image) {        
        image.request = request;
        image.didFinishSelector = @selector(createRequestDone:);
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                selector:@selector(processImageBeforeUpload:)
                                                                                  object:image];
        
        /* Add the operation to the photo processing queue */
        [_photoProcessingQueue addOperation:operation];
        [operation release];
        return;
        
	}
    
	[self performAsyncRequest:request callback:@selector(createRequestDone:)];
}

-(void)showCurrentUser
{
	NSString *urlPath = [self generateFullRequestUrl:@"users/show/me.json" additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
}

-(void)showUser:(NSString *)userId
{
	NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"users/show/%@.json", userId] additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
    
}

-(void)searchUsers:(NSString *)query page:(int)page perPage:(int)perPage 
{
    NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];
    if (query) {
        [additionalParams addObject:[NSString stringWithFormat:@"q=%@", query]];
    }
    
	NSString *urlPath = [self generateFullRequestUrl:@"users/search.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
}


-(void)login:(NSString *)login password:(NSString *)password
{
	NSString *urlPath = [self generateFullRequestUrl:@"users/login.json" additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    
	// set the form
	[request setPostValue:login forKey:@"login"];
	[request setPostValue:password forKey:@"password"];
    
	[self performAsyncRequest:request callback:@selector(loginRequestDone:)];
}

-(void)logout
{
	NSString *urlPath = [self generateFullRequestUrl:@"users/logout.json" additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(logoutRequestDone:)];
    
}

-(void)updateUser:(CCUser *)updatedUser image:(CCUploadImage *)image
{
    CCUser *currentUser = [[Cocoafish defaultCocoafish] getCurrentUser];
    
    NSString *urlPath = [self generateFullRequestUrl:@"users/update.json" additionalParams:nil];
    NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    [request setRequestMethod:@"PUT"];
    
    if ([currentUser.email caseInsensitiveCompare:updatedUser.email] != NSOrderedSame) {
        [request setPostValue:updatedUser.email forKey:@"email"];
    }
    if ([currentUser.firstName caseInsensitiveCompare:updatedUser.firstName] != NSOrderedSame) {
        [request setPostValue:updatedUser.firstName forKey:@"first_name"];
    }
    if ([currentUser.email caseInsensitiveCompare:updatedUser.email] != NSOrderedSame) {
        [request setPostValue:updatedUser.lastName forKey:@"last_name"];
    }
    if ([currentUser.username caseInsensitiveCompare:updatedUser.username] != NSOrderedSame) {
        [request setPostValue:updatedUser.username forKey:@"username"];
    }        
    if (image) {
        /* Create our NSInvocationOperation to call loadDataWithOperation, passing in nil */
        
        image.request = request;
        image.didFinishSelector = @selector(updateRequestDone:);
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processImageBeforeUpload:) object:image];
        
        /* Add the operation to the photo processing queue */
        [_photoProcessingQueue addOperation:operation];
        [operation release];
        return;
        
	}
    
	[self performAsyncRequest:request callback:@selector(updateRequestDone:)];
    
}

-(void)deleteUser
{
    NSString *urlPath = [self generateFullRequestUrl:@"users/delete.json" additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
    
	CCDeleteRequest *request = [[[CCDeleteRequest alloc] initWithURL:url deleteClass:[CCUser class]] autorelease];
    
    [self performAsyncRequest:request callback:@selector(deleteRequestDone:)];
}

#pragma mark - Facebook related
-(CCUser *)linkWithFacebook:(NSString *)fbAppId accessToken:(NSString *)accessToken error:(NSError **)error
{
	return [self facebookAuth:fbAppId accessToken:accessToken error:error isLogin:NO];
}

-(CCUser *)loginWithFacebook:(NSString *)fbAppId accessToken:(NSString *)accessToken error:(NSError **)error
{
	return [self facebookAuth:fbAppId accessToken:accessToken error:error isLogin:YES];
    
}

-(void)unlinkFromFacebook:(NSError **)error
{
	NSString *urlPath = [self generateFullRequestUrl:@"social/facebook/unlink.json" additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    [request setRequestMethod:@"DELETE"];
	[self addOauthHeaderToRequest:request];
    
	[request startSynchronous];	
	*error = [request error];
	CCUser *currentUser = nil;
	if (!*error) {
		NSLog(@"%@", [request responseString]);
		CCResponse *response = [[CCResponse alloc] initWithJsonData:[request responseData]];
		if (response && [response.meta.status isEqualToString:CC_STATUS_OK]) {
			NSMutableArray *users = nil;
            Class class = [self parseResultArray:response.response resultArray:&users];
			if (class == [CCUser class] && [users count] == 1) {
				currentUser = [users objectAtIndex:0];
			}
			if (!currentUser) {
				NSLog(@"Did not receive user info after facebookLogin");
			} else {
				[[Cocoafish defaultCocoafish] setCurrentUser:currentUser];
			}
            
		} else {
			*error = [self serverErrorFromResponse:response];
		}
	} 
    
}

-(CCUser *)facebookAuth:(NSString *)fbAppId accessToken:(NSString *)accessToken error:(NSError **)error isLogin:(Boolean)isLogin
{
	NSString *urlPath = nil;
    
	if (isLogin) {
		urlPath = [self generateFullRequestUrl:@"social/facebook/login.json" additionalParams:nil];
	} else {
		urlPath = [self generateFullRequestUrl:@"social/facebook/link.json" additionalParams:nil];
	}
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    
	// set the form
	[request setPostValue:fbAppId forKey:@"facebook_app_id"];
	[request setPostValue:accessToken forKey:@"access_token"];
    
	[self addOauthHeaderToRequest:request];
    
	[request startSynchronous];	
	*error = [request error];
	CCUser *currentUser = nil;
	if (!*error) {
		NSLog(@"%@", [request responseString]);
		CCResponse *response = [[CCResponse alloc] initWithJsonData:[request responseData]];
		if (response && [response.meta.status isEqualToString:CC_STATUS_OK]) {
			NSMutableArray *users = nil;
            Class class = [self parseResultArray:response.response resultArray:&users];
			if (class == [CCUser class] && [users count] == 1) {
				currentUser = [users objectAtIndex:0];
			}
			if (!currentUser) {
				NSLog(@"Did not receive user info after facebookLogin");
			} else {
				[[Cocoafish defaultCocoafish] setCurrentUser:currentUser];
			}
            
		} else {
			*error = [self serverErrorFromResponse:response];
		}
	} 
	return currentUser;
}


#pragma mark - Facebook related
-(void)searchCheckins:(CCObject *)belongTo page:(int)page perPage:(int)perPage
{
    NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];
    if ([belongTo isKindOfClass:[CCPlace class]]) {
        [additionalParams addObject:[NSString stringWithFormat:@"place_id=%@", belongTo.objectId]];
    } else if ([belongTo isKindOfClass:[CCUser class]]) {
        [additionalParams addObject:[NSString stringWithFormat:@"user_id=%@", belongTo.objectId]];
    } else if ([belongTo isKindOfClass:[CCEvent class]]) {
        [additionalParams addObject:[NSString stringWithFormat:@"event_id=%@", belongTo.objectId]];
    } else {
        [NSException raise:@"Object type is not supported in showCheckins" format:@"unknow object type"];
    }
    NSString *urlPath = [self generateFullRequestUrl:@"checkins/search.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
    
}

-(void)createCheckin:(CCObject *)belongTo message:(NSString *)message image:(CCUploadImage *)image
{
    
	NSString *urlPath = [self generateFullRequestUrl:@"checkins/create.json" additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    
    if ([belongTo isKindOfClass:[CCPlace class]]) {
        [request setPostValue:belongTo.objectId forKey:@"place_id"];
    } else if ([belongTo isKindOfClass:[CCEvent class]]) {
        [request setPostValue:belongTo.objectId forKey:@"event_id"];
    } else {
        [NSException raise:@"Object type is not supported in createCheckin" format:@"unknow object type"];
    }
	if (message && [message length] > 0) {
		[request setPostValue:message forKey:@"message"];
	}
    
	if (image) {
        image.request = request;
        image.didFinishSelector = @selector(createRequestDone:);
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                selector:@selector(processImageBeforeUpload:)
                                                                                  object:image];
        
        /* Add the operation to the photo processing queue */
        [_photoProcessingQueue addOperation:operation];
        [operation release];
        return;
	}
    
	[self performAsyncRequest:request callback:@selector(createRequestDone:)];
    
}

-(void)deleteCheckin:(NSString *)checkinId
{
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"checkins/delete/%@.json", checkinId] additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
    
	CCDeleteRequest *request = [[[CCDeleteRequest alloc] initWithURL:url deleteClass:[CCCheckin class]] autorelease];
    
    [self performAsyncRequest:request callback:@selector(deleteRequestDone:)];
}

-(void)showCheckin:(NSString *)checkinId
{	
	NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"checkins/show/%@.json", checkinId] additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
}

#pragma mark - Statuses
-(void)createUserStatus:(NSString *)message image:(CCUploadImage *)image
{	
	NSString *urlPath = [self generateFullRequestUrl:@"statuses/create.json" additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    
	[request setPostValue:message forKey:@"message"];
    
    if (image) {
        image.request = request;
        image.didFinishSelector = @selector(createRequestDone:);
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                selector:@selector(processImageBeforeUpload:) object:image];
        
        /* Add the operation to the photo processing queue */
        [_photoProcessingQueue addOperation:operation];
        [operation release];
        return;
	}
    
	[self performAsyncRequest:request callback:@selector(createRequestDone:)];
    
}

-(void)searchUserStatuses:(CCUser *)user startTime:(NSDate *)startTime page:(int)page perPage:(int)perPage
{
	NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];
    if (user != nil) {
        [additionalParams addObject:[NSString stringWithFormat:@"user_id=%@", user.objectId]];
    }
    if (startTime != nil) {
        [additionalParams addObject:[NSString stringWithFormat:@"start_time=%.0f", [startTime timeIntervalSince1970]]];
    }
	NSString *urlPath = [self generateFullRequestUrl:@"statuses/search.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
    
}
-(void)deletePlace:(NSString *)placeId
{
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"places/delete/%@.json", placeId] additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
    
    
	CCDeleteRequest *request = [[[CCDeleteRequest alloc] initWithURL:url deleteClass:[CCPlace class]] autorelease];
    
    [self performAsyncRequest:request callback:@selector(deleteRequestDone:)];
}

-(void)updatePlace:(CCPlace *)place image:(CCUploadImage *)image
{
    
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"places/update/%@.json", place.objectId] additionalParams:nil];
    NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    [request setRequestMethod:@"PUT"];
    if (place.name) {
        [request setPostValue:place.name forKey:@"name"];
    }
    if (place.address) {
        [request setPostValue:place.address forKey:@"address"];
    }
    if (place.crossStreet) {
        [request setPostValue:place.crossStreet forKey:@"crossStreet"];
    }
    if (place.city) {
        [request setPostValue:place.city forKey:@"city"];
    }
    if (place.state) {
        [request setPostValue:place.state forKey:@"state"];
    }
    if (place.country) {
        [request setPostValue:place.country forKey:@"country"];
    }
    if (place.postalCode) {
        [request setPostValue:place.postalCode forKey:@"postal_code"];
    }
    if (place.website) {
        [request setPostValue:place.website forKey:@"website"];
    }
    if (place.twitter) {
        [request setPostValue:place.twitter forKey:@"twitter"];
    }
    if (place.phone) {
        [request setPostValue:place.phone forKey:@"phone_number"];
    }
    if (place.location) {
        [request setPostValue:[NSString stringWithFormat:@"%f", place.location.coordinate.latitude] forKey:@"latitude"];
        [request setPostValue:[NSString stringWithFormat:@"%f", place.location.coordinate.longitude] forKey:@"longitude"];
    }
    
    if (image) {
        /* Create our NSInvocationOperation to call loadDataWithOperation, passing in nil */
        
        image.request = request;
        image.didFinishSelector = @selector(updateRequestDone:);
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processImageBeforeUpload:) object:image];
        
        /* Add the operation to the photo processing queue */
        [_photoProcessingQueue addOperation:operation];
        [operation release];
        return;
        
	}
    
	[self performAsyncRequest:request callback:@selector(updateRequestDone:)];
    
}

-(void)createPlace:(CCPlace *)newPlace image:(CCUploadImage *)image
{
    NSString *urlPath = [self generateFullRequestUrl:@"places/create.json" additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    if (newPlace.name) {
        [request setPostValue:newPlace.name forKey:@"name"];
    }
    if (newPlace.address) {
        [request setPostValue:newPlace.address forKey:@"address"];
    }
    if (newPlace.crossStreet) {
        [request setPostValue:newPlace.crossStreet forKey:@"crossStreet"];
    }
    if (newPlace.city) {
        [request setPostValue:newPlace.city forKey:@"city"];
    }
    if (newPlace.state) {
        [request setPostValue:newPlace.state forKey:@"state"];
    }
    if (newPlace.country) {
        [request setPostValue:newPlace.country forKey:@"country"];
    }
    if (newPlace.postalCode) {
        [request setPostValue:newPlace.postalCode forKey:@"postal_code"];
    }
    if (newPlace.website) {
        [request setPostValue:newPlace.website forKey:@"website"];
    }
    if (newPlace.twitter) {
        [request setPostValue:newPlace.twitter forKey:@"twitter"];
    }
    if (newPlace.phone) {
        [request setPostValue:newPlace.phone forKey:@"phone_number"];
    }
    if (newPlace.location) {
        [request setPostValue:[NSString stringWithFormat:@"%f", newPlace.location.coordinate.latitude] forKey:@"latitude"];
        [request setPostValue:[NSString stringWithFormat:@"%f", newPlace.location.coordinate.longitude] forKey:@"longitude"];
    }
    
    if (image) {
        image.request = request;
        image.didFinishSelector = @selector(createRequestDone:);
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processImageBeforeUpload:) object:image];
        
        /* Add the operation to the photo processing queue */
        [_photoProcessingQueue addOperation:operation];
        [operation release];
        return;
	}
    
    [self performAsyncRequest:request callback:@selector(createRequestDone:)];
    
}

-(void)searchPlaces:(NSString *)query location:(CLLocation *)location distance:(NSNumber *)distance page:(int)page perPage:(int)perPage
{
    NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];
    if (query) {
        [additionalParams addObject:[NSString stringWithFormat:@"q=%@", query]];
    }
    if (location) {
        [additionalParams addObject:[NSString stringWithFormat:@"latitude=%f", location.coordinate.latitude]];
        [additionalParams addObject:[NSString stringWithFormat:@"longitude=%f", location.coordinate.longitude]];
    }
    if (distance) {
        [additionalParams addObject:[NSString stringWithFormat:@"distance=%f", [distance doubleValue]]];
    }
    
	NSString *urlPath = [self generateFullRequestUrl:@"places/search.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
}

-(void)showPlace:(NSString *)placeId
{	
	NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"places/show/%@.json", placeId] additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
}

// currently object only supports CCUser and CCPlace
-(void)createPhoto:(CCObject *)photoHost collectionName:(NSString *)collectionName image:(CCUploadImage *)image
{
    NSString *urlPath = [self generateFullRequestUrl:@"photos/create.json" additionalParams:nil];
    
    NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
	//[request setFile:photoPath forKey:@"file"];	
    
    if ([photoHost isKindOfClass:[CCPlace class]]) {
        [request setPostValue:photoHost.objectId forKey:@"place_id"];
    } else if ([photoHost isKindOfClass:[CCUser class]]) {
        [request setPostValue:photoHost.objectId forKey:@"user_id"];
    } else {
        [NSException raise:@"Object type is not supported in uploadPhoto" format:@"unknow object type"];
    }
    
    if ([collectionName length]>0) {
        [request setPostValue:collectionName forKey:@"collection_name"];
    }
    if ([photoHost isKindOfClass:[CCPlace class]]) {
        [request setPostValue:photoHost.objectId forKey:@"place_id"];
    } else if ([photoHost isKindOfClass:[CCUser class]]) {
        [request setPostValue:photoHost.objectId forKey:@"user_id"];
    } else {
        [NSException raise:@"Object type is not supported in uploadPhoto" format:@"unknow object type"];
    }
    
    if (image) {
        /* Create our NSInvocationOperation to call loadDataWithOperation, passing in nil */
        
        image.request = request;
        image.didFinishSelector = @selector(createRequestDone:);
        image.photoKey = @"file";
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                selector:@selector(processImageBeforeUpload:)
                                                                                  object:image];
        
        /* Add the operation to the photo processing queue */
        [_photoProcessingQueue addOperation:operation];
        [operation release];
        return;
    }     	
    
	[self performAsyncRequest:request callback:@selector(createRequestDone:)];
}

-(void)searchPhotos:(CCObject *)object collectionName:(NSString *)collectionName page:(int)page perPage:(int)perPage
{
    NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];
    if ([collectionName length] > 0) {
        [additionalParams addObject:[NSString stringWithFormat:@"collection_name=%@", collectionName]];
    }
    
    if ([object isKindOfClass:[CCPlace class]]) {
        [additionalParams addObject:[NSString stringWithFormat:@"place_id=%@", object.objectId]];
    } else if ([object isKindOfClass:[CCUser class]]) {
        [additionalParams addObject:[NSString stringWithFormat:@"user_id=%@", object.objectId]];
    } else {
        [NSException raise:@"Object type is not supported in searchPhotos" format:@"unknow object type"];
    }
    
    NSString *urlPath = [self generateFullRequestUrl:@"photos/search.json" additionalParams:additionalParams];
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];	
    
}

-(void)showPhoto:(NSString *)photoId
{
	NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"photos/show/%@.json", photoId] additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];	
}

-(void)deletePhoto:(NSString *)photoId
{
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"photos/delete/%@.json", photoId] additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
    
	CCDeleteRequest *request = [[[CCDeleteRequest alloc] initWithURL:url deleteClass:[CCPhoto class]] autorelease];	
    
	[self performAsyncRequest:request callback:@selector(deleteRequestDone:)];
}

// Get a list of photos by their ids
-(void)getPhotosByIds:(NSArray *)photoIds
{
	if ([photoIds count] == 0) {
		return;
	} 
	NSMutableString *photoIdsStr = [[[NSMutableString alloc] init] autorelease];;
    
	for (NSString *photoId in photoIds) {
		[photoIdsStr appendFormat:@"%@,", photoId];
	}
	if ([photoIdsStr length] > 0) {
		// remove the last ,
		NSRange range;
		range.location = [photoIdsStr length] - 1;
		range.length = 1;
		[photoIdsStr deleteCharactersInRange:range];
        
	}
    
	NSArray *additionalParams = [NSArray arrayWithObject:[NSString stringWithFormat:@"ids=%@", photoIdsStr]];
    
	NSString *urlPath = [self generateFullRequestUrl:@"photos/show.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];	
}


/*-(Boolean)downloadPhoto:(id)sender photo:(CCPhoto *)photo size:(int)size
{
	NSString *urlPath = [photo getImageUrl:size];
	if (photo == nil || urlPath == nil) {
		return NO;
	}
	NSURL *url = [NSURL URLWithString:urlPath];
	CCDownloadRequest *request = [[[CCDownloadRequest alloc] initWithURL:url object:photo size:[NSNumber numberWithInt:size]] autorelease];
	[request setDownloadDestinationPath:[photo localPath:size]];
    
	request.timeOutSeconds = CC_TIMEOUT;
    
	// set callbacks
	[request setDelegate:sender];
	[request setDidFinishSelector:@selector(downloadDone:)];
	[request setDidFailSelector:@selector(downloadFailed:)];
    
	[_operationQueue addOperation:request];
    
	[self addNewRequest:request];
	return YES;
}*/

#pragma mark - KeyValues related

-(void)setValueForKey:(NSString *)key value:(NSString *)value
{
    NSArray *additionalParams = [NSArray arrayWithObjects:[NSString stringWithFormat:@"name=%@", key], [NSString stringWithFormat:@"value=%@", value], nil];
    
    NSString *urlPath = [self generateFullRequestUrl:@"keyvalues/set.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    [request setRequestMethod:@"PUT"];
    
	[self performAsyncRequest:request callback:@selector(createRequestDone:)];
}

-(void)getValueForKey:(NSString *)key
{
	NSArray *additionalParams = [NSArray arrayWithObject:[NSString stringWithFormat:@"name=%@", key]];
    
	NSString *urlPath = [self generateFullRequestUrl:@"keyvalues/get.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];	
    
}

-(void)appendValueForKey:(NSString *)key appendValue:(NSString *)appendValue
{
    NSArray *additionalParams = [NSArray arrayWithObjects:[NSString stringWithFormat:@"name=%@", key], [NSString stringWithFormat:@"value=%@", appendValue], nil];
    
    NSString *urlPath = [self generateFullRequestUrl:@"keyvalues/append.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    [request setRequestMethod:@"PUT"];
    
	[self performAsyncRequest:request callback:@selector(updateRequestDone:)];
    
}

-(void)deleteKeyValue:(NSString *)key
{
    NSArray *additionalParams = [NSArray arrayWithObject:[NSString stringWithFormat:@"name=%@", key]];
    
    NSString *urlPath = [self generateFullRequestUrl:@"keyvalues/delete.json" additionalParams:additionalParams];
	NSURL *url = [NSURL URLWithString:urlPath];
    
	CCDeleteRequest *request = [[[CCDeleteRequest alloc] initWithURL:url deleteClass:[CCKeyValuePair class]] autorelease];
    
	[self performAsyncRequest:request callback:@selector(deleteRequestDone:)];
}

-(void)incrBy:(NSString *)name value:(NSInteger)value
{
    NSArray *additionalParams = [NSArray arrayWithObjects:[NSString stringWithFormat:@"name=%@", name], [NSString stringWithFormat:@"value=%d", value], nil];
    NSString *urlPath = [self generateFullRequestUrl:@"keyvalues/incrby.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    [request setRequestMethod:@"PUT"];
    
	[self performAsyncRequest:request callback:@selector(updateRequestDone:)];
    
}

-(void)searchKeyValues:(NSString *)query page:(int)page per_page:(int)perPage
{
    NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];
    if (query) {
        [additionalParams addObject:[NSString stringWithFormat:@"q=%@", query]];
    }
    NSString *urlPath = [self generateFullRequestUrl:@"keyvalues/search.json" additionalParams:additionalParams];
    NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
}

-(void)setValuesForKey:(NSString *)key values:(NSArray *)values
{
    NSArray *additionalParams = [NSArray arrayWithObjects:[NSString stringWithFormat:@"name=%@", key], [NSString stringWithFormat:@"value=%@",  [values componentsJoinedByString:@"^"]], nil];
    
    NSString *urlPath = [self generateFullRequestUrl:@"keyvalues/set.json" additionalParams:additionalParams];
    
    NSURL *url = [NSURL URLWithString:urlPath];
    
    ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    [request setRequestMethod:@"PUT"];
    
    [self performAsyncRequest:request callback:@selector(createRequestDone:)];

}

-(NSArray *)getValuesForKey:(NSString *)key
{
    NSArray *additionalParams = [NSArray arrayWithObject:[NSString stringWithFormat:@"name=%@", key]];
    
    NSString *urlPath = [self generateFullRequestUrl:@"keyvalues/get.json" additionalParams:additionalParams];
    
    NSURL *url = [NSURL URLWithString:urlPath];
    ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    [self addOauthHeaderToRequest:request];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        NSLog(@"%@", [request responseString]);
        CCResponse *response = [[CCResponse alloc] initWithJsonData:[request responseData]];
        if (response && [response.meta.status isEqualToString:CC_STATUS_OK]) {
            NSDictionary *results = [self parseJsonResponse:response.response];
            NSArray *kvs = [results objectForKey:NSStringFromClass([CCKeyValuePair class])];
            CCKeyValuePair *kv = nil;
            if ([kvs count] == 1) {
                kv = [kvs objectAtIndex:0];
                return [kv.value componentsSeparatedByString:@"^"];
            }
        }
    }
    return nil;
    
}


#pragma mark - Event related
-(void)createEvent:(NSString *)name details:(NSString *)details placeId:(NSString *)placeId startTime:(NSDate *)startTime endTime:(NSDate *)endTime image:(CCUploadImage *)image
{    
    NSString *urlPath = [self generateFullRequestUrl:@"events/create.json" additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
    ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    
    if (name) {
        [request setPostValue:name forKey:@"name"];
    }
    if (details) {
        [request setPostValue:details forKey:@"details"];
    }
    if (placeId) {
        [request setPostValue:placeId forKey:@"place_id"];
    }
    if (startTime) {
        [request setPostValue:[startTime description] forKey:@"start_time"];
    }
    if (endTime) {
        [request setPostValue:[endTime description] forKey:@"end_time"];
    }
    
    if (image) {
        image.request = request;
        image.didFinishSelector = @selector(createRequestDone:);
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processImageBeforeUpload:) object:image];
        
        /* Add the operation to the photo processing queue */
        [_photoProcessingQueue addOperation:operation];
        [operation release];
        return;
	}
    
	[self performAsyncRequest:request callback:@selector(createRequestDone:)];
    
}

-(void)updateEvent:(NSString *)eventId name:(NSString *)name details:(NSString *)details placeId:(NSString *)placeId startTime:(NSDate *)startTime endTime:(NSDate *)endTime image:(CCUploadImage *)image

{
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"events/update/%@.json", eventId] additionalParams:nil];
    NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    [request setRequestMethod:@"PUT"];
    
    if (name) {
        [request setPostValue:name forKey:@"name"];
    }
    if (details) {
        [request setPostValue:details forKey:@"details"];
    }
    if (placeId) {
        [request setPostValue:placeId forKey:@"place_id"];
    }
    if (startTime) {
        [request setPostValue:[startTime description] forKey:@"start_time"];
    }
    if (endTime) {
        [request setPostValue:[endTime description] forKey:@"end_time"];
    }
    
    if (image) {
        /* Create our NSInvocationOperation to call loadDataWithOperation, passing in nil */
        
        image.request = request;
        image.didFinishSelector = @selector(updateRequestDone:);
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processImageBeforeUpload:) object:image];
        
        /* Add the operation to the photo processing queue */
        [_photoProcessingQueue addOperation:operation];
        [operation release];
        return;
        
	}
    
	[self performAsyncRequest:request callback:@selector(updateRequestDone:)];
    
}

-(void)showEvent:(NSString *)eventId
{
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"events/show/%@.json", eventId] additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
    
}
-(void)searchEvents:(CCObject *)belongTo page:(int)page perPage:(int)perPage
{
    NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];
    
    if ([belongTo isKindOfClass:[CCUser class]]) {
        [additionalParams addObject:[NSString stringWithFormat:@"user_id=%@", belongTo.objectId]]; 
    } else if ([belongTo isKindOfClass:[CCPlace class]]) {
        [additionalParams addObject:[NSString stringWithFormat:@"place_id=%@", belongTo.objectId]]; 
    } else {
        [NSException raise:@"Object type is not supported in searchEvents" format:@"unknow object type"];
    }
    
	NSString *urlPath = [self generateFullRequestUrl:@"events/search.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
}

-(void)deleteEvent:(NSString *)eventId
{
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"events/delete/%@.json", eventId] additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
    
	CCDeleteRequest *request = [[[CCDeleteRequest alloc] initWithURL:url deleteClass:[CCEvent class]] autorelease];
    
    [self performAsyncRequest:request callback:@selector(deleteRequestDone:)];    
}

#pragma - Messages related
// Message related
-(void)createMessage:(NSString *)subject body:(NSString *)body toUserIds:(NSArray *)toUserIds
{
    NSString *urlPath = [self generateFullRequestUrl:@"messages/create.json" additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
    ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    
    if (subject) {
        [request setPostValue:subject forKey:@"subject"];
    }
    if (body) {
        [request setPostValue:body forKey:@"body"];
    }
    if (toUserIds) {
        [request setPostValue:[toUserIds componentsJoinedByString:@","] forKey:@"to_ids"];
    }
    
	[self performAsyncRequest:request callback:@selector(createRequestDone:)];
    
}
-(void)replyMessage:(NSString *)messageId body:(NSString *)body
{
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"messages/reply/%@.json", messageId] additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
    
    ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
    
    if (body) {
        [request setPostValue:body forKey:@"body"];
    }
	[self performAsyncRequest:request callback:@selector(createRequestDone:)];
}

-(void)showMessage:(NSString *)messageId
{
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"messages/show/%@.json", messageId] additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
}

-(void)showInboxMessages:(int)page perPage:(int)perPage
{
    NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];
    NSString *urlPath = [self generateFullRequestUrl:@"messages/show/inbox.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
}

-(void)showSentMessages:(int)page perPage:(int)perPage
{
    NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];
    NSString *urlPath = [self generateFullRequestUrl:@"messages/show/sent.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
}

-(void)showMessageThreads:(int)page perPage:(int)perPage
{
    NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];

    NSString *urlPath = [self generateFullRequestUrl:@"messages/show/threads.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
    
}

-(void)showThreadMessages:(NSString *)threadId page:(int)page perPage:(int)perPage startTime:(NSDate *)startTime order:(NSString *)order
{

    NSMutableArray *additionalParams = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"page=%d", page], [NSString stringWithFormat:@"per_page=%d", perPage], nil];
    if (startTime != nil) {
        [additionalParams addObject:[NSString stringWithFormat:@"start_time=%@", encodeToPercentEscapeString([startTime description])]];
    }
    if (order) {
         [additionalParams addObject:[NSString stringWithFormat:@"order=%@", order]];
    }
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"messages/show/thread/%@.json", threadId] additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];
    
}

-(int)newMesssageCount:(NSString *)threadId
{
    
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"messages/show/thread_unread_count/%@.json", threadId] additionalParams:nil];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    [self addOauthHeaderToRequest:request];
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        NSLog(@"%@", [request responseString]);
        CCResponse *response = [[CCResponse alloc] initWithJsonData:[request responseData]];
        if (response && [response.meta.status isEqualToString:CC_STATUS_OK] && response.meta.pagination) {
            return response.meta.pagination.totalResults;
        }
    }
    return 0;
    

}

-(void)deleteMessage:(NSString *)messageId
{
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"messages/delete/%@.json", messageId] additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
    
	CCDeleteRequest *request = [[[CCDeleteRequest alloc] initWithURL:url deleteClass:[CCMessage class]] autorelease];
    
    [self performAsyncRequest:request callback:@selector(deleteRequestDone:)]; 
    
}

-(void)deleteThreadMessages:(NSString *)threadId
{
    NSString *urlPath = [self generateFullRequestUrl:[NSString stringWithFormat:@"messages/delete/thread/%@.json", threadId] additionalParams:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
    
	CCDeleteRequest *request = [[[CCDeleteRequest alloc] initWithURL:url deleteClass:[CCMessage class]] autorelease];
    
    [self performAsyncRequest:request callback:@selector(deleteRequestDone:)]; 
    
}

# pragma objects
-(void)getObjectsByIds:(NSDictionary *)idsByType
{
    if ([idsByType count] == 0) {
		return;
	} 
    NSArray *types = [idsByType allKeys];
    NSMutableArray *additionalParams = [NSMutableArray arrayWithCapacity:1];
    for (NSString *type in types) {
        NSArray *ids = [idsByType objectForKey:type];
        NSString *idString = [ids componentsJoinedByString:@","];
        [additionalParams addObject:[NSString stringWithFormat:@"%@_ids=%@",[[type lowercaseString] substringFromIndex:2], idString]];
    }
    
	NSString *urlPath = [self generateFullRequestUrl:@"objects/show.json" additionalParams:additionalParams];
    
	NSURL *url = [NSURL URLWithString:urlPath];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    
	[self performAsyncRequest:request callback:@selector(getRequestDone:)];	
    
}


# pragma -
# pragma mark Handle Server responses
// parse response into a dictionary with class name string as key and array of objects of that class as value
-(NSDictionary *)parseJsonResponse:(NSDictionary *)jsonResponse
{
    NSArray *jsonTagArray = [jsonResponse allKeys];
    NSMutableDictionary *resultDictionary = nil;
    for (NSString *jsonTag in jsonTagArray) {
        Class class = [CCObject class];
        if ([jsonTag caseInsensitiveCompare:CC_JSON_USERS] == NSOrderedSame) {
            class = [CCUser class];
        } else if ([jsonTag caseInsensitiveCompare:CC_JSON_PLACES] == NSOrderedSame) {
            class = [CCPlace class];
        } else if ([jsonTag caseInsensitiveCompare:CC_JSON_CHECKINS] == NSOrderedSame) {
            class = [CCCheckin class];
        } else if ([jsonTag caseInsensitiveCompare:CC_JSON_PHOTOS] == NSOrderedSame) {
            class = [CCPhoto class];
        } else if ([jsonTag caseInsensitiveCompare:CC_JSON_STATUSES] == NSOrderedSame) {
            class = [CCStatus class];
        } else if ([jsonTag caseInsensitiveCompare:CC_JSON_KEY_VALUES] == NSOrderedSame) {
            class = [CCKeyValuePair class];
        } else if ([jsonTag caseInsensitiveCompare:CC_JSON_EVENTS] == NSOrderedSame) {
            class = [CCEvent class];
        } else if ([jsonTag caseInsensitiveCompare:CC_JSON_MESSAGES] == NSOrderedSame) {
            class = [CCMessage class];
        } else  {
            continue;
        }
        
        NSArray *jsonArray = [jsonResponse objectForKey:jsonTag];
        if (jsonArray == nil) {
            continue;
        }
        if ([jsonArray isKindOfClass:[NSArray class]]) {
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:[jsonArray count]];
            for (NSDictionary *jsonObject in jsonArray) {
                CCObject *object = (CCObject *)[[class alloc] initWithJsonResponse:jsonObject];
                if (object) {
                    [array addObject:object];
                    [object release];
                }
            }
            if (resultDictionary == nil) {
                resultDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
            }
            [resultDictionary setObject:array forKey:NSStringFromClass(class)];
        }
    }
    return (NSDictionary *)resultDictionary;
}

-(CCResponse *)requestDoneCommon:(ASIHTTPRequest *)request
{
    
    NSLog(@"Received %@", [request responseString]);
    CCResponse *response = [[CCResponse alloc] initWithJsonData:[request responseData]];
    if (response && [response.meta.status isEqualToString:CC_STATUS_OK]) {
        return response;
    } else {
        // something failed on the server
        NSError *error = [self serverErrorFromResponse:response];
        if (error && [_delegate respondsToSelector:@selector(networkManager:didFailWithError:)]) {
            [_delegate networkManager:self didFailWithError:error];
        }
    }
    [self removeFinishedRequest:request];
    
    return nil;
}

// Create action finished
-(void)loginRequestDone:(ASIHTTPRequest *)request
{
    CCResponse *response = [self requestDoneCommon:request];
    if (response) {
        if ([_delegate respondsToSelector:@selector(networkManager:didLogin:)]) {
            NSDictionary *results = [self parseJsonResponse:response.response];
            NSArray *users = [results objectForKey:NSStringFromClass([CCUser class])];       
            
            CCUser *user = nil;
            
            if ([users count] == 1) {
                user = [users objectAtIndex:0];
            }
            
            [_delegate networkManager:self didLogin:user];
            [[Cocoafish defaultCocoafish] setCurrentUser:user];
            
        }
    } 
}

// Create action finished
-(void)logoutRequestDone:(ASIHTTPRequest *)request
{
    CCResponse *response = [self requestDoneCommon:request];
    if (response) {
        if ([_delegate respondsToSelector:@selector(didLogout:)]) {
            
            [_delegate didLogout:self];
            [[Cocoafish defaultCocoafish] setCurrentUser:nil];
        }
    } 
}

// Create action finished
-(void)createRequestDone:(ASIHTTPRequest *)request
{
    CCResponse *response = [self requestDoneCommon:request];
    if (response) {
        NSDictionary *results = [self parseJsonResponse:response.response];
        NSArray *users = [results objectForKey:NSStringFromClass([CCUser class])];
        if ([users count] == 1) {
            CCUser *user = [users objectAtIndex:0];
            [[Cocoafish defaultCocoafish] setCurrentUser:user];
        }
        
        if ([_delegate respondsToSelector:@selector(networkManager:didCreate:objectType:)]) {
            
            NSArray *classKeys = [results allKeys];
            for (NSString *classKey in classKeys) {
                Class class = NSClassFromString(classKey);
                NSArray *objects = [results objectForKey:classKey];
                [_delegate networkManager:self didCreate:objects objectType:class];
            }
        } else if ([_delegate respondsToSelector:@selector(networkManager:meta:didSucceed:)]) {
            
            // Call the generic callback if we don't know how to process the returned objects or 
            // the didGet callback was not implemented
            [_delegate networkManager:self meta:response.meta didSucceed:response.response];
        }
        
    } 
}

// get action finished
-(void)getRequestDone:(ASIHTTPRequest *)request
{
    CCResponse *response = [self requestDoneCommon:request];
    if (response) {
        NSDictionary *results = [self parseJsonResponse:response.response];
        if ([_delegate respondsToSelector:@selector(networkManager:didGet:objectType:pagination:)]) {
            
            NSArray *classKeys = [results allKeys];
            for (NSString *classKey in classKeys) {
                Class class = NSClassFromString(classKey);
                NSArray *objects = [results objectForKey:classKey];
                [_delegate networkManager:self didGet:objects objectType:class pagination:response.meta.pagination];
                
            }
        } else if ([_delegate respondsToSelector:@selector(networkManager:meta:didSucceed:)]) {
            
            // Call the generic callback if we don't know how to process the returned objects or 
            // the didGet callback was not implemented
            [_delegate networkManager:self meta:response.meta didSucceed:response.response];
        }
    } 
}

// update action finished
-(void)updateRequestDone:(ASIHTTPRequest *)request
{
    CCResponse *response = [self requestDoneCommon:request];
    if (response) {
        NSDictionary *results = [self parseJsonResponse:response.response];
        NSArray *users = [results objectForKey:NSStringFromClass([CCUser class])];
        if ([users count] == 1) {
            CCUser *user = [users objectAtIndex:0];
            [[Cocoafish defaultCocoafish] setCurrentUser:user];
        }
        
        if ([_delegate respondsToSelector:@selector(networkManager:didUpdate:objectType:)]) {
            
            NSArray *classKeys = [results allKeys];
            for (NSString *classKey in classKeys) {
                Class class = NSClassFromString(classKey);
                NSArray *objects = [results objectForKey:classKey];
                [_delegate networkManager:self didUpdate:objects objectType:class];
            }
        } else if ([_delegate respondsToSelector:@selector(networkManager:meta:didSucceed:)]) {
            
            // Call the generic callback if we don't know how to process the returned objects or 
            // the didGet callback was not implemented
            [_delegate networkManager:self meta:response.meta didSucceed:response.response];
        }
    } 
}

// delete action finished
-(void)deleteRequestDone:(ASIHTTPRequest *)request
{
    CCResponse *response = [self requestDoneCommon:request];
    if (response) {
        CCDeleteRequest *deleteRequest = (CCDeleteRequest *)request;
        Class deleteClass = deleteRequest.deleteClass;
        if (deleteClass == [CCUser class]) {
            [[Cocoafish defaultCocoafish] setCurrentUser:nil];
        }
        if ([_delegate respondsToSelector:@selector(networkManager:didDelete:)]) {
            [_delegate networkManager:self didDelete:deleteClass];
        } else if ([_delegate respondsToSelector:@selector(networkManager:meta:didSucceed:)]) {
            
            // Call the generic callback if we don't know how to process the returned objects or 
            // the didGet callback was not implemented
            [_delegate networkManager:self meta:response.meta didSucceed:response.response];
        }
        
    } 
}

-(void)compoundRequestDone:(ASIHTTPRequest *)request
{
    CCResponse *response = [self requestDoneCommon:request];
    if (response) {
        if ([_delegate respondsToSelector:@selector(networkManager:meta:didSucceedWithCompound:)]) {
            [_delegate networkManager:self meta:response.meta didSucceedWithCompound:response.responses];
        }
    }    
}

-(void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
    if ([_delegate respondsToSelector:@selector(networkManager:didFailWithError:)]) {
        [_delegate networkManager:self didFailWithError:error];
    }
	[self removeFinishedRequest:request];
    
}

# pragma -
# pragma mark Memory Management
-(void)dealloc
{
	[self cancelAllRequests];
	[_operationQueue cancelAllOperations];
	[_operationQueue release];
    [_photoProcessingQueue cancelAllOperations];
    [_photoProcessingQueue release];
	[_requestSet release];
	[super dealloc];
}

@end
