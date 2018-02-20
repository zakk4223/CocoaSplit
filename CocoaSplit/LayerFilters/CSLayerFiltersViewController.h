//
//  CSLayerFiltersViewController.h
//  CocoaSplit
//
//  Created by Zakk on 1/28/18.
//

#import "CSViewController.h"

@interface CSLayerFiltersViewController : CSViewController <NSWindowDelegate>

@property (nonatomic, copy) void (^addFilter)(NSString *filterName);
@property (nonatomic, copy) void (^deleteFilter)(NSString *filterName);
@property (strong) IBOutlet NSArrayController *filterArrayController;

@property (strong) CALayer *baseLayer;
@property (strong) NSString *filterArrayName;
@property (strong) NSWindow *userFilterWindow;

- (IBAction)filterControlAction:(NSSegmentedControl *)sender;

@end

