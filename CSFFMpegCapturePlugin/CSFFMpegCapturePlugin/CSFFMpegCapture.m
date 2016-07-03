//
//  CSFFMpegCapture.m
//  CSFFMpegCapturePlugin
//
//  Created by Zakk on 6/11/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSFFMpegCapture.h"

@implementation CSFFMpegCapture

@synthesize currentMovieTime  = _currentMovieTime;

-(instancetype) init
{
    if (self = [super init])
    {
        av_register_all();
        avformat_network_init();
        
        
        self.needsSourceSelection = NO;

        //Inputs resample to floating point non-interleaved 48k for now.
        
        _asbd.mSampleRate = 48000;
        _asbd.mFormatID = kAudioFormatLinearPCM;
        _asbd.mFormatFlags = kAudioFormatFlagsNativeEndian  | kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
        _asbd.mChannelsPerFrame = 2;
        _asbd.mBitsPerChannel = 32;
        _asbd.mBytesPerFrame = 4;
        _asbd.mBytesPerPacket = 4;
        _asbd.mFramesPerPacket = 1;
        
        _player = [[CSFFMpegPlayer alloc] init];
        
        _player.asbd = &_asbd;
        _player.itemStarted = ^(CSFFMpegInput *item) { [self itemStarted:item]; };
        _player.queueStateChanged = ^() { [self queueChanged]; };
        
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];

        


        
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    NSMutableArray *queuePaths = [[NSMutableArray alloc] init];
    
    for (CSFFMpegInput *inp in self.player.inputQueue)
    {
        [queuePaths addObject:inp.mediaPath];
    }
    
    [aCoder encodeObject:queuePaths forKey:@"queuePaths"];
    
    CSFFMpegInput *nowPlaying = self.player.currentlyPlaying;
    
    NSString *nPath = nil;
    
    if (nowPlaying)
    {
        nPath = nowPlaying.mediaPath;
    }
    
    [aCoder encodeObject:nPath forKey:@"nowPlayingPath"];
    [aCoder encodeBool:self.playWhenLive forKey:@"playWhenLive"];
    [aCoder encodeBool:self.useCurrentPosition forKey:@"useCurrentPosition"];
    [aCoder encodeDouble:_currentMovieTime forKey:@"savedTime"];
    
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        
        CSFFMpegInput *nowPlayingInput = nil;
        NSString *nowPlayingPath = [aDecoder decodeObjectForKey:@"nowPlayingPath"];
        
        NSArray *paths = [aDecoder decodeObjectForKey:@"queuePaths"];
        for (NSString *mPath in paths)
        {
            CSFFMpegInput *newInput = [[CSFFMpegInput alloc] initWithMediaPath:mPath];
            [self.player enqueueItem:newInput];
            if (nowPlayingPath && [newInput.mediaPath isEqualToString:nowPlayingPath])
            {
                nowPlayingInput = newInput;
            }
        }
        
        if (nowPlayingInput)
        {
            self.player.currentlyPlaying = nowPlayingInput;
        }
        
        _savedTime = [aDecoder decodeDoubleForKey:@"savedTime"];
        self.useCurrentPosition = [aDecoder decodeBoolForKey:@"useCurrentPosition"];
        
        self.playWhenLive = [aDecoder decodeBoolForKey:@"playWhenLive"];
    }
    
    return self;
}


+(NSString *)label
{
    return @"Movie";
}

-(void) generateUniqueID
{
    NSMutableString *uID = [NSMutableString string];
    
    
    for(CSFFMpegInput *item in self.player.inputQueue)
    {
        NSString *itemStr = item.mediaPath;
        [uID appendString:itemStr];
    }
    
    if (_pcmPlayer)
    {
        _pcmPlayer.nodeUID = uID;
    }
    
    
    self.activeVideoDevice.uniqueID = uID;
}



-(double)currentMovieTime
{
    return _currentMovieTime;
}

-(void)setCurrentMovieTime:(double)currentMovieTime
{
    if (self.player)
    {
        [self.player seek:currentMovieTime];
    }
}


