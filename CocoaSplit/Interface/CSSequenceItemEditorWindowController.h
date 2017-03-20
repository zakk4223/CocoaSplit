//
//  CSSequenceItemEditorWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 3/16/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSSequenceItem.h"
#import "CSSequenceItemViewController.h"

@interface CSSequenceItemEditorWindowController : NSWindowController
{
    CSSequenceItemViewController *_itemController;
    void (^_closeWindowBlock)(NSWindowController *controller);
    
}

@property (assign) bool saveItemRequested;

@property (strong) CSSequenceItem *editItem;

@property (weak) IBOutlet NSView *mainView;


-(void)openWithItem:(CSSequenceItem *)editItem usingCloseBlock:(void (^)(CSSequenceItemEditorWindowController *controller))closeBlock;

- (IBAction)cancelEditClicked:(id)sender;
- (IBAction)saveEditClicked:(id)sender;

@end
