
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
#import "x264.h"
#import <mach/mach.h>
#import <mach/mach_time.h>


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



-(IBAction)openAdvancedPrefPanel:(id)sender
{
    if (!self.advancedPrefPanel)
    {
        
        
        [NSBundle loadNibNamed:@"advancedPrefPanel" owner:self];
        
        [NSApp beginSheet:self.advancedPrefPanel modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        
    }
    
}


-(IBAction)closeAdvancedPrefPanel:(id)sender
{
    [NSApp endSheet:self.advancedPrefPanel];
    [self.advancedPrefPanel close];
    self.advancedPrefPanel = nil;
}


-(IBAction)openCompressPanel:(id)sender
{
    if (!self.compressPanel)
    {
        
        NSString *panelName;
        
        if ([self.selectedCompressorType isEqualToString:@"x264"])
        {
            panelName = @"x264Panel";
        } else if ([self.selectedDestinationType isEqualToString:@"AppleVTCompressor"]) {
            panelName = @"AppleVTPanel";
        } else {
            panelName = @"AppleVTPanel";
        }

        [NSBundle loadNibNamed:panelName owner:self];
        
        [NSApp beginSheet:self.compressPanel modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        
    }
    
}


-(IBAction)closeCompressPanel:(id)sender
{
    [NSApp endSheet:self.compressPanel];
    [self.compressPanel close];
    self.compressPanel = nil;
}

-(IBAction)openAVFAdvanced:(id)sender
{
    if (!_avfPanel)
    {
        [NSBundle loadNibNamed:@"AVFAdvancedPanel" owner:self];
        
        [NSApp beginSheet:self.avfPanel modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    
    }
    
}

-(IBAction)closeAVFAdvanced:(id)sender
{
    [NSApp endSheet:self.avfPanel];
    [self.avfPanel close];
    self.avfPanel = nil;
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
        self.audioCaptureSession  = nil;
        _selectedVideoType = nil;
    }
    
    if ([self.videoCaptureSession providesAudio])
    {
        self.audioCaptureSession = self.videoCaptureSession;
    } else {
        self.audioCaptureSession = [[AVFCapture alloc] init];
    }
    
    self.audioCaptureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    self.selectedVideoCapture = nil;
    
    _selectedVideoType = selectedVideoType;
}




-(id) init
{
   if (self = [super init])
   {
       dispatch_source_t sigsrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGPIPE, 0, dispatch_get_global_queue(0, 0));
       dispatch_source_set_event_handler(sigsrc, ^{ return;});
       dispatch_resume(sigsrc);
       
       _main_capture_queue = dispatch_queue_create("CocoaSplit.main.queue", NULL);
       _preview_queue = dispatch_queue_create("CocoaSplit.preview.queue", NULL);
       
       self.destinationTypes = @{@"file" : @"File/Raw",
       @"twitch" : @"Twitch TV"};
       
       self.showPreview = YES;
       self.videoTypes = @[@"Desktop", @"AVFoundation", @"QTCapture", @"Syphon"];
       self.compressorTypes = @[@"None", @"AppleVTCompressor", @"x264"];
       
       self.x264tunes = [[NSMutableArray alloc] init];
       
       self.x264presets = [[NSMutableArray alloc] init];
       
       self.x264profiles = [[NSMutableArray alloc] init];

       [self.x264tunes addObject:[NSNull null]];
       [self.x264presets addObject:[NSNull null]];
       for (int i = 0; x264_profile_names[i]; i++)
       {
           [self.x264profiles addObject:[NSString stringWithUTF8String:x264_profile_names[i]]];
       }

       
       for (int i = 0; x264_preset_names[i]; i++)
       {
           [self.x264presets addObject:[NSString stringWithUTF8String:x264_preset_names[i]]];
       }
       
       for (int i = 0; x264_tune_names[i]; i++)
       {
           [self.x264tunes addObject:[NSString stringWithUTF8String:x264_tune_names[i]]];
       }

       
       self.vtcompressor_profiles = @[[NSNull null], @"Baseline", @"Main", @"High"];
       
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
    [saveRoot setValue: [NSNumber numberWithDouble:self.videoCaptureSession.videoCaptureFPS] forKey:@"captureFPS"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureVideoAverageBitrate] forKey:@"captureVideoAverageBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioBitrate] forKey:@"audioBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioSamplerate] forKey:@"audioSamplerate"];
    [saveRoot setValue: self.selectedVideoType forKey:@"selectedVideoType"];
    [saveRoot setValue: self.videoCaptureSession.activeVideoDevice.uniqueID forKey:@"videoCaptureID"];
    [saveRoot setValue: self.selectedAudioCapture.uniqueID forKey:@"audioCaptureID"];
    [saveRoot setValue: self.captureDestinations forKey:@"captureDestinations"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureVideoMaxBitrate] forKey:@"captureVideoMaxBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureVideoMaxKeyframeInterval] forKey:@"captureVideoMaxKeyframeInterval"];
    [saveRoot setValue: self.selectedCompressorType forKey:@"selectedCompressorType"];
    [saveRoot setValue: self.x264profile forKey:@"x264profile"];
    [saveRoot setValue: self.x264preset forKey:@"x264preset"];
    [saveRoot setValue: self.x264tune forKey:@"x264tune"];
    [saveRoot setValue: [NSNumber numberWithInt:self.x264crf] forKey:@"x264crf"];
    [saveRoot setValue:[NSNumber numberWithBool:self.previewCtx.vsync] forKey:@"previewVsync"];
    [saveRoot setValue:[NSNumber numberWithFloat:self.audioCaptureSession.previewVolume] forKey:@"previewVolume"];
    [saveRoot setValue:[NSNumber numberWithBool:self.videoCBR] forKey:@"videoCBR"];
    [saveRoot setValue:[NSNumber numberWithInt:self.maxOutputDropped] forKey:@"maxOutputDropped"];
    [saveRoot setValue:[NSNumber numberWithInt:self.maxOutputPending] forKey:@"maxOutputPending"];

    
    
    
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
    
    
    self.x264tune = [saveRoot valueForKey:@"x264tune"];
    self.x264preset = [saveRoot valueForKey:@"x264preset"];
    self.x264profile = [saveRoot valueForKey:@"x264profile"];
    self.x264crf = [[saveRoot valueForKey:@"x264crf"] intValue];
    
    self.selectedVideoType = [saveRoot valueForKey:@"selectedVideoType"];
    self.selectedCompressorType = [saveRoot valueForKey:@"selectedCompressorType"];

    NSString *videoID = [saveRoot valueForKey:@"videoCaptureID"];
    
    [self selectedVideoCaptureFromID:videoID];
    
    NSString *audioID = [saveRoot valueForKey:@"audioCaptureID"];
    
    [self selectedAudioCaptureFromID:audioID];
    self.audioCaptureSession.previewVolume = [[saveRoot valueForKey:@"previewVolume"] floatValue];
    
    self.videoCaptureSession.videoCaptureFPS = [[saveRoot valueForKey:@"captureFPS"] doubleValue];
    self.previewCtx.vsync = [[saveRoot valueForKey:@"previewVsync"] boolValue];
    self.videoCBR = [[saveRoot valueForKey:@"videoCBR"] boolValue];
    self.maxOutputDropped = [[saveRoot valueForKey:@"maxOutputDropped"] intValue];
    self.maxOutputPending = [[saveRoot valueForKey:@"maxOutputPending"] intValue];


    
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
    newout.settingsController = self;
    output.ffmpeg_out = newout;
}





