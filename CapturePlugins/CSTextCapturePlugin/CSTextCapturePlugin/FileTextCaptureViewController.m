//
//  FileTextCaptureViewController.m
//  CSTextCapturePlugin
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "FileTextCaptureViewController.h"
#import "FileTextCapture.h"

@interface FileTextCaptureViewController ()

@end

@implementation FileTextCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}



- (IBAction)chooseFile:(id)sender;
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [self commitEditing];
    
    if ([openPanel runModal] == NSOKButton)
    {
        NSArray *files = [openPanel URLs];
        for (NSURL *fileUrl in files)
        {
            if (fileUrl)
            {
                [(FileTextCapture *)self.captureObj openFile:fileUrl.path];
                
            }
        }
    }
}



@end
