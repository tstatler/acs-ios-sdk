//
//  CCNetworkManager.h
//  Demo
//
//  Created by Wei Kong on 12/14/10.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

#define CC_FIRST_PAGE 1
#define CC_DEFAULT_PER_PAGE 20

@class CLLocation;
@class CCUser;
@class CCPlace;
@class CCCheckin;
@class CCResponse;
@class CCStatus;
@class CCPhoto;
@class CCKeyValuePair;
@class CCObject;
@class CCPagination;
@class CCEvent;
@class CCUploadImage;
@class CCMeta;
@class CCMessage;
@class CCRequest;

@protocol CCNetworkManagerDelegate;

@interface CCNetworkManager : NSObject {
	id<CCNetworkManagerDelegate> _delegate;

	@private
	NSOperationQueue *_operationQueue;
    NSOperationQueue *_photoProcessingQueue;
	NSMutableSet *_requestSet;
}

-(id)initWithDelegate:(id)delegate;
-(id)init;
-(void)cancelAllRequests;

// Users
-(CCRequest *)registerUser:(CCUser *)user password:(NSString *)password passwordConfirmation:(NSString *)passwordConfirmation image:(CCUploadImage *)image;
-(CCRequest *)login:(NSString *)login password:(NSString *)password;
-(CCRequest *)logout;
-(CCRequest *)deleteUser;  // delete current user
-(CCRequest *)showCurrentUser;
-(CCRequest *)showUser:(NSString *)userId;
-(CCRequest *)searchUsers:(NSString *)query page:(int)page perPage:(int)perPage;
-(CCRequest *)updateUser:(CCUser *)updatedUser image:(CCUploadImage *)image; // update current user

// Checkins
-(CCRequest *)searchCheckins:(CCObject *)belongTo page:(int)page perPage:(int)perPage;
-(CCRequest *)showCheckin:(NSString *)checkId;
-(CCRequest *)createCheckin:(CCObject *)belongTo message:(NSString *)message image:(CCUploadImage *)image;
-(CCRequest *)deleteCheckin:(NSString *)checkinId;

// Statuses
-(CCRequest *)createUserStatus:(NSString *)status image:(CCUploadImage *)image;
-(CCRequest *)searchUserStatuses:(CCUser *)user startTime:(NSDate *)startTime page:(int)page perPage:(int)perPage;

// Places
-(CCRequest *)deletePlace:(NSString *)placeId;
-(CCRequest *)createPlace:(CCPlace *)newPlace image:(CCUploadImage *)image;
-(CCRequest *)showPlace:(NSString *)placeId;
-(CCRequest *)searchPlaces:(NSString *)query location:(CLLocation *)location distance:(NSNumber *)distance page:(int)page perPage:(int)perPage;
-(CCRequest *)updatePlace:(CCPlace *)place image:(CCUploadImage *)image;
//-(void)getPlacesInRegion:(MKCoordinateRegion)region;

// Photos
-(CCRequest *)createPhoto:(CCObject *)photoHost collectionName:(NSString *)collectionName image:(CCUploadImage *)image;
-(CCRequest *)updatePhoto:(NSString *)photoId collectionName:(NSString *)collectionName image:(CCUploadImage *)image;
-(CCRequest *)searchPhotos:(CCObject *)photoHost collectionName:(NSString *)collectionName page:(int)page perPage:(int)perPage;
-(CCRequest *)showPhoto:(NSString *)photoId;
-(CCRequest *)deletePhoto:(NSString *)photoId;
-(CCRequest *)downloadPhoto:(id)sender photo:(CCPhoto *)photo size:(int)size;

// Key Value Pairs
-(CCRequest *)setValueForKey:(NSString *)key value:(NSString *)value;
-(CCRequest *)getValueForKey:(NSString *)value;
-(CCRequest *)appendValueForKey:(NSString *)key appendValue:(NSString *)appendValue;
-(CCRequest *)deleteKeyValue:(NSString *)key;
-(CCRequest *)incrBy:(NSString *)name value:(NSInteger)value;
-(CCRequest *)searchKeyValues:(NSString *)keyword page:(int)page per_page:(int)perPage;
-(CCRequest *)setValuesForKey:(NSString *)key values:(NSArray *)values;
-(NSArray *)getValuesForKey:(NSString *)key;

// Event related
-(CCRequest *)createEvent:(NSString *)name details:(NSString *)details placeId:(NSString *)placeId startTime:(NSDate *)startTime endTime:(NSDate *)endTime image:(CCUploadImage *)image;
-(CCRequest *)updateEvent:(NSString *)eventId name:(NSString *)name details:(NSString *)details placeId:(NSString *)placeId startTime:(NSDate *)startTime endTime:(NSDate *)endTime image:(CCUploadImage *)image;
-(CCRequest *)showEvent:(NSString *)eventId;
-(CCRequest *)searchEvents:(CCObject *)belongTo page:(int)page perPage:(int)perPage;
-(CCRequest *)deleteEvent:(NSString *)eventId;

// Message related
-(CCRequest *)createMessage:(NSString *)subject body:(NSString *)body toUserIds:(NSArray *)toUserIds;
-(CCRequest *)replyMessage:(NSString *)messageId body:(NSString *)body;
-(CCRequest *)showMessage:(NSString *)messageId;
-(CCRequest *)showInboxMessages:(int)page perPage:(int)perPage;
-(CCRequest *)showSentMessages:(int)page perPage:(int)perPage;
-(CCRequest *)showMessageThreads:(int)page perPage:(int)perPage;
-(CCRequest *)showThreadMessages:(NSString *)threadId page:(int)page perPage:(int)perPage;
-(CCRequest *)deleteMessage:(NSString *)messageId;

// Objects
-(CCRequest *)getObjectsByIds:(NSDictionary *)idsByType;

// Used to login with cocoafish after a successful facebook login
-(CCUser *)loginWithFacebook:(NSString *)fbAppId accessToken:(NSString *)accessToken error:(NSError **)error;
-(CCUser *)linkWithFacebook:(NSString *)fbAppId accessToken:(NSString *)accessToken error:(NSError **)error;
-(void)unlinkFromFacebook:(NSError **)error;

@end

// Delegate callback methods
@protocol CCNetworkManagerDelegate <NSObject>

@optional
// user logged in
-(void)networkManager:(CCNetworkManager *)networkManager didLogin:(CCUser *)user;

// user logged out
-(void)didLogout:(CCNetworkManager *)networkManager;

// create succeeded
-(void)networkManager:(CCNetworkManager *)networkManager didCreate:(NSArray *)objectArray objectType:(Class)objectType;

// get succeeded
-(void)networkManager:(CCNetworkManager *)networkManager didGet:(NSArray *)objectArray objectType:(Class)objectType pagination:(CCPagination *)pagination;

// update succeeded
-(void)networkManager:(CCNetworkManager *)networkManager didUpdate:(NSArray *)objectArray objectType:(Class)objectType;

// delete succeeded
-(void)networkManager:(CCNetworkManager *)networkManager didDelete:(Class)objectType;

// compound
-(void)networkManager:(CCNetworkManager *)networkManager meta:(CCMeta *)meta didSucceedWithCompound:(NSArray *)responses;

// generic callback, if we received custom objects or above callbacks were not implemented
-(void)networkManager:(CCNetworkManager *)networkManager didSucceed:(CCResponse *)response;


@required
-(void)networkManager:(CCNetworkManager *)networkManager didFailWithError:(NSError *)error;

@end


