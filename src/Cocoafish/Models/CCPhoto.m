//
//  CCPhoto.m
//  Cocoafish-ios-sdk
//
//  Created by Wei Kong on 2/7/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCPhoto.h"
#import "Cocoafish.h"
#import "CCDownloadManager.h"
#import "CCRequest.h"
#import "WBImage.h"

@interface CCPhoto ()

@property (nonatomic, retain, readwrite) NSString *filename;
@property (nonatomic, readwrite) int size;
@property (nonatomic, retain, readwrite) NSArray *collections;
@property (nonatomic, retain, readwrite) NSString *md5;
@property (nonatomic, readwrite) BOOL processed;
@property (nonatomic, retain, readwrite) NSString *contentType;
@property (nonatomic, retain, readwrite) NSDictionary *urls;
@property (nonatomic, retain, readwrite) NSDate *takenAt;
@property (nonatomic, retain, readwrite) CCUser *user;

-(void)handlePhotoProcessed:(NSNotification *)notification;

@end

@implementation CCPhoto
@synthesize filename = _filename;
@synthesize size = _size;
@synthesize collections = _collections;
@synthesize md5 = _md5;
@synthesize processed = _processed;
@synthesize contentType = _contentType;
@synthesize urls = _urls;
@synthesize takenAt = _takenAt;
@synthesize user = _user;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{

	if ((self = [super initWithJsonResponse:jsonResponse])) {
		self.filename = [jsonResponse objectForKey:CC_JSON_FILENAME];
		self.size = [[jsonResponse objectForKey:CC_JSON_SIZE] intValue];
        self.collections = [CCCollection arrayWithJsonResponse:jsonResponse class:[CCCollection class]];
		self.md5 = [jsonResponse objectForKey:CC_JSON_MD5];
		self.processed = [[jsonResponse objectForKey:CC_JSON_PROCESSED] boolValue];
		self.contentType = [jsonResponse objectForKey:CC_JSON_CONTENT_TYPE];
		self.urls = [jsonResponse objectForKey:CC_JSON_URLS];
        _user = [jsonResponse objectForKey:CC_JSON_USER];
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
		
		NSString *dateString = [jsonResponse objectForKey:CC_JSON_TAKEN_AT];
		if (dateString) {
			self.takenAt = [dateFormatter dateFromString:dateString];
		}
		
		if (self.processed == NO) {
			// Photo hasn't been processed on the server, add to the download manager queue 
			// it will pull for its status periodically.
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePhotoProcessed:) name:@"PhotosProcessed" object:[Cocoafish defaultCocoafish]];
			[[Cocoafish defaultCocoafish].downloadManager addProcessingPhoto:self parent:nil];
		}
			
	}
	
	return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CCPhoto:\n\tfilename: %@\n\tsize: %d\n\tmd5: %@\n\tprocessed: %d\n\tcontentType :%@\n\ttakenAt: %@\n\turls: %@\n\t%@",
            self.filename, self.size, self.md5, 
            self.processed, self.contentType, self.takenAt, [self.urls description], [super description]];
}

+(NSString *)modelName
{
    return @"photo";
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	self.filename = nil;
	self.collections = nil;
	self.md5 = nil;
	self.contentType = nil;
	self.urls = nil;
	self.takenAt = nil;
    self.user = nil;
	[super dealloc];
}

-(void)handlePhotoProcessed:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
    
	NSDictionary *photos = [userInfo valueForKey:@"photos"];
    CCPhoto *updatedPhoto = [photos objectForKey:self.objectId];
    if (updatedPhoto) {
        self.urls = updatedPhoto.urls;
        self.processed = YES;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
}

