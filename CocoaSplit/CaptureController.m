
//
//  CaptureController.m
//  H264Streamer
//
//  Created by Zakk on 9/2/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "CaptureController.h"
#import "FFMpegTask.h"
#import "SyphonCapture.h"
#import "OutputDestination.h"
#import "DesktopCapture.h"
#import "PreviewView.h"
#import <IOSurface/IOSurface.h>


@implementation CaptureController




-(IBAction)openCreateSheet:(id)sender
{
    
    if (!_createSheet)
    {
        NSString *panelName;
        
        self.streamingDestination = nil;
        
        
        //if ([self.selectedDestinationType isEqualToString:@"file"])
        //{
            panelName = @"FilePanel";
        //} else {
          //  panelName = @"StreamServicePanel";
        //}
        
        [NSBundle loadNibNamed:panelName owner:self];
    }
    
    [NSApp beginSheet:self.createSheet modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
}


-(IBAction)closeCreateSheet:(id)sender
{
    
    [NSApp endSheet:self.createSheet];
    [self.createSheet close];
    self.createSheet = nil;
}

-(void) selectedAudioCaptureFromID:(NSString *)uniqueID
{
    self.selectedAudioCapture = [AVCaptureDevice deviceWithUniqueID:uniqueID];
}



-(void) selectedVideoCaptureFromID:(NSString *)uniqueID
{
    
    AbstractCaptureDevice *dummydev = [[AbstractCaptureDevice alloc] init];
    
    dummydev.uniqueID = uniqueID;
    
    NSUInteger sidx;
    sidx = [self.videoCaptureDevices indexOfObject:dummydev];
    if (sidx == NSNotFound)
    {
        self.selectedVideoCapture = nil;
    } else {
        self.selectedVideoCapture = [self.videoCaptureDevices objectAtIndex:sidx];
    }
}

-(IBAction) videoRefresh:(id)sender
{
    
    self.videoCaptureDevices = [_video_capture_session availableVideoDevices];
    if (self.selectedVideoCapture)
    {
        NSUInteger sidx;
        sidx = [self.videoCaptureDevices indexOfObject:self.selectedVideoCapture];
        if (sidx == NSNotFound)
        {
            self.selectedVideoCapture = nil;
        } else {
            self.selectedVideoCapture = [self.videoCaptureDevices objectAtIndex:sidx];
        }
    }
}



-(NSString *) selectedVideoType
{
    return _selectedVideoType;
}



-(void) setSelectedVideoType:(NSString *)selectedVideoType
{
    if ([selectedVideoType isEqualToString:@"Desktop"])
    {
        _video_capture_session = [[DesktopCapture alloc ] init];
    } else if ([selectedVideoType isEqualToString:@"AVFoundation"]) {
        _video_capture_session = [[AVFCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"QTCapture"]) {
        _video_capture_session = [[QTCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Syphon"]) {
        _video_capture_session = [[SyphonCapture alloc] init];
    } else {
        _video_capture_session = nil;
    }
    
    if (!_video_capture_session)
    {
        _audio_capture_session  = nil;
        _selectedVideoType = nil;
    }
    
    if ([_video_capture_session providesAudio])
    {
        _audio_capture_session = _video_capture_session;
    } else {
        _audio_capture_session = [[AVFCapture alloc] init];
    }
    
    self.videoCaptureDevices = [_video_capture_session availableVideoDevices];
    self.audioCaptureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    self.selectedVideoCapture = nil;
    
    _selectedVideoType = selectedVideoType;
}


-(id) init
{
   if (self = [super init])
   {
       /*
       self.destinationTypes = @{  
       @"twitchtv" : @"Twitch.tv/Justin.tv",
       @"own3dtv" : @"Own3d.tv",
       @"file" : @"Local File" };
       */

       dispatch_source_t sigsrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGPIPE, 0, dispatch_get_global_queue(0, 0));
       dispatch_source_set_event_handler(sigsrc, ^{ return;});
       dispatch_resume(sigsrc);
       
       self.destinationTypes = @{@"file" : @"Local File",
       @"rtmp" : @"RTMP Stream"};
       
       
       self.videoTypes = @[@"Desktop", @"AVFoundation", @"QTCapture"];
       self.selectedVideoType = [self.videoTypes objectAtIndex:0];
       
       
   }
    
    return self;
    
}


- (NSString *) saveFilePath
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *saveFolder = @"~/Library/Application Support/H264Streamer";
    
    saveFolder = [saveFolder stringByExpandingTildeInPath];
    
    if ([fileManager fileExistsAtPath:saveFolder] == NO)
    {
        [fileManager createDirectoryAtPath:saveFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *saveFile = @"H264Streamer.settings";
    
    return [saveFolder stringByAppendingPathComponent:saveFile];
}


-(void) saveSettings
{
    
    NSString *path = [self saveFilePath];
    
    NSMutableDictionary *saveRoot;
    
    saveRoot = [NSMutableDictionary dictionary];
    
    [saveRoot setValue: [NSNumber numberWithInt:self.captureWidth] forKey:@"captureWidth"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureHeight] forKey:@"captureHeight"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureFPS] forKey:@"captureFPS"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureVideoAverageBitrate] forKey:@"captureVideoAverageBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioBitrate] forKey:@"audioBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioSamplerate] forKey:@"audioSamplerate"];
    [saveRoot setValue: self.selectedVideoType forKey:@"selectedVideoType"];
    [saveRoot setValue: self.selectedVideoCapture.uniqueID forKey:@"videoCaptureID"];
    [saveRoot setValue: self.selectedAudioCapture.uniqueID forKey:@"audioCaptureID"];
    [saveRoot setValue: self.captureDestinations forKey:@"captureDestinations"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureVideoMaxBitrate] forKey:@"captureVideoMaxBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureVideoMaxKeyframeInterval] forKey:@"captureVideoMaxKeyframeInterval"];
    
    
    [NSKeyedArchiver archiveRootObject:saveRoot toFile:path];
    
}


