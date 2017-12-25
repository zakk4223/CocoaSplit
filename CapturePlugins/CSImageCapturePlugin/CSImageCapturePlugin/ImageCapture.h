//
//  ImageCapture.h
//  CocoaSplit
//
//  Created by Zakk on 12/27/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSCaptureBase.h"
#import "ImageCaptureLayer.h"

@interface ImageCapture : CSCaptureBase <CSCaptureSourceProtocol, CALayerDelegate>
{
    
    NSArray *_sourceList;
    size_t _totalFrames;
    CAKeyframeAnimation *_animation;
    CGImageRef _singleImage;
    NSData *_imageData;
    bool _wasLoadedFromData;
    float _imageDuration;
    NSSize _imageSize;
    CGImageSourceRef _imageSource;
}




@property (assign) double videoCaptureFPS;
@property (assign) int width;
@property (assign) int height;
@property (weak) id videoDelegate;

@property NSString *imagePath;


- (BOOL)needsAdvancedVideo;
-(void)chooseDirectory;




@end
