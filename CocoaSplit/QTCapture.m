//
//  QTCapture.m
//  CocoaSplit
//
//  Created by Zakk on 11/6/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "QTCapture.h"
#import "AbstractCaptureDevice.h"
#import "QTHelperProtocol.h"
#import "CapturedFrameProtocol.h"

@implementation QTCapture


-(id) init
{
    self = [super init];
    if (self)
    {
        NSXPCInterface *xpcInterface = [NSXPCInterface interfaceWithProtocol:@protocol(QTHelperProtocol)];
        NSXPCInterface *xpcCallbackInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CapturedFrameProtocol)];
        
        _xpcConnection = [[NSXPCConnection alloc] initWithServiceName:@"zakk.lol.QTCaptureHelper"];
        
        [_xpcConnection setRemoteObjectInterface:xpcInterface];
        [_xpcConnection setExportedInterface:xpcCallbackInterface];
        [_xpcConnection setExportedObject:self];
        
        NSLog(@"SETUP CONNECTION TO LISTENER");
        [_xpcConnection resume];
        _xpcProxy = [_xpcConnection remoteObjectProxy];
        NSLog(@"GOT PROXY OBJECT");
        
        
    }
    return self;
    
}


-(void) setVideoDimensions:(int)width height:(int)height
{
    return;
}


-(bool) providesVideo
{
    return YES;
}

-(bool) providesAudio
{
    return NO;
}





-(bool) setActiveVideoDevice:(AbstractCaptureDevice *)newDev
{
    NSLog(@"SET VIDEO DEVICE TO %@", [newDev uniqueID]);
    _videoInputDevice = [newDev uniqueID];
    return YES;
    
}


-(NSArray *) availableVideoDevices
{
    
    dispatch_semaphore_t reply_s = dispatch_semaphore_create(0);
    
    NSMutableArray *__block retArray;
    NSLog(@"PROXY %@", _xpcProxy);
    NSLog(@"CONNECTION %@", _xpcConnection);
    [_xpcProxy testMethod];
    NSLog(@"CALLED TEST METHOD FROM SPLIT");
    
    [_xpcProxy listCaptureDevices:^(NSArray *r_devices) {
        NSLog(@"REMOTE DEVICES %@", r_devices);
        retArray = [[NSMutableArray alloc] init];
        NSDictionary *devinstance;
        for (devinstance in r_devices)
        {
           [retArray addObject:[[AbstractCaptureDevice alloc]  initWithName:[devinstance valueForKey:@"name"] device:[devinstance valueForKey:@"id"] uniqueID:[devinstance valueForKey:@"id"]]];
        }
        dispatch_semaphore_signal(reply_s);
    }];
    NSLog(@"SEMAPHORE WAIT");
    dispatch_semaphore_wait(reply_s, DISPATCH_TIME_FOREVER);
    reply_s = nil;
    return (NSArray *)retArray;
    
}

-(void) newCapturedFrame:(IOSurfaceID)ioxpc reply:(void (^)())reply
{
    
    IOSurfaceRef  frameIOref = IOSurfaceLookup(ioxpc);
    if (frameIOref)
    {
        
        @synchronized(self) {
            if (_currentFrame)
            {
                IOSurfaceDecrementUseCount(_currentFrame);
                //CFRelease(_currentFrame);
            }
            
            _currentFrame = frameIOref;
            IOSurfaceIncrementUseCount(_currentFrame);
            //CFRetain(_currentFrame);
        }
    
        
    }

    // ALWAYS reply
    reply();
}




-(bool) stopCaptureSession
{
    [_xpcProxy stopXPCCaptureSession];
    return YES;
}


-(bool) startCaptureSession:(NSError **)error
{
    
    NSLog(@"CALLING STARTXPC WITH %@", _videoInputDevice);
    [_xpcProxy startXPCCaptureSession:_videoInputDevice];
    
    return YES;
}


-(bool) setupCaptureSession:(NSError *__autoreleasing *)therror
{
    
    return YES;
    
}

void QTPixelBufferRelease(void *releaseRefCon, const void *baseAddress)
{
    
    if (baseAddress)
        free((void *)baseAddress);
    
    
}

- (CVImageBufferRef) getCurrentFrame
{

    CVImageBufferRef newbuf = NULL;
    
    @synchronized(self)
    {
        if (_currentFrame)
        {
            CVPixelBufferCreateWithIOSurface(NULL, _currentFrame, NULL, &newbuf);
            return newbuf;
            
            
        }
        
    }
    
    return newbuf;
    
    

    
    
}

/*
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    if (connection.output == _video_capture_output)
    {
        CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        
        
        @synchronized(self)
        {
            if (_currentFrame)
            {
                CVPixelBufferRelease(_currentFrame);
            }
            
            CVPixelBufferRetain(videoFrame);
            _currentFrame = videoFrame;
        }
    } else if (connection.output == _audio_capture_output) {
        
        
        [_audioDelegate captureOutputAudio:self didOutputSampleBuffer:sampleBuffer];
    }
    
}
 */

@end
