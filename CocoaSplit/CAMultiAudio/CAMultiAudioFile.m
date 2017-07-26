//
//  CAMultiAudioFile.m
//  CocoaSplit
//
//  Created by Zakk on 7/23/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioFile.h"

@implementation CAMultiAudioFile

@synthesize outputFormat = _outputFormat;
@synthesize currentTime = _currentTime;

-(instancetype)initWithPath:(NSString *)path
{
    if (self = [self init])
    {
        self.filePath = path;
        self.nodeUID = path;
        _outputSampleRate = 0.0f;
        _lastStartFrame = 0;
        
        if (self.filePath)
        {
            self.name = [self.filePath lastPathComponent];
        }
        [self openAudioFile];
    }
    
    return self;
}


-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_AudioFilePlayer unitType:kAudioUnitType_Generator])
    {
    }
    
    return self;
}

-(void)setVolume:(float)volume
{
    super.volume = volume;
    
    
    if (self.converterNode)
    {
        
        [(CAMultiAudioNode *)self.converterNode setVolumeOnConnectedNode];
    }
}


-(Float64)currentTime
{
    return _currentTime;
}

-(void)setCurrentTime:(Float64)currentTime
{
    AudioTimeStamp auTime;
    
    bool is_playing = self.playing;
    
    _currentTime = currentTime;
    Float64 sampleTime = currentTime * _outputSampleRate;
    [self stop];
    _lastStartFrame = sampleTime;
    [self createAudioPlayer];
    if (is_playing)
    {
        [self play];
    }
    
}


-(void)updatePowerlevel
{
    [super updatePowerlevel];
    AudioTimeStamp currentTime;
    UInt32 asbdSize = sizeof(_outputSampleRate);
    
    UInt32 timeSize = sizeof(currentTime);
    
    if (self.playing)
    {
        AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_CurrentPlayTime, kAudioUnitScope_Global, 0, &currentTime, &timeSize);
        
        Float64 realTime = (currentTime.mSampleTime+_lastStartFrame) / (_outputSampleRate);
        if (realTime > self.duration)
        {
            [self completed];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self willChangeValueForKey:@"currentTime"];
            _currentTime = realTime;
            [self didChangeValueForKey:@"currentTime"];
            
        });
    }
}


-(void)openAudioFile
{
    if (self.filePath)
    {
        CFURLRef audioURL = CFURLCreateWithFileSystemPath(NULL, (__bridge CFStringRef)self.filePath, kCFURLPOSIXPathStyle, false);
        OSStatus err;
        UInt32 absdSize = sizeof(AudioStreamBasicDescription);
        UInt32 durationSize = sizeof(Float64);
        Float64 fileDuration;
        UInt64 pktCnt;
        UInt32 pktSize = sizeof(UInt64);
        
        if (!_outputFormat)
        {
            _outputFormat = malloc(sizeof(AudioStreamBasicDescription));
        }
        err = AudioFileOpenURL(audioURL, kAudioFileReadPermission, 0, &_audioFile);
        err = AudioFileGetProperty(_audioFile, kAudioFilePropertyDataFormat, &absdSize, _outputFormat);
        AudioFileGetProperty(_audioFile, kAudioFilePropertyEstimatedDuration, &durationSize, &fileDuration);
        AudioFileGetProperty(_audioFile, kAudioFilePropertyAudioDataPacketCount, &pktSize, &pktCnt);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.duration = fileDuration;
        });
        
    }
}

-(void)completed
{
    [self stop];
}

-(void)createAudioPlayer
{
    
    if (!self.filePath)
    {
        return;
    }
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduledFileIDs, kAudioUnitScope_Global, 0, &_audioFile, sizeof(_audioFile));
    ScheduledAudioFileRegion fileRegion;
    fileRegion.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    fileRegion.mTimeStamp.mSampleTime = 0;
    fileRegion.mCompletionProc = NULL;
    fileRegion.mCompletionProcUserData = NULL;
    fileRegion.mAudioFile = _audioFile;
    fileRegion.mLoopCount = 0;
    fileRegion.mStartFrame = _lastStartFrame * (_outputFormat->mSampleRate/_outputSampleRate);
    fileRegion.mFramesToPlay = -1;
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &fileRegion, sizeof(fileRegion));
    UInt32 primeFrames = 0;
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduledFilePrime,
                         kAudioUnitScope_Global, 0, &primeFrames, sizeof(primeFrames));
    
}


-(void)play
{
    AudioTimeStamp startTime;
    startTime.mFlags = kAudioTimeStampSampleTimeValid;
    startTime.mSampleTime = -1;
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduleStartTimeStamp,
                         kAudioUnitScope_Global, 0, &startTime, sizeof(startTime));
    self.playing = YES;

}


-(void)stop
{
    AudioUnitReset(self.audioUnit, kAudioUnitScope_Global, 0);
    self.playing = NO;
}


-(void)setEnabled:(bool)enabled
{
    super.enabled = enabled;
    if (enabled)
    {
        [self createAudioPlayer];
        [self play];
    } else {
        [self stop];
    }
}

-(void)setInputStreamFormat:(AudioStreamBasicDescription *)format
{
    return;
}

-(void)setOutputStreamFormat:(AudioStreamBasicDescription *)format
{
    _outputSampleRate = format->mSampleRate;
    return;
}


@end
