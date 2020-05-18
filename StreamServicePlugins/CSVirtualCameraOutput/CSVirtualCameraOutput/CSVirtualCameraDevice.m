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


-(void)createPixelBufferPool
{

        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        [attributes setValue:[NSNumber numberWithInt:self.width] forKey:(NSString *)kCVPixelBufferWidthKey];
        [attributes setValue:[NSNumber numberWithInt:self.height] forKey:(NSString *)kCVPixelBufferHeightKey];
        [attributes setValue:@{} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
        [attributes setValue:[NSNumber numberWithUnsignedInt:self.pixelFormat] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)(attributes), &_pixelBufferPool);
}
 

-(void)publishCVPixelBufferFrame:(CVPixelBufferRef)videoFrame
{
    if (!_assistant)
    {
        return;
    }
    
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(videoFrame);
    CVPixelBufferRef outputBuffer = NULL;
    
    IOSurface *bufferSurface = (__bridge IOSurface *)(CVPixelBufferGetIOSurface(videoFrame));
    
    if (pixelFormat != self.pixelFormat || !bufferSurface)
    {
        //We have to copy and/or convert
        if (!_pixelBufferPool)
        {
            [self createPixelBufferPool];
        }
        
        if (!_transferSession)
        {
            VTPixelTransferSessionCreate(NULL, &_transferSession);
        }
        

        CVPixelBufferPoolCreatePixelBuffer(NULL, _pixelBufferPool, &outputBuffer);
        VTPixelTransferSessionTransferImage(_transferSession, videoFrame, outputBuffer);
        bufferSurface = (__bridge IOSurface *)(CVPixelBufferGetIOSurface(outputBuffer));
        
    }
    if (bufferSurface)
    {
        [self publishIOSurfaceFrame:bufferSurface];
    }

    if (outputBuffer)
    {
        CVPixelBufferRelease(outputBuffer);
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



