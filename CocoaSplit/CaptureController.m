
//
//  CaptureController.m
//  H264Streamer
//
//  Created by Zakk on 9/2/12.
//  Copyright (c) 2012 Zakk. All rights reserved.

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

@synthesize selectedCompressorType = _selectedCompressorType;

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


- (IBAction)openOutputEdit:(id)sender
{
    long clickedRow = [sender clickedRow];
    
    self.editDestination = [self.captureDestinations objectAtIndex:clickedRow];
    
    if (!self.outputEditPanel)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"OutputPanel" owner:self topLevelObjects:nil];
        [NSApp beginSheet:self.outputEditPanel modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        
    }

}

- (IBAction)closeOutputPanel:(id)sender
{

    [NSApp endSheet:self.outputEditPanel];
    [self.outputEditPanel close];
    self.outputEditPanel = nil;


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


-(NSString *)selectedCompressorType
{
 
    return _selectedCompressorType;
}


-(void)setSelectedCompressorType:(NSString *)selectedCompressorType
{
    _selectedCompressorType = selectedCompressorType;
    self.compressTabLabel = selectedCompressorType;

    if (!self.editingCompressor || self.editingCompressor.isNew)
    {
        if ([selectedCompressorType isEqualToString:@"x264"])
        {
            self.editingCompressor = [[x264Compressor alloc] init];
        } else if ([selectedCompressorType isEqualToString:@"AppleVTCompressor"]) {
            self.editingCompressor = [[AppleVTCompressor alloc] init];
        } else {
            self.editingCompressor = nil;
        }
        if (self.editingCompressor)
        {
            self.editingCompressor.isNew = YES;
        }

    }
    
    
}




-(IBAction)newCompressPanel
{
    [self openCompressPanel:NO];
}

-(IBAction)editCompressPanel
{
    [self openCompressPanel:YES];
}


-(IBAction)deleteCompressorPanel
{
    
    if (self.editingCompressor)
    {
        NSString *deleteKey = self.editingCompressor.name;
        
        if (deleteKey)
        {
            self.selectedCompressor = nil;
            self.editingCompressor = nil;
            
            [self willChangeValueForKey:@"compressors"];
            [self.compressors removeObjectForKey:deleteKey];
            [self didChangeValueForKey:@"compressors"];
        }
    }
    
    [self closeCompressPanel];
}



-(IBAction)openCompressPanel:(bool)doEdit
{
    self.selectedCompressor = nil;
    
    if (self.compressController.selectedObjects.count > 0)
    {
        self.selectedCompressor = [[self.compressController.selectedObjects objectAtIndex:0] valueForKey:@"value"];
    }
    
    

    if (doEdit)
    {
        self.editingCompressor = self.selectedCompressor;
        self.editingCompressorKey = self.selectedCompressor.name;
        
        
        if (self.editingCompressor)
        {
            self.selectedCompressorType = self.editingCompressor.compressorType;
            self.compressTabLabel = self.editingCompressor.compressorType;
        }
    } else {
        self.selectedCompressorType = self.selectedCompressorType;
    }
    
    
    
    if (!self.compressPanel)
    {
        NSString *panelName;
        
        panelName = @"CompressionSettingsPanel";
        
        [[NSBundle mainBundle] loadNibNamed:panelName owner:self topLevelObjects:nil];
        

        
        [NSApp beginSheet:self.compressPanel modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        
    }
    
}


-(NSString *)addCompressor:(id <h264Compressor>)newCompressor
{
    NSMutableString *baseName = newCompressor.name;
    
    NSMutableString *newName = baseName;
    int name_try = 1;
    
    while (self.compressors[newName]) {
        newName = [NSMutableString stringWithFormat:@"%@#%d", baseName, name_try];
        name_try++;
    }
    
    newCompressor.name = newName;
    [self willChangeValueForKey:@"compressors"];
    [self.compressors setObject:newCompressor forKey:newName];
    [self didChangeValueForKey:@"compressors"];

    return newName;
    
}


-(void) setCompressSelection:(NSString *)forName
{
    
    for (id tmpval in self.compressController.arrangedObjects)
    {
        if ([[tmpval valueForKey:@"key"] isEqualToString:forName] )
        {
            [self.compressController setSelectedObjects:@[tmpval]];
            break;
        }
    }
}



-(IBAction)saveCompressPanel
{

    NSError *compressError;
    
    
    if (![self.compressSettingsController commitEditing])
    {
        NSLog(@"FAILED TO COMMIT EDITING FOR COMPRESS EDIT");
    }
    
    
    
    if (self.editingCompressor)
    {
        
        if (![self.editingCompressor validate:&compressError])
        {
            if (compressError)
            {
                [NSApp presentError:compressError];
            }
            return;
        }
        
        
        
        if (self.editingCompressor.isNew)
        {
            
            self.editingCompressor.isNew = NO;

            NSString *newName = [self addCompressor:self.editingCompressor];
            
            [self setCompressSelection:newName];

            
            
        } else if (![self.editingCompressorKey isEqualToString:self.editingCompressor.name]) {
            //the name was changed in the edit dialog, so create a new key entry and delete the old one
            NSString *newName = [self addCompressor:self.editingCompressor];
            
            


            [self willChangeValueForKey:@"compressors"];
            [self.compressors removeObjectForKey:self.editingCompressorKey];
            [self didChangeValueForKey:@"compressors"];
            [self setCompressSelection:newName];

            
            
        } else {
            [self.compressors setObject:self.editingCompressor forKey:self.editingCompressor.name];
        }
    }
    
    [self closeCompressPanel];
    
}


-(IBAction)closeCompressPanel
{
        
    [NSApp endSheet:self.compressPanel];
    [self.compressPanel close];
    self.compressPanel = nil;
    self.editingCompressor = nil;
    self.editingCompressorKey = nil;
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
    if (uniqueID)
    {
        self.audioCaptureSession.activeAudioDevice = [AVCaptureDevice deviceWithUniqueID:uniqueID];
    }
    
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




-(void) createCGLContext
{
    NSOpenGLPixelFormatAttribute glAttributes[] = {
        
        NSOpenGLPFAPixelBuffer,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFADepthSize, 32,
        (NSOpenGLPixelFormatAttribute) 0
        
    };
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:glAttributes];
    
    if (!pixelFormat)
    {
        return;
    }
    
    _ogl_ctx = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
    
    if (!_ogl_ctx)
    {
        return;
    }

    _cgl_ctx = [_ogl_ctx CGLContextObj];
    /*
    _cictx = [CIContext contextWithCGLContext:_cgl_ctx pixelFormat:CGLGetPixelFormat(_cgl_ctx) colorSpace:CGColorSpaceCreateDeviceRGB() options:nil];
    
    _cifilter = [CIFilter filterWithName:@"CISepiaTone"];
    [_cifilter setDefaults];
*/
    
    
}


-(bool) createPixelBufferPoolForSize:(NSSize) size
{
    
    NSLog(@"Controller: Creating Pixel Buffer Pool %f x %f", size.width, size.height);
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setValue:[NSNumber numberWithInt:size.width] forKey:(NSString *)kCVPixelBufferWidthKey];
    [attributes setValue:[NSNumber numberWithInt:size.height] forKey:(NSString *)kCVPixelBufferHeightKey];
    [attributes setValue:@{(NSString *)kIOSurfaceIsGlobal: @NO} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    [attributes setValue:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    
    
    if (_cvpool)
    {
        CVPixelBufferPoolRelease(_cvpool);
    }
    
    
    
    CVReturn result = CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)(attributes), &_cvpool);
    
    if (result != kCVReturnSuccess)
    {
        return NO;
    }
    
    return YES;
    
    
}


-(id) init
{
   if (self = [super init])
   {
       
       
#ifndef DEBUG
       [self setupLogging];
#endif
       
       

       audioLastReadPosition = 0;
       audioWritePosition = 0;
       
       audioBuffer = [[NSMutableArray alloc] init];
       videoBuffer = [[NSMutableArray alloc] init];
       
       
       
       self.useStatusColors = YES;
       
       
       dispatch_source_t sigsrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGPIPE, 0, dispatch_get_global_queue(0, 0));
       dispatch_source_set_event_handler(sigsrc, ^{ return;});
       dispatch_resume(sigsrc);
       
       _main_capture_queue = dispatch_queue_create("CocoaSplit.main.queue", NULL);
       _preview_queue = dispatch_queue_create("CocoaSplit.preview.queue", NULL);
       
       self.destinationTypes = @{@"file" : @"File/Raw",
       @"twitch" : @"Twitch TV"};
       
       
       
       self.showPreview = YES;
       self.videoTypes = @[@"Desktop", @"AVFoundation", @"QTCapture", @"Syphon", @"Image"];
       self.compressorTypes = @[@"x264", @"AppleVTCompressor", @"None"];
       self.arOptions = @[@"None", @"Use Source", @"Preserve AR"];
       self.validSamplerates = @[@44100, @48000];
       
       
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
       
       _statistics_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
       
       dispatch_source_set_timer(_statistics_timer, DISPATCH_TIME_NOW, 1*NSEC_PER_SEC, 0);
       dispatch_source_set_event_handler(_statistics_timer, ^{
           
           for (OutputDestination *outdest in _captureDestinations)
           {
               [outdest updateStatistics];
           }

       });
       
       dispatch_resume(_statistics_timer);
       
       
       self.extraSaveData = [[NSMutableDictionary alloc] init];
       [self createCGLContext];
       
       
           

       
   }
    
    return self;
    
}