-(void) loadSettings
{
    
    NSString *path = [self saveFilePath];
    NSDictionary *saveRoot;
    
    saveRoot = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    self.captureWidth = [[saveRoot valueForKey:@"captureWidth"] intValue];
    self.captureHeight = [[saveRoot valueForKey:@"captureHeight"] intValue];
    self.captureFPS = [[saveRoot valueForKey:@"captureFPS"] intValue];
    self.captureVideoAverageBitrate = [[saveRoot valueForKey:@"captureVideoAverageBitrate"] intValue];
    self.captureVideoMaxBitrate = [[saveRoot valueForKey:@"captureVideoMaxBitrate"] intValue];
    self.captureVideoMaxKeyframeInterval = [[saveRoot valueForKey:@"captureVideoMaxKeyframeInterval"] intValue];
    self.audioBitrate = [[saveRoot valueForKey:@"audioBitrate"] intValue];
    self.audioSamplerate = [[saveRoot valueForKey:@"audioSamplerate"] intValue];
    self.captureDestinations = [saveRoot valueForKey:@"captureDestinations"];
    
    if (!self.captureDestinations)
    {
        self.captureDestinations = [[NSMutableArray alloc] init];
    }
    
    
    
    self.selectedVideoType = [saveRoot valueForKey:@"selectedVideoType"];
    NSString *videoID = [saveRoot valueForKey:@"videoCaptureID"];
    
    [self selectedVideoCaptureFromID:videoID];
    
    NSString *audioID = [saveRoot valueForKey:@"audioCaptureID"];
    
    [self selectedAudioCaptureFromID:audioID];
    
}




- (IBAction)ffmpegPathPushed:(id)sender {
    
    NSOpenPanel *filepanel = [NSOpenPanel openPanel];
    
    [filepanel setCanChooseFiles:YES];
    [filepanel setAllowsMultipleSelection:FALSE];
    
    if ([filepanel runModal] == NSOKButton)
    {
        NSURL *fpath = [filepanel URL];
        [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[fpath path] forKey:@"ffmpeg_path"];
        
    }
}



- (IBAction)addStreamingService:(id)sender {
    
    
    OutputDestination *newDest;
    
    newDest = [[OutputDestination alloc] initWithType:_selectedDestinationType];
    newDest.server_name = _streamingServiceServer;
    newDest.stream_key = _streamingServiceKey;
    newDest.destination = _streamingDestination;
    
    
    [[self mutableArrayValueForKey:@"captureDestinations"] addObject:newDest];
    [self attachCaptureDestination:newDest];
    [self closeCreateSheet:nil];
    
}

-(void)attachCaptureDestination:(OutputDestination *)output
{
    FFMpegTask *newout;
    
    
    newout = [[FFMpegTask alloc] init];
    newout.height = _captureHeight;
    newout.width = _captureWidth;
    newout.framerate = _captureFPS;
    newout.stream_output = output.destination;
    newout.stream_format = output.output_format;
    newout.samplerate = _audioSamplerate;
    output.ffmpeg_out = newout;
}






