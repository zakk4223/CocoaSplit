//
//  DesktopCapture.h
//  H264Streamer
//
//  Created by Zakk on 9/24/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSCaptureBase.h"
#import "CSAbstractCaptureDevice.h"


@interface DesktopCapture : CSCaptureBase <CSCaptureSourceProtocol>
{
    
    dispatch_queue_t _capture_queue;
    CGDisplayStreamRef _displayStreamRef;
    IOSurfaceRef _currentFrame;
    uint64_t _currentFrameTime;
    CGDirectDisplayID _currentDisplay;
    CIImage *_currentImg;
    CFAbsoluteTime _lastFrame;
    

}



-(bool)providesAudio;
-(bool)providesVideo;
-(NSArray *)availableVideoDevices;



@property (assign) double videoCaptureFPS;
@property (assign) int width;
@property (assign) int height;
@property (assign) int x_origin;
@property (assign) int y_origin;
@property (assign) int region_width;
@property (assign) int region_height;
@property (assign) BOOL showCursor;
@property (readonly) BOOL needsAdvancedVideo;
@property NSArray *videoFormats;
@property NSArray *videoFramerates;
@property (assign) bool propertiesChanged;
@property (assign) CGDirectDisplayID currentDisplay;





@end
