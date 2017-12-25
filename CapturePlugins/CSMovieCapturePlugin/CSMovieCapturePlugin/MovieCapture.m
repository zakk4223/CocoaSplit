//
//  MovieCapture.m
//  CocoaSplit
//
//  Created by Zakk on 8/26/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "MovieCapture.h"

extern void av_register_all();


void tapInit(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut) {
    *tapStorageOut = clientInfo;
}

void tapFinalize(MTAudioProcessingTapRef tap)
{
    void *tapStorage = MTAudioProcessingTapGetStorage(tap);
    if (tapStorage)
    {
        CFBridgingRelease(tapStorage);
    }
}


void tapPrepare(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat)
{

    void *tapStorage = MTAudioProcessingTapGetStorage(tap);
    
    if (tapStorage)
    {
        MovieCapture *captureObj = (__bridge MovieCapture *)tapStorage;
        [captureObj preallocateAudioBuffers:maxFrames audioFormat:processingFormat];
        
    }
}


void tapProcess(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut,MTAudioProcessingTapFlags *flagsOut)
{
    
    void *tapStorage = MTAudioProcessingTapGetStorage(tap);
    
    
    if (tapStorage)
    {
        MovieCapture *captureObj = (__bridge MovieCapture *)tapStorage;
        MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, NULL, numberFramesOut);

        
        if (captureObj && captureObj.pcmPlayer)
        {
            [captureObj playAudioBuffer:bufferListInOut];
        }
    }
}






@implementation MovieCapture

@synthesize currentMedia = _currentMedia;
@synthesize currentMovieTime = _currentMovieTime;


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    NSMutableArray *currentQueueURLS = [NSMutableArray array];
    for(AVPlayerItem *item in _avPlayer.items)
    {
        AVURLAsset *itemAsset = (AVURLAsset *)item.asset;
        if (itemAsset)
        {
            NSURL *url = itemAsset.URL;
            if (url)
            {
                [currentQueueURLS addObject:url];
            }
        }
    }
    
    [aCoder encodeDouble:self.currentMovieTime forKey:@"currentMovieTime"];
    [aCoder encodeObject:currentQueueURLS forKey:@"currentQueueURLS"];
    [aCoder encodeFloat:_avPlayer.rate forKey:@"playerRate"];
    [aCoder encodeInt32:self.repeat forKey:@"repeat"];
    
}


-(id)initWithCoder:(NSCoder *)aDecoder
{

    if (self = [self init])
    {
        NSMutableArray *urls = [aDecoder decodeObjectForKey:@"currentQueueURLS"];
        for (NSURL *url in urls)
        {
            [self enqueueMedia:url];
        }
        self.currentMovieTime = [aDecoder decodeDoubleForKey:@"currentMovieTime"];
        _avPlayer.rate = [aDecoder decodeFloatForKey:@"playerRate"];
        if ([aDecoder containsValueForKey:@"repeat"])
        {
            self.repeat = [aDecoder decodeInt32ForKey:@"repeat"];
        }
    }
    
    return self;
}


-(id) init
{
    if (self = [super init])
    {
        

        self.repeat = kCSMovieRepeatNone;
        
        _currentMovieTime = 0.0f;
        self.needsSourceSelection = NO;
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
        self.playPauseTitle = @"Play";
        
        
        
        
    }
    return self;
}


-(CALayer *)createNewLayer
{
    return [CSIOSurfaceLayer layer];
}





-(NSSize)captureSize
{
    return _lastSize;
}


-(void)frameTick
{
    
    CFTimeInterval currentTime = CACurrentMediaTime();
    CVPixelBufferRef newFrame = NULL;
    CMTime outputItemTime = [self.avOutput itemTimeForHostTime:currentTime];
    if ([self.avOutput hasNewPixelBufferForItemTime:outputItemTime])
    {
        
        newFrame = [self.avOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:nil];
        if (newFrame)
        {
            
            _lastSize = NSMakeSize(CVPixelBufferGetWidth(newFrame), CVPixelBufferGetHeight(newFrame));
            [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                ((CSIOSurfaceLayer *)layer).imageBuffer = newFrame;
            }];
            //outputlayer retains the pixel buffer until no longer needed
            CVPixelBufferRelease(newFrame);
        }
    }
    
    
}



-(void)copyAudioBufferList:(AudioBufferList *)bufferList
{
    [_bufferPCM copyFromAudioBufferList:bufferList];
}

