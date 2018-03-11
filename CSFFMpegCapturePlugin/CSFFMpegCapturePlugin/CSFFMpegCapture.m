//
//  CSFFMpegCapture.m
//  CSFFMpegCapturePlugin
//
//  Created by Zakk on 6/11/16.
//

#import "CSFFMpegCapture.h"

@implementation CSFFMpegCapture

@synthesize currentMovieTime  = _currentMovieTime;
@synthesize repeat = _repeat;

-(instancetype) init
{
    if (self = [super init])
    {
        
        _lastSize = NSZeroSize;
        
        self.needsSourceSelection = NO;
        
        self.updateMovieTime = YES;
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
        _firstFrame = YES;
        _repeat = kCSFFMovieRepeatNone;
        self.uuid = [[NSUUID UUID] UUIDString];
        self.allowDedup = NO; //Seeking makes this impossible
        
        
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
        
    }
    return ret;
}


-(void)setRepeat:(ff_movie_repeat)repeat
{
    _repeat = repeat;
    
    if (self.player)
    {
        self.player.repeat = repeat;
    }
}

-(ff_movie_repeat)repeat
{
    if (self.player)
    {
        _repeat = self.player.repeat;
        
    }
    
    return _repeat;
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
    _player.repeat = _repeat;
    
    
    if (self.isLive)
    {
        [self registerPCMOutput:1024 audioFormat:&_asbd];
    }
}


-(void)saveWithCoder:(NSCoder *)aCoder
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
    [aCoder encodeInt:self.repeat forKey:@"repeat"];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
    
}


-(void)restoreWithCoder:(NSCoder *)aDecoder
{

    
        CSFFMpegInput *nowPlayingInput = nil;
        NSString *nowPlayingPath = [aDecoder decodeObjectForKey:@"nowPlayingPath"];
        
        self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
        
        if (!self.uuid)
        {
            self.uuid = [[NSUUID UUID] UUIDString];
        }
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
            self.captureName = nowPlayingInput.shortName;
    
        } else {
            CSFFMpegInput *firstItem = self.player.inputQueue.firstObject;

            self.captureName = firstItem.shortName;
        }
        
        
        _savedTime = [aDecoder decodeDoubleForKey:@"savedTime"];
        self.useCurrentPosition = [aDecoder decodeBoolForKey:@"useCurrentPosition"];
        
        self.playWhenLive = [aDecoder decodeBoolForKey:@"playWhenLive"];
        self.repeat = [aDecoder decodeIntForKey:@"repeat"];

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
    
    /*
    if (_pcmPlayer)
    {
        _pcmPlayer.nodeUID = uID;
    }*/
    
    
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
        [self changeAttachedAudioInputName:self.uuid withName:item.shortName];
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
        self.player.pcmPlayer = self.pcmPlayer;
    }
    
    CSFFMpegInput *newItem = [[CSFFMpegInput alloc] initWithMediaPath:path];
    
    [self.player enqueueItem:newItem ];
    CSFFMpegInput *firstItem = self.player.inputQueue.firstObject;

    if (!self.captureName)
    {
        if (firstItem)
        {
            self.captureName = firstItem.shortName;
            if (self.pcmPlayer)
            {
                self.pcmPlayer.name = firstItem.shortName;
            }
        }
    }

    [self createAttachedAudioInputForUUID:self.uuid withName:firstItem.shortName];
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
    return [CALayer layer];
    /*
    CSIOSurfaceLayer *newLayer = [CSIOSurfaceLayer layer];
    
    
    return newLayer;
     */
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

-(void)setIsVisible:(bool)isVisible
{
    [super setIsVisible:isVisible];
    if (isVisible && self.playWhenLive && !self.player.playing)
    {
        [self.player play];
        if (self.useCurrentPosition)
        {
            [self.player seek:_savedTime];
        }
    }
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
            layer.contents = (__bridge id _Nullable)(use_buf);
        } withPreuseBlock:^{
            CVPixelBufferRetain(use_buf);
        } withPostuseBlock:^{
            CVPixelBufferRelease(use_buf);
        }];
        
        if (_firstFrame)
        {
            _firstFrame = NO;
            //[self.player pause];
        }
        CVPixelBufferRelease(use_buf);

    } else if (_firstFrame) {
        use_buf = [self.player firstFrame];
        if (use_buf)
        {
            _lastSize = NSMakeSize(CVPixelBufferGetWidth(use_buf), CVPixelBufferGetHeight(use_buf));
            [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                layer.contents = (__bridge id _Nullable)(use_buf);
                [layer displayIfNeeded];
            } withPreuseBlock:^{
                CVPixelBufferRetain(use_buf);
            } withPostuseBlock:^{
                CVPixelBufferRelease(use_buf);
            }];
            CVPixelBufferRelease(use_buf);
            _firstFrame = NO;
        }

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
    
    
    self.pcmPlayer = [self createPCMInput:self.uuid withFormat:audioFormat];
    

    
    if (self.player)
    {
        self.player.asbd = &_asbd;
        self.player.pcmPlayer = self.pcmPlayer;
        if (self.player.currentlyPlaying)
        {
            self.pcmPlayer.name = self.player.currentlyPlaying.shortName;
        } else {
            CSFFMpegInput *firstItem = self.player.inputQueue.firstObject;

            self.pcmPlayer.name = firstItem.shortName;
        }
    }
    
}


-(float)duration
{
    float startpos = 0;
    if (self.useCurrentPosition)
    {
        startpos = _savedTime;
    }
    float totalDuration = 0;
    for (CSFFMpegInput *item in self.player.inputQueue)
    {
        totalDuration += item.duration;
    }
    return totalDuration - startpos;
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
    if (self.pcmPlayer)
    {
        [self deregisterPCMOutput];
    }
    [self.player stop];
    
    self.player = nil;
    
}




@end
