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
#import "AppDelegate.h"
#import "CSAudioInputSource.h"
#import <Python/Python.h>
#import "CSLayoutRecorder.h"
#import "CSJSProxyObj.h"
#import "CSLayoutCollectionItem.h"
#import "CSLayoutTransition.h"
#import "CSSimpleLayoutTransitionViewController.h"
#import "CSCIFilterLayoutTransitionViewController.h"
#import "CSLayoutLayoutTransitionViewController.h"
#import "CSScriptInputSource.h"
#import "CSJSAnimationDelegate.h"


@implementation CaptureController

@synthesize selectedLayout = _selectedLayout;
@synthesize stagingLayout = _stagingLayout;
@synthesize audioSamplerate  = _audioSamplerate;
@synthesize transitionName = _transitionName;
@synthesize useInstantRecord = _useInstantRecord;
@synthesize instantRecordBufferDuration = _instantRecordBufferDuration;
@synthesize useTransitions = _useTransitions;
@synthesize captureRunning = _captureRunning;
@synthesize useDarkMode = _useDarkMode;



-(void)evaluateJavascriptFile:(NSString *)baseFile inContext:(JSContext *)ctx
{
    if (!_javaScriptFileCache)
    {
        _javaScriptFileCache = [NSMutableDictionary dictionary];
    }
    
    NSString *scriptSource = nil;
    
    scriptSource = _javaScriptFileCache[baseFile];
    
    if (!scriptSource)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:baseFile ofType:@"js" inDirectory:@"Javascript"];
        if (path)
        {
            scriptSource = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            if (scriptSource)
            {
                _javaScriptFileCache[baseFile] = scriptSource;
            }
        }
    }
    
    if (scriptSource)
    {
        [ctx evaluateScript:scriptSource];
    }
}


-(JSContext *)setupJavascriptContext
{

    return [self setupJavascriptContext:nil];
}


-(JSContext *)setupJavascriptContext:(JSVirtualMachine *)machine
{
    
    JSContext *ctx = nil;
    if (machine)
    {
        ctx = [[JSContext alloc] initWithVirtualMachine:machine];
    } else {
        ctx = [[JSContext alloc] init];
    }
    ctx.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        NSString *stackTrace = [exception objectForKeyedSubscript:@"stack"].toString;
        NSNumber *lineNum = [exception objectForKeyedSubscript:@"line"].toNumber;
        NSNumber *colNum = [exception objectForKeyedSubscript:@"column"].toNumber;
        NSLog(@"JS EXCEPTION %@\n%@ LINE %@ COLUMN %@", exception, stackTrace, lineNum, colNum);
    };

    
    ctx[@"generateUUID"] = ^(void) {
        CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
        NSString *uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
        CFRelease(tmpUUID);
        return uuid;
    };
    
    ctx[@"console"][@"log"] = ^(NSString *msg) {
        NSLog(@"JS: %@", msg);
    };
    
    ctx[@"CSJSAnimationDelegate"] = CSJSAnimationDelegate.class;
    
    ctx[@"proxyWithObject"] = ^(JSValue *jObject) {
        
        CSJSProxyObj *retObj = [[CSJSProxyObj alloc] init];
        retObj.jsObject = jObject;
        return retObj;
    };
    
    
    ctx[@"captureController"] = self;
    ctx[@"CATransaction"] = CATransaction.class;
    ctx[@"CALayer"] = CALayer.class;
    ctx[@"CAAnimation"] = CAAnimation.class;
    ctx[@"CAPropertyAnimation"] = CAPropertyAnimation.class;
    ctx[@"CABasicAnimation"] = CABasicAnimation.class;
    ctx[@"CAKeyframeAnimation"] = CAKeyframeAnimation.class;
    ctx[@"CATransition"] = CATransition.class;
    ctx[@"NSValue"] = NSValue.class;
    ctx[@"FLT_MAX"] = @(FLT_MAX);
    ctx[@"CIFilter"] = CIFilter.class;
    ctx[@"CSLayoutTransition"] = CSLayoutTransition.class;
    
    
    ctx[@"CACurrentMediaTime"] = ^(void) {
        return CACurrentMediaTime();
    };
    
    
    ctx[@"NSMinY"] = ^(NSRect rect) {
        return NSMinY(rect);
    };
    
    ctx[@"NSMinX"] = ^(NSRect rect) {
        return NSMinX(rect);
    };

    ctx[@"NSMaxY"] = ^(NSRect rect) {
        return NSMaxY(rect);
    };

    ctx[@"NSMaxX"] = ^(NSRect rect) {
        return NSMaxX(rect);
    };

    ctx[@"NSMidY"] = ^(NSRect rect) {
        return NSMidY(rect);
    };

    ctx[@"NSMidX"] = ^(NSRect rect) {
        return NSMidX(rect);
    };


    ctx[@"applyAnimationAsync"] = ^(CALayer *target, CAAnimation *animation, NSString *uukey) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [target addAnimation:animation forKey:uukey];
        });
    };
    

    [self evaluateJavascriptFile:@"CSAnimationBlock" inContext:ctx];
    [self evaluateJavascriptFile:@"CSAnimationInput" inContext:ctx];

    [self evaluateJavascriptFile:@"CSAnimation" inContext:ctx];
    [self evaluateJavascriptFile:@"cocoasplit" inContext:ctx];
    return ctx;
}


+(CaptureController *)sharedCaptureController
{
    AppDelegate *appDel = [NSApp delegate];
    return appDel.captureController;
}


-(void)setUseDarkMode:(bool)useDarkMode
{
    _useDarkMode = useDarkMode;
    AppDelegate *aDel = [NSApp delegate];
    [aDel changeAppearance];
}

-(bool)useDarkMode
{
    return _useDarkMode;
}


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


-(void)menuEndedTracking:(NSNotification *)notification
{
    NSMenu *menu = notification.object;
    
    if (menu == _inputsMenu)
    {
        _inputsMenu = nil;
    }
}


- (void)topLevelInputClicked:(NSMenuItem *)item
{
    
    
    NSObject *clickedItem = item.representedObject;
    if ([[clickedItem valueForKey:@"instanceLabel"] isEqualToString:@"Script"])
    {
        CSScriptInputSource *newScript = [[CSScriptInputSource alloc] init];
        [self.activePreviewView addInputSourceWithInput:newScript];
        [self.activePreviewView openInputConfigWindow:newScript.uuid];
        return;
    }
    
    NSObject <CSCaptureSourceProtocol> *clickedCapture = (NSObject <CSCaptureSourceProtocol> *)clickedItem;
    
    
    
    InputSource *newSrc = [[InputSource alloc] init];
    newSrc.selectedVideoType = clickedCapture.instanceLabel;
    newSrc.depth = FLT_MAX;
    [self.activePreviewView addInputSourceWithInput:newSrc];
    [self.activePreviewView openInputConfigWindow:newSrc.uuid];
    
}

- (void)videoInputItemClicked:(NSMenuItem *)item
{
    CSAbstractCaptureDevice *clickedDevice;
    clickedDevice = item.representedObject;
    if (clickedDevice)
    {
        InputSource *newSrc =  [[InputSource alloc] init];
        NSObject <CSCaptureSourceProtocol> *clickedCapture = (NSObject <CSCaptureSourceProtocol> *)item.parentItem.representedObject;
        
        newSrc.selectedVideoType = clickedCapture.instanceLabel;
        newSrc.videoInput.activeVideoDevice = clickedDevice;
        newSrc.depth = FLT_MAX;
        [self.activePreviewView addInputSourceWithInput:newSrc];
        [newSrc autoCenter];
        
    }
    
}

-(void)audioInputItemClicked:(NSMenuItem *)item
{
    
    CAMultiAudioNode *audioNode = item.representedObject;
    
    CSAudioInputSource *newSource = [[CSAudioInputSource alloc] initWithAudioNode:audioNode];
    [self.activePreviewView addInputSourceWithInput:newSource];
}


-(void)buildInputSubMenu:(NSMenuItem *)forItem
{
    NSObject <CSCaptureSourceProtocol> *captureObj = forItem.representedObject;
    
    for (CSAbstractCaptureDevice *dev in captureObj.availableVideoDevices)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:dev.captureName action:nil keyEquivalent:@""];
        item.representedObject = dev;
        item.target = self;
        item.action = @selector(videoInputItemClicked:);
        [forItem.submenu addItem:item];
    }
}


