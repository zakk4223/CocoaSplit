//
//  CAMultiAudioPCM.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioPCM.h"
#import <AVFoundation/AVFoundation.h>

@implementation CAMultiAudioPCM



-(instancetype) copyWithZone:(NSZone *)zone
{
    CAMultiAudioPCM *newCopy = [super copyWithZone:zone];
    newCopy.audioSlice = self.audioSlice;
    return newCopy;
}



-(void)copyFromAudioBufferList:(AudioBufferList *)copyFrom
{
    //Just copy the data, we already allocated the List.
    
    const AudioBufferList *myData = self.audioBufferList;
    for (int i=0; i < myData->mNumberBuffers; i++)
    {
        memcpy(myData->mBuffers[i].mData, copyFrom->mBuffers[i].mData, myData->mBuffers[i].mDataByteSize);
    }
}


-(instancetype)initWithDescription:(const AudioStreamBasicDescription *)streamFormat forFrameCount:(int)forFrameCount
{
    
    AVAudioChannelLayout *chanLayout = [AVAudioChannelLayout layoutWithLayoutTag:kAudioChannelLayoutTag_DiscreteInOrder | streamFormat->mChannelsPerFrame];
    AVAudioFormat *avFmt = [[AVAudioFormat alloc] initWithStreamDescription:streamFormat channelLayout:chanLayout];
    if (self = [super initWithPCMFormat:avFmt frameCapacity:forFrameCount])
    {
        self.frameLength = forFrameCount;
    }
    return self;
}


-(void)createAudioSlice
{
    _audioSlice = calloc(1, sizeof(ScheduledAudioSlice));
    _audioSlice->mNumberFrames = self.frameLength;
    _audioSlice->mBufferList = self.mutableAudioBufferList;
}


-(void)dealloc
{
    
    if (_audioSlice)
    {
        free(_audioSlice);
    }
}



@end
