//
//  CSLayoutRecorder.m
//  CocoaSplit
//
//  Created by Zakk on 4/30/17.
//

#import "CSLayoutRecorder.h"
#import "CaptureController.h"
#import "CSLavfOutput.h"

@interface RecAudioBufferData : NSObject
@property (strong) NSMutableArray *audiobuffer;
@property (assign) CMTime firstAudioTime;
@property (assign) CMTime previousAudioTime;
@end

@implementation RecAudioBufferData
-(instancetype) init
{
    if (self = [super init])
    {
        _audiobuffer = [NSMutableArray array];
        _firstAudioTime = kCMTimeZero;
        _previousAudioTime = kCMTimeZero;
    }
    
    return self;
}
@end


@implementation CSLayoutRecorder


@synthesize audioEngine = _audioEngine;

-(instancetype) init
{
    if (self = [super init])
    {
        _outputs = [NSMutableArray array];
        _compressors = [NSMutableDictionary dictionary];
    }
    return self;
}


-(float)frameRate
{
    if (self.layout)
    {
        return self.layout.frameRate;
    }
    
    return 0.0f;
}


-(void)checkOutputs
{
    if (self.outputs.count == 0)
    {
        self.layout.recorder = nil;
        self.layout.isActive = NO;
        self.recordingActive = NO;
        /*
        [self.audioEncoder stopEncoder];
        self.audioEngine.encoder = nil;
         */
        [self.audioEngine stopEncoders];
        self.audioEngine = nil;
        [[CaptureController sharedCaptureController] removeLayoutRecorder:self];
    }
}





-(void)stopRecordingAll
{
    
    NSArray *outCopy = self.outputs.copy;
    
    for (OutputDestination *dest in outCopy)
    {
        [self stopRecordingForOutput:dest];
    }
    
    if (self.output)
    {
        [self stopDefaultRecording];
    }
}


-(void)startRecordingWithOutput:(OutputDestination *)output
{
    
    if (![self.outputs containsObject:output])
    {
        [self.outputs addObject:output];
    }
    
    output.settingsController = self;

    output.captureRunning = YES;

    [output setup];
    
    //[output setupCompressor];
    if (!self.recordingActive)
    {
    
        [self startRecordingCommon];
    }
    
}

-(void)stopRecordingForOutput:(OutputDestination *)output
{
    OutputDestination *useOut;
    
    for (OutputDestination *tmpOut in self.outputs)
    {
        if (tmpOut == output)
        {
            useOut = tmpOut;
        }
    }
    
    if (useOut)
    {
        useOut.captureRunning = NO;

        [useOut stopOutput];
        [useOut reset];
        
        [self.outputs removeObject:useOut];
        [self checkOutputs];

    }
}

-(NSObject<CSOutputWriterProtocol> *)createOutput
{
    return [[CSLavfOutput alloc] init];
}


-(void)startRecording
{
    
    self.useTimestamp = YES;

    CaptureController *captureController = [CaptureController sharedCaptureController];

    OutputDestination *newOutput;
    newOutput = [[OutputDestination alloc] init];
    newOutput.settingsController = self;
    newOutput.streamServiceObject = (id<CSStreamServiceProtocol>)self;
    //NSObject<VideoCompressor> *origCompressor = [captureController compressorByName:captureController.layoutRecorderCompressorName];
    newOutput.compressor_name = captureController.layoutRecorderCompressorName;
    
    //newOutput.compressor = origCompressor.copy;
    newOutput.settingsController = self;
    
    NSString *baseDir = captureController.layoutRecordingDirectory;
    NSString *fileFormat = captureController.layoutRecordingFormat;
    newOutput.captureRunning = YES;
    newOutput.active = YES;

    self.output = newOutput;
    self.outputFilename = [baseDir stringByAppendingString:[NSString stringWithFormat:@"/%@.%@", self.layout.name, fileFormat]];
    self.fileFormat = fileFormat;
    
    [self.outputs addObject:newOutput];
    [self startRecordingCommon];
    self.defaultRecordingActive = YES;
    self.layout.recordingLayout = YES;
}