-(void)buildInputMenu
{
    _inputsMenu = [[NSMenu alloc] init];
    
    NSMutableDictionary *pluginMap = [[CSPluginLoader sharedPluginLoader] sourcePlugins];
    
    NSArray *sortedKeys = [pluginMap.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSMenuItem *item = nil;
    NSSize iconSize;
    iconSize.width = [[NSFont menuFontOfSize:0] pointSize];
    iconSize.height = iconSize.width;
    for (NSString *inputName in sortedKeys)
    {
        Class captureClass = pluginMap[inputName];

        NSObject <CSCaptureSourceProtocol> *newCapture = [[captureClass alloc] init];

        item = [[NSMenuItem alloc] initWithTitle:inputName action:nil keyEquivalent:@""];
        item.image = newCapture.libraryImage;
        item.image.size = iconSize;
        item.representedObject = newCapture;
        item.target = self;
        [_inputsMenu addItem:item];
        
        if (newCapture.availableVideoDevices && newCapture.availableVideoDevices.count > 0)
        {
            item.submenu = [[NSMenu alloc] init];
            [self buildInputSubMenu:item];
        } else {
            item.action = @selector(topLevelInputClicked:);
            item.target = self;
        }
    }

    item = [[NSMenuItem alloc] initWithTitle:@"Script" action:nil keyEquivalent:@""];
    NSImage *scriptImage  = [NSImage imageNamed:@"NSScriptTemplate"];
    scriptImage.template = NO;
    item.image = scriptImage;
    item.image.size = iconSize;
    item.representedObject = @{@"instanceLabel":@"Script"};
    item.action = @selector(topLevelInputClicked:);
    item.target = self;

    [_inputsMenu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:@"Audio" action:nil keyEquivalent:@""];
    NSImage *audioImage = [NSImage imageNamed:@"NSAudioOutputVolumeMedTemplate"];
    audioImage.template = NO;
    item.image = audioImage;
    item.image.size = iconSize;
    item.submenu = [[NSMenu alloc] init];

    for(CAMultiAudioInput *input in [CaptureController sharedCaptureController].multiAudioEngine.audioInputs)
    {
        if (input.systemDevice)
        {
            NSMenuItem *audioItem = [[NSMenuItem alloc] initWithTitle:input.name action:nil keyEquivalent:@""];
            audioItem.representedObject = input;
            audioItem.target = self;
            audioItem.action = @selector(audioInputItemClicked:);
            [item.submenu addItem:audioItem];
        }
    }

    [_inputsMenu addItem:item];

}
-(void)openAddInputPopover:(id)sender sourceRect:(NSRect)sourceRect
{
    [self buildInputMenu];
    
    NSInteger midItem = _inputsMenu.itemArray.count/2;
    NSPoint popupPoint = NSMakePoint(NSMaxY(sourceRect), NSMidY(sourceRect));
    [_inputsMenu popUpMenuPositioningItem:[_inputsMenu itemAtIndex:midItem] atLocation:popupPoint inView:sender];

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

-(NSObject<VideoCompressor> *)compressorByName:(NSString *)name
{
    return self.compressors[name];
}


-(float)frameRate
{
    
    return self.captureFPS;
}


- (IBAction)openLibraryWindow:(id) sender
{
    CSInputLibraryWindowController *newController = [[CSInputLibraryWindowController alloc] init];
    
    [newController showWindow:nil];
    
    newController.controller = self;
    
    self.inputLibraryController = newController;
}

-(void)addInputToLibrary:(NSObject<CSInputSourceProtocol> *)source atIndex:(NSUInteger)idx
{
    CSInputLibraryItem *newItem = [[CSInputLibraryItem alloc] initWithInput:source];
    
    
    [self insertObject:newItem inInputLibraryAtIndex:idx];

}

-(void)addInputToLibrary:(NSObject<CSInputSourceProtocol> *)source
{
    
    NSUInteger cIdx = self.inputLibrary.count;
    [self addInputToLibrary:source atIndex:cIdx];
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
    if (!layout.recorder)
    {
        [newController.previewView.sourceLayout restoreSourceList:nil];
        [layout adjustAllInputs];
    }
    
    newController.delegate = self;
    
    
    [_layoutWindows addObject:newController];
    return newController;
}




-(void)openSequenceWindow:(CSLayoutSequence *)forSequence
{
    CSSequenceEditorWindowController *editSequenceController = [[CSSequenceEditorWindowController alloc] init];
    editSequenceController.addSequenceOnSave = NO;
    if (!forSequence)
    {
        forSequence = [[CSLayoutSequence alloc] init];
        
    }
    editSequenceController.sequence = forSequence;
    [_sequenceWindows addObject:editSequenceController];
    editSequenceController.delegate = self;
    
    
    [editSequenceController showWindow:nil];

}


-(void)sequenceWindowWillClose:(CSSequenceEditorWindowController *)windowController
{
    if ([_sequenceWindows containsObject:windowController])
    {
        [_sequenceWindows removeObject:windowController];
    }
}


- (IBAction)createLayoutOrSequenceAction:(id)sender
{
    if (_layoutViewController)
    {
        [self openLayoutPopover:sender];
    } else {
        _sequenceWindowController = [[CSSequenceEditorWindowController alloc] init];
        _sequenceWindowController.addSequenceOnSave = YES;
        _sequenceWindowController.sequence = [[CSLayoutSequence alloc] init];
        [_sequenceWindowController showWindow:nil];
    }
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


-(bool)deleteSequence:(CSLayoutSequence *)toDelete
{
    if (toDelete)
    {
        if ([self actionConfirmation:[NSString stringWithFormat:@"Really delete %@?", toDelete.name] infoString:nil])
        {
            
            
            NSInteger seqIdx = [self.layoutSequences indexOfObject:toDelete];
            if (seqIdx != NSNotFound)
            {
                [self removeObjectFromLayoutSequencesAtIndex:seqIdx];
            }
            return YES;
        }
    }
    return NO;
    
}


-(CSLayoutSequence *)findSequenceWithName:(NSString *)name
{
    for(CSLayoutSequence *seq in self.layoutSequences)
    {
        if([seq.name isEqualToString:name])
        {
            return seq;
        }
    }
    
    return nil;
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


-(void)addSequenceWithNameDedup:(CSLayoutSequence *)sequence
{
    
    NSMutableString *baseName = sequence.name.mutableCopy;
    
    NSMutableString *newName = baseName;
    int name_try = 1;
    
    while ([self findSequenceWithName:newName]) {
        newName = [NSMutableString stringWithFormat:@"%@#%d", baseName, name_try];
        name_try++;
    }
    
    
    sequence.name = newName;

    [self insertObject:sequence inLayoutSequencesAtIndex:self.layoutSequences.count];
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

        [self->_outputWindows removeObject:window];
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

- (IBAction)chooseLayoutRecordDirectory:(id)sender
{
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = NO;
    panel.allowsMultipleSelection = NO;
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            self.layoutRecordingDirectory = panel.URL.path;
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
    } else if (menu == _inputsMenu) {
        return [[CSPluginLoader sharedPluginLoader] sourcePlugins].count;
    }
    
    return 0;
}


-(BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
    
    
    
    if (menu == _inputsMenu)
    {
        return NO;
    }
    
    
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
        [useLayout saveSourceListForExport];
    } else if (layout == self.stagingLayout) {
        useLayout = self.stagingPreviewView.sourceLayout;
        [useLayout saveSourceListForExport];

    } else {
        //It's not an active source layout, so restore the source list, and re-save it. This way any sources that do special export saving will work properly
        SourceLayout *useCopy = [useLayout copy];
        [useCopy restoreSourceList:nil];
        [useCopy saveSourceListForExport];
        useLayout = useCopy;
    }

    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSURL *saveFile = [panel URL];
            
            
            [NSKeyedArchiver archiveRootObject:useLayout toFile:saveFile.path];
            
        }
    }];
}


