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
    if (self = [super initWithSubType:kAudioUnitSubType_ScheduledSoundPlayer unitType:kAudioUnitType_Generator])
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
    const AudioStreamBasicDescription *asbd =  CMAudioFormatDescriptionGetStreamBasicDescription(sDescr);
    
    
    int bufferCnt = asbd->mFormatFlags & kAudioFormatFlagIsNonInterleaved ? asbd->mChannelsPerFrame : 1;
    int channelCnt = asbd->mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : asbd->mChannelsPerFrame;
    CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);

    long byteCnt = asbd->mBytesPerFrame * numSamples;
    
    sampleABL = malloc(sizeof(AudioBufferList) + (bufferCnt-1)*sizeof(AudioBuffer));
    
    
    sampleABL->mNumberBuffers = bufferCnt;
    uint8_t *dataBuf = malloc(bufferCnt*byteCnt);
    
    for (int i=0; i<bufferCnt; i++)
    {
        /*
        if (byteCnt > 0)
        {
            sampleABL->mBuffers[i].mData = malloc(byteCnt);
            
        }*/
        
        sampleABL->mBuffers[i].mData = dataBuf+(byteCnt*i);
        
        sampleABL->mBuffers[i].mDataByteSize = (UInt32)byteCnt;
        sampleABL->mBuffers[i].mNumberChannels = channelCnt;
    }
    
    
    CMSampleBufferCopyPCMDataIntoAudioBufferList(sampleBuffer, 0, (int32_t)numSamples, sampleABL);
    CAMultiAudioPCM *pcmBuffer = [[CAMultiAudioPCM alloc] initWithAudioBufferList:sampleABL streamFormat:asbd];
    pcmBuffer.dataBuffer = dataBuf;
    

    pcmBuffer.handleFreeBuffer = YES;
    
    

    
    [self playPcmBuffer:pcmBuffer];
}

-(void)releasePCM:(CAMultiAudioPCM *)buffer
{
    /*
    @synchronized (self) {
        [self->_pendingBuffers removeObject:buffer];

    }
    
    @autoreleasepool {
    */
    
    //dispatch_async(_pendingQueue, ^{
    @synchronized(self)
    {
        [self->_pendingBuffers removeObject:buffer];
    }
    
   // });
/*    }*/
}



-(bool)createNode:(CAMultiAudioGraph *)forGraph
{
    bool ret = [super createNode:forGraph];
    if (floor(NSAppKitVersionNumber > NSAppKitVersionNumber10_9))
    {
        
        //We can start whenever on 10.10. Anything not 10.10 we have to start/restart at specific times in the schedule function.
        [self play];

    }

    return ret;
}


-(void)setInputFormat:(AudioStreamBasicDescription *)inputFormat
{
    if (inputFormat)
    {
        if (!_inputFormat)
        {
            _inputFormat = malloc(sizeof(AudioStreamBasicDescription));
        }
        
        memcpy(_inputFormat, inputFormat, sizeof(AudioStreamBasicDescription));
    } else {
        inputFormat = NULL;
    }
}

-(AudioStreamBasicDescription *)inputFormat
{
    return _inputFormat;
}

-(bool)setInputStreamFormat:(AudioStreamBasicDescription *)format
{
    return YES;
}

-(bool)setOutputStreamFormat:(AudioStreamBasicDescription *)format
{
    if (self.inputFormat)
    {
        return [super setOutputStreamFormat:self.inputFormat];
    }
    
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


-(void)dealloc
{
    
    [self flush];
    _pendingBuffers = nil;
    if (_inputFormat)
    {
        free(_inputFormat);
    }
}


@end



