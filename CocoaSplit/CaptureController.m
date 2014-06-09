
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
#import "ImageCapture.h"


@implementation CaptureController


@synthesize captureFPS = _captureFPS;






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



-(IBAction)openLogWindow:(id)sender
{
    if (self.logWindow)
    {
        
        [self.logWindow makeKeyAndOrderFront:sender];
        
    }
}


-(IBAction)openAdvancedPrefPanel:(id)sender
{
    if (!self.advancedPrefPanel)
    {
        
        
        
        [[NSBundle mainBundle] loadNibNamed:@"advancedPrefPanel" owner:self topLevelObjects:nil];
        
        
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
        
        [[NSBundle mainBundle] loadNibNamed:panelName owner:self topLevelObjects:nil];
        

        
        [NSApp beginSheet:self.compressPanel modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        
    }
    
}


-(IBAction)closeCompressPanel:(id)sender
{
        
    if (![self.compressSettingsController commitEditing])
    {
        NSLog(@"FAILED TO COMMIT EDITING");
    }
    
    [NSApp endSheet:self.compressPanel];
    [self.compressPanel close];
    self.compressPanel = nil;
}

- (IBAction)openAudioMixerPanel:(id)sender {
    
    if (!self.audioMixerPanel)
    {
        [[NSBundle mainBundle] loadNibNamed:@"AudioMixer" owner:self topLevelObjects:nil];
        [NSApp beginSheet:self.audioMixerPanel modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    }
}


- (IBAction)closeAudioMixerPanel:(id)sender {
    
    [NSApp endSheet:self.audioMixerPanel];
    [self.audioMixerPanel close];
    self.audioMixerPanel = nil;
}



-(IBAction)openVideoAdvanced:(id)sender
{
    
    
    NSString *panelName;
    
    if (!self.advancedVideoPanel)
    {
        
    
        panelName = [NSString stringWithFormat:@"%@AdvancedPanel", self.selectedVideoType];
        
        
        [[NSBundle mainBundle] loadNibNamed:panelName owner:self topLevelObjects:nil];
        
        [NSApp beginSheet:self.advancedVideoPanel modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    
    }
    
}

-(IBAction)closeVideoAdvanced:(id)sender
{
    [NSApp endSheet:self.advancedVideoPanel];
    [self.advancedVideoPanel close];
    self.advancedVideoPanel = nil;
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
        
        
        [[NSBundle mainBundle] loadNibNamed:panelName owner:self topLevelObjects:nil];
        
        
    }
    
    [NSApp beginSheet:self.createSheet modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
}


-(IBAction)closeCreateSheet:(id)sender
{
    
    [self.outputPanelController commitEditing];
    
    [NSApp endSheet:self.createSheet];
    [self.createSheet close];
    self.createSheet = nil;
}




-(AVCaptureDevice *)selectedAudioCapture
{
    if (self.audioCaptureSession)
    {
        return self.audioCaptureSession.activeAudioDevice;
    }
    
    return nil;
}


-(void) selectedAudioCaptureFromID:(NSString *)uniqueID
{
    self.audioCaptureSession.activeAudioDevice = [AVCaptureDevice deviceWithUniqueID:uniqueID];
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



- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"videoCaptureFPS"])
    {
        self.captureFPS = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        
        [self setupFrameTimer];
    }
}



-(NSString *) selectedVideoType
{
    return _selectedVideoType;
}



-(void) setSelectedVideoType:(NSString *)selectedVideoType
{
    
    
    NSLog(@"SETTING SELECTED VIDEO TYPE %@", selectedVideoType);
    
    if (self.videoCaptureSession)
    {
        
        [(NSObject *)self.videoCaptureSession removeObserver:self forKeyPath:@"videoCaptureFPS" context:NULL];
    }
    
    self.videoCaptureSession = nil;
    
    id newCaptureSession;
    
    if ([selectedVideoType isEqualToString:@"Desktop"])
    {
        newCaptureSession = [[DesktopCapture alloc ] init];
    } else if ([selectedVideoType isEqualToString:@"AVFoundation"]) {
        newCaptureSession = [[AVFCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"QTCapture"]) {
        newCaptureSession = [[QTCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Syphon"]) {
        newCaptureSession = [[SyphonCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Image"]) {
        
        newCaptureSession = [[ImageCapture alloc] init];
    } else {
        newCaptureSession = [[AVFCapture alloc] init];
    }
    
    
    self.videoCaptureSession = newCaptureSession;
    newCaptureSession = nil;
    
    
    if (!self.videoCaptureSession)
    {
        self.audioCaptureSession  = nil;
        _selectedVideoType = nil;
        
    } else {
        self.videoCaptureSession.videoDelegate = self;
        self.videoCaptureSession.settingsController = self;
        
    }
    
    [(NSObject *)self.videoCaptureSession addObserver:self forKeyPath:@"videoCaptureFPS" options:NSKeyValueObservingOptionNew context:NULL];
    
    
    self.selectedVideoCapture = nil;
    
    _selectedVideoType = selectedVideoType;
}




-(id) init
{
   if (self = [super init])
   {
       
       
       
       audioLastReadPosition = 0;
       audioWritePosition = 0;
       
       audioBuffer = [[NSMutableArray alloc] init];
       videoBuffer = [[NSMutableArray alloc] init];
       
       
       
       dispatch_source_t sigsrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGPIPE, 0, dispatch_get_global_queue(0, 0));
       dispatch_source_set_event_handler(sigsrc, ^{ return;});
       dispatch_resume(sigsrc);
       
       _main_capture_queue = dispatch_queue_create("CocoaSplit.main.queue", NULL);
       _preview_queue = dispatch_queue_create("CocoaSplit.preview.queue", NULL);
       
       self.destinationTypes = @{@"file" : @"File/Raw",
       @"twitch" : @"Twitch TV"};
       
       
       self.showPreview = YES;
       self.videoTypes = @[@"Desktop", @"AVFoundation", @"QTCapture", @"Syphon", @"Image"];
       self.compressorTypes = @[@"None", @"AppleVTCompressor", @"x264"];
       self.arOptions = @[@"None", @"Use Source", @"Preserve AR"];
       self.validSamplerates = @[@44100, @48000];
       
       
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
       
       self.audioCaptureSession = [[AVFCapture alloc] initForAudio];
       [self.audioCaptureSession setAudioDelegate:self];
       
       
       
       
       self.audioCaptureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
       
       mach_timebase_info(&_mach_timebase);
       
       dispatch_async(_main_capture_queue, ^{[self newFrameTimed];});
       
       /*
       int dispatch_strict_flag = 1;
       
       if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8)
       {
           dispatch_strict_flag = 0;
       }
       
       _dispatch_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, dispatch_strict_flag, _main_capture_queue);
       
       dispatch_source_set_timer(_dispatch_timer, DISPATCH_TIME_NOW, _frame_interval, 0);
       
       dispatch_source_set_event_handler(_dispatch_timer, ^{[self newFrameDispatched];});
       
       dispatch_resume(_dispatch_timer);
       
       */
       self.extraSaveData = [[NSMutableDictionary alloc] init];
       
       
           

       
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


-(void) appendToLogView:(NSString *)logLine
{
    
    [[self.logTextView textStorage] beginEditing];
    [[[self.logTextView textStorage] mutableString] appendString:logLine];
    [[[self.logTextView textStorage] mutableString] appendString:@"\n"];

    [[self.logTextView textStorage] endEditing];
    NSRange range;
    
    range = NSMakeRange([[self.logTextView string] length], 0);
    
    [self.logTextView scrollRangeToVisible:range];

}



-(void) loggingNotification:(NSNotification *)notification
{
    [self.logReadHandle readInBackgroundAndNotify];
    NSString *logLine = [[NSString alloc] initWithData:[[notification userInfo] objectForKey:NSFileHandleNotificationDataItem] encoding: NSASCIIStringEncoding];
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        [self appendToLogView:logLine];
    //});
    
    
    
    
}
-(void)setupLogging
{
    
    self.loggingPipe = [NSPipe pipe];
    
    self.logReadHandle = [self.loggingPipe fileHandleForReading];
    dup2([[self.loggingPipe fileHandleForWriting] fileDescriptor], fileno(stderr));
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggingNotification) name:NSFileHandleReadCompletionNotification object:self.logReadHandle];
    [self.logReadHandle readInBackgroundAndNotify];
    
}
-(void) saveSettings
{
    
    NSString *path = [self saveFilePath];
    
    NSMutableDictionary *saveRoot;
    
    saveRoot = [NSMutableDictionary dictionary];
    
    [saveRoot setValue: [NSNumber numberWithInt:self.captureWidth] forKey:@"captureWidth"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureHeight] forKey:@"captureHeight"];
    [saveRoot setValue: [NSNumber numberWithDouble:self.captureFPS] forKey:@"captureFPS"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureVideoAverageBitrate] forKey:@"captureVideoAverageBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioCaptureSession.audioBitrate] forKey:@"audioBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioCaptureSession.audioSamplerate] forKey:@"audioSamplerate"];
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
    [saveRoot setValue:[NSNumber numberWithFloat:self.audioCaptureSession.previewVolume] forKey:@"previewVolume"];
    [saveRoot setValue:[NSNumber numberWithBool:self.videoCBR] forKey:@"videoCBR"];
    [saveRoot setValue:[NSNumber numberWithInt:self.maxOutputDropped] forKey:@"maxOutputDropped"];
    [saveRoot setValue:[NSNumber numberWithInt:self.maxOutputPending] forKey:@"maxOutputPending"];
    [saveRoot setValue:self.resolutionOption forKey:@"resolutionOption"];
    [saveRoot setValue:[NSNumber numberWithDouble:self.audio_adjust] forKey:@"audioAdjust"];
    
    
    
    [saveRoot setValue:self.extraSaveData forKey:@"extraSaveData"];
    
    
    
    
    
    
    [NSKeyedArchiver archiveRootObject:saveRoot toFile:path];
    
}


-(void) loadSettings
{
    
    NSString *path = [self saveFilePath];
    NSDictionary *defaultValues = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]];
    
    NSDictionary *savedValues = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    NSMutableDictionary *saveRoot = [[NSMutableDictionary alloc] init];
    

    [saveRoot addEntriesFromDictionary:defaultValues];
    [saveRoot addEntriesFromDictionary:savedValues];
    
    self.captureWidth = [[saveRoot valueForKey:@"captureWidth"] intValue];
    self.captureHeight = [[saveRoot valueForKey:@"captureHeight"] intValue];
    self.captureVideoAverageBitrate = [[saveRoot valueForKey:@"captureVideoAverageBitrate"] intValue];
    self.captureVideoMaxBitrate = [[saveRoot valueForKey:@"captureVideoMaxBitrate"] intValue];
    self.captureVideoMaxKeyframeInterval = [[saveRoot valueForKey:@"captureVideoMaxKeyframeInterval"] intValue];
    self.audioCaptureSession.audioBitrate = [[saveRoot valueForKey:@"audioBitrate"] intValue];
    self.audioCaptureSession.audioSamplerate = [[saveRoot valueForKey:@"audioSamplerate"] intValue];
    self.captureDestinations = [saveRoot valueForKey:@"captureDestinations"];
    
    if (!self.captureDestinations)
    {
        self.captureDestinations = [[NSMutableArray alloc] init];
    }
    
    
    self.x264tune = [saveRoot valueForKey:@"x264tune"];
    self.x264preset = [saveRoot valueForKey:@"x264preset"];
    self.x264profile = [saveRoot valueForKey:@"x264profile"];
    self.x264crf = [[saveRoot valueForKey:@"x264crf"] intValue];
    
    id tmp_savedata = [saveRoot valueForKey:@"extraSaveData"];
    
    if (tmp_savedata)
    {
        self.extraSaveData = (NSMutableDictionary *)tmp_savedata;
    }

    
    
    self.selectedVideoType = [saveRoot valueForKey:@"selectedVideoType"];
    self.selectedCompressorType = [saveRoot valueForKey:@"selectedCompressorType"];

    NSString *videoID = [saveRoot valueForKey:@"videoCaptureID"];
    
    [self selectedVideoCaptureFromID:videoID];
    
    NSString *audioID = [saveRoot valueForKey:@"audioCaptureID"];
    
    [self selectedAudioCaptureFromID:audioID];
    self.audioCaptureSession.previewVolume = [[saveRoot valueForKey:@"previewVolume"] floatValue];
    
    self.captureFPS = [[saveRoot valueForKey:@"captureFPS"] doubleValue];
    self.videoCBR = [[saveRoot valueForKey:@"videoCBR"] boolValue];
    self.maxOutputDropped = [[saveRoot valueForKey:@"maxOutputDropped"] intValue];
    self.maxOutputPending = [[saveRoot valueForKey:@"maxOutputPending"] intValue];

    self.audio_adjust = [[saveRoot valueForKey:@"audioAdjust"] doubleValue];
    
    self.resolutionOption = [saveRoot valueForKey:@"resolutionOption"];
    if (!self.resolutionOption)
    {
        self.resolutionOption = @"None";
    }

    
    
    
}