-(id) init
{
   if (self = [super init])
   {
       
       _inputViewSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"depth" ascending:NO]];

       _layoutWindows = [NSMutableArray array];
       _sequenceWindows = [NSMutableArray array];
       _layoutRecorders = [NSMutableArray array];
       
       _layoutRecordingDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSMoviesDirectory inDomains:NSUserDomainMask] firstObject].path;
       
       _layoutRecordingFormat = @"MOV";
       
       self.transitionDirections = @[kCATransitionFromTop, kCATransitionFromRight, kCATransitionFromBottom, kCATransitionFromLeft];
       self.useInstantRecord = YES;
       self.instantRecordActive = YES;
       self.instantRecordBufferDuration = 60;
       
       
       NSArray *caTransitionNames = @[@"Layout", kCATransitionFade, kCATransitionPush, kCATransitionMoveIn, kCATransitionReveal, @"cube", @"alignedCube", @"flip", @"alignedFlip"];
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
       OSStatus err;
       NSArray *audioTypes;
       UInt32 size;
       
       self.audioFileUTIs = [NSMutableSet set];
       
       err = AudioFileGetGlobalInfoSize(kAudioFileGlobalInfo_AllUTIs, 0, NULL, &size);
       if (err == noErr)
       {
           err = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_AllUTIs, 0, NULL, &size, &audioTypes);
           if (err == noErr)
           {
               
               self.audioFileUTIs = [NSMutableSet setWithArray:audioTypes];
               [self.audioFileUTIs removeObject:@"public.movie"];
               [self.audioFileUTIs removeObject:@"public.mpeg-4"];

           }
       }

       [self setupMIDI];
       
       
       //[[CSPluginLoader sharedPluginLoader] loadAllBundles];
       
#ifndef DEBUG
       [self setupLogging];
#endif
       
       

       
       videoBuffer = [[NSMutableArray alloc] init];
       
       
       
       
       _max_render_time = 0.0f;
       _min_render_time = 0.0f;
       _avg_render_time = 0.0f;
       _render_time_total = 0.0f;
       
       self.useStatusColors = YES;
       
       
       
       
       dispatch_source_t sigsrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGPIPE, 0, dispatch_get_global_queue(0, 0));
       dispatch_source_set_event_handler(sigsrc, ^{ return;});
       dispatch_resume(sigsrc);
       
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
           int dropped_frame_cnt = 0;
           
           for (OutputDestination *outdest in self->_captureDestinations)
           {
               if (outdest.active)
               {
                   total_outputs++;
                   if (outdest.errored)
                   {
                       errored_outputs++;
                   }
                   
                   dropped_frame_cnt += outdest.dropped_frame_count;
               }
               [outdest updateStatistics];
           }
           
           
           
           dispatch_async(dispatch_get_main_queue(), ^{
               self.outputStatsString = [NSString stringWithFormat:@"Active Outputs: %d Errored %d Frames dropped %d", total_outputs, errored_outputs,dropped_frame_cnt];
               self.renderStatsString = [NSString stringWithFormat:@"Render min/max/avg: %f/%f/%f", self->_min_render_time, self->_max_render_time, self->_render_time_total / self->_renderedFrames];
               self.active_output_count = total_outputs;
               bool streamButtonEnabled = YES;
               if (total_outputs == 0 && !self.captureRunning)
               {
                   streamButtonEnabled = NO;
               }
               
               self.streamButton.enabled = streamButtonEnabled;
               self.total_dropped_frames = dropped_frame_cnt;
               
           });
           self->_renderedFrames = 0;
           self->_render_time_total = 0.0f;
           

           [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationStatisticsUpdate object:self userInfo:nil];

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

       
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuEndedTracking:) name:NSMenuDidEndTrackingNotification object:nil];

       
   }
    
    return self;
    
}

-(CSLayoutRecorder *)startRecordingLayout:(SourceLayout *)layout usingOutput:(OutputDestination *)output
{
    
    CSLayoutRecorder *useRecorder = layout.recorder;
    if (!useRecorder)
    {
        useRecorder = [[CSLayoutRecorder alloc] init];
        useRecorder.layout = layout;
    }
    [useRecorder startRecordingWithOutput:output];
    if (![self.layoutRecorders containsObject:useRecorder])
    {
        [self.layoutRecorders addObject:useRecorder];
    }
    return useRecorder;
}



-(void)removeLayoutRecorder:(CSLayoutRecorder *)toRemove
{
    [self.layoutRecorders removeObject:toRemove];
}


-(void)stopRecordingLayout:(SourceLayout *)layout usingOutput:(OutputDestination *)output
{
    
    CSLayoutRecorder *useRecorder = layout.recorder;
    if (useRecorder)
    {
        [useRecorder stopRecordingForOutput:output];
        //output.active = NO;
        if (self.mainLayoutRecorder)
        {
            output.settingsController = self.mainLayoutRecorder;
        }
    }
}


-(CSLayoutRecorder *)startRecordingLayout:(SourceLayout *)layout
{
    if (layout.recordingLayout && layout.recorder && layout.recorder.defaultRecordingActive)
    {
        return nil;
    }
    
    if (!self.layoutRecordingDirectory)
    {
        self.layoutRecordingDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSMoviesDirectory inDomains:NSUserDomainMask] firstObject].path;
    }
    
    if (!self.layoutRecorderCompressorName)
    {
        self.layoutRecorderCompressorName = @"AppleProRes";
    }
    
    if (!self.layoutRecordingFormat)
    {
        self.layoutRecordingFormat = @"MOV";
    }
    
    CSLayoutRecorder *useRec = layout.recorder;
    if (!useRec)
    {
        useRec = [[CSLayoutRecorder alloc] init];
        useRec.layout = layout;
        [self.layoutRecorders addObject:useRec];
    }

    //useRec.compressor_name = self.layoutRecorderCompressorName;
    //useRec.baseDirectory = self.layoutRecordingDirectory;
    //useRec.fileFormat  = self.layoutRecordingFormat;
    [useRec startRecording];
    return useRec;
}



-(void)stopRecordingLayout:(SourceLayout *)layout
{
    
    CSLayoutRecorder *layoutRecorder = layout.recorder;
    
    if (!layoutRecorder)
    {
        return;
    }
    
    
    
    [layoutRecorder stopDefaultRecording];
    
}

-(void)stopAllRecordings
{
    NSArray *recCopy = self.layoutRecorders.copy;
    
    for (CSLayoutRecorder *rec in recCopy)
    {
        SourceLayout *forLayout = rec.layout;
        if (!forLayout.recordingLayout)
        {
            forLayout = nil;
        }
        [rec stopDefaultRecording];
        //Reassert recording flag for save
        if (forLayout)
        {
            forLayout.recordingLayout = YES;
        }
        
        //[self.layoutRecorders removeObject:rec];
    }
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
    if (layout == self.livePreviewView.sourceLayout)
    {
        SourceLayout *sLayout = self.stagingPreviewView.sourceLayout;

        if (sLayout.frameRate != layout.frameRate)
        {
            sLayout.frameRate = layout.frameRate;
        }
        [self resetInstantRecorder];
        
    }
    
    if (layout == self.stagingPreviewView.sourceLayout)
    {
        SourceLayout *lLayout = self.livePreviewView.sourceLayout;
        if (lLayout.frameRate != layout.frameRate)
        {
            lLayout.frameRate = layout.frameRate;
        }
    }
}