- (void) outputAVPacket:(AVPacket *)avpkt codec_ctx:(AVCodecContext *)codec_ctx
{
    for (OutputDestination *outdest in _captureDestinations)
    {
        if (outdest.active)
        {
            id ffmpeg = outdest.ffmpeg_out;
            [ffmpeg writeAVPacket:avpkt codec_ctx:codec_ctx];
        }
    }
}

- (void) outputSampleBuffer:(CMSampleBufferRef)theBuffer
{
    for (OutputDestination *outdest in _captureDestinations)
    {
        if (outdest.active)
        {
            id ffmpeg = outdest.ffmpeg_out;
            [ffmpeg writeVideoSampleBuffer:theBuffer];
        }
    }
}


-(bool) startStream
{
    // We should already have a capture session from init since we need it to figure out device lists.
    
    
    NSError *error;
    bool success;
    
    
    if (_cmdLineInfo)
    {
        printf("%s", [[self buildCmdLineInfo] UTF8String]);
        [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
        return YES;
    }
    
    [self.audioCaptureSession setActiveAudioDevice:_selectedAudioCapture];
    [self.videoCaptureSession setVideoDelegate:self];
    [self.videoCaptureSession setVideoDimensions:_captureWidth height:_captureHeight];
    [self.audioCaptureSession setAudioDelegate:self];
    [self.audioCaptureSession setAudioBitrate:_audioBitrate];
    [self.audioCaptureSession setAudioSamplerate:_audioSamplerate];
    
    
    
    success = [self.videoCaptureSession setupCaptureSession:&error];
    if (!success)
    {
        [NSApp presentError:error];
        return NO;
    }
    success = [self.audioCaptureSession setupCaptureSession:&error];
    if (!success)
    {
        [NSApp presentError:error];
        return NO;
    }
    
    if ([self.selectedCompressorType isEqualToString:@"x264"])
    {
        self.videoCompressor = [[x264Compressor alloc] init];
    } else if ([self.selectedCompressorType isEqualToString:@"AppleVTCompressor"]) {
        self.videoCompressor = [[AppleVTCompressor alloc] init];
    } else {
        self.videoCompressor = nil;
    }
    
    
    if (self.videoCompressor)
    {
    
        self.videoCompressor.settingsController = self;
    
        if ([self.videoCompressor setupCompressor] == YES)
        {
            self.videoCompressor.outputDelegate = self;
        }
    
    
        if (!success)
        {
            NSLog(@"Failed compression setup");
            [NSApp presentError:error];
            return NO;
        }
    
        OutputDestination *output;
    
    
        for (output in _captureDestinations)
        {
            [self attachCaptureDestination:output];
        }
    
    }
    
    success = [self.videoCaptureSession startCaptureSession:&error];
    
    _frameCount = 0;
    _firstAudioTime = 0;
    _firstFrameTime = 0;
    
    _compressedFrameCount = 0;
    _min_delay = _max_delay = _avg_delay = 0;
    
    
    self.captureRunning = YES;
    uint64_t frame_interval = (1.0/self.captureFPS)*NSEC_PER_SEC;
    
    _dispatch_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _main_capture_queue);
    
    dispatch_source_set_timer(_dispatch_timer, DISPATCH_TIME_NOW, frame_interval, 0);
    dispatch_source_set_event_handler(_dispatch_timer, ^{ [self newFrame]; });
    dispatch_resume(_dispatch_timer);
    //dispatch_async(_main_capture_queue, ^{[self newFrame];});
    
    
    
     //_captureTimer = [NSTimer timerWithTimeInterval:1.0/self.captureFPS target:self selector:@selector(newFrame) userInfo:nil repeats:YES];
    //[[NSRunLoop currentRunLoop] addTimer:_captureTimer forMode:NSRunLoopCommonModes];
    
    if (!success)
    {
        self.captureRunning = NO;
        NSLog(@"Failed start capture");
        [NSApp presentError:error];
        return NO;
    }
    if (self.audioCaptureSession != self.videoCaptureSession)
    {
        success = [self.audioCaptureSession startCaptureSession:&error];
    }
    
    
    
    
    if (!success)
    {
        NSLog(@"Failed start capture");
        self.captureRunning = NO;
        [NSApp presentError:error];
        return NO;
    }

    
    _PMAssertionRet = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep, kIOPMAssertionLevelOn, CFSTR("CocoaSplit is capturing video"), &_PMAssertionID);
    
    return YES;
    
}