-(void)stopDefaultRecording
{
    if (self.output)
    {
        self.layout.recordingLayout = NO;
        self.output.active = NO;
        self.output.captureRunning = NO;
        //[self.outputs removeObject:self.output];
        [self checkOutputs];
    }
}

-(void)attachToEncoder:(NSString *)trackUID
{
    CAMultiAudioOutputTrack *outputTrack = self.audioEngine.outputTracks[trackUID];
    CSAacEncoder *enc = outputTrack.encoder;
    enc.encodedReceiver = self;
    [self.audioEngine startEncoder:trackUID];
}

-(void)startRecordingCommon
{

    if (!self.recordingActive)
    {
        _firstAudioTime = kCMTimeZero;
        _previousAudioTime = kCMTimeZero;
        _firstPcmAudioTime = kCMTimeZero;
        _previousPcmAudioTime = kCMTimeZero;
        
        
        _audioBuffers = [NSMutableDictionary dictionary];
        _pcmAudioBuffers = [NSMutableDictionary dictionary];


        
        
        
        
        if (!self.audioEngine)
        {
        
            CAMultiAudioEngine *useEngine = nil;


            useEngine = self.layout.audioEngine;
            
            if (!useEngine)
            {
                CAMultiAudioEngine *systemEngine = CaptureController.sharedCaptureController.multiAudioEngine;
                NSString *defaultOutUUID = nil;
                if (systemEngine)
                {
                    defaultOutUUID = systemEngine.defaultTrackUUID;
                }
                
                useEngine = [[CAMultiAudioEngine alloc] initWithDefaultTrackUUID:defaultOutUUID];
                useEngine.sampleRate = [CaptureController sharedCaptureController].multiAudioEngine.sampleRate;
                [useEngine disableAllInputs];
                if (systemEngine)
                {
                    NSDictionary *outputTracks = systemEngine.outputTracks;
                    for (NSString *trackUUID in outputTracks)
                    {
                        CAMultiAudioOutputTrack *track = outputTracks[trackUUID];
                        NSString *trackName = track.name;
                        [useEngine createOutputTrack:trackName withUUID:track.uuid];
                        
                    }
                }
            }
            


            useEngine.previewMixer.muted = YES;
            self.audioEngine = useEngine;
            [self.audioEngine startEncoders];
            
        } else {
            //self.audioEncoder = self.audioEngine.encoder;
        }
        
        for(NSString *trackName in self.audioEngine.outputTracks)
        {
            [self attachToEncoder:trackName];
        }
        if (!self.renderer)
        {
            self.renderer = [[LayoutRenderer alloc] init];
        }
        if (self.layout.sourceList.count == 0)
        {
            [self.layout restoreSourceList:nil];
        } else {
            [self.layout reapplyAudioSources];
        }
        
        self.renderer.layout = self.layout;
        
        if (!_frame_queue)
        {
            _frame_queue = dispatch_queue_create("layout.recorder.queue", DISPATCH_QUEUE_SERIAL);
        }
        
        
        if (self.output)
        {
            self.output.assignedLayout = self.layout;
        }
        
        self.layout.recorder = self;
        
        self.recordingActive = YES;
        self.layout.isActive = YES;
        [self.audioEngine addObserver:self forKeyPath:@"outputTracks.@allKeys" options:NSKeyValueObservingOptionNew context:nil];
        dispatch_async(_frame_queue, ^{
            [self newFrameTimed];
            
        });
    }
    
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (!self.audioEngine)
    {
        return;
    }
    NSArray *trackKeys = change[NSKeyValueChangeNewKey];
    for (NSString *trackUID in trackKeys)
    {
        CAMultiAudioOutputTrack *outTrack = self.audioEngine.outputTracks[trackUID];
        if (!outTrack.encoder.encodedReceiver)
        {
            [self attachToEncoder:trackUID];
        }
    }
}


