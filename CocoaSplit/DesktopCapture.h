//
//  DesktopCapture.h
//  H264Streamer
//
//  Created by Zakk on 9/24/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureSessionProtocol.h"
#import "CaptureController.h"
#import "ControllerProtocol.h"

@interface DesktopCapture : NSObject <CaptureSessionProtocol>
{
    
    dispatch_queue_t _capture_queue;
    CGDisplayStreamRef _displayStreamRef;
    IOSurfaceRef _currentFrame;
    uint64_t _currentFrameTime;
    CGDirectDisplayID _currentDisplay;
    

}



-(bool)providesAudio;
-(bool)providesVideo;
-(NSArray *)availableVideoDevices;
-(void) setVideoDimensions:(int)width height:(int)height;
-(CVImageBufferRef) getCurrentFrame;



@property double videoCaptureFPS;
@property int width;
@property int height;
@property AbstractCaptureDevice *activeVideoDevice;
@property id<ControllerProtocol> videoDelegate;
@property (readonly) NSArray *availableVideoDevices;
@property (readonly) BOOL needsAdvancedVideo;
@property NSArray *videoFormats;
@property NSArray *videoFramerates;





@end
