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
#import "CSExtraPluginProtocol.h"
#import <OpenCL/opencl.h>
#import <OpenCl/cl_gl_ext.h>
#import <CoreMediaIO/CMIOHardware.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import "MIKMIDI.h"
#import "CSMidiWrapper.h"
#import "CSCaptureBase+TimerDelegate.h"
#import "CSLayoutEditWindowController.h"
#import "CSTimedOutputBuffer.h"
#import "CSAdvancedAudioWindowController.h"


#import <Python/Python.h>





@implementation CaptureController

@synthesize selectedLayout = _selectedLayout;
@synthesize stagingLayout = _stagingLayout;
@synthesize audioSamplerate  = _audioSamplerate;
@synthesize transitionName = _transitionName;
@synthesize useInstantRecord = _useInstantRecord;
@synthesize instantRecordBufferDuration = _instantRecordBufferDuration;







-(void) cloneSelectedSourceLayout:(NSTableView *)fromTable
{
    NSInteger selectedIdx = fromTable.selectedRow;
    
    if (selectedIdx != -1)
    {
        SourceLayout *toClone = [self.sourceLayoutsArrayController.arrangedObjects objectAtIndex:selectedIdx];
        [toClone savedSourceListData];
        [self addLayoutFromBase:toClone];
    }
}


-(void)openBuiltinLayoutPopover:(NSView *)sender spawnRect:(NSRect)spawnRect forLayout:(SourceLayout *)layout
{
    CreateLayoutViewController *vc;
    if (!_layoutpopOver)
    {
        _layoutpopOver = [[NSPopover alloc] init];
        
        _layoutpopOver.animates = YES;
        _layoutpopOver.behavior = NSPopoverBehaviorTransient;
    }
    
    if (!_layoutpopOver.contentViewController)
    {
        vc = [[CreateLayoutViewController alloc] initForBuiltin];
        
        
        _layoutpopOver.contentViewController = vc;
        _layoutpopOver.delegate = vc;
        vc.popover = _layoutpopOver;
        
    }
    
    SourceLayout *useLayout = layout;
    if (!useLayout)
    {
        vc.createDialog = YES;
        useLayout = [[SourceLayout alloc] init];
    }
    vc.sourceLayout = useLayout;
    
    
    [_layoutpopOver showRelativeToRect:spawnRect ofView:sender preferredEdge:NSMinYEdge];
}


-(void)openAddOutputPopover:(id)sender sourceRect:(NSRect)sourceRect
{
    CSAddOutputPopupViewController *vc;
    if (!_addOutputpopOver)
    {
        _addOutputpopOver = [[NSPopover alloc] init];
        _addOutputpopOver.animates = YES;
        _addOutputpopOver.behavior = NSPopoverBehaviorTransient;
    }
    
    //if (!_addInputpopOver.contentViewController)
    {
        vc = [[CSAddOutputPopupViewController alloc] init];
        vc.addOutput = ^void(Class outputClass) {
            [self outputPopupButtonAction:outputClass];
        };
        
        _addOutputpopOver.contentViewController = vc;
        vc.popover = _addOutputpopOver;
        //_addInputpopOver.delegate = vc;
    }
    
    [_addOutputpopOver showRelativeToRect:sourceRect ofView:sender preferredEdge:NSMaxXEdge];
}


-(void)openAddInputPopover:(id)sender sourceRect:(NSRect)sourceRect
{
    CSAddInputViewController *vc;
    if (!_addInputpopOver)
    {
        _addInputpopOver = [[NSPopover alloc] init];
        _addInputpopOver.animates = YES;
        _addInputpopOver.behavior = NSPopoverBehaviorTransient;
    }
    
    //if (!_addInputpopOver.contentViewController)
    {
        vc = [[CSAddInputViewController alloc] init];
        _addInputpopOver.contentViewController = vc;
        vc.popover = _addInputpopOver;
        vc.previewView = self.activePreviewView;
        //_addInputpopOver.delegate = vc;
    }
    
    [_addInputpopOver showRelativeToRect:sourceRect ofView:sender preferredEdge:NSMaxXEdge];
}


-(void)openLayoutPopover:(NSButton *)sender forLayout:(SourceLayout *)layout
{
    CreateLayoutViewController *vc;
    if (!_layoutpopOver)
    {
        _layoutpopOver = [[NSPopover alloc] init];
        
        _layoutpopOver.animates = YES;
        _layoutpopOver.behavior = NSPopoverBehaviorTransient;
    }
    
    if (!_layoutpopOver.contentViewController)
    {
        vc = [[CreateLayoutViewController alloc] init];
        
        
        _layoutpopOver.contentViewController = vc;
        _layoutpopOver.delegate = vc;
        vc.popover = _layoutpopOver;
        
    }
    
    SourceLayout *useLayout = layout;
    if (!useLayout)
    {
        vc.createDialog = YES;
        useLayout = [[SourceLayout alloc] init];
    }
    vc.sourceLayout = useLayout;
    [_layoutpopOver showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMinYEdge];
}


-(void)layoutWindowWillClose:(CSLayoutEditWindowController *)windowController
{
    
    if ([_layoutWindows containsObject:windowController])
    {
        [_layoutWindows removeObject:windowController];
    }
}


- (IBAction)openLibraryWindow:(id) sender
{
    CSInputLibraryWindowController *newController = [[CSInputLibraryWindowController alloc] init];
    
    [newController showWindow:nil];
    
    newController.controller = self;
    
    self.inputLibraryController = newController;
}

-(void)addInputToLibrary:(InputSource *)source
{
    CSInputLibraryItem *newItem = [[CSInputLibraryItem alloc] initWithInput:source];
    
    NSUInteger cIdx = self.inputLibrary.count;
    
    [self insertObject:newItem inInputLibraryAtIndex:cIdx];
    
}


-(CSLayoutEditWindowController *)openLayoutWindow:(SourceLayout *)layout
{
    CSLayoutEditWindowController *newController = [[CSLayoutEditWindowController alloc] init];

    [newController showWindow:nil];
    
    newController.previewView.isEditWindow = YES;
    
    LayoutRenderer *wRenderer = [[LayoutRenderer alloc] init];
    
    newController.previewView.layoutRenderer = wRenderer;
    
    newController.previewView.controller = self;
    newController.previewView.sourceLayout = layout;
    [newController.previewView.sourceLayout restoreSourceList:nil];
    newController.delegate = self;
    
    
    [_layoutWindows addObject:newController];
    return newController;
}





- (IBAction)openLayoutPopover:(NSButton *)sender
{
    

    [self openLayoutPopover:sender forLayout:nil];
    
}


- (bool)deleteLayout:(SourceLayout *)toDelete
{
    
    if (toDelete)
    {
        if ([self actionConfirmation:[NSString stringWithFormat:@"Really delete %@?", toDelete.name] infoString:nil])
        {
            
            
            toDelete.isActive = NO;
            [self.sourceLayoutsArrayController removeObject:toDelete];
            return YES;
        }
    }
    return NO;
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


-(SourceLayout *)addLayoutFromBase:(SourceLayout *)baseLayout
{
    
    
    SourceLayout *newLayout = baseLayout.copy;

    NSMutableString *baseName = newLayout.name.mutableCopy;
    
    NSMutableString *newName = baseName;
    int name_try = 1;
    
    while ([self findLayoutWithName:newName]) {
        newName = [NSMutableString stringWithFormat:@"%@#%d", baseName, name_try];
        name_try++;
    }
    
    
    newLayout.name = newName;
    
    if (newLayout.canvas_width == 0)
    {
        newLayout.canvas_width = self.captureWidth;
    }
    
    if (newLayout.canvas_height == 0)
    {
        newLayout.canvas_height = self.captureHeight;
    }
    
    
    [self insertObject:newLayout inSourceLayoutsAtIndex:self.sourceLayouts.count];
    
    
    return newLayout;
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
        
        [NSApp beginSheet:self.advancedPrefPanel modalForWindow:[NSApplication sharedApplication].mainWindow modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        
    }
    
}


- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    
    NSView *retView = nil;
    
    SourceLayout *layout;
    
    if (tableView == self.inputTableView)
    {
        return [tableView makeViewWithIdentifier:@"inputTableCellView" owner:tableView];
    }
    
    
    if (tableView.tag == 0)
    {
        layout = self.activePreviewView.sourceLayout;
    } else {
        layout = self.livePreviewView.sourceLayout;
    }
    CSAnimationItem *animation = layout.selectedAnimation;
    
    NSArray *inputs = animation.inputs;
    
    NSDictionary *inputmap = nil;
    
    if (row > -1 && row < inputs.count)
    {
        inputmap = [inputs objectAtIndex:row];
    }
    
    if ([tableColumn.identifier isEqualToString:@"label"])
    {
        
        retView = [tableView makeViewWithIdentifier:@"LabelCellView" owner:self];
    } else if ([tableColumn.identifier isEqualToString:@"value"]) {
        
        if ([inputmap[@"type"] isEqualToString:@"param"])
        {
            retView = [tableView makeViewWithIdentifier:@"InputParamView" owner:self];
        } else if ([inputmap[@"type"] isEqualToString:@"bool"]) {
            retView = [tableView makeViewWithIdentifier:@"InputBoolView" owner:self];
        } else {
            retView = [tableView makeViewWithIdentifier:@"InputSourceView" owner:self];
        }
    }
    
    return retView;
}


- (IBAction)openAnimatePopover:(NSButton *)sender
{
    
    CSAnimationChooserViewController *vc;
    if (!_animatepopOver)
    {
        _animatepopOver = [[NSPopover alloc] init];
        
        _animatepopOver.animates = YES;
        _animatepopOver.behavior = NSPopoverBehaviorTransient;
    }
    
    if (!_animatepopOver.contentViewController)
    {
        vc = [[CSAnimationChooserViewController alloc] init];
        
        
        _animatepopOver.contentViewController = vc;
        _animatepopOver.delegate = vc;
        vc.popover = _animatepopOver;
        
    }
    
    vc.sourceLayout = self.activePreviewView.sourceLayout;
    
    
    [_animatepopOver showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMinYEdge];
    
}


-(IBAction)closeAdvancedPrefPanel:(id)sender
{
    [NSApp endSheet:self.advancedPrefPanel];
    [self.advancedPrefPanel close];
    self.advancedPrefPanel = nil;
}


-(void)outputPopupButtonAction:(Class)outputClass
{
    
    OutputDestination *newDest = [[OutputDestination alloc] initWithType:[outputClass label]];
    id serviceObj = [[outputClass alloc] init];
    newDest.streamServiceObject = serviceObj;
    
    [self openOutputSheet:newDest];
}


