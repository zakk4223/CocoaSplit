//
//  CAMultiAudioPCM.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioPCM.h"

@implementation CAMultiAudioPCM



-(instancetype) copyWithZone:(NSZone *)zone
{
    
    CAMultiAudioPCM *newCopy = [[CAMultiAudioPCM allocWithZone:zone] initWithDescription:&_pcmFormat forFrameCount:self.frameCount];
    
    [newCopy copyFromAudioBufferList:_pcmData];
    
    return newCopy;
}


-(instancetype)initWithAudioBufferList:(AudioBufferList *)bufferList streamFormat:(const AudioStreamBasicDescription *)streamFormat
{
    if (self = [super init])
    {
        AVAudioFrameCount numFrames = 0;
        AVAudioFormat *bufferFmt = [[AVAudioFormat alloc] initWithStreamDescription:streamFormat];
        numFrames = bufferList->mBuffers[0].mDataByteSize / streamFormat->mBytesPerFrame;
        
        self.avBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:bufferFmt frameCapacity:numFrames];
        for (uint32_t i = 0; i < bufferList->mNumberBuffers; i++)
        {
            memcpy(self.avBuffer.mutableAudioBufferList->mBuffers[i].mData, bufferList->mBuffers[i].mData, self.avBuffer.mutableAudioBufferList->mBuffers[i].mDataByteSize);
        }
    }
    
    return self;
}



-(void)copyFromAudioBufferList:(AudioBufferList *)copyFrom
{
    //Just copy the data, we already allocated the List.
    if (!self.avBuffer)
    {
        return;
    }
    for (int i=0; i < self.avBuffer.audioBufferList->mNumberBuffers; i++)
    {
        memcpy(self.avBuffer.mutableAudioBufferList->mBuffers[i].mData, copyFrom->mBuffers[i].mData, self.avBuffer.mutableAudioBufferList->mBuffers[i].mDataByteSize);
    }
}


-(instancetype)initWithDescription:(const AudioStreamBasicDescription *)streamFormat forFrameCount:(int)forFrameCount
{
    
    if (self = [super init])
    {
        AVAudioFormat *fmt = [[AVAudioFormat alloc] initWithStreamDescription:streamFormat];
        self.avBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:fmt frameCapacity:forFrameCount];
        self.avBuffer.frameLength = forFrameCount;

    }
    
    
    
    return self;
}


-(void)dealloc
{
    if (_alloced_buffers || self.handleFreeBuffer)
    {
        /*
        for (int i=0; i < self.bufferCount; i++)
        {
            free(_audioSlice->mBufferList->mBuffers[i].mData);
        }*/
        free(_audioSlice->mBufferList);
        free(_dataBuffer);
        
    }
    free(_audioSlice);
}



@end