-(void)layoutCanvasChanged:(NSNotification *)notification
{
    SourceLayout *layout = [notification object];
    
    if ([layout isEqual:self.livePreviewView.sourceLayout])
    {
        
        SourceLayout *sLayout = self.stagingPreviewView.sourceLayout;
        if (sLayout.canvas_width != layout.canvas_width || sLayout.canvas_height != layout.canvas_height)
        {
            [sLayout updateCanvasWidth:layout.canvas_width height:layout.canvas_height];
        }
        [self resetInstantRecorder];

        
    }
    
    if ([layout isEqual:self.stagingPreviewView.sourceLayout])
    {
        SourceLayout *lLayout = self.livePreviewView.sourceLayout;
        
        if (lLayout.canvas_width != layout.canvas_width || lLayout.canvas_height != layout.canvas_height)
        {
            [lLayout updateCanvasWidth:layout.canvas_width height:layout.canvas_height];
        }

        
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
        
        NSString *sysstr = [NSString stringWithFormat:@"import sys;sys.path.append('%@');sys.dont_write_bytecode = True", resourcePath];
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


-(SourceLayout *)activeLayout
{
    return self.activePreviewView.sourceLayout;
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
    
    return;
    /*
    NSAttributedString *appendStr = [[NSAttributedString alloc] initWithString:logLine];
    [[self.logTextView textStorage] beginEditing];

    [self.logTextView.textStorage appendAttributedString:appendStr];
    
    [[self.logTextView textStorage] endEditing];

    NSRange range;
    
    range = NSMakeRange([[self.logTextView string] length], 0);
    
    [self.logTextView scrollRangeToVisible:range];
    */
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
        if (!self.mainLayoutRecorder)
        {
            [self setupMainRecorder];
        }

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
        newCompressor.crf = 23;
        newCompressor.use_cbr = YES;
        
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
    
    [saveRoot setValue:self.layoutRecorderCompressorName forKey:@"layoutRecorderCompressorName"];
    [saveRoot setValue:self.layoutRecordingFormat forKey:@"layoutRecordingFormat"];
    [saveRoot setValue:self.layoutRecordingDirectory forKey:@"layoutRecordingDirectory"];
    

    
    
    [saveRoot setValue:[NSNumber numberWithBool:self.useDarkMode] forKey:@"useDarkMode"];
    
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
    
    [saveRoot setValue:[NSNumber numberWithBool:self.useMidiLiveChannelMapping] forKey:@"useMidiLiveChannelMapping"];
    [saveRoot setValue:[NSNumber numberWithInteger:self.midiLiveChannel] forKey:@"midiLiveChannel"];
    
    [self saveMIDI];

    [saveRoot setValue:self.inputLibrary forKey:@"inputLibrary"];
    [saveRoot setValue:[NSNumber numberWithBool:self.useTransitions] forKey:@"useTransitions"];
    if (self.layoutTransitionViewController && self.layoutTransitionViewController.transition)
    {
        [saveRoot setValue:self.layoutTransitionViewController.transition forKey:@"transitionInfo"];
    }
    [saveRoot setValue:self.layoutSequences forKey:@"layoutSequences"];
    [NSKeyedArchiver archiveRootObject:saveRoot toFile:path];
    
}


-(void) loadSettings
{
    [[CSPluginLoader sharedPluginLoader] loadAllBundles];

    CGColorRef tmpColor = CGColorCreateGenericRGB(0, 1, 0, 1);
    self.streamButton.layer.backgroundColor = tmpColor;
    CGColorRelease(tmpColor);
    tmpColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    self.streamButton.layer.borderColor   = tmpColor;
    CGColorRelease(tmpColor);
    
    self.streamButton.layer.borderWidth = 1.0f;
    self.streamButton.layer.cornerRadius = 2.0f;
    //all color panels allow opacity
    _savedAudioConstraintConstant = self.audioConstraint.constant;
    self.layoutScriptLabel = @"Layouts";
    
    
    self.activePreviewView = self.stagingPreviewView;
    [self.layoutCollectionView registerForDraggedTypes:@[@"CS_LAYOUT_DRAG"]];
    //[self.inputOutlineView registerForDraggedTypes:@[@"cocoasplit.input.item", @"cocoasplit.audio.item"]];
    [self.inputOutlineView registerForDraggedTypes:@[NSSoundPboardType,NSFilenamesPboardType, NSFilesPromisePboardType, NSFileContentsPboardType, @"cocoasplit.input.item", @"cocoasplit.audio.item"]];
    [self.audioTableView registerForDraggedTypes:@[@"cocoasplit.audio.item", NSFilenamesPboardType]];

    NSNib *layoutNib = [[NSNib alloc] initWithNibNamed:@"CSLayoutCollectionItem" bundle:nil];
    [self.layoutCollectionView registerNib:layoutNib forItemWithIdentifier:@"layout_item"];
    
    
    

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
    
    
    
    self.useDarkMode = [[saveRoot valueForKey:@"useDarkMode"] boolValue];
    
    
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

    if (!self.maxOutputDropped)
    {
        self.maxOutputDropped = 300;
    }
    
    if (!self.maxOutputPending)
    {
        self.maxOutputPending = 600;
    }
    
    
    self.audio_adjust = [[saveRoot valueForKey:@"audioAdjust"] doubleValue];
    

    self.stagingPreviewView.controller = self;
    self.livePreviewView.controller = self;
    self.livePreviewView.showTransitionToggle = YES;
    
    
    LayoutRenderer *stagingRender = [[LayoutRenderer alloc] init];
    self.stagingPreviewView.layoutRenderer = stagingRender;
    
    
    LayoutRenderer *liveRender = [[LayoutRenderer alloc] init];
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
    
    
    self.useTransitions = [[saveRoot valueForKey:@"useTransitions"] boolValue];
    
    self.transitionName = [saveRoot valueForKey:@"transitionName"];

    if (self.transitionName)
    {
        CSLayoutTransition *savedTransition = [saveRoot valueForKey:@"transitionInfo"];

        if (savedTransition)
        {
            self.layoutTransitionViewController.transition = savedTransition;
        } else {
            savedTransition = self.layoutTransitionViewController.transition;
            
            savedTransition.transitionDirection = [saveRoot valueForKey:@"transitionDirection"];
            savedTransition.transitionDuration = [[saveRoot valueForKey:@"transitionDuration"] floatValue];
            savedTransition.transitionFilter = [saveRoot valueForKey:@"transitionFilter"];
        }
    }
    
    
    self.multiAudioEngine = [saveRoot valueForKey:@"multiAudioEngine"];
    if (!self.multiAudioEngine)
    {
        self.multiAudioEngine = [[CAMultiAudioEngine alloc] init];
    }
     


    self.layoutSequences = [saveRoot valueForKey:@"layoutSequences"];
    if (!self.layoutSequences)
    {
        self.layoutSequences = [[NSMutableArray alloc] init];
    }
    
    
    self.extraPluginsSaveData = nil;
    self.sourceLayouts = [saveRoot valueForKey:@"sourceLayouts"];
    
    
    if (!self.sourceLayouts)
    {
        self.sourceLayouts = [[NSMutableArray alloc] init];
    }
    
    if (self.sourceLayouts.count < 12)
    {
        for(NSUInteger i=self.sourceLayouts.count+1; i <= 12; i++)
        {
            SourceLayout *nLayout = [[SourceLayout alloc] init];
            nLayout.name = [NSString stringWithFormat:@"Layout %lu", (unsigned long)i];
            [self.sourceLayouts addObject:nLayout];
        }
    }
    if (!_layoutViewController)
    {
        _layoutViewController = [[CSLayoutSwitcherViewController alloc] init];
        _layoutViewController.isSwitcherView = NO;
        _layoutViewController.view = self.layoutGridView;
       _layoutViewController.layouts = self.sourceLayouts;
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
        
        self.stagingLayout.name = @"staging";
        self.selectedLayout.name = @"live";
        
        //[self.stagingLayout mergeSourceLayout:tmpLayout withLayer:nil];
    }
    
    self.inputLibrary = [saveRoot valueForKey:@"inputLibrary"];
    if (!self.inputLibrary)
    {
        self.inputLibrary = [NSMutableArray array];
    }
    

    self.layoutRecorderCompressorName = [saveRoot valueForKey:@"layoutRecorderCompressorName"];
    if (!self.layoutRecorderCompressorName)
    {
        self.layoutRecorderCompressorName = @"AppleProRes";
    }
    
    self.layoutRecordingDirectory = [saveRoot valueForKey:@"layoutRecordingDirectory"];
    self.layoutRecordingFormat = [saveRoot valueForKey:@"layoutRecordingFormat"];
    if (!self.layoutRecordingFormat)
    {
        _layoutRecordingFormat = @"MOV";
    }
    
    
    

    //dispatch_async(_main_capture_queue, ^{[self newFrameTimed];});
    
    [self.livePreviewView enablePrimaryRender];
    [self.stagingPreviewView enablePrimaryRender];
    
    
    
    
    for (SourceLayout *layout in self.sourceLayouts)
    {
        if (layout.recordingLayout)
        {
            [self startRecordingLayout:layout];
        }
    }
    
    
    /*
    for (OutputDestination *output in self.captureDestinations)
    {
        if (output.active && output.assignedLayout)
        {
            [self startRecordingLayout:output.assignedLayout usingOutput:output];
        }
    }
     */
    if (self.useInstantRecord)
    {
        [self setupInstantRecorder];
    }


    

    
    
}



-(NSObject<CSInputSourceProtocol>*)inputSourceForPasteboardItem:(NSPasteboardItem *)item
{
    

    NSArray *captureClasses = [self captureSourcesForPasteboardItem:item];
    Class<CSCaptureSourceProtocol> useClass = captureClasses.firstObject;
    
    if (useClass)
    {
        NSObject<CSCaptureSourceProtocol> *newSource = [useClass createSourceFromPasteboardItem:item];
        InputSource *newInput = [[InputSource alloc] init];
        [newInput setDirectVideoInput:newSource];
        return newInput;
    }
    
    return nil;
}


-(NSArray *)captureSourcesForPasteboardItem:(NSPasteboardItem *)item
{
    
    NSMutableArray *candidates = [NSMutableArray array];
    
    CSPluginLoader *loader = [CSPluginLoader sharedPluginLoader];

    
    
    NSString *urlString = [item stringForType:@"public.file-url"];
    if (urlString)
    {
        NSURL *fileURL = [NSURL URLWithString:urlString];
        NSString *realPath = [fileURL path];
        
        MDItemRef mditem = MDItemCreate(NULL, (__bridge CFStringRef)realPath);
        if (mditem)
        {
            NSArray *attrs = @[(__bridge NSString *)kMDItemContentTypeTree];
            NSDictionary *attrMap = CFBridgingRelease(MDItemCopyAttributes(mditem, (__bridge CFArrayRef)attrs));
            NSArray *fileTypes = attrMap[(__bridge NSString *)kMDItemContentTypeTree];
            if (fileTypes)
            {
                NSSet *typeSet = [NSSet setWithArray:fileTypes];
                for (NSString *key in loader.sourcePlugins)
                {
                    Class<CSCaptureSourceProtocol> captureClass = loader.sourcePlugins[key];
                    NSSet *captureSet = [captureClass mediaUTIs];
                    if (captureSet)
                    {
                        if([typeSet intersectsSet:captureSet])
                        {
                            [candidates addObject:captureClass];
                        }
                    }
                    
                }
            }
        }
        
    }

    /*
    if (candidates.count == 0)
    {
        for (NSString *key in loader.sourcePlugins)
        {
            Class<CSCaptureSourceProtocol> captureClass = loader.sourcePlugins[key];
            
            if ([captureClass canCreateSourceFromPasteboardItem:item])
            {
                [candidates addObject:captureClass];
            }
            
        }
    }*/
    return candidates;
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
    _stagingLayout = stagingLayout;

    [stagingLayout setAddLayoutBlock:^(SourceLayout *layout) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
        layout.in_staging = YES;
        });
    }];
    
    [stagingLayout setRemoveLayoutBlock:^(SourceLayout *layout) {

        dispatch_async(dispatch_get_main_queue(), ^{

        layout.in_staging = NO;
        });

    }];

    
    [stagingLayout applyAddBlock];
    
    self.currentMidiInputStagingIdx = 0;
    
    stagingLayout.doSaveSourceList = YES;
    if (!self.stagingHidden)
    {
        [stagingLayout restoreSourceList:nil];
        [stagingLayout setupMIDI];
        self.stagingPreviewView.sourceLayout = stagingLayout;
        self.stagingPreviewView.midiActive = YES;
    }

    
    
    

}


