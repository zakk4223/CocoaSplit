//
//  CSTransitionSwitcherView.m
//  CocoaSplit
//
//  Created by Zakk on 3/17/18.
//

#import "CSTransitionSwitcherView.h"
#import "CSTransitionCA.h"
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
    
    NSArray *transitionClasses = @[CSTransitionCA.class];
    
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
@end
