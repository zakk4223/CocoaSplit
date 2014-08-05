//
//  DesktopCapture.h
//  H264Streamer
//
//  Created by Zakk on 9/24/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureBase.h"

@interface DesktopCapture : CaptureBase <CaptureSessionProtocol>
{
    
    dispatch_queue_t _capture_queue;
    CGDisplayStreamRef _displayStreamRef;
    IOSurfaceRef _currentFrame;
    uint64_t _currentFrameTime;
    CGDirectDisplayID _currentDisplay;
    CIImage *_currentImg;

}



-(bool)providesAudio;
-(bool)providesVideo;
-(NSArray *)availableVideoDevices;



@property (assign) double videoCaptureFPS;
@property (assign) int width;
@property (assign) int height;
@property (assign) BOOL showCursor;
@property (readonly) BOOL needsAdvancedVideo;
@property NSArray *videoFormats;
@property NSArray *videoFramerates;
@property (assign) bool propertiesChanged;




@end
