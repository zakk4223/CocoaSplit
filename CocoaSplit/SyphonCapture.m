//
//  SyphonCapture.m
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "SyphonCapture.h"
#import "AbstractCaptureDevice.h"
#import <OpenGL/OpenGL.h>


@implementation SyphonCapture




@synthesize activeVideoDevice = _activeVideoDevice;




-(AbstractCaptureDevice *)activeVideoDevice
{
    return _activeVideoDevice;
}

-(void)setActiveVideoDevice:(AbstractCaptureDevice *)activeVideoDevice
{
    _activeVideoDevice = activeVideoDevice;
    [self startSyphon];
}



-(void) setVideoDimensions:(int)width height:(int)height
{
    self.width = width;
    self.height = height;
    
}


-(bool)stopCaptureSession
{
    [_syphon_client stop];
    
    return YES;
}



-(bool) createPixelBufferPoolForSize:(NSSize) size
{
    
    NSLog(@"SyphonCapture: Creating Pixel Buffer Pool %f x %f", size.width, size.height);
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setValue:[NSNumber numberWithInt:size.width] forKey:(NSString *)kCVPixelBufferWidthKey];
    [attributes setValue:[NSNumber numberWithInt:size.height] forKey:(NSString *)kCVPixelBufferHeightKey];
    [attributes setValue:@{(NSString *)kIOSurfaceIsGlobal: @YES} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    [attributes setValue:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    
    
    if (_pixel_buffer_pool)
    {
        CVPixelBufferPoolRelease(_pixel_buffer_pool);
    }
    
    
    
    CVReturn result = CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)(attributes), &_pixel_buffer_pool);
    
    if (result != kCVReturnSuccess)
    {
        return NO;
    }
    
    return YES;

    
}

-(id) init
{
    
    if (self = [super init])
    {
        NSOpenGLPixelFormatAttribute glAttributes[] = {
            
            NSOpenGLPFAPixelBuffer,
            NSOpenGLPFANoRecovery,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFADepthSize, 32,
            (NSOpenGLPixelFormatAttribute) 0
            
        };
        NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:glAttributes];
        
        if (!pixelFormat)
        {
            return NO;
        }
        
        _ogl_ctx = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
        
        if (!_ogl_ctx)
        {
            return NO;
        }
        
        CVReturn result;
        
        result = CVOpenGLTextureCacheCreate(kCFAllocatorDefault, NULL, [_ogl_ctx CGLContextObj], CGLGetPixelFormat([_ogl_ctx CGLContextObj]), NULL, &_texture_cache);
        
        if (result != kCVReturnSuccess)
        {
            return NO;
        }
        
    }
    return self;
}




-(CVImageBufferRef)getCurrentFrame
{
    
    return [self renderNewFrame:_syphon_client];
}



