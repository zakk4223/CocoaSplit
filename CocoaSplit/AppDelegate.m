//
//  AppDelegate.m
//  H264Streamer
//
//  Created by Zakk on 9/2/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "AppDelegate.h"
#import "JSExports.h"

#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "CSLayoutTransition.h"



@implementation AppDelegate




-(void)addProtocolsForClass:(Class)class
{
    Class tmpClass = class;
    
    while (tmpClass)
    {
        NSString *className = NSStringFromClass(tmpClass);
        NSString *protoName = [NSString stringWithFormat:@"%@JSExport", className];
        
        Protocol *proto = NSProtocolFromString(protoName);
        if (proto)
        {
            class_addProtocol(class, proto);
        }
        
        unsigned int protoCnt;
        Protocol *__unsafe_unretained *classProtos = class_copyProtocolList(tmpClass, &protoCnt);
        if (classProtos)
        {
            for (int p = 0; p < protoCnt; p++)
            {
                Protocol *aProto = classProtos[p];
                NSString *aProtoName = NSStringFromProtocol(aProto);
                NSString *aExportName = [NSString stringWithFormat:@"%@JSExport", aProtoName];
                Protocol *exProto = NSProtocolFromString(aExportName);
                if (exProto)
                {
                    class_addProtocol(class, exProto);
                }
            }
            free(classProtos);
        }
        
        tmpClass = class_getSuperclass(tmpClass);
    }
}

-(void)applicationWillFinishLaunching:(NSNotification *)notification
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:@"_NSWindowWillBecomeVisible" object:nil];
    
    _notificationController = [[CSUserNotificationController alloc] init];
    
    [self addProtocolsForClass:[CATransaction class]];
    [self addProtocolsForClass:[CALayer class]];
    [self addProtocolsForClass:[CAAnimation class]];
    [self addProtocolsForClass:[CAPropertyAnimation class]];
    [self addProtocolsForClass:[CABasicAnimation class]];
    [self addProtocolsForClass:[CAKeyframeAnimation class]];
    [self addProtocolsForClass:[CATransition class]];
    [self addProtocolsForClass:[CSInputLayer class]];
    [self addProtocolsForClass:[NSValue class]];
    [self addProtocolsForClass:[CIFilter class]];
    
    [self addProtocolsForClass:[CSLayoutTransition class]];
    
    
    
    
    
    self.captureController = [CaptureController sharedCaptureController];

    
    [_window setReleasedWhenClosed:NO];
    
    
    //NSImage *img = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebarSmartFolder.icns"];
    
    NSImage *img = [NSImage imageNamed:@"NSScriptTemplate"];
    NSImage *useimg = [[NSImage alloc] initWithSize:NSMakeSize(64,64)];
    [useimg addRepresentation:img.representations[0]];
    
    NSImage *altImg = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebarMoviesFolder.icns"];
    
    self.layoutSequenceButton.image = useimg;
    self.layoutSequenceButton.alternateImage = altImg;
    
    [[NSBundle mainBundle] loadNibNamed:@"LogWindow" owner:self.captureController topLevelObjects:nil];
    
    /*
     dispatch_async(dispatch_get_main_queue(), ^{
     [self.captureController setupLogging];
     });*/
    
    //Force loading of python stuff now
    
    /*
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
     [CaptureController sharedAnimationObj];
     });
     */
    
    [self.captureController loadSettings];
    //self.captureController.audioConstraint.constant = 0;
    
    // Insert code here to initialize your application
    
    
    //_window.appearance = [self getAppearance];
    
    
}

-(NSAppearance *)getAppearance
{
    NSAppearance *ret = nil;
    NSString *contAppearance = self.captureController.appearance;
    
    if ([contAppearance isEqualToString:CSAppearanceSystem])
    {
        ret = nil;
        
    } else if ([contAppearance isEqualToString:CSAppearanceLight]) {
        ret = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    } else if ([contAppearance isEqualToString:CSAppearanceDark]) {
        if(@available(macOS 10.14, *))
        {
            ret = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
        } else {
            ret = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        }
    } else {
        ret = nil;
    }
    return ret;
}


-(void)handleNotification:(NSNotification *)notification
{
    

    NSWindow *window = notification.object;
    if (@available(macOS 10.14, *))
    {
        return;
    } else {
        window.appearance = [self getAppearance];
    }
}



-(void)changeAppearance
{
    NSAppearance *useAppearance = [self getAppearance];
    if (@available(macOS 10.14, *))
    {
        NSApp.appearance = useAppearance;
    } else {
        for (NSWindow *win in [NSApplication sharedApplication].windows)
        {
            win.appearance = useAppearance;
        }
        //NSApp.appearance = useAppearance;
    }
    [CaptureController.sharedCaptureController postNotification:CSNotificationThemeChanged forObject:self];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [CaptureController.sharedCaptureController postNotification:CSNotificationLaunchCompleted forObject:self];
}



-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (self.captureController)
    {
        return [self.captureController applicationShouldTerminate:sender];
    }
    
    return NSTerminateNow;
}


-(void) applicationWillTerminate: (NSNotification *)notification
{
    
    
    [self.captureController saveSettings];
    
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    [_window setIsVisible:YES];
    return YES;
}



@end