-(SourceLayout *)stagingLayout
{
    return _stagingLayout;
}


-(void)setSelectedLayout:(SourceLayout *)selectedLayout
{
    
    
    [selectedLayout setAddLayoutBlock:^(SourceLayout *layout) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            layout.in_live = YES;

        });
        
    }];
    
    [selectedLayout setRemoveLayoutBlock:^(SourceLayout *layout) {
        dispatch_async(dispatch_get_main_queue(), ^{

        layout.in_live = NO;
        });

    }];

    
    [selectedLayout applyAddBlock];

    [self.objectController commitEditing];
    
    
    selectedLayout.isActive = YES;
    [selectedLayout restoreSourceList:nil];
    
    [selectedLayout setupMIDI];
    
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
    
    _transitionName = transitionName;

    if (!transitionName)
    {
        self.layoutTransitionViewController = nil;
    } else if ([transitionName hasPrefix:@"CI"]) {
        CIFilter *newFilter = [CIFilter filterWithName:transitionName];
        [newFilter setDefaults];
        self.transitionFilter = newFilter;
        self.layoutTransitionViewController = nil;
        self.layoutTransitionViewController = [[CSCIFilterLayoutTransitionViewController alloc] init];
        self.layoutTransitionViewController.transition = [[CSLayoutTransition alloc] init];
        self.layoutTransitionViewController.transition.transitionFilter = newFilter;
        self.layoutTransitionViewController.transition.transitionName = transitionName;
        
    } else if ([transitionName isEqualToString:@"Layout"]) {
        self.layoutTransitionViewController = nil;
        self.layoutTransitionViewController = [[CSLayoutLayoutTransitionViewController alloc] init];
        self.layoutTransitionViewController.transition = [[CSLayoutTransition alloc] init];
        self.layoutTransitionViewController.transition.transitionName = transitionName;
    } else {
        
        self.transitionFilter = nil;
        self.layoutTransitionViewController = [[CSSimpleLayoutTransitionViewController alloc] init];
        self.layoutTransitionViewController.transition = [[CSLayoutTransition alloc] init];
        self.layoutTransitionViewController.transition.transitionName = transitionName;
    }
    [self changeTransitionView];
}




-(void)changeTransitionView
{
    self.layoutTransitionConfigView.subviews = @[];
    if (self.layoutTransitionViewController)
    {
        self.layoutTransitionViewController.view.frame = self.layoutTransitionConfigView.bounds;
        [self.layoutTransitionConfigView addSubview:self.layoutTransitionViewController.view];
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




-(void)setupMainRecorder
{
    if (!self.mainLayoutRecorder)
    {
        self.mainLayoutRecorder = [[CSLayoutRecorder alloc] init];
        self.mainLayoutRecorder.renderer = self.livePreviewView.layoutRenderer;
        self.mainLayoutRecorder.layout = self.livePreviewView.sourceLayout;
        self.mainLayoutRecorder.audioEngine = self.multiAudioEngine;
        if (!self.multiAudioEngine.encoder)
        {
            CSAacEncoder *audioEnc = [[CSAacEncoder alloc] init];
            audioEnc.sampleRate = self.audioSamplerate;
            audioEnc.bitRate = self.audioBitrate*1000;
            
            audioEnc.inputASBD = self.multiAudioEngine.graph.graphAsbd;
            [audioEnc setupEncoderBuffer];
            self.multiAudioEngine.encoder = audioEnc;

        }
    }
        self.mainLayoutRecorder.audioEngine.encoder.encodedReceiver = self.mainLayoutRecorder;
    
        self.mainLayoutRecorder.compressors  = self.compressors;
        self.mainLayoutRecorder.outputs = self.captureDestinations;
        [self.mainLayoutRecorder startRecordingCommon];
    

    //if (!self.livePreviewView.layoutRenderer)
    //{
        //self.livePreviewView.layoutRenderer = self.mainLayoutRecorder.renderer;
   // }
    
        [self.livePreviewView disablePrimaryRender];

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

    
    [self setupMainRecorder];
    
    
    for (OutputDestination *outdest in _captureDestinations)
    {
    
        outdest.captureRunning = YES;

        if (outdest.assignedLayout && outdest.active)
        {
            [self startRecordingLayout:outdest.assignedLayout usingOutput:outdest];
        } else {
            
            
            outdest.settingsController = self.mainLayoutRecorder;
            if (outdest.active)
            {
                [outdest reset];
                [outdest setup];

                //[outdest setupCompressor];

            }
        }
    }
    
    
    self.captureRunning = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationStreamStarted object:self userInfo:nil];
    
    return YES;
    
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
        out.captureRunning = NO;
        
        if (out.assignedLayout && out.active)
        {
            [self stopRecordingLayout:out.assignedLayout usingOutput:out];
        } else {
            [out stopOutput];
        }
    }
    
    if (self.mainLayoutRecorder && !self.instantRecorder)
    {
        self.mainLayoutRecorder.recordingActive = NO;
    }
    
    if (self.mainLayoutRecorder && !self.instantRecorder)
    {
        
        [self.livePreviewView enablePrimaryRender];
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
    
    if (_needsIRReset)
    {
        [self resetInstantRecorder];
        _needsIRReset = NO;
    }
    
    
    
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
        
        if ([self activeRecordingConfirmation:@"Also stop all recordings?"] == YES)
        {
            [self stopAllRecordings];
        }
        
        [self stopStream];

    }
    
}

-(BOOL)captureRunning
{
    return _captureRunning;
}