-(void)setExtraData:(id)saveData forKey:(NSString *)forKey
{
    
    
    [self.extraSaveData setValue:saveData forKey:forKey];
}

-(id)getExtraData:(NSString *)forkey
{
    return [self.extraSaveData valueForKey:forkey];
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



- (IBAction)imagePanelChooseDirectory:(id)sender {
    [self.videoCaptureSession chooseDirectory:sender];
}


- (IBAction)addStreamingService:(id)sender {
    
    
    OutputDestination *newDest;
    [self.outputPanelController commitEditing];
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
    
    if (!output.ffmpeg_out)
    {
        newout = [[FFMpegTask alloc] init];
    } else {
        newout = output.ffmpeg_out;
    }
    
    newout.height = _captureHeight;
    newout.width = _captureWidth;
    newout.framerate = self.captureFPS;
    newout.stream_output = [output.destination stringByStandardizingPath];
    newout.stream_format = output.output_format;
    newout.samplerate = self.audioCaptureSession.audioSamplerate;
    newout.audio_bitrate = self.audioCaptureSession.audioBitrate*1000;
    
    newout.settingsController = self;
    newout.active = YES;
    output.ffmpeg_out = newout;
}




- (void) outputEncodedData:(CapturedFrameData *)newFrameData
{

    [videoBuffer addObject:newFrameData];
    //This is here to facilitate future video buffering/delay. Right now the buffer is effectively 1 frame..
    
    CapturedFrameData *frameData = [videoBuffer objectAtIndex:0];
    
    [videoBuffer removeObjectAtIndex:0];
    
    
    CMTime videoTime = frameData.videoPTS;
    NSUInteger audioConsumed = 0;
    
    @synchronized(self)
    {
        NSUInteger audioBufferSize = [audioBuffer count];
        
        for (int i = 0; i < audioBufferSize; i++)
        {
            CMSampleBufferRef audioData = (__bridge CMSampleBufferRef)[audioBuffer objectAtIndex:i];
            
            CMTime audioTime = CMSampleBufferGetOutputPresentationTimeStamp(audioData);

            
            

            if (CMTIME_COMPARE_INLINE(audioTime, <=, videoTime))
            {
                
                audioConsumed++;
                
                [frameData.audioSamples addObject:(__bridge id)audioData];
                
            } else {
                break;
            }
        }
        
        if (audioConsumed > 0)
        {
            [audioBuffer removeObjectsInRange:NSMakeRange(0, audioConsumed)];
        }
        
    }
    
    for (OutputDestination *outdest in _captureDestinations)
    {
        if (outdest.active)
        {
            
            id ffmpeg = outdest.ffmpeg_out;
            [ffmpeg writeEncodedData:frameData];
            
        }
    }
    
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


-(bool) setupCompressors
{
    id<h264Compressor> newCompressor;
    
    
    if ([self.selectedCompressorType isEqualToString:@"x264"])
    {
        newCompressor = [[x264Compressor alloc] init];
    } else if ([self.selectedCompressorType isEqualToString:@"AppleVTCompressor"]) {
        newCompressor = [[AppleVTCompressor alloc] init];
    } else {
        newCompressor = nil;
    }
    
    
    if (newCompressor)
    {
        
        newCompressor.settingsController = self;
        
        
    }
    
    
    
    
    
    [self.audioCaptureSession setupAudioCompression];
    
    _frameCount = 0;
    _firstAudioTime = kCMTimeZero;
    _firstFrameTime = 0;
    
    _compressedFrameCount = 0;
    _min_delay = _max_delay = _avg_delay = 0;

    self.videoCompressor = newCompressor;
    
    return YES;

    
}
-(bool) startStream
{
    // We should already have a capture session from init since we need it to figure out device lists.
    
    
    if (_cmdLineInfo)
    {
        printf("%s", [[self buildCmdLineInfo] UTF8String]);
        [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
        return YES;
    }
    
    _frameCount = 0;
    _firstAudioTime = kCMTimeZero;
    _firstFrameTime = 0;
    
    _compressedFrameCount = 0;
    _min_delay = _max_delay = _avg_delay = 0;
    
    
    
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8)
    {
        _PMAssertionRet = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep, kIOPMAssertionLevelOn, CFSTR("CocoaSplit is capturing video"), &_PMAssertionID);
    } else {
        _activity_token = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated|NSActivityIdleDisplaySleepDisabled reason:@"CocoaSplit is capturing video"];
        
    }

    self.captureRunning = YES;

    return YES;
    
}