-(NSString *)getImageUrl:(PhotoSize)photoSize
{
	@synchronized(self) {
		switch (photoSize) {
			case CC_SQUARE_75:
				return [_urls objectForKey:@"square_75"];
			case CC_THUMB_100:
				return [_urls objectForKey:@"thumb_100"];
			case CC_SMALL_240:
				return [_urls objectForKey:@"small_240"];
			case CC_MEDIUM_500:
				return [_urls objectForKey:@"medium_500"];
			case CC_MEDIUM_640:
				return [_urls objectForKey:@"medium_640"];
			case CC_LARGE_1024:
				return [_urls objectForKey:@"large_1024"];			
			case CC_ORIGINAL:
				return [_urls objectForKey:@"original"];
			default:
                [NSException raise:@"Invalid Photo Size" format:@"Unknown photo size",photoSize];
				break;
		}
	}
	return nil;
			
}

-(UIImage *)getImage:(PhotoSize)photoSize
{
    UIImage *image = [UIImage imageWithContentsOfFile:[self localPath:photoSize]];
    if (!image) {
        [[Cocoafish defaultCocoafish].downloadManager downloadPhoto:self size:photoSize];
        // try again if the image was just downloaded
        image = [UIImage imageWithContentsOfFile:[self localPath:photoSize]];
    }
    return image;
}

-(NSString *)localPath:(PhotoSize)photoSize
{
    if (photoSize < CC_SQUARE_75 || photoSize > CC_ORIGINAL) {
        [NSException raise:@"Invalid Photo Size" format:@"Unknown photo size",photoSize];
    }
	return [NSString stringWithFormat:@"%@/%@_%d", [Cocoafish defaultCocoafish].cocoafishDir, self.objectId, photoSize];
}

@end


#define DEFAULT_PHOTO_MAX_SIZE  0 // original photo size 
#define DEFAULT_JPEG_COMPRESSION   1 // best photo quality
#define DEFAULT_PHOTO_FILE_NAME @"photo.jpg"
#define DEFAULT_PHOTO_KEY   @"photo"

@implementation CCUploadImage

@synthesize request = _request;
@synthesize didFinishSelector = _didFinishSelector;
@synthesize photoFileName = _photoFileName;
@synthesize photoKey = _photoKey;

-(id)initWithImage:(UIImage *)image
{
    if (image == nil) {
        return nil;
    }
    self = [super init];
    if (self) {
        _rawImage = [image retain];
        _photoFileName = DEFAULT_PHOTO_FILE_NAME;
        _photoKey = DEFAULT_PHOTO_KEY;
        _maxPhotoSize = DEFAULT_PHOTO_MAX_SIZE;
        _jpegCompression = DEFAULT_JPEG_COMPRESSION;
        
    }
    return self;
}

-(id)initWithImage:(UIImage *)image maxPhotoSize:(int)maxPhotoSize jpegCompression:(double)jpegCompression
{
    if (image == nil) {
        return nil;
    }
    if (jpegCompression < 0 || jpegCompression > 1) {
        [NSException raise:@"jpegCompression must be greater than or equal to zero and less than or equal to 1" format:@"invalid parameter"];
    }
    if (maxPhotoSize <= 0) {
        [NSException raise:@"maxPhotoSize must be greater than zero" format:@"invalid parameter"];
    }
    self = [super init];
    if (self) {
        _rawImage = [image  retain];
        _photoFileName = DEFAULT_PHOTO_FILE_NAME;
        _photoKey = DEFAULT_PHOTO_KEY;
        _maxPhotoSize = maxPhotoSize;
        _jpegCompression = jpegCompression;
        
    }
    return self;

}
-(void)processAndSetPhotoData
{    
    if (!_photoData) {
        UIImage *processedImage = [_rawImage scaleAndRotateImage:_maxPhotoSize];
        [_rawImage release];
        _rawImage = nil;
    
        // convert to jpeg and save
        _photoData = [UIImageJPEGRepresentation(processedImage, _jpegCompression) retain];
    }
    [_request setData:_photoData withFileName:_photoFileName andContentType:@"image/jpeg" forKey:_photoKey];
    
}

-(void)dealloc
{
    [_rawImage release];
    [_photoData release];
    [_request release];
    [_photoFileName release];
    [_photoKey release];
    [super dealloc];
}
@end
