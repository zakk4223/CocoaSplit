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
    [self.tableView registerForDraggedTypes:@[@"cocoasplit.library.item"]];
}


//Table view delegate

-(void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
{
    NSUInteger dlen = (rowIndexes.lastIndex+1) - rowIndexes.firstIndex;
    _dragRange = NSMakeRange(rowIndexes.firstIndex, dlen);
    _draggingObjects = [self.itemArrayController.arrangedObjects objectsAtIndexes:rowIndexes];
}

-(void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    _dragRange = NSMakeRange(0, 0);
    _draggingObjects = nil;
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if (dropOperation == NSTableViewDropAbove && (_dragRange.location > row || _dragRange.location+_dragRange.length < row))
    {
        if ([info draggingSource] == self.tableView)
        {
            return NSDragOperationMove;
        }
    }
    return NSDragOperationNone;
}


-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    [tableView beginUpdates];
    NSArray *classes = @[[CSInputLibraryItem class]];
    
    [info enumerateDraggingItemsWithOptions:0 forView:tableView classes:classes searchOptions:@{} usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {
        NSInteger newIdx = row+idx;
        CSInputLibraryItem *dragItem = _draggingObjects[idx];
        NSInteger oldIdx = [self.itemArrayController.arrangedObjects indexOfObject:dragItem];
        if (oldIdx < newIdx)
        {
            newIdx -= idx+1;
        }
        
        [self.controller.inputLibrary removeObjectAtIndex:oldIdx];
        [self.controller.inputLibrary insertObject:dragItem atIndex:newIdx];
        [self.tableView moveRowAtIndex:oldIdx toIndex:newIdx];
    }];
    [tableView endUpdates];
    return YES;
}


-(BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSArray *draggedItems = [self.itemArrayController.arrangedObjects objectsAtIndexes:rowIndexes];
    
    [pboard clearContents];
    [pboard writeObjects:draggedItems];
    
    return YES;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (!self.tableControllers)
    {
        self.tableControllers = [NSMutableArray array];
    }
    
    CSInputLibraryItem *cItem = [self.itemArrayController.arrangedObjects objectAtIndex:row];
    if (cItem)
    {
        CSLibraryInputItemViewController *vCont = [[CSLibraryInputItemViewController alloc] init];
        vCont.item = cItem;
        [self.tableControllers addObject:vCont];
        return vCont.view;
    }
    return nil;
}

- (IBAction)deleteItem:(id)sender
{
    [self.tableView beginUpdates];
    [self.itemArrayController removeObjectsAtArrangedObjectIndexes:self.tableView.selectedRowIndexes];
//    [self.tableView removeRowsAtIndexes:self.tableView.selectedRowIndexes withAnimation:NSTableViewAnimationEffectFade];
    [self.tableView endUpdates];
}

- (IBAction)doDeleteFromMenu:(id)sender
{
    if (self.tableView.selectedRowIndexes.count == 0)
    {
        NSIndexSet *toSelect = [NSIndexSet indexSetWithIndex:self.tableView.clickedRow];
        [self.tableView selectRowIndexes:toSelect byExtendingSelection:NO];
    }
    [self deleteItem:sender];
}



@end
