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






@implementation CaptureController

@synthesize selectedCompressorType = _selectedCompressorType;
@synthesize selectedLayout = _selectedLayout;
@synthesize stagingLayout = _stagingLayout;
@synthesize audioSamplerate  = _audioSamplerate;
@synthesize transitionName = _transitionName;



-(IBAction)mainDeleteLayoutClicked:(id)sender
{
    
    NSInteger selectedIdx = self.mainSourceLayoutTableView.selectedRow;
    if (selectedIdx != -1)
    {
        [self deleteLayout:selectedIdx];
        [self layoutTableSelected:self.mainSourceLayoutTableView];
    }
}

-(IBAction)stagingDeleteLayoutClicked:(id)sender
{

    NSInteger selectedIdx = self.stagingSourceLayoutTableView.selectedRow;
    if (selectedIdx != -1)
    {
        [self deleteLayout:selectedIdx];
        [self layoutTableSelected:self.stagingSourceLayoutTableView];
    }
}

-(IBAction)stagingCopyLayoutClicked:(id)sender
{
    [self cloneSelectedSourceLayout:self.stagingSourceLayoutTableView];
}

- (IBAction)stagingAnimationSelected:(id)sender {
}


-(IBAction)mainCopyLayoutClicked:(id)sender
{
    [self cloneSelectedSourceLayout:self.mainSourceLayoutTableView];
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


- (IBAction)openLayoutPopover:(NSButton *)sender
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
        
        vc.controller = self;
        
        _layoutpopOver.contentViewController = vc;
        _layoutpopOver.delegate = vc;
        vc.popover = _layoutpopOver;
        
    }
    
    vc.sourceLayout = [[SourceLayout alloc] init];

    [_layoutpopOver showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMinYEdge];
    
}


- (void)deleteLayout:(NSInteger)deleteIdx
{
    SourceLayout *toDelete = [self.sourceLayoutsArrayController.arrangedObjects objectAtIndex:deleteIdx];
    
    if (toDelete)
    {
        if ([self actionConfirmation:[NSString stringWithFormat:@"Really delete %@?", toDelete.name] infoString:nil])
        {
            
            
            toDelete.isActive = NO;
         
            [self.sourceLayoutsArrayController removeObjectAtArrangedObjectIndex:deleteIdx];
            
            if (self.selectedLayout == toDelete)
            {
                self.selectedLayout = nil;
            }
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
    
    if (tableView.tag == 0)
    {
        layout = self.stagingPreviewView.sourceLayout;
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
        
        vc.controller = self;
        
        _animatepopOver.contentViewController = vc;
        _animatepopOver.delegate = vc;
        vc.popover = _animatepopOver;
        
    }
    
    if (sender.tag == 1)
    {
        vc.sourceLayout = self.stagingPreviewView.sourceLayout;
    } else {
        vc.sourceLayout = self.livePreviewView.sourceLayout;
    }
    
    
    [_animatepopOver showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMinYEdge];
    
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
            
            [self deleteCompressorForName:deleteKey];
        }
    }
    
    [self closeCompressPanel];
}


-(void)deleteCompressorForName:(NSString *)name
{
    id to_delete = self.compressors[name];
    
    [self willChangeValueForKey:@"compressors"];
    [self.compressors removeObjectForKey:name];
    [self didChangeValueForKey:@"compressors"];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorDeleted object:to_delete userInfo:nil];
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
        

        
        [NSApp beginSheet:self.compressPanel modalForWindow:[NSApplication sharedApplication].mainWindow modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        
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

    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationCompressorAdded object:newCompressor userInfo:nil];
    
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
        [NSApp beginSheet:self.audioMixerPanel modalForWindow:[NSApplication sharedApplication].mainWindow modalDelegate:self didEndSelector:NULL contextInfo:NULL];
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
        
        [NSApp beginSheet:self.advancedVideoPanel modalForWindow:[NSApplication sharedApplication].mainWindow modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    
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
        [NSApp beginSheet:self.streamServiceConfWindow modalForWindow:[NSApplication sharedApplication].mainWindow modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    }
    
}


