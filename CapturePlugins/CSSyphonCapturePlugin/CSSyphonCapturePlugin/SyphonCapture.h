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




@interface SyphonCapture : CSCaptureBase <CSCaptureSourceProtocol>
{
    NSDictionary *_syphonServer;
    SyphonClient *_syphon_client;
    NSString *_syphon_uuid;
    NSString *_resume_name;
    
    NSOpenGLContext *_ogl_ctx;
    NSSize _last_frame_size;
    CVOpenGLTextureCacheRef _texture_cache;
    CVPixelBufferPoolRef _pixel_buffer_pool;
    GLuint _framebuffer;
    id _retire_observer;
    id _announce_observer;
    CVPixelBufferRef _currentFrame;
    IOSurfaceRef _serverSurface;
    uint32_t _surfaceSeed;
    
    CIFilter *_flipTransform;
}



@property (assign) double videoCaptureFPS;
@property (assign) int width;
@property (assign) int height;
@property (assign) BOOL isFlipped;
@property (readonly) BOOL needsAdvancedVideo;



-(bool) stopCaptureSession;

@end