-(void)openOutputSheet:(OutputDestination *)toEdit
{
    
    CSNewOutputWindowController *newController = nil;
    
    if (!_outputWindows)
    {
        _outputWindows = [[NSMutableArray alloc] init];
    }
    
    
    
    newController = [[CSNewOutputWindowController alloc] init];
    newController.compressors = self.compressors;
    if (toEdit)
    {
        newController.outputDestination = toEdit;
    }
    
    
    newController.windowDone = ^void(NSModalResponse returnCode, CSNewOutputWindowController *window) {
    
        if (returnCode == NSModalResponseOK)
        {
                        
            OutputDestination *newDest = window.outputDestination;
            if (newDest)
            {
                newDest.settingsController = self;
                
                NSInteger idx = NSNotFound;
                
                if (toEdit)
                {
                    idx = [self.captureDestinations indexOfObject:toEdit];
                }
                if (idx != NSNotFound)
                {
                    [self replaceObjectInCaptureDestinationsAtIndex:idx withObject:newDest];
                } else {
                    [self insertObject:newDest inCaptureDestinationsAtIndex:self.captureDestinations.count];
                }
            }
        }

        [_outputWindows removeObject:window];
        [window close];
    };
    
    [_outputWindows addObject:newController];
    [newController showWindow:nil];
}


-(IBAction)openCreateSheet:(id)sender
{
    [self openOutputSheet:nil];
}

- (IBAction)chooseInstantRecordDirectory:(id)sender
{

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = NO;
    panel.allowsMultipleSelection = NO;
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            self.instantRecordDirectory = panel.URL.path;
        }
        
    }];
    
}


-(void)buildScreensInfo:(NSNotification *)notification
{
    
    
    NSArray *screens = [NSScreen screens];
    
    _screensCache = [NSMutableArray array];
    
    
    CFMutableDictionaryRef iodisp = IOServiceMatching("IODisplayConnect");
    
    io_iterator_t itr;
    kern_return_t err = IOServiceGetMatchingServices(kIOMasterPortDefault, iodisp, &itr);
    if (err)
    {
        return;
    }
    
    io_service_t serv;
    while ((serv = IOIteratorNext(itr)) != 0)
    {
        NSDictionary *info = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(serv, kIODisplayOnlyPreferredName));
        
        NSNumber *vendorIDVal = [info objectForKey:@(kDisplayVendorID)];
        
        NSNumber *productIDVal = [info objectForKey:@(kDisplayProductID)];
        
        
        for (NSScreen *screen in screens)
        {
            CGDirectDisplayID dispID = [[[screen deviceDescription] valueForKey:@"NSScreenNumber"] unsignedIntValue];
            uint32_t vid = CGDisplayVendorNumber(dispID);
            uint32_t pid = CGDisplayModelNumber(dispID);
            
            if (vid == vendorIDVal.integerValue && pid == productIDVal.integerValue)
            {
                NSDictionary *names = [info objectForKey:@(kDisplayProductName)];
                if (names)
                {
                    NSString *dispName = [names objectForKey:[[names allKeys] firstObject]];
                    [_screensCache addObject:@{@"name": dispName, @"screen": screen}];
                }
                
            }
            
            
        }
        
        
    }
    
    
}



-(IBAction)doImportLayout:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSButton *clobberAnimButton = [[NSButton alloc] init];
    [clobberAnimButton setButtonType:NSSwitchButton];
    clobberAnimButton.title = @"Overwrite animation scripts";
    clobberAnimButton.state = NSOnState;
    [clobberAnimButton sizeToFit];
    
    panel.accessoryView = clobberAnimButton;
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            
            bool doClobber = clobberAnimButton.state == NSOnState;
            
            NSURL *fileURL = [panel.URLs objectAtIndex:0];
            if (fileURL)
            {
                SourceLayout *newLayout = [NSKeyedUnarchiver unarchiveObjectWithFile:fileURL.path];
                if (!newLayout)
                {
                    return;
                }
                int name_try = 1;
                
                NSString *newName = newLayout.name;
                NSString *baseName = newLayout.name;
                while ([self findLayoutWithName:newName]) {
                    newName = [NSMutableString stringWithFormat:@"%@#%d", baseName, name_try];
                    name_try++;
                }
                
                newLayout.name = newName;
                
                NSString *userAppSupp = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
                
                NSString *csAnimationDir = [[[userAppSupp stringByAppendingPathComponent:@"CocoaSplit"] stringByAppendingPathComponent:@"Plugins"] stringByAppendingPathComponent:@"Animations"];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:csAnimationDir])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:csAnimationDir withIntermediateDirectories:YES attributes:nil error:nil];
                }
                
                
                if (newLayout.animationSaveData)
                {
                    for (NSString *moduleFile in newLayout.animationSaveData)
                    {
                        NSString *moduleSource = newLayout.animationSaveData[moduleFile];
                        NSString *modulePath = [csAnimationDir stringByAppendingPathComponent:moduleFile];
                        
                        
                        bool fileExists = [[NSFileManager defaultManager] fileExistsAtPath:modulePath];
                        if (fileExists && !doClobber)
                        {
                            continue;
                        }
                        
                        NSError *writeError;
                        
                        [moduleSource writeToFile:modulePath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
                        
                    }
                }
                
                newLayout.animationSaveData = nil;
                
                [self insertObject:newLayout inSourceLayoutsAtIndex:self.sourceLayouts.count];


            }
        }
    }];
}
-(void)doExportLayout:(NSMenuItem *)item
{
    [self exportLayout:item.representedObject];
}


-(void)goFullscreen:(NSMenuItem *)item
{
    
    if (item.menu == self.stagingFullScreenMenu)
    {
        
        [self.stagingPreviewView goFullscreen:item.representedObject];
    } else {
        [self.livePreviewView goFullscreen:item.representedObject];
    }
}


-(NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
    
    if (menu == self.stagingFullScreenMenu || menu == self.liveFullScreenMenu)
    {
        return _screensCache.count;
    } else if (menu == self.exportLayoutMenu) {
        return self.sourceLayouts.count;
    }
    
    return 0;
}


-(BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
    
    
    
    if (menu == self.stagingFullScreenMenu || menu == self.liveFullScreenMenu)
    {
        NSDictionary *sInfo = [_screensCache objectAtIndex:index];
        if (sInfo)
        {
            item.title = sInfo[@"name"];
            item.representedObject = sInfo[@"screen"];
            item.action = @selector(goFullscreen:);
            item.target = self;
        } else {
            item.title = @"Unknown";
        }
        return YES;
    } else if (menu == self.exportLayoutMenu) {
        SourceLayout *layout = [self.sourceLayouts objectAtIndex:index];
        item.title = layout.name;
        item.representedObject = layout;
        item.action = @selector(doExportLayout:);
        item.target = self;
        return YES;
    }
    
    return NO;
}



-(void)exportLayout:(SourceLayout *)layout
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    NSString *defaultSave = [layout.name stringByAppendingPathExtension:@"plist"];
    
    panel.nameFieldStringValue = defaultSave;
    panel.canCreateDirectories = YES;
    SourceLayout *useLayout = layout;
    
    if (layout == self.selectedLayout)
    {
        useLayout = self.livePreviewView.sourceLayout;
        [useLayout saveSourceList];
        [useLayout saveAnimationSource];
    } else if (layout == self.stagingLayout) {
        useLayout = self.stagingPreviewView.sourceLayout;
        [useLayout saveSourceList];
        [useLayout saveAnimationSource];

    }

    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSURL *saveFile = [panel URL];
            
            
            [NSKeyedArchiver archiveRootObject:useLayout toFile:saveFile.path];
            
            useLayout.animationSaveData = nil;
        }
    }];
}


-(id) init
{
   if (self = [super init])
   {
       
       
       _layoutWindows = [NSMutableArray array];
       
       self.transitionDirections = @[kCATransitionFromTop, kCATransitionFromRight, kCATransitionFromBottom, kCATransitionFromLeft];
       self.useInstantRecord = YES;
       self.instantRecordActive = YES;
       self.instantRecordBufferDuration = 60;
       
       
       NSArray *caTransitionNames = @[kCATransitionFade, kCATransitionPush, kCATransitionMoveIn, kCATransitionReveal, @"cube", @"alignedCube", @"flip", @"alignedFlip"];
       NSArray *ciTransitionNames = [CIFilter filterNamesInCategory:kCICategoryTransition];
       
       self.transitionNames = [NSMutableDictionary dictionary];
       
       for (NSString *caName in caTransitionNames)
       {
           [self.transitionNames setObject:caName forKey:caName];
       }
       
       for (NSString *ciName in ciTransitionNames)
       {
           NSString *niceName = [CIFilter localizedNameForFilterName:ciName];
           [self.transitionNames setObject:niceName forKey:ciName];
       }

       self.sharedPluginLoader = [CSPluginLoader sharedPluginLoader];
       

       [self setupMIDI];
       
       
       [[CSPluginLoader sharedPluginLoader] loadAllBundles];
       
#ifndef DEBUG
       [self setupLogging];
#endif
       
       

       
       videoBuffer = [[NSMutableArray alloc] init];
       _audioBuffer = [[NSMutableArray alloc] init];
       
       
       
       
       _max_render_time = 0.0f;
       _min_render_time = 0.0f;
       _avg_render_time = 0.0f;
       _render_time_total = 0.0f;
       
       self.useStatusColors = YES;
       
       
       
       
       dispatch_source_t sigsrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGPIPE, 0, dispatch_get_global_queue(0, 0));
       dispatch_source_set_event_handler(sigsrc, ^{ return;});
       dispatch_resume(sigsrc);
       
       /*
       dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
       _main_capture_queue = dispatch_queue_create("CocoaSplit.main.queue", attr);
       _preview_queue = dispatch_queue_create("CocoaSplit.preview.queue", NULL);
        */
       
       _main_capture_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
       _preview_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
       
       
       
       
       
       mach_timebase_info(&_mach_timebase);
       

       
       int dispatch_strict_flag = 1;
       
       if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8)
       {
           dispatch_strict_flag = 0;
       }
       
       _audio_statistics_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
       
       dispatch_source_set_timer(_audio_statistics_timer, DISPATCH_TIME_NOW, 0.10*NSEC_PER_SEC, 0);

       dispatch_source_set_event_handler(_audio_statistics_timer, ^{
           if (self.multiAudioEngine)
           {
               [self.multiAudioEngine updateStatistics];
           }
       });
       dispatch_resume(_audio_statistics_timer);

       

       _statistics_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
       
       dispatch_source_set_timer(_statistics_timer, DISPATCH_TIME_NOW, 1*NSEC_PER_SEC, 0);
       dispatch_source_set_event_handler(_statistics_timer, ^{
           
           int total_outputs = 0;
           int errored_outputs = 0;
           for (OutputDestination *outdest in _captureDestinations)
           {
               if (outdest.active)
               {
                   total_outputs++;
                   if (outdest.errored)
                   {
                       errored_outputs++;
                   }
               }
               [outdest updateStatistics];
           }
           
           
           
           self.outputStatsString = [NSString stringWithFormat:@"Active Outputs: %d Errored %d", total_outputs, errored_outputs];
           self.renderStatsString = [NSString stringWithFormat:@"Render min/max/avg: %f/%f/%f", _min_render_time, _max_render_time, _render_time_total / _renderedFrames];
           _renderedFrames = 0;
           _render_time_total = 0.0f;
           

       });
       
       dispatch_resume(_statistics_timer);
       
       
       self.extraSaveData = [[NSMutableDictionary alloc] init];
       
       //load all filters, then load our custom filter(s)
       
       
       [CIPlugIn loadAllPlugIns];
       

       
       [[CSPluginLoader sharedPluginLoader] loadPrivateAndUserImageUnits];
       

       self.extraPlugins = [NSMutableDictionary dictionary];
       
       [self buildScreensInfo:nil];
       
       self.currentMidiInputLiveIdx = 0;
       self.currentMidiInputStagingIdx = 0;
       self.currentMidiLayoutLive = NO;
       
       _inputIdentifiers =          @[@"Opacity", @"Rotate",
                                     @"RotateX", @"RotateY", @"Active", @"AutoFit",
                                     @"HScroll", @"VScroll", @"CropLeft", @"CropRight", @"CropTop", @"CropBottom",
                                     @"CKEnable", @"CKThresh", @"CKSmooth", @"BorderWidth", @"CornerRadius",
                                     @"GradientStartX", @"GradientStartY", @"GradientStopX", @"GradientStopY",
                                     @"ChangeInterval", @"EffectDuration", @"MultiTransition",
                                     @"PositionX", @"PositionY"];

       
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buildScreensInfo:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
       
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutCanvasChanged:) name:CSNotificationLayoutCanvasChanged object:nil];
       
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutFramerateChanged:) name:CSNotificationLayoutFramerateChanged object:nil];
       
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(compressorReconfigured:) name:CSNotificationCompressorReconfigured object:nil];

       
       
       
   }
    
    return self;
    
}


