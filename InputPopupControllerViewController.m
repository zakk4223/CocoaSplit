//
//  InputPopupControllerViewController.m
//  CocoaSplit
//
//  Created by Zakk on 7/26/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "InputPopupControllerViewController.h"

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
    
    
    self.popoverWindow = [[NSWindow alloc] init];
    
    InputPopupControllerViewController *newViewController = [[InputPopupControllerViewController alloc] initWithNibName:@"InputPopupControllerViewController" bundle:nil];
    
    //InputPopupControllerViewController *newViewController = self;
    
    NSRect newFrame = [self.popoverWindow frameRectForContentRect:NSMakeRect(0.0f, 0.0f, newViewController.view.frame.size.width, newViewController.view.frame.size.height)];
    //newViewController.myPopover = popover;
    
    [self.popoverWindow setFrame:newFrame display:NO];

    [self.popoverWindow setReleasedWhenClosed:NO];
    
    self.popoverWindow.contentView = newViewController.view;
    self.popoverWindow.delegate = self;
    
    newViewController.InputController.content = self.InputController.content;

    
    self.popoverWindow.title = [NSString stringWithFormat:@"CocoaSplit Input (%@)", [self.InputController.selection valueForKeyPath:@"name"]];
    
    self.popoverWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    return self.popoverWindow;
    
}
@end
