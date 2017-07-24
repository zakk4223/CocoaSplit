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


-(instancetype)initWithPath:(NSString *)path
{
    if (self = [self init])
    {
        self.filePath = path;
        self.nodeUID = path;
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



-(void)openAudioFile
{
    if (self.filePath)
    {
        CFURLRef audioURL = CFURLCreateWithFileSystemPath(NULL, (__bridge CFStringRef)self.filePath, kCFURLPOSIXPathStyle, false);
        OSStatus err;
        UInt32 absdSize = sizeof(AudioStreamBasicDescription);
        if (!_outputFormat)
        {
            _outputFormat = malloc(sizeof(AudioStreamBasicDescription));
        }
        err = AudioFileOpenURL(audioURL, kAudioFileReadPermission, 0, &_audioFile);
        err = AudioFileGetProperty(_audioFile, kAudioFilePropertyDataFormat, &absdSize, _outputFormat);
    }
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
    fileRegion.mStartFrame = 0;
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
}

-(void)stop
{
    AudioUnitReset(self.audioUnit, kAudioUnitScope_Global, 0);
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
    return;
}


@end