-(IBAction)closeCreateSheet:(id)sender
{
    
    
    [self.streamServicePluginViewController.view removeFromSuperview];
    
    
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


-(void) createCGLContext
{
    NSOpenGLPixelFormatAttribute glAttributes[] = {
        
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAAccelerated,
        //NSOpenGLPFAAllowOfflineRenderers,
        NSOpenGLPFADepthSize, 32,
        (NSOpenGLPixelFormatAttribute) 0,0,
        (NSOpenGLPixelFormatAttribute) 0
        
    };
    if (self.renderOnIntegratedGPU)
    {
        NSLog(@"RENDERING ON INTELHD!");
        
        glAttributes[5] = NSOpenGLPFARendererID;
        glAttributes[6] = kCGLRendererIntelHDID;
    }
    
    
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



static CVReturn displayLinkRender(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime,
                                  CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    
    
    
    CaptureController *myself;
    
    
    myself = (__bridge CaptureController *)displayLinkContext;
    
   
    
    
    

    if (!myself.stagingPreviewView.hiddenOrHasHiddenAncestor)
    {
        //[CATransaction commit];

        [CATransaction begin];
        [myself.stagingPreviewView cvrender];
        [CATransaction commit];
        
    }
    
    if (!myself.livePreviewView.hiddenOrHasHiddenAncestor)
    {
        [myself.livePreviewView cvrender];
    }
    
    
    [CATransaction commit];
    
    return kCVReturnSuccess;
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
                
                
                if (newLayout.animationSaveData)
                {
                    for (NSString *moduleFile in newLayout.animationSaveData)
                    {
                        NSString *moduleSource = newLayout.animationSaveData[moduleFile];
                        NSString *modulePath = [csAnimationDir stringByAppendingPathComponent:moduleFile];
                        
                        bool fileExists = [[NSFileManager defaultManager] fileExistsAtPath:modulePath];
                        if (fileExists)
                        {
                            continue;
                        }
                        
                        [moduleSource writeToFile:moduleSource atomically:YES encoding:NSUTF8StringEncoding error:nil];
                    }
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
    } else if (layout == self.stagingLayout) {
        useLayout = self.stagingPreviewView.sourceLayout;
    }

    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSURL *saveFile = [panel URL];
            [useLayout saveSourceList];
            [useLayout saveAnimationSource];
            
            NSLog(@"SAVING LAYOUT %@ TO %@", useLayout, saveFile.absoluteString);
            
            [NSKeyedArchiver archiveRootObject:useLayout toFile:saveFile.path];
            
            useLayout.animationSaveData = nil;
        }
    }];
}


-(id) init
{
   if (self = [super init])
   {
       
       self.transitionDirections = @[kCATransitionFromTop, kCATransitionFromRight, kCATransitionFromBottom, kCATransitionFromLeft];

       
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
       
       
       //self.audioCaptureSession = [[AVFAudioCapture alloc] init];
       //[self.audioCaptureSession setAudioDelegate:self];
       
       
       
       //self.audioCaptureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
       
       
       mach_timebase_info(&_mach_timebase);
       

       
       int dispatch_strict_flag = 1;
       
       if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8)
       {
           dispatch_strict_flag = 0;
       }
       
       /*
       _dispatch_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, dispatch_strict_flag, _main_capture_queue);
       
       dispatch_source_set_timer(_dispatch_timer, DISPATCH_TIME_NOW, _frame_interval, 0);
       
       dispatch_source_set_event_handler(_dispatch_timer, ^{[self newFrameDispatched];});
       
       dispatch_resume(_dispatch_timer);
       */
       
       _audio_statistics_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
       
       dispatch_source_set_timer(_audio_statistics_timer, DISPATCH_TIME_NOW, 0.10*NSEC_PER_SEC, 0);

       dispatch_source_set_event_handler(_audio_statistics_timer, ^{
           [self.multiAudioEngine updateStatistics];
       });
       dispatch_resume(_audio_statistics_timer);

       

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
       

       self.extraPlugins = [NSMutableDictionary dictionary];
       
       [self buildScreensInfo:nil];
       
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buildScreensInfo:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
       
       
       
       CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
       CVDisplayLinkSetOutputCallback(_displayLink, &displayLinkRender, (__bridge void *)self);
       
       CVDisplayLinkStart(_displayLink);

       
       
   }
    
    return self;
    
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