-(void) setupFrameTimer
{
    NSLog(@"SETTING UP FRAME TIMER %f", self.captureFPS);
    
    if (self.captureFPS && self.captureFPS > 0)
    {
        _frame_interval = (1.0/self.captureFPS);
    } else {
        _frame_interval = 1.0/60.0;
    }
    
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
        self.captureWidth = (int)[cmdargs integerForKey:@"captureWidth"];
    }
    
    if ([cmdargs objectForKey:@"captureHeight"])
    {
        self.captureHeight = (int)[cmdargs integerForKey:@"captureHeight"];
    }
    
    if ([cmdargs objectForKey:@"captureVideoAverageBitrate"])
    {
        self.captureVideoAverageBitrate = (int)[cmdargs integerForKey:@"captureVideoAverageBitrate"];
    }
    
    if ([cmdargs objectForKey:@"captureVideoMaxBitrate"])
    {
        self.captureVideoMaxBitrate = (int)[cmdargs integerForKey:@"captureVideoMaxBitrate"];
    }
    
    if ([cmdargs objectForKey:@"captureVideoMaxKeyframeInterval"])
    {
        self.captureVideoMaxKeyframeInterval = (int)[cmdargs integerForKey:@"captureVideoMaxKeyframeInterval"];
    }
    
    if ([cmdargs objectForKey:@"audioBitrate"])
    {
        self.audioCaptureSession.audioBitrate = (int)[cmdargs integerForKey:@"audioBitrate"];
    }
    
    if ([cmdargs objectForKey:@"audioSamplerate"])
    {
        self.audioCaptureSession.audioSamplerate = (int)[cmdargs integerForKey:@"audioSamplerate"];
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
        self.x264crf = (int)[cmdargs integerForKey:@"x264crf"];
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
        self.captureFPS = [cmdargs doubleForKey:@"captureFPS"];
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
    
    self.videoCompressor = nil;
    self.captureRunning = NO;

    
    for (OutputDestination *out in _captureDestinations)
    {
        [out stopOutput];
    }
    
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8)
    {

        if (_PMAssertionRet == kIOReturnSuccess)
        {
            _PMAssertionRet = kIOReturnInvalid;
            IOPMAssertionRelease(_PMAssertionID);
        }
    } else {
        [[NSProcessInfo processInfo] endActivity:_activity_token];
    }
    
    
    [self.audioCaptureSession stopAudioCompression];
    @synchronized(self)
    {
        audioBuffer = [[NSMutableArray alloc] init];
        
    }
}