-(CAMultiAudioEngine *)audioEngine
{
    return _audioEngine;
}
-(void)setAudioEngine:(CAMultiAudioEngine *)audioEngine
{
    if (self.audioEngine)
    {
        [self.audioEngine removeObserver:self forKeyPath:@"outputTracks.@allKeys"];
    }
    
    _audioEngine = audioEngine;
}


-(NSObject<VideoCompressor> *)compressorByName:(NSString *)name
{
    NSObject<VideoCompressor> *compressor = nil;
    
    compressor = self.compressors[name];
    
    if (!compressor || [compressor isEqualTo:[NSNull null]])
    {
        NSObject<VideoCompressor> *origCompressor =  [CaptureController sharedCaptureController].compressors[name];
        compressor = origCompressor.copy;
        self.compressors[compressor.name] = compressor;
    }
    
    return compressor;
}





-(NSString *)getServiceDestination
{
    NSString *useFilename = self.outputFilename;
    NSString *pathExt = [self.outputFilename pathExtension];
    NSString *noExt = [useFilename stringByDeletingPathExtension];
    
    if (self.useTimestamp)
    {
        NSDateFormatter *dFormat = [[NSDateFormatter alloc] init];
        dFormat.dateFormat = @"yyyyMMddHHmmss";
        NSString *dateStr = [dFormat stringFromDate:[NSDate date]];
        useFilename = [NSString stringWithFormat:@"%@-%@.%@", noExt, dateStr, pathExt];
    }
    
    if (self.noClobber)
    {
        noExt = [useFilename stringByDeletingPathExtension];
        
        NSFileManager *fManager = [[NSFileManager alloc] init];
        NSString *noExt = [useFilename stringByDeletingPathExtension];
        int fidx = 1;
        while ([fManager fileExistsAtPath:useFilename])
        {
            useFilename = [NSString stringWithFormat:@"%@-%d.%@", noExt, fidx, pathExt];
            fidx++;
        }
    }
    return useFilename;
}



-(void)prepareForStreamStart
{
    return;
}


-(void)newFrameEvent
{
    _frame_time = [self mach_time_seconds];
    [self newFrame];
}


-(void)frameArrived:(id)ctx
{
    dispatch_async(_frame_queue, ^{
        if (self.recordingActive)
        {
            [self newFrameEvent];
        }
    });
}

-(void)frameTimerWillStop:(id)ctx
{
    dispatch_async(_frame_queue, ^{
        [self newFrameTimed];
    });
}


-(void) newFrameTimed
{
    
    double startTime;
    double start_t, end_t, elapsed_t;
    
    startTime = [[CaptureController sharedCaptureController] mach_time_seconds];
    
    _frame_time = startTime;
    _firstFrameTime = startTime;
    
    [self newFrame];
    
    while (1)
    {
        @autoreleasepool {
            
            
            if (self.layout.layoutTimingSource && self.layout.layoutTimingSource.videoInput && self.layout.layoutTimingSource.videoInput.canProvideTiming)
            {
                CSCaptureBase *newTiming = (CSCaptureBase *)self.layout.layoutTimingSource.videoInput;
                newTiming.timerDelegateCtx = nil;
                newTiming.timerDelegate = self;
                return;
            }
            
            
            
            
            //_frame_time = nowTime;//startTime;
            
            startTime += 1.0/self.layout.frameRate;
            
            if (![[CaptureController sharedCaptureController] sleepUntil:startTime])
            {
                NSLog(@"SLEEP UNTIL %f CURRENT TIME %f LAYOUT %@ %@", startTime, [[CaptureController sharedCaptureController] mach_time_seconds], self.layout.name, NSThread.currentThread);
                continue;
            }
            //NSLog(@"SLEPT %f %f", end_time - start_time, self.layout.frameRate);
            
            int drain_cnt = 0;
            if (!self.recordingActive)
            {
                
                NSMutableDictionary *useCompressors = self.compressors.copy;

                for(id cKey in useCompressors)
                {
                    
                    id <VideoCompressor> compressor;
                    compressor = useCompressors[cKey];
                    drain_cnt += [compressor drainOutputBufferFrame];
                }

                if (!drain_cnt)
                {
                    return;
                }
            }
            
            
            _frame_time = startTime;
            start_t = [CaptureController.sharedCaptureController mach_time_seconds];
            [self newFrame];
            end_t = [CaptureController.sharedCaptureController mach_time_seconds];
            elapsed_t = end_t - start_t;
            if (elapsed_t > 1.0/self.layout.frameRate)
            {
                NSLog(@"NEW FRAME TOOK %f", elapsed_t);
            }
            
        }
    }
}

