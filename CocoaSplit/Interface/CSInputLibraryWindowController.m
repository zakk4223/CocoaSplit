//
//  CSInputLibraryWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 10/18/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSInputLibraryWindowController.h"
#import "CaptureController.h"
#import "CSLibraryInputItemViewController.h"


@interface CSInputLibraryWindowController ()

@end

@implementation CSInputLibraryWindowController


-(instancetype) init
{
    return [self initWithWindowNibName:@"CSInputLibraryWindowController"];
}



- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self.tableView registerForDraggedTypes:@[@"CSInputPasteBoard"]];
}


//Table view delegate


-(BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSMutableArray *dataArray = [NSMutableArray array];
    [pboard declareTypes:[NSArray arrayWithObject:@"CSInputPasteBoard"] owner:self];
    NSArray *draggedItems = [self.itemArrayController.arrangedObjects objectsAtIndexes:rowIndexes];
    
    for (CSInputLibraryItem *item in draggedItems)
    {
        [dataArray addObject:item.inputData];
    }
    
    NSData *pbData = [NSArchiver archivedDataWithRootObject:dataArray];
    
    [pboard setData:pbData forType: @"CSInputPasteBoard"];
    return YES;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (!self.tableControllers)
    {
        self.tableControllers = [NSMutableArray array];
    }
    
    CSInputLibraryItem *cItem = [self.controller.inputLibrary objectAtIndex:row];
    if (cItem)
    {
        CSLibraryInputItemViewController *vCont = [[CSLibraryInputItemViewController alloc] init];
        vCont.item = cItem;
        [self.tableControllers addObject:vCont];
        return vCont.view;
    }
    return nil;
}

@end
