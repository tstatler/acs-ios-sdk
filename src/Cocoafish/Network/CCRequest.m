//
//  CCRequest.m
//  APIs
//
//  Created by Wei Kong on 4/2/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCRequest.h"
#import "CCResponse.h"
#import "Cocoafish.h"
#import "OAuthCore.h"

@interface CCRequest ()
+(NSString *)generateRequestId;
-(void)initCommon;
-(void)addOauthHeaderToRequest;
+(NSString *)generateFullRequestUrl:(NSString *)partialUrl additionalParams:(NSArray *)additionalParams;
@property (nonatomic, readwrite, retain) NSString *requestId;
@property (nonatomic, readwrite, retain) CCAttachment *attachment;
@end

@implementation CCRequest
@synthesize requestId = _requestId;
@synthesize attachment = _attachment;
@synthesize requestDelegate = _requestDelegate;

-(id)initWithDelegate:(id)requestDelegate httpMethod:(NSString *)httpMethod baseUrl:(NSString *)baseUrl paramDict:(NSDictionary *)paramDict;
{
    NSMutableArray *paramArray = nil;
    NSArray *keys = [paramDict allKeys];
    if ([httpMethod isEqualToString:@"GET"] || [httpMethod isEqualToString:@"DELETE"]) {
        // construct the url
        if ([paramDict count] > 0) {
            paramArray = [NSMutableArray arrayWithCapacity:[paramDict count]];
            for (NSString *key in keys) {
                id valueObject = [paramDict valueForKey:key];
                NSString *value = nil;
                // URL encode string
                if ([valueObject isKindOfClass:[NSArray class]]) {
                    // concatenate the array
                    value = [valueObject componentsJoinedByString:@","];
                } else if (![valueObject isKindOfClass:[NSString class]]) {
                    value = [valueObject description];
                } else {
                    value = (NSString *)valueObject;
                }
                value = encodeToPercentEscapeString(value);
                [paramArray addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
            }
        }
    }
    
    NSString *urlPath = [CCRequest generateFullRequestUrl:baseUrl additionalParams:paramArray];
    
	NSURL *newUrl = [NSURL URLWithString:urlPath];
    self = [super initWithURL:newUrl];
    if (self) {
        NSLog(@"CCRequest Url: %@", [newUrl absoluteString]);
        [self setRequestMethod:httpMethod];
        self.requestDelegate = requestDelegate;       
        if ([httpMethod isEqualToString:@"POST"] || [httpMethod isEqualToString:@"PUT"]) {
            // add post body
            for (NSString *key in keys) {
                id valueObject = [paramDict valueForKey:key];
                NSString *value = nil;
                // URL encode string
                if ([valueObject isKindOfClass:[NSArray class]]) {
                    // concatenate the array
                    value = [valueObject componentsJoinedByString:@","];
                } else if (![valueObject isKindOfClass:[NSString class]]) {
                    value = [valueObject description];
                } else {
                    value = (NSString *)valueObject;
                }
                [self setPostValue:value forKey:key];
                
            }
            
        }
        [self initCommon];
    }
    return self;
    
}

-(void)initCommon
{
    self.requestId = [CCRequest generateRequestId];
    self.timeOutSeconds = CC_TIMEOUT;
    [self setDelegate:self];
    [self setDidFinishSelector:@selector(requestDone:)];
    [self setDidFailSelector:@selector(requestFailed:)];
    [self addRequestHeader:@"Accepts-Encoding" value:@"gzip"];   
    
}

// use UUID
+(NSString *)generateRequestId
{
    // Create universally unique identifier (object)
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    
    // Get the string representation of CFUUID object.
    NSString *uuidStr = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject) autorelease];
    
    // If needed, here is how to get a representation in bytes, returned as a structure
    // typedef struct {
    //   UInt8 byte0;
    //   UInt8 byte1;
    //   ...
    //   UInt8 byte15;
    // } CFUUIDBytes;
  //  CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuidObject);
    
    CFRelease(uuidObject);
    
    return uuidStr;
}

-(void)main
{
    [self addOauthHeaderToRequest];
    [super main];
}