-(NSString *) buildCmdLineInfo
{
    
    NSMutableDictionary *infoDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *audioArray = [[NSMutableArray alloc] init];
    
    
    for (AVCaptureDevice *audioDev in self.audioCaptureDevices)
    {
        [audioArray addObject:@{@"name": audioDev.localizedName, @"uniqueID": audioDev.uniqueID}];
    }
    
    
    
    [infoDict setValue:audioArray forKey:@"audioDevices"];
    
    
    NSMutableDictionary *x264dict = [[NSMutableDictionary alloc] init];
    
    [x264dict setValue:self.x264presets forKey:@"presets"];
    [x264dict setValue:self.x264tunes forKey:@"tunes"];
    [x264dict setValue:self.x264profiles forKey:@"profiles"];


    
    [infoDict setValue:x264dict forKey:@"x264"];
    
    
    [infoDict setValue:@{@"profiles": self.vtcompressor_profiles} forKey:@"AppleVTCompressor"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict options:0 error:nil];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}



-(void) loadCmdlineSettings:(NSUserDefaults *)cmdargs
{
    
    
    if ([cmdargs objectForKey:@"dumpInfo"])
    {
        _cmdLineInfo = YES;
    } else {
        _cmdLineInfo = NO;
    }
    
    
    if ([cmdargs objectForKey:@"captureWidth"])
    {
        self.captureWidth = [cmdargs integerForKey:@"captureWidth"];
    }
    
    if ([cmdargs objectForKey:@"captureHeight"])
    {
        self.captureHeight = [cmdargs integerForKey:@"captureHeight"];
    }
    
    if ([cmdargs objectForKey:@"captureVideoAverageBitrate"])
    {
        self.captureVideoAverageBitrate = [cmdargs integerForKey:@"captureVideoAverageBitrate"];
    }
    
    if ([cmdargs objectForKey:@"captureVideoMaxBitrate"])
    {
        self.captureVideoMaxBitrate = [cmdargs integerForKey:@"captureVideoMaxBitrate"];
    }
    
    if ([cmdargs objectForKey:@"captureVideoMaxKeyframeInterval"])
    {
        self.captureVideoMaxKeyframeInterval = [cmdargs integerForKey:@"captureVideoMaxKeyframeInterval"];
    }
    
    if ([cmdargs objectForKey:@"audioBitrate"])
    {
        self.audioBitrate = [cmdargs integerForKey:@"audioBitrate"];
    }
    
    if ([cmdargs objectForKey:@"audioSamplerate"])
    {
        self.audioSamplerate = [cmdargs integerForKey:@"audioSamplerate"];
    }
    
    if ([cmdargs objectForKey:@"x264tune"])
    {
        self.x264tune = [cmdargs stringForKey:@"x264tune"];
    }
    
    if ([cmdargs objectForKey:@"x264preset"])
    {
        self.x264preset = [cmdargs stringForKey:@"x264preset"];
    }
    
    if ([cmdargs objectForKey:@"x264profile"])
    {
        self.x264profile = [cmdargs stringForKey:@"x264profile"];
    }
    
    if ([cmdargs objectForKey:@"x264crf"])
    {
        self.x264crf = [cmdargs integerForKey:@"x264crf"];
    }
    
    if ([cmdargs objectForKey:@"selectedVideoType"])
    {
        self.selectedVideoType = [cmdargs stringForKey:@"selectedVideoType"];
    }
    
    if ([cmdargs objectForKey:@"selectedCompressorType"])
    {
        self.selectedCompressorType = [cmdargs stringForKey:@"selectedCompressorType"];
    }
    
    
    if ([cmdargs objectForKey:@"videoCaptureID"])
    {
        NSString *videoID = [cmdargs stringForKey:@"videoCaptureID"];
        [self selectedVideoCaptureFromID:videoID];
    }
    
    
    if ([cmdargs objectForKey:@"audioCaptureID"])
    {
        NSString *audioID = [cmdargs stringForKey:@"audioCaptureID"];
        [self selectedAudioCaptureFromID:audioID];
    }
    
    if ([cmdargs objectForKey:@"captureFPS"])
    {
        self.videoCaptureSession.videoCaptureFPS = [cmdargs doubleForKey:@"captureFPS"];
    }
    
    if ([cmdargs objectForKey:@"outputDestinations"])
    {
        
        if (!self.captureDestinations)
        {
            self.captureDestinations = [[NSMutableArray alloc] init];
        }

        NSArray *outputs = [cmdargs arrayForKey:@"outputDestinations"];
        for (NSString *outstr in outputs)
        {
            OutputDestination *newDest = [[OutputDestination alloc] initWithType:@"file"];
            
            newDest.active = YES;
            newDest.destination = outstr;
            [[self mutableArrayValueForKey:@"captureDestinations"] addObject:newDest];
        }
        
    }
}

