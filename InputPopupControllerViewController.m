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





- (IBAction)deleteMultiSource:(id)sender
{

    NSTableView *bTable = (NSTableView *)sender;
    NSInteger deleteRow = [bTable clickedRow];
    
    [self.multiSourceController removeObjectAtArrangedObjectIndex:deleteRow];
}


@end