-(void)setCaptureRunning:(BOOL)captureRunning
{
    _captureRunning = captureRunning;
    CGColorRef tmpColor;
    
    if (captureRunning)
    {
        
         [NSApp setApplicationIconImage:[NSImage imageNamed:@"StreamingIcon"]];
        tmpColor = CGColorCreateGenericRGB(1, 0, 0, 1);
    } else {
        [NSApp setApplicationIconImage:[NSImage imageNamed:@"AppIcon"]];

        tmpColor = CGColorCreateGenericRGB(0, 1, 0, 1);
    }
    
    self.streamButton.layer.backgroundColor = tmpColor;
    CGColorRelease(tmpColor);
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

- (IBAction)configureLayoutRecordingCompressor:(id)sender
{
    
    
    CompressionSettingsPanelController *cPanel = [[CompressionSettingsPanelController alloc] init];
    CSIRCompressor *compressor = self.compressors[self.layoutRecorderCompressorName];
    
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





- (IBAction)openAdvancedAudio:(id)sender
{
    if (!_audioWindowController)
    {
        _audioWindowController = [[CSAdvancedAudioWindowController alloc] init];
    }
    
    _audioWindowController.controller = self;
    [_audioWindowController showWindow:nil];
    
}


-(IBAction)openScriptSwitcherWindow:(id)sender
{
    if (!_scriptWindowViewController)
    {
        _scriptWindowViewController = [[CSScriptWindowViewController alloc] init];
    }
    [_scriptWindowViewController showWindow:nil];
    _scriptWindowViewController.sequences = nil;
}


- (IBAction)openLayoutSwitcherWindow:(id)sender
{
    
    
    if (_layoutViewController)
    {
        if (!_layoutSwitcherWindowController)
        {
            _layoutSwitcherWindowController = [[CSLayoutSwitcherWithPreviewWindowController alloc] init];
        }
        [_layoutSwitcherWindowController showWindow:nil];
        _layoutSwitcherWindowController.layouts = nil;
        /*
    } else {
        if (!_scriptWindowViewController)
        {
            _scriptWindowViewController = [[CSScriptWindowViewController alloc] init];
        }
        [_scriptWindowViewController showWindow:nil];
        _scriptWindowViewController.sequences = nil;
        
         */
    }
         

    
}

- (IBAction)switchLayoutView:(id)sender
{
    if (_layoutViewController)
    {
        _layoutViewController.layouts = @[];
        
        _layoutViewController = nil;
        _sequenceViewController = [[CSSequenceActivatorViewController alloc] init];
        _sequenceViewController.view = self.layoutGridView;
        _sequenceViewController.sequences = self.layoutSequences;
        self.layoutScriptLabel = @"Scripts";
    } else {
        _sequenceViewController.sequences = @[];
        _sequenceViewController = nil;
        _layoutViewController = [[CSLayoutSwitcherViewController alloc] init];
        _layoutViewController.view = self.layoutGridView;
        _layoutViewController.isSwitcherView = NO;
        _layoutViewController.layouts = self.sourceLayouts;
        self.layoutScriptLabel = @"Layouts";

    }
}





-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CAMultiAudioNode *audioNode = [self.audioInputsArrayController.arrangedObjects objectAtIndex:row];
    if ([audioNode isKindOfClass:CAMultiAudioFile.class])
    {
        return [tableView makeViewWithIdentifier:@"fileAudioView" owner:self];
    } else {
        return [tableView makeViewWithIdentifier:@"standardAudioView" owner:self];
    }
}
-(BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    

    NSArray *audioNodes = [self.audioInputsArrayController.arrangedObjects objectsAtIndexes:rowIndexes];
    
    NSPasteboardItem *pItem = [[NSPasteboardItem alloc] init];
    
    NSArray *audioUIDS = [audioNodes valueForKey:@"nodeUID"];
    
    
    [pItem setPropertyList:audioUIDS forType:@"cocoasplit.audio.item"];
    [pboard writeObjects:@[pItem]];
    
    return YES;
}


/*
- (id <NSPasteboardWriting>) tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
    NSPasteboardItem *pItem = [[NSPasteboardItem alloc] init];
    CAMultiAudioNode *audioNode = [self.audioInputsArrayController.arrangedObjects objectAtIndex:row];
    
    [pItem setString:audioNode.nodeUID forType:@"cocoasplit.audio.item"];
    
    return pItem;
}*/



-(IBAction)inputOutlineViewDoubleClick:(NSOutlineView *)outlineView
{
    NSTreeNode *node = [outlineView itemAtRow:outlineView.clickedRow];
    if (node)
    {
        NSObject<CSInputSourceProtocol> *src = node.representedObject;
        [self.activePreviewView openInputConfigWindow:src.uuid];
    }
}


-(void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    if (outlineView == self.inputOutlineView)
    {

        NSTreeNode *node = [outlineView itemAtRow:row];
        NSObject<CSInputSourceProtocol> *src = node.representedObject;
        if (!src.layer || !((InputSource *)src).parentInput)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [outlineView expandItem:nil expandChildren:YES];
            });
        }
    }
}


-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
    
    NSPasteboardItem *pItem = [[NSPasteboardItem alloc] init];

    NSMutableArray *sourceIDS = [NSMutableArray array];
    for (NSTreeNode *node in items)
    {
        NSObject<CSInputSourceProtocol> *iSrc = node.representedObject;
        NSString *iUUID = iSrc.uuid;
        [sourceIDS addObject:iUUID];
        
    }
    [pItem setPropertyList:sourceIDS forType:@"cocoasplit.input.item"];
    [pasteboard writeObjects:@[pItem]];
    return YES;
}

/*
- (id<NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item
{
    NSPasteboardItem *pItem = [[NSPasteboardItem alloc] init];
    NSTreeNode *outlineNode = (NSTreeNode *)item;
    InputSource *itemInput = outlineNode.representedObject;

    [pItem setString:itemInput.uuid forType:@"cocoasplit.input.item"];
    
    return pItem;
}
*/

-(NSString *)primaryTypeForURL:(NSURL *)url
{
    NSString *dType;
    [url getResourceValue:&dType forKey:NSURLTypeIdentifierKey error:nil];
    return dType;
}


-(bool)fileURLIsAudio:(NSURL *)url
{
    NSString *dType = [self primaryTypeForURL:url];
    if (dType && [self.audioFileUTIs containsObject:dType])
    {
        return YES;
    }
    return NO;
}


-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pb = [info draggingPasteboard];
    if ([pb.types containsObject:NSFilenamesPboardType])
    {
        return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pb = [info draggingPasteboard];

    bool retVal = NO;
    for(NSPasteboardItem *item in pb.pasteboardItems)
    {
        
        if ([item.types containsObject:@"public.file-url"])
        {
            NSString *dragPath = [item stringForType:@"public.file-url"];
            if (dragPath)
            {
                NSURL *fileURL = [NSURL URLWithString:dragPath];
                
                if ([self fileURLIsAudio:fileURL])
                {
                    NSString *realPath = [fileURL path];
                    
                    [self.multiAudioEngine createFileInput:realPath];
                    retVal = YES;
                }
            }
        }
        
    }

    return retVal;
}


