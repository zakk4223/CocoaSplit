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


@interface CSLayoutEditWindowController : NSWindowController <NSWindowDelegate, NSOutlineViewDelegate, NSTableViewDelegate>
{
    float _frame_interval;
    NSPopover *_animatepopOver;
    NSPopover *_addInputpopOver;
    NSMenu *_inputsMenu;
    
    
    

}

@property (strong) IBOutlet NSMenu *recordingMenu;
-(IBAction)inputOutlineViewDoubleClick:(NSOutlineView *)outlineView;

@property (weak) id delegate;

@property (weak) IBOutlet PreviewView *previewView;

@property (strong) IBOutlet NSObjectController *layoutController;
- (IBAction)cancelEdit:(id)sender;
- (IBAction)editOK:(id)sender;
- (IBAction)inputTableControlClick:(NSButton *)sender;
- (IBAction)layoutGoLive:(id)sender;

@property (weak) IBOutlet NSOutlineView *inputOutlineView;
@property (assign) bool previewOnly;
@property (strong) IBOutlet NSTreeController *inputTreeController;
@property (strong) NSArray *inputViewSortDescriptors;
@end
