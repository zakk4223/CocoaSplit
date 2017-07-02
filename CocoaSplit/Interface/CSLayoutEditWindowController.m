//
//  CSLayoutEditWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 10/12/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSLayoutEditWindowController.h"

@interface CSLayoutEditWindowController ()

@end

@implementation CSLayoutEditWindowController


-(instancetype) init
{
    return [self initWithWindowNibName:@"CSLayoutEditWindowController"];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.delegate = self;
    [self.inputOutlineView registerForDraggedTypes:@[@"cocoasplit.input.item"]];

    if (self.previewView.sourceLayout.recorder)
    {
        [self.previewView disablePrimaryRender];
    }
    [self.previewView addObserver:self forKeyPath:@"sourceLayout.recorder" options:NSKeyValueObservingOptionNew context:NULL];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


-(void)windowWillClose:(NSNotification *)notification
{
    
    [self.previewView removeObserver:self forKeyPath:@"sourceLayout.recorder"];
    if (self.layoutController)
    {
        [self.layoutController discardEditing];
    }
    
    if (self.previewView.sourceLayout && !self.previewView.sourceLayout.recordingLayout)
    {
        [self.previewView.sourceLayout clearSourceList];
    }
    
    if (self.delegate)
    {
        [self.delegate layoutWindowWillClose:self];
    }
}



- (IBAction)cancelEdit:(id)sender
{
    [self close];
}



- (IBAction)editOK:(id)sender
{
    if (self.layoutController)
    {
        [self.layoutController commitEditing];
    }
        
    if (self.previewView.sourceLayout)
    {
        [self.previewView.sourceLayout saveSourceList];
        [self.previewView.sourceLayout clearSourceList];
    }
    [self close];
}



- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item
{
    NSPasteboardItem *pItem = [[NSPasteboardItem alloc] init];
    NSTreeNode *outlineNode = (NSTreeNode *)item;
    InputSource *itemInput = outlineNode.representedObject;
    
    [pItem setString:itemInput.uuid forType:@"cocoasplit.input.item"];
    
    return pItem;
}

-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    
    NSTreeNode *nodeItem = (NSTreeNode *)item;
    InputSource *nodeInput = nil;
    if (nodeItem)
    {
        nodeInput = nodeItem.representedObject;
    }
    
    
    NSPasteboard *pb = [info draggingPasteboard];
    NSString *draggedUUID = [pb stringForType:@"cocoasplit.input.item"];
    InputSource *draggedSource = [self.previewView.sourceLayout inputForUUID:draggedUUID];
    
    
    if (nodeInput && nodeInput == draggedSource)
    {
        return NSDragOperationNone;
    }
    
    if (nodeInput && draggedSource.parentInput == nodeInput)
    {
        return NSDragOperationNone;
    }
    
    if (draggedSource.parentInput && nodeInput && nodeInput != draggedSource.parentInput)
    {
        return NSDragOperationMove;
    }
    
    
    if (draggedSource.parentInput && !nodeInput)
    {
        return NSDragOperationMove;
    }
    
    
    if (item && index == -1)
    {
        return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
    
    NSPasteboard *pb = [info draggingPasteboard];
    NSString *draggedUUID = [pb stringForType:@"cocoasplit.input.item"];
    NSTreeNode *parentNode = (NSTreeNode *)item;
    InputSource *parentSource = nil;
    InputSource *draggedSource = [self.previewView.sourceLayout inputForUUID:draggedUUID];
    
    if (parentNode)
    {
        parentSource = parentNode.representedObject;
    }
    
    if (!parentSource)
    {
        [draggedSource.parentInput detachInput:draggedSource];
    } else {
        [parentSource attachInput:draggedSource];
    }
    
    return YES;
}


-(void) resetInputTableHighlights
{
    [self.previewView stopHighlightingAllSources];
    if (self.inputOutlineView && self.inputOutlineView.selectedRowIndexes)
    {
        [self.inputOutlineView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSTreeNode *node = [self.inputOutlineView itemAtRow:idx];
            InputSource *src = node.representedObject;
            if (src)
            {
                [self.previewView highlightSource:src];
            }
        }];
    }
}


-(void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    NSTreeNode *node = [outlineView itemAtRow:row];
    InputSource *src = node.representedObject;
    if (!src.parentInput)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [outlineView expandItem:nil expandChildren:YES];
        });
    }
}


-(void) outlineViewSelectionDidChange:(NSNotification *)notification
{
    [self resetInputTableHighlights];
}


-(void)openAddInputPopover:(id)sender sourceRect:(NSRect)sourceRect
{
    
    CSAddInputViewController *vc;
    if (!_addInputpopOver)
    {
        _addInputpopOver = [[NSPopover alloc] init];
        _addInputpopOver.animates = YES;
        _addInputpopOver.behavior = NSPopoverBehaviorTransient;
    }
    
    //if (!_addInputpopOver.contentViewController)
    {
        vc = [[CSAddInputViewController alloc] init];
        _addInputpopOver.contentViewController = vc;
        vc.popover = _addInputpopOver;
        vc.previewView = self.previewView;
        
        //_addInputpopOver.delegate = vc;
    }
    
    [_addInputpopOver showRelativeToRect:sourceRect ofView:sender preferredEdge:NSMaxXEdge];
}





- (IBAction)inputTableControlClick:(NSButton *)sender
{
    NSInteger clicked = sender.tag;
    
    NSRect sbounds;
    switch (clicked) {
        case 0:
            sbounds = sender.bounds;
            [self openAddInputPopover:sender sourceRect:sbounds];
            break;
        case 1:
            if (self.inputOutlineView && self.inputOutlineView.selectedRowIndexes)
            {
                [self.inputOutlineView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    NSTreeNode *node = [self.inputOutlineView itemAtRow:idx];
                    InputSource *src = node.representedObject;
                    
                    if (src)
                    {
                        NSString *uuid = src.uuid;
                        InputSource *realInput = [self.previewView.sourceLayout inputForUUID:uuid];
                        [self.previewView deleteInput:realInput];
                    }
                    
                }];

            }
            break;
        case 2:
            
            if (self.inputOutlineView && self.inputOutlineView.selectedRowIndexes)
            {
                
                [self.inputOutlineView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    NSTreeNode *node = [self.inputOutlineView itemAtRow:idx];
                    InputSource *src = node.representedObject;
                    
                    if (src)
                    {
                        [self.previewView openInputConfigWindow:src.uuid];
                    }
                    
                }];
            }
            break;
        default:
            break;
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"sourceLayout.recorder"])
    {
        if (self.previewView.sourceLayout.recorder)
        {
            [self.previewView disablePrimaryRender];
        } else {
            [self.previewView enablePrimaryRender];
        }
    }
}


@end
