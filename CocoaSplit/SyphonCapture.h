//
//  SyphonCapture.h
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Syphon/Syphon.h>
#import "CaptureSessionProtocol.h"
#import "ControllerProtocol.h"

@interface SyphonCapture : NSObject < CaptureSessionProtocol>
{
    NSDictionary *_syphonServer;
    SyphonClient *_syphon_client;
    NSOpenGLContext *_ogl_ctx;
    NSSize _last_frame_size;
    CVOpenGLTextureCacheRef _texture_cache;
    CVPixelBufferPoolRef _pixel_buffer_pool;
    GLuint _framebuffer;
    
    
}



@property int videoCaptureFPS;
@property int width;
@property int height;
@property AbstractCaptureDevice *activeVideoDevice;
@property id<ControllerProtocol> videoDelegate;
@property (readonly) NSArray *availableVideoDevices;
@property (readonly) BOOL needsAdvancedVideo;



-(bool) stopCaptureSession;
-(bool) startCaptureSession:(NSError **)error;
-(bool) providesVideo;
-(bool) providesAudio;
-(bool) setupCaptureSession:(NSError **)therror;
-(void) setVideoDimensions:(int)width height:(int)height;

@end
