//
//  CCAttachment.m
//  Demo
//
//  Created by Wei Kong on 6/1/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCAttachment.h"
#import "WBImage.h"
#import "AssetsLibrary/AssetsLibrary.h"

@interface CCAttachment ()

@property (nonatomic, retain, readwrite) NSString *fileName;
@property (nonatomic, retain, readwrite) NSString *contentType;
@property (nonatomic, retain, readwrite) NSString *postKey;

@end

@implementation CCAttachment

@synthesize fileName = _fileName;
@synthesize contentType = _contentType;
@synthesize postKey = _postKey;

-(NSData *)attachmentData
{
    [NSException raise:@"Please implement this method in subclass" format:@"missing implementation"];  
    return nil;
}

@end

#define DEFAULT_PHOTO_MAX_SIZE  0 // original photo size 
#define DEFAULT_JPEG_COMPRESSION   1 // best photo quality

@interface CCPhotoAttachment ()
-(void)initCommon;
- (NSData *)imageDataFromALAsset;
@end

@implementation CCPhotoAttachment

-(id)initWithALAsset:(ALAsset *)asset
{
    if (asset == nil) {
        return nil;
    }
    
    if (![[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
        [NSException raise:@"ALAsset is not a photo" format:@"invalid object type"];
    }

    self = [super init];
    if (self) {
        _asset = [asset retain];
        _maxPhotoSize = DEFAULT_PHOTO_MAX_SIZE;
        _jpegCompression = DEFAULT_JPEG_COMPRESSION;
        [self initCommon];
        
    }
    return self;
}

-(id)initWithALAsset:(ALAsset *)asset maxPhotoSize:(int)maxPhotoSize jpegCompression:(double)jpegCompression
{
    if (asset == nil) {
        return nil;
    }
    if (![[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
        [NSException raise:@"ALAsset is not a photo" format:@"invalid object type"];
    }
     self = [super init];
    if (self) {
        _asset = [asset retain];
        _maxPhotoSize = maxPhotoSize;
        _jpegCompression = jpegCompression;
        [self initCommon];
        
    }
    return self;
}

-(id)initWithImage:(UIImage *)image
{
    if (image == nil) {
        return nil;
    }
    self = [super init];
    if (self) {
        _rawImage = [image retain];
        _maxPhotoSize = DEFAULT_PHOTO_MAX_SIZE;
        _jpegCompression = DEFAULT_JPEG_COMPRESSION;
        [self initCommon];
        
    }
    return self;
}

-(void)initCommon
{
    _needProcess = YES;
    if (_asset && _maxPhotoSize == 0 && _jpegCompression == 1.0) {
        // send original file from _asset, need to get the correct file type
        NSString *uti = [[_asset defaultRepresentation] UTI];
        NSArray *tokens = [NSArray arrayWithArray:[uti componentsSeparatedByString:@"."]];
        for (NSString *token in tokens) {
            if ([[token lowercaseString] isEqualToString:@"jpg"] || 
                [[token lowercaseString] isEqualToString:@"jpeg"] || 
                [[token lowercaseString] isEqualToString:@"png"] || 
                [[token lowercaseString] isEqualToString:@"gif"]) {
                _fileName = [[NSString alloc] initWithFormat:@"photo.%@", token];
                _contentType = [[NSString alloc] initWithFormat:@"image/%@", token];
                _needProcess = NO;
                break;
            }
        }
    }
    if (!_fileName || !_contentType) {
        _fileName = @"file.jpg";
        _contentType = @"image/jpeg";
    }
    _postKey = @"photo";
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
        _rawImage = [image retain];
        _maxPhotoSize = maxPhotoSize;
        _jpegCompression = jpegCompression;
        [self initCommon];
        
    }
    return self;
    
}
-(NSData *)attachmentData
{    
    NSData *photoData = nil;
    if (_asset && !_needProcess) {
        photoData = [self imageDataFromALAsset];

    } else {
        UIImage *image = _rawImage;
        if (_asset) {
            image = [UIImage imageWithCGImage:[[_asset defaultRepresentation] fullResolutionImage]];
        }
        UIImage *processedImage = [image scaleAndRotateImage:_maxPhotoSize];
    
        // convert to jpeg and save
        photoData = UIImageJPEGRepresentation(processedImage, _jpegCompression);
    }

    return photoData;
}

- (NSData *)imageDataFromALAsset {
	ALAssetRepresentation *assetRep = [_asset defaultRepresentation];
    
	NSUInteger size = [assetRep size];
	uint8_t *buff = malloc(size);
    
	NSError *err = nil;
	NSUInteger gotByteCount = [assetRep getBytes:buff fromOffset:0 length:size error:&err];
    
	if (gotByteCount) {
		if (err) {
			NSLog(@"!!! Error reading asset: %@", [err localizedDescription]);
			[err release];
			free(buff);
			return nil;
		}
	}
    
	return [NSData dataWithBytesNoCopy:buff length:size freeWhenDone:YES];
}

-(void)dealloc
{
    [_asset release];
    [_fileName release];
    [_postKey release];
    [_contentType release];
    [_rawImage release];
    [super dealloc];
}

@end
