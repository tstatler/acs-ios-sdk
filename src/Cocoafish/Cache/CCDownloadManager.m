 //
//  CCDownloadManager.m
//  Cocoafish-ios-sdk
//
//  Created by Wei Kong on 3/8/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCDownloadManager.h"
#import "CCDownloadRequest.h"
#import "CCPhoto.h"
#import "Cocoafish.h"
#import "CCResponse.h"

#define DEFAULT_TIME_INTERVAL	3

@interface CCDownloadManager ()

@property (nonatomic, retain, readwrite) NSTimer *autoUpdateTimer;
@end

@implementation CCDownloadManager
@synthesize autoUpdateTimer = _autoUpdateTimer;

-(id)init
{
	self = [super init];
	if (self) {
		if (_ccNetworkManager == nil) {
			_ccNetworkManager = [[CCNetworkManager alloc] initWithDelegate:self];
		}
		_downloadInProgress = [[NSMutableSet alloc] init];
		_processingPhotos = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)downloadPhoto:(CCPhoto *)photo size:(int)size
{
	@synchronized(self) {
        if (!photo.processed) {
            // we don't have the photo url info yet, put in the queue
            if (_pendingPhotoDownloadQueue == nil) {
                _pendingPhotoDownloadQueue = [[NSMutableDictionary alloc] init];
            }
            NSMutableArray *sizes = [_pendingPhotoDownloadQueue objectForKey:photo.objectId];
            if (sizes == nil) {
                sizes = [NSMutableArray arrayWithObject:[NSNumber numberWithInt:size]];
                [_pendingPhotoDownloadQueue setObject:sizes forKey:photo.objectId];
            } else {
                Boolean found = false;
                for (NSNumber *cursize in sizes) {
                    if ([cursize intValue] == size) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    [sizes addObject:[NSNumber numberWithInt:size]];
                }
            }
            return;
        }
        NSString *downloadPath = [photo localPath:size];
		if ([_downloadInProgress containsObject:downloadPath]) {
			// download already in progress, no op
			return;
		}
		[_ccNetworkManager downloadPhoto:self photo:photo size:size];
        [_downloadInProgress addObject:[photo localPath:size]];
		
	}
}

-(void)downloadDone:(ASIHTTPRequest *)request
{

	CCDownloadRequest *downloadRequest = (CCDownloadRequest *)request;
	NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:downloadRequest.size, @"size", downloadRequest.object, @"object", nil];
	
	NSNotification * myNotification = [NSNotification notificationWithName:@"DownloadFinished" object:[Cocoafish defaultCocoafish] userInfo:dict];
	[[NSNotificationQueue defaultQueue] enqueueNotification:myNotification postingStyle:NSPostNow];	
	@synchronized(self) {
		if (downloadRequest.size != nil) {
			// it is a photo download
			[_downloadInProgress removeObject:[(CCPhoto *)downloadRequest.object localPath:[downloadRequest.size intValue]]];
		}
	}
} 
	
-(void)downloadFailed:(ASIHTTPRequest *)request
{
	CCDownloadRequest *downloadRequest = (CCDownloadRequest *)request;
	NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:downloadRequest.size, @"size", downloadRequest.object, @"object", nil];
	NSNotification * myNotification = [NSNotification notificationWithName:@"sDownloadFailed" object:[Cocoafish defaultCocoafish] userInfo:dict];
	[[NSNotificationQueue defaultQueue] enqueueNotification:myNotification postingStyle:NSPostNow];	
} 

-(void)addProcessingPhoto:(CCPhoto *)photo parent:(CCObject *)parent;
{
	if (!photo) {
		return;
	}
    if (parent == nil) {
        // set parnt to photo self if no parent was given
        parent = photo;
    }
	@synchronized(self) {
        [_processingPhotos setObject:parent forKey:photo.objectId];
		
		if (self.autoUpdateTimer != nil) {
			[self.autoUpdateTimer invalidate];
			self.autoUpdateTimer = nil;
		}
		
		_timeInterval = DEFAULT_TIME_INTERVAL;
		self.autoUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:(_timeInterval)
																target:self
															  selector:@selector(updateProcessingPhotos)
															  userInfo:nil
															   repeats:NO];
		
	}
}

