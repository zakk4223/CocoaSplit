//
//  CAMultiAudioPCMPlayer.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//

#import "CAMultiAudioPCMPlayer.h"
#import "CAMultiAudioDownmixer.h"

#import <AVFoundation/AVFoundation.h>

@interface CAMultiAudioPCM()
-(void)createAudioSlice;
@end


@implementation CAMultiAudioPCMPlayer

-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_ScheduledSoundPlayer unitType:kAudioUnitType_Generator])
    {
        _pendingBuffers = [NSMutableArray array];
        _pauseBuffer = [[NSMutableArray alloc] init];
        self.enabled = YES;
        _exitPending = NO;
        
    }
    return self;
}

-(NSUInteger)pendingFrames
{
    return _pendingBuffers.count;
}

-(void)setEnabled:(bool)enabled
{
    [super setEnabled:enabled];
    if (enabled)
    {
        [self setMuted:NO];
    } else {
        [self setMuted:YES];
    }
}


-(void)startPendingProcessor
{
    
    if (!_pendingTimer)
    {
        _pendingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
        if (_pendingTimer)
        {
            dispatch_source_set_timer(_pendingTimer, dispatch_time(DISPATCH_TIME_NOW, 0.10*NSEC_PER_SEC), 0.10*NSEC_PER_SEC, 0.5*NSEC_PER_SEC);
            dispatch_source_set_event_handler(_pendingTimer, ^{
                @autoreleasepool {
                     NSArray *pendingCopy;
                     
                     @synchronized(self) {
                         pendingCopy = [self->_pendingBuffers copy];
                     }
                     

                     
                     for (CAMultiAudioPCM *pcmObj in pendingCopy)
                     {

                         if ((pcmObj.audioSlice)->mFlags & kScheduledAudioSliceFlag_Complete)
                         {
                             
                             if (self.save_buffer)
                             {
                                 [self.pauseBuffer addObject:pcmObj];
                             }
                             [self releasePCM:pcmObj];
                         }
                     }
                 }
            });
            dispatch_resume(_pendingTimer);
        }
                                               
    }


}

-(bool)playPcmBuffer:(CAMultiAudioPCM *)pcmBuffer
{
    
    if (_exitPending)
    {
        return NO;
    }
    
    
    if (!_pendingTimer)
    {
        [self startPendingProcessor];
    }
    

    OSStatus err;
    //Under 10.10 this means PLAY NEXT. Need to figure out everything that's not 10.10 :(
    
    [pcmBuffer createAudioSlice];
    pcmBuffer.audioSlice->mFlags = 0;
    pcmBuffer.audioSlice->mTimeStamp.mSampleTime = 0;
    pcmBuffer.audioSlice->mTimeStamp.mFlags = 0;
    

    err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduleAudioSlice, kAudioUnitScope_Global, 0, pcmBuffer.audioSlice, sizeof(ScheduledAudioSlice));
    //dispatch_async(_pendingQueue, ^{
    
    @synchronized(self)
    {
        [self->_pendingBuffers addObject:pcmBuffer];
    }
    
    return YES;
}

-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CMFormatDescriptionRef sDescr = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
    
    AVAudioFormat *avFmt = [[AVAudioFormat alloc] initWithCMAudioFormatDescription:sDescr];
    
    
    CAMultiAudioPCM *pcmBuffer = [[CAMultiAudioPCM alloc] initWithPCMFormat:avFmt frameCapacity:(unsigned int)numSamples];
    pcmBuffer.frameLength = (unsigned int)numSamples;

    CMSampleBufferCopyPCMDataIntoAudioBufferList(sampleBuffer, 0, (int32_t)numSamples, pcmBuffer.mutableAudioBufferList);
    [self playPcmBuffer:pcmBuffer];
}

-(void)releasePCM:(CAMultiAudioPCM *)buffer
{
    @autoreleasepool {
    
    @synchronized(self)
    {
        [self->_pendingBuffers removeObject:buffer];
    }
  }
}



-(bool)setInputStreamFormat:(AVAudioFormat *)format bus:(UInt32)bus
{
    return YES;
}


-(bool)setOutputStreamFormat:(AVAudioFormat *)format bus:(UInt32)bus
{
    AudioUnitUninitialize(self.audioUnit);
    bool ret = [super setOutputStreamFormat:format bus:bus];
    AudioUnitInitialize(self.audioUnit);
    [self play];
    return ret;
}



-(void)pause
{
    
    self.save_buffer = YES;
    [self flush];
}


-(void)flush
{
    if (self.audioUnit)
    {
        AudioUnitReset(self.audioUnit, kAudioUnitScope_Global, 0);
    }
}


-(void)play
{
    AudioTimeStamp ts = {0};
    
    OSStatus err;
    

 
    
    ts.mFlags = kAudioTimeStampSampleTimeValid;
    ts.mSampleTime = -1;
    err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0, &ts, sizeof(ts));
    _save_buffer = NO;
    for (CAMultiAudioPCM *buffer in self.pauseBuffer)
    {
        [self playPcmBuffer:buffer];
    }
    
    [self.pauseBuffer removeAllObjects];
}

-(void)drainPendingBuffers
{
    @synchronized (self) {
        [_pendingBuffers removeAllObjects];
    }
}
-(void)didRemoveInput
{
    if (_pendingTimer)
    {
        dispatch_source_cancel(_pendingTimer);
    }
    [self drainPendingBuffers];
}


-(void)dealloc
{
    
    [self flush];
    if (_pendingTimer)
    {
        dispatch_source_cancel(_pendingTimer);
    }
    _pendingTimer = nil;
    _pendingBuffers = nil;

}


@end



