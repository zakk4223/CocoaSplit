//
//  CSSourceLayoutSettingsWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 2/17/18.
//

#import <Cocoa/Cocoa.h>
#import "SourceLayout.h"
#import "CSLayerFiltersViewController.h"
#import "CSUndoObjectControllerDelegate.h"
@interface CSSourceLayoutSettingsWindowController : NSWindowController <CSUndoObjectControllerDelegate, NSWindowDelegate>

@property (strong) SourceLayout *layout;
@property (strong) IBOutlet CSLayerFiltersViewController *filterListViewController;
@property (strong) NSArray *scriptTypes;
@property (strong) NSArray *scriptKeys;
@property (strong) IBOutlet CSUndoObjectController *layoutObjectController;

- (IBAction)clearGradient:(id)sender;

@end
