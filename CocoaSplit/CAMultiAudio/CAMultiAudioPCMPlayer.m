//
//  CAMultiAudioPCMPlayer.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioPCMPlayer.h"
#import <AVFoundation/AVFoundation.h>



@implementation CAMultiAudioPCMPlayer


void BufferCompletedPlaying(void *userData, ScheduledAudioSlice *bufferList);


-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_ScheduledSoundPlayer unitType:kAudioUnitType_Generator])
    {
        _pendingBuffers = [NSMutableArray array];
        _pendingQueue = dispatch_queue_create("PCM Player pending queue", NULL);
        
        self.latestScheduledTime = 0;
    }
    
    return self;
}

-(void)scheduleAudioBuffer:(AudioBufferList *)bufferList bufferFormat:(AudioStreamBasicDescription)bufferFormat
{
    //Assuming 32 bit non-interleaved float.
    
    CAMultiAudioPCM *pcmBuffer = [[CAMultiAudioPCM alloc] initWithAudioBufferList:bufferList streamFormat:&bufferFormat];
    
    [self playPcmBuffer:pcmBuffer];
}


-(bool)playPcmBuffer:(CAMultiAudioPCM *)pcmBuffer
{
    
    
    
    OSStatus err;
    //Under 10.10 this means PLAY NEXT. Need to figure out everything that's not 10.10 :(
    
    
    AudioTimeStamp currentTimeStamp = {0};
    UInt32 ctsSize = sizeof(currentTimeStamp);
    
    Float64 playAtTime = 0;
    
    pcmBuffer.audioSlice->mFlags = 0;
    pcmBuffer.audioSlice->mCompletionProcUserData = (__bridge void *)(pcmBuffer);
    pcmBuffer.audioSlice->mCompletionProc = BufferCompletedPlaying;
    pcmBuffer.player = self;
    
    if (!self.enabled)
    {
        return YES;
    }
    
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9)
    {
        //Before 10.10 this was a bit more involved...
        AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_CurrentPlayTime, kAudioUnitScope_Global, 0, &currentTimeStamp, &ctsSize);
        
        if (self.latestScheduledTime == 0)
        {
            playAtTime = 0;
        } else {
            playAtTime = self.latestScheduledTime;
        }
        
        if (currentTimeStamp.mSampleTime > self.latestScheduledTime)
        {
            
            self.latestScheduledTime = playAtTime = 0;
        }
        pcmBuffer.audioSlice->mTimeStamp.mSampleTime = playAtTime;
        pcmBuffer.audioSlice->mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        
        if (playAtTime == 0)
        {
            [self play];
        }
        self.latestScheduledTime += pcmBuffer.frameCount;
    } else {
        //In 10.10 mFlags = 0 says 'play as soon as you can, but don't interrupt anything currently playing'
        pcmBuffer.audioSlice->mTimeStamp.mSampleTime = 0;
        pcmBuffer.audioSlice->mTimeStamp.mFlags = 0;

    }
    

    err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduleAudioSlice, kAudioUnitScope_Global, 0, pcmBuffer.audioSlice, sizeof(ScheduledAudioSlice));
    

    
    dispatch_async(_pendingQueue, ^{
        
        [_pendingBuffers addObject:pcmBuffer];
    });
    

    
    
    
    //NSLog(@"SCHED SLICE %d", err);
    
    return YES;
}

-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    
    //NSLog(@"THE BUFFER %@", sampleBuffer);
    
    //credit to TheAmazingAudioEngine for an illustration of proper audiobufferlist allocation. Google leads to some really really bad allocation code...

    AudioBufferList *sampleABL;
    
    CMFormatDescriptionRef sDescr = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *asbd =  CMAudioFormatDescriptionGetStreamBasicDescription(sDescr);
    
    int bufferCnt = asbd->mFormatFlags & kAudioFormatFlagIsNonInterleaved ? asbd->mChannelsPerFrame : 1;
    int channelCnt = asbd->mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : asbd->mChannelsPerFrame;
    CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);

    long byteCnt = asbd->mBytesPerFrame * numSamples;
    
    sampleABL = malloc(sizeof(AudioBufferList) + (bufferCnt-1)*sizeof(AudioBuffer));
    
    
    sampleABL->mNumberBuffers = bufferCnt;
    
    //NSLog(@"BUFFERCNT %d CHANNELCNT %d, SAMPLES %ld, BYTES/FRAME %d", bufferCnt, channelCnt, numSamples, asbd->mBytesPerFrame);
    
    for (int i=0; i<bufferCnt; i++)
    {
        if (byteCnt > 0)
        {
            sampleABL->mBuffers[i].mData = malloc(byteCnt);
            
        }
        sampleABL->mBuffers[i].mDataByteSize = (UInt32)byteCnt;
        sampleABL->mBuffers[i].mNumberChannels = channelCnt;
    }
    
    
    CMSampleBufferCopyPCMDataIntoAudioBufferList(sampleBuffer, 0, (int32_t)numSamples, sampleABL);
    CAMultiAudioPCM *pcmBuffer = [[CAMultiAudioPCM alloc] initWithAudioBufferList:sampleABL streamFormat:asbd];

    
    
    [self playPcmBuffer:pcmBuffer];
}

-(void)releasePCM:(CAMultiAudioPCM *)buffer
{
    dispatch_async(_pendingQueue, ^{
        [_pendingBuffers removeObject:buffer];
    });
}



-(bool)createNode:(AUGraph)forGraph
{
    bool ret = [super createNode:forGraph];
    if (floor(NSAppKitVersionNumber > NSAppKitVersionNumber10_9))
    {
        
        //We can start whenever on 10.10. Anything not 10.10 we have to start/restart at specific times in the schedule function.
        [self play];

    }

    return ret;
}


-(void)play
{
    AudioTimeStamp ts = {0};
    
    OSStatus err;
    

    
    ts.mFlags = kAudioTimeStampSampleTimeValid;
    ts.mSampleTime = -1;
    err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0, &ts, sizeof(ts));
    
    
    
        
    //NSLog(@"PLAYER INPUT rate %f, %d channels, %d bits per channel", asbd.mSampleRate, asbd.mChannelsPerFrame, asbd.mBitsPerChannel);
    
    
    //NSLog(@"SCHEDULE START %d", err);
    
    
}
@end


void BufferCompletedPlaying(void *userData, ScheduledAudioSlice *bufferList)
{
    //NSLog(@"BUFFER COMPLETED PLAYING!!!! COMP %d BEGAN %d LATE %d", bufferList->mFlags & kScheduledAudioSliceFlag_Complete, bufferList->mFlags & kScheduledAudioSliceFlag_BeganToRender, bufferList->mFlags & kScheduledAudioSliceFlag_BeganToRenderLate);
    
    
    CAMultiAudioPCM *pcmObj = (__bridge CAMultiAudioPCM *)(userData);
    //maybe put this on a dedicated queue?
    //why a queue? don't want to do any sort of memory/managed object operations in an audio callback.
    dispatch_async(dispatch_get_main_queue(), ^{
        CAMultiAudioPCMPlayer *pplayer = pcmObj.player;
        //pplayer.latestScheduledTime = pcmObj.audioSlice->mTimeStamp.mSampleTime + pcmObj.audioSlice->mNumberFrames;
        [pplayer releasePCM:pcmObj];
    });
    
    
}