- (IBAction)streamButtonPushed:(id)sender {
    
    NSButton *button = (NSButton *)sender;
    
    
    [self.objectController commitEditing];
    
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
    
    if (!self.captureRunning)
    {
        return;
    }
    
    
    if (_firstFrameTime == 0)
    {
        //Don't start sending audio to the outputs until a video frame has arrived, with AVFoundation this can take 2+ seconds (!?)
        //Might need to prime the capture session first...
        return;
    }
    
    
    CMTime orig_pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    

    
    
    if (CMTIME_COMPARE_INLINE(_firstAudioTime, ==, kCMTimeZero))
    {
        NSLog(@"SETTING FIRST AUDIO TIME");
        _firstAudioTime = orig_pts;
        return;
    }
    
    CMTime real_pts = CMTimeSubtract(orig_pts, _firstAudioTime);
    CMTime adjust_pts = CMTimeMakeWithSeconds(self.audio_adjust, orig_pts.timescale);
    CMTime pts = CMTimeAdd(real_pts, adjust_pts);
    

    CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, pts);
    
    
    if (audioBuffer)
    {
        @synchronized(self)
        {
            [audioBuffer addObject:(__bridge id)sampleBuffer];
        }
    }
    /*
    for (OutputDestination *outdest in _captureDestinations)
    {
        if (outdest.active)
        {
            id ffmpeg = outdest.ffmpeg_out;
            [ffmpeg writeAudioSampleBuffer:sampleBuffer presentationTimeStamp:pts];
        }
    }
     */
    
}



