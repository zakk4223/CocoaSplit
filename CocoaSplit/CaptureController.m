
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
#import "CaptureSessionProtocol.h"

@implementation CaptureController



-(void)loadTwitchIngest
{
    
    NSString *apiString = @"https://api.twitch.tv/kraken/ingests";
    
    NSURL *apiURL = [NSURL URLWithString:apiString];
    
    NSMutableURLRequest *apiRequest = [NSMutableURLRequest requestWithURL:apiURL];
    
    [NSURLConnection sendAsynchronousRequest:apiRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *err) {
        
        NSError *jsonError;
        NSDictionary *ingest_response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        //Handle error
        
        NSArray *ingest_list = [ingest_response objectForKey:@"ingests"];
        
        NSMutableArray *cooked_ingests = [[NSMutableArray alloc] init];
        
        for (NSDictionary *tw_ingest in ingest_list)
        {
        
            NSMutableDictionary *ingest_map = [[NSMutableDictionary alloc] init];
            
            NSString *url_temp = [tw_ingest objectForKey:@"url_template"];
            NSString *name = [tw_ingest objectForKey:@"name"];
            
            
            
            if (!url_temp || !name)
            {
                continue;
            }
            
            [ingest_map setValue: url_temp forKey:@"destination"];
            [ingest_map setValue:name forKey:@"name"];
            [cooked_ingests addObject:ingest_map];
            
        }

        dispatch_async(dispatch_get_main_queue(), ^{self.streamPanelDestinations = cooked_ingests; });

        
        
        return;
    }];
}



