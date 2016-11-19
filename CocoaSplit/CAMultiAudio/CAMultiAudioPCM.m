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
        
        _audioSlice = calloc(1, sizeof(ScheduledAudioSlice));
        
        _audioSlice->mBufferList = bufferList;
        _audioSlice->mNumberFrames = bufferList->mBuffers[0].mDataByteSize / streamFormat->mBytesPerFrame;
        self.frameCount = _audioSlice->mNumberFrames;
        
        self.bufferCount = streamFormat->mChannelsPerFrame;
        _alloced_buffers = NO;
        
    }
    
    return self;
}



-(void)copyFromAudioBufferList:(AudioBufferList *)copyFrom
{
    //Just copy the data, we already allocated the List.
    
    for (int i=0; i < _pcmData->mNumberBuffers; i++)
    {
        memcpy(_pcmData->mBuffers[i].mData, copyFrom->mBuffers[i].mData, _audioBufferDataSize);
    }
}


-(instancetype)initWithDescription:(const AudioStreamBasicDescription *)streamFormat forFrameCount:(int)forFrameCount
{
    
    if (self = [super init])
    {
        _audioSlice = calloc(1, sizeof(ScheduledAudioSlice));
        _audioSlice->mNumberFrames = forFrameCount;
        _audioSlice->mBufferList = NULL;
        
        
        int bufferCnt = streamFormat->mFormatFlags & kAudioFormatFlagIsNonInterleaved ? streamFormat->mChannelsPerFrame : 1;
        int channelCnt = streamFormat->mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : streamFormat->mChannelsPerFrame;
        
        self.bufferCount = bufferCnt;
        self.frameCount = forFrameCount;
        
        long byteCnt = streamFormat->mBytesPerFrame * forFrameCount;
        
        _audioBufferListSize = sizeof(AudioBufferList) + (bufferCnt-1)*sizeof(AudioBuffer);
        _audioBufferDataSize = byteCnt;
        
        _pcmData = malloc(_audioBufferListSize);
        
        
        _pcmData->mNumberBuffers = bufferCnt;
        
        for (int i=0; i<bufferCnt; i++)
        {
            if (byteCnt > 0)
            {
                _pcmData->mBuffers[i].mData = malloc(_audioBufferDataSize);
                
            }
            _pcmData->mBuffers[i].mDataByteSize = (UInt32)_audioBufferDataSize;
            _pcmData->mBuffers[i].mNumberChannels = channelCnt;
        }
        _audioSlice->mBufferList = _pcmData;
        memcpy(&_pcmFormat, streamFormat, sizeof(AudioStreamBasicDescription));
        _alloced_buffers = YES;
    }
    
    
    
    return self;
}


-(void)dealloc
{
    if (_alloced_buffers || self.handleFreeBuffer)
    {
        for (int i=0; i < self.bufferCount; i++)
        {
            free(_audioSlice->mBufferList->mBuffers[i].mData);
        }
        free(_audioSlice->mBufferList);
    }
    free(_audioSlice);
}



@end
