//
//  SyphonCapture.h
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSCaptureBase.h"
#import "CSAbstractCaptureDevice.h"
#import "SyphonBuildMacros.h"
#import "Syphon.h"
#import "CSIOSurfaceLayer.h"
#import "CSSyphonCaptureLayer.h"




@interface SyphonCapture : CSCaptureBase <CSCaptureSourceProtocol>
{
    NSDictionary *_syphonServer;
    SyphonClient *_syphon_client;
    NSString *_syphon_uuid;
    NSString *_resume_name;
    
    NSSize _last_frame_size;
    id _retire_observer;
    id _announce_observer;
    IOSurfaceRef _serverSurface;
    uint32_t _surfaceSeed;
    
    CATransform3D _flipTransform;
}


@property (assign) double videoCaptureFPS;
@property (assign) int width;
@property (assign) int height;
@property (assign) BOOL isFlipped;
@property (readonly) BOOL needsAdvancedVideo;
@property (assign) frame_render_behavior renderType;




-(bool) stopCaptureSession;
-(void) startSyphon;
-(void) commonInit;



@end