//
//  SyphonCapture.m
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "SyphonCapture.h"
#import "AbstractCaptureDevice.h"

@implementation SyphonCapture

-(void) setVideoCaptureFPS:(int)fps
{
    _captureFPS = fps;
}

-(void) setVideoDelegate:(id)delegate
{
    _delegate = delegate;
    
}

-(bool) setActiveVideoDevice:(id)videoDevice
{
    
    _syphonServer = [videoDevice captureDevice];
    return YES;
}

-(bool) setupCaptureSession:(NSError *__autoreleasing *)therror
{
    
    const NSOpenGLPixelFormatAttribute attr[] = {NSOpenGLPFANoRecovery, NSOpenGLPFAAccelerated, NSOpenGLPFADoubleBuffer, 0};
    
    NSOpenGLPixelFormat* fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
    _cgl_ctx = [[NSOpenGLContext alloc] initWithFormat:fmt shareContext:nil];
    

    return YES;
    
    
}

-(bool) startCaptureSession:(NSError *__autoreleasing *)error
{
    
    NSLog(@"SERVER IS %@", _syphonServer);
    
    
    _syphon_client = [[SyphonClient alloc] initWithServerDescription:_syphonServer options:nil newFrameHandler:^(SyphonClient *client) {
        [_cgl_ctx makeCurrentContext];
        CGLContextObj cgl_ctx = [_cgl_ctx CGLContextObj];

        SyphonImage *myFrame = [client newFrameImageForContext:cgl_ctx];
        CVPixelBufferRef pbuff;
        int buf_size;
        
        buf_size = myFrame.textureSize.height * myFrame.textureSize.width;
        
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, myFrame.textureName);
        

        
        GLuint *buffer = malloc(buf_size*4);

        
        glGetTexImage(GL_TEXTURE_RECTANGLE_ARB, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, buffer);
         
        CVPixelBufferCreateWithBytes(NULL, myFrame.textureSize.width, myFrame.textureSize.height, kCVPixelFormatType_32BGRA, buffer, myFrame.textureSize.width*4, NULL, 0, NULL, &pbuff);
        
        [_delegate captureOutputVideo:self didOutputSampleBuffer:nil didOutputImage:pbuff frameTime:0];
        //CVPixelBufferRelease(pbuff);
        
      
    
    } ];
       return YES;
    
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
    
    NSLog(@"SERVERS %@", servers);
    for(sserv in servers)
    {
        //[retArr addObject:[[AbstractCaptureDevice alloc] initWithName:[sserv objectForKey:SyphonServerDescriptionAppNameKey] device:sserv]];
        
    }
    return (NSArray *)retArr;
    
}
@end