-(NSColor *)statusColor
{
    if (self.captureRunning && [self streamsActiveCount] > 0)
    {
        return [NSColor redColor];
    }
    
    if ([self streamsPendingCount] > 0)
    {
        return [NSColor orangeColor];
    }
    
    return [NSColor blackColor];
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
    
    
    NSAttributedString *appendStr = [[NSAttributedString alloc] initWithString:logLine];
    [[self.logTextView textStorage] beginEditing];

    [self.logTextView.textStorage appendAttributedString:appendStr];
    
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
    
    _log_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, [self.logReadHandle fileDescriptor], 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_event_handler(_log_source, ^{
       
        void *data = malloc(512);
        ssize_t read_size = 0;
        do
        {
            errno = 0;
            read_size = read([self.logReadHandle fileDescriptor], data, 512);
        } while (read_size == -1 && errno == EINTR);
        
        if (read_size > 0)
        {
            

            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *logStr = [[NSString alloc] initWithBytesNoCopy:data length:read_size encoding:NSUTF8StringEncoding freeWhenDone:YES];
                [self appendToLogView:logStr];
                
            });
        } else {
            free(data);
        }
        
        
        
    });
    
    dispatch_resume(_log_source);
}

-(void) migrateDefaultCompressor:(NSMutableDictionary *)saveRoot
{
    
    if (self.compressors[@"default"])
    {
        //We already migrated, or the user did it for us?
        return;
    }
    

    
    id <h264Compressor> newCompressor;
    if ([self.selectedCompressorType isEqualToString:@"x264"])
    {
        
        x264Compressor *tmpCompressor;
        
        tmpCompressor = [[x264Compressor alloc] init];
        tmpCompressor.tune = [saveRoot valueForKey:@"x264tune"];
        tmpCompressor.profile = [saveRoot valueForKey:@"x264profile"];
        tmpCompressor.preset = [saveRoot valueForKey:@"x264preset"];
        tmpCompressor.use_cbr = [[saveRoot valueForKey:@"videoCBR"] boolValue];
        tmpCompressor.crf = [[saveRoot valueForKey:@"x264crf"] intValue];
        tmpCompressor.vbv_maxrate = [[saveRoot valueForKey:@"captureVideoAverageBitrate"] intValue];
        tmpCompressor.vbv_buffer = [[saveRoot valueForKey:@"captureVideoMaxBitrate"] intValue];
        tmpCompressor.keyframe_interval = [[saveRoot valueForKey:@"captureVideoMaxKeyframeInterval"] intValue];
        newCompressor = tmpCompressor;
    } else if ([self.selectedCompressorType isEqualToString:@"AppleVTCompressor"]) {
        AppleVTCompressor *tmpCompressor;
        tmpCompressor = [[AppleVTCompressor alloc] init];
        tmpCompressor.average_bitrate = [[saveRoot valueForKey:@"captureVideoAverageBitrate"] intValue];
        tmpCompressor.max_bitrate = [[saveRoot valueForKey:@"captureVideoMaxBitrate"] intValue];
        tmpCompressor.keyframe_interval = [[saveRoot valueForKey:@"captureVideoMaxKeyframeInterval"] intValue];
        newCompressor = tmpCompressor;
    } else {
        newCompressor = nil;
    }

    if (newCompressor)
    {
        
        newCompressor.width = [[saveRoot valueForKey:@"captureWidth"] intValue];
        newCompressor.height = [[saveRoot valueForKey:@"captureHeight"] intValue];
        if ([saveRoot valueForKey:@"resolutionOption"])
        {
            newCompressor.resolutionOption = [saveRoot valueForKey:@"resolutionOption"];
        }
        
        
        newCompressor.name = [@"default" mutableCopy];
        [self addCompressor:newCompressor];
    }
    
}


