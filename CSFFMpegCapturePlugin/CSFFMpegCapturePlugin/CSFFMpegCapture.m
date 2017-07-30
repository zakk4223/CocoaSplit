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
        
        _lastSize = NSZeroSize;
        
        self.needsSourceSelection = NO;

        self.updateMovieTime = YES;
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
        _firstFrame = YES;
    }
    return self;
}

+(NSSet *)mediaUTIs
{
    return [NSSet setWithArray:@[@"public.movie"]];
}


+(NSObject<CSCaptureSourceProtocol> *)createSourceFromPasteboardItem:(NSPasteboardItem *)item
{
    
    CSFFMpegCapture *ret = nil;
    
    NSString *imagePath = [item stringForType:@"public.file-url"];
    if (imagePath)
    {
        NSURL *fileURL = [NSURL URLWithString:imagePath];
        NSString *realPath = [fileURL path];
        ret = [[CSFFMpegCapture alloc] init];
        [ret queuePath:realPath];
        [ret play];
    }
    return ret;
}

-(void)setupPlayer
{
    
    av_register_all();
    avformat_network_init();
    
    
    
    //Inputs resample to floating point non-interleaved 48k for now.
    
    _asbd.mSampleRate = 48000;
    _asbd.mFormatID = kAudioFormatLinearPCM;
    _asbd.mFormatFlags = kAudioFormatFlagsNativeEndian  | kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
    _asbd.mChannelsPerFrame = 2;
    _asbd.mBitsPerChannel = 32;
    _asbd.mBytesPerFrame = 4;
    _asbd.mBytesPerPacket = 4;
    _asbd.mFramesPerPacket = 1;
    
    self.player = [[CSFFMpegPlayer alloc] init];
    
    self.player.asbd = &_asbd;
    
    __weak __typeof__(self) weakSelf = self;
    
    _player.itemStarted = ^(CSFFMpegInput *item) { [weakSelf itemStarted:item]; };
    _player.queueStateChanged = ^() { [weakSelf queueChanged]; };

    if (self.isLive)
    {
        [self registerPCMOutput:1024 audioFormat:&_asbd];
    }
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
            if (!self.player)
            {
                [self setupPlayer];
            }
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


-(NSImage *)libraryImage
{
    return [NSImage imageNamed:@"NSMediaBrowserMediaTypeMoviesTemplate32"];
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
        self.currentTimeString = [self timeToString:self.player.lastVideoTime];

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
    if (!self.player)
    {
        [self setupPlayer];
    }
    
    
    if (!self.player.pcmPlayer && self.pcmPlayer)
    {
        NSLog(@"SETTING PCM PLAYER TO %@", self.pcmPlayer);
        self.player.pcmPlayer = self.pcmPlayer;
    }
    
    CSFFMpegInput *newItem = [[CSFFMpegInput alloc] initWithMediaPath:path];
    
    [self.player enqueueItem:newItem ];
    if (!self.captureName)
    {
        CSFFMpegInput *firstItem = self.player.inputQueue.firstObject;
        if (firstItem)
        {
            self.captureName = firstItem.shortName;
        }
    }

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



-(NSSize)captureSize
{
    return _lastSize;
}


-(void)frameTick
{
    if (!self.player)
    {
        return;
    }
    
    
    CFTimeInterval cTime = CACurrentMediaTime();
    CVPixelBufferRef use_buf = [self.player frameForMediaTime:cTime];
    
    if (use_buf)
    {
    
        _lastSize = NSMakeSize(CVPixelBufferGetWidth(use_buf), CVPixelBufferGetHeight(use_buf));
        
        if ((cTime - _lastTimeUpdate > 0.5) && self.updateMovieTime)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentTimeString = [self timeToString:self.player.lastVideoTime];
                [self willChangeValueForKey:@"currentMovieTime"];
                self->_currentMovieTime = self.player.lastVideoTime;;
                
                [self didChangeValueForKey:@"currentMovieTime"];
            });
        }
        [self updateLayersWithFramedataBlock:^(CALayer *layer) {
            
            ((CSIOSurfaceLayer *)layer).imageBuffer = use_buf;
        }];
        
        if (_firstFrame)
        {
            _firstFrame = NO;
            [self.player pause];
        }
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
        if (self.player)
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
    if (self.player)
    {
        self.player.pcmPlayer = nil;
    }
    
}

-(void)dealloc
{
    NSLog(@"MOVIE DEALLOC");
    if (self.pcmPlayer)
    {
        [self deregisterPCMOutput];
    }
}




@end
