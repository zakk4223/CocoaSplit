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
    if (!_cameraDevice)
    {
        _cameraDevice = [[CSVirtualCameraDevice alloc] init];
        _cameraDevice.deviceUID = @"CocoaSplit Test Output";
        _cameraDevice.frameRate = 60.0f;
        _cameraDevice.width = CVPixelBufferGetWidth(useImage);
        _cameraDevice.height = CVPixelBufferGetHeight(useImage);
        _cameraDevice.name = @"CocoaSplit Test Output";
        _cameraDevice.pixelFormat = CVPixelBufferGetPixelFormatType(useImage);
        [_cameraDevice createDeviceWithCompletionBlock:^{
            _cameraDevice.persistOnDisconnect = NO;
        }];
        return NO; //We'll start next frame or so
    } else if (_cameraDevice.isReady) {
        [_cameraDevice publishCVPixelBufferFrame:useImage];
        return YES;
    }
    
    return NO;
}
@end
