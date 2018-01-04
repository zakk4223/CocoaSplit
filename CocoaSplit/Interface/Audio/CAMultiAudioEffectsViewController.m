//
//  CAMultiAudioEffectsViewController.m
//  CocoaSplit
//
//  Created by Zakk on 1/3/18.
//  Copyright © 2018 Zakk. All rights reserved.
//

#import "CAMultiAudioEffectsViewController.h"

@interface CAMultiAudioEffectsViewController ()

@end

@implementation CAMultiAudioEffectsViewController




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
    
    CAMultiAudioNode *newEffect = clickedEffect.copy;
    
    [self.effectArrayController addObject:newEffect];
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


-(IBAction)configureEffects:(id)sender
{
    NSArray *selectedEffects = self.effectArrayController.selectedObjects;
    for (CAMultiAudioEffect *effect in selectedEffects)
    {
        [self openConfigWindowForEffect:effect];
    }
}


-(void)setEffectPreset:(NSMenuItem *)item
{
    NSDictionary *effectData = item.representedObject;
    CAMultiAudioEffect *effect = effectData[@"effect"];
    if (effect)
    {
        NSNumber *pNum = effectData[@"number"];
        SInt32 presetNumber = [pNum intValue];
        [effect selectPresetNumber:presetNumber];
    }
}
-(void)menuNeedsUpdate:(NSMenu *)menu
{
    [menu removeAllItems];
    CAMultiAudioEffect *effect = [self.effectArrayController.arrangedObjects objectAtIndex:self.effectTable.clickedRow];
    if (effect)
    {
        for (NSDictionary *pDict in [effect effectPresets])
        {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:pDict[@"name"] action:@selector(setEffectPreset:) keyEquivalent:@""];
            NSMutableDictionary *rDict = pDict.mutableCopy;
            rDict[@"effect"] = effect;
            item.representedObject = rDict;
            item.target = self;
            [menu addItem:item];
        }
        
        if (menu.itemArray.count == 0)
        {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"No Presets" action:nil keyEquivalent:@""];
            item.representedObject = nil;
            [menu addItem:item];
        }
    }
}


-(void)awakeFromNib
{
    
    [super awakeFromNib];
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
    CAMultiAudioEffectWindow *newWindow;
    
    //if (nodeView)
    {
        newWindow = [[CAMultiAudioEffectWindow alloc] initWithAudioNode:effect];
        
        newWindow.delegate = self;
        [newWindow setReleasedWhenClosed:NO];
        [newWindow center];
        [newWindow makeKeyAndOrderFront:nil];
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

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do view setup here.
}

@end