- (void)stopStream
{
    
    if (_dispatch_timer)
    {
        dispatch_source_cancel(_dispatch_timer);
        _dispatch_timer = nil;
        
    }
    if (_captureTimer)
    {
        [_captureTimer invalidate];
        
        
    }
    
    self.videoCompressor = nil;
    
    /*
     if (_compression_session)
     {
     VTCompressionSessionInvalidate(_compression_session);
     CFRelease(_compression_session);
     }
     */
    
    if (self.videoCaptureSession)
    {
        [self.videoCaptureSession stopCaptureSession];
    }
    
    if (self.audioCaptureSession)
    {
        [self.audioCaptureSession stopCaptureSession];
    }
    
    
    
    for (OutputDestination *out in _captureDestinations)
    {
        [out stopOutput];
    }
    
    if (_PMAssertionRet == kIOReturnSuccess)
    {
        _PMAssertionRet = kIOReturnInvalid;
        IOPMAssertionRelease(_PMAssertionID);
    }
    self.captureRunning = NO;
    
}

- (IBAction)streamButtonPushed:(id)sender {
    
    NSButton *button = (NSButton *)sender;
    
    
    if ([button state] == NSOnState)
    {
        
        if ([self startStream] == YES)
        {
            self.selectedTabIndex = 1;
        } else {
            [sender setNextState];

        }

    } else {
        
        self.selectedTabIndex = 0;
        [self stopStream];
    }
    
}


