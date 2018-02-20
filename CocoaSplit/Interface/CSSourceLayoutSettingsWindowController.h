//
//  CSSourceLayoutSettingsWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 2/17/18.
//

#import <Cocoa/Cocoa.h>
#import "SourceLayout.h"
#import "CSLayerFiltersViewController.h"

@interface CSSourceLayoutSettingsWindowController : NSWindowController
@property (strong) SourceLayout *layout;
@property (strong) IBOutlet CSLayerFiltersViewController *filterListViewController;
@property (strong) NSArray *scriptTypes;
@property (strong) NSArray *scriptKeys;

- (IBAction)clearGradient:(id)sender;

@end