-(void) saveSettings
{
    
    NSString *path = [self saveFilePath];
    
    NSMutableDictionary *saveRoot;
    
    saveRoot = [NSMutableDictionary dictionary];
    
    [saveRoot setValue: [NSNumber numberWithInt:self.captureWidth] forKey:@"captureWidth"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureHeight] forKey:@"captureHeight"];
    [saveRoot setValue: [NSNumber numberWithDouble:self.videoCaptureSession.videoCaptureFPS] forKey:@"captureFPS"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioCaptureSession.audioBitrate] forKey:@"audioBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioCaptureSession.audioSamplerate] forKey:@"audioSamplerate"];
    [saveRoot setValue: self.selectedVideoType forKey:@"selectedVideoType"];
    [saveRoot setValue: self.videoCaptureSession.activeVideoDevice.uniqueID forKey:@"videoCaptureID"];
    [saveRoot setValue: self.selectedAudioCapture.uniqueID forKey:@"audioCaptureID"];
    [saveRoot setValue: self.captureDestinations forKey:@"captureDestinations"];
    [saveRoot setValue: self.selectedCompressorType forKey:@"selectedCompressorType"];
    [saveRoot setValue:[NSNumber numberWithFloat:self.audioCaptureSession.previewVolume] forKey:@"previewVolume"];
    [saveRoot setValue:[NSNumber numberWithInt:self.maxOutputDropped] forKey:@"maxOutputDropped"];
    [saveRoot setValue:[NSNumber numberWithInt:self.maxOutputPending] forKey:@"maxOutputPending"];
    [saveRoot setValue:self.resolutionOption forKey:@"resolutionOption"];
    [saveRoot setValue:[NSNumber numberWithDouble:self.audio_adjust] forKey:@"audioAdjust"];
    [saveRoot setValue: [NSNumber numberWithBool:self.useStatusColors] forKey:@"useStatusColors"];
    [saveRoot setValue:self.compressors forKey:@"compressors"];
    [saveRoot setValue:self.extraSaveData forKey:@"extraSaveData"];

    NSUInteger compressoridx =    [self.compressController selectionIndex];

    
    [saveRoot setValue:[NSNumber numberWithUnsignedInteger:compressoridx] forKey:@"selectedCompressor"];
    
    
    
    
    
    
    
    
    
    
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
    self.audioCaptureSession.audioBitrate = [[saveRoot valueForKey:@"audioBitrate"] intValue];
    self.audioCaptureSession.audioSamplerate = [[saveRoot valueForKey:@"audioSamplerate"] intValue];
   
    self.compressors = [[saveRoot valueForKey:@"compressors"] mutableCopy];
    
    
    if (!self.compressors)
    {
        self.compressors = [[NSMutableDictionary alloc] init];
        
    }
    
    NSUInteger selectedCompressoridx = [[saveRoot valueForKey:@"selectedCompressor"] unsignedIntegerValue];
    
    
    if (self.compressors.count > 0)
    {
        [self.compressController setSelectionIndex:selectedCompressoridx];
    }

    
    self.captureDestinations = [saveRoot valueForKey:@"captureDestinations"];
    
    if (!self.captureDestinations)
    {
        self.captureDestinations = [[NSMutableArray alloc] init];
    }
    
    
    for (OutputDestination *outdest in _captureDestinations)
    {
        outdest.settingsController = self;
    }


    
    self.useStatusColors = [[saveRoot valueForKeyPath:@"useStatusColors"] boolValue];
    
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
    
    self.videoCaptureSession.videoCaptureFPS = [[saveRoot valueForKey:@"captureFPS"] doubleValue];
    self.maxOutputDropped = [[saveRoot valueForKey:@"maxOutputDropped"] intValue];
    self.maxOutputPending = [[saveRoot valueForKey:@"maxOutputPending"] intValue];

    self.audio_adjust = [[saveRoot valueForKey:@"audioAdjust"] doubleValue];
    
    self.resolutionOption = [saveRoot valueForKey:@"resolutionOption"];
    if (!self.resolutionOption)
    {
        self.resolutionOption = @"None";
    }

    [self migrateDefaultCompressor:saveRoot];
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
    newDest.settingsController = self;
    [self closeCreateSheet:nil];
    
}





