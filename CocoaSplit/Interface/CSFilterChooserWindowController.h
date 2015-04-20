//
//  CSFilterChooserWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 4/20/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CSFilterChooserWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    
    NSArray *_filterCategories;
    NSMutableDictionary *_availableFilterMap;
    
    NSString *_selectedCategory;
    
}

@property (weak) IBOutlet NSTableView *filterListTableView;
@property (strong) NSString *selectedFilterName;

- (IBAction)modalButtonAction:(NSButton *)sender;
+ (NSString *)run;
@end