-(void)queueChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateUniqueID];
    });
}


-(void)itemStarted:(CSFFMpegInput *)item
{
    
    NSString *timeString = [self timeToString:item.duration];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.durationString = [self timeToString:item.duration];
        self.currentMovieDuration = item.duration;
        [self generateUniqueID];
        self.captureName = item.shortName;
        if (self.pcmPlayer)
        {
            self.pcmPlayer.name = item.shortName;
        }
    });
    
}


-(void)queuePath:(NSString *)path
{
    if (!self.player.pcmPlayer && self.pcmPlayer)
    {
        self.player.pcmPlayer = self.pcmPlayer;
    }
    
    CSFFMpegInput *newItem = [[CSFFMpegInput alloc] initWithMediaPath:path];
    
    [self.player enqueueItem:newItem ];
    [self generateUniqueID];
}

-(void)pause
{
    if (self.player)
    {
        [self.player pause];
    }
}


-(void)play
{
    if (self.player)
    {
        [self.player play];
    }
}


-(void)mute
{
    if (self.player)
    {
        self.player.muted = !self.player.muted;
    }
}

-(void)next
{
    if (self.player)
    {
        [self.player next];
    }
}

-(void)back
{
    if (self.player)
    {
        [self.player back];
    }
}


-(CALayer *)createNewLayer
{
    
    CSIOSurfaceLayer *newLayer = [CSIOSurfaceLayer layer];
    
    
    return newLayer;
}


-(NSString *) timeToString:(double)convertTime
{
    
    UInt64 minutes = convertTime/60;
    UInt64 seconds = (int)convertTime % 60;
    return [NSString stringWithFormat:@"%02lld:%02lld", minutes, seconds];
}



-(void)frameTick
{
    CFTimeInterval cTime = CACurrentMediaTime();
    CVPixelBufferRef use_buf = [self.player frameForMediaTime:cTime];
    
    if (use_buf)
    {
    
        if (cTime - _lastTimeUpdate > 0.5)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentTimeString = [self timeToString:self.player.lastVideoTime];
                [self willChangeValueForKey:@"currentMovieTime"];
                _currentMovieTime = self.player.lastVideoTime;;
                
                [self didChangeValueForKey:@"currentMovieTime"];
            });
        }
        [self updateLayersWithBlock:^(CALayer *layer) {
            
            ((CSIOSurfaceLayer *)layer).imageBuffer = use_buf;
        }];
        
        CVPixelBufferRelease(use_buf);

    }
}

-(void)setIsLive:(bool)isLive
{
    
    bool oldLive = super.isLive;
    super.isLive = isLive;
    
    if (isLive == oldLive)
    {
        return;
    }
    
    if (isLive)
    {
        [self registerPCMOutput:1024 audioFormat:&_asbd];
        if (self.playWhenLive)
        {
            [self.player play];
            if (self.useCurrentPosition)
            {
                [self.player seek:_savedTime];
            }
        }

    } else {
        [self deregisterPCMOutput];
    }
}


-(void)registerPCMOutput:(CMItemCount)frameCount audioFormat:(const AudioStreamBasicDescription *)audioFormat
{
    
    if (self.pcmPlayer)
    {
        //looks like we already have one?
        return;
    }
    
    
    self.pcmPlayer = [[CSPluginServices sharedPluginServices] createPCMInput:@"BLAHBLAH" withFormat:audioFormat];
    if (self.player)
    {
        self.player.asbd = &_asbd;
        self.player.pcmPlayer = self.pcmPlayer;
        self.pcmPlayer.name = self.player.currentlyPlaying.shortName;
    }
    
}

-(void)deregisterPCMOutput
{
    
    
    if (self.pcmPlayer)
    {
        
        [[CSPluginServices sharedPluginServices] removePCMInput:self.pcmPlayer];
    }
    
    self.pcmPlayer = nil;
    self.player.pcmPlayer = nil;
    
}

-(void)dealloc
{
    if (self.pcmPlayer)
    {
        [self deregisterPCMOutput];
    }
}




@end
