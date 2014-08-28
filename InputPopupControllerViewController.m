//
//  InputPopupControllerViewController.m
//  CocoaSplit
//
//  Created by Zakk on 7/26/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "InputPopupControllerViewController.h"
#import "InputSource.h"
#import "CSOverlayView.h"

@interface InputPopupControllerViewController ()

@end

@implementation InputPopupControllerViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}




-(NSWindow *)detachableWindowForPopover:(NSPopover *)popover
{
    //InputPopupControllerViewController *newViewController = [[InputPopupControllerViewController alloc] initWithNibName:@"InputPopupControllerViewController" bundle:nil];
    
    //NSLog(@"IN DETACHED CREATE %p", newViewController);
    
    self.popoverWindow = [[NSWindow alloc] init];

    InputPopupControllerViewController *newViewController = self;
    
    NSRect newFrame = [self.popoverWindow frameRectForContentRect:NSMakeRect(0.0f, 0.0f, newViewController.view.frame.size.width, newViewController.view.frame.size.height)];
    //newViewController.myPopover = popover;
    
    [self.popoverWindow setFrame:newFrame display:NO];

    [self.popoverWindow setReleasedWhenClosed:NO];
    
    self.popoverWindow.contentView = newViewController.view;
    self.popoverWindow.delegate = self;
    
    newViewController.transitionFilterWindow = self.transitionFilterWindow;
    newViewController.InputController.content = self.InputController.content;
    newViewController.multiSourceController.content = self.multiSourceController.content;
    
    
    
    self.popoverWindow.title = [NSString stringWithFormat:@"CocoaSplit Input (%@)", [self.InputController.selection valueForKeyPath:@"name"]];
    
    self.popoverWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    return self.popoverWindow;
    
}


-(void)openUserFilterPanel:(CIFilter *)forFilter
{
    if (!forFilter)
    {
        return;
    }
    
    IKFilterUIView *filterView = [forFilter viewForUIConfiguration:@{IKUISizeFlavor:IKUISizeMini} excludedKeys:@[kCIInputImageKey, kCIInputTargetImageKey, kCIInputTimeKey]];
    
    self.userFilterWindow = [[NSWindow alloc] init];

    self.userFilterWindow.delegate = self;
    [self.userFilterWindow setContentSize:filterView.bounds.size];
    [self.userFilterWindow.contentView addSubview:filterView];
    self.userFilterWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    [self.userFilterWindow setReleasedWhenClosed:NO];
    
    [self.userFilterWindow makeKeyAndOrderFront:self.userFilterWindow];
    
}


-(void)openTransitionFilterPanel:(CIFilter *)forFilter
{
    if (!forFilter)
    {
        return;
    }
    
    IKFilterUIView *filterView = [forFilter viewForUIConfiguration:@{IKUISizeFlavor:IKUISizeMini} excludedKeys:@[kCIInputImageKey, kCIInputTargetImageKey, kCIInputTimeKey]];
    
    
    self.transitionFilterWindow = [[NSWindow alloc] init];
    self.transitionFilterWindow.delegate = self;
    [self.transitionFilterWindow setContentSize:filterView.bounds.size];
    [self.transitionFilterWindow.contentView addSubview:filterView];
    
    self.transitionFilterWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    [self.transitionFilterWindow setReleasedWhenClosed:NO];
    
    [self.transitionFilterWindow makeKeyAndOrderFront:self.transitionFilterWindow];
    
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


-(void)openScreenCropWindow:(AbstractCaptureDevice *)captureDevice
{

    NSScreen *cropScreen = [self findScreeenForDisplayID:captureDevice.captureDevice];
    
    
    //self.screenCropWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(100.0f, 100.0f, 400, 400) styleMask:NSBorderlessWindowMask backing:NSBackingStoreRetained defer:NO];
    
    
    //[self.screenCropWindow setContentView:oview];
    
    
    
    [self.cropSelectionWindow setOpaque:NO];
    [self.cropSelectionWindow setLevel:CGShieldingWindowLevel()];
    //self.cropSelectionWindow.styleMask = NSBorderlessWindowMask;
    
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
    
    
    
    id vidInput = self.InputController.selection;
    
    
    
    
    [vidInput setValue:[NSNumber numberWithInt:(int)viewBounds.origin.x] forKeyPath:@"videoInput.x_origin"];
    [vidInput setValue:[NSNumber numberWithInt:(int)viewBounds.origin.y] forKeyPath:@"videoInput.y_origin"];

    [vidInput setValue:[NSNumber numberWithInt:(int)NSHeight(viewBounds)] forKeyPath:@"videoInput.region_height"];
    [vidInput setValue:[NSNumber numberWithInt:(int)NSWidth(viewBounds)] forKeyPath:@"videoInput.region_width"];


    
    [self.cropSelectionWindow close];
}



- (IBAction)deleteMultiSource:(id)sender
{

    NSTableView *bTable = (NSTableView *)sender;
    NSInteger deleteRow = [bTable clickedRow];
    
    [self.multiSourceController removeObjectAtArrangedObjectIndex:deleteRow];
}


@end