- (void) outputEncodedData:(CapturedFrameData *)newFrameData 
{

    [videoBuffer addObject:newFrameData];
    //This is here to facilitate future video buffering/delay. Right now the buffer is effectively 1 frame..
    
    CapturedFrameData *frameData = [videoBuffer objectAtIndex:0];
    
    [videoBuffer removeObjectAtIndex:0];
    
    
    
    
    for (OutputDestination *outdest in _captureDestinations)
    {
        [outdest writeEncodedData:frameData];
        
    }
    
}




-(bool) setupCompressors
{
    
    
    id <h264Compressor> tmpCompressor;
    
    for (id cKey in self.compressors)
    {
        id <h264Compressor> tmpcomp = self.compressors[cKey];
        tmpcomp.settingsController = self;
    }
    
    
    if (!self.selectedCompressor)
    {
    
        if (self.compressController.selectedObjects.count > 0)
        {
            tmpCompressor = [[self.compressController.selectedObjects objectAtIndex:0] valueForKey:@"value"];
            if (tmpCompressor)
            {
                self.selectedCompressor = self.compressors[tmpCompressor.name];
            }
            
        }
    }

    
    if (self.selectedCompressor)
    {
        
        self.selectedCompressor.settingsController = self;
    }
    
    for (OutputDestination *outdest in _captureDestinations)
    {
        //make the outputs pick up the default selected compressor
        [outdest setupCompressor];
    }
    
    
    
    [self.audioCaptureSession setupAudioCompression];
    
    _frameCount = 0;
    _firstAudioTime = kCMTimeZero;
    _firstFrameTime = 0;
    
    _compressedFrameCount = 0;
    _min_delay = _max_delay = _avg_delay = 0;

    //self.videoCompressor = self.selectedCompressor;
    
    return YES;

    
}

