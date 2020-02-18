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




-(instancetype)initWithAudioFormat:(AVAudioFormat *)format
{
    if (self = [self init])
    {
        if (format)
        {
            _audioFormat = format;
        }
    }
    
    return self;
}


-(instancetype)init
{
    AVAudioPlayerNode *pNode = [[AVAudioPlayerNode alloc] init];
    pNode.volume = 1.0f;
    if (self = [self initWithAudioNode:pNode])
    {
        _pendingBuffers = [NSMutableArray array];
        _dataSeen = NO; //Assume we need a converter until proven otherwise.
        //_pendingQueue = dispatch_queue_create("PCM Player pending queue", NULL);
        _bufcnt = 0;
        self.latestScheduledTime = 0;
        _pauseBuffer = [[NSMutableArray alloc] init];
        self.enabled = NO;
        _exitPending = NO;
        _audioFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
    }
    return self;
}

-(void)scheduleAudioBuffer:(AudioBufferList *)bufferList bufferFormat:(AudioStreamBasicDescription)bufferFormat
{
    //Assuming 32 bit non-interleaved float.
    
    CAMultiAudioPCM *pcmBuffer = [[CAMultiAudioPCM alloc] initWithAudioBufferList:bufferList streamFormat:&bufferFormat];
    
    [self playPcmBuffer:pcmBuffer];
}


-(bool)isPlaying
{
    AVAudioPlayerNode *pNode = (AVAudioPlayerNode *)self.avAudioNode;
    if (!pNode)
    {
        return NO;
    }
    
    return pNode.playing;
}


-(AVAudioFormat *)inputFormat
{
    return _audioFormat;
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


-(void)rebuildEffectChain
{

    bool isPlaying = self.isPlaying;
    if (isPlaying)
    {
        [self pause];
    }
    [super rebuildEffectChain];
    if (isPlaying)
    {
        [self play];
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
    
    if (!self.isPlaying)
    {
        return NO;
    }
    
    
    if (!_audioConverter && !_dataSeen)
    {
        AVAudioFormat *newFmt = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:pcmBuffer.avBuffer.format.sampleRate channels:pcmBuffer.avBuffer.format.channelCount];
        if (![newFmt isEqual:pcmBuffer.avBuffer.format])
        {
            _audioConverter = [[AVAudioConverter alloc] initFromFormat:pcmBuffer.avBuffer.format toFormat:newFmt];
        }
        _dataSeen = YES;
    }
    
    AVAudioPCMBuffer *newBuffer = pcmBuffer.avBuffer;
    if (_audioConverter)
    {
        newBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_audioConverter.outputFormat frameCapacity:pcmBuffer.avBuffer.frameCapacity];
        newBuffer.frameLength = pcmBuffer.avBuffer.frameCapacity;
        [_audioConverter convertToBuffer:newBuffer fromBuffer:pcmBuffer.avBuffer error:nil];
    }

    [((AVAudioPlayerNode *)self.avAudioNode) scheduleBuffer:newBuffer completionHandler:^{
        //NSLog(@"DONE PLAYING BUFFER!");
    }];
    
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
     if (self.avAudioNode)
    {
        AVAudioPlayerNode *pNode = (AVAudioPlayerNode *)self.avAudioNode;
        [pNode pause];
    }
}


-(void)stop
{
     if (self.avAudioNode)
    {
        AVAudioPlayerNode *pNode = (AVAudioPlayerNode *)self.avAudioNode;
        [pNode stop];
    }
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
        AVAudioPlayerNode *pNode = (AVAudioPlayerNode *)self.avAudioNode;
        [pNode play];
    }
}


-(void)engineDidStart
{
    
    [super engineDidStart];
    bool ppending;
    
    @synchronized (self) {
        ppending = _playPending;
    }
    
    if (ppending)
    {
        [self play];
    }
    
    @synchronized (self) {
        ppending = NO;
    }
}


-(void)didAttachInput
{
    [super didAttachInput];
    
    AVAudioPlayerNode *pNode = (AVAudioPlayerNode *)self.avAudioNode;
    if (!pNode.engine || !pNode.engine.running)
    {
        
        @synchronized (self) {
            _playPending = YES;
        }
        return;
    }

    
    if (!self.isPlaying)
    {
        [self play];
    }
}
-(void)dealloc
{
    
    [self flush];
    _pendingBuffers = nil;

}


@end



