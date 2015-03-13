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
    CGDirectDisplayID _currentDisplay;
    
    AVCaptureSession *_capture_session;
    AVCaptureScreenInput *_screen_input;
    AVCaptureVideoDataOutput *_capture_output;
    
    

}



-(bool)providesAudio;
-(bool)providesVideo;
-(NSArray *)availableVideoDevices;



@property (assign) double videoCaptureFPS;
@property (assign) float scaleFactor;
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
@property (assign) frame_render_behavior renderType;
@property (assign) bool showClicks;





@end
