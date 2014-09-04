//
//  CaptureController.m
//  H264Streamer
//
//  Created by Zakk on 9/2/12.
//  Copyright (c) 2012 Zakk. All rights reserved.

#import "CaptureController.h"
#import "FFMpegTask.h"
#import "OutputDestination.h"
#import "PreviewView.h"
#import <IOSurface/IOSurface.h>
#import "CSCaptureSourceProtocol.h"
#import "x264.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import "x264Compressor.h"
#import "InputSource.h"
#import "InputPopupControllerViewController.h"
#import "SourceLayout.h"
#import "LayoutPreviewWindowController.h"


@implementation CaptureController

@synthesize selectedCompressorType = _selectedCompressorType;
@synthesize captureFPS = _captureFPS;
@synthesize selectedLayout = _selectedLayout;




- (IBAction)deleteLayout:(id)sender
{
    if (self.selectedLayout)
    {
        if ([self actionConfirmation:[NSString stringWithFormat:@"Really delete %@?", self.selectedLayout.name] infoString:nil])
        {
            [self willChangeValueForKey:@"sourceLayouts"];
            self.selectedLayout.isActive = NO;
            [self.sourceLayouts removeObject:self.selectedLayout];
            
            [self didChangeValueForKey:@"sourceLayouts"];
            self.selectedLayout = nil;
        }
    }
}



-(SourceLayout *)findLayoutWithName:(NSString *)name
{
    for(SourceLayout *layout in self.sourceLayouts)
    {
        if([layout.name isEqualToString:name])
        {
            return layout;
        }
    }
    
    return nil;
}

- (IBAction)createNewLayout:(id)sender
{
    
    SourceLayout *oldLayout = self.selectedLayout;
    
    [self.layoutPanelController commitEditing];
    
    if (self.layoutPanelName)
    {
        
        NSMutableString *baseName = self.layoutPanelName.mutableCopy;
        
        NSMutableString *newName = baseName;
        int name_try = 1;
        
        while ([self findLayoutWithName:newName]) {
            newName = [NSMutableString stringWithFormat:@"%@#%d", baseName, name_try];
            name_try++;
        }

        
        SourceLayout *newLayout = [[SourceLayout alloc] init];
        newLayout.name = newName;
        
        [self willChangeValueForKey:@"sourceLayouts"];
        
        [self.sourceLayouts addObject:newLayout];
        [self didChangeValueForKey:@"sourceLayouts"];
        oldLayout.isActive = NO;
    }
    
    self.layoutPanelName  = nil;
    
    [NSApp endSheet:self.layoutPanel];
    [self.layoutPanel close];
}



