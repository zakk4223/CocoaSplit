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




-(void)setVideoDimensions:(int)width height:(int)height
{
    return;
}


-(bool)stopCaptureSession
{
    [_syphon_client stop];
    
    return YES;
}

- (CVImageBufferRef) getCurrentFrame
{
    
    CVImageBufferRef newbuf = NULL;
    
    @synchronized(self)
    {
        if (_currentFrame)
        {
            IOSurfaceSetValue(_currentFrame, kCVPixelBufferPixelFormatTypeKey, (__bridge CFTypeRef)(@(kCVPixelFormatType_32BGRA)));
            CVPixelBufferCreateWithIOSurface(NULL, _currentFrame, (__bridge CFDictionaryRef)(@{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_422YpCbCr10)}), &newbuf);
            
            
        }
        
    }
    
    return newbuf;
    
    
}


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
    
    return YES;
    
    
}




-(bool) startCaptureSession:(NSError *__autoreleasing *)error
{
    
    NSLog(@"SERVER IS %@", _syphonServer);
    
    
    _syphon_client = [[SyphonClient alloc] initWithServerDescription:_syphonServer options:nil newFrameHandler:^(SyphonClient *client) {
        IOSurfaceRef frameSurface = [client currentSurfaceRef];
        NSLog(@"IOSURFACE BLAH %d", IOSurfaceGetHeight(frameSurface));
        if (frameSurface)
        {
            CFRetain(frameSurface);
            IOSurfaceIncrementUseCount(frameSurface);
            @synchronized(self) {
                if (_currentFrame)
                {
                    IOSurfaceDecrementUseCount(_currentFrame);
                    CFRelease(_currentFrame);
                }
                
                _currentFrame = frameSurface;
            }

        }
        
    }];
    
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
        
        [retArr addObject:[[AbstractCaptureDevice alloc] initWithName:[sserv objectForKey:SyphonServerDescriptionAppNameKey] device:sserv uniqueID:[sserv objectForKey:SyphonServerDescriptionUUIDKey ]]];
        
    }
    return (NSArray *)retArr;
    
}
@end