+(CSAnimationRunnerObj *) sharedAnimationObj
{
    static CSAnimationRunnerObj *sharedAnimationObj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *animationPluginPath = [[NSBundle mainBundle] pathForResource:@"CSAnimationRunner" ofType:@"plugin"];
        NSBundle *animationBundle = [NSBundle bundleWithPath:animationPluginPath];
        Class animationClass = [animationBundle classNamed:@"CSAnimationRunnerObj"];
        
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


-(NSArray *)destinationTypes
{
    
    NSMutableDictionary *servicePlugins = [[CSPluginLoader sharedPluginLoader] streamServicePlugins];

    return servicePlugins.allKeys;
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
    
    NSString *saveFile = [saveFolder stringByAppendingPathComponent:@"CocoaSplit-CA.settings"];
    
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
    
    NSString *saveFile = @"CocoaSplit-CA.settings";
    
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
    
    [saveRoot setValue:self.transitionName forKey:@"transitionName"];
    [saveRoot setValue:self.transitionDirection forKey:@"transitionDirection"];
    [saveRoot setValue:[NSNumber numberWithFloat:self.transitionDuration] forKey:@"transitionDuration"];
    
    [saveRoot setValue: [NSNumber numberWithInt:self.captureWidth] forKey:@"captureWidth"];
    [saveRoot setValue: [NSNumber numberWithInt:self.captureHeight] forKey:@"captureHeight"];
    [saveRoot setValue: [NSNumber numberWithDouble:self.captureFPS] forKey:@"captureFPS"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioBitrate] forKey:@"audioBitrate"];
    [saveRoot setValue: [NSNumber numberWithInt:self.audioSamplerate] forKey:@"audioSamplerate"];
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

    [saveRoot setValue:[NSNumber numberWithBool:self.renderOnIntegratedGPU] forKey:@"renderOnIntegratedGPU"];
    
    
    NSUInteger compressoridx =    [self.compressController selectionIndex];

    
    [saveRoot setValue:[NSNumber numberWithUnsignedInteger:compressoridx] forKey:@"selectedCompressor"];\
    
    //[saveRoot setValue:self.sourceList forKeyPath:@"sourceList"];
    
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
    
    [NSKeyedArchiver archiveRootObject:saveRoot toFile:path];
    [self saveMIDI];
    
}


