//
//  CSInputLayoutTransitionViewController.m
//  CocoaSplit
//
//  Created by Zakk on 4/1/18.
//  Copyright © 2018 Zakk. All rights reserved.
//

#import "CSInputLayoutTransitionViewController.h"

@interface CSInputLayoutTransitionViewController ()

@end

@implementation CSInputLayoutTransitionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self openInputConfigWindow:nil];
    // Do view setup here.
}

    -(IBAction)openInputConfigWindow:(id)sender
    {
        
        
        NSObject<CSInputSourceProtocol> *configSrc = self.transition.inputSource;
        NSViewController *newViewController = [configSrc configurationViewController];
        _configViewController = newViewController;
        
        NSRect curBounds = self.view.bounds;
        curBounds.size.width = _configViewController.view.bounds.size.width + 16;
        curBounds.size.height = curBounds.size.height + _configViewController.view.bounds.size.height + 8;
        self.popover.contentSize = curBounds.size;
        NSRect subFrame = _configViewController.view.frame;
        subFrame.origin.y = subFrame.origin.y * 0.5;
        [self.inputConfigView addSubview:_configViewController.view];
        [_configViewController.view setFrameOrigin:NSMakePoint(_configViewController.view.frame.origin.x, NSMaxY(self.inputConfigView.frame) - _configViewController.view.frame.size.height-8)];
        
    }
    
@end
