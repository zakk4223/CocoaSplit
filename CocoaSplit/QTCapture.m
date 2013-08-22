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

@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize availableVideoDevices = _availableVideoDevices;


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
        
        [_xpcConnection resume];
        _xpcProxy = [_xpcConnection remoteObjectProxy];
        [self updateAvailableVideoDevices];
        
        
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



/*
-(NSString *) activeVideoDevice
{
    return _activeVideoDevice;
}



-(void) setActiveVideoDevice:(AbstractCaptureDevice *)newDev
{
    _activeVideoDevice = [newDev uniqueID];
}

 */

-(void) updateAvailableVideoDevices
{
    
    
    
    NSMutableArray *__block retArray;
    [_xpcProxy testMethod];
    
    [_xpcProxy listCaptureDevices:^(NSArray *r_devices) {
        retArray = [[NSMutableArray alloc] init];
        NSDictionary *devinstance;
        for (devinstance in r_devices)
        {
           [retArray addObject:[[AbstractCaptureDevice alloc]  initWithName:[devinstance valueForKey:@"name"] device:[devinstance valueForKey:@"id"] uniqueID:[devinstance valueForKey:@"id"]]];
        }
        [self willChangeValueForKey:@"availableVideoDevices"];
        _availableVideoDevices = (NSArray *)retArray;
        [self didChangeValueForKey:@"availableVideoDevices"];
        //dispatch_semaphore_signal(reply_s);
    }];
    /*
    NSLog(@"SEMAPHORE WAIT");
    dispatch_semaphore_wait(reply_s, DISPATCH_TIME_FOREVER);
    NSLog(@"NO LONGER WAITING ON SEMAPHORE");
    reply_s = nil;
    return (NSArray *)retArray;
 */   
}

-(void) newCapturedFrame:(IOSurfaceID)ioxpc reply:(void (^)())reply
{
    
    IOSurfaceRef  frameIOref = IOSurfaceLookup(ioxpc);

    IOSurfaceIncrementUseCount(frameIOref);
    
    if (frameIOref)
    {
        @synchronized(self)
        {
            if (_currentFrame)
            {
                IOSurfaceDecrementUseCount(_currentFrame);

                CFRelease(_currentFrame);
            }
            
            _currentFrame = frameIOref;
        }
    }
    /*
    if (self.videoDelegate && frameIOref)
    {
        CVPixelBufferCreateWithIOSurface(NULL, frameIOref, NULL, &tmpbuf);
        if (tmpbuf)
        {
            [self.videoDelegate captureOutputVideo:nil didOutputSampleBuffer:nil didOutputImage:tmpbuf frameTime:0 ];
            CVPixelBufferRelease(tmpbuf);
        }

    }
     */
    //ALWAYS REPLY
    reply();
}




-(bool) stopCaptureSession
{
    [_xpcProxy stopXPCCaptureSession];
    return YES;
}


-(bool) startCaptureSession:(NSError **)error
{
    
    [_xpcProxy startXPCCaptureSession:self.activeVideoDevice.uniqueID];
    
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
