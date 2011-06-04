//
//  CCAttachment.h
//  Demo
//
//  Created by Wei Kong on 6/1/11.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALAsset;

@interface CCAttachment : NSObject {
@protected
    NSString *_fileName;
    NSString *_contentType;
    NSString *_postKey;
}

-(NSData *)attachmentData;

@property (nonatomic, retain, readonly) NSString *fileName;
@property (nonatomic, retain, readonly) NSString *contentType;
@property (nonatomic, retain, readonly) NSString *postKey;

@end

@interface CCPhotoAttachment: CCAttachment {
@private
    UIImage *_rawImage;
    int _maxPhotoSize;
    double _jpegCompression;
    ALAsset *_asset;
    BOOL _needProcess;
}

-(id)initWithALAsset:(ALAsset *)asset;
-(id)initWithALAsset:(ALAsset *)asset maxPhotoSize:(int)maxPhotoSize jpegCompression:(double)jpegCompression;
-(id)initWithImage:(UIImage *)image;
-(id)initWithImage:(UIImage *)image maxPhotoSize:(int)maxPhotoSize jpegCompression:(double)jpegCompression;

@end
