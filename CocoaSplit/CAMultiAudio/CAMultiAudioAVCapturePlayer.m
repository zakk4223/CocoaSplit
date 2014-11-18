//
//  CAMultiAudioAVCapturePlayer.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioAVCapturePlayer.h"

@implementation CAMultiAudioAVCapturePlayer


-(instancetype)initWithDevice:(AVCaptureDevice *)avDevice sampleRate:(int)sampleRate
{
    if (self = [super init])
    {
        
        self.captureDevice = avDevice;
        self.sampleRate = sampleRate;
        self.name = avDevice.localizedName;
    }
    return self;
}

-(void)setEnabled:(bool)enabled
{
    super.enabled = enabled;
    if (enabled)
    {
        [self attachCaptureSession];
    } else {
        [self detachCaptureSession];
    }
}


-(void)detachCaptureSession
{
    if (self.avfCapture)
    {
        [self.avfCapture stopCaptureSession];
        self.avfCapture = nil;
    }
}

-(void)attachCaptureSession
{
    AVFAudioCapture *newAC = [[AVFAudioCapture alloc] initForAudioEngine:self.captureDevice sampleRate:self.sampleRate];
    self.avfCapture = newAC;
    newAC.multiInput = self;
}


-(void)resetSamplerate:(UInt32)sampleRate
{
    if (self.avfCapture)
    {
        self.avfCapture.audioSamplerate = sampleRate;
    
        [self.avfCapture stopAudioCompression];
        [self.avfCapture setupAudioCompression];
    }
}


-(void)setChannelCount:(int)channelCount
{
    super.channelCount = channelCount;
}

-(int)channelCount
{
    if (self.captureDevice)
    {
        CMFormatDescriptionRef sDescr = self.captureDevice.activeFormat.formatDescription;
        
        
        const AudioStreamBasicDescription *asbd =  CMAudioFormatDescriptionGetStreamBasicDescription(sDescr);

        if (asbd)
        {
            return asbd->mChannelsPerFrame;
        }
    }
    
    return super.channelCount;
}


@end