-(void) newFrame
{
    double start_t,end_t, elapsed_t;
    
    CVPixelBufferRef newFrame;
    
    //double nfstart = [self mach_time_seconds];

    start_t = [CaptureController.sharedCaptureController mach_time_seconds];
    newFrame = [self.renderer currentImg];
    end_t = [CaptureController.sharedCaptureController mach_time_seconds];
    elapsed_t = end_t - start_t;
    if (elapsed_t > 1.0f/60.0f)
    {
        NSLog(@"RENDER TOOK %f", elapsed_t);
    }
    if (self.frameReadyBlock)
    {
        self.frameReadyBlock();
    }
    
    /*
    double nfdone = [self mach_time_seconds];
    double nftime = nfdone - nfstart;
    _renderedFrames++;
    
    _render_time_total += nftime;
    if (nftime < _min_render_time || _min_render_time == 0.0f)
    {
        _min_render_time = nftime;
    }
    
    if (nftime > _max_render_time)
    {
        _max_render_time = nftime;
    }
    */
    

    if (newFrame && self.compressors && self.compressors.count > 0)
    {
        _frameCount++;
        CVPixelBufferRetain(newFrame);



        
        CapturedFrameData *newData = [self createFrameData];
        
        for(NSString *trackName in _audioBuffers)
        {
            NSMutableArray *frameAudio = [[NSMutableArray alloc] init];
            [self setAudioData:frameAudio videoPTS:CMTimeMake((_frame_time - _firstFrameTime)*1000, 1000) forTrack:trackName];
            newData.audioSamples[trackName] = frameAudio;
        }
        
        for(NSString *trackName in _pcmAudioBuffers)
        {
            NSMutableArray *pcmFrameAudio = [[NSMutableArray alloc] init];
            [self setPcmAudioData:pcmFrameAudio videoPTS:CMTimeMake((_frame_time - _firstFrameTime)*1000, 1000) forTrack:trackName];
            newData.pcmAudioSamples[trackName] = pcmFrameAudio;
        }
        
        newData.videoFrame = newFrame;
        
        int used_compressor_count = 0;
        start_t = [CaptureController.sharedCaptureController mach_time_seconds];

        NSMutableDictionary *useCompressors = self.compressors.copy;
        
        for(id cKey in useCompressors)
        {
            
            id <VideoCompressor> compressor;
            compressor = useCompressors[cKey];
            CapturedFrameData *newFrameData = newData.copy;
            double c_start = [CaptureController.sharedCaptureController mach_time_seconds];
            [compressor compressFrame:newFrameData];
            double c_end = [CaptureController.sharedCaptureController mach_time_seconds];
            double c_elapsed = c_end - c_start;
            
            if (c_elapsed > 1.0f/60.0f)
            {
                NSLog(@"COMPRESSOR %@ TOOK %f %@", compressor, c_elapsed, self.layout.name);
            }
            
            if ([compressor hasOutputs])
            {
                used_compressor_count++;
            }
        }
        end_t = [CaptureController.sharedCaptureController mach_time_seconds];
        elapsed_t = end_t - start_t;
        if (elapsed_t > 1.0f/60.0f)
        {
            NSLog(@"COMPRESSOR STUFF TOOK %f %@", elapsed_t, self.layout.name);
        }
        
        CVPixelBufferRelease(newFrame);
        if (used_compressor_count == 0)
        {
            //[self stopRecordingAll];
        }
        
    }
}

