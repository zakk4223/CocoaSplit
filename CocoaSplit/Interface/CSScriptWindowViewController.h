//
//  CSScriptWindowViewController.h
//  CocoaSplit
//
//  Created by Zakk on 4/7/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSSequenceActivatorViewController.h"
#import "CSGridView.h"
#import "CSSequenceEditorWindowController.h"


@interface CSScriptWindowViewController : NSWindowController
{
    CSSequenceActivatorViewController *_sequenceViewController;
    CSSequenceEditorWindowController *_sequenceWindowController;
}

-(IBAction)addScriptAction:(id)sender;

@property (weak) IBOutlet CSGridView *gridView;
@property (strong) NSArray *sequences;

@end
