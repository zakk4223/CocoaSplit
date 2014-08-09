//
//  ImageCapture.h
//  CocoaSplit
//
//  Created by Zakk on 12/27/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureBase.h"
#import "CaptureController.h"


@interface ImageCapture : CaptureBase <CaptureSessionProtocol>
{
    
    NSArray *_sourceList;
    NSMutableArray *_delayList;
    CGImageSourceRef _imageSource;
    size_t _totalFrames;
    int _frameNumber;
    dispatch_queue_t _animationQueue;
    NSMutableArray *_imageCache;
    CIImage *_ciimage;
}


@property (assign) double videoCaptureFPS;
@property (assign) int width;
@property (assign) int height;
@property (weak) id videoDelegate;

@property NSString *imagePath;



@property CVPixelBufferRef currentFrame;

@property (weak) CaptureController *settingsController;





-(CVImageBufferRef) getCurrentFrame;

- (BOOL)needsAdvancedVideo;
-(void)chooseDirectory;




@end