-(int)audioBitrate
{
    return self.audioCaptureSession.audioBitrate;
    
}

-(int)audioSamplerate
{
    return self.audioCaptureSession.audioSamplerate;
}

-(double) captureFPS
{
    return self.videoCaptureSession.videoCaptureFPS;
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

    
    for (OutputDestination *outdest in _captureDestinations)
    {
        [outdest reset];
    }
    
    
    self.captureRunning = YES;

    return YES;
    
}



-(void) setupFrameTimer
{
    NSLog(@"SETTING UP FRAME TIMER %f", self.videoCaptureSession.videoCaptureFPS);
    
    if (self.videoCaptureSession.videoCaptureFPS && self.videoCaptureSession.videoCaptureFPS > 0)
    {
        _frame_interval = (1.0/self.videoCaptureSession.videoCaptureFPS);
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
    


    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict options:0 error:nil];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}


-(id <h264Compressor>) buildCmdlineCompressor:(NSUserDefaults *)cmdargs
{
    
    id <h264Compressor> newCompressor;
    if ([self.selectedCompressorType isEqualToString:@"x264"])
    {
        
        x264Compressor *tmpCompressor;
        
        tmpCompressor = [[x264Compressor alloc] init];
        tmpCompressor.tune = [cmdargs stringForKey:@"x264tune"];
        tmpCompressor.profile = [cmdargs stringForKey:@"x264profile"];
        tmpCompressor.preset = [cmdargs stringForKey:@"x264preset"];
        tmpCompressor.use_cbr = [cmdargs boolForKey:@"videoCBR"];
        tmpCompressor.crf = (int)[cmdargs integerForKey:@"x264crf"];
        tmpCompressor.vbv_maxrate = (int)[cmdargs integerForKey:@"captureVideoAverageBitrate"];
        tmpCompressor.vbv_buffer = (int)[cmdargs integerForKey:@"captureVideoMaxBitrate"];
        tmpCompressor.keyframe_interval = (int)[cmdargs integerForKey:@"captureVideoMaxKeyframeInterval"];
        newCompressor = tmpCompressor;
    } else if ([self.selectedCompressorType isEqualToString:@"AppleVTCompressor"]) {
        AppleVTCompressor *tmpCompressor;
        tmpCompressor = [[AppleVTCompressor alloc] init];
        tmpCompressor.average_bitrate = (int)[cmdargs integerForKey:@"captureVideoAverageBitrate"];
        tmpCompressor.max_bitrate = (int)[cmdargs integerForKey:@"captureVideoMaxBitrate"];
        tmpCompressor.keyframe_interval = (int)[cmdargs integerForKey:@"captureVideoMaxKeyframeInterval"];
        newCompressor = tmpCompressor;
    } else {
        newCompressor = nil;
    }

    return newCompressor;
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
    
    if ([cmdargs objectForKey:@"audioBitrate"])
    {
        self.audioCaptureSession.audioBitrate = (int)[cmdargs integerForKey:@"audioBitrate"];
    }
    
    if ([cmdargs objectForKey:@"audioSamplerate"])
    {
        self.audioCaptureSession.audioSamplerate = (int)[cmdargs integerForKey:@"audioSamplerate"];
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
            newDest.settingsController = self;
            [[self mutableArrayValueForKey:@"captureDestinations"] addObject:newDest];
        }
        
    }
    
    if ([cmdargs objectForKey:@"compressor"])
    {
        NSString *forName = [cmdargs stringForKey:@"compressor"];
        
        for (id tmpval in self.compressController.arrangedObjects)
        {
            if ([[tmpval valueForKey:@"key"] isEqualToString:forName] )
            {
                self.selectedCompressor = tmpval;
                break;
            }
        }

    } else {
        self.selectedCompressor = [self buildCmdlineCompressor:cmdargs];
    }
}