-(void)compressorReconfigured:(NSNotification *)notification
{
    
    
    id<VideoCompressor> compressor = [notification object];
    if (self.instantRecorder && [compressor isEqual:self.instantRecorder.compressor])
    {
        [self resetInstantRecorder];
    }
}


-(void)layoutFramerateChanged:(NSNotification *)notification
{
    SourceLayout *layout = [notification object];
    if (layout == self.livePreviewView.sourceLayout || layout == self.stagingPreviewView.sourceLayout)
    {
        [self updateFrameIntervals];
    }
    
    if (layout == self.livePreviewView.sourceLayout)
    {
        [self resetInstantRecorder];
    }
}


-(void)layoutCanvasChanged:(NSNotification *)notification
{
    SourceLayout *layout = [notification object];
    
    if ([layout isEqual:self.livePreviewView.sourceLayout])
    {
        
        [self resetInstantRecorder];
    }
}


-(NSData *)archiveLayout:(SourceLayout *)layout
{
    
    [layout saveSourceList];
    
    NSMutableData *saveData = [NSMutableData data];
    
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:saveData];
    archiver.outputFormat = NSPropertyListXMLFormat_v1_0;
    [archiver encodeObject:layout forKey:@"root"];
    [archiver finishEncoding];
    return saveData;
}


+(void)initializePython
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        
        Py_SetProgramName("/usr/bin/python");
        Py_Initialize();
        PyEval_InitThreads();
        
        NSString *resourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Python"];
        
        NSString *sysstr = [NSString stringWithFormat:@"from Foundation import *; import sys; sys.path.append('%@');sys.dont_write_bytecode = True", resourcePath];
        PyGILState_STATE gilState = PyGILState_Ensure();
        PyRun_SimpleString([sysstr UTF8String]);
        PyGILState_Release(gilState);
        
        if (gilState == PyGILState_LOCKED)
        {
            PyThreadState_Swap(NULL);

            PyEval_ReleaseLock();
        }

    });

}

+(void)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile withBlock:(void(^)(Class))withBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Class retClass = [self loadPythonClass:pyClass fromFile:fromFile];
        if (withBlock)
        {
            withBlock(retClass);
        }
    });
}


+(Class)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile
{
    
    
    [CaptureController initializePython];
    FILE *runnerFile = fopen([fromFile UTF8String], "r");
    
    PyGILState_STATE gilState = PyGILState_Ensure();
    
    PyObject *main_tl = PyImport_AddModule("__main__");
    PyObject *main_dict = PyModule_GetDict(main_tl);
    PyObject *dict_copy = PyDict_Copy(main_dict);
    
    
    PyObject *ret = PyRun_File(runnerFile, (char *)[[fromFile lastPathComponent] UTF8String], Py_file_input, dict_copy, dict_copy);
    if (!ret)
    {
        NSLog(@"PYTHON RETURNED NULL!");
        PyErr_Print();
        return nil;
    }
    
    
    Class retClass = NSClassFromString(pyClass);
    PyGILState_Release(gilState);
    
    if (gilState == PyGILState_LOCKED)
    {
        PyThreadState_Swap(NULL);
        
        PyEval_ReleaseLock();
    }
    
    return retClass;
}


+(CSAnimationRunnerObj *) sharedAnimationObj
{
    static CSAnimationRunnerObj *sharedAnimationObj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        
        
        NSString *runnerPath = [[NSBundle mainBundle] pathForResource:@"CSAnimationRunner" ofType:@"py" inDirectory:@"Python"];
        Class animationClass = [CaptureController loadPythonClass:@"CSAnimationRunnerObj" fromFile:runnerPath];
        
        sharedAnimationObj = [[animationClass alloc] init];


    });

    return sharedAnimationObj;
}


-(void) buildExtrasMenu
{
    
    CSPluginLoader *sharedLoader = [CSPluginLoader sharedPluginLoader];
    [self.extrasMenu removeAllItems];
    
    for(NSString *pKey in sharedLoader.extraPlugins)
    {
        Class extraClass = (Class)sharedLoader.extraPlugins[pKey];
        NSObject<CSExtraPluginProtocol>*pInstance;
        if (self.extraPluginsSaveData[pKey])
        {
            pInstance = [NSKeyedUnarchiver unarchiveObjectWithData:self.extraPluginsSaveData[pKey]];
        } else {
            pInstance = [[extraClass alloc] init];
        }
        
        
        if ([pInstance respondsToSelector:@selector(pluginWasLoaded)])
        {
            [pInstance pluginWasLoaded];
        }
        
        
        self.extraPlugins[pKey] = pInstance;
        NSMenuItem *pItem = [[NSMenuItem alloc] init];
        pItem.title = pKey;
        pItem.representedObject = pInstance;
        if ([pInstance respondsToSelector:@selector(extraPluginMenu)])
        {
            NSMenu *subMenu = [pInstance extraPluginMenu];
            [pItem setSubmenu:subMenu];
        } else if ([pInstance respondsToSelector:@selector(extraTopLevelMenuClicked)]) {
            pItem.target = pInstance;
            pItem.action = @selector(extraTopLevelMenuClicked);
        } else {
            [pItem setEnabled:NO];
        }
        [self.extrasMenu addItem:pItem];
    }
    
}



-(void)setAudioSamplerate:(int)audioSamplerate
{
    if (self.multiAudioEngine)
    {
        self.multiAudioEngine.sampleRate = audioSamplerate;
    }
}

-(int)audioSamplerate
{
    return self.multiAudioEngine.sampleRate;
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


-(NSString *) restoreFilePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *saveFolder = @"~/Library/Application Support/CocoaSplit";
    
    saveFolder = [saveFolder stringByExpandingTildeInPath];
    
    if ([fileManager fileExistsAtPath:saveFolder] == NO)
    {
        [fileManager createDirectoryAtPath:saveFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *saveFile = [saveFolder stringByAppendingPathComponent:@"CocoaSplit-2.settings"];
    
    if ([fileManager fileExistsAtPath:saveFile])
    {
        return saveFile;
    }

    
    saveFile = [saveFolder stringByAppendingPathComponent:@"CocoaSplit-CA.settings"];
    
    if ([fileManager fileExistsAtPath:saveFile])
    {
        return saveFile;
    }
    
    saveFile = [saveFolder stringByAppendingPathComponent:@"CocoaSplit-CI.settings"];
    
    return saveFile;
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
    
    NSString *saveFile = @"CocoaSplit-2.settings";
    
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



-(void) resetInstantRecorder
{
    
    
    if (self.instantRecorder && self.instantRecorder.compressor)
    {
        id<VideoCompressor> irCompressor = self.instantRecorder.compressor;
        if ([irCompressor outputCount] > 1 && !_needsIRReset)
        {
            _needsIRReset = YES;
        } else {
            [irCompressor reset];
        }

    }
}


-(void) setupInstantRecorder
{
    id<VideoCompressor> irCompressor = self.compressors[@"InstantRecorder"];
    
    if (irCompressor)
    {
        self.instantRecorder = [[CSTimedOutputBuffer alloc] initWithCompressor:irCompressor];
        self.instantRecorder.bufferDuration = self.instantRecordBufferDuration;
    }
}


-(void) migrateDefaultCompressor:(NSMutableDictionary *)saveRoot
{
    

    id <VideoCompressor> defaultCompressor = self.compressors[@"default"];
    if (defaultCompressor)
    {
        [self.compressors removeObjectForKey:@"default"];
        defaultCompressor.name = defaultCompressor.compressorType.mutableCopy;
        [self.compressors setObject:defaultCompressor forKey:@"x264"];
        NSDictionary *notifyMsg = [NSDictionary dictionaryWithObjectsAndKeys:@"default", @"oldName", defaultCompressor, @"compressor", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorRenamed object:notifyMsg];
    }
    
    
    
    
    if (!self.compressors[@"x264"])
    {
        x264Compressor *newCompressor;
        
        newCompressor = [[x264Compressor alloc] init];
        newCompressor.name = @"x264".mutableCopy;
        newCompressor.vbv_buffer = 1000;
        newCompressor.vbv_maxrate = 1000;
        newCompressor.keyframe_interval = 2;
        
        self.compressors[@"x264"] = newCompressor;
        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorAdded object:newCompressor];
    }
    
    if (!self.compressors[@"AppleVT"])
    {
        AppleVTCompressor *newCompressor = [[AppleVTCompressor alloc] init];
        newCompressor.name = @"AppleVT".mutableCopy;
        newCompressor.average_bitrate = 1000;
        newCompressor.max_bitrate = 1000;
        newCompressor.keyframe_interval = 2;
        self.compressors[@"AppleVT"] = newCompressor;
        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorAdded object:newCompressor];
    }
    
    if (!self.compressors[@"AppleProRes"])
    {
        AppleProResCompressor *newCompressor = [[AppleProResCompressor alloc] init];
        newCompressor.name = @"AppleProRes".mutableCopy;
        self.compressors[@"AppleProRes"] = newCompressor;
        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorAdded object:newCompressor];
    }
    
    if (!self.compressors[@"InstantRecorder"])
    {
        CSIRCompressor *newCompressor = [[CSIRCompressor alloc] init];
        newCompressor.name = @"InstantRecorder".mutableCopy;
        self.compressors[@"InstantRecorder"] = newCompressor;
        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorAdded object:newCompressor];
    }
    
}