-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    
    NSTreeNode *nodeItem = (NSTreeNode *)item;
    InputSource *nodeInput = nil;
    if (nodeItem)
    {
        nodeInput = nodeItem.representedObject;
    }


    
    
    NSPasteboard *pb = [info draggingPasteboard];

    
    
    if ([pb.types containsObject:@"cocoasplit.audio.item" ])
    {
        if (item)
        {
            return NSDragOperationNone;
        } else {
            return NSDragOperationMove;
        }
    }
    
    NSArray *draggedUUIDS = [pb propertyListForType:@"cocoasplit.input.item"];
    if (draggedUUIDS && draggedUUIDS.lastObject)
    {
        NSString *draggedUUID = draggedUUIDS.lastObject;
        NSObject<CSInputSourceProtocol> *pdraggedSource = [self.activePreviewView.sourceLayout inputForUUID:draggedUUID];
        
        
        
        if (!pdraggedSource || !pdraggedSource.layer)
        {
            return NSDragOperationNone;
        }
        
        InputSource *draggedSource = (InputSource *)pdraggedSource;
        
        if (nodeInput && nodeInput == draggedSource)
        {
            return NSDragOperationNone;
        }
        
        if (nodeInput && draggedSource.parentInput == nodeInput)
        {
            return NSDragOperationNone;
        }
        
        
        if (draggedSource.parentInput && nodeInput && nodeInput != draggedSource.parentInput)
        {
            return NSDragOperationMove;
        }
        
        
        if (draggedSource.parentInput && !nodeInput)
        {
            return NSDragOperationMove;
        }
        
        
        if (item && index == -1)
        {
            return NSDragOperationMove;
        }
    }
    return NSDragOperationMove;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
    
    NSPasteboard *pb = [info draggingPasteboard];
    
    NSArray *audioUUIDS = [pb propertyListForType:@"cocoasplit.audio.item"];
    if (audioUUIDS)
    {
        for(NSString *aUID in audioUUIDS)
        {
            CAMultiAudioNode *audioNode = [self.multiAudioEngine inputForUUID:aUID];
            if (audioNode)
            {
                CSAudioInputSource *newSource = [[CSAudioInputSource alloc] initWithAudioNode:audioNode];
                [self.activePreviewView addInputSourceWithInput:newSource];

            }
        }
        return YES;
    }

    NSArray *draggedUUIDS = [pb propertyListForType:@"cocoasplit.input.item"];
    
    NSTreeNode *parentNode = (NSTreeNode *)item;
    InputSource *parentSource = nil;
    
    
    NSIndexPath *droppedIdxPath = nil;

    if (parentNode)
    {
        parentSource = parentNode.representedObject;
        droppedIdxPath = [[parentNode indexPath] indexPathByAddingIndex:index];
    } else {
        droppedIdxPath = [NSIndexPath indexPathWithIndex:index];
    }

    
    NSTreeNode *idxNode = nil;
    float newDepth = 1;
    
    if (index == -1)
    {
        newDepth = -FLT_MAX;
    } else {
        idxNode = [self.inputTreeController.arrangedObjects descendantNodeAtIndexPath:droppedIdxPath];
        
    }

    
    if (idxNode)
    {
        NSObject<CSInputSourceProtocol> *iSrc = idxNode.representedObject;
        if (iSrc.layer)
        {
            InputSource *dSrc = (InputSource *)iSrc;
            newDepth = dSrc.depth + 1;
        } else {
            newDepth = -FLT_MAX;
        }
    }

    
    if (draggedUUIDS)
    {

    for (NSString *srcID in draggedUUIDS.reverseObjectEnumerator)
    {
        
        NSObject <CSInputSourceProtocol> *pSrc = [self.activePreviewView.sourceLayout inputForUUID:srcID];
        if (!pSrc || !pSrc.layer)
        {
            continue;
        }
        
        InputSource *iSrc = (InputSource *)pSrc;
        if (iSrc.parentInput)
        {
            if ([draggedUUIDS containsObject:iSrc.parentInput.uuid])
            {
                continue;
            }
        
            [iSrc.parentInput detachInput:iSrc];

        }
        if (parentSource)
        {
            [parentSource attachInput:iSrc];
        }
        iSrc.depth = newDepth++;
    }
    
    
    [self.activePreviewView.sourceLayout generateTopLevelSourceList];
                    return YES;
    }
    
    bool retVal = NO;
    
    
    for(NSPasteboardItem *item in pb.pasteboardItems)
    {
        
        NSString *urlString = [item stringForType:@"public.file-url"];
        if (urlString)
        {
            NSURL *fileURL = [NSURL URLWithString:urlString];
            if ([self fileURLIsAudio:fileURL])
            {
                CSAudioInputSource *audioSrc = [[CSAudioInputSource alloc] initWithPath:fileURL.path];
                [self.activePreviewView addInputSourceWithInput:audioSrc];
                retVal = YES;
                continue;
            }

        }
        
        NSObject<CSInputSourceProtocol> *itemSrc = [self inputSourceForPasteboardItem:item];
        if (itemSrc)
        {
            
            [self.activePreviewView addInputSourceWithInput:itemSrc];
            if (itemSrc.layer)
            {
                InputSource *lsrc = (InputSource *)itemSrc;
                
                [lsrc autoCenter];
                if (parentSource)
                {
                    [parentSource attachInput:lsrc];
                }
                lsrc.depth = newDepth++;
            }
            retVal = YES;
        }
    }

    if (retVal)
    {
        [self.activePreviewView.sourceLayout generateTopLevelSourceList];

    }
    return retVal;
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

    NSRect sbounds;
    switch (clicked) {
        case 0:
            sbounds = sender.bounds;
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
                        NSObject<CSInputSourceProtocol> *realInput = [self.activePreviewView.sourceLayout inputForUUID:uuid];
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



-(void)removeFileAudio:(CAMultiAudioFile *)toDelete
{
    
    [self.multiAudioEngine removeFileInput:toDelete];
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


-(bool)activeRecordingConfirmation:(NSString *)queryString
{
    NSUInteger recording_count = 0;
    
    
    for (CSLayoutRecorder *rec in self.layoutRecorders)
    {
        if (rec.defaultRecordingActive)
        {
            recording_count++;
        }
    }
    
    bool retval;
    
    if (recording_count > 0)
    {
        retval = [self actionConfirmation:queryString infoString:[NSString stringWithFormat:@"There are %lu active recordings", (unsigned long)recording_count]];
    } else {
        retval = YES;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationLayoutAdded object:object userInfo:nil];
}


-(void) removeObjectFromSourceLayoutsAtIndex:(NSUInteger)index
{
    id to_delete = [self.sourceLayouts objectAtIndex:index];
    
    [self.sourceLayouts removeObjectAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationLayoutDeleted object:to_delete userInfo:nil];
}

-(void) insertObject:(CSLayoutSequence *)object inLayoutSequencesAtIndex:(NSUInteger)index
{
    [self.layoutSequences insertObject:object atIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationSequenceAdded object:object userInfo:nil];
}


-(void) removeObjectFromLayoutSequencesAtIndex:(NSUInteger)index
{
    id to_delete = [self.layoutSequences objectAtIndex:index];
    
    [self.layoutSequences removeObjectAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationSequenceDeleted object:to_delete userInfo:nil];
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
        if (![self actionConfirmation:@"Really quit?" infoString:@"There are still active outputs"])
        {
            return NSTerminateCancel;
        }
    }
    
    if (![self activeRecordingConfirmation:@"Really quit?"])
    {
        return NSTerminateCancel;
        
    }

    if (![self pendingStreamConfirmation:@"Quit now?"])
    {

        return NSTerminateCancel;
    }

    [self stopAllRecordings];

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

-(CSLayoutSequence *)getSequenceForName:(NSString *)name
{
    NSUInteger selectedIdx = [self.layoutSequences indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [((CSLayoutSequence *)obj).name isEqualToString:name];
    }];
    
    CSLayoutSequence *foundSequence = nil;
    
    if (selectedIdx != NSNotFound)
    {
        foundSequence = [self.layoutSequences objectAtIndex:selectedIdx];
    }
    
    return foundSequence;
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

-(void)switchToLayout:(SourceLayout *)layout usingLayout:(SourceLayout *)usingLayout
{
    if (!usingLayout)
    {
        return;
    }
    [self applyTransitionSettings:usingLayout];
    
    
    //[usingLayout sequenceThroughLayoutsViaScript:@[layout] withCompletionBlock:nil withExceptionBlock:nil];
    [usingLayout replaceWithSourceLayoutViaScript:layout withCompletionBlock:nil withExceptionBlock:nil];

}


-(void)switchToLayout:(SourceLayout *)layout
{
    [self switchToLayout:layout usingLayout:self.activePreviewView.sourceLayout];
    [self.activePreviewView stopHighlightingAllSources];
}



-(void)mergeLayout:(SourceLayout *)layout usingLayout:(SourceLayout *)usingLayout
{
    if (!usingLayout)
    {
        return;
    }
    
    if ([usingLayout containsLayout:layout])
    {
        return;
    }
    
    [self applyTransitionSettings:usingLayout];

    [usingLayout mergeSourceLayoutViaScript:layout];

}


-(void)removeLayout:(SourceLayout *)layout usingLayout:(SourceLayout *)usingLayout
{
    if (!usingLayout)
    {
        return;
    }
    
    if (![usingLayout containsLayout:layout])
    {
        return;
    }
    
    [self applyTransitionSettings:usingLayout];
    
    [usingLayout removeSourceLayoutViaScript:layout];
    
}

-(void)toggleLayout:(SourceLayout *)layout usingLayout:(SourceLayout *)usingLayout
{
    if (!usingLayout)
    {
        return;
        
    }
    [self applyTransitionSettings:usingLayout];
    
    if ([usingLayout containsLayout:layout])
    {
        [usingLayout removeSourceLayoutViaScript:layout];
    } else {
        [usingLayout mergeSourceLayoutViaScript:layout];
    }

    
}
-(void)toggleLayout:(SourceLayout *)layout
{
    
    [self toggleLayout:layout usingLayout:self.activePreviewView.sourceLayout];
}


-(void)saveToLayout:(SourceLayout *)layout
{
    [self.activePreviewView.sourceLayout saveSourceList];
    layout.savedSourceListData = self.activePreviewView.sourceLayout.savedSourceListData;
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationLayoutSaved object:layout userInfo:nil];
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

-(float)convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:(float)minvalue maxValue:(float)maxvalue
{
    NSUInteger midiValue = command.value;
    
    float midifract = midiValue/127.0;
    
    float valRange = maxvalue - minvalue;
    
    float valFract = valRange * midifract;
    
    return minvalue + valFract;
}


- (NSArray *)commandIdentifiers
{
    NSArray *baseIdentifiers = @[@"GoLive", @"InputNext", @"InputPrevious", @"ActivateLive", @"ActivateStaging", @"ActivateToggle", @"InstantRecord", @"MutePreview", @"MuteStream", @"AudioVolume:Stream", @"AudioVolume:Preview"];
    
     NSMutableArray *layoutIdentifiers = [NSMutableArray array];
    
    for (SourceLayout *layout in self.sourceLayouts)
    {
        [layoutIdentifiers addObject:[NSString stringWithFormat:@"ToggleLayout:%@", layout.name]];
    }
    
    for (SourceLayout *layout in self.sourceLayouts)
    {
        [layoutIdentifiers addObject:[NSString stringWithFormat:@"SwitchToLayout:%@", layout.name]];
    }

    NSMutableArray *audioIdentifiers = [NSMutableArray array];
    
    for (CAMultiAudioNode *node in self.multiAudioEngine.audioInputs)
    {
        [audioIdentifiers addObject:[NSString stringWithFormat:@"MuteAudio:%@", node.name]];
        [audioIdentifiers addObject:[NSString stringWithFormat:@"AudioVolume:%@", node.name]];

    }
    
    
    baseIdentifiers = [baseIdentifiers arrayByAddingObjectsFromArray:layoutIdentifiers];
    baseIdentifiers = [baseIdentifiers arrayByAddingObjectsFromArray:audioIdentifiers];
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
    
    if ([commandID containsString:@"Volume"])
    {
        ret = MIKMIDIResponderTypeAbsoluteSliderOrKnob | MIKMIDIResponderTypeButton;
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


-(void)handleMIDICommandMuteStream:(MIKMIDICommand *)command
{
    self.multiAudioEngine.encodeMixer.muted = !self.multiAudioEngine.encodeMixer.muted;
}

-(void)handleMIDICommandMutePreview:(MIKMIDICommand *)command
{
    self.multiAudioEngine.previewMixer.muted = !self.multiAudioEngine.previewMixer.muted;
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
        NSObject <CSInputSourceProtocol> *input = [currLayout inputForUUID:uuid];
        if (input)
        {
            ret = (InputSource *)input;
        }
    }

    return ret;
}




-(void)handleMIDIVolume:(MIKMIDICommand *)command forNode:(CAMultiAudioNode *)inputNode
{
    float newVal;
    if (command.commandType == MIKMIDICommandTypeNoteOn)
    {
        if (inputNode.volume != 0)
        {
            newVal = 0;
        } else {
            newVal = 1;
        }
    } else {
        newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0 maxValue:1.0];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        inputNode.volume = newVal;
    });
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

    if ([identifier hasPrefix:@"MuteAudio:"])
    {
        NSString *audioName = [identifier substringFromIndex:10];
        CAMultiAudioNode *inputNode = nil;
        for (CAMultiAudioNode *node in self.multiAudioEngine.audioInputs)
        {
            if ([node.name isEqualToString:audioName])
            {
                inputNode = node;
                break;
            }
        }
        
        if (inputNode)
        {
            inputNode.enabled = !inputNode.enabled;
        }
        return;
    }
    
    if ([identifier hasPrefix:@"AudioVolume:"])
    {
        CAMultiAudioNode *audioNode = nil;

        NSString *audioName = [identifier substringFromIndex:12];
        if ([audioName isEqualToString:@"Stream"])
        {
            audioNode = self.multiAudioEngine.encodeMixer;
        } else if ([audioName isEqualToString:@"Preview"]) {
            audioNode = self.multiAudioEngine.previewMixer;
        } else {
            
            for (CAMultiAudioNode *node in self.multiAudioEngine.audioInputs)
            {
                if ([node.name isEqualToString:audioName])
                {
                    audioNode = node;
                    break;
                }
            }
        }
        
        if (audioNode)
        {
            [self handleMIDIVolume:command forNode:audioNode];
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


-(void)setUseTransitions:(bool)useTransitions
{
    _useTransitions = useTransitions;
    
    if (_useTransitions)
    {
        [self showTransitionView:nil];
    } else {
        [self hideTransitionView:nil];
    }
}

-(bool)useTransitions
{
    return _useTransitions;
}



-(IBAction)showTransitionView:(id)sender
{
    
    [NSAnimationContext beginGrouping];
    
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        self.audioConstraint.priority = 500;
        [self changeTransitionView];

    }];
    
    
    self.transitionConfigurationView.animator.hidden = NO;
    self.transitionLabel.animator.hidden = NO;
    self.audioConstraint.animator.constant = _savedAudioConstraintConstant;
    
    [NSAnimationContext endGrouping];

}


-(IBAction)hideTransitionView:(id)sender
{
    _savedAudioConstraintConstant = self.audioConstraint.constant;
    [NSAnimationContext beginGrouping];
    
    self.audioConstraint.animator.priority = 700;
    self.audioConstraint.animator.constant = 8;
    [self.transitionConfigurationView setHidden:YES];
    self.transitionLabel.hidden = YES;

    self.layoutTransitionConfigView.subviews = @[];
    self.layoutTransitionViewController = nil;
    
    [NSAnimationContext endGrouping];


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
    
    if (self.useTransitions && self.layoutTransitionViewController)
    {
        [self.layoutTransitionViewController commitEditing];
        layout.transitionInfo = [self.layoutTransitionViewController.transition copy];
        
    } else {
        [self clearTransitionSettings:layout];
    }
}


-(void)clearTransitionSettings:(SourceLayout *)layout
{
    layout.transitionInfo = nil;
    

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
    
        self.inLayoutTransition = YES;
        [self.selectedLayout replaceWithSourceLayout:self.stagingLayout usingScripts:YES withCompletionBlock:^{
          dispatch_async(dispatch_get_main_queue(), ^{
              self.inLayoutTransition = NO;
          });
            
        }];
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
    stagingView.animator.hidden = YES;
    //[liveView setFrameSize:NSMakeSize(self.canvasSplitView.frame.size.width, liveView.frame.size.height)];
    [self.canvasSplitView.animator adjustSubviews];
    
    
    [self.canvasSplitView.animator display];
    
    if (self.stagingPreviewView.sourceLayout)
    {
        [self.stagingPreviewView.sourceLayout saveSourceList];
        [self.stagingPreviewView.sourceLayout clearSourceList];
    }
    self.livePreviewView.viewOnly = NO;
    self.livePreviewView.midiActive = NO;
    self.activePreviewView = self.livePreviewView;
    self.stagingHidden = YES;
    self.stagingLayout = self.livePreviewView.sourceLayout;
    self.selectedLayout = self.livePreviewView.sourceLayout;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationLayoutModeChanged object:self];

}

-(void) showStagingView
{
    NSView *stagingView = self.canvasSplitView.subviews[0];
    stagingView.animator.hidden = NO;
    if (self.livePreviewView.sourceLayout)
    {
        [self.livePreviewView.sourceLayout saveSourceList];
            self.stagingPreviewView.sourceLayout.savedSourceListData = self.livePreviewView.sourceLayout.savedSourceListData;
            [self.stagingPreviewView.sourceLayout restoreSourceList:nil];
        
        self.stagingLayout = self.stagingPreviewView.sourceLayout;
        self.selectedLayout = self.livePreviewView.sourceLayout;
    }

    [self.canvasSplitView.animator setPosition:_liveFrame.origin.x ofDividerAtIndex:0];
    
    [self.canvasSplitView.animator adjustSubviews];
    
    [self.canvasSplitView.animator display];
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
    /*
    dispatch_async(_preview_queue, ^{
        [self newStagingFrameTimed];
    });*/


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