- (IBAction)streamButtonPushed:(id)sender {
    
    NSButton *button = (NSButton *)sender;
    
    
    if ([button state] == NSOnState)
    {
        
        
        // We should already have a capture session from init since we need it to figure out device lists.
        
    
        NSError *error;
        bool success;
        
        
        
        [_audio_capture_session setActiveAudioDevice:_selectedAudioCapture];
        [_video_capture_session setActiveVideoDevice:_selectedVideoCapture];
        [_video_capture_session setVideoCaptureFPS:_captureFPS];
        [_video_capture_session setVideoDelegate:self];
        [_video_capture_session setVideoDimensions:_captureWidth height:_captureHeight];
        [_audio_capture_session setAudioDelegate:self];
        [_audio_capture_session setAudioBitrate:_audioBitrate];
        [_audio_capture_session setAudioSamplerate:_audioSamplerate];
        
        
        success = [_video_capture_session setupCaptureSession:&error];
        if (!success)
        {
            [NSApp presentError:error];
            [sender setNextState];
            return;
        }
        success = [_audio_capture_session setupCaptureSession:&error];
        if (!success)
        {
            [NSApp presentError:error];
            [sender setNextState];
            return;
        }

        
        success = [self setupCompression:&error];
    
        if (!success)
        {
            NSLog(@"Failed compression setup");
            [NSApp presentError:error];
            [sender setNextState];
            return;
        }
    
        OutputDestination *output;
        
        
        for (output in _captureDestinations)
        {
            [self attachCaptureDestination:output];
        }
        
        
        success = [_video_capture_session startCaptureSession:&error];
        
        _frameCount = 0;
        _compressedFrameCount = 0;
        _min_delay = _max_delay = _avg_delay = 0;
        
        _captureTimer = [NSTimer timerWithTimeInterval:1.0/_captureFPS target:self selector:@selector(newFrame) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_captureTimer forMode:NSRunLoopCommonModes];

        if (!success)
        {
            NSLog(@"Failed start capture");
            [NSApp presentError:error];
            [sender setNextState];
            return;
        }
        success = [_audio_capture_session startCaptureSession:&error];
        
        
        
        if (!success)
        {
            NSLog(@"Failed start capture");
            [NSApp presentError:error];
            [sender setNextState];
            return;
        }

    } else {
        

        if (_captureTimer)
        {
            [_captureTimer invalidate];
            
            
        }
        if (_compression_session)
        {
            VTCompressionSessionInvalidate(_compression_session);
            CFRelease(_compression_session);
        }
        
        
        if (_video_capture_session)
        {
            [_video_capture_session stopCaptureSession];
        }
        
        if (_audio_capture_session)
        {
            [_audio_capture_session stopCaptureSession];
        }

        
        
        for (OutputDestination *out in _captureDestinations)
        {
            [out stopOutput];
        }
    
    }
    
}

- (bool)setupCompression:(NSError **)error
{
    OSStatus status;
    NSDictionary *encoder_spec = @{@"EnableHardwareAcceleratedVideoEncoder": @1};
       
    
    if (!_captureHeight || !_captureHeight)
    {
        *error = [NSError errorWithDomain:@"videoCapture" code:120 userInfo:@{NSLocalizedDescriptionKey : @"Width and Height must be non-zero"}];
        return NO;
        
    }
    
    status = VTCompressionSessionCreate(NULL, _captureWidth, _captureHeight, 'avc1', (__bridge CFDictionaryRef)encoder_spec, NULL, NULL, VideoCompressorReceiveFrame,  (__bridge void *)self, &_compression_session);

    //If priority isn't set to -20 the framerate in the SPS/VUI section locks to 25. With -20 it takes on the value of
    //whatever ExpectedFrameRate is. I have no idea what the fuck, but it works.
    
    VTSessionSetProperty(_compression_session, (CFStringRef)@"Priority", (__bridge CFTypeRef)(@-20));
    VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    //VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)(@30));
    
    
    if (self.captureVideoMaxKeyframeInterval && self.captureVideoMaxKeyframeInterval)
    {
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)(@(self.captureVideoMaxKeyframeInterval)));
    }
    
    if (self.captureVideoMaxBitrate && self.captureVideoMaxBitrate > 0)
    {
        
        int real_bitrate = self.captureVideoMaxBitrate*128; // In bytes (1024/8)
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFTypeRef)(@[@(real_bitrate), @1]));
        
    }
    
    
    if (_captureVideoAverageBitrate > 0)
    {
        int real_bitrate = _captureVideoAverageBitrate*1024;
                            
        NSLog(@"Setting bitrate to %d", real_bitrate);
        
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_AverageBitRate, CFNumberCreate(NULL, kCFNumberIntType, &real_bitrate));
        
    }
    
    if (_captureFPS && _captureFPS > 0)
    {
        
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_ExpectedFrameRate, CFNumberCreate(NULL, kCFNumberIntType, &_captureFPS));
        
    }
    
    return YES;
    
}