-(CapturedFrameData *)createFrameData
{
    
    CMTime pts = CMTimeMake((_frame_time - _firstFrameTime)*1000, 1000);
    
    CMTime duration = CMTimeMake(1, self.layout.frameRate);
    
    CapturedFrameData *newFrameData = [[CapturedFrameData alloc] init];
    newFrameData.videoPTS = pts;
    newFrameData.videoDuration = duration;
    newFrameData.frameNumber = _frameCount;
    newFrameData.frameTime = _frame_time;
    return newFrameData;
}


-(CFAbsoluteTime) mach_time_seconds
{
    return [[CaptureController sharedCaptureController] mach_time_seconds];
}

-(void)createBuffersForTrack:(NSString *)trackName
{
    @synchronized (self) {
    if (!_audioBuffers[trackName])
    {
        _audioBuffers[trackName] = [[RecAudioBufferData alloc] init];
    }
    
    if (!_pcmAudioBuffers[trackName])
    {
        _pcmAudioBuffers[trackName] = [[RecAudioBufferData alloc] init];
    }
    }
}


-(void) addPcmAudioData:(CMSampleBufferRef)audioData forTrack:(NSString *)trackName
{
    
    @synchronized(self)
    {
        RecAudioBufferData *pcmBuffer = _pcmAudioBuffers[trackName];
        if (!pcmBuffer)
        {
            pcmBuffer = [[RecAudioBufferData alloc] init];
            _pcmAudioBuffers[trackName] = pcmBuffer;
        }
        [pcmBuffer.audiobuffer addObject:(__bridge id)audioData];
    }
}


-(void) addAudioData:(CMSampleBufferRef)audioData forTrack:(NSString *)trackName
{
    
    @synchronized(self)
    {

        RecAudioBufferData *audioBuffer = _audioBuffers[trackName];
        if (!audioBuffer)
        {
            audioBuffer = [[RecAudioBufferData alloc] init];
            _audioBuffers[trackName] = audioBuffer;
        }
        [audioBuffer.audiobuffer addObject:(__bridge id)audioData];
    }
}


-(void)setPcmAudioData:(NSMutableArray *)audioDestination videoPTS:(CMTime)videoPTS forTrack:(NSString *)trackName
{
    NSUInteger audioConsumed = 0;
    NSUInteger sampleCount = 0;
    
    
    @synchronized(self)
    {
        RecAudioBufferData *pcmBuffer = _pcmAudioBuffers[trackName];
        if (!pcmBuffer)
        {
            return;
        }
        
        NSUInteger audioBufferSize = [pcmBuffer.audiobuffer count];
        
        for (int i = 0; i < audioBufferSize; i++)
        {
            CMSampleBufferRef audioData = (__bridge CMSampleBufferRef)[pcmBuffer.audiobuffer objectAtIndex:i];
            
            CMTime audioTime = CMSampleBufferGetOutputPresentationTimeStamp(audioData);
            
            
            
            
            if (CMTIME_COMPARE_INLINE(audioTime, <=, videoPTS))
            {
                sampleCount += CMSampleBufferGetNumSamples(audioData);
                audioConsumed++;
                [audioDestination addObject:(__bridge id)audioData];
            } else {
                break;
            }
        }
        
        if (audioConsumed > 0)
        {
            [pcmBuffer.audiobuffer removeObjectsInRange:NSMakeRange(0, audioConsumed)];
        }
        
    }
}