-(void) saveSettings
{
    
    NSString *path = [self saveFilePath];
    
    NSMutableDictionary *saveRoot;
    
    saveRoot = [NSMutableDictionary dictionary];
    
    [saveRoot setValue:self.transitionName forKey:@"transitionName"];
    [saveRoot setValue:self.transitionDirection forKey:@"transitionDirection"];
    [saveRoot setValue:[NSNumber numberWithFloat:self.transitionDuration] forKey:@"transitionDuration"];
    
    [saveRoot setValue: [NSNumber numberWithInt:self.captureWidth] forKey:@"captureWidth"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureHeight] forKey:@"captureHeight"];
    [saveRoot setValue: [NSNumber numberWithDouble:self.captureFPS] forKey:@"captureFPS"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioBitrate] forKey:@"audioBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioSamplerate] forKey:@"audioSamplerate"];
    [saveRoot setValue: self.selectedVideoType forKey:@"selectedVideoType"];
    [saveRoot setValue: self.captureDestinations forKey:@"captureDestinations"];
    [saveRoot setValue:[NSNumber numberWithInt:self.maxOutputDropped] forKey:@"maxOutputDropped"];
    [saveRoot setValue:[NSNumber numberWithInt:self.maxOutputPending] forKey:@"maxOutputPending"];
    [saveRoot setValue:[NSNumber numberWithDouble:self.audio_adjust] forKey:@"audioAdjust"];
    [saveRoot setValue: [NSNumber numberWithBool:self.useStatusColors] forKey:@"useStatusColors"];
    [saveRoot setValue:self.compressors forKey:@"compressors"];
    [saveRoot setValue:self.extraSaveData forKey:@"extraSaveData"];
    [saveRoot setValue: [NSNumber numberWithBool:self.useInstantRecord] forKey:@"useInstantRecord"];
    
    [saveRoot setValue:[NSNumber numberWithInt:self.instantRecordBufferDuration] forKey:@"instantRecordBufferDuration"];
    [saveRoot setValue:self.instantRecordDirectory forKey:@"instantRecordDirectory"];
    
    

    
    
    
    [saveRoot setValue:self.selectedLayout forKey:@"selectedLayout"];
    
    [saveRoot setValue:self.stagingLayout forKey:@"stagingLayout"];
    
    [saveRoot setValue:self.sourceLayouts forKey:@"sourceLayouts"];
    
    

    self.extraPluginsSaveData = [NSMutableDictionary dictionary];
    
    for(NSString *pkey in self.extraPlugins)
    {
        id ePlugin = self.extraPlugins[pkey];
        if ([ePlugin respondsToSelector:@selector(encodeWithCoder:)])
        {
            self.extraPluginsSaveData[pkey] = [NSKeyedArchiver archivedDataWithRootObject:ePlugin];
        }
        
    }
    
    [saveRoot setValue:self.extraPluginsSaveData forKeyPath:@"extraPluginsSaveData"];
    
    BOOL stagingHidden = [self.canvasSplitView isSubviewCollapsed:self.canvasSplitView.subviews[0]];
    [saveRoot setValue:[NSNumber numberWithBool:stagingHidden] forKey:@"stagingHidden"];
    
    [saveRoot setValue:self.multiAudioEngine forKey:@"multiAudioEngine"];
    
    [saveRoot setValue:self.transitionFilter forKey:@"transitionFilter"];
    [saveRoot setValue:[NSNumber numberWithBool:self.useMidiLiveChannelMapping] forKey:@"useMidiLiveChannelMapping"];
    [saveRoot setValue:[NSNumber numberWithInteger:self.midiLiveChannel] forKey:@"midiLiveChannel"];
    
    [self saveMIDI];

    [saveRoot setValue:self.inputLibrary forKey:@"inputLibrary"];
    [NSKeyedArchiver archiveRootObject:saveRoot toFile:path];
    
}


-(void) loadSettings
{
    
    //all color panels allow opacity
    self.activePreviewView = self.stagingPreviewView;
    [self.layoutCollectionView registerForDraggedTypes:@[@"CS_LAYOUT_DRAG"]];

    [NSColorPanel sharedColorPanel].showsAlpha = YES;
    [NSColor setIgnoresAlpha:NO];
    
    NSString *path = [self restoreFilePath];
    NSDictionary *defaultValues = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]];
    
    NSDictionary *savedValues = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    
    NSMutableDictionary *saveRoot = [[NSMutableDictionary alloc] init];
    

    [saveRoot addEntriesFromDictionary:defaultValues];
    [saveRoot addEntriesFromDictionary:savedValues];
    

    if (saveRoot[@"useInstantRecord"])
    {
        self.useInstantRecord = [[saveRoot valueForKey:@"useInstantRecord"] boolValue];
    }
    
    self.instantRecordActive = YES;
    
    if (saveRoot[@"instantRecordBufferDuration"])
    {
        self.instantRecordBufferDuration = [[saveRoot valueForKey:@"instantRecordBufferDuration"] intValue];
    }
    
    self.instantRecordDirectory = [saveRoot valueForKey:@"instantRecordDirectory"];
    
    
    
    self.transitionName = [saveRoot valueForKey:@"transitionName"];
    self.transitionDirection = [saveRoot valueForKey:@"transitionDirection"];
    self.transitionDuration = [[saveRoot valueForKey:@"transitionDuration"] floatValue];
    self.transitionFilter = [saveRoot valueForKey:@"transitionFilter"];
    
    
    self.captureWidth = [[saveRoot valueForKey:@"captureWidth"] intValue];
    self.captureHeight = [[saveRoot valueForKey:@"captureHeight"] intValue];
    self.audioBitrate = [[saveRoot valueForKey:@"audioBitrate"] intValue];
    self.audioSamplerate = [[saveRoot valueForKey:@"audioSamplerate"] intValue];
   
    self.compressors = [[saveRoot valueForKey:@"compressors"] mutableCopy];
    
    
    if (!self.compressors)
    {
        self.compressors = [[NSMutableDictionary alloc] init];
        
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

    
    
    
    self.captureFPS = [[saveRoot valueForKey:@"captureFPS"] doubleValue];
    self.maxOutputDropped = [[saveRoot valueForKey:@"maxOutputDropped"] intValue];
    self.maxOutputPending = [[saveRoot valueForKey:@"maxOutputPending"] intValue];

    self.audio_adjust = [[saveRoot valueForKey:@"audioAdjust"] doubleValue];
    

    self.stagingPreviewView.controller = self;
    self.livePreviewView.controller = self;
    LayoutRenderer *stagingRender = [[LayoutRenderer alloc] init];
    stagingRender.isLiveRenderer = NO;
    self.stagingPreviewView.layoutRenderer = stagingRender;
    
    LayoutRenderer *liveRender = [[LayoutRenderer alloc] init];
    liveRender.isLiveRenderer = YES;
    self.livePreviewView.layoutRenderer = liveRender;

    self.livePreviewView.viewOnly = YES;
    
    self.selectedLayout = [[SourceLayout alloc] init];
    self.stagingLayout = [[SourceLayout alloc] init];

    
    self.extraPluginsSaveData = [saveRoot valueForKey:@"extraPluginsSaveData"];
    [self migrateDefaultCompressor:saveRoot];
    [self buildExtrasMenu];
    
    BOOL stagingHidden = [[saveRoot valueForKeyPath:@"stagingHidden"] boolValue];
    
    if (stagingHidden)
    {
        [self hideStagingView];
    }

    self.useMidiLiveChannelMapping   = [[saveRoot valueForKey:@"useMidiLiveChannelMapping"] boolValue];
    self.midiLiveChannel = [[saveRoot valueForKey:@"midiLiveChannel"] integerValue];
    
    
    self.multiAudioEngine = [saveRoot valueForKey:@"multiAudioEngine"];
    if (!self.multiAudioEngine)
    {
        self.multiAudioEngine = [[CAMultiAudioEngine alloc] init];
    }
     


    self.extraPluginsSaveData = nil;
    self.sourceLayouts = [saveRoot valueForKey:@"sourceLayouts"];
    
    
    if (!self.sourceLayouts)
    {
        self.sourceLayouts = [[NSMutableArray alloc] init];
    }
    
    SourceLayout *tmpLayout = [saveRoot valueForKey:@"selectedLayout"];
    if (tmpLayout)
    {
        if (tmpLayout == self.stagingLayout || [self.sourceLayouts containsObject:tmpLayout])
        {
            SourceLayout *tmpCopy = [tmpLayout copy];
            self.selectedLayout = tmpCopy;
        } else {
            self.selectedLayout = tmpLayout;
        }
        //[self.selectedLayout mergeSourceLayout:tmpLayout withLayer:nil];
    }
    
    tmpLayout = [saveRoot valueForKey:@"stagingLayout"];
    if (tmpLayout)
    {
        if (tmpLayout == self.selectedLayout || [self.sourceLayouts containsObject:tmpLayout])
        {
            SourceLayout *tmpCopy = [tmpLayout copy];
            self.stagingLayout = tmpCopy;
        } else {
            self.stagingLayout = tmpLayout;
        }
        
        //[self.stagingLayout mergeSourceLayout:tmpLayout withLayer:nil];
    }
    
    self.inputLibrary = [saveRoot valueForKey:@"inputLibrary"];
    if (!self.inputLibrary)
    {
        self.inputLibrary = [NSMutableArray array];
    }
    
    _firstAudioTime = kCMTimeZero;
    _previousAudioTime = kCMTimeZero;
    
    
    
    
    
    CSAacEncoder *audioEnc = [[CSAacEncoder alloc] init];
    audioEnc.encodedReceiver = self;
    audioEnc.sampleRate = self.audioSamplerate;
    audioEnc.bitRate = self.audioBitrate*1000;
    
    audioEnc.inputASBD = self.multiAudioEngine.graph.graphAsbd;
    [audioEnc setupEncoderBuffer];
    self.multiAudioEngine.encoder = audioEnc;
    
    if (self.useInstantRecord)
    {
        [self setupInstantRecorder];
    }

    dispatch_async(_main_capture_queue, ^{[self newFrameTimed];});
    
    dispatch_async(_preview_queue, ^{
        [self newStagingFrameTimed];
    });

    
}

-(void)setInstantRecordBufferDuration:(int)instantRecordBufferDuration
{
    _instantRecordBufferDuration = instantRecordBufferDuration;
    
    if (_instantRecordBufferDuration <= 0)
    {
        self.instantRecorder = nil;
    } else {
        if (self.instantRecorder)
        {
            self.instantRecorder.bufferDuration = _instantRecordBufferDuration;
        }
    }
}

