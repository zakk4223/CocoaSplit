//
//  CSTransitionSwitcherView.m
//  CocoaSplit
//
//  Created by Zakk on 3/17/18.
//

#import "CSTransitionSwitcherView.h"
#import "CSTransitionCA.h"
#import "CSTransitionCIFilter.h"

@interface CSTransitionSwitcherView ()

@end

@implementation CSTransitionSwitcherView

- (void)viewDidLoad {
    CSTransitionCA *wtf = [[CSTransitionCA alloc] init];
    wtf.subType = kCATransitionFromRight;
    wtf.duration = @1.5f;
    [self.blah addObject:wtf];
    [super viewDidLoad];
    // Do view setup here.
}

-(void)awakeFromNib
{
    self.blah = [NSMutableArray array];

    [super awakeFromNib];

    
    [self.transitionsArrayController bind:@"contentArray" toObject:self.parentObjectController  withKeyPath:self.transitionArrayKeyPath options:nil];
    [self.collectionView registerForDraggedTypes:@[@"cocoasplit.transition"]];
    
    //[self.collectionView bind:@"content" toObject:self.parentObjectController withKeyPath:self.transitionArrayKeyPath options:nil];
}



- (IBAction)addTransitionClicked:(NSButton *)sender
{
    [self buildTransitionMenu];
    
    NSInteger midItem = _transitionsMenu.itemArray.count/2;
    NSPoint popupPoint = NSMakePoint(NSMaxY(sender.bounds), NSMidY(sender.bounds));
    [_transitionsMenu popUpMenuPositioningItem:[_transitionsMenu itemAtIndex:midItem] atLocation:popupPoint inView:sender];
}

-(void)createTransition:(NSMenuItem *)menuItem
{
    if (menuItem.representedObject)
    {
        CSTransitionBase *transitionCopy = [menuItem.representedObject copy];
        [self.transitionsArrayController addObject:transitionCopy];
    }
}



-(void)buildTransitionMenu
{
    _transitionsMenu = [[NSMenu alloc] init];
    
    NSArray *transitionClasses = @[CSTransitionCA.class, CSTransitionCIFilter.class];
    
    for (Class tClass in transitionClasses)
    {
       
        NSString *tCategory = [tClass transitionCategory];
        NSArray *tTypes = [tClass subTypes];
        

        NSMenuItem *item = nil;
        
        item = [[NSMenuItem alloc] initWithTitle:tCategory action:nil keyEquivalent:@""];
        NSMenu *typeMenu = [[NSMenu alloc] init];
        item.submenu = typeMenu;
        
        for (CSTransitionBase *tType in tTypes)
        {
            NSMenuItem *typeItem = [[NSMenuItem alloc] initWithTitle:tType.name action:nil keyEquivalent:@""];
            typeItem.target = self;
            typeItem.representedObject = tType;
            typeItem.action = @selector(createTransition:);
            [typeMenu addItem:typeItem];
        }
        [_transitionsMenu addItem:item];
        
    }
}

-(NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    
    NSPasteboard *pBoard = [draggingInfo draggingPasteboard];
    NSData *indexSave = [pBoard dataForType:@"cocoasplit.transition"];
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexSave];
    NSInteger draggedItemIdx = [indexes firstIndex];
    
    NSInteger useIdx = *proposedDropIndex;
    
    if (*proposedDropIndex > draggedItemIdx)
    {
        useIdx--;
    }
    
    
    if (useIdx < 0)
    {
        useIdx = 0;
    }
    
    
    
    if (*proposedDropIndex == -1 || labs(draggedItemIdx - useIdx) < 1)
    {
        return NSDragOperationNone;
    }
    
    return NSDragOperationMove;
}


-(BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    NSData *indexSave = [NSKeyedArchiver archivedDataWithRootObject:indexes];
    [pasteboard declareTypes:@[@"cocoasplit.transition"] owner:nil];
    [pasteboard setData:indexSave forType:@"cocoasplit.transition"];
    return YES;
}


-(BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    NSPasteboard *pBoard = [draggingInfo draggingPasteboard];
    NSData *indexSave = [pBoard dataForType:@"cocoasplit.transition"];
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexSave];
    NSInteger draggedItemIdx = [indexes firstIndex];
    
    
    
    CSTransitionBase *draggedItem = [self.transitionsArrayController.arrangedObjects objectAtIndex:draggedItemIdx];
    NSInteger useIdx = index;
    
    if (index > draggedItemIdx)
    {
        useIdx--;
    }
    
    
    if (useIdx < 0)
    {
        useIdx = 0;
    }
    
    [self.transitionsArrayController removeObjectAtArrangedObjectIndex:draggedItemIdx];
    [self.transitionsArrayController insertObject:draggedItem atArrangedObjectIndex:useIdx];
    return YES;
}


-(BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event
{
    return YES;
}

-(CSTransitionBase *)transitionForUUID:(NSString *)uuid
{
    for (CSTransitionBase *transition in self.transitionsArrayController.arrangedObjects)
    {
        if ([transition.uuid isEqualToString:uuid])
        {
            return transition;
        }
    }
    
    return nil;
}
@end