-(void)updateProcessingPhotos
{
	@synchronized(self) {
		self.autoUpdateTimer = nil;
		
		NSArray *objectIds;
		if ([_processingPhotos count] > 100) {
			// we will check 100 at a time
			NSRange theRange;
			
			theRange.location = 0;
			theRange.length = 100;
			
			objectIds = [[_processingPhotos allKeys] subarrayWithRange:theRange];
		} else {
			objectIds = [_processingPhotos allKeys]; 
		}

		if ([objectIds count] > 0) {
			// construct the request
            NSMutableDictionary *idsByType = [NSMutableDictionary dictionaryWithCapacity:1];
            for (NSString *objectId in objectIds) {
                CCObject *parent = [_processingPhotos objectForKey:objectId];
                NSMutableArray *ids = [idsByType objectForKey:NSStringFromClass([parent class])];
                if (ids == nil) {
                    ids = [NSMutableArray arrayWithObject:parent.objectId];
                    [idsByType setObject:ids forKey:NSStringFromClass([parent class])];
                } else {
                    [ids addObject:parent.objectId];
                }
            }
			[_ccNetworkManager getObjectsByIds:idsByType];
		}
		
	}
}


-(void)networkManager:(CCNetworkManager *)networkManager didGet:(NSArray *)objects objectType:(Class)objectType pagination:(CCPagination *)pagination
{
    NSMutableDictionary *processedPhotos = [NSMutableDictionary dictionaryWithCapacity:1];

	@synchronized(self) {	
        for (CCObject *object in objects) {
            CCPhoto *photo = nil;
            if (objectType == [CCPhoto class]) {
                photo = (CCPhoto *)object;
            }  else if ([object isKindOfClass:[CCObjectWithPhoto class]]) {
                photo = ((CCObjectWithPhoto *)object).photo;
            } else {
                continue;
            }/*else if (objectType == [CCUser class]) {
                photo = ((CCUser *)object).photo;
            } else if (objectType == [CCCheckin class]) {
                photo = ((CCCheckin *)object).photo;
            } else if (objectType == [CCStatus class]) {
                photo = ((CCStatus *)object).photo;
            }*/

            if (photo.processed) {
                [_processingPhotos removeObjectForKey:photo.objectId];
                [processedPhotos setObject:photo forKey:photo.objectId];
                NSArray *sizes = [_pendingPhotoDownloadQueue objectForKey:photo.objectId];
                // there are some pending download, perform them now since we have the urls
                for (NSNumber *size in sizes) {
                    [photo getImage:[size intValue]];
                }
                [_pendingPhotoDownloadQueue removeObjectForKey:photo.objectId];
            }
        }
		
        if ([_processingPhotos count] > 0) {
			// there are still some photos are being processed on the server
			if (_autoUpdateTimer == nil) {
				if (_timeInterval < 864000) {
					_timeInterval = _timeInterval * 2;
				}
				self.autoUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:(_timeInterval)
												target:self
												selector:@selector(updateProcessingPhotos)
												userInfo:nil
												repeats:NO];
			}
		}
	}
	
	if ([processedPhotos count] > 0) {
		// send out notification
		NSDictionary *dict = [NSDictionary dictionaryWithObject:processedPhotos forKey:@"photos"];
		
		NSNotification * myNotification = [NSNotification notificationWithName:@"PhotosProcessed" object:[Cocoafish defaultCocoafish] userInfo:dict];
		[[NSNotificationQueue defaultQueue] enqueueNotification:myNotification postingStyle:NSPostNow];	
	}
	
}

-(void)networkManager:(CCNetworkManager *)networkManager didFailWithError:(NSError *)error
{
	// restart the timer
	@synchronized(self) {
		if (_autoUpdateTimer == nil) {
			if (_timeInterval < 864000) {
				_timeInterval = _timeInterval * 2;
			}
			self.autoUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:(_timeInterval)
																	target:self
																  selector:@selector(updateProcessingPhotos)
																  userInfo:nil
																   repeats:NO];
		}
	}
}

-(void)dealloc
{
	[_ccNetworkManager release];
	[super dealloc];
	
}
@end

