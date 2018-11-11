//
//  CSAppleWebViewCaptureViewController.m
//  CSAppleWebViewCapturePlugin
//
//  Created by Zakk on 11/4/18.
//  Copyright © 2018 Zakk. All rights reserved.
//

#import "CSAppleWebViewCaptureViewController.h"

@interface CSAppleWebViewCaptureViewController ()

@end

@implementation CSAppleWebViewCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)openTestWindow:(id)sender {
    self.viewWindow = [[NSWindow alloc] init];
    self.viewWindow.styleMask = NSWindowStyleMaskClosable|NSWindowStyleMaskResizable|NSWindowStyleMaskTitled;

    [self.viewWindow setContentSize:self.captureObj.webView.bounds.size];
    [self.viewWindow.contentView addSubview:self.captureObj.webView];
    self.captureObj.webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    self.viewWindow.title = self.captureObj.webURL;
    self.viewWindow.delegate = self;
    self.viewWindow.releasedWhenClosed = NO;
    [self.viewWindow makeKeyAndOrderFront:nil];
}


-(void)windowDidEndLiveResize:(NSNotification *)notification
{
    self.captureObj.browser_width = self.viewWindow.frame.size.width;
    self.captureObj.browser_height = self.viewWindow.frame.size.height;
}


-(void)windowWillClose:(NSNotification *)notification
{
    self.viewWindow = nil;
}


@end