-(BOOL) setupResolution:(CVImageBufferRef)withFrame error:(NSError **)therror
{
    
    if ([self.resolutionOption isEqualToString:@"None"])
    {
        if (!(self.captureHeight > 0) || !(self.captureWidth > 0))
        {
            if (therror)
            {
                *therror = [NSError errorWithDomain:@"videoCapture" code:150 userInfo:@{NSLocalizedDescriptionKey : @"Both width and height are required"}];
            }

            return NO;
        }
        
        return YES;
    }
    
    self.arOptions = @[@"None", @"Use Source", @"Preserve AR"];

    if ([self.resolutionOption isEqualToString:@"Use Source"])
    {
        self.captureHeight = (int)CVPixelBufferGetHeight(withFrame);
        self.captureWidth = (int)CVPixelBufferGetWidth(withFrame);
    } else if ([self.resolutionOption isEqualToString:@"Preserve AR"]) {
        float inputAR = (float)CVPixelBufferGetWidth(withFrame) / (float)CVPixelBufferGetHeight(withFrame);
        int newWidth;
        int newHeight;
        
        if (self.captureHeight > 0)
        {
            newHeight = self.captureHeight;
            newWidth = (int)(round(self.captureHeight * inputAR));
        } else if (self.captureWidth > 0) {
            newWidth = self.captureWidth;
            newHeight = (int)(round(self.captureWidth / inputAR));
        } else {
            
            if (therror)
            {
                *therror = [NSError errorWithDomain:@"videoCapture" code:160 userInfo:@{NSLocalizedDescriptionKey : @"Either width or height are required"}];
            }
            
            return NO;

        }
        
        self.captureHeight = (newHeight +1)/2*2;
        self.captureWidth = (newWidth+1)/2*2;
    }
    
    return YES;
}