-(CCResponse *)startSynchronous
{
  /*  [self setDelegate:nil];
    [self setDidFailSelector:nil];
    [self setDidFailSelector:nil];*/
    [super startSynchronous];	
    CCResponse *response = nil;
	if (![self error]) {
		NSLog(@"%@", [self responseString]);
        response = [[CCResponse alloc] initWithJsonData:[self responseData]];
	}
    return response;
}

-(void)addPhoto:(CCPhotoAttachment *)photoAttachment
{
    if (!photoAttachment) {
        return;
    }
    if (![self.requestMethod isEqualToString:@"PUT"] && ![self.requestMethod isEqualToString:@"POST"]) {
        NSLog(@"addPhotoAttachment only works with PUT or POST");
        return;
    }
    [self setData:[photoAttachment attachmentData] withFileName:photoAttachment.fileName andContentType:photoAttachment.contentType forKey:photoAttachment.postKey];
    
}
#pragma mark - REST Call support
-(void)addOauthHeaderToRequest
{
	if (![[Cocoafish defaultCocoafish] getOauthConsumerKey] || ![[Cocoafish defaultCocoafish] getOauthConsumerSecret]) {
		// nothing to add
		return;
	}
	BOOL postRequest = NO;
	if ([self.requestMethod isEqualToString:@"POST"] || [self.requestMethod isEqualToString:@"PUT"]) {
		postRequest = YES;
	}
	NSData *body = nil;
    
	if (postRequest) {
		[self buildPostBody];
		body = [self postBody];
	}
	
	NSString *header = OAuthorizationHeader([self url],
											[self requestMethod],
											body,
											[[Cocoafish defaultCocoafish] getOauthConsumerKey],
											[[Cocoafish defaultCocoafish] getOauthConsumerSecret],
											@"",
											@"");
	[self addRequestHeader:@"Authorization" value:header];
}

+(NSString *)generateFullRequestUrl:(NSString *)partialUrl additionalParams:(NSArray *)additionalParams
{
	NSString *url = nil;
	NSString *appKey = [[Cocoafish defaultCocoafish] getAppKey];
    NSString *paramsString = nil;
    if ([additionalParams count] > 0) {
        paramsString = [additionalParams componentsJoinedByString:@"&"];
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

-(void)dealloc
{
    self.requestId = nil;
    self.attachment = nil;
    [super dealloc];
}

#pragma ASIHTTPrequest Callback
-(void)requestDone:(CCRequest *)origRequest
{
    NSLog(@"Received %@", [origRequest responseString]);
    CCResponse *response = [[CCResponse alloc] initWithJsonData:[origRequest responseData]];
    if (response && [response.meta.status isEqualToString:CC_STATUS_OK]) {
        if ([_requestDelegate respondsToSelector:@selector(request:didSucceed:)]) {
            [_requestDelegate request:origRequest didSucceed:response];
        }
    } else {
       // something failed on the server
        if ([_requestDelegate respondsToSelector:@selector(request:didFailWithError:)]) {
          
            NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionaryWithCapacity:2];
            if (response && [response.meta.message length] > 0) {
                [errorUserInfo setObject:[NSString stringWithFormat:@"%@", response.meta.message] forKey:NSLocalizedDescriptionKey];
            }
            if (response.meta) {
                [errorUserInfo setObject:response.meta forKey:@"meta"];
            }
            NSError *requestError = [NSError errorWithDomain:CC_DOMAIN code:CC_SERVER_ERROR userInfo:errorUserInfo];
            [_requestDelegate request:origRequest didFailWithError:requestError];
        }
    }
    
}

-(void)requestFailed:(CCRequest *)origRequest
{
    if ([_requestDelegate respondsToSelector:@selector(request:didFailWithError:)]) {
        [_requestDelegate request:origRequest didFailWithError:[origRequest error]];
    }
    
}
@end


// Used by Joshua
@implementation CCDeleteRequest
@synthesize deleteClass = _deleteClass;

-(id)initWithURL:(NSURL *)newURL deleteClass:(Class)deleteClass
{
    self = [super initWithURL:newURL];
    if (self) {
        _deleteClass = deleteClass;
        [self setRequestMethod:@"DELETE"];
    }
    return self;
}

-(void)dealloc
{
    [super dealloc];
}
@end
