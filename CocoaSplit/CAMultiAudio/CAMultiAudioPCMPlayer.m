//
//  CAMultiAudioPCMPlayer.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//

#import "CAMultiAudioPCMPlayer.h"
#import "CAMultiAudioDownmixer.h"

#import <AVFoundation/AVFoundation.h>



@implementation CAMultiAudioPCMPlayer

@synthesize inputFormat = _inputFormat;



-(instancetype)init
{
    AVAudioPlayerNode *pNode = [[AVAudioPlayerNode alloc] init];
    pNode.volume = 1.0f;
    if (self = [self initWithAudioNode:pNode])
    {
        _pendingBuffers = [NSMutableArray array];
        //_pendingQueue = dispatch_queue_create("PCM Player pending queue", NULL);
        _bufcnt = 0;
        _inputFormat = NULL;
        self.latestScheduledTime = 0;
        _pauseBuffer = [[NSMutableArray alloc] init];
        self.enabled = NO;
        _exitPending = NO;
        
    }
    return self;
}

-(void)scheduleAudioBuffer:(AudioBufferList *)bufferList bufferFormat:(AudioStreamBasicDescription)bufferFormat
{
    //Assuming 32 bit non-interleaved float.
    
    CAMultiAudioPCM *pcmBuffer = [[CAMultiAudioPCM alloc] initWithAudioBufferList:bufferList streamFormat:&bufferFormat];
    
    [self playPcmBuffer:pcmBuffer];
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
    if (!_pendingQueue)
    {
        _pendingQueue = dispatch_queue_create("PCM Player pending queue", NULL);
    }
    
    
    dispatch_async(_pendingQueue, ^{
        
        while (1)
        {
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
            
            @synchronized(self)
            {
                if (self->_exitPending)
                {
                    return;
                }
            }
            usleep(20000);
        }
    });
}


-(void)didRemoveInput
{
    @synchronized(self)
    {
        _exitPending = YES;
    }
}


-(bool)playPcmBuffer:(CAMultiAudioPCM *)pcmBuffer
{
    
    if (_exitPending)
    {
        return NO;
    }
    
    AVAudioPlayerNode *pNode = (AVAudioPlayerNode *)self.avAudioNode;
    if (!pNode.engine)
    {
        return NO;
    }
    
    if (!pNode.engine.running)
    {
        return NO;
    }
    

    if (!pNode.playing)
    {
        [self play];
    }
    
    
    if (!_audioConverter)
    {
        AVAudioFormat *newFmt = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:pcmBuffer.avBuffer.format.sampleRate channels:pcmBuffer.avBuffer.format.channelCount];
        _audioConverter = [[AVAudioConverter alloc] initFromFormat:pcmBuffer.avBuffer.format toFormat:newFmt];
    }
    
    AVAudioPCMBuffer *newBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_audioConverter.outputFormat frameCapacity:pcmBuffer.avBuffer.frameCapacity];
    newBuffer.frameLength = pcmBuffer.avBuffer.frameCapacity;
    NSError *wtf = nil;
    [_audioConverter convertToBuffer:newBuffer fromBuffer:pcmBuffer.avBuffer error:&wtf];

    [((AVAudioPlayerNode *)self.avAudioNode) scheduleBuffer:newBuffer completionHandler:^{
        //NSLog(@"DONE PLAYING BUFFER!");
    }];
    
    return YES;
    if (!_pendingQueue)
    {
        [self startPendingProcessor];
    }
    
    OSStatus err;
    //Under 10.10 this means PLAY NEXT. Need to figure out everything that's not 10.10 :(
    
    
    AudioTimeStamp currentTimeStamp = {0};
    UInt32 ctsSize = sizeof(currentTimeStamp);
    
    Float64 playAtTime = 0;
    
    pcmBuffer.audioSlice->mFlags = 0;
 
    pcmBuffer.player = self;
    
    
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
    //dispatch_async(_pendingQueue, ^{
    
    @synchronized(self)
    {
        [self->_pendingBuffers addObject:pcmBuffer];
    }
    
   // });
    

    
    
    
    
    return YES;
}





-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    
    //credit to TheAmazingAudioEngine for an illustration of proper audiobufferlist allocation. Google leads to some really really bad allocation code...

    AudioBufferList *sampleABL;
    
    
    CMFormatDescriptionRef sDescr = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
    
    const AudioStreamBasicDescription *asbd =  CMAudioFormatDescriptionGetStreamBasicDescription(sDescr);
    
    CAMultiAudioPCM *pcmBuffer = [[CAMultiAudioPCM alloc] initWithDescription:asbd forFrameCount:numSamples];
    CMSampleBufferCopyPCMDataIntoAudioBufferList(sampleBuffer, 0, (int32_t)numSamples, pcmBuffer.avBuffer.mutableAudioBufferList);
    [self playPcmBuffer:pcmBuffer];
}

-(void)releasePCM:(CAMultiAudioPCM *)buffer
{
    @autoreleasepool {
    
    //dispatch_async(_pendingQueue, ^{
    @synchronized(self)
    {
        [self->_pendingBuffers removeObject:buffer];
    }
    
   // });
  }
}

/*
-(void)didAttachNode
{
    [self play];
}
*/




-(bool)setInputStreamFormat:(AudioStreamBasicDescription *)format
{
    return YES;
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
    
    if (self.avAudioNode)
    {
        AVAudioPlayerNode *pNode = self.avAudioNode;
        [pNode play];
    }
}


-(void)dealloc
{
    
    [self flush];
    _pendingBuffers = nil;

}


@end