-(void) playAudioBuffer:(AudioBufferList *)buffer
{
    [self copyAudioBufferList:buffer];
    
    dispatch_async(_audioQueue, ^{
        
        
            CAMultiAudioPCM *newBuffer = [_bufferPCM copy];
        
            [self.pcmPlayer playPcmBuffer:newBuffer];
    });
}

-(void)setIsLive:(bool)isLive
{
    
    bool oldLive = super.isLive;
    super.isLive = isLive;
    
    if (isLive == oldLive)
    {
        return;
    }
    
    if (isLive && _bufferPCM)
    {
        AudioStreamBasicDescription asbd = _bufferPCM.pcmFormat;
        
        [self registerPCMOutput:1024 audioFormat:&asbd];
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
    

    self.pcmPlayer = [[CSPluginServices sharedPluginServices] createPCMInput:self.activeVideoDevice.uniqueID withFormat:audioFormat];
    AVURLAsset *urlAsset = (AVURLAsset *)_avPlayer.currentItem.asset;
    self.pcmPlayer.name = urlAsset.URL.lastPathComponent;
}

-(void)deregisterPCMOutput
{
    

    if (self.pcmPlayer)
    {

        [[CSPluginServices sharedPluginServices] removePCMInput:self.pcmPlayer];
    }
    
    self.pcmPlayer = nil;
}


-(void)preallocateAudioBuffers:(CMItemCount)frameCount audioFormat:(const AudioStreamBasicDescription *)audioFormat
{
 
    if (self.isLive)
    {
        [self registerPCMOutput:frameCount audioFormat:audioFormat];
    }
    _bufferPCM = [[CAMultiAudioPCM alloc] initWithDescription:audioFormat forFrameCount:(int)frameCount];
}


-(void) generateUniqueID
{
    NSMutableString *uID = [NSMutableString string];
    
    
    for(AVPlayerItem *qItem in _avPlayer.items)
    {
        AVURLAsset *urlAsset = (AVURLAsset *)qItem.asset;
        
        NSString *itemStr = urlAsset.URL.description;
        [uID appendString:itemStr];
    }
    if (_pcmPlayer)
    {
        _pcmPlayer.nodeUID = uID;
    }
    
    
    self.activeVideoDevice.uniqueID = uID;
}


- (void) setupPlayer
{
    
    _audioQueue = dispatch_queue_create("MoviePlayerAudioQueue", NULL);

    _avPlayer = [[AVQueuePlayer alloc] init];
    [_avPlayer pause];
    NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];
    
    [videoSettings setValue:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: NO]
                                                        forKey: (NSString *)kIOSurfaceIsGlobal];
    
    
    
    [videoSettings setValue:ioAttrs forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    
    self.avOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:videoSettings];

    [_avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:NULL];
    [_avPlayer addObserver:self forKeyPath:@"currentItem" options:0 context:NULL];
    _avPlayer.volume = 0.0;
}





+ (NSSet *)keyPathsForValuesAffectingCurrentMovieTimeString
{
	return [NSSet setWithObjects:@"currentMovieTime", nil];
}


+ (NSSet *)keyPathsForValuesAffectingMovieDuration
{
	return [NSSet setWithObjects:@"avPlayer.currentItem", @"avPlayer.currentItem.status", nil];
}

+ (NSSet *)keyPathsForValuesAffectingMovieDurationString
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
    AVPlayerItem *nowPlaying = _avPlayer.currentItem;
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
    [_avPlayer seekToTime:CMTimeMakeWithSeconds(time, 1000)];
}



-(void) setupTimeObserver
{
    
    __weak MovieCapture *weakself = self;
    
    if (self.timeToken)
    {
        [_avPlayer removeTimeObserver:self.timeToken];
    }
    
    
    self.timeToken = [_avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1,10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
       
        MovieCapture *strongself = weakself;
        
        double currentTime = CMTimeGetSeconds(time);
        
        [strongself willChangeValueForKey:@"currentMovieTime"];
        strongself->_currentMovieTime = currentTime;
        
        [strongself didChangeValueForKey:@"currentMovieTime"];
    }];
}



