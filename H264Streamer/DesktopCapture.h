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

@interface DesktopCapture : NSObject <CaptureSessionProtocol>
{
    
    int _width;
    int _height;
    dispatch_queue_t _capture_queue;
    CGDisplayStreamRef _displayStreamRef;
    IOSurfaceRef _currentFrame;
    uint64_t _currentFrameTime;
    
    CGDirectDisplayID _activeVideoDevice;
    
    

}


-(bool)providesAudio;
-(bool)providesVideo;
-(NSArray *)availableVideoDevices;
-(void) setVideoDimensions:(int)width height:(int)height;

@property (strong) id videoDelegate;
@property (assign) int videoCaptureFPS;





@end