-(int)instantRecordBufferDuration
{
    return _instantRecordBufferDuration;
}


-(void) setUseInstantRecord:(bool)useInstantRecord
{
    _useInstantRecord = useInstantRecord;
    
    if (useInstantRecord)
    {
        [self setupInstantRecorder];
        self.instantRecordActive = YES;
    } else {
        self.instantRecorder = nil;
        self.instantRecordActive = NO;
    }
}

-(bool)useInstantRecord
{
    return _useInstantRecord;
}


-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    
}

-(void)setExtraData:(id)saveData forKey:(NSString *)forKey
{
    
    [self.extraSaveData setValue:saveData forKey:forKey];
}

-(id)getExtraData:(NSString *)forkey
{
    return [self.extraSaveData valueForKey:forkey];
}


-(void)setStagingLayout:(SourceLayout *)stagingLayout
{
    
    
    [stagingLayout restoreSourceList:nil];
    [stagingLayout setupMIDI];
    
    self.stagingPreviewView.sourceLayout = stagingLayout;
    self.stagingPreviewView.midiActive = YES;
    
    [stagingLayout setAddLayoutBlock:^(SourceLayout *layout) {
        
        layout.in_staging = YES;
        
    }];
    
    [stagingLayout setRemoveLayoutBlock:^(SourceLayout *layout) {
        
        layout.in_staging = NO;
        
    }];

    
    [stagingLayout applyAddBlock];
    
    float framerate = stagingLayout.frameRate;
    
    if (framerate && framerate > 0)
    {
        _staging_frame_interval = (1.0/framerate);
    } else {
        _staging_frame_interval = 1.0/60.0;
    }
    
    self.currentMidiInputStagingIdx = 0;
    
    _stagingLayout = stagingLayout;
    stagingLayout.doSaveSourceList = YES;
    
    
    

}


-(SourceLayout *)stagingLayout
{
    return _stagingLayout;
}


-(void)setSelectedLayout:(SourceLayout *)selectedLayout
{
    

    [selectedLayout setAddLayoutBlock:^(SourceLayout *layout) {
        
        layout.in_live = YES;
        
    }];
    
    [selectedLayout setRemoveLayoutBlock:^(SourceLayout *layout) {
        
        layout.in_live = NO;
        
    }];

    
    [selectedLayout applyAddBlock];

    [self.objectController commitEditing];
    
    
    selectedLayout.isActive = YES;
    [selectedLayout restoreSourceList:nil];
    
    [selectedLayout setupMIDI];
    
    [self setupFrameTimer:selectedLayout.frameRate];
    self.livePreviewView.sourceLayout = selectedLayout;
    self.livePreviewView.midiActive = NO;
    
    
    
    self.currentMidiInputLiveIdx = 0;
    _selectedLayout = selectedLayout;
    selectedLayout.doSaveSourceList = YES;
    
    
}

-(SourceLayout *)selectedLayout
{
    return _selectedLayout;
}


-(void) setTransitionName:(NSString *)transitionName
{
    
    NSLog(@"SETTING TRANSITION %@", transitionName);
    
    _transitionName = transitionName;
    if ([transitionName hasPrefix:@"CI"])
    {
        CIFilter *newFilter = [CIFilter filterWithName:transitionName];
        [newFilter setDefaults];
        self.transitionFilter = newFilter;
    } else {
        self.transitionFilter = nil;
    }
}




-(NSString *)transitionName
{
    return _transitionName;
}

-(NSArray *)layoutSortDescriptors
{
    return @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] ];
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
    
    
    
    for (OutputDestination *outdest in _captureDestinations)
    {
        //make the outputs pick up the default selected compressor
        [outdest setupCompressor];
    }
    return YES;

    
}


-(bool) startStream
{
    
    
    //_frameCount = 0;
    //_firstAudioTime = kCMTimeZero;
    //_firstFrameTime = [self mach_time_seconds];
    
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

    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationStreamStarted object:self userInfo:nil];
    
    return YES;
    
}




-(void) setupFrameTimer:(double)framerate
{
    if (self.captureRunning)
    {
        //Don't change FPS mid-stream
        return;
    }
    
    
    if (framerate && framerate > 0)
    {
        _frame_interval = (1.0/framerate);
    } else {
        _frame_interval = 1.0/60.0;
    }
    
    self.captureFPS = framerate;
    
}




- (void)stopStream
{
    
    self.captureRunning = NO;

    
    for (id cKey in self.compressors)
    {
        id <VideoCompressor> ctmp = self.compressors[cKey];
        if (ctmp && self.instantRecorder && [self.instantRecorder.compressor isEqual:ctmp])
        {
            continue;
        }
        
        if (ctmp)
        {
            [ctmp reset];
        }
    }

    for (OutputDestination *out in _captureDestinations)
    {
        [out stopOutput];
    }
    
    
    [self setupFrameTimer:self.selectedLayout.frameRate];

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
    
    if (_needsIRReset)
    {
        [self resetInstantRecorder];
        _needsIRReset = NO;
    }
    
    
    //self.multiAudioEngine.encoder = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationStreamStopped object:self userInfo:nil];

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
        
        
        
        if ([self startStream] != YES)
        {
            [sender setNextState];

        }

    } else {
        
        [self stopStream];
    }
    
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
    
        //NSLog(@"FIRST AUDIO AT %f", CFAbsoluteTimeGetCurrent());
        
        _firstAudioTime = orig_pts;
        return;
    }
    
    
    CMTime real_pts = CMTimeSubtract(orig_pts, _firstAudioTime);
    CMTime adjust_pts = CMTimeMakeWithSeconds(self.audio_adjust, orig_pts.timescale);
    CMTime pts = CMTimeAdd(real_pts, adjust_pts);

    
    
    CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, pts);
    
    if (CMTIME_COMPARE_INLINE(pts, >, _previousAudioTime))
    {
        [self addAudioData:sampleBuffer];
        _previousAudioTime = pts;
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
    while ([self mach_time_seconds] < target_time)
    {
        int32_t useconds = (target_time - [self mach_time_seconds]) * 0.25e6;
        if (useconds > 0)
        {
            usleep(useconds);
        }
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


-(void)frameArrived:(id)ctx
{
    if (ctx == self.previewCtx)
    {
        dispatch_async(_main_capture_queue, ^{
            [self newFrameEvent];
        });
    } else if (ctx == self.stagingCtx) {
        dispatch_async(_preview_queue, ^{
            [self newStagingFrame];
        });
    }
    
}

-(void)frameTimerWillStop:(id)ctx
{
    if (ctx == self.previewCtx)
    {
        dispatch_async(_main_capture_queue, ^{
            [self newFrameTimed];
        });
    } else if (ctx == self.stagingCtx) {
        dispatch_async(_preview_queue, ^{
            [self newStagingFrameTimed];
        });
    }
}


-(void)newStagingFrame
{
    if (self.stagingHidden)
    {
        return;
    }
    
    [self.stagingCtx.layoutRenderer currentImg];

}


-(void)newFrameEvent
{
    _frame_time = [self mach_time_seconds];
    [self newFrame];
}


-(void)newStagingFrameTimed
{
    double startTime;
    startTime = [self mach_time_seconds];
    while (1)
    {
        
        if (self.stagingHidden)
        {
            return;
        }
        
        if (self.stagingCtx.sourceLayout.layoutTimingSource && self.stagingCtx.sourceLayout.layoutTimingSource.videoInput && self.stagingCtx.sourceLayout.layoutTimingSource.videoInput.canProvideTiming)
        {
            CSCaptureBase *newTiming = (CSCaptureBase *)self.stagingCtx.sourceLayout.layoutTimingSource.videoInput;
            newTiming.timerDelegateCtx = self.stagingCtx;
            newTiming.timerDelegate = self;
            return;
        }
        
        @autoreleasepool {
            if (![self sleepUntil:(startTime += _staging_frame_interval)])
            {
                continue;
            }
            [self.stagingCtx.layoutRenderer currentImg];
         }
        

    }
}

-(void)updateFrameIntervals
{
    _staging_frame_interval = 1.0/self.stagingPreviewView.sourceLayout.frameRate;
    [self setupFrameTimer:self.livePreviewView.sourceLayout.frameRate];
}

- (IBAction)configureIRCompressor:(id)sender {
    
    
    CompressionSettingsPanelController *cPanel = [[CompressionSettingsPanelController alloc] init];
    CSIRCompressor *compressor = self.compressors[@"InstantRecorder"];
    
    cPanel.compressor = compressor;
    
    
    [self.advancedPrefPanel beginSheet:cPanel.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSModalResponseStop:
                if (cPanel.compressor.active)
                {
                    return;
                }
                [self willChangeValueForKey:@"compressors"];
                [self.compressors removeObjectForKey:cPanel.compressor.name];
                [self didChangeValueForKey:@"compressors"];
                [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorDeleted object:cPanel.compressor userInfo:nil];
                
                break;
            case NSModalResponseOK:
            {
                
                
                if (!cPanel.compressor.active)
                {
                    if (![compressor.name isEqualToString:cPanel.compressor.name])
                    {
                        [self.compressors removeObjectForKey:compressor.name];
                        NSDictionary *notifyMsg = [NSDictionary dictionaryWithObjectsAndKeys:compressor.name, @"oldName", cPanel.compressor, @"compressor", nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorRenamed object:notifyMsg];
                        
                    }
                    self.compressors[cPanel.compressor.name] = cPanel.compressor;
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorReconfigured object:cPanel.compressor];
                
                break;
            }
            case 4242:
                if (cPanel.saveProfileName)
                {
                    cPanel.compressor.name = cPanel.saveProfileName.mutableCopy;
                    [self willChangeValueForKey:@"compressors"];
                    self.compressors[cPanel.compressor.name] = cPanel.compressor;
                    [self didChangeValueForKey:@"compressors"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorAdded object:cPanel.compressor userInfo:nil];
                    
                }
            default:
                break;
        }

        
    }];
}

-(void) resetInputTableHighlights
{
    [self.activePreviewView stopHighlightingAllSources];
    if (self.inputOutlineView && self.inputOutlineView.selectedRowIndexes)
    {
        [self.inputOutlineView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSTreeNode *node = [self.inputOutlineView itemAtRow:idx];
            InputSource *src = node.representedObject;
            
            if (src)
            {
                [self.activePreviewView highlightSource:src];
            }
        }];
    }
}

- (IBAction)outputSegmentedAction:(NSButton *)sender
{
    NSUInteger clicked = sender.tag;
    
    switch (clicked)
    {
        case 0:
            [self openAddOutputPopover:sender sourceRect:sender.bounds];
            break;
        case 1:
            [self removeDestination:sender];
            break;
        default:
            break;
    }
}


