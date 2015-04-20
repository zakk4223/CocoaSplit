//
//  CSFilterChooserWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 4/20/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSFilterChooserWindowController.h"
#import <QuartzCore/QuartzCore.h>


@interface CSFilterChooserWindowController ()

@end

@implementation CSFilterChooserWindowController

- (void)windowDidLoad {
    
    _filterCategories = @[kCICategoryDistortionEffect,
                          kCICategoryGeometryAdjustment,
                          kCICategoryCompositeOperation,
                          kCICategoryHalftoneEffect,
                          kCICategoryColorAdjustment,
                          kCICategoryColorEffect,
                          kCICategoryTransition,
                          kCICategoryTileEffect,
                          kCICategoryGenerator,
                          kCICategoryReduction,
                          kCICategoryGradient,
                          kCICategoryStylize,
                          kCICategorySharpen,
                          kCICategoryBlur,
                          kCICategoryVideo,
                          kCICategoryStillImage,
                          kCICategoryInterlaced,
                          kCICategoryNonSquarePixels,
                          kCICategoryHighDynamicRange,
                          kCICategoryBuiltIn,
                          ];
    
    _availableFilterMap = [NSMutableDictionary dictionary];
    
    for (NSString *cat in _filterCategories)
    {
        [_availableFilterMap setObject:[CIFilter filterNamesInCategory:cat] forKey:cat];
    }
    
    
        
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    
    NSTableView *tableView = notification.object;
    
    

    if (tableView.tag == 1)
    {
        _selectedCategory = [_filterCategories objectAtIndex:tableView.selectedRow];
        
        [self.filterListTableView reloadData];
        [self.filterListTableView deselectAll:self];
        [self.filterListTableView noteNumberOfRowsChanged];
        self.selectedFilterName = nil;
        
    } else if (tableView.tag == 2) {
        NSArray *filters = _availableFilterMap[_selectedCategory];
        self.selectedFilterName = [filters objectAtIndex:tableView.selectedRow];
    }
}


-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView.tag == 1)
    {
        return _filterCategories.count;
    } else if (tableView.tag == 2) {
        if (_selectedCategory)
        {
            NSArray *filters = _availableFilterMap[_selectedCategory];
            return filters.count;
        }
    }
    return 0;
}

-(id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView.tag == 1)
    {
        NSString *filterCategory = [_filterCategories objectAtIndex:row];
        NSString *filterDesc = [CIFilter localizedNameForCategory:filterCategory];
        return filterDesc;
    } else if (tableView.tag == 2) {
        if (_selectedCategory)
        {
            NSArray *filters = _availableFilterMap[_selectedCategory];
            return [filters objectAtIndex:row];
        }
    }
        
    
    return nil;
}


- (IBAction)modalButtonAction:(NSButton *)sender
{
    [NSApp stopModalWithCode:sender.tag];
    [self.window close];
}

+(NSString *)run
{
    CSFilterChooserWindowController *windowController = [[CSFilterChooserWindowController alloc] initWithWindowNibName:@"CSFilterChooserWindowController"];
    
    [NSApp runModalForWindow:windowController.window];
    return windowController.selectedFilterName;
    
}

@end