- (void)stopStream
{
    
    self.videoCompressor = nil;
    self.selectedCompressor = nil;
    self.captureRunning = NO;

    
    for (id cKey in self.compressors)
    {
        id <h264Compressor> ctmp = self.compressors[cKey];
        if (ctmp)
        {
            [ctmp reset];
        }
    }

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
}

- (IBAction)streamButtonPushed:(id)sender {
    
    NSButton *button = (NSButton *)sender;
    
    
    [self.objectController commitEditing];
    
    if ([button state] == NSOnState)
    {
        if ([self pendingStreamConfirmation:@"Start streaming?"] == NO)
        {
            [sender setNextState];
            return;
        }
        
        
        
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
        
        _firstAudioTime = orig_pts;
        return;
    }
    
    CMTime real_pts = CMTimeSubtract(orig_pts, _firstAudioTime);
    CMTime adjust_pts = CMTimeMakeWithSeconds(self.audio_adjust, orig_pts.timescale);
    CMTime pts = CMTimeAdd(real_pts, adjust_pts);
    

    //NSLog(@"AUDIO PTS %@", CMTimeCopyDescription(kCFAllocatorDefault, pts));
    
    CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, pts);
    
    for(id cKey in self.compressors)
    {
        
        id <h264Compressor> compressor;
        compressor = self.compressors[cKey];
        [compressor addAudioData:sampleBuffer];
        
    }
}




