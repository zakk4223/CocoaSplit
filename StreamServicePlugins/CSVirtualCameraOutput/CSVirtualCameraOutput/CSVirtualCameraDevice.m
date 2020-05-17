//
//  CSVirtualCameraDevice.m
//  CSVirtualCamera
//
//  Created by Zakk on 5/6/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import "CSVirtualCameraDevice.h"

@implementation CSVirtualCameraDevice

@synthesize useInternalClock = _useInternalClock;
@synthesize persistOnDisconnect = _persistOnDisconnect;


-(void)connectToAssistant
{
    NSXPCInterface *assistantInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CSVirtualCameraProtocol)];
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.cocoasplit.vcam.assistant" options:0];
    [connection setRemoteObjectInterface:assistantInterface];
    [connection resume];
    _assistant = [connection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Could not connect to remote Assistant");
    }];
    _XPCconnection = connection;
}


-(void)setPersistOnDisconnect:(bool)persist
{
    _persistOnDisconnect = persist;
    if (_assistant)
    {
        [_assistant setPersistOnDisconnect:persist forDevice:self.deviceUID];
    }
}

-(bool)persistOnDisconnect
{
    return _persistOnDisconnect;
}



-(void)setUseInternalClock:(bool)useClock
{
    _useInternalClock = useClock;
    if (_assistant)
    {
        [_assistant setInternalClock:useClock forDevice:self.deviceUID];
    }
}

-(bool)useInternalClock
{
    return _useInternalClock;
}

-(void)createDeviceWithCompletionBlock:(void (^)(void))completionBlock
{
    if (!_assistant)
    {
        [self connectToAssistant];
    }
    
    
    [_assistant createDevice:self.name withUID:self.deviceUID withModel:self.modelName withManufacturer:self.manufacturer width:self.width height:self.height pixelFormat:self.pixelFormat frameRate:self.frameRate withReply:^(NSString * _Nonnull uid) {
        self.isReady = YES;
        [_assistant setInternalClock:self.useInternalClock forDevice:self.deviceUID];
        [_assistant setPersistOnDisconnect:self.persistOnDisconnect forDevice:self.deviceUID];
       if (completionBlock)
       {
           completionBlock();
       }
    }];
}


-(void)destroyDevice
{
    [_assistant destroyDevice:self.deviceUID];
}


-(void)publishCVPixelBufferFrame:(CVPixelBufferRef)videoFrame
{
    if (!_assistant)
    {
        return;
    }
    
    IOSurface *bufferSurface = (__bridge IOSurface *)(CVPixelBufferGetIOSurface(videoFrame));
    
    if (bufferSurface)
    {
        [self publishIOSurfaceFrame:bufferSurface];
    } else {
        NSMutableDictionary *ioProperties = [NSMutableDictionary dictionary];
        ioProperties[(id)kCVPixelBufferIOSurfacePropertiesKey] = @{};
        CVPixelBufferRef newPixelBuffer = NULL;
        CVPixelBufferCreate(kCFAllocatorDefault, CVPixelBufferGetWidth(videoFrame), CVPixelBufferGetHeight(videoFrame), CVPixelBufferGetPixelFormatType(videoFrame), (__bridge CFDictionaryRef _Nullable)(ioProperties), &newPixelBuffer);

        
        NSUInteger planeCnt = CVPixelBufferGetPlaneCount(videoFrame);
        CVPixelBufferLockBaseAddress(videoFrame, kCVPixelBufferLock_ReadOnly);
        CVPixelBufferLockBaseAddress(newPixelBuffer, 0);
        if (!planeCnt)
        {

            void *srcAddr = CVPixelBufferGetBaseAddress(videoFrame);
            void *dstAddr = CVPixelBufferGetBaseAddress(newPixelBuffer);
            memcpy(dstAddr, srcAddr, CVPixelBufferGetDataSize(videoFrame));
        } else {

            for(NSUInteger i = 0; i < planeCnt; i++)
            {

                void *srcAddr = CVPixelBufferGetBaseAddressOfPlane(videoFrame, i);
                void *dstAddr = CVPixelBufferGetBaseAddressOfPlane(newPixelBuffer, i);
                memcpy(dstAddr, srcAddr, CVPixelBufferGetBytesPerRowOfPlane(videoFrame, i) * CVPixelBufferGetWidthOfPlane(videoFrame, i));
                
            }
        }
        CVPixelBufferUnlockBaseAddress(newPixelBuffer, 0);
        CVPixelBufferUnlockBaseAddress(videoFrame, kCVPixelBufferLock_ReadOnly);
        [self publishIOSurfaceFrame:(__bridge IOSurface *)CVPixelBufferGetIOSurface(newPixelBuffer)];
        CVPixelBufferRelease(newPixelBuffer);
    }
}


-(void)publishIOSurfaceFrame:(IOSurface *)videoFrame
{
    if (!_assistant)
    {
        return;
    }
    [_assistant publishNewFrame:self.deviceUID withIOSurface:videoFrame];
}

-(void)dealloc
{
    
}
@end



