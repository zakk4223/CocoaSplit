//
//  CAMultiAudioPCM.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioPCM.h"

@implementation CAMultiAudioPCM


-(instancetype)initWithAudioBufferList:(AudioBufferList *)bufferList streamFormat:(AudioStreamBasicDescription *)streamFormat
{
    if (self = [super init])
    {
        
        _audioSlice = calloc(1, sizeof(ScheduledAudioSlice));
        
        
        _audioSlice->mBufferList = bufferList;
        _audioSlice->mNumberFrames = bufferList->mBuffers[0].mDataByteSize / streamFormat->mBytesPerFrame;
        
        
    }
    
    return self;
}


-(void)dealloc
{
    NSLog(@"FREEING PCM BUFFER!");
    
    //You better not have freed this before
    free(_audioSlice->mBufferList);
    free(_audioSlice);
}



@end
