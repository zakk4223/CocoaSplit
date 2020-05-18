//
//  CSVirtualCameraOutput.m
//  CSVirtualCameraOutput
//
//  Created by Zakk on 5/6/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import "CSVirtualCameraOutput.h"

@implementation CSVirtualCameraOutput



-(bool)queueFramedata:(CapturedFrameData *)frameData
{
    
    CVPixelBufferRef useImage = CMSampleBufferGetImageBuffer(frameData.encodedSampleBuffer);
    if (!useImage)
    {
        return NO;
    }
    if (!self.cameraDevice)
    {
        self.cameraDevice = [[CSVirtualCameraDevice alloc] init];
        self.cameraDevice.name = self.deviceName;
        
        self.cameraDevice.persistOnDisconnect = self.persistDevice;
        self.cameraDevice.deviceUID = self.cameraDevice.name;
        self.cameraDevice.frameRate = 1.0f/CMTimeGetSeconds(frameData.videoDuration);
        self.cameraDevice.width = CVPixelBufferGetWidth(useImage);
        self.cameraDevice.height = CVPixelBufferGetHeight(useImage);
        if (self.pixelFormat)
        {
            self.cameraDevice.pixelFormat = self.pixelFormat.intValue;
        } else {
            self.cameraDevice.pixelFormat = kCVPixelFormatType_32BGRA;
        }
        
        [self.cameraDevice createDeviceWithCompletionBlock:nil];
        return NO; //We'll start next frame or so
    } else if (self.cameraDevice.isReady) {
        [self.cameraDevice publishCVPixelBufferFrame:useImage];
        return YES;
    }
    
    return NO;
}

-(void)dealloc
{
    if (self.cameraDevice)
    {
        if (!self.cameraDevice.persistOnDisconnect)
        {
            [self.cameraDevice destroyDevice];
        }
    }
}
@end