-(void) loadSettings
{
    
    //all color panels allow opacity
    [NSColorPanel sharedColorPanel].showsAlpha = YES;
    [NSColor setIgnoresAlpha:NO];
    
    NSString *path = [self restoreFilePath];
    NSDictionary *defaultValues = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]];
    
    NSDictionary *savedValues = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    
    NSMutableDictionary *saveRoot = [[NSMutableDictionary alloc] init];
    

    [saveRoot addEntriesFromDictionary:defaultValues];
    [saveRoot addEntriesFromDictionary:savedValues];
    

    
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

    
    self.renderOnIntegratedGPU = [[saveRoot valueForKey:@"renderOnIntegratedGPU"] boolValue];

    [self createCGLContext];
    _cictx = [CIContext contextWithCGLContext:_cgl_ctx pixelFormat:CGLGetPixelFormat(_cgl_ctx) colorSpace:nil options:@{kCIContextWorkingColorSpace: [NSNull null]}];
    
    mainThread = [[NSThread alloc] initWithTarget:self selector:@selector(newFrameTimed) object:nil];
    [mainThread start];
    
    
    
    //dispatch_async(_main_capture_queue, ^{[self newFrameTimed];});

    self.stagingPreviewView.controller = self;
    self.livePreviewView.controller = self;
    LayoutRenderer *stagingRender = [[LayoutRenderer alloc] init];
    stagingRender.isLiveRenderer = NO;
    self.stagingPreviewView.layoutRenderer = stagingRender;
    
    LayoutRenderer *liveRender = [[LayoutRenderer alloc] init];
    liveRender.isLiveRenderer = YES;
    self.livePreviewView.layoutRenderer = liveRender;

    self.livePreviewView.viewOnly = YES;
    
    
    self.sourceLayouts = [saveRoot valueForKey:@"sourceLayouts"];
    
    if (!self.sourceLayouts)
    {
        self.sourceLayouts = [[NSMutableArray alloc] init];
        SourceLayout *newLayout = [[SourceLayout alloc] init];
        newLayout.name = @"default";
        [[self mutableArrayValueForKey:@"sourceLayouts" ] addObject:newLayout];
        self.selectedLayout = newLayout;
        self.stagingLayout = newLayout;
        newLayout.isActive = YES;
        
    } else {
    
        self.selectedLayout = [saveRoot valueForKey:@"selectedLayout"];
        self.stagingLayout  = [saveRoot valueForKey:@"stagingLayout"];
    }
    


    
    self.extraPluginsSaveData = [saveRoot valueForKey:@"extraPluginsSaveData"];
    [self migrateDefaultCompressor:saveRoot];
    [self buildExtrasMenu];
    
    BOOL stagingHidden = [[saveRoot valueForKeyPath:@"stagingHidden"] boolValue];
    
    if (stagingHidden)
    {
        [self hideStagingView];
    }

    self.multiAudioEngine = [saveRoot valueForKey:@"multiAudioEngine"];
    if (!self.multiAudioEngine)
    {
        self.multiAudioEngine = [[CAMultiAudioEngine alloc] init];
    }


    self.extraPluginsSaveData = nil;
    
    
    

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
    
    self.stagingCtx.layoutRenderer.transitionName = self.transitionName;
    self.stagingCtx.layoutRenderer.transitionDirection = self.transitionDirection;
    self.stagingCtx.layoutRenderer.transitionDuration = self.transitionDuration;
    self.stagingCtx.layoutRenderer.transitionFilter = self.transitionFilter;
    
    
    

    [self stagingSave:self];
    
    _stagingLayout = stagingLayout;
    
    /*
    if (stagingLayout.isActive)
    {
        [stagingLayout saveSourceList];
    }
     
     */
    
    
    SourceLayout *previewCopy = stagingLayout.copy;
    [previewCopy restoreSourceList];

    self.stagingCtx.sourceLayout = previewCopy;
    if (self.sourceLayoutsArrayController)
    {
        NSUInteger sidx = [self.sourceLayoutsArrayController.arrangedObjects indexOfObject:stagingLayout];
        if ((sidx != NSNotFound) && self.stagingSourceLayoutTableView)
        {
            [self.stagingSourceLayoutTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:sidx] byExtendingSelection:NO];
            
        }
    }


}


-(SourceLayout *)stagingLayout
{
    return _stagingLayout;
}