- (void)captureOutputAudio:(id)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent()*1000000;
    if (_firstFrameTime == 0)
    {
        //Don't start sending audio to the outputs until a video frame has arrived, with AVFoundation this can take 2+ seconds (!?)
        //Might need to prime the capture session first...
        return;
    }
    if (_firstAudioTime == 0)
    {
        _firstAudioTime = currentTime;
    }
    
    CFAbsoluteTime ptsTime = currentTime - _firstAudioTime;
    
    CMTime pts = CMTimeMake(_frameCount*(1.0f/self.captureFPS)*1000000, 1000000);
    //CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    

    //CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, pts);
    
    
    for (OutputDestination *outdest in _captureDestinations)
    {
        if (outdest.active)
        {
            id ffmpeg = outdest.ffmpeg_out;
            [ffmpeg writeAudioSampleBuffer:sampleBuffer presentationTimeStamp:pts];
        }
    }
    
}


//This function is the main capture loop. Naive sleep implementation for now.
//Maybe look into mach_wait_until?



-(void) newFrame
{
    CVImageBufferRef newFrame;

    
    if (self.videoCaptureSession)
    {
        newFrame = [self.videoCaptureSession getCurrentFrame];
        if (newFrame)
        {
            //dispatch_async(_preview_queue, ^{
                [self.previewCtx drawFrame:newFrame];
            //});
            
            //dispatch_async(_main_capture_queue, ^{
            [self processVideoFrame:newFrame];
            //});
            
        }
    }

}


- (void)captureOutputVideo:(AbstractCaptureDevice *)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer didOutputImage:(CVImageBufferRef)imageBuffer frameTime:(uint64_t)frameTime
{

    if (imageBuffer)
    {
        CVPixelBufferRetain(imageBuffer);
        [self.previewCtx drawFrame:imageBuffer];


        dispatch_async(_main_capture_queue, ^{
            [self processVideoFrame:imageBuffer];
        });
        
       }
    
}

-(void)processVideoFrame:(CVImageBufferRef)imageBuffer
{

    
    //[self.previewCtx drawFrame:imageBuffer];

    CMTime pts;
    CMTime duration;
    
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent()*1000000;

    
    
    if (_firstFrameTime == 0)
    {
        _firstFrameTime = currentTime;
        
    }
    
    CFAbsoluteTime ptsTime = currentTime - _firstFrameTime;
    
    _frameCount++;
    _lastFrameTime = currentTime;
    
    
    

    pts = CMTimeMake(_frameCount*(1.0f/self.captureFPS)*1000000,1000000);
    
    //NSLog(@"PTS IS %@", CMTimeCopyDescription(kCFAllocatorDefault, pts));
    
    duration = CMTimeMake(1000, self.videoCaptureSession.videoCaptureFPS*1000);
    
    
    
    if (self.videoCompressor)
    {
        
        [self.videoCompressor compressFrame:imageBuffer pts:pts duration:duration];
        
        
    } else {
        CVPixelBufferRelease(imageBuffer);
    }
        
}



- (double) captureFPS
{
    
    return self.videoCaptureSession.videoCaptureFPS;
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
    
}
@end
