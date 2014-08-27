//
//  MovieCapture.m
//  CocoaSplit
//
//  Created by Zakk on 8/26/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "MovieCapture.h"


@implementation MovieCapture

@synthesize currentMedia = _currentMedia;
@synthesize currentMovieTime = _currentMovieTime;



-(id) init
{
    if (self = [super init])
    {
        _currentFrame = NULL;
        _currentMovieTime = 0.0f;
        
        
        self.playPauseTitle = @"Play";
        
        [self setupPlayer];
        
        
        
    }
    return self;
}



- (void) setupPlayer
{
    self.avPlayer = [[AVQueuePlayer alloc] init];
    [self.avPlayer pause];
    NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];
    
    [videoSettings setValue:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: NO]
                                                        forKey: (NSString *)kIOSurfaceIsGlobal];
    
    
    
    [videoSettings setValue:ioAttrs forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    
    self.avOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:videoSettings];

    [self.avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:NULL];
    
}



- (CVImageBufferRef) getCurrentFrame
{
    CFTimeInterval currentTime = CACurrentMediaTime();
    CVPixelBufferRef newFrame = NULL;
    CMTime outputItemTime = [self.avOutput itemTimeForHostTime:currentTime];
    if ([self.avOutput hasNewPixelBufferForItemTime:outputItemTime])
    {
        
        newFrame = [self.avOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:nil];
        if (newFrame)
        {
            CVPixelBufferRelease(_currentFrame);
            _currentFrame = newFrame;
        }
    }
    
    
    CVPixelBufferRetain(_currentFrame);
    
    return _currentFrame;
    
}


+ (NSSet *)keyPathsForValuesAffectingCurrentMovieTimeString
{
	return [NSSet setWithObjects:@"currentMovieTime", nil];
}


+ (NSSet *)keyPathsForValuesAffectingMovieDuration
{
	return [NSSet setWithObjects:@"avPlayer.currentItem", @"avPlayer.currentItem.status", nil];
}

+ (NSSet *)keyPathsForValuesAffectingMovieDurationstring
{
	return [NSSet setWithObjects:@"avPlayer.currentItem", @"avPlayer.currentItem.status", nil];
}


-(NSString *) movieDurationString
{
    double duration = self.movieDuration;
    
    UInt64 minutes = duration/60;
    UInt64 seconds = (int)duration % 60;
    return [NSString stringWithFormat:@"%02lld:%02lld", minutes, seconds];
}


-(double) movieDuration
{
    AVPlayerItem *nowPlaying = self.avPlayer.currentItem;
    if (nowPlaying.status == AVPlayerItemStatusReadyToPlay)
    {
        return CMTimeGetSeconds(nowPlaying.asset.duration);
    } else {
        return 0.0f;
    }
}

-(NSString *) currentMovieTimeString
{
    double currentTime = self.currentMovieTime;
    
    UInt64 minutes = currentTime/60;
    UInt64 seconds = (int)currentTime % 60;
    return [NSString stringWithFormat:@"%02lld:%02lld", minutes, seconds];
}




-(double)currentMovieTime
{
    return _currentMovieTime;
}

-(void) setCurrentMovieTime:(double)time
{
    [self.avPlayer seekToTime:CMTimeMakeWithSeconds(time, 1)];
}



-(void) setupTimeObserver
{
    
    __weak MovieCapture *weakself = self;
    
    if (self.timeToken)
    {
        [self.avPlayer removeTimeObserver:self.timeToken];
    }
    
    
    self.timeToken = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1,10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
       
        MovieCapture *strongself = weakself;
        
        double currentTime = CMTimeGetSeconds(time);
        
        [strongself willChangeValueForKey:@"currentMovieTime"];
        strongself->_currentMovieTime = currentTime;
        
        [strongself didChangeValueForKey:@"currentMovieTime"];
    }];
}



-(void) enqueueMedia:(NSURL *)mediaURL
{
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:mediaURL];

    [item addOutput:self.avOutput];
    if ([self.avPlayer canInsertItem:item afterItem:nil])
    {
        [self.avPlayer insertItem:item afterItem:nil];
    }
    
    if (self.avPlayer.items.count == 1)
    {
        [self setupTimeObserver];
        [self.avPlayer play];
    }
}


-(NSURL *) currentMedia
{
    return _currentMedia;
}


-(void) setCurrentMedia:(NSURL *)currentMedia
{
    _currentMedia = currentMedia;
    
}

-(void)chooseMedia
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    
    if ([openPanel runModal] == NSOKButton)
    {
        NSArray *files = [openPanel URLs];
        for (NSURL *fileUrl in files)
        {
            if (fileUrl)
            {
                [self enqueueMedia:fileUrl];
            }
        }
    }
}



-(void)removeQueueItems:(NSIndexSet *)movieIndexes
{
    
    NSArray *deleteItems = [self.avPlayer.items objectsAtIndexes:movieIndexes];
    for(AVPlayerItem *toDelete in deleteItems)
    {
        [self.avPlayer removeItem:toDelete];
    }
    
}



-(void) nextMovie
{
    
    [self.avPlayer advanceToNextItem];
}


-(void)playOrPause
{
    if (self.avPlayer.rate != 1.0f)
    {
        [self.avPlayer play];
    } else {
        [self.avPlayer pause];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"rate"])
    {
        float playerRate = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        
        if (playerRate != 1.0f)
        {
            self.playPauseTitle = @"Play";
        } else {
            self.playPauseTitle = @"Pause";
        }
    }
}


@end