-(IBAction)openCreateSheet:(id)sender
{
    
    if (!_createSheet)
    {
        NSString *panelName;
        
        self.streamingDestination = nil;
        
        
        if ([self.selectedDestinationType isEqualToString:@"file"])
        {
            panelName = @"FilePanel";
        } else if ([self.selectedDestinationType isEqualToString:@"twitch"]) {
            [self loadTwitchIngest];
            panelName = @"StreamServicePanel";
        } else {
            panelName = @"FilePanel";
        }
        
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
    
    NSArray *currentAvailableDevices;
    
    currentAvailableDevices = self.videoCaptureSession.availableVideoDevices;
    
    NSUInteger sidx;
    sidx = [currentAvailableDevices indexOfObject:dummydev];
    if (sidx == NSNotFound)
    {
        self.videoCaptureSession.activeVideoDevice = nil;
    } else {
        self.videoCaptureSession.activeVideoDevice = [currentAvailableDevices objectAtIndex:sidx];
    }
}

-(IBAction) videoRefresh:(id)sender
{
    
    NSArray *currentAvailableDevices = self.videoCaptureSession.availableVideoDevices;
    
    if (self.selectedVideoCapture)
    {
        NSUInteger sidx;
        sidx = [currentAvailableDevices indexOfObject:self.selectedVideoCapture];
        if (sidx == NSNotFound)
        {
            self.selectedVideoCapture = nil;
        } else {
            self.selectedVideoCapture = [currentAvailableDevices objectAtIndex:sidx];
        }
    }
}



-(NSString *) selectedVideoType
{
    return _selectedVideoType;
}



-(void) setSelectedVideoType:(NSString *)selectedVideoType
{
    
    NSLog(@"SETTING SELECTED VIDEO TYPE");
    if ([selectedVideoType isEqualToString:@"Desktop"])
    {
        self.videoCaptureSession = [[DesktopCapture alloc ] init];
    } else if ([selectedVideoType isEqualToString:@"AVFoundation"]) {
        self.videoCaptureSession = [[AVFCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"QTCapture"]) {
        self.videoCaptureSession = [[QTCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Syphon"]) {
        self.videoCaptureSession = [[SyphonCapture alloc] init];
    } else {
        self.videoCaptureSession = [[AVFCapture alloc] init];
    }
    
    if (!self.videoCaptureSession)
    {
        _audio_capture_session  = nil;
        _selectedVideoType = nil;
    }
    
    if ([self.videoCaptureSession providesAudio])
    {
        _audio_capture_session = self.videoCaptureSession;
    } else {
        _audio_capture_session = [[AVFCapture alloc] init];
    }
    
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
       
       _main_capture_queue = dispatch_queue_create("CocoaSplit.main.queue", NULL);
       self.destinationTypes = @{@"file" : @"File/Raw",
       @"twitch" : @"Twitch TV"};
       
       
       self.videoTypes = @[@"Desktop", @"AVFoundation", @"QTCapture"];
       self.selectedVideoType = [self.videoTypes objectAtIndex:0];
       
       
   }
    
    return self;
    
}


- (NSString *) saveFilePath
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *saveFolder = @"~/Library/Application Support/CocoaSplit";
    
    saveFolder = [saveFolder stringByExpandingTildeInPath];
    
    if ([fileManager fileExistsAtPath:saveFolder] == NO)
    {
        [fileManager createDirectoryAtPath:saveFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *saveFile = @"CocoaSplit.settings";
    
    return [saveFolder stringByAppendingPathComponent:saveFile];
}


-(void) saveSettings
{
    
    NSString *path = [self saveFilePath];
    
    NSMutableDictionary *saveRoot;
    
    saveRoot = [NSMutableDictionary dictionary];
    
    [saveRoot setValue: [NSNumber numberWithInt:self.captureWidth] forKey:@"captureWidth"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureHeight] forKey:@"captureHeight"];
    [saveRoot setValue: [NSNumber numberWithInt:self.videoCaptureSession.videoCaptureFPS] forKey:@"captureFPS"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureVideoAverageBitrate] forKey:@"captureVideoAverageBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioBitrate] forKey:@"audioBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioSamplerate] forKey:@"audioSamplerate"];
    [saveRoot setValue: self.selectedVideoType forKey:@"selectedVideoType"];
    [saveRoot setValue: self.videoCaptureSession.activeVideoDevice.uniqueID forKey:@"videoCaptureID"];
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
    self.videoCaptureSession.videoCaptureFPS = [[saveRoot valueForKey:@"captureFPS"] intValue];

    
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
    if (_streamingServiceKey)
    {
        
        newDest.destination = [_streamingDestination stringByReplacingOccurrencesOfString:@"{stream_key}" withString:_streamingServiceKey];
    } else {
        newDest.destination = _streamingDestination;
    }
    
    
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
    newout.framerate = self.videoCaptureSession.videoCaptureFPS;
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
        [self.videoCaptureSession setVideoDelegate:self];
        [self.videoCaptureSession setVideoDimensions:_captureWidth height:_captureHeight];
        [_audio_capture_session setAudioDelegate:self];
        [_audio_capture_session setAudioBitrate:_audioBitrate];
        [_audio_capture_session setAudioSamplerate:_audioSamplerate];
        
        
        success = [self.videoCaptureSession setupCaptureSession:&error];
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
        
        
        success = [self.videoCaptureSession startCaptureSession:&error];
        
        _frameCount = 0;
        _compressedFrameCount = 0;
        _min_delay = _max_delay = _avg_delay = 0;
        
       // _captureTimer = [NSTimer timerWithTimeInterval:1.0/_captureFPS target:self selector:@selector(newFrame) userInfo:nil repeats:YES];
        //[[NSRunLoop currentRunLoop] addTimer:_captureTimer forMode:NSRunLoopCommonModes];

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
        
        
        if (self.videoCaptureSession)
        {
            [self.videoCaptureSession stopCaptureSession];
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
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFTypeRef)(@[@(real_bitrate), @1.0]));
        
    }
    
    
    if (_captureVideoAverageBitrate > 0)
    {
        int real_bitrate = _captureVideoAverageBitrate*1024;
                            
        NSLog(@"Setting bitrate to %d", real_bitrate);
        
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_AverageBitRate, CFNumberCreate(NULL, kCFNumberIntType, &real_bitrate));
        
    }
    
    if (self.videoCaptureSession.videoCaptureFPS && self.videoCaptureSession.videoCaptureFPS > 0)
    {
        
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)(@(self.videoCaptureSession.videoCaptureFPS)));
        
    }
    
    return YES;
    
}


-  (void)newFrame
{
    
    CVImageBufferRef cFrame;
    cFrame = [self.videoCaptureSession getCurrentFrame];
    
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
    
    
    [self captureOutputVideo:self.videoCaptureSession didOutputSampleBuffer:nil didOutputImage:cFrame frameTime:0 ];
    
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
    
    if (imageBuffer)
    {
        CVPixelBufferRetain(imageBuffer);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self processVideoFrame:imageBuffer];
        }
                       );
        
    }
    
}

-(void)processVideoFrame:(CVImageBufferRef)imageBuffer
{

    
    CMTime pts;
    CMTime duration;
    
    if(!imageBuffer)
        return;

    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    pts = CMTimeMake(currentTime*1000, 1000);
    
    
    duration = CMTimeMake(1, self.videoCaptureSession.videoCaptureFPS);
    
    
    if (_frameCount == 0)
    {
        _firstFrameTime = currentTime;
    }
    
    _frameCount++;
    if ((_frameCount % 15) == 0)
    {
        [self updateStatusString];
    }
    
    [self.previewCtx drawFrame:imageBuffer];
    
    
    VTCompressionSessionEncodeFrame(_compression_session, imageBuffer, pts, duration, NULL, imageBuffer, NULL);
    //CVPixelBufferRelease(imageBuffer); 
}

void VideoCompressorReceiveFrame(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    if (VTFrameRef)
    {
        CVPixelBufferRelease(VTFrameRef);
    }

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
        
        selfobj.compressedFrameCount++;

        
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
