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


-(instancetype) init
{
    if (self = [super init])
    {
        self = [super initWithNibName:@"InputPopupControllerViewController" bundle:nil];
    }
    
    return self;
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





- (IBAction)deleteMultiSource:(id)sender
{

    NSTableView *bTable = (NSTableView *)sender;
    NSInteger deleteRow = [bTable clickedRow];
    
    [self.multiSourceController removeObjectAtArrangedObjectIndex:deleteRow];
}


@end