-(void)setSelectedLayout:(SourceLayout *)selectedLayout
{
    
    
    
    self.previewCtx.layoutRenderer.transitionName = self.transitionName;
    self.previewCtx.layoutRenderer.transitionDirection = self.transitionDirection;
    self.previewCtx.layoutRenderer.transitionDuration = self.transitionDuration;
    self.previewCtx.layoutRenderer.transitionFilter = self.transitionFilter;
    

    if (selectedLayout == _selectedLayout)
    {
        return;
    }
    
    _selectedLayout = selectedLayout;
    selectedLayout.ciCtx = _cictx;
    selectedLayout.isActive = YES;

    [self setupFrameTimer:selectedLayout.frameRate];
    
    
    self.previewCtx.sourceLayout = selectedLayout;
    //currentLayout.isActive = NO;
    if (self.sourceLayoutsArrayController)
    {
        NSUInteger sidx = [self.sourceLayoutsArrayController.arrangedObjects indexOfObject:selectedLayout];
        if ((sidx != NSNotFound) && self.mainSourceLayoutTableView)
        {
            [self.mainSourceLayoutTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:sidx] byExtendingSelection:NO];
            
        }
    }
    
}

-(SourceLayout *)selectedLayout
{
    return _selectedLayout;
}


-(void) setTransitionName:(NSString *)transitionName
{
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



- (IBAction)addStreamingService:(id)sender {
    
    
    OutputDestination *newDest;
    
    [self.streamServicePluginViewController commitEditing];
    
    NSString *destination = [self.streamServiceObject getServiceDestination];
    
    newDest = [[OutputDestination alloc] initWithType:[self.streamServiceObject.class label]];
    newDest.destination = destination;
    newDest.settingsController = self;

    [self insertObject:newDest inCaptureDestinationsAtIndex:self.captureDestinations.count];
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


-(bool) startStream
{
    
    
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
    
    
    CSAacEncoder *audioEnc = [[CSAacEncoder alloc] init];
    audioEnc.encodedReceiver = self;
    audioEnc.sampleRate = self.audioSamplerate;
    audioEnc.bitRate = self.audioBitrate*1000;
    
    self.multiAudioEngine.encoder = audioEnc;

    
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
    
    NSLog(@"SETTING UP FRAME TIMER %f", framerate);
    
    if (framerate && framerate > 0)
    {
        _frame_interval = (1.0/framerate);
    } else {
        _frame_interval = 1.0/60.0;
    }
    
    self.captureFPS = framerate;
    
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
        self.audioBitrate = (int)[cmdargs integerForKey:@"audioBitrate"];
    }
    
    if ([cmdargs objectForKey:@"audioSamplerate"])
    {
        self.audioSamplerate = (int)[cmdargs integerForKey:@"audioSamplerate"];
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
    
    //[self.audioCaptureSession stopAudioCompression];
    self.multiAudioEngine.encoder = nil;
    
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
        
        
        
        if ([self startStream] == YES)
        {
            self.selectedTabIndex = 4;
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
    
    CMTime orig_pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    

    
    if (CMTIME_COMPARE_INLINE(_firstAudioTime, ==, kCMTimeZero))
    {
        
        _firstAudioTime = orig_pts;
        return;
    }
    
    CMTime real_pts = CMTimeSubtract(orig_pts, _firstAudioTime);
    CMTime adjust_pts = CMTimeMakeWithSeconds(self.audio_adjust, orig_pts.timescale);
    CMTime pts = CMTimeAdd(real_pts, adjust_pts);
    

    
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
    while ([self mach_time_seconds] < target_time)
    {
        int32_t useconds = (target_time - [self mach_time_seconds]) * 0.25e6;
        if (useconds > 0)
        {
            usleep(useconds);
        }
    }
    
    /*
    double mach_duration = target_time - mach_now;
    double mach_wait_time = mach_now + mach_duration/2.0;
    
    mach_wait_until(mach_wait_time*NSEC_PER_SEC);
    
    
    while ([self mach_time_seconds] < target_time)
    {
        usleep(500);
        
            //wheeeeeeeeeeeee
    }
     
     */
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
        
        @autoreleasepool {
            
        
        
        
        //_frame_time = nowTime;//startTime;
        double nowTime = [self mach_time_seconds];
        
        lastLoopTime = nowTime;
        
        if (![self sleepUntil:(startTime += _frame_interval)])
        {
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

/*
-(NSArray *)sourceListOrdered
{
    NSArray *listCopy = [self.selectedLayout.sourceList sortedArrayUsingDescriptors:@[_sourceDepthSorter, _sourceUUIDSorter]];
    return listCopy;
}
 */



-(InputSource *)findSource:(NSPoint)forPoint
{
    
    return [self.selectedLayout findSource:forPoint deepParent:YES];
}


/*
-(NSString *)getCurrentRendererName
{
    cl_int error;
    
    CGLShareGroupObj share_group = CGLGetShareGroup(_cgl_ctx);
    
    cl_context_properties properties[] = {CL_CONTEXT_PROPERTY_USE_CGL_SHAREGROUP_APPLE, (intptr_t)share_group, 0};
    
    cl_context context = clCreateContext(properties, 0, NULL, 0, 0, &error);
    cl_device_id renderer;
    clGetGLContextInfoAPPLE(context, _cgl_ctx, CL_CGL_DEVICE_FOR_CURRENT_VIRTUAL_SCREEN_APPLE, sizeof(renderer), &renderer, NULL);
    
    char buf[128];
    
    clGetDeviceInfo(renderer, CL_DEVICE_NAME, 128, buf, NULL);
    
    return [NSString stringWithUTF8String:buf];
}

*/
-(CVPixelBufferRef) currentFrame
{
    return [self.previewCtx.layoutRenderer currentFrame];
}


-(void) newFrame
{

        CVPixelBufferRef newFrame;
    
        //if (self.videoCaptureSession)
        {
            
            double nfstart = [self mach_time_seconds];
            
            [CATransaction begin];
            newFrame = [self.previewCtx.layoutRenderer currentImg];
            [CATransaction commit];
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
    
    
    
    _frameCount++;
    _lastFrameTime = _frame_time;
    
    
    pts = CMTimeMake(ptsTime*1000000, 1000000);

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

- (IBAction)layoutTableSelected:(NSTableView *)sender
{
    
    NSInteger selectedRow = [sender selectedRow];
    
    NSInteger selectedCount = sender.numberOfSelectedRows;
    
    if (selectedRow != -1)
    {
        SourceLayout *selected = [self.sourceLayoutsArrayController.arrangedObjects objectAtIndex:selectedRow];
        if (selected)
        {
            if (sender == self.mainSourceLayoutTableView)
            {
                if (selectedCount > 1)
                {
                    if (!self.livePreviewView.viewOnly)
                    {
                        [self.selectedLayout mergeSourceListData:selected.savedSourceListData];
                    }
                } else {
                    self.selectedLayout = selected;
                }
            } else {
                if (selectedCount > 1)
                {
                    [self.stagingPreviewView.sourceLayout mergeSourceListData:selected.savedSourceListData];
                } else {
                    self.stagingLayout = selected;
                }
            }
            if (selectedCount > 1)
            {
                [sender deselectRow:selectedRow];
            }
        }
    }
    
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


- (NSArray *)commandIdentifiers
{
    NSArray *baseIdentfiers = @[@"GoLive", @"StagingRevert", @"LiveRevert"];
    NSMutableArray *layoutIdentifiers = [NSMutableArray array];
    
    for (SourceLayout *layout in self.sourceLayouts)
    {
        [layoutIdentifiers addObject:[NSString stringWithFormat:@"SwitchStaging:%@", layout.name]];
        [layoutIdentifiers addObject:[NSString stringWithFormat:@"SwitchLive:%@", layout.name]];
    }
    
    return [baseIdentfiers arrayByAddingObjectsFromArray:layoutIdentifiers];
}

- (MIKMIDIResponderType)MIDIResponderTypeForCommandIdentifier:(NSString *)commandID
{
    MIKMIDIResponderType ret = MIKMIDIResponderTypeButton;
    
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

-(void)handleMIDICommand:(MIKMIDICommand *)command forIdentifier:(NSString *)identifier
{
    
    __weak CaptureController *weakSelf = self;

    if ([identifier hasPrefix:@"SwitchStaging:"])
    {
        NSString *layoutName = [identifier substringFromIndex:14];
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
                weakSelf.stagingLayout = layout;
            });

        }
        return;
    }

    
    if ([identifier hasPrefix:@"SwitchLive:"])
    {
        NSString *layoutName = [identifier substringFromIndex:11];
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
                weakSelf.selectedLayout = layout;
            });
            
        }
        return;
    }

    
    if ([identifier isEqualToString:@"GoLive"])
    {
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf stagingGoLive:nil];
        });
    } else if ([identifier isEqualToString:@"StagingRevert"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf stagingRevert:nil];
        });
    }
}


