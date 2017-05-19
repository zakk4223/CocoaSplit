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

- (IBAction)newSource:(id)sender
{
    [self.previewView addInputSource:self];
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


-(void)recordWithDefaults:(NSMenuItem *)item
{
    
    if (self.previewView.sourceLayout.recorder)
    {
        [[CaptureController sharedCaptureController] stopRecordingLayout:self.previewView.sourceLayout];
        [self.previewView enablePrimaryRender];
    } else {
        CSLayoutRecorder *recorder = [[CaptureController sharedCaptureController] startRecordingLayout:self.previewView.sourceLayout];
        self.previewView.layoutRenderer = recorder.renderer;
        [self.previewView disablePrimaryRender];
    }
}



-(void)recordWithOutput:(NSMenuItem *)item
{
    
    
    OutputDestination *useOutput = item.representedObject;
    if (self.previewView.sourceLayout.recorder && [self.previewView.sourceLayout.recorder.outputs containsObject:useOutput])
    {
        [[CaptureController sharedCaptureController] stopRecordingLayout:self.previewView.sourceLayout usingOutput:useOutput];
        [self.previewView enablePrimaryRender];
        
    } else {
        
        CSLayoutRecorder *recorder = [[CaptureController sharedCaptureController] startRecordingLayout:self.previewView.sourceLayout usingOutput:useOutput];
        self.previewView.layoutRenderer = recorder.renderer;
        [self.previewView disablePrimaryRender];
    }
}


- (IBAction)recordingButtonAction:(NSButton *)sender
{
    [self buildRecordMenu];
    
    
    [NSMenu popUpContextMenu:self.recordingMenu withEvent:[NSApp currentEvent] forView:sender];
}



-(void) buildRecordMenu
{
    
    NSInteger idx = 0;
    
    NSMenuItem *tmp;
    self.recordingMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    
    if (self.previewView.sourceLayout.recorder && self.previewView.sourceLayout.recorder.defaultRecordingActive)
    {
        tmp = [self.recordingMenu insertItemWithTitle:@"Stop Default Recorder" action:@selector(recordWithDefaults:) keyEquivalent:@"" atIndex:idx++];
    } else {
        tmp = [self.recordingMenu insertItemWithTitle:@"With Defaults" action:@selector(recordWithDefaults:) keyEquivalent:@"" atIndex:idx++];
    }
    
    tmp.target = self;
    NSArray *outputs = [[CaptureController sharedCaptureController] captureDestinations];
    for (OutputDestination *dest in outputs)
    {
        if (self.previewView.sourceLayout.recorder && [self.previewView.sourceLayout.recorder.outputs containsObject:dest])
        {
            tmp = [self.recordingMenu insertItemWithTitle:[NSString stringWithFormat:@"Stop %@", dest.name] action:@selector(recordWithOutput:) keyEquivalent:@"" atIndex:idx++];
            tmp.target = self;
            tmp.representedObject = dest;

        } else if (!dest.active) {

            tmp = [self.recordingMenu insertItemWithTitle:dest.name action:@selector(recordWithOutput:) keyEquivalent:@"" atIndex:idx++];
            tmp.target = self;
            tmp.representedObject = dest;
        }

    }
}

- (IBAction)inputTableControlClick:(NSButton *)sender
{
    NSInteger clicked = sender.tag;
    
    NSArray *selectedInputs;
    NSRect sbounds;
    switch (clicked) {
        case 0:
            sbounds = sender.bounds;
            //[self.activePreviewView addInputSource:sender];
            //sbounds.origin.x = NSMaxX(sender.frame) - [sender widthForSegment:0];
            //sbounds.origin.x -= 333;
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
