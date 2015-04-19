//
//  InputPopupControllerViewController.m
//  CocoaSplit
//
//  Created by Zakk on 7/26/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "InputPopupControllerViewController.h"
#import "InputSource.h"

@interface InputPopupControllerViewController ()

@end

@implementation InputPopupControllerViewController
@synthesize inputSource = _inputSource;


-(instancetype) init
{
    if (self = [super init])
    {
        self = [super initWithNibName:@"InputPopupControllerViewController" bundle:nil];
        self.inputConstraintMap = @{@"Left Edge": @(kCAConstraintMinX),
                                    @"Right Edge": @(kCAConstraintMaxX),
                                    @"Top Edge": @(kCAConstraintMaxY),
                                    @"Bottom Edge": @(kCAConstraintMinY),
                                    @"Horizontal Center": @(kCAConstraintMidX),
                                    @"Vertical Center": @(kCAConstraintMidY),
                                    @"Width": @(kCAConstraintWidth),
                                    @"Height": @(kCAConstraintHeight),
                                    };

        self.constraintSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES]];

        
        //self = [super initWithNibName:@"TestView" bundle:nil];

    }
    
    return self;
}


+(NSSet *)keyPathsForValuesAffectingSelectedVideoType
{
    return [NSSet setWithObjects:@"inputSource", nil];
}


-(void)setInputSource:(InputSource *)inputSource
{
    _inputSource = inputSource;
    
    [self sourceConfigurationView];
    
}

-(InputSource *)inputSource
{
    return _inputSource;
}


-(NSString *)selectedVideoType
{
    
    return self.inputSource.selectedVideoType;
}


-(void)setSelectedVideoType:(NSString *)selectedVideoType
{
    self.inputSource.selectedVideoType = selectedVideoType;
    [self sourceConfigurationView];
}


-(void)sourceConfigurationView
{

    NSViewController *sourceViewController = [self.inputSource sourceConfigurationView];
    
    
    
    NSView *configView = sourceViewController.view;
    self.view.hidden = NO;
    
    
    NSArray *currentSubviews = self.sourceConfigView.subviews;
    NSView *currentSubview = currentSubviews.firstObject;
    
    
    if (!configView)
    {
        [currentSubview removeFromSuperview];
    } else if (currentSubview) {
        [[self.sourceConfigView animator] replaceSubview:currentSubview with:configView ];
        [configView setFrameOrigin:NSMakePoint(configView.frame.origin.x, NSMaxY(self.sourceConfigView.frame) - configView.frame.size.height)];
        
    } else {
        [[self.sourceConfigView animator] addSubview:configView];
        [configView setFrameOrigin:NSMakePoint(configView.frame.origin.x, NSMaxY(self.sourceConfigView.frame) - configView.frame.size.height)];
    }
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}




- (void)popoverDidClose:(NSNotification *)notification
{
    
    NSString *closeReason = [[notification userInfo] valueForKey:NSPopoverCloseReasonKey];
            
    if (closeReason && closeReason == NSPopoverCloseReasonStandard)
    {
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        //
        // add new code here if you want to respond "after" the popover closes
        //
        self.inputSource.editorController = nil;
    }
    
    [self.inputSource editorPopoverDidClose];
    
    
    
    
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





- (IBAction)resetConstraints:(id)sender
{
    [self.inputSource resetConstraints];
    
}

- (IBAction)deleteMultiSource:(id)sender
{

    NSTableView *bTable = (NSTableView *)sender;
    NSInteger deleteRow = [bTable clickedRow];
    
    InputSource *toConfig = [self.multiSourceController.arrangedObjects objectAtIndex:deleteRow];
    

    InputPopupControllerViewController *windowController = [[InputPopupControllerViewController alloc] init];
    
    windowController.inputSource = toConfig;
    NSWindow *configWindow = [[NSWindow alloc] init];
    
    NSRect newFrame = [configWindow frameRectForContentRect:NSMakeRect(0.0f, 0.0f, windowController.view.frame.size.width, windowController.view.frame.size.height)];
    
    [configWindow setFrame:newFrame display:NO];
    
    [configWindow setReleasedWhenClosed:NO];
    
    
    [configWindow.contentView addSubview:windowController.view];
    configWindow.title = [NSString stringWithFormat:@"CocoaSplit Input (%@)", windowController.inputSource.name];
    configWindow.delegate = windowController.inputSource;
    
    configWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    
    windowController.inputSource.editorWindow = configWindow;
    windowController.inputSource.editorController = windowController;
    [configWindow makeKeyAndOrderFront:NSApp];
}


@end
