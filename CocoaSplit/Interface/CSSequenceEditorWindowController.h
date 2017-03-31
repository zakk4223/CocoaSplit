//
//  CSSequenceEditorWIndowController.h
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSLayoutSequence.h"

@interface CSSequenceEditorWindowController : NSWindowController
{
    NSPopover *_addStepPopover;
    NSMutableArray *_itemConfigWindows;
    NSMutableArray *_itemClasses;
    
}
@property (unsafe_unretained) IBOutlet NSTextView *sequenceTextView;
@property (strong) IBOutlet NSObjectController *sequenceObjectController;

@property (assign) bool addSequenceOnSave;

@property (strong) CSLayoutSequence *sequence;
- (IBAction)saveButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;
-(IBAction)openAddStepPopover:(NSButton *)sender;

@end