-(double)mach_time_seconds
{
    double retval;
    
    uint64_t mach_now = mach_absolute_time();
    retval = (double)((mach_now * _mach_timebase.numer / _mach_timebase.denom))/NSEC_PER_SEC;
    return retval;
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


-(CVPixelBufferRef)currentImg
{
    
    @autoreleasepool {
        
        CVPixelBufferRef newFrame = [self currentFrame];
        CVPixelBufferRef destFrame = NULL;
        
        if (self.videoCaptureSession)
        {
            newFrame = [self.videoCaptureSession getCurrentFrame];
        }

        
        
        if (!newFrame)
        {
            return nil;
        }
        
        CGFloat frameWidth, frameHeight;
        
        frameWidth = CVPixelBufferGetWidth(newFrame);
        frameHeight = CVPixelBufferGetHeight(newFrame);
        
        NSSize frameSize = NSMakeSize(frameHeight, frameWidth);
        
        if (!CGSizeEqualToSize(frameSize, _cvpool_size))
         {
             [self createPixelBufferPoolForSize:NSMakeSize(CVPixelBufferGetWidth(newFrame), CVPixelBufferGetHeight(newFrame))];
             _cvpool_size = frameSize;
         
         }
        
        
        if (!_cictx)
        {
            
            _cictx = [CIContext contextWithCGLContext:_cgl_ctx pixelFormat:CGLGetPixelFormat(_cgl_ctx) colorSpace:CGColorSpaceCreateDeviceRGB() options:nil];
            

        }
        
        if (!_cifilter)
        {
            _cifilter = [CIFilter filterWithName:@"CISepiaTone"];
            [_cifilter setDefaults];

        }

        CIImage *tmpimg = [CIImage imageWithIOSurface:CVPixelBufferGetIOSurface(newFrame)];
        
        CVPixelBufferRelease(newFrame);
        
        
        CIImage *outimg;
        
        [_cifilter setValue:tmpimg forKey:kCIInputImageKey];
        
        
        outimg = [_cifilter valueForKey:kCIOutputImageKey];
        
        CVPixelBufferPoolCreatePixelBuffer(kCVReturnSuccess, _cvpool, &destFrame);
        
        [_cictx render:outimg toIOSurface:CVPixelBufferGetIOSurface(destFrame) bounds:outimg.extent colorSpace:CGColorSpaceCreateDeviceRGB()];
        
    
    
        @synchronized(self)
        {
            if (_currentPB)
            {
                CVPixelBufferRelease(_currentPB);
            }
            
            _currentPB = destFrame;
        }
        
    }
    return _currentPB;
}

-(CVPixelBufferRef)currentFrame
{

    
    @synchronized(self)
    {
        return _currentPB;
    }
}


-(void) newFrame
{

        CVPixelBufferRef newFrame;
    
        if (self.videoCaptureSession)
        {
            newFrame = [self currentImg];
            
            
            if (newFrame)
            {
                CVPixelBufferRetain(newFrame);
                if (self.captureRunning)
                {
                    if (self.captureRunning != _last_running_value)
                    {
                        [self setupCompressors];
                    }
                    
                    
                    [self processVideoFrame:newFrame];

                    
                } else {
                    
                    for (OutputDestination *outdest in _captureDestinations)
                    {
                        [outdest writeEncodedData:nil];
                    }

                }
                _last_running_value = self.captureRunning;
                
                CVPixelBufferRelease(newFrame);

                
            }
        }
}



-(void)processVideoFrame:(CVPixelBufferRef)videoFrame
{

    
    //CVImageBufferRef imageBuffer = frameData.videoFrame;
    
    if (!self.captureRunning)
    {
        //CVPixelBufferRelease(imageBuffer);

        return;
    }
    CMTime pts;
    CMTime duration;
    
    
    
    if (_firstFrameTime == 0)
    {
        _firstFrameTime = _frame_time;
        
    }
    
    CFAbsoluteTime ptsTime = _frame_time - _firstFrameTime;
    
    //NSLog(@"PTS TIME IS %f", ptsTime);
    
    
    _frameCount++;
    _lastFrameTime = _frame_time;
    
    
    pts = CMTimeMake(ptsTime*1000000, 1000000);
    //NSLog(@"PTS TIME IS %@", CMTimeCopyDescription(kCFAllocatorDefault, pts));

    duration = CMTimeMake(1000, self.videoCaptureSession.videoCaptureFPS*1000);
    
    for(id cKey in self.compressors)
    {
        CapturedFrameData *newFrameData = [[CapturedFrameData alloc] init];
        
        newFrameData.videoPTS = pts;
        newFrameData.videoDuration = duration;
        newFrameData.frameNumber = _frameCount;
        newFrameData.frameTime = _frame_time;
        newFrameData.videoFrame = videoFrame;
        
        id <h264Compressor> compressor;
        compressor = self.compressors[cKey];
        [compressor compressFrame:newFrameData];

    }
        
}

-(int)streamsActiveCount
{
    int ret = 0;
    for (OutputDestination *outdest in _captureDestinations)
    {
        if (outdest.active)
        {
            ret++;
        }
    }

    return ret;
}


-(int)streamsPendingCount
{
    int ret = 0;
    
    for (OutputDestination *outdest in _captureDestinations)
    {
        if (outdest.buffer_draining)
        {
            ret++;
        }
    }

    return ret;
}


-(bool)actionConfirmation:(NSString *)queryString infoString:(NSString *)infoString
{
    
    bool retval;
    
    NSAlert *confirmationAlert = [[NSAlert alloc] init];
    [confirmationAlert addButtonWithTitle:@"Yes"];
    [confirmationAlert addButtonWithTitle:@"No"];
    [confirmationAlert setMessageText:queryString];
    if (infoString)
    {
        [confirmationAlert setInformativeText:infoString];
    }
    
    [confirmationAlert setAlertStyle:NSWarningAlertStyle];
    
    if ([confirmationAlert runModal] == NSAlertFirstButtonReturn)
    {
        retval = YES;
    } else {
        retval = NO;
    }

    return retval;
}


-(bool)pendingStreamConfirmation:(NSString *)queryString
{
    int pending_count = [self streamsPendingCount];
    bool retval;
    
    if (pending_count > 0)
    {
        retval = [self actionConfirmation:queryString infoString:[NSString stringWithFormat:@"There are %d streams pending output", pending_count]];
    } else {
        retval = YES;
    }
    
    return retval;
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

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    
    
    if (self.captureRunning && [self streamsActiveCount] > 0)

    {
        if ([self actionConfirmation:@"Really quit?" infoString:@"There are still active outputs"])
        {
            return NSTerminateNow;
        } else {
            return NSTerminateCancel;
        }
    }
    
    if ([self pendingStreamConfirmation:@"Quit now?"])
    {
        return NSTerminateNow;
    } else {
        return NSTerminateCancel;
    }
    return NSTerminateNow;
    
}
@end