-(double)mach_time_seconds
{
    uint64_t mach_now = mach_absolute_time();
    return (double)((mach_now * _mach_timebase.numer / _mach_timebase.denom))/NSEC_PER_SEC;
}


-(bool) sleepUntil:(double)target_time
{
    
    double mach_now = [self mach_time_seconds];
    
    
    if (target_time < mach_now)
    {
        return NO;
    }
    
    
    double mach_duration = target_time - mach_now;
    double mach_wait_time = mach_now + mach_duration/2.0;
    
    mach_wait_until(mach_wait_time*NSEC_PER_SEC);
    
    
    while ([self mach_time_seconds] < target_time)
    {
        usleep(500);
        
            //wheeeeeeeeeeeee
    }
    return YES;
}



-(void) setFrameThreadPriority
{

    thread_extended_policy_data_t policy;
    
    mach_port_t mach_thread_id = mach_thread_self();
    
    
    policy.timeshare = 0;
    thread_policy_set(mach_thread_id, THREAD_EXTENDED_POLICY, (thread_policy_t)&policy, THREAD_EXTENDED_POLICY_COUNT);
    
    thread_precedence_policy_data_t precedence;
    
    precedence.importance = 63;
    
    thread_policy_set(mach_thread_id, THREAD_PRECEDENCE_POLICY, (thread_policy_t)&precedence, THREAD_PRECEDENCE_POLICY_COUNT);
    
    const double guaranteedDutyCycle = 0.75;
    
    const double maxDutyCycle = 0.85;
    
    const double timequantum = 1;
    
    const double timeNeeded = guaranteedDutyCycle * timequantum;
    
    const double maxTimeAllowed = maxDutyCycle * timequantum;
    
    mach_timebase_info_data_t timebase_info;
    
    mach_timebase_info(&timebase_info);
    
    double ms_to_abs_time = ((double)timebase_info.denom / (double)timebase_info.numer) * 1000000;
    
    thread_time_constraint_policy_data_t time_constraints;
    
    time_constraints.period = timequantum * ms_to_abs_time;
    time_constraints.computation = timeNeeded * ms_to_abs_time;
    time_constraints.constraint = maxTimeAllowed * ms_to_abs_time;
    time_constraints.preemptible = 0;
    thread_policy_set(mach_thread_id, THREAD_TIME_CONSTRAINT_POLICY, (thread_policy_t)&time_constraints, THREAD_TIME_CONSTRAINT_POLICY_COUNT);
    
    
}