-(void) enqueueMedia:(NSURL *)mediaURL
{
    
    if (!_avPlayer)
    {
        [self setupPlayer];
    }
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:mediaURL];

    if ([_avPlayer canInsertItem:item afterItem:nil])
    {
        
        [_avPlayer insertItem:item afterItem:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidFinishPlaying:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:item];

    }
    
    [self generateUniqueID];
    
    if (_avPlayer.items.count == 1)
    {
        [self setupTimeObserver];
        [_avPlayer play];
    }
    
}


-(void) advanceQueue
{
    AVPlayerItem *currentItem = _avPlayer.currentItem;
    AVPlayerItem *currentCopy = currentItem.copy;
    
    [self willChangeValueForKey:@"movieQueue"];
    if (self.repeat == kCSMovieRepeatOne)
    {
        [_avPlayer insertItem:currentCopy afterItem:currentItem];
    } else if (self.repeat == kCSMovieRepeatAll) {
        [_avPlayer insertItem:currentCopy afterItem:nil];
        
    }
    
    [_avPlayer removeItem:currentItem];

    [self didChangeValueForKey:@"movieQueue"];
    [self generateUniqueID];
    
}


-(void) itemDidFinishPlaying:(NSNotification *)notification
{
    
    [self advanceQueue];
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
    
    NSArray *deleteItems = [_avPlayer.items objectsAtIndexes:movieIndexes];
    [self willChangeValueForKey:@"movieQueue"];
    for(AVPlayerItem *toDelete in deleteItems)
    {
        [_avPlayer removeItem:toDelete];
    }
    [self generateUniqueID];
    [self didChangeValueForKey:@"movieQueue"];
}

-(void) nextMovie
{
    [self advanceQueue];
}



-(NSArray *) movieQueue
{
    return _avPlayer.items;
}




-(void)playOrPause
{
    if (_avPlayer.rate != 1.0f)
    {
        [_avPlayer play];
    } else {
        [_avPlayer pause];
    }
}

-(void)setupAudioTapOnItem:(AVPlayerItem *)item
{
    AVAssetTrack *audioTrack;
    MTAudioProcessingTapRef tap;
    MTAudioProcessingTapCallbacks callbacks;
    
    audioTrack = [item.asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    
    if (!audioTrack)
    {
        return;
    }
    
    
    callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
    callbacks.clientInfo = (__bridge_retained void *)(self);
    callbacks.init = tapInit;
    callbacks.prepare = tapPrepare;
    callbacks.process = tapProcess;
    callbacks.unprepare = NULL;
    callbacks.finalize = tapFinalize;
    
    
    MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &tap);
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    AVMutableAudioMixInputParameters *inputParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
    
    inputParams.audioTapProcessor = tap;
    audioMix.inputParameters = @[inputParams];
    _avPlayer.currentItem.audioMix = audioMix;
    CFRelease(tap);
    
    
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
    } else if ([keyPath isEqualToString:@"status"]) {
        
    
        NSInteger oldVal, newVal;
        
        oldVal = [change[NSKeyValueChangeOldKey] intValue];
        newVal = [change[NSKeyValueChangeNewKey] intValue];
        if (oldVal == newVal)
        {
            return;
        }
        
        AVPlayerItem *item = (AVPlayerItem *)object;
        if (item.status != AVPlayerItemStatusReadyToPlay)
        {
            return;
        }
        [self setupAudioTapOnItem:item];
    } else if ([keyPath isEqualToString:@"currentItem"]) {
        [_avPlayer.currentItem addOutput:self.avOutput];

        [self setupAudioTapOnItem:_avPlayer.currentItem];
    }
    
}



+(NSString *)label
{
    return @"AppleMovie";
}


-(void)willDelete
{
    
    if (self.timeToken)
    {
        [_avPlayer removeTimeObserver:self.timeToken];
        self.timeToken = nil;
    }
    
    if (_avPlayer)
    {
        [_avPlayer pause];
        [_avPlayer removeAllItems];
        
        [_avPlayer removeObserver:self forKeyPath:@"rate"];
        [_avPlayer removeObserver:self forKeyPath:@"currentItem"];

        if (_avPlayer.currentItem)
        {
            AVMutableAudioMixInputParameters *inputParams = _avPlayer.currentItem.audioMix.inputParameters.firstObject;
            inputParams.audioTapProcessor = nil;
            _avPlayer.currentItem.audioMix = nil;

        }
        
        _avPlayer = nil;
    }
    

    //self.avOutput = nil;
    //_avPlayer = nil;


    
}
-(void) dealloc
{
    [self willDelete];

}




@end