- (IBAction)openStreamOutputWindow:(id)sender
{
    if (!_streamOutputWindowController)
    {
        _streamOutputWindowController = [[CSStreamOutputWindowController alloc] init];
    }
    
    _streamOutputWindowController.controller = self;
    
    [_streamOutputWindowController showWindow:nil];
}



- (IBAction)openAnimationWindow:(id)sender
{
    if (!_animationWindowController)
    {
        _animationWindowController = [[CSAnimationWindowController alloc] init];
    }
    
    [_animationWindowController showWindow:nil];
}


- (IBAction)openAdvancedAudio:(id)sender
{
    if (!_audioWindowController)
    {
        _audioWindowController = [[CSAdvancedAudioWindowController alloc] init];
    }
    
    _audioWindowController.controller = self;
    [_audioWindowController showWindow:nil];
    
}



-(void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    if (outlineView == self.inputOutlineView)
    {

        NSTreeNode *node = [outlineView itemAtRow:row];
        InputSource *src = node.representedObject;
        if (!src.parentInput)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [outlineView expandItem:nil expandChildren:YES];
            });
        }
    }
}


-(void) outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSOutlineView *outline = notification.object;
   
    if (outline == self.inputOutlineView)
    {
        [self resetInputTableHighlights];

    }
             
             
}


- (IBAction)inputTableControlClick:(NSButton *)sender
{
    NSInteger clicked = sender.tag;

    NSArray *selectedInputs;
    NSRect sbounds;
    switch (clicked) {
        case 0:
            sbounds = sender.bounds;
            //[self.activePreviewView addInputSource:sender];
            //sbounds.origin.x = NSMaxX(sender.frame) - [sender widthForSegment:0];
            //sbounds.origin.x -= 333;
            [self openAddInputPopover:sender sourceRect:sbounds];
            break;
        case 1:
            if (self.inputOutlineView && self.inputOutlineView.selectedRowIndexes)
            {
                [self.inputOutlineView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    NSTreeNode *node = [self.inputOutlineView itemAtRow:idx];
                    InputSource *src = node.representedObject;
                    
                    if (src)
                    {
                        NSString *uuid = src.uuid;
                        InputSource *realInput = [self.activePreviewView.sourceLayout inputForUUID:uuid];
                        [self.activePreviewView deleteInput:realInput];
                    }
                    
                }];

                
            }
            break;
        case 2:
            if (self.inputOutlineView && self.inputOutlineView.selectedRowIndexes)
            {
                
                [self.inputOutlineView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    NSTreeNode *node = [self.inputOutlineView itemAtRow:idx];
                    InputSource *src = node.representedObject;
                    
                    if (src)
                    {
                        [self.activePreviewView openInputConfigWindow:src.uuid];
                    }
                    
                }];
            }
            break;
        default:
            break;
    }
}