-  (void)newFrame
{
    
    CVImageBufferRef cFrame;
    cFrame = [_video_capture_session getCurrentFrame];
    
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    
    if (_frameCount == 0)
    {
        _firstFrameTime = currentTime;
    }
    
    _frameCount++;
    if ((_frameCount % 15) == 0)
    {
        [self updateStatusString];
    }

    
    
    [self.previewCtx drawFrame:cFrame];
    
    
    [self captureOutputVideo:_video_capture_session didOutputSampleBuffer:nil didOutputImage:cFrame frameTime:0 ];
    
}

- (void)captureOutputAudio:(id)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    
    
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    CMTime pts = CMTimeMake(currentTime*1000, 1000);

    CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, pts);
    
    
    for (OutputDestination *outdest in _captureDestinations)
    {
        if (outdest.active)
        {
            id ffmpeg = outdest.ffmpeg_out;
            [ffmpeg writeAudioSampleBuffer:sampleBuffer presentationTimeStamp:pts];
        }
    }
    
}



-(void)updateStatusString
{
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    self.statusString = [NSString stringWithFormat:@"%lld frames %3.2f frames/sec", _frameCount, _frameCount/(currentTime-_firstFrameTime)];
    self.compressionStatusString = [NSString stringWithFormat:@"Delay min/max/avg 0/%2.3f/%2.3f", self.max_delay, self.avg_delay];
}


- (void)captureOutputVideo:(AbstractCaptureDevice *)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer didOutputImage:(CVImageBufferRef)imageBuffer frameTime:(uint64_t)frameTime
{

    CMTime pts;
    CMTime duration;
    
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    pts = CMTimeMake(currentTime*1000, 1000);
    
    
    duration = CMTimeMake(1, _captureFPS);
    
    if(!imageBuffer)
        return;
    
    VTCompressionSessionEncodeFrame(_compression_session, imageBuffer, pts, duration, NULL, imageBuffer, NULL);
    CVPixelBufferRelease(imageBuffer); //VTCompression should retain it?
}

void VideoCompressorReceiveFrame(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    
    @autoreleasepool {
        if(!sampleBuffer)
            return;
 
        CaptureController *selfobj = (__bridge CaptureController *)VTref;

        double frame_delay = 0;
        
        CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
        CFAbsoluteTime sample_time = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer));
        
        frame_delay = currentTime - sample_time;
        
        selfobj.avg_delay = ((selfobj.avg_delay * selfobj.compressedFrameCount)+frame_delay)/++selfobj.compressedFrameCount;
        if (frame_delay > selfobj.max_delay)
        {
            selfobj.max_delay = frame_delay;
        }
        
        //selfobj.compressedFrameCount++;

        
    CFRetain(sampleBuffer);
        
    for (id od in selfobj.captureDestinations)
    {
        if ([od active])
        {
            
            [[od ffmpeg_out] writeVideoSampleBuffer:sampleBuffer];
        }
    }
    CFRelease(sampleBuffer);
    }
}


- (void) setNilValueForKey:(NSString *)key
{
    
    NSUInteger key_idx = [@[@"captureWidth", @"captureHeight", @"captureFPS",
    @"captureVideoAverageBitrate", @"audioBitrate", @"audioSamplerate", @"captureVideoMaxBitrate", @"captureVideoMaxKeyframeInterval"] indexOfObject:key];
    
    if (key_idx != NSNotFound)
    {
        return [self setValue:[NSNumber numberWithInt:0] forKey:key];
    }
    
    [super setNilValueForKey:key];
}


- (IBAction)removeDestination:(id)sender
{
    [self.selectedCaptureDestinations enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger idx, BOOL *stop) {
        OutputDestination *to_delete = [[self mutableArrayValueForKey:@"captureDestinations"] objectAtIndex:idx];
        to_delete.active = NO;
        [[self mutableArrayValueForKey:@"captureDestinations"] removeObjectAtIndex:idx];
        
    }];
    
    NSLog(@"OUTPUT DESTINATIONS %@", self.captureDestinations);
}
@end