-(void) setAudioData:(NSMutableArray *)audioDestination videoPTS:(CMTime)videoPTS forTrack:(NSString *)trackName
{
    
    NSUInteger audioConsumed = 0;
    @synchronized(self)
    {
        RecAudioBufferData *audioBuffer = _audioBuffers[trackName];
        if (!audioBuffer)
        {
            return;
        }
        
        NSUInteger audioBufferSize = [audioBuffer.audiobuffer count];
        
        for (int i = 0; i < audioBufferSize; i++)
        {
            CMSampleBufferRef audioData = (__bridge CMSampleBufferRef)[audioBuffer.audiobuffer objectAtIndex:i];
            
            CMTime audioTime = CMSampleBufferGetOutputPresentationTimeStamp(audioData);
            
            
            
            
            if (CMTIME_COMPARE_INLINE(audioTime, <=, videoPTS))
            {
                
                audioConsumed++;
                [audioDestination addObject:(__bridge id)audioData];
            } else {
                break;
            }
        }
        
        if (audioConsumed > 0)
        {
            [audioBuffer.audiobuffer removeObjectsInRange:NSMakeRange(0, audioConsumed)];
        }
        
    }
}

-(void)captureOutputAudio:(NSString *)withTag didOutputPCMSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (!self.recordingActive)
    {
        return;
    }
    RecAudioBufferData *pcmBuffer = _pcmAudioBuffers[withTag];
    if (!pcmBuffer)
    {

        [self createBuffersForTrack:withTag];
        pcmBuffer = _pcmAudioBuffers[withTag];
    }
    
    
    CMTime orig_pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    
    
    if (CMTIME_COMPARE_INLINE(_firstPcmAudioTime, ==, kCMTimeZero))
    {
        
        _firstPcmAudioTime = orig_pts;
        return;
    }
    
    
    CMTime pts = CMTimeSubtract(orig_pts, _firstPcmAudioTime);
    //CMTime adjust_pts = CMTimeMakeWithSeconds(self.audio_adjust, orig_pts.timescale);
    //CMTime pts = CMTimeAdd(real_pts, adjust_pts);
    
    
    
    CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, pts);
    
    if (CMTIME_COMPARE_INLINE(pts, >, pcmBuffer.previousAudioTime))
    {
        if (sampleBuffer)
        {
            [self addPcmAudioData:sampleBuffer forTrack:withTag];
        }
        pcmBuffer.previousAudioTime = pts;
    }
}


- (void)captureOutputAudio:(NSString *)withTag didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    if (!self.recordingActive)
    {
        return;
    }
    
    RecAudioBufferData *audioBuffer = _audioBuffers[withTag];
    if (!audioBuffer)
    {
        [self createBuffersForTrack:withTag];
        audioBuffer = _audioBuffers[withTag];
    }
    
    CMTime orig_pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    
    
    
    if (CMTIME_COMPARE_INLINE(_firstAudioTime, ==, kCMTimeZero))
    {
        
        
        _firstAudioTime = orig_pts;
        return;
    }
    
    
    CMTime pts = CMTimeSubtract(orig_pts, _firstAudioTime);
    //CMTime adjust_pts = CMTimeMakeWithSeconds(self.audio_adjust, orig_pts.timescale);
    //CMTime pts = CMTimeAdd(real_pts, adjust_pts);
    
    CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, pts);
    if (CMTIME_COMPARE_INLINE(pts, >, audioBuffer.previousAudioTime))
    {
        if (sampleBuffer)
        {
            [self addAudioData:sampleBuffer forTrack:withTag];
        }
        audioBuffer.previousAudioTime = pts;
    }
}

-(void)dealloc
{
    if (self.audioEngine)
    {
        [self.audioEngine removeObserver:self forKeyPath:@"outputTracks.@allKeys"];
    }
}
@end