-(void)saveMIDI
{
    MIKMIDIMappingManager *manager = [MIKMIDIMappingManager sharedManager];
    
    for (CSMidiWrapper *wrap in self.midiMapGenerators)
    {
        [manager addUserMappingsObject:wrap.deviceMapping];
    }
    
    //[manager saveMappingsToDisk];
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
        self.midiDeviceMappings[wrap.device.name] = wrap;
        [wrap connect];

    }
    
    [self loadMIDI];
    [NSApp registerMIDIResponder:self];
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

- (IBAction)stagingGoLive:(id)sender
{
    
    self.previewCtx.layoutRenderer.transitionName = self.transitionName;
    self.previewCtx.layoutRenderer.transitionDirection = self.transitionDirection;
    self.previewCtx.layoutRenderer.transitionDuration = self.transitionDuration;
    self.previewCtx.layoutRenderer.transitionFilter = self.transitionFilter;
    

    if (self.stagingLayout && self.stagingCtx.sourceLayout)
    {
        [self stagingSave:sender];
        
        if (self.selectedLayout != self.stagingLayout)
        {
            self.selectedLayout = self.stagingLayout;
        } else {
            if (!self.stagingLayout.inTransition)
            {
                [self.stagingLayout restoreSourceListForSelfGoLive];
            
                [self setupFrameTimer:self.selectedLayout.frameRate];
            }

        }
    }
}

