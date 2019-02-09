//
//  CSInputLibraryWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 10/18/15.
//

#import <Cocoa/Cocoa.h>
#import "InputPopupControllerViewController.h"
#import "CSInputLibraryItem.h"


@class CaptureController;
@class CSLayoutEditWindowController;

@interface CSInputLibraryWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource, NSPopoverDelegate>
{
    NSRange _dragRange;
    NSArray *_draggingObjects;

}


@property (strong) CaptureController *controller;
@property (weak) IBOutlet NSTableView *tableView;
@property (strong) NSMutableArray *tableControllers;
@property (strong) IBOutlet NSArrayController *itemArrayController;

@property (strong) InputPopupControllerViewController *activePopupController;
@property (strong) CSInputLibraryItem *activePopupItem;

@property (strong) SourceLayout *editLayout;

@property (strong) CSLayoutEditWindowController *editWindowController;

- (IBAction)deleteItem:(id)sender;


- (IBAction)doDeleteFromMenu:(id)sender;
-(IBAction)doEditFromMenu:(id)sender;

@end
