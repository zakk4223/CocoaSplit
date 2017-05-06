//
//  CSLayoutRecorder.m
//  CocoaSplit
//
//  Created by Zakk on 4/30/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSLayoutRecorder.h"
#import "CaptureController.h"

@implementation CSLayoutRecorder



-(void)stopRecording
{
    if (self.output)
    {
        [self.output stopOutput];
    }
    self.layout.recordingLayout = NO;
}


-(void)startRecording
{
    
    self.useTimestamp = YES;
    
    
    self.outputFilename = [self.baseDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.%@", self.layout.name, self.fileFormat]];
    
    _firstAudioTime = kCMTimeZero;
    _previousAudioTime = kCMTimeZero;

    
    _audioBuffer = [NSMutableArray array];
    self.renderer = [[LayoutRenderer alloc] init];
    [self.layout restoreSourceList:nil];
    self.renderer.layout = self.layout;
    
    NSObject<VideoCompressor> *origCompressor = [CaptureController sharedCaptureController].compressors[self.compressor_name];
    
    self.compressor = origCompressor.copy;
    
    self.output = [[OutputDestination alloc] init];
    self.output.settingsController = [CaptureController sharedCaptureController];
    self.output.streamServiceObject = (id<CSStreamServiceProtocol>)self;
    self.output.compressor = self.compressor;
    self.audioEngine = [[CAMultiAudioEngine alloc] init];
    self.audioEngine.sampleRate = [CaptureController sharedCaptureController].audioSamplerate;
    
    NSDictionary *inputSettings = [[CaptureController sharedCaptureController].multiAudioEngine generateInputSettings];
    [self.audioEngine applyInputSettings:inputSettings];
    self.audioEncoder = [[CSAacEncoder alloc] init];
    self.audioEncoder.encodedReceiver = self;
    self.audioEncoder.sampleRate = [CaptureController sharedCaptureController].audioSamplerate;
    self.audioEncoder.bitRate = [CaptureController sharedCaptureController].audioBitrate*1000;
    
    self.audioEncoder.inputASBD = self.audioEngine.graph.graphAsbd;
    [self.audioEncoder setupEncoderBuffer];
    self.audioEngine.encoder = self.audioEncoder;
    
    
    if (!_frame_queue)
    {
        _frame_queue = dispatch_queue_create("layout.recorder.queue", DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async(_frame_queue, ^{
        [self newFrameTimed];
    });
    self.output.captureRunning = YES;
    self.output.active = YES;
    self.layout.recordingLayout = YES;

    
}




-(NSString *)getServiceFormat
{
    return nil;
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

-(void) newFrameTimed
{
    
    double startTime;
    
    startTime = [[CaptureController sharedCaptureController] mach_time_seconds];
    
    _frame_time = startTime;
    _firstFrameTime = startTime;
    [self newFrame];
    
    //[self setFrameThreadPriority];
    while (1)
    {
        
 /*
        if (self.previewCtx.sourceLayout.layoutTimingSource && self.previewCtx.sourceLayout.layoutTimingSource.videoInput && self.previewCtx.sourceLayout.layoutTimingSource.videoInput.canProvideTiming)
        {
            CSCaptureBase *newTiming = (CSCaptureBase *)self.previewCtx.sourceLayout.layoutTimingSource.videoInput;
            newTiming.timerDelegateCtx = self.previewCtx;
            newTiming.timerDelegate = self;
            return;
        }
        
  */
        
        
        
        //_frame_time = nowTime;//startTime;
        
        
        if (![[CaptureController sharedCaptureController] sleepUntil:(startTime += 1.0/self.layout.frameRate)])
        {
            //NSLog(@"MISSED FRAME!");
            continue;
        }
        
        
        
        _frame_time = startTime;
        @autoreleasepool {
            
            [self newFrame];
        }
        
    }
}

-(void) newFrame
{
    
    CVPixelBufferRef newFrame;
    
    //double nfstart = [self mach_time_seconds];
    
    newFrame = [self.renderer currentImg];
    
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
    
    
    if (newFrame)
    {
        _frameCount++;
        CVPixelBufferRetain(newFrame);
        NSMutableArray *frameAudio = [[NSMutableArray alloc] init];
        [self setAudioData:frameAudio videoPTS:CMTimeMake((_frame_time - _firstFrameTime)*1000, 1000)];
        CapturedFrameData *newData = [self createFrameData];
        newData.audioSamples = frameAudio;
        newData.videoFrame = newFrame;
        
        if (self.compressor)
        {
            [self.compressor compressFrame:newData];
        }
        
        
            
        CVPixelBufferRelease(newFrame);
        
        
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


-(void) addAudioData:(CMSampleBufferRef)audioData
{
    
    @synchronized(self)
    {
        
        [_audioBuffer addObject:(__bridge id)audioData];
    }
}


-(void) setAudioData:(NSMutableArray *)audioDestination videoPTS:(CMTime)videoPTS
{
    
    NSUInteger audioConsumed = 0;
    @synchronized(self)
    {
        NSUInteger audioBufferSize = [_audioBuffer count];
        
        for (int i = 0; i < audioBufferSize; i++)
        {
            CMSampleBufferRef audioData = (__bridge CMSampleBufferRef)[_audioBuffer objectAtIndex:i];
            
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
            [_audioBuffer removeObjectsInRange:NSMakeRange(0, audioConsumed)];
        }
        
    }
}

- (void)captureOutputAudio:(id)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    
    CMTime orig_pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    
    
    
    if (CMTIME_COMPARE_INLINE(_firstAudioTime, ==, kCMTimeZero))
    {
        
        NSLog(@"FIRST AUDIO AT %f", CFAbsoluteTimeGetCurrent());
        
        _firstAudioTime = orig_pts;
        return;
    }
    
    
    CMTime pts = CMTimeSubtract(orig_pts, _firstAudioTime);
    //CMTime adjust_pts = CMTimeMakeWithSeconds(self.audio_adjust, orig_pts.timescale);
    //CMTime pts = CMTimeAdd(real_pts, adjust_pts);
    
    
    
    CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, pts);
    
    if (CMTIME_COMPARE_INLINE(pts, >, _previousAudioTime))
    {
        [self addAudioData:sampleBuffer];
        _previousAudioTime = pts;
    }
}


@end
