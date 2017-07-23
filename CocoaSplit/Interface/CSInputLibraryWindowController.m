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
#import "CSLayoutEditWindowController.h"


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
    [self.tableView registerForDraggedTypes:@[NSSoundPboardType,NSFilenamesPboardType, NSFilesPromisePboardType, NSFileContentsPboardType, @"cocoasplit.library.item"]];
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
    if (_draggingObjects)
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

    return NSDragOperationCopy;
}


-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    [tableView beginUpdates];
    NSArray *classes = @[[CSInputLibraryItem class]];

    __block bool trySources = YES;
    
    [info enumerateDraggingItemsWithOptions:0 forView:tableView classes:classes searchOptions:@{} usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {

        NSInteger newIdx = row+idx;
        CSInputLibraryItem *dragItem = self->_draggingObjects[idx];
        NSInteger oldIdx = [self.itemArrayController.arrangedObjects indexOfObject:dragItem];
        if (oldIdx < newIdx)
        {
            newIdx -= idx+1;
        }
        
        trySources = NO;
        
        [self.controller.inputLibrary removeObjectAtIndex:oldIdx];
        [self.controller.inputLibrary insertObject:dragItem atIndex:newIdx];
        [self.tableView moveRowAtIndex:oldIdx toIndex:newIdx];
    }];
    
    [tableView endUpdates];
    
    if (trySources)
    {
        NSPasteboard *pb = [info draggingPasteboard];
        for (NSPasteboardItem *item in pb.pasteboardItems)
        {
            NSObject<CSInputSourceProtocol> *itemSrc = [[CaptureController sharedCaptureController] inputSourceForPasteboardItem:item];
            if (itemSrc)
            {
                [[CaptureController sharedCaptureController] addInputToLibrary:itemSrc atIndex:row];
            }
        }
        
    }

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


-(void)popoverWillClose:(NSNotification *)notification
{
    if (self.activePopupController && self.activePopupItem)
    {
        InputSource *editInput = self.activePopupController.inputSource;
        
        //[editInput frameTick];
        
        [self.activePopupItem makeDataFromInput:editInput];
    }
    
    self.activePopupItem = nil;
}

-(void)popoverDidClose:(NSNotification *)notification
{
    self.activePopupItem = nil;
    self.activePopupController = nil;
    self.editLayout = nil;
}


-(void)layoutWindowWillClose:(id)controller
{
    [self.activePopupItem makeDataFromInput:self.activePopupItem.editInput];
    self.activePopupItem.editInput = nil;
    [self.controller layoutWindowWillClose:controller];
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

-(IBAction)doEditFromMenu:(id)sender
{
    
    CSInputLibraryItem *cItem = [self.itemArrayController.arrangedObjects objectAtIndex:self.tableView.clickedRow];
    
    
    
    
    
    InputSource *iSrc = [cItem makeInput];

    cItem.editInput = iSrc;
    
    //self.editLayout = [[SourceLayout alloc] init];
    
    CGFloat parent_width = iSrc.topLevelWidth;
    CGFloat parent_height = iSrc.topLevelHeight;
    
    //self.editLayout.canvas_width = parent_width;
    //self.editLayout.canvas_height = parent_height;
    NSLog(@"PARENT WIDTH %f HEIGHT %f", parent_width, parent_height);
    
    
    //[self.editLayout addSource:iSrc];
    
    /*
    self.editWindowController = [[CSLayoutEditWindowController alloc] init];
    self.editWindowController.previewView.sourceLayout = self.editLayout;
    [self.editWindowController showWindow:nil];
     */
    //self.editWindowController = [self.controller openLayoutWindow:self.editLayout];
    //self.editWindowController.delegate = self;
    
    InputPopupControllerViewController *popupController = [[InputPopupControllerViewController alloc] init];
    
    NSPopover *popover = [[NSPopover alloc] init];
    popover.contentViewController = popupController;
    popover.animates = YES;
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    [popover showRelativeToRect:self.tableView.frame ofView:self.tableView preferredEdge:NSMaxXEdge];
    
    //[iSrc frameTick];
    popupController.inputSource = iSrc;
    self.activePopupItem = cItem;
    self.activePopupController = popupController;
}

@end
