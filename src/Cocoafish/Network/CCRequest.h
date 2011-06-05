//
//  CCRequest.h
//  APIs
//
//  Created by Wei Kong on 4/2/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

@class CCObject;
@class CCResponse;
@class CCUploadImage;
@class CCAttachment;

@protocol CCRequestDelegate;

// use format data request all the time
@interface CCRequest : ASIFormDataRequest {
    id<CCRequestDelegate> _requestDelegate;
    NSString *_requestId;
    CCAttachment *_attachment;
}

-(id)initWithURL:(NSURL *)url;
-(id)initWithURL:(NSURL *)url method:(NSString *)method; 
-(id)initWithURL:(NSURL *)newUrl httpMethod:(NSString *)httpMethod requestDelegate:(id)requestDelegate attachment:(CCAttachment *)attachment;
-(CCResponse *)startSynchronous;

-(void)addOauthHeaderToRequest;
+(NSString *)generateFullRequestUrl:(NSString *)partialUrl additionalParams:(NSArray *)additionalParams;

@property(nonatomic, assign) id<CCRequestDelegate> requestDelegate;
@property (nonatomic, retain, readonly) NSString *requestId;
@property (nonatomic, retain, readonly) CCAttachment *attachment;
@end

// Delegate callback methods
@protocol CCRequestDelegate <NSObject>

@optional

// generic callback, if we received custom objects or above callbacks were not implemented
-(void)request:(CCRequest *)request didSucceed:(CCResponse *)response;

-(void)request:(CCRequest *)request didFailWithError:(NSError *)error;

@end

// used by joshua
@interface  CCDeleteRequest  :  ASIHTTPRequest  {
@private
    Class _deleteClass;
}

@property (nonatomic, readonly) Class deleteClass;

-(id)initWithURL:(NSURL *)newURL deleteClass:(Class)deleteClass;
@end