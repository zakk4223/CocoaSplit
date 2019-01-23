//
//  CSFilterImageLayoutTransitionViewController.m
//  CocoaSplit
//
//  Created by Zakk on 1/23/19.
//  Copyright © 2019 Zakk. All rights reserved.
//

#import "CSFilterImageLayoutTransitionViewController.h"
#import "CSFilterChooserWindowController.h"

@interface CSFilterImageLayoutTransitionViewController ()

@end

@implementation CSFilterImageLayoutTransitionViewController


-(instancetype) init
{
    if ([self initWithNibName:@"CSFilterImageLayoutTransitionViewController" bundle:nil])
    {
        
    }
    
    return self;
}

-(IBAction)openFilterChooser:(NSButton *)sender
{
    NSString *filterName = [CSFilterChooserWindowController run];
    
    if (filterName)
    {
        self.transition.filter = [CIFilter filterWithName:filterName];
    }
}


-(IBAction)openTransitionFilterPanel:(NSButton *)sender
{
    
    if (!self.transition.filter)
    {
        return;
    }
    
    IKFilterUIView *filterView = [self.transition.filter viewForUIConfiguration:@{IKUISizeFlavor:IKUISizeMini} excludedKeys:@[kCIInputImageKey, kCIInputTargetImageKey, kCIInputTimeKey]];
    
    
    self.transitionFilterWindow = [[NSWindow alloc] init];
    [self.transitionFilterWindow setContentSize:filterView.bounds.size];
    [self.transitionFilterWindow.contentView addSubview:filterView];
    
    self.transitionFilterWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    [self.transitionFilterWindow setReleasedWhenClosed:NO];
    
    [self.transitionFilterWindow makeKeyAndOrderFront:self.transitionFilterWindow];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
