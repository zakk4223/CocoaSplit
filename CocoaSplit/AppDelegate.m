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
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    
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


    
    
    

    [_window setReleasedWhenClosed:NO];
    
    
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebarSmartFolder.icns"];
    
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
