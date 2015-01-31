//
//  DesktopCaptureViewController.m
//  CocoaSplit
//
//  Created by Zakk on 8/28/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "DesktopCaptureViewController.h"
#import "CSOverlayView.h"
#import "CSOverlayWindow.h"


@interface DesktopCaptureViewController ()

@end

@implementation DesktopCaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}


-(NSScreen *)findScreeenForDisplayID:(NSNumber *)displayID
{
    
    NSArray *screens = [NSScreen screens];
    
    for(NSScreen *screen in screens)
    {
        NSDictionary *screenDescr = [screen deviceDescription];
        NSNumber *screenID = screenDescr[@"NSScreenNumber"];
        if ([displayID isEqualToNumber:screenID])
        {
            return screen;
        }
    }
    
    return nil;
}


-(void)openScreenCropWindow:(CSAbstractCaptureDevice *)captureDevice
{
    
    
    NSScreen *cropScreen = [self findScreeenForDisplayID:captureDevice.captureDevice];
    
    
    
    [self.cropSelectionWindow setOpaque:NO];
    [self.cropSelectionWindow setLevel:CGShieldingWindowLevel()];
    
    [self.cropSelectionWindow setIgnoresMouseEvents:NO];
    
    [self.cropSelectionWindow setBackgroundColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.0]];
    
    float screenX = NSMidX(cropScreen.frame) - self.cropSelectionWindow.frame.size.width/2;
    float screenY = NSMidY(cropScreen.frame) - self.cropSelectionWindow.frame.size.height/2;
    
    
    [self.cropSelectionWindow setFrameOrigin:NSMakePoint(screenX, screenY)];
    [self.cropSelectionWindow orderFrontRegardless];
    
    
}


-(void)cropRegionSelected
{
    if (!self.cropSelectionWindow)
    {
        return;
    }
    
    CSOverlayView *cropView = (CSOverlayView *)self.cropSelectionWindow.contentView;
    NSScreen *onScreen = self.cropSelectionWindow.screen;
    
    NSRect viewRect = cropView.bounds;
    NSRect screenFrame = onScreen.frame;
    
    
    
    NSRect windowRect = [cropView convertRect:viewRect fromView:cropView];
    NSRect viewBounds = [self.cropSelectionWindow convertRectToScreen:windowRect];
    
    
    
    
    
    //Clamp to screen bounds if we're outside of them
    
    if (viewBounds.origin.x < screenFrame.origin.x)
    {
        viewBounds.origin.x = screenFrame.origin.x;
    }
    
    if (viewBounds.origin.y < screenFrame.origin.y)
    {
        viewBounds.origin.y  = screenFrame.origin.y;
    }
    
    if ((viewBounds.origin.x+NSWidth(viewBounds)) > (screenFrame.origin.x + NSWidth(screenFrame)))
    {
        viewBounds.size.width = (screenFrame.origin.x+NSWidth(screenFrame))-viewBounds.origin.x;
    }
    
    if ((viewBounds.origin.y+NSHeight(viewBounds)) > (screenFrame.origin.y + NSHeight(screenFrame)))
    {
        viewBounds.size.height = (screenFrame.origin.y+NSHeight(screenFrame))-viewBounds.origin.y;
    }
    
    
    //adjust origin to screen relative point
    viewBounds.origin.x = fabs(fabs(viewBounds.origin.x) - fabs(screenFrame.origin.x));
    viewBounds.origin.y = fabs(fabs(viewBounds.origin.y) - fabs(screenFrame.origin.y) );
    
    
    
    
    //adjust for CGDisplay's origin being top left
    
    
    viewBounds.origin.y = -(viewBounds.origin.y - NSHeight(screenFrame)) - NSHeight(viewBounds);
    
    
    
    id vidInput = self.captureObj;
    
    
    
    
    [vidInput setValue:[NSNumber numberWithInt:(int)viewBounds.origin.x] forKeyPath:@"x_origin"];
    [vidInput setValue:[NSNumber numberWithInt:(int)viewBounds.origin.y] forKeyPath:@"y_origin"];
    
    [vidInput setValue:[NSNumber numberWithInt:(int)NSHeight(viewBounds)] forKeyPath:@"region_height"];
    [vidInput setValue:[NSNumber numberWithInt:(int)NSWidth(viewBounds)] forKeyPath:@"region_width"];
    
    
    
    [self.cropSelectionWindow close];
}


@end
