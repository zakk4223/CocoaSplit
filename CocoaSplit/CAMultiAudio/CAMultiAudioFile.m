//
//  CAMultiAudioFile.m
//  CocoaSplit
//
//  Created by Zakk on 7/23/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioFile.h"
#import "CoreAudio/HostTime.h"

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
        self.refCount = 0;
        
        if (self.filePath)
        {
            self.name = [self.filePath lastPathComponent];
        }
        if (![self openAudioFile])
        {
            return nil;
        }
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

-(void)saveDataToDict:(NSMutableDictionary *)saveDict
{
    [super saveDataToDict:saveDict];
    saveDict[@"filePath"] = self.filePath;
    saveDict[@"currentTime"] = [NSNumber numberWithFloat:self.currentTime];
    saveDict[@"currentSampletime"] = [NSNumber numberWithFloat:self.currentTime*_outputSampleRate];
}


-(void)restoreDataFromDict:(NSDictionary *)restoreDict
{
    [super restoreDataFromDict:restoreDict];
    self.filePath = restoreDict[@"filePath"];
    self.currentTime = [restoreDict[@"currentTime"] floatValue];
    _lastStartFrame = [restoreDict[@"currentSampletime"] floatValue];
}



-(Float64)currentTime
{
    return _currentTime;
}

-(void)setCurrentTime:(Float64)currentTime
{
    
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
    
    
    UInt32 timeSize = sizeof(currentTime);
    
    if (self.playing)
    {
        
        AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_CurrentPlayTime, kAudioUnitScope_Global, 0, &currentTime, &timeSize);
        
        
              
        Float64 realTime = (currentTime.mSampleTime+_lastStartFrame) / (_outputSampleRate);
        if (self.loop)
        {
            realTime = fmod(realTime, self.duration);
        }
        
        if ((realTime > self.duration) && !self.loop)
        {
            [self completed];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self willChangeValueForKey:@"currentTime"];
            self->_currentTime = realTime;
            [self didChangeValueForKey:@"currentTime"];
            
        });
    }
}



+(Float64)durationForPath:(NSString *)path
{
    OSStatus err;
    
    if (!path)
    {
        return 0.0f;
    }
    
    
    CFURLRef audioURL = CFURLCreateWithFileSystemPath(NULL, (__bridge CFStringRef)path, kCFURLPOSIXPathStyle, false);
    UInt32 durationSize = sizeof(Float64);
    AudioFileID audioFile;
    Float64 duration;
    
    err = AudioFileOpenURL(audioURL, kAudioFileReadPermission, 0, &audioFile);
    CFRelease(audioURL);
    
    if (err != noErr)
    {
        return 0.0f;
    }
    
    err = AudioFileGetProperty(audioFile, kAudioFilePropertyEstimatedDuration, &durationSize, &duration);
    AudioFileClose(audioFile);

    if (err != noErr)
    {
        return 0.0f;
    }
    
    
    return duration;
}



-(bool)openAudioFile
{
    if (self.filePath)
    {
        CFURLRef audioURL = CFURLCreateWithFileSystemPath(NULL, (__bridge CFStringRef)self.filePath, kCFURLPOSIXPathStyle, false);
        OSStatus err;
        UInt32 absdSize = sizeof(AudioStreamBasicDescription);
        UInt32 durationSize = sizeof(Float64);
        Float64 fileDuration;
        
        err = AudioFileOpenURL(audioURL, kAudioFileReadPermission, 0, &_audioFile);
        CFRelease(audioURL);

        if (err != noErr)
        {
            return NO;
        }
        AudioStreamBasicDescription fileasbd;
        
        err = AudioFileGetProperty(_audioFile, kAudioFilePropertyDataFormat, &absdSize, &fileasbd);
        
        AudioFileGetProperty(_audioFile, kAudioFilePropertyEstimatedDuration, &durationSize, &fileDuration);
        
        AVAudioChannelLayout *chanLayout = [AVAudioChannelLayout layoutWithLayoutTag:kAudioChannelLayoutTag_DiscreteInOrder | fileasbd.mChannelsPerFrame];
        _outputFormat = [[AVAudioFormat alloc] initWithStreamDescription:&fileasbd channelLayout:chanLayout];
        Float64 realEnd = fileDuration;

        if (self.endTime)
        {
            
            realEnd = self.endTime;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.duration = realEnd - self.startTime;
        });
        return YES;
        

    }
    return NO;
}

-(void)completed
{
    [self stop];
}

-(void)rewind
{
    [self stop];
    _lastStartFrame = 0;
    [self createAudioPlayer];
    [self play];
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
    if (self.loop && !_lastStartFrame)
    {
        fileRegion.mLoopCount = UINT32_MAX;
    } else {
        fileRegion.mLoopCount = 0;
    }
    
    
    Float64 adjustedFrame = _lastStartFrame * (_outputFormat.sampleRate/_outputSampleRate);
    Float64 calculatedStart = self.startTime * _outputFormat.sampleRate;
    
    fileRegion.mStartFrame = calculatedStart + adjustedFrame;
    
    if (self.endTime > 0 && self.endTime > self.startTime)
    {
     
        Float64 endFrame = self.endTime * _outputFormat.sampleRate;
        fileRegion.mFramesToPlay = endFrame - fileRegion.mStartFrame;
    } else {
        fileRegion.mFramesToPlay = -1;
    }
    
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &fileRegion, sizeof(fileRegion));
    
    if (self.loop && _lastStartFrame > 0)
    {
        fileRegion.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
        Float64 restartTime = 0;
        
        
        if (fileRegion.mFramesToPlay == -1)
        {
            restartTime = (self.duration * _outputSampleRate) - _lastStartFrame;
        } else {
            restartTime = fileRegion.mFramesToPlay;
        }
        fileRegion.mTimeStamp.mSampleTime = restartTime;
        

        fileRegion.mLoopCount = -1;
        fileRegion.mStartFrame = calculatedStart;
        if (self.endTime > 0 && self.endTime > self.startTime)
        {
            fileRegion.mFramesToPlay = (self.endTime * _outputFormat.sampleRate) - fileRegion.mStartFrame;
        } else {
            fileRegion.mFramesToPlay = -1;
        }
        
        AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &fileRegion, sizeof(fileRegion));
        
    }
    UInt32 primeFrames = 0;
    
    
    if (self.endTime)
    {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.duration = self.endTime - self.startTime;
        });
    }
    

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
    
    dispatch_async(dispatch_get_main_queue(), ^{
            self.playing = YES;

    });

}


-(void)stop
{

    AudioTimeStamp currentTime;

    UInt32 timesize = sizeof(currentTime);
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_CurrentPlayTime, kAudioUnitScope_Global, 0, &currentTime, &timesize);
    AudioUnitReset(self.audioUnit, kAudioUnitScope_Global, 0);
    self.playing = NO;
    Float64 sampleTime = _currentTime * _outputSampleRate;
    _lastStartFrame = (sampleTime);
    
}


-(bool)setOutputStreamFormat:(AVAudioFormat *)format bus:(UInt32)bus
{
    bool ret = [super setOutputStreamFormat:format bus:bus];
    _outputSampleRate = format.sampleRate;
    return ret;
}

-(bool)setInputStreamFormat:(AVAudioFormat *)format bus:(UInt32)bus
{
    return YES;
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

-(AVAudioFormat *)inputFormat
{
    return _outputFormat;
}


-(void)dealloc
{
    AudioFileClose(_audioFile);
    _outputFormat = nil;
}


@end
