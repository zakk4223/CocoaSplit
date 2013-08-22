//
//  XPCListenerDelegate.m
//  CocoaSplit
//
//  Created by Zakk on 11/10/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "XPCListenerDelegate.h"
#import "QTHelperProtocol.h"
#import <QTKit/QTKit.h>
#import <IOSurface/IOSurfaceAPI.h>

#import <CoreVideo/CoreVideo.h>
#import <QuickTime/QuickTime.h>





@implementation XPCListenerDelegate


@synthesize captureDevice;
@synthesize captureSession;
@synthesize captureInput;
@synthesize captureOutput;
@synthesize xpcProxy;


- (void) dealloc
{
 
    if (self.xpcProxy)
    {
        [self.xpcProxy release];
        
    }
    [super dealloc];

}



- (BOOL) listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    
    NSXPCInterface *helperInterface = [[NSXPCInterface interfaceWithProtocol:@protocol(QTHelperProtocol)] retain];
    NSXPCInterface *masterInterface = [[NSXPCInterface interfaceWithProtocol:@protocol(CapturedFrameProtocol)] retain];
    
    
    [newConnection setExportedInterface:helperInterface];
    [newConnection setExportedObject:self];
    
    [newConnection setRemoteObjectInterface:masterInterface];
    self.xpcProxy = [newConnection remoteObjectProxy];
    [self.xpcProxy retain];
    

    
    [newConnection resume];
    [helperInterface release];
    [masterInterface release];
    return YES;
}

- (void) listCaptureDevices:(void (^)(NSArray *r_devices))reply
{
    NSArray *devices = [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo];
    NSLog(@"DEVICES IN HELPER %@", devices);
    
    NSMutableArray *retArray = [[NSMutableArray alloc] init];
    QTCaptureDevice *devinstance;
    
    for(devinstance in devices)
    {
        [retArray addObject: @{@"name" : [devinstance localizedDisplayName], @"id":devinstance.uniqueID}];
        
        
    }
    
    [devices release];
    reply((NSArray *)retArray);
    [retArray release];
}


- (void) stopXPCCaptureSession
{
    if (self.captureSession)
    {
        [self.captureSession stopRunning];
        [self.captureSession release];
    }
    
    if (self.captureDevice)
    {
        [self.captureDevice close];
        [self.captureDevice release];
    }
    
    if (self.captureInput)
    {
        [self.captureInput release];
    }
    
    if (self.captureOutput)
    {
        [self.captureOutput release];
    }
    
    if (frameQueue)
    {
        dispatch_release(frameQueue);
    }
    
    
}


- (void) startXPCCaptureSession:(NSString *)captureID
{
    frameQueue = dispatch_queue_create("zakk.lol.frameQueue", NULL);
    
    self.captureSession = [[[QTCaptureSession alloc] init] retain];
    self.captureDevice = [[QTCaptureDevice deviceWithUniqueID:captureID] retain];
    [self.captureDevice open:nil];
    self.captureInput = [[[QTCaptureDeviceInput alloc] initWithDevice:self.captureDevice] retain];
    

    NSError *error;
    
    [self.captureSession addInput:self.captureInput error:&error];
    
    self.captureOutput = [[[QTCaptureDecompressedVideoOutput alloc] init] retain];
    

    NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES]
                                                        forKey: (NSString *)kIOSurfaceIsGlobal];
    
    NSMutableDictionary *pbAttrs = [NSMutableDictionary dictionaryWithObject:ioAttrs
                                                                      forKey: (NSString*)kCVPixelBufferIOSurfacePropertiesKey];
    
    [pbAttrs setObject: @[@(kCVPixelFormatType_422YpCbCr8), @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
                forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    [self.captureOutput setPixelBufferAttributes:pbAttrs];
    
    [self.captureOutput setDelegate:self];
    [self.captureSession addOutput:self.captureOutput error:nil];
    
    
    [self.captureSession startRunning];
    
}


- (void) sendFrame:(CVImageBufferRef)newFrame
{
   
   if (newFrame)
   {
       dispatch_semaphore_t reply_s = dispatch_semaphore_create(0);
       IOSurfaceRef frameIOSurface = CVPixelBufferGetIOSurface(newFrame);
       IOSurfaceID frameID = IOSurfaceGetID(frameIOSurface);
       [self.xpcProxy newCapturedFrame:frameID reply:^{
           dispatch_semaphore_signal(reply_s);
       }];
       dispatch_semaphore_wait(reply_s, DISPATCH_TIME_FOREVER);
       
       
       CVPixelBufferRelease(newFrame);
       dispatch_release(reply_s);
   }
    
}
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{

    CVPixelBufferRetain(videoFrame);
    dispatch_async(frameQueue, ^{
        [self sendFrame:videoFrame];
    });
    
    //IOSurfaceIncrementUseCount(frameIORef);
    
    //[self.xpcProxy newCapturedFrame:IOSurfaceCreateXPCObject(frameIORef)];
    //mach_port_deallocate(mach_task_self(), framePort);
    //CVPixelBufferRelease(videoFrame);
    
}


- (void) testMethod
{
    NSLog(@"CALLED TEST METHOD");
    return;
}

@end
