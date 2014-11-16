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
        
        
        AVFAudioCapture *newAC = [[AVFAudioCapture alloc] initForAudioEngine:avDevice sampleRate:sampleRate];
         self.avfCapture = newAC;
         newAC.multiInput = self;
        self.name = newAC.name;
        
    }
    return self;
}

-(void)setChannelCount:(int)channelCount
{
    super.channelCount = channelCount;
}

-(int)channelCount
{
    if (self.avfCapture)
    {
        CMFormatDescriptionRef sDescr = self.avfCapture.activeAudioDevice.activeFormat.formatDescription;
        
        
        const AudioStreamBasicDescription *asbd =  CMAudioFormatDescriptionGetStreamBasicDescription(sDescr);

        return asbd->mChannelsPerFrame;
    }
    
    return super.channelCount;
}


@end
