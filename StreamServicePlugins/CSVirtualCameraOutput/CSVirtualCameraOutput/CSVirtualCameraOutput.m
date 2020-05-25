//
//  CSVirtualCameraOutput.m
//  CSVirtualCameraOutput
//
//  Created by Zakk on 5/6/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import "CSVirtualCameraOutput.h"
#import "CSPluginServices.h"

#import <AVFoundation/AVFoundation.h>
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
        self.cameraDevice.deviceUID = self.deviceName;
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
    } else if (self.cameraDevice.isReady) {
        [self.cameraDevice publishCVPixelBufferFrame:useImage];
    }
    
    if (self.audioOutputDevice)
    {
        NSString *audioTrackkey = nil;
        
        if (self.activeAudioTracks && (self.activeAudioTracks.allKeys.count > 0))
        {
            audioTrackkey = self.activeAudioTracks.allKeys.firstObject;
        }
        
        if (!audioTrackkey)
        {
            audioTrackkey = frameData.pcmAudioSamples.allKeys.firstObject;
        }
        
        NSArray *pcmSamples = frameData.pcmAudioSamples[audioTrackkey];
        
        for (id object in pcmSamples)
        {
            
            CMSampleBufferRef audioSample = (__bridge CMSampleBufferRef)object;
            CMFormatDescriptionRef sampleAudioFormat = CMSampleBufferGetFormatDescription(audioSample);

            AVAudioFormat *audioFormat = [[AVAudioFormat alloc] initWithCMAudioFormatDescription:sampleAudioFormat];
            if (!_audioOutput)
            {
                _audioOutput = [CSPluginServices.sharedPluginServices systemAudioOutputForFormat:audioFormat forDevice:self.audioOutputDevice];
                [_audioOutput start];
            }
            
            if (!_audioOutput)
            {
                break;
            }
            
            [_audioOutput playSampleBuffer:audioSample];
        }
    }
    return YES;
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
