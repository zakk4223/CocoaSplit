//
//  CSLayoutEditWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 10/12/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

#import "SourceLayout.h"
#import "PreviewView.h"
#import "OutputDestination.h"
#import "CSLayoutRecorder.h"
#import "CSScriptInputSource.h"
#import "CSSourceListViewController.h"
#import "CAMultiAudioEngineInputsController.h"
@interface CSLayoutEditWindowController : NSWindowController <NSWindowDelegate>
{
    float _frame_interval;
    CSSourceListViewController *_sourceListController;
    
    

}


@property (readonly) NSString *windowTitle;
@property (readonly) NSString *resolutionDescription;
@property (weak) CAMultiAudioEngine *multiAudioEngine;

@property (strong) IBOutlet NSMenu *recordingMenu;

@property (weak) id delegate;

@property (weak) IBOutlet PreviewView *previewView;

@property (strong) IBOutlet NSObjectController *layoutController;
- (IBAction)cancelEdit:(id)sender;
- (IBAction)editOK:(id)sender;
- (IBAction)layoutGoLive:(id)sender;

@property (assign) bool previewOnly;
@property (strong) IBOutlet CSSourceListViewController *sourceListViewController;
@property (strong) IBOutlet CAMultiAudioEngineInputsController *multiAudioEngineViewController;

@end