-(IBAction)stagingSave:(id)sender
{
    if (self.stagingLayout && self.stagingCtx.sourceLayout)
    {
        [self.stagingCtx.sourceLayout saveSourceList];
        self.stagingLayout.savedSourceListData = self.stagingCtx.sourceLayout.savedSourceListData;
        
        self.stagingLayout.frameRate = self.stagingCtx.sourceLayout.frameRate;
        self.stagingLayout.canvas_width = self.stagingCtx.sourceLayout.canvas_width;
        self.stagingLayout.canvas_height = self.stagingCtx.sourceLayout.canvas_height;
    }
}

-(IBAction)stagingRevert:(id)sender
{
    if (self.stagingPreviewView.sourceLayout)
    {
        [self.stagingPreviewView.sourceLayout restoreSourceList];
    }
}

-(IBAction)mainRevert:(id)sender
{
    if (self.livePreviewView.sourceLayout)
    {
        [self.livePreviewView.sourceLayout restoreSourceList];
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
    self.stagingControls.hidden = YES;
    self.goLiveControls.hidden = YES;
    self.livePreviewView.viewOnly = NO;
    
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
            [self.stagingPreviewView.sourceLayout restoreSourceList];
        }
    }

    [self.canvasSplitView setPosition:_liveFrame.origin.x ofDividerAtIndex:0];
    
    [self.canvasSplitView adjustSubviews];
    
    [self.canvasSplitView display];
    self.stagingControls.hidden = NO;
    self.goLiveControls.hidden = NO;
    self.livePreviewView.viewOnly = YES;

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


@end
