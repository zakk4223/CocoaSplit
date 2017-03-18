//
//  CSSequenceEditorWIndowController.h
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSLayoutSequence.h"
#import "CSSequenceItemEditorWindowController.h"

@interface CSSequenceEditorWindowController : NSWindowController
{
    NSPopover *_addStepPopover;
    NSMutableArray *_itemConfigWindows;
}
- (IBAction)itemSegmentControlClicked:(id)sender;
@property (strong) IBOutlet NSArrayController *sequenceItemsArrayController;
@property (strong) IBOutlet NSObjectController *sequenceObjectController;

@property (assign) bool addSequenceOnSave;

@property (strong) CSLayoutSequence *sequence;
- (IBAction)saveButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;

@end