-(CVPixelBufferRef)renderNewFrame:(SyphonClient *)client
{
    
    CGLContextObj cgl_ctx = [_ogl_ctx CGLContextObj];
    [_ogl_ctx makeCurrentContext];
    NSSize frameSize;
    
    if (cgl_ctx == nil)
    {
        return NULL;
    }
    GLuint frametexture;
    
    CGLLockContext(cgl_ctx);
    SyphonImage *syphon_frame = [client newFrameImageForContext:cgl_ctx];
    frametexture = [syphon_frame textureName];
    frameSize = [syphon_frame textureSize];

    BOOL returnNow = NO;
    
    
    if (frameSize.width == 0.0f || frameSize.height == 0.0f)
    {
        returnNow = YES;
        
    } else if  ((_last_frame_size.width != frameSize.width) || (_last_frame_size.height != frameSize.height)) {
    
        BOOL pixelBufferPoolOK = [self createPixelBufferPoolForSize:frameSize];
        
        if (pixelBufferPoolOK != YES)
        {

            returnNow = YES;
        }
        
        _last_frame_size.width = frameSize.width;
        _last_frame_size.height = frameSize.height;
    }
    
    
    if (returnNow)
    {
        
        [NSOpenGLContext clearCurrentContext];
        CGLUnlockContext(cgl_ctx);
        return NULL;
    }
    
    
    if (!_framebuffer)
    {
        glGenFramebuffers(1, &_framebuffer);
        
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    CVOpenGLTextureRef textureOut;
    CVPixelBufferRef bufferOut;
    
    CVPixelBufferPoolCreatePixelBuffer(NULL, _pixel_buffer_pool, &bufferOut);
    if (!bufferOut)
    {
        return NULL;
    }
    
    
    
    CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _texture_cache, bufferOut, NULL, &textureOut);
    

    glEnable(CVOpenGLTextureGetTarget(textureOut));
    
    glActiveTexture(GL_TEXTURE0);
    
    
    glBindTexture(CVOpenGLTextureGetTarget(textureOut), CVOpenGLTextureGetName(textureOut));
    glTexParameterf(CVOpenGLTextureGetTarget(textureOut), GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(CVOpenGLTextureGetTarget(textureOut), GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glDisable(GL_DEPTH_TEST);
    glDisable(CVOpenGLTextureGetTarget(textureOut));
    glDepthMask(GL_FALSE);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLTextureGetTarget(textureOut), CVOpenGLTextureGetName(textureOut), 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"FRAMEBUFFER IS NOT COMPLETE %d", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NULL;
    }
    
    
    glBindTexture(CVOpenGLTextureGetTarget(textureOut), 0);
    
    double angle = 0.15f;
    
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glClearColor (1.0f, 0.0f, 0.0f, 0.5f);
    glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);            // Clear Screen And Depth Buffer on the fbo to red
    glLoadIdentity ();                                              // Reset The Modelview Matrix
    glTranslatef (0.0f, 0.0f, -6.0f);                               // Translate 6 Units Into The Screen and then rotate
    glRotatef(angle,0.0f,1.0f,0.0f);
    glRotatef(angle,1.0f,0.0f,0.0f);
    glRotatef(angle,0.0f,0.0f,1.0f);
    glColor3f(1,1,0);                                               // set color to yellow
    
    
    
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, frameSize.width, frameSize.height);
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0.0, frameSize.width, 0.0, frameSize.height, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, frametexture);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    
    glDisable(GL_BLEND);
    
    
    GLfloat text_coords[] =
    {
        0.0, 0.0,
        frameSize.width, 0.0,
        frameSize.width, frameSize.height,
        0.0, frameSize.height
    };
    
    float halfw = frameSize.width * 0.5;
    float halfh = frameSize.height * 0.5;
    
    
    GLfloat verts[] =
    {
        -halfw, halfh,
        halfw, halfh,
        halfw, -halfh,
        -halfw, -halfh
    };
    
    glTranslated(frameSize.width * 0.5, frameSize.height * 0.5, 0.0);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, text_coords);
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, verts);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    
    glEnd();
    glFlush();

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLTextureGetTarget(textureOut), 0, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    CVOpenGLTextureRelease(textureOut);

    
    [NSOpenGLContext clearCurrentContext];
    CGLUnlockContext(cgl_ctx);
    
    //[self.videoDelegate captureOutputVideo:nil didOutputSampleBuffer:nil didOutputImage:bufferOut frameTime:0 ];
    
    //CVPixelBufferRelease(bufferOut);
    CVOpenGLTextureCacheFlush(_texture_cache, 0);
    syphon_frame = nil;
    return bufferOut;
    
    
}

-(void) startSyphon
{
    
    
    
    if (_syphon_client)
    {
        [_syphon_client stop];
        _syphon_client = nil;
    }
    
    
    _syphonServer = [self.activeVideoDevice captureDevice];
    
    if (_syphonServer)
    {
        NSLog(@"STARTING SYPHON");
        _syphon_client = [[SyphonClient alloc] initWithServerDescription:_syphonServer options:nil newFrameHandler:nil];
    }
    
    
    /*
    _syphon_client = [[SyphonClient alloc] initWithServerDescription:_syphonServer options:nil newFrameHandler:^(SyphonClient *client) {
        [self renderNewFrame:client];
    }];
     */
}





-(bool)providesAudio
{
    return NO;
}

-(bool)providesVideo
{
    return YES;
}

-(NSArray *)availableVideoDevices
{
     
    NSArray *servers = [[SyphonServerDirectory sharedDirectory] servers];
    NSMutableArray *retArr = [[NSMutableArray alloc] init];
    id sserv;
    
    for(sserv in servers)
    {
        
        NSLog(@"Syphon UUID %@", [sserv objectForKey:SyphonServerDescriptionUUIDKey ]);
        
        [retArr addObject:[[AbstractCaptureDevice alloc] initWithName:[sserv objectForKey:SyphonServerDescriptionAppNameKey] device:sserv uniqueID:[sserv objectForKey:SyphonServerDescriptionUUIDKey ]]];
        
    }
    return (NSArray *)retArr;
    
}
@end