- (IBAction)closeLayoutPanel:(id)sender
{
    [NSApp endSheet:self.layoutPanel];
    [self.layoutPanel close];

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
        id <h264Compressor> tmpCompressor;
        tmpCompressor = [[self.compressController.selectedObjects objectAtIndex:0] valueForKey:@"value"];
        
        
        self.selectedCompressor = self.compressors[tmpCompressor.name];
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

- (IBAction)addInputSource:(id)sender
{
    if (self.selectedLayout)
    {
        
    
        InputSource *newSource = [[InputSource alloc] init];
        [self.selectedLayout addSource:newSource];
        [self.previewCtx spawnInputSettings:newSource atRect:NSZeroRect];
    }
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
    
    
    self.streamServiceObject = nil;
    
    NSMutableDictionary *servicePlugins = [[CSPluginLoader sharedPluginLoader] streamServicePlugins];
    
    
    Class serviceClass = servicePlugins[self.selectedDestinationType];;
    
    
    if (serviceClass)
    {
        self.streamServiceObject = [[serviceClass alloc] init];
    }
    
    
    
    
    
    if (self.streamServiceObject)
    {
        NSViewController *serviceConfigView = [self.streamServiceObject getConfigurationView];
        self.streamServiceAddView.frame = serviceConfigView.view.frame;
        
        [self.streamServiceAddView addSubview:serviceConfigView.view];
        self.streamServicePluginViewController  = serviceConfigView;
        [NSApp beginSheet:self.streamServiceConfWindow modalForWindow:[[NSApp delegate] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    }
    
}


-(IBAction)closeCreateSheet:(id)sender
{
    
    
    [self.streamServicePluginViewController.view removeFromSuperview];
    
    NSLog(@"STREAM SERVICE CONFI WINDOW %@", self.streamServiceConfWindow);
    
    [NSApp endSheet:self.streamServiceConfWindow];
    [self.streamServiceConfWindow close];
    self.streamServicePluginViewController = nil;
    self.streamServiceObject = nil;
    
}

- (IBAction)openLayoutPanel:(id)sender
{
    if (!self.layoutPanel)
    {
        
        [[NSBundle mainBundle] loadNibNamed:@"NewLayoutPanel" owner:self topLevelObjects:nil];
        
    }
    [NSApp beginSheet:self.layoutPanel modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
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


-(void)setCaptureFPS:(double)captureFPS
{
    _captureFPS = captureFPS;
    [self setupFrameTimer];
}


-(double)captureFPS
{
    return _captureFPS;
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




-(id) init
{
   if (self = [super init])
   {
       
       [[CSPluginLoader sharedPluginLoader] loadAllBundles];
       
#ifndef DEBUG
       [self setupLogging];
#endif
       
       

       audioLastReadPosition = 0;
       audioWritePosition = 0;
       
       audioBuffer = [[NSMutableArray alloc] init];
       videoBuffer = [[NSMutableArray alloc] init];
       
       
       _max_render_time = 0.0f;
       _min_render_time = 0.0f;
       _avg_render_time = 0.0f;
       _render_time_total = 0.0f;
       
       self.useStatusColors = YES;
       
       
       dispatch_source_t sigsrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGPIPE, 0, dispatch_get_global_queue(0, 0));
       dispatch_source_set_event_handler(sigsrc, ^{ return;});
       dispatch_resume(sigsrc);
       
       _main_capture_queue = dispatch_queue_create("CocoaSplit.main.queue", NULL);
       _preview_queue = dispatch_queue_create("CocoaSplit.preview.queue", NULL);
       
       
       
       self.showPreview = YES;
       self.videoTypes = @[@"Desktop", @"AVFoundation", @"QTCapture", @"Syphon", @"Image", @"Text"];
       self.compressorTypes = @[@"x264", @"AppleVTCompressor", @"None"];
       self.arOptions = @[@"None", @"Use Source", @"Preserve AR"];
       self.validSamplerates = @[@44100, @48000];
       
       
       self.audioCaptureSession = [[AVFAudioCapture alloc] init];
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
           
           self.renderStatsString = [NSString stringWithFormat:@"Render min/max/avg: %f/%f/%f", _min_render_time, _max_render_time, _render_time_total / _renderedFrames];
           _renderedFrames = 0;
           _render_time_total = 0.0f;
           

       });
       
       dispatch_resume(_statistics_timer);
       
       
       self.extraSaveData = [[NSMutableDictionary alloc] init];
       
       //load all filters, then load our custom filter(s)
       
       [CIPlugIn loadAllPlugIns];
       
       [[CSPluginLoader sharedPluginLoader] loadPrivateAndUserImageUnits];
       
        [self createCGLContext];
       _cictx = [CIContext contextWithCGLContext:_cgl_ctx pixelFormat:CGLGetPixelFormat(_cgl_ctx) colorSpace:CGColorSpaceCreateDeviceRGB() options:nil];


       
       
           

       
   }
    
    return self;
    
}


-(NSArray *)destinationTypes
{
    
    NSMutableDictionary *servicePlugins = [[CSPluginLoader sharedPluginLoader] streamServicePlugins];

    return servicePlugins.allKeys;
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
    [saveRoot setValue: [NSNumber numberWithDouble:self.captureFPS] forKey:@"captureFPS"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioCaptureSession.audioBitrate] forKey:@"audioBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioCaptureSession.audioSamplerate] forKey:@"audioSamplerate"];
    [saveRoot setValue: self.selectedVideoType forKey:@"selectedVideoType"];
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

    
    [saveRoot setValue:[NSNumber numberWithUnsignedInteger:compressoridx] forKey:@"selectedCompressor"];\
    
    //[saveRoot setValue:self.sourceList forKeyPath:@"sourceList"];
    
    [saveRoot setValue:self.selectedLayout forKey:@"selectedLayout"];
    
    [saveRoot setValue:self.sourceLayouts forKey:@"sourceLayouts"];
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

    
    
    NSString *audioID = [saveRoot valueForKey:@"audioCaptureID"];
    
    [self selectedAudioCaptureFromID:audioID];
    self.audioCaptureSession.previewVolume = [[saveRoot valueForKey:@"previewVolume"] floatValue];
    
    self.captureFPS = [[saveRoot valueForKey:@"captureFPS"] doubleValue];
    self.maxOutputDropped = [[saveRoot valueForKey:@"maxOutputDropped"] intValue];
    self.maxOutputPending = [[saveRoot valueForKey:@"maxOutputPending"] intValue];

    self.audio_adjust = [[saveRoot valueForKey:@"audioAdjust"] doubleValue];
    
    self.resolutionOption = [saveRoot valueForKey:@"resolutionOption"];
    if (!self.resolutionOption)
    {
        self.resolutionOption = @"None";
    }

    self.sourceLayouts = [saveRoot valueForKey:@"sourceLayouts"];
    
    if (!self.sourceLayouts)
    {
        self.sourceLayouts = [[NSMutableArray alloc] init];
        SourceLayout *newLayout = [[SourceLayout alloc] init];
        newLayout.name = @"default";
        [[self mutableArrayValueForKey:@"sourceLayouts" ] addObject:newLayout];
        self.selectedLayout = newLayout;
        newLayout.isActive = YES;
        
    } else {
    
        self.selectedLayout = [saveRoot valueForKey:@"selectedLayout"];
        
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



-(void)setSelectedLayout:(SourceLayout *)selectedLayout
{
    SourceLayout *currentLayout = _selectedLayout;
    
    _selectedLayout = selectedLayout;
    selectedLayout.isActive = YES;
    selectedLayout.controller = self;
    selectedLayout.ciCtx = _cictx;
    self.previewCtx.sourceLayout = selectedLayout;
    currentLayout.isActive = NO;
    
}

-(SourceLayout *)selectedLayout
{
    return _selectedLayout;
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
    
    [self.streamServicePluginViewController commitEditing];
    
    NSString *destination = [self.streamServiceObject getServiceDestination];
    
    newDest = [[OutputDestination alloc] initWithType:[self.streamServiceObject.class label]];
    newDest.destination = destination;
    
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
    
    
    /*
    if ([cmdargs objectForKey:@"videoCaptureID"])
    {
        NSString *videoID = [cmdargs stringForKey:@"videoCaptureID"];
        [self selectedVideoCaptureFromID:videoID];
    }
    
     */
    
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
            NSLog(@"SLEEP FAILED");
            continue;
        }

        
        _frame_time = startTime;
        [self newFrame];
    }
    

}

-(void)deleteSource:(InputSource *)delSource
{
    
    if (self.selectedLayout)
    {
        [self.selectedLayout deleteSource:delSource];
    }
    delSource.editorController = nil;
    
}

/*
-(NSArray *)sourceListOrdered
{
    NSArray *listCopy = [self.selectedLayout.sourceList sortedArrayUsingDescriptors:@[_sourceDepthSorter, _sourceUUIDSorter]];
    return listCopy;
}
 */



-(InputSource *)findSource:(NSPoint)forPoint
{
    return [self.selectedLayout findSource:forPoint];
}



-(CVPixelBufferRef) currentFrame
{
    return [self.selectedLayout currentFrame];
}


-(void) newFrame
{

        CVPixelBufferRef newFrame;
    
        //if (self.videoCaptureSession)
        {
            
            double nfstart = [self mach_time_seconds];
            
            newFrame = [self.selectedLayout currentImg];
            //newFrame = [self currentFrame];
            
            
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

    duration = CMTimeMake(1000, self.captureFPS*1000);
    
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

- (IBAction)openLayoutPreview:(id)sender
{
    self.layoutPreviewController = [[LayoutPreviewWindowController alloc] initWithWindowNibName:@"LayoutPreviewWindowController"];
    [self.layoutPreviewController showWindow:nil];
    self.layoutPreviewController.captureController = self;
    //Preview gets a copy of everything so it doesn't mess up live source
    //self.layoutPreviewController.sourceLayouts = [[NSMutableArray alloc] initWithArray:self.sourceLayouts copyItems:YES];
    //Or maybe not...
    self.layoutPreviewController.sourceLayouts = self.sourceLayouts;
    
}
@end