-(void) newFrameTimed
{
    
    double startTime;
    
    startTime = [self mach_time_seconds];

    _frame_time = startTime;
    _firstFrameTime = startTime;
    [self newFrame];
    
    //[self setFrameThreadPriority];
    while (1)
    {
        
        
        if (self.previewCtx.sourceLayout.layoutTimingSource && self.previewCtx.sourceLayout.layoutTimingSource.videoInput && self.previewCtx.sourceLayout.layoutTimingSource.videoInput.canProvideTiming)
        {
            CSCaptureBase *newTiming = (CSCaptureBase *)self.previewCtx.sourceLayout.layoutTimingSource.videoInput;
            newTiming.timerDelegateCtx = self.previewCtx;
            newTiming.timerDelegate = self;
            return;
        }
        
        @autoreleasepool {
            
        
        
        
        //_frame_time = nowTime;//startTime;
        
        
        if (![self sleepUntil:(startTime += _frame_interval)])
        {
            //NSLog(@"MISSED FRAME!");
            continue;
        }

        
            
        _frame_time = startTime;

        [self newFrame];
        }
        
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


-(InputSource *)findSource:(NSPoint)forPoint
{
    
    return [self.selectedLayout findSource:forPoint deepParent:YES];
}


-(CVPixelBufferRef) currentFrame
{
    return [self.previewCtx.layoutRenderer currentFrame];
}


-(void) newFrame
{
    
    CVPixelBufferRef newFrame;
    
    
    double nfstart = [self mach_time_seconds];
    
    newFrame = [self.previewCtx.layoutRenderer currentImg];
    
    
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
        _frameCount++;
        CVPixelBufferRetain(newFrame);
        NSMutableArray *frameAudio = [[NSMutableArray alloc] init];
        [self setAudioData:frameAudio videoPTS:CMTimeMake((_frame_time - _firstFrameTime)*1000, 1000)];
        CapturedFrameData *newData = [self createFrameData];
        newData.audioSamples = frameAudio;
        newData.videoFrame = newFrame;
        
        [self sendFrameToReplay:newData];
        if (self.captureRunning)
        {
            if (self.captureRunning != _last_running_value)
            {
                [self setupCompressors];
            }
            
            
            [self processVideoFrame:newData];
            
            
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


-(CapturedFrameData *)createFrameData
{
    
    CMTime pts = CMTimeMake((_frame_time - _firstFrameTime)*1000, 1000);
    CMTime duration = CMTimeMake(1, self.captureFPS);

    CapturedFrameData *newFrameData = [[CapturedFrameData alloc] init];
    newFrameData.videoPTS = pts;
    newFrameData.videoDuration = duration;
    newFrameData.frameNumber = _frameCount;
    newFrameData.frameTime = _frame_time;
    return newFrameData;
}


-(void)sendFrameToReplay:(CapturedFrameData *)frameData
{
    CMTime pts;
    CMTime duration;
    
    pts = CMTimeMake((_frame_time - _firstFrameTime)*1000, 1000);
    
    duration = CMTimeMake(1, self.captureFPS);
    
    
    
    if (self.instantRecorder && self.instantRecorder.compressor && !self.instantRecorder.compressor.errored)
    {
        CapturedFrameData *newFrameData = frameData.copy;
        [self.instantRecorder.compressor compressFrame:newFrameData];
        if (self.instantRecorder.compressor.errored)
        {
            self.instantRecordActive = NO;
        }
    }
}


-(void)processVideoFrame:(CapturedFrameData *)frameData
{

    
    
    if (!self.captureRunning)
    {

        return;
    }
    
    for(id cKey in self.compressors)
    {
        
        id <VideoCompressor> compressor;
        compressor = self.compressors[cKey];

        if (self.instantRecorder && [self.instantRecorder.compressor isEqual:compressor])
        {
            continue;
        }
        
        CapturedFrameData *newFrameData = frameData.copy;
        
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
    @"audioBitrate", @"audioSamplerate"] indexOfObject:key];
    
    if (key_idx != NSNotFound)
    {
        return [self setValue:[NSNumber numberWithInt:0] forKey:key];
    }
    
    [super setNilValueForKey:key];
}


- (IBAction)removeDestination:(id)sender
{
    [self.selectedCaptureDestinations enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger idx, BOOL *stop) {
                [self removeObjectFromCaptureDestinationsAtIndex:idx];
    }];
    
}


-(void) removeObjectFromCaptureDestinationsAtIndex:(NSUInteger)index
{
    OutputDestination *to_delete = [self.captureDestinations objectAtIndex:index];
    to_delete.active = NO;
    [self.captureDestinations removeObjectAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationOutputDeleted object:to_delete userInfo:nil];
}

-(void)replaceObjectInCaptureDestinationsAtIndex:(NSUInteger)index withObject:(id)object
{
    [self.captureDestinations replaceObjectAtIndex:index withObject:object];
}


-(void)insertObject:(OutputDestination *)object inCaptureDestinationsAtIndex:(NSUInteger)index
{
    [self.captureDestinations insertObject:object atIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationOutputAdded object:object userInfo:nil];
}


-(void) insertObject:(SourceLayout *)object inSourceLayoutsAtIndex:(NSUInteger)index
{
    [self.sourceLayouts insertObject:object atIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationOutputAdded object:object userInfo:nil];
}


-(void) removeObjectFromSourceLayoutsAtIndex:(NSUInteger)index
{
    id to_delete = [self.sourceLayouts objectAtIndex:index];
    
    [self.sourceLayouts removeObjectAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationLayoutDeleted object:to_delete userInfo:nil];
}


-(void) insertObject:(CSInputLibraryItem *)item inInputLibraryAtIndex:(NSUInteger)index
{
    [self.inputLibrary insertObject:item atIndex:index];
}

-(void)removeObjectFromInputLibraryAtIndex:(NSUInteger)index
{
    [self.inputLibrary removeObjectAtIndex:index];
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



-(NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    
    NSPasteboard *pBoard = [draggingInfo draggingPasteboard];
    NSData *indexSave = [pBoard dataForType:@"CS_LAYOUT_DRAG"];
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexSave];
    NSInteger draggedItemIdx = [indexes firstIndex];
    
    NSInteger useIdx = *proposedDropIndex;
    
    if (*proposedDropIndex > draggedItemIdx)
    {
        useIdx--;
    }
    
    
    if (useIdx < 0)
    {
        useIdx = 0;
    }


    
    if (*proposedDropIndex == -1 || labs(draggedItemIdx - useIdx) < 1)
    {
        return NSDragOperationNone;
    }
    
    return NSDragOperationMove;
}


-(BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    NSData *indexSave = [NSKeyedArchiver archivedDataWithRootObject:indexes];
    [pasteboard declareTypes:@[@"CS_LAYOUT_DRAG"] owner:nil];
    [pasteboard setData:indexSave forType:@"CS_LAYOUT_DRAG"];
    return YES;
}


-(BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    NSPasteboard *pBoard = [draggingInfo draggingPasteboard];
    NSData *indexSave = [pBoard dataForType:@"CS_LAYOUT_DRAG"];
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexSave];
    NSInteger draggedItemIdx = [indexes firstIndex];

    
    [self willChangeValueForKey:@"sourceLayouts"];
    SourceLayout *draggedItem = [self.sourceLayouts objectAtIndex:draggedItemIdx];
    NSInteger useIdx = index;
    
    if (index > draggedItemIdx)
    {
        useIdx--;
    }
    
    
    if (useIdx < 0)
    {
        useIdx = 0;
    }
    
    [self.sourceLayouts removeObjectAtIndex:draggedItemIdx];
    [self.sourceLayouts insertObject:draggedItem atIndex:useIdx];
    [self didChangeValueForKey:@"sourceLayouts"];
    
    return YES;
}


-(BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event
{
    return YES;
}


-(SourceLayout *)getLayoutForName:(NSString *)name
{
    NSUInteger selectedIdx = [self.sourceLayouts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [((SourceLayout *)obj).name isEqualToString:name];
        
    }];
    
    
    SourceLayout *selectedLayout = nil;
    
    if (selectedIdx != NSNotFound)
    {
        selectedLayout = [self.sourceLayouts objectAtIndex:selectedIdx];
    }
    
    return selectedLayout;

}

-(void)switchToLayout:(SourceLayout *)layout
{
    SourceLayout *activeLayout = self.activePreviewView.sourceLayout;
    [activeLayout replaceWithSourceLayout:layout];
}


-(void)toggleLayout:(SourceLayout *)layout
{
    SourceLayout *activeLayout = self.activePreviewView.sourceLayout;
    [self applyTransitionSettings:activeLayout];

    if ([activeLayout containsLayout:layout])
    {
        [activeLayout removeSourceLayout:layout withLayer:nil];
    } else {
        [activeLayout mergeSourceLayout:layout withLayer:nil];
    }
}


-(void)saveToLayout:(SourceLayout *)layout
{
    [self.activePreviewView.sourceLayout saveSourceList];
    layout.savedSourceListData = self.activePreviewView.sourceLayout.savedSourceListData;
}




-(void)clearLearnedMidiForCommand:(NSString *)command withResponder:(id<MIKMIDIMappableResponder>)responder
{
    for(CSMidiWrapper *cwrap in self.midiMapGenerators)
    {
        [cwrap forgetCommand:command forResponder:responder];
    }
}


-(void)learnedMidiCommand:(NSString *)command fromWrapper:(CSMidiWrapper *)wrapper
{
    for (CSMidiWrapper *cwrap in self.midiMapGenerators)
    {
        if (cwrap == wrapper)
        {
            continue;
        }
        
        [cwrap cancelLearning];
    }
    
    [self.midiManagerController learnedDone];
    
}

-(void)learnMidiForCommand:(NSString *)command withRepsonder:(id<MIKMIDIMappableResponder>)responder
{
    for (CSMidiWrapper *wrap in self.midiMapGenerators)
    {
        
        __weak CaptureController *weakSelf = self;
        [wrap learnCommand:command forResponder:responder completionBlock:^(CSMidiWrapper *wrapper, NSString *command) {
            [weakSelf learnedMidiCommand:command fromWrapper:wrapper];
        }];
    }
}


-(NSInteger)additionalChannelForMIDIIdentifier:(NSString *)identifier
{
    NSArray *idents = [_inputIdentifiers arrayByAddingObjectsFromArray:@[@"InputNext", @"InputPrevious"]];
    
    if ([idents containsObject:identifier] && self.useMidiLiveChannelMapping && self.midiLiveChannel > -1)
    {
        return self.midiLiveChannel;
    }
    
    return -1;
}


- (NSArray *)commandIdentifiers
{
    NSArray *baseIdentifiers = @[@"GoLive", @"InputNext", @"InputPrevious", @"ActivateLive", @"ActivateStaging", @"ActivateToggle", @"InstantRecord"];
    
     NSMutableArray *layoutIdentifiers = [NSMutableArray array];
    
    for (SourceLayout *layout in self.sourceLayouts)
    {
        [layoutIdentifiers addObject:[NSString stringWithFormat:@"ToggleLayout:%@", layout.name]];
    }
    
    for (SourceLayout *layout in self.sourceLayouts)
    {
        [layoutIdentifiers addObject:[NSString stringWithFormat:@"SwitchToLayout:%@", layout.name]];
    }

    baseIdentifiers = [baseIdentifiers arrayByAddingObjectsFromArray:layoutIdentifiers];
    baseIdentifiers = [baseIdentifiers arrayByAddingObjectsFromArray:_inputIdentifiers];
    return baseIdentifiers;
}


- (MIKMIDIResponderType)MIDIResponderTypeForCommandIdentifier:(NSString *)commandID
{
    MIKMIDIResponderType ret = MIKMIDIResponderTypeButton;

    if ([_inputIdentifiers containsObject:commandID])
    {
        ret = MIKMIDIResponderTypeAbsoluteSliderOrKnob;
        if ([@[@"Opacity",@"Rotate",@"RotateX",@"RotateY"] containsObject:commandID])
        {
            ret |= MIKMIDIResponderTypeButton;
        }
    
        if ([@[@"Active", @"AutoFit", @"CKEnable", @"MultiTransition"] containsObject:commandID])
        {
            ret = MIKMIDIResponderTypeButton;
        }
    }
    return ret;
}



-(NSString *)MIDIIdentifier
{
    return @"Global";
}

-(BOOL)respondsToMIDICommand:(MIKMIDICommand *)command
{
    return YES;
}

-(void)handleMIDICommand:(MIKMIDICommand *)command
{
    return;
}


-(SourceLayout *)currentMIDILayout
{
    
    if (self.stagingHidden)
    {
        return self.activePreviewView.sourceLayout;
    }
    
    
    if (self.currentMidiLayoutLive)
    {
        return self.livePreviewView.sourceLayout;
    }
    
    return self.stagingPreviewView.sourceLayout;
}

-(InputSource *)currentMIDIInput:(MIKMIDIChannelVoiceCommand *)command
{
    SourceLayout *currLayout = [self currentMIDILayout];

    
    if (self.useMidiLiveChannelMapping && command.channel == self.midiLiveChannel)
    {
        currLayout = self.livePreviewView.sourceLayout;
    }
    
    NSArray *inputs = currLayout.sourceListOrdered;
    
    if (!inputs || inputs.count == 0)
    {
        return nil;
    }
    
    NSInteger inputIdx;
    if (self.currentMidiLayoutLive || (self.useMidiLiveChannelMapping && command.channel == self.midiLiveChannel))
    {
        inputIdx = self.currentMidiInputLiveIdx;
    } else {
        inputIdx = self.currentMidiInputStagingIdx;
    }
    
    
    
    InputSource *retval = nil;
    
    @try {
        retval = [inputs objectAtIndex:inputIdx];
    } @catch (NSException *exception) {
        retval = nil;
    }
    
    return retval;
}


-(void)handleMIDICommandActivateLive:(MIKMIDICommand *)command
{
    if (!self.stagingHidden)
    {
        self.currentMidiLayoutLive = YES;
        self.stagingPreviewView.midiActive = NO;
        self.livePreviewView.midiActive = YES;
    }
}

-(void)handleMIDICommandActivateStaging:(MIKMIDICommand *)command
{
    if (!self.stagingHidden)
    {
        self.currentMidiLayoutLive = NO;
        self.livePreviewView.midiActive = NO;
        self.stagingPreviewView.midiActive = YES;
    }
}

-(void)handleMIDICommandActivateToggle:(MIKMIDICommand *)command
{
    if (!self.stagingHidden)
    {
        self.currentMidiLayoutLive = !self.currentMidiLayoutLive;
        self.stagingPreviewView.midiActive = !self.stagingPreviewView.midiActive;
        self.livePreviewView.midiActive = !self.livePreviewView.midiActive;
    }
}


-(void)handleMIDICommandInputNext:(MIKMIDIChannelVoiceCommand *)command
{
    
    NSInteger cVal;
    NSInteger cCount;
    
    if (self.currentMidiLayoutLive || (self.useMidiLiveChannelMapping && command.channel == self.midiLiveChannel))
    {
        cVal = self.currentMidiInputLiveIdx;
        cCount = self.livePreviewView.sourceLayout.sourceListOrdered.count;
    } else {
        cVal = self.currentMidiInputStagingIdx;
        cCount = self.stagingPreviewView.sourceLayout.sourceListOrdered.count;
    }
    
    cVal++;
    
    
    if (cVal >= cCount)
    {
        cVal = 0;
    }
    
    if (self.currentMidiLayoutLive || (self.useMidiLiveChannelMapping && command.channel == self.midiLiveChannel))
    {
        self.currentMidiInputLiveIdx = cVal;
    } else {
        self.currentMidiInputStagingIdx = cVal;
    }
    
}

-(void)handleMIDICommandInputPrevious:(MIKMIDIChannelVoiceCommand *)command
{
    NSInteger cVal;
    NSInteger cCount;
    
    if (self.currentMidiLayoutLive || (self.useMidiLiveChannelMapping && command.channel == self.midiLiveChannel))
    {
        cVal = self.currentMidiInputLiveIdx;
        cCount = self.livePreviewView.sourceLayout.sourceListOrdered.count;
    } else {
        cVal = self.currentMidiInputStagingIdx;
        cCount = self.stagingPreviewView.sourceLayout.sourceListOrdered.count;
    }
    
    cVal--;
    
    if (cVal < 0)
    {
        cVal = cCount -1;
    }
    
    if (self.currentMidiLayoutLive)
    {
        self.currentMidiInputLiveIdx = cVal;
    } else {
        self.currentMidiInputStagingIdx = cVal;
    }
}


-(id<MIKMIDIResponder>)dispatchMIDI:(MIKMIDICommand *)command forItem:(MIKMIDIMappingItem *)item
{
    
    id<MIKMIDIResponder> ret = nil;
    
    SourceLayout *currLayout = [self currentMIDILayout];
    NSString *responderName = item.MIDIResponderIdentifier;
    
    if ([responderName hasPrefix:@"Layout:"])
    {
        ret = currLayout;
    } else if ([responderName hasPrefix:@"Input:"]) {
        NSString *uuid = [responderName substringFromIndex:6];
        InputSource *input = [currLayout inputForUUID:uuid];
        if (input)
        {
            ret = input;
        }
    }

    return ret;
}





-(void)handleMIDICommand:(MIKMIDICommand *)command forIdentifier:(NSString *)identifier
{
    
    __weak CaptureController *weakSelf = self;

    
    if ([_inputIdentifiers containsObject:identifier])
    {
        InputSource *currInput = [self currentMIDIInput:command];
        NSString *dynMethod = [NSString stringWithFormat:@"handleMIDICommand%@:", identifier];
        
        SEL dynSelector = NSSelectorFromString(dynMethod);
        
        if ([currInput respondsToSelector:dynSelector])
        {
            NSMethodSignature *dynsig = [[currInput class] instanceMethodSignatureForSelector:dynSelector];
            NSInvocation *dyninvoke = [NSInvocation invocationWithMethodSignature:dynsig];
            dyninvoke.target = currInput;
            dyninvoke.selector = dynSelector;
            [dyninvoke setArgument:&command atIndex:2];
            [dyninvoke retainArguments];
            [dyninvoke invoke];
        }
        return;
    }
    
    
    if ([identifier hasPrefix:@"ToggleLayout:"])
    {
        
        
        NSString *layoutName = [identifier substringFromIndex:13];
        NSUInteger indexOfLayout = [self.sourceLayouts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            SourceLayout *testLayout = obj;
            if ([testLayout.name isEqualToString:layoutName])
            {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        
        if (indexOfLayout != NSNotFound)
        {
            SourceLayout *layout = [self.sourceLayouts objectAtIndex:indexOfLayout];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf toggleLayout:layout];
            });
            
        }
        return;
    }

    
    if ([identifier hasPrefix:@"SwitchToLayout:"])
    {
        
        
        NSString *layoutName = [identifier substringFromIndex:15];
        NSUInteger indexOfLayout = [self.sourceLayouts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            SourceLayout *testLayout = obj;
            if ([testLayout.name isEqualToString:layoutName])
            {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        
        if (indexOfLayout != NSNotFound)
        {
            SourceLayout *layout = [self.sourceLayouts objectAtIndex:indexOfLayout];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf switchToLayout:layout];
            });
            
        }
        return;
    }

    if ([identifier isEqualToString:@"GoLive"])
    {
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf stagingGoLive:nil];
        });
    }
    
    if ([identifier isEqualToString:@"InstantRecord"])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf doInstantRecord:nil];
        });
    }
}



