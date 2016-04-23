//
//  FileStreamServiceViewController.m
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "FileStreamServiceViewController.h"

@interface FileStreamServiceViewController ()

@end

@implementation FileStreamServiceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (IBAction)chooseDestination:(id)sender
{
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = NO;
    panel.allowsMultipleSelection = NO;
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            self.serviceObj.fileName = panel.URL.path;
        }
        
    }];
    
}

@end