-(NSMutableArray *)swapAudioBuffer
{
 
    NSMutableArray *newBuf;
    newBuf = [[NSMutableArray alloc] init];
    
    NSMutableArray *retBuf;
    
    retBuf = audioBuffer;
    audioBuffer = newBuf;
    
    return retBuf;
}




-(void) newFrameDispatched
{
    _frame_time = [self mach_time_seconds];
    [self newFrame];

}


-(void) newFrameTimed
{
    double startTime;
    
    startTime = [self mach_time_seconds];
    double lastLoopTime = startTime;

    _frame_time = startTime;
    [self newFrame];
    
    //[self setFrameThreadPriority];
    while (1)
    {
        
        
        
        //_frame_time = nowTime;//startTime;
        double nowTime = [self mach_time_seconds];
        
        lastLoopTime = nowTime;
        
        if (![self sleepUntil:(startTime += _frame_interval)])
        {
            //NSLog(@"SLEEP FAILED");
            continue;
        }

        
        _frame_time = startTime;
        [self newFrame];
    }
    

}


-(CVPixelBufferRef)currentFrame
{
    
    if (self.videoCaptureSession)
    {
        return [self.videoCaptureSession getCurrentFrame];
    }
    
    return NULL;
}


-(void) newFrame
{

    CVPixelBufferRef newFrame;
    
        if (self.videoCaptureSession)
        {
            newFrame = [self.videoCaptureSession getCurrentFrame];
            if (newFrame)
            {
                if (self.captureRunning && !self.videoCompressor)
                {
                    [self setupCompressors];
                    NSError *error;
                    BOOL success;
                    NSLog(@"SETTING UP RESOLUTION");
                    success = [self setupResolution:newFrame error:&error];
                    if (success)
                    {
                        if ([self.videoCompressor setupCompressor] == YES)
                        {
                            self.videoCompressor.outputDelegate = self;
                        } else {
                            NSLog(@"Compressor failed to setup properly");
                            success = NO;
                            error = [NSError errorWithDomain:@"videoCompressor" code:110 userInfo:@{NSLocalizedDescriptionKey : @"Could not create compression session!"}];
                        }
                    }

                    if (!success)
                    {
                        [self stopStream];
                        [NSApp presentError:error];
                    } else {
                        
                        OutputDestination *output;
                        
                        NSLog(@"Attaching destinations");
                        for (output in _captureDestinations)
                        {
                            [self attachCaptureDestination:output];
                        }
                    }

                }
                
                
                
                if (self.captureRunning && self.videoCompressor)
                {
                    CapturedFrameData *capturedData = [[CapturedFrameData alloc] init];
                    
                    capturedData.videoFrame = newFrame;
                    
                    [self processVideoFrame:capturedData];
                //} else {
                }
                
                
                    CVPixelBufferRelease(newFrame);
              
                
            }
            
        }
}



-(void)processVideoFrame:(CapturedFrameData *)frameData
{

    
    //CVImageBufferRef imageBuffer = frameData.videoFrame;
    
    if (!self.captureRunning || !self.videoCompressor)
    {
        //CVPixelBufferRelease(imageBuffer);

        return;
    }
    CMTime pts;
    CMTime duration;
    
    
    //compressor should have a ready? method
    
    if (_firstFrameTime == 0)
    {
        
        
        _firstFrameTime = _frame_time;
        _next_keyframe_time = _frame_time;
        
    }
    
    CFAbsoluteTime ptsTime = _frame_time - _firstFrameTime;
    
    //NSLog(@"PTS TIME IS %f", ptsTime);
    
    
    _frameCount++;
    _lastFrameTime = _frame_time;
    
    
    pts = CMTimeMake(ptsTime*1000000, 1000000);
    
    duration = CMTimeMake(1000, self.captureFPS*1000);
    
    BOOL doKeyFrame = NO;
    
    if (_frame_time >= _next_keyframe_time)
    {
        doKeyFrame = YES;
        _next_keyframe_time += self.captureVideoMaxKeyframeInterval;
    }
    
    frameData.videoPTS = pts;
    frameData.videoDuration = duration;
    frameData.frameNumber = _frameCount;
    
    if (self.videoCompressor)
    {
        
        [self.videoCompressor compressFrame:frameData isKeyFrame:doKeyFrame];

    }
        
}


-(void)setCaptureFPS:(double)captureFPS
{
    
    _captureFPS = captureFPS;
    [self setupFrameTimer];
}

- (double) captureFPS
{
    
    return _captureFPS;
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