-(void)saveMIDI
{
    MIKMIDIMappingManager *manager = [MIKMIDIMappingManager sharedManager];
    
    /*
    for (CSMidiWrapper *wrap in self.midiMapGenerators)
    {
        [manager addUserMappingsObject:wrap.deviceMapping];
    }
     */
    
    [manager saveMappingsToDisk];
}


-(void)loadMIDI
{
    MIKMIDIMappingManager *manager = [MIKMIDIMappingManager sharedManager];
    
    for (CSMidiWrapper *wrap in self.midiMapGenerators)
    {
        MIKMIDIMapping *devmap = [[manager mappingsForControllerName:wrap.device.name] anyObject];
        if (devmap)
        {
            wrap.deviceMapping = devmap;
        } else {
            [manager addUserMappingsObject:wrap.deviceMapping];
        }
    }
}



-(void)setupMIDI
{
    self.midiManager = [MIKMIDIDeviceManager sharedDeviceManager];
    self.midiMapGenerators = [CSMidiWrapper getAllMidiDevices];
    self.midiDeviceMappings = [NSMutableDictionary dictionary];

    for (CSMidiWrapper *wrap in self.midiMapGenerators)
    {
        wrap.redirectResponderBlock = ^id<MIKMIDIResponder>(MIKMIDICommand *command, MIKMIDIMappingItem *item) {
            return [self dispatchMIDI:command forItem:item];
        };
        
        self.midiDeviceMappings[wrap.device.name] = wrap;
        [wrap connect];

    }
    
    [self loadMIDI];
    [NSApp registerMIDIResponder:self];
}



- (IBAction)doInstantRecord:(id)sender
{
    if (self.instantRecordActive && self.instantRecorder)
    {
        
        NSString *directory = self.instantRecordDirectory;
        
        if (!directory)
        {
            NSArray *mPaths = NSSearchPathForDirectoriesInDomains(NSMoviesDirectory, NSUserDomainMask, YES);
            directory = mPaths.firstObject;
        }
        
        if (directory)
        {
            NSDateFormatter *dFormat = [[NSDateFormatter alloc] init];
            dFormat.dateStyle = NSDateFormatterMediumStyle;
            dFormat.timeStyle = NSDateFormatterMediumStyle;
            NSString *dateStr = [dFormat stringFromDate:[NSDate date]];
            NSString *useFilename = [NSString stringWithFormat:@"CS_instant_record-%@.mov", dateStr];

            NSString *savePath = [NSString pathWithComponents:@[directory, useFilename]];
            
            [self.instantRecorder writeCurrentBuffer:savePath];
        }
    }
}



-(IBAction)openTransitionFilterPanel:(NSButton *)sender
{
    
    
    if (!self.transitionFilter)
    {
        return;
    }
    
    IKFilterUIView *filterView = [self.transitionFilter viewForUIConfiguration:@{IKUISizeFlavor:IKUISizeMini} excludedKeys:@[kCIInputImageKey, kCIInputTargetImageKey, kCIInputTimeKey]];
    
    
    self.transitionFilterWindow = [[NSWindow alloc] init];
    [self.transitionFilterWindow setContentSize:filterView.bounds.size];
    [self.transitionFilterWindow.contentView addSubview:filterView];
    
    self.transitionFilterWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    [self.transitionFilterWindow setReleasedWhenClosed:NO];
    
    [self.transitionFilterWindow makeKeyAndOrderFront:self.transitionFilterWindow];
    
}


-(void)openMidiLearnerForResponders:(NSArray *)responders
{
    self.midiManagerController = [[CSMidiManagerWindowController alloc] initWithWindowNibName:@"CSMidiManagerWindowController"];
    self.midiManagerController.captureController = self;
    self.midiManagerController.responderList = responders;
    [self.midiManagerController showWindow:nil];
}


-(IBAction)openMidiManager:(id)sender
{
    [self openMidiLearnerForResponders:@[self]];
}

- (IBAction)openPluginManager:(id)sender
{
    self.pluginManagerController = [[PluginManagerWindowController alloc] initWithWindowNibName:@"PluginManagerWindowController"];
    self.pluginManagerController.sharedPluginLoader = self.sharedPluginLoader;
    [self.pluginManagerController showWindow:nil];
}



-(void)applyTransitionSettings:(SourceLayout *)layout
{
    [self.objectController commitEditing];
    layout.transitionName = self.transitionName;
    layout.transitionDirection = self.transitionDirection;
    layout.transitionDuration = self.transitionDuration;
    layout.transitionFilter = self.transitionFilter;
    layout.transitionFullScene = self.transitionFullScene;
}

-(void)clearTransitionSettings:(SourceLayout *)layout
{
    layout.transitionName = nil;
    layout.transitionDirection = nil;
    layout.transitionDuration = 0;
    layout.transitionFilter = nil;
    layout.transitionFullScene = nil;

}
-(IBAction) swapStagingAndLive:(id)sender
{

    //Save the current live layout to a temporary layout, do a normal staging->live and then restore old live into current staging

    [self.livePreviewView.sourceLayout saveSourceList];
    
    SourceLayout *tmpLive = [self.livePreviewView.sourceLayout copy];
    
    [self stagingGoLive:self];

    [self applyTransitionSettings:self.activePreviewView.sourceLayout];
    [self switchToLayout:tmpLive];
    [self clearTransitionSettings:self.activePreviewView.sourceLayout];
}



- (IBAction)stagingGoLive:(id)sender
{
    
    [self applyTransitionSettings:self.livePreviewView.sourceLayout];

    if (self.stagingLayout)
    {
        [self stagingSave:sender];
    
        [self.selectedLayout replaceWithSourceLayout:self.stagingLayout];
    }
}


-(IBAction)stagingSave:(id)sender
{
    [self.stagingLayout saveSourceList];
}

-(IBAction)stagingRevert:(id)sender
{
    if (self.stagingPreviewView.sourceLayout)
    {
        [self.stagingPreviewView.sourceLayout restoreSourceList:nil];
    }
}

-(IBAction)mainRevert:(id)sender
{
    if (self.livePreviewView.sourceLayout)
    {
        [self.livePreviewView.sourceLayout restoreSourceList:nil];
    }
}

- (IBAction)unlockStagingFPS:(id)sender
{
    if (self.stagingPreviewView && self.stagingPreviewView.sourceLayout)
    {
        self.stagingPreviewView.sourceLayout.layoutTimingSource = nil;
    }
}

- (IBAction)unlockLiveFPS:(id)sender
{
    if (self.livePreviewView && self.livePreviewView.sourceLayout)
    {
        self.livePreviewView.sourceLayout.layoutTimingSource = nil;
    }
}




-(void) hideStagingView
{
    NSView *stagingView = self.canvasSplitView.subviews[0];
    NSView *liveView = self.canvasSplitView.subviews[1];
    _liveFrame = liveView.frame;
    stagingView.hidden = YES;
    //[liveView setFrameSize:NSMakeSize(self.canvasSplitView.frame.size.width, liveView.frame.size.height)];
    [self.canvasSplitView adjustSubviews];
    
    
    [self.canvasSplitView display];
    self.livePreviewView.viewOnly = NO;
    self.livePreviewView.midiActive = NO;
    self.activePreviewView = self.livePreviewView;
    self.stagingHidden = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationLayoutModeChanged object:self];

}

-(void) showStagingView
{
    NSView *stagingView = self.canvasSplitView.subviews[0];
    NSView *liveView = self.canvasSplitView.subviews[1];
    stagingView.hidden = NO;
    
    
    /*
    CGFloat dividerWidth = self.canvasSplitView.dividerThickness;
    NSRect stagingFrame = stagingView.frame;
    NSRect liveFrame = liveView.frame;
    liveFrame.size.width = liveFrame.size.width - stagingFrame.size.width-dividerWidth;
    liveFrame.origin.x = stagingFrame.size.width + dividerWidth;
    [stagingView setFrameSize:stagingFrame.size];
    [liveView setFrame:liveFrame];
    */
    if (self.livePreviewView.sourceLayout)
    {
        [self.livePreviewView.sourceLayout saveSourceList];
        if (self.selectedLayout == self.stagingLayout)
        {
            self.stagingPreviewView.sourceLayout.savedSourceListData = self.livePreviewView.sourceLayout.savedSourceListData;
            [self.stagingPreviewView.sourceLayout restoreSourceList:nil];
        }
    }

    [self.canvasSplitView setPosition:_liveFrame.origin.x ofDividerAtIndex:0];
    
    [self.canvasSplitView adjustSubviews];
    
    [self.canvasSplitView display];
    self.livePreviewView.viewOnly = YES;
    self.stagingHidden = NO;
    self.activePreviewView = self.stagingPreviewView;
    if (self.currentMidiLayoutLive)
    {
        self.livePreviewView.midiActive = YES;
        self.stagingPreviewView.midiActive = NO;
    } else {
        self.livePreviewView.midiActive = YES;
        self.stagingPreviewView.midiActive = NO;
    }
    dispatch_async(_preview_queue, ^{
        [self newStagingFrameTimed];
    });


}

-(void)layoutWentFullscreen
{
    
    //[self.canvasSplitView adjustSubviews];
    //[self.canvasSplitView display];
    /*
    _stagingFrame = self.stagingPreviewView.frame;
    _liveFrame = self.livePreviewView.frame;
     */
    if (!self.stagingPreviewView.isInFullScreenMode && !self.stagingPreviewView.isInFullScreenMode)
    {
        _liveFrame = self.livePreviewView.frame;
    }

    
}

-(void)layoutLeftFullscreen
{
    [self.canvasSplitView adjustSubviews];
    [self.canvasSplitView setPosition:_liveFrame.origin.x ofDividerAtIndex:0];
    [self.canvasSplitView display];
    
    
    /*
    self.stagingPreviewView.frame = _stagingFrame;
    self.livePreviewView.frame = _liveFrame;
     */
    
}
- (IBAction)stagingViewToggle:(id)sender
{
    BOOL stagingCollapsed = [self.canvasSplitView isSubviewCollapsed:self.canvasSplitView.subviews[0]];
    
    if (stagingCollapsed)
    {
        [self showStagingView];
    } else {
        [self hideStagingView];
    }
}


- (IBAction)outputEditClicked:(OutputDestination *)toEdit
{
    [self openOutputSheet:toEdit];
}

@end
