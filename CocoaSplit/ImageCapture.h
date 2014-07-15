//
//  ImageCapture.h
//  CocoaSplit
//
//  Created by Zakk on 12/27/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureSessionProtocol.h"


@interface ImageCapture : NSObject <CaptureSessionProtocol>
{
    
    NSArray *_sourceList;
    NSMutableArray *_delayList;
    CGImageSourceRef _imageSource;
    size_t _totalFrames;
    int _frameNumber;
    dispatch_queue_t _animationQueue;
    NSMutableArray *_imageCache;
    
}


@property double videoCaptureFPS;
@property int width;
@property int height;
@property AbstractCaptureDevice *activeVideoDevice;
@property (weak) id videoDelegate;
@property (readonly) NSArray *availableVideoDevices;
@property (readonly) BOOL needsAdvancedVideo;

@property NSString *imageDirectory;


@property NSImage *currentImage;

@property CVPixelBufferRef currentFrame;

@property (weak) id<ControllerProtocol> settingsController;





-(CVImageBufferRef) getCurrentFrame;

- (BOOL)needsAdvancedVideo;
-(void)chooseDirectory:(id)sender;




@end
