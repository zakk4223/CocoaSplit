//
//  CSVirtualCameraDevice.h
//  CSVirtualCamera
//
//  Created by Zakk on 5/6/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <IOSurface/IOSurfaceObjC.h>

NS_ASSUME_NONNULL_BEGIN


@protocol CSVirtualCameraProtocol
-(void)publishNewFrame:(NSString *)deviceUUID withIOSurface:(IOSurface *)ioSurface;
-(void)createDevice:(NSString *)name withUID:(NSString *)uid withModel:(NSString *)modelName withManufacturer:(NSString *)manufacturer width:(NSUInteger)width height:(NSUInteger)height pixelFormat:(OSType)pixelFormat frameRate:(float) frameRate withReply:(void (^)(NSString *))reply;
-(void)destroyDevice:(NSString *)uuid;
-(void)setInternalClock:(bool)useClock forDevice:(NSString *)deviceUUID;
-(void)setPersistOnDisconnect:(bool)persist forDevice:(NSString *)deviceUUID;

@end


@interface CSVirtualCameraDevice : NSObject
{
    NSXPCConnection *_XPCconnection;
    id<CSVirtualCameraProtocol> _assistant;
    
}


@property (strong) NSString *name;
@property (strong) NSString *deviceUID;
@property (strong) NSString *modelName;
@property (strong) NSString *manufacturer;
@property (assign) float frameRate;
@property (assign) UInt32 width;
@property (assign) UInt32 height;
@property (assign) OSType pixelFormat;
@property (assign) bool isReady;
@property (assign) bool useInternalClock;
@property (assign) bool persistOnDisconnect;

-(void)createDeviceWithCompletionBlock:(void (^)(void))completionBlock;
-(void)destroyDevice;
-(void)publishCVPixelBufferFrame:(CVPixelBufferRef)videoFrame;
-(void)publishIOSurfaceFrame:(IOSurface *)videoFrame;

@end

NS_ASSUME_NONNULL_END
