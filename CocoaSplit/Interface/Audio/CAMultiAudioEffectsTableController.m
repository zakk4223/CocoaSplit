//
//  CAMultiAudioEffectsTableController.m
//  CocoaSplit
//
//  Created by Zakk on 12/31/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioEffectsTableController.h"

@implementation CAMultiAudioEffectsTableController




-(void)removeEffects:(id)sender
{
    if (self.effectArrayController)
    {
        [self.effectArrayController removeObjectsAtArrangedObjectIndexes:self.effectArrayController.selectionIndexes];
    }
    
    
}


-(void)addEffect:(NSMenuItem *)item
{
    CAMultiAudioEffect *clickedEffect = item.representedObject;
    
    
    CAMultiAudioNode *useNode = self.audioNode;

    CAMultiAudioNode *newEffect = clickedEffect.copy;
    
    [useNode addEffect:newEffect];
}


-(IBAction)openAddEffect:(id)sender
{
    _effectsMenu = [[NSMenu alloc] init];
    
    NSArray *availableEffects = [CAMultiAudioEffect availableEffects];
    
    NSMenuItem *item = nil;
    for (CAMultiAudioEffect *effect in availableEffects)
    {
        item = [[NSMenuItem alloc] initWithTitle:effect.name action:@selector(addEffect:) keyEquivalent:@""];
        item.representedObject = effect;
        item.target = self;
        [_effectsMenu addItem:item];
    }
    
    NSButton *clicked = (NSButton *)sender;
    
    NSInteger midItem = _effectsMenu.itemArray.count/2;
    NSPoint popupPoint = NSMakePoint(NSMaxX(clicked.bounds), NSMidY(clicked.bounds));
    [_effectsMenu popUpMenuPositioningItem:[_effectsMenu itemAtIndex:midItem] atLocation:popupPoint inView:sender];
    
}



/*
-(void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    bool removeRows = false;
    
    if (operation == NSDragOperationMove)
    {
        NSRect windowRect = [self.effectTable convertRect:self.effectTable.bounds toView:nil];
    }

}
 */



-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if (dropOperation == NSTableViewDropAbove)
    {
        return NSDragOperationMove;
    }
    
    return NSDragOperationNone;
    
}


-(IBAction)effectTableDoubleClick:(NSTableView *)tableView
{
    NSInteger row = tableView.clickedRow;
    CAMultiAudioEffect *effect = [self.effectArrayController.arrangedObjects objectAtIndex:row];
    [self openConfigWindowForEffect:effect];
}


-(void)awakeFromNib
{
    self.configWindows = [NSMutableDictionary dictionary];
    
    [self.effectTable registerForDraggedTypes:@[@"cocoasplit.audioeffect.indexes"]];
}

-(void)windowWillClose:(NSNotification *)notification
{
    NSWindow *removed = notification.object;
    [self.configWindows removeObjectForKey:removed.identifier];
}


-(void) openConfigWindowForEffect:(CAMultiAudioEffect *)effect
{
    NSWindow *newWindow;
    
    NSView *nodeView = [effect audioUnitNSView];
    if (nodeView)
    {
        newWindow = [[NSWindow alloc] initWithContentRect:nodeView.frame styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
        
        newWindow.delegate = self;
        [newWindow setReleasedWhenClosed:NO];
        [newWindow center];
        [newWindow setContentView:nodeView];
        [newWindow makeKeyAndOrderFront:NSApp];
        newWindow.identifier = effect.nodeUID;
        [self.configWindows setObject:newWindow forKey:newWindow.identifier];
    }
}


-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    
    NSInteger dropRow = row;
    
    NSData *iData = [info.draggingPasteboard dataForType:@"cocoasplit.audioeffect.indexes"];
    
    NSIndexSet *movedIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:iData];
    
    NSArray *movedObjects = [self.effectArrayController.arrangedObjects objectsAtIndexes:movedIndexes];
    
    [self.effectArrayController removeObjectsAtArrangedObjectIndexes:movedIndexes];
    
    dropRow -= [movedIndexes countOfIndexesInRange:NSMakeRange(0, dropRow)];
    
    
    [self.effectArrayController insertObjects:movedObjects atArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dropRow, movedObjects.count)]];
    

    return YES;
}


-(BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    
    [pboard clearContents];
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:@"cocoasplit.audioeffect.indexes"];
    return YES;
}



@end
