//
//  CSAddInputViewController.h
//  CocoaSplit
//
//  Created by Zakk on 5/8/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSPluginLoader.h"
#import "InputSource.h"


@interface CSAddInputViewController : NSViewController <NSTableViewDelegate>
{
    NSView *_typeListView;
    NSArray *_sourceTypeList;
}
@property (strong) IBOutlet NSView *initialView;

@property (weak) NSPopover *popover;

@property (strong) IBOutlet NSView *inputListView;

@property (weak) IBOutlet NSTableView *initialTable;

@property (strong) NSObject <CSCaptureSourceProtocol> *selectedInput;

@property (weak) IBOutlet NSTableView *deviceTable;

@property (readonly) NSArray *sourceTypes;
@property (weak) IBOutlet NSView *headerView;
@property (strong) IBOutlet NSArrayController *sourceTypesController;

- (IBAction)nextViewButton:(id)sender;
- (IBAction)previousViewButton:(id)sender;
- (IBAction)initalTableButtonClicked:(id)sender;
- (IBAction)inputTableButtonClicked:(id)sender;

@